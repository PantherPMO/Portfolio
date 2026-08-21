/* ============================================================
   File   : 01_cleaning/08_cleaning_reconciliation.sql
   Stage  : PREPARE
   Purpose: REC-02 — raw -> core row-count reconciliation.
            No row may be lost or gained at promotion. Any difference must be
            explained, not absorbed.
   ============================================================ */

WITH counts AS (
    SELECT 'demographics' AS source_table,
           (SELECT count(*) FROM raw.demographics) AS raw_rows,
           (SELECT count(*) FROM core.dim_customer) AS core_rows
    UNION ALL SELECT 'demographics (restricted)',
           (SELECT count(*) FROM raw.demographics),
           (SELECT count(*) FROM core.restricted_demographics)
    UNION ALL SELECT 'location',
           (SELECT count(*) FROM raw.location),
           (SELECT count(*) FROM core.dim_location)
    UNION ALL SELECT 'population',
           (SELECT count(*) FROM raw.population),
           (SELECT count(*) FROM core.dim_population)
    UNION ALL SELECT 'services -> dim_contract',
           (SELECT count(*) FROM raw.services),
           (SELECT count(*) FROM core.dim_contract)
    UNION ALL SELECT 'services+status -> fact',
           (SELECT count(*) FROM raw.services),
           (SELECT count(*) FROM core.fact_customer_status)
)
SELECT 'REC-02' AS check_id, source_table, raw_rows, core_rows,
       core_rows - raw_rows AS difference,
       CASE WHEN core_rows = raw_rows THEN 'PASS' ELSE 'FAIL' END AS status
FROM   counts
ORDER  BY source_table;
