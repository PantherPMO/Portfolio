/* ============================================================
   Project    : 02 — Warehouse Inventory & Supply Chain Performance
   File       : 04_analysis/12_supplier_delivery_reliability_over_time.sql
   Question   : BQ-06 / AQ-12 — Which suppliers deliver when they say
                they will, and is anyone getting better or worse?
   Finding ID : F-12
   Output     : analysis/query_results/analyse_12_supplier_reliability.txt
   Author     : Peters
   Created    : 2026-08-23
   ============================================================

   Calderfield Trade Supplies Ltd is fictional and this data is synthetic.

   Grain: one row per goods receipt line in vw_receipt_performance.
   4,853 receipts, of which 4,741 (97.7%) carry a promised date that can
   be measured against.

   THREE MEASURES, DELIBERATELY DIFFERENT.

     First receipt   the first delivery against a purchase order line.
                     Answers "did they start on time".
     All receipts    every delivery. A split shipment counts twice and
                     the second drop is late by construction, so this
                     runs materially below the first-receipt figure.
     Line complete   the purchase order line fully received by the
                     promised date. This is OTIF as KPI_LIBRARY defines
                     it and is the strictest of the three.

   All three are reported together. Quoting one alone is a choice about
   which answer to give (D-07).

   WINDOW. The comparable window closes 2025-09-30 (D-14). Importer
   lead times run near 78 days, so orders placed after that had not
   arrived by the end of the data — 77.1% of Q4 2025 importer orders
   have no receipt at all. Section 7 shows the excluded period with its
   counts; it is never mixed into the trend.

   Note that 2025H2 inside the window is July to September only, three
   months against six elsewhere. Its counts are smaller by construction
   and are printed.

   GRANULARITY. Half-year, because 33.2% of supplier-quarter cells hold
   fewer than ten receipts against 7.8% at half-year (D-15). Every rate
   carries its n.

   NOTHING IS ASSUMED ABOUT ANY NAMED SUPPLIER. Section 5 ranks every
   supplier by measured change and reports what it finds.
   ============================================================ */

SET search_path TO supply;

\set window_close '2025-09-30'
\set min_cell 15


\echo '=== 1. The measurable population ==='

SELECT
    'Goods receipt lines'                                                AS population,
    COUNT(*)                                                             AS receipts,
    NULL::numeric                                                        AS share_pct
FROM   vw_receipt_performance
UNION ALL
SELECT 'Measurable against a promised date', COUNT(*) FILTER (WHERE is_measurable),
       ROUND(100.0 * COUNT(*) FILTER (WHERE is_measurable) / COUNT(*), 1)
FROM   vw_receipt_performance
UNION ALL
SELECT 'In the comparable window (ordered on or before 2025-09-30)',
       COUNT(*) FILTER (WHERE is_measurable AND is_in_primary_window),
       ROUND(100.0 * COUNT(*) FILTER (WHERE is_measurable AND is_in_primary_window) / COUNT(*), 1)
FROM   vw_receipt_performance
UNION ALL
SELECT 'First deliveries in the window',
       COUNT(*) FILTER (WHERE is_measurable AND is_in_primary_window AND receipt_sequence = 1),
       ROUND(100.0 * COUNT(*) FILTER (WHERE is_measurable AND is_in_primary_window
                                        AND receipt_sequence = 1) / COUNT(*), 1)
FROM   vw_receipt_performance
UNION ALL
SELECT 'Second or later deliveries (split shipments)',
       COUNT(*) FILTER (WHERE receipt_sequence > 1),
       ROUND(100.0 * COUNT(*) FILTER (WHERE receipt_sequence > 1) / COUNT(*), 1)
FROM   vw_receipt_performance;


\echo '=== 2. The three measures at network level, comparable window ==='

DROP VIEW IF EXISTS vw_line_completion CASCADE;

CREATE VIEW vw_line_completion AS

