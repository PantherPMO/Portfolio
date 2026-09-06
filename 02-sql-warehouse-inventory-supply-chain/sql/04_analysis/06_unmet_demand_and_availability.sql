/* ============================================================
   Project    : 02 — Warehouse Inventory & Supply Chain Performance
   File       : 04_analysis/06_unmet_demand_and_availability.sql
   Question   : BQ-04 / AQ-06 — What is poor availability costing, and
                do the three ways of measuring it agree?
   Finding ID : F-06
   Output     : analysis/query_results/analyse_06_unmet_demand_availability.txt
   Author     : Peters
   Created    : 2026-08-23
   ============================================================

   Calderfield Trade Supplies Ltd is fictional and this data is synthetic.

   THREE MEASURES, AND THEY ARE NOT INTERCHANGEABLE.

   1. Weeks closing at zero
      quantity_on_hand = 0 at the Sunday snapshot.
      Counts stockouts that survived to the end of the week. Understates:
      a shortage that cleared on Thursday is invisible.

   2. Weeks containing a zero-stock day
      days_at_zero_in_week > 0, taken from the daily state.
      Catches shortages the weekly snapshot misses. Still says nothing
      about whether anyone tried to buy during them.

   3. Unmet order lines and units
      quantity_ordered - quantity_despatched on vw_demand_line.
      The commercial measure: demand the business had and could not
      supply. This is the only one denominated in customers and pounds.

   A line can be at zero all week and cost nothing if nobody asked for
   it. A line can be in stock every Sunday and still short-ship on a
   Wednesday. Reporting a single "stockout rate" would hide both, so all
   three are carried together and the gaps between them are examined
   rather than smoothed over.

   Demand excludes only cancelled lines. Fulfilment is read from
   quantities, never from line_status — a return overwrites the status
   and would silently drop the line (D-03).

   Cover is used as the stock-depth measure, not excess above policy,
   which measures conformance rather than adequacy (D-17).
   ============================================================ */

SET search_path TO supply;

\set analysis_year 2025
\set snapshot_date '2025-12-28'


\echo '=== 1. The three measures at network level, 2025 ==='

WITH snapshot_side AS (
    SELECT
        COUNT(*)                                                         AS sku_weeks,
        COUNT(*) FILTER (WHERE quantity_on_hand = 0)                     AS weeks_closing_at_zero,
        COUNT(*) FILTER (WHERE days_at_zero_in_week > 0)                 AS weeks_with_a_zero_day,
        SUM(days_at_zero_in_week)                                        AS zero_days_total
    FROM   mv_inventory_week
    WHERE  year = :analysis_year
),

demand_side AS (
    SELECT
        COUNT(*)                                                         AS demand_lines,
        COUNT(*) FILTER (WHERE unmet_units > 0)                          AS lines_not_supplied_in_full,
        COUNT(*) FILTER (WHERE supplied_units = 0)                       AS lines_wholly_unsupplied,
        SUM(demand_units)                                                AS demand_units,
        SUM(unmet_units)                                                 AS unmet_units,
        SUM(unmet_value_gbp)                                             AS unmet_value_gbp
    FROM   vw_demand_line
    WHERE  order_date BETWEEN DATE '2025-01-01' AND DATE '2025-12-31'
)

SELECT
    'Weeks closing at zero'                                              AS measure,
    s.weeks_closing_at_zero                                              AS count,
    s.sku_weeks                                                          AS denominator,
    ROUND(100.0 * s.weeks_closing_at_zero / s.sku_weeks, 2)              AS rate_pct,
    'SKU-weeks with no stock at the Sunday snapshot'                     AS what_it_measures
FROM   snapshot_side AS s
UNION ALL
SELECT 'Weeks containing a zero-stock day', s.weeks_with_a_zero_day, s.sku_weeks,
       ROUND(100.0 * s.weeks_with_a_zero_day / s.sku_weeks, 2),
       'SKU-weeks in which the site closed at zero on at least one day'
FROM   snapshot_side AS s
UNION ALL
SELECT 'Order lines not supplied in full', d.lines_not_supplied_in_full, d.demand_lines,
       ROUND(100.0 * d.lines_not_supplied_in_full / d.demand_lines, 2),
       'Customer order lines short-shipped or wholly unsupplied'
FROM   demand_side AS d
UNION ALL
SELECT 'Order lines wholly unsupplied', d.lines_wholly_unsupplied, d.demand_lines,
       ROUND(100.0 * d.lines_wholly_unsupplied / d.demand_lines, 2),
       'Customer order lines that received nothing at all'
