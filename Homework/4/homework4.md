### Resources
```
https://github.com/DataTalksClub/data-engineering-zoomcamp/blob/main/cohorts/2026/04-analytics-engineering/homework.md
```

### Setup

How to delete all and load everything again:
```sql
-- Check which tables will be removed before actually commiting
SELECT table_name, table_type
FROM `analog-artifact-377402.zoomcamp.INFORMATION_SCHEMA.TABLES`
WHERE STARTS_WITH(table_name, 'fhv_')
   OR STARTS_WITH(table_name, 'green')
   OR STARTS_WITH(table_name, 'yellow');

-- Delete
FOR record IN (
  SELECT table_name
  FROM `analog-artifact-377402.zoomcamp.INFORMATION_SCHEMA.TABLES`
  WHERE STARTS_WITH(table_name, 'fhv_')
     OR STARTS_WITH(table_name, 'green')
     OR STARTS_WITH(table_name, 'yellow')
)
DO
  EXECUTE IMMEDIATE FORMAT(
    'DROP TABLE IF EXISTS `analog-artifact-377402.zoomcamp.%s`',
    record.table_name
  );
END FOR;
```

```
Start Kestra
> docker compose up
Download Green and Yellow taxi data for 2019-2020:
Kestra: http://localhost:8080/
2_1_homework_gcp_taxi_scheduled > Triggers > yellow_schedule > Backfill executions > 2019-01-01 00:00:00 ~ 2020-12-02 00:00:00
2_1_homework_gcp_taxi_scheduled > Triggers > green_schedule > Backfill executions > 2019-01-01 00:00:00 ~ 2020-12-02 00:00:00
Download FHV for 2019:
gcp_fhv_scheduled > Triggers > fhv_schedule > Backfill executions > 2019-01-01 00:00:00 ~ 2019-12-02 00:00:00
> dbt run
```

### 1. Given a dbt project with the following structure... If you run ```dbt run --select int_trips_unioned```, what models will be built?

```
int_trips_unioned only. However, would be different for +int_trips_unioned, int_trips_unioned+ or +int_trips_unioned+
```

### 2. You've configured a generic test like this in your schema.yml... What happens when you run ```dbt test --select fct_trips```?

```
Test will fail because its not expecting the value "6" in "payment_type".

dbt fails the test with non-zero exit code
```

### 3. What is the count of records in the fct_monthly_zone_revenue model?

```
Run row_count_check.sql
-- 12184
```

### 4. Using the fct_monthly_zone_revenue table, find the pickup zone with the highest total revenue (revenue_monthly_total_amount) for Green taxi trips in 2020.

```
Run top_green_revenue_by_pickup_zone.sql
-- East Harlem North
```

### 5. Using the fct_monthly_zone_revenue table, what is the total number of trips (total_monthly_trips) for Green taxis in October 2019?

```
> dbt run -s +green_total_trips
Run green_total_trips.sql
-- 384624
-- 384,624
```

### 6. ...What is the count of records in stg_fhv_tripdata?

```
> dbt run -s +int_count_fhv
Run int_count_fhv.sql
-- 43244693
-- 43,244,693
```
