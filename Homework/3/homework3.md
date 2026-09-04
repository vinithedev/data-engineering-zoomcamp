### Resources
```
https://github.com/DataTalksClub/data-engineering-zoomcamp/blob/main/cohorts/2026/03-data-warehouse/homework.md
https://www.nyc.gov/site/tlc/about/tlc-trip-record-data.page
```

### Create an external table using the Yellow Taxi Trip Records
```
> cd Pipeline/pipeline/
> pip install google-cloud-storage
> gcloud auth application-default login
> python load_yellow_taxi_data.py
> rm -rf .venv
> uv venv
> uv sync

Create .env file in this dir and add google credentials: "GCP_CREDENTIALS={"type": "service_account",...
Move every .py file into another dir

> unset GCP_CREDENTIALS
> powershell.exe -Command "[System.Environment]::SetEnvironmentVariable('GCP_CREDENTIALS', \$null, 'User')"

> uv run jupyter notebook
http://localhost:8888/
Open DLT_upload_to_GCP.ipynb and run it
```

### 1. What is count of records for the 2024 Yellow Taxi Data?

In the last jupyter cell:
```python
# provide a resource name to query a table of that name
with pipeline.sql_client() as client:
    with client.execute_query(f"SELECT count(1) FROM rides") as cursor:
        data = cursor.df()
print(data)
```
```
   count(1)
0  20332093
```
```python
# 20,332,093
```

### 2. Write a query to count the distinct number of PULocationIDs for the entire dataset on both the tables. What is the estimated amount of data that will be read when this query is executed on the External Table and the Table?

In BigQuery:
```sql
CREATE SCHEMA IF NOT EXISTS `analog-artifact-377402.03_data_warehouse`;

CREATE OR REPLACE EXTERNAL TABLE `analog-artifact-377402.03_data_warehouse.yellow_tripdata_2024_external`
OPTIONS (
  format = 'PARQUET',
  uris = ['gs://kestra-zoomcamp-vini-demo-20260818/rides_dataset/rides/yellow_tripdata_2024_*_parquet.parquet']
);
```

```sql
CREATE OR REPLACE TABLE `analog-artifact-377402.03_data_warehouse.yellow_tripdata_2024_materialized`
AS
SELECT *
FROM `analog-artifact-377402.03_data_warehouse.yellow_tripdata_2024_external`;
```

```sql
SELECT DISTINCT(pu_location_id)
FROM `analog-artifact-377402.03_data_warehouse.yellow_tripdata_2024_external`;

-- This query will process 0 B when run.
```

```sql
SELECT DISTINCT(pu_location_id)
FROM `analog-artifact-377402.03_data_warehouse.yellow_tripdata_2024_materialized`;

-- This query will process 155.12 MB when run.
```

0 MB for the External Table and 155.12 MB for the Materialized Table

### 3. Write a query to retrieve the PULocationID from the table (not the external table) in BigQuery. Now write a query to retrieve the PULocationID and DOLocationID on the same table. Why are the estimated number of Bytes different?

```sql
SELECT pu_location_id
FROM `analog-artifact-377402.03_data_warehouse.yellow_tripdata_2024_materialized`;

SELECT
  pu_location_id,
  do_location_id
FROM `analog-artifact-377402.03_data_warehouse.yellow_tripdata_2024_materialized`;
```

BigQuery is a columnar database, and it only scans the specific columns requested in the query. Querying two columns (PULocationID, DOLocationID) requires reading more data than querying one column (PULocationID), leading to a higher estimated number of bytes processed.

### 4. How many records have a fare_amount of 0?

```sql
SELECT count(1)
FROM `analog-artifact-377402.03_data_warehouse.yellow_tripdata_2024_external`
where fare_amount = 0

-- 8333
```

### 5. What is the best strategy to make an optimized table in Big Query if your query will always filter based on tpep_dropoff_datetime and order the results by VendorID (Create a new table with this strategy)

```sql
CREATE OR REPLACE TABLE `analog-artifact-377402.03_data_warehouse.yellow_tripdata_2024_optimized`
PARTITION BY DATE(tpep_dropoff_datetime)
CLUSTER BY vendor_id
AS
SELECT *
FROM `analog-artifact-377402.03_data_warehouse.yellow_tripdata_2024_external`;

SELECT *
FROM `analog-artifact-377402.03_data_warehouse.yellow_tripdata_2024_optimized`
WHERE tpep_dropoff_datetime >= '2024-03-01'
  AND tpep_dropoff_datetime <  '2024-04-01'
ORDER BY vendor_id;

-- This query will process 488.11 MB when run.

SELECT *
FROM `analog-artifact-377402.03_data_warehouse.yellow_tripdata_2024_materialized`
WHERE tpep_dropoff_datetime >= '2024-03-01'
  AND tpep_dropoff_datetime <  '2024-04-01'
ORDER BY vendor_id;

-- This query will process 2.72 GB when run.
```

Partition by tpep_dropoff_datetime and Cluster on VendorID

### 6. Write a query to retrieve the distinct VendorIDs between tpep_dropoff_datetime 2024-03-01 and 2024-03-15 (inclusive). Use the materialized table you created earlier in your from clause and note the estimated bytes. Now change the table in the from clause to the partitioned table you created for question 5 and note the estimated bytes processed. What are these values?

```sql
select distinct(vendor_id)
from `analog-artifact-377402.03_data_warehouse.yellow_tripdata_2024_materialized`
where tpep_dropoff_datetime between '2024-03-01' and '2024-03-15';

-- This query will process 310.24 MB when run.

select distinct(vendor_id)
from `analog-artifact-377402.03_data_warehouse.yellow_tripdata_2024_optimized`
where tpep_dropoff_datetime between '2024-03-01' and '2024-03-15';

-- This query will process 26.84 MB when run.
```

310.24 MB for non-partitioned table and 26.84 MB for the partitioned table

### 7. Where is the data stored in the External Table you created?

GCP Bucket

### 8. It is best practice in Big Query to always cluster your data:

False. Not always.

### 9. No Points: Write a SELECT count(*) query FROM the materialized table you created. How many bytes does it estimate will be read? Why?

```sql
select count(*)
from `analog-artifact-377402.03_data_warehouse.yellow_tripdata_2024_materialized`;

-- This query will process 0 B when run.
```

0 B. A simple ```count(*)``` with no ```where``` clause doesn't need to read any row or column. BigQuery already tracks the total row count as metadata.
