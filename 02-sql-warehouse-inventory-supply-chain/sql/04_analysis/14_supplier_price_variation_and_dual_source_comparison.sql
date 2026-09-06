/* ============================================================
   Project    : 02 — Warehouse Inventory & Supply Chain Performance
   File       : 04_analysis/14_supplier_price_variation_and_dual_source_comparison.sql
   Question   : BQ-07 / AQ-14 — Where does dual sourcing reveal an
                avoidable purchase-cost difference, and what does taking
                it actually cost elsewhere?
   Finding ID : F-14
   Output     : analysis/query_results/analyse_14_price_and_dual_sourcing.txt
   Author     : Peters
   Created    : 2026-08-23
   ============================================================

   Calderfield Trade Supplies Ltd is fictional and this data is synthetic.

   EVERY COMPARISON IN THIS FILE IS LIKE FOR LIKE, AND SECTION 2 SHOWS
   WHY. Arden's basket changed across the price-change date: 67 SKUs
   bought before, 57 after, and only 57 on both sides. Any average taken
   across the whole basket therefore measures the mix as much as the
   price.

   Section 2 runs both methods on the same data rather than repeating a
   figure from anywhere else. The raw and like-for-like answers are both
   printed and they differ materially — the raw comparison is wrong in
   the same direction but by a very different magnitude.

   Rule applied throughout: never compare an average price across a
   changing basket. Compare identical SKUs, take the median of the
   SKU-level ratios, and report the spread.

   A CHEAPER UNIT PRICE IS NOT AUTOMATICALLY A SAVING. The cheaper
   source in this dataset is usually an importer, and importer minimum
   order quantities run to months of demand (F-05, D-18). Section 6 nets
   the unit-price saving against the carrying cost of the stock the
   larger minimum creates, at the approved 22% rate with a 20-25% band
   (D-11). Neither number is presented without the other.

   Prices are taken from purchase_order_line.unit_cost_gbp — what was
   actually paid — not from product_supplier.agreed_unit_cost_gbp,
   which holds only the current agreed rate and carries no history.
   ============================================================ */

SET search_path TO supply;

\set price_change_date '2025-03-01'
\set snapshot_date '2025-12-28'
\set analysis_date '2025-12-31'
\set holding_rate 0.22
\set holding_rate_low 0.20
\set holding_rate_high 0.25
\set min_lines 4


\echo '=== 1. The sourcing population ==='

SELECT
    'SKUs in the range'                                                  AS population,
    COUNT(*)                                                             AS n
FROM   product
UNION ALL
SELECT 'SKUs with more than one approved source',
       COUNT(*) FROM (SELECT sku FROM product_supplier
                      GROUP BY sku HAVING COUNT(*) > 1) AS a
UNION ALL
SELECT 'SKUs actually purchased from more than one supplier',
       COUNT(*) FROM (SELECT pol.sku
                      FROM purchase_order_line AS pol
                      INNER JOIN purchase_order AS po USING (purchase_order_number)
                      GROUP BY pol.sku HAVING COUNT(DISTINCT po.supplier_code) > 1) AS b
UNION ALL
SELECT 'Of those, with at least 4 purchase lines from each of two sources',
       COUNT(*) FROM (SELECT pol.sku
                      FROM purchase_order_line AS pol
                      INNER JOIN purchase_order AS po USING (purchase_order_number)
                      GROUP BY pol.sku, po.supplier_code
                      HAVING COUNT(*) >= 4) AS c
       WHERE 1 = 1
UNION ALL
SELECT 'Purchase order lines in total',
       COUNT(*) FROM purchase_order_line;


\echo '=== 2. Arden before and after March 2025 — the wrong way and the right way ==='

DROP VIEW IF EXISTS vw_arden_price_change CASCADE;

CREATE VIEW vw_arden_price_change AS

WITH arden_lines AS (
    SELECT
        pol.sku,
        p.category_code,
        po.order_date >= DATE :'price_change_date'                       AS is_after,
        pol.unit_cost_gbp,
        pol.quantity_ordered
    FROM       purchase_order_line AS pol
    INNER JOIN purchase_order      AS po ON po.purchase_order_number = pol.purchase_order_number
    INNER JOIN product             AS p  ON p.sku = pol.sku
    WHERE      po.supplier_code = 'ARDEN'
),

by_sku AS (
    SELECT
        sku,
        category_code,
        COUNT(*) FILTER (WHERE NOT is_after)                             AS lines_before,
        COUNT(*) FILTER (WHERE is_after)                                 AS lines_after,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY unit_cost_gbp)
            FILTER (WHERE NOT is_after)::numeric                         AS median_price_before,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY unit_cost_gbp)
            FILTER (WHERE is_after)::numeric                             AS median_price_after,
        SUM(quantity_ordered) FILTER (WHERE is_after)                    AS units_after
    FROM   arden_lines
    GROUP  BY sku, category_code
)

