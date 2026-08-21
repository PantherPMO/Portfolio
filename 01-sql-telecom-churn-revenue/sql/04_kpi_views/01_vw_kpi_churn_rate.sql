/* ============================================================
   Project : 01 — Telecommunications Revenue Retention
   File    : 04_kpi_views/01_vw_kpi_churn_rate.sql
   Stage   : ANALYSE
   Purpose : Churn rate by cohort scope. Implements decision C-3.
   Grain   : one row per cohort scope (3 rows).
   Author  : Peters
   Created : 2026-08-19

   DENOMINATOR (C-3): numerator and denominator are drawn from the SAME scope,
   so every rate is symmetric by construction. The primary KPI is the
   opening-cohort rate; the period-end rate is reported alongside for
   reconciliation with published work on this dataset, which universally uses it.

   FAN-OUT: reads only analytics.vw_customer_analytical_base, which is one row
   per customer. The service bridge is aggregated inside that view.
   ============================================================ */

DROP VIEW IF EXISTS analytics.vw_kpi_churn_rate CASCADE;

CREATE VIEW analytics.vw_kpi_churn_rate AS
WITH scoped AS (
    SELECT 'opening_base'          AS scope,
           'Opening cohort (tenure >= 4) — PRIMARY KPI, C-3' AS scope_note,
           1 AS scope_order, b.*
    FROM   analytics.vw_customer_analytical_base AS b
    WHERE  b.cohort_class = 'opening_base'
    UNION ALL
    SELECT 'in_period_acquisition',
           'Acquired within the observation quarter (tenure <= 3)', 2, b.*
    FROM   analytics.vw_customer_analytical_base AS b
    WHERE  b.cohort_class = 'in_period_acquisition'
    UNION ALL
    SELECT 'ALL',
           'Period-end base — reconciliation only, not the primary KPI', 3, b.*
    FROM   analytics.vw_customer_analytical_base AS b
)
SELECT scope,
       scope_note,
       count(*)                                   AS customers,
       count(*) FILTER (WHERE is_churned)         AS churned,
       count(*) FILTER (WHERE NOT is_churned)     AS retained,
       round(100.0 * count(*) FILTER (WHERE is_churned)
             / NULLIF(count(*), 0), 2)            AS churn_rate_pct,
       round(100.0 * count(*) FILTER (WHERE NOT is_churned)
             / NULLIF(count(*), 0), 2)            AS retention_rate_pct,
       CASE WHEN count(*) >= 100 THEN 'reportable'
            WHEN count(*) >= 30  THEN 'caveat_required'
            ELSE 'below_threshold' END            AS cell_size_flag,
       scope_order
FROM   scoped
GROUP  BY scope, scope_note, scope_order
ORDER  BY scope_order;

COMMENT ON VIEW analytics.vw_kpi_churn_rate IS
  'C-3. Primary KPI = opening-cohort churn rate (expected 21.23%). Period-end '
  'base rate (expected 26.54%) reported alongside for reconciliation only. '
  'Numerator and denominator always drawn from the same scope.';

SELECT * FROM analytics.vw_kpi_churn_rate;
