/* ============================================================
   File    : 04_kpi_views/03_vw_kpi_revenue_concentration.sql
   Stage   : ANALYSE
   Purpose : AQ-02. Revenue concentration (Pareto) across the base.
   Grain   : one row per revenue decile (10 rows).

   Answers BQ-02: is revenue concentrated, or spread across the base?
   If it is spread evenly, segment targeting has no leverage and the remedy is
   structural rather than a targeting exercise — decision branch 2 in the charter.

   The cumulative window runs DESCENDING from decile 10 (highest charge), so
   cumulative_revenue_pct reads as "the top N deciles account for X% of revenue".
   DECILE 1 = LOWEST monthly_charge, DECILE 10 = HIGHEST. Stated because both
   conventions exist in practice.
   ============================================================ */

DROP VIEW IF EXISTS analytics.vw_kpi_revenue_concentration CASCADE;

CREATE VIEW analytics.vw_kpi_revenue_concentration AS
WITH per_decile AS (
    SELECT revenue_decile,
           count(*)                                    AS customers,
           round(min(monthly_charge), 2)               AS charge_min,
           round(max(monthly_charge), 2)               AS charge_max,
           round(sum(annual_recurring_revenue), 2)     AS arr_currency_units
    FROM   analytics.vw_customer_analytical_base
    GROUP  BY revenue_decile
)
SELECT revenue_decile,
       customers,
       charge_min,
       charge_max,
       arr_currency_units,
       round(100.0 * customers / SUM(customers) OVER (), 2)          AS customer_share_pct,
       round(100.0 * arr_currency_units / SUM(arr_currency_units) OVER (), 2)
                                                                     AS revenue_share_pct,
       /* Cumulative from the top decile downward — the Pareto curve. */
       round(SUM(customers) OVER (ORDER BY revenue_decile DESC
                                  ROWS UNBOUNDED PRECEDING)
             * 100.0 / SUM(customers) OVER (), 2)                    AS cumulative_customer_pct,
       round(SUM(arr_currency_units) OVER (ORDER BY revenue_decile DESC
                                           ROWS UNBOUNDED PRECEDING)
             * 100.0 / SUM(arr_currency_units) OVER (), 2)           AS cumulative_revenue_pct,
       'reportable'::text                                            AS cell_size_flag
FROM   per_decile
ORDER  BY revenue_decile DESC;

COMMENT ON VIEW analytics.vw_kpi_revenue_concentration IS
  'AQ-02 / BQ-02. Decile 1 = lowest monthly_charge, decile 10 = highest. '
  'Cumulative columns run from decile 10 downward, so they read as "the top N '
  'deciles hold X% of revenue". Currency UNKNOWN.';

SELECT * FROM analytics.vw_kpi_revenue_concentration;
