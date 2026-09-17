with monthly_zone_revenue as (
    select * from {{ ref('fct_monthly_zone_revenue') }}
),

filtered as (
    select
        sum(total_monthly_trips) as sum_trips
    from monthly_zone_revenue
    where 1=1
    and service_type = 'Green'
    and extract(year from revenue_month) = 2019
    and extract(month from revenue_month) = 10
)

select * from filtered