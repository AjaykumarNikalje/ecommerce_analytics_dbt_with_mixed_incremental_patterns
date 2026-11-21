{% set run_window = var('silver_run_window', none) %}
{% set backfill = var('silver_backfill', none) %}
{% if backfill is not none and execute and not is_incremental() %}
    {{ exceptions.raise_compiler_error('Backfill requires an existing incremental Silver table. Run the initial Silver load first.') }}
{% endif %}

with
{% if backfill is none %}
checkpoint_state as (
    {% if run_window is not none %}
    select {% if run_window.previous_us is none %}cast(null as timestamp){% else %}timestamp_micros({{ run_window.previous_us | int }}){% endif %}
        as last_successful_ingested_at
    {% else %}
    select last_successful_ingested_at
    from {{ adapter.quote(target.database) }}.{{ adapter.quote(target.schema) }}.pipeline_checkpoint
    where pipeline_name = 'customers_bronze_to_silver'
    {% endif %}
),
upper_bound as (
    {% if run_window is not none %}
    select {% if run_window.upper_us is none %}cast(null as timestamp){% else %}timestamp_micros({{ run_window.upper_us | int }}){% endif %}
        as upper_watermark
    {% else %}
    select max(bronze_ingested_at) as upper_watermark
    from {{ ref('bronze_customers') }}
    {% endif %}
),
{% endif %}
windowed_events as (
    select bronze.*
    from {{ ref('bronze_customers') }} as bronze
    {% if backfill is none %}
    cross join checkpoint_state
    cross join upper_bound
    where bronze.bronze_ingested_at <= upper_bound.upper_watermark
        and (
            checkpoint_state.last_successful_ingested_at is null
            or bronze.bronze_ingested_at >
                checkpoint_state.last_successful_ingested_at - interval 6 hours
        )
    {% endif %}
),
typed_events as (
    select distinct
        try_cast(customer_id as bigint) as customer_id,
        customer_name,
        email,
        city,
        customer_status,
        cast(try_cast(source_created_at as timestamp) as date) as customer_creation_date,
        try_cast(source_created_at as timestamp) as source_created_at,
        try_cast(source_updated_at as timestamp) as source_updated_at,
        cdc_operation
    from windowed_events
),
ranked_events as (
    select
        *,
        row_number() over (
            partition by customer_id
            order by source_updated_at desc
        ) as event_rank
    from typed_events
    {% if backfill is not none %}
    where customer_creation_date >= date '{{ modules.datetime.date.fromisoformat(backfill.start_date).isoformat() }}'
        and customer_creation_date < date '{{ modules.datetime.date.fromisoformat(backfill.end_date).isoformat() }}'
    {% endif %}
),
winning_events as (
    select *
    from ranked_events
    where event_rank = 1
)

select
    winner.customer_id,
    winner.customer_name,
    winner.email,
    winner.city,
    winner.customer_status,
    winner.customer_creation_date,
    winner.source_created_at,
    winner.source_updated_at,
    winner.cdc_operation,
    (winner.cdc_operation = 'DELETE') as is_deleted,
    current_timestamp() as silver_created_at,
    current_timestamp() as silver_updated_at
from winning_events as winner
