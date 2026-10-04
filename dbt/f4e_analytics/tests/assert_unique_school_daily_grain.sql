select
    service_date,
    school_id,
    kitchen_id,
    count(*) as row_count

from {{ ref('fct_school_daily_meal_reconciliation') }}

group by
    service_date,
    school_id,
    kitchen_id

having count(*) > 1