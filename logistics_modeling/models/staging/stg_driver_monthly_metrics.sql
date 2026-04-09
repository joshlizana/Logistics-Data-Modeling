{{ config(materialized='table') }}

select
    driver_id,
    month,
    trips_completed,
    total_miles,
    total_revenue,
    average_mpg,
    total_fuel_gallons,
    on_time_delivery_rate,
    average_idle_hours
from {{ source('logistics', 'driver_monthly_metrics') }}
