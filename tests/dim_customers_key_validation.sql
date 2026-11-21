with key_counts as (
    select
        customer_id,
        customer_sk,
        customer_creation_date,
        count(*) over (partition by customer_id) as customer_id_count,
        count(*) over (partition by customer_sk) as customer_sk_count
    from {{ ref('dim_customers') }}
)

select *
from key_counts
where customer_id is null
    or customer_sk is null
    or customer_creation_date is null
    or customer_id_count > 1
    or customer_sk_count > 1