-- Grain: one row per purchase order line. Receipts are pre-aggregated first, so
-- the join to the line cannot fan out and inflate ordered quantity.
WITH receipts AS (
    SELECT
        purchase_order_number,
        purchase_order_line_number,
        COUNT(*)                                                         AS receipt_events,
        SUM(quantity_received)                                           AS units_received,
        SUM(quantity_rejected)                                           AS units_rejected,
        MAX(receipt_date)                                                AS final_receipt_date,
        MIN(receipt_date)                                                AS first_receipt_date
    FROM   goods_receipt_line
    GROUP  BY purchase_order_number, purchase_order_line_number
)

SELECT
    pol.purchase_order_number,
    pol.line_number,
    pol.sku,
    po.supplier_code,
    s.supplier_name,
    s.supplier_type,
    po.warehouse_code,
    po.order_date,
    po.promised_delivery_date,
    CONCAT(EXTRACT(YEAR FROM po.order_date)::int,
           CASE WHEN EXTRACT(MONTH FROM po.order_date) <= 6 THEN 'H1' ELSE 'H2' END)
                                                                         AS order_half_year,
    pol.quantity_ordered,
    COALESCE(r.units_received, 0)                                        AS units_received,
    COALESCE(r.units_rejected, 0)                                        AS units_rejected,
    COALESCE(r.receipt_events, 0)                                        AS receipt_events,
    r.first_receipt_date,
    r.final_receipt_date,
    po.promised_delivery_date IS NOT NULL
        AND po.promised_delivery_date >= po.order_date                   AS is_measurable,
    po.order_date <= DATE :'window_close'                                AS is_in_primary_window,
    -- On time and in full: everything ordered, accounted for by the promised
    -- date. Rejected units count as accounted for — they arrived, they failed
    -- inspection, which is a quality question rather than a delivery one.
    CASE WHEN po.promised_delivery_date IS NOT NULL
              AND po.promised_delivery_date >= po.order_date
         THEN r.final_receipt_date IS NOT NULL
              AND r.final_receipt_date <= po.promised_delivery_date
              AND COALESCE(r.units_received, 0) + COALESCE(r.units_rejected, 0)
                  >= pol.quantity_ordered
    END                                                                  AS is_complete_on_time
FROM       purchase_order_line AS pol
INNER JOIN purchase_order      AS po ON po.purchase_order_number = pol.purchase_order_number
INNER JOIN supplier            AS s  ON s.supplier_code = po.supplier_code
LEFT JOIN  receipts            AS r
       ON  r.purchase_order_number      = pol.purchase_order_number
      AND  r.purchase_order_line_number = pol.line_number;


SELECT
    'First receipt against each line'                                    AS measure,
    COUNT(*) FILTER (WHERE is_measurable AND is_in_primary_window
                       AND receipt_sequence = 1)                         AS n,
    ROUND(100.0 * COUNT(*) FILTER (WHERE is_on_time AND is_in_primary_window
                                     AND receipt_sequence = 1)
          / NULLIF(COUNT(*) FILTER (WHERE is_measurable AND is_in_primary_window
                                      AND receipt_sequence = 1), 0), 1)  AS on_time_pct,
    'Did the supplier start on time'                                     AS what_it_measures
FROM   vw_receipt_performance
UNION ALL
SELECT 'All receipts',
       COUNT(*) FILTER (WHERE is_measurable AND is_in_primary_window),
       ROUND(100.0 * COUNT(*) FILTER (WHERE is_on_time AND is_in_primary_window)
             / NULLIF(COUNT(*) FILTER (WHERE is_measurable AND is_in_primary_window), 0), 1),
       'Every delivery, so a split shipment counts twice'
FROM   vw_receipt_performance
UNION ALL
SELECT 'Line complete on time (OTIF)',
       COUNT(*) FILTER (WHERE is_measurable AND is_in_primary_window),
       ROUND(100.0 * COUNT(*) FILTER (WHERE is_complete_on_time AND is_in_primary_window)
             / NULLIF(COUNT(*) FILTER (WHERE is_measurable AND is_in_primary_window), 0), 1),
       'Full quantity received by the promised date'
FROM   vw_line_completion;


\echo '=== 3. Supplier type by half-year, all three measures ==='

