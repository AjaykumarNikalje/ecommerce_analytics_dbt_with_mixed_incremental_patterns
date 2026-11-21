
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
select
    customer_id,
    cdc_operation,
    source_created_at,
    source_updated_at,
    bronze_ingested_at
from `ecommerce_analytics_poc`.`ecommerce`.`bronze_customers`
where
    
    cast(try_cast(source_created_at as timestamp) as date) >= date '2026-11-01'
    and cast(try_cast(source_created_at as timestamp) as date) < date '2026-11-02'
    and
    
    (
        try_cast(customer_id as bigint) is null
        or cdc_operation is null
        or cdc_operation not in ('INSERT', 'UPDATE', 'DELETE')
        or try_cast(source_updated_at as timestamp) is null
        or try_cast(source_created_at as timestamp) is null
        or bronze_ingested_at is null
    )
  
  
      
    ) dbt_internal_test