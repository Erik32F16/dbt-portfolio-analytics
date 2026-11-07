{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        unique_key='transaction_id',
        merge_exclude_columns=['id'],
        pre_hook="CREATE SEQUENCE IF NOT EXISTS fact_transactions_id_seq START 1"
    )
}}

SELECT
    nextval('fact_transactions_id_seq') AS id,
    transaction_id,
    client_id,
    asset_ticker,
    operation,
    quantity,
    unit_price,
    transaction_date
FROM {{ ref('int_transactions') }}
