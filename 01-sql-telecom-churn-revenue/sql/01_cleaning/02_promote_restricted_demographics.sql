/* ============================================================
   File   : 01_cleaning/02_promote_restricted_demographics.sql
   Stage  : PREPARE
   Purpose: raw.demographics -> core.restricted_demographics.

   *** RESTRICTED — DECISION D-15 ***
   These are protected characteristics. They are isolated in their own table
   which NO analytical view joins. Permitted use: descriptive and confounding
   checks only (sql/02_eda/09_confounding_checks.sql). They MUST NOT enter any
   prioritisation rule, segment definition, KPI or recommendation.

   Reason: this project's output is a differentiated retention INVESTMENT
   recommendation. Segmenting spend on a protected characteristic is not a
   defensible commercial recommendation and would raise fair-treatment concerns
   in a regulated market.
   ============================================================ */

TRUNCATE core.restricted_demographics;

INSERT INTO core.restricted_demographics
       (customer_id, gender, age, is_under_30, is_senior_citizen)
SELECT trim(customer_id),
       trim(gender),
       trim(age)::smallint,
       core.yn_to_bool(trim(under_30)),
       core.yn_to_bool(trim(senior_citizen))
FROM   raw.demographics;

/* Stage 2 verified both derived flags agree with age exactly. */
SELECT 'CLEAN-03' AS check_id, 'restricted_demographics rows' AS description,
       7043 AS expected, count(*) AS actual,
       CASE WHEN count(*) = 7043 THEN 'PASS' ELSE 'FAIL' END AS status
FROM   core.restricted_demographics
UNION ALL
SELECT 'CLEAN-04', 'is_senior_citizen <=> age >= 65 (0 = consistent)', 0,
       count(*) FILTER (WHERE is_senior_citizen <> (age >= 65)),
       CASE WHEN count(*) FILTER (WHERE is_senior_citizen <> (age >= 65)) = 0
            THEN 'PASS' ELSE 'FAIL' END
FROM   core.restricted_demographics
UNION ALL
SELECT 'CLEAN-05', 'is_under_30 <=> age < 30 (0 = consistent)', 0,
       count(*) FILTER (WHERE is_under_30 <> (age < 30)),
       CASE WHEN count(*) FILTER (WHERE is_under_30 <> (age < 30)) = 0
            THEN 'PASS' ELSE 'FAIL' END
FROM   core.restricted_demographics;
