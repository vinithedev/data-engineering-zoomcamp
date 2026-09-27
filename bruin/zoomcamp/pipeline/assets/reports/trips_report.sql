/* @bruin
name: reports.trips_report
type: duckdb.sql
description: Daily trip volume, distance and revenue per taxi type and payment type.

depends:
  - staging.trips

# trip_date is the day of staging's incremental_key (pickup_datetime), so both layers
# reprocess the same window.
materialization:
  type: table
  strategy: time_interval
  incremental_key: trip_date
  time_granularity: date

columns:
  - name: trip_date
    type: DATE
    description: Pickup date
    primary_key: true
    nullable: false
    checks:
      - name: not_null
  - name: taxi_type
    type: VARCHAR
    description: Taxi type (yellow or green)
    primary_key: true
    nullable: false
    checks:
      - name: not_null
      - name: accepted_values
        value: ["yellow", "green"]
  - name: payment_type_name
    type: VARCHAR
    description: Payment type name, 'unknown' when missing or unmapped
    primary_key: true
    nullable: false
    checks:
      - name: not_null
  - name: trip_count
    type: BIGINT
    description: Number of trips
    checks:
      - name: positive
  - name: total_passengers
    type: BIGINT
    description: Sum of passenger_count (trips with no count are excluded)
    checks:
      - name: non_negative
  - name: total_distance
    type: DOUBLE
    description: Sum of trip distance in miles
    checks:
      - name: non_negative
  - name: total_fare
    type: DOUBLE
    description: Sum of metered fares, in USD
    checks:
      - name: non_negative
  - name: total_tips
    type: DOUBLE
    description: Sum of tips, in USD
  - name: total_revenue
    type: DOUBLE
    description: Sum of total_amount, in USD
    checks:
      - name: non_negative
  - name: avg_fare
    type: DOUBLE
    description: Average metered fare per trip, in USD
    checks:
      - name: non_negative
  - name: avg_trip_distance
    type: DOUBLE
    description: Average trip distance in miles
    checks:
      - name: non_negative
  - name: avg_trip_duration_minutes
    type: DOUBLE
    description: Average minutes between pickup and dropoff
    checks:
      - name: non_negative

custom_checks:
  - name: unique_report_grain
    description: One row per trip_date, taxi_type and payment_type_name
    query: |
      SELECT COUNT(*)
      FROM (
        SELECT 1
        FROM reports.trips_report
        GROUP BY trip_date, taxi_type, payment_type_name
        HAVING COUNT(*) > 1
      )
    value: 0

@bruin */

-- Filters on whole days to match the window Bruin deletes (trip_date BETWEEN start_date AND end_date)
SELECT
    CAST(pickup_datetime AS DATE)           AS trip_date,
    taxi_type,
    COALESCE(payment_type_name, 'unknown')  AS payment_type_name,
    COUNT(*)                                AS trip_count,
    SUM(passenger_count)                    AS total_passengers,
    SUM(trip_distance)                      AS total_distance,
    SUM(fare_amount)                        AS total_fare,
    SUM(tip_amount)                         AS total_tips,
    SUM(total_amount)                       AS total_revenue,
    AVG(fare_amount)                        AS avg_fare,
    AVG(trip_distance)                      AS avg_trip_distance,
    AVG(date_diff('second', pickup_datetime, dropoff_datetime)) / 60.0 AS avg_trip_duration_minutes
FROM staging.trips
WHERE CAST(pickup_datetime AS DATE) BETWEEN '{{ start_date }}' AND '{{ end_date }}'
GROUP BY 1, 2, 3
