SELECT
    clients.id as client_id,
    clients.name,
    transactions.asset_ticker,
    SUM (
        (
            CASE transactions.operation 
            WHEN 'BUY' THEN 1
            WHEN 'SELL' THEN -1
            END
        )*transactions.quantity
    ) AS net_quantity,
    SUM (
        (
            CASE transactions.operation 
            WHEN 'BUY' THEN 1
            WHEN 'SELL' THEN -1
            END
        )*transactions.quantity*transactions.unit_price
    ) AS position
FROM {{ ref('dim_clients') }} AS clients
INNER JOIN {{ ref('fact_transactions') }} AS transactions
    ON clients.id = transactions.client_id
GROUP BY ALL
HAVING net_quantity >= 0