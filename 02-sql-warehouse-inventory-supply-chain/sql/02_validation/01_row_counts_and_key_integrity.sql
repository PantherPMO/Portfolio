/* ============================================================
   Project    : 02 — Warehouse Inventory & Supply Chain Performance
   File       : 02_validation/01_row_counts_and_key_integrity.sql
   Question   : Did the database receive exactly what the source files
                hold, with every relationship intact?
   Output     : analysis/query_results/validate_01_row_counts_and_keys.txt
   Author     : Peters
   Created    : 2026-08-23
   ============================================================

   Primary and foreign keys are enforced by the schema, so a successful
   load already proves referential integrity. The checks below are the
   documented evidence of that, plus the things constraints cannot
   express: expected row counts, the specific nulls that are meant to be
   there, and the structural rules the data model assumes.
   ============================================================ */

SET search_path TO supply;

\echo '=== 1. Row counts against the source files ==='

WITH loaded AS (
    SELECT 'warehouse'            AS table_name, COUNT(*) AS row_count FROM warehouse
    UNION ALL SELECT 'product_category',     COUNT(*) FROM product_category
    UNION ALL SELECT 'product',              COUNT(*) FROM product
    UNION ALL SELECT 'supplier',             COUNT(*) FROM supplier
    UNION ALL SELECT 'product_supplier',     COUNT(*) FROM product_supplier
    UNION ALL SELECT 'customer',             COUNT(*) FROM customer
    UNION ALL SELECT 'calendar_week',        COUNT(*) FROM calendar_week
    UNION ALL SELECT 'replenishment_policy', COUNT(*) FROM replenishment_policy
    UNION ALL SELECT 'purchase_order',       COUNT(*) FROM purchase_order
    UNION ALL SELECT 'purchase_order_line',  COUNT(*) FROM purchase_order_line
    UNION ALL SELECT 'goods_receipt_line',   COUNT(*) FROM goods_receipt_line
    UNION ALL SELECT 'sales_order',          COUNT(*) FROM sales_order
    UNION ALL SELECT 'sales_order_line',     COUNT(*) FROM sales_order_line
    UNION ALL SELECT 'stock_movement',       COUNT(*) FROM stock_movement
    UNION ALL SELECT 'inventory_snapshot',   COUNT(*) FROM inventory_snapshot
),

expected (table_name, expected_rows) AS (
    VALUES ('warehouse', 4), ('product_category', 8), ('product', 250),
           ('supplier', 30), ('product_supplier', 344), ('customer', 500),
           ('calendar_week', 104), ('replenishment_policy', 515),
           ('purchase_order', 2103), ('purchase_order_line', 4457),
           ('goods_receipt_line', 4853), ('sales_order', 10027),
           ('sales_order_line', 33422), ('stock_movement', 39752),
           ('inventory_snapshot', 51220)
)

SELECT
    e.table_name,
    e.expected_rows,
    l.row_count                                          AS loaded_rows,
    CASE WHEN l.row_count = e.expected_rows
         THEN 'PASS' ELSE 'FAIL' END                     AS result
FROM       expected AS e
INNER JOIN loaded   AS l ON l.table_name = e.table_name
ORDER BY   e.table_name;


\echo '=== 2. Foreign key relationships (anti-join verification) ==='

SELECT 'product -> product_category'                 AS relationship, COUNT(*) AS orphan_rows
FROM       product            AS p
LEFT JOIN  product_category   AS c ON c.category_code = p.category_code
WHERE      c.category_code IS NULL
UNION ALL
SELECT 'product_supplier -> product', COUNT(*)
FROM       product_supplier   AS ps
LEFT JOIN  product            AS p ON p.sku = ps.sku
WHERE      p.sku IS NULL
UNION ALL
SELECT 'product_supplier -> supplier', COUNT(*)
FROM       product_supplier   AS ps
LEFT JOIN  supplier           AS s ON s.supplier_code = ps.supplier_code
WHERE      s.supplier_code IS NULL
UNION ALL
SELECT 'customer -> warehouse', COUNT(*)
FROM       customer           AS c
LEFT JOIN  warehouse          AS w ON w.warehouse_code = c.primary_warehouse_code
WHERE      w.warehouse_code IS NULL
UNION ALL
SELECT 'replenishment_policy -> product', COUNT(*)
FROM       replenishment_policy AS rp
LEFT JOIN  product              AS p ON p.sku = rp.sku
WHERE      p.sku IS NULL
UNION ALL
SELECT 'purchase_order_line -> purchase_order', COUNT(*)
FROM       purchase_order_line AS pol
LEFT JOIN  purchase_order      AS po ON po.purchase_order_number = pol.purchase_order_number
WHERE      po.purchase_order_number IS NULL
UNION ALL
SELECT 'goods_receipt_line -> purchase_order_line', COUNT(*)
FROM       goods_receipt_line  AS grl
LEFT JOIN  purchase_order_line AS pol
       ON  pol.purchase_order_number = grl.purchase_order_number
      AND  pol.line_number           = grl.purchase_order_line_number
WHERE      pol.purchase_order_number IS NULL
UNION ALL
SELECT 'sales_order_line -> sales_order', COUNT(*)
FROM       sales_order_line    AS sol
LEFT JOIN  sales_order         AS so ON so.sales_order_number = sol.sales_order_number
WHERE      so.sales_order_number IS NULL
UNION ALL
SELECT 'stock_movement -> product', COUNT(*)
FROM       stock_movement      AS sm
LEFT JOIN  product             AS p ON p.sku = sm.sku
WHERE      p.sku IS NULL
UNION ALL
SELECT 'inventory_snapshot -> calendar_week', COUNT(*)
FROM       inventory_snapshot  AS inv
LEFT JOIN  calendar_week       AS cw ON cw.week_ending_date = inv.week_ending_date
WHERE      cw.week_ending_date IS NULL
-- An unordered UNION ALL returns rows in whatever order the planner
-- produces them, which differs between runs and makes the committed
-- result non-reproducible. Ordered by the relationship label.
ORDER  BY  1;


