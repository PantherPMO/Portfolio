/* ============================================================
   Project    : 02 — Warehouse Inventory & Supply Chain Performance
   File       : 04_analysis/05_stock_cover_versus_demand_trend.sql
   Question   : BQ-03 / AQ-05 — Is stock held where demand is going, or
                where demand has been?
   Finding ID : F-05
   Output     : analysis/query_results/analyse_05_cover_versus_demand_trend.txt
   Author     : Peters
   Created    : 2026-08-23
   ============================================================

   Calderfield Trade Supplies Ltd is fictional and this data is synthetic.

   Grain: one row per SKU per warehouse at the closing snapshot of
   2025-12-28, with demand direction measured across the quarters that
   site actually traded.

   THREE RULES CARRIED IN FROM EARLIER WORK.

   D-17. High cover is NOT the same as excess above policy, and this
   file uses cover only. Livingston holds 129 days of cover while
   breaching its own policy on 4.6% of stock; Bristol breaches its
   policy on 39.8% of stock while holding 51 days. Cover is the measure
   of how much stock there is. Policy excess is the measure of whether
   the site followed its own rules. They are different questions.

   D-18. Where a purchasing constraint is tested, the minimum order
   quantity is that of the supplier ACTUALLY used on the most recent
   receipt, not the nominated primary source. Using the nominated source
   reversed the conclusion in file 04.

   TREND IS DIRECTIONAL EVIDENCE ONLY. Two years gives one
   year-on-year comparison, and Bristol has six quarters rather than
   eight. A slope tells you which way a line has moved. It is not a
   trend estimate and it is not a forecast. Every slope in this file is
   reported with the number of quarters behind it.

   DEMAND, NOT ISSUES. The slope is measured on quantity ordered, not
   quantity issued. Issues are censored by availability: a line that
   stocks out issues less, and measuring the trend on issues would
   record the consequence of a shortage as a fall in demand.

   MECHANISMS ARE TESTED, NOT ASSERTED. Section 5 checks each high-cover
   line against four identifiable mechanisms. A line can match several
   or none. Matching a mechanism is consistent with it, not proof of it.
   ============================================================ */

SET search_path TO supply;

\set snapshot_date '2025-12-28'
\set analysis_date '2025-12-31'
\set holding_rate 0.22


\echo '=== 1. Build: demand direction and current position per SKU and site ==='

DROP VIEW IF EXISTS vw_cover_versus_trend CASCADE;

CREATE VIEW vw_cover_versus_trend AS

WITH quarterly_demand AS (
    -- Demand ordered, not units issued. Cancelled lines are already excluded
    -- by vw_demand_line; nothing else is (D-03).
    SELECT
        d.sku,
        d.warehouse_code,
        TO_CHAR(d.order_date, 'YYYY"Q"Q')                                AS order_quarter,
        -- Sequential index for the regression. Anchored to 2024Q1 so the slope
        -- is comparable across sites even where a site started later.
        (EXTRACT(YEAR FROM d.order_date)::int - 2024) * 4
            + EXTRACT(QUARTER FROM d.order_date)::int                    AS quarter_index,
        SUM(d.demand_units)                                              AS demand_units
    FROM   vw_demand_line AS d
    WHERE  d.order_date <= DATE :'analysis_date'
    GROUP  BY d.sku, d.warehouse_code, order_quarter, quarter_index
),

demand_shape AS (
    SELECT
        sku,
        warehouse_code,
        COUNT(*)                                                         AS quarters_observed,
        SUM(demand_units)                                                AS demand_units_total,
        REGR_SLOPE(demand_units, quarter_index)                          AS units_per_quarter_slope,
        AVG(demand_units)                                                AS mean_quarterly_units,
        MIN(demand_units) FILTER (WHERE quarter_index = 1)               AS first_quarter_units,
        MIN(demand_units) FILTER (WHERE quarter_index = 8)               AS last_quarter_units
    FROM   quarterly_demand
    GROUP  BY sku, warehouse_code
),

