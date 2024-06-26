{{ config(materialized="table") }}
with
    temp as (
        select
            f.date,
            f.value as num_staked_eth,
            f.value * p.shifted_token_price_usd as amount_staked_usd,
            p.shifted_token_price_usd
        from {{ ref("fact_lido_staked_eth_count") }} f
        join pc_dbt_db.prod.fact_coingecko_token_date_adjusted_gold p on f.date = p.date
        where p.coingecko_id = 'ethereum'
        order by date desc
    )
select
    t.date,
    t.num_staked_eth,
    t.amount_staked_usd,
    case
        when t.date = '2020-12-19'
        then 0
        else t.num_staked_eth - lag(t.num_staked_eth, 1) over (order by t.date)
    end as num_staked_eth_net_change,  -- no previous date for 2020-12-19, so cannot calculate net change, hence set to 0
    case
        when t.date = '2020-12-19'
        then 0
        -- amount_staked_usd_net_change: (today's num eth staked -  prev day num eth
        -- staked ) * avg eth_price_USD
        else
            (t.num_staked_eth - lag(t.num_staked_eth, 1) over (order by t.date)) * (
                (
                    t.shifted_token_price_usd
                    + lag(t.shifted_token_price_usd, 1) over (order by t.date)
                )
                / 2
            )
    end as amount_staked_usd_net_change  -- no previous date for 2020-12-19, so cannot calculate net change, hence set to 0
from temp t
order by date desc
