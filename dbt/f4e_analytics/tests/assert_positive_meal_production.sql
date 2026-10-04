select
    service_date,
    kitchen_id,
    meals_prepared

from {{ ref('stg_meal_production') }}

where meals_prepared <= 0