last_receipt AS (
    -- The source ACTUALLY used most recently, per D-18.
    SELECT DISTINCT ON (pol.sku, po.warehouse_code)
        pol.sku,
        po.warehouse_code,
        po.supplier_code                                                 AS last_supplier_code,
        s.supplier_type                                                  AS last_supplier_type,
        ps.minimum_order_quantity                                        AS last_source_moq,
        ps.quoted_lead_time_days                                         AS last_source_lead_days
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
    m.sku,
    m.category_code,
    m.category_name,
    m.warehouse_code,
    m.discontinued_date,
    m.quantity_on_hand,
    m.quantity_on_order,
    m.stock_value_gbp,
    m.cover_weeks,
    m.issued_units_13w,
    m.weeks_since_last_issue,
    m.reorder_point_units,
    m.reorder_quantity_units,
    m.policy_age_months,
    m.set_by_buyer,
    ds.quarters_observed,
    ds.demand_units_total,
    ROUND(ds.units_per_quarter_slope::numeric, 2)                        AS units_per_quarter_slope,
    ROUND(ds.mean_quarterly_units::numeric, 1)                           AS mean_quarterly_units,
    -- Slope as a share of the average quarter, so a fall of 40 units means
    -- something different on a line selling 60 a quarter and one selling 6,000.
    ROUND((100.0 * ds.units_per_quarter_slope
           / NULLIF(ds.mean_quarterly_units, 0))::numeric, 1)            AS slope_pct_of_mean_quarter,
    lr.last_supplier_code,
    lr.last_supplier_type,
    lr.last_source_moq,
    lr.last_source_lead_days,
    -- The policy's own ceiling expressed in weeks of current demand. This is
    -- how deep the site's rules authorise stock to go, independent of whether
    -- the rules were followed.
    ROUND((m.reorder_point_units + m.reorder_quantity_units)
          / NULLIF(m.issued_units_13w::numeric / 13, 0), 1)              AS policy_ceiling_weeks_cover,
    -- One purchase from the source actually used, expressed in weeks of demand.
    ROUND(lr.last_source_moq
          / NULLIF(m.issued_units_13w::numeric / 13, 0), 1)              AS moq_weeks_of_demand,
    CASE WHEN ds.units_per_quarter_slope IS NULL                    THEN 'insufficient quarters'
         WHEN ds.mean_quarterly_units = 0                           THEN 'no demand'
         WHEN (100.0 * ds.units_per_quarter_slope
               / NULLIF(ds.mean_quarterly_units, 0))::numeric >=  5  THEN 'rising'
         WHEN (100.0 * ds.units_per_quarter_slope
               / NULLIF(ds.mean_quarterly_units, 0))::numeric <= -5  THEN 'falling'
         ELSE                                                             'broadly flat'
    END                                                                  AS demand_direction,
    CASE WHEN m.quantity_on_hand = 0     THEN '0 — no stock'
         WHEN m.cover_weeks IS NULL      THEN '5 — no demand in 13 weeks'
         WHEN m.cover_weeks <= 8         THEN '1 — under 2 months'
         WHEN m.cover_weeks <= 26        THEN '2 — 2 to 6 months'
         WHEN m.cover_weeks <= 52        THEN '3 — 6 to 12 months'
         ELSE                                 '4 — over 12 months'
    END                                                                  AS cover_band
FROM       mv_inventory_week AS m
LEFT JOIN  demand_shape      AS ds ON ds.sku = m.sku AND ds.warehouse_code = m.warehouse_code
LEFT JOIN  last_receipt      AS lr ON lr.sku = m.sku AND lr.warehouse_code = m.warehouse_code
WHERE      m.week_ending_date = DATE :'snapshot_date';


SELECT
    'Stocked lines at 2025-12-28'                                        AS measure,
    COUNT(*)                                                             AS lines,
    NULL::numeric                                                        AS stock_value_gbp
FROM   vw_cover_versus_trend
UNION ALL
SELECT 'With a measurable demand slope', COUNT(*) FILTER (WHERE units_per_quarter_slope IS NOT NULL), NULL
FROM   vw_cover_versus_trend
UNION ALL
SELECT 'With a cover figure (issued in the last 13 weeks)',
       COUNT(*) FILTER (WHERE cover_weeks IS NOT NULL), NULL
FROM   vw_cover_versus_trend
UNION ALL
SELECT 'Cover over 6 months', COUNT(*) FILTER (WHERE cover_weeks > 26),
       ROUND(SUM(stock_value_gbp) FILTER (WHERE cover_weeks > 26), 0)
FROM   vw_cover_versus_trend
UNION ALL
SELECT 'Cover over 12 months', COUNT(*) FILTER (WHERE cover_weeks > 52),
       ROUND(SUM(stock_value_gbp) FILTER (WHERE cover_weeks > 52), 0)
FROM   vw_cover_versus_trend;


\echo '=== 2. Quarters observed per site — what the slope rests on ==='

-- Bristol traded from 2024-07-01, so its slope has six quarters against eight
-- elsewhere. Its lines are not comparable on slope magnitude and are reported
-- separately wherever that matters.
SELECT
    warehouse_code,
    quarters_observed,
    COUNT(*)                                                             AS lines,
    ROUND(SUM(stock_value_gbp), 0)                                       AS stock_value_gbp
FROM   vw_cover_versus_trend
GROUP  BY warehouse_code, quarters_observed
ORDER  BY warehouse_code, quarters_observed;


\echo '=== 3. The alignment matrix: cover against demand direction ==='

-- The question the file exists to answer. Stock sitting deep on falling demand
-- is capital committed against a receding requirement; thin stock on rising
-- demand is the reverse. Both are misalignment.
SELECT
    cover_band,
    COUNT(*) FILTER (WHERE demand_direction = 'rising')                  AS n_rising,
    COUNT(*) FILTER (WHERE demand_direction = 'broadly flat')            AS n_flat,
    COUNT(*) FILTER (WHERE demand_direction = 'falling')                 AS n_falling,
    ROUND(SUM(stock_value_gbp) FILTER (WHERE demand_direction = 'rising'), 0)
                                                                         AS stock_rising_gbp,
    ROUND(SUM(stock_value_gbp) FILTER (WHERE demand_direction = 'broadly flat'), 0)
                                                                         AS stock_flat_gbp,
    ROUND(SUM(stock_value_gbp) FILTER (WHERE demand_direction = 'falling'), 0)
                                                                         AS stock_falling_gbp
FROM   vw_cover_versus_trend
GROUP  BY cover_band
ORDER  BY cover_band;


\echo '=== 4. The two misalignment quadrants, quantified ==='

WITH quadrant AS (
    SELECT
        CASE WHEN cover_weeks > 26  AND demand_direction = 'falling'
                  THEN 'Deep stock on falling demand'
             WHEN cover_weeks <= 8  AND demand_direction = 'rising'
                  THEN 'Thin stock on rising demand'
             WHEN cover_weeks > 26  AND demand_direction = 'rising'
                  THEN 'Deep stock on rising demand'
             WHEN cover_weeks <= 8  AND demand_direction = 'falling'
                  THEN 'Thin stock on falling demand'
             ELSE 'Neither extreme'
        END                                                              AS quadrant,
        stock_value_gbp,
        cover_weeks,
        quantity_on_hand
    FROM   vw_cover_versus_trend
    WHERE  cover_weeks IS NOT NULL
      AND  demand_direction IN ('rising', 'falling', 'broadly flat')
)

SELECT
    quadrant,
    COUNT(*)                                                             AS lines,
    ROUND(SUM(stock_value_gbp), 0)                                       AS stock_value_gbp,
    ROUND(100.0 * SUM(stock_value_gbp) / SUM(SUM(stock_value_gbp)) OVER (), 1)
                                                                         AS share_of_stock_pct,
    ROUND(AVG(cover_weeks), 1)                                           AS mean_cover_weeks,
    ROUND(SUM(stock_value_gbp) * :holding_rate, 0)                       AS holding_cost_gbp
FROM   quadrant
GROUP  BY quadrant
ORDER  BY stock_value_gbp DESC;


\echo '=== 5. What explains the high-cover lines? ==='

-- Four identifiable mechanisms, each measurable from the data. A line can match
-- several, so the columns do not sum to the row count. Matching is consistent
-- with a mechanism, not proof of it — nothing here establishes cause.
WITH high_cover AS (
    SELECT
        v.*,
        -- Slow: trailing demand in the bottom quarter of all stocked lines.
        v.issued_units_13w <= (SELECT PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY issued_units_13w)
                               FROM vw_cover_versus_trend)               AS is_slow_demand,
        v.demand_direction = 'falling'                                   AS is_falling_demand,
        -- The site's own rules authorise more than six months of cover.
        v.policy_ceiling_weeks_cover > 26                                AS is_policy_authorised,
        -- One purchase from the source actually used buys over a quarter's trade.
        v.moq_weeks_of_demand > 13                                       AS is_moq_constrained
    FROM   vw_cover_versus_trend AS v
    WHERE  v.cover_weeks > 26
)

