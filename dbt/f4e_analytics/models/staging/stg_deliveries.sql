select
    delivery_id,
    service_date,
    kitchen_id,
    school_id,
    meals_dispatched,
    meals_received
from {{ source('f4e_raw', 'deliveries') }}