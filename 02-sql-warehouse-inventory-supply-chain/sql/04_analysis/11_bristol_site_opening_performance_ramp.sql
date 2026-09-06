/* ============================================================
   Project    : 02 — Warehouse Inventory & Supply Chain Performance
   File       : 04_analysis/11_bristol_site_opening_performance_ramp.sql
   Question   : BQ-05 / AQ-11 — How has Bristol performed since opening,
                and is its March-April 2025 shortfall an opening effect
                or the seasonal replenishment lag found in file 07?
   Finding ID : F-11
   Output     : analysis/query_results/analyse_11_bristol_opening_ramp.txt
   Author     : Peters
   Created    : 2026-08-23
   ============================================================

   Calderfield Trade Supplies Ltd is fictional and this data is synthetic.

   Bristol opened 1 July 2024 and has 78 weekly snapshots against 104 at
   the other three sites. Its part-year is never annualised against a
   full year: comparisons either use 2025 alone, where all four sites
   carry 52 weeks, or are made explicitly against Bristol's own earlier
   months.

   THE QUESTION THIS FILE HAS TO SETTLE. File 06 found Bristol's unmet
   demand peaking at £37,166 in March 2025 and £32,136 in April, nine
   and ten months after opening. Two explanations fit:

     Opening effect   a new site still finding its stock levels, which
                      should decay as the site matures.
     Replenishment lag the same signature file 07 found across every
                      seasonal category — shortage trailing the demand
                      peak by one to two months.

   They make different predictions and both are testable here:

     If opening effect   the shortfall should be worst in the earliest
                         months and fall away; the categories affected
                         should be spread across the range; the other
                         three sites should not show the same shape.
     If replenishment lag the shortfall should sit in categories with a
                         spring demand peak; the other sites should show
                         a similar monthly shape; and Bristol's opening
                         months should not be the worst.

   HONEST LIMITATION, STATED UP FRONT. Bristol has traded through only
   one spring. A ramp effect and a seasonal effect can only be fully
   separated by observing two cycles. This file can rule one in or out
   on the evidence available; it cannot settle the question the way two
   years of trading would.
   ============================================================ */

SET search_path TO supply;

\set opened_date '2024-07-01'
\set first_week  '2024-07-07'
\set snapshot_date '2025-12-28'
\set analysis_date '2025-12-31'
\set holding_rate 0.22


\echo '=== 1. Coverage: what Bristol actually has ==='

-- Explicitly ordered. An unordered UNION ALL returns rows in whatever
-- order the planner produces them, which differs between runs and makes
-- the committed result non-reproducible.
SELECT
    measure, value
FROM (
SELECT
    1                                                                    AS sort_order,
    'Bristol snapshot weeks'                                             AS measure,
    COUNT(DISTINCT week_ending_date)                                     AS value
FROM   mv_inventory_week WHERE warehouse_code = 'BRS'
UNION ALL
SELECT 2, 'Other sites, snapshot weeks each',
       (SELECT COUNT(DISTINCT week_ending_date) FROM mv_inventory_week WHERE warehouse_code = 'DAV')
UNION ALL
SELECT 3, 'Bristol snapshot weeks in 2025',
       COUNT(DISTINCT week_ending_date)
FROM   mv_inventory_week WHERE warehouse_code = 'BRS' AND year = 2025
UNION ALL
SELECT 4, 'Bristol SKUs stocked', COUNT(DISTINCT sku)
FROM   mv_inventory_week WHERE warehouse_code = 'BRS'
UNION ALL
SELECT 5, 'Bristol demand lines since opening', COUNT(*)
FROM   vw_demand_line WHERE warehouse_code = 'BRS'
UNION ALL
SELECT 6, 'Bristol demand lines, March-April 2025', COUNT(*)
FROM   vw_demand_line
WHERE  warehouse_code = 'BRS'
  AND  order_date BETWEEN DATE '2025-03-01' AND DATE '2025-04-30'
) AS coverage
ORDER  BY sort_order;


\echo '=== 2. The ramp, quarter by quarter ==='

WITH stock_side AS (
    SELECT
        year,
        quarter,
        COUNT(DISTINCT week_ending_date)                                 AS weeks,
        SUM(stock_value_gbp) / COUNT(DISTINCT week_ending_date)          AS average_stock_gbp,
        SUM(issued_cost_gbp)                                             AS cost_of_sales_gbp,
        AVG(cover_weeks) FILTER (WHERE cover_weeks IS NOT NULL)          AS mean_cover_weeks,
        SUM(days_at_zero_in_week)                                        AS zero_days,
        COUNT(*)                                                         AS sku_weeks
    FROM   mv_inventory_week
    WHERE  warehouse_code = 'BRS'
    GROUP  BY year, quarter
),

