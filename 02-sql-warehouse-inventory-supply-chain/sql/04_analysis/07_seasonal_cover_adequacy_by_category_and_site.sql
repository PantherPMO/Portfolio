/* ============================================================
   Project    : 02 — Warehouse Inventory & Supply Chain Performance
   File       : 04_analysis/07_seasonal_cover_adequacy_by_category_and_site.sql
   Question   : BQ-04 / AQ-07 — Does cover flex with the season, and
                where does the shortfall land relative to the demand peak?
   Finding ID : F-07
   Output     : analysis/query_results/analyse_07_seasonal_cover_adequacy.txt
   Author     : Peters
   Created    : 2026-08-23
   ============================================================

   Calderfield Trade Supplies Ltd is fictional and this data is synthetic.

   NO ASSUMED ANSWER. The implementation plan expected Heating shortages
   at Warrington. It did not assume when, and this file does not either:
   the monthly pattern is measured from the data and the demand peak and
   the shortage peak are located independently before either is
   described. If they coincide, that is one finding. If the shortage
   trails the peak, that is a different one and it points at
   replenishment response rather than at the size of the buffer.

   Sample sizes are small. Twenty-four months, eight categories, four
   sites. A monthly rate at category-and-site level can rest on very few
   order lines, so counts are printed alongside every rate and no
   correlation over 24 points is treated as more than suggestive.

   Both years are pooled by calendar month to get two observations per
   month rather than one. Bristol contributes only from July 2024, so
   its months carry different weight and it is reported separately
   wherever the comparison depends on equal exposure.
   ============================================================ */

SET search_path TO supply;

\set analysis_start '2024-01-01'
\set analysis_end   '2025-12-31'


\echo '=== 1. Seasonal demand shape by category, measured not assumed ==='

DROP VIEW IF EXISTS vw_monthly_seasonal CASCADE;

CREATE VIEW vw_monthly_seasonal AS

WITH monthly_demand AS (
    SELECT
        d.category_code,
        d.warehouse_code,
        EXTRACT(MONTH FROM d.order_date)::int                            AS month_number,
        COUNT(*)                                                         AS demand_lines,
        SUM(d.demand_units)                                              AS demand_units,
        SUM(d.unmet_units)                                               AS unmet_units,
        SUM(d.unmet_value_gbp)                                           AS unmet_value_gbp
    FROM   vw_demand_line AS d
    WHERE  d.order_date BETWEEN DATE :'analysis_start' AND DATE :'analysis_end'
    GROUP  BY d.category_code, d.warehouse_code, month_number
),

monthly_stock AS (
    SELECT
        m.category_code,
        m.warehouse_code,
        m.month_number,
        COUNT(*)                                                         AS sku_weeks,
        SUM(m.days_at_zero_in_week)                                      AS zero_days,
        COUNT(*) FILTER (WHERE m.days_at_zero_in_week > 0)               AS weeks_with_a_zero_day,
        AVG(m.cover_weeks) FILTER (WHERE m.cover_weeks IS NOT NULL)      AS mean_cover_weeks,
        AVG(m.quantity_on_hand)                                          AS mean_units_on_hand
    FROM   mv_inventory_week AS m
    GROUP  BY m.category_code, m.warehouse_code, m.month_number
)

SELECT
    s.category_code,
    s.warehouse_code,
    s.month_number,
    TO_CHAR(TO_DATE(s.month_number::text, 'MM'), 'Mon')                  AS month_name,
    COALESCE(d.demand_lines, 0)                                          AS demand_lines,
    COALESCE(d.demand_units, 0)                                          AS demand_units,
    COALESCE(d.unmet_units, 0)                                           AS unmet_units,
    ROUND(COALESCE(d.unmet_value_gbp, 0), 0)                             AS unmet_value_gbp,
    s.sku_weeks,
    s.zero_days,
    s.weeks_with_a_zero_day,
    ROUND(s.mean_cover_weeks::numeric, 1)                                AS mean_cover_weeks,
    ROUND(s.mean_units_on_hand::numeric, 1)                              AS mean_units_on_hand,
    -- Demand index: this month against the category-and-site average month.
    ROUND((COALESCE(d.demand_units, 0)
           / NULLIF(AVG(COALESCE(d.demand_units, 0)) OVER (
                 PARTITION BY s.category_code, s.warehouse_code), 0))::numeric, 2)
                                                                         AS demand_index,
    ROUND((s.zero_days::numeric / NULLIF(s.sku_weeks, 0) * 7)::numeric, 3)
                                                                         AS zero_day_rate_pct_of_days,
    ROUND((s.mean_cover_weeks
           / NULLIF(AVG(s.mean_cover_weeks) OVER (
                 PARTITION BY s.category_code, s.warehouse_code), 0))::numeric, 2)
                                                                         AS cover_index
