{{ config(materialized='table') }}

select
    trip_id,
    load_id,
    driver_id,
    truck_id,
    trailer_id,
    dispatch_date,
    actual_distance_miles,
    actual_duration_hours,
    fuel_gallons_used,
    average_mpg,
    idle_time_hours,
    trip_status
from {{ source('logistics', 'trips') }}
