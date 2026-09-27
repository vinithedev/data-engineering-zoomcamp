"""@bruin
name: ingestion.trips
type: python
image: python:3.11
connection: duckdb-default
description: |
  Raw NYC TLC trip records, fetched as monthly parquet files from the public TLC endpoint.
  Data is kept as-is (no cleaning); `taxi_type` and `extracted_at` are added for lineage.
  Duplicates from re-runs are expected and handled in staging.

materialization:
  type: table
  strategy: append
@bruin"""

import json
import os
import shutil
import tempfile
from datetime import date, datetime, timezone

import pyarrow as pa
import pyarrow.parquet as pq
import requests
from dateutil.relativedelta import relativedelta

BASE_URL = "https://d37ci6vzurychx.cloudfront.net/trip-data"
DEFAULT_TAXI_TYPES = ["yellow"]
# Bruin writes each yielded table as one Arrow batch, and the loader rejects
# batches over 256 MB. 250k rows of trip data is roughly 40 MB.
BATCH_SIZE = 250_000


def get_months(start: date, end: date) -> list[date]:
    """First day of every month that overlaps the half-open window [start, end)."""
    month = start.replace(day=1)
    months = []
    while month < end:
        months.append(month)
        month += relativedelta(months=1)
    return months


def download(url: str, dest: str) -> bool:
    with requests.get(url, stream=True, timeout=300) as response:
        if response.status_code in (403, 404):
            # TLC returns 403/404 for months that are not published yet
            print(f"Skipping {url}: not available (HTTP {response.status_code})")
            return False
        response.raise_for_status()
        with open(dest, "wb") as f:
            for chunk in response.iter_content(chunk_size=1 << 20):
                f.write(chunk)
    return True


def lowercase(schema: pa.Schema) -> pa.Schema:
    # Column casing varies between months (e.g. airport_fee vs Airport_fee);
    # lowercase so appends don't create duplicate columns.
    return pa.schema([field.with_name(field.name.lower()) for field in schema])


def conform(table: pa.Table, schema: pa.Schema) -> pa.Table:
    """Cast to the run's unified schema, adding columns this file doesn't have as nulls."""
    columns = [
        table[field.name].cast(field.type)
        if field.name in table.column_names
        else pa.nulls(table.num_rows, field.type)
        for field in schema
    ]
    return pa.Table.from_arrays(columns, schema=schema)


def stream(files, schema, extracted_at, tmp_dir):
    try:
        for path, taxi_type in files:
            rows = 0
            for batch in pq.ParquetFile(path).iter_batches(batch_size=BATCH_SIZE):
                table = pa.Table.from_batches([batch])
                table = table.rename_columns([c.lower() for c in table.column_names])
                table = table.append_column(
                    "taxi_type", pa.array([taxi_type] * table.num_rows, pa.string())
                )
                table = table.append_column(
                    "extracted_at",
                    pa.array([extracted_at] * table.num_rows, schema.field("extracted_at").type),
                )
                rows += table.num_rows
                yield conform(table, schema)
            print(f"Loaded {rows:,} rows from {os.path.basename(path)}")
    finally:
        shutil.rmtree(tmp_dir, ignore_errors=True)


def materialize():
    start = date.fromisoformat(os.environ["BRUIN_START_DATE"])
    end = date.fromisoformat(os.environ["BRUIN_END_DATE"])
    taxi_types = json.loads(os.environ.get("BRUIN_VARS", "{}")).get(
        "taxi_types", DEFAULT_TAXI_TYPES
    )

    # Download everything first: every yielded table must share one schema, and
    # column types drift between months (e.g. int64 vs double), so the schemas
    # are unified before streaming any rows.
    tmp_dir = tempfile.mkdtemp(prefix="nyc_taxi_")
    files = []
    for taxi_type in taxi_types:
        for month in get_months(start, end):
            filename = f"{taxi_type}_tripdata_{month:%Y-%m}.parquet"
            url = f"{BASE_URL}/{filename}"
            print(f"Downloading {url}")
            path = os.path.join(tmp_dir, filename)
            if download(url, path):
                files.append((path, taxi_type))

    if not files:
        shutil.rmtree(tmp_dir, ignore_errors=True)
        print(f"No data found for {taxi_types} between {start} and {end}")
        return None

    schema = pa.unify_schemas(
        [lowercase(pq.read_schema(path)) for path, _ in files],
        promote_options="permissive",
    ).remove_metadata()
    schema = schema.append(pa.field("taxi_type", pa.string()))
    schema = schema.append(pa.field("extracted_at", pa.timestamp("us", tz="UTC")))

    return stream(files, schema, datetime.now(timezone.utc), tmp_dir)
