select
    service_date,
    kitchen_id,
    count(*) as row_count
from {{ ref('fct_kitchen_daily_meal_reconciliation') }}
group by
    service_date,
    kitchen_id
having count(*) > 1