WITH receipt_side AS (
    SELECT
        supplier_type,
        order_half_year,
        COUNT(*) FILTER (WHERE is_measurable AND receipt_sequence = 1)    AS n_first,
        ROUND(100.0 * COUNT(*) FILTER (WHERE is_on_time AND receipt_sequence = 1)
              / NULLIF(COUNT(*) FILTER (WHERE is_measurable AND receipt_sequence = 1), 0), 1)
                                                                         AS on_time_first_pct,
        COUNT(*) FILTER (WHERE is_measurable)                            AS n_all,
        ROUND(100.0 * COUNT(*) FILTER (WHERE is_on_time)
              / NULLIF(COUNT(*) FILTER (WHERE is_measurable), 0), 1)     AS on_time_all_pct
    FROM   vw_receipt_performance
    WHERE  is_in_primary_window
    GROUP  BY supplier_type, order_half_year
),

line_side AS (
    SELECT
        supplier_type,
        order_half_year,
        COUNT(*) FILTER (WHERE is_measurable)                            AS n_lines,
        ROUND(100.0 * COUNT(*) FILTER (WHERE is_complete_on_time)
              / NULLIF(COUNT(*) FILTER (WHERE is_measurable), 0), 1)     AS otif_pct
    FROM   vw_line_completion
    WHERE  is_in_primary_window
    GROUP  BY supplier_type, order_half_year
)

SELECT
    r.supplier_type,
    r.order_half_year,
    r.n_first,
    r.on_time_first_pct,
    r.n_all,
    r.on_time_all_pct,
    l.n_lines,
    l.otif_pct
FROM       receipt_side AS r
INNER JOIN line_side    AS l
       ON  l.supplier_type = r.supplier_type AND l.order_half_year = r.order_half_year
ORDER  BY  r.supplier_type, r.order_half_year;


\echo '=== 4. Every supplier, comparable window, with counts ==='

SELECT
    supplier_code,
    supplier_name,
    supplier_type,
    COUNT(*) FILTER (WHERE is_measurable)                                AS n_receipts,
    COUNT(*) FILTER (WHERE is_measurable AND receipt_sequence = 1)       AS n_first,
    ROUND(100.0 * COUNT(*) FILTER (WHERE is_on_time AND receipt_sequence = 1)
          / NULLIF(COUNT(*) FILTER (WHERE is_measurable AND receipt_sequence = 1), 0), 1)
                                                                         AS on_time_first_pct,
    ROUND(100.0 * COUNT(*) FILTER (WHERE is_on_time)
          / NULLIF(COUNT(*) FILTER (WHERE is_measurable), 0), 1)         AS on_time_all_pct,
    ROUND(100.0 * COUNT(*) FILTER (WHERE receipt_sequence > 1) / COUNT(*), 1)
                                                                         AS split_delivery_rate_pct,
    COUNT(DISTINCT warehouse_code)                                       AS sites_supplied
FROM   vw_receipt_performance
WHERE  is_in_primary_window
GROUP  BY supplier_code, supplier_name, supplier_type
ORDER  BY on_time_first_pct;


\echo '=== 5. Who changed? Every supplier ranked by measured movement ==='

-- No supplier is singled out in advance. The comparison is the first full half
-- against the last measurable one, restricted to suppliers with at least 15
-- first receipts in both, so a swing on five deliveries cannot reach the top.
WITH by_half AS (
    SELECT
        supplier_code,
        supplier_name,
        supplier_type,
        order_half_year,
        COUNT(*) FILTER (WHERE is_measurable AND receipt_sequence = 1)   AS n_first,
        100.0 * COUNT(*) FILTER (WHERE is_on_time AND receipt_sequence = 1)
              / NULLIF(COUNT(*) FILTER (WHERE is_measurable AND receipt_sequence = 1), 0)
                                                                         AS on_time_first_pct
    FROM   vw_receipt_performance
    WHERE  is_in_primary_window
    GROUP  BY supplier_code, supplier_name, supplier_type, order_half_year
),

