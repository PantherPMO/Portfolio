/* ============================================================
   Project    : 02 — Warehouse Inventory & Supply Chain Performance
   File       : 04_analysis/01_working_capital_position_by_site_and_category.sql
   Question   : BQ-01 / AQ-01 — Where is our working capital sitting,
                by site, by category and by product?
   Finding ID : F-01
   Output     : analysis/query_results/analyse_01_working_capital_position.txt
   Author     : Peters
   Created    : 2026-08-23
   ============================================================

   Calderfield Trade Supplies Ltd is fictional and this data is synthetic.

   Measurement rules, all from docs/DECISIONS.md:

   - Average inventory, not closing (KPI_LIBRARY, and D-10). All four
     sites have a full 52 weeks in 2025, so the average is comparable
     across sites even though Bristol has only 78 weeks in total.
   - Cost of sales is 'Sales issue' valued at ledger weighted average
     cost (D-09, D-10). Transfers are stock moving between sites, not
     stock sold.
   - Holding cost at 22% per annum, sensitivity 20% and 25% (D-11).
     Three of its four components are external assumptions the dataset
     cannot corroborate, so the band travels with the figure.
   ============================================================ */

SET search_path TO supply;

\set analysis_year 2025
\set snapshot_date '2025-12-28'
\set holding_rate 0.22
\set holding_rate_low 0.20
\set holding_rate_high 0.25


\echo '=== 1. Network position: closing stock against average stock ==='

-- Both are shown because they answer different questions and differ materially.
-- Closing stock is what the balance sheet carries at year end; average stock is
-- what the business financed through the year. Large import receipts land in a
-- sawtooth, so closing can sit well above or below the money actually tied up.
WITH weekly_total AS (
    SELECT
        week_ending_date,
        SUM(stock_value_gbp)                         AS stock_value_gbp
    FROM   mv_inventory_week
    WHERE  year = :analysis_year
    GROUP  BY week_ending_date
)

SELECT
    ROUND(AVG(stock_value_gbp), 0)                                       AS average_stock_gbp,
    ROUND(MIN(stock_value_gbp), 0)                                       AS lowest_week_gbp,
    ROUND(MAX(stock_value_gbp), 0)                                       AS highest_week_gbp,
    ROUND(MAX(stock_value_gbp) FILTER (WHERE week_ending_date = DATE :'snapshot_date'), 0)
                                                                         AS closing_stock_gbp,
    ROUND(100.0 * (MAX(stock_value_gbp) FILTER (WHERE week_ending_date = DATE :'snapshot_date')
                   - AVG(stock_value_gbp))
          / NULLIF(AVG(stock_value_gbp), 0), 1)                          AS closing_vs_average_pct,
    COUNT(*)                                                             AS weeks_measured
FROM   weekly_total;


\echo '=== 2. Working capital and inventory performance by site, 2025 ==='

WITH site_year AS (
    SELECT
        warehouse_code,
        warehouse_name,
        SUM(stock_value_gbp) / COUNT(DISTINCT week_ending_date)          AS average_stock_gbp,
        SUM(issued_cost_gbp)                                             AS cost_of_sales_gbp,
        COUNT(DISTINCT week_ending_date)                                 AS weeks_measured,
        COUNT(DISTINCT sku)                                              AS skus_stocked
    FROM   mv_inventory_week
    WHERE  year = :analysis_year
    GROUP  BY warehouse_code, warehouse_name
)

