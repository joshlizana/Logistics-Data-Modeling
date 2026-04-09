{{ config(materialized='table') }}

select
    r.route_id,
    oc.city_id                      as origin_city_id,
    dc.city_id                      as destination_city_id,
    r.typical_distance_miles,
    r.base_rate_per_mile,
    r.fuel_surcharge_rate,
    r.typical_transit_days,
    r.lane_id
from {{ source('logistics', 'routes') }} r
inner join {{ source('logistics', 'cities') }} oc
    on lower(r.origin_city) = lower(oc.city)
    and lower(r.origin_state) = lower(oc.state)
inner join {{ source('logistics', 'cities') }} dc
    on lower(r.destination_city) = lower(dc.city)
    and lower(r.destination_state) = lower(dc.state)
