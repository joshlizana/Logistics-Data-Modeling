{{ config(materialized='table') }}

select
    customer_id,
    customer_name,
    customer_type,
    credit_terms_days,
    primary_freight_type,
    is_active,
    contract_start_date,
    annual_revenue_potential,
    DATEDIFF('year', contract_start_date, CURRENT_DATE) as contract_tenure_years
from {{ ref('stg_customers') }}
