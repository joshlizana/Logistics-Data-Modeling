{{ config(materialized='table') }}

select
    lane_id,
    origin_region_id,
    destination_region_id,
    lane_type
from {{ source('logistics', 'lanes') }}
