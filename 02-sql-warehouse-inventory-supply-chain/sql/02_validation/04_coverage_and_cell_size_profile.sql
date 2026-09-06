/* ============================================================
   Project    : 02 — Warehouse Inventory & Supply Chain Performance
   File       : 02_validation/04_coverage_and_cell_size_profile.sql
   Question   : Where is the data too thin to support a conclusion?
   Output     : analysis/query_results/validate_04_coverage_and_cell_sizes.txt
   Author     : Peters
   Created    : 2026-08-23
   ============================================================

   This runs before any analysis for one reason: it establishes which
   breakdowns the data can carry. A 38% on-time rate on eight deliveries
   is not a finding, and the only way to avoid writing one up is to know
   the cell sizes first.
   ============================================================ */

SET search_path TO supply;

\echo '=== 1. Snapshot coverage by site ==='

-- Bristol opened 2024-07-01 and therefore has 78 weekly snapshots against 104
-- elsewhere. Any per-site average that divides by 104 understates Bristol by a
-- quarter. Site comparison in the analysis runs on 2025 only.
SELECT
    inv.warehouse_code,
    w.opened_date,
    COUNT(DISTINCT inv.week_ending_date)             AS weeks_covered,
    COUNT(DISTINCT inv.sku)                          AS skus_stocked,
    MIN(inv.week_ending_date)                        AS first_week,
    MAX(inv.week_ending_date)                        AS last_week,
    COUNT(*)                                         AS snapshot_rows,
    COUNT(DISTINCT inv.week_ending_date)
        * COUNT(DISTINCT inv.sku)                    AS expected_rows
FROM       inventory_snapshot AS inv
INNER JOIN warehouse          AS w ON w.warehouse_code = inv.warehouse_code
GROUP  BY  inv.warehouse_code, w.opened_date
ORDER  BY  inv.warehouse_code;


\echo '=== 2. Range overlap between sites ==='

-- Daventry stocks the full range; the regional sites stock a subset. The SKUs
-- held nowhere else are the national slow-moving tail, and they are why raw
-- site turnover ranks Daventry unfairly. Quantified properly in 04_analysis/10.
WITH sku_site_count AS (
    SELECT
        sku,
        COUNT(DISTINCT warehouse_code)               AS sites_stocking
    FROM   inventory_snapshot
    GROUP  BY sku
)

SELECT
    sites_stocking,
    COUNT(*)                                         AS sku_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS share_of_range_pct
FROM   sku_site_count
GROUP  BY sites_stocking
ORDER  BY sites_stocking;


\echo '=== 3. Purchase and receipt volume per supplier ==='

WITH supplier_volume AS (
    SELECT
        s.supplier_code,
        s.supplier_name,
        s.supplier_type,
        COUNT(DISTINCT pol.purchase_order_number)    AS purchase_orders,
        COUNT(*)                                     AS purchase_lines
    FROM       supplier            AS s
    LEFT JOIN  purchase_order      AS po  ON po.supplier_code = s.supplier_code
    LEFT JOIN  purchase_order_line AS pol ON pol.purchase_order_number = po.purchase_order_number
    GROUP  BY  s.supplier_code, s.supplier_name, s.supplier_type
)

SELECT
    supplier_code,
    supplier_name,
    supplier_type,
    purchase_orders,
    purchase_lines
FROM   supplier_volume
ORDER  BY purchase_lines DESC;


\echo '=== 4. Supplier cell sizes by quarter and by half-year ==='

-- The reason supplier trend analysis is planned at half-year granularity.
WITH receipt_period AS (
    SELECT
        po.supplier_code,
        TO_CHAR(po.order_date, 'YYYY"Q"Q')           AS order_quarter,
        CONCAT(EXTRACT(YEAR FROM po.order_date)::int,
               CASE WHEN EXTRACT(MONTH FROM po.order_date) <= 6
                    THEN 'H1' ELSE 'H2' END)         AS order_half
    FROM       goods_receipt_line  AS grl
    INNER JOIN purchase_order      AS po ON po.purchase_order_number = grl.purchase_order_number
),

quarter_cells AS (
    SELECT supplier_code, order_quarter, COUNT(*) AS receipts
    FROM   receipt_period GROUP BY supplier_code, order_quarter
),

half_cells AS (
    SELECT supplier_code, order_half, COUNT(*) AS receipts
    FROM   receipt_period GROUP BY supplier_code, order_half
)

SELECT
    'supplier x quarter'                                                 AS grouping_level,
    COUNT(*)                                                             AS cells,
    COUNT(*) FILTER (WHERE receipts < 10)                                AS cells_under_10,
    ROUND(100.0 * COUNT(*) FILTER (WHERE receipts < 10) / COUNT(*), 1)   AS share_under_10_pct,
    MIN(receipts)                                                        AS smallest_cell,
    ROUND(AVG(receipts), 1)                                              AS mean_cell