SELECT
    'Lines with cover over 6 months'                                     AS mechanism,
    COUNT(*)                                                             AS lines,
    ROUND(SUM(stock_value_gbp), 0)                                       AS stock_value_gbp,
    NULL::numeric                                                        AS share_of_high_cover_pct
FROM   high_cover
UNION ALL
SELECT 'Slow demand (bottom quartile of trailing demand)',
       COUNT(*) FILTER (WHERE is_slow_demand),
       ROUND(SUM(stock_value_gbp) FILTER (WHERE is_slow_demand), 0),
       ROUND(100.0 * COUNT(*) FILTER (WHERE is_slow_demand) / COUNT(*), 1)
FROM   high_cover
UNION ALL
SELECT 'Falling demand',
       COUNT(*) FILTER (WHERE is_falling_demand),
       ROUND(SUM(stock_value_gbp) FILTER (WHERE is_falling_demand), 0),
       ROUND(100.0 * COUNT(*) FILTER (WHERE is_falling_demand) / COUNT(*), 1)
FROM   high_cover
UNION ALL
SELECT 'Policy ceiling itself authorises over 6 months',
       COUNT(*) FILTER (WHERE is_policy_authorised),
       ROUND(SUM(stock_value_gbp) FILTER (WHERE is_policy_authorised), 0),
       ROUND(100.0 * COUNT(*) FILTER (WHERE is_policy_authorised) / COUNT(*), 1)
