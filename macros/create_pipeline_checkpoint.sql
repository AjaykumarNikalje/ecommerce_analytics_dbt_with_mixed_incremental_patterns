{% macro create_pipeline_checkpoint() %}
    {% set checkpoint = api.Relation.create(
        database=target.database,
        schema=target.schema,
        identifier='pipeline_checkpoint',
        type='table'
    ) %}

    {% call statement('create_pipeline_checkpoint') %}
        create table if not exists {{ checkpoint }} (
            pipeline_name string not null,
            source_table string not null,
            target_table string not null,
            last_successful_ingested_at timestamp,
            last_run_started_at timestamp,
            last_run_completed_at timestamp,
            pipeline_status string,
            error_message string,
            created_at timestamp not null,
            updated_at timestamp not null
        )
        using delta
    {% endcall %}

    {% call statement('initialize_pipeline_checkpoints') %}
        merge into {{ checkpoint }} as checkpoint
        using (
            select *
            from values
                ('customers_bronze_to_silver', 'bronze_customers', 'silver_customers'),
                ('orders_bronze_to_silver', 'bronze_orders', 'silver_orders')
            as pipelines(pipeline_name, source_table, target_table)
        ) as initial
        on checkpoint.pipeline_name = initial.pipeline_name
        when not matched then insert (
            pipeline_name,
            source_table,
            target_table,
            last_successful_ingested_at,
            pipeline_status,
            created_at,
            updated_at
        ) values (
            initial.pipeline_name,
            initial.source_table,
            initial.target_table,
            null,
            'NOT_STARTED',
            current_timestamp(),
            current_timestamp()
        )
    {% endcall %}
{% endmacro %}
