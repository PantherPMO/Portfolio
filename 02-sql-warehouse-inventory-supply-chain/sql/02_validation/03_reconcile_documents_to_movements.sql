/* ============================================================
   Project    : 02 — Warehouse Inventory & Supply Chain Performance
   File       : 02_validation/03_reconcile_documents_to_movements.sql
   Question   : Do the transaction documents and the stock ledger tell
                the same story?
   Output     : analysis/query_results/validate_03_document_reconciliation.txt
   Author     : Peters
   Created    : 2026-08-23
   ============================================================

   A goods receipt line, a sales order line and a stock movement are
   three records of the same physical event. If they disagree, every
   figure built on them is wrong.

   Receipts are pre-aggregated before any comparison against ordered
   quantity: a purchase order line can be received more than once
   (split deliveries), so joining the two directly fans out and inflates
   ordered quantity by the number of receipts against it.
   ============================================================ */

SET search_path TO supply;

\echo '=== 1. Receipts against the stock ledger ==='

SELECT
    'Goods receipt movements equal accepted receipt quantity'            AS check_name,
    (SELECT SUM(quantity) FROM stock_movement
     WHERE movement_type = 'Goods receipt')                              AS ledger_units,
    (SELECT SUM(quantity_received) FROM goods_receipt_line)              AS document_units,
    CASE WHEN (SELECT SUM(quantity) FROM stock_movement WHERE movement_type = 'Goods receipt')
            = (SELECT SUM(quantity_received) FROM goods_receipt_line)
         THEN 'PASS' ELSE 'FAIL' END                                     AS result
UNION ALL
SELECT
    'Sales issue movements equal despatched quantity',
    -(SELECT SUM(quantity) FROM stock_movement WHERE movement_type = 'Sales issue'),
    (SELECT SUM(quantity_despatched) FROM sales_order_line),
    CASE WHEN -(SELECT SUM(quantity) FROM stock_movement WHERE movement_type = 'Sales issue')
            = (SELECT SUM(quantity_despatched) FROM sales_order_line)
         THEN 'PASS' ELSE 'FAIL' END;


\echo '=== 2. Receipts never exceed what was ordered ==='

WITH receipt_totals AS (
    -- Pre-aggregated to one row per purchase order line. This is the join that
    -- fans out if taken directly against purchase_order_line.
    SELECT
        purchase_order_number,
        purchase_order_line_number,
        COUNT(*)                                     AS receipt_events,
        SUM(quantity_received)                       AS units_received,
        SUM(quantity_rejected)                       AS units_rejected
    FROM   goods_receipt_line
    GROUP  BY purchase_order_number, purchase_order_line_number
)

SELECT
    'Purchase order lines'                                               AS check_name,
    COUNT(*)                                                             AS line_count,
    NULL                                                                 AS result
FROM   purchase_order_line
UNION ALL
SELECT
    'Lines over-received (received + rejected > ordered)',
    COUNT(*),
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM       purchase_order_line AS pol
INNER JOIN receipt_totals      AS rt
       ON  rt.purchase_order_number      = pol.purchase_order_number
      AND  rt.purchase_order_line_number = pol.line_number
WHERE      rt.units_received + rt.units_rejected > pol.quantity_ordered
UNION ALL
SELECT
    'Lines marked Received in full that are not',
    COUNT(*),
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM       purchase_order_line AS pol
LEFT JOIN  receipt_totals      AS rt
       ON  rt.purchase_order_number      = pol.purchase_order_number
      AND  rt.purchase_order_line_number = pol.line_number
WHERE      pol.line_status = 'Received in full'
  AND      COALESCE(rt.units_received, 0) + COALESCE(rt.units_rejected, 0) < pol.quantity_ordered
UNION ALL
SELECT
    'Receipts dated before their order date',
    COUNT(*),
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM       goods_receipt_line AS grl
INNER JOIN purchase_order     AS po ON po.purchase_order_number = grl.purchase_order_number
WHERE      grl.receipt_date < po.order_date;


