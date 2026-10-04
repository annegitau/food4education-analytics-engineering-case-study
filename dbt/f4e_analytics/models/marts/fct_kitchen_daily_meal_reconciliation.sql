with kitchen_flow as (

    select *
    from {{ ref('int_kitchen_daily_meal_flow') }}

),

final as (

    select
        service_date,
        kitchen_id,

        meals_prepared,
        meals_dispatched,

        prepared_to_dispatch_variance,
        dispatch_rate,

        case
            when dispatch_rate < 0.95 then 'review'
            else 'within_threshold'
        end as dispatch_status

    from kitchen_flow

)

select *
from final