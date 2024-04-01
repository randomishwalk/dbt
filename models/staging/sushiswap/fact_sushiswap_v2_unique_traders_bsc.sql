{{
    config(
        materialized="incremental",
        unique_key="date",
        snowflake_warehouse="SUSHISWAP_SM",
    )
}}

{{
    fact_daily_uniswap_fork_unique_traders(
        "0xc35DADB65012eC5796536bD9864eD8773aBc74C4",
        "bsc",
        "PairCreated",
        "pair",
        "sushiswap_v2",
    )
}}