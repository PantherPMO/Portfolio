/* ============================================================
   Project    : 02 — Warehouse Inventory & Supply Chain Performance
   File       : 04_analysis/02_inventory_value_concentration_and_abc.sql
   Question   : BQ-01 / AQ-02 — How concentrated is the working capital,
                and does the ranking by stock value match the ranking by
                cost of sales?
   Finding ID : F-02
   Output     : analysis/query_results/analyse_02_value_concentration_abc.txt
   Author     : Peters
   Created    : 2026-08-23
   ============================================================

   Calderfield Trade Supplies Ltd is fictional and this data is synthetic.

   Two curves are built, not one. A Pareto on stock value alone finds
   expensive stock; a Pareto on cost of sales finds important stock.
   Where a SKU ranks high on the first and low on the second, that is
   working capital doing no work — and it is only visible by holding
   both rankings side by side.

   Classes follow the standard ABC convention on cumulative share:
   A to 80%, B to 95%, C beyond. Applied independently to each measure,
   so the cross-tabulation in section 4 is meaningful.
   ============================================================ */

SET search_path TO supply;

\set analysis_year 2025
\set holding_rate 0.22


\echo '=== 1. SKU-level position, 2025 ==='

DROP VIEW IF EXISTS vw_sku_value_position CASCADE;

CREATE VIEW vw_sku_value_position AS

WITH sku_year AS (
    -- Grain: one row per SKU across the whole network. A product is ranged
    -- once for the business, so the buying decision sits at SKU level even
    -- though the stock sits at SKU/site level.
    SELECT
        sku,
        product_name,
        category_code,
        category_name,
        discontinued_date,
        COUNT(DISTINCT warehouse_code)                                   AS sites_stocking,
        SUM(stock_value_gbp) / COUNT(DISTINCT week_ending_date)          AS average_stock_gbp,
        SUM(issued_cost_gbp)                                             AS cost_of_sales_gbp,
        SUM(issued_units)                                                AS units_issued,
        MAX(weighted_average_cost_gbp)                                   AS unit_cost_gbp
    FROM   mv_inventory_week
    WHERE  year = :analysis_year
    GROUP  BY sku, product_name, category_code, category_name, discontinued_date
),

