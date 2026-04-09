{{ config(materialized='table') }}

with delivery_events as (
    select
        trip_id,
        SUM(on_time_flag::int) FILTER (WHERE event_type = 'Delivery')  as deliveries_on_time,
        COUNT(*) FILTER (WHERE event_type = 'Delivery')                as total_deliveries,
        SUM(on_time_flag::int) FILTER (WHERE event_type = 'Pickup')    as pickups_on_time,
        COUNT(*) FILTER (WHERE event_type = 'Pickup')                  as total_pickups,
        SUM(detention_minutes)                                         as total_detention_minutes
    from {{ ref('stg_delivery_events') }}
    group by trip_id
),

fuel_purchases as (
    select
        trip_id,
        COUNT(*)              as fuel_stops,
        SUM(total_cost)       as fuel_cost_total,
        AVG(price_per_gallon) as fuel_cost_per_gallon_avg
    from {{ ref('stg_fuel_purchases') }}
    group by trip_id
),

safety_incidents as (
    select
        trip_id,
        COUNT(*)                                                     as incident_count,
        SUM(at_fault_flag::int)                                      as at_fault_count,
        SUM(preventable_flag::int)                                   as preventable_count,
        SUM(injury_flag::int)                                        as injury_count,
        SUM(vehicle_damage_cost + cargo_damage_cost + claim_amount)  as total_incident_cost
    from {{ ref('stg_safety_incidents') }}
    group by trip_id
)

select
    t.trip_id,
    t.load_id,
    t.driver_id,
    t.truck_id,
    t.trailer_id,
    t.dispatch_date,
    t.dispatch_month,
    t.driver_full_name,
    t.cdl_class,
    t.years_experience,
    t.driver_home_terminal                                             as home_terminal,
    t.actual_distance_miles,
    t.actual_duration_hours,
    t.fuel_gallons_used,
    t.average_mpg,
    t.idle_time_hours,
    t.typical_distance_miles,
    t.trip_status,
    t.total_revenue,
    t.revenue_per_mile,

    de.deliveries_on_time,
    de.total_deliveries,
    de.pickups_on_time,
    de.total_pickups,
    de.total_detention_minutes,

    fp.fuel_stops,
    fp.fuel_cost_total,
    fp.fuel_cost_per_gallon_avg,

    si.incident_count,
    si.at_fault_count,
    si.preventable_count,
    si.injury_count,
    si.total_incident_cost,

    de.deliveries_on_time::float / NULLIF(de.total_deliveries, 0)      as on_time_delivery_pct,

    fp.fuel_cost_total
        / NULLIF(COALESCE(t.actual_distance_miles, t.typical_distance_miles), 0)
                                                                       as fuel_cost_per_mile,

    t.idle_time_hours / NULLIF(t.actual_duration_hours, 0)             as idle_pct,

    GREATEST(COALESCE(de.total_detention_minutes, 0) - 120, 0) * 1.25  as estimated_detention_cost

from {{ ref('int_trips_enriched') }} t
left join delivery_events   de on t.trip_id = de.trip_id
left join fuel_purchases    fp on t.trip_id = fp.trip_id
left join safety_incidents  si on t.trip_id = si.trip_id
