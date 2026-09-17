with monthly_zone_revenue as (
    select * from {{ ref('fct_monthly_zone_revenue') }}
),

filtered as (
    select
        pickup_zone,
        sum(revenue_monthly_total_amount) as sum_amount
    from monthly_zone_revenue
    where 1=1
    and service_type = 'Green'
    and extract(year from revenue_month) = 2020
    group by pickup_zone
    order by sum_amount desc
),

ranked as (
    select
        pickup_zone,
        sum_amount,
        ROW_NUMBER() OVER (ORDER BY sum_amount DESC) AS rank
    from filtered
)

select * from ranked