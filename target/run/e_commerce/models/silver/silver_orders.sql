-- back compat for old kwarg name
  
  
  
  
  
  
      
          
              
              
          
              
              
          
      
  

    merge
    into
        `ecommerce_analytics_poc`.`ecommerce`.`silver_orders` as DBT_INTERNAL_DEST
    using
        `silver_orders__dbt_tmp` as DBT_INTERNAL_SOURCE
    on
        
                  DBT_INTERNAL_SOURCE.`order_id` <=> DBT_INTERNAL_DEST.`order_id`
              
    and 
                  DBT_INTERNAL_SOURCE.`order_date` <=> DBT_INTERNAL_DEST.`order_date`
              
    when matched
        and (DBT_INTERNAL_SOURCE.source_updated_at > DBT_INTERNAL_DEST.source_updated_at)
        then update set
            `order_id` = DBT_INTERNAL_SOURCE.`order_id`, `customer_id` = DBT_INTERNAL_SOURCE.`customer_id`, `order_amount` = DBT_INTERNAL_SOURCE.`order_amount`, `order_status` = DBT_INTERNAL_SOURCE.`order_status`, `source_updated_at` = DBT_INTERNAL_SOURCE.`source_updated_at`, `cdc_operation` = DBT_INTERNAL_SOURCE.`cdc_operation`, `is_deleted` = DBT_INTERNAL_SOURCE.`is_deleted`, `silver_updated_at` = DBT_INTERNAL_SOURCE.`silver_updated_at`
    when not matched
        then insert
            (`order_id`, `customer_id`, `order_amount`, `order_status`, `order_date`, `source_created_at`, `source_updated_at`, `cdc_operation`, `is_deleted`, `silver_created_at`, `silver_updated_at`) VALUES (DBT_INTERNAL_SOURCE.`order_id`, DBT_INTERNAL_SOURCE.`customer_id`, DBT_INTERNAL_SOURCE.`order_amount`, DBT_INTERNAL_SOURCE.`order_status`, DBT_INTERNAL_SOURCE.`order_date`, DBT_INTERNAL_SOURCE.`source_created_at`, DBT_INTERNAL_SOURCE.`source_updated_at`, DBT_INTERNAL_SOURCE.`cdc_operation`, DBT_INTERNAL_SOURCE.`is_deleted`, DBT_INTERNAL_SOURCE.`silver_created_at`, DBT_INTERNAL_SOURCE.`silver_updated_at`)
