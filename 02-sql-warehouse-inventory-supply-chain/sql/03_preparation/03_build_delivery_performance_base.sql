/* ============================================================
   Project    : 02 — Warehouse Inventory & Supply Chain Performance
   File       : 03_preparation/03_build_delivery_performance_base.sql
   Question   : When a supplier promised a delivery date, what actually
                happened?
   Output     : view supply.vw_receipt_performance
   Author     : Peters
   Created    : 2026-08-23
   ============================================================

   Grain: one row per goods receipt line. Every receipt is kept —
   including the ones that cannot be measured — so the denominator is
   always visible rather than quietly reduced by a WHERE clause.

   Four flags carry the measurement rules, and each exists because of
   something real in this data:

   is_measurable        22 purchase orders carry no promised date and 24
                        carry a promised date before the order date.
                        Neither can be measured for lateness.

   receipt_sequence     A purchase order line can be received more than
                        once. Measuring on-time per receipt row counts a
                        split delivery as two events, one of which is
                        late by construction. Sequence 1 is the
                        first-delivery measure; all rows together are the
                        in-full measure. Both are reported. See D-07.

   is_in_primary_window Orders placed after 2025-09-30 are excluded from
                        the headline figures. Importer lead times run
                        near 78 days, so late-2025 orders had not arrived
                        by the end of the data — 77% of Q4 importer
                        orders have no receipt at all. Measuring them
                        would compute an on-time rate on the ones that
                        happened to come back early. See D-04.

   booked_on_monday     Livingston books goods inwards in a Monday
                        batch, so 42.7% of its receipts land on a Monday
                        against 18-20% elsewhere. This inflates its
                        measured lead times. It is a Livingston process
                        problem, not a supplier problem, and supplier
                        comparison must control for receiving site.
                        See D-08.
   ============================================================ */

SET search_path TO supply;

CREATE OR REPLACE VIEW vw_receipt_performance AS

WITH sequenced AS (
    SELECT
        grl.receipt_reference,
        grl.line_number,
        grl.purchase_order_number,
        grl.purchase_order_line_number,
        grl.warehouse_code,
        grl.receipt_date,
        grl.quantity_received,
        grl.quantity_rejected,
        ROW_NUMBER() OVER (
            PARTITION BY grl.purchase_order_number, grl.purchase_order_line_number
            ORDER BY     grl.receipt_date, grl.receipt_reference
        )                                            AS receipt_sequence,
        COUNT(*)     OVER (
            PARTITION BY grl.purchase_order_number, grl.purchase_order_line_number
        )                                            AS receipts_against_line
    FROM   goods_receipt_line AS grl
)

SELECT
    s.receipt_reference,
    s.line_number,
    s.purchase_order_number,
    s.purchase_order_line_number,
    s.receipt_sequence,
    s.receipts_against_line,
    po.supplier_code,
    sup.supplier_name,
    sup.supplier_type,
    sup.country,
    s.warehouse_code,
    pol.sku,
    p.category_code,
    po.buyer_name,
    po.order_date,
    po.promised_delivery_date,
    s.receipt_date,
    pol.quantity_ordered,
    s.quantity_received,
    s.quantity_rejected,
    pol.unit_cost_gbp,
    ps.quoted_lead_time_days,
    (s.receipt_date - po.order_date)                 AS actual_lead_time_days,
    -- Positive means later than quoted. Measured against the quoted lead time
    -- rather than the promised date so it survives the invalid promised dates.
    (s.receipt_date - po.order_date) - ps.quoted_lead_time_days
                                                     AS lead_time_variance_days,
    TO_CHAR(po.order_date, 'YYYY"Q"Q')               AS order_quarter,
    CONCAT(EXTRACT(YEAR FROM po.order_date)::int,
           CASE WHEN EXTRACT(MONTH FROM po.order_date) <= 6 THEN 'H1' ELSE 'H2' END)
                                                     AS order_half_year,
    po.promised_delivery_date IS NOT NULL
        AND po.promised_delivery_date >= po.order_date
                                                     AS is_measurable,
    po.order_date <= DATE '2025-09-30'               AS is_in_primary_window,
    CASE WHEN po.promised_delivery_date IS NOT NULL
              AND po.promised_delivery_date >= po.order_date
         THEN s.receipt_date <= po.promised_delivery_date
    END                                              AS is_on_time,
    EXTRACT(ISODOW FROM s.receipt_date)::int = 1     AS booked_on_monday,
    TO_CHAR(s.receipt_date, 'Day')                   AS receipt_weekday
