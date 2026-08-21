/* ============================================================
   File   : 02_eda/01_referential_integrity.sql
   Stage  : PREPARE — validation gate 4
   Purpose: RI-01 to RI-08. Every check must return 0.
            RI-06 is directional: 45 population zip codes have no customers,
            which is a lookup superset, not an orphan.
   ============================================================ */

SELECT 'RI-01' AS check_id, 'dim_location customer_ids not in dim_customer' AS description,
       count(*) AS violations, CASE WHEN count(*)=0 THEN 'PASS' ELSE 'FAIL' END AS status
FROM core.dim_location l LEFT JOIN core.dim_customer c USING (customer_id) WHERE c.customer_id IS NULL
UNION ALL
SELECT 'RI-02','dim_contract customer_ids not in dim_customer',count(*),CASE WHEN count(*)=0 THEN 'PASS' ELSE 'FAIL' END
FROM core.dim_contract k LEFT JOIN core.dim_customer c USING (customer_id) WHERE c.customer_id IS NULL
UNION ALL
SELECT 'RI-03','fact_customer_status customer_ids not in dim_customer',count(*),CASE WHEN count(*)=0 THEN 'PASS' ELSE 'FAIL' END
FROM core.fact_customer_status f LEFT JOIN core.dim_customer c USING (customer_id) WHERE c.customer_id IS NULL
UNION ALL
SELECT 'RI-04','restricted_demographics customer_ids not in dim_customer',count(*),CASE WHEN count(*)=0 THEN 'PASS' ELSE 'FAIL' END
FROM core.restricted_demographics r LEFT JOIN core.dim_customer c USING (customer_id) WHERE c.customer_id IS NULL
UNION ALL
SELECT 'RI-05','dim_customer ids missing from any of the four child tables',count(*),CASE WHEN count(*)=0 THEN 'PASS' ELSE 'FAIL' END
FROM core.dim_customer c
WHERE NOT EXISTS (SELECT 1 FROM core.dim_location          x WHERE x.customer_id=c.customer_id)
   OR NOT EXISTS (SELECT 1 FROM core.dim_contract          x WHERE x.customer_id=c.customer_id)
   OR NOT EXISTS (SELECT 1 FROM core.fact_customer_status  x WHERE x.customer_id=c.customer_id)
   OR NOT EXISTS (SELECT 1 FROM core.restricted_demographics x WHERE x.customer_id=c.customer_id)
UNION ALL
SELECT 'RI-06','dim_location zip codes not in dim_population (directional)',count(*),CASE WHEN count(*)=0 THEN 'PASS' ELSE 'FAIL' END
FROM core.dim_location l LEFT JOIN core.dim_population p USING (zip_code) WHERE p.zip_code IS NULL
UNION ALL
SELECT 'RI-07','bridge customer_ids not in dim_customer',count(*),CASE WHEN count(*)=0 THEN 'PASS' ELSE 'FAIL' END
FROM core.bridge_customer_service b LEFT JOIN core.dim_customer c USING (customer_id) WHERE c.customer_id IS NULL
UNION ALL
SELECT 'RI-08','bridge service_codes not in dim_service',count(*),CASE WHEN count(*)=0 THEN 'PASS' ELSE 'FAIL' END
FROM core.bridge_customer_service b LEFT JOIN core.dim_service d USING (service_code) WHERE d.service_code IS NULL
ORDER BY 1;

/* Informational — expected 45, NOT a failure. Population is a lookup superset. */
SELECT 'RI-06b' AS check_id,
       'population zip codes with no customers (expected 45, informational)' AS description,
       count(*) AS value
FROM   core.dim_population p
LEFT   JOIN core.dim_location l USING (zip_code)
WHERE  l.zip_code IS NULL;
