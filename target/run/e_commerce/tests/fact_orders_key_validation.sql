
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  with key_counts as (
    select
        order_id,
        order_sk,
        order_date,
        count(*) over (partition by order_id) as order_id_count,
        count(*) over (partition by order_sk) as order_sk_count
    from `ecommerce_analytics_poc`.`ecommerce`.`fact_orders`
)

select *
from key_counts
where order_id is null
    or order_sk is null
    or order_date is null
    or order_id_count > 1
    or order_sk_count > 1
  
  
      
    ) dbt_internal_test