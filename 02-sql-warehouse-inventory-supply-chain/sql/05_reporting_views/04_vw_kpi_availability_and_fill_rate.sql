/* ============================================================
   Project    : 02 — Warehouse Inventory & Supply Chain Performance
   File       : 05_reporting_views/04_vw_kpi_availability_and_fill_rate.sql
   KPI        : Stockout Rate — _portfolio/KPI_LIBRARY.md
                plus two project-specific measures defined in the charter
   Output     : view supply.vw_kpi_availability_and_fill_rate
                analysis/query_results/report_04_availability_and_fill_rate.txt
   Author     : Peters
   Created    : 2026-08-23
   ============================================================

   Calderfield Trade Supplies Ltd is fictional and this data is synthetic.

   KPI DEFINITION, from the library.

     Stockout Rate   Periods with zero stock / Total periods x 100
     Unit            %

   THE LIBRARY DEFINES ONE MEASURE. THIS PROJECT REPORTS THREE, AND
   THEY MUST TRAVEL TOGETHER (AQ-06, charter trap 3).

     1. Closing-zero weeks     SKU-weeks with no stock at the Sunday
                               snapshot. The literal library definition.
                               Network 3.52%.
     2. Zero-day exposure      SKU-weeks containing at least one day at
                               zero. Catches the stockout that clears
                               before Sunday. Network 5.05%.
     3. Line fill              Order lines not supplied in full, from
                               quantities. Network 7.71%.

   Quoting any one alone is a choice about which answer to give. The
   snapshot measure understates the day-level measure by 1.26x to 1.67x
   depending on the site, and both understate what the customer
   experienced, because a line can be short-shipped from a position that
   never reached zero.

   D-03. Fulfilment is read from quantities, never from `line_status`.
   A line despatched in full and later returned carries the status
   `Returned`, which overwrites what it said about fulfilment. Filtering
   on `line_status = 'Despatched in full'` discards 2,906 lines and
   £2,084,119 of unmet demand — the whole measurement. Demand excludes
   `Cancelled` lines and nothing else: cancelled demand was withdrawn
   before it became a claim on stock; unsupplied demand is demand the
   business failed to meet and belongs in the denominator.

   TWO CLOCKS, AND THEY DO NOT AGREE TO THE POUND (D-22). The stock
   measures run on the 52 ISO snapshot weeks of 2025. The fulfilment
   measures run on order date within calendar 2025, which includes the
   133 lines dated 29-31 December that no snapshot week covers (D-13).
   Unmet demand is £1,027,629 on the order-date basis and £1,025,038 on
   the snapshot-week basis; the £2,591 difference is that boundary and
   is reported in section 5 rather than reconciled away.

   UNMET DEMAND IS AN UPPER BOUND. Substitution is not modelled
   (charter §8). Some of these customers would have taken an
   alternative; some would have waited.
   ============================================================ */

SET search_path TO supply;

\set analysis_year 2025


CREATE OR REPLACE VIEW vw_kpi_availability_and_fill_rate AS

WITH stock_weeks AS (
    SELECT
        m.warehouse_code,
        m.category_code,
        COUNT(*)                                                         AS sku_weeks,
        COUNT(*) FILTER (WHERE m.quantity_on_hand = 0)                   AS weeks_closing_at_zero,
        COUNT(*) FILTER (WHERE m.days_at_zero_in_week > 0)               AS weeks_with_a_zero_day,
        SUM(m.days_at_zero_in_week)                                      AS days_at_zero,
        COUNT(*) * 7                                                     AS days_observed,
        AVG(m.cover_weeks) FILTER (WHERE m.cover_weeks IS NOT NULL)      AS mean_cover_weeks
    FROM   mv_inventory_week AS m
    WHERE  m.year = :analysis_year
    GROUP  BY GROUPING SETS ((), (m.warehouse_code), (m.category_code),
                             (m.warehouse_code, m.category_code))
),

