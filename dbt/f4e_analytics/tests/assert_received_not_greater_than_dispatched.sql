select
    delivery_id,
    service_date,
    school_id,
    meals_dispatched,
    meals_received

from {{ ref('stg_deliveries') }}

where meals_received > meals_dispatched