select
    school_id,
    trim(school_name) as school_name,
    trim(county) as county,
    kitchen_id,
    eligible_learners
from {{ source('f4e_raw', 'schools') }}