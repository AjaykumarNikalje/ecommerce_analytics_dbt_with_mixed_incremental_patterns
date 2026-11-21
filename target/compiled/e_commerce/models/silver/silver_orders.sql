



with

windowed_events as (
    select bronze.*
    from `ecommerce_analytics_poc`.`ecommerce`.`bronze_orders` as bronze
    
),
typed_events as (
    select distinct
        try_cast(order_id as bigint) as order_id,
        try_cast(customer_id as bigint) as customer_id,
        try_cast(order_amount as decimal(18,2)) as order_amount,
        order_status,
        try_cast(order_date as date) as order_date,
        try_cast(source_created_at as timestamp) as source_created_at,
        try_cast(source_updated_at as timestamp) as source_updated_at,
        cdc_operation
    from windowed_events
),
ranked_events as (
    select
        *,
        row_number() over (
            partition by order_id
            order by source_updated_at desc
        ) as event_rank
    from typed_events
    
    where order_date >= date '2026-11-01'
        and order_date < date '2026-11-02'
    
),
winning_events as (
    select *
    from ranked_events
    where event_rank = 1
)

select
    winner.order_id,
    winner.customer_id,
    winner.order_amount,
    winner.order_status,
    winner.order_date,
    winner.source_created_at,
    winner.source_updated_at,
    winner.cdc_operation,
    (winner.cdc_operation = 'DELETE') as is_deleted,
    current_timestamp() as silver_created_at,
    current_timestamp() as silver_updated_at
from winning_events as winner