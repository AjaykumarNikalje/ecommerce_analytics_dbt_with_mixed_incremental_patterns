
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
select
    order_id,
    customer_id,
    order_amount,
    order_date,
    cdc_operation,
    source_created_at,
    source_updated_at,
    bronze_ingested_at
from `ecommerce_analytics_poc`.`ecommerce`.`bronze_orders`
where
    
    try_cast(order_date as date) >= date '2026-11-01'
    and try_cast(order_date as date) < date '2026-11-02'
    and
    
    (
        try_cast(order_id as bigint) is null
        or cdc_operation is null
        or cdc_operation not in ('INSERT', 'UPDATE', 'DELETE')
        or try_cast(source_updated_at as timestamp) is null
        or (source_created_at is not null and try_cast(source_created_at as timestamp) is null)
        or (customer_id is not null and try_cast(customer_id as bigint) is null)
        or (order_amount is not null and try_cast(order_amount as decimal(18,2)) is null)
        or try_cast(order_date as date) is null
        or bronze_ingested_at is null
    )
  
  
      
    ) dbt_internal_test