SELECT
    1
FROM {{ ref('mart_client_portfolio') }}
WHERE net_quantity < 0
