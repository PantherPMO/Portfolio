/* ============================================================
   File   : 01_cleaning/01_promote_dim_customer.sql
   Stage  : PREPARE
   Purpose: raw.demographics -> core.dim_customer.
            Protected characteristics are NOT promoted here (D-15).
            Count dropped — verified constant 1.
   ============================================================ */

TRUNCATE core.dim_customer CASCADE;

INSERT INTO core.dim_customer (customer_id, is_married, has_dependents, dependent_count)
SELECT trim(customer_id),
       core.yn_to_bool(trim(married)),
       core.yn_to_bool(trim(dependents)),
       trim(number_of_dependents)::smallint
FROM   raw.demographics;

/* Stage 2 verified: Dependents = Yes  <=>  Number of Dependents > 0, no exceptions.
   Re-asserted here because a break would mean the source changed. */
SELECT 'CLEAN-01' AS check_id,
       'dim_customer rows' AS description, 7043 AS expected, count(*) AS actual,
       CASE WHEN count(*) = 7043 THEN 'PASS' ELSE 'FAIL' END AS status
FROM   core.dim_customer
UNION ALL
SELECT 'CLEAN-02',
       'has_dependents <=> dependent_count > 0 (0 = consistent)',
       0,
       count(*) FILTER (WHERE has_dependents <> (dependent_count > 0)),
       CASE WHEN count(*) FILTER (WHERE has_dependents <> (dependent_count > 0)) = 0
            THEN 'PASS' ELSE 'FAIL' END
FROM   core.dim_customer;
