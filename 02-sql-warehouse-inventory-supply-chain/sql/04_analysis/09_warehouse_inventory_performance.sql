/* ============================================================
   Project    : 02 — Warehouse Inventory & Supply Chain Performance
   File       : 04_analysis/09_warehouse_inventory_performance.sql
   Question   : BQ-05 / AQ-09 — How does each site perform on cash and
                on service, and why does Daventry short-ship even when
                its stock cover is adequate?
   Finding ID : F-09
   Output     : analysis/query_results/analyse_09_warehouse_performance.txt
   Author     : Peters
   Created    : 2026-08-23
   ============================================================

   Calderfield Trade Supplies Ltd is fictional and this data is synthetic.

   2025 ONLY. Bristol traded 78 of the 104 weeks in the dataset but a
   full 52 in 2025, so restricting to 2025 makes all four sites
   comparable without annualising a part-year.

   MEASUREMENT RULES, all carried from earlier decisions.
   D-09  Cost of sales is 'Sales issue' only. Transfers move stock
         between sites and are not sales; counting them would overstate
         Daventry, which supplies the regional network.
   D-10  Valued at ledger weighted average cost, not standard cost.
   D-17  Cover and excess-above-policy answer different questions. Cover
         is used here; excess is not a proxy for overstock.
   D-03  Fulfilment from quantities, never from line_status.

   THE SECOND HALF OF THIS FILE TESTS A SPECIFIC ANOMALY.
   File 06 found Daventry short-ships 2.60% of units even in weeks that
   opened with eight or more weeks of cover, against 0.30% at Warrington
   — four to nine times the other sites. Cover does not explain it.
   Sections 5 to 8 test four candidate explanations that can be measured
   from this dataset. Each is reported as surviving or failing. None is
   asserted as the cause: this is elimination, not proof.
   ============================================================ */

SET search_path TO supply;

\set analysis_year 2025
\set snapshot_date '2025-12-28'
\set holding_rate 0.22


\echo '=== 1. Headline site performance, 2025 ==='

SELECT
    m.warehouse_code,
    w.warehouse_name,
    w.site_type,
    w.opened_date,
    COUNT(DISTINCT m.week_ending_date)                                   AS weeks_measured,
    COUNT(DISTINCT m.sku)                                                AS skus_stocked,
    ROUND(SUM(m.stock_value_gbp) / COUNT(DISTINCT m.week_ending_date), 0) AS average_stock_gbp,
    ROUND(SUM(m.issued_cost_gbp), 0)                                     AS cost_of_sales_gbp,
    ROUND(SUM(m.issued_cost_gbp)
          / NULLIF(SUM(m.stock_value_gbp) / COUNT(DISTINCT m.week_ending_date), 0), 2)
                                                                         AS inventory_turns,
    ROUND(365 / NULLIF(SUM(m.issued_cost_gbp)
          / NULLIF(SUM(m.stock_value_gbp) / COUNT(DISTINCT m.week_ending_date), 0), 0), 0)
                                                                         AS days_inventory_outstanding,
    ROUND(AVG(m.cover_weeks) FILTER (WHERE m.cover_weeks IS NOT NULL), 1) AS mean_cover_weeks,
    ROUND(SUM(m.stock_value_gbp) / COUNT(DISTINCT m.week_ending_date) * :holding_rate, 0)
                                                                         AS holding_cost_gbp
FROM       mv_inventory_week AS m
INNER JOIN warehouse         AS w ON w.warehouse_code = m.warehouse_code
WHERE      m.year = :analysis_year
GROUP  BY  m.warehouse_code, w.warehouse_name, w.site_type, w.opened_date
ORDER  BY  inventory_turns;


\echo '=== 2. Service performance beside it ==='

