/* ============================================================
   Project    : 02 — Warehouse Inventory & Supply Chain Performance
   File       : 01_setup/01_create_supply_schema.sql
   Question   : Does the data model hold together under enforced
                primary keys, foreign keys and business constraints?
   Output     : schema supply, 15 tables
   Author     : Peters
   Created    : 2026-08-23
   ============================================================

   Calderfield Trade Supplies Ltd is a fictional company and this
   dataset is entirely synthetic. See docs/DECISIONS.md D-06.

   Table names are singular, matching the approved data model and the
   CSV file names, rather than the plural convention in SQL_STANDARDS.md.
   See docs/DECISIONS.md D-02.
   ============================================================ */

DROP SCHEMA IF EXISTS supply CASCADE;
CREATE SCHEMA supply;

SET search_path TO supply;


CREATE TABLE warehouse (
    warehouse_code            TEXT        PRIMARY KEY,
    warehouse_name            TEXT        NOT NULL,
    region                    TEXT        NOT NULL,
    postcode_district         TEXT        NOT NULL,
    site_type                 TEXT        NOT NULL,
    opened_date               DATE        NOT NULL,
    storage_capacity_pallets  INTEGER     NOT NULL CHECK (storage_capacity_pallets > 0),
    warehouse_headcount       INTEGER     NOT NULL CHECK (warehouse_headcount > 0)
);


CREATE TABLE product_category (
    category_code             TEXT        PRIMARY KEY,
    category_name             TEXT        NOT NULL,
    storage_class             TEXT        NOT NULL
);


CREATE TABLE product (
    sku                       TEXT        PRIMARY KEY,
    product_name              TEXT        NOT NULL,
    category_code             TEXT        NOT NULL REFERENCES product_category (category_code),
    brand                     TEXT        NOT NULL,
    unit_of_measure           TEXT        NOT NULL,
    list_price_gbp            NUMERIC(10,2) NOT NULL CHECK (list_price_gbp > 0),
    standard_cost_gbp         NUMERIC(10,2) NOT NULL CHECK (standard_cost_gbp > 0),
    -- Nullable by design: dimension data was never backfilled for part of the
    -- older range. 10 of 250 products. A data quality finding, not a load error.
    unit_weight_kg            NUMERIC(8,3),
    unit_volume_m3            NUMERIC(8,4),
    pallet_quantity           INTEGER     NOT NULL CHECK (pallet_quantity > 0),
    -- NUMERIC rather than SMALLINT: 229 of 250 products have no shelf life, so
    -- the source CSV writes the remaining values as "24.0". Widening the type
    -- accepts the file as it stands rather than altering frozen source data.
    -- See docs/DECISIONS.md D-04.
    shelf_life_months         NUMERIC(4,0) CHECK (shelf_life_months > 0),
    introduced_date           DATE        NOT NULL,
    discontinued_date         DATE,
    hazardous_flag            BOOLEAN     NOT NULL
);


CREATE TABLE supplier (
    supplier_code             TEXT        PRIMARY KEY,
    supplier_name             TEXT        NOT NULL,
    supplier_type             TEXT        NOT NULL,
    country                   TEXT        NOT NULL,
    payment_terms_days        SMALLINT    NOT NULL CHECK (payment_terms_days > 0),
    account_opened_date       DATE        NOT NULL
);


CREATE TABLE product_supplier (
    sku                       TEXT        NOT NULL REFERENCES product (sku),
    supplier_code             TEXT        NOT NULL REFERENCES supplier (supplier_code),
    is_primary_source         BOOLEAN     NOT NULL,
    quoted_lead_time_days     SMALLINT    NOT NULL CHECK (quoted_lead_time_days > 0),
    minimum_order_quantity    INTEGER     NOT NULL CHECK (minimum_order_quantity > 0),
    order_multiple            INTEGER     NOT NULL CHECK (order_multiple > 0),
    agreed_unit_cost_gbp      NUMERIC(10,2) NOT NULL CHECK (agreed_unit_cost_gbp > 0),
    price_agreed_date         DATE        NOT NULL,
    PRIMARY KEY (sku, supplier_code)
);


