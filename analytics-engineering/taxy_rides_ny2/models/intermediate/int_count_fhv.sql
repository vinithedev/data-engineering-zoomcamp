with fhv as (
    select * from {{ ref('stg_fhv_tripdata') }}
)

-- count(*) -- 43244693
select * from fhv