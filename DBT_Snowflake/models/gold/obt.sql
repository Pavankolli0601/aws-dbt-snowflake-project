{{ config(materialized='table') }}

SELECT
    -- booking columns (explicit string/VARCHAR for contract; BOOKING_DATE cast to DATE)
    b.BOOKING_ID::VARCHAR AS BOOKING_ID,
    b.LISTING_ID::VARCHAR AS LISTING_ID,
    b.BOOKING_DATE::DATE AS BOOKING_DATE,
    b.TOTAL_AMOUNT,
    b.SERVICE_FEE,
    b.CLEANING_FEE,
    b.BOOKING_STATUS,
    b.CREATED_AT,

    -- listing columns (remove duplicates + keep listing created_at separately)
    l.HOST_ID::VARCHAR AS HOST_ID,
    l.* EXCLUDE (LISTING_ID, HOST_ID, CREATED_AT),
    l.CREATED_AT AS LISTING_CREATED_AT,

    -- host columns (remove duplicates + keep host created_at separately)
    h.* EXCLUDE (HOST_ID, CREATED_AT),
    h.CREATED_AT AS HOST_CREATED_AT

FROM {{ ref('silver_bookings') }} b

LEFT JOIN {{ ref('silver_listings') }} l
    ON b.LISTING_ID = l.LISTING_ID

LEFT JOIN {{ ref('silver_hosts') }} h
    ON l.HOST_ID = h.HOST_ID