movement AS (
    SELECT
        supplier_code,
        supplier_name,
        supplier_type,
        MAX(n_first)            FILTER (WHERE order_half_year = '2024H1') AS n_2024h1,
        MAX(on_time_first_pct)  FILTER (WHERE order_half_year = '2024H1') AS pct_2024h1,
        MAX(n_first)            FILTER (WHERE order_half_year = '2024H2') AS n_2024h2,
        MAX(on_time_first_pct)  FILTER (WHERE order_half_year = '2024H2') AS pct_2024h2,
        MAX(n_first)            FILTER (WHERE order_half_year = '2025H1') AS n_2025h1,
        MAX(on_time_first_pct)  FILTER (WHERE order_half_year = '2025H1') AS pct_2025h1,
        MAX(n_first)            FILTER (WHERE order_half_year = '2025H2') AS n_2025h2,
        MAX(on_time_first_pct)  FILTER (WHERE order_half_year = '2025H2') AS pct_2025h2
    FROM   by_half
    GROUP  BY supplier_code, supplier_name, supplier_type
)

SELECT
    supplier_code,
    supplier_name,
    supplier_type,
    n_2024h1, ROUND(pct_2024h1, 1)                                       AS pct_2024h1,
    n_2024h2, ROUND(pct_2024h2, 1)                                       AS pct_2024h2,
    n_2025h1, ROUND(pct_2025h1, 1)                                       AS pct_2025h1,
    n_2025h2, ROUND(pct_2025h2, 1)                                       AS pct_2025h2,
    ROUND(pct_2025h2 - pct_2024h1, 1)                                    AS change_points,
    CASE WHEN LEAST(COALESCE(n_2024h1, 0), COALESCE(n_2025h2, 0)) >= :min_cell
         THEN 'yes' ELSE 'no — thin cell' END                            AS meets_minimum_n
FROM   movement
WHERE  n_2024h1 IS NOT NULL AND n_2025h2 IS NOT NULL
ORDER  BY change_points;


\echo '=== 6. The two suppliers with the largest movement, in detail ==='

-- Identified by section 5, not chosen in advance. Both on-time measures shown
-- against the network baseline for the same half, so a general drift in
-- performance cannot be read as a supplier-specific one.
WITH baseline AS (
    SELECT
        order_half_year,
        COUNT(*) FILTER (WHERE is_measurable AND receipt_sequence = 1)   AS n_network,
        ROUND(100.0 * COUNT(*) FILTER (WHERE is_on_time AND receipt_sequence = 1)
              / NULLIF(COUNT(*) FILTER (WHERE is_measurable AND receipt_sequence = 1), 0), 1)
                                                                         AS network_on_time_first_pct
    FROM   vw_receipt_performance
    WHERE  is_in_primary_window
    GROUP  BY order_half_year
),

focus AS (
    SELECT
        supplier_code,
        supplier_name,
        order_half_year,
        COUNT(*) FILTER (WHERE is_measurable AND receipt_sequence = 1)   AS n_first,
        ROUND(100.0 * COUNT(*) FILTER (WHERE is_on_time AND receipt_sequence = 1)
              / NULLIF(COUNT(*) FILTER (WHERE is_measurable AND receipt_sequence = 1), 0), 1)
                                                                         AS on_time_first_pct,
        COUNT(*) FILTER (WHERE is_measurable)                            AS n_all,
        ROUND(100.0 * COUNT(*) FILTER (WHERE is_on_time)
              / NULLIF(COUNT(*) FILTER (WHERE is_measurable), 0), 1)     AS on_time_all_pct,
        ROUND(AVG(lead_time_variance_days) FILTER (WHERE receipt_sequence = 1), 1)
                                                                         AS mean_days_over_quoted
    FROM   vw_receipt_performance
    WHERE  is_in_primary_window
      AND  supplier_code IN ('MERID', 'KELSO')
    GROUP  BY supplier_code, supplier_name, order_half_year
)

SELECT
    f.supplier_code,
    f.supplier_name,
    f.order_half_year,
    f.n_first,
    f.on_time_first_pct,
    f.n_all,
    f.on_time_all_pct,
    f.mean_days_over_quoted,
    b.n_network,
    b.network_on_time_first_pct,
    ROUND(f.on_time_first_pct - b.network_on_time_first_pct, 1)          AS points_above_network
FROM       focus    AS f
INNER JOIN baseline AS b ON b.order_half_year = f.order_half_year
ORDER  BY  f.supplier_code, f.order_half_year;


