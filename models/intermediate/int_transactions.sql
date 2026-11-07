{{ config(materialized='table') }}

SELECT
    transactions.transaction_id,
    clients.id AS client_id,
    transactions.asset_ticker,
    transactions.operation,
    transactions.quantity,
    transactions.unit_price,
    transactions.transaction_date
FROM {{ ref('stg_transactions') }} AS transactions
LEFT JOIN {{ ref('dim_clients') }} AS clients
    ON transactions.client_id = clients.client_id
