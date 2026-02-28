{% snapshot dim_bookings %}

{{
  config(
    target_schema='gold',
    unique_key='BOOKING_ID',
    strategy='timestamp',
    updated_at='CREATED_AT',
    invalidate_hard_deletes=true,
    dbt_valid_to_current="to_date('9999-12-31')"
  )
}}

select *
from {{ ref('bookings') }}

{% endsnapshot %}