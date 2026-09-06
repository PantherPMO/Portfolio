/* ============================================================
   Project    : 02 — Warehouse Inventory & Supply Chain Performance
   File       : 03_preparation/02_build_demand_and_fulfilment_base.sql
   Question   : What did customers actually ask for, and what did they
                get?
   Output     : view supply.vw_demand_line
   Author     : Peters
   Created    : 2026-08-23
   ============================================================

   Grain: one row per sales order line. 33,422 lines in, 32,737 out —
   only the 685 cancelled lines are removed. 133 of the retained lines
   were ordered on 29-31 December 2025, after the last snapshot week,
   and carry a null week_ending_date.

   Two rules govern this view, and both exist because the obvious
   alternative is wrong:

   1. FULFILMENT IS READ FROM QUANTITIES, NEVER FROM line_status.
      A line that was despatched and later returned carries the status
      'Returned', which overwrites whatever it said about fulfilment.
      245 lines are in that state. Filtering on
      line_status = 'Despatched in full' looks like a clean way to get
      good demand and silently discards every short, unavailable and
      returned line — 2,667 of them, which is exactly the demand that
      evidences the availability problem.

   2. ONLY CANCELLED LINES ARE EXCLUDED.
      A cancelled line is demand that was withdrawn, so it never became
      a claim on stock. A line that could not be supplied is real demand
      the business failed to meet, and belongs in the denominator.

   See docs/DECISIONS.md D-03.
   ============================================================ */

SET search_path TO supply;

CREATE OR REPLACE VIEW vw_demand_line AS

SELECT
    sol.sales_order_number,
    sol.line_number,
    so.order_date,
    so.despatch_date,
    cw.week_ending_date,
    so.warehouse_code,
    so.order_channel,
    sol.sku,
    p.category_code,
    pc.category_name,
    so.customer_account,
    cr.resolved_account,
    cr.customer_segment,
    sol.quantity_ordered                             AS demand_units,
    sol.quantity_despatched                          AS supplied_units,
    sol.quantity_ordered - sol.quantity_despatched   AS unmet_units,
    sol.unit_price_gbp,
    sol.line_discount_pct,
    -- Demand value is what the customer asked to buy; supplied value is what
    -- the business actually invoiced. The difference is revenue not taken.
    ROUND(sol.quantity_ordered    * sol.unit_price_gbp, 2)  AS demand_value_gbp,
    ROUND(sol.quantity_despatched * sol.unit_price_gbp, 2)  AS supplied_value_gbp,
    ROUND((sol.quantity_ordered - sol.quantity_despatched)
          * sol.unit_price_gbp, 2)                          AS unmet_value_gbp,
    sol.quantity_despatched = sol.quantity_ordered   AS is_supplied_in_full,
    sol.quantity_despatched = 0                      AS is_wholly_unsupplied,
    sol.line_status                                  AS source_line_status
FROM       sales_order_line     AS sol
INNER JOIN sales_order          AS so  ON so.sales_order_number = sol.sales_order_number
INNER JOIN product              AS p   ON p.sku = sol.sku
INNER JOIN product_category     AS pc  ON pc.category_code = p.category_code
INNER JOIN vw_customer_resolved AS cr  ON cr.customer_account = so.customer_account
-- Attaches the reporting week. LEFT JOIN, not INNER: the weekly calendar ends
-- 2025-12-28 and 133 order lines were taken on 29-31 December. They are real
-- demand and stay in this view; only week-based aggregation excludes them,
-- which is correct because no snapshot week covers them.
LEFT JOIN  calendar_week        AS cw
       ON  so.order_date BETWEEN cw.week_starting_date AND cw.week_ending_date
WHERE      sol.line_status <> 'Cancelled';


\echo '=== Demand base: what was kept and what was dropped ==='

SELECT
    'sales_order_line rows'                          AS population,
    COUNT(*)                                         AS line_count,
    NULL::numeric                                    AS units
FROM   sales_order_line
UNION ALL
SELECT 'excluded — cancelled lines', COUNT(*), SUM(quantity_ordered)
FROM   sales_order_line WHERE line_status = 'Cancelled'
UNION ALL
SELECT 'retained in vw_demand_line', COUNT(*), SUM(demand_units)
FROM   vw_demand_line
UNION ALL
SELECT 'of which returned after despatch', COUNT(*), SUM(demand_units)
FROM   vw_demand_line WHERE source_line_status = 'Returned'
UNION ALL
SELECT 'of which short or wholly unsupplied', COUNT(*), SUM(unmet_units)
FROM   vw_demand_line WHERE unmet_units > 0
UNION ALL
SELECT 'of which fall outside the weekly grid (29-31 Dec 2025)', COUNT(*), SUM(demand_units)
FROM   vw_demand_line WHERE week_ending_date IS NULL;


\echo '=== The cost of filtering on line_status instead of quantities ==='

-- Evidence for D-03, kept because it is the kind of mistake that is invisible
-- once made: the naive filter loses a twelfth of demand and almost all of the
-- unmet demand the analysis exists to measure.
SELECT
    'Correct base — all non-cancelled lines'                             AS method,
    COUNT(*)                                                             AS lines,
    SUM(demand_units)                                                    AS demand_units,
    SUM(unmet_units)                                                     AS unmet_units,
    ROUND(SUM(unmet_value_gbp), 2)                                       AS unmet_value_gbp
FROM   vw_demand_line
UNION ALL
SELECT
    'Naive filter — line_status = ''Despatched in full''',
    COUNT(*), SUM(demand_units), SUM(unmet_units), ROUND(SUM(unmet_value_gbp), 2)
FROM   vw_demand_line
WHERE  source_line_status = 'Despatched in full';


\echo '=== Fulfilment by site, 2025 ==='

SELECT
    warehouse_code,
    COUNT(*)                                                             AS demand_lines,
    COUNT(*) FILTER (WHERE unmet_units > 0)                              AS lines_not_supplied_in_full,
    ROUND(100.0 * COUNT(*) FILTER (WHERE unmet_units = 0) / COUNT(*), 1) AS line_fill_rate_pct,
    ROUND(100.0 * SUM(supplied_units) / NULLIF(SUM(demand_units), 0), 1) AS unit_fill_rate_pct,
    ROUND(SUM(unmet_value_gbp), 2)                                       AS unmet_value_gbp
FROM   vw_demand_line
WHERE  order_date BETWEEN DATE '2025-01-01' AND DATE '2025-12-31'
GROUP  BY warehouse_code
ORDER  BY warehouse_code;
