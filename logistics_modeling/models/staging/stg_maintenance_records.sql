{{ config(materialized='table') }}

select
    maintenance_id,
    truck_id,
    maintenance_date,
    maintenance_type,
    odometer_reading,
    labor_hours,
    labor_cost,
    parts_cost,
    total_cost,
    facility_location,
    downtime_hours,
    service_description
from {{ source('logistics', 'maintenance_records') }}
