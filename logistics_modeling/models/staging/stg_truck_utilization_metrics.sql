{{ config(materialized='table') }}

select
    truck_id,
    month,
    trips_completed,
    total_miles,
    total_revenue,
    average_mpg,
    maintenance_events,
    maintenance_cost,
    downtime_hours,
    utilization_rate
from {{ source('logistics', 'truck_utilization_metrics') }}
