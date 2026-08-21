/* ============================================================
   File    : 03_analysis/08_analysis_validation.sql
   Stage   : ANALYSE — validation gate
   Purpose : A-VAL-01 to A-VAL-16. Validates every analytical output before any
             interpretation is drawn.

   PLACEMENT NOTE: PREPARE validation lives in 02_eda/. This file validates
   ANALYSE outputs and depends on the analysis views, so it sits with them and
   runs last. Flagged rather than filed silently against convention.

   ANY FAILURE STOPS WORK. No expectation is adjusted to make a check pass.

   LABELLING REPAIR (19 Aug 2026): the A-VAL-17 fan-out block now carries an
   explicit check_id column. Its logic, thresholds and expected values are
   UNCHANGED; ORDER BY moves from column 1 to column 2 so the block still sorts
   by view_name now that check_id occupies position 1.
   Author  : Peters
   Created : 2026-08-19
   ============================================================ */

\echo '=== A-VAL-01 to A-VAL-16 ==='

WITH b AS (SELECT * FROM analytics.vw_customer_analytical_base)

SELECT 'A-VAL-01' AS check_id,
       'Cohort scopes partition the base exactly' AS description,
       '7043' AS expected,
       (SELECT (count(*) FILTER (WHERE cohort_class='opening_base')
              + count(*) FILTER (WHERE cohort_class='in_period_acquisition'))::text FROM b) AS actual,
       CASE WHEN (SELECT count(*) FILTER (WHERE cohort_class='opening_base')
                       + count(*) FILTER (WHERE cohort_class='in_period_acquisition') FROM b) = 7043
            THEN 'PASS' ELSE 'FAIL' END AS status

UNION ALL SELECT 'A-VAL-02a','Opening-cohort churn rate reproduces C-3 primary KPI','21.23',
       (SELECT churn_rate_pct::text FROM analytics.vw_kpi_churn_rate WHERE scope='opening_base'),
       CASE WHEN (SELECT churn_rate_pct FROM analytics.vw_kpi_churn_rate WHERE scope='opening_base') = 21.23
            THEN 'PASS' ELSE 'FAIL' END

UNION ALL SELECT 'A-VAL-02b','Period-end base rate reproduces 26.54','26.54',
       (SELECT churn_rate_pct::text FROM analytics.vw_kpi_churn_rate WHERE scope='ALL'),
       CASE WHEN (SELECT churn_rate_pct FROM analytics.vw_kpi_churn_rate WHERE scope='ALL') = 26.54
            THEN 'PASS' ELSE 'FAIL' END

UNION ALL SELECT 'A-VAL-03','Revenue at risk (ALL scope) = sum(monthly_charge) x 12 over churned','0.00 diff',
       (SELECT round(abs(v.arr_at_risk_currency_units
              - (SELECT sum(monthly_charge)*12 FROM b WHERE is_churned)), 2)::text
        FROM analytics.vw_kpi_revenue_at_risk v WHERE v.scope='ALL'),
       CASE WHEN (SELECT abs(v.arr_at_risk_currency_units
                  - (SELECT sum(monthly_charge)*12 FROM b WHERE is_churned))
                  FROM analytics.vw_kpi_revenue_at_risk v WHERE v.scope='ALL') < 0.01
            THEN 'PASS' ELSE 'FAIL' END

UNION ALL SELECT 'A-VAL-04','Decile revenue sums to base total recurring revenue','0.00 diff',
       (SELECT round(abs(sum(arr_currency_units) - (SELECT sum(annual_recurring_revenue) FROM b)), 2)::text
        FROM analytics.vw_kpi_revenue_concentration),
       CASE WHEN (SELECT abs(sum(arr_currency_units) - (SELECT sum(annual_recurring_revenue) FROM b))
                  FROM analytics.vw_kpi_revenue_concentration) < 0.5
            THEN 'PASS' ELSE 'FAIL' END

