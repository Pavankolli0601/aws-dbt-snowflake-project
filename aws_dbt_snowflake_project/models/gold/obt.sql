{{ config(materialized='table') }}

SELECT
    -- booking columns
    b.*,

    -- listing columns (remove duplicates + keep listing created_at separately)
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