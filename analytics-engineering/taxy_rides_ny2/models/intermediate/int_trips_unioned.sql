/*
Dupes:
- all yellow
- 4 rows with dupe count = 2
- 45 rows with dupe count = 45

-- select count(*) from green_tripdata -- 1205959
-- select count(*) from yellow_tripdata -- 51470455
-- select count(*) from trips_unioned -- 52676414
-- select count(*) from (select distinct * from trips_unioned) -- 52676368

dupes as (
    select
        *,
        count(*) over (partition by
            color,
            vendor_id,
            rate_code_id,
            pickup_location_id,
            dropoff_location_id,
            pickup_datetime,
            dropoff_datetime,
            store_and_fwd_flag,
            passenger_count,
            trip_distance,
            trip_type,
            fare_amount,
            extra,
            mta_tax,
            tip_amount,
            tolls_amount,
            ehail_fee,
            improvement_surcharge,
            total_amount,
            payment_type
        ) as exact_dupe_count
    from trips_unioned
)

select *
from dupes
where exact_dupe_count > 1
order by exact_dupe_count
*/

with green_tripdata as (
    select * from {{ ref('stg_green_tripdata') }}
),

yellow_tripdata as (
    select * from {{ ref('stg_yellow_tripdata') }}
),

trips_unioned as (
    select
        'Green' as service_type,
        *
    from green_tripdata
    union all
    select
        'Yellow' as service_type,
        *
    from yellow_tripdata
)

select * from trips_unioned