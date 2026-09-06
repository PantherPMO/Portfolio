/* ============================================================
   Project    : 02 — Warehouse Inventory & Supply Chain Performance
   File       : 04_analysis/10_range_mix_adjusted_warehouse_comparison.sql
   Question   : BQ-05 / AQ-10 — How much of each site's headline
                inventory performance is its own management, and how
                much is the range it happens to carry?
   Finding ID : F-10
   Output     : analysis/query_results/analyse_10_range_mix_adjusted.txt
   Author     : Peters
   Created    : 2026-08-23
   ============================================================

   Calderfield Trade Supplies Ltd is fictional and this data is synthetic.

   REFRAMED AFTER FILE 09. The implementation plan expected this file to
   rescue Daventry from an unfairly poor raw ranking. It cannot: Daventry
   turns 4.68 against a network 4.67, which is the average, not the
   bottom. The correction runs in both directions and the size of each
   site's correction is the finding, not its direction.

   Two independent adjustments, because each has a different weakness.

   A. THE COMMON BASKET. Restrict every site to the SKUs all four
      stock. A true like-for-like comparison, but it discards most of
      Daventry's range and most of the network's stock value, so it
      answers a narrower question than it appears to.

   B. CATEGORY STANDARDISATION. Give every site the network's category
      mix and recompute. Uses all the data and corrects for mix
      directly, but assumes a site's performance within a category is
      independent of how much of that category it carries.

   Agreement between two methods with different weaknesses is worth more
   than either alone. Where they disagree, that is reported too.

   2025 only, so all four sites carry a full 52 weeks (Bristol has 78 of
   104 overall). Cost of sales is 'Sales issue' at ledger weighted
   average cost, transfers excluded (D-09, D-10).
   ============================================================ */

SET search_path TO supply;

\set analysis_year 2025
\set snapshot_date '2025-12-28'


\echo '=== 1. What each site actually carries ==='

DROP VIEW IF EXISTS vw_range_footprint CASCADE;

CREATE VIEW vw_range_footprint AS

WITH sku_reach AS (
    -- Grain: one row per SKU. Counts the sites that stocked it in 2025.
    SELECT
        sku,
        COUNT(DISTINCT warehouse_code)                                   AS sites_stocking
    FROM   mv_inventory_week
    WHERE  year = :analysis_year
    GROUP  BY sku
)

SELECT
    m.warehouse_code,
    m.sku,
    m.category_code,
    r.sites_stocking,
    SUM(m.stock_value_gbp) / COUNT(DISTINCT m.week_ending_date)          AS average_stock_gbp,
    SUM(m.issued_cost_gbp)                                               AS cost_of_sales_gbp,
    SUM(m.issued_units)                                                  AS issued_units
FROM       mv_inventory_week AS m
INNER JOIN sku_reach         AS r ON r.sku = m.sku
WHERE      m.year = :analysis_year
GROUP  BY  m.warehouse_code, m.sku, m.category_code, r.sites_stocking;


SELECT
    sites_stocking,
    COUNT(DISTINCT sku)                                                  AS skus,
    ROUND(SUM(average_stock_gbp), 0)                                     AS average_stock_gbp,
    ROUND(100.0 * SUM(average_stock_gbp) / SUM(SUM(average_stock_gbp)) OVER (), 1)
                                                                         AS share_of_network_stock_pct,
    ROUND(SUM(cost_of_sales_gbp), 0)                                     AS cost_of_sales_gbp,
    ROUND(SUM(cost_of_sales_gbp) / NULLIF(SUM(average_stock_gbp), 0), 2) AS inventory_turns
FROM   vw_range_footprint
GROUP  BY sites_stocking
ORDER  BY sites_stocking;


\echo '=== 2. Each site split into the common basket and the rest ==='

