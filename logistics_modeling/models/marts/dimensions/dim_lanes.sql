{{ config(materialized='table') }}

select
    l.lane_id,
    l.lane_type,
    l.origin_region_id,
    org.region_name        as origin_region_name,
    l.destination_region_id,
    dst.region_name        as destination_region_name
from {{ ref('stg_lanes') }}     l
inner join {{ ref('stg_regions') }} org on l.origin_region_id      = org.region_id
inner join {{ ref('stg_regions') }} dst on l.destination_region_id = dst.region_id