\echo '=== 3. Null profile — the gaps that are meant to be there ==='

SELECT
    'product.unit_weight_kg'                         AS column_name,
    COUNT(*) FILTER (WHERE unit_weight_kg IS NULL)   AS null_rows,
    COUNT(*)                                         AS total_rows,
    ROUND(100.0 * COUNT(*) FILTER (WHERE unit_weight_kg IS NULL) / COUNT(*), 1) AS null_pct
FROM   product
UNION ALL
SELECT 'product.unit_volume_m3',
       COUNT(*) FILTER (WHERE unit_volume_m3 IS NULL), COUNT(*),
       ROUND(100.0 * COUNT(*) FILTER (WHERE unit_volume_m3 IS NULL) / COUNT(*), 1)
FROM   product
UNION ALL
SELECT 'product.shelf_life_months',
       COUNT(*) FILTER (WHERE shelf_life_months IS NULL), COUNT(*),
       ROUND(100.0 * COUNT(*) FILTER (WHERE shelf_life_months IS NULL) / COUNT(*), 1)
FROM   product
UNION ALL
SELECT 'product.discontinued_date',
       COUNT(*) FILTER (WHERE discontinued_date IS NULL), COUNT(*),
       ROUND(100.0 * COUNT(*) FILTER (WHERE discontinued_date IS NULL) / COUNT(*), 1)
FROM   product
UNION ALL
SELECT 'purchase_order.promised_delivery_date',
       COUNT(*) FILTER (WHERE promised_delivery_date IS NULL), COUNT(*),
       ROUND(100.0 * COUNT(*) FILTER (WHERE promised_delivery_date IS NULL) / COUNT(*), 1)
FROM   purchase_order
UNION ALL
SELECT 'sales_order.despatch_date',
       COUNT(*) FILTER (WHERE despatch_date IS NULL), COUNT(*),
       ROUND(100.0 * COUNT(*) FILTER (WHERE despatch_date IS NULL) / COUNT(*), 1)
FROM   sales_order;


\echo '=== 4. Structural rules the data model assumes ==='

SELECT 'SKUs without exactly one primary source'  AS rule_checked,
       COUNT(*)                                   AS breaches
FROM  (SELECT sku
       FROM   product_supplier
       GROUP  BY sku
       HAVING COUNT(*) FILTER (WHERE is_primary_source) <> 1) AS breach
UNION ALL
SELECT 'Stocked pairs in policy with no snapshot row',
       COUNT(*)
FROM       replenishment_policy AS rp
LEFT JOIN  (SELECT DISTINCT sku, warehouse_code FROM inventory_snapshot) AS inv
       ON  inv.sku = rp.sku AND inv.warehouse_code = rp.warehouse_code
WHERE      inv.sku IS NULL
UNION ALL
SELECT 'Snapshot pairs with no replenishment policy',
       COUNT(*)
FROM      (SELECT DISTINCT sku, warehouse_code FROM inventory_snapshot) AS inv
LEFT JOIN  replenishment_policy AS rp
       ON  rp.sku = inv.sku AND rp.warehouse_code = inv.warehouse_code
WHERE      rp.sku IS NULL
UNION ALL
SELECT 'Ledger pairs with no snapshot coverage',
       COUNT(*)
FROM      (SELECT DISTINCT sku, warehouse_code FROM stock_movement) AS sm
LEFT JOIN  (SELECT DISTINCT sku, warehouse_code FROM inventory_snapshot) AS inv
       ON  inv.sku = sm.sku AND inv.warehouse_code = sm.warehouse_code
WHERE      inv.sku IS NULL
UNION ALL
SELECT 'Movements dated outside 2024-01-01 to 2025-12-31',
       COUNT(*)
FROM   stock_movement
WHERE  movement_date NOT BETWEEN DATE '2024-01-01' AND DATE '2025-12-31'
UNION ALL
SELECT 'Snapshot rows dated before the site opened',
       COUNT(*)
FROM       inventory_snapshot AS inv
INNER JOIN warehouse          AS w ON w.warehouse_code = inv.warehouse_code
WHERE      inv.week_ending_date < w.opened_date
ORDER  BY  1;


\echo '=== 5. Domain values present in the loaded data ==='

SELECT 'stock_movement.movement_type' AS column_name, movement_type AS value, COUNT(*) AS rows
FROM   stock_movement GROUP BY movement_type
UNION ALL
SELECT 'sales_order_line.line_status', line_status, COUNT(*)
FROM   sales_order_line GROUP BY line_status
UNION ALL
SELECT 'purchase_order_line.line_status', line_status, COUNT(*)
FROM   purchase_order_line GROUP BY line_status
UNION ALL
SELECT 'sales_order.order_status', order_status, COUNT(*)
FROM   sales_order GROUP BY order_status
UNION ALL
SELECT 'purchase_order.order_status', order_status, COUNT(*)
FROM   purchase_order GROUP BY order_status
UNION ALL
SELECT 'supplier.supplier_type', supplier_type, COUNT(*)
FROM   supplier GROUP BY supplier_type
-- Value added as a tiebreak: two domain values with the same row count
-- would otherwise swap places between runs.
ORDER  BY 1, 3 DESC, 2;
