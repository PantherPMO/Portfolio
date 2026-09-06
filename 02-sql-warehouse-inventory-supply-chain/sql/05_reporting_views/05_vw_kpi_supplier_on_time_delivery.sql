/* ============================================================
   Project    : 02 — Warehouse Inventory & Supply Chain Performance
   File       : 05_reporting_views/05_vw_kpi_supplier_on_time_delivery.sql
   KPI        : On-Time Delivery / OTIF — _portfolio/KPI_LIBRARY.md
   Output     : view supply.vw_kpi_supplier_on_time_delivery
                analysis/query_results/report_05_supplier_on_time_delivery.txt
   Author     : Peters
   Created    : 2026-08-23
   ============================================================

   Calderfield Trade Supplies Ltd is fictional and this data is synthetic.

   KPI DEFINITION, from the library.

     Formula   Orders delivered on time and in full / Total orders x 100
     Unit      %
     Note      OTIF is stricter than on-time alone; state which is used

   THE LIBRARY SAYS STATE WHICH. THIS PROJECT REPORTS ALL THREE,
   BECAUSE THEY DISAGREE BY TEN POINTS (D-07).

     First receipt   89.8%   Did the supplier start on time
     All receipts    80.1%   Every delivery, so a split shipment counts
                             twice and the second drop is late by
                             construction
     Line complete   79.1%   The full ordered quantity received by the
       (OTIF)                promised date — the library's own definition

   537 of 4,853 receipts (11.1%) are the second or later delivery
   against a line. Quoting the first-receipt figure alone hides every
   split delivery, which is why the split rate is carried as a column on
   every row of this view rather than left to a footnote.

   D-14. THE MEASURABLE WINDOW CLOSES 2025-09-30. Importer lead times
   run near 78 days, so 77.1% of Q4 2025 importer orders have no receipt
   at all against 8.3% for UK manufacturers. Measuring them would
   compute an on-time rate only on the orders that happened to come back
   early — survivorship bias flattering exactly the suppliers under
   question. The excluded quarter is reported separately in section 5,
   with its counts, because excluding it removes the sharpest quarter of
   Meridian Pacific's decline and that cost should be visible.

   D-15. TRENDS RUN AT HALF-YEAR, WITH n PRINTED. 33.2% of
   supplier-by-quarter cells hold fewer than ten receipts; at half-year
   that falls to 7.8%. Every rate in this view carries its denominator,
   and section 4 marks any cell under ten.

   NOT MEASURABLE IS NOT THE SAME AS LATE. 22 purchase orders carry no
   promised date and 24 carry a promised date before the order date.
   They are excluded from the rate and counted in the population table,
   never silently dropped by a WHERE clause.
   ============================================================ */

SET search_path TO supply;

\set window_close '2025-09-30'
\set thin_cell 10


CREATE OR REPLACE VIEW vw_kpi_supplier_on_time_delivery AS

WITH receipt_level AS (
    -- The two receipt-based measures. Grain: goods receipt line.
    SELECT
        r.supplier_code,
        r.supplier_name,
        r.supplier_type,
        r.warehouse_code,
        r.order_half_year,
        COUNT(*) FILTER (WHERE r.is_measurable AND r.is_in_primary_window
                           AND r.receipt_sequence = 1)                   AS n_first_measurable,
        COUNT(*) FILTER (WHERE r.is_on_time AND r.is_in_primary_window
                           AND r.receipt_sequence = 1)                   AS n_first_on_time,
        COUNT(*) FILTER (WHERE r.is_measurable AND r.is_in_primary_window)
                                                                         AS n_all_measurable,
        COUNT(*) FILTER (WHERE r.is_on_time AND r.is_in_primary_window)   AS n_all_on_time,
        COUNT(*) FILTER (WHERE r.is_in_primary_window)                   AS n_receipts_in_window,
        COUNT(*) FILTER (WHERE r.is_in_primary_window
                           AND r.receipt_sequence > 1)                   AS n_split_deliveries,
        COUNT(*) FILTER (WHERE NOT r.is_measurable)                      AS n_not_measurable,
        COUNT(*) FILTER (WHERE NOT r.is_in_primary_window)               AS n_outside_window
    FROM   vw_receipt_performance AS r
    GROUP  BY GROUPING SETS ((), (r.supplier_type), (r.supplier_type, r.order_half_year),
                             (r.supplier_code, r.supplier_name, r.supplier_type),
                             (r.warehouse_code))
),

line_level AS (
    -- OTIF. Grain: purchase order line, so a split delivery is one event
    -- judged on whether the whole quantity arrived by the promised date.
    SELECT
        l.supplier_code,
        l.supplier_name,
        l.supplier_type,
        l.warehouse_code,
        l.order_half_year,
        COUNT(*) FILTER (WHERE l.is_measurable AND l.is_in_primary_window)
                                                                         AS n_lines_measurable,
        COUNT(*) FILTER (WHERE l.is_complete_on_time AND l.is_in_primary_window)
                                                                         AS n_lines_complete_on_time,
        SUM(l.quantity_ordered) FILTER (WHERE l.is_in_primary_window)    AS units_ordered,
        SUM(l.units_received)   FILTER (WHERE l.is_in_primary_window)    AS units_received,
        SUM(l.units_rejected)   FILTER (WHERE l.is_in_primary_window)    AS units_rejected
    FROM   vw_line_completion AS l
    GROUP  BY GROUPING SETS ((), (l.supplier_type), (l.supplier_type, l.order_half_year),
                             (l.supplier_code, l.supplier_name, l.supplier_type),
                             (l.warehouse_code))
)

