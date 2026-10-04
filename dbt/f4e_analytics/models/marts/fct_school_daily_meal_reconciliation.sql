with meal_flow as (

    select *
    from {{ ref('int_school_daily_meal_flow') }}

),

schools as (

    select *
    from {{ ref('stg_schools') }}

),

final as (

    select
        f.service_date,
        f.school_id,
        s.school_name,
        s.county,
        f.kitchen_id,
        s.eligible_learners,

        f.meals_dispatched,
        f.meals_received,
        f.meals_served,

        f.dispatch_to_receipt_variance,
        f.receipt_to_served_variance,

        f.receipt_rate,
        f.serving_rate,

        safe_divide(
            f.meals_served,
            s.eligible_learners
        ) as learner_serving_rate,

        case
            when f.receipt_rate < 0.95 then 'review'
            else 'within_threshold'
        end as delivery_status,

        case
            when f.serving_rate < 0.90 then 'review'
            else 'within_threshold'
        end as serving_status

    from meal_flow f

    left join schools s
        on f.school_id = s.school_id

)

select *
from final