/* ============================================================
   File    : 04_kpi_views/06_vw_kpi_early_life_churn.sql
   Stage   : ANALYSE
   Purpose : C-3. Early-life churn, reported SEPARATELY from base retention.
   Grain   : one row per tenure month 1-3, plus a TOTAL row.

   WHY SEPARATE (C-3): 597 customers joined AND left within the observation
   quarter. Early-life churn is an onboarding and acquisition-quality question;
   established-base churn is a retention question. Different budget, different
   owner, different intervention. Pooling them would produce a driver profile
   that describes neither.

   TWO DENOMINATORS, both labelled:
     pct_of_all_churn            = share of the 1,869 total churned customers
     pct_of_in_period_acquisitions = share of the 1,051 customers acquired in-period
   Neither is "the" rate; both are stated so the figure cannot be misread.
   ============================================================ */

DROP VIEW IF EXISTS analytics.vw_kpi_early_life_churn CASCADE;

CREATE VIEW analytics.vw_kpi_early_life_churn AS
WITH totals AS (
    SELECT count(*) FILTER (WHERE is_churned)                            AS all_churn,
           count(*) FILTER (WHERE cohort_class = 'in_period_acquisition') AS all_in_period
    FROM   analytics.vw_customer_analytical_base
),
by_month AS (
    SELECT tenure_months::text                             AS tenure_month,
           tenure_months                                   AS sort_key,
           count(*)                                        AS acquisitions,
           count(*) FILTER (WHERE is_churned)              AS churned,
           round(sum(annual_recurring_revenue) FILTER (WHERE is_churned), 2)
                                                           AS arr_at_risk_currency_units,
           round(sum(annual_long_distance_revenue) FILTER (WHERE is_churned), 2)
                                                           AS long_distance_at_risk_currency_units
    FROM   analytics.vw_customer_analytical_base
    WHERE  cohort_class = 'in_period_acquisition'
    GROUP  BY tenure_months
    UNION ALL
    SELECT 'TOTAL (months 1-3)', 99,
           count(*), count(*) FILTER (WHERE is_churned),
           round(sum(annual_recurring_revenue) FILTER (WHERE is_churned), 2),
           round(sum(annual_long_distance_revenue) FILTER (WHERE is_churned), 2)
    FROM   analytics.vw_customer_analytical_base
    WHERE  cohort_class = 'in_period_acquisition'
)
SELECT m.tenure_month,
       m.acquisitions,
       m.churned,
       round(100.0 * m.churned / NULLIF(m.acquisitions, 0), 2) AS churn_rate_within_month_pct,
       round(100.0 * m.churned / NULLIF(t.all_churn, 0), 2)    AS pct_of_all_churn,
       round(100.0 * m.churned / NULLIF(t.all_in_period, 0), 2) AS pct_of_in_period_acquisitions,
       m.arr_at_risk_currency_units,
       m.long_distance_at_risk_currency_units,
       CASE WHEN m.acquisitions >= 100 THEN 'reportable'
            WHEN m.acquisitions >= 30  THEN 'caveat_required'
            ELSE 'below_threshold' END                        AS cell_size_flag
FROM   by_month AS m CROSS JOIN totals AS t
ORDER  BY m.sort_key;

COMMENT ON VIEW analytics.vw_kpi_early_life_churn IS
  'C-3. In-period acquisitions (tenure <= 3) reported separately from base '
  'retention. Two denominators, both labelled. Currency UNKNOWN.';

SELECT * FROM analytics.vw_kpi_early_life_churn;
