/* ============================================================
   Project    : 02 — Warehouse Inventory & Supply Chain Performance
   File       : 05_reporting_views/01_vw_kpi_inventory_value_and_turnover.sql
   KPI        : Inventory Turnover — _portfolio/KPI_LIBRARY.md, Inventory & Operations
   Output     : view supply.vw_kpi_inventory_value_and_turnover
                analysis/query_results/report_01_inventory_value_and_turnover.txt
   Author     : Peters
   Created    : 2026-08-23
   ============================================================

   Calderfield Trade Supplies Ltd is fictional and this data is synthetic.

   KPI DEFINITION, taken from the library and not redefined here.

     Formula   Cost of goods sold / Average inventory value
     Grain     SKU, category or site
     Unit      Times per year
     Note      Use average inventory, not closing — closing distorts
               seasonal businesses
     Decision  Where working capital is trapped

   FOUR PROJECT RULES THE LIBRARY DEFINITION DOES NOT CARRY.

   D-05. The period is fixed at calendar 2025, 52 weekly snapshots
   ending 2025-12-28. CURRENT_DATE is never used, so a committed result
   stays reproducible.

   Average inventory is the mean of those 52 weekly snapshots, not
   (opening + closing) / 2. Closing stock is £1,711,042 against an
   average of £2,043,979 — 16.3% lower — because importer receipts land
   in a sawtooth and the year happens to end in a trough. Closing stock
   is carried in this view as a column so the gap stays visible, but it
   is never the turnover denominator.

   D-09. Transfers are excluded from cost of sales. `issued_cost_gbp`
   in the weekly base counts `Sales issue` movements only. Counting the
   441 transfer pairs out of Daventry as Daventry throughput would
   flatter the site the range-mix work exists to assess honestly.

   D-10. Cost of sales is valued at the ledger weighted average cost
   carried at the moment of issue, not at `product.standard_cost_gbp`.
   Standard cost is one rate per SKU regardless of source, which erases
   the roughly 21% import price advantage — the exact trade-off the
   project is quantifying.

   GRAIN. One view, four grain levels, produced by GROUPING SETS so the
   network, site, category and site-by-category figures are guaranteed
   to be the same arithmetic rather than four queries that might drift.
   Read one grain at a time; the rows are not additive across levels.
   ============================================================ */

SET search_path TO supply;

\set analysis_year 2025
\set snapshot_date '2025-12-28'


CREATE OR REPLACE VIEW vw_kpi_inventory_value_and_turnover AS

WITH weekly AS (
    SELECT
        m.warehouse_code,
        m.warehouse_name,
        m.category_code,
        m.category_name,
        m.week_ending_date,
        m.sku,
        m.stock_value_gbp,
        m.issued_cost_gbp,
        m.issued_units
    FROM   mv_inventory_week AS m
    WHERE  m.year = :analysis_year
),

aggregated AS (
    SELECT
        GROUPING(warehouse_code)                                         AS grouping_site,
        GROUPING(category_code)                                          AS grouping_category,
        warehouse_code,
        MAX(warehouse_name)                                              AS warehouse_name,
        category_code,
        MAX(category_name)                                               AS category_name,
        COUNT(DISTINCT week_ending_date)                                 AS weeks_measured,
        COUNT(DISTINCT sku)                                              AS skus_stocked,
        -- Average of the weekly snapshots. Dividing the summed weekly
        -- values by the count of distinct weeks gives the mean weekly
        -- position at every grain without a second pass.
        SUM(stock_value_gbp) / NULLIF(COUNT(DISTINCT week_ending_date), 0)
                                                                         AS average_stock_gbp,
        SUM(stock_value_gbp) FILTER (WHERE week_ending_date = DATE :'snapshot_date')
                                                                         AS closing_stock_gbp,
        SUM(issued_cost_gbp)                                             AS cost_of_sales_gbp,
        SUM(issued_units)                                                AS units_issued
    FROM   weekly
    GROUP  BY GROUPING SETS ((), (warehouse_code), (category_code),
                             (warehouse_code, category_code))
)

SELECT
    CASE WHEN grouping_site = 1 AND grouping_category = 1 THEN '1 — network'
         WHEN grouping_site = 0 AND grouping_category = 1 THEN '2 — site'
         WHEN grouping_site = 1 AND grouping_category = 0 THEN '3 — category'
         ELSE                                                  '4 — site and category'
    END                                                                  AS grain_level,
    -- GROUPING, not COALESCE, decides the label. MAX(warehouse_name) returns
    -- a real site name even on the rolled-up rows, so keying the label off the
    -- name would print "Warrington" against the network total.
    CASE WHEN grouping_site     = 1 THEN 'ALL SITES'      ELSE warehouse_code END
                                                                         AS warehouse_code,
    CASE WHEN grouping_site     = 1 THEN 'All warehouses' ELSE warehouse_name END
                                                                         AS warehouse_name,
    CASE WHEN grouping_category = 1 THEN 'ALL CATEGORIES' ELSE category_code END
                                                                         AS category_code,
    CASE WHEN grouping_category = 1 THEN 'All categories' ELSE category_name END
                                                                         AS category_name,
    weeks_measured,
    skus_stocked,
    ROUND(average_stock_gbp, 2)                                          AS average_stock_gbp,
    ROUND(closing_stock_gbp, 2)                                          AS closing_stock_gbp,
    ROUND(100.0 * (closing_stock_gbp - average_stock_gbp)
          / NULLIF(average_stock_gbp, 0), 1)                             AS closing_vs_average_pct,
    ROUND(cost_of_sales_gbp, 2)                                          AS cost_of_sales_gbp,
    units_issued,
    ROUND(cost_of_sales_gbp / NULLIF(average_stock_gbp, 0), 2)           AS inventory_turns
