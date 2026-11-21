with key_counts as (
    select
        customer_id,
        is_deleted,
        silver_created_at,
        silver_updated_at,
        count(*) over (partition by customer_id) as key_count
    from {{ ref('silver_customers') }}
)

select *
from key_counts
where customer_id is null
    or key_count > 1
    or is_deleted is null
    or silver_created_at is null
    or silver_updated_at is null
