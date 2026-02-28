{{ config(materialized='incremental', unique_key='LISTING_ID') }}

-- Rolling window: re-process last N days for late-arriving staging data.
SELECT * FROM {{ source('staging', 'listings') }}

{% if is_incremental() %}
    WHERE CREATED_AT >= (
        SELECT DATEADD(day, -{{ var('lookback_days', 3) }}, COALESCE(MAX(CREATED_AT), '1900-01-01'))
        FROM {{ this }}
    )
{% endif %}