-- back compat for old kwarg name
  
  
  
  
  
  
      
          
              
              
          
              
              
          
      
  

    merge
    into
        `ecommerce_analytics_poc`.`ecommerce`.`silver_customers` as DBT_INTERNAL_DEST
    using
        `silver_customers__dbt_tmp` as DBT_INTERNAL_SOURCE
    on
        
                  DBT_INTERNAL_SOURCE.`customer_id` <=> DBT_INTERNAL_DEST.`customer_id`
              
    and 
                  DBT_INTERNAL_SOURCE.`customer_creation_date` <=> DBT_INTERNAL_DEST.`customer_creation_date`
              
    when matched
        and (DBT_INTERNAL_SOURCE.source_updated_at > DBT_INTERNAL_DEST.source_updated_at)
        then update set
            `customer_id` = DBT_INTERNAL_SOURCE.`customer_id`, `customer_name` = DBT_INTERNAL_SOURCE.`customer_name`, `email` = DBT_INTERNAL_SOURCE.`email`, `city` = DBT_INTERNAL_SOURCE.`city`, `customer_status` = DBT_INTERNAL_SOURCE.`customer_status`, `source_updated_at` = DBT_INTERNAL_SOURCE.`source_updated_at`, `cdc_operation` = DBT_INTERNAL_SOURCE.`cdc_operation`, `is_deleted` = DBT_INTERNAL_SOURCE.`is_deleted`, `silver_updated_at` = DBT_INTERNAL_SOURCE.`silver_updated_at`
    when not matched
        then insert
            (`customer_id`, `customer_name`, `email`, `city`, `customer_status`, `customer_creation_date`, `source_created_at`, `source_updated_at`, `cdc_operation`, `is_deleted`, `silver_created_at`, `silver_updated_at`) VALUES (DBT_INTERNAL_SOURCE.`customer_id`, DBT_INTERNAL_SOURCE.`customer_name`, DBT_INTERNAL_SOURCE.`email`, DBT_INTERNAL_SOURCE.`city`, DBT_INTERNAL_SOURCE.`customer_status`, DBT_INTERNAL_SOURCE.`customer_creation_date`, DBT_INTERNAL_SOURCE.`source_created_at`, DBT_INTERNAL_SOURCE.`source_updated_at`, DBT_INTERNAL_SOURCE.`cdc_operation`, DBT_INTERNAL_SOURCE.`is_deleted`, DBT_INTERNAL_SOURCE.`silver_created_at`, DBT_INTERNAL_SOURCE.`silver_updated_at`)
