/* ============================================================
   Project    : 02 — Warehouse Inventory & Supply Chain Performance
   File       : 04_analysis/15_february_2025_buy_ahead_and_residual_stock.sql
   Question   : BQ-07 / AQ-15 — Did buying ahead of the Arden price rise
                save more than it tied up?
   Finding ID : F-15
   Output     : analysis/query_results/analyse_15_buy_ahead_trade.txt
   Author     : Peters
   Created    : 2026-08-23
   ============================================================

   Calderfield Trade Supplies Ltd is fictional and this data is synthetic.

   Arden raised prices from 1 March 2025. File 14 measured the rise
   like-for-like at a median +18.2% across the 57 SKUs bought on both
   sides, with a tight spread (p10 17.0%, p90 18.9%) and no other
   supplier moving more than 0.7% over the same dates.

   THIS FILE IS A TRADE, NOT A VERDICT. Buying ahead of a price rise is
   neither right nor wrong in itself. It is right if the price saved
   exceeds the cost of carrying the stock, and wrong if it does not.
   Both sides are computed and netted, and the answer is whatever the
   arithmetic gives.

   HOW "EXCESS" IS DEFINED. Each purchase is compared against that
   SKU's own normal order size from Arden — the median line quantity
   outside the buy-ahead window — rather than against a flat monthly
   average. A SKU that always orders 500 units has not bought ahead by
   ordering 500 in February.

   WHAT CANNOT BE PROVEN, AND IS NOT CLAIMED. Stock is valued at
   weighted average cost and the ledger carries no batch identity, so no
   unit on the shelf at 2025-12-28 can be traced to a specific February
   receipt. Section 5 therefore reports a BOUND, not an attribution:
   excess units bought, less everything issued since, floored at zero.
   That is the most that could still be attributable. The true figure is
   at or below it, and section 6 states what the bound rests on.
   ============================================================ */

SET search_path TO supply;

\set buy_ahead_start '2025-02-03'
\set buy_ahead_end   '2025-02-28'
\set price_change_date '2025-03-01'
\set snapshot_date '2025-12-28'
\set holding_rate 0.22
\set holding_rate_low 0.20
\set holding_rate_high 0.25


\echo '=== 1. Arden purchasing month by month, 2025 ==='

-- Where the cluster is, before anything is asserted about it.
SELECT
    TO_CHAR(po.order_date, 'YYYY-MM')                                    AS order_month,
    COUNT(DISTINCT po.purchase_order_number)                             AS purchase_orders,
    COUNT(*)                                                             AS purchase_lines,
    COUNT(DISTINCT pol.sku)                                              AS distinct_skus,
    SUM(pol.quantity_ordered)                                            AS units_ordered,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY pol.quantity_ordered)::numeric, 0)
                                                                         AS median_line_quantity,
    ROUND(SUM(pol.quantity_ordered * pol.unit_cost_gbp), 0)              AS spend_gbp,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY pol.unit_cost_gbp)::numeric, 2)
                                                                         AS median_unit_cost
FROM       purchase_order_line AS pol
INNER JOIN purchase_order      AS po ON po.purchase_order_number = pol.purchase_order_number
WHERE      po.supplier_code = 'ARDEN'
  AND      po.order_date BETWEEN DATE '2025-01-01' AND DATE '2025-12-31'
GROUP  BY  order_month
ORDER  BY  order_month;


\echo '=== 2. Each buy-ahead line against that SKU''s own normal order size ==='

DROP VIEW IF EXISTS vw_buy_ahead_lines CASCADE;

CREATE VIEW vw_buy_ahead_lines AS

WITH arden_lines AS (
    SELECT
        pol.purchase_order_number,
        pol.line_number,
        pol.sku,
        p.category_code,
        po.warehouse_code,
        po.order_date,
        pol.quantity_ordered,
        pol.unit_cost_gbp,
        po.order_date BETWEEN DATE :'buy_ahead_start' AND DATE :'buy_ahead_end'
                                                                         AS in_buy_ahead_window
    FROM       purchase_order_line AS pol
    INNER JOIN purchase_order      AS po ON po.purchase_order_number = pol.purchase_order_number
    INNER JOIN product             AS p  ON p.sku = pol.sku
    WHERE      po.supplier_code = 'ARDEN'
),