SELECT
    sku,
    category_code,
    lines_before,
    lines_after,
    ROUND(median_price_before::numeric, 2)                               AS median_price_before,
    ROUND(median_price_after::numeric, 2)                                AS median_price_after,
    ROUND((100.0 * (median_price_after / NULLIF(median_price_before, 0) - 1))::numeric, 1)
                                                                         AS price_change_pct,
    units_after
FROM   by_sku
WHERE  lines_before > 0 AND lines_after > 0;


WITH raw_compare AS (
    SELECT
        AVG(pol.unit_cost_gbp) FILTER (WHERE po.order_date <  DATE :'price_change_date')
                                                                         AS mean_before,
        AVG(pol.unit_cost_gbp) FILTER (WHERE po.order_date >= DATE :'price_change_date')
                                                                         AS mean_after,
        COUNT(*) FILTER (WHERE po.order_date <  DATE :'price_change_date') AS lines_before,
        COUNT(*) FILTER (WHERE po.order_date >= DATE :'price_change_date') AS lines_after,
        COUNT(DISTINCT pol.sku) FILTER (WHERE po.order_date <  DATE :'price_change_date')
                                                                         AS skus_before,
        COUNT(DISTINCT pol.sku) FILTER (WHERE po.order_date >= DATE :'price_change_date')
                                                                         AS skus_after
    FROM       purchase_order_line AS pol
    INNER JOIN purchase_order      AS po ON po.purchase_order_number = pol.purchase_order_number
    WHERE      po.supplier_code = 'ARDEN'
)

SELECT
    'Raw mean across all lines — INVALID, basket changed'                AS method,
    lines_before                                                         AS n_before,
    lines_after                                                          AS n_after,
    skus_before                                                          AS skus_before,
    skus_after                                                           AS skus_after,
    ROUND(mean_before, 2)                                                AS price_before,
    ROUND(mean_after, 2)                                                 AS price_after,
    ROUND(100.0 * (mean_after / NULLIF(mean_before, 0) - 1), 1)          AS change_pct
FROM   raw_compare
UNION ALL
SELECT
    'Like for like — median of SKU-level ratios',
    (SELECT SUM(lines_before) FROM vw_arden_price_change),
    (SELECT SUM(lines_after)  FROM vw_arden_price_change),
    (SELECT COUNT(*) FROM vw_arden_price_change),
    (SELECT COUNT(*) FROM vw_arden_price_change),
    NULL, NULL,
    (SELECT ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY price_change_pct)::numeric, 1)
     FROM vw_arden_price_change);


\echo '=== 3. The like-for-like distribution, not just its middle ==='

SELECT
    COUNT(*)                                                             AS skus_priced_both_sides,
    ROUND(PERCENTILE_CONT(0.10) WITHIN GROUP (ORDER BY price_change_pct)::numeric, 1) AS p10_pct,
    ROUND(PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY price_change_pct)::numeric, 1) AS p25_pct,
    ROUND(PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY price_change_pct)::numeric, 1) AS median_pct,
    ROUND(PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY price_change_pct)::numeric, 1) AS p75_pct,
    ROUND(PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY price_change_pct)::numeric, 1) AS p90_pct,
    ROUND(STDDEV_SAMP(price_change_pct), 1)                              AS stddev_pct,
    COUNT(*) FILTER (WHERE price_change_pct > 10)                        AS skus_up_over_10pct,
    COUNT(*) FILTER (WHERE price_change_pct BETWEEN -10 AND 10)          AS skus_broadly_flat,
    COUNT(*) FILTER (WHERE price_change_pct < -10)                       AS skus_down_over_10pct
FROM   vw_arden_price_change;


\echo '=== 4. Every other supplier over the same dates, as a control ==='

-- If prices generally moved in March 2025, Arden's change is a market event
-- rather than a supplier one. Same like-for-like method, every supplier.
WITH sku_supplier_period AS (
    SELECT
        po.supplier_code,
        s.supplier_type,
        pol.sku,
        COUNT(*) FILTER (WHERE po.order_date <  DATE :'price_change_date') AS lines_before,
        COUNT(*) FILTER (WHERE po.order_date >= DATE :'price_change_date') AS lines_after,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY pol.unit_cost_gbp)
            FILTER (WHERE po.order_date <  DATE :'price_change_date')::numeric AS price_before,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY pol.unit_cost_gbp)
            FILTER (WHERE po.order_date >= DATE :'price_change_date')::numeric AS price_after
    FROM       purchase_order_line AS pol
    INNER JOIN purchase_order      AS po ON po.purchase_order_number = pol.purchase_order_number
    INNER JOIN supplier            AS s  ON s.supplier_code = po.supplier_code
    GROUP  BY  po.supplier_code, s.supplier_type, pol.sku
)