FROM   high_cover
UNION ALL
SELECT 'Minimum order quantity over a quarter of demand',
       COUNT(*) FILTER (WHERE is_moq_constrained),
       ROUND(SUM(stock_value_gbp) FILTER (WHERE is_moq_constrained), 0),
       ROUND(100.0 * COUNT(*) FILTER (WHERE is_moq_constrained) / COUNT(*), 1)
FROM   high_cover
UNION ALL
SELECT 'Matches none of the four',
       COUNT(*) FILTER (WHERE NOT is_slow_demand AND NOT is_falling_demand
                          AND NOT COALESCE(is_policy_authorised, false)
                          AND NOT COALESCE(is_moq_constrained, false)),
       ROUND(SUM(stock_value_gbp) FILTER (WHERE NOT is_slow_demand AND NOT is_falling_demand
                          AND NOT COALESCE(is_policy_authorised, false)
                          AND NOT COALESCE(is_moq_constrained, false)), 0),
       ROUND(100.0 * COUNT(*) FILTER (WHERE NOT is_slow_demand AND NOT is_falling_demand
                          AND NOT COALESCE(is_policy_authorised, false)
                          AND NOT COALESCE(is_moq_constrained, false)) / COUNT(*), 1)
FROM   high_cover;


\echo '=== 6. High cover by site, with the mechanisms present at each ==='

