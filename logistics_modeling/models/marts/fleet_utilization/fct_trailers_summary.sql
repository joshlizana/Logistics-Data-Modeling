{{ config(materialized='table') }}

select
    trailer_id,

    MIN(dispatch_date)                                                            as first_trip_date,
    MAX(dispatch_date)                                                            as last_trip_date,
    COUNT(*)                                                                      as total_trips,
    COUNT(*) FILTER (WHERE trip_status = 'Completed')                             as trips_completed,
    SUM(actual_distance_miles)                                                    as total_miles,
    SUM(total_revenue)                                                            as total_revenue,
    SUM(weight_lbs)                                                               as total_weight_lbs,
    COUNT(*) FILTER (WHERE trailer_type = 'Dry Van')                              as dry_van_trips,
    COUNT(*) FILTER (WHERE trailer_type = 'Refrigerated')                         as refrigerated_trips,
    SUM(total_revenue)
        / NULLIF(SUM(COALESCE(actual_distance_miles, typical_distance_miles)), 0) as revenue_per_mile,
    SUM(total_revenue)
        / NULLIF(DATEDIFF('day', MIN(dispatch_date), MAX(dispatch_date)), 0)      as avg_daily_revenue

from {{ ref('fct_fleet_trips') }}
group by trailer_id