SELECT
    warehouse_code,
    CASE WHEN sites_stocking = 4 THEN 'Stocked at all four sites'
         ELSE                         'Not stocked everywhere' END       AS range_group,
    COUNT(DISTINCT sku)                                                  AS skus,
    ROUND(SUM(average_stock_gbp), 0)                                     AS average_stock_gbp,
    ROUND(100.0 * SUM(average_stock_gbp)
          / SUM(SUM(average_stock_gbp)) OVER (PARTITION BY warehouse_code), 1)
                                                                         AS share_of_site_stock_pct,
    ROUND(SUM(cost_of_sales_gbp), 0)                                     AS cost_of_sales_gbp,
    ROUND(100.0 * SUM(cost_of_sales_gbp)
          / SUM(SUM(cost_of_sales_gbp)) OVER (PARTITION BY warehouse_code), 1)
                                                                         AS share_of_site_cogs_pct,
    ROUND(SUM(cost_of_sales_gbp) / NULLIF(SUM(average_stock_gbp), 0), 2) AS inventory_turns,
    ROUND(365 / NULLIF(SUM(cost_of_sales_gbp) / NULLIF(SUM(average_stock_gbp), 0), 0), 0)
                                                                         AS days_inventory_outstanding
FROM   vw_range_footprint
GROUP  BY warehouse_code, range_group
ORDER  BY warehouse_code, range_group;


\echo '=== 3. Adjustment A — the common basket, like for like ==='

-- The 70 SKUs every site stocks. This is the only genuinely comparable basket,
-- and the coverage columns say how much of each site it represents so the
-- narrowness of the comparison stays visible.
WITH full_range AS (
    SELECT
        warehouse_code,
        SUM(average_stock_gbp)                                           AS stock_gbp,
        SUM(cost_of_sales_gbp)                                           AS cogs_gbp
    FROM   vw_range_footprint
    GROUP  BY warehouse_code
),

common_basket AS (
    SELECT
        warehouse_code,
        COUNT(DISTINCT sku)                                              AS skus,
        SUM(average_stock_gbp)                                           AS stock_gbp,
        SUM(cost_of_sales_gbp)                                           AS cogs_gbp
    FROM   vw_range_footprint
    WHERE  sites_stocking = 4
    GROUP  BY warehouse_code
)

SELECT
    f.warehouse_code,
    c.skus                                                               AS common_basket_skus,
    ROUND(100.0 * c.stock_gbp / NULLIF(f.stock_gbp, 0), 1)               AS basket_share_of_site_stock_pct,
    ROUND(f.cogs_gbp / NULLIF(f.stock_gbp, 0), 2)                        AS turns_full_range,
    ROUND(c.cogs_gbp / NULLIF(c.stock_gbp, 0), 2)                        AS turns_common_basket,
    ROUND(c.cogs_gbp / NULLIF(c.stock_gbp, 0)
          - f.cogs_gbp / NULLIF(f.stock_gbp, 0), 2)                      AS correction,
    ROUND(365 / NULLIF(f.cogs_gbp / NULLIF(f.stock_gbp, 0), 0), 0)       AS dio_full_range,
    ROUND(365 / NULLIF(c.cogs_gbp / NULLIF(c.stock_gbp, 0), 0), 0)       AS dio_common_basket
FROM       full_range    AS f
INNER JOIN common_basket AS c ON c.warehouse_code = f.warehouse_code
ORDER  BY  turns_common_basket;


\echo '=== 4. Adjustment B — every site given the network category mix ==='

-- Indirect standardisation. Each site keeps its own turnover within each
-- category but is reweighted to the network's category stock mix, so the
-- comparison no longer rewards or punishes a site for what it happens to carry.
WITH site_category AS (
    SELECT
        warehouse_code,
        category_code,
        SUM(average_stock_gbp)                                           AS stock_gbp,
        SUM(cost_of_sales_gbp)                                           AS cogs_gbp
    FROM   vw_range_footprint
    GROUP  BY warehouse_code, category_code
),

network_weights AS (
    SELECT
        category_code,
        SUM(stock_gbp) / SUM(SUM(stock_gbp)) OVER ()                     AS network_stock_weight
    FROM   site_category
    GROUP  BY category_code
),

standardised AS (
    SELECT
        sc.warehouse_code,
        SUM(sc.stock_gbp)                                                AS actual_stock_gbp,
        SUM(sc.cogs_gbp)                                                 AS actual_cogs_gbp,
        SUM(sc.cogs_gbp) / NULLIF(SUM(sc.stock_gbp), 0)                  AS actual_turns,
        -- Weighted mean of the site's own within-category turnover, using the
        -- network's mix. Categories the site does not stock are excluded and
        -- the remaining weights renormalised, which is stated below.
        SUM(nw.network_stock_weight * sc.cogs_gbp / NULLIF(sc.stock_gbp, 0))
            / NULLIF(SUM(nw.network_stock_weight), 0)                    AS standardised_turns,
        COUNT(*)                                                         AS categories_stocked,
        ROUND(SUM(nw.network_stock_weight), 3)                           AS network_weight_covered
    FROM       site_category   AS sc
    INNER JOIN network_weights AS nw ON nw.category_code = sc.category_code
    GROUP  BY  sc.warehouse_code
)

