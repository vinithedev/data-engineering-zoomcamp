select
    -- identifiers
    unique_row_id as fhv_id,
    filename,
    dispatching_base_num,
    cast(PUlocationID as int) as pickup_location_id,
    cast(DOlocationID as int) as dropoff_location_id,
    Affiliated_base_number as affiliated_base_number,

     -- timestamps
    cast(pickup_datetime as timestamp) as pickup_datetime,
    cast(dropOff_datetime as timestamp) as dropOff_datetime,
    
    -- info
    SR_Flag as sr_flag

from {{ source('raw_data', 'fhv_tripdata') }}
where dispatching_base_num is not null
