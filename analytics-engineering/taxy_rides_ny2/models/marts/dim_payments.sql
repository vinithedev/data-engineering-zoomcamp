with trips_unioned as (
    select * from {{ ref('int_trips_unioned') }}
),

payments as (
    select
        distinct payment_type,
        {{ get_payment_type('payment_type') }} as payment_type_name
    from trips_unioned
)

select * from payments