normal_pattern AS (
    -- The SKU-and-site baseline: how big an Arden order normally is, measured
    -- outside the window so the window cannot inflate its own benchmark.
    SELECT
        sku,
        warehouse_code,
        COUNT(*)                                                         AS baseline_lines,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY quantity_ordered)::numeric
                                                                         AS normal_line_quantity,
        PERCENTILE_CONT(0.9) WITHIN GROUP (ORDER BY quantity_ordered)::numeric
                                                                         AS p90_line_quantity
    FROM   arden_lines
    WHERE  NOT in_buy_ahead_window
    GROUP  BY sku, warehouse_code
),

price_sides AS (
    -- Like-for-like price on each side of the change, per SKU (D from file 14).
    SELECT
        sku,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY unit_cost_gbp)
            FILTER (WHERE order_date <  DATE :'price_change_date')::numeric AS price_before,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY unit_cost_gbp)
            FILTER (WHERE order_date >= DATE :'price_change_date')::numeric AS price_after,
        COUNT(*) FILTER (WHERE order_date <  DATE :'price_change_date')  AS lines_before,
        COUNT(*) FILTER (WHERE order_date >= DATE :'price_change_date')  AS lines_after
    FROM   arden_lines
    GROUP  BY sku
)

SELECT
    a.purchase_order_number,
    a.line_number,
    a.sku,
    a.category_code,
    a.warehouse_code,
    a.order_date,
    a.quantity_ordered,
    a.unit_cost_gbp,
    n.baseline_lines,
    ROUND(n.normal_line_quantity, 0)                                     AS normal_line_quantity,
    ROUND(a.quantity_ordered / NULLIF(n.normal_line_quantity, 0), 2)     AS quantity_versus_normal,
    -- Units above the SKU's own normal order size. Floored at zero: a
    -- below-normal order in the window is not negative buying-ahead.
    GREATEST(a.quantity_ordered - n.normal_line_quantity, 0)             AS excess_units,
    ps.price_before,
    ps.price_after,
    ps.lines_before,
    ps.lines_after,
    ROUND(ps.price_after - ps.price_before, 2)                           AS price_rise_per_unit,
    -- Saving only counts where the SKU has a measurable price on both sides.
    CASE WHEN ps.lines_before > 0 AND ps.lines_after > 0
         THEN GREATEST(a.quantity_ordered - n.normal_line_quantity, 0)
              * (ps.price_after - ps.price_before)
    END                                                                  AS price_saving_gbp
FROM       arden_lines    AS a
INNER JOIN normal_pattern AS n ON n.sku = a.sku AND n.warehouse_code = a.warehouse_code
LEFT JOIN  price_sides    AS ps ON ps.sku = a.sku
WHERE      a.in_buy_ahead_window;


SELECT
    'Arden purchase lines in the window (3-28 Feb 2025)'                 AS measure,
    COUNT(*)                                                             AS n,
    NULL::numeric                                                        AS value
FROM   vw_buy_ahead_lines
UNION ALL
SELECT 'Of which above the SKU''s own normal order size',
       COUNT(*) FILTER (WHERE excess_units > 0), NULL
FROM   vw_buy_ahead_lines
UNION ALL
SELECT 'Median quantity versus that SKU''s normal', COUNT(*),
       ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY quantity_versus_normal)::numeric, 2)
FROM   vw_buy_ahead_lines
UNION ALL
SELECT 'Units ordered in the window', COUNT(*), SUM(quantity_ordered)
FROM   vw_buy_ahead_lines
UNION ALL
SELECT 'Of which above normal (excess units)', COUNT(*), ROUND(SUM(excess_units), 0)
FROM   vw_buy_ahead_lines
UNION ALL
SELECT 'SKUs with a measurable price on both sides of the rise',
       COUNT(DISTINCT sku) FILTER (WHERE price_saving_gbp IS NOT NULL), NULL
