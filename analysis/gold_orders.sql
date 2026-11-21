-- Run in the pipeline catalog and schema. Zero rows means the data reconciles.
with expected as (
    select
        order_id,
        customer_id,
        order_amount,
        order_status,
        order_date,
        source_created_at,
        source_updated_at,
        is_deleted,
        silver_updated_at
    from silver_orders
),
actual as (
    select
        order_id,
        customer_id,
        order_amount,
        order_status,
        order_date,
        source_created_at,
        source_updated_at,
        is_deleted,
        silver_updated_at
    from fact_orders
),
expected_only as (
    select * from expected
    except all
    select * from actual
),
actual_only as (
    select * from actual
    except all
    select * from expected
)

select 'EXPECTED_ONLY' as reconciliation_issue, expected_only.*
from expected_only
union all
select 'ACTUAL_ONLY' as reconciliation_issue, actual_only.*
from actual_only
