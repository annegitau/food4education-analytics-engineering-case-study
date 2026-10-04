with production as (

    select
        service_date,
        kitchen_id,
        sum(meals_prepared) as meals_prepared

    from {{ ref('stg_meal_production') }}

    group by
        service_date,
        kitchen_id

),

dispatches as (

    select
        service_date,
        kitchen_id,
        sum(meals_dispatched) as meals_dispatched

    from {{ ref('stg_deliveries') }}

    group by
        service_date,
        kitchen_id

),

reconciled as (

    select
        p.service_date,
        p.kitchen_id,

        p.meals_prepared,
        coalesce(d.meals_dispatched, 0) as meals_dispatched,

        p.meals_prepared - coalesce(d.meals_dispatched, 0)
            as prepared_to_dispatch_variance,

        safe_divide(
            coalesce(d.meals_dispatched, 0),
            p.meals_prepared
        ) as dispatch_rate

    from production p

    left join dispatches d
        on p.service_date = d.service_date
        and p.kitchen_id = d.kitchen_id

)

select *
from reconciled