FROM   quarter_cells
UNION ALL
SELECT
    'supplier x half-year',
    COUNT(*),
    COUNT(*) FILTER (WHERE receipts < 10),
    ROUND(100.0 * COUNT(*) FILTER (WHERE receipts < 10) / COUNT(*), 1),
    MIN(receipts),
    ROUND(AVG(receipts), 1)
FROM   half_cells;


\echo '=== 5. End-of-period truncation in delivery performance ==='

-- Importer lead times run near 78 days, so orders placed late in 2025 had not
-- arrived by 31 December. Their measured on-time rate is computed only on the
-- ones that came back early, which flatters. D-04 sets the primary window at
-- 2025-09-30 and reports the excluded quarter separately.
WITH order_outcome AS (
    SELECT
        po.purchase_order_number,
        po.order_date,
        s.supplier_type,
        COUNT(grl.receipt_reference)                 AS receipts_recorded
    FROM       purchase_order      AS po
    INNER JOIN supplier            AS s   ON s.supplier_code = po.supplier_code
    INNER JOIN purchase_order_line AS pol ON pol.purchase_order_number = po.purchase_order_number
    LEFT JOIN  goods_receipt_line  AS grl
           ON  grl.purchase_order_number      = pol.purchase_order_number
          AND  grl.purchase_order_line_number = pol.line_number
    GROUP  BY  po.purchase_order_number, po.order_date, s.supplier_type
)

SELECT
    supplier_type,
    COUNT(*) FILTER (WHERE order_date <= DATE '2025-09-30')               AS orders_in_window,
    COUNT(*) FILTER (WHERE order_date >  DATE '2025-09-30')               AS orders_excluded_q4,
    COUNT(*) FILTER (WHERE order_date > DATE '2025-09-30'
                       AND receipts_recorded = 0)                         AS excluded_q4_unreceived,
    ROUND(100.0 * COUNT(*) FILTER (WHERE order_date > DATE '2025-09-30'
                                     AND receipts_recorded = 0)
          / NULLIF(COUNT(*) FILTER (WHERE order_date > DATE '2025-09-30'), 0), 1)
                                                                          AS q4_unreceived_pct
FROM   order_outcome
GROUP  BY supplier_type
ORDER  BY supplier_type;


\echo '=== 6. Demand cell sizes across the dimensions the analysis uses ==='

WITH demand_line AS (
    SELECT
        so.warehouse_code,
        p.category_code,
        c.customer_segment,
        TO_CHAR(so.order_date, 'YYYY"Q"Q')           AS order_quarter
    FROM       sales_order_line AS sol
    INNER JOIN sales_order      AS so ON so.sales_order_number = sol.sales_order_number
    INNER JOIN product          AS p  ON p.sku = sol.sku
    INNER JOIN customer         AS c  ON c.customer_account = so.customer_account
    WHERE      sol.line_status <> 'Cancelled'
)

SELECT
    COALESCE(warehouse_code, 'ALL SITES')            AS warehouse_code,
    COALESCE(category_code, 'ALL CATEGORIES')        AS category_code,
    COALESCE(customer_segment, 'ALL SEGMENTS')       AS customer_segment,
    COUNT(*)                                         AS order_lines
FROM   demand_line
GROUP  BY GROUPING SETS (
             (warehouse_code),
             (category_code),
             (customer_segment),
             (warehouse_code, category_code)
         )
ORDER  BY 1, 2, 3;


\echo '=== 7. Renewables and discontinued lines — the small populations ==='

SELECT
    'Renewables SKUs'                                AS population,
    COUNT(*)                                         AS item_count
FROM   product WHERE category_code = 'RENW'
UNION ALL
SELECT 'Renewables stocked pairs', COUNT(*)
FROM       replenishment_policy AS rp
INNER JOIN product              AS p ON p.sku = rp.sku
WHERE      p.category_code = 'RENW'
UNION ALL
SELECT 'Discontinued SKUs', COUNT(*)
FROM   product WHERE discontinued_date IS NOT NULL
UNION ALL
SELECT 'SKUs with more than one approved source', COUNT(*)
FROM  (SELECT sku FROM product_supplier GROUP BY sku HAVING COUNT(*) > 1) AS multi
UNION ALL
SELECT 'SKUs actually purchased from more than one supplier', COUNT(*)
FROM  (SELECT pol.sku
       FROM       purchase_order_line AS pol
       INNER JOIN purchase_order      AS po ON po.purchase_order_number = pol.purchase_order_number
       GROUP  BY  pol.sku
       HAVING COUNT(DISTINCT po.supplier_code) > 1) AS multi_bought
UNION ALL
SELECT 'Replenishment policies not reviewed since 2024-09-30', COUNT(*)
FROM   replenishment_policy WHERE last_reviewed_date < DATE '2024-09-30';
