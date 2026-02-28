{{
    config(
        materialized='incremental',
        unique_key='BOOKING_ID'
    )
}}

SELECT
    BOOKING_ID,
    LISTING_ID,
    BOOKING_DATE,
    {{ multiply('NIGHTS_BOOKED', 'BOOKING_AMOUNT', 2) }} AS TOTAL_AMOUNT,
    SERVICE_FEE,
    CLEANING_FEE,
    BOOKING_STATUS,
    CREATED_AT
FROM
    {{ ref('bronze_bookings') }}

-- Rolling window: re-process last N days so late-arriving bronze rows are merged.
{% if is_incremental() %}
WHERE CREATED_AT >= (
    SELECT DATEADD(day, -{{ var('lookback_days', 3) }}, COALESCE(MAX(CREATED_AT), '1900-01-01'))
    FROM {{ this }}
)
{% endif %}