SELECT
    supplier_code,
    supplier_type,
    COUNT(*) FILTER (WHERE lines_before > 0 AND lines_after > 0)         AS skus_both_sides,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (
              ORDER BY 100.0 * (price_after / NULLIF(price_before, 0) - 1))::numeric, 1)
                                                                         AS median_like_for_like_pct,
    ROUND(PERCENTILE_CONT(0.25) WITHIN GROUP (
              ORDER BY 100.0 * (price_after / NULLIF(price_before, 0) - 1))::numeric, 1)
                                                                         AS p25_pct,
    ROUND(PERCENTILE_CONT(0.75) WITHIN GROUP (
              ORDER BY 100.0 * (price_after / NULLIF(price_before, 0) - 1))::numeric, 1)
                                                                         AS p75_pct
FROM   sku_supplier_period
WHERE  lines_before > 0 AND lines_after > 0
GROUP  BY supplier_code, supplier_type
HAVING COUNT(*) >= :min_lines
ORDER  BY median_like_for_like_pct DESC;


\echo '=== 5. Dual sourcing — the price gap on identical SKUs ==='

DROP VIEW IF EXISTS vw_dual_source_gap CASCADE;

CREATE VIEW vw_dual_source_gap AS

WITH sku_supplier AS (
    -- Grain: one row per SKU per supplier actually purchased from.
    SELECT
        pol.sku,
        p.category_code,
        po.supplier_code,
        s.supplier_type,
        COUNT(*)                                                         AS purchase_lines,
        SUM(pol.quantity_ordered)                                        AS units_purchased,
        SUM(pol.quantity_ordered * pol.unit_cost_gbp)                    AS spend_gbp,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY pol.unit_cost_gbp)::numeric AS median_unit_cost,
        ps.minimum_order_quantity,
        ps.quoted_lead_time_days
    FROM       purchase_order_line AS pol
    INNER JOIN purchase_order      AS po ON po.purchase_order_number = pol.purchase_order_number
    INNER JOIN supplier            AS s  ON s.supplier_code = po.supplier_code
    INNER JOIN product             AS p  ON p.sku = pol.sku
    INNER JOIN product_supplier    AS ps
           ON  ps.sku = pol.sku AND ps.supplier_code = po.supplier_code
    GROUP  BY  pol.sku, p.category_code, po.supplier_code, s.supplier_type,
               ps.minimum_order_quantity, ps.quoted_lead_time_days
),

ranked AS (
    SELECT
        ss.*,
        COUNT(*)     OVER (PARTITION BY sku)                             AS sources_used,
        ROW_NUMBER() OVER (PARTITION BY sku ORDER BY median_unit_cost)   AS price_rank,
        ROW_NUMBER() OVER (PARTITION BY sku ORDER BY units_purchased DESC) AS volume_rank
    FROM   sku_supplier AS ss
)

SELECT
    c.sku,
    c.category_code,
    c.sources_used,
    -- Cheapest source actually used
    c.supplier_code                                                      AS cheap_supplier,
    c.supplier_type                                                      AS cheap_supplier_type,
    ROUND(c.median_unit_cost, 2)                                         AS cheap_unit_cost,
    c.purchase_lines                                                     AS cheap_lines,
    c.units_purchased                                                    AS cheap_units,
    c.minimum_order_quantity                                             AS cheap_moq,
    c.quoted_lead_time_days                                              AS cheap_lead_days,
    -- Dearest source actually used
    d.supplier_code                                                      AS dear_supplier,
    d.supplier_type                                                      AS dear_supplier_type,
    ROUND(d.median_unit_cost, 2)                                         AS dear_unit_cost,
    d.purchase_lines                                                     AS dear_lines,
    d.units_purchased                                                    AS dear_units,
    d.minimum_order_quantity                                             AS dear_moq,
    d.quoted_lead_time_days                                              AS dear_lead_days,
    ROUND(d.median_unit_cost - c.median_unit_cost, 2)                    AS price_gap_per_unit,
    ROUND(100.0 * (d.median_unit_cost / NULLIF(c.median_unit_cost, 0) - 1), 1)
                                                                         AS dear_premium_pct,
    -- What was bought from the dearer source at the gap. Gross, before any
    -- consideration of what switching would cost in stock or lead time.
    ROUND(d.units_purchased * (d.median_unit_cost - c.median_unit_cost), 2)
                                                                         AS gross_gap_on_dear_volume_gbp
