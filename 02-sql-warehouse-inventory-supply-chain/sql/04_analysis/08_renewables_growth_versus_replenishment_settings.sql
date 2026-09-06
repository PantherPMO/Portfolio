/* ============================================================
   Project    : 02 — Warehouse Inventory & Supply Chain Performance
   File       : 04_analysis/08_renewables_growth_versus_replenishment_settings.sql
   Question   : BQ-03 / AQ-08 — Is the fastest-growing part of the range
                being starved, and do the buying rules explain it?
   Finding ID : F-08
   Output     : analysis/query_results/analyse_08_renewables_growth.txt
   Author     : Peters
   Created    : 2026-08-23
   ============================================================

   Calderfield Trade Supplies Ltd is fictional and this data is synthetic.

   SMALL POPULATION. Renewables is 31 SKUs across 40 stocked
   SKU-and-site positions, of which 31 are at Daventry and only 3 each
   at Bristol, Warrington and Livingston. Every rate in this file is
   printed with the count behind it, and site-level splits within
   Renewables are reported for completeness rather than for conclusions.

   NO ASSUMED CAUSATION. The implementation plan expected stale policies
   to be starving the growth range. This file measures four things —
   demand growth, cover, availability and policy review currency — and
   then tests whether they move together. If policy age does not
   separate the good positions from the bad ones, that is reported as
   found. An association across a few dozen positions would in any case
   be suggestive, not causal.

   Slope is directional evidence only: two years, eight quarters, six at
   Bristol (charter §14, D-05 anchoring).
   ============================================================ */

SET search_path TO supply;

\set snapshot_date '2025-12-28'
\set analysis_date '2025-12-31'


\echo '=== 1. The population, stated before anything is measured ==='

SELECT
    'Renewables SKUs in the range'                                       AS population,
    COUNT(*)                                                             AS n
FROM   product WHERE category_code = 'RENW'
UNION ALL
SELECT 'Renewables stocked SKU-and-site positions', COUNT(*)
FROM   replenishment_policy AS rp
INNER JOIN product AS p ON p.sku = rp.sku
WHERE  p.category_code = 'RENW'
UNION ALL
SELECT 'Positions at Daventry', COUNT(*)
FROM   replenishment_policy AS rp
INNER JOIN product AS p ON p.sku = rp.sku
WHERE  p.category_code = 'RENW' AND rp.warehouse_code = 'DAV'
UNION ALL
SELECT 'Positions at the three regional sites combined', COUNT(*)
FROM   replenishment_policy AS rp
INNER JOIN product AS p ON p.sku = rp.sku
WHERE  p.category_code = 'RENW' AND rp.warehouse_code <> 'DAV'
UNION ALL
SELECT 'Renewables order lines, 2024-2025', COUNT(*)
FROM   vw_demand_line WHERE category_code = 'RENW';


\echo '=== 2. Demand growth: Renewables against every other category ==='

-- Quarterly units, pooled across sites. Bristol enters from 2024Q3, which lifts
-- every category's later quarters equally and so does not favour Renewables.
WITH quarterly AS (
    SELECT
        category_code,
        TO_CHAR(order_date, 'YYYY"Q"Q')                                  AS order_quarter,
        (EXTRACT(YEAR FROM order_date)::int - 2024) * 4
            + EXTRACT(QUARTER FROM order_date)::int                      AS quarter_index,
        SUM(demand_units)                                                AS demand_units,
        COUNT(*)                                                         AS demand_lines
    FROM   vw_demand_line
    WHERE  order_date BETWEEN DATE '2024-01-01' AND DATE :'analysis_date'
    GROUP  BY category_code, order_quarter, quarter_index
)

SELECT
    category_code,
    COUNT(*)                                                             AS quarters,
    SUM(demand_lines)                                                    AS demand_lines,
    MIN(demand_units) FILTER (WHERE quarter_index = 1)                   AS units_2024q1,
    MIN(demand_units) FILTER (WHERE quarter_index = 8)                   AS units_2025q4,
    ROUND(100.0 * (MIN(demand_units) FILTER (WHERE quarter_index = 8)
                   - MIN(demand_units) FILTER (WHERE quarter_index = 1))
          / NULLIF(MIN(demand_units) FILTER (WHERE quarter_index = 1), 0), 1)
                                                                         AS first_to_last_quarter_pct,
    ROUND(REGR_SLOPE(demand_units, quarter_index)::numeric, 1)           AS units_per_quarter_slope,
    ROUND((100.0 * REGR_SLOPE(demand_units, quarter_index)
           / NULLIF(AVG(demand_units), 0))::numeric, 1)                  AS slope_pct_of_mean_quarter,
    ROUND(REGR_R2(demand_units, quarter_index)::numeric, 2)              AS r_squared
