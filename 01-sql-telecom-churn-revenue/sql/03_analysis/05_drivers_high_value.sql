/* ============================================================
   File       : 03_analysis/05_drivers_high_value.sql
   Stage      : ANALYSE
   Question   : AQ-05 / BQ-05 — What characteristics most distinguish high-value
                customers who leave from high-value customers who stay?
   Finding ID : F-05
   Output     : analysis/query_results/analyse_05_drivers_high_value.txt
   Type       : DIAGNOSTIC

   *** ALL SEVEN LENSES ARE REPORTED (C-6 commitment 3), including any showing
   no effect. A lens is never dropped because its result is uninteresting. ***

   SCOPE: opening cohort x High value tier (deciles 8-10), consistent with the
   C-3 primary KPI. The all-customer comparison is in 06_drivers_comparison.sql.

   DENOMINATOR: all customers in that lens segment within the same scope.
   churn_index_vs_scope: 1.00 = at the scope average.

   SMALL CELLS: every row carries n and cell_size_flag. Cells below n=30 are
   FLAGGED AND SHOWN, never silently dropped. Collapsing, if required, is a
   separate documented decision.

   EXCLUSIONS: no restricted or prohibited field appears in any lens. Protected
   characteristics are absent by construction — they are not in the base view.

   LABELLING REPAIR (19 Aug 2026): every block now carries scope_cohort and
   scope_tier as explicit columns. psql \echo writes to stdout, not to the -o
   file, so section headers never reached the committed evidence. The GROUP BY in
   F-05b gains those two columns; both are single-valued under the WHERE clause,
   so this adds no rows and changes no aggregate.
   ============================================================ */

\echo '=== F-05a  All seven driver lenses — OPENING COHORT x HIGH VALUE TIER ==='
SELECT scope_cohort, scope_tier,
       lens_id, lens_name, segment_value, n, pct_of_scope_population,
       churned, churn_rate_pct, scope_churn_rate_pct, churn_index_vs_scope,
       arr_at_risk_currency_units, cell_size_flag
FROM   analytics.vw_driver_lenses
WHERE  scope_cohort = 'opening_base' AND scope_tier = 'High'
ORDER  BY lens_id, churn_index_vs_scope DESC NULLS LAST;

\echo ''
\echo '=== F-05b  Lens coverage check — all seven present, no cell missing ==='
SELECT scope_cohort, scope_tier,
       lens_id, lens_name,
       count(*)                                              AS segments,
       sum(n)                                                AS total_customers,
       count(*) FILTER (WHERE cell_size_flag = 'reportable')      AS reportable,
       count(*) FILTER (WHERE cell_size_flag = 'caveat_required') AS caveat_required,
       count(*) FILTER (WHERE cell_size_flag = 'below_threshold') AS below_threshold
FROM   analytics.vw_driver_lenses
WHERE  scope_cohort = 'opening_base' AND scope_tier = 'High'
GROUP  BY scope_cohort, scope_tier, lens_id, lens_name
ORDER  BY lens_id;

\echo ''
\echo '=== F-05c  Cells requiring a caveat or collapse (n < 100) ==='
\echo '(An empty result means every cell in the High tier is freely reportable.)'
SELECT scope_cohort, scope_tier,
       lens_id, lens_name, segment_value, n, churned, churn_rate_pct, cell_size_flag
FROM   analytics.vw_driver_lenses
WHERE  scope_cohort = 'opening_base' AND scope_tier = 'High'
  AND  cell_size_flag <> 'reportable'
ORDER  BY n;
