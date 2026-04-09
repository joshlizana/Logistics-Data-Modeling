{{ config(materialized='table') }}

select
    region_id,
    region_name,
    centroid_latitude,
    centroid_longitude
from {{ ref('stg_regions') }}