ranked AS (
    SELECT
        s.*,
        ROW_NUMBER() OVER (ORDER BY s.average_stock_gbp DESC)            AS stock_rank,
        ROW_NUMBER() OVER (ORDER BY s.cost_of_sales_gbp DESC)            AS cogs_rank,
        SUM(s.average_stock_gbp) OVER (ORDER BY s.average_stock_gbp DESC
             ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
            / NULLIF(SUM(s.average_stock_gbp) OVER (), 0)                AS cumulative_stock_share,
        SUM(s.cost_of_sales_gbp) OVER (ORDER BY s.cost_of_sales_gbp DESC
             ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
            / NULLIF(SUM(s.cost_of_sales_gbp) OVER (), 0)                AS cumulative_cogs_share
    FROM   sku_year AS s
)

SELECT
    sku,
    product_name,
    category_code,
    category_name,
    discontinued_date,
    sites_stocking,
    ROUND(average_stock_gbp, 2)                                          AS average_stock_gbp,
    ROUND(cost_of_sales_gbp, 2)                                          AS cost_of_sales_gbp,
    units_issued,
    ROUND(unit_cost_gbp, 2)                                              AS unit_cost_gbp,
    ROUND(cost_of_sales_gbp / NULLIF(average_stock_gbp, 0), 2)           AS inventory_turns,
    stock_rank,
    cogs_rank,
    ROUND(cumulative_stock_share * 100, 2)                               AS cumulative_stock_share_pct,
    ROUND(cumulative_cogs_share  * 100, 2)                               AS cumulative_cogs_share_pct,
    CASE WHEN cumulative_stock_share <= 0.80 THEN 'A'
         WHEN cumulative_stock_share <= 0.95 THEN 'B'
         ELSE 'C' END                                                    AS stock_value_class,
    CASE WHEN cumulative_cogs_share <= 0.80 THEN 'A'
         WHEN cumulative_cogs_share <= 0.95 THEN 'B'
         ELSE 'C' END                                                    AS cogs_class
FROM   ranked;


\echo '=== 2. Concentration of stock value and of cost of sales ==='

WITH thresholds AS (
    SELECT
        COUNT(*)                                                         AS total_skus,
        SUM(average_stock_gbp)                                           AS total_stock_gbp,
        SUM(cost_of_sales_gbp)                                           AS total_cogs_gbp,
        SUM(average_stock_gbp) FILTER (WHERE stock_rank <= 10)           AS top10_stock_gbp,
        SUM(average_stock_gbp) FILTER (WHERE stock_rank <= 25)           AS top25_stock_gbp,
        SUM(average_stock_gbp) FILTER (WHERE stock_rank <= 50)           AS top50_stock_gbp,
        SUM(cost_of_sales_gbp) FILTER (WHERE cogs_rank <= 10)            AS top10_cogs_gbp,
        SUM(cost_of_sales_gbp) FILTER (WHERE cogs_rank <= 25)            AS top25_cogs_gbp,
        SUM(cost_of_sales_gbp) FILTER (WHERE cogs_rank <= 50)            AS top50_cogs_gbp
    FROM   vw_sku_value_position
)

SELECT
    'Top 10 SKUs'                                                        AS population,
    ROUND(100.0 * 10 / total_skus, 1)                                    AS share_of_range_pct,
    ROUND(100.0 * top10_stock_gbp / NULLIF(total_stock_gbp, 0), 1)       AS share_of_stock_value_pct,
    ROUND(100.0 * top10_cogs_gbp  / NULLIF(total_cogs_gbp, 0), 1)        AS share_of_cost_of_sales_pct
FROM   thresholds
UNION ALL
SELECT 'Top 25 SKUs', ROUND(100.0 * 25 / total_skus, 1),
       ROUND(100.0 * top25_stock_gbp / NULLIF(total_stock_gbp, 0), 1),
       ROUND(100.0 * top25_cogs_gbp  / NULLIF(total_cogs_gbp, 0), 1)
FROM   thresholds
UNION ALL
SELECT 'Top 50 SKUs', ROUND(100.0 * 50 / total_skus, 1),
       ROUND(100.0 * top50_stock_gbp / NULLIF(total_stock_gbp, 0), 1),
       ROUND(100.0 * top50_cogs_gbp  / NULLIF(total_cogs_gbp, 0), 1)
FROM   thresholds;


\echo '=== 3. ABC classes on each measure ==='

SELECT
    'Stock value'                                                        AS ranked_by,
    stock_value_class                                                    AS class,
    COUNT(*)                                                             AS skus,
    ROUND(SUM(average_stock_gbp), 0)                                     AS average_stock_gbp,
    ROUND(SUM(cost_of_sales_gbp), 0)                                     AS cost_of_sales_gbp,
    ROUND(SUM(cost_of_sales_gbp) / NULLIF(SUM(average_stock_gbp), 0), 2) AS inventory_turns
FROM   vw_sku_value_position
GROUP  BY stock_value_class
UNION ALL
SELECT
    'Cost of sales', cogs_class, COUNT(*),
    ROUND(SUM(average_stock_gbp), 0), ROUND(SUM(cost_of_sales_gbp), 0),
    ROUND(SUM(cost_of_sales_gbp) / NULLIF(SUM(average_stock_gbp), 0), 2)
FROM   vw_sku_value_position
GROUP  BY cogs_class
ORDER  BY 1, 2;


\echo '=== 4. Where the two rankings disagree ==='

-- The diagonal is stock behaving as it should. Off-diagonal cells above the
-- diagonal — high stock class, low sales class — are working capital carrying
-- little trade. This is the measurement the file exists for.
SELECT
    stock_value_class,
    COUNT(*) FILTER (WHERE cogs_class = 'A')                             AS cogs_class_a,
    COUNT(*) FILTER (WHERE cogs_class = 'B')                             AS cogs_class_b,
    COUNT(*) FILTER (WHERE cogs_class = 'C')                             AS cogs_class_c,
    ROUND(SUM(average_stock_gbp) FILTER (WHERE cogs_class = 'C'), 0)     AS stock_in_cogs_class_c_gbp,
    ROUND(SUM(average_stock_gbp) FILTER (WHERE cogs_class = 'C') * :holding_rate, 0)
                                                                         AS holding_cost_of_those_gbp
FROM   vw_sku_value_position
GROUP  BY stock_value_class
ORDER  BY stock_value_class;


\echo '=== 5. The mismatch, quantified ==='

WITH mismatch AS (
    SELECT
        SUM(average_stock_gbp)                                           AS total_stock_gbp,
        SUM(average_stock_gbp) FILTER (WHERE stock_value_class IN ('A', 'B')
                                         AND cogs_class = 'C')           AS high_stock_low_sales_gbp,
        COUNT(*) FILTER (WHERE stock_value_class IN ('A', 'B')
                           AND cogs_class = 'C')                         AS high_stock_low_sales_skus,
        SUM(cost_of_sales_gbp) FILTER (WHERE stock_value_class = 'C'
                                         AND cogs_class = 'A')           AS low_stock_high_sales_cogs_gbp,
        COUNT(*) FILTER (WHERE stock_value_class = 'C'
                           AND cogs_class = 'A')                         AS low_stock_high_sales_skus
    FROM   vw_sku_value_position
)

SELECT
    high_stock_low_sales_skus,
    ROUND(high_stock_low_sales_gbp, 0)                                   AS stock_held_gbp,
    ROUND(100.0 * high_stock_low_sales_gbp / NULLIF(total_stock_gbp, 0), 1)
                                                                         AS share_of_network_stock_pct,
    ROUND(high_stock_low_sales_gbp * :holding_rate, 0)                   AS annual_holding_cost_gbp,
    low_stock_high_sales_skus,
    ROUND(low_stock_high_sales_cogs_gbp, 0)                              AS their_cost_of_sales_gbp
FROM   mismatch;


\echo '=== 6. The twenty SKUs holding most stock, with their trade ==='

SELECT
    stock_rank,
    sku,
    category_code,
    sites_stocking,
    ROUND(unit_cost_gbp, 2)                                              AS unit_cost_gbp,
    ROUND(average_stock_gbp, 0)                                          AS average_stock_gbp,
    cumulative_stock_share_pct,
    ROUND(cost_of_sales_gbp, 0)                                          AS cost_of_sales_gbp,
    cogs_rank,
    inventory_turns,
    stock_value_class || cogs_class                                      AS class_pair,
    discontinued_date
FROM   vw_sku_value_position
ORDER  BY stock_rank
LIMIT  20;


\echo '=== 7. Is expensive the same as important? ==='

-- A deliberate check on the assumption a stakeholder is most likely to bring
-- to the table. If unit cost and units sold are uncorrelated, then targeting
-- the expensive lines is not the same as targeting the ones that matter.
SELECT
    ROUND(CORR(unit_cost_gbp, units_issued)::numeric, 3)                 AS corr_unit_cost_vs_units_sold,
    ROUND(CORR(average_stock_gbp, cost_of_sales_gbp)::numeric, 3)        AS corr_stock_value_vs_cost_of_sales,
    ROUND(CORR(stock_rank, cogs_rank)::numeric, 3)                       AS corr_of_the_two_rankings,
    COUNT(*)                                                             AS skus
FROM   vw_sku_value_position;


\echo '=== 8. Concentration within each site ==='

WITH site_sku AS (
    SELECT
        warehouse_code,
        sku,
        SUM(stock_value_gbp) / COUNT(DISTINCT week_ending_date)          AS average_stock_gbp
    FROM   mv_inventory_week
    WHERE  year = :analysis_year
    GROUP  BY warehouse_code, sku
),

site_ranked AS (
    SELECT
        warehouse_code,
        average_stock_gbp,
        ROW_NUMBER() OVER (PARTITION BY warehouse_code
                           ORDER BY average_stock_gbp DESC)              AS rank_in_site,
        COUNT(*)     OVER (PARTITION BY warehouse_code)                  AS skus_in_site,
        -- Cut computed in the window, not the aggregate: each site holds a
        -- different number of lines, so the top fifth is a different count.
        CEIL(COUNT(*) OVER (PARTITION BY warehouse_code) * 0.20)         AS top_fifth_cut
    FROM   site_sku
)

SELECT
    warehouse_code,
    MAX(skus_in_site)                                                    AS skus_stocked,
    ROUND(SUM(average_stock_gbp), 0)                                     AS average_stock_gbp,
    ROUND(100.0 * SUM(average_stock_gbp) FILTER (WHERE rank_in_site <= 10)
          / NULLIF(SUM(average_stock_gbp), 0), 1)                        AS top_10_skus_share_pct,
    ROUND(100.0 * SUM(average_stock_gbp) FILTER (WHERE rank_in_site <= top_fifth_cut)
          / NULLIF(SUM(average_stock_gbp), 0), 1)                        AS top_fifth_share_pct
FROM   site_ranked
GROUP  BY warehouse_code
ORDER  BY warehouse_code;