WITH high_cover AS (
    SELECT
        v.warehouse_code,
        v.stock_value_gbp,
        v.cover_weeks,
        v.issued_units_13w <= (SELECT PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY issued_units_13w)
                               FROM vw_cover_versus_trend)               AS is_slow_demand,
        v.demand_direction = 'falling'                                   AS is_falling_demand,
        v.policy_ceiling_weeks_cover > 26                                AS is_policy_authorised,
        v.moq_weeks_of_demand > 13                                       AS is_moq_constrained
    FROM   vw_cover_versus_trend AS v
    WHERE  v.cover_weeks > 26
)

SELECT
    warehouse_code,
    COUNT(*)                                                             AS high_cover_lines,
    ROUND(SUM(stock_value_gbp), 0)                                       AS high_cover_stock_gbp,
    ROUND(AVG(cover_weeks), 1)                                           AS mean_cover_weeks,
    COUNT(*) FILTER (WHERE is_slow_demand)                               AS n_slow_demand,
    COUNT(*) FILTER (WHERE is_falling_demand)                            AS n_falling_demand,
    COUNT(*) FILTER (WHERE is_policy_authorised)                         AS n_policy_authorised,
    COUNT(*) FILTER (WHERE is_moq_constrained)                           AS n_moq_constrained
FROM   high_cover
GROUP  BY warehouse_code
ORDER  BY high_cover_stock_gbp DESC;


\echo '=== 7. Demand direction by category, with n ==='

SELECT
    category_code,
    category_name,
    COUNT(*)                                                             AS lines,
    COUNT(*) FILTER (WHERE demand_direction = 'rising')                  AS n_rising,
    COUNT(*) FILTER (WHERE demand_direction = 'broadly flat')            AS n_flat,
    COUNT(*) FILTER (WHERE demand_direction = 'falling')                 AS n_falling,
    ROUND(AVG(slope_pct_of_mean_quarter)
          FILTER (WHERE slope_pct_of_mean_quarter IS NOT NULL), 1)       AS mean_slope_pct_of_quarter,
    ROUND(AVG(cover_weeks) FILTER (WHERE cover_weeks IS NOT NULL), 1)    AS mean_cover_weeks
FROM   vw_cover_versus_trend
GROUP  BY category_code, category_name
ORDER  BY mean_slope_pct_of_quarter DESC NULLS LAST;


\echo '=== 8. The twenty deepest positions on falling demand ==='

SELECT
    sku,
    category_code,
    warehouse_code,
    quarters_observed,
    quantity_on_hand,
    ROUND(stock_value_gbp, 0)                                            AS stock_value_gbp,
    cover_weeks,
    slope_pct_of_mean_quarter,
    policy_ceiling_weeks_cover,
    last_supplier_type,
    moq_weeks_of_demand,
    policy_age_months,
    discontinued_date
FROM   vw_cover_versus_trend
WHERE  cover_weeks > 26
  AND  demand_direction = 'falling'
ORDER  BY stock_value_gbp DESC
LIMIT  20;


\echo '=== 9. The twenty thinnest positions on rising demand ==='

SELECT
    sku,
    category_code,
    warehouse_code,
    quarters_observed,
    quantity_on_hand,
    ROUND(stock_value_gbp, 0)                                            AS stock_value_gbp,
    cover_weeks,
    slope_pct_of_mean_quarter,
    reorder_point_units,
    issued_units_13w,
    weeks_since_last_issue,
    policy_age_months
FROM   vw_cover_versus_trend
WHERE  cover_weeks <= 8
  AND  demand_direction = 'rising'
ORDER  BY demand_units_total DESC
LIMIT  20;
