{{ config(materialized='incremental', unique_key='HOST_ID') }}

SELECT
    HOST_ID,
    REPLACE(HOST_NAME, ' ', '-') AS HOST_NAME,
    HOST_SINCE AS HOST_SINCE,
    IS_SUPERHOST AS IS_SUPERHOST,
    RESPONSE_RATE AS RESPONSE_RATE,
    CASE
        WHEN RESPONSE_RATE > 95 THEN 'VERY GOOD'
        WHEN RESPONSE_RATE > 80 THEN 'GOOD'
        WHEN RESPONSE_RATE > 60 THEN 'FAIR'
        ELSE 'POOR'
    END AS RESPONSE_RATE_QUALITY,
    CREATED_AT AS CREATED_AT
FROM {{ ref('bronze_hosts') }}

-- Rolling window: re-process last N days for late-arriving bronze data.
{% if is_incremental() %}
WHERE CREATED_AT >= (
    SELECT DATEADD(day, -{{ var('lookback_days', 3) }}, COALESCE(MAX(CREATED_AT), '1900-01-01'))
    FROM {{ this }}
)
{% endif %}