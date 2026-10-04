select
    transaction_id,
    meal_qty

from {{ ref('int_tap2eat_valid') }}

where meal_qty <= 0