FROM   vw_buy_ahead_lines;


\echo '=== 3. The lines themselves ==='

SELECT
    purchase_order_number,
    sku,
    category_code,
    warehouse_code,
    order_date,
    quantity_ordered,
    normal_line_quantity,
    quantity_versus_normal,
    ROUND(excess_units, 0)                                               AS excess_units,
    unit_cost_gbp,
    price_after,
    price_rise_per_unit,
    ROUND(price_saving_gbp, 0)                                           AS price_saving_gbp
FROM   vw_buy_ahead_lines
ORDER  BY price_saving_gbp DESC NULLS LAST;


\echo '=== 4. The price saving captured ==='

SELECT
    COUNT(*)                                                             AS lines,
    COUNT(*) FILTER (WHERE price_saving_gbp IS NOT NULL)                 AS lines_with_measurable_saving,
    ROUND(SUM(excess_units), 0)                                          AS excess_units,
    ROUND(SUM(excess_units) FILTER (WHERE price_saving_gbp IS NOT NULL), 0)
                                                                         AS excess_units_measurable,
    ROUND(SUM(price_saving_gbp), 0)                                      AS price_saving_gbp,
    ROUND(SUM(excess_units * unit_cost_gbp), 0)                          AS excess_purchase_value_gbp,
    ROUND(100.0 * SUM(price_saving_gbp)
          / NULLIF(SUM(excess_units * unit_cost_gbp), 0), 1)             AS saving_as_pct_of_purchase
FROM   vw_buy_ahead_lines;


\echo '=== 5. What became of the stock — a bound, not an attribution ==='

DROP VIEW IF EXISTS vw_buy_ahead_stock CASCADE;

CREATE VIEW vw_buy_ahead_stock AS

WITH excess_by_position AS (
    SELECT
        sku,
        warehouse_code,
        SUM(excess_units)                                                AS excess_units,
        SUM(quantity_ordered)                                            AS window_units_ordered,
        SUM(price_saving_gbp)                                            AS price_saving_gbp,
        AVG(unit_cost_gbp)                                               AS mean_window_unit_cost
    FROM   vw_buy_ahead_lines
    GROUP  BY sku, warehouse_code
),

receipts_from_window AS (
    -- What actually arrived from those orders, and when.
    SELECT
        pol.sku,
        po.warehouse_code,
        SUM(grl.quantity_received)                                       AS units_received,
        MIN(grl.receipt_date)                                            AS first_receipt,
        MAX(grl.receipt_date)                                            AS last_receipt
    FROM       goods_receipt_line  AS grl
    INNER JOIN purchase_order_line AS pol
           ON  pol.purchase_order_number = grl.purchase_order_number
          AND  pol.line_number           = grl.purchase_order_line_number
    INNER JOIN purchase_order      AS po ON po.purchase_order_number = pol.purchase_order_number
    WHERE      po.supplier_code = 'ARDEN'
      AND      po.order_date BETWEEN DATE :'buy_ahead_start' AND DATE :'buy_ahead_end'
    GROUP  BY  pol.sku, po.warehouse_code
),

issued_since AS (
    -- Everything sold from that position after the first buy-ahead receipt.
    -- If this exceeds the excess, the excess has demonstrably been consumed.
    SELECT
        sm.sku,
        sm.warehouse_code,
        -SUM(sm.quantity)                                                AS units_issued_since
    FROM       stock_movement AS sm
    INNER JOIN receipts_from_window AS r
           ON  r.sku = sm.sku AND r.warehouse_code = sm.warehouse_code
    WHERE      sm.movement_type = 'Sales issue'
      AND      sm.movement_date >= r.first_receipt
      AND      sm.movement_date <= DATE :'snapshot_date'
    GROUP  BY  sm.sku, sm.warehouse_code
),

closing AS (
    SELECT
        sku,
        warehouse_code,
        quantity_on_hand,
        weighted_average_cost_gbp,
        stock_value_gbp,
        cover_weeks
    FROM   mv_inventory_week
    WHERE  week_ending_date = DATE :'snapshot_date'
)

