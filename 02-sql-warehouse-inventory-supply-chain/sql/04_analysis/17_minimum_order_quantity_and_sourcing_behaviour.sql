/* ============================================================
   Project    : 02 — Warehouse Inventory & Supply Chain Performance
   File       : 04_analysis/17_minimum_order_quantity_and_sourcing_behaviour.sql
   Question   : BQ-01 / AQ-17 — How much inventory is structurally created
                by minimum order quantities and sourcing decisions rather
                than by customer demand or replenishment policy?
   Finding ID : F-17
   Output     : analysis/query_results/analyse_17_moq_and_sourcing_behaviour.txt
   Author     : Peters
   Created    : 2026-08-23
   ============================================================

   Calderfield Trade Supplies Ltd is fictional and this data is synthetic.

   Grain: purchase order lines placed during 2025 for the flow measures;
   one row per SKU per warehouse at the closing snapshot of 2025-12-28
   for the standing-stock measures.

   WHAT "STRUCTURALLY CREATED" MEANS HERE. A replenishment policy calls
   for a reorder quantity. Where the source actually used will not sell
   that quantity, the buyer orders the supplier's minimum instead. The
   difference between the two is not a demand decision and not a policy
   decision: it is a term of trade. That difference, and the deeper
   pipeline a longer lead time requires, are what this file measures.

   D-18 GOVERNS ATTRIBUTION. Every minimum order quantity and lead time
   in this file belongs to the supplier ACTUALLY used, taken from the
   purchase order that was raised or the most recent receipt against the
   position. Attributing to the nominated primary source reversed the
   conclusion in file 04 and is not used anywhere here.

   NO DOUBLE COUNTING WITH FILES 04 AND 05. Section 5 partitions closing
   stock into three exhaustive, mutually exclusive buckets, of which the
   third is file 04's excess above policy and must reconcile to
   £134,701. The minimum-order-quantity attribution in section 6 is
   deliberately NOT a fourth bucket: it is a bound that cuts across the
   first two, reported as such, because a unit can be both inside the
   policy ceiling and there only because of a supplier minimum. Adding
   section 6 to section 5 would count those units twice.

   TWO CLOCKS, KEPT SEPARATE (D-29). Purchase value bought during 2025
   is a flow across twelve months. Stock standing at 2025-12-28 is a
   level at one instant. Average incremental cycle stock is a level
   derived from a flow. They are never added, and any comparison against
   an annual holding cost uses the level, not the flow.

   A BOUND, NOT AN ESTIMATE. Stock is fungible: once a delivery is put
   away, no unit carries a record of why it was bought. Section 6 takes
   the largest quantity the minimum could still account for and calls
   that the upper bound. The true figure is at or below it.
   ============================================================ */

SET search_path TO supply;

\set snapshot_date '2025-12-28'
\set analysis_date '2025-12-31'
\set year_start '2025-01-01'
\set holding_rate 0.22


\echo '=== 1. How buying quantities are set, by the source actually used ==='

DROP VIEW IF EXISTS vw_purchase_quantity_structure CASCADE;

CREATE VIEW vw_purchase_quantity_structure AS
SELECT
    pol.purchase_order_number,
    pol.line_number,
    pol.sku,
    pr.category_code,
    pc.category_name,
    po.warehouse_code,
    po.order_date,
    po.supplier_code,
    s.supplier_name,
    s.supplier_type,
    pol.quantity_ordered,
    pol.unit_cost_gbp,
    ps.minimum_order_quantity,
    ps.order_multiple,
    ps.quoted_lead_time_days,
    rp.reorder_quantity_units,
    rp.reorder_point_units,
    ps.minimum_order_quantity > rp.reorder_quantity_units                AS minimum_exceeds_policy_quantity,
    pol.quantity_ordered = ps.minimum_order_quantity                     AS ordered_exactly_at_minimum,
    -- Units bought beyond what the policy's own reorder quantity called
    -- for, capped at the supplier minimum so that a buyer choosing to
    -- order more than the minimum is not charged to the minimum.
    GREATEST(LEAST(pol.quantity_ordered, ps.minimum_order_quantity)
             - rp.reorder_quantity_units, 0)                             AS minimum_increment_units,
    GREATEST(pol.quantity_ordered
             - GREATEST(rp.reorder_quantity_units, ps.minimum_order_quantity), 0)
                                                                         AS buyer_discretion_units
