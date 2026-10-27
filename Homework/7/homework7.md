### Resources
```
https://github.com/DataTalksClub/data-engineering-zoomcamp/blob/main/cohorts/2026/07-streaming/homework.md
https://d37ci6vzurychx.cloudfront.net/trip-data/green_tripdata_2025-10.parquet
```

### Setup
```bash
> cd streaming
> docker compose down -v
> docker compose build
> docker compose up -d

This gives us:
    Redpanda (Kafka-compatible broker) on localhost:9092
    Flink Job Manager at http://localhost:8081
    Flink Task Manager
    PostgreSQL on localhost:5432 (user: postgres, password: postgres)
```

### 1. What version of Redpanda are you running?
```bash
> docker compose exec redpanda rpk version
rpk version: v25.3.9

v25.3.9
```

### 2. How long did it take to send the data?
```bash
> docker exec -it streaming-redpanda-1 rpk topic create green-trips
> uv run python src/producers/producer_green.py
sent 49416 rows
took 3.01 seconds
10 seconds
```

### 3. How many trips have trip_distance > 5?
```bash
> uv run python src/consumers/consumer_green.py
read 49416 trips
trips with trip_distance > 5: 8506
8506
```

### 4. Which PULocationID had the most trips in a single 5-minute window?
```bash
Terminal 1:
> docker exec -it streaming-postgres-1 psql -U postgres -c "CREATE TABLE green_pickup_5min (window_start TIMESTAMP, PULocationID INT, num_trips BIGINT, PRIMARY KEY (window_start, PULocationID));"
> MSYS_NO_PATHCONV=1 docker exec -it streaming-jobmanager-1 flink run -py /opt/src/job/green_tumbling_job.py

Terminal 2:
> docker exec -it streaming-postgres-1 psql -U postgres -c "SELECT PULocationID, num_trips FROM green_pickup_5min ORDER BY num_trips DESC LIMIT 3;"
 pulocationid | num_trips 
--------------+-----------
           74 |        15
           74 |        14
           74 |        13

74
```

### 5. How many trips were in the longest session?
```bash
Terminal 1:
> docker exec -it streaming-postgres-1 psql -U postgres -c "CREATE TABLE green_pickup_sessions (window_start TIMESTAMP, window_end TIMESTAMP, PULocationID INT, num_trips BIGINT, PRIMARY KEY (window_start, window_end, PULocationID));"
> MSYS_NO_PATHCONV=1 docker exec -it streaming-jobmanager-1 flink run -py /opt/src/job/green_session_job.py

Terminal 2:
> docker exec -it streaming-postgres-1 psql -U postgres -c "SELECT PULocationID, window_start, window_end, num_trips FROM green_pickup_sessions ORDER BY num_trips DESC LIMIT 5;"

 pulocationid |    window_start     |     window_end      | num_trips 
--------------+---------------------+---------------------+-----------
           74 | 2025-10-08 06:46:14 | 2025-10-08 08:27:40 |        81
           74 | 2025-10-01 06:52:23 | 2025-10-01 08:23:33 |        72
           74 | 2025-10-28 08:31:08 | 2025-10-28 09:39:30 |        71
           74 | 2025-10-22 06:58:31 | 2025-10-22 08:25:04 |        71
           74 | 2025-10-27 06:56:30 | 2025-10-27 08:24:09 |        70

81
```

### 6. Which hour had the highest total tip amount?
```bash
Terminal 1:
> docker exec -it streaming-postgres-1 psql -U postgres -c "CREATE TABLE green_hourly_tips (window_start TIMESTAMP PRIMARY KEY, total_tip_amount DOUBLE PRECISION);"
> MSYS_NO_PATHCONV=1 docker exec -it streaming-jobmanager-1 flink run -py /opt/src/job/green_hourly_tips_job.py

Terminal 2:
docker exec -it streaming-postgres-1 psql -U postgres -c "SELECT window_start, ROUND(total_tip_amount::numeric, 2) AS total_tips FROM green_hourly_tips ORDER BY total_tip_amount DESC LIMIT 3;"

    window_start     | total_tips 
---------------------+------------
 2025-10-16 18:00:00 |     524.96
 2025-10-30 16:00:00 |     507.10
 2025-10-10 17:00:00 |     499.60

2025-10-16 18:00:00
```
