select
    transaction_id,
    student_id_hash,
    school_id,
    tap_timestamp,
    service_date,
    meal_qty,
    status,
    quality_issue
from {{ ref('int_tap2eat_quality') }}
where not is_valid