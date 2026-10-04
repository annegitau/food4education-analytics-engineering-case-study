select
    transaction_id,
    student_id_hash,
    school_id,
    tap_timestamp,
    service_date,
    meal_qty,
    status
from {{ ref('int_tap2eat_quality') }}
where is_valid