FROM       monthly_stock  AS s
LEFT JOIN  monthly_demand AS d
       ON  d.category_code = s.category_code
      AND  d.warehouse_code = s.warehouse_code
      AND  d.month_number  = s.month_number;


-- Network seasonal shape, pooling both years.
SELECT
    category_code,
    ROUND(SUM(demand_units) FILTER (WHERE month_number = 1)
          / NULLIF(SUM(demand_units)::numeric / 12, 0), 2)               AS jan,
    ROUND(SUM(demand_units) FILTER (WHERE month_number = 2)
          / NULLIF(SUM(demand_units)::numeric / 12, 0), 2)               AS feb,
    ROUND(SUM(demand_units) FILTER (WHERE month_number = 3)
          / NULLIF(SUM(demand_units)::numeric / 12, 0), 2)               AS mar,
    ROUND(SUM(demand_units) FILTER (WHERE month_number = 4)
          / NULLIF(SUM(demand_units)::numeric / 12, 0), 2)               AS apr,
    ROUND(SUM(demand_units) FILTER (WHERE month_number = 5)
          / NULLIF(SUM(demand_units)::numeric / 12, 0), 2)               AS may,
    ROUND(SUM(demand_units) FILTER (WHERE month_number = 6)
          / NULLIF(SUM(demand_units)::numeric / 12, 0), 2)               AS jun,
    ROUND(SUM(demand_units) FILTER (WHERE month_number = 7)
          / NULLIF(SUM(demand_units)::numeric / 12, 0), 2)               AS jul,
    ROUND(SUM(demand_units) FILTER (WHERE month_number = 8)
          / NULLIF(SUM(demand_units)::numeric / 12, 0), 2)               AS aug,
    ROUND(SUM(demand_units) FILTER (WHERE month_number = 9)
          / NULLIF(SUM(demand_units)::numeric / 12, 0), 2)               AS sep,
    ROUND(SUM(demand_units) FILTER (WHERE month_number = 10)
          / NULLIF(SUM(demand_units)::numeric / 12, 0), 2)               AS oct,
    ROUND(SUM(demand_units) FILTER (WHERE month_number = 11)
          / NULLIF(SUM(demand_units)::numeric / 12, 0), 2)               AS nov,
    ROUND(SUM(demand_units) FILTER (WHERE month_number = 12)
          / NULLIF(SUM(demand_units)::numeric / 12, 0), 2)               AS dec,
    SUM(demand_units)                                                    AS total_units
FROM   vw_monthly_seasonal
GROUP  BY category_code
ORDER  BY category_code;


\echo '=== 2. Where the demand peak sits, and where the shortage peak sits ==='

-- The two peaks are located independently. The gap between them is the finding,
-- whichever way it falls.
WITH network_month AS (
    SELECT
        category_code,
        month_number,
        SUM(demand_units)                                                AS demand_units,
        SUM(zero_days)                                                   AS zero_days,
        SUM(sku_weeks)                                                   AS sku_weeks,
        SUM(unmet_units)                                                 AS unmet_units
    FROM   vw_monthly_seasonal
    GROUP  BY category_code, month_number
),

