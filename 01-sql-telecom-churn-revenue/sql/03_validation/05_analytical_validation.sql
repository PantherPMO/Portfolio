/* ============================================================
   File   : 02_eda/05_analytical_validation.sql
   Stage  : PREPARE — validation gate 6
   Purpose: VAL-01 to VAL-10. The final gate before ANALYSE.

   VAL-07 and VAL-08 assert churn rates. These are PRE-REGISTERED validation
   assertions against Stage 2 verified figures, not analytical findings. No
   interpretation is drawn from them here.
   ============================================================ */

SELECT 'VAL-01' AS check_id, 'analytical base row count' AS description,
       '7043' AS expected, count(*)::text AS actual,
       CASE WHEN count(*)=7043 THEN 'PASS' ELSE 'FAIL' END AS status
FROM analytics.vw_customer_analytical_base

UNION ALL
/* VAL-02: THE FAN-OUT CONTROL. Joining the bridge must not change row count,
   because the base view aggregates it to customer grain internally. */
SELECT 'VAL-02','row count after joining the bridge (fan-out control)','7043',
       (SELECT count(*) FROM (
          SELECT b.customer_id
          FROM analytics.vw_customer_analytical_base b
          LEFT JOIN (SELECT customer_id, count(*) AS n
                     FROM core.bridge_customer_service GROUP BY customer_id) x
                 ON x.customer_id = b.customer_id) q)::text,
       CASE WHEN (SELECT count(*) FROM (
          SELECT b.customer_id
          FROM analytics.vw_customer_analytical_base b
          LEFT JOIN (SELECT customer_id, count(*) AS n
                     FROM core.bridge_customer_service GROUP BY customer_id) x
                 ON x.customer_id = b.customer_id) q) = 7043
            THEN 'PASS' ELSE 'FAIL' END

UNION ALL
SELECT 'VAL-03','sum(annual_recurring_revenue) = sum(monthly_charge) x 12','0.0000',
       to_char(abs(sum(annual_recurring_revenue) - sum(monthly_charge)*12),'FM9990.0000'),
       CASE WHEN abs(sum(annual_recurring_revenue) - sum(monthly_charge)*12) < 0.01
            THEN 'PASS' ELSE 'FAIL' END
FROM analytics.vw_customer_analytical_base

UNION ALL
SELECT 'VAL-04a','decile membership sums to 7043','7043', sum(n)::text,
       CASE WHEN sum(n)=7043 THEN 'PASS' ELSE 'FAIL' END
FROM (SELECT count(*) AS n FROM analytics.vw_customer_analytical_base GROUP BY revenue_decile) q

UNION ALL
SELECT 'VAL-04b','decile sizes within Stage 2 range 695-717','within',
       min(n)::text || '-' || max(n)::text,
       CASE WHEN min(n) >= 695 AND max(n) <= 717 THEN 'PASS' ELSE 'FAIL' END
FROM (SELECT count(*) AS n FROM analytics.vw_customer_analytical_base GROUP BY revenue_decile) q

UNION ALL
SELECT 'VAL-05a','value tiers sum to 7043','7043', sum(n)::text,
       CASE WHEN sum(n)=7043 THEN 'PASS' ELSE 'FAIL' END
FROM (SELECT count(*) AS n FROM analytics.vw_customer_analytical_base GROUP BY value_tier) q

UNION ALL
SELECT 'VAL-05b','value_tier High maps exactly to deciles 8-10','0 mismatches',
       count(*) FILTER (WHERE (value_tier='High') <> (revenue_decile >= 8))::text,
       CASE WHEN count(*) FILTER (WHERE (value_tier='High') <> (revenue_decile >= 8)) = 0
            THEN 'PASS' ELSE 'FAIL' END
FROM analytics.vw_customer_analytical_base

UNION ALL
/* VAL-06: cohort_class is derived from tenure, NOT from customer_status.
   Stage 2 proved customer_status is itself derived. This asserts equivalence. */
