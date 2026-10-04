with deliveries as (

    select
        service_date,
        school_id,
        kitchen_id,
        sum(meals_dispatched) as meals_dispatched,
        sum(meals_received) as meals_received

    from {{ ref('stg_deliveries') }}

    group by
        service_date,
        school_id,
        kitchen_id

),

served as (

    select
        service_date,
        school_id,
        sum(meal_qty) as meals_served

    from {{ ref('int_tap2eat_valid') }}

    where status = 'success'

    group by
        service_date,
        school_id

),

reconciled as (

    select
        d.service_date,
        d.school_id,
        d.kitchen_id,

        d.meals_dispatched,
        d.meals_received,
        coalesce(s.meals_served, 0) as meals_served,

        d.meals_dispatched - d.meals_received
            as dispatch_to_receipt_variance,

        d.meals_received - coalesce(s.meals_served, 0)
            as receipt_to_served_variance,

        safe_divide(
            d.meals_received,
            d.meals_dispatched
        ) as receipt_rate,

        safe_divide(
            coalesce(s.meals_served, 0),
            d.meals_received
        ) as serving_rate

    from deliveries d

    left join served s
        on d.service_date = s.service_date
        and d.school_id = s.school_id

)

select *
from reconciled