FROM       sequenced           AS s
INNER JOIN purchase_order_line AS pol
       ON  pol.purchase_order_number = s.purchase_order_number
      AND  pol.line_number           = s.purchase_order_line_number
INNER JOIN purchase_order      AS po  ON po.purchase_order_number = s.purchase_order_number
INNER JOIN supplier            AS sup ON sup.supplier_code = po.supplier_code
INNER JOIN product             AS p   ON p.sku = pol.sku
-- The quoted lead time belongs to the SKU/supplier agreement, not the supplier.
-- LEFT JOIN would hide a purchase placed outside the approved sourcing list;
-- INNER JOIN plus the row-count check below proves there are none.
INNER JOIN product_supplier    AS ps
       ON  ps.sku = pol.sku AND ps.supplier_code = po.supplier_code;


\echo '=== Coverage: every receipt accounted for ==='

SELECT
    'goods_receipt_line rows'                        AS population,
    (SELECT COUNT(*) FROM goods_receipt_line)        AS receipt_count,
    NULL::numeric                                    AS share_pct
UNION ALL
SELECT 'rows in vw_receipt_performance', COUNT(*), NULL
FROM   vw_receipt_performance
UNION ALL
SELECT 'measurable for lateness', COUNT(*) FILTER (WHERE is_measurable),
       ROUND(100.0 * COUNT(*) FILTER (WHERE is_measurable) / COUNT(*), 1)
FROM   vw_receipt_performance
UNION ALL
SELECT 'excluded — no promised date', COUNT(*) FILTER (WHERE promised_delivery_date IS NULL),
       ROUND(100.0 * COUNT(*) FILTER (WHERE promised_delivery_date IS NULL) / COUNT(*), 1)
FROM   vw_receipt_performance
UNION ALL
SELECT 'excluded — promised before ordered',
       COUNT(*) FILTER (WHERE promised_delivery_date < order_date),
       ROUND(100.0 * COUNT(*) FILTER (WHERE promised_delivery_date < order_date) / COUNT(*), 1)
FROM   vw_receipt_performance
UNION ALL
SELECT 'second or later delivery against a line',
       COUNT(*) FILTER (WHERE receipt_sequence > 1),
       ROUND(100.0 * COUNT(*) FILTER (WHERE receipt_sequence > 1) / COUNT(*), 1)
FROM   vw_receipt_performance
UNION ALL
SELECT 'outside the primary window (ordered after 2025-09-30)',
       COUNT(*) FILTER (WHERE NOT is_in_primary_window),
       ROUND(100.0 * COUNT(*) FILTER (WHERE NOT is_in_primary_window) / COUNT(*), 1)
FROM   vw_receipt_performance;


\echo '=== The two on-time measures differ, and this is why ==='

SELECT
    'First delivery against each line'                                    AS measure,
    COUNT(*) FILTER (WHERE is_measurable AND is_in_primary_window
                       AND receipt_sequence = 1)                          AS receipts,
    ROUND(100.0 * COUNT(*) FILTER (WHERE is_on_time AND is_in_primary_window
                                     AND receipt_sequence = 1)
          / NULLIF(COUNT(*) FILTER (WHERE is_measurable AND is_in_primary_window
                                      AND receipt_sequence = 1), 0), 1)   AS on_time_pct
FROM   vw_receipt_performance
UNION ALL
SELECT
    'All deliveries (on time and in full)',
    COUNT(*) FILTER (WHERE is_measurable AND is_in_primary_window),
    ROUND(100.0 * COUNT(*) FILTER (WHERE is_on_time AND is_in_primary_window)
          / NULLIF(COUNT(*) FILTER (WHERE is_measurable AND is_in_primary_window), 0), 1)
FROM   vw_receipt_performance;


\echo '=== Monday booking pattern by receiving site ==='

SELECT
    warehouse_code,
    COUNT(*)                                                             AS receipts,
    COUNT(*) FILTER (WHERE booked_on_monday)                             AS booked_monday,
    ROUND(100.0 * COUNT(*) FILTER (WHERE booked_on_monday) / COUNT(*), 1) AS monday_share_pct,
    ROUND(AVG(lead_time_variance_days), 1)                               AS mean_days_over_quoted
FROM   vw_receipt_performance
WHERE  is_in_primary_window
GROUP  BY warehouse_code
ORDER  BY monday_share_pct DESC;
