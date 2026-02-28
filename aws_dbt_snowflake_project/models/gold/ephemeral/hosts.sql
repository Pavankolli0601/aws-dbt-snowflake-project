{{ config(materialized='ephemeral') }}

select
  host_name,
  host_since,
  is_superhost,
  response_rate,
  response_rate_quality,
  host_created_at
from {{ ref('obt') }}