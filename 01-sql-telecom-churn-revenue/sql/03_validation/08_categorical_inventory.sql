/* ============================================================
   File   : 02_eda/08_categorical_inventory.sql
   Stage  : PREPARE — profiling
   Purpose: Full value inventory of every categorical field promoted to core,
            to confirm the loaded values match the Stage 2 verified inventory.
   NOTE   : counts only. No churn or revenue measure — that would be analysis.
   ============================================================ */

SELECT 'contract_type' AS field, contract_type AS value, count(*) AS customers
FROM analytics.vw_customer_analytical_base GROUP BY contract_type
UNION ALL SELECT 'payment_method', payment_method, count(*)
FROM analytics.vw_customer_analytical_base GROUP BY payment_method
UNION ALL SELECT 'internet_type', internet_type, count(*)
FROM analytics.vw_customer_analytical_base GROUP BY internet_type
UNION ALL SELECT 'offer', offer, count(*)
FROM analytics.vw_customer_analytical_base GROUP BY offer
UNION ALL SELECT 'service_intensity_band', service_intensity_band, count(*)
FROM analytics.vw_customer_analytical_base GROUP BY service_intensity_band
UNION ALL SELECT 'value_tier', value_tier, count(*)
FROM analytics.vw_customer_analytical_base GROUP BY value_tier
UNION ALL SELECT 'cohort_class', cohort_class, count(*)
FROM analytics.vw_customer_analytical_base GROUP BY cohort_class
UNION ALL SELECT 'customer_status', customer_status, count(*)
FROM analytics.vw_customer_analytical_base GROUP BY customer_status
UNION ALL SELECT 'is_paperless_billing', is_paperless_billing::text, count(*)
FROM analytics.vw_customer_analytical_base GROUP BY is_paperless_billing
UNION ALL SELECT 'has_referred', has_referred::text, count(*)
FROM analytics.vw_customer_analytical_base GROUP BY has_referred
UNION ALL SELECT 'is_married', is_married::text, count(*)
FROM analytics.vw_customer_analytical_base GROUP BY is_married
UNION ALL SELECT 'has_dependents', has_dependents::text, count(*)
FROM analytics.vw_customer_analytical_base GROUP BY has_dependents
ORDER BY 1, 3 DESC;

/* Expected against Stage 2: Contract 3610/1550/1883; Payment 3909/2749/385;
   Internet Type 3035 Fiber Optic / 1652 DSL / 830 Cable / 1526 No internet;
   Offer 3877 No offer + A 520 / B 824 / C 415 / D 602 / E 805. */

SELECT addon_service_count, count(*) AS customers
FROM   analytics.vw_customer_analytical_base
GROUP  BY addon_service_count ORDER BY addon_service_count;
