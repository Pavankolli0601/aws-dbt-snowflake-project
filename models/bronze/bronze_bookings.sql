{{ config(materialized='incremental', unique_key='BOOKING_ID') }}

-- Incremental with rolling window: re-process last N days so late-arriving staging
-- data (e.g. backfills or delayed loads) is merged correctly via unique_key.
SELECT * FROM {{ source('staging', 'bookings') }}

{% if is_incremental() %}
    WHERE CREATED_AT >= (
        SELECT DATEADD(day, -{{ var('lookback_days', 3) }}, COALESCE(MAX(CREATED_AT), '1900-01-01'))
        FROM {{ this }}
    )
{% endif %}