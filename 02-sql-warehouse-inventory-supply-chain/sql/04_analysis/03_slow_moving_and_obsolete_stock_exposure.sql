/* ============================================================
   Project    : 02 — Warehouse Inventory & Supply Chain Performance
   File       : 04_analysis/03_slow_moving_and_obsolete_stock_exposure.sql
   Question   : BQ-02 / AQ-03 — How much cash is sitting in stock that is
                barely moving, and where is it?
   Finding ID : F-03
   Output     : analysis/query_results/analyse_03_slow_moving_exposure.txt
   Author     : Peters
   Created    : 2026-08-23
   ============================================================

   Calderfield Trade Supplies Ltd is fictional and this data is synthetic.

   Grain: one row per SKU per warehouse, as at the closing snapshot of
   2025-12-28. Slow movement is a position at a site, not a property of
   a product — the same SKU can turn well at Warrington and sit still at
   Livingston, and that difference is the finding.

   Two measures, deliberately kept apart:

     Age    weeks since the line last issued to a customer
     Cover  weeks of stock at the trailing 13-week rate

   Age catches stock that has stopped moving entirely. Cover catches
   stock that is still moving but far too deep.

   The two are complementary by construction, not independent, and
   section 3 proves it. Cover is measured against trailing 13-week
   demand, so a line that has not issued inside that window has no
   cover figure at all. Age is therefore the only measure available for
   stopped lines, and cover the only useful one for moving lines. They
   partition the range rather than overlapping it, and a slow-moving
   total built by adding them without checking would be right only by
   accident. See docs/DECISIONS.md D-16.

   LIMITATION. The dataset runs 104 weeks. "No movement in 104 weeks"
   means at least two years and cannot mean more, because there is no
   more. Obsolescence findings are floors, not measurements.

   Discontinued products are included, not filtered out. Stock of a
   superseded line is the clearest obsolescence exposure there is.
   ============================================================ */

SET search_path TO supply;

\set snapshot_date '2025-12-28'
\set holding_rate 0.22
\set holding_rate_low 0.20
\set holding_rate_high 0.25


\echo '=== 1. Closing position by age band ==='

DROP VIEW IF EXISTS vw_closing_position CASCADE;

CREATE VIEW vw_closing_position AS

SELECT
    m.sku,
    m.product_name,
    m.category_code,
    m.category_name,
    m.warehouse_code,
    m.discontinued_date,
    m.quantity_on_hand,
    m.weighted_average_cost_gbp,
    m.stock_value_gbp,
    m.issued_units_13w,
    m.issued_cost_13w_gbp,
    m.cover_weeks,
    m.last_issue_week,
    m.weeks_since_last_issue,
    m.reorder_point_units,
    m.reorder_quantity_units,
    m.policy_age_months,
    m.set_by_buyer,
    -- Age bands. NULL weeks_since_last_issue means the line never issued at
    -- this site inside the two-year window, which is the oldest band there is.
    CASE WHEN m.quantity_on_hand = 0                    THEN '0 — no stock held'
         WHEN m.weeks_since_last_issue IS NULL          THEN '5 — no issue in the period'
         -- 12, not 13: the trailing window is 12 preceding rows plus the
         -- current one, so a line last issued 13 weeks ago sits outside it and
         -- has no cover figure. Aligning the boundaries keeps the two measures
         -- consistent with each other.
         WHEN m.weeks_since_last_issue <= 12            THEN '1 — issued in the last 13 weeks'
         WHEN m.weeks_since_last_issue <= 26            THEN '2 — 13 to 26 weeks'
         WHEN m.weeks_since_last_issue <= 52            THEN '3 — 27 to 52 weeks'
         ELSE                                                '4 — over 52 weeks'
    END                                                                  AS age_band,
    CASE WHEN m.quantity_on_hand = 0                    THEN '0 — no stock held'
         WHEN m.cover_weeks IS NULL                     THEN '6 — no demand to measure against'
         WHEN m.cover_weeks <= 8                        THEN '1 — under 2 months'
         WHEN m.cover_weeks <= 17                       THEN '2 — 2 to 4 months'
         WHEN m.cover_weeks <= 26                       THEN '3 — 4 to 6 months'
         WHEN m.cover_weeks <= 52                        THEN '4 — 6 to 12 months'
         ELSE                                                '5 — over 12 months'
    END                                                                  AS cover_band
FROM   mv_inventory_week AS m
WHERE  m.week_ending_date = DATE :'snapshot_date';