SELECT
    d.warehouse_code,
    COUNT(*)                                                             AS demand_lines,
    COUNT(DISTINCT d.resolved_account)                                   AS customers_served,
    SUM(d.demand_units)                                                  AS demand_units,
    ROUND(SUM(d.supplied_value_gbp), 0)                                  AS revenue_gbp,
    ROUND(100.0 * COUNT(*) FILTER (WHERE d.unmet_units = 0) / COUNT(*), 2)
                                                                         AS line_fill_rate_pct,
    ROUND(100.0 * SUM(d.supplied_units) / NULLIF(SUM(d.demand_units), 0), 2)
                                                                         AS unit_fill_rate_pct,
    SUM(d.unmet_units)                                                   AS unmet_units,
    ROUND(SUM(d.unmet_value_gbp), 0)                                     AS unmet_value_gbp,
    ROUND(100.0 * SUM(d.unmet_value_gbp)
          / NULLIF(SUM(d.demand_value_gbp), 0), 2)                       AS unmet_share_of_demand_pct
FROM   vw_demand_line AS d
WHERE  d.order_date BETWEEN DATE '2025-01-01' AND DATE '2025-12-31'
GROUP  BY d.warehouse_code
ORDER  BY line_fill_rate_pct;


\echo '=== 3. Cash and service on one row — the trade each site has made ==='

WITH cash AS (
    SELECT
        warehouse_code,
        SUM(stock_value_gbp) / COUNT(DISTINCT week_ending_date)          AS average_stock_gbp,
        SUM(issued_cost_gbp)                                             AS cost_of_sales_gbp
    FROM   mv_inventory_week
    WHERE  year = :analysis_year
    GROUP  BY warehouse_code
),

service AS (
    SELECT
        warehouse_code,
        COUNT(*)                                                         AS demand_lines,
        100.0 * COUNT(*) FILTER (WHERE unmet_units = 0) / COUNT(*)       AS line_fill_rate_pct,
        SUM(unmet_value_gbp)                                             AS unmet_value_gbp
    FROM   vw_demand_line
    WHERE  order_date BETWEEN DATE '2025-01-01' AND DATE '2025-12-31'
    GROUP  BY warehouse_code
)

SELECT
    c.warehouse_code,
    ROUND(c.average_stock_gbp, 0)                                        AS average_stock_gbp,
    ROUND(365 / NULLIF(c.cost_of_sales_gbp / NULLIF(c.average_stock_gbp, 0), 0), 0)
                                                                         AS days_inventory_outstanding,
    ROUND(s.line_fill_rate_pct, 2)                                       AS line_fill_rate_pct,
    s.demand_lines,
    ROUND(s.unmet_value_gbp, 0)                                          AS unmet_value_gbp,
    -- Stock carried per pound of cost of sales. A blunt but honest way of
    -- putting the two sides of the trade on the same scale.
    ROUND(c.average_stock_gbp / NULLIF(c.cost_of_sales_gbp, 0), 3)       AS stock_per_pound_of_cogs,
    ROUND(c.average_stock_gbp * :holding_rate, 0)                        AS holding_cost_gbp
FROM       cash    AS c
INNER JOIN service AS s ON s.warehouse_code = c.warehouse_code
ORDER  BY  days_inventory_outstanding DESC;


\echo '=== 4. Site performance by category, with the network as reference ==='

SELECT
    category_code,
    ROUND(SUM(issued_cost_gbp) FILTER (WHERE warehouse_code = 'DAV')
          / NULLIF(SUM(stock_value_gbp) FILTER (WHERE warehouse_code = 'DAV') / 52, 0), 2)
                                                                         AS daventry_turns,
    ROUND(SUM(issued_cost_gbp) FILTER (WHERE warehouse_code = 'WAR')
          / NULLIF(SUM(stock_value_gbp) FILTER (WHERE warehouse_code = 'WAR') / 52, 0), 2)
                                                                         AS warrington_turns,
    ROUND(SUM(issued_cost_gbp) FILTER (WHERE warehouse_code = 'BRS')
          / NULLIF(SUM(stock_value_gbp) FILTER (WHERE warehouse_code = 'BRS') / 52, 0), 2)
                                                                         AS bristol_turns,
    ROUND(SUM(issued_cost_gbp) FILTER (WHERE warehouse_code = 'LIV')
          / NULLIF(SUM(stock_value_gbp) FILTER (WHERE warehouse_code = 'LIV') / 52, 0), 2)
                                                                         AS livingston_turns,
    ROUND(SUM(issued_cost_gbp) / NULLIF(SUM(stock_value_gbp) / 52, 0), 2) AS network_turns
