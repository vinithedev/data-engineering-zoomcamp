/*
To Do:
- One row per trip (doesn't matter if yellow or green)
- Add a primary key (trip_id) It has to be unique
- Find all the duplicates, understand why they happen, and fix them
- Find a way to enrich the column payment_type

columns:
trip_id
trip_hex
service_type -- color
vendor_id
rate_code_id
pickup_location_id
dropoff_location_id
pickup_datetime
dropoff_datetime
store_and_fwd_flag
passenger_count
trip_distance
trip_type
fare_amount
extra
mta_tax
tip_amount
tolls_amount
ehail_fee
improvement_surcharge
total_amount
payment_type

select distinct -- 1 ~ 5
    payment_type
from final
*/

with trips_unioned as (
    select * from {{ ref('int_trips_unioned') }}
),

zones as (
    select * from {{ ref('dim_zones') }}
),

payments as (
    select distinct
        payment_type,
        {{ get_payment_type('payment_type') }} as payment_type_name
    from trips_unioned
),

deduped as (
    select distinct * from trips_unioned
),

hex as (
    select
        to_hex(md5(concat(
            coalesce(cast(service_type as string), ''), '|',
            coalesce(cast(vendor_id as string), ''), '|',
            coalesce(cast(rate_code_id as string), ''), '|',
            coalesce(cast(pickup_location_id as string), ''), '|',
            coalesce(cast(dropoff_location_id as string), ''), '|',
            coalesce(cast(pickup_datetime as string), ''), '|',
            coalesce(cast(dropoff_datetime as string), ''), '|',
            coalesce(cast(store_and_fwd_flag as string), ''), '|',
            coalesce(cast(passenger_count as string), ''), '|',
            coalesce(cast(trip_distance as string), ''), '|',
            coalesce(cast(trip_type as string), ''), '|',
            coalesce(cast(fare_amount as string), ''), '|',
            coalesce(cast(extra as string), ''), '|',
            coalesce(cast(mta_tax as string), ''), '|',
            coalesce(cast(tip_amount as string), ''), '|',
            coalesce(cast(tolls_amount as string), ''), '|',
            coalesce(cast(ehail_fee as string), ''), '|',
            coalesce(cast(improvement_surcharge as string), ''), '|',
            coalesce(cast(total_amount as string), ''), '|',
            coalesce(cast(payment_type as string), '')
        ))) as trip_hex,
        *
    from deduped
),

final as (
    select
        cast(row_number() over (order by fp.trip_hex) as string) as trip_id,
        fp.service_type,
        fp.vendor_id,
        fp.rate_code_id,
        fp.pickup_location_id,
        pz.borough as pickup_borough,
        pz.zone as pickup_zone,
        fp.dropoff_location_id,
        dz.borough as dropoff_borough,
        dz.zone as dropoff_zone,
        fp.pickup_datetime,
        fp.dropoff_datetime,
        fp.store_and_fwd_flag,
        fp.passenger_count,
        fp.trip_distance,
        fp.trip_type,
        {{ dbt.datediff('fp.pickup_datetime', 'fp.dropoff_datetime', 'minute') }} as trip_duration_minutes,
        fp.fare_amount,
        fp.extra,
        fp.mta_tax,
        fp.tip_amount,
        fp.tolls_amount,
        fp.ehail_fee,
        fp.improvement_surcharge,
        fp.total_amount,
        fp.payment_type,
        p.payment_type_name as payment_type_description
    from hex as fp
    left join zones as pz
        on fp.pickup_location_id = pz.location_id
    left join zones as dz
        on fp.dropoff_location_id = dz.location_id
    left join payments as p
        on fp.payment_type = p.payment_type
)

select * from final