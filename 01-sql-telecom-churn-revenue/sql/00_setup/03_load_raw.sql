/* ============================================================
   Project : 01 — Telecommunications Revenue Retention
   File    : 00_setup/03_load_raw.sql
   Stage   : PREPARE
   Purpose : Load the six CSV intermediates into the raw layer.
   Author  : Peters
   Created : 2026-08-19

   RUN THIS WITH psql, NOT a GUI. \copy is a psql client command: it reads the
   file from YOUR machine using YOUR permissions. The server-side COPY would
   require the file to be readable by the postgres service account.

   PREREQUISITE: run convert_xlsx_to_csv.py first (see 00_setup/README.md).
   PATHS ARE RELATIVE to the project root. Start psql with your working
   directory set to the 01-sql-telecom-churn-revenue folder of your clone.
   ============================================================ */

TRUNCATE raw.demographics, raw.location, raw.population,
         raw.services, raw.status, raw.merged_reconciliation;

\copy raw.demographics          FROM 'data/processed/csv/demographics.csv'   WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\copy raw.location              FROM 'data/processed/csv/location.csv'       WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\copy raw.population            FROM 'data/processed/csv/population.csv'     WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\copy raw.services              FROM 'data/processed/csv/services.csv'       WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\copy raw.status                FROM 'data/processed/csv/status.csv'         WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\copy raw.merged_reconciliation FROM 'data/processed/csv/merged.csv'         WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')

/* ---- REC-01: row counts must match the Stage 2 verified profile ---- */
SELECT 'REC-01' AS check_id, 'demographics' AS table_name, 7043 AS expected,
       count(*) AS actual, CASE WHEN count(*) = 7043 THEN 'PASS' ELSE 'FAIL' END AS status
FROM raw.demographics
UNION ALL SELECT 'REC-01','location',7043,count(*),CASE WHEN count(*)=7043 THEN 'PASS' ELSE 'FAIL' END FROM raw.location
UNION ALL SELECT 'REC-01','population',1671,count(*),CASE WHEN count(*)=1671 THEN 'PASS' ELSE 'FAIL' END FROM raw.population
UNION ALL SELECT 'REC-01','services',7043,count(*),CASE WHEN count(*)=7043 THEN 'PASS' ELSE 'FAIL' END FROM raw.services
UNION ALL SELECT 'REC-01','status',7043,count(*),CASE WHEN count(*)=7043 THEN 'PASS' ELSE 'FAIL' END FROM raw.status
UNION ALL SELECT 'REC-01','merged_reconciliation',7043,count(*),CASE WHEN count(*)=7043 THEN 'PASS' ELSE 'FAIL' END FROM raw.merged_reconciliation
ORDER BY 2;