FROM   quarterly
GROUP  BY category_code
ORDER  BY slope_pct_of_mean_quarter DESC;


\echo '=== 3. Renewables quarter by quarter, with lines behind each figure ==='

SELECT
    TO_CHAR(order_date, 'YYYY"Q"Q')                                      AS order_quarter,
    COUNT(*)                                                             AS demand_lines,
    SUM(demand_units)                                                    AS demand_units,
    SUM(supplied_units)                                                  AS supplied_units,
    SUM(unmet_units)                                                     AS unmet_units,
    ROUND(100.0 * COUNT(*) FILTER (WHERE unmet_units = 0) / COUNT(*), 1) AS line_fill_rate_pct,
    ROUND(SUM(unmet_value_gbp), 0)                                       AS unmet_value_gbp,
    COUNT(DISTINCT sku)                                                  AS distinct_skus
FROM   vw_demand_line
WHERE  category_code = 'RENW'
  AND  order_date BETWEEN DATE '2024-01-01' AND DATE :'analysis_date'
GROUP  BY order_quarter
ORDER  BY order_quarter;


\echo '=== 4. Cover, availability and policy age: Renewables against the rest ==='

WITH position AS (
    SELECT
        CASE WHEN category_code = 'RENW' THEN 'Renewables'
             ELSE 'All other categories' END                             AS grouping,
        cover_weeks,
        days_at_zero_in_week,
        quantity_on_hand,
        policy_age_months,
        reorder_point_units,
        issued_units_13w,
        stock_value_gbp
    FROM   mv_inventory_week
    WHERE  week_ending_date = DATE :'snapshot_date'
),

availability AS (
    SELECT
        CASE WHEN category_code = 'RENW' THEN 'Renewables'
             ELSE 'All other categories' END                             AS grouping,
        COUNT(*)                                                         AS sku_weeks,
        SUM(days_at_zero_in_week)                                        AS zero_days,
        COUNT(*) FILTER (WHERE days_at_zero_in_week > 0)                 AS weeks_with_a_zero_day
    FROM   mv_inventory_week
    WHERE  year = 2025
    GROUP  BY grouping
)

SELECT
    p.grouping,
    COUNT(*)                                                             AS n_positions,
    ROUND(AVG(p.cover_weeks) FILTER (WHERE p.cover_weeks IS NOT NULL), 1) AS mean_cover_weeks,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY p.cover_weeks)::numeric, 1)
                                                                         AS median_cover_weeks,
    ROUND(AVG(p.policy_age_months), 1)                                   AS mean_policy_age_months,
    COUNT(*) FILTER (WHERE p.policy_age_months > 15)                     AS n_policies_over_15_months,
    ROUND(100.0 * COUNT(*) FILTER (WHERE p.policy_age_months > 15) / COUNT(*), 1)
                                                                         AS stale_policy_share_pct,
    a.sku_weeks                                                          AS sku_weeks_2025,
    ROUND(100.0 * a.weeks_with_a_zero_day / a.sku_weeks, 2)              AS weeks_with_zero_day_pct,
    -- Reorder point expressed against the demand rate the line runs at today.
    ROUND(AVG(p.reorder_point_units / NULLIF(p.issued_units_13w::numeric / 13, 0))
          FILTER (WHERE p.issued_units_13w > 0), 1)                      AS mean_reorder_point_weeks_cover
FROM       position     AS p
INNER JOIN availability AS a ON a.grouping = p.grouping
GROUP  BY  p.grouping, a.sku_weeks, a.weeks_with_a_zero_day
ORDER  BY  p.grouping;


\echo '=== 5. Renewables positions in full — 40 rows, nothing aggregated away ==='

