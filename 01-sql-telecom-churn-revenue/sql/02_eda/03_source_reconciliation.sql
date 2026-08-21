/* ============================================================
   File   : 02_eda/03_source_reconciliation.sql
   Stage  : PREPARE — validation gate 5
   Purpose: REC-03 to REC-12. Every assertion is against a Stage 2 VERIFIED
            figure. A mismatch means the load is wrong — stop, do not adjust
            the expectation to fit.
   ============================================================ */

SELECT 'REC-03' AS check_id, 'analytical base row count' AS description,
       '7043' AS expected, count(*)::text AS actual,
       CASE WHEN count(*)=7043 THEN 'PASS' ELSE 'FAIL' END AS status
FROM analytics.vw_customer_analytical_base
UNION ALL
SELECT 'REC-04','customer id sets identical across all four core tables','0',
       (SELECT count(*) FROM (
            (SELECT customer_id FROM core.dim_customer
             EXCEPT SELECT customer_id FROM core.dim_location)
             UNION ALL
            (SELECT customer_id FROM core.dim_location
             EXCEPT SELECT customer_id FROM core.dim_customer)
             UNION ALL
            (SELECT customer_id FROM core.dim_customer
             EXCEPT SELECT customer_id FROM core.dim_contract)
             UNION ALL
            (SELECT customer_id FROM core.dim_customer
             EXCEPT SELECT customer_id FROM core.fact_customer_status)
       ) q)::text,
       CASE WHEN (SELECT count(*) FROM (
            (SELECT customer_id FROM core.dim_customer EXCEPT SELECT customer_id FROM core.dim_location)
             UNION ALL
            (SELECT customer_id FROM core.dim_location EXCEPT SELECT customer_id FROM core.dim_customer)
             UNION ALL
            (SELECT customer_id FROM core.dim_customer EXCEPT SELECT customer_id FROM core.dim_contract)
             UNION ALL
            (SELECT customer_id FROM core.dim_customer EXCEPT SELECT customer_id FROM core.fact_customer_status)
       ) q) = 0 THEN 'PASS' ELSE 'FAIL' END
UNION ALL
SELECT 'REC-05','churned customers','1869',
       count(*) FILTER (WHERE is_churned)::text,
       CASE WHEN count(*) FILTER (WHERE is_churned)=1869 THEN 'PASS' ELSE 'FAIL' END
FROM core.fact_customer_status
UNION ALL
SELECT 'REC-06a','customer_status = Stayed','4720',
       count(*) FILTER (WHERE customer_status='Stayed')::text,
       CASE WHEN count(*) FILTER (WHERE customer_status='Stayed')=4720 THEN 'PASS' ELSE 'FAIL' END
FROM core.fact_customer_status
UNION ALL
SELECT 'REC-06b','customer_status = Churned','1869',
       count(*) FILTER (WHERE customer_status='Churned')::text,
       CASE WHEN count(*) FILTER (WHERE customer_status='Churned')=1869 THEN 'PASS' ELSE 'FAIL' END
FROM core.fact_customer_status
UNION ALL
SELECT 'REC-06c','customer_status = Joined','454',
       count(*) FILTER (WHERE customer_status='Joined')::text,
       CASE WHEN count(*) FILTER (WHERE customer_status='Joined')=454 THEN 'PASS' ELSE 'FAIL' END
FROM core.fact_customer_status
UNION ALL
/* REC-08: the reconciliation of record. Revenue identity RECOMPUTED, then
   compared with the loaded source field. total_revenue_source is never used
   for anything else. */
SELECT 'REC-08','revenue identity: max abs diff (recomputed vs source), tolerance 0.01','<= 0.01',
       to_char(max(abs((total_charges - total_refunds + total_extra_data_charges
                        + total_long_distance_charges) - total_revenue_source)),'FM9990.000000'),
       CASE WHEN max(abs((total_charges - total_refunds + total_extra_data_charges
                          + total_long_distance_charges) - total_revenue_source)) <= 0.01
            THEN 'PASS' ELSE 'FAIL' END
FROM core.fact_customer_status
UNION ALL
SELECT 'REC-10','sum(total_charges)','16060725.24',
       to_char(sum(total_charges),'FM99999990.00'),
       CASE WHEN round(sum(total_charges),2) = 16060725.24 THEN 'PASS' ELSE 'FAIL' END
FROM core.fact_customer_status
UNION ALL
SELECT 'REC-11a','min(monthly_charge)','18.25', to_char(min(monthly_charge),'FM990.00'),
       CASE WHEN round(min(monthly_charge),2)=18.25 THEN 'PASS' ELSE 'FAIL' END
FROM core.fact_customer_status
UNION ALL
SELECT 'REC-11b','max(monthly_charge)','118.75', to_char(max(monthly_charge),'FM990.00'),
       CASE WHEN round(max(monthly_charge),2)=118.75 THEN 'PASS' ELSE 'FAIL' END
FROM core.fact_customer_status
UNION ALL
SELECT 'REC-12a','min(tenure_months)','1', min(tenure_months)::text,
       CASE WHEN min(tenure_months)=1 THEN 'PASS' ELSE 'FAIL' END FROM core.fact_customer_status
UNION ALL
SELECT 'REC-12b','max(tenure_months)','72', max(tenure_months)::text,
       CASE WHEN max(tenure_months)=72 THEN 'PASS' ELSE 'FAIL' END FROM core.fact_customer_status
UNION ALL
SELECT 'REC-12c','tenure = 0 count','0', count(*) FILTER (WHERE tenure_months=0)::text,
       CASE WHEN count(*) FILTER (WHERE tenure_months=0)=0 THEN 'PASS' ELSE 'FAIL' END
FROM core.fact_customer_status
ORDER BY 1;

/* REC-09 — informational aggregate for the record. NOT a finding. */
SELECT 'REC-09' AS check_id,
       to_char(sum(monthly_charge),'FM9999990.00')       AS sum_monthly_charge,
       to_char(avg(monthly_charge),'FM990.0000')         AS mean_monthly_charge,
       to_char(percentile_cont(0.5) WITHIN GROUP (ORDER BY monthly_charge),'FM990.00') AS median_monthly_charge
FROM   core.fact_customer_status;