\echo '=== 7. The excluded period, shown separately and not mixed in ==='

-- Orders placed after 2025-09-30. Reported so the exclusion is visible, with
-- the evidence for why it cannot join the trend: the unreceived share.
WITH ordered_after AS (
    SELECT
        s.supplier_type,
        pol.purchase_order_number,
        pol.line_number,
        COUNT(grl.receipt_reference)                                     AS receipts_recorded
    FROM       purchase_order_line AS pol
    INNER JOIN purchase_order      AS po  ON po.purchase_order_number = pol.purchase_order_number
    INNER JOIN supplier            AS s   ON s.supplier_code = po.supplier_code
    LEFT JOIN  goods_receipt_line  AS grl
           ON  grl.purchase_order_number      = pol.purchase_order_number
          AND  grl.purchase_order_line_number = pol.line_number
    WHERE      po.order_date > DATE :'window_close'
    GROUP  BY  s.supplier_type, pol.purchase_order_number, pol.line_number
),

measured_after AS (
    SELECT
        supplier_type,
        COUNT(*) FILTER (WHERE is_measurable AND receipt_sequence = 1)   AS n_first,
        ROUND(100.0 * COUNT(*) FILTER (WHERE is_on_time AND receipt_sequence = 1)
              / NULLIF(COUNT(*) FILTER (WHERE is_measurable AND receipt_sequence = 1), 0), 1)
                                                                         AS on_time_first_pct
    FROM   vw_receipt_performance
    WHERE  NOT is_in_primary_window
    GROUP  BY supplier_type
)

SELECT
    o.supplier_type,
    COUNT(*)                                                             AS lines_ordered_after_cutoff,
    COUNT(*) FILTER (WHERE o.receipts_recorded = 0)                      AS lines_with_no_receipt,
    ROUND(100.0 * COUNT(*) FILTER (WHERE o.receipts_recorded = 0) / COUNT(*), 1)
                                                                         AS unreceived_pct,
    m.n_first                                                            AS n_first_measurable,
    m.on_time_first_pct                                                  AS on_time_first_pct_truncated,
    'Not comparable — survivors only'                                    AS caveat
FROM       ordered_after  AS o
LEFT JOIN  measured_after AS m ON m.supplier_type = o.supplier_type
GROUP  BY  o.supplier_type, m.n_first, m.on_time_first_pct
ORDER  BY  unreceived_pct DESC;


\echo '=== 8. Supplier against its own type — how much is the archetype? ==='

-- If a supplier's performance were fully explained by what kind of supplier it
-- is, every deviation would be near zero. The spread of deviations says how
-- much is individual.
WITH supplier_rate AS (
    SELECT
        supplier_code,
        supplier_name,
        supplier_type,
        COUNT(*) FILTER (WHERE is_measurable AND receipt_sequence = 1)   AS n_first,
        100.0 * COUNT(*) FILTER (WHERE is_on_time AND receipt_sequence = 1)
              / NULLIF(COUNT(*) FILTER (WHERE is_measurable AND receipt_sequence = 1), 0)
                                                                         AS supplier_pct
    FROM   vw_receipt_performance
    WHERE  is_in_primary_window
    GROUP  BY supplier_code, supplier_name, supplier_type
),

type_rate AS (
    SELECT
        supplier_type,
        100.0 * COUNT(*) FILTER (WHERE is_on_time AND receipt_sequence = 1)
              / NULLIF(COUNT(*) FILTER (WHERE is_measurable AND receipt_sequence = 1), 0)
                                                                         AS type_pct
    FROM   vw_receipt_performance
    WHERE  is_in_primary_window
    GROUP  BY supplier_type
)

SELECT
    s.supplier_type,
    COUNT(*)                                                             AS suppliers,
    SUM(s.n_first)                                                       AS total_first_receipts,
    ROUND(MAX(t.type_pct), 1)                                            AS type_on_time_pct,
    ROUND(MIN(s.supplier_pct), 1)                                        AS worst_supplier_pct,
    ROUND(MAX(s.supplier_pct), 1)                                        AS best_supplier_pct,
    ROUND(MAX(s.supplier_pct) - MIN(s.supplier_pct), 1)                  AS spread_within_type,
    ROUND(STDDEV_SAMP(s.supplier_pct), 1)                                AS stddev_within_type
