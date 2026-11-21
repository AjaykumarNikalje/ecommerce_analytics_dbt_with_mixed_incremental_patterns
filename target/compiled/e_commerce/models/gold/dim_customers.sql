select
    md5(cast(concat(coalesce(cast(silver.customer_id as string), '_dbt_utils_surrogate_key_null_')) as string)) as customer_sk,
    silver.customer_id,
    silver.customer_name,
    silver.email,
    silver.city,
    silver.customer_status,
    silver.customer_creation_date,
    silver.source_created_at,
    silver.source_updated_at,
    silver.is_deleted,
    silver.silver_updated_at
from `ecommerce_analytics_poc`.`ecommerce`.`silver_customers` as silver

cross join (
    select max(silver_updated_at) as last_loaded_at
    from `ecommerce_analytics_poc`.`ecommerce`.`dim_customers`
) as watermark
where watermark.last_loaded_at is null
    or silver.silver_updated_at >= watermark.last_loaded_at - interval 6 hours