FROM   demand_side AS d
UNION ALL
SELECT 'Units not supplied', d.unmet_units, d.demand_units,
       ROUND(100.0 * d.unmet_units / d.demand_units, 2),
       'Units ordered that were never despatched'
FROM   demand_side AS d;


\echo '=== 2. The gap between the snapshot measure and the daily measure ==='

-- Direct evidence for why a weekly snapshot alone is not enough. Every week in
-- the second column but not the first is a stockout that cleared before Sunday.
SELECT
    warehouse_code,
    COUNT(*)                                                             AS sku_weeks,
    COUNT(*) FILTER (WHERE quantity_on_hand = 0)                         AS weeks_closing_at_zero,
    COUNT(*) FILTER (WHERE days_at_zero_in_week > 0)                     AS weeks_with_a_zero_day,
    COUNT(*) FILTER (WHERE days_at_zero_in_week > 0 AND quantity_on_hand > 0)
                                                                         AS zero_cleared_before_sunday,
    ROUND(100.0 * COUNT(*) FILTER (WHERE quantity_on_hand = 0) / COUNT(*), 2)
                                                                         AS closing_zero_rate_pct,
    ROUND(100.0 * COUNT(*) FILTER (WHERE days_at_zero_in_week > 0) / COUNT(*), 2)
                                                                         AS any_zero_day_rate_pct,
    ROUND(100.0 * COUNT(*) FILTER (WHERE days_at_zero_in_week > 0) / COUNT(*)
          / NULLIF(100.0 * COUNT(*) FILTER (WHERE quantity_on_hand = 0) / COUNT(*), 0), 2)
                                                                         AS understatement_factor
FROM   mv_inventory_week
WHERE  year = :analysis_year
GROUP  BY warehouse_code
ORDER  BY any_zero_day_rate_pct DESC;


\echo '=== 3. All three measures by site, side by side ==='

WITH stock_side AS (
    SELECT
        warehouse_code,
        COUNT(*)                                                         AS sku_weeks,
        ROUND(100.0 * COUNT(*) FILTER (WHERE quantity_on_hand = 0) / COUNT(*), 2)
                                                                         AS closing_zero_rate_pct,
        ROUND(100.0 * COUNT(*) FILTER (WHERE days_at_zero_in_week > 0) / COUNT(*), 2)
                                                                         AS any_zero_day_rate_pct,
        ROUND(AVG(cover_weeks) FILTER (WHERE cover_weeks IS NOT NULL), 1) AS mean_cover_weeks
    FROM   mv_inventory_week
    WHERE  year = :analysis_year
    GROUP  BY warehouse_code
),

demand_side AS (
    SELECT
        warehouse_code,
        COUNT(*)                                                         AS demand_lines,
        ROUND(100.0 * COUNT(*) FILTER (WHERE unmet_units = 0) / COUNT(*), 2)
                                                                         AS line_fill_rate_pct,
        ROUND(100.0 * SUM(supplied_units) / NULLIF(SUM(demand_units), 0), 2)
                                                                         AS unit_fill_rate_pct,
        SUM(unmet_units)                                                 AS unmet_units,
        ROUND(SUM(unmet_value_gbp), 0)                                   AS unmet_value_gbp
    FROM   vw_demand_line
    WHERE  order_date BETWEEN DATE '2025-01-01' AND DATE '2025-12-31'
    GROUP  BY warehouse_code
)

SELECT
    s.warehouse_code,
    s.mean_cover_weeks,
    s.closing_zero_rate_pct,
    s.any_zero_day_rate_pct,
    d.demand_lines,
    d.line_fill_rate_pct,
    d.unit_fill_rate_pct,
    d.unmet_units,
    d.unmet_value_gbp
FROM       stock_side  AS s
INNER JOIN demand_side AS d ON d.warehouse_code = s.warehouse_code
ORDER  BY  d.line_fill_rate_pct;


\echo '=== 4. Does deeper stock buy better availability? ==='

-- The alignment test. Cover is taken from the PRIOR week, not the current one:
-- cover measured in the week of a stockout is zero by definition, so using it
-- would test the shortage against itself.
WITH weekly_position AS (
    SELECT
        warehouse_code,
        sku,
        week_ending_date,
        demand_units,
        unmet_units,
        unmet_value_gbp,
        LAG(cover_weeks) OVER (PARTITION BY sku, warehouse_code
                               ORDER BY week_ending_date)                AS prior_week_cover
    FROM   mv_inventory_week
),