FROM       supplier_rate AS s
INNER JOIN type_rate     AS t ON t.supplier_type = s.supplier_type
WHERE      s.n_first >= :min_cell
GROUP  BY  s.supplier_type
ORDER  BY  spread_within_type DESC;


\echo '=== 8b. Is a type-level trend really the type, or one supplier? ==='

-- A supplier type is only a useful unit of analysis if it behaves like one.
-- Each type's largest supplier by volume is removed and the trend recomputed.
-- Where the trend survives, it belongs to the archetype. Where it collapses, it
-- belonged to one relationship and should never have been described as a type
-- problem. See docs/DECISIONS.md D-26.
WITH volume_rank AS (
    SELECT
        supplier_code,
        supplier_type,
        COUNT(*)                                                         AS receipts,
        ROW_NUMBER() OVER (PARTITION BY supplier_type ORDER BY COUNT(*) DESC)
                                                                         AS rank_in_type
    FROM   vw_receipt_performance
    WHERE  is_in_primary_window
    GROUP  BY supplier_code, supplier_type
),

largest AS (
    SELECT supplier_type, supplier_code, receipts
    FROM   volume_rank WHERE rank_in_type = 1
)

SELECT
    r.supplier_type,
    l.supplier_code                                                      AS largest_supplier,
    l.receipts                                                           AS largest_supplier_receipts,
    r.order_half_year,
    COUNT(*) FILTER (WHERE r.is_measurable AND r.receipt_sequence = 1)   AS n_all_suppliers,
    ROUND(100.0 * COUNT(*) FILTER (WHERE r.is_on_time AND r.receipt_sequence = 1)
          / NULLIF(COUNT(*) FILTER (WHERE r.is_measurable AND r.receipt_sequence = 1), 0), 1)
                                                                         AS on_time_all_suppliers_pct,
    COUNT(*) FILTER (WHERE r.is_measurable AND r.receipt_sequence = 1
                       AND r.supplier_code <> l.supplier_code)           AS n_excluding_largest,
    ROUND(100.0 * COUNT(*) FILTER (WHERE r.is_on_time AND r.receipt_sequence = 1
                                     AND r.supplier_code <> l.supplier_code)
          / NULLIF(COUNT(*) FILTER (WHERE r.is_measurable AND r.receipt_sequence = 1
                                      AND r.supplier_code <> l.supplier_code), 0), 1)
                                                                         AS on_time_excluding_largest_pct
FROM       vw_receipt_performance AS r
INNER JOIN largest                AS l ON l.supplier_type = r.supplier_type
WHERE      r.is_in_primary_window
GROUP  BY  r.supplier_type, l.supplier_code, l.receipts, r.order_half_year
ORDER  BY  r.supplier_type, r.order_half_year;


\echo '=== 9. Reconciliation ==='

SELECT
    'Goods receipt lines — source table'                                 AS measure,
    (SELECT COUNT(*) FROM goods_receipt_line)::numeric                   AS value
UNION ALL
SELECT 'Goods receipt lines — vw_receipt_performance',
       (SELECT COUNT(*) FROM vw_receipt_performance)::numeric
UNION ALL
SELECT 'Purchase order lines — source table',
       (SELECT COUNT(*) FROM purchase_order_line)::numeric
UNION ALL
SELECT 'Purchase order lines — vw_line_completion',
       (SELECT COUNT(*) FROM vw_line_completion)::numeric
UNION ALL
SELECT 'Units received — goods_receipt_line',
       (SELECT SUM(quantity_received) FROM goods_receipt_line)::numeric
UNION ALL
SELECT 'Units received — vw_line_completion (pre-aggregated, no fan-out)',
       (SELECT SUM(units_received) FROM vw_line_completion)::numeric
UNION ALL
SELECT 'Lines where received exceeds ordered (must be 0)',
       (SELECT COUNT(*) FROM vw_line_completion
        WHERE units_received + units_rejected > quantity_ordered)::numeric;