SELECT
    warehouse_code,
    categories_stocked,
    network_weight_covered,
    ROUND(actual_stock_gbp, 0)                                           AS average_stock_gbp,
    ROUND(actual_turns, 2)                                               AS turns_as_reported,
    ROUND(standardised_turns, 2)                                         AS turns_mix_standardised,
    ROUND(standardised_turns - actual_turns, 2)                          AS correction,
    ROUND(365 / NULLIF(actual_turns, 0), 0)                              AS dio_as_reported,
    ROUND(365 / NULLIF(standardised_turns, 0), 0)                        AS dio_mix_standardised
FROM   standardised
ORDER  BY turns_mix_standardised;


\echo '=== 5. Do the two adjustments agree? ==='

WITH full_range AS (
    SELECT warehouse_code, SUM(average_stock_gbp) AS stock_gbp, SUM(cost_of_sales_gbp) AS cogs_gbp
    FROM   vw_range_footprint GROUP BY warehouse_code
),
common_basket AS (
    SELECT warehouse_code, SUM(average_stock_gbp) AS stock_gbp, SUM(cost_of_sales_gbp) AS cogs_gbp
    FROM   vw_range_footprint WHERE sites_stocking = 4 GROUP BY warehouse_code
),
site_category AS (
    SELECT warehouse_code, category_code,
           SUM(average_stock_gbp) AS stock_gbp, SUM(cost_of_sales_gbp) AS cogs_gbp
    FROM   vw_range_footprint GROUP BY warehouse_code, category_code
),
network_weights AS (
    SELECT category_code, SUM(stock_gbp) / SUM(SUM(stock_gbp)) OVER () AS w
    FROM   site_category GROUP BY category_code
),
standardised AS (
    SELECT sc.warehouse_code,
           SUM(nw.w * sc.cogs_gbp / NULLIF(sc.stock_gbp, 0)) / NULLIF(SUM(nw.w), 0) AS standardised_turns
    FROM   site_category AS sc INNER JOIN network_weights AS nw USING (category_code)
    GROUP  BY sc.warehouse_code
)

SELECT
    f.warehouse_code,
    ROUND(f.cogs_gbp / NULLIF(f.stock_gbp, 0), 2)                        AS turns_as_reported,
    ROUND(c.cogs_gbp / NULLIF(c.stock_gbp, 0), 2)                        AS turns_common_basket,
    ROUND(s.standardised_turns, 2)                                       AS turns_mix_standardised,
    RANK() OVER (ORDER BY f.cogs_gbp / NULLIF(f.stock_gbp, 0) DESC)      AS rank_as_reported,
    RANK() OVER (ORDER BY c.cogs_gbp / NULLIF(c.stock_gbp, 0) DESC)      AS rank_common_basket,
    RANK() OVER (ORDER BY s.standardised_turns DESC)                     AS rank_standardised
FROM       full_range    AS f
INNER JOIN common_basket AS c ON c.warehouse_code = f.warehouse_code
INNER JOIN standardised  AS s ON s.warehouse_code = f.warehouse_code
ORDER  BY  rank_standardised;


\echo '=== 6. Daventry decomposed — what the exclusive range costs it ==='

