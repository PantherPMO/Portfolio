/* ============================================================
   File   : 02_eda/09_confounding_checks.sql
   Stage  : PREPARE — profiling

   *** THE ONLY SCRIPT PERMITTED TO REFERENCE core.restricted_demographics ***

   PURPOSE : descriptive confounding checks on protected characteristics.
   PROHIBITED (decision D-15):
     - using these fields in any prioritisation rule
     - using them as a segment in P1, P2 or any driver lens
     - using them in any KPI, recommendation or README finding

   WHY THIS SCRIPT EXISTS AT ALL: if a protected characteristic is strongly
   associated with an approved segment, an apparently value-based recommendation
   could act as a proxy for it. Checking is how that risk is detected. Not
   checking is not the same as not discriminating.

   The output is a DISTRIBUTION check — deliberately no churn or revenue measure
   is crossed with these fields at PREPARE stage.
   ============================================================ */

/* Are protected characteristics evenly spread across the approved segments?
   A strong skew is a flag for the Limitations section, not a finding. */
SELECT 'age band x value_tier' AS check_name,
       CASE WHEN r.age < 30 THEN 'Under 30'
            WHEN r.age < 45 THEN '30-44'
            WHEN r.age < 65 THEN '45-64'
            ELSE '65+' END        AS age_band,
       b.value_tier,
       count(*)                   AS customers,
       to_char(100.0*count(*)/sum(count(*)) OVER (PARTITION BY b.value_tier),'FM990.0') AS pct_within_tier
FROM   analytics.vw_customer_analytical_base AS b
JOIN   core.restricted_demographics          AS r ON r.customer_id = b.customer_id
GROUP  BY 2, b.value_tier
ORDER  BY b.value_tier, 2;

SELECT 'gender x value_tier' AS check_name, r.gender, b.value_tier, count(*) AS customers,
       to_char(100.0*count(*)/sum(count(*)) OVER (PARTITION BY b.value_tier),'FM990.0') AS pct_within_tier
FROM   analytics.vw_customer_analytical_base AS b
JOIN   core.restricted_demographics          AS r ON r.customer_id = b.customer_id
GROUP  BY r.gender, b.value_tier
ORDER  BY b.value_tier, r.gender;

SELECT 'senior citizen x contract' AS check_name,
       r.is_senior_citizen, b.contract_type, count(*) AS customers,
       to_char(100.0*count(*)/sum(count(*)) OVER (PARTITION BY b.contract_type),'FM990.0') AS pct_within_contract
FROM   analytics.vw_customer_analytical_base AS b
JOIN   core.restricted_demographics          AS r ON r.customer_id = b.customer_id
GROUP  BY r.is_senior_citizen, b.contract_type
ORDER  BY b.contract_type, r.is_senior_citizen;
