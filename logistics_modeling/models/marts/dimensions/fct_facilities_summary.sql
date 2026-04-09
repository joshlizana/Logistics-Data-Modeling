{{ config(materialized='table') }}

with event_agg as (
    select
        facility_id,
        MIN(actual_datetime::DATE)                                        as first_event_date,
        MAX(actual_datetime::DATE)                                        as last_event_date,
        COUNT(*)                                                          as total_events,
        COUNT(*) FILTER (WHERE event_type = 'Pickup')                     as total_pickups,
        COUNT(*) FILTER (WHERE event_type = 'Delivery')                   as total_deliveries,
        SUM(on_time_flag::int)::FLOAT / NULLIF(COUNT(*), 0)               as on_time_pct,
        SUM(detention_minutes)                                            as total_detention_minutes,
        SUM(detention_minutes)::FLOAT / NULLIF(COUNT(*), 0)               as avg_detention_per_event,
        SUM(GREATEST(detention_minutes - 120, 0) * 1.25)                  as estimated_detention_cost,
        COUNT(DISTINCT load_id)                                           as unique_loads,
        COUNT(DISTINCT trip_id)                                           as unique_trips
    from {{ ref('stg_delivery_events') }}
    group by facility_id
),

revenue_agg as (
    select
        de.facility_id,
        SUM(rt.total_revenue)           as revenue_throughput,
        SUM(rt.net_revenue_after_fuel)  as net_revenue_throughput
    from (
        select distinct facility_id, trip_id
        from {{ ref('stg_delivery_events') }}
    ) de
    inner join {{ ref('fct_route_trips') }} rt on de.trip_id = rt.trip_id
    group by de.facility_id
)

select
    ea.facility_id,
    ea.first_event_date,
    ea.last_event_date,
    ea.total_events,
    ea.total_pickups,
    ea.total_deliveries,
    ea.on_time_pct,
    ea.total_detention_minutes,
    ea.avg_detention_per_event,
    ea.estimated_detention_cost,
    ea.unique_loads,
    ea.unique_trips,
    ra.revenue_throughput,
    ra.net_revenue_throughput

from event_agg ea
left join revenue_agg ra on ea.facility_id = ra.facility_id
