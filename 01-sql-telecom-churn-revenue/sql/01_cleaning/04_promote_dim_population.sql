/* ============================================================
   File   : 01_cleaning/04_promote_dim_population.sql
   Stage  : PREPARE
   Purpose: raw.population -> core.dim_population.
            One row per zip code. The only non-customer-grain table and the
            only N:1 relationship in the model.
   NOTE   : must run BEFORE 03_promote_dim_location (FK target).
   ============================================================ */

TRUNCATE core.dim_population CASCADE;

INSERT INTO core.dim_population (zip_code, population_id, population)
SELECT lpad(trim(zip_code), 5, '0'),
       trim(population_id)::integer,
       trim(population)::integer
FROM   raw.population;

SELECT 'CLEAN-08' AS check_id, 'dim_population rows' AS description,
       1671 AS expected, count(*) AS actual,
       CASE WHEN count(*) = 1671 THEN 'PASS' ELSE 'FAIL' END AS status
FROM   core.dim_population;
