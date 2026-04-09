{{ config(materialized='table') }}

select
    event_id,
    load_id,
    trip_id,
    event_type,
    facility_id,
    scheduled_datetime,
    actual_datetime,
    detention_minutes,
    on_time_flag
from {{ source('logistics', 'delivery_events') }}
