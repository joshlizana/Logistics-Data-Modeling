{{ config(materialized='table') }}

select
    driver_id,
    first_name || ' ' || last_name  as driver_full_name,
    first_name,
    last_name,
    hire_date,
    termination_date,
    date_of_birth,
    license_number,
    license_state,
    home_terminal,
    employment_status = 'Terminated' as is_terminated,
    cdl_class,
    years_experience
from {{ source('logistics', 'drivers') }}
