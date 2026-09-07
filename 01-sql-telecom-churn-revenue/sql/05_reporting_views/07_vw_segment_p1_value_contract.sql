/* ============================================================
   File    : 04_kpi_views/07_vw_segment_p1_value_contract.sql
   Stage   : ANALYSE
   Purpose : P1 segmentation — Value Tier x Contract. Locked at C-6.
   Grain   : one row per (population_scope, value_tier, contract_type).
             2 scopes x 3 tiers x 3 contracts = up to 18 rows.

   *** POPULATION SCOPE — A-07 LOCKED 19 August 2026 (D-21) ***
   PRIMARY     : 'opening_base'  — both the churn rate and the revenue-at-risk
                 figure are computed from the opening cohort, so the divergence
                 index compares like with like.
   SENSITIVITY : 'all_customers' — retained, clearly labelled, and does NOT
                 replace the primary result.
   Locked before results were seen and not to be changed afterwards.

   Value tiers are NOT recomputed here — they come from the base view, where the
   deterministic NTILE lives (V-11). Recomputing them per scope would produce
   scope-relative deciles and break comparability.

   CELL SIZES: expected minimum 208, from the PREPARE cell-size check.
   ============================================================ */

DROP VIEW IF EXISTS analytics.vw_segment_p1_value_contract CASCADE;

CREATE VIEW analytics.vw_segment_p1_value_contract AS
WITH scoped AS (
    SELECT 'opening_base' AS population_scope, 1 AS scope_order, b.*
    FROM   analytics.vw_customer_analytical_base AS b
    WHERE  b.cohort_class = 'opening_base'
    UNION ALL
    SELECT 'all_customers', 2, b.*
    FROM   analytics.vw_customer_analytical_base AS b
)
SELECT population_scope,
       value_tier,
       contract_type,
       count(*)                                                  AS n,
       count(*) FILTER (WHERE is_churned)                        AS churned,
       round(100.0 * count(*) FILTER (WHERE is_churned)
             / NULLIF(count(*), 0), 2)                           AS churn_rate_pct,
       round(sum(annual_recurring_revenue) FILTER (WHERE is_churned), 2)
                                                                 AS arr_at_risk_currency_units,
       round(sum(annual_long_distance_revenue) FILTER (WHERE is_churned), 2)
                                                                 AS long_distance_at_risk_currency_units,
       round(sum(annual_recurring_revenue), 2)                   AS arr_total_currency_units,
       /* Scope-level churn rate, for the index in vw_segment_divergence.
          The window partitions by scope only, so it reconstitutes the whole
          scope population regardless of how the cells divide it. */
       round(100.0 * SUM(count(*) FILTER (WHERE is_churned)) OVER (PARTITION BY population_scope)
             / NULLIF(SUM(count(*)) OVER (PARTITION BY population_scope), 0), 2)
                                                                 AS scope_churn_rate_pct,
       CASE WHEN count(*) >= 100 THEN 'reportable'
            WHEN count(*) >= 30  THEN 'caveat_required'
            ELSE 'below_threshold' END                           AS cell_size_flag,
       scope_order
FROM   scoped
GROUP  BY population_scope, value_tier, contract_type, scope_order
ORDER  BY scope_order,
         CASE value_tier WHEN 'High' THEN 1 WHEN 'Mid' THEN 2 ELSE 3 END,
         contract_type;

COMMENT ON VIEW analytics.vw_segment_p1_value_contract IS
  'P1, locked at C-6. Value tiers inherited from the base view (deterministic '
  'NTILE, V-11) — never recomputed per scope. Emits BOTH population scopes '
  'because A-07 is open; no headline designated. Currency UNKNOWN.';

SELECT * FROM analytics.vw_segment_p1_value_contract;
