{{ config(materialized='table') }}

select
    trailer_id,
    trailer_number,
    trailer_type,
    length_feet,
    model_year,
    vin,
    acquisition_date,
    status,
    current_location,
    YEAR(CURRENT_DATE) - model_year as age_years
from {{ ref('stg_trailers') }}
