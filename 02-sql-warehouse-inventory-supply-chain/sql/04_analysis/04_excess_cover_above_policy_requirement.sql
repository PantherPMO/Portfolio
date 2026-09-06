/* ============================================================
   Project    : 02 — Warehouse Inventory & Supply Chain Performance
   File       : 04_analysis/04_excess_cover_above_policy_requirement.sql
   Question   : BQ-02 / AQ-03 — How much stock is above what the
                business's own buying rules call for?
   Finding ID : F-04
   Output     : analysis/query_results/analyse_04_excess_above_policy.txt
   Author     : Peters
   Created    : 2026-08-23
   ============================================================

   Calderfield Trade Supplies Ltd is fictional and this data is synthetic.

   Grain: one row per SKU per warehouse at the closing snapshot of
   2025-12-28.

   The test is internal, and that is the point. Rather than compare
   stock against an outside benchmark, it compares stock against the
   maximum the site's own replenishment policy is designed to reach:

       expected maximum = reorder_point_units + reorder_quantity_units

   Under a min/max rule, stock is replenished when it falls to the
   reorder point and rises by the reorder quantity, so it should never
   sit far above their sum. Anything above it was not put there by the
   policy — it was put there by something the policy did not ask for.
   Whatever that something is, the business cannot defend the position
   using its own rules.

   Two readings are given:

     on hand only          stock on the shelf today
     on hand plus on order stock plus everything already committed

   The second matters because import lead times run near 78 days. A
   position that looks controlled on the shelf can already be far above
   its ceiling once the container in transit is counted.

   quantity_allocated is never added to quantity_on_hand. It is a claim
   against stock already counted, not stock in addition to it.

   WHAT THIS MEASURE DOES NOT DO. It tests conformance to the policy, not
   whether the policy is right. A site whose rules authorise deep cover
   can hold a great deal of stock and register no excess at all, while a
   site whose rules are deliberately tight registers a large excess on a
   modest position. The two failures are opposite and this measure only
   sees one of them. Read alongside days of cover, never instead of it.
   See docs/DECISIONS.md D-17.
   ============================================================ */

SET search_path TO supply;

\set snapshot_date '2025-12-28'
\set holding_rate 0.22
\set holding_rate_low 0.20
\set holding_rate_high 0.25


\echo '=== 1. Position against the policy ceiling ==='

DROP VIEW IF EXISTS vw_excess_position CASCADE;

CREATE VIEW vw_excess_position AS

WITH primary_source AS (
    -- The nominated source and its terms. Which supplier was actually used on
    -- each order is a separate question, answered in 04_analysis/17.
    SELECT
        ps.sku,
        ps.supplier_code,
        s.supplier_name,
        s.supplier_type,
        ps.quoted_lead_time_days,
        ps.minimum_order_quantity,
        ps.order_multiple
    FROM       product_supplier AS ps
    INNER JOIN supplier         AS s ON s.supplier_code = ps.supplier_code
    WHERE      ps.is_primary_source
)

SELECT
    m.sku,
    m.category_code,
    m.category_name,
    m.warehouse_code,
    m.discontinued_date,
    ps.supplier_code                                                     AS primary_supplier_code,
    ps.supplier_type                                                     AS primary_supplier_type,
    ps.quoted_lead_time_days,
    ps.minimum_order_quantity,
    m.quantity_on_hand,
    m.quantity_on_order,
    m.weighted_average_cost_gbp,
    m.stock_value_gbp,
    m.reorder_point_units,
    m.reorder_quantity_units,
    m.safety_stock_units,
    m.reorder_point_units + m.reorder_quantity_units                     AS policy_ceiling_units,
    m.cover_weeks,
    m.issued_units_13w,
    m.policy_age_months,
    m.last_reviewed_date,
    m.set_by_buyer,
    GREATEST(m.quantity_on_hand - (m.reorder_point_units + m.reorder_quantity_units), 0)
                                                                         AS excess_units_on_hand,
    GREATEST(m.quantity_on_hand + m.quantity_on_order
             - (m.reorder_point_units + m.reorder_quantity_units), 0)    AS excess_units_with_pipeline,
    ROUND(GREATEST(m.quantity_on_hand - (m.reorder_point_units + m.reorder_quantity_units), 0)
          * m.weighted_average_cost_gbp, 2)                              AS excess_value_on_hand_gbp,
    ROUND(GREATEST(m.quantity_on_hand + m.quantity_on_order
                   - (m.reorder_point_units + m.reorder_quantity_units), 0)
          * m.weighted_average_cost_gbp, 2)                              AS excess_value_with_pipeline_gbp,
    ROUND(m.quantity_on_hand::numeric
          / NULLIF(m.reorder_point_units + m.reorder_quantity_units, 0), 2)
                                                                         AS stock_to_ceiling_ratio