-- The population is small enough to show entirely, which is better than any
-- summary of it. Read the counts, not the percentages.
SELECT
    m.sku,
    m.warehouse_code,
    m.quantity_on_hand,
    ROUND(m.stock_value_gbp, 0)                                          AS stock_value_gbp,
    m.issued_units_13w,
    m.cover_weeks,
    m.reorder_point_units,
    m.reorder_quantity_units,
    ROUND(m.reorder_point_units / NULLIF(m.issued_units_13w::numeric / 13, 0), 1)
                                                                         AS reorder_point_weeks_cover,
    m.last_reviewed_date,
    m.policy_age_months,
    m.set_by_buyer,
    d.demand_units_2025,
    d.unmet_units_2025,
    ROUND(d.unmet_value_2025_gbp, 0)                                     AS unmet_value_2025_gbp,
    z.zero_days_2025
FROM       mv_inventory_week AS m
LEFT JOIN  (SELECT sku, warehouse_code,
                   SUM(demand_units)    AS demand_units_2025,
                   SUM(unmet_units)     AS unmet_units_2025,
                   SUM(unmet_value_gbp) AS unmet_value_2025_gbp
            FROM   vw_demand_line
            WHERE  order_date BETWEEN DATE '2025-01-01' AND DATE :'analysis_date'
            GROUP  BY sku, warehouse_code)                               AS d
       ON  d.sku = m.sku AND d.warehouse_code = m.warehouse_code
LEFT JOIN  (SELECT sku, warehouse_code, SUM(days_at_zero_in_week) AS zero_days_2025
            FROM   mv_inventory_week WHERE year = 2025
            GROUP  BY sku, warehouse_code)                               AS z
       ON  z.sku = m.sku AND z.warehouse_code = m.warehouse_code
WHERE      m.week_ending_date = DATE :'snapshot_date'
  AND      m.category_code = 'RENW'
ORDER  BY  COALESCE(d.unmet_value_2025_gbp, 0) DESC;


\echo '=== 6. Does policy age separate the good positions from the bad? ==='

-- The test the plan expected to pass. Within Renewables only, so demand
-- profile is held roughly constant. n is tiny — read the counts.
WITH renewables AS (
    SELECT
        m.sku,
        m.warehouse_code,
        m.policy_age_months,
        m.cover_weeks,
        m.reorder_point_units,
        m.issued_units_13w,
        m.reorder_point_units / NULLIF(m.issued_units_13w::numeric / 13, 0)
                                                                         AS reorder_point_weeks_cover,
        COALESCE(z.zero_days_2025, 0)                                    AS zero_days_2025,
        COALESCE(d.unmet_units_2025, 0)                                  AS unmet_units_2025,
        COALESCE(d.demand_units_2025, 0)                                 AS demand_units_2025
    FROM       mv_inventory_week AS m
    LEFT JOIN  (SELECT sku, warehouse_code, SUM(days_at_zero_in_week) AS zero_days_2025
                FROM   mv_inventory_week WHERE year = 2025
                GROUP  BY sku, warehouse_code)                           AS z
           ON  z.sku = m.sku AND z.warehouse_code = m.warehouse_code
    LEFT JOIN  (SELECT sku, warehouse_code,
                       SUM(demand_units) AS demand_units_2025,
                       SUM(unmet_units)  AS unmet_units_2025
                FROM   vw_demand_line
                WHERE  order_date BETWEEN DATE '2025-01-01' AND DATE :'analysis_date'
                GROUP  BY sku, warehouse_code)                           AS d
           ON  d.sku = m.sku AND d.warehouse_code = m.warehouse_code
    WHERE      m.week_ending_date = DATE :'snapshot_date'
      AND      m.category_code = 'RENW'
)

SELECT
    CASE WHEN policy_age_months > 15 THEN 'Policy over 15 months old'
         ELSE                             'Policy reviewed within 15 months' END AS policy_currency,
    COUNT(*)                                                             AS n_positions,
    ROUND(AVG(policy_age_months), 1)                                     AS mean_policy_age_months,
    ROUND(AVG(reorder_point_weeks_cover)
          FILTER (WHERE reorder_point_weeks_cover IS NOT NULL), 1)       AS mean_reorder_point_weeks,
    ROUND(AVG(cover_weeks) FILTER (WHERE cover_weeks IS NOT NULL), 1)    AS mean_cover_weeks,
    SUM(zero_days_2025)                                                  AS zero_days_2025,
    ROUND(AVG(zero_days_2025), 1)                                        AS mean_zero_days_per_position,
    SUM(demand_units_2025)                                               AS demand_units_2025,
    SUM(unmet_units_2025)                                                AS unmet_units_2025,
    ROUND(100.0 * SUM(unmet_units_2025) / NULLIF(SUM(demand_units_2025), 0), 1)
                                                                         AS unmet_unit_rate_pct