demand_side AS (
    SELECT
        EXTRACT(YEAR FROM order_date)::int                               AS year,
        'Q' || EXTRACT(QUARTER FROM order_date)::int                     AS quarter,
        COUNT(*)                                                         AS demand_lines,
        SUM(demand_units)                                                AS demand_units,
        ROUND(100.0 * COUNT(*) FILTER (WHERE unmet_units = 0) / COUNT(*), 2)
                                                                         AS line_fill_rate_pct,
        SUM(unmet_value_gbp)                                             AS unmet_value_gbp
    FROM   vw_demand_line
    WHERE  warehouse_code = 'BRS'
      AND  order_date <= DATE :'analysis_date'
    GROUP  BY year, quarter
)

SELECT
    s.year,
    s.quarter,
    -- Quarters of trading, so the ramp can be read on the site's own clock.
    ROW_NUMBER() OVER (ORDER BY s.year, s.quarter)                       AS quarter_of_trading,
    s.weeks,
    ROUND(s.average_stock_gbp, 0)                                        AS average_stock_gbp,
    ROUND(s.mean_cover_weeks::numeric, 1)                                AS mean_cover_weeks,
    d.demand_lines,
    d.demand_units,
    d.line_fill_rate_pct,
    ROUND(d.unmet_value_gbp, 0)                                          AS unmet_value_gbp,
    s.zero_days,
    ROUND(s.zero_days::numeric / NULLIF(s.sku_weeks, 0), 3)              AS zero_days_per_sku_week
FROM       stock_side  AS s
INNER JOIN demand_side AS d ON d.year = s.year AND d.quarter = s.quarter
ORDER  BY  s.year, s.quarter;


\echo '=== 3. Where Bristol demand came from before it opened ==='

-- Customers whose servicing branch is Bristol had to be served from somewhere
-- for the first six months. If the region's demand simply moved, the other
-- sites should show a matching fall.
SELECT
    EXTRACT(YEAR FROM d.order_date)::int                                 AS year,
    'Q' || EXTRACT(QUARTER FROM d.order_date)::int                       AS quarter,
    COUNT(*) FILTER (WHERE d.warehouse_code = 'BRS')                     AS lines_from_bristol,
    COUNT(*) FILTER (WHERE d.warehouse_code = 'DAV')                     AS lines_from_daventry,
    COUNT(*) FILTER (WHERE d.warehouse_code = 'WAR')                     AS lines_from_warrington,
    COUNT(*) FILTER (WHERE d.warehouse_code = 'LIV')                     AS lines_from_livingston,
    COUNT(*)                                                             AS total_lines
FROM       vw_demand_line AS d
INNER JOIN customer       AS c ON c.customer_account = d.customer_account
WHERE      c.primary_warehouse_code = 'BRS'
  AND      d.order_date <= DATE :'analysis_date'
GROUP  BY  year, quarter
ORDER  BY  year, quarter;


\echo '=== 4. Bristol month by month, on its own trading clock ==='

-- Month of trading in the first column. An opening effect should be worst in
-- the low-numbered months and fade.
WITH bristol_month AS (
    SELECT
        TO_CHAR(order_date, 'YYYY-MM')                                   AS order_month,
        EXTRACT(MONTH FROM order_date)::int                              AS calendar_month,
        (EXTRACT(YEAR FROM order_date)::int - 2024) * 12
            + EXTRACT(MONTH FROM order_date)::int - 6                    AS month_of_trading,
        COUNT(*)                                                         AS demand_lines,
        SUM(demand_units)                                                AS demand_units,
        SUM(unmet_units)                                                 AS unmet_units,
        SUM(unmet_value_gbp)                                             AS unmet_value_gbp,
        100.0 * COUNT(*) FILTER (WHERE unmet_units = 0) / COUNT(*)       AS line_fill_rate_pct
    FROM   vw_demand_line
    WHERE  warehouse_code = 'BRS'
      AND  order_date <= DATE :'analysis_date'
    GROUP  BY order_month, calendar_month, month_of_trading
),

bristol_stock AS (
    SELECT
        TO_CHAR(week_ending_date, 'YYYY-MM')                             AS stock_month,
        SUM(days_at_zero_in_week)                                        AS zero_days,
        COUNT(*)                                                         AS sku_weeks,
        AVG(cover_weeks) FILTER (WHERE cover_weeks IS NOT NULL)          AS mean_cover_weeks
    FROM   mv_inventory_week
    WHERE  warehouse_code = 'BRS'
    GROUP  BY stock_month
)