SELECT
    age_band,
    COUNT(*)                                                             AS stocked_lines,
    SUM(quantity_on_hand)                                                AS units_held,
    ROUND(SUM(stock_value_gbp), 0)                                       AS stock_value_gbp,
    ROUND(100.0 * SUM(stock_value_gbp) / SUM(SUM(stock_value_gbp)) OVER (), 1)
                                                                         AS share_of_stock_pct,
    ROUND(SUM(stock_value_gbp) * :holding_rate, 0)                       AS holding_cost_gbp,
    ROUND(SUM(stock_value_gbp) * :holding_rate_low, 0)                   AS holding_cost_low_gbp,
    ROUND(SUM(stock_value_gbp) * :holding_rate_high, 0)                  AS holding_cost_high_gbp
FROM   vw_closing_position
GROUP  BY age_band
ORDER  BY age_band;


\echo '=== 2. Closing position by cover band ==='

SELECT
    cover_band,
    COUNT(*)                                                             AS stocked_lines,
    ROUND(SUM(stock_value_gbp), 0)                                       AS stock_value_gbp,
    ROUND(100.0 * SUM(stock_value_gbp) / SUM(SUM(stock_value_gbp)) OVER (), 1)
                                                                         AS share_of_stock_pct,
    ROUND(SUM(stock_value_gbp) * :holding_rate, 0)                       AS holding_cost_gbp,
    ROUND(AVG(cover_weeks), 1)                                           AS mean_cover_weeks
FROM   vw_closing_position
GROUP  BY cover_band
ORDER  BY cover_band;


\echo '=== 3. Do the two measures find the same stock? ==='

-- Expected result: everything with a cover figure sits in age band 1, and every
-- older band sits entirely in "no demand to measure against". That is not a
-- coincidence — it is what the 13-week cover window forces. The cross-tab is
-- kept because it is the proof, and because it stops anyone adding the two
-- populations together and double-counting.
SELECT
    age_band,
    ROUND(SUM(stock_value_gbp) FILTER (WHERE cover_band = '1 — under 2 months'), 0)
                                                                         AS cover_under_2m_gbp,
    ROUND(SUM(stock_value_gbp) FILTER (WHERE cover_band = '2 — 2 to 4 months'), 0)
                                                                         AS cover_2_to_4m_gbp,
    ROUND(SUM(stock_value_gbp) FILTER (WHERE cover_band = '3 — 4 to 6 months'), 0)
                                                                         AS cover_4_to_6m_gbp,
    ROUND(SUM(stock_value_gbp) FILTER (WHERE cover_band = '4 — 6 to 12 months'), 0)
                                                                         AS cover_6_to_12m_gbp,
    ROUND(SUM(stock_value_gbp) FILTER (WHERE cover_band = '5 — over 12 months'), 0)
                                                                         AS cover_over_12m_gbp,
    ROUND(SUM(stock_value_gbp) FILTER (WHERE cover_band = '6 — no demand to measure against'), 0)
                                                                         AS no_demand_gbp
FROM   vw_closing_position
GROUP  BY age_band
ORDER  BY age_band;


\echo '=== 4. Slow-moving exposure by site ==='

-- "Slow" here means either no issue for over 26 weeks, or more than 12 months
-- of cover. A line failing either test is stock the business is financing
-- without a matching rate of trade.
SELECT
    warehouse_code,
    COUNT(*)                                                             AS stocked_lines,
    ROUND(SUM(stock_value_gbp), 0)                                       AS stock_value_gbp,
    COUNT(*) FILTER (WHERE age_band IN ('3 — 27 to 52 weeks', '4 — over 52 weeks',
                                        '5 — no issue in the period')
                        OR cover_band = '5 — over 12 months')            AS slow_lines,
    ROUND(SUM(stock_value_gbp) FILTER (WHERE age_band IN ('3 — 27 to 52 weeks',
                                                          '4 — over 52 weeks',
                                                          '5 — no issue in the period')
                                          OR cover_band = '5 — over 12 months'), 0)
                                                                         AS slow_stock_gbp,
    ROUND(100.0 * SUM(stock_value_gbp) FILTER (WHERE age_band IN ('3 — 27 to 52 weeks',
                                                                  '4 — over 52 weeks',
                                                                  '5 — no issue in the period')
                                                  OR cover_band = '5 — over 12 months')
          / NULLIF(SUM(stock_value_gbp), 0), 1)                          AS slow_share_pct,
    ROUND(SUM(stock_value_gbp) FILTER (WHERE age_band IN ('3 — 27 to 52 weeks',
                                                          '4 — over 52 weeks',
                                                          '5 — no issue in the period')
                                          OR cover_band = '5 — over 12 months')
          * :holding_rate, 0)                                            AS slow_holding_cost_gbp
FROM   vw_closing_position
GROUP  BY warehouse_code
ORDER  BY slow_share_pct DESC;


\echo '=== 5. Slow-moving exposure by category ==='

