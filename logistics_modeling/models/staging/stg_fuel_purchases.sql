{{ config(materialized='table') }}

select
    fuel_purchase_id,
    trip_id,
    truck_id,
    driver_id,
    purchase_date,
    location_city,
    location_state,
    gallons,
    price_per_gallon,
    total_cost,
    fuel_card_number
from {{ source('logistics', 'fuel_purchases') }}