FROM       mv_inventory_week AS m
LEFT JOIN  primary_source    AS ps ON ps.sku = m.sku
WHERE      m.week_ending_date = DATE :'snapshot_date';


SELECT
    'Stocked lines at the closing snapshot'                              AS measure,
    COUNT(*)                                                             AS lines,
    NULL::numeric                                                        AS value_gbp
FROM   vw_excess_position
UNION ALL
SELECT 'Lines above the policy ceiling on hand',
       COUNT(*) FILTER (WHERE excess_units_on_hand > 0),
       ROUND(SUM(excess_value_on_hand_gbp), 0)
FROM   vw_excess_position
UNION ALL
SELECT 'Lines above the ceiling once the pipeline is counted',
       COUNT(*) FILTER (WHERE excess_units_with_pipeline > 0),
       ROUND(SUM(excess_value_with_pipeline_gbp), 0)
FROM   vw_excess_position
UNION ALL
SELECT 'Lines at or below the reorder point (due to reorder)',
       COUNT(*) FILTER (WHERE quantity_on_hand <= reorder_point_units), NULL
FROM   vw_excess_position
UNION ALL
SELECT 'Closing stock value, all lines', COUNT(*), ROUND(SUM(stock_value_gbp), 0)
FROM   vw_excess_position;


\echo '=== 2. How far above the ceiling does stock sit? ==='

SELECT
    CASE WHEN quantity_on_hand = 0                   THEN '0 — no stock'
         WHEN stock_to_ceiling_ratio <= 0.5          THEN '1 — at or below half the ceiling'
         WHEN stock_to_ceiling_ratio <= 1.0          THEN '2 — within the ceiling'
         WHEN stock_to_ceiling_ratio <= 1.5          THEN '3 — up to 1.5x the ceiling'
         WHEN stock_to_ceiling_ratio <= 2.5          THEN '4 — 1.5x to 2.5x'
         ELSE                                             '5 — over 2.5x the ceiling'
    END                                                                  AS position_band,
    COUNT(*)                                                             AS lines,
    ROUND(SUM(stock_value_gbp), 0)                                       AS stock_value_gbp,
    ROUND(SUM(excess_value_on_hand_gbp), 0)                              AS excess_value_gbp,
    ROUND(AVG(cover_weeks), 1)                                           AS mean_cover_weeks
FROM   vw_excess_position
GROUP  BY position_band
ORDER  BY position_band;


\echo '=== 3. Excess above policy by site ==='

SELECT
    warehouse_code,
    COUNT(*)                                                             AS stocked_lines,
    COUNT(*) FILTER (WHERE excess_units_on_hand > 0)                     AS lines_above_ceiling,
    ROUND(SUM(stock_value_gbp), 0)                                       AS closing_stock_gbp,
    ROUND(SUM(excess_value_on_hand_gbp), 0)                              AS excess_on_hand_gbp,
    ROUND(100.0 * SUM(excess_value_on_hand_gbp) / NULLIF(SUM(stock_value_gbp), 0), 1)
                                                                         AS excess_share_of_stock_pct,
    ROUND(SUM(excess_value_with_pipeline_gbp), 0)                        AS excess_with_pipeline_gbp,
    ROUND(SUM(excess_value_on_hand_gbp) * :holding_rate, 0)              AS excess_holding_cost_gbp
FROM   vw_excess_position
GROUP  BY warehouse_code
ORDER  BY excess_share_of_stock_pct DESC;


\echo '=== 4. Excess above policy by category ==='

SELECT
    category_code,
    category_name,
    COUNT(*)                                                             AS stocked_lines,
    ROUND(SUM(stock_value_gbp), 0)                                       AS closing_stock_gbp,
    ROUND(SUM(excess_value_on_hand_gbp), 0)                              AS excess_on_hand_gbp,
    ROUND(100.0 * SUM(excess_value_on_hand_gbp) / NULLIF(SUM(stock_value_gbp), 0), 1)
                                                                         AS excess_share_of_stock_pct,
    ROUND(AVG(cover_weeks), 1)                                           AS mean_cover_weeks