FROM   mv_inventory_week
WHERE  year = :analysis_year
GROUP  BY category_code
ORDER  BY network_turns;


\echo '=== 5. The anomaly restated, with counts ==='

-- Cover is taken from the PRIOR week. Cover measured in the week of a shortage
-- is depressed by the shortage itself.
DROP VIEW IF EXISTS vw_weekly_service_position CASCADE;

CREATE VIEW vw_weekly_service_position AS

SELECT
    warehouse_code,
    sku,
    category_code,
    week_ending_date,
    demand_units,
    unmet_units,
    unmet_value_gbp,
    demand_lines,
    quantity_on_hand,
    LAG(cover_weeks)      OVER (PARTITION BY sku, warehouse_code
                                ORDER BY week_ending_date)               AS prior_cover_weeks,
    LAG(quantity_on_hand) OVER (PARTITION BY sku, warehouse_code
                                ORDER BY week_ending_date)               AS prior_units_on_hand
FROM   mv_inventory_week;


SELECT
    warehouse_code,
    COUNT(*) FILTER (WHERE prior_cover_weeks >= 8 AND demand_units > 0)  AS well_covered_weeks_with_demand,
    COUNT(*) FILTER (WHERE prior_cover_weeks >= 8 AND unmet_units > 0)   AS of_which_short,
    ROUND(100.0 * COUNT(*) FILTER (WHERE prior_cover_weeks >= 8 AND unmet_units > 0)
          / NULLIF(COUNT(*) FILTER (WHERE prior_cover_weeks >= 8 AND demand_units > 0), 0), 2)
                                                                         AS pct_of_weeks_short,
    SUM(demand_units) FILTER (WHERE prior_cover_weeks >= 8)              AS demand_units_well_covered,
    SUM(unmet_units)  FILTER (WHERE prior_cover_weeks >= 8)              AS unmet_units_well_covered,
    ROUND(100.0 * SUM(unmet_units) FILTER (WHERE prior_cover_weeks >= 8)
          / NULLIF(SUM(demand_units) FILTER (WHERE prior_cover_weeks >= 8), 0), 2)
                                                                         AS unmet_unit_rate_pct,
    ROUND(SUM(unmet_value_gbp) FILTER (WHERE prior_cover_weeks >= 8), 0) AS unmet_value_gbp
FROM   vw_weekly_service_position
WHERE  week_ending_date >= DATE '2025-01-01'
  AND  demand_units > 0
GROUP  BY warehouse_code
ORDER  BY unmet_unit_rate_pct DESC;


\echo '=== 6. Candidate A — order-size lumpiness ==='

-- If a single large line is outrunning otherwise adequate stock, the demand in
-- shortfall weeks should be far above the site's normal line size, and the
-- stock on hand should be close to or below it.
SELECT
    warehouse_code,
    COUNT(*) FILTER (WHERE prior_cover_weeks >= 8 AND unmet_units > 0)    AS short_weeks,
    ROUND(AVG(demand_units) FILTER (WHERE prior_cover_weeks >= 8 AND demand_units > 0), 1)
                                                                         AS mean_weekly_demand_units,
    ROUND(AVG(demand_units) FILTER (WHERE prior_cover_weeks >= 8 AND unmet_units > 0), 1)
                                                                         AS mean_demand_in_short_weeks,
    ROUND(AVG(demand_units) FILTER (WHERE prior_cover_weeks >= 8 AND unmet_units > 0)
          / NULLIF(AVG(demand_units) FILTER (WHERE prior_cover_weeks >= 8 AND demand_units > 0), 0), 2)
                                                                         AS demand_spike_ratio,
    ROUND(AVG(prior_units_on_hand) FILTER (WHERE prior_cover_weeks >= 8 AND unmet_units > 0), 1)
                                                                         AS mean_units_on_hand_when_short,
    ROUND(AVG(demand_units) FILTER (WHERE prior_cover_weeks >= 8 AND unmet_units > 0)
          / NULLIF(AVG(prior_units_on_hand) FILTER (WHERE prior_cover_weeks >= 8 AND unmet_units > 0), 0), 2)
                                                                         AS demand_to_stock_ratio
