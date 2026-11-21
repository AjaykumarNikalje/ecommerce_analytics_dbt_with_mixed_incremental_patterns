select
    cast(order_id as string) as order_id,
    cast(customer_id as string) as customer_id,
    cast(order_amount as string) as order_amount,
    cast(order_status as string) as order_status,
    cast(order_date as string) as order_date,
    cast(source_created_at as string) as source_created_at,
    cast(source_updated_at as string) as source_updated_at,
    cast(cdc_operation as string) as cdc_operation,
    cast(landing_ingested_at as timestamp) as landing_ingested_at,
    current_timestamp() as bronze_ingested_at
from stream `ecommerce_analytics_poc`.`ecommerce`.`landing_orders_cdc`