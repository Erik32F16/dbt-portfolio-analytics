{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        unique_key='client_id',
        merge_exclude_columns=['id'],
        pre_hook="CREATE SEQUENCE IF NOT EXISTS dim_clients_id_seq START 1"
    )
}}

SELECT
    nextval('dim_clients_id_seq') AS id,
    client_id,
    name,
    city,
    state,
    created_at
FROM {{ ref('stg_clients') }}