FROM   vw_weekly_service_position
WHERE  week_ending_date >= DATE '2025-01-01'
GROUP  BY warehouse_code
ORDER  BY demand_spike_ratio DESC;


\echo '=== 7. Candidate B — customer mix ==='

-- Housebuilders order in project drops. If Daventry served a heavier share of
-- them, that alone could raise its shortfall rate. Segment share is reported
-- with the unmet rate so the two can be read against each other.
SELECT
    warehouse_code,
    customer_segment,
    COUNT(*)                                                             AS demand_lines,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY warehouse_code), 1)
                                                                         AS share_of_site_lines_pct,
    ROUND(AVG(demand_units), 1)                                          AS mean_line_units,
    ROUND(PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY demand_units)::numeric, 0)
                                                                         AS p95_line_units,
    ROUND(100.0 * COUNT(*) FILTER (WHERE unmet_units > 0) / COUNT(*), 2)  AS unmet_line_rate_pct
FROM   vw_demand_line
WHERE  order_date BETWEEN DATE '2025-01-01' AND DATE '2025-12-31'
GROUP  BY warehouse_code, customer_segment
ORDER  BY warehouse_code, unmet_line_rate_pct DESC;


\echo '=== 8. Candidate C — cover is a ratio, and Daventry holds thin lines ==='

-- Eight weeks of cover on a line selling 200 units a week is 1,600 units on the
-- shelf. Eight weeks on a line selling two units a week is sixteen. Both count
-- as "well covered". If Daventry's range runs to slower lines, its well-covered
-- positions will be thinner in absolute units and more easily outrun.
SELECT
    warehouse_code,
    COUNT(*) FILTER (WHERE prior_cover_weeks >= 8 AND demand_units > 0)  AS well_covered_weeks,
    ROUND(AVG(prior_units_on_hand) FILTER (WHERE prior_cover_weeks >= 8 AND demand_units > 0), 1)
                                                                         AS mean_units_on_hand,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY prior_units_on_hand)
          FILTER (WHERE prior_cover_weeks >= 8 AND demand_units > 0)::numeric, 1)
                                                                         AS median_units_on_hand,
    ROUND(PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY prior_units_on_hand)
          FILTER (WHERE prior_cover_weeks >= 8 AND demand_units > 0)::numeric, 1)
                                                                         AS lower_quartile_units,
    ROUND(100.0 * COUNT(*) FILTER (WHERE prior_cover_weeks >= 8 AND demand_units > 0
                                     AND prior_units_on_hand < 50)
          / NULLIF(COUNT(*) FILTER (WHERE prior_cover_weeks >= 8 AND demand_units > 0), 0), 1)
                                                                         AS pct_well_covered_under_50_units
FROM   vw_weekly_service_position
WHERE  week_ending_date >= DATE '2025-01-01'
GROUP  BY warehouse_code
ORDER  BY mean_units_on_hand;


-- Holding absolute stock depth constant. If the effect is a ratio artefact, the
-- site difference should shrink or vanish once well-covered weeks are compared
-- at similar unit levels.
SELECT
    CASE WHEN prior_units_on_hand <   25 THEN '1 — under 25 units'
         WHEN prior_units_on_hand <  100 THEN '2 — 25 to 100'
         WHEN prior_units_on_hand <  500 THEN '3 — 100 to 500'
         ELSE                                 '4 — 500 or more'
    END                                                                  AS stock_depth_band,
    COUNT(*) FILTER (WHERE warehouse_code = 'DAV')                       AS dav_weeks,
    ROUND(100.0 * SUM(unmet_units) FILTER (WHERE warehouse_code = 'DAV')
          / NULLIF(SUM(demand_units) FILTER (WHERE warehouse_code = 'DAV'), 0), 2)
                                                                         AS dav_unmet_rate_pct,
    COUNT(*) FILTER (WHERE warehouse_code <> 'DAV')                      AS other_weeks,
    ROUND(100.0 * SUM(unmet_units) FILTER (WHERE warehouse_code <> 'DAV')
          / NULLIF(SUM(demand_units) FILTER (WHERE warehouse_code <> 'DAV'), 0), 2)
                                                                         AS other_sites_unmet_rate_pct