CREATE TABLE customer (
    customer_account          TEXT        PRIMARY KEY,
    customer_name             TEXT        NOT NULL,
    customer_segment          TEXT        NOT NULL,
    region                    TEXT        NOT NULL,
    postcode_district         TEXT        NOT NULL,
    primary_warehouse_code    TEXT        NOT NULL REFERENCES warehouse (warehouse_code),
    account_opened_date       DATE        NOT NULL,
    credit_limit_gbp          NUMERIC(12,2) NOT NULL CHECK (credit_limit_gbp > 0),
    account_status            TEXT        NOT NULL
);


CREATE TABLE calendar_week (
    week_ending_date          DATE        PRIMARY KEY,
    week_starting_date        DATE        NOT NULL,
    year                      SMALLINT    NOT NULL,
    iso_week                  SMALLINT    NOT NULL CHECK (iso_week BETWEEN 1 AND 53),
    month_number              SMALLINT    NOT NULL CHECK (month_number BETWEEN 1 AND 12),
    month_name                TEXT        NOT NULL,
    quarter                   TEXT        NOT NULL,
    working_days_in_week      SMALLINT    NOT NULL CHECK (working_days_in_week BETWEEN 0 AND 5),
    CHECK (week_ending_date = week_starting_date + 6)
);


CREATE TABLE replenishment_policy (
    sku                       TEXT        NOT NULL REFERENCES product (sku),
    warehouse_code            TEXT        NOT NULL REFERENCES warehouse (warehouse_code),
    reorder_point_units       INTEGER     NOT NULL CHECK (reorder_point_units > 0),
    reorder_quantity_units    INTEGER     NOT NULL CHECK (reorder_quantity_units > 0),
    safety_stock_units        INTEGER     NOT NULL CHECK (safety_stock_units > 0),
    review_method             TEXT        NOT NULL,
    last_reviewed_date        DATE        NOT NULL,
    set_by_buyer              TEXT        NOT NULL,
    stocked_since             DATE        NOT NULL,
    PRIMARY KEY (sku, warehouse_code)
);


CREATE TABLE purchase_order (
    purchase_order_number     TEXT        PRIMARY KEY,
    supplier_code             TEXT        NOT NULL REFERENCES supplier (supplier_code),
    warehouse_code            TEXT        NOT NULL REFERENCES warehouse (warehouse_code),
    order_date                DATE        NOT NULL,
    -- Nullable, and deliberately NOT constrained to be on or after order_date.
    -- 22 orders carry no promised date (placed by telephone) and 24 carry a
    -- promised date before the order date (buyer keying errors). Both are
    -- findings for the delivery-performance analysis, not load failures.
    promised_delivery_date    DATE,
    buyer_name                TEXT        NOT NULL,
    order_status              TEXT        NOT NULL
);


CREATE TABLE purchase_order_line (
    purchase_order_number     TEXT        NOT NULL REFERENCES purchase_order (purchase_order_number),
    line_number               SMALLINT    NOT NULL,
    sku                       TEXT        NOT NULL REFERENCES product (sku),
    quantity_ordered          INTEGER     NOT NULL CHECK (quantity_ordered > 0),
    unit_cost_gbp             NUMERIC(10,2) NOT NULL CHECK (unit_cost_gbp > 0),
    line_status               TEXT        NOT NULL,
    PRIMARY KEY (purchase_order_number, line_number)
);


CREATE TABLE goods_receipt_line (
    receipt_reference         TEXT        NOT NULL,
    line_number               SMALLINT    NOT NULL,
    purchase_order_number     TEXT        NOT NULL,
    purchase_order_line_number SMALLINT   NOT NULL,
    warehouse_code            TEXT        NOT NULL REFERENCES warehouse (warehouse_code),
    receipt_date              DATE        NOT NULL,
    quantity_received         INTEGER     NOT NULL CHECK (quantity_received >= 0),
    quantity_rejected         INTEGER     NOT NULL CHECK (quantity_rejected >= 0),
    PRIMARY KEY (receipt_reference, line_number),
    FOREIGN KEY (purchase_order_number, purchase_order_line_number)
        REFERENCES purchase_order_line (purchase_order_number, line_number)
);