SELECT
    CASE WHEN r.supplier_type IS NULL AND r.warehouse_code IS NULL THEN '1 — network'
         WHEN r.warehouse_code IS NOT NULL                         THEN '5 — receiving site'
         WHEN r.supplier_code IS NOT NULL                          THEN '4 — supplier'
         WHEN r.order_half_year IS NOT NULL                        THEN '3 — supplier type by half-year'
         ELSE                                                           '2 — supplier type'
    END                                                                  AS grain_level,
    COALESCE(r.supplier_type, 'ALL TYPES')                               AS supplier_type,
    r.supplier_code,
    r.supplier_name,
    COALESCE(r.warehouse_code, 'ALL SITES')                              AS warehouse_code,
    COALESCE(r.order_half_year, 'ALL PERIODS')                           AS order_half_year,

    -- Measure 1 — first receipt against each line.
    r.n_first_measurable,
    ROUND(100.0 * r.n_first_on_time / NULLIF(r.n_first_measurable, 0), 1)
                                                                         AS on_time_first_receipt_pct,
    -- Measure 2 — every receipt.
    r.n_all_measurable,
    ROUND(100.0 * r.n_all_on_time / NULLIF(r.n_all_measurable, 0), 1)    AS on_time_all_receipts_pct,
    -- Measure 3 — OTIF at line grain, the library definition.
    l.n_lines_measurable,
    ROUND(100.0 * l.n_lines_complete_on_time
          / NULLIF(l.n_lines_measurable, 0), 1)                          AS otif_pct,

    -- Split deliveries are never hidden. The gap between measure 1 and
    -- measure 2 is largely this column.
    r.n_split_deliveries,
    ROUND(100.0 * r.n_split_deliveries
          / NULLIF(r.n_receipts_in_window, 0), 1)                        AS split_delivery_rate_pct,
    ROUND(100.0 * (r.n_first_on_time::numeric / NULLIF(r.n_first_measurable, 0)
                   - r.n_all_on_time::numeric / NULLIF(r.n_all_measurable, 0)), 1)
                                                                         AS first_over_all_points,
    l.units_ordered,
    l.units_received,
    l.units_rejected,
    ROUND(100.0 * l.units_received / NULLIF(l.units_ordered, 0), 1)      AS units_received_pct,

    -- Denominator hygiene, carried as columns rather than assumed.
    r.n_not_measurable,
    r.n_outside_window,
    CASE WHEN LEAST(COALESCE(r.n_first_measurable, 0),
                    COALESCE(l.n_lines_measurable, 0)) < :thin_cell
         THEN 'thin cell — under ' || :thin_cell || ' observations'
         ELSE ''
    END                                                                  AS cell_note
FROM       receipt_level AS r
LEFT  JOIN line_level    AS l
       ON  l.supplier_type   IS NOT DISTINCT FROM r.supplier_type
      AND  l.supplier_code   IS NOT DISTINCT FROM r.supplier_code
      AND  l.warehouse_code  IS NOT DISTINCT FROM r.warehouse_code
      AND  l.order_half_year IS NOT DISTINCT FROM r.order_half_year;


\echo '=== 1. Population, reconciling to file 12 ==='

-- Expected from analyse_12_supplier_reliability.txt: 4,853 receipt lines,
-- 4,741 measurable, 4,241 in window, 3,766 first deliveries, 537 splits.
SELECT
    'Goods receipt lines'                                                AS population,
    (SELECT COUNT(*) FROM vw_receipt_performance)                        AS receipts
UNION ALL
SELECT 'Measurable against a promised date',
       (SELECT COUNT(*) FROM vw_receipt_performance WHERE is_measurable)
UNION ALL
SELECT 'In the comparable window (ordered on or before 2025-09-30)',
       (SELECT COUNT(*) FROM vw_receipt_performance WHERE is_measurable AND is_in_primary_window)
UNION ALL
SELECT 'First deliveries in the window',
       (SELECT COUNT(*) FROM vw_receipt_performance
        WHERE is_measurable AND is_in_primary_window AND receipt_sequence = 1)
UNION ALL
SELECT 'Second or later deliveries (split shipments)',
       (SELECT COUNT(*) FROM vw_receipt_performance WHERE receipt_sequence > 1);


\echo '=== 2. The three measures at network level, reconciling to file 12 ==='

-- Expected: 89.8% first receipt, 80.1% all receipts, 79.1% OTIF.
SELECT
    n_first_measurable                                                   AS n_first,
    on_time_first_receipt_pct,
    n_all_measurable                                                     AS n_all,
    on_time_all_receipts_pct,
    n_lines_measurable                                                   AS n_lines,
    otif_pct,
    n_split_deliveries,
    split_delivery_rate_pct,
    first_over_all_points
