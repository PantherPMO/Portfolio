/* ============================================================
   Project : 01 — Telecommunications Revenue Retention
   File    : 00_setup/01_create_schemas.sql
   Stage   : PREPARE
   Purpose : Create the three-layer schema architecture.
             raw       = landing zone, all TEXT, immutable after load
             core      = typed, keyed, constrained; excluded fields ABSENT
             analytics = derived attributes and the analytical surface
   Author  : Peters
   Created : 2026-08-19
   ============================================================ */

-- Creates ONLY these three schemas. No other database object is touched.

CREATE SCHEMA IF NOT EXISTS raw;
CREATE SCHEMA IF NOT EXISTS core;
CREATE SCHEMA IF NOT EXISTS analytics;

COMMENT ON SCHEMA raw IS
  'Landing zone. Source data as supplied, all columns TEXT. Immutable after load. '
  'Contains fields excluded from analysis (Satisfaction Score, Churn Score, CLTV, '
  'Churn Reason, Churn Category) so the exclusion remains auditable. '
  'NEVER referenced by analytics.';

COMMENT ON SCHEMA core IS
  'Typed, constrained, referentially enforced. One row per customer. '
  'Excluded fields are ABSENT, not filtered. Restricted protected-characteristic '
  'fields are isolated in core.restricted_demographics, which no analytical view joins.';

COMMENT ON SCHEMA analytics IS
  'Derived attributes, segmentation and KPI surface. '
  'analytics.vw_customer_analytical_base is the single analytical grain.';

-- Verification
SELECT nspname AS schema_created
FROM   pg_namespace
WHERE  nspname IN ('raw','core','analytics')
ORDER  BY nspname;