CREATE TABLE sales_order (
    sales_order_number        TEXT        PRIMARY KEY,
    customer_account          TEXT        NOT NULL REFERENCES customer (customer_account),
    warehouse_code            TEXT        NOT NULL REFERENCES warehouse (warehouse_code),
    order_date                DATE        NOT NULL,
    requested_delivery_date   DATE        NOT NULL,
    -- Null where the order was cancelled before despatch. 42 orders.
    despatch_date             DATE,
    order_channel             TEXT        NOT NULL,
    order_status              TEXT        NOT NULL
);


CREATE TABLE sales_order_line (
    sales_order_number        TEXT        NOT NULL REFERENCES sales_order (sales_order_number),
    line_number               SMALLINT    NOT NULL,
    sku                       TEXT        NOT NULL REFERENCES product (sku),
    quantity_ordered          INTEGER     NOT NULL CHECK (quantity_ordered > 0),
    quantity_despatched       INTEGER     NOT NULL CHECK (quantity_despatched >= 0),
    unit_price_gbp            NUMERIC(10,2) NOT NULL CHECK (unit_price_gbp > 0),
    line_discount_pct         NUMERIC(5,2) NOT NULL CHECK (line_discount_pct BETWEEN 0 AND 100),
    line_status               TEXT        NOT NULL,
    PRIMARY KEY (sales_order_number, line_number),
    -- The shortfall between these two columns is the only reliable record of
    -- unmet demand. line_status cannot be used for fulfilment: a later return
    -- overwrites it. See docs/DECISIONS.md D-03.
    CHECK (quantity_despatched <= quantity_ordered)
);


CREATE TABLE stock_movement (
    movement_id               INTEGER     PRIMARY KEY,
    sku                       TEXT        NOT NULL REFERENCES product (sku),
    warehouse_code            TEXT        NOT NULL REFERENCES warehouse (warehouse_code),
    movement_date             DATE        NOT NULL,
    movement_type             TEXT        NOT NULL CHECK (movement_type IN (
                                  'Opening balance', 'Goods receipt', 'Sales issue',
                                  'Customer return', 'Stock adjustment', 'Write-off',
                                  'Transfer out', 'Transfer in')),
    quantity                  INTEGER     NOT NULL CHECK (quantity <> 0),
    unit_cost_gbp             NUMERIC(10,2) NOT NULL CHECK (unit_cost_gbp > 0),
    source_document           TEXT        NOT NULL
);


CREATE TABLE inventory_snapshot (
    week_ending_date          DATE        NOT NULL REFERENCES calendar_week (week_ending_date),
    sku                       TEXT        NOT NULL REFERENCES product (sku),
    warehouse_code            TEXT        NOT NULL REFERENCES warehouse (warehouse_code),
    quantity_on_hand          INTEGER     NOT NULL CHECK (quantity_on_hand >= 0),
    -- A claim against stock already counted in quantity_on_hand, not stock in
    -- addition to it. Never add the two together.
    quantity_allocated        INTEGER     NOT NULL CHECK (quantity_allocated >= 0),
    quantity_on_order         INTEGER     NOT NULL CHECK (quantity_on_order >= 0),
    -- Counts days the site closed with no stock. Recovers intra-week stockouts
    -- that a Sunday-night snapshot cannot see.
    days_at_zero_in_week      SMALLINT    NOT NULL CHECK (days_at_zero_in_week BETWEEN 0 AND 7),
    weighted_average_cost_gbp NUMERIC(10,2) NOT NULL CHECK (weighted_average_cost_gbp >= 0),
    stock_value_gbp           NUMERIC(12,2) NOT NULL CHECK (stock_value_gbp >= 0),
    PRIMARY KEY (week_ending_date, sku, warehouse_code)
);
