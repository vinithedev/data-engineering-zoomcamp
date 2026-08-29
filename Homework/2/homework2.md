### Resources
```
https://github.com/DataTalksClub/data-engineering-zoomcamp/blob/main/cohorts/2026/02-workflow-orchestration/homework.md
https://github.com/DataTalksClub/nyc-tlc-data/releases/tag/green/download
https://github.com/DataTalksClub/nyc-tlc-data/releases/download/green/
```

### Start Kestra
```bash
> docker compose up

# Kestra http://localhost:8080/
```

### 1. Within the execution for Yellow Taxi data for the year 2020 and month 12: what is the uncompressed file size (i.e. the output file yellow_tripdata_2020-12.csv of the extract task)?
```
2_1_homework_gcp_taxi_scheduled > Triggers > yellow_schedule > Backfill executions > 2020-12-01 00:00:00 ~ 2020-12-02 00:00:00

Check status if its running or done: Executions

Click execution id > Outputs > check_size > size > 134481400 > 134481400 / 1024 / 1024 = 128.251

128.3MB
```

### 2. What is the rendered value of the variable file when the inputs taxi is set to green, year is set to 2020, and month is set to 04 during execution?
```
2_1_homework_gcp_taxi_scheduled > Triggers > green_schedule > Backfill executions > 2020-04-01 00:00:00 ~ 2020-04-02 00:00:00

Check status if its running or done: Executions

Click execution id > Outputs > extract > outputFiles > green_tripdata_2020-04.csv
```

### 3. How many rows are there for the Yellow Taxi data for all CSV files in the year 2020?
```
2_1_homework_gcp_taxi_scheduled > Triggers > yellow_schedule > Backfill executions > 2020-01-01 00:00:00 ~ 2020-12-02 00:00:00

In BigQuery:
Can't use wildcards and _TABLE_SUFFIX, we do this instead:
```

```sql
SELECT
  (SELECT COUNT(1) FROM `analog-artifact-377402.zoomcamp.yellow_tripdata_2020_01`) +
  (SELECT COUNT(1) FROM `analog-artifact-377402.zoomcamp.yellow_tripdata_2020_02`) +
  (SELECT COUNT(1) FROM `analog-artifact-377402.zoomcamp.yellow_tripdata_2020_03`) +
  (SELECT COUNT(1) FROM `analog-artifact-377402.zoomcamp.yellow_tripdata_2020_04`) +
  (SELECT COUNT(1) FROM `analog-artifact-377402.zoomcamp.yellow_tripdata_2020_05`) +
  (SELECT COUNT(1) FROM `analog-artifact-377402.zoomcamp.yellow_tripdata_2020_06`) +
  (SELECT COUNT(1) FROM `analog-artifact-377402.zoomcamp.yellow_tripdata_2020_07`) +
  (SELECT COUNT(1) FROM `analog-artifact-377402.zoomcamp.yellow_tripdata_2020_08`) +
  (SELECT COUNT(1) FROM `analog-artifact-377402.zoomcamp.yellow_tripdata_2020_09`) +
  (SELECT COUNT(1) FROM `analog-artifact-377402.zoomcamp.yellow_tripdata_2020_10`) +
  (SELECT COUNT(1) FROM `analog-artifact-377402.zoomcamp.yellow_tripdata_2020_11`) +
  (SELECT COUNT(1) FROM `analog-artifact-377402.zoomcamp.yellow_tripdata_2020_12`)
  AS total_rows

-- 24648499
-- 24,648,499
```

### 4. How many rows are there for the Green Taxi data for all CSV files in the year 2020?
```
2_1_homework_gcp_taxi_scheduled > Triggers > green_schedule > Backfill executions > 2020-01-01 00:00:00 ~ 2020-12-02 00:00:00
```

```sql
SELECT
  (SELECT COUNT(1) FROM `analog-artifact-377402.zoomcamp.green_tripdata_2020_01`) +
  (SELECT COUNT(1) FROM `analog-artifact-377402.zoomcamp.green_tripdata_2020_02`) +
  (SELECT COUNT(1) FROM `analog-artifact-377402.zoomcamp.green_tripdata_2020_03`) +
  (SELECT COUNT(1) FROM `analog-artifact-377402.zoomcamp.green_tripdata_2020_04`) +
  (SELECT COUNT(1) FROM `analog-artifact-377402.zoomcamp.green_tripdata_2020_05`) +
  (SELECT COUNT(1) FROM `analog-artifact-377402.zoomcamp.green_tripdata_2020_06`) +
  (SELECT COUNT(1) FROM `analog-artifact-377402.zoomcamp.green_tripdata_2020_07`) +
  (SELECT COUNT(1) FROM `analog-artifact-377402.zoomcamp.green_tripdata_2020_08`) +
  (SELECT COUNT(1) FROM `analog-artifact-377402.zoomcamp.green_tripdata_2020_09`) +
  (SELECT COUNT(1) FROM `analog-artifact-377402.zoomcamp.green_tripdata_2020_10`) +
  (SELECT COUNT(1) FROM `analog-artifact-377402.zoomcamp.green_tripdata_2020_11`) +
  (SELECT COUNT(1) FROM `analog-artifact-377402.zoomcamp.green_tripdata_2020_12`)
  AS total_rows

-- 1734051
-- 1,734,051
```

### 5. How many rows are there for the Yellow Taxi data for the March 2021 CSV file?
```
2_1_homework_gcp_taxi_scheduled > Triggers > yellow_schedule > Backfill executions > 2021-03-01 00:00:00 ~ 2021-03-02 00:00:00
```

```sql
SELECT COUNT(1) as total_rows
FROM `analog-artifact-377402.zoomcamp.yellow_tripdata_2021_03`

-- 1925152
-- 1,925,152
```

### 6. How would you configure the timezone to New York in a Schedule trigger?
```
timezone: America/New_York

Add a timezone property set to America/New_York in the Schedule trigger configuration 
```
