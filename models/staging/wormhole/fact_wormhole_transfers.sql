{{ config(snowflake_warehouse="BRIDGE_MD", materialized="table") }}

with
    flattened_json as (
        select
            value:"id"::string as id,
            value:"timestamp"::timestamp as timestamp,
            value:"standardizedProperties":"amount"::string as amount,
            value:"standardizedProperties":"appIds" as app_ids,
            value:"standardizedProperties":"fee"::string as fee,
            value:"standardizedProperties":"feeAddress"::string as fee_address,
            value:"standardizedProperties":"feeChain"::string as fee_chain,
            value:"standardizedProperties":"fromAddress"::string as from_address,
            value:"standardizedProperties":"fromChain"::integer as from_chain,
            value:"standardizedProperties":"toAddress"::string as to_address,
            value:"standardizedProperties":"toChain"::integer as to_chain,
            value:"standardizedProperties":"tokenAddress"::string as token_address,
            value:"standardizedProperties":"tokenChain"::integer as token_chain,
            value:"usdAmount"::float as amount_usd,
            value:"symbol"::string as symbol,
            extraction_date
        from
            {{ source("PROD_LANDING", "raw_wormhole_transactions") }},
            lateral flatten(input => parse_json(source_json)) as flat_json
        where value:"standardizedProperties" is not null
    ),

    recent_data as (
        select id, max(extraction_date) as extraction_date
        from flattened_json
        group by 1
    ),

    prices as (
        select hour, token_address, decimals, price
        from ethereum_flipside.price.ez_hourly_token_prices
    ),
    decoded_transfers as (
        select
            id,
            timestamp,
            try_to_number(amount) as amount,
            app_ids,
            fee,
            fee_address,
            fee_chain,
            from_address,
            from_chain,
            to_address,
            to_chain,
            token_address,
            token_chain,
            amount_usd,
            symbol
        from flattened_json t1
        left join recent_data t2 using (id)
        where
            t1.extraction_date = t2.extraction_date
            and token_address != ''
            and lower(token_address)
            != lower('0xcc8fa225d80b9c7d42f96e9570156c65d6caaa25')
    )

select
    id,
    timestamp,
    amount,
    app_ids,
    fee,
    fee_address,
    fee_chain,
    from_address,
    from_chain,
    to_address,
    to_chain,
    decoded_transfers.token_address,
    token_chain,
    coalesce(
        amount_usd, (amount * coalesce(price, 0)) / pow(10, decimals), 0
    ) as amount_usd,
    symbol
from decoded_transfers
left join
    prices
    on decoded_transfers.token_address = prices.token_address
    and date_trunc('hour', timestamp) = prices.hour
