{% macro start_silver_checkpoint(entity) %}
    {% if entity not in ['customers', 'orders'] %}
        {{ exceptions.raise_compiler_error('Unknown Silver pipeline: ' ~ entity) }}
    {% endif %}
    {% set checkpoint = api.Relation.create(
        database=target.database, schema=target.schema, identifier='pipeline_checkpoint'
    ) %}
    {% set bronze = ref('bronze_' ~ entity) %}
    {% set pipeline = entity ~ '_bronze_to_silver' %}

    {% set capture_sql %}
        select
            unix_micros(checkpoint.last_successful_ingested_at),
            bounds.upper_watermark_us
        from {{ checkpoint }} as checkpoint
        cross join (
            select unix_micros(max(bronze_ingested_at)) as upper_watermark_us
            from {{ bronze }}
        ) as bounds
        where checkpoint.pipeline_name = '{{ pipeline }}'
    {% endset %}
    {% set window = run_query(capture_sql) %}
    {% if window | length != 1 %}
        {{ exceptions.raise_compiler_error('Expected one checkpoint row for ' ~ pipeline) }}
    {% endif %}

    {% call statement('mark_silver_running') %}
        update {{ checkpoint }}
        set pipeline_status = 'RUNNING',
            last_run_started_at = current_timestamp(),
            last_run_completed_at = null,
            error_message = null,
            updated_at = current_timestamp()
        where pipeline_name = '{{ pipeline }}'
    {% endcall %}

    {% set previous = window.rows[0][0] %}
    {% set upper = window.rows[0][1] %}
    {% do log('SILVER_RUN_WINDOW=' ~ tojson({
        'previous_us': previous | int if previous is not none else none,
        'upper_us': upper | int if upper is not none else none
    }), info=true) %}
{% endmacro %}

{% macro finish_silver_checkpoint(entity, upper_us=none, failed_step=none) %}
    {% if entity not in ['customers', 'orders'] %}
        {{ exceptions.raise_compiler_error('Unknown Silver pipeline: ' ~ entity) }}
    {% endif %}
    {% if failed_step is not none and failed_step not in ['Bronze validation', 'Silver merge', 'Silver validation', 'checkpoint finalization'] %}
        {{ exceptions.raise_compiler_error('Unknown Silver processing step') }}
    {% endif %}
    {% set checkpoint = api.Relation.create(
        database=target.database, schema=target.schema, identifier='pipeline_checkpoint'
    ) %}

    {% call statement('finalize_silver_checkpoint') %}
        update {{ checkpoint }}
        set
            {% if failed_step is none %}
            pipeline_status = 'SUCCESS',
            error_message = null,
            {% if upper_us is not none %}
            last_successful_ingested_at = greatest(
                last_successful_ingested_at, timestamp_micros({{ upper_us | int }})
            ),
            {% endif %}
            {% else %}
            pipeline_status = 'FAILED',
            error_message = '{{ failed_step }} failed. See the dbt run logs.',
            {% endif %}
            last_run_completed_at = current_timestamp(),
            updated_at = current_timestamp()
        where pipeline_name = '{{ entity }}_bronze_to_silver'
            and pipeline_status = 'RUNNING'
    {% endcall %}
{% endmacro %}
