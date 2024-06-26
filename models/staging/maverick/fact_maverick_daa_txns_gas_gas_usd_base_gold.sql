{{
    config(
        materialized="table", snowflake_warehouse="FUNDAMENTAL_METRICS_WAREHOUSE_SM"
    )
}}

select date, app, chain, daa, txns, gas, gas_usd
from {{ ref("fact_maverick_daa_txns_gas_gas_usd_base") }}