banded AS (
    SELECT
        CASE WHEN prior_week_cover IS NULL   THEN '6 — no cover figure'
             WHEN prior_week_cover <  2      THEN '1 — under 2 weeks'
             WHEN prior_week_cover <  4      THEN '2 — 2 to 4 weeks'
             WHEN prior_week_cover <  8      THEN '3 — 4 to 8 weeks'
             WHEN prior_week_cover < 26      THEN '4 — 2 to 6 months'
             ELSE                                 '5 — over 6 months'
        END                                                              AS prior_cover_band,
        demand_units,
        unmet_units,
        unmet_value_gbp
    FROM   weekly_position
    WHERE  week_ending_date >= DATE '2025-01-01'
      AND  demand_units > 0
)

SELECT
    prior_cover_band,
    COUNT(*)                                                             AS sku_weeks_with_demand,
    SUM(demand_units)                                                    AS demand_units,
    SUM(unmet_units)                                                     AS unmet_units,
    ROUND(100.0 * SUM(unmet_units) / NULLIF(SUM(demand_units), 0), 2)    AS unmet_unit_rate_pct,
    ROUND(100.0 * COUNT(*) FILTER (WHERE unmet_units > 0) / COUNT(*), 2) AS weeks_with_shortfall_pct,
    ROUND(SUM(unmet_value_gbp), 0)                                       AS unmet_value_gbp
FROM   banded
GROUP  BY prior_cover_band
ORDER  BY prior_cover_band;


\echo '=== 5. The exceptions: where cover and availability disagree ==='

-- If cover explained availability completely, every site would sit on the same
-- curve. It does not, and the residual is where the site-specific mechanisms
-- live. Reported by site so the exceptions are attributable.
WITH weekly_position AS (
    SELECT
        warehouse_code,
        sku,
        week_ending_date,
        demand_units,
        unmet_units,
        LAG(cover_weeks) OVER (PARTITION BY sku, warehouse_code
                               ORDER BY week_ending_date)                AS prior_week_cover
    FROM   mv_inventory_week
)

SELECT
    warehouse_code,
    COUNT(*) FILTER (WHERE prior_week_cover >= 8)                        AS weeks_well_covered,
    ROUND(100.0 * SUM(unmet_units) FILTER (WHERE prior_week_cover >= 8)
          / NULLIF(SUM(demand_units) FILTER (WHERE prior_week_cover >= 8), 0), 2)
                                                                         AS unmet_rate_when_well_covered_pct,
    COUNT(*) FILTER (WHERE prior_week_cover < 4)                         AS weeks_thinly_covered,
    ROUND(100.0 * SUM(unmet_units) FILTER (WHERE prior_week_cover < 4)
          / NULLIF(SUM(demand_units) FILTER (WHERE prior_week_cover < 4), 0), 2)
                                                                         AS unmet_rate_when_thin_pct
FROM   weekly_position
WHERE  week_ending_date >= DATE '2025-01-01'
  AND  demand_units > 0
GROUP  BY warehouse_code
ORDER  BY unmet_rate_when_well_covered_pct DESC;


\echo '=== 6. Availability by category, with all three measures ==='

WITH stock_side AS (
    SELECT
        category_code,
        ROUND(100.0 * COUNT(*) FILTER (WHERE quantity_on_hand = 0) / COUNT(*), 2)
                                                                         AS closing_zero_rate_pct,
        ROUND(100.0 * COUNT(*) FILTER (WHERE days_at_zero_in_week > 0) / COUNT(*), 2)
                                                                         AS any_zero_day_rate_pct,
        ROUND(AVG(cover_weeks) FILTER (WHERE cover_weeks IS NOT NULL), 1) AS mean_cover_weeks
    FROM   mv_inventory_week
    WHERE  year = :analysis_year
    GROUP  BY category_code
),

demand_side AS (
    SELECT
        category_code,
        COUNT(*)                                                         AS demand_lines,
        ROUND(100.0 * COUNT(*) FILTER (WHERE unmet_units = 0) / COUNT(*), 2)
                                                                         AS line_fill_rate_pct,
        SUM(unmet_units)                                                 AS unmet_units,
        ROUND(SUM(unmet_value_gbp), 0)                                   AS unmet_value_gbp
    FROM   vw_demand_line
    WHERE  order_date BETWEEN DATE '2025-01-01' AND DATE '2025-12-31'
    GROUP  BY category_code
)

SELECT
    s.category_code,
    s.mean_cover_weeks,
    s.closing_zero_rate_pct,
    s.any_zero_day_rate_pct,
    d.demand_lines,
    d.line_fill_rate_pct,
    d.unmet_units,
    d.unmet_value_gbp
