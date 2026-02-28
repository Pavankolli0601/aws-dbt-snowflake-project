{{
  config(
    materialized='ephemeral'
  )
}}
-- Fact-style mart: OBT joined to current snapshot dimensions for star-style reporting.
-- Uses ref() so it works in any environment; joins on LISTING_ID and HOST_ID.

WITH obt AS (
  SELECT
    BOOKING_ID,
    LISTING_ID,
    HOST_ID,
    TOTAL_AMOUNT,
    SERVICE_FEE,
    CLEANING_FEE,
    BOOKING_STATUS,
    CREATED_AT
  FROM {{ ref('obt') }}
),
dim_listings_current AS (
  SELECT * FROM {{ ref('dim_listings') }}
  WHERE dbt_valid_to IS NULL
),
dim_hosts_current AS (
  SELECT * FROM {{ ref('dim_hosts') }}
  WHERE dbt_valid_to IS NULL
)
SELECT
  o.BOOKING_ID,
  o.LISTING_ID,
  o.HOST_ID,
  o.TOTAL_AMOUNT,
  o.SERVICE_FEE,
  o.CLEANING_FEE,
  o.BOOKING_STATUS,
  o.CREATED_AT
FROM obt o
LEFT JOIN dim_listings_current dl ON o.LISTING_ID = dl.LISTING_ID
LEFT JOIN dim_hosts_current dh ON o.HOST_ID = dh.HOST_ID