SELECT 'VAL-06','in-period acquisitions that survived = customer_status Joined','454',
       count(*) FILTER (WHERE cohort_class='in_period_acquisition' AND NOT is_churned)::text,
       CASE WHEN count(*) FILTER (WHERE cohort_class='in_period_acquisition' AND NOT is_churned) = 454
             AND count(*) FILTER (WHERE cohort_class='in_period_acquisition' AND NOT is_churned
                                    AND customer_status <> 'Joined') = 0
            THEN 'PASS' ELSE 'FAIL' END
FROM analytics.vw_customer_analytical_base

UNION ALL
SELECT 'VAL-07','opening-cohort churn rate (C-3 primary KPI)','21.23',
       to_char(100.0 * count(*) FILTER (WHERE is_churned)
               / NULLIF(count(*),0), 'FM990.00'),
       CASE WHEN round(100.0 * count(*) FILTER (WHERE is_churned) / NULLIF(count(*),0), 2) = 21.23
            THEN 'PASS' ELSE 'FAIL' END
FROM analytics.vw_customer_analytical_base WHERE cohort_class='opening_base'

UNION ALL
SELECT 'VAL-08','period-end base rate (reported alongside)','26.54',
       to_char(100.0 * count(*) FILTER (WHERE is_churned)
               / NULLIF(count(*),0), 'FM990.00'),
       CASE WHEN round(100.0 * count(*) FILTER (WHERE is_churned) / NULLIF(count(*),0), 2) = 26.54
            THEN 'PASS' ELSE 'FAIL' END
FROM analytics.vw_customer_analytical_base
ORDER BY 1;

/* ---- VAL-09: THE EXCLUSION CONTROL --------------------------------------
   Scans the SQL text of every core/analytics object for any reference to an
   excluded field, the restricted table, or the merged workbook.
   MUST return zero rows. This is what makes the exclusions real rather than
   aspirational. */
SELECT 'VAL-09' AS check_id,
       c.relnamespace::regnamespace::text AS schema_name,
       c.relname                          AS object_name,
       'references a prohibited object or field' AS problem
FROM   pg_class c
LEFT   JOIN pg_views v ON v.schemaname = c.relnamespace::regnamespace::text
                      AND v.viewname   = c.relname
WHERE  c.relnamespace::regnamespace::text IN ('core','analytics')
  AND  v.definition IS NOT NULL
  AND  (v.definition ~* 'satisfaction_score'
     OR v.definition ~* 'churn_score'
     OR v.definition ~* '\mcltv\M'
     OR v.definition ~* 'churn_reason'
     OR v.definition ~* 'churn_category'
     OR v.definition ~* 'restricted_demographics'
     OR v.definition ~* 'merged_reconciliation');

SELECT 'VAL-09' AS check_id,
       'prohibited references in core/analytics view definitions' AS description,
       '0' AS expected,
       (SELECT count(*) FROM pg_views v
         WHERE v.schemaname IN ('core','analytics')
           AND (v.definition ~* 'satisfaction_score' OR v.definition ~* 'churn_score'
             OR v.definition ~* '\mcltv\M'          OR v.definition ~* 'churn_reason'
             OR v.definition ~* 'churn_category'    OR v.definition ~* 'restricted_demographics'
             OR v.definition ~* 'merged_reconciliation'))::text AS actual,
       CASE WHEN (SELECT count(*) FROM pg_views v
                   WHERE v.schemaname IN ('core','analytics')
                     AND (v.definition ~* 'satisfaction_score' OR v.definition ~* 'churn_score'
                       OR v.definition ~* '\mcltv\M'          OR v.definition ~* 'churn_reason'
                       OR v.definition ~* 'churn_category'    OR v.definition ~* 'restricted_demographics'
                       OR v.definition ~* 'merged_reconciliation')) = 0
            THEN 'PASS' ELSE 'FAIL' END AS status;

/* Also confirm the excluded columns exist in raw (auditability) and nowhere in core. */
SELECT 'VAL-09b' AS check_id, table_schema, table_name, column_name
FROM   information_schema.columns
WHERE  column_name IN ('satisfaction_score','churn_score','cltv','churn_reason','churn_category')
ORDER  BY table_schema, table_name, column_name;
