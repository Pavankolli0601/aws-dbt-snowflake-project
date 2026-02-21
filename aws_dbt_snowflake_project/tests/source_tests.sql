{{ config(
    severity='warn',) }}

SELECT
    *
FROM
    {{ source('staging', 'bookings') }}
WHERE
    BOOKING_AMOUNT < 200