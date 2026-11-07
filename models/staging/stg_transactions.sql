WITH cleaned AS (
    SELECT
        cast(transaction_id AS varchar) AS transaction_id,
        cast(client_id AS varchar) AS client_id,
        cast(asset_ticker AS varchar) AS asset_ticker,
        cast(operation AS varchar) AS operation,
        try_cast(quantity AS double) AS quantity,
        try_cast(unit_price AS double) AS unit_price,
        try_cast(transaction_date AS date) AS transaction_date
    FROM {{ ref('transactions') }}
)

SELECT *
FROM cleaned
WHERE transaction_id IS NOT NULL
  AND client_id IS NOT NULL
  AND asset_ticker IS NOT NULL
  AND operation IS NOT NULL
  AND quantity IS NOT NULL
  AND unit_price IS NOT NULL
  AND transaction_date IS NOT NULL
  AND quantity >= 0
  AND unit_price >= 0
  AND operation IN ('BUY', 'SELL')
{{ deduplicate('transaction_id', 'transaction_date') }}
