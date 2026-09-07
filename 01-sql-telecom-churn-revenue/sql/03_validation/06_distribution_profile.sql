/* ============================================================
   File   : 02_eda/06_distribution_profile.sql
   Stage  : PREPARE — profiling, not analysis
   Purpose: Record distributions of the analytical fields so the PREPARE
            evidence pack documents what the data looks like before any
            question is asked of it.
   NOTE   : descriptive only. NO business interpretation is drawn here.
            Monetary values are in UNKNOWN currency units (check P-15).
   ============================================================ */

SELECT 'monthly_charge' AS field,
       count(*)                                                        AS n,
       to_char(min(monthly_charge),'FM990.00')                         AS minimum,
       to_char(percentile_cont(0.25) WITHIN GROUP (ORDER BY monthly_charge),'FM990.00') AS p25,
       to_char(percentile_cont(0.50) WITHIN GROUP (ORDER BY monthly_charge),'FM990.00') AS median,
       to_char(percentile_cont(0.75) WITHIN GROUP (ORDER BY monthly_charge),'FM990.00') AS p75,
       to_char(max(monthly_charge),'FM990.00')                         AS maximum,
       to_char(avg(monthly_charge),'FM990.00')                         AS mean,
       to_char(stddev_samp(monthly_charge),'FM990.00')                 AS std_dev
FROM   analytics.vw_customer_analytical_base;

SELECT 'tenure_months' AS field, count(*) AS n,
       min(tenure_months) AS minimum,
       percentile_cont(0.25) WITHIN GROUP (ORDER BY tenure_months) AS p25,
       percentile_cont(0.50) WITHIN GROUP (ORDER BY tenure_months) AS median,
       percentile_cont(0.75) WITHIN GROUP (ORDER BY tenure_months) AS p75,
       max(tenure_months) AS maximum,
       round(avg(tenure_months),2) AS mean
FROM   analytics.vw_customer_analytical_base;

SELECT 'avg_monthly_long_distance' AS field, count(*) AS n,
       to_char(min(avg_monthly_long_distance),'FM990.00')  AS minimum,
       to_char(percentile_cont(0.50) WITHIN GROUP (ORDER BY avg_monthly_long_distance),'FM990.00') AS median,
       to_char(max(avg_monthly_long_distance),'FM990.00')  AS maximum,
       count(*) FILTER (WHERE avg_monthly_long_distance = 0) AS zero_value_customers
FROM   analytics.vw_customer_analytical_base;

/* Invalid-value scan — all expected to be zero. */
SELECT 'monthly_charge <= 0'  AS scan, count(*) AS rows FROM analytics.vw_customer_analytical_base WHERE monthly_charge <= 0
UNION ALL SELECT 'tenure_months < 1', count(*) FROM analytics.vw_customer_analytical_base WHERE tenure_months < 1
UNION ALL SELECT 'tenure_months > 72', count(*) FROM analytics.vw_customer_analytical_base WHERE tenure_months > 72
UNION ALL SELECT 'negative long distance', count(*) FROM analytics.vw_customer_analytical_base WHERE avg_monthly_long_distance < 0
UNION ALL SELECT 'addon_service_count outside 0-8', count(*) FROM analytics.vw_customer_analytical_base WHERE addon_service_count NOT BETWEEN 0 AND 8;

/* Tenure band distribution — structure, not interpretation. */
SELECT tenure_band, count(*) AS customers,
       to_char(100.0*count(*)/sum(count(*)) OVER (),'FM990.0') AS pct_of_base
FROM   analytics.vw_customer_analytical_base
GROUP  BY tenure_band ORDER BY tenure_band;

/* Cohort split — C-3 structure. */
SELECT cohort_class, count(*) AS customers,
       count(*) FILTER (WHERE is_churned) AS churned
FROM   analytics.vw_customer_analytical_base
GROUP  BY cohort_class ORDER BY cohort_class;
