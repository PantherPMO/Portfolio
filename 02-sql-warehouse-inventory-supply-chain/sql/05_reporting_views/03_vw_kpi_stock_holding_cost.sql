/* ============================================================
   Project    : 02 — Warehouse Inventory & Supply Chain Performance
   File       : 05_reporting_views/03_vw_kpi_stock_holding_cost.sql
   KPI        : Stock Holding Cost — _portfolio/KPI_LIBRARY.md
   Output     : view supply.vw_kpi_stock_holding_cost
                analysis/query_results/report_03_stock_holding_cost.txt
   Author     : Peters
   Created    : 2026-08-23
   ============================================================

   Calderfield Trade Supplies Ltd is fictional and this data is synthetic.

   KPI DEFINITION, from the library.

     Formula   Average inventory value x Annual holding cost rate
     Unit      £ per annum
     Note      State the rate and its basis. A commonly cited range is
               20-30% of inventory value

   THE RATE IS 22% AND IT IS DERIVED, NOT ASSERTED (D-11).

     Cost of capital          6.00%   Bank of England Bank Rate 3.75%,
                                      set 18 December 2025, plus an
                                      assumed 2.25pp commercial margin
     Storage and handling     8.00%   Rent, racking, utilities, labour
                                      attributable to holding
     Service costs            3.00%   Insurance, stock-taking, systems
     Risk                     5.00%   Damage, obsolescence, shrinkage
     Total                   22.00%

   Calderfield sits at the low end of the published 20-30% range because
   the range is durable: 13 of 250 SKUs are discontinued and only 21
   carry any shelf life. Copper tube does not spoil.

   SENSITIVITY IS NOT OPTIONAL HERE. Three of the four components are
   external assumptions the dataset cannot corroborate, and the 20-30%
   range is an industry convention rather than a measured fact. Every
   row therefore carries 20% and 25% alongside 22%, and the average
   inventory value is always printed beside the cost so a reader can
   apply their own rate. The charter requires this of every quantified
   recommendation; the view makes it structural rather than remembered.

   THE RISK COMPONENT DOES NOT COME FROM THIS DATASET (D-12). Observed
   stock loss in the generated data runs at 7.9% of average inventory a
   year against a real-world norm well under 2%. The 5% risk component
   is taken from the published benchmark. Shrinkage in this project is
   reported comparatively between sites, never as an absolute.
   ============================================================ */

SET search_path TO supply;

\set holding_rate 0.22
\set holding_rate_low 0.20
\set holding_rate_high 0.25


CREATE OR REPLACE VIEW vw_kpi_stock_holding_cost AS
SELECT
    t.grain_level,
    t.warehouse_code,
    t.warehouse_name,
    t.category_code,
    t.category_name,
    t.weeks_measured,
    t.skus_stocked,
    t.average_stock_gbp,
    t.closing_stock_gbp,
    t.cost_of_sales_gbp,
    t.inventory_turns,
    :holding_rate                                                        AS holding_rate,
    ROUND(t.average_stock_gbp * :holding_rate, 2)                        AS holding_cost_gbp,
    ROUND(t.average_stock_gbp * :holding_rate_low, 2)                    AS holding_cost_at_20pct_gbp,
    ROUND(t.average_stock_gbp * :holding_rate_high, 2)                   AS holding_cost_at_25pct_gbp,
    -- The four components of the rate, carried as columns so a reader can
    -- see which part of the 22% they are being asked to accept. Only the
    -- capital component has an authoritative primary source (D-11).
    ROUND(t.average_stock_gbp * 0.0600, 2)                               AS component_capital_gbp,
    ROUND(t.average_stock_gbp * 0.0800, 2)                               AS component_storage_gbp,
    ROUND(t.average_stock_gbp * 0.0300, 2)                               AS component_service_gbp,
    ROUND(t.average_stock_gbp * 0.0500, 2)                               AS component_risk_gbp,
    -- Holding cost as a share of what the stock earned, which is the
    -- version an Operations Director can act on.
    ROUND(100.0 * t.average_stock_gbp * :holding_rate
          / NULLIF(t.cost_of_sales_gbp, 0), 2)                           AS holding_cost_pct_of_cost_of_sales
FROM   vw_kpi_inventory_value_and_turnover AS t;


\echo '=== 1. Holding cost by site, reconciling to file 01 ==='

-- Expected from analyse_01_working_capital_position.txt:
--   network £449,675 at 22%; DAV £219,314, LIV £104,178,
--   WAR £80,586, BRS £45,597
SELECT
    warehouse_code,
    warehouse_name,
    average_stock_gbp,
    holding_cost_gbp,
    holding_cost_at_20pct_gbp,
    holding_cost_at_25pct_gbp,
    holding_cost_pct_of_cost_of_sales
