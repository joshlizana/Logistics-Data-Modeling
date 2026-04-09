{{ config(materialized='table') }}

select
    truck_id,
    unit_number,
    make,
    model_year,
    vin,
    acquisition_date,
    acquisition_mileage,
    fuel_type,
    tank_capacity_gallons,
    status,
    home_terminal,
    YEAR(CURRENT_DATE) - model_year as age_years
from {{ ref('stg_trucks') }}