FROM       ranked AS c
INNER JOIN ranked AS d ON d.sku = c.sku
WHERE      c.price_rank = 1
  AND      d.price_rank = c.sources_used
  AND      c.sources_used > 1
  AND      c.supplier_code <> d.supplier_code
  AND      c.purchase_lines >= :min_lines
  AND      d.purchase_lines >= :min_lines;


SELECT
    'SKUs with two comparable sources (4+ lines each)'                   AS measure,
    COUNT(*)                                                             AS n,
    NULL::numeric                                                        AS value_gbp
FROM   vw_dual_source_gap
UNION ALL
SELECT 'Median price premium of the dearer source, per cent',
       COUNT(*),
       ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY dear_premium_pct)::numeric, 1)
FROM   vw_dual_source_gap
UNION ALL
SELECT 'Units bought from the dearer source', SUM(dear_lines), SUM(dear_units)
FROM   vw_dual_source_gap
UNION ALL
SELECT 'Gross price gap on that volume', COUNT(*), ROUND(SUM(gross_gap_on_dear_volume_gbp), 0)
FROM   vw_dual_source_gap;


\echo '=== 6. What the cheaper source costs elsewhere ==='

-- The trade-off, in one table, on a single time basis.
--
-- THE TIME BASIS MATTERS AND IS EASY TO GET WRONG. The purchase history spans
-- two years, so the volume bought from the dearer source is a two-year figure.
-- The holding cost of the stock the cheaper source would create is annual.
-- Comparing the two directly overstates the saving by roughly a factor of two.
-- The price saving is therefore annualised — two-year volume halved — and every
-- column below is labelled by the period it covers.
--
-- Extra cycle stock is roughly half the difference in order size; extra
-- pipeline stock is the extra lead time at the annual demand rate. Both are
-- one-off increases in working capital, carried each year at the holding rate.
WITH annual_demand AS (
    SELECT
        sku,
        SUM(issued_units) AS units_2025
    FROM   mv_inventory_week
    WHERE  year = 2025
    GROUP  BY sku
),

trade AS (
    SELECT
        g.sku,
        g.category_code,
        g.cheap_supplier,
        g.cheap_supplier_type,
        g.dear_supplier,
        g.dear_supplier_type,
        g.cheap_unit_cost,
        g.dear_unit_cost,
        g.price_gap_per_unit,
        g.dear_premium_pct,
        g.cheap_moq,
        g.dear_moq,
        g.cheap_lead_days,
        g.dear_lead_days,
        COALESCE(a.units_2025, 0)                                        AS units_2025,
        -- Annualised: two years of purchases halved.
        g.dear_units / 2.0 * g.price_gap_per_unit                        AS annual_price_saving_gbp,
        -- Extra cycle stock from the larger minimum, valued at the cheaper cost.
        GREATEST(g.cheap_moq - g.dear_moq, 0) / 2.0 * g.cheap_unit_cost  AS extra_cycle_stock_gbp,
        -- Extra pipeline stock from the longer lead time, at the cheaper cost.
        GREATEST(g.cheap_lead_days - g.dear_lead_days, 0)
            * COALESCE(a.units_2025, 0) / 365.0 * g.cheap_unit_cost      AS extra_pipeline_stock_gbp
    FROM       vw_dual_source_gap AS g
    LEFT JOIN  annual_demand      AS a ON a.sku = g.sku
)

SELECT
    sku,
    category_code,
    cheap_supplier,
    cheap_supplier_type,
    dear_supplier,
    cheap_unit_cost,
    dear_unit_cost,
    dear_premium_pct,
    cheap_moq,
    dear_moq,
    cheap_lead_days,
    dear_lead_days,
    units_2025,
    ROUND(annual_price_saving_gbp, 0)                                    AS annual_price_saving_gbp,
    ROUND(extra_cycle_stock_gbp + extra_pipeline_stock_gbp, 0)           AS one_off_working_capital_gbp,
    ROUND((extra_cycle_stock_gbp + extra_pipeline_stock_gbp) * :holding_rate, 0)
                                                                         AS annual_holding_cost_gbp,
    ROUND(annual_price_saving_gbp
          - (extra_cycle_stock_gbp + extra_pipeline_stock_gbp) * :holding_rate, 0)
                                                                         AS annual_net_at_22pct_gbp,
    ROUND((extra_cycle_stock_gbp + extra_pipeline_stock_gbp)
          / NULLIF(annual_price_saving_gbp, 0), 1)                       AS years_of_saving_tied_up
