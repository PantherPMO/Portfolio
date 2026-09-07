/* ============================================================
   Project : 01 — Telecommunications Revenue Retention
   File    : 02_eda/04_merged_cross_check.sql
   Stage   : PREPARE — validation gate 5
   Purpose : REC-13 to REC-18. Cross-check the merged workbook against the
             authoritative relational source.
   Revised : 2026-08-19 — DEFECT FIX.

   *** BUG FIXED ***
   The original CTE was  SELECT trim(customer_id) AS customer_id, * FROM ...
   which produced TWO columns named customer_id, making JOIN ... USING
   (customer_id) ambiguous. The statement errored and REC-13 to REC-18 never
   ran — only the trailing detail query produced output. Columns are now
   selected explicitly.

   READ THIS BEFORE INTERPRETING THE OUTPUT:
   REC-15 to REC-18 are EXPECTED TO DISAGREE. They pass by reproducing the
   documented defect counts exactly — that is the evidence base for decision
   C-1 / D-06. If a count differs from the expectation, the C-1 evidence needs
   re-examination and work stops.

   This is the ONLY script permitted to reference raw.merged_reconciliation.
   ============================================================ */

WITH m AS (
    SELECT trim(customer_id)   AS customer_id,
           trim(tenure_months) AS tenure_months,
           total_charges       AS total_charges_raw,
           trim(monthly_charges) AS monthly_charges,
           trim(churn_value)     AS churn_value,
           trim(payment_method)  AS payment_method,
           trim(internet_service) AS internet_service
    FROM   raw.merged_reconciliation
)

SELECT 'REC-13' AS check_id,
       'monthly_charge agreement (expect full agreement)' AS description,
       '0' AS expected_disagreements,
       count(*) FILTER (WHERE round(m.monthly_charges::numeric, 4)
                           <> round(f.monthly_charge, 4))::text AS actual,
       CASE WHEN count(*) FILTER (WHERE round(m.monthly_charges::numeric, 4)
                                     <> round(f.monthly_charge, 4)) = 0
            THEN 'PASS' ELSE 'FAIL' END AS status
FROM m JOIN core.fact_customer_status AS f USING (customer_id)

UNION ALL
SELECT 'REC-14', 'churn_value agreement (expect full agreement)', '0',
       count(*) FILTER (WHERE (m.churn_value = '1') <> f.is_churned)::text,
       CASE WHEN count(*) FILTER (WHERE (m.churn_value = '1') <> f.is_churned) = 0
            THEN 'PASS' ELSE 'FAIL' END
FROM m JOIN core.fact_customer_status AS f USING (customer_id)

UNION ALL
SELECT 'REC-15', 'tenure disagreement — DEFECT, expect exactly 11', '11',
       count(*) FILTER (WHERE m.tenure_months::int <> f.tenure_months)::text,
       CASE WHEN count(*) FILTER (WHERE m.tenure_months::int <> f.tenure_months) = 11
            THEN 'PASS' ELSE 'FAIL' END
FROM m JOIN core.fact_customer_status AS f USING (customer_id)

UNION ALL
SELECT 'REC-16', 'merged Total Charges blank/non-numeric — DEFECT, expect exactly 11', '11',
       count(*) FILTER (WHERE trim(COALESCE(m.total_charges_raw, ''))
                              !~ '^[0-9]+(\.[0-9]+)?$')::text,
       CASE WHEN count(*) FILTER (WHERE trim(COALESCE(m.total_charges_raw, ''))
                                        !~ '^[0-9]+(\.[0-9]+)?$') = 11
            THEN 'PASS' ELSE 'FAIL' END
FROM m

UNION ALL
SELECT 'REC-17a', 'payment method reclassified Mailed check -> Credit Card — expect 1227', '1227',
       count(*) FILTER (WHERE m.payment_method = 'Mailed check'
                          AND k.payment_method = 'Credit Card')::text,
       CASE WHEN count(*) FILTER (WHERE m.payment_method = 'Mailed check'
                                    AND k.payment_method = 'Credit Card') = 1227
            THEN 'PASS' ELSE 'FAIL' END
FROM m JOIN core.dim_contract AS k USING (customer_id)

UNION ALL
SELECT 'REC-17b', 'merged ''Electronic check'' (absent from source taxonomy) — expect 2365', '2365',
       count(*) FILTER (WHERE m.payment_method = 'Electronic check')::text,
       CASE WHEN count(*) FILTER (WHERE m.payment_method = 'Electronic check') = 2365
            THEN 'PASS' ELSE 'FAIL' END
FROM m

UNION ALL
SELECT 'REC-18', 'Cable customers absorbed into DSL/Fiber by the merged file — expect 830', '830',
       count(*) FILTER (WHERE k.internet_type = 'Cable')::text,
       CASE WHEN count(*) FILTER (WHERE k.internet_type = 'Cable') = 830
            THEN 'PASS' ELSE 'FAIL' END
FROM m JOIN core.dim_contract AS k USING (customer_id)
ORDER BY 1;

/* Detail for the record: how the merged file distributed the 830 Cable customers.
   Confirmed in the first run: 769 -> DSL, 61 -> Fiber optic. */
SELECT 'REC-18 detail' AS note,
       trim(m.internet_service) AS merged_internet_service,
       k.internet_type          AS source_internet_type,
       count(*)                 AS customers
FROM   raw.merged_reconciliation AS m
JOIN   core.dim_contract         AS k ON k.customer_id = trim(m.customer_id)
GROUP  BY 2, 3
ORDER  BY 2, 3;