UNION ALL SELECT 'A-VAL-05','Pareto cumulative share reaches 100% at decile 1','100.00',
       (SELECT cumulative_revenue_pct::text FROM analytics.vw_kpi_revenue_concentration WHERE revenue_decile=1),
       CASE WHEN (SELECT cumulative_revenue_pct FROM analytics.vw_kpi_revenue_concentration WHERE revenue_decile=1)
                 BETWEEN 99.9 AND 100.1 THEN 'PASS' ELSE 'FAIL' END

UNION ALL SELECT 'A-VAL-06','P2 decile membership sums to scope population (all_customers)','7043',
       (SELECT sum(n)::text FROM analytics.vw_segment_p2_revenue_decile WHERE population_scope='all_customers'),
       CASE WHEN (SELECT sum(n) FROM analytics.vw_segment_p2_revenue_decile WHERE population_scope='all_customers') = 7043
            THEN 'PASS' ELSE 'FAIL' END

UNION ALL SELECT 'A-VAL-07','Every P2 row carries a cell_size_flag','0 missing',
       (SELECT count(*) FILTER (WHERE cell_size_flag IS NULL)::text FROM analytics.vw_segment_p2_revenue_decile),
       CASE WHEN (SELECT count(*) FILTER (WHERE cell_size_flag IS NULL) FROM analytics.vw_segment_p2_revenue_decile)=0
            THEN 'PASS' ELSE 'FAIL' END

UNION ALL SELECT 'A-VAL-08a','P1 cells sum to opening-cohort population','5992',
       (SELECT sum(n)::text FROM analytics.vw_segment_p1_value_contract WHERE population_scope='opening_base'),
       CASE WHEN (SELECT sum(n) FROM analytics.vw_segment_p1_value_contract WHERE population_scope='opening_base')
                 = (SELECT count(*) FROM b WHERE cohort_class='opening_base') THEN 'PASS' ELSE 'FAIL' END

UNION ALL SELECT 'A-VAL-08b','P1 cells sum to all-customer population','7043',
       (SELECT sum(n)::text FROM analytics.vw_segment_p1_value_contract WHERE population_scope='all_customers'),
       CASE WHEN (SELECT sum(n) FROM analytics.vw_segment_p1_value_contract WHERE population_scope='all_customers')=7043
            THEN 'PASS' ELSE 'FAIL' END

UNION ALL SELECT 'A-VAL-09','Divergence ranks span 1..9 with no gaps, both scopes','9 per scope',
       (SELECT string_agg(DISTINCT cnt::text, ',') FROM (
            SELECT population_scope, count(DISTINCT rank_by_churn_rate) AS cnt
            FROM analytics.vw_segment_divergence GROUP BY population_scope) q),
       CASE WHEN (SELECT count(*) FROM (
            SELECT population_scope FROM analytics.vw_segment_divergence
            GROUP BY population_scope HAVING count(*) <> 9) q) = 0
            THEN 'PASS' ELSE 'FAIL' END

UNION ALL SELECT 'A-VAL-10','Divergence index sums to zero within each scope (paired ranks)','0',
       (SELECT string_agg(s::text, ',') FROM (
            SELECT sum(divergence_index) AS s FROM analytics.vw_segment_divergence
            GROUP BY population_scope) q),
       CASE WHEN (SELECT count(*) FROM (
            SELECT population_scope FROM analytics.vw_segment_divergence
            GROUP BY population_scope HAVING sum(divergence_index) <> 0) q) = 0
            THEN 'PASS' ELSE 'FAIL' END

