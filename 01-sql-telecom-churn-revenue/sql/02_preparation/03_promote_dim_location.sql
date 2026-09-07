/* ============================================================
   File   : 01_cleaning/03_promote_dim_location.sql
   Stage  : PREPARE
   Purpose: raw.location -> core.dim_location.
            Country/State dropped (verified constant). Lat Long dropped
            (redundant composite). zip_code cast to char(5) text.
   NOTE   : runs AFTER 04_promote_dim_population — the FK requires it.
   ============================================================ */

TRUNCATE core.dim_location;

INSERT INTO core.dim_location (customer_id, city, zip_code, latitude, longitude)
SELECT trim(customer_id),
       trim(city),
       lpad(trim(zip_code), 5, '0'),
       trim(latitude)::numeric(9,6),
       trim(longitude)::numeric(9,6)
FROM   raw.location;

SELECT 'CLEAN-06' AS check_id, 'dim_location rows' AS description,
       7043 AS expected, count(*) AS actual,
       CASE WHEN count(*) = 7043 THEN 'PASS' ELSE 'FAIL' END AS status
FROM   core.dim_location
UNION ALL
SELECT 'CLEAN-07', 'distinct zip codes in use', 1626, count(DISTINCT zip_code),
       CASE WHEN count(DISTINCT zip_code) = 1626 THEN 'PASS' ELSE 'FAIL' END
FROM   core.dim_location;
