/* ============================================================
   Project    : 02 — Warehouse Inventory & Supply Chain Performance
   File       : 01_setup/03_create_analysis_indexes.sql
   Question   : Which access paths does the analysis actually use?
   Output     : 11 indexes on supply
   Author     : Peters
   Created    : 2026-08-23
   ============================================================

   Chosen from the joins and filters the planned analysis performs, not
   added speculatively. Primary keys already cover single-table lookups
   on sku, warehouse_code and the document numbers.
   ============================================================ */

SET search_path TO supply;

-- The ledger rebuild partitions by (sku, warehouse_code) and orders by date.
-- This is the single most expensive access path in the project.
CREATE INDEX idx_stock_movement_sku_site_date
    ON stock_movement (sku, warehouse_code, movement_date);

CREATE INDEX idx_stock_movement_type_date
    ON stock_movement (movement_type, movement_date);

-- Snapshot scans are almost always bounded by week, then grouped by site.
CREATE INDEX idx_inventory_snapshot_week_site
    ON inventory_snapshot (week_ending_date, warehouse_code);

CREATE INDEX idx_inventory_snapshot_sku_site
    ON inventory_snapshot (sku, warehouse_code);

CREATE INDEX idx_sales_order_date_site
    ON sales_order (order_date, warehouse_code);

CREATE INDEX idx_sales_order_customer
    ON sales_order (customer_account);

CREATE INDEX idx_sales_order_line_sku
    ON sales_order_line (sku);

CREATE INDEX idx_purchase_order_supplier_date
    ON purchase_order (supplier_code, order_date);

CREATE INDEX idx_purchase_order_site_date
    ON purchase_order (warehouse_code, order_date);

CREATE INDEX idx_purchase_order_line_sku
    ON purchase_order_line (sku);

-- Receipts are read both by parent line (reconciliation) and by date
-- (delivery performance and the weekday booking pattern).
CREATE INDEX idx_goods_receipt_line_parent
    ON goods_receipt_line (purchase_order_number, purchase_order_line_number);

CREATE INDEX idx_goods_receipt_line_date_site
    ON goods_receipt_line (receipt_date, warehouse_code);

ANALYZE;