SELECT
    m.month_of_trading,
    m.order_month,
    m.demand_lines,
    m.demand_units,
    ROUND(m.line_fill_rate_pct, 2)                                       AS line_fill_rate_pct,
    m.unmet_units,
    ROUND(m.unmet_value_gbp, 0)                                          AS unmet_value_gbp,
    ROUND(s.mean_cover_weeks::numeric, 1)                                AS mean_cover_weeks,
    ROUND(s.zero_days::numeric / NULLIF(s.sku_weeks, 0), 3)              AS zero_days_per_sku_week
FROM       bristol_month AS m
LEFT JOIN  bristol_stock AS s ON s.stock_month = m.order_month
ORDER  BY  m.month_of_trading;


\echo '=== 5. Test one — do the other sites show the same monthly shape? ==='

-- A replenishment lag is a network mechanism and should appear everywhere with
-- a seasonal category. An opening effect belongs to Bristol alone.
WITH monthly_site AS (
    SELECT
        warehouse_code,
        TO_CHAR(order_date, 'MM')                                        AS calendar_month,
        SUM(unmet_value_gbp)                                             AS unmet_value_gbp,
        COUNT(*)                                                         AS demand_lines
    FROM   vw_demand_line
    WHERE  order_date BETWEEN DATE '2025-01-01' AND DATE '2025-12-31'
    GROUP  BY warehouse_code, calendar_month
),

site_year AS (
    SELECT warehouse_code, SUM(unmet_value_gbp) AS year_unmet_gbp
    FROM   monthly_site GROUP BY warehouse_code
),

shares AS (
    -- Each site's month expressed as a share of its OWN year, so sites of very
    -- different size can be compared on shape rather than on level.
    SELECT
        m.calendar_month,
        m.warehouse_code,
        m.demand_lines,
        100.0 * m.unmet_value_gbp / NULLIF(y.year_unmet_gbp, 0)          AS share_of_own_year_pct
    FROM       monthly_site AS m
    INNER JOIN site_year    AS y ON y.warehouse_code = m.warehouse_code
)

SELECT
    calendar_month,
    ROUND(MAX(share_of_own_year_pct) FILTER (WHERE warehouse_code = 'BRS'), 1)
                                                                         AS bristol_share_pct,
    ROUND(MAX(share_of_own_year_pct) FILTER (WHERE warehouse_code = 'WAR'), 1)
                                                                         AS warrington_share_pct,
    ROUND(MAX(share_of_own_year_pct) FILTER (WHERE warehouse_code = 'DAV'), 1)
                                                                         AS daventry_share_pct,
    ROUND(MAX(share_of_own_year_pct) FILTER (WHERE warehouse_code = 'LIV'), 1)
                                                                         AS livingston_share_pct,
    MAX(demand_lines) FILTER (WHERE warehouse_code = 'BRS')              AS bristol_demand_lines
FROM   shares
GROUP  BY calendar_month
ORDER  BY calendar_month;


\echo '=== 6. Test two — which categories carry Bristol''s March-April shortfall? ==='

-- A seasonal lag should concentrate in categories with a spring demand peak.
-- An opening effect should be spread across the range in rough proportion to
-- demand. The demand-share column is the comparison that makes that testable.
SELECT
    category_code,
    COUNT(*)                                                             AS demand_lines,
    SUM(demand_units)                                                    AS demand_units,
    ROUND(100.0 * SUM(demand_value_gbp) / SUM(SUM(demand_value_gbp)) OVER (), 1)
                                                                         AS share_of_demand_value_pct,
    SUM(unmet_units)                                                     AS unmet_units,
    ROUND(SUM(unmet_value_gbp), 0)                                       AS unmet_value_gbp,
    ROUND(100.0 * SUM(unmet_value_gbp) / SUM(SUM(unmet_value_gbp)) OVER (), 1)
                                                                         AS share_of_unmet_value_pct,
    ROUND(100.0 * SUM(unmet_value_gbp) / NULLIF(SUM(demand_value_gbp), 0), 1)
                                                                         AS unmet_share_of_own_demand_pct
FROM   vw_demand_line
WHERE  warehouse_code = 'BRS'
  AND  order_date BETWEEN DATE '2025-03-01' AND DATE '2025-04-30'
GROUP  BY category_code
ORDER  BY unmet_value_gbp DESC;


\echo '=== 7. Test three — is the shortfall worst in the opening months? ==='

