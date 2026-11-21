-- Run in the pipeline catalog and schema after Gold refresh. Zero rows means the data reconciles.
with customer_events as (
    select distinct
        try_cast(customer_id as bigint) as customer_id,
        customer_name,
        city,
        customer_status,
        try_cast(source_updated_at as timestamp) as source_updated_at,
        cdc_operation
    from bronze_customers
),
current_customers as (
    select customer_id, customer_name, city, customer_status, cdc_operation
    from customer_events
    qualify row_number() over (
        partition by customer_id
        order by source_updated_at desc
    ) = 1
),
order_events as (
    select distinct
        try_cast(order_id as bigint) as order_id,
        try_cast(customer_id as bigint) as customer_id,
        try_cast(order_amount as decimal(18,2)) as order_amount,
        order_status,
        try_cast(order_date as date) as order_date,
        try_cast(source_updated_at as timestamp) as source_updated_at,
        cdc_operation
    from bronze_orders
),
current_orders as (
    select order_id, customer_id, order_amount, order_status, order_date, cdc_operation
    from order_events
    qualify row_number() over (
        partition by order_id
        order by source_updated_at desc
    ) = 1
),
expected as (
    select
        customers.customer_id,
        customers.customer_name,
        customers.city,
        customers.customer_status,
        count(orders.order_id) as total_orders,
        count(case when orders.order_status = 'COMPLETED' then 1 end) as completed_orders,
        cast(coalesce(sum(case when orders.order_status = 'COMPLETED' then orders.order_amount end), 0)
            as decimal(28,2)) as completed_sales_amount,
        count(case when orders.order_status = 'CANCELLED' then 1 end) as cancelled_orders,
        count(case when orders.order_status = 'REFUNDED' then 1 end) as refunded_orders,
        max(orders.order_date) as latest_order_date
    from current_customers as customers
    left join current_orders as orders
        on customers.customer_id = orders.customer_id
        and orders.cdc_operation <> 'DELETE'
    where customers.cdc_operation <> 'DELETE'
    group by
        customers.customer_id,
        customers.customer_name,
        customers.city,
        customers.customer_status
),
actual as (
    select
        customer_id,
        customer_name,
        city,
        customer_status,
        total_orders,
        completed_orders,
        completed_sales_amount,
        cancelled_orders,
        refunded_orders,
        latest_order_date
    from gld_customer_summary
),
expected_only as (
    select * from expected
    except all
    select * from actual
),
actual_only as (
    select * from actual
    except all
    select * from expected
)

select 'EXPECTED_ONLY' as reconciliation_issue, expected_only.*
from expected_only
union all
select 'ACTUAL_ONLY' as reconciliation_issue, actual_only.*
from actual_only
