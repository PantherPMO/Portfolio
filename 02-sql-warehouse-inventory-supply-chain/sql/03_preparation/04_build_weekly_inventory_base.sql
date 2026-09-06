/* ============================================================
   Project    : 02 — Warehouse Inventory & Supply Chain Performance
   File       : 03_preparation/04_build_weekly_inventory_base.sql
   Question   : For every stocked line at every site, in every week —
                how much stock, worth how much, against how much demand?
   Output     : materialised view supply.mv_inventory_week
   Author     : Peters
   Created    : 2026-08-23
   ============================================================

   Grain: one row per SKU per warehouse per week. 51,220 rows, matching
   inventory_snapshot exactly. Every join below is to a source
   pre-aggregated to that same key, so the grain cannot fan out.

   Materialised rather than a plain view because eleven downstream
   analysis files read it and it carries the most expensive joins in the
   project. It is derived entirely from frozen source tables, so it
   never needs refreshing except after a reload.

   Three measurement rules are built in:

   - Outbound demand is 'Sales issue' only. 'Transfer out' is stock
     moving to another site, not a sale. Counting it as demand overstates
     Daventry, which supplies the regional network. See D-09.

   - Cost of sales is valued at stock_movement.unit_cost_gbp — the
     weighted average cost carried at the time of the issue — not at
     product.standard_cost_gbp. Standard cost is a single rate per SKU
     and would erase the difference between sites that buy from cheap
     importers and sites that buy from UK manufacturers, which is the
     Livingston trade-off the analysis exists to quantify. See D-10.

   - Cover is expressed in weeks against trailing 13-week demand. Where
     there has been no demand in 13 weeks, cover is NULL rather than
     infinity, and the analysis handles those lines through
     weeks_since_last_issue instead.
   ============================================================ */

SET search_path TO supply;

DROP MATERIALIZED VIEW IF EXISTS mv_inventory_week;

CREATE MATERIALIZED VIEW mv_inventory_week AS

WITH weekly_issue AS (
    -- Units and cost leaving the site as customer demand, by week.
    SELECT
        sm.sku,
        sm.warehouse_code,
        cw.week_ending_date,
        -SUM(sm.quantity)                                        AS issued_units,
        ROUND(-SUM(sm.quantity * sm.unit_cost_gbp), 2)           AS issued_cost_gbp
    FROM       stock_movement AS sm
    INNER JOIN calendar_week  AS cw
           ON  sm.movement_date BETWEEN cw.week_starting_date AND cw.week_ending_date
    WHERE      sm.movement_type = 'Sales issue'
    GROUP  BY  sm.sku, sm.warehouse_code, cw.week_ending_date
),

weekly_demand AS (
    -- What was asked for, including what could not be supplied.
    SELECT
        sku,
        warehouse_code,
        week_ending_date,
        SUM(demand_units)                                        AS demand_units,
        SUM(unmet_units)                                         AS unmet_units,
        SUM(unmet_value_gbp)                                     AS unmet_value_gbp,
        COUNT(*)                                                 AS demand_lines,
        COUNT(*) FILTER (WHERE unmet_units > 0)                  AS lines_not_supplied_in_full
    FROM   vw_demand_line
    GROUP  BY sku, warehouse_code, week_ending_date
),

joined AS (
    SELECT
        inv.week_ending_date,
        inv.sku,
        inv.warehouse_code,
        inv.quantity_on_hand,
        inv.quantity_allocated,
        inv.quantity_on_order,
        inv.days_at_zero_in_week,
        inv.weighted_average_cost_gbp,
        inv.stock_value_gbp,
        COALESCE(wi.issued_units, 0)                             AS issued_units,
        COALESCE(wi.issued_cost_gbp, 0)                          AS issued_cost_gbp,
        COALESCE(wd.demand_units, 0)                             AS demand_units,
        COALESCE(wd.unmet_units, 0)                              AS unmet_units,
        COALESCE(wd.unmet_value_gbp, 0)                          AS unmet_value_gbp,
        COALESCE(wd.demand_lines, 0)                             AS demand_lines,
        COALESCE(wd.lines_not_supplied_in_full, 0)               AS lines_not_supplied_in_full
    FROM       inventory_snapshot AS inv
    LEFT JOIN  weekly_issue       AS wi
           ON  wi.sku = inv.sku AND wi.warehouse_code = inv.warehouse_code
          AND  wi.week_ending_date = inv.week_ending_date
    LEFT JOIN  weekly_demand      AS wd
           ON  wd.sku = inv.sku AND wd.warehouse_code = inv.warehouse_code
          AND  wd.week_ending_date = inv.week_ending_date
),

with_trailing AS (
    SELECT
        j.*,
        SUM(j.issued_units) OVER w13                             AS issued_units_13w,
        SUM(j.issued_cost_gbp) OVER w13                          AS issued_cost_13w_gbp,
        SUM(j.demand_units) OVER w13                             AS demand_units_13w,
        SUM(j.unmet_units) OVER w13                              AS unmet_units_13w,
        COUNT(*) OVER w13                                        AS weeks_in_trailing_window,
        -- Running latest week that saw an issue. Cheaper and clearer than a
        -- LATERAL lookup, and it never looks into the future.
        MAX(CASE WHEN j.issued_units > 0 THEN j.week_ending_date END) OVER (
            PARTITION BY j.sku, j.warehouse_code
            ORDER BY     j.week_ending_date
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        )                                                        AS last_issue_week
    FROM   joined AS j
    WINDOW w13 AS (
        PARTITION BY j.sku, j.warehouse_code
        ORDER BY     j.week_ending_date
        ROWS BETWEEN 12 PRECEDING AND CURRENT ROW
    )
)