\echo '=== 3. Split delivery profile ==='

-- Reported rather than asserted: the split rate is what makes per-receipt and
-- per-line on-time measurement give different answers in the supplier analysis.
WITH receipts_per_line AS (
    SELECT
        purchase_order_number,
        purchase_order_line_number,
        COUNT(*)                                     AS receipt_events
    FROM   goods_receipt_line
    GROUP  BY purchase_order_number, purchase_order_line_number
)

SELECT
    receipt_events                                                       AS receipts_against_one_line,
    COUNT(*)                                                             AS purchase_order_lines,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1)                   AS share_pct
FROM   receipts_per_line
GROUP  BY receipt_events
ORDER  BY receipt_events;


\echo '=== 4. Transfers net to zero on every reference ==='

WITH transfer_pairs AS (
    SELECT
        source_document,
        SUM(quantity)                                AS net_units,
        COUNT(*)                                     AS movement_rows,
        COUNT(DISTINCT warehouse_code)               AS sites_involved
    FROM   stock_movement
    WHERE  movement_type IN ('Transfer out', 'Transfer in')
    GROUP  BY source_document
)

SELECT
    'Transfer references'                                                AS check_name,
    COUNT(*)                                                             AS transfer_count,
    NULL                                                                 AS result
FROM   transfer_pairs
UNION ALL
SELECT
    'References that do not net to zero',
    COUNT(*) FILTER (WHERE net_units <> 0),
    CASE WHEN COUNT(*) FILTER (WHERE net_units <> 0) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM   transfer_pairs
UNION ALL
SELECT
    'References not spanning exactly two sites',
    COUNT(*) FILTER (WHERE sites_involved <> 2 OR movement_rows <> 2),
    CASE WHEN COUNT(*) FILTER (WHERE sites_involved <> 2 OR movement_rows <> 2) = 0
         THEN 'PASS' ELSE 'FAIL' END
FROM   transfer_pairs;


\echo '=== 5. Sales fulfilment consistency ==='

SELECT
    'Lines despatching more than ordered'                                AS check_name,
    COUNT(*) FILTER (WHERE quantity_despatched > quantity_ordered)       AS breaches,
    CASE WHEN COUNT(*) FILTER (WHERE quantity_despatched > quantity_ordered) = 0
         THEN 'PASS' ELSE 'FAIL' END                                     AS result
FROM   sales_order_line
UNION ALL
SELECT
    'Cancelled lines despatching stock',
    COUNT(*) FILTER (WHERE line_status = 'Cancelled' AND quantity_despatched > 0),
    CASE WHEN COUNT(*) FILTER (WHERE line_status = 'Cancelled' AND quantity_despatched > 0) = 0
         THEN 'PASS' ELSE 'FAIL' END
FROM   sales_order_line
UNION ALL
SELECT
    'Despatched lines without a sales issue movement',
    COUNT(*),
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM      (SELECT DISTINCT sales_order_number
           FROM   sales_order_line
           WHERE  quantity_despatched > 0)                               AS despatched
LEFT JOIN (SELECT DISTINCT source_document
           FROM   stock_movement
           WHERE  movement_type = 'Sales issue')                         AS issued
       ON  issued.source_document = despatched.sales_order_number
WHERE      issued.source_document IS NULL;


\echo '=== 6. Movement mix ==='

-- 'Transfer out' is stock leaving a site for another site, not a sale. Counting
-- it as demand overstates Daventry, which supplies the regional network.
SELECT
    movement_type,
    COUNT(*)                                         AS movement_rows,
    SUM(quantity)                                    AS net_units,
    ROUND(SUM(ABS(quantity) * unit_cost_gbp), 2)     AS gross_value_gbp
FROM   stock_movement
GROUP  BY movement_type
ORDER  BY movement_rows DESC;