FROM       purchase_order_line   AS pol
INNER JOIN purchase_order        AS po  ON po.purchase_order_number = pol.purchase_order_number
INNER JOIN supplier              AS s   ON s.supplier_code          = po.supplier_code
INNER JOIN product              AS pr   ON pr.sku                   = pol.sku
INNER JOIN product_category      AS pc  ON pc.category_code         = pr.category_code
INNER JOIN product_supplier      AS ps  ON ps.sku = pol.sku AND ps.supplier_code = po.supplier_code
INNER JOIN replenishment_policy  AS rp  ON rp.sku = pol.sku AND rp.warehouse_code = po.warehouse_code
WHERE      po.order_date BETWEEN DATE :'year_start' AND DATE :'analysis_date';


-- The signature. Where a supplier's minimum binds, the order quantity
-- stops being a replenishment decision and becomes a term of trade.
SELECT
    supplier_type,
    COUNT(*)                                                             AS purchase_lines,
    COUNT(*) FILTER (WHERE minimum_exceeds_policy_quantity)              AS lines_where_minimum_binds,
    ROUND(100.0 * COUNT(*) FILTER (WHERE minimum_exceeds_policy_quantity) / COUNT(*), 1)
                                                                         AS minimum_binds_pct,
    COUNT(*) FILTER (WHERE ordered_exactly_at_minimum)                   AS lines_ordered_at_minimum,
    ROUND(100.0 * COUNT(*) FILTER (WHERE ordered_exactly_at_minimum) / COUNT(*), 1)
                                                                         AS ordered_at_minimum_pct,
    ROUND(AVG(minimum_order_quantity)::numeric, 0)                       AS mean_minimum_order_quantity,
    ROUND(AVG(reorder_quantity_units)::numeric, 0)                       AS mean_policy_reorder_quantity,
    ROUND(AVG(quoted_lead_time_days)::numeric, 0)                        AS mean_quoted_lead_days
FROM   vw_purchase_quantity_structure
GROUP  BY supplier_type
ORDER  BY purchase_lines DESC;


\echo '=== 2. Flow: 2025 purchase value bought as a minimum-order increment ==='

-- A flow across twelve months, not a stock level. Not comparable with
-- anything in sections 5 to 8 without the halving in section 4.
SELECT
    CASE WHEN GROUPING(supplier_type) = 1 THEN 'All sources' ELSE supplier_type END
                                                                         AS supplier_type,
    COUNT(*)                                                             AS purchase_lines,
    SUM(quantity_ordered)                                                AS units_ordered,
    SUM(minimum_increment_units)                                         AS minimum_increment_units,
    ROUND(100.0 * SUM(minimum_increment_units) / NULLIF(SUM(quantity_ordered), 0), 1)
                                                                         AS increment_share_of_units_pct,
    ROUND(SUM(quantity_ordered * unit_cost_gbp), 0)                      AS purchase_value_gbp,
    ROUND(SUM(minimum_increment_units * unit_cost_gbp), 0)               AS increment_value_gbp,
    ROUND(100.0 * SUM(minimum_increment_units * unit_cost_gbp)
          / NULLIF(SUM(quantity_ordered * unit_cost_gbp), 0), 1)         AS increment_share_of_value_pct,
    ROUND(SUM(buyer_discretion_units * unit_cost_gbp), 0)                AS buyer_discretion_value_gbp
FROM   vw_purchase_quantity_structure
GROUP  BY ROLLUP (supplier_type)
ORDER  BY increment_value_gbp DESC NULLS LAST;


\echo '=== 3. The same flow by site and by category ==='