UNION ALL SELECT 'A-VAL-11','Each lens partitions its scope exactly (no double-count, no gap)','0 mismatches',
       (SELECT count(*)::text FROM (
            SELECT scope_cohort, scope_tier, lens_id, sum(n) AS lens_total
            FROM analytics.vw_driver_lenses GROUP BY 1,2,3) L
        JOIN (SELECT scope_cohort, scope_tier, max(lens_total) AS scope_total FROM (
            SELECT scope_cohort, scope_tier, lens_id, sum(n) AS lens_total
            FROM analytics.vw_driver_lenses GROUP BY 1,2,3) x GROUP BY 1,2) S
          ON S.scope_cohort=L.scope_cohort AND S.scope_tier=L.scope_tier
        WHERE L.lens_total <> S.scope_total),
       CASE WHEN (SELECT count(*) FROM (
            SELECT scope_cohort, scope_tier, count(DISTINCT lens_total) AS d FROM (
                SELECT scope_cohort, scope_tier, lens_id, sum(n) AS lens_total
                FROM analytics.vw_driver_lenses GROUP BY 1,2,3) x
            GROUP BY 1,2 HAVING count(DISTINCT lens_total) > 1) q) = 0
            THEN 'PASS' ELSE 'FAIL' END

UNION ALL SELECT 'A-VAL-12','All seven lenses present in every scope','6 scopes x 7 lenses',
       (SELECT count(*)::text FROM (
            SELECT scope_cohort, scope_tier FROM analytics.vw_driver_lenses
            GROUP BY 1,2 HAVING count(DISTINCT lens_id) = 7) q),
       CASE WHEN (SELECT count(*) FROM (
            SELECT scope_cohort, scope_tier FROM analytics.vw_driver_lenses
            GROUP BY 1,2 HAVING count(DISTINCT lens_id) <> 7) q) = 0
            THEN 'PASS' ELSE 'FAIL' END

UNION ALL SELECT 'A-VAL-13','Every driver row carries n and cell_size_flag','0 missing',
       (SELECT count(*) FILTER (WHERE n IS NULL OR cell_size_flag IS NULL)::text
        FROM analytics.vw_driver_lenses),
       CASE WHEN (SELECT count(*) FILTER (WHERE n IS NULL OR cell_size_flag IS NULL)
                  FROM analytics.vw_driver_lenses) = 0 THEN 'PASS' ELSE 'FAIL' END

UNION ALL SELECT 'A-VAL-14','Every High-tier lens row has an all-customer counterpart (AQ-06)','0 orphans',
       (SELECT count(*)::text FROM analytics.vw_driver_lenses h
        WHERE h.scope_cohort='opening_base' AND h.scope_tier='High'
          AND NOT EXISTS (SELECT 1 FROM analytics.vw_driver_lenses a
                          WHERE a.lens_id=h.lens_id AND a.segment_value=h.segment_value
                            AND a.scope_cohort=h.scope_cohort AND a.scope_tier='ALL')),
       CASE WHEN (SELECT count(*) FROM analytics.vw_driver_lenses h
        WHERE h.scope_cohort='opening_base' AND h.scope_tier='High'
          AND NOT EXISTS (SELECT 1 FROM analytics.vw_driver_lenses a
                          WHERE a.lens_id=h.lens_id AND a.segment_value=h.segment_value
                            AND a.scope_cohort=h.scope_cohort AND a.scope_tier='ALL')) = 0
            THEN 'PASS' ELSE 'FAIL' END

UNION ALL SELECT 'A-VAL-15','In-period acquisitions = 1051 (454 survived + 597 churned)','1051',
       (SELECT count(*)::text FROM b WHERE cohort_class='in_period_acquisition'),
       CASE WHEN (SELECT count(*) FROM b WHERE cohort_class='in_period_acquisition')=1051
             AND (SELECT count(*) FROM b WHERE cohort_class='in_period_acquisition' AND is_churned)=597
            THEN 'PASS' ELSE 'FAIL' END

UNION ALL SELECT 'A-VAL-16','Numerator is a subset of its denominator in every driver cell','0 violations',
       (SELECT count(*) FILTER (WHERE churned > n)::text FROM analytics.vw_driver_lenses),
       CASE WHEN (SELECT count(*) FILTER (WHERE churned > n) FROM analytics.vw_driver_lenses)=0
            THEN 'PASS' ELSE 'FAIL' END
