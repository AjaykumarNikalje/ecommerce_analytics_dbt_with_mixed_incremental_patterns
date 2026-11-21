select
    {{ dbt_utils.generate_surrogate_key(['silver.order_id']) }} as order_sk,
    silver.order_id,
    case when silver.customer_id is not null
        then {{ dbt_utils.generate_surrogate_key(['silver.customer_id']) }}
    end as customer_sk,
    silver.customer_id,
    silver.order_amount,
    silver.order_status,
    silver.order_date,
    silver.source_created_at,
    silver.source_updated_at,
    silver.is_deleted,
    silver.silver_updated_at
from {{ ref('silver_orders') }} as silver
{% if is_incremental() %}
cross join (
    select max(silver_updated_at) as last_loaded_at
    from {{ this }}
) as watermark
where watermark.last_loaded_at is null
    or silver.silver_updated_at >= watermark.last_loaded_at - interval 6 hours
{% endif %}
