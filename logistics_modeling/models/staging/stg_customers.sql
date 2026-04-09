{{ config(materialized='table') }}

select
    customer_id,
    customer_name,
    customer_type,
    credit_terms_days,
    primary_freight_type,
    account_status = 'Active'   as is_active,
    contract_start_date,
    annual_revenue_potential
from {{ source('logistics', 'customers') }}
