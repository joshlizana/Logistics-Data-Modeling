{{ config(materialized='table') }}

select
    incident_id,
    trip_id,
    truck_id,
    driver_id,
    incident_date,
    incident_type,
    location_city,
    location_state,
    at_fault_flag,
    injury_flag,
    vehicle_damage_cost,
    cargo_damage_cost,
    claim_amount,
    preventable_flag,
    description
from {{ source('logistics', 'safety_incidents') }}
