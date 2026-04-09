{{ config(materialized='table') }}

with origin_trips as (
    select
        origin_region_id    as region_id,
        'origin'            as direction,
        trip_id,
        route_id,
        lane_id,
        total_revenue,
        net_revenue_after_fuel,
        total_detention_minutes,
        estimated_detention_cost
    from {{ ref('fct_route_trips') }}
),

destination_trips as (
    select
        destination_region_id as region_id,
        'destination'         as direction,
        trip_id,
        route_id,
        lane_id,
        total_revenue,
        net_revenue_after_fuel,
        total_detention_minutes,
        estimated_detention_cost
    from {{ ref('fct_route_trips') }}
    where lane_type = 'over_the_road'
),

combined as (
    select * from origin_trips
    union all
    select * from destination_trips
),

region_agg as (
    select
        region_id,
        COUNT(*) FILTER (WHERE direction = 'origin')       as total_trips_as_origin,
        COUNT(*) FILTER (WHERE direction = 'destination')   as total_trips_as_destination,
        COUNT(*)                                            as total_trips,
        SUM(total_revenue) FILTER (WHERE direction = 'origin')
                                                            as total_revenue_as_origin,
        SUM(total_revenue) FILTER (WHERE direction = 'destination')
                                                            as total_revenue_as_destination,
        SUM(total_revenue)                                  as total_revenue,
        SUM(net_revenue_after_fuel)                         as total_net_revenue_after_fuel,
        SUM(total_detention_minutes)                        as total_detention_minutes,
        SUM(estimated_detention_cost)                       as total_estimated_detention_cost,
        COUNT(DISTINCT route_id)                            as unique_routes,
        COUNT(DISTINCT lane_id)                             as unique_lanes
    from combined
    group by region_id
)

select
    region_id,
    total_trips_as_origin,
    total_trips_as_destination,
    total_trips,
    total_revenue_as_origin,
    total_revenue_as_destination,
    total_revenue,
    total_net_revenue_after_fuel,
    total_net_revenue_after_fuel / NULLIF(total_revenue, 0) as net_revenue_after_fuel_pct,
    total_detention_minutes,
    total_estimated_detention_cost,
    unique_routes,
    unique_lanes
from region_agg