FROM   vw_excess_position
GROUP  BY category_code, category_name
ORDER  BY excess_on_hand_gbp DESC;


\echo '=== 5. Excess against the nominated source type ==='

-- Long lead times and large minimum order quantities are the two most obvious
-- structural reasons a position could exceed its own ceiling. This tests
-- whether the excess sits where those terms sit.
--
-- Read with section 5b. Classifying by the nominated source materially
-- misattributes the excess, because the stock that created it was in several
-- cases bought from the alternative source instead.
SELECT
    primary_supplier_type,
    COUNT(*)                                                             AS stocked_lines,
    ROUND(AVG(quoted_lead_time_days), 0)                                 AS mean_quoted_lead_days,
    ROUND(SUM(stock_value_gbp), 0)                                       AS closing_stock_gbp,
    ROUND(SUM(excess_value_on_hand_gbp), 0)                              AS excess_on_hand_gbp,
    ROUND(100.0 * SUM(excess_value_on_hand_gbp) / NULLIF(SUM(stock_value_gbp), 0), 1)
                                                                         AS excess_share_of_stock_pct,
    ROUND(SUM(excess_value_with_pipeline_gbp), 0)                        AS excess_with_pipeline_gbp,
    ROUND(AVG(cover_weeks), 1)                                           AS mean_cover_weeks,
    -- Minimum order quantity expressed against the rate the line actually
    -- sells at. A ratio above 1 means one order buys more than a quarter's trade.
    ROUND(AVG(minimum_order_quantity::numeric / NULLIF(issued_units_13w, 0))
          FILTER (WHERE issued_units_13w > 0), 2)                        AS mean_moq_to_quarterly_demand
FROM   vw_excess_position
GROUP  BY primary_supplier_type
ORDER  BY excess_share_of_stock_pct DESC;


\echo '=== 5b. Excess against the source ACTUALLY used ==='

-- Section 5 classifies by the NOMINATED primary source, which turns out to
-- attribute the excess to the wrong supplier type. Where a SKU has a cheaper
-- alternative source with a large minimum order quantity, the buyer may use it
-- even though the nominated source is a UK manufacturer with a small minimum.
-- The stock that lands is then the importer's, on the importer's terms, sitting
-- against a line the nominated-source view labels 'UK Manufacturer'.
--
-- This section attributes the position to the supplier that actually delivered
-- into it most recently. See docs/DECISIONS.md D-18.
WITH last_receipt AS (
    SELECT DISTINCT ON (pol.sku, po.warehouse_code)
        pol.sku,
        po.warehouse_code,
        po.supplier_code                                                 AS last_supplier_code,
        s.supplier_type                                                  AS last_supplier_type,
        ps.minimum_order_quantity                                        AS last_source_moq,
        grl.receipt_date,
        grl.quantity_received
    FROM       goods_receipt_line  AS grl
    INNER JOIN purchase_order_line AS pol
           ON  pol.purchase_order_number = grl.purchase_order_number
          AND  pol.line_number           = grl.purchase_order_line_number
    INNER JOIN purchase_order      AS po ON po.purchase_order_number = grl.purchase_order_number
    INNER JOIN supplier            AS s  ON s.supplier_code = po.supplier_code
    INNER JOIN product_supplier    AS ps
           ON  ps.sku = pol.sku AND ps.supplier_code = po.supplier_code
    WHERE      grl.receipt_date <= DATE :'snapshot_date'
    ORDER  BY  pol.sku, po.warehouse_code, grl.receipt_date DESC
)

SELECT
    COALESCE(lr.last_supplier_type, 'No receipt in the period')          AS last_actual_source_type,
    COUNT(*)                                                             AS stocked_lines,
    ROUND(SUM(e.stock_value_gbp), 0)                                     AS closing_stock_gbp,
    ROUND(SUM(e.excess_value_on_hand_gbp), 0)                            AS excess_on_hand_gbp,
    ROUND(100.0 * SUM(e.excess_value_on_hand_gbp)
          / NULLIF(SUM(SUM(e.excess_value_on_hand_gbp)) OVER (), 0), 1) AS share_of_all_excess_pct,
    ROUND(100.0 * SUM(e.excess_value_on_hand_gbp) / NULLIF(SUM(e.stock_value_gbp), 0), 1)
                                                                         AS excess_share_of_stock_pct,
    ROUND(AVG(lr.last_source_moq::numeric / NULLIF(e.issued_units_13w, 0))
          FILTER (WHERE e.issued_units_13w > 0), 2)                      AS mean_moq_to_quarterly_demand