fulfilment AS (
    -- Order-date basis, so the 133 lines dated after the last snapshot
    -- week are retained (D-13). Cancelled lines are already excluded by
    -- vw_demand_line; nothing else is (D-03).
    SELECT
        d.warehouse_code,
        d.category_code,
        COUNT(*)                                                         AS demand_lines,
        COUNT(*) FILTER (WHERE NOT d.is_supplied_in_full)                AS lines_not_supplied_in_full,
        COUNT(*) FILTER (WHERE d.is_wholly_unsupplied)                   AS lines_wholly_unsupplied,
        SUM(d.demand_units)                                              AS demand_units,
        SUM(d.supplied_units)                                            AS supplied_units,
        SUM(d.unmet_units)                                               AS unmet_units,
        SUM(d.demand_value_gbp)                                          AS demand_value_gbp,
        SUM(d.unmet_value_gbp)                                           AS unmet_value_gbp
    FROM   vw_demand_line AS d
    WHERE  EXTRACT(YEAR FROM d.order_date)::int = :analysis_year
    GROUP  BY GROUPING SETS ((), (d.warehouse_code), (d.category_code),
                             (d.warehouse_code, d.category_code))
)

SELECT
    CASE WHEN s.warehouse_code IS NULL AND s.category_code IS NULL THEN '1 — network'
         WHEN s.category_code  IS NULL                             THEN '2 — site'
         WHEN s.warehouse_code IS NULL                             THEN '3 — category'
         ELSE                                                           '4 — site and category'
    END                                                                  AS grain_level,
    COALESCE(s.warehouse_code, 'ALL SITES')                              AS warehouse_code,
    COALESCE(s.category_code, 'ALL CATEGORIES')                          AS category_code,

    -- Measure 1 — the library definition, on the Sunday snapshot.
    s.sku_weeks,
    s.weeks_closing_at_zero,
    ROUND(100.0 * s.weeks_closing_at_zero / NULLIF(s.sku_weeks, 0), 2)   AS closing_zero_rate_pct,

    -- Measure 2 — any day at zero inside the week.
    s.weeks_with_a_zero_day,
    ROUND(100.0 * s.weeks_with_a_zero_day / NULLIF(s.sku_weeks, 0), 2)   AS any_zero_day_rate_pct,
    s.days_at_zero,
    ROUND(100.0 * s.days_at_zero / NULLIF(s.days_observed, 0), 2)        AS days_at_zero_rate_pct,
    -- How far the snapshot measure understates the day measure. A value
    -- of 1.67 means two thirds of Bristol's stockouts cleared before the
    -- snapshot was taken.
    ROUND(s.weeks_with_a_zero_day::numeric
          / NULLIF(s.weeks_closing_at_zero, 0), 2)                       AS snapshot_understatement_factor,

    -- Measure 3 — what the customer actually experienced.
    f.demand_lines,
    f.lines_not_supplied_in_full,
    f.lines_wholly_unsupplied,
    ROUND(100.0 * (f.demand_lines - f.lines_not_supplied_in_full)
          / NULLIF(f.demand_lines, 0), 2)                                AS line_fill_rate_pct,
    ROUND(100.0 * f.lines_not_supplied_in_full
          / NULLIF(f.demand_lines, 0), 2)                                AS lines_short_rate_pct,
    f.demand_units,
    f.unmet_units,
    ROUND(100.0 * f.supplied_units / NULLIF(f.demand_units, 0), 2)       AS unit_fill_rate_pct,
    ROUND(f.demand_value_gbp, 2)                                         AS demand_value_gbp,
    ROUND(f.unmet_value_gbp, 2)                                          AS unmet_value_gbp,
    ROUND(100.0 * f.unmet_value_gbp / NULLIF(f.demand_value_gbp, 0), 2)  AS unmet_share_of_demand_pct,
    ROUND(s.mean_cover_weeks, 1)                                         AS mean_cover_weeks
FROM       stock_weeks AS s
LEFT  JOIN fulfilment  AS f
       ON  f.warehouse_code IS NOT DISTINCT FROM s.warehouse_code
      AND  f.category_code  IS NOT DISTINCT FROM s.category_code;


\echo '=== 1. The three measures at network level, reconciling to file 06 ==='

-- Expected from analyse_06_unmet_demand_availability.txt:
--   closing-zero 943 / 26,780 = 3.52%
--   any-zero-day 1,353 / 26,780 = 5.05%
--   lines not in full 1,272 / 16,506 = 7.71%
SELECT
    measure, numerator, denominator, rate_pct, what_it_measures
FROM (
SELECT
    1                                                                    AS sort_order,
    'Weeks closing at zero'                                              AS measure,
    weeks_closing_at_zero                                                AS numerator,
    sku_weeks                                                            AS denominator,
    closing_zero_rate_pct                                                AS rate_pct,
    'SKU-weeks with no stock at the Sunday snapshot'                     AS what_it_measures
FROM   vw_kpi_availability_and_fill_rate WHERE grain_level = '1 — network'
UNION ALL
SELECT 2, 'Weeks containing a zero-stock day', weeks_with_a_zero_day, sku_weeks,
       any_zero_day_rate_pct,
       'SKU-weeks in which the site held nothing on at least one day'
FROM   vw_kpi_availability_and_fill_rate WHERE grain_level = '1 — network'
UNION ALL
SELECT 3, 'Order lines not supplied in full', lines_not_supplied_in_full, demand_lines,
       lines_short_rate_pct,
       'Customer order lines short-shipped or wholly unsupplied'
FROM   vw_kpi_availability_and_fill_rate WHERE grain_level = '1 — network'
UNION ALL
SELECT 4, 'Order lines wholly unsupplied', lines_wholly_unsupplied, demand_lines,
       ROUND(100.0 * lines_wholly_unsupplied / NULLIF(demand_lines, 0), 2),
       'Customer order lines that received nothing at all'
FROM   vw_kpi_availability_and_fill_rate WHERE grain_level = '1 — network'
UNION ALL
SELECT 5, 'Units not supplied', unmet_units, demand_units,
       ROUND(100.0 * unmet_units / NULLIF(demand_units, 0), 2),
       'Units ordered that were never despatched'
FROM   vw_kpi_availability_and_fill_rate WHERE grain_level = '1 — network'
) AS three_measures
ORDER  BY sort_order;


\echo '=== 2. All three measures by site ==='

SELECT
    warehouse_code,
    sku_weeks,
    closing_zero_rate_pct,
    any_zero_day_rate_pct,
    snapshot_understatement_factor,
    demand_lines,
    line_fill_rate_pct,
    unit_fill_rate_pct,
    unmet_units,
    unmet_value_gbp,
    mean_cover_weeks
FROM   vw_kpi_availability_and_fill_rate
WHERE  grain_level = '2 — site'
ORDER  BY line_fill_rate_pct;


\echo '=== 3. All three measures by category ==='

SELECT
    category_code,
    sku_weeks,
    closing_zero_rate_pct,
    any_zero_day_rate_pct,
    demand_lines,
    line_fill_rate_pct,
    unmet_units,
    unmet_value_gbp,
    mean_cover_weeks
FROM   vw_kpi_availability_and_fill_rate
WHERE  grain_level = '3 — category'
ORDER  BY line_fill_rate_pct;


\echo '=== 4. Validation: the three measures disagree, and by how much ==='

-- Not a failure. The point of carrying three is that they measure
-- different things. This table quantifies the gap so nobody quotes the
-- smallest number without knowing what it excludes.
SELECT
    warehouse_code,
    closing_zero_rate_pct                                                AS measure_1_snapshot,
    any_zero_day_rate_pct                                                AS measure_2_any_zero_day,
    lines_short_rate_pct                                                 AS measure_3_lines_short,
    ROUND(any_zero_day_rate_pct - closing_zero_rate_pct, 2)              AS day_over_snapshot_points,
    ROUND(lines_short_rate_pct - any_zero_day_rate_pct, 2)               AS customer_over_day_points
FROM   vw_kpi_availability_and_fill_rate
WHERE  grain_level IN ('1 — network', '2 — site')
ORDER  BY grain_level, warehouse_code;


\echo '=== 5. Validation: the two clocks, and the boundary between them (D-22) ==='

-- Unmet demand on the order-date basis against the snapshot-week basis.
-- The difference is the 133 lines dated 29-31 December 2025 that fall
-- inside calendar 2025 but inside no snapshot week (D-13).
SELECT
    basis, unmet_value_gbp, demand_lines
FROM (
SELECT
    1                                                                    AS sort_order,
    'Unmet demand, order date within 2025'                               AS basis,
    ROUND(SUM(d.unmet_value_gbp), 2)                                     AS unmet_value_gbp,
    COUNT(*)                                                             AS demand_lines
FROM   vw_demand_line AS d
WHERE  EXTRACT(YEAR FROM d.order_date)::int = :analysis_year
UNION ALL
SELECT 2, 'Unmet demand, snapshot week within 2025',
       ROUND(SUM(d.unmet_value_gbp), 2), COUNT(*)
FROM   vw_demand_line AS d
WHERE  d.week_ending_date BETWEEN DATE '2025-01-01' AND DATE '2025-12-28'
UNION ALL
SELECT 3, 'Boundary — lines dated 29-31 December 2025 (D-13)',
       ROUND(SUM(d.unmet_value_gbp), 2), COUNT(*)
FROM   vw_demand_line AS d
WHERE  EXTRACT(YEAR FROM d.order_date)::int = :analysis_year
  AND  d.week_ending_date IS NULL
) AS two_clocks
ORDER  BY sort_order;


\echo '=== 6. Validation: fulfilment is read from quantities, not line_status ==='

-- A standing guard against the charter''s trap 1. If anyone later filters
-- demand on line_status, this table shows what it costs.
SELECT
    population, lines, unmet_value_gbp
FROM (
SELECT
    1                                                                    AS sort_order,
    'Lines in vw_demand_line (cancelled excluded, D-03)'                 AS population,
    COUNT(*)                                                             AS lines,
    ROUND(SUM(unmet_value_gbp), 2)                                       AS unmet_value_gbp
FROM   vw_demand_line
WHERE  EXTRACT(YEAR FROM order_date)::int = :analysis_year
UNION ALL
SELECT 2, 'Lines carrying status ''Returned'' — fulfilment overwritten',
       COUNT(*) FILTER (WHERE source_line_status = 'Returned'),
       ROUND(SUM(unmet_value_gbp) FILTER (WHERE source_line_status = 'Returned'), 2)
FROM   vw_demand_line
WHERE  EXTRACT(YEAR FROM order_date)::int = :analysis_year
UNION ALL
SELECT 3, 'What a line_status filter would discard',
       COUNT(*) FILTER (WHERE source_line_status <> 'Despatched in full'),
       ROUND(SUM(unmet_value_gbp) FILTER (WHERE source_line_status <> 'Despatched in full'), 2)
FROM   vw_demand_line
WHERE  EXTRACT(YEAR FROM order_date)::int = :analysis_year
) AS status_trap
ORDER  BY sort_order;


\echo '=== 7. Validation: sites and categories partition the same populations ==='

WITH n AS (SELECT sku_weeks, demand_lines, unmet_value_gbp
           FROM vw_kpi_availability_and_fill_rate WHERE grain_level = '1 — network'),
     s AS (SELECT SUM(sku_weeks) AS sku_weeks, SUM(demand_lines) AS demand_lines,
                  SUM(unmet_value_gbp) AS unmet_value_gbp
           FROM vw_kpi_availability_and_fill_rate WHERE grain_level = '2 — site'),
     c AS (SELECT SUM(sku_weeks) AS sku_weeks, SUM(demand_lines) AS demand_lines,
                  SUM(unmet_value_gbp) AS unmet_value_gbp
           FROM vw_kpi_availability_and_fill_rate WHERE grain_level = '3 — category')

SELECT
    'Sites sum to network'                                               AS check_name,
    s.sku_weeks - n.sku_weeks                                            AS sku_week_difference,
    s.demand_lines - n.demand_lines                                      AS demand_line_difference,
    ROUND(s.unmet_value_gbp - n.unmet_value_gbp, 2)                      AS unmet_value_difference_gbp,
    CASE WHEN s.sku_weeks = n.sku_weeks AND s.demand_lines = n.demand_lines
              AND ABS(s.unmet_value_gbp - n.unmet_value_gbp) <= 0.05
         THEN 'PASS' ELSE 'FAIL' END                                     AS result
FROM   n CROSS JOIN s
UNION ALL
SELECT 'Categories sum to network',
       c.sku_weeks - n.sku_weeks, c.demand_lines - n.demand_lines,
       ROUND(c.unmet_value_gbp - n.unmet_value_gbp, 2),
       CASE WHEN c.sku_weeks = n.sku_weeks AND c.demand_lines = n.demand_lines
                 AND ABS(c.unmet_value_gbp - n.unmet_value_gbp) <= 0.05
            THEN 'PASS' ELSE 'FAIL' END
FROM   n CROSS JOIN c;