-- The single clearest discriminator. Opening effects decay with site age.
WITH bristol_month AS (
    SELECT
        (EXTRACT(YEAR FROM order_date)::int - 2024) * 12
            + EXTRACT(MONTH FROM order_date)::int - 6                    AS month_of_trading,
        COUNT(*)                                                         AS demand_lines,
        SUM(demand_units)                                                AS demand_units,
        SUM(unmet_units)                                                 AS unmet_units,
        SUM(unmet_value_gbp)                                             AS unmet_value_gbp
    FROM   vw_demand_line
    WHERE  warehouse_code = 'BRS'
      AND  order_date <= DATE :'analysis_date'
    GROUP  BY month_of_trading
)

SELECT
    CASE WHEN month_of_trading <=  3 THEN '1 — months 1 to 3'
         WHEN month_of_trading <=  6 THEN '2 — months 4 to 6'
         WHEN month_of_trading <=  9 THEN '3 — months 7 to 9'
         WHEN month_of_trading <= 12 THEN '4 — months 10 to 12'
         ELSE                             '5 — months 13 to 18'
    END                                                                  AS trading_period,
    SUM(demand_lines)                                                    AS demand_lines,
    SUM(demand_units)                                                    AS demand_units,
    SUM(unmet_units)                                                     AS unmet_units,
    ROUND(SUM(unmet_value_gbp), 0)                                       AS unmet_value_gbp,
    ROUND(100.0 * SUM(unmet_units) / NULLIF(SUM(demand_units), 0), 2)    AS unmet_unit_rate_pct
FROM   bristol_month
GROUP  BY trading_period
ORDER  BY trading_period;


\echo '=== 8. Bristol''s replenishment settings against the other sites ==='

-- Context for whichever explanation survives. Bristol's policies are the
-- tightest in the network, which is the standing condition under which any
-- demand surge or replenishment delay turns into a shortfall.
SELECT
    warehouse_code,
    COUNT(*)                                                             AS stocked_positions,
    ROUND(AVG(reorder_point_units / NULLIF(issued_units_13w::numeric / 13, 0))
          FILTER (WHERE issued_units_13w > 0), 1)                        AS mean_reorder_point_weeks,
    ROUND(AVG(safety_stock_units / NULLIF(issued_units_13w::numeric / 13, 0))
          FILTER (WHERE issued_units_13w > 0), 1)                        AS mean_safety_stock_weeks,
    ROUND(AVG((reorder_point_units + reorder_quantity_units)
              / NULLIF(issued_units_13w::numeric / 13, 0))
          FILTER (WHERE issued_units_13w > 0), 1)                        AS mean_policy_ceiling_weeks,
    ROUND(AVG(cover_weeks) FILTER (WHERE cover_weeks IS NOT NULL), 1)    AS mean_cover_weeks,
    ROUND(AVG(policy_age_months), 1)                                     AS mean_policy_age_months
FROM   mv_inventory_week
WHERE  week_ending_date = DATE :'snapshot_date'
GROUP  BY warehouse_code
ORDER  BY mean_policy_ceiling_weeks;


\echo '=== 9. Reconciliation ==='

SELECT
    'Bristol unmet value 2025 — this file'                               AS measure,
    ROUND((SELECT SUM(unmet_value_gbp) FROM vw_demand_line
           WHERE warehouse_code = 'BRS'
             AND order_date BETWEEN DATE '2025-01-01' AND DATE '2025-12-31'), 2)::text  AS value
UNION ALL
SELECT 'Bristol unmet value 2025 — file 06 reported 216,665',
       ROUND((SELECT SUM(unmet_value_gbp) FROM vw_demand_line
              WHERE warehouse_code = 'BRS'
                AND order_date BETWEEN DATE '2025-01-01' AND DATE '2025-12-31'), 2)::text
UNION ALL
SELECT 'Bristol snapshot rows — 90 SKUs x 78 weeks = 7,020 expected',
       (SELECT COUNT(*) FROM mv_inventory_week WHERE warehouse_code = 'BRS')::text
UNION ALL
SELECT 'Earliest Bristol snapshot week',
       (SELECT MIN(week_ending_date) FROM mv_inventory_week WHERE warehouse_code = 'BRS')::text
UNION ALL
SELECT 'Bristol movements before the opening date (must be 0)',
       (SELECT COUNT(*) FROM stock_movement
        WHERE warehouse_code = 'BRS' AND movement_date < DATE :'opened_date')::text
UNION ALL
SELECT 'Bristol demand lines before the opening date (must be 0)',
       (SELECT COUNT(*) FROM vw_demand_line
        WHERE warehouse_code = 'BRS' AND order_date < DATE :'opened_date')::text;
