/* @bruin
name: staging.trips
type: duckdb.sql
description: |
  Cleaned, deduplicated NYC taxi trips for yellow and green cabs, enriched with payment type names.
  Yellow (tpep_*) and green (lpep_*) pickup/dropoff columns are unified into pickup_datetime/dropoff_datetime.

depends:
  - ingestion.trips
  - ingestion.payment_lookup

materialization:
  type: table
  strategy: time_interval
  incremental_key: pickup_datetime
  time_granularity: timestamp

columns:
  - name: pickup_datetime
    type: timestamp
    description: When the meter was engaged
    primary_key: true
    nullable: false
    checks:
      - name: not_null
  - name: dropoff_datetime
    type: timestamp
    description: When the meter was disengaged
    primary_key: true
    nullable: false
    checks:
      - name: not_null
  - name: taxi_type
    type: string
    description: Source taxi type (yellow or green)
    primary_key: true
    nullable: false
    checks:
      - name: not_null
      - name: accepted_values
        value: ["yellow", "green"]
  - name: pickup_location_id
    type: integer
    description: TLC taxi zone where the trip started
    primary_key: true
    nullable: false
    checks:
      - name: not_null
  - name: dropoff_location_id
    type: integer
    description: TLC taxi zone where the trip ended
    primary_key: true
    nullable: false
    checks:
      - name: not_null
  - name: fare_amount
    type: float
    description: Time-and-distance fare calculated by the meter, in USD
    primary_key: true
    checks:
      - name: non_negative
  - name: vendor_id
    type: integer
    description: TPEP/LPEP provider that supplied the record
  - name: passenger_count
    type: integer
    description: Number of passengers, as entered by the driver
  - name: trip_distance
    type: float
    description: Trip distance in miles reported by the meter
    checks:
      - name: non_negative
  - name: rate_code_id
    type: integer
    description: Final rate code in effect at the end of the trip
  - name: store_and_fwd_flag
    type: string
    description: Y if the record was held in vehicle memory before being sent
  - name: payment_type_id
    type: integer
    description: Payment type code
  - name: payment_type_name
    type: string
    description: Payment type name from ingestion.payment_lookup
  - name: extra
    type: float
    description: Miscellaneous extras and surcharges, in USD
  - name: mta_tax
    type: float
    description: MTA tax, in USD
  - name: tip_amount
    type: float
    description: Tip amount (credit card tips only), in USD
  - name: tolls_amount
    type: float
    description: Total tolls paid, in USD
  - name: improvement_surcharge
    type: float
    description: Improvement surcharge, in USD
  - name: congestion_surcharge
    type: float
    description: NYS congestion surcharge, in USD
  - name: total_amount
    type: float
    description: Total amount charged to passengers (excludes cash tips), in USD
    checks:
      - name: non_negative
  - name: extracted_at
    type: timestamp
    description: When the raw record was extracted by ingestion.trips

custom_checks:
  - name: row_count_positive
    description: Ensures the table is not empty
    query: select count(*) > 0 from staging.trips
    value: 1
  - name: no_duplicate_trips
    description: Each composite key appears only once
    query: |
      SELECT COUNT(*)
      FROM (
        SELECT 1
        FROM staging.trips
        GROUP BY pickup_datetime, dropoff_datetime, taxi_type,
                 pickup_location_id, dropoff_location_id, fare_amount
        HAVING COUNT(*) > 1
      )
    value: 0

@bruin */

WITH raw AS (
    SELECT
        -- Yellow uses tpep_*, green uses lpep_*. COLUMNS() only matches columns that exist,
        -- so this works whether ingestion.trips holds yellow, green, or both.
        COALESCE(*COLUMNS('^[lt]pep_pickup_datetime$'))::TIMESTAMP  AS pickup_datetime,
        COALESCE(*COLUMNS('^[lt]pep_dropoff_datetime$'))::TIMESTAMP AS dropoff_datetime,
        taxi_type,
        vendorid::INTEGER        AS vendor_id,
        pulocationid::INTEGER    AS pickup_location_id,
        dolocationid::INTEGER    AS dropoff_location_id,
        passenger_count::INTEGER AS passenger_count,
        trip_distance,
        ratecodeid::INTEGER      AS rate_code_id,
        store_and_fwd_flag,
        payment_type::INTEGER    AS payment_type_id,
        fare_amount,
        extra,
        mta_tax,
        tip_amount,
        tolls_amount,
        improvement_surcharge,
        congestion_surcharge,
        total_amount,
        extracted_at
    FROM ingestion.trips
),

deduped AS (
    SELECT *
    FROM raw
    -- Must match the window Bruin deletes (BETWEEN, inclusive) or boundary rows are lost
    WHERE pickup_datetime BETWEEN '{{ start_datetime }}' AND '{{ end_datetime }}'
    -- Ingestion appends, so re-runs load the same trips again; keep the latest extraction
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY pickup_datetime, dropoff_datetime, taxi_type,
                     pickup_location_id, dropoff_location_id, fare_amount
        ORDER BY extracted_at DESC
    ) = 1
)

SELECT
    t.pickup_datetime,
    t.dropoff_datetime,
    t.taxi_type,
    t.vendor_id,
    t.pickup_location_id,
    t.dropoff_location_id,
    t.passenger_count,
    t.trip_distance,
    t.rate_code_id,
    t.store_and_fwd_flag,
    t.payment_type_id,
    p.payment_type_name,
    t.fare_amount,
    t.extra,
    t.mta_tax,
    t.tip_amount,
    t.tolls_amount,
    t.improvement_surcharge,
    t.congestion_surcharge,
    t.total_amount,
    t.extracted_at
FROM deduped AS t
LEFT JOIN ingestion.payment_lookup AS p
    ON t.payment_type_id = p.payment_type_id
WHERE t.dropoff_datetime IS NOT NULL
  AND t.pickup_location_id IS NOT NULL
  AND t.dropoff_location_id IS NOT NULL
  AND t.dropoff_datetime >= t.pickup_datetime
  -- Negative amounts are refunds/voids; drop them rather than let them skew reports
  AND t.fare_amount >= 0
  AND t.total_amount >= 0
  AND t.trip_distance >= 0
