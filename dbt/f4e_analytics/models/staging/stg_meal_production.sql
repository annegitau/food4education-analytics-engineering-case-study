select
    service_date,
    kitchen_id,
    meals_prepared
from {{ source('f4e_raw', 'meal_production') }}