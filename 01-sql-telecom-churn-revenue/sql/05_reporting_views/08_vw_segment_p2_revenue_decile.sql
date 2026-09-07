/* ============================================================
   File    : 04_kpi_views/08_vw_segment_p2_revenue_decile.sql
   Stage   : ANALYSE
   Purpose : P2 segmentation — churn by revenue decile. AQ-03 / BQ-03.
   Grain   : one row per (population_scope, revenue_decile).

   Answers BQ-03: are we losing our most valuable customers, or our least
   valuable ones? DENOMINATOR is all customers in the decile within the same
   scope — symmetric by construction.

   DECILE 1 = LOWEST monthly_charge, DECILE 10 = HIGHEST.
   Cell sizes verified 695-717 at PREPARE; all reportable.
   ============================================================ */

DROP VIEW IF EXISTS analytics.vw_segment_p2_revenue_decile CASCADE;

CREATE VIEW analytics.vw_segment_p2_revenue_decile AS
WITH scoped AS (
    SELECT 'opening_base' AS population_scope, 1 AS scope_order, b.*
    FROM   analytics.vw_customer_analytical_base AS b
    WHERE  b.cohort_class = 'opening_base'
    UNION ALL
    SELECT 'all_customers', 2, b.*
    FROM   analytics.vw_customer_analytical_base AS b
)
SELECT population_scope,
       revenue_decile,
       CASE WHEN revenue_decile >= 8 THEN 'High'
            WHEN revenue_decile >= 4 THEN 'Mid'
            ELSE 'Low' END                                       AS value_tier,
       count(*)                                                  AS n,
       count(*) FILTER (WHERE is_churned)                        AS churned,
       round(100.0 * count(*) FILTER (WHERE is_churned)
             / NULLIF(count(*), 0), 2)                           AS churn_rate_pct,
       /* Churn index vs the scope rate. 1.00 = at the scope average. */
       round((100.0 * count(*) FILTER (WHERE is_churned) / NULLIF(count(*), 0))
             / NULLIF(100.0 * SUM(count(*) FILTER (WHERE is_churned)) OVER (PARTITION BY population_scope)
                      / NULLIF(SUM(count(*)) OVER (PARTITION BY population_scope), 0), 0), 2)
                                                                 AS churn_index_vs_scope,
       round(min(monthly_charge), 2)                             AS charge_min,
       round(max(monthly_charge), 2)                             AS charge_max,
       round(sum(annual_recurring_revenue) FILTER (WHERE is_churned), 2)
                                                                 AS arr_at_risk_currency_units,
       round(sum(annual_recurring_revenue), 2)                   AS arr_total_currency_units,
       CASE WHEN count(*) >= 100 THEN 'reportable'
            WHEN count(*) >= 30  THEN 'caveat_required'
            ELSE 'below_threshold' END                           AS cell_size_flag,
       scope_order
FROM   scoped
GROUP  BY population_scope, revenue_decile, scope_order
ORDER  BY scope_order, revenue_decile;

COMMENT ON VIEW analytics.vw_segment_p2_revenue_decile IS
  'P2, locked at C-6. Decile 1 = lowest charge, 10 = highest. Deciles inherited '
  'from the base view, never recomputed per scope. Currency UNKNOWN.';

SELECT * FROM analytics.vw_segment_p2_revenue_decile;
