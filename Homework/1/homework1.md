https://github.com/DataTalksClub/data-engineering-zoomcamp/blob/main/cohorts/2026/01-docker-terraform/homework.md

1. What's the version of pip in the python:3.13 image?
docker run -it --entrypoint=bash python:3.13.11-slim
pip -V
pip 25.3 from /usr/local/lib/python3.13/site-packages/pip (python 3.13)

2.
services:
  db:
    ports:
      - '5433:5432'
      
db:5432

3.
curl -O https://d37ci6vzurychx.cloudfront.net/trip-data/green_tripdata_2025-11.parquet
curl -L -O https://github.com/DataTalksClub/nyc-tlc-data/releases/download/misc/taxi_zone_lookup.csv

select count(1)
from public.green_taxi_data
where lpep_pickup_datetime between '2025-11-01' and '2025-12-01'
and trip_distance <= 1;

8007

4.
select
    lpep_pickup_datetime::date as pickup_date,
    max(trip_distance) as trip_distance
from public.green_taxi_data
where 1=1
and trip_distance < 100
and lpep_pickup_datetime::date in ('2025-11-14','2025-11-20','2025-11-23','2025-11-25')
group by lpep_pickup_datetime::date
order by max(trip_distance) desc;

2025-11-14

5.
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

East Harlem North

6.
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

Yorkville West

7.
terraform init, terraform apply -auto-approve, terraform destroy