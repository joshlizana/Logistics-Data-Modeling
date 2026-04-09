{{ config(materialized='table') }}

select
    driver_id,
    driver_full_name,
    first_name,
    last_name,
    hire_date,
    termination_date,
    date_of_birth,
    license_number,
    license_state,
    home_terminal,
    is_terminated,
    cdl_class,
    years_experience,
    DATEDIFF('year', date_of_birth, CURRENT_DATE)                           as age,
    DATEDIFF('year', hire_date, COALESCE(termination_date, CURRENT_DATE))   as tenure_years
from {{ ref('stg_drivers') }}