SELECT
    warehouse_code,
    COUNT(*)                                                             AS purchase_lines,
    ROUND(SUM(quantity_ordered * unit_cost_gbp), 0)                      AS purchase_value_gbp,
    ROUND(SUM(minimum_increment_units * unit_cost_gbp), 0)               AS increment_value_gbp,
    ROUND(100.0 * SUM(minimum_increment_units * unit_cost_gbp)
          / NULLIF(SUM(quantity_ordered * unit_cost_gbp), 0), 1)         AS increment_share_pct,
    ROUND(100.0 * COUNT(*) FILTER (WHERE supplier_type = 'Far East Importer') / COUNT(*), 1)
                                                                         AS import_line_share_pct,
    ROUND(AVG(quoted_lead_time_days)::numeric, 1)                        AS mean_quoted_lead_days
FROM   vw_purchase_quantity_structure
GROUP  BY warehouse_code
ORDER  BY increment_value_gbp DESC;


SELECT
    category_code,
    category_name,
    COUNT(*)                                                             AS purchase_lines,
    ROUND(SUM(quantity_ordered * unit_cost_gbp), 0)                      AS purchase_value_gbp,
    ROUND(SUM(minimum_increment_units * unit_cost_gbp), 0)               AS increment_value_gbp,
    ROUND(100.0 * SUM(minimum_increment_units * unit_cost_gbp)
          / NULLIF(SUM(quantity_ordered * unit_cost_gbp), 0), 1)         AS increment_share_pct
FROM   vw_purchase_quantity_structure
GROUP  BY category_code, category_name
ORDER  BY increment_value_gbp DESC;


\echo '=== 4. Level: the average incremental cycle stock a minimum creates ==='

-- Ordering Q units where the policy called for q leaves, on average
-- across the cycle, (Q - q) / 2 units standing that demand did not
-- require. This converts the section 2 flow into a level comparable
-- with a stock figure, and is the only form in which the flow may be
-- set against an annual holding cost (D-29).
SELECT
    CASE WHEN GROUPING(supplier_type) = 1 THEN 'All sources' ELSE supplier_type END
                                                                         AS supplier_type,
    ROUND(SUM(minimum_increment_units * unit_cost_gbp), 0)               AS increment_bought_2025_gbp,
    ROUND(SUM(minimum_increment_units * unit_cost_gbp) / 2, 0)           AS mean_incremental_cycle_stock_gbp,
    ROUND(SUM(minimum_increment_units * unit_cost_gbp) / 2 * :holding_rate, 0)
                                                                         AS annual_holding_cost_gbp,
    ROUND(SUM(minimum_increment_units * unit_cost_gbp) / 2 * 0.20, 0)    AS holding_cost_at_20pct_gbp,
    ROUND(SUM(minimum_increment_units * unit_cost_gbp) / 2 * 0.25, 0)    AS holding_cost_at_25pct_gbp
FROM   vw_purchase_quantity_structure
GROUP  BY ROLLUP (supplier_type)
ORDER  BY increment_bought_2025_gbp DESC NULLS LAST;


\echo '=== 5. Closing stock partitioned three ways — exhaustive and exclusive ==='

DROP VIEW IF EXISTS vw_structural_stock_position CASCADE;

CREATE VIEW vw_structural_stock_position AS

WITH last_purchase AS (
    -- The most recent buy against the position, and the increment it
    -- carried. DISTINCT ON takes one row per position, so a SKU
    -- replenished repeatedly cannot fan out (D-18).
    SELECT DISTINCT ON (q.sku, q.warehouse_code)
        q.sku,
        q.warehouse_code,
        q.order_date                                                     AS last_order_date,
        q.supplier_code                                                  AS last_supplier_code,
        q.supplier_type                                                  AS last_supplier_type,
        q.quantity_ordered                                               AS last_quantity_ordered,
        q.minimum_order_quantity                                         AS last_minimum_order_quantity,
        q.quoted_lead_time_days                                          AS last_quoted_lead_days,
        q.minimum_increment_units                                        AS last_minimum_increment_units,
        q.minimum_exceeds_policy_quantity                                AS last_minimum_binds
    FROM   vw_purchase_quantity_structure AS q
    ORDER  BY q.sku, q.warehouse_code, q.order_date DESC, q.purchase_order_number DESC
),