peaks AS (
    SELECT
        category_code,
        month_number,
        demand_units,
        zero_days::numeric / NULLIF(sku_weeks, 0)                        AS zero_days_per_sku_week,
        ROW_NUMBER() OVER (PARTITION BY category_code
                           ORDER BY demand_units DESC)                   AS demand_rank,
        ROW_NUMBER() OVER (PARTITION BY category_code
                           ORDER BY zero_days::numeric / NULLIF(sku_weeks, 0) DESC)
                                                                         AS shortage_rank
    FROM   network_month
)

SELECT
    category_code,
    MAX(month_number) FILTER (WHERE demand_rank = 1)                     AS peak_demand_month,
    TO_CHAR(TO_DATE(MAX(month_number) FILTER (WHERE demand_rank = 1)::text, 'MM'), 'Mon')
                                                                         AS peak_demand_month_name,
    MAX(month_number) FILTER (WHERE shortage_rank = 1)                   AS peak_shortage_month,
    TO_CHAR(TO_DATE(MAX(month_number) FILTER (WHERE shortage_rank = 1)::text, 'MM'), 'Mon')
                                                                         AS peak_shortage_month_name,
    -- Months from demand peak to shortage peak, wrapped into 0-11.
    ((MAX(month_number) FILTER (WHERE shortage_rank = 1)
      - MAX(month_number) FILTER (WHERE demand_rank = 1)) + 12) % 12     AS months_shortage_trails_demand,
    ROUND(MAX(zero_days_per_sku_week) FILTER (WHERE shortage_rank = 1), 3)
                                                                         AS peak_zero_days_per_sku_week
FROM   peaks
GROUP  BY category_code
ORDER  BY months_shortage_trails_demand DESC, category_code;


\echo '=== 3. Heating, month by month, by site ==='

SELECT
    warehouse_code,
    month_number,
    month_name,
    demand_lines,
    demand_units,
    demand_index,
    mean_cover_weeks,
    cover_index,
    zero_days,
    sku_weeks,
    ROUND(zero_days::numeric / NULLIF(sku_weeks, 0), 3)                  AS zero_days_per_sku_week,
    unmet_units,
    unmet_value_gbp
FROM   vw_monthly_seasonal
WHERE  category_code = 'HEAT'
ORDER  BY warehouse_code, month_number;


\echo '=== 4. Ventilation, the summer-peak counter-example ==='

-- If the lag is a replenishment-response effect it should appear on a category
-- with the opposite season too. If it only appears in winter it is something
-- about winter.
SELECT
    warehouse_code,
    month_number,
    month_name,
    demand_units,
    demand_index,
    mean_cover_weeks,
    cover_index,
    zero_days,
    sku_weeks,
    ROUND(zero_days::numeric / NULLIF(sku_weeks, 0), 3)                  AS zero_days_per_sku_week
FROM   vw_monthly_seasonal
WHERE  category_code = 'VENT'
ORDER  BY warehouse_code, month_number;


\echo '=== 5. Does cover flex with demand at all? ==='

-- The structural question behind the whole file. If policies are sized on an
-- annual average, cover will not rise ahead of the peak and the correlation
-- between demand index and cover index will be flat or negative.
-- 12 monthly points per category and site. Suggestive only, never conclusive.
SELECT
    category_code,
    warehouse_code,
    COUNT(*)                                                             AS months_observed,
    ROUND(CORR(demand_index, cover_index)::numeric, 2)                   AS corr_demand_vs_cover,
    ROUND(CORR(demand_index, zero_day_rate_pct_of_days)::numeric, 2)     AS corr_demand_vs_shortage,
    ROUND(MAX(demand_index) - MIN(demand_index), 2)                      AS demand_index_range,
    ROUND(MAX(cover_index) - MIN(cover_index), 2)                        AS cover_index_range
FROM   vw_monthly_seasonal
WHERE  category_code IN ('HEAT', 'VENT', 'DRAIN')
GROUP  BY category_code, warehouse_code
ORDER  BY category_code, warehouse_code;


\echo '=== 6. Is the reorder point big enough for the peak month? ==='

