{{ config(materialized='table') }}

select
    m.maintenance_id,
    m.truck_id,
    tk.unit_number,
    tk.make,
    tk.model_year,
    tk.fuel_type,
    tk.home_terminal,

    m.maintenance_date,
    DATE_TRUNC('month', m.maintenance_date)                     as maintenance_month,
    m.maintenance_type,
    m.odometer_reading,
    m.labor_hours,
    m.labor_cost,
    m.parts_cost,
    m.total_cost,
    m.downtime_hours,
    m.service_description,

    m.total_cost / NULLIF(m.downtime_hours, 0)                  as cost_per_downtime_hour,

    ts.avg_daily_revenue * (m.downtime_hours / 24.0)            as opportunity_cost

from {{ ref('stg_maintenance_records') }} m
inner join {{ ref('stg_trucks') }}        tk on m.truck_id = tk.truck_id
left  join {{ ref('fct_trucks_summary') }} ts on m.truck_id = ts.truck_id
