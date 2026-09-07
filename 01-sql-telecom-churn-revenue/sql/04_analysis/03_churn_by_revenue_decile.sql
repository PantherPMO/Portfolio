/* ============================================================
   File       : 03_analysis/03_churn_by_revenue_decile.sql
   Stage      : ANALYSE
   Question   : AQ-03 / BQ-03 — Are we losing our most valuable customers, or
                our least valuable ones?
   Finding ID : F-03
   Output     : analysis/query_results/analyse_03_churn_by_decile.txt
   Type       : DIAGNOSTIC

   DENOMINATOR: all customers in the decile, within the same population scope.
   churn_index_vs_scope: 1.00 = at the scope average.
   Both scopes emitted. Each output block now carries population_scope as an
   explicit column so the artefact is self-describing (labelling repair,
   19 Aug 2026). psql \echo writes to stdout, not to the -o file, so section
   headers never reached the committed evidence.
   Cell sizes verified 695-717 at PREPARE.
   ============================================================ */

\echo '=== F-03a  Churn by revenue decile — OPENING COHORT (C-3 primary) ==='
SELECT population_scope,
       revenue_decile, value_tier, n, churned, churn_rate_pct,
       churn_index_vs_scope, charge_min, charge_max,
       arr_at_risk_currency_units, cell_size_flag
FROM   analytics.vw_segment_p2_revenue_decile
WHERE  population_scope = 'opening_base'
ORDER  BY revenue_decile;

\echo ''
\echo '=== F-03b  Churn by revenue decile — ALL CUSTOMERS (reconciliation) ==='
SELECT population_scope,
       revenue_decile, value_tier, n, churned, churn_rate_pct,
       churn_index_vs_scope, arr_at_risk_currency_units, cell_size_flag
FROM   analytics.vw_segment_p2_revenue_decile
WHERE  population_scope = 'all_customers'
ORDER  BY revenue_decile;

\echo ''
\echo '=== F-03c  ARPU by value tier and outcome ==='
SELECT scope, value_tier, outcome, customers,
       arpu_monthly_currency_units, arpu_annual_currency_units,
       mean_monthly_long_distance, cell_size_flag
FROM   analytics.vw_kpi_arpu
ORDER  BY scope_order,
         CASE value_tier WHEN 'High' THEN 1 WHEN 'Mid' THEN 2 ELSE 3 END,
         outcome;
