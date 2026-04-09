{{ config(materialized='table') }}

select
    route_id,

    MIN(dispatch_date)                                                            as first_trip_date,
    MAX(dispatch_date)                                                            as last_trip_date,
    COUNT(*)                                                                      as total_trips,
    COUNT(*) FILTER (WHERE load_status = 'Completed')                             as trips_completed,
    SUM(total_revenue)                                                            as total_revenue,
    SUM(fuel_cost_total)                                                          as total_fuel_cost,
    SUM(net_revenue_after_fuel)                                                   as total_net_revenue_after_fuel,
    SUM(net_revenue_after_fuel) / NULLIF(SUM(total_revenue), 0)                   as net_revenue_after_fuel_pct,
    SUM(weight_lbs)                                                               as total_weight_lbs,
    SUM(total_detention_minutes)                                                  as total_detention_minutes,
    SUM(estimated_detention_cost)                                                 as total_estimated_detention_cost,
    SUM(total_revenue)
        / NULLIF(SUM(COALESCE(actual_distance_miles, typical_distance_miles)), 0) as revenue_per_mile,
    SUM(actual_distance_miles) / NULLIF(SUM(actual_duration_hours), 0)            as avg_mph,
    SUM(distance_variance_miles) / NULLIF(SUM(typical_distance_miles), 0)         as distance_variance_pct

from {{ ref('fct_route_trips') }}
group by route_id