-- The mechanism test. A reorder point sized on an annual average is by
-- construction too small in a month running well above that average. This
-- compares each policy against the demand the line actually saw in its own
-- busiest month.
WITH monthly_sku_demand AS (
    SELECT
        d.sku,
        d.warehouse_code,
        EXTRACT(MONTH FROM d.order_date)::int                            AS month_number,
        SUM(d.demand_units) / 2.0                                        AS mean_monthly_units
    FROM   vw_demand_line AS d
    WHERE  d.order_date BETWEEN DATE :'analysis_start' AND DATE :'analysis_end'
    GROUP  BY d.sku, d.warehouse_code, month_number
),

sku_profile AS (
    SELECT
        sku,
        warehouse_code,
        AVG(mean_monthly_units)                                          AS average_month_units,
        MAX(mean_monthly_units)                                          AS peak_month_units,
        COUNT(*)                                                         AS months_with_demand
    FROM   monthly_sku_demand
    GROUP  BY sku, warehouse_code
),

policy_versus_peak AS (
    SELECT
        p.sku,
        p.warehouse_code,
        m.category_code,
        m.reorder_point_units,
        m.reorder_quantity_units,
        p.average_month_units,
        p.peak_month_units,
        p.months_with_demand,
        p.peak_month_units / NULLIF(p.average_month_units, 0)            AS peak_to_average_ratio,
        m.reorder_point_units / NULLIF(p.average_month_units, 0)         AS reorder_point_average_months,
        m.reorder_point_units / NULLIF(p.peak_month_units, 0)            AS reorder_point_peak_months
    FROM       sku_profile        AS p
    INNER JOIN mv_inventory_week  AS m
           ON  m.sku = p.sku AND m.warehouse_code = p.warehouse_code
          AND  m.week_ending_date = DATE '2025-12-28'
    WHERE      p.months_with_demand >= 6
)

SELECT
    category_code,
    warehouse_code,
    COUNT(*)                                                             AS lines,
    ROUND(AVG(peak_to_average_ratio)::numeric, 2)                        AS mean_peak_to_average,
    ROUND(AVG(reorder_point_average_months)::numeric, 2)                 AS reorder_point_in_average_months,
    ROUND(AVG(reorder_point_peak_months)::numeric, 2)                    AS reorder_point_in_peak_months,
    COUNT(*) FILTER (WHERE reorder_point_peak_months < 0.5)              AS lines_under_half_a_peak_month
FROM   policy_versus_peak
WHERE  category_code IN ('HEAT', 'VENT', 'DRAIN', 'RENW')
GROUP  BY category_code, warehouse_code
ORDER  BY category_code, reorder_point_in_peak_months;


\echo '=== 7. Heating at Warrington against Heating everywhere else ==='

-- The specific comparison the plan asked for, with the counts behind it.
SELECT
    month_number,
    month_name,
    SUM(demand_units) FILTER (WHERE warehouse_code = 'WAR')              AS warrington_demand_units,
    SUM(zero_days) FILTER (WHERE warehouse_code = 'WAR')                 AS warrington_zero_days,
    ROUND(SUM(zero_days) FILTER (WHERE warehouse_code = 'WAR')::numeric
          / NULLIF(SUM(sku_weeks) FILTER (WHERE warehouse_code = 'WAR'), 0), 3)
                                                                         AS warrington_zero_days_per_week,
    ROUND(SUM(zero_days) FILTER (WHERE warehouse_code <> 'WAR')::numeric
          / NULLIF(SUM(sku_weeks) FILTER (WHERE warehouse_code <> 'WAR'), 0), 3)
                                                                         AS other_sites_zero_days_per_week,
    SUM(demand_lines) FILTER (WHERE warehouse_code = 'WAR')              AS warrington_demand_lines,
    SUM(unmet_units) FILTER (WHERE warehouse_code = 'WAR')               AS warrington_unmet_units,
    ROUND(SUM(unmet_value_gbp) FILTER (WHERE warehouse_code = 'WAR'), 0) AS warrington_unmet_gbp
FROM   vw_monthly_seasonal
WHERE  category_code = 'HEAT'
GROUP  BY month_number, month_name
ORDER  BY month_number;
