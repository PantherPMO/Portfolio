/* ============================================================
   File    : 04_kpi_views/05_vw_kpi_revenue_retention.sql
   Stage   : ANALYSE
   Purpose : Revenue retention rate — the CVM lead's actual target measure.
   Grain   : one row per cohort scope.

   DENOMINATOR: opening recurring revenue for the scope.
   NUMERATOR  : recurring revenue of customers still present at period end.

   Computed on the OPENING COHORT for the headline, consistent with C-3. The
   all-customer figure is reported alongside and is NOT the primary measure,
   because customers acquired within the period were not part of the opening
   revenue base.
   ============================================================ */

DROP VIEW IF EXISTS analytics.vw_kpi_revenue_retention CASCADE;

CREATE VIEW analytics.vw_kpi_revenue_retention AS
WITH scoped AS (
    SELECT 'opening_base' AS scope,
           'PRIMARY — consistent with C-3' AS scope_note, 1 AS scope_order, b.*
    FROM analytics.vw_customer_analytical_base AS b WHERE b.cohort_class = 'opening_base'
    UNION ALL
    SELECT 'ALL', 'Reconciliation only', 2, b.*
    FROM analytics.vw_customer_analytical_base AS b
)
SELECT scope,
       scope_note,
       round(sum(annual_recurring_revenue), 2)                        AS opening_arr_currency_units,
       round(sum(annual_recurring_revenue) FILTER (WHERE NOT is_churned), 2)
                                                                      AS retained_arr_currency_units,
       round(sum(annual_recurring_revenue) FILTER (WHERE is_churned), 2)
                                                                      AS lost_arr_currency_units,
       round(100.0 * sum(annual_recurring_revenue) FILTER (WHERE NOT is_churned)
             / NULLIF(sum(annual_recurring_revenue), 0), 2)           AS revenue_retention_rate_pct,
       /* Customer retention alongside revenue retention: if they differ, the
          leavers are not an average slice of the base. Reported, not interpreted. */
       round(100.0 * count(*) FILTER (WHERE NOT is_churned)
             / NULLIF(count(*), 0), 2)                                AS customer_retention_rate_pct,
       scope_order
FROM   scoped
GROUP  BY scope, scope_note, scope_order
ORDER  BY scope_order;

COMMENT ON VIEW analytics.vw_kpi_revenue_retention IS
  'Revenue retention on the C-2 recurring basis, opening-cohort denominator per '
  'C-3. Customer retention reported alongside for comparison. Currency UNKNOWN.';

SELECT * FROM analytics.vw_kpi_revenue_retention;
