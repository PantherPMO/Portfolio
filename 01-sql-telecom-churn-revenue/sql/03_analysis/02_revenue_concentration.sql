/* ============================================================
   File       : 03_analysis/02_revenue_concentration.sql
   Stage      : ANALYSE
   Question   : AQ-02 / BQ-02 — Is lost revenue concentrated in a few segments,
                or spread across the base?
   Finding ID : F-02
   Output     : analysis/query_results/analyse_02_revenue_concentration.txt
   Type       : DESCRIPTIVE

   Decides whether targeting is a viable strategy at all. If revenue is spread
   evenly, targeting has no leverage and the remedy is structural — charter
   decision branch 2.

   DECILE 1 = LOWEST monthly_charge, DECILE 10 = HIGHEST.
   Cumulative columns run from decile 10 downward.
   ============================================================ */

\echo '=== F-02a  Revenue concentration by decile (Pareto curve) ==='
SELECT revenue_decile, customers, charge_min, charge_max,
       arr_currency_units, customer_share_pct, revenue_share_pct,
       cumulative_customer_pct, cumulative_revenue_pct
FROM   analytics.vw_kpi_revenue_concentration
ORDER  BY revenue_decile DESC;

\echo ''
\echo '=== F-02b  Headline concentration measures ==='
SELECT 'Top decile (10) share of recurring revenue' AS measure,
       revenue_share_pct AS value_pct
FROM   analytics.vw_kpi_revenue_concentration WHERE revenue_decile = 10
UNION ALL
SELECT 'Top 2 deciles (9-10) cumulative share', cumulative_revenue_pct
FROM   analytics.vw_kpi_revenue_concentration WHERE revenue_decile = 9
UNION ALL
SELECT 'Top 3 deciles (8-10) = High value tier', cumulative_revenue_pct
FROM   analytics.vw_kpi_revenue_concentration WHERE revenue_decile = 8
UNION ALL
SELECT 'Bottom 3 deciles (1-3) = Low value tier',
       round(sum(revenue_share_pct), 2)
FROM   analytics.vw_kpi_revenue_concentration WHERE revenue_decile <= 3;