-- The shortest lead time available for the SKU from any qualified
-- source, used as the comparator for the pipeline premium in section 7.
shortest_alternative AS (
    SELECT
        sku,
        MIN(quoted_lead_time_days)                                       AS shortest_lead_days,
        COUNT(*)                                                         AS qualified_sources
    FROM   product_supplier
    GROUP  BY sku
)

SELECT
    m.sku,
    m.category_code,
    m.category_name,
    m.warehouse_code,
    m.quantity_on_hand,
    m.weighted_average_cost_gbp,
    m.stock_value_gbp,
    m.cover_weeks,
    m.issued_units_13w,
    m.issued_units_13w::numeric / 13                                     AS weekly_demand_units,
    m.reorder_point_units,
    m.reorder_quantity_units,
    m.reorder_point_units + m.reorder_quantity_units                     AS policy_ceiling_units,
    lp.last_order_date,
    lp.last_supplier_type,
    lp.last_quantity_ordered,
    lp.last_minimum_order_quantity,
    lp.last_quoted_lead_days,
    lp.last_minimum_increment_units,
    lp.last_minimum_binds,
    sa.shortest_lead_days,
    sa.qualified_sources,
    -- Bucket 1. Stock up to the reorder point: the depth demand and
    -- lead time require before a replenishment is triggered.
    LEAST(m.quantity_on_hand, m.reorder_point_units)                     AS units_to_reorder_point,
    -- Bucket 2. Stock between the reorder point and the policy ceiling:
    -- depth the site's own rules authorise.
    GREATEST(LEAST(m.quantity_on_hand, m.reorder_point_units + m.reorder_quantity_units)
             - m.reorder_point_units, 0)                                 AS units_within_policy_ceiling,
    -- Bucket 3. Stock above the ceiling: file 04's excess, reproduced
    -- here so the partition can be reconciled against it.
    GREATEST(m.quantity_on_hand - (m.reorder_point_units + m.reorder_quantity_units), 0)
                                                                         AS units_above_policy_ceiling,
    -- The bound, cutting across buckets 1 and 2. The last buy's
    -- increment can only still be standing if there is stock to hold
    -- it, so the bound is the smaller of the two.
    LEAST(m.quantity_on_hand, COALESCE(lp.last_minimum_increment_units, 0))
                                                                         AS units_bounded_to_minimum
FROM       mv_inventory_week      AS m
LEFT  JOIN last_purchase          AS lp ON lp.sku = m.sku AND lp.warehouse_code = m.warehouse_code
LEFT  JOIN shortest_alternative   AS sa ON sa.sku = m.sku
WHERE      m.week_ending_date = DATE :'snapshot_date';


SELECT
    'Closing stock at 2025-12-28'                                        AS partition_bucket,
    SUM(quantity_on_hand)                                                AS units,
    ROUND(SUM(stock_value_gbp), 0)                                       AS value_gbp,
    100.0                                                                AS share_pct
FROM   vw_structural_stock_position
UNION ALL
SELECT 'Bucket 1 — cover to the reorder point',
       SUM(units_to_reorder_point),
       ROUND(SUM(units_to_reorder_point * weighted_average_cost_gbp), 0),
       ROUND(100.0 * SUM(units_to_reorder_point * weighted_average_cost_gbp)
             / SUM(stock_value_gbp), 1)
FROM   vw_structural_stock_position
UNION ALL
SELECT 'Bucket 2 — authorised by the policy ceiling',
       SUM(units_within_policy_ceiling),
       ROUND(SUM(units_within_policy_ceiling * weighted_average_cost_gbp), 0),
       ROUND(100.0 * SUM(units_within_policy_ceiling * weighted_average_cost_gbp)
             / SUM(stock_value_gbp), 1)