FROM   trade
ORDER  BY annual_net_at_22pct_gbp DESC;


\echo '=== 7. The trade netted, with the sensitivity band ==='

WITH annual_demand AS (
    SELECT sku, SUM(issued_units) AS units_2025
    FROM   mv_inventory_week WHERE year = 2025 GROUP BY sku
),

trade AS (
    SELECT
        g.cheap_supplier_type,
        g.dear_units / 2.0 * g.price_gap_per_unit                        AS annual_price_saving_gbp,
        GREATEST(g.cheap_moq - g.dear_moq, 0) / 2.0 * g.cheap_unit_cost
        + GREATEST(g.cheap_lead_days - g.dear_lead_days, 0)
          * COALESCE(a.units_2025, 0) / 365.0 * g.cheap_unit_cost        AS extra_working_capital_gbp
    FROM       vw_dual_source_gap AS g
    LEFT JOIN  annual_demand      AS a ON a.sku = g.sku
)

SELECT
    cheap_supplier_type                                                  AS cheaper_source_type,
    COUNT(*)                                                             AS skus,
    ROUND(SUM(annual_price_saving_gbp), 0)                               AS annual_price_saving_gbp,
    ROUND(SUM(extra_working_capital_gbp), 0)                             AS one_off_working_capital_gbp,
    ROUND(SUM(annual_price_saving_gbp)
          - SUM(extra_working_capital_gbp) * :holding_rate_low, 0)       AS annual_net_at_20pct_gbp,
    ROUND(SUM(annual_price_saving_gbp)
          - SUM(extra_working_capital_gbp) * :holding_rate, 0)           AS annual_net_at_22pct_gbp,
    ROUND(SUM(annual_price_saving_gbp)
          - SUM(extra_working_capital_gbp) * :holding_rate_high, 0)      AS annual_net_at_25pct_gbp,
    COUNT(*) FILTER (WHERE annual_price_saving_gbp
                           - extra_working_capital_gbp * :holding_rate < 0)
                                                                         AS skus_net_negative,
    ROUND(SUM(extra_working_capital_gbp) / NULLIF(SUM(annual_price_saving_gbp), 0), 2)
                                                                         AS years_of_saving_tied_up
FROM   trade
GROUP  BY cheaper_source_type
ORDER  BY annual_net_at_22pct_gbp DESC;


\echo '=== 8. Which source did buyers actually favour, and was it the cheap one? ==='

SELECT
    CASE WHEN cheap_units > dear_units THEN 'Bought mostly from the cheaper source'
         ELSE                               'Bought mostly from the dearer source' END AS buying_pattern,
    COUNT(*)                                                             AS skus,
    ROUND(AVG(dear_premium_pct), 1)                                      AS mean_premium_pct,
    SUM(cheap_units)                                                     AS units_from_cheap,
    SUM(dear_units)                                                      AS units_from_dear,
    ROUND(SUM(gross_gap_on_dear_volume_gbp), 0)                          AS gross_gap_gbp,
    ROUND(AVG(cheap_moq::numeric / NULLIF(dear_moq, 0)), 1)              AS mean_moq_ratio_cheap_to_dear,
    ROUND(AVG(cheap_lead_days - dear_lead_days), 0)                      AS mean_extra_lead_days
FROM   vw_dual_source_gap
GROUP  BY buying_pattern
ORDER  BY buying_pattern;


\echo '=== 9. Reconciliation ==='

SELECT
    'Purchase order lines — source table'                                AS measure,
    (SELECT COUNT(*) FROM purchase_order_line)::numeric                  AS value
UNION ALL
SELECT 'Arden purchase lines — all',
       (SELECT COUNT(*) FROM purchase_order_line AS pol
        INNER JOIN purchase_order AS po USING (purchase_order_number)
        WHERE po.supplier_code = 'ARDEN')::numeric
UNION ALL
SELECT 'Arden SKUs priced on both sides of 2025-03-01',
       (SELECT COUNT(*) FROM vw_arden_price_change)::numeric
UNION ALL
SELECT 'Median like-for-like Arden change, per cent (expected near +18)',
       (SELECT ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY price_change_pct)::numeric, 1)
        FROM vw_arden_price_change)
UNION ALL
SELECT 'Dual-source SKUs compared',
       (SELECT COUNT(*) FROM vw_dual_source_gap)::numeric
UNION ALL
SELECT 'Total purchase spend, all suppliers',
       (SELECT ROUND(SUM(quantity_ordered * unit_cost_gbp), 0) FROM purchase_order_line);
