with transactions as (

    select *
    from {{ ref('stg_tap2eat_transactions') }}

),

schools as (

    select
        school_id
    from {{ source('f4e_raw', 'schools') }}

),

evaluated as (

    select
        t.*,

        case
            when t.school_id is null then false
            when s.school_id is null then false
            when t.meal_qty <= 0 then false
            else true
        end as is_valid,

        case
            when t.school_id is null then 'missing_school_id'
            when s.school_id is null then 'unknown_school_id'
            when t.meal_qty <= 0 then 'invalid_meal_quantity'
            else null
        end as quality_issue

    from transactions t

    left join schools s
        on t.school_id = s.school_id

)

select *
from evaluated