FROM   vw_structural_stock_position
UNION ALL
SELECT 'Bucket 3 — above the policy ceiling (file 04)',
       SUM(units_above_policy_ceiling),
       ROUND(SUM(units_above_policy_ceiling * weighted_average_cost_gbp), 0),
       ROUND(100.0 * SUM(units_above_policy_ceiling * weighted_average_cost_gbp)
             / SUM(stock_value_gbp), 1)
FROM   vw_structural_stock_position;


\echo '=== 6. The minimum-order bound, which cuts across buckets 1 and 2 ==='

-- NOT a fourth bucket. These units are already counted in section 5.
-- The question this answers is a different one: of the stock standing
-- inside the policy ceiling, how much can the supplier minimum still
-- account for?
SELECT
    CASE WHEN GROUPING(last_supplier_type) = 1 THEN 'All positions'
         WHEN last_supplier_type IS NULL       THEN 'No 2025 purchase against the position'
         ELSE last_supplier_type
    END                                                                  AS last_supplier_type,
    COUNT(*)                                                             AS positions,
    SUM(quantity_on_hand)                                                AS units_on_hand,
    ROUND(SUM(stock_value_gbp), 0)                                       AS stock_value_gbp,
    COUNT(*) FILTER (WHERE last_minimum_binds)                           AS positions_where_minimum_bound,
    SUM(units_bounded_to_minimum)                                        AS units_bounded_to_minimum,
    ROUND(SUM(units_bounded_to_minimum * weighted_average_cost_gbp), 0)  AS value_bounded_to_minimum_gbp,
    ROUND(100.0 * SUM(units_bounded_to_minimum * weighted_average_cost_gbp)
          / NULLIF(SUM(stock_value_gbp), 0), 1)                          AS bound_share_of_stock_pct
FROM   vw_structural_stock_position
GROUP  BY ROLLUP (last_supplier_type)
ORDER  BY value_bounded_to_minimum_gbp DESC NULLS LAST;


\echo '=== 7. The pipeline premium a longer lead time requires ==='

-- A source quoting 55 days rather than 7 obliges the network to hold
-- roughly seven further weeks of demand somewhere — in transit, or as
-- the deeper reorder point the wait forces. Measured only where an
-- alternative source exists, since a sole-source SKU has no comparator.
SELECT
    CASE WHEN GROUPING(last_supplier_type) = 1 THEN 'All sources' ELSE last_supplier_type END
                                                                         AS last_supplier_type,
    COUNT(*)                                                             AS positions,
    ROUND(AVG(last_quoted_lead_days)::numeric, 1)                        AS mean_lead_days_used,
    ROUND(AVG(shortest_lead_days)::numeric, 1)                           AS mean_shortest_available_days,
    ROUND(AVG(last_quoted_lead_days - shortest_lead_days)::numeric, 1)   AS mean_extra_lead_days,
    ROUND(SUM((last_quoted_lead_days - shortest_lead_days) / 7.0
              * weekly_demand_units * weighted_average_cost_gbp), 0)     AS pipeline_premium_gbp,
    ROUND(SUM((last_quoted_lead_days - shortest_lead_days) / 7.0
              * weekly_demand_units * weighted_average_cost_gbp) * :holding_rate, 0)
                                                                         AS annual_holding_cost_gbp
FROM   vw_structural_stock_position
WHERE  qualified_sources    > 1
  AND  last_quoted_lead_days IS NOT NULL
  AND  last_quoted_lead_days > shortest_lead_days
GROUP  BY ROLLUP (last_supplier_type)
ORDER  BY pipeline_premium_gbp DESC NULLS LAST;


\echo '=== 8. Sourcing behaviour by site, on the source actually used ==='

