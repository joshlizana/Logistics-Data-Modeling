{{ config(materialized='table') }}

select
    region_id,
    region_name,
    centroid_latitude,
    centroid_longitude
from {{ source('logistics', 'regions') }}