SELECT
    warehouse_code,
    warehouse_name,
    weeks_measured,
    skus_stocked,
    ROUND(average_stock_gbp, 0)                                          AS average_stock_gbp,
    ROUND(100.0 * average_stock_gbp / SUM(average_stock_gbp) OVER (), 1) AS share_of_stock_pct,
    ROUND(cost_of_sales_gbp, 0)                                          AS cost_of_sales_gbp,
    ROUND(100.0 * cost_of_sales_gbp / SUM(cost_of_sales_gbp) OVER (), 1) AS share_of_cogs_pct,
    ROUND(cost_of_sales_gbp / NULLIF(average_stock_gbp, 0), 2)           AS inventory_turns,
    ROUND(365 / NULLIF(cost_of_sales_gbp / NULLIF(average_stock_gbp, 0), 0), 0)
                                                                         AS days_inventory_outstanding,
    ROUND(average_stock_gbp * :holding_rate, 0)                          AS holding_cost_gbp,
    ROUND(average_stock_gbp * :holding_rate_low, 0)                      AS holding_cost_low_gbp,
    ROUND(average_stock_gbp * :holding_rate_high, 0)                     AS holding_cost_high_gbp
FROM   site_year
ORDER  BY average_stock_gbp DESC;


\echo '=== 3. Stock share against sales share — where the two diverge ==='

-- The single most useful view in this file. A site or category holding a larger
-- share of the stock than it generates of the cost of sales is consuming more
-- than its share of working capital.
WITH site_year AS (
    SELECT
        warehouse_code,
        SUM(stock_value_gbp) / COUNT(DISTINCT week_ending_date)          AS average_stock_gbp,
        SUM(issued_cost_gbp)                                             AS cost_of_sales_gbp
    FROM   mv_inventory_week
    WHERE  year = :analysis_year
    GROUP  BY warehouse_code
)

SELECT
    warehouse_code,
    ROUND(100.0 * average_stock_gbp / SUM(average_stock_gbp) OVER (), 1) AS share_of_stock_pct,
    ROUND(100.0 * cost_of_sales_gbp / SUM(cost_of_sales_gbp) OVER (), 1) AS share_of_cogs_pct,
    ROUND(100.0 * average_stock_gbp / SUM(average_stock_gbp) OVER ()
          - 100.0 * cost_of_sales_gbp / SUM(cost_of_sales_gbp) OVER (), 1)
                                                                         AS stock_share_minus_cogs_share,
    -- Working capital the site would release if it held stock in proportion to
    -- the trade it actually does. Not a recommendation; a measure of the gap.
    ROUND(average_stock_gbp
          - SUM(average_stock_gbp) OVER ()
            * cost_of_sales_gbp / NULLIF(SUM(cost_of_sales_gbp) OVER (), 0), 0)
                                                                         AS stock_above_proportional_gbp
FROM   site_year
ORDER  BY stock_share_minus_cogs_share DESC;


\echo '=== 4. Working capital by category, 2025 ==='

WITH category_year AS (
    SELECT
        category_code,
        category_name,
        SUM(stock_value_gbp) / COUNT(DISTINCT week_ending_date)          AS average_stock_gbp,
        SUM(issued_cost_gbp)                                             AS cost_of_sales_gbp,
        COUNT(DISTINCT sku)                                              AS skus
    FROM   mv_inventory_week
    WHERE  year = :analysis_year
    GROUP  BY category_code, category_name
)

SELECT
    category_code,
    category_name,
    skus,
    ROUND(average_stock_gbp, 0)                                          AS average_stock_gbp,
    ROUND(100.0 * average_stock_gbp / SUM(average_stock_gbp) OVER (), 1) AS share_of_stock_pct,
    ROUND(cost_of_sales_gbp, 0)                                          AS cost_of_sales_gbp,
    ROUND(100.0 * cost_of_sales_gbp / SUM(cost_of_sales_gbp) OVER (), 1) AS share_of_cogs_pct,
    ROUND(cost_of_sales_gbp / NULLIF(average_stock_gbp, 0), 2)           AS inventory_turns,
    ROUND(365 / NULLIF(cost_of_sales_gbp / NULLIF(average_stock_gbp, 0), 0), 0)
                                                                         AS days_inventory_outstanding,
    ROUND(average_stock_gbp * :holding_rate, 0)                          AS holding_cost_gbp