FROM   renewables
GROUP  BY policy_currency
ORDER  BY policy_currency;


\echo '=== 7. The same test across the whole range, for comparison ==='

-- Renewables is too small to conclude from on its own. Running the identical
-- split across all 515 positions shows whether policy age separates outcomes
-- anywhere, which is the more answerable question.
WITH all_positions AS (
    SELECT
        m.category_code,
        m.policy_age_months,
        m.cover_weeks,
        m.reorder_point_units / NULLIF(m.issued_units_13w::numeric / 13, 0)
                                                                         AS reorder_point_weeks_cover,
        COALESCE(z.zero_days_2025, 0)                                    AS zero_days_2025,
        COALESCE(d.demand_units_2025, 0)                                 AS demand_units_2025,
        COALESCE(d.unmet_units_2025, 0)                                  AS unmet_units_2025
    FROM       mv_inventory_week AS m
    LEFT JOIN  (SELECT sku, warehouse_code, SUM(days_at_zero_in_week) AS zero_days_2025
                FROM   mv_inventory_week WHERE year = 2025
                GROUP  BY sku, warehouse_code)                           AS z
           ON  z.sku = m.sku AND z.warehouse_code = m.warehouse_code
    LEFT JOIN  (SELECT sku, warehouse_code,
                       SUM(demand_units) AS demand_units_2025,
                       SUM(unmet_units)  AS unmet_units_2025
                FROM   vw_demand_line
                WHERE  order_date BETWEEN DATE '2025-01-01' AND DATE :'analysis_date'
                GROUP  BY sku, warehouse_code)                           AS d
           ON  d.sku = m.sku AND d.warehouse_code = m.warehouse_code
    WHERE      m.week_ending_date = DATE :'snapshot_date'
)

SELECT
    CASE WHEN policy_age_months > 15 THEN 'Policy over 15 months old'
         ELSE                             'Policy reviewed within 15 months' END AS policy_currency,
    COUNT(*)                                                             AS n_positions,
    ROUND(AVG(reorder_point_weeks_cover)
          FILTER (WHERE reorder_point_weeks_cover IS NOT NULL), 1)       AS mean_reorder_point_weeks,
    ROUND(AVG(cover_weeks) FILTER (WHERE cover_weeks IS NOT NULL), 1)    AS mean_cover_weeks,
    ROUND(AVG(zero_days_2025), 2)                                        AS mean_zero_days_per_position,
    ROUND(100.0 * SUM(unmet_units_2025) / NULLIF(SUM(demand_units_2025), 0), 2)
                                                                         AS unmet_unit_rate_pct
FROM   all_positions
GROUP  BY policy_currency
ORDER  BY policy_currency;


\echo '=== 8. Reorder point against demand direction, all categories ==='

-- The mechanism the plan proposed, stated generally: a reorder point set on an
-- earlier demand level will look small against a line whose demand has since
-- grown, and generous against one whose demand has since fallen. This tests it
-- without reference to Renewables, so the category is not doing the work.
SELECT
    demand_direction,
    COUNT(*)                                                             AS n_positions,
    ROUND(AVG(policy_age_months), 1)                                     AS mean_policy_age_months,
    ROUND(AVG(reorder_point_units / NULLIF(issued_units_13w::numeric / 13, 0))
          FILTER (WHERE issued_units_13w > 0), 1)                        AS mean_reorder_point_weeks,
    ROUND(AVG(cover_weeks) FILTER (WHERE cover_weeks IS NOT NULL), 1)    AS mean_cover_weeks,
    COUNT(*) FILTER (WHERE category_code = 'RENW')                       AS of_which_renewables
FROM   vw_cover_versus_trend
GROUP  BY demand_direction
ORDER  BY demand_direction;
