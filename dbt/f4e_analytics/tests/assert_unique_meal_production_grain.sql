select
    service_date,
    kitchen_id,
    count(*) as row_count

from {{ ref('stg_meal_production') }}

group by
    service_date,
    kitchen_id

having count(*) > 1