FROM       stock_side  AS s
INNER JOIN demand_side AS d ON d.category_code = s.category_code
ORDER  BY  d.line_fill_rate_pct;


\echo '=== 7. Monthly path of unmet demand, 2025 ==='

SELECT
    TO_CHAR(order_date, 'YYYY-MM')                                       AS order_month,
    COUNT(*)                                                             AS demand_lines,
    ROUND(100.0 * COUNT(*) FILTER (WHERE unmet_units = 0) / COUNT(*), 2) AS line_fill_rate_pct,
    SUM(unmet_units)                                                     AS unmet_units,
    ROUND(SUM(unmet_value_gbp), 0)                                       AS unmet_value_gbp,
    ROUND(SUM(unmet_value_gbp) FILTER (WHERE warehouse_code = 'BRS'), 0) AS bristol_gbp,
    ROUND(SUM(unmet_value_gbp) FILTER (WHERE warehouse_code = 'WAR'), 0) AS warrington_gbp,
    ROUND(SUM(unmet_value_gbp) FILTER (WHERE warehouse_code = 'DAV'), 0) AS daventry_gbp,
    ROUND(SUM(unmet_value_gbp) FILTER (WHERE warehouse_code = 'LIV'), 0) AS livingston_gbp
FROM   vw_demand_line
WHERE  order_date BETWEEN DATE '2025-01-01' AND DATE '2025-12-31'
GROUP  BY order_month
ORDER  BY order_month;


\echo '=== 8. Where unmet demand concentrates ==='

-- Concentration matters more than the total. If unmet demand is spread evenly
-- there is a network problem; if it sits in a handful of lines, it is a
-- replenishment problem on those lines.
DROP VIEW IF EXISTS vw_unmet_concentration CASCADE;

CREATE VIEW vw_unmet_concentration AS

WITH sku_site AS (
    SELECT
        sku,
        warehouse_code,
        category_code,
        SUM(demand_units)                                                AS demand_units,
        SUM(unmet_units)                                                 AS unmet_units,
        SUM(unmet_value_gbp)                                             AS unmet_value_gbp,
        COUNT(*) FILTER (WHERE unmet_units > 0)                          AS lines_short
    FROM   vw_demand_line
    WHERE  order_date BETWEEN DATE '2025-01-01' AND DATE '2025-12-31'
    GROUP  BY sku, warehouse_code, category_code
),

ranked AS (
    SELECT
        s.*,
        ROW_NUMBER() OVER (ORDER BY s.unmet_value_gbp DESC)              AS rank_position,
        SUM(s.unmet_value_gbp) OVER (ORDER BY s.unmet_value_gbp DESC
             ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
            / NULLIF(SUM(s.unmet_value_gbp) OVER (), 0)                  AS cumulative_share
    FROM   sku_site AS s
    WHERE  s.unmet_value_gbp > 0
)

SELECT
    rank_position,
    sku,
    category_code,
    warehouse_code,
    demand_units,
    unmet_units,
    unmet_value_gbp,
    lines_short,
    cumulative_share
FROM   ranked;


SELECT
    'Lines with any unmet demand'                                        AS population,
    COUNT(*)                                                             AS sku_site_positions,
    ROUND(SUM(unmet_value_gbp), 0)                                       AS unmet_value_gbp,
    NULL::numeric                                                        AS share_pct
FROM   vw_unmet_concentration
UNION ALL
SELECT 'Top 10 positions', 10,
       ROUND(SUM(unmet_value_gbp) FILTER (WHERE rank_position <= 10), 0),
       ROUND(100.0 * SUM(unmet_value_gbp) FILTER (WHERE rank_position <= 10)
             / NULLIF(SUM(unmet_value_gbp), 0), 1)
FROM   vw_unmet_concentration
UNION ALL
SELECT 'Top 25 positions', 25,
       ROUND(SUM(unmet_value_gbp) FILTER (WHERE rank_position <= 25), 0),
       ROUND(100.0 * SUM(unmet_value_gbp) FILTER (WHERE rank_position <= 25)
             / NULLIF(SUM(unmet_value_gbp), 0), 1)
FROM   vw_unmet_concentration;


SELECT
    rank_position,
    sku,
    category_code,
    warehouse_code,
    demand_units,
    unmet_units,
    ROUND(unmet_value_gbp, 0)                                            AS unmet_value_gbp,
    lines_short,
    ROUND(100.0 * cumulative_share, 1)                                   AS cumulative_share_pct
FROM   vw_unmet_concentration
ORDER  BY rank_position
LIMIT  20;
