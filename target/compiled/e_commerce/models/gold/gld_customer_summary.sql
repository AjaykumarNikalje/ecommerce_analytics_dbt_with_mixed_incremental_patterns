with order_summary as (
    select
        customer_sk,
        count(*) as total_orders,
        count(case when order_status = 'COMPLETED' then 1 end) as completed_orders,
        cast(sum(case when order_status = 'COMPLETED' then order_amount else 0 end)
            as decimal(28,2)) as completed_sales_amount,
        count(case when order_status = 'CANCELLED' then 1 end) as cancelled_orders,
        count(case when order_status = 'REFUNDED' then 1 end) as refunded_orders,
        max(order_date) as latest_order_date
    from `ecommerce_analytics_poc`.`ecommerce`.`fact_orders`
    where is_deleted = false
    group by customer_sk
)

select
    customers.customer_sk,
    customers.customer_id,
    customers.customer_name,
    customers.city,
    customers.customer_status,
    coalesce(orders.total_orders, cast(0 as bigint)) as total_orders,
    coalesce(orders.completed_orders, cast(0 as bigint)) as completed_orders,
    coalesce(orders.completed_sales_amount, cast(0 as decimal(28,2))) as completed_sales_amount,
    coalesce(orders.cancelled_orders, cast(0 as bigint)) as cancelled_orders,
    coalesce(orders.refunded_orders, cast(0 as bigint)) as refunded_orders,
    orders.latest_order_date
from `ecommerce_analytics_poc`.`ecommerce`.`dim_customers` as customers
left join order_summary as orders
    on customers.customer_sk = orders.customer_sk
where customers.is_deleted = false