SELECT
    t.week_ending_date,
    cw.year,
    cw.quarter,
    cw.month_number,
    cw.month_name,
    t.sku,
    p.product_name,
    p.category_code,
    pc.category_name,
    p.discontinued_date,
    p.list_price_gbp,
    p.standard_cost_gbp,
    t.warehouse_code,
    w.warehouse_name,
    w.site_type,
    t.quantity_on_hand,
    t.quantity_allocated,
    t.quantity_on_order,
    t.days_at_zero_in_week,
    t.weighted_average_cost_gbp,
    t.stock_value_gbp,
    t.issued_units,
    t.issued_cost_gbp,
    t.demand_units,
    t.unmet_units,
    t.unmet_value_gbp,
    t.demand_lines,
    t.lines_not_supplied_in_full,
    t.issued_units_13w,
    t.issued_cost_13w_gbp,
    t.demand_units_13w,
    t.unmet_units_13w,
    t.weeks_in_trailing_window,
    -- Weeks of cover at the trailing rate. NULL where nothing has moved in 13
    -- weeks: those lines are slow movers to be measured by age, not by cover.
    ROUND(t.quantity_on_hand
          / NULLIF(t.issued_units_13w::numeric / t.weeks_in_trailing_window, 0), 1)
                                                                 AS cover_weeks,
    t.last_issue_week,
    CASE WHEN t.last_issue_week IS NOT NULL
         THEN ((t.week_ending_date - t.last_issue_week) / 7)::int
    END                                                          AS weeks_since_last_issue,
    rp.reorder_point_units,
    rp.reorder_quantity_units,
    rp.safety_stock_units,
    rp.review_method,
    rp.last_reviewed_date,
    rp.set_by_buyer,
    rp.stocked_since,
    -- Anchored to the fixed analysis date, never CURRENT_DATE, so a committed
    -- result stays reproducible. See D-05.
    ((DATE '2025-12-31' - rp.last_reviewed_date) / 30.44)::numeric(6,1)
                                                                 AS policy_age_months
FROM       with_trailing        AS t
INNER JOIN calendar_week        AS cw ON cw.week_ending_date = t.week_ending_date
INNER JOIN product              AS p  ON p.sku = t.sku
INNER JOIN product_category     AS pc ON pc.category_code = p.category_code
INNER JOIN warehouse            AS w  ON w.warehouse_code = t.warehouse_code
INNER JOIN replenishment_policy AS rp
       ON  rp.sku = t.sku AND rp.warehouse_code = t.warehouse_code;


CREATE UNIQUE INDEX idx_mv_inventory_week_key
    ON mv_inventory_week (week_ending_date, sku, warehouse_code);

CREATE INDEX idx_mv_inventory_week_site_week
    ON mv_inventory_week (warehouse_code, week_ending_date);

CREATE INDEX idx_mv_inventory_week_category
    ON mv_inventory_week (category_code, week_ending_date);

ANALYZE mv_inventory_week;


\echo '=== Grain check: one row per snapshot, nothing gained or lost ==='

SELECT
    (SELECT COUNT(*) FROM inventory_snapshot)        AS snapshot_rows,
    (SELECT COUNT(*) FROM mv_inventory_week)         AS base_rows,
    (SELECT COUNT(*) FROM (SELECT week_ending_date, sku, warehouse_code
                           FROM mv_inventory_week
                           GROUP BY 1, 2, 3 HAVING COUNT(*) > 1) AS d)
                                                     AS duplicated_keys,
    CASE WHEN (SELECT COUNT(*) FROM inventory_snapshot) = (SELECT COUNT(*) FROM mv_inventory_week)
         THEN 'PASS' ELSE 'FAIL' END                 AS result;


\echo '=== Reconciliation: demand and issues tie back to source ==='

SELECT
    'Sales issue units'                                                   AS measure,
    (SELECT -SUM(quantity) FROM stock_movement
     WHERE movement_type = 'Sales issue'
       AND movement_date <= DATE '2025-12-28')                            AS source_value,
    (SELECT SUM(issued_units) FROM mv_inventory_week)                     AS base_value
UNION ALL
SELECT
    'Demand units (non-cancelled order lines)',
    (SELECT SUM(demand_units) FROM vw_demand_line),
    (SELECT SUM(demand_units) FROM mv_inventory_week)
UNION ALL
SELECT
    'Closing stock value at 2025-12-28',
    (SELECT SUM(stock_value_gbp) FROM inventory_snapshot
     WHERE week_ending_date = DATE '2025-12-28'),
    (SELECT SUM(stock_value_gbp) FROM mv_inventory_week
     WHERE week_ending_date = DATE '2025-12-28');


\echo '=== Shape of the base ==='

SELECT
    warehouse_code,
    COUNT(*)                                                             AS rows,
    COUNT(DISTINCT sku)                                                  AS skus,
    COUNT(DISTINCT week_ending_date)                                     AS weeks,
    COUNT(*) FILTER (WHERE cover_weeks IS NULL)                          AS rows_without_cover,
    ROUND(AVG(cover_weeks) FILTER (WHERE cover_weeks IS NOT NULL), 1)    AS mean_cover_weeks,
    ROUND(AVG(policy_age_months), 1)                                     AS mean_policy_age_months
FROM   mv_inventory_week
GROUP  BY warehouse_code
ORDER  BY warehouse_code;
