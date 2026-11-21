with customer_counts as (
    select
        customer_id,
        customer_sk,
        total_orders,
        completed_orders,
        completed_sales_amount,
        cancelled_orders,
        refunded_orders,
        latest_order_date,
        count(*) over (partition by customer_id) as customer_id_count,
        count(*) over (partition by customer_sk) as customer_sk_count
    from `ecommerce_analytics_poc`.`ecommerce`.`gld_customer_summary`
)

select *
from customer_counts
where customer_id is null
    or customer_sk is null
    or customer_id_count > 1
    or customer_sk_count > 1
    or total_orders is null
    or completed_orders is null
    or completed_sales_amount is null
    or cancelled_orders is null
    or refunded_orders is null
    or total_orders < 0
    or completed_orders < 0
    or cancelled_orders < 0
    or refunded_orders < 0
    or completed_orders + cancelled_orders + refunded_orders > total_orders
    or (completed_orders = 0 and completed_sales_amount <> 0)
    or (total_orders = 0 and latest_order_date is not null)
    or (total_orders > 0 and latest_order_date is null)