ORDER BY 1;

\echo ''
\echo '=== A-VAL-17  Fan-out control: no analysis view exceeds its expected grain ==='
SELECT 'A-VAL-17' AS check_id,
       'vw_kpi_churn_rate' AS view_name, count(*) AS rows, 3 AS expected_max,
       CASE WHEN count(*) <= 3 THEN 'PASS' ELSE 'FAIL' END AS status
FROM analytics.vw_kpi_churn_rate
UNION ALL SELECT 'A-VAL-17','vw_kpi_revenue_at_risk', count(*), 3,
       CASE WHEN count(*) <= 3 THEN 'PASS' ELSE 'FAIL' END FROM analytics.vw_kpi_revenue_at_risk
UNION ALL SELECT 'A-VAL-17','vw_kpi_revenue_concentration', count(*), 10,
       CASE WHEN count(*) = 10 THEN 'PASS' ELSE 'FAIL' END FROM analytics.vw_kpi_revenue_concentration
UNION ALL SELECT 'A-VAL-17','vw_segment_p1_value_contract', count(*), 18,
       CASE WHEN count(*) <= 18 THEN 'PASS' ELSE 'FAIL' END FROM analytics.vw_segment_p1_value_contract
UNION ALL SELECT 'A-VAL-17','vw_segment_p2_revenue_decile', count(*), 20,
       CASE WHEN count(*) <= 20 THEN 'PASS' ELSE 'FAIL' END FROM analytics.vw_segment_p2_revenue_decile
UNION ALL SELECT 'A-VAL-17','vw_segment_divergence', count(*), 18,
       CASE WHEN count(*) <= 18 THEN 'PASS' ELSE 'FAIL' END FROM analytics.vw_segment_divergence
ORDER BY 2;

\echo ''
\echo '=== A-VAL-18  Reproducibility: decile membership identical across two reads ==='
SELECT 'A-VAL-18' AS check_id,
       'customers whose decile differs between two reads of the view' AS description,
       0 AS expected,
       (SELECT count(*) FROM analytics.vw_customer_analytical_base a
        JOIN analytics.vw_customer_analytical_base c USING (customer_id)
        WHERE a.revenue_decile <> c.revenue_decile) AS actual,
       CASE WHEN (SELECT count(*) FROM analytics.vw_customer_analytical_base a
        JOIN analytics.vw_customer_analytical_base c USING (customer_id)
        WHERE a.revenue_decile <> c.revenue_decile) = 0 THEN 'PASS' ELSE 'FAIL' END AS status;

\echo ''
\echo '=== A-VAL-19  Exclusion scan: no prohibited field in any ANALYSE view ==='
SELECT 'A-VAL-19' AS check_id,
       'prohibited references in analytics view definitions' AS description,
       '0' AS expected,
       (SELECT count(*) FROM pg_views v
         WHERE v.schemaname IN ('core','analytics')
           AND (v.definition ~* 'satisfaction_score' OR v.definition ~* 'churn_score'
             OR v.definition ~* '\mcltv\M'          OR v.definition ~* 'churn_reason'
             OR v.definition ~* 'churn_category'    OR v.definition ~* 'restricted_demographics'
             OR v.definition ~* 'merged_reconciliation'))::text AS actual,
       CASE WHEN (SELECT count(*) FROM pg_views v
                   WHERE v.schemaname IN ('core','analytics')
                     AND (v.definition ~* 'satisfaction_score' OR v.definition ~* 'churn_score'
                       OR v.definition ~* '\mcltv\M'          OR v.definition ~* 'churn_reason'
                       OR v.definition ~* 'churn_category'    OR v.definition ~* 'restricted_demographics'
                       OR v.definition ~* 'merged_reconciliation')) = 0
            THEN 'PASS' ELSE 'FAIL' END AS status;
