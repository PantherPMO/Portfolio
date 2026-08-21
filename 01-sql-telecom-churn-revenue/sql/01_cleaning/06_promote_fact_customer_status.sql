/* ============================================================
   File   : 01_cleaning/06_promote_fact_customer_status.sql
   Stage  : PREPARE
   Purpose: raw.services + raw.status -> core.fact_customer_status.

   FIVE FIELDS ARE DELIBERATELY NOT PROMOTED (D-11..D-14, D-18):
     Satisfaction Score  outcome-contaminated (100% churn at 1-2, 0% at 4-5)
     Churn Score         predictive model output — target leakage
     CLTV                project 07 scope + undocumented black-box prediction
     Churn Reason        outcome-derived; would collapse AQ-05/06 to a GROUP BY
     Churn Category      same basis as Churn Reason
   They remain in raw so the exclusion is auditable. They exist nowhere in core.

   Churn Label is checked for agreement with Churn Value, then dropped —
   churn_value is authoritative.
   ============================================================ */

TRUNCATE core.fact_customer_status;

INSERT INTO core.fact_customer_status
       (customer_id, quarter, tenure_months, monthly_charge,
        avg_monthly_long_distance, avg_monthly_gb, total_charges, total_refunds,
        total_extra_data_charges, total_long_distance_charges, total_revenue_source,
        customer_status, is_churned)
SELECT trim(sv.customer_id),
       trim(sv.quarter),
       trim(sv.tenure_in_months)::smallint,
       trim(sv.monthly_charge)::numeric(12,4),
       trim(sv.avg_monthly_long_distance_charges)::numeric(12,4),
       trim(sv.avg_monthly_gb_download)::smallint,
       trim(sv.total_charges)::numeric(12,4),
       trim(sv.total_refunds)::numeric(12,4),
       trim(sv.total_extra_data_charges)::numeric(12,4),
       trim(sv.total_long_distance_charges)::numeric(12,4),
       trim(sv.total_revenue)::numeric(12,4),
       trim(st.customer_status),
       CASE trim(st.churn_value) WHEN '1' THEN true WHEN '0' THEN false
            ELSE NULL END
FROM   raw.services AS sv
JOIN   raw.status   AS st ON st.customer_id = sv.customer_id;
-- NOT NULL on is_churned makes any churn_value outside {0,1} fail the load.

SELECT 'CLEAN-12' AS check_id, 'fact rows' AS description, 7043 AS expected,
       count(*) AS actual,
       CASE WHEN count(*) = 7043 THEN 'PASS' ELSE 'FAIL' END AS status
FROM   core.fact_customer_status
UNION ALL
SELECT 'CLEAN-13', 'churned customers', 1869, count(*) FILTER (WHERE is_churned),
       CASE WHEN count(*) FILTER (WHERE is_churned) = 1869 THEN 'PASS' ELSE 'FAIL' END
FROM   core.fact_customer_status
UNION ALL
SELECT 'CLEAN-14', 'quarter is constant Q3', 1, count(DISTINCT quarter),
       CASE WHEN count(DISTINCT quarter) = 1 AND min(quarter) = 'Q3' THEN 'PASS' ELSE 'FAIL' END
FROM   core.fact_customer_status
UNION ALL
SELECT 'CLEAN-15', 'REC-07: raw Churn Label vs Churn Value disagreements', 0,
       count(*) FILTER (WHERE (trim(churn_label) = 'Yes') <> (trim(churn_value) = '1')),
       CASE WHEN count(*) FILTER (WHERE (trim(churn_label) = 'Yes') <> (trim(churn_value) = '1')) = 0
            THEN 'PASS' ELSE 'FAIL' END
FROM   raw.status
UNION ALL
SELECT 'CLEAN-16', 'tenure = 0 rows (relational source has none)', 0,
       count(*) FILTER (WHERE tenure_months = 0),
       CASE WHEN count(*) FILTER (WHERE tenure_months = 0) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM   core.fact_customer_status;
