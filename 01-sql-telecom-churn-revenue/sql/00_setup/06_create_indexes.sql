/* ============================================================
   Project : 01 — Telecommunications Revenue Retention
   File    : 00_setup/06_create_indexes.sql
   Stage   : PREPARE
   Purpose : Indexes on join keys and frequent filter columns.
             At 7,043 rows PostgreSQL will often prefer a sequential scan and
             these will go unused. They are declared because the model should
             be correct at any scale, and because index design is part of the
             work being evidenced — not because this dataset needs them.
   Author  : Peters
   Created : 2026-08-19
   ============================================================ */

-- Join keys (primary keys are already indexed; these cover the FK side)
CREATE INDEX IF NOT EXISTS ix_location_zip
    ON core.dim_location (zip_code);
CREATE INDEX IF NOT EXISTS ix_bridge_service
    ON core.bridge_customer_service (service_code) WHERE is_subscribed;

-- Frequent analytical filters
CREATE INDEX IF NOT EXISTS ix_status_churned
    ON core.fact_customer_status (is_churned);
CREATE INDEX IF NOT EXISTS ix_status_tenure
    ON core.fact_customer_status (tenure_months);
CREATE INDEX IF NOT EXISTS ix_status_monthly_charge
    ON core.fact_customer_status (monthly_charge);
CREATE INDEX IF NOT EXISTS ix_contract_type
    ON core.dim_contract (contract_type);
CREATE INDEX IF NOT EXISTS ix_contract_payment
    ON core.dim_contract (payment_method);

SELECT schemaname, tablename, indexname
FROM   pg_indexes
WHERE  schemaname IN ('core','analytics')
ORDER  BY tablename, indexname;
