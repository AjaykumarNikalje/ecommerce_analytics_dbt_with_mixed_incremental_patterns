with key_counts as (
    select
        order_id,
        is_deleted,
        silver_created_at,
        silver_updated_at,
        count(*) over (partition by order_id) as key_count
    from `ecommerce_analytics_poc`.`ecommerce`.`silver_orders`
)

select *
from key_counts
where order_id is null
    or key_count > 1
    or is_deleted is null
    or silver_created_at is null
    or silver_updated_at is null