SELECT
    warehouse_code,
    COUNT(*)                                                             AS positions,
    ROUND(SUM(stock_value_gbp), 0)                                       AS stock_value_gbp,
    COUNT(*) FILTER (WHERE last_supplier_type = 'Far East Importer')     AS n_imported,
    ROUND(100.0 * COUNT(*) FILTER (WHERE last_supplier_type = 'Far East Importer')
          / NULLIF(COUNT(*) FILTER (WHERE last_supplier_type IS NOT NULL), 0), 1)
                                                                         AS import_share_of_positions_pct,
    ROUND(100.0 * SUM(stock_value_gbp) FILTER (WHERE last_supplier_type = 'Far East Importer')
          / NULLIF(SUM(stock_value_gbp), 0), 1)                          AS import_share_of_value_pct,
    ROUND(AVG(last_quoted_lead_days)::numeric, 1)                        AS mean_lead_days_used,
    ROUND(SUM(units_bounded_to_minimum * weighted_average_cost_gbp), 0)  AS value_bounded_to_minimum_gbp,
    ROUND(AVG(cover_weeks), 1)                                           AS mean_cover_weeks
FROM   vw_structural_stock_position
GROUP  BY warehouse_code
ORDER  BY value_bounded_to_minimum_gbp DESC;


\echo '=== 9. Minimums expressed in weeks of demand, which is what makes them bite ==='

-- A minimum of 400 units is unremarkable on a line selling 200 a week
-- and is two years of trade on one selling four.
WITH banded AS (
    SELECT
        CASE WHEN weekly_demand_units = 0                                    THEN '5 — no current demand'
             WHEN last_minimum_order_quantity IS NULL                        THEN '6 — no 2025 purchase'
             WHEN last_minimum_order_quantity / weekly_demand_units <=  4    THEN '1 — up to 1 month'
             WHEN last_minimum_order_quantity / weekly_demand_units <= 13    THEN '2 — 1 to 3 months'
             WHEN last_minimum_order_quantity / weekly_demand_units <= 26    THEN '3 — 3 to 6 months'
             ELSE                                                                 '4 — over 6 months'
        END                                                                  AS minimum_in_weeks_band,
        quantity_on_hand,
        stock_value_gbp,
        cover_weeks,
        units_bounded_to_minimum,
        weighted_average_cost_gbp,
        last_supplier_type
    FROM   vw_structural_stock_position
)

SELECT
    minimum_in_weeks_band,
    COUNT(*)                                                             AS positions,
    ROUND(SUM(stock_value_gbp), 0)                                       AS stock_value_gbp,
    ROUND(AVG(cover_weeks), 1)                                           AS mean_cover_weeks,
    ROUND(SUM(units_bounded_to_minimum * weighted_average_cost_gbp), 0)  AS value_bounded_to_minimum_gbp,
    COUNT(*) FILTER (WHERE last_supplier_type = 'Far East Importer')     AS n_imported
FROM   banded
GROUP  BY minimum_in_weeks_band
ORDER  BY minimum_in_weeks_band;


\echo '=== 10. The February 2025 buy-ahead, re-measured against closing stock ==='

-- File 15 bounded the residual at £6,971. D-28 requires the figure to
-- be re-derived rather than carried forward, so it is rebuilt here from
-- its components against the same closing snapshot the rest of this file
-- uses. Two bounds are shown, and the difference between them is the
-- point: the loose bound ignores what has been issued since the buy and
-- is therefore nearly the whole position. The tight bound nets off
-- issues first, which is the only version that says anything.
WITH matched AS (
    SELECT
        b.sku,
        b.warehouse_code,
        b.excess_units_ordered,
        b.units_issued_since_receipt,
        p.quantity_on_hand,
        p.weighted_average_cost_gbp,
        p.units_above_policy_ceiling,
        LEAST(p.quantity_on_hand, b.excess_units_ordered)                AS loose_bound_units,
        LEAST(GREATEST(b.excess_units_ordered - b.units_issued_since_receipt, 0),
              p.quantity_on_hand)                                        AS tight_bound_units
    FROM       vw_buy_ahead_stock            AS b
    INNER JOIN vw_structural_stock_position  AS p
           ON  p.sku = b.sku AND p.warehouse_code = b.warehouse_code
)

SELECT
    'Buy-ahead positions matched at the closing snapshot'                 AS measure,
    COUNT(*)                                                             AS positions,
    NULL::numeric                                                        AS value_gbp
FROM   matched
UNION ALL
SELECT 'Excess units ordered in the February window',
       NULL, ROUND(SUM(excess_units_ordered), 0)
FROM   matched
UNION ALL
SELECT 'Units issued from those positions since receipt',
       NULL, SUM(units_issued_since_receipt)
FROM   matched
UNION ALL
SELECT 'Closing stock on those positions at 2025-12-28',
       COUNT(*) FILTER (WHERE quantity_on_hand > 0),
       ROUND(SUM(quantity_on_hand * weighted_average_cost_gbp), 0)
FROM   matched
UNION ALL
SELECT 'Loose bound — ignores issues since receipt',
       COUNT(*) FILTER (WHERE loose_bound_units > 0),
       ROUND(SUM(loose_bound_units * weighted_average_cost_gbp), 0)
FROM   matched
UNION ALL
SELECT 'Tight bound — nets off issues since receipt (file 15 method)',
       COUNT(*) FILTER (WHERE tight_bound_units > 0),
       ROUND(SUM(tight_bound_units * weighted_average_cost_gbp), 0)
FROM   matched
UNION ALL
SELECT 'Of the tight bound, also above the policy ceiling',
       NULL,
       ROUND(SUM(LEAST(tight_bound_units, units_above_policy_ceiling)
                 * weighted_average_cost_gbp), 0)
FROM   matched;


\echo '=== 11. What the minimum-order increment bought, netted on one clock ==='

-- File 14 measured the dual-source price gap on 60 SKUs: an annual
-- saving of £492,020 against £604,231 of one-off working capital, net
-- £359,089 at 22%. This section asks the narrower version of the same
-- question using only the minimum-order increment measured above, so
-- the two are related but not the same number and are not additive.
WITH increment AS (
    SELECT
        ROUND(SUM(minimum_increment_units * unit_cost_gbp), 0)           AS bought_2025_gbp,
        ROUND(SUM(minimum_increment_units * unit_cost_gbp) / 2, 0)       AS cycle_stock_level_gbp
    FROM   vw_purchase_quantity_structure
)

SELECT
    'Minimum-order increment bought during 2025 (flow)'                  AS component,
    bought_2025_gbp                                                      AS value_gbp,
    'twelve months of purchasing'                                        AS time_basis
FROM   increment
UNION ALL
SELECT 'Average incremental cycle stock it leaves standing (level)',
       cycle_stock_level_gbp, 'one instant, derived from the flow'
FROM   increment
UNION ALL
SELECT 'Annual holding cost on that level at 22%',
       ROUND(cycle_stock_level_gbp * :holding_rate, 0), 'twelve months'
FROM   increment
UNION ALL
SELECT 'Minimum-order bound in closing stock at 2025-12-28 (level)',
       ROUND(SUM(units_bounded_to_minimum * weighted_average_cost_gbp), 0),
       'one instant, measured directly'
FROM   vw_structural_stock_position;


\echo '=== 12. The twenty positions where the minimum bites hardest ==='

SELECT
    sku,
    category_code,
    warehouse_code,
    last_supplier_type,
    last_quantity_ordered,
    last_minimum_order_quantity,
    reorder_quantity_units,
    last_minimum_increment_units,
    ROUND(last_minimum_order_quantity / NULLIF(weekly_demand_units, 0), 1)
                                                                         AS minimum_in_weeks_of_demand,
    quantity_on_hand,
    ROUND(stock_value_gbp, 0)                                            AS stock_value_gbp,
    cover_weeks,
    ROUND(units_bounded_to_minimum * weighted_average_cost_gbp, 0)       AS value_bounded_to_minimum_gbp,
    last_quoted_lead_days,
    shortest_lead_days
FROM   vw_structural_stock_position
WHERE  last_minimum_binds
ORDER  BY units_bounded_to_minimum * weighted_average_cost_gbp DESC
LIMIT  20;
