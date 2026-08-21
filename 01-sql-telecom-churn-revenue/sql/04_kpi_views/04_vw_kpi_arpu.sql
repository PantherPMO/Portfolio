/* ============================================================
   File    : 04_kpi_views/04_vw_kpi_arpu.sql
   Stage   : ANALYSE
   Purpose : ARPU by value tier and churn outcome.
   Grain   : one row per (scope, value_tier, churn outcome).

   ARPU here is MONTHLY recurring revenue per customer, consistent with the C-2
   basis. Reported by outcome so the value profile of leavers and stayers is
   visible — but NO comparison is interpreted at this stage.
   ============================================================ */

DROP VIEW IF EXISTS analytics.vw_kpi_arpu CASCADE;

CREATE VIEW analytics.vw_kpi_arpu AS
WITH scoped AS (
    SELECT 'opening_base' AS scope, 1 AS scope_order, b.*
    FROM analytics.vw_customer_analytical_base AS b WHERE b.cohort_class = 'opening_base'
    UNION ALL
    SELECT 'ALL', 2, b.* FROM analytics.vw_customer_analytical_base AS b
)
SELECT scope,
       value_tier,
       CASE WHEN is_churned THEN 'Churned' ELSE 'Retained' END AS outcome,
       count(*)                                                AS customers,
       round(avg(monthly_charge), 2)                           AS arpu_monthly_currency_units,
       round(avg(annual_recurring_revenue), 2)                 AS arpu_annual_currency_units,
       round(avg(avg_monthly_long_distance), 2)                AS mean_monthly_long_distance,
       CASE WHEN count(*) >= 100 THEN 'reportable'
            WHEN count(*) >= 30  THEN 'caveat_required'
            ELSE 'below_threshold' END                         AS cell_size_flag,
       scope_order
FROM   scoped
GROUP  BY scope, value_tier, is_churned, scope_order
ORDER  BY scope_order,
         CASE value_tier WHEN 'High' THEN 1 WHEN 'Mid' THEN 2 ELSE 3 END,
         outcome;

COMMENT ON VIEW analytics.vw_kpi_arpu IS
  'ARPU on the C-2 recurring basis. Long-distance reported separately, never '
  'folded in. Currency UNKNOWN.';

SELECT * FROM analytics.vw_kpi_arpu;
