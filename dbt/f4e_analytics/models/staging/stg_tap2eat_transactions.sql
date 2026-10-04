with source as (

    select *
    from {{ source('f4e_raw', 'tap2eat_transactions') }}

),

deduplicated as (

    select
        transaction_id,
        student_id,
        school_id,
        tap_timestamp,
        meal_qty,
        status,

        row_number() over (
            partition by transaction_id
            order by tap_timestamp desc
        ) as row_num

    from source

),

cleaned as (

    select
        transaction_id,

        -- Pseudonymise the student identifier before it leaves staging.
        to_hex(sha256(student_id)) as student_id_hash,

        school_id,
        tap_timestamp,

        date(tap_timestamp, 'Africa/Nairobi') as service_date,

        meal_qty,
        lower(trim(status)) as status

    from deduplicated

    where row_num = 1

)

select *
from cleaned