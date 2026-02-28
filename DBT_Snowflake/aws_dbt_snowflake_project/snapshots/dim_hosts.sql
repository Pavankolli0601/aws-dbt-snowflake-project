{% snapshot dim_hosts %}

{{
  config(
    target_schema='gold',
    unique_key='HOST_ID',
    strategy='timestamp',
    updated_at='HOST_CREATED_AT',
    invalidate_hard_deletes=true,
    dbt_valid_to_current="to_date('9999-12-31')"
  )
}}

select
  HOST_ID,
  HOST_NAME,
  HOST_SINCE,
  IS_SUPERHOST,
  RESPONSE_RATE,
  RESPONSE_RATE_QUALITY,
  HOST_CREATED_AT
from {{ ref('hosts') }}

{% endsnapshot %}