FROM   category_year
ORDER  BY average_stock_gbp DESC;


\echo '=== 5. Site by category, with subtotals ==='

SELECT
    COALESCE(warehouse_code, 'ALL SITES')                                AS warehouse_code,
    COALESCE(category_code, 'ALL CATEGORIES')                            AS category_code,
    ROUND(SUM(stock_value_gbp) / COUNT(DISTINCT week_ending_date), 0)    AS average_stock_gbp,
    ROUND(SUM(issued_cost_gbp), 0)                                       AS cost_of_sales_gbp,
    ROUND(SUM(issued_cost_gbp)
          / NULLIF(SUM(stock_value_gbp) / COUNT(DISTINCT week_ending_date), 0), 2)
                                                                         AS inventory_turns
FROM   mv_inventory_week
WHERE  year = :analysis_year
GROUP  BY ROLLUP (warehouse_code, category_code)
ORDER  BY 1, 3 DESC;


\echo '=== 6. Quarterly path of average stock by site ==='

-- Bristol opened 2024-07-01, so its 2024 quarters are absent by design rather
-- than missing. Included to show the ramp, not to compare part-years.
SELECT
    year,
    quarter,
    ROUND(SUM(stock_value_gbp) FILTER (WHERE warehouse_code = 'DAV')
          / NULLIF(COUNT(DISTINCT week_ending_date), 0), 0)              AS daventry_gbp,
    ROUND(SUM(stock_value_gbp) FILTER (WHERE warehouse_code = 'WAR')
          / NULLIF(COUNT(DISTINCT week_ending_date), 0), 0)              AS warrington_gbp,
    ROUND(SUM(stock_value_gbp) FILTER (WHERE warehouse_code = 'BRS')
          / NULLIF(COUNT(DISTINCT week_ending_date), 0), 0)              AS bristol_gbp,
    ROUND(SUM(stock_value_gbp) FILTER (WHERE warehouse_code = 'LIV')
          / NULLIF(COUNT(DISTINCT week_ending_date), 0), 0)              AS livingston_gbp,
    ROUND(SUM(stock_value_gbp) / NULLIF(COUNT(DISTINCT week_ending_date), 0), 0)
                                                                         AS network_gbp
FROM   mv_inventory_week
GROUP  BY year, quarter
ORDER  BY year, quarter;


\echo '=== 7. Reconciliation ==='

-- The site and category breakdowns must sum back to the network figure, and the
-- cost of sales must tie to the ledger. A breakdown that does not reconcile is
-- a breakdown that has silently lost or double-counted rows.
SELECT
    'Average 2025 stock — network total'                                 AS measure,
    ROUND((SELECT SUM(stock_value_gbp) / COUNT(DISTINCT week_ending_date)
           FROM mv_inventory_week WHERE year = :analysis_year), 2)        AS value_gbp
UNION ALL
SELECT
    'Average 2025 stock — sum of sites',
    ROUND((SELECT SUM(site_avg) FROM
             (SELECT SUM(stock_value_gbp) / COUNT(DISTINCT week_ending_date) AS site_avg
              FROM mv_inventory_week WHERE year = :analysis_year
              GROUP BY warehouse_code) AS s), 2)
UNION ALL
SELECT
    'Cost of sales 2025 — from mv_inventory_week',
    ROUND((SELECT SUM(issued_cost_gbp) FROM mv_inventory_week
           WHERE year = :analysis_year), 2)
UNION ALL
SELECT
    'Cost of sales 2025 — direct from stock_movement',
    ROUND((SELECT -SUM(sm.quantity * sm.unit_cost_gbp)
           FROM       stock_movement AS sm
           INNER JOIN calendar_week  AS cw
                  ON  sm.movement_date BETWEEN cw.week_starting_date AND cw.week_ending_date
           WHERE      sm.movement_type = 'Sales issue'
             AND      cw.year = :analysis_year), 2);
