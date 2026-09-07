/* ============================================================
   Project    : 01 — Telecommunications Revenue Retention
   File       : 03_analysis/01_base_position.sql
   Stage      : ANALYSE
   Question   : AQ-01 / BQ-01 — How much annual recurring revenue are we losing
                to churn?  (trend clause removed: single quarter, no time dimension)
   Finding ID : F-01
   Output     : analysis/query_results/analyse_01_base_position.txt
   Type       : DESCRIPTIVE
   Author     : Peters
   Created    : 2026-08-19

   PRIMARY KPI  : opening-cohort churn rate (C-3), expected 21.23%
   ALONGSIDE    : period-end base rate, expected 26.54%
   REVENUE BASIS: monthly_charge x 12 (C-2). Long distance reported separately.
   CURRENCY     : UNKNOWN (P-15). No symbol anywhere.
   NO TREND     : tenure must NOT be used as a time proxy — it is a cohort
                  artefact, not a time series.
   ============================================================ */

\echo '=== F-01a  Churn rate by cohort scope (C-3) ==='
SELECT scope, scope_note, customers, churned, retained,
       churn_rate_pct, retention_rate_pct, cell_size_flag
FROM   analytics.vw_kpi_churn_rate
ORDER  BY scope_order;

\echo ''
\echo '=== F-01b  Annualised revenue at risk (C-2 basis) ==='
SELECT scope, customers, churned,
       arr_at_risk_currency_units,
       long_distance_at_risk_currency_units,
       arr_total_currency_units,
       arr_at_risk_pct_of_scope,
       mean_arr_per_churned_customer
FROM   analytics.vw_kpi_revenue_at_risk
ORDER  BY scope_order;

\echo ''
\echo '=== F-01c  Revenue retention rate ==='
SELECT scope, scope_note,
       opening_arr_currency_units, retained_arr_currency_units,
       lost_arr_currency_units,
       revenue_retention_rate_pct, customer_retention_rate_pct
FROM   analytics.vw_kpi_revenue_retention
ORDER  BY scope_order;