FROM   vw_kpi_stock_holding_cost
WHERE  grain_level IN ('1 — network', '2 — site')
ORDER  BY grain_level, holding_cost_gbp DESC;


\echo '=== 2. Holding cost by category ==='

SELECT
    category_code,
    category_name,
    average_stock_gbp,
    inventory_turns,
    holding_cost_gbp,
    holding_cost_at_20pct_gbp,
    holding_cost_at_25pct_gbp,
    holding_cost_pct_of_cost_of_sales
FROM   vw_kpi_stock_holding_cost
WHERE  grain_level = '3 — category'
ORDER  BY holding_cost_gbp DESC;


\echo '=== 3. The rate decomposed, at network level ==='

-- Printed once rather than per row. Three of these four numbers are
-- assumptions; the table exists so that is visible.
-- Explicitly ordered: an unordered UNION ALL is not reproducible, and a
-- committed result that changes between identical runs is not a committed
-- result.
SELECT
    component, rate_pct, annual_cost_gbp, basis
FROM (
SELECT
    1                                                                    AS sort_order,
    'Cost of capital — BoE Bank Rate 3.75% plus 2.25pp assumed margin'   AS component,
    6.00                                                                 AS rate_pct,
    component_capital_gbp                                                AS annual_cost_gbp,
    'Primary source for the Bank Rate only; the margin is assumed'       AS basis
FROM   vw_kpi_stock_holding_cost WHERE grain_level = '1 — network'
UNION ALL
SELECT 2, 'Storage and handling', 8.00, component_storage_gbp,
       'Industry convention; no cost data in the dataset'
FROM   vw_kpi_stock_holding_cost WHERE grain_level = '1 — network'
UNION ALL
SELECT 3, 'Service — insurance, stock-taking, systems', 3.00, component_service_gbp,
       'Industry convention; no cost data in the dataset'
FROM   vw_kpi_stock_holding_cost WHERE grain_level = '1 — network'
UNION ALL
SELECT 4, 'Risk — damage, obsolescence, shrinkage', 5.00, component_risk_gbp,
       'Published benchmark, NOT this dataset''s 7.9% observed loss (D-12)'
FROM   vw_kpi_stock_holding_cost WHERE grain_level = '1 — network'
UNION ALL
SELECT 5, 'Total', 22.00, holding_cost_gbp, 'Sensitivity reported at 20% and 25%'
FROM   vw_kpi_stock_holding_cost WHERE grain_level = '1 — network'
) AS rate_components
ORDER  BY sort_order;


\echo '=== 4. Validation: cost is on average stock, and sites sum to network ==='

WITH network AS (
    SELECT average_stock_gbp, holding_cost_gbp, closing_stock_gbp
    FROM   vw_kpi_stock_holding_cost WHERE grain_level = '1 — network'
),
sites AS (
    SELECT SUM(holding_cost_gbp) AS holding_cost_gbp
    FROM   vw_kpi_stock_holding_cost WHERE grain_level = '2 — site'
)

SELECT
    'Sites sum to network holding cost'                                  AS check_name,
    ROUND(s.holding_cost_gbp - n.holding_cost_gbp, 2)                    AS difference_gbp,
    CASE WHEN ABS(s.holding_cost_gbp - n.holding_cost_gbp) <= 0.05
         THEN 'PASS' ELSE 'FAIL' END                                     AS result
FROM   network AS n CROSS JOIN sites AS s
UNION ALL
SELECT 'Holding cost equals average stock x 22%, not closing stock x 22%',
       ROUND(n.holding_cost_gbp - n.average_stock_gbp * 0.22, 2),
       CASE WHEN ABS(n.holding_cost_gbp - n.average_stock_gbp * 0.22) <= 0.05
            THEN 'PASS' ELSE 'FAIL' END
FROM   network AS n
UNION ALL
SELECT 'Understatement avoided by not using closing stock',
       ROUND(n.holding_cost_gbp - n.closing_stock_gbp * 0.22, 2),
       'INFORMATION'
FROM   network AS n
UNION ALL
SELECT 'Components sum to the total',
       ROUND(component_capital_gbp + component_storage_gbp
             + component_service_gbp + component_risk_gbp - holding_cost_gbp, 2),
       CASE WHEN ABS(component_capital_gbp + component_storage_gbp
                     + component_service_gbp + component_risk_gbp - holding_cost_gbp) <= 0.05
            THEN 'PASS' ELSE 'FAIL' END
FROM   vw_kpi_stock_holding_cost WHERE grain_level = '1 — network';