FROM   aggregated;


\echo '=== 1. Network and site KPI, reconciling to file 01 ==='

-- Expected from analyse_01_working_capital_position.txt:
--   network average £2,043,979, cost of sales £9,550,572, 4.67 turns
--   DAV 4.68 / LIV 2.84 / WAR 5.63 / BRS 7.13
SELECT
    warehouse_code,
    warehouse_name,
    weeks_measured,
    skus_stocked,
    average_stock_gbp,
    closing_stock_gbp,
    closing_vs_average_pct,
    cost_of_sales_gbp,
    inventory_turns
FROM   vw_kpi_inventory_value_and_turnover
WHERE  grain_level IN ('1 — network', '2 — site')
ORDER  BY grain_level, average_stock_gbp DESC;


\echo '=== 2. Category KPI ==='

SELECT
    category_code,
    category_name,
    skus_stocked,
    average_stock_gbp,
    cost_of_sales_gbp,
    inventory_turns
FROM   vw_kpi_inventory_value_and_turnover
WHERE  grain_level = '3 — category'
ORDER  BY average_stock_gbp DESC;


\echo '=== 3. Site by category ==='

SELECT
    warehouse_code,
    category_code,
    average_stock_gbp,
    cost_of_sales_gbp,
    inventory_turns
FROM   vw_kpi_inventory_value_and_turnover
WHERE  grain_level = '4 — site and category'
ORDER  BY warehouse_code, average_stock_gbp DESC;


\echo '=== 4. Validation: the grains must reconcile to each other ==='

-- Site rows and category rows are two partitions of the same population,
-- so each must sum to the network row. A mismatch means the GROUPING SETS
-- are not partitioning what they claim to.
--
-- TOLERANCE, and why there is one. The view rounds every row to the penny,
-- so summing 4 site rows or 32 cell rows can differ from the single network
-- row by a few pence of rounding. The tolerance is £0.05 — an order of
-- magnitude below the smallest figure anyone would act on, and far below
-- any real partitioning error, which would show as thousands.
WITH network AS (
    SELECT average_stock_gbp, cost_of_sales_gbp
    FROM   vw_kpi_inventory_value_and_turnover
    WHERE  grain_level = '1 — network'
),
by_site AS (
    SELECT SUM(average_stock_gbp) AS average_stock_gbp, SUM(cost_of_sales_gbp) AS cost_of_sales_gbp
    FROM   vw_kpi_inventory_value_and_turnover
    WHERE  grain_level = '2 — site'
),
by_category AS (
    SELECT SUM(average_stock_gbp) AS average_stock_gbp, SUM(cost_of_sales_gbp) AS cost_of_sales_gbp
    FROM   vw_kpi_inventory_value_and_turnover
    WHERE  grain_level = '3 — category'
),
by_cell AS (
    SELECT SUM(average_stock_gbp) AS average_stock_gbp, SUM(cost_of_sales_gbp) AS cost_of_sales_gbp
    FROM   vw_kpi_inventory_value_and_turnover
    WHERE  grain_level = '4 — site and category'
)

SELECT
    'Sites sum to network'                                               AS check_name,
    ROUND(b.average_stock_gbp - n.average_stock_gbp, 2)                  AS average_stock_difference_gbp,
    ROUND(b.cost_of_sales_gbp - n.cost_of_sales_gbp, 2)                  AS cost_of_sales_difference_gbp,
    CASE WHEN ABS(b.average_stock_gbp - n.average_stock_gbp) <= 0.05
          AND ABS(b.cost_of_sales_gbp - n.cost_of_sales_gbp) <= 0.05
         THEN 'PASS' ELSE 'FAIL' END                                     AS result
FROM   network AS n CROSS JOIN by_site AS b
UNION ALL
SELECT 'Categories sum to network',
       ROUND(b.average_stock_gbp - n.average_stock_gbp, 2),
       ROUND(b.cost_of_sales_gbp - n.cost_of_sales_gbp, 2),
       CASE WHEN ABS(b.average_stock_gbp - n.average_stock_gbp) <= 0.05
             AND ABS(b.cost_of_sales_gbp - n.cost_of_sales_gbp) <= 0.05
            THEN 'PASS' ELSE 'FAIL' END
FROM   network AS n CROSS JOIN by_category AS b
UNION ALL
SELECT 'Site-by-category cells sum to network',
       ROUND(b.average_stock_gbp - n.average_stock_gbp, 2),
       ROUND(b.cost_of_sales_gbp - n.cost_of_sales_gbp, 2),
       CASE WHEN ABS(b.average_stock_gbp - n.average_stock_gbp) <= 0.05
             AND ABS(b.cost_of_sales_gbp - n.cost_of_sales_gbp) <= 0.05
            THEN 'PASS' ELSE 'FAIL' END
FROM   network AS n CROSS JOIN by_cell AS b;


\echo '=== 5. Validation: turnover is computed on average, never closing ==='

-- Printed as a standing guard. If someone later swaps the denominator,
-- the network figure moves from 4.67 to 5.58 and this row exposes it.
SELECT
    average_stock_gbp,
    closing_stock_gbp,
    cost_of_sales_gbp,
    inventory_turns                                                      AS turns_on_average_stock,
    ROUND(cost_of_sales_gbp / NULLIF(closing_stock_gbp, 0), 2)           AS turns_on_closing_stock_not_used,
    ROUND(cost_of_sales_gbp / NULLIF(closing_stock_gbp, 0)
          - inventory_turns, 2)                                          AS overstatement_if_closing_used
FROM   vw_kpi_inventory_value_and_turnover
WHERE  grain_level = '1 — network';