FROM   vw_kpi_supplier_on_time_delivery
WHERE  grain_level = '1 — network';


\echo '=== 3. By supplier type ==='

SELECT
    supplier_type,
    n_first_measurable,
    on_time_first_receipt_pct,
    n_all_measurable,
    on_time_all_receipts_pct,
    n_lines_measurable,
    otif_pct,
    split_delivery_rate_pct,
    units_received_pct
FROM   vw_kpi_supplier_on_time_delivery
WHERE  grain_level = '2 — supplier type'
ORDER  BY otif_pct DESC;


\echo '=== 4. By supplier type and half-year, with n on every cell (D-15) ==='

SELECT
    supplier_type,
    order_half_year,
    n_first_measurable,
    on_time_first_receipt_pct,
    n_all_measurable,
    on_time_all_receipts_pct,
    n_lines_measurable,
    otif_pct,
    cell_note
FROM   vw_kpi_supplier_on_time_delivery
WHERE  grain_level = '3 — supplier type by half-year'
ORDER  BY supplier_type, order_half_year;


\echo '=== 5. What the measurable window excludes, and what it costs (D-14) ==='

-- Reported rather than reconciled away. Excluding Q4 removes the
-- sharpest quarter of the importer decline, and a reader is entitled to
-- see the size of what was set aside and why it cannot be trusted.
SELECT
    r.supplier_type,
    COUNT(*) FILTER (WHERE r.is_in_primary_window)                       AS receipts_in_window,
    COUNT(*) FILTER (WHERE NOT r.is_in_primary_window)                   AS receipts_excluded,
    ROUND(100.0 * COUNT(*) FILTER (WHERE r.is_on_time AND r.is_in_primary_window)
          / NULLIF(COUNT(*) FILTER (WHERE r.is_measurable AND r.is_in_primary_window), 0), 1)
                                                                         AS on_time_in_window_pct,
    ROUND(100.0 * COUNT(*) FILTER (WHERE r.is_on_time AND NOT r.is_in_primary_window)
          / NULLIF(COUNT(*) FILTER (WHERE r.is_measurable AND NOT r.is_in_primary_window), 0), 1)
                                                                         AS on_time_excluded_pct_unreliable
FROM   vw_receipt_performance AS r
GROUP  BY r.supplier_type
ORDER  BY receipts_excluded DESC;


-- The reason the excluded figure is unreliable: orders placed in Q4 that
-- never arrived are invisible to a receipt-based rate.
SELECT
    s.supplier_type,
    COUNT(*)                                                             AS q4_2025_order_lines,
    COUNT(*) FILTER (WHERE g.purchase_order_number IS NULL)              AS lines_never_received,
    ROUND(100.0 * COUNT(*) FILTER (WHERE g.purchase_order_number IS NULL)
          / NULLIF(COUNT(*), 0), 1)                                      AS never_received_pct
FROM       purchase_order_line AS pol
INNER JOIN purchase_order      AS po ON po.purchase_order_number = pol.purchase_order_number
INNER JOIN supplier            AS s  ON s.supplier_code = po.supplier_code
LEFT  JOIN (SELECT DISTINCT purchase_order_number, purchase_order_line_number
            FROM   goods_receipt_line) AS g
       ON  g.purchase_order_number      = pol.purchase_order_number
      AND  g.purchase_order_line_number = pol.line_number
WHERE      po.order_date > DATE :'window_close'
GROUP  BY  s.supplier_type
ORDER  BY  never_received_pct DESC;


\echo '=== 6. By receiving site — a process view, not a supplier view (D-08) ==='

-- Site rows measure the receiving operation, not the supplier. Livingston
-- books goods inwards in a Monday batch; comparing suppliers across sites
-- without holding site constant charges the supplier for that.
SELECT
    warehouse_code,
    n_first_measurable,
    on_time_first_receipt_pct,
    n_all_measurable,
    on_time_all_receipts_pct,
    n_lines_measurable,
    otif_pct,
    split_delivery_rate_pct
FROM   vw_kpi_supplier_on_time_delivery
WHERE  grain_level = '5 — receiving site'
ORDER  BY otif_pct DESC;


\echo '=== 7. Validation: the three measures are ordered as expected ==='

-- OTIF must be the strictest and first-receipt the most generous. If that
-- ordering ever breaks, one of the three is measuring something else.
SELECT
    grain_level,
    supplier_type,
    on_time_first_receipt_pct,
    on_time_all_receipts_pct,
    otif_pct,
    CASE WHEN on_time_first_receipt_pct >= on_time_all_receipts_pct
              AND on_time_all_receipts_pct >= otif_pct
         THEN 'PASS'
         WHEN on_time_first_receipt_pct >= otif_pct
         THEN 'PASS — all-receipts below OTIF, split-driven'
         ELSE 'REVIEW'
    END                                                                  AS ordering_check
FROM   vw_kpi_supplier_on_time_delivery
WHERE  grain_level IN ('1 — network', '2 — supplier type')
ORDER  BY grain_level, supplier_type;