FROM       vw_excess_position AS e
LEFT JOIN  last_receipt       AS lr
       ON  lr.sku = e.sku AND lr.warehouse_code = e.warehouse_code
GROUP  BY  COALESCE(lr.last_supplier_type, 'No receipt in the period')
ORDER  BY  excess_on_hand_gbp DESC;


\echo '=== 6. Excess against policy review currency ==='

-- Anchored to 2025-12-31 (D-05). "Stale" is over 15 months, the threshold used
-- throughout the project.
SELECT
    CASE WHEN policy_age_months > 15 THEN 'Not reviewed for over 15 months'
         ELSE                             'Reviewed within 15 months' END AS policy_currency,
    COUNT(*)                                                             AS stocked_lines,
    ROUND(SUM(stock_value_gbp), 0)                                       AS closing_stock_gbp,
    ROUND(SUM(excess_value_on_hand_gbp), 0)                              AS excess_on_hand_gbp,
    ROUND(100.0 * SUM(excess_value_on_hand_gbp) / NULLIF(SUM(stock_value_gbp), 0), 1)
                                                                         AS excess_share_of_stock_pct,
    ROUND(AVG(cover_weeks), 1)                                           AS mean_cover_weeks,
    ROUND(AVG(policy_age_months), 1)                                     AS mean_policy_age_months
FROM   vw_excess_position
GROUP  BY policy_currency
ORDER  BY policy_currency;


\echo '=== 7. The twenty largest positions above ceiling ==='

SELECT
    sku,
    category_code,
    warehouse_code,
    primary_supplier_code,
    primary_supplier_type,
    quantity_on_hand,
    quantity_on_order,
    policy_ceiling_units,
    stock_to_ceiling_ratio,
    excess_units_on_hand,
    ROUND(excess_value_on_hand_gbp, 0)                                   AS excess_value_gbp,
    cover_weeks,
    minimum_order_quantity,
    issued_units_13w,
    policy_age_months
FROM   vw_excess_position
WHERE  excess_units_on_hand > 0
ORDER  BY excess_value_on_hand_gbp DESC
LIMIT  20;


\echo '=== 8. Totals, with the sensitivity band ==='

SELECT
    ROUND(SUM(stock_value_gbp), 0)                                       AS closing_stock_gbp,
    ROUND(SUM(excess_value_on_hand_gbp), 0)                              AS excess_on_hand_gbp,
    ROUND(100.0 * SUM(excess_value_on_hand_gbp) / NULLIF(SUM(stock_value_gbp), 0), 1)
                                                                         AS excess_share_pct,
    ROUND(SUM(excess_value_with_pipeline_gbp), 0)                        AS excess_with_pipeline_gbp,
    ROUND(SUM(excess_value_on_hand_gbp) * :holding_rate_low, 0)          AS holding_cost_at_20pct_gbp,
    ROUND(SUM(excess_value_on_hand_gbp) * :holding_rate, 0)              AS holding_cost_at_22pct_gbp,
    ROUND(SUM(excess_value_on_hand_gbp) * :holding_rate_high, 0)         AS holding_cost_at_25pct_gbp
FROM   vw_excess_position;


\echo '=== 9. Overlap with the slow-moving population from file 03 ==='

-- The two exposures are different questions and they overlap. A single stated
-- hierarchy is needed before either total is added to anything, or the same
-- stock gets counted twice in the recommendations.
SELECT
    CASE WHEN e.excess_units_on_hand > 0 THEN 'Above policy ceiling'
         ELSE                                 'Within policy ceiling' END AS excess_status,
    CASE WHEN c.age_band IN ('3 — 27 to 52 weeks', '4 — over 52 weeks',
                             '5 — no issue in the period')
              OR c.cover_band = '5 — over 12 months'
         THEN 'Slow moving' ELSE 'Not slow moving' END                   AS slow_status,
    COUNT(*)                                                             AS lines,
    ROUND(SUM(c.stock_value_gbp), 0)                                     AS stock_value_gbp
FROM       vw_excess_position  AS e
INNER JOIN vw_closing_position AS c
       ON  c.sku = e.sku AND c.warehouse_code = e.warehouse_code
GROUP  BY excess_status, slow_status
ORDER  BY excess_status, slow_status;
