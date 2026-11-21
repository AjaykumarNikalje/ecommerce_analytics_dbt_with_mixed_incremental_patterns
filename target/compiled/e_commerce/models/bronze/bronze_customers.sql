select
    cast(customer_id as string) as customer_id,
    cast(customer_name as string) as customer_name,
    cast(email as string) as email,
    cast(city as string) as city,
    cast(customer_status as string) as customer_status,
    cast(source_created_at as string) as source_created_at,
    cast(source_updated_at as string) as source_updated_at,
    cast(cdc_operation as string) as cdc_operation,
    cast(landing_ingested_at as timestamp) as landing_ingested_at,
    current_timestamp() as bronze_ingested_at
from stream `ecommerce_analytics_poc`.`ecommerce`.`landing_customers_cdc`