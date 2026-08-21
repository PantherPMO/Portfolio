/* ============================================================
   File   : 02_eda/02_duplicate_checks.sql
   Stage  : PREPARE — validation gate 4
   Purpose: DUP-01 to DUP-05. Every check must return 0.
   ============================================================ */

SELECT 'DUP-01' AS check_id, 'dim_customer duplicate ids' AS description,
       count(*) - count(DISTINCT customer_id) AS duplicates,
       CASE WHEN count(*) = count(DISTINCT customer_id) THEN 'PASS' ELSE 'FAIL' END AS status
FROM core.dim_customer
UNION ALL
SELECT 'DUP-01','dim_location duplicate ids',count(*)-count(DISTINCT customer_id),
       CASE WHEN count(*)=count(DISTINCT customer_id) THEN 'PASS' ELSE 'FAIL' END FROM core.dim_location
UNION ALL
SELECT 'DUP-01','dim_contract duplicate ids',count(*)-count(DISTINCT customer_id),
       CASE WHEN count(*)=count(DISTINCT customer_id) THEN 'PASS' ELSE 'FAIL' END FROM core.dim_contract
UNION ALL
SELECT 'DUP-01','fact_customer_status duplicate ids',count(*)-count(DISTINCT customer_id),
       CASE WHEN count(*)=count(DISTINCT customer_id) THEN 'PASS' ELSE 'FAIL' END FROM core.fact_customer_status
UNION ALL
SELECT 'DUP-02','dim_population duplicate zip codes',count(*)-count(DISTINCT zip_code),
       CASE WHEN count(*)=count(DISTINCT zip_code) THEN 'PASS' ELSE 'FAIL' END FROM core.dim_population
UNION ALL
SELECT 'DUP-03','bridge duplicate (customer_id, service_code)',
       count(*)-count(DISTINCT (customer_id, service_code)),
       CASE WHEN count(*)=count(DISTINCT (customer_id, service_code)) THEN 'PASS' ELSE 'FAIL' END
FROM core.bridge_customer_service
UNION ALL
SELECT 'DUP-04','dim_service duplicate codes',count(*)-count(DISTINCT service_code),
       CASE WHEN count(*)=count(DISTINCT service_code) THEN 'PASS' ELSE 'FAIL' END FROM core.dim_service
UNION ALL
SELECT 'DUP-05','null keys across core tables',
       (SELECT count(*) FROM core.dim_customer          WHERE customer_id IS NULL)
     + (SELECT count(*) FROM core.dim_location          WHERE customer_id IS NULL OR zip_code IS NULL)
     + (SELECT count(*) FROM core.dim_contract          WHERE customer_id IS NULL)
     + (SELECT count(*) FROM core.fact_customer_status  WHERE customer_id IS NULL)
     + (SELECT count(*) FROM core.dim_population        WHERE zip_code IS NULL)
     + (SELECT count(*) FROM core.bridge_customer_service WHERE customer_id IS NULL OR service_code IS NULL),
       CASE WHEN (SELECT count(*) FROM core.dim_customer WHERE customer_id IS NULL)
               + (SELECT count(*) FROM core.dim_location WHERE customer_id IS NULL OR zip_code IS NULL)
               + (SELECT count(*) FROM core.dim_contract WHERE customer_id IS NULL)
               + (SELECT count(*) FROM core.fact_customer_status WHERE customer_id IS NULL)
               + (SELECT count(*) FROM core.dim_population WHERE zip_code IS NULL)
               + (SELECT count(*) FROM core.bridge_customer_service WHERE customer_id IS NULL OR service_code IS NULL) = 0
            THEN 'PASS' ELSE 'FAIL' END
ORDER BY 1, 2;