-- 145 SKUs are stocked only at Daventry. Whatever they do to its numbers, it is
-- a consequence of holding the national range, not of how the site is run.
SELECT
    CASE WHEN sites_stocking = 1 THEN 'Stocked only at Daventry'
         WHEN sites_stocking = 4 THEN 'Stocked at all four sites'
         ELSE                         'Stocked at two or three sites' END AS range_group,
    COUNT(DISTINCT sku)                                                  AS skus,
    ROUND(SUM(average_stock_gbp), 0)                                     AS average_stock_gbp,
    ROUND(100.0 * SUM(average_stock_gbp) / SUM(SUM(average_stock_gbp)) OVER (), 1)
                                                                         AS share_of_daventry_stock_pct,
    ROUND(SUM(cost_of_sales_gbp), 0)                                     AS cost_of_sales_gbp,
    ROUND(100.0 * SUM(cost_of_sales_gbp) / SUM(SUM(cost_of_sales_gbp)) OVER (), 1)
                                                                         AS share_of_daventry_cogs_pct,
    ROUND(SUM(cost_of_sales_gbp) / NULLIF(SUM(average_stock_gbp), 0), 2) AS inventory_turns,
    ROUND(365 / NULLIF(SUM(cost_of_sales_gbp) / NULLIF(SUM(average_stock_gbp), 0), 0), 0)
                                                                         AS days_inventory_outstanding
FROM   vw_range_footprint
WHERE  warehouse_code = 'DAV'
GROUP  BY range_group
ORDER  BY inventory_turns;


\echo '=== 7. Does range mix explain the file 09 service anomaly? ==='

-- File 09 found Daventry short-shipping 2.60% of units in weeks that opened
-- well covered, against 0.30% at Warrington, and that the gap survived holding
-- absolute stock depth constant. This repeats that test on the common basket
-- only. If range mix were the whole explanation the gap should close here.
WITH sku_reach AS (
    SELECT sku, COUNT(DISTINCT warehouse_code) AS sites_stocking
    FROM   mv_inventory_week WHERE year = :analysis_year GROUP BY sku
),

weekly AS (
    SELECT
        m.warehouse_code,
        m.sku,
        r.sites_stocking,
        m.week_ending_date,
        m.demand_units,
        m.unmet_units,
        LAG(m.cover_weeks) OVER (PARTITION BY m.sku, m.warehouse_code
                                 ORDER BY m.week_ending_date)            AS prior_cover_weeks
    FROM       mv_inventory_week AS m
    INNER JOIN sku_reach         AS r ON r.sku = m.sku
)

SELECT
    warehouse_code,
    COUNT(*) FILTER (WHERE sites_stocking = 4)                           AS common_basket_weeks,
    ROUND(100.0 * SUM(unmet_units) FILTER (WHERE sites_stocking = 4)
          / NULLIF(SUM(demand_units) FILTER (WHERE sites_stocking = 4), 0), 2)
                                                                         AS unmet_rate_common_basket_pct,
    COUNT(*) FILTER (WHERE sites_stocking < 4)                           AS other_range_weeks,
    ROUND(100.0 * SUM(unmet_units) FILTER (WHERE sites_stocking < 4)
          / NULLIF(SUM(demand_units) FILTER (WHERE sites_stocking < 4), 0), 2)
                                                                         AS unmet_rate_other_range_pct,
    ROUND(100.0 * SUM(unmet_units) / NULLIF(SUM(demand_units), 0), 2)    AS unmet_rate_all_pct
FROM   weekly
WHERE  week_ending_date >= DATE '2025-01-01'
  AND  prior_cover_weeks >= 8
  AND  demand_units > 0
GROUP  BY warehouse_code
ORDER  BY unmet_rate_common_basket_pct DESC;


\echo '=== 8. Reconciliation ==='

SELECT
    'Average 2025 stock — vw_range_footprint'                            AS measure,
    ROUND((SELECT SUM(average_stock_gbp) FROM vw_range_footprint), 2)     AS value
UNION ALL
SELECT 'Average 2025 stock — mv_inventory_week, must match file 01',
       ROUND((SELECT SUM(stock_value_gbp) / COUNT(DISTINCT week_ending_date)
              FROM mv_inventory_week WHERE year = :analysis_year), 2)
UNION ALL
SELECT 'Cost of sales 2025 — vw_range_footprint',
       ROUND((SELECT SUM(cost_of_sales_gbp) FROM vw_range_footprint), 2)
UNION ALL
SELECT 'Cost of sales 2025 — mv_inventory_week',
       ROUND((SELECT SUM(issued_cost_gbp) FROM mv_inventory_week
              WHERE year = :analysis_year), 2)
UNION ALL
SELECT 'SKU-site positions — vw_range_footprint',
       (SELECT COUNT(*) FROM vw_range_footprint)::numeric
UNION ALL
SELECT 'SKU-site positions — replenishment_policy',
       (SELECT COUNT(*) FROM replenishment_policy)::numeric;