SELECT
    category_code,
    category_name,
    COUNT(*)                                                             AS stocked_lines,
    ROUND(SUM(stock_value_gbp), 0)                                       AS stock_value_gbp,
    ROUND(SUM(stock_value_gbp) FILTER (WHERE age_band IN ('3 — 27 to 52 weeks',
                                                          '4 — over 52 weeks',
                                                          '5 — no issue in the period')
                                          OR cover_band = '5 — over 12 months'), 0)
                                                                         AS slow_stock_gbp,
    ROUND(100.0 * SUM(stock_value_gbp) FILTER (WHERE age_band IN ('3 — 27 to 52 weeks',
                                                                  '4 — over 52 weeks',
                                                                  '5 — no issue in the period')
                                                  OR cover_band = '5 — over 12 months')
          / NULLIF(SUM(stock_value_gbp), 0), 1)                          AS slow_share_pct,
    ROUND(AVG(cover_weeks), 1)                                           AS mean_cover_weeks
FROM   vw_closing_position
GROUP  BY category_code, category_name
ORDER  BY slow_stock_gbp DESC;


\echo '=== 6. Discontinued products still holding stock ==='

-- The clearest obsolescence exposure in the dataset: a product the business has
-- stopped selling, with stock still on the shelf and cash still in it.
SELECT
    COUNT(DISTINCT sku)                                                  AS discontinued_skus,
    COUNT(*) FILTER (WHERE quantity_on_hand > 0)                         AS site_positions_with_stock,
    SUM(quantity_on_hand)                                                AS units_held,
    ROUND(SUM(stock_value_gbp), 0)                                       AS stock_value_gbp,
    ROUND(SUM(stock_value_gbp) * :holding_rate, 0)                       AS holding_cost_gbp,
    ROUND(AVG(DATE :'snapshot_date' - discontinued_date), 0)             AS mean_days_since_discontinued
FROM   vw_closing_position
WHERE  discontinued_date IS NOT NULL;


SELECT
    sku,
    category_code,
    warehouse_code,
    discontinued_date,
    quantity_on_hand,
    ROUND(stock_value_gbp, 0)                                            AS stock_value_gbp,
    weeks_since_last_issue,
    cover_weeks
FROM   vw_closing_position
WHERE  discontinued_date IS NOT NULL
  AND  quantity_on_hand > 0
ORDER  BY stock_value_gbp DESC
LIMIT  15;


\echo '=== 7. The twenty largest slow-moving positions ==='

SELECT
    sku,
    category_code,
    warehouse_code,
    quantity_on_hand,
    ROUND(stock_value_gbp, 0)                                            AS stock_value_gbp,
    issued_units_13w,
    cover_weeks,
    weeks_since_last_issue,
    reorder_point_units,
    reorder_quantity_units,
    policy_age_months,
    discontinued_date
FROM   vw_closing_position
WHERE  age_band IN ('3 — 27 to 52 weeks', '4 — over 52 weeks', '5 — no issue in the period')
   OR  cover_band = '5 — over 12 months'
ORDER  BY stock_value_gbp DESC
LIMIT  20;


\echo '=== 8. Totals, with the sensitivity band ==='

WITH exposure AS (
    SELECT
        SUM(stock_value_gbp)                                             AS total_stock_gbp,
        SUM(stock_value_gbp) FILTER (WHERE age_band IN ('3 — 27 to 52 weeks',
                                                        '4 — over 52 weeks',
                                                        '5 — no issue in the period')
                                        OR cover_band = '5 — over 12 months')
                                                                         AS slow_stock_gbp,
        SUM(stock_value_gbp) FILTER (WHERE age_band IN ('4 — over 52 weeks',
                                                        '5 — no issue in the period'))
                                                                         AS no_movement_52w_gbp,
        SUM(stock_value_gbp) FILTER (WHERE cover_band = '5 — over 12 months')
                                                                         AS over_12m_cover_gbp,
        SUM(stock_value_gbp) FILTER (WHERE discontinued_date IS NOT NULL) AS discontinued_gbp
    FROM   vw_closing_position
)

SELECT
    ROUND(total_stock_gbp, 0)                                            AS closing_stock_gbp,
    ROUND(slow_stock_gbp, 0)                                             AS slow_moving_gbp,
    ROUND(100.0 * slow_stock_gbp / NULLIF(total_stock_gbp, 0), 1)        AS slow_share_pct,
    ROUND(no_movement_52w_gbp, 0)                                        AS no_movement_over_52w_gbp,
    ROUND(over_12m_cover_gbp, 0)                                         AS cover_over_12_months_gbp,
    ROUND(discontinued_gbp, 0)                                           AS discontinued_stock_gbp,
    ROUND(slow_stock_gbp * :holding_rate_low, 0)                         AS holding_cost_at_20pct_gbp,
    ROUND(slow_stock_gbp * :holding_rate, 0)                             AS holding_cost_at_22pct_gbp,
    ROUND(slow_stock_gbp * :holding_rate_high, 0)                        AS holding_cost_at_25pct_gbp
FROM   exposure;
