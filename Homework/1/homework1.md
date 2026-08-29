### Resources
```
https://github.com/DataTalksClub/data-engineering-zoomcamp/blob/main/cohorts/2026/01-docker-terraform/homework.md
```

### Start Postgres and pgadmin
```bash
> docker run -it --rm \
  -e POSTGRES_USER="root" \
  -e POSTGRES_PASSWORD="root" \
  -e POSTGRES_DB="ny_taxi" \
  -v ny_taxi_postgres_data:/var/lib/postgresql \
  -p 5432:5432 \
  --network=pg-network \
  --name pgdatabase \
  postgres:18

> docker run -it \
  -e PGADMIN_DEFAULT_EMAIL="admin@admin.com" \
  -e PGADMIN_DEFAULT_PASSWORD="root" \
  -v pgadmin_data:/var/lib/pgadmin \
  -p 8085:80 \
  --network=pg-network \
  --name pgadmin \
  dpage/pgadmin4

# pgadmin http://localhost:8085/
```

### 1. What's the version of pip in the python:3.13 image?
```bash
> docker run -it --entrypoint=bash python:3.13.11-slim
> pip -V
> pip 25.3 from /usr/local/lib/python3.13/site-packages/pip (python 3.13)
```

### 2. What is the hostname and port that pgadmin should use to connect to the postgres database?
```yaml
services:
  db:
    ports:
      - '5433:5432'
      
db:5432
```

### 3. For the trips in November 2025 (lpep_pickup_datetime between '2025-11-01' and '2025-12-01', exclusive of the upper bound), how many trips had a trip_distance of less than or equal to 1 mile?
```bash
> curl -O https://d37ci6vzurychx.cloudfront.net/trip-data/green_tripdata_2025-11.parquet
> curl -L -O https://github.com/DataTalksClub/nyc-tlc-data/releases/download/misc/taxi_zone_lookup.csv
```
```
Check homework1.3.ipynb jupyter file to see how I imported the data to the database
```
```sql
select count(1)
from public.green_taxi_data
where lpep_pickup_datetime between '2025-11-01' and '2025-12-01'
and trip_distance <= 1;

-- 8007
```

### 4. Which was the pick up day with the longest trip distance? Only consider trips with trip_distance less than 100 miles (to exclude data errors). Use the pick up time for your calculations.
```sql
select
    lpep_pickup_datetime::date as pickup_date,
    max(trip_distance) as trip_distance
from public.green_taxi_data
where 1=1
and trip_distance < 100
and lpep_pickup_datetime::date in ('2025-11-14','2025-11-20','2025-11-23','2025-11-25')
group by lpep_pickup_datetime::date
order by max(trip_distance) desc;

-- 2025-11-14
```

### 5. Which was the pickup zone with the largest total_amount (sum of all trips) on November 18th, 2025?
```sql
select
  tzl."Zone" as pickup_zone,
  sum(gtd.total_amount) as total_amount
from public.green_taxi_data gtd
join public.taxi_zone_lookup tzl
	on tzl."LocationID" = gtd."PULocationID"
where 1=1
and gtd.lpep_pickup_datetime::date = '2025-11-18'
and tzl."Zone" in ('East Harlem North','East Harlem South','Morningside Heights','Forest Hills')
group by tzl."Zone"
order by sum(gtd.total_amount) desc;

-- East Harlem North
```

### 6. For the passengers picked up in the zone named "East Harlem North" in November 2025, which was the drop off zone that had the largest tip?
```sql
select
	tzl_dropoff."Zone" as dropoff_zone,
	gtd.tip_amount
from public.green_taxi_data gtd
join public.taxi_zone_lookup tzl
	on tzl."LocationID" = gtd."PULocationID"
join public.taxi_zone_lookup tzl_dropoff
	on tzl_dropoff."LocationID" = gtd."DOLocationID"
where 1=1
and tzl."Zone" = 'East Harlem North'
and gtd.lpep_pickup_datetime::date between '2025-11-01' and '2025-11-30'
order by gtd.tip_amount desc
limit 1;

-- Yorkville West
```

### 7. Which of the following sequences, respectively, describes the workflow
```bash
> terraform init
> terraform apply -auto-approve
> terraform destroy
```