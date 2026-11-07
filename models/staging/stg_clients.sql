WITH cleaned AS (
    SELECT
        cast(client_id AS varchar) AS client_id,
        cast(name AS varchar) AS name,
        cast(city AS varchar) AS city,
        upper(cast(state AS varchar)) AS state,
        try_cast(created_at AS date) AS created_at
    FROM {{ ref('clients') }}
)

SELECT *
FROM cleaned
WHERE client_id IS NOT NULL
  AND name IS NOT NULL
  AND city IS NOT NULL
  AND state IS NOT NULL
  AND state IN ('AC', 'AL', 'AP', 'AM', 'BA', 'CE', 'DF', 'ES', 'GO', 'MA', 'MT', 'MS', 'MG', 'PA', 'PB', 'PR', 'PE', 'PI', 'RJ', 'RN', 'RS', 'RO', 'RR', 'SC', 'SP', 'SE', 'TO')
  AND created_at IS NOT NULL
{{ deduplicate('client_id', 'created_at') }}
