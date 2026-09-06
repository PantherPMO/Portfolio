/* ============================================================
   Project    : 02 — Warehouse Inventory & Supply Chain Performance
   File       : 05_reporting_views/02_vw_kpi_days_inventory_outstanding.sql
   KPI        : Days Inventory Outstanding — _portfolio/KPI_LIBRARY.md
   Output     : view supply.vw_kpi_days_inventory_outstanding
                analysis/query_results/report_02_days_inventory_outstanding.txt
   Author     : Peters
   Created    : 2026-08-23
   ============================================================

   Calderfield Trade Supplies Ltd is fictional and this data is synthetic.

   KPI DEFINITION, from the library.

     Formula   365 / Inventory turnover
     Unit      Days
     Note      More intuitive for stakeholders than turnover; prefer it
               in stakeholder-facing output

   BUILT ON THE TURNOVER VIEW, NOT REDERIVED. Reporting view 01 already
   computes turnover from average inventory at ledger weighted average
   cost. Recomputing it here would create a second definition that could
   drift from the first. This view reads view 01 and applies 365 / turns.

   365, NOT 364. The period is 52 weekly snapshots, which spans 364
   days, but the KPI library defines DIO on a 365-day year and the
   library definition is not varied without a documented deviation. The
   difference is 0.27% — under a quarter of a day at 78 days of cover —
   and both figures are printed in section 3 so the choice is visible
   rather than assumed.

   A COMPANION, NOT A REPLACEMENT. DIO is turnover inverted, so it
   carries every limitation turnover carries. In particular it is a
   whole-year average and says nothing about the sawtooth: Livingston's
   129 days is a mean across 52 weeks that ranged widely.
   ============================================================ */

SET search_path TO supply;

\set days_in_year 365


CREATE OR REPLACE VIEW vw_kpi_days_inventory_outstanding AS
SELECT
    t.grain_level,
    t.warehouse_code,
    t.warehouse_name,
    t.category_code,
    t.category_name,
    t.weeks_measured,
    t.skus_stocked,
    t.average_stock_gbp,
    t.cost_of_sales_gbp,
    t.inventory_turns,
    ROUND(:days_in_year / NULLIF(t.inventory_turns, 0), 1)               AS days_inventory_outstanding,
    -- The same measure built from the components rather than from the
    -- rounded turnover figure, so rounding in view 01 cannot propagate.
    ROUND(:days_in_year * t.average_stock_gbp
          / NULLIF(t.cost_of_sales_gbp, 0), 1)                           AS days_inventory_outstanding_unrounded_basis,
    ROUND(t.average_stock_gbp / NULLIF(t.cost_of_sales_gbp / 52.0, 0), 1)
                                                                         AS weeks_of_cost_of_sales_held
FROM   vw_kpi_inventory_value_and_turnover AS t;


\echo '=== 1. Days inventory outstanding by site, reconciling to file 01 ==='

-- Expected from analyse_01_working_capital_position.txt, rounded to whole
-- days there: network 78, DAV 78, LIV 129, WAR 65, BRS 51.
SELECT
    warehouse_code,
    warehouse_name,
    average_stock_gbp,
    cost_of_sales_gbp,
    inventory_turns,
    days_inventory_outstanding,
    days_inventory_outstanding_unrounded_basis,
    weeks_of_cost_of_sales_held
FROM   vw_kpi_days_inventory_outstanding
WHERE  grain_level IN ('1 — network', '2 — site')
ORDER  BY grain_level, days_inventory_outstanding DESC;


\echo '=== 2. Days inventory outstanding by category ==='

SELECT
    category_code,
    category_name,
    skus_stocked,
    average_stock_gbp,
    inventory_turns,
    days_inventory_outstanding
FROM   vw_kpi_days_inventory_outstanding
WHERE  grain_level = '3 — category'
ORDER  BY days_inventory_outstanding DESC;


\echo '=== 3. Validation: rounding basis and calendar basis both stated ==='

-- Two things are checked. First, that computing DIO from the rounded
-- turnover figure and from the raw components agree to within a day.
-- Second, what the 365-day convention costs against the 364 days the
-- 52 snapshots actually span.
SELECT
    warehouse_code,
    days_inventory_outstanding                                           AS from_rounded_turns,
    days_inventory_outstanding_unrounded_basis                           AS from_components,
    ROUND(ABS(days_inventory_outstanding
              - days_inventory_outstanding_unrounded_basis), 2)          AS difference_days,
    CASE WHEN ABS(days_inventory_outstanding
                  - days_inventory_outstanding_unrounded_basis) <= 1.0
         THEN 'PASS' ELSE 'FAIL' END                                     AS rounding_check,
    ROUND(364 * average_stock_gbp / NULLIF(cost_of_sales_gbp, 0), 1)     AS dio_on_364_day_basis,
    ROUND(days_inventory_outstanding_unrounded_basis
          - 364 * average_stock_gbp / NULLIF(cost_of_sales_gbp, 0), 2)   AS calendar_convention_cost_days
FROM   vw_kpi_days_inventory_outstanding
WHERE  grain_level IN ('1 — network', '2 — site')
ORDER  BY grain_level, warehouse_code;


\echo '=== 4. Validation: DIO and turnover are reciprocal by construction ==='

-- A standing guard. If the two ever stop being reciprocal, one of them
-- has acquired its own denominator and the KPI has been redefined.
SELECT
    COUNT(*)                                                             AS rows_checked,
    COUNT(*) FILTER (WHERE ABS(inventory_turns
                               * days_inventory_outstanding - 365) > 1.0)
                                                                         AS rows_failing_reciprocal,
    CASE WHEN COUNT(*) FILTER (WHERE ABS(inventory_turns
                                         * days_inventory_outstanding - 365) > 1.0) = 0
         THEN 'PASS' ELSE 'FAIL' END                                     AS result
FROM   vw_kpi_days_inventory_outstanding
WHERE  inventory_turns IS NOT NULL
  AND  days_inventory_outstanding IS NOT NULL;
