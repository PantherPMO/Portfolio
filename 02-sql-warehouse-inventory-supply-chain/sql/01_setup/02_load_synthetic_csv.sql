/* ============================================================
   Project    : 02 — Warehouse Inventory & Supply Chain Performance
   File       : 01_setup/02_load_synthetic_csv.sql
   Question   : Does the dataset load cleanly with referential
                integrity enforced throughout?
   Output     : 147,589 rows across 15 tables
   Author     : Peters
   Created    : 2026-08-23
   ============================================================

   Run from the project root:
       psql -d calderfield -f sql/01_setup/02_load_synthetic_csv.sql

   Foreign keys stay enabled for the whole load. Tables are loaded
   parents first, so a wrong order fails rather than passing quietly.

   PostgreSQL's CSV reader treats an unquoted empty field as NULL, which
   is how pandas wrote the missing weights, dimensions, promised dates
   and despatch dates. No pre-processing is required.
   ============================================================ */

SET search_path TO supply;

\copy warehouse (warehouse_code, warehouse_name, region, postcode_district, site_type, opened_date, storage_capacity_pallets, warehouse_headcount) FROM 'data/synthetic/warehouse.csv' WITH (FORMAT csv, HEADER true)

\copy product_category (category_code, category_name, storage_class) FROM 'data/synthetic/product_category.csv' WITH (FORMAT csv, HEADER true)

\copy product (sku, product_name, category_code, brand, unit_of_measure, list_price_gbp, standard_cost_gbp, unit_weight_kg, unit_volume_m3, pallet_quantity, shelf_life_months, introduced_date, discontinued_date, hazardous_flag) FROM 'data/synthetic/product.csv' WITH (FORMAT csv, HEADER true)

\copy supplier (supplier_code, supplier_name, supplier_type, country, payment_terms_days, account_opened_date) FROM 'data/synthetic/supplier.csv' WITH (FORMAT csv, HEADER true)

\copy product_supplier (sku, supplier_code, is_primary_source, quoted_lead_time_days, minimum_order_quantity, order_multiple, agreed_unit_cost_gbp, price_agreed_date) FROM 'data/synthetic/product_supplier.csv' WITH (FORMAT csv, HEADER true)

\copy customer (customer_account, customer_name, customer_segment, region, postcode_district, primary_warehouse_code, account_opened_date, credit_limit_gbp, account_status) FROM 'data/synthetic/customer.csv' WITH (FORMAT csv, HEADER true)

\copy calendar_week (week_ending_date, week_starting_date, year, iso_week, month_number, month_name, quarter, working_days_in_week) FROM 'data/synthetic/calendar_week.csv' WITH (FORMAT csv, HEADER true)

\copy replenishment_policy (sku, warehouse_code, reorder_point_units, reorder_quantity_units, safety_stock_units, review_method, last_reviewed_date, set_by_buyer, stocked_since) FROM 'data/synthetic/replenishment_policy.csv' WITH (FORMAT csv, HEADER true)

\copy purchase_order (purchase_order_number, supplier_code, warehouse_code, order_date, promised_delivery_date, buyer_name, order_status) FROM 'data/synthetic/purchase_order.csv' WITH (FORMAT csv, HEADER true)

\copy purchase_order_line (purchase_order_number, line_number, sku, quantity_ordered, unit_cost_gbp, line_status) FROM 'data/synthetic/purchase_order_line.csv' WITH (FORMAT csv, HEADER true)

\copy goods_receipt_line (receipt_reference, line_number, purchase_order_number, purchase_order_line_number, warehouse_code, receipt_date, quantity_received, quantity_rejected) FROM 'data/synthetic/goods_receipt_line.csv' WITH (FORMAT csv, HEADER true)

\copy sales_order (sales_order_number, customer_account, warehouse_code, order_date, requested_delivery_date, despatch_date, order_channel, order_status) FROM 'data/synthetic/sales_order.csv' WITH (FORMAT csv, HEADER true)

\copy sales_order_line (sales_order_number, line_number, sku, quantity_ordered, quantity_despatched, unit_price_gbp, line_discount_pct, line_status) FROM 'data/synthetic/sales_order_line.csv' WITH (FORMAT csv, HEADER true)

\copy stock_movement (movement_id, sku, warehouse_code, movement_date, movement_type, quantity, unit_cost_gbp, source_document) FROM 'data/synthetic/stock_movement.csv' WITH (FORMAT csv, HEADER true)

\copy inventory_snapshot (week_ending_date, sku, warehouse_code, quantity_on_hand, quantity_allocated, quantity_on_order, days_at_zero_in_week, weighted_average_cost_gbp, stock_value_gbp) FROM 'data/synthetic/inventory_snapshot.csv' WITH (FORMAT csv, HEADER true)

ANALYZE;
