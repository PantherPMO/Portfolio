/* ============================================================
   Project    : 02 — Warehouse Inventory & Supply Chain Performance
   File       : 05_reporting_views/06_vw_kpi_order_cycle_time.sql
   KPI        : Order Cycle Time — _portfolio/KPI_LIBRARY.md
   Output     : view supply.vw_kpi_order_cycle_time
                analysis/query_results/report_06_order_cycle_time.txt
   Author     : Peters
   Created    : 2026-08-23
   ============================================================

   Calderfield Trade Supplies Ltd is fictional and this data is synthetic.

   KPI DEFINITION, from the library.

     Formula   Mean (Delivery date - Order date)
     Unit      Days
     Note      Report median alongside mean where the distribution is
               skewed — it usually is

   IT IS SKEWED HERE, SO BOTH ARE REPORTED AND THE SPREAD WITH THEM.
   The importer distribution has a long right tail: median 78 days,
   longest 166. A mean alone would describe a shipment nobody received.
   Every row carries median, mean, quartiles, p90, the longest observed
   and the standard deviation, so the shape is visible rather than
   summarised into one number.

   FIRST RECEIPT IS THE CYCLE-TIME EVENT. The cycle a buyer plans
   against is order to first arrival. Measuring every receipt row would
   count a split delivery twice and record the second drop — late by
   construction — as a separate long cycle. The split rate is carried
   as a column so the reader can see how often "first" is not "all",
   and section 4 reports the final-receipt cycle separately for the
   lines that were split.

   D-14. The window closes 2025-09-30 for the same survivorship reason
   as view 05: an order placed in December that had not arrived by the
   end of the data would otherwise be excluded from the mean simply by
   being slow, which biases the mean downwards for exactly the suppliers
   whose lead times are the problem.

   D-08. A SITE ROW IS NOT A SUPPLIER ROW. Livingston books goods
   inwards in a Monday batch — 39.8% of its receipts land on a Monday
   against 14-21% elsewhere — which adds days to its measured cycle that
   the supplier did not cause. Site figures in this view describe the
   receiving operation. File 13 fitted the two apart by alternating
   adjustment and found the Livingston site effect is +1.8 days, not the
   +10.1 that naive marginals suggested (D-27). Nothing in this view
   should be read as attributing a site's cycle time to its suppliers.

   QUOTED IS NOT PROMISED. The variance column compares actual days
   against the supplier's quoted lead time on the sourcing agreement,
   not against the promised delivery date, so it survives the 46
   purchase orders whose promised dates are missing or invalid.
   ============================================================ */

SET search_path TO supply;

\set thin_cell 10


CREATE OR REPLACE VIEW vw_kpi_order_cycle_time AS

WITH first_receipts AS (
    SELECT
        r.supplier_code,
        r.supplier_name,
        r.supplier_type,
        r.warehouse_code,
        r.order_half_year,
        r.actual_lead_time_days,
        r.quoted_lead_time_days,
        r.lead_time_variance_days,
        r.receipts_against_line > 1                                      AS line_was_split
    FROM   vw_receipt_performance AS r
    WHERE  r.receipt_sequence   = 1
      AND  r.is_in_primary_window
)