SELECT
    e.sku,
    e.warehouse_code,
    ROUND(e.excess_units, 0)                                             AS excess_units_ordered,
    r.units_received                                                     AS window_units_received,
    r.first_receipt,
    r.last_receipt,
    COALESCE(i.units_issued_since, 0)                                    AS units_issued_since_receipt,
    c.quantity_on_hand                                                   AS closing_units_on_hand,
    ROUND(c.stock_value_gbp, 0)                                          AS closing_stock_value_gbp,
    c.cover_weeks                                                        AS closing_cover_weeks,
    -- The bound. Whatever the excess was, everything issued since has been
    -- consumed from somewhere; and nothing more than what is on the shelf can
    -- still be there. The residual attributable to the buy-ahead is at most the
    -- smaller of those two limits.
    LEAST(
        GREATEST(e.excess_units - COALESCE(i.units_issued_since, 0), 0),
        c.quantity_on_hand
    )                                                                    AS residual_units_upper_bound,
    ROUND(LEAST(
        GREATEST(e.excess_units - COALESCE(i.units_issued_since, 0), 0),
        c.quantity_on_hand
    ) * c.weighted_average_cost_gbp, 2)                                  AS residual_value_upper_bound_gbp,
    ROUND(e.price_saving_gbp, 2)                                         AS price_saving_gbp
FROM       excess_by_position   AS e
LEFT JOIN  receipts_from_window AS r ON r.sku = e.sku AND r.warehouse_code = e.warehouse_code
LEFT JOIN  issued_since         AS i ON i.sku = e.sku AND i.warehouse_code = e.warehouse_code
LEFT JOIN  closing              AS c ON c.sku = e.sku AND c.warehouse_code = e.warehouse_code;


SELECT
    sku,
    warehouse_code,
    excess_units_ordered,
    window_units_received,
    first_receipt,
    units_issued_since_receipt,
    closing_units_on_hand,
    residual_units_upper_bound,
    residual_value_upper_bound_gbp,
    closing_cover_weeks,
    price_saving_gbp
FROM   vw_buy_ahead_stock
ORDER  BY residual_value_upper_bound_gbp DESC NULLS LAST;


\echo '=== 6. The trade, netted, with the sensitivity band ==='

-- Working capital is charged for the period the stock has actually been held:
-- first receipt to 2025-12-28, not a full year. Charging a full year on stock
-- received in April would overstate the cost of the decision.
WITH held AS (
    SELECT
        sku,
        warehouse_code,
        price_saving_gbp,
        residual_units_upper_bound,
        residual_value_upper_bound_gbp,
        (DATE :'snapshot_date' - first_receipt)                          AS days_held,
        residual_value_upper_bound_gbp * (DATE :'snapshot_date' - first_receipt) / 365.0
                                                                         AS value_days_gbp
    FROM   vw_buy_ahead_stock
    WHERE  first_receipt IS NOT NULL
)

SELECT
    COUNT(*)                                                             AS positions,
    ROUND(SUM(price_saving_gbp), 0)                                      AS price_saving_captured_gbp,
    SUM(residual_units_upper_bound)                                      AS residual_units_upper_bound,
    ROUND(SUM(residual_value_upper_bound_gbp), 0)                        AS residual_value_upper_bound_gbp,
    ROUND(AVG(days_held), 0)                                             AS mean_days_held,
    ROUND(SUM(value_days_gbp) * :holding_rate_low, 0)                    AS holding_cost_at_20pct_gbp,
    ROUND(SUM(value_days_gbp) * :holding_rate, 0)                        AS holding_cost_at_22pct_gbp,
    ROUND(SUM(value_days_gbp) * :holding_rate_high, 0)                   AS holding_cost_at_25pct_gbp,
    ROUND(SUM(price_saving_gbp) - SUM(value_days_gbp) * :holding_rate_low, 0)
                                                                         AS net_at_20pct_gbp,
    ROUND(SUM(price_saving_gbp) - SUM(value_days_gbp) * :holding_rate, 0) AS net_at_22pct_gbp,
    ROUND(SUM(price_saving_gbp) - SUM(value_days_gbp) * :holding_rate_high, 0)
                                                                         AS net_at_25pct_gbp
