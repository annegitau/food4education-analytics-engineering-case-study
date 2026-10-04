select
    (select count(*) from {{ ref('int_tap2eat_valid') }}) as valid_rows,
    (select count(*) from {{ ref('int_tap2eat_quarantine') }}) as quarantined_rows