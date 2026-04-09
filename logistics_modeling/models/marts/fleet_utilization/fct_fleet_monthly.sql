{{ config(materialized='table') }}

with trip_agg as (
    select
        truck_id,
        dispatch_month                                                     as month,
        COUNT(*)                                                           as total_trips,
        COUNT(*) FILTER (WHERE trip_status = 'Completed')                  as trips_completed,
        SUM(actual_distance_miles)                                         as total_miles,
        SUM(total_revenue)                                                 as total_revenue,
        SUM(fuel_cost_total)                                               as total_fuel_cost,
        SUM(actual_distance_miles) / NULLIF(SUM(fuel_gallons_used), 0)     as avg_mpg,
        SUM(idle_time_hours)                                               as total_idle_hours,
        SUM(COALESCE(actual_distance_miles, typical_distance_miles))        as total_effective_miles
    from {{ ref('fct_fleet_trips') }}
    group by truck_id, dispatch_month
),

maint_agg as (
    select
        truck_id,
        maintenance_month                                                  as month,
        COUNT(*)                                                           as maintenance_events,
        SUM(total_cost)                                                    as total_maintenance_cost,
        SUM(downtime_hours)                                                as total_downtime_hours,
        SUM(opportunity_cost)                                              as total_opportunity_cost
    from {{ ref('fct_truck_maintenance') }}
    group by truck_id, maintenance_month
)

select
    COALESCE(ta.truck_id, ma.truck_id)                                     as truck_id,
    tk.unit_number,
    tk.make,
    tk.model_year,
    tk.fuel_type,
    tk.home_terminal,
    COALESCE(ta.month, ma.month)                                           as month,

    ta.total_trips,
    ta.trips_completed,
    ta.total_miles,
    ta.total_revenue,
    ta.total_fuel_cost,
    ta.avg_mpg,
    ta.total_idle_hours,

    ma.maintenance_events,
    ma.total_maintenance_cost,
    ma.total_downtime_hours,
    ma.total_opportunity_cost,

    COALESCE(ta.total_fuel_cost, 0) + COALESCE(ma.total_maintenance_cost, 0) as total_operating_cost,

    ta.total_revenue / NULLIF(ta.total_effective_miles, 0)                   as revenue_per_mile

from trip_agg ta
full outer join maint_agg ma
    on ta.truck_id = ma.truck_id
    and ta.month = ma.month
left join {{ ref('stg_trucks') }} tk
    on COALESCE(ta.truck_id, ma.truck_id) = tk.truck_id
