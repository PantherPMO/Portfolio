/* ============================================================
   File    : 04_kpi_views/02_vw_kpi_revenue_at_risk.sql
   Stage   : ANALYSE
   Purpose : Annualised revenue at risk. Implements decision C-2.
   Grain   : one row per cohort scope (3 rows).

   C-2 — THE HEADLINE BASIS IS monthly_charge x 12.
   Long-distance revenue is a SEPARATE COLUMN in this same view and is never
   summed into the headline. Keeping both in one view means the headline cannot
   be selected without the long-distance component being visible beside it.

   *** Long-distance revenue is NOT economically irrelevant. *** Its exclusion
   from the headline is a statement about what a retention offer can secure —
   a subscription, not usage volume — not about whether the revenue matters.

   CURRENCY IS UNKNOWN (check P-15). Columns are suffixed _currency_units.
   Never label as GBP, USD or any symbol.

   ALL churned customers are included regardless of cohort, because lost revenue
   is lost whenever the customer joined. The split by cohort is reported so
   retention exposure and onboarding exposure remain distinguishable.
   ============================================================ */

DROP VIEW IF EXISTS analytics.vw_kpi_revenue_at_risk CASCADE;

CREATE VIEW analytics.vw_kpi_revenue_at_risk AS
WITH scoped AS (
    SELECT 'opening_base' AS scope, 1 AS scope_order, b.*
    FROM analytics.vw_customer_analytical_base AS b WHERE b.cohort_class = 'opening_base'
    UNION ALL
    SELECT 'in_period_acquisition', 2, b.*
    FROM analytics.vw_customer_analytical_base AS b WHERE b.cohort_class = 'in_period_acquisition'
    UNION ALL
    SELECT 'ALL', 3, b.* FROM analytics.vw_customer_analytical_base AS b
)
SELECT scope,
       count(*)                                                 AS customers,
       count(*) FILTER (WHERE is_churned)                       AS churned,

       /* --- C-2 HEADLINE: recurring subscription revenue only --- */
       round(sum(annual_recurring_revenue) FILTER (WHERE is_churned), 2)
                                                                AS arr_at_risk_currency_units,
       /* --- C-2 SEPARATE COMPONENT: usage-based, never added to the headline --- */
       round(sum(annual_long_distance_revenue) FILTER (WHERE is_churned), 2)
                                                                AS long_distance_at_risk_currency_units,

       round(sum(annual_recurring_revenue), 2)                  AS arr_total_currency_units,
       round(100.0 * sum(annual_recurring_revenue) FILTER (WHERE is_churned)
             / NULLIF(sum(annual_recurring_revenue), 0), 2)     AS arr_at_risk_pct_of_scope,
       round(avg(annual_recurring_revenue) FILTER (WHERE is_churned), 2)
                                                                AS mean_arr_per_churned_customer,
       CASE WHEN count(*) >= 100 THEN 'reportable'
            WHEN count(*) >= 30  THEN 'caveat_required'
            ELSE 'below_threshold' END                          AS cell_size_flag,
       scope_order
FROM   scoped
GROUP  BY scope, scope_order
ORDER  BY scope_order;

COMMENT ON VIEW analytics.vw_kpi_revenue_at_risk IS
  'C-2. Headline = monthly_charge x 12 over churned customers. Long-distance '
  'revenue is a separate column and must never be added into the headline, but '
  'must always be reported beside it. Currency UNKNOWN — never label with a symbol.';

SELECT * FROM analytics.vw_kpi_revenue_at_risk;
