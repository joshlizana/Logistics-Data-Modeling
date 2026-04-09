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
    current_location
from {{ source('logistics', 'trailers') }}
