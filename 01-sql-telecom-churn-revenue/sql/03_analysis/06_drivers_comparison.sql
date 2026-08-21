/* ============================================================
   File       : 03_analysis/06_drivers_comparison.sql
   Stage      : ANALYSE
   Question   : AQ-06 — Do high-value drivers differ from base-wide drivers?
   Finding ID : F-06
   Output     : analysis/query_results/analyse_06_drivers_comparison.txt
   Type       : DIAGNOSTIC

   *** THE ANALYTICAL CRUX. ***
   Charter risk R-04: if high-value churn drivers prove indistinguishable from
   base-wide drivers, that is a LEGITIMATE NULL RESULT and will be reported as
   one. It is not grounds for trying another lens until something appears.
   The prioritisation argument survives on concentration (AQ-02/03) regardless.

   COMPARISON MEASURE: difference in churn_index_vs_scope between the High-tier
   scope and the all-customer scope, within the same cohort. Comparing INDICES
   rather than raw rates normalises for the two scopes having different base
   rates — without it, every High-tier segment would appear to differ simply
   because the tier's overall rate differs.

   Both scopes use the OPENING COHORT, so the comparison is like-for-like.
   ============================================================ */

\echo '=== F-06a  High tier vs all customers — churn index by lens and segment ==='
SELECT h.lens_id, h.lens_name, h.segment_value,
       a.n                        AS n_all,
       a.churn_rate_pct           AS churn_rate_all_pct,
       a.churn_index_vs_scope     AS index_all,
       h.n                        AS n_high,
       h.churn_rate_pct           AS churn_rate_high_pct,
       h.churn_index_vs_scope     AS index_high,
       round(h.churn_index_vs_scope - a.churn_index_vs_scope, 2) AS index_difference,
       h.cell_size_flag           AS high_cell_flag
FROM       analytics.vw_driver_lenses AS h
INNER JOIN analytics.vw_driver_lenses AS a
        ON  a.lens_id       = h.lens_id
        AND a.segment_value = h.segment_value
        AND a.scope_cohort  = h.scope_cohort
        AND a.scope_tier    = 'ALL'
WHERE  h.scope_cohort = 'opening_base'
  AND  h.scope_tier   = 'High'
ORDER  BY h.lens_id, abs(COALESCE(h.churn_index_vs_scope - a.churn_index_vs_scope, 0)) DESC;

\echo ''
\echo '=== F-06b  Per-lens summary — how much does the High tier differ at all? ==='
\echo '(max_abs_index_difference near zero for a lens = a null result for that lens.)'
SELECT h.lens_id, h.lens_name,
       count(*)                                                          AS segments_compared,
       round(max(abs(h.churn_index_vs_scope - a.churn_index_vs_scope)), 2) AS max_abs_index_difference,
       round(avg(abs(h.churn_index_vs_scope - a.churn_index_vs_scope)), 2) AS mean_abs_index_difference
FROM       analytics.vw_driver_lenses AS h
INNER JOIN analytics.vw_driver_lenses AS a
        ON  a.lens_id       = h.lens_id
        AND a.segment_value = h.segment_value
        AND a.scope_cohort  = h.scope_cohort
        AND a.scope_tier    = 'ALL'
WHERE  h.scope_cohort = 'opening_base' AND h.scope_tier = 'High'
GROUP  BY h.lens_id, h.lens_name
ORDER  BY h.lens_id;

\echo ''
\echo '=== F-06c  All seven lenses, ALL CUSTOMERS, opening cohort (base-wide reference) ==='
SELECT lens_id, lens_name, segment_value, n, pct_of_scope_population,
       churned, churn_rate_pct, churn_index_vs_scope,
       arr_at_risk_currency_units, cell_size_flag
FROM   analytics.vw_driver_lenses
WHERE  scope_cohort = 'opening_base' AND scope_tier = 'ALL'
ORDER  BY lens_id, churn_index_vs_scope DESC NULLS LAST;
