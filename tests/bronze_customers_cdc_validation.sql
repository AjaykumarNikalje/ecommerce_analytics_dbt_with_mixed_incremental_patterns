{% set backfill = var('silver_backfill', none) %}
select
    customer_id,
    cdc_operation,
    source_created_at,
    source_updated_at,
    bronze_ingested_at
from {{ ref('bronze_customers') }}
where
    {% if backfill is not none %}
    cast(try_cast(source_created_at as timestamp) as date) >= date '{{ modules.datetime.date.fromisoformat(backfill.start_date).isoformat() }}'
    and cast(try_cast(source_created_at as timestamp) as date) < date '{{ modules.datetime.date.fromisoformat(backfill.end_date).isoformat() }}'
    and
    {% endif %}
    (
        try_cast(customer_id as bigint) is null
        or cdc_operation is null
        or cdc_operation not in ('INSERT', 'UPDATE', 'DELETE')
        or try_cast(source_updated_at as timestamp) is null
        or try_cast(source_created_at as timestamp) is null
        or bronze_ingested_at is null
    )