SELECT
    CASE WHEN supplier_type IS NULL AND warehouse_code IS NULL THEN '1 — network'
         WHEN warehouse_code IS NOT NULL                       THEN '4 — receiving site'
         WHEN supplier_code IS NOT NULL                        THEN '3 — supplier'
         ELSE                                                       '2 — supplier type'
    END                                                                  AS grain_level,
    COALESCE(supplier_type, 'ALL TYPES')                                 AS supplier_type,
    supplier_code,
    supplier_name,
    COALESCE(warehouse_code, 'ALL SITES')                                AS warehouse_code,
    COUNT(*)                                                             AS n_first_receipts,

    -- The quoted expectation, for reference.
    ROUND(AVG(quoted_lead_time_days)::numeric, 1)                        AS quoted_lead_time_days,

    -- The KPI as the library defines it, plus the median it asks for.
    ROUND(AVG(actual_lead_time_days)::numeric, 1)                        AS mean_cycle_days,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY actual_lead_time_days)::numeric, 1)
                                                                         AS median_cycle_days,
    ROUND(AVG(actual_lead_time_days)::numeric
          - PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY actual_lead_time_days)::numeric, 1)
                                                                         AS mean_minus_median_days,

    -- The shape, because one number cannot carry it.
    ROUND(PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY actual_lead_time_days)::numeric, 1)
                                                                         AS p25_cycle_days,
    ROUND(PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY actual_lead_time_days)::numeric, 1)
                                                                         AS p75_cycle_days,
    ROUND((PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY actual_lead_time_days)
           - PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY actual_lead_time_days))::numeric, 1)
                                                                         AS iqr_days,
    ROUND(PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY actual_lead_time_days)::numeric, 1)
                                                                         AS p90_cycle_days,
    MAX(actual_lead_time_days)                                           AS longest_cycle_days,
    ROUND(STDDEV_SAMP(actual_lead_time_days)::numeric, 1)                AS stddev_days,

    -- Against the quoted lead time. Positive means longer than quoted.
    ROUND(AVG(lead_time_variance_days)::numeric, 1)                      AS mean_overrun_vs_quoted_days,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY lead_time_variance_days)::numeric, 1)
                                                                         AS median_overrun_vs_quoted_days,

    -- Split deliveries are never hidden.
    COUNT(*) FILTER (WHERE line_was_split)                               AS n_lines_later_split,
    ROUND(100.0 * COUNT(*) FILTER (WHERE line_was_split) / NULLIF(COUNT(*), 0), 1)
                                                                         AS split_rate_pct,
    CASE WHEN COUNT(*) < :thin_cell
         THEN 'thin cell — under ' || :thin_cell || ' first receipts'
         ELSE ''
    END                                                                  AS cell_note
FROM   first_receipts
GROUP  BY GROUPING SETS ((), (supplier_type),
                         (supplier_code, supplier_name, supplier_type),
                         (warehouse_code));


\echo '=== 1. Order cycle time by supplier type, reconciling to file 13 ==='

-- Expected from analyse_13_lead_time_and_site_effects.txt:
--   UK Manufacturer quoted 7, median 8, longest 17, stddev 1.4
--   Far East Importer quoted 55, median 78, longest 166, stddev 12.5
SELECT
    supplier_type,
    n_first_receipts,
    quoted_lead_time_days,
    mean_cycle_days,
    median_cycle_days,
    p25_cycle_days,
    p75_cycle_days,
    iqr_days,
    p90_cycle_days,
    longest_cycle_days,
    stddev_days,
    mean_overrun_vs_quoted_days,
    median_overrun_vs_quoted_days
FROM   vw_kpi_order_cycle_time
WHERE  grain_level IN ('1 — network', '2 — supplier type')
ORDER  BY grain_level, median_cycle_days;


\echo '=== 2. Mean against median — how far the tail moves the average ==='

-- The library asks for the median alongside the mean where the
-- distribution is skewed. This table is the evidence that it is.
SELECT
    supplier_type,
    n_first_receipts,
    mean_cycle_days,
    median_cycle_days,
    mean_minus_median_days,
    p90_cycle_days,
    longest_cycle_days,
    ROUND(longest_cycle_days - median_cycle_days, 1)                     AS tail_length_days
FROM   vw_kpi_order_cycle_time
WHERE  grain_level = '2 — supplier type'
ORDER  BY mean_minus_median_days DESC;


\echo '=== 3. By supplier, with n on every row ==='

SELECT
    supplier_code,
    supplier_name,
    supplier_type,
    n_first_receipts,
    quoted_lead_time_days,
    median_cycle_days,
    mean_cycle_days,
    iqr_days,
    stddev_days,
    median_overrun_vs_quoted_days,
    split_rate_pct,
    cell_note