FROM   held;


\echo '=== 7. The same trade if every excess unit were still on the shelf ==='

-- The pessimistic bound: assume none of the excess sold and it has been carried
-- since receipt. The true cost lies between this and section 6.
WITH held AS (
    SELECT
        excess_units_ordered * COALESCE(
            (SELECT weighted_average_cost_gbp FROM mv_inventory_week AS m
             WHERE m.sku = s.sku AND m.warehouse_code = s.warehouse_code
               AND m.week_ending_date = DATE :'snapshot_date'), 0)       AS full_excess_value_gbp,
        price_saving_gbp,
        (DATE :'snapshot_date' - first_receipt)                          AS days_held
    FROM   vw_buy_ahead_stock AS s
    WHERE  first_receipt IS NOT NULL
)

SELECT
    'Upper bound on residual (section 6)'                                AS scenario,
    ROUND((SELECT SUM(residual_value_upper_bound_gbp) FROM vw_buy_ahead_stock), 0)
                                                                         AS working_capital_gbp,
    ROUND((SELECT SUM(price_saving_gbp) FROM vw_buy_ahead_stock), 0)     AS price_saving_gbp
UNION ALL
SELECT 'All excess units still held (pessimistic)',
       ROUND(SUM(full_excess_value_gbp), 0),
       ROUND(SUM(price_saving_gbp), 0)
FROM   held
UNION ALL
SELECT 'Excess fully consumed (optimistic)',
       0,
       ROUND(SUM(price_saving_gbp), 0)
FROM   held;


\echo '=== 8. Did the buy-ahead positions end the year overstocked? ==='

-- The question behind the working-capital number. If these positions closed the
-- year on normal cover, the stock was absorbed and the saving stands.
SELECT
    CASE WHEN closing_cover_weeks IS NULL      THEN 'No demand in the last 13 weeks'
         WHEN closing_cover_weeks <= 8         THEN '1 — under 2 months cover'
         WHEN closing_cover_weeks <= 26        THEN '2 — 2 to 6 months'
         WHEN closing_cover_weeks <= 52        THEN '3 — 6 to 12 months'
         ELSE                                       '4 — over 12 months'
    END                                                                  AS closing_cover_band,
    COUNT(*)                                                             AS positions,
    SUM(excess_units_ordered)                                            AS excess_units,
    SUM(residual_units_upper_bound)                                      AS residual_units_upper_bound,
    ROUND(SUM(residual_value_upper_bound_gbp), 0)                        AS residual_value_gbp,
    ROUND(SUM(price_saving_gbp), 0)                                      AS price_saving_gbp
FROM   vw_buy_ahead_stock
GROUP  BY closing_cover_band
ORDER  BY closing_cover_band;


\echo '=== 9. Reconciliation ==='

SELECT
    'Arden purchase lines, Feb 2025 window'                              AS measure,
    (SELECT COUNT(*) FROM vw_buy_ahead_lines)::numeric                   AS value
UNION ALL
SELECT 'Units ordered in the window',
       (SELECT SUM(quantity_ordered) FROM vw_buy_ahead_lines)::numeric
UNION ALL
SELECT 'Units received against those orders',
       (SELECT SUM(window_units_received) FROM vw_buy_ahead_stock)::numeric
UNION ALL
SELECT 'Received cannot exceed ordered (difference, expect <= 0)',
       (SELECT SUM(window_units_received) FROM vw_buy_ahead_stock)::numeric
       - (SELECT SUM(quantity_ordered) FROM vw_buy_ahead_lines)::numeric
UNION ALL
SELECT 'Positions where the residual bound exceeds closing stock (must be 0)',
       (SELECT COUNT(*) FROM vw_buy_ahead_stock
        WHERE residual_units_upper_bound > closing_units_on_hand)::numeric
UNION ALL
SELECT 'Arden median like-for-like price rise, per cent (file 14 gave 18.2)',
       (SELECT ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY price_change_pct)::numeric, 1)
        FROM vw_arden_price_change);