FROM   vw_weekly_service_position
WHERE  week_ending_date >= DATE '2025-01-01'
  AND  prior_cover_weeks >= 8
  AND  demand_units > 0
GROUP  BY stock_depth_band
ORDER  BY stock_depth_band;


\echo '=== 9. Candidate D — transfers out of the national distribution centre ==='

-- Daventry ships stock to the regional sites. If those transfers were draining
-- lines that customers then wanted, the weeks with transfers out should carry a
-- higher shortfall rate than weeks without.
WITH transfer_week AS (
    SELECT
        sm.sku,
        sm.warehouse_code,
        cw.week_ending_date,
        -SUM(sm.quantity)                                                AS units_transferred_out
    FROM       stock_movement AS sm
    INNER JOIN calendar_week  AS cw
           ON  sm.movement_date BETWEEN cw.week_starting_date AND cw.week_ending_date
    WHERE      sm.movement_type = 'Transfer out'
    GROUP  BY  sm.sku, sm.warehouse_code, cw.week_ending_date
)

SELECT
    p.warehouse_code,
    COUNT(*) FILTER (WHERE t.units_transferred_out IS NOT NULL)          AS weeks_with_a_transfer_out,
    COUNT(*) FILTER (WHERE t.units_transferred_out IS NULL)              AS weeks_without,
    ROUND(100.0 * SUM(p.unmet_units) FILTER (WHERE t.units_transferred_out IS NOT NULL)
          / NULLIF(SUM(p.demand_units) FILTER (WHERE t.units_transferred_out IS NOT NULL), 0), 2)
                                                                         AS unmet_rate_transfer_weeks_pct,
    ROUND(100.0 * SUM(p.unmet_units) FILTER (WHERE t.units_transferred_out IS NULL)
          / NULLIF(SUM(p.demand_units) FILTER (WHERE t.units_transferred_out IS NULL), 0), 2)
                                                                         AS unmet_rate_other_weeks_pct,
    SUM(t.units_transferred_out)                                         AS units_transferred_out
FROM       vw_weekly_service_position AS p
LEFT JOIN  transfer_week              AS t
       ON  t.sku = p.sku AND t.warehouse_code = p.warehouse_code
      AND  t.week_ending_date = p.week_ending_date
WHERE      p.week_ending_date >= DATE '2025-01-01'
  AND      p.demand_units > 0
GROUP  BY  p.warehouse_code
ORDER  BY  p.warehouse_code;


\echo '=== 10. Reconciliation ==='

SELECT
    'Average 2025 stock — sum of sites'                                  AS measure,
    ROUND((SELECT SUM(site_avg) FROM
             (SELECT SUM(stock_value_gbp) / COUNT(DISTINCT week_ending_date) AS site_avg
              FROM mv_inventory_week WHERE year = :analysis_year
              GROUP BY warehouse_code) AS s), 2)                          AS value
UNION ALL
SELECT 'Average 2025 stock — network total, must match file 01',
       ROUND((SELECT SUM(stock_value_gbp) / COUNT(DISTINCT week_ending_date)
              FROM mv_inventory_week WHERE year = :analysis_year), 2)
UNION ALL
SELECT 'Unmet value 2025 — sum of sites',
       ROUND((SELECT SUM(unmet_value_gbp) FROM vw_demand_line
              WHERE order_date BETWEEN DATE '2025-01-01' AND DATE '2025-12-31'), 2)
UNION ALL
SELECT 'Demand lines 2025 — sum of sites',
       (SELECT COUNT(*) FROM vw_demand_line
        WHERE order_date BETWEEN DATE '2025-01-01' AND DATE '2025-12-31')::numeric;