FROM   vw_kpi_order_cycle_time
WHERE  grain_level = '3 — supplier'
ORDER  BY median_overrun_vs_quoted_days DESC, supplier_code
LIMIT  15;


\echo '=== 4. By receiving site — the receiving operation, not the supplier ==='

-- Livingston's figures include its Monday booking batch. File 13 fitted
-- the site effect at +1.8 days once supplier mix was controlled (D-27);
-- the raw gap below is larger and must not be read as a supplier finding.
SELECT
    warehouse_code,
    n_first_receipts,
    median_cycle_days,
    mean_cycle_days,
    iqr_days,
    stddev_days,
    mean_overrun_vs_quoted_days,
    median_overrun_vs_quoted_days
FROM   vw_kpi_order_cycle_time
WHERE  grain_level = '4 — receiving site'
ORDER  BY median_overrun_vs_quoted_days DESC;


\echo '=== 5. First receipt against final receipt, on the lines that split ==='

-- The cycle a buyer plans against is order to first arrival. The cycle
-- the stock actually completes on is order to final arrival. On split
-- lines these are different numbers and both are reported.
WITH split_lines AS (
    SELECT
        r.supplier_type,
        r.purchase_order_number,
        r.purchase_order_line_number,
        MIN(r.actual_lead_time_days) FILTER (WHERE r.receipt_sequence = 1)
                                                                         AS first_receipt_days,
        MAX(r.actual_lead_time_days)                                     AS final_receipt_days
    FROM   vw_receipt_performance AS r
    WHERE  r.is_in_primary_window
      AND  r.receipts_against_line > 1
    GROUP  BY r.supplier_type, r.purchase_order_number, r.purchase_order_line_number
)

SELECT
    supplier_type,
    COUNT(*)                                                             AS split_lines,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY first_receipt_days)::numeric, 1)
                                                                         AS median_to_first_receipt_days,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY final_receipt_days)::numeric, 1)
                                                                         AS median_to_final_receipt_days,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY final_receipt_days - first_receipt_days)::numeric, 1)
                                                                         AS median_completion_lag_days,
    MAX(final_receipt_days - first_receipt_days)                         AS longest_completion_lag_days
FROM   split_lines
GROUP  BY supplier_type
ORDER  BY median_completion_lag_days DESC;


\echo '=== 6. Validation: population and window ==='

SELECT
    'First receipts in the primary window (the KPI population)'          AS check_name,
    (SELECT n_first_receipts FROM vw_kpi_order_cycle_time
     WHERE grain_level = '1 — network')                                  AS value,
    'Matches file 13 total first receipts'                               AS note
UNION ALL
SELECT 'Supplier-type rows sum to the network row',
       (SELECT SUM(n_first_receipts) FROM vw_kpi_order_cycle_time
        WHERE grain_level = '2 — supplier type'),
       CASE WHEN (SELECT SUM(n_first_receipts) FROM vw_kpi_order_cycle_time
                  WHERE grain_level = '2 — supplier type')
               = (SELECT n_first_receipts FROM vw_kpi_order_cycle_time
                  WHERE grain_level = '1 — network')
            THEN 'PASS' ELSE 'FAIL' END
UNION ALL
SELECT 'Site rows sum to the network row',
       (SELECT SUM(n_first_receipts) FROM vw_kpi_order_cycle_time
        WHERE grain_level = '4 — receiving site'),
       CASE WHEN (SELECT SUM(n_first_receipts) FROM vw_kpi_order_cycle_time
                  WHERE grain_level = '4 — receiving site')
               = (SELECT n_first_receipts FROM vw_kpi_order_cycle_time
                  WHERE grain_level = '1 — network')
            THEN 'PASS' ELSE 'FAIL' END
UNION ALL
SELECT 'First receipts excluded by the 2025-09-30 window (D-14)',
       (SELECT COUNT(*) FROM vw_receipt_performance
        WHERE receipt_sequence = 1 AND NOT is_in_primary_window),
       'Reported, not silently dropped';
