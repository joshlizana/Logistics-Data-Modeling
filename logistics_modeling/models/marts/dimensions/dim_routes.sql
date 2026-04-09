{{ config(materialized='table') }}

select
    r.route_id,
    r.lane_id,
    l.lane_type,
    r.origin_city_id,
    oc.city                as origin_city,
    oc.state               as origin_state,
    l.origin_region_id,
    org.region_name        as origin_region_name,
    r.destination_city_id,
    dc.city                as destination_city,
    dc.state               as destination_state,
    l.destination_region_id,
    dst.region_name        as destination_region_name,
    r.typical_distance_miles,
    r.base_rate_per_mile,
    r.fuel_surcharge_rate,
    r.typical_transit_days
from {{ ref('stg_routes') }}  r
inner join {{ ref('stg_lanes') }}              l   on r.lane_id             = l.lane_id
inner join {{ source('logistics', 'cities') }} oc  on r.origin_city_id      = oc.city_id
inner join {{ source('logistics', 'cities') }} dc  on r.destination_city_id  = dc.city_id
inner join {{ ref('stg_regions') }}            org on l.origin_region_id     = org.region_id
inner join {{ ref('stg_regions') }}            dst on l.destination_region_id = dst.region_id
