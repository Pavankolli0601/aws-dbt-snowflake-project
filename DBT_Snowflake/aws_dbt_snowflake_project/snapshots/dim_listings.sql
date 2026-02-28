{% snapshot dim_listings %}

{{
  config(
    target_schema='gold',
    unique_key='LISTING_ID',
    strategy='timestamp',
    updated_at='LISTING_CREATED_AT',
    invalidate_hard_deletes=true,
    dbt_valid_to_current="to_date('9999-12-31')"
  )
}}

select *
from {{ ref('listings') }}

{% endsnapshot %}