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
)

select
    t.trip_id,
    t.load_id,
    t.customer_id,
    t.dispatch_date,
    t.dispatch_month,
    t.load_date,
    t.customer_name,
    t.customer_type,
    t.primary_freight_type,
    t.is_active,
    t.credit_terms_days,
    t.annual_revenue_potential,
    t.load_type,
    t.weight_lbs,
    t.pieces,
    t.booking_type,
    t.load_status,
    t.trip_status,
    t.route_id,
    t.lane_id,
    t.lane_type,
    t.origin_region_id,
    t.destination_region_id,
    t.typical_transit_days,
    t.actual_duration_hours,
    t.revenue,
    t.fuel_surcharge,
    t.accessorial_charges,
    t.total_revenue,

    de.deliveries_on_time,
    de.total_deliveries,
    de.pickups_on_time,
    de.total_pickups,
    de.total_detention_minutes,

    de.deliveries_on_time::float / NULLIF(de.total_deliveries, 0)       as on_time_delivery_pct,

    t.accessorial_charges / NULLIF(t.total_revenue, 0)                  as accessorial_pct,

    t.actual_duration_hours - (t.typical_transit_days * 24.0)           as vs_typical_transit_hours,

    GREATEST(COALESCE(de.total_detention_minutes, 0) - 120, 0) * 1.25  as estimated_detention_cost

from {{ ref('int_trips_enriched') }} t
left join delivery_events de on t.trip_id = de.trip_id
