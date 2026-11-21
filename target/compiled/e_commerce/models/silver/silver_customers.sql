



with

windowed_events as (
    select bronze.*
    from `ecommerce_analytics_poc`.`ecommerce`.`bronze_customers` as bronze
    
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
    
    where customer_creation_date >= date '2026-11-01'
        and customer_creation_date < date '2026-11-02'
    
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