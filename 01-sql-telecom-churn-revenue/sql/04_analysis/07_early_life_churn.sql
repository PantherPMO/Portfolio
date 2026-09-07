/* ============================================================
   File       : 03_analysis/07_early_life_churn.sql
   Stage      : ANALYSE
   Question   : C-3 — Early-life churn, reported SEPARATELY from base retention.
   Finding ID : F-07
   Output     : analysis/query_results/analyse_07_early_life_churn.txt
   Type       : DESCRIPTIVE

   597 customers joined AND left within the observation quarter. Early-life churn
   is an onboarding and acquisition-quality question; established-base churn is a
   retention question. Different budget, different owner, different intervention.
   Pooling them would produce a driver profile describing neither.

   TWO DENOMINATORS, both labelled. Neither is "the" rate.

   LABELLING REPAIR (19 Aug 2026): each block now carries its population scope as
   an explicit column. F-07a's literal reflects the view's own definition — 
   vw_kpi_early_life_churn is defined solely over in-period acquisitions.
   ============================================================ */

\echo '=== F-07a  Early-life churn by tenure month ==='
SELECT 'in_period_acquisition'::text AS population_scope,
       tenure_month, acquisitions, churned,
       churn_rate_within_month_pct,
       pct_of_all_churn,
       pct_of_in_period_acquisitions,
       arr_at_risk_currency_units,
       long_distance_at_risk_currency_units,
       cell_size_flag
FROM   analytics.vw_kpi_early_life_churn;

\echo ''
\echo '=== F-07b  Driver lenses within in-period acquisitions (all seven) ==='
\echo '(Reported separately per C-3 — never pooled with the opening base.)'
SELECT scope_cohort, scope_tier,
       lens_id, lens_name, segment_value, n, pct_of_scope_population,
       churned, churn_rate_pct, scope_churn_rate_pct, churn_index_vs_scope,
       arr_at_risk_currency_units, cell_size_flag
FROM   analytics.vw_driver_lenses
WHERE  scope_cohort = 'in_period_acquisition' AND scope_tier = 'ALL'
ORDER  BY lens_id, churn_index_vs_scope DESC NULLS LAST;

\echo ''
\echo '=== F-07c  Cohort split of total revenue at risk (C-2 basis) ==='
SELECT scope, churned,
       arr_at_risk_currency_units,
       long_distance_at_risk_currency_units,
       round(100.0 * arr_at_risk_currency_units
             / NULLIF(SUM(arr_at_risk_currency_units)
                      FILTER (WHERE scope <> 'ALL') OVER (), 0), 2)
                                             AS pct_of_total_arr_at_risk
FROM   analytics.vw_kpi_revenue_at_risk
ORDER  BY scope_order;
