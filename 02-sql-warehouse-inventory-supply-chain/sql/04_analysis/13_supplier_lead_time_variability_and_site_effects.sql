/* ============================================================
   Project    : 02 — Warehouse Inventory & Supply Chain Performance
   File       : 04_analysis/13_supplier_lead_time_variability_and_site_effects.sql
   Question   : BQ-06 / AQ-13 — How much of a delivery delay belongs to
                the supplier, and how much belongs to our own
                goods-inwards process?
   Finding ID : F-13
   Output     : analysis/query_results/analyse_13_lead_time_and_site_effects.txt
   Author     : Peters
   Created    : 2026-08-23
   ============================================================

   Calderfield Trade Supplies Ltd is fictional and this data is synthetic.

   Grain: one row per goods receipt line. First deliveries only unless
   stated — a split shipment's second drop is late by construction and
   would contaminate a lead-time distribution (D-07).

   Comparable window closes 2025-09-30 (D-14).

   THE PROBLEM THIS FILE EXISTS FOR. Livingston books goods inwards in a
   Monday batch: 39.8% of its receipts land on a Monday against 14-21%
   elsewhere, and its mean overrun against quoted lead time is 14.8 days
   against 7.1-7.9 (D-08). Livingston also buys heavily from Meridian,
   the one supplier with a measured decline (F-12). Read without
   controlling for site, the two are inseparable and Meridian carries
   the blame for a Livingston process.

   HOW THE SPLIT IS DONE. Section 6 fits an additive two-way
   decomposition of mean lead-time overrun:

       cell mean = grand mean + supplier effect + site effect + residual

   The supplier and site effects are marginal deviations from the grand
   mean; the residual is what neither explains. A large residual means
   the two interact — a supplier that is late only at one site — and is
   reported rather than absorbed.

   WHAT THIS CANNOT DO. This is association, not causation. The dataset
   is observational: sites choose their suppliers, so supplier and site
   are not independent, and no decomposition of observational data can
   separate them the way an experiment would. The residual column is the
   honest measure of how much is left unexplained.
   ============================================================ */

SET search_path TO supply;

\set window_close '2025-09-30'
\set min_cell 20


\echo '=== 1. Lead-time distribution by supplier type — not just the mean ==='

-- Quoted against actual, with the shape of the distribution. The interquartile
-- range and the 90th percentile say more about planning risk than a mean does.
SELECT
    supplier_type,
    COUNT(*)                                                             AS n_first_receipts,
    ROUND(AVG(quoted_lead_time_days), 0)                                 AS quoted_days,
    ROUND(PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY actual_lead_time_days)::numeric, 0)
                                                                         AS median_actual_days,
    ROUND(PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY actual_lead_time_days)::numeric, 0)
                                                                         AS p25_days,
    ROUND(PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY actual_lead_time_days)::numeric, 0)
                                                                         AS p75_days,
    ROUND(PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY actual_lead_time_days)::numeric
          - PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY actual_lead_time_days)::numeric, 0)
                                                                         AS iqr_days,
    ROUND(PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY actual_lead_time_days)::numeric, 0)
                                                                         AS p90_days,
    ROUND(MAX(actual_lead_time_days), 0)                                 AS longest_days,
    ROUND(STDDEV_SAMP(actual_lead_time_days), 1)                         AS stddev_days,
    ROUND(AVG(lead_time_variance_days), 1)                               AS mean_overrun_vs_quoted,
    ROUND(PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY lead_time_variance_days)::numeric, 1)
                                                                         AS median_overrun_vs_quoted
FROM   vw_receipt_performance
WHERE  is_in_primary_window
  AND  receipt_sequence = 1
GROUP  BY supplier_type
ORDER  BY median_actual_days;


\echo '=== 2. The same distribution by receiving site ==='

-- If lead time were purely a supplier property, these four rows would differ
-- only through their supplier mix.
SELECT
    warehouse_code,
    COUNT(*)                                                             AS n_first_receipts,
    ROUND(PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY actual_lead_time_days)::numeric, 0)
                                                                         AS median_actual_days,
    ROUND(PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY actual_lead_time_days)::numeric
          - PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY actual_lead_time_days)::numeric, 0)
                                                                         AS iqr_days,
    ROUND(STDDEV_SAMP(actual_lead_time_days), 1)                         AS stddev_days,
    ROUND(AVG(lead_time_variance_days), 1)                               AS mean_overrun_vs_quoted,
    ROUND(PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY lead_time_variance_days)::numeric, 1)
                                                                         AS median_overrun_vs_quoted,
    ROUND(100.0 * COUNT(*) FILTER (WHERE supplier_type = 'Far East Importer') / COUNT(*), 1)
                                                                         AS importer_share_of_receipts_pct
FROM   vw_receipt_performance
WHERE  is_in_primary_window
  AND  receipt_sequence = 1
GROUP  BY warehouse_code
ORDER  BY mean_overrun_vs_quoted DESC;


\echo '=== 3. Weekday receipt pattern, quantified ==='

SELECT
    warehouse_code,
    COUNT(*)                                                             AS receipts,
    COUNT(*) FILTER (WHERE EXTRACT(ISODOW FROM receipt_date) = 1)        AS monday,
    COUNT(*) FILTER (WHERE EXTRACT(ISODOW FROM receipt_date) = 2)        AS tuesday,
    COUNT(*) FILTER (WHERE EXTRACT(ISODOW FROM receipt_date) = 3)        AS wednesday,
    COUNT(*) FILTER (WHERE EXTRACT(ISODOW FROM receipt_date) = 4)        AS thursday,
    COUNT(*) FILTER (WHERE EXTRACT(ISODOW FROM receipt_date) = 5)        AS friday,
    ROUND(100.0 * COUNT(*) FILTER (WHERE EXTRACT(ISODOW FROM receipt_date) = 1) / COUNT(*), 1)
                                                                         AS monday_share_pct,
    -- An even spread across five working days would be 20%.
    ROUND(100.0 * COUNT(*) FILTER (WHERE EXTRACT(ISODOW FROM receipt_date) = 1) / COUNT(*) - 20.0, 1)
                                                                         AS monday_excess_points
FROM   vw_receipt_performance
WHERE  is_in_primary_window
GROUP  BY warehouse_code
ORDER  BY monday_share_pct DESC;


\echo '=== 4. Test the Monday effect directly ==='

-- Within Livingston, do Monday-booked receipts carry more overrun than the
-- rest? And does the same gap appear at sites without a Monday batch? If the
-- gap is Livingston-specific it is a process effect, not a weekday artefact.
SELECT
    warehouse_code,
    COUNT(*) FILTER (WHERE booked_on_monday)                             AS n_monday,
    ROUND(AVG(lead_time_variance_days) FILTER (WHERE booked_on_monday), 1)
                                                                         AS mean_overrun_monday,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY lead_time_variance_days)
          FILTER (WHERE booked_on_monday)::numeric, 1)                   AS median_overrun_monday,
    COUNT(*) FILTER (WHERE NOT booked_on_monday)                         AS n_other_days,
    ROUND(AVG(lead_time_variance_days) FILTER (WHERE NOT booked_on_monday), 1)
                                                                         AS mean_overrun_other_days,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY lead_time_variance_days)
          FILTER (WHERE NOT booked_on_monday)::numeric, 1)               AS median_overrun_other_days,
    ROUND(AVG(lead_time_variance_days) FILTER (WHERE booked_on_monday)
          - AVG(lead_time_variance_days) FILTER (WHERE NOT booked_on_monday), 1)
                                                                         AS monday_penalty_days
FROM   vw_receipt_performance
WHERE  is_in_primary_window
  AND  receipt_sequence = 1
GROUP  BY warehouse_code
ORDER  BY monday_penalty_days DESC NULLS LAST;


\echo '=== 5. Supplier lead times with the receiving site held constant ==='

-- Every supplier that delivers to more than one site, measured at each. A
-- supplier whose overrun is uniform across sites is telling you about itself;
-- one whose overrun jumps at a single site is telling you about that site.
WITH cells AS (
    SELECT
        supplier_code,
        supplier_name,
        supplier_type,
        warehouse_code,
        COUNT(*)                                                         AS n,
        AVG(lead_time_variance_days)                                     AS mean_overrun
    FROM   vw_receipt_performance
    WHERE  is_in_primary_window
      AND  receipt_sequence = 1
    GROUP  BY supplier_code, supplier_name, supplier_type, warehouse_code
    HAVING COUNT(*) >= :min_cell
)

SELECT
    supplier_code,
    supplier_name,
    supplier_type,
    COUNT(*)                                                             AS sites_with_enough_data,
    SUM(n)                                                               AS total_receipts,
    ROUND(MAX(mean_overrun) FILTER (WHERE warehouse_code = 'DAV'), 1)    AS daventry_overrun,
    MAX(n)                 FILTER (WHERE warehouse_code = 'DAV')         AS n_dav,
    ROUND(MAX(mean_overrun) FILTER (WHERE warehouse_code = 'WAR'), 1)    AS warrington_overrun,
    MAX(n)                 FILTER (WHERE warehouse_code = 'WAR')         AS n_war,
    ROUND(MAX(mean_overrun) FILTER (WHERE warehouse_code = 'BRS'), 1)    AS bristol_overrun,
    MAX(n)                 FILTER (WHERE warehouse_code = 'BRS')         AS n_brs,
    ROUND(MAX(mean_overrun) FILTER (WHERE warehouse_code = 'LIV'), 1)    AS livingston_overrun,
    MAX(n)                 FILTER (WHERE warehouse_code = 'LIV')         AS n_liv,
    ROUND(MAX(mean_overrun) - MIN(mean_overrun), 1)                      AS spread_across_sites
FROM   cells
GROUP  BY supplier_code, supplier_name, supplier_type
HAVING COUNT(*) > 1
ORDER  BY spread_across_sites DESC;


\echo '=== 6. Two-way decomposition: supplier, site, and what is left ==='

-- Additive model on mean overrun against quoted lead time:
--     cell = grand mean + supplier effect + site effect + residual
-- Restricted to supplier-and-site cells with at least 20 first receipts. The
-- coverage row states what share of receipts the model actually sees.
DROP VIEW IF EXISTS vw_lead_time_decomposition CASCADE;

CREATE VIEW vw_lead_time_decomposition AS

-- WHY THIS IS NOT A SIMPLE MARGINAL MEAN. The design is badly unbalanced:
-- Daventry has 21 supplier cells, Livingston only 3, and 52% of Livingston's
-- modelled receipts come from importers against 7.5% of Daventry's. Taking each
-- site's raw marginal mean would fold that supplier mix straight into the site
-- effect and hand Livingston a penalty that belongs to the suppliers it happens
-- to use — the exact error this file exists to avoid.
--
-- The effects are therefore fitted by alternating adjustment: estimate site
-- effects holding supplier effects fixed, then supplier effects holding site
-- effects fixed, and repeat. Four rounds, which is ample for a 4-by-26 design.
-- Both the naive marginal and the fitted effect are carried through so the
-- difference between them is visible rather than assumed away.
WITH base AS (
    SELECT supplier_code, supplier_name, supplier_type, warehouse_code, lead_time_variance_days
    FROM   vw_receipt_performance
    WHERE  is_in_primary_window AND receipt_sequence = 1
),

cells AS (
    SELECT
        supplier_code, supplier_name, supplier_type, warehouse_code,
        COUNT(*)                                                         AS n,
        AVG(lead_time_variance_days)                                     AS cell_mean
    FROM   base
    GROUP  BY supplier_code, supplier_name, supplier_type, warehouse_code
    HAVING COUNT(*) >= :min_cell
),

grand AS (
    SELECT SUM(cell_mean * n) / NULLIF(SUM(n), 0)                        AS grand_mean
    FROM   cells
),

-- Naive marginals, kept for comparison only.
naive_site AS (
    SELECT c.warehouse_code,
           SUM(c.cell_mean * c.n) / NULLIF(SUM(c.n), 0) - MAX(g.grand_mean) AS naive_site_effect
    FROM   cells AS c CROSS JOIN grand AS g GROUP BY c.warehouse_code
),

naive_supplier AS (
    SELECT c.supplier_code,
           SUM(c.cell_mean * c.n) / NULLIF(SUM(c.n), 0) - MAX(g.grand_mean) AS naive_supplier_effect
    FROM   cells AS c CROSS JOIN grand AS g GROUP BY c.supplier_code
),

-- Round 1: site effects with supplier effects held at zero.
site_1 AS (
    SELECT c.warehouse_code,
           SUM((c.cell_mean - g.grand_mean) * c.n) / NULLIF(SUM(c.n), 0)  AS eff
    FROM   cells AS c CROSS JOIN grand AS g GROUP BY c.warehouse_code
),

supplier_1 AS (
    SELECT c.supplier_code,
           SUM((c.cell_mean - g.grand_mean - s.eff) * c.n) / NULLIF(SUM(c.n), 0) AS eff
    FROM   cells AS c CROSS JOIN grand AS g INNER JOIN site_1 AS s USING (warehouse_code)
    GROUP  BY c.supplier_code
),

site_2 AS (
    SELECT c.warehouse_code,
           SUM((c.cell_mean - g.grand_mean - p.eff) * c.n) / NULLIF(SUM(c.n), 0) AS eff
    FROM   cells AS c CROSS JOIN grand AS g INNER JOIN supplier_1 AS p USING (supplier_code)
    GROUP  BY c.warehouse_code
),

supplier_2 AS (
    SELECT c.supplier_code,
           SUM((c.cell_mean - g.grand_mean - s.eff) * c.n) / NULLIF(SUM(c.n), 0) AS eff
    FROM   cells AS c CROSS JOIN grand AS g INNER JOIN site_2 AS s USING (warehouse_code)
    GROUP  BY c.supplier_code
),

site_3 AS (
    SELECT c.warehouse_code,
           SUM((c.cell_mean - g.grand_mean - p.eff) * c.n) / NULLIF(SUM(c.n), 0) AS eff
    FROM   cells AS c CROSS JOIN grand AS g INNER JOIN supplier_2 AS p USING (supplier_code)
    GROUP  BY c.warehouse_code
),

supplier_3 AS (
    SELECT c.supplier_code,
           SUM((c.cell_mean - g.grand_mean - s.eff) * c.n) / NULLIF(SUM(c.n), 0) AS eff
    FROM   cells AS c CROSS JOIN grand AS g INNER JOIN site_3 AS s USING (warehouse_code)
    GROUP  BY c.supplier_code
),

site_4 AS (
    SELECT c.warehouse_code,
           SUM((c.cell_mean - g.grand_mean - p.eff) * c.n) / NULLIF(SUM(c.n), 0) AS eff
    FROM   cells AS c CROSS JOIN grand AS g INNER JOIN supplier_3 AS p USING (supplier_code)
    GROUP  BY c.warehouse_code
),

supplier_4 AS (
    SELECT c.supplier_code,
           SUM((c.cell_mean - g.grand_mean - s.eff) * c.n) / NULLIF(SUM(c.n), 0) AS eff
    FROM   cells AS c CROSS JOIN grand AS g INNER JOIN site_4 AS s USING (warehouse_code)
    GROUP  BY c.supplier_code
)

SELECT
    c.supplier_code,
    c.supplier_name,
    c.supplier_type,
    c.warehouse_code,
    c.n,
    ROUND(c.cell_mean, 1)                                                AS cell_mean_overrun_days,
    ROUND(g.grand_mean, 1)                                               AS grand_mean_days,
    ROUND(ns.naive_site_effect, 1)                                       AS naive_site_effect_days,
    ROUND(s4.eff, 1)                                                     AS site_effect_days,
    ROUND(np.naive_supplier_effect, 1)                                   AS naive_supplier_effect_days,
    ROUND(p4.eff, 1)                                                     AS supplier_effect_days,
    ROUND(c.cell_mean - g.grand_mean - s4.eff - p4.eff, 1)               AS residual_days
FROM       cells          AS c
CROSS JOIN grand          AS g
INNER JOIN site_4         AS s4 ON s4.warehouse_code = c.warehouse_code
INNER JOIN supplier_4     AS p4 ON p4.supplier_code  = c.supplier_code
INNER JOIN naive_site     AS ns ON ns.warehouse_code = c.warehouse_code
INNER JOIN naive_supplier AS np ON np.supplier_code  = c.supplier_code;


SELECT
    'First receipts in the comparable window'                            AS measure,
    (SELECT COUNT(*) FROM vw_receipt_performance
     WHERE is_in_primary_window AND receipt_sequence = 1)::numeric        AS value
UNION ALL
SELECT 'Receipts inside modelled cells (n >= 20)',
       (SELECT SUM(n) FROM vw_lead_time_decomposition)::numeric
UNION ALL
SELECT 'Coverage of the model, per cent',
       ROUND(100.0 * (SELECT SUM(n) FROM vw_lead_time_decomposition)
             / NULLIF((SELECT COUNT(*) FROM vw_receipt_performance
                       WHERE is_in_primary_window AND receipt_sequence = 1), 0), 1)
UNION ALL
SELECT 'Supplier-and-site cells modelled',
       (SELECT COUNT(*) FROM vw_lead_time_decomposition)::numeric
UNION ALL
SELECT 'Mean absolute residual after fitting, days',
       ROUND((SELECT SUM(ABS(residual_days) * n) / NULLIF(SUM(n), 0)
              FROM vw_lead_time_decomposition), 2);


-- Site effects: naive against fitted. The gap is supplier mix.
SELECT
    warehouse_code,
    SUM(n)                                                               AS receipts_modelled,
    COUNT(*)                                                             AS supplier_cells,
    ROUND(100.0 * SUM(n) FILTER (WHERE supplier_type = 'Far East Importer')
          / NULLIF(SUM(n), 0), 1)                                        AS importer_share_of_cells_pct,
    ROUND(MAX(naive_site_effect_days), 1)                                AS naive_site_effect_days,
    ROUND(MAX(site_effect_days), 1)                                      AS fitted_site_effect_days,
    ROUND(MAX(naive_site_effect_days) - MAX(site_effect_days), 1)        AS attributable_to_supplier_mix
FROM   vw_lead_time_decomposition
GROUP  BY warehouse_code
ORDER  BY fitted_site_effect_days DESC;


-- Supplier effects: naive against fitted. The gap is site mix.
SELECT
    supplier_code,
    supplier_type,
    SUM(n)                                                               AS receipts_modelled,
    COUNT(*)                                                             AS site_cells,
    ROUND(MAX(naive_supplier_effect_days), 1)                            AS naive_supplier_effect_days,
    ROUND(MAX(supplier_effect_days), 1)                                  AS fitted_supplier_effect_days,
    ROUND(MAX(naive_supplier_effect_days) - MAX(supplier_effect_days), 1) AS attributable_to_site_mix
FROM   vw_lead_time_decomposition
GROUP  BY supplier_code, supplier_type
ORDER  BY fitted_supplier_effect_days DESC;


\echo '=== 7. The cells themselves, with the residual exposed ==='

SELECT
    supplier_code,
    supplier_type,
    warehouse_code,
    n,
    cell_mean_overrun_days,
    grand_mean_days,
    supplier_effect_days,
    site_effect_days,
    residual_days,
    ROUND(ABS(residual_days), 1)                                         AS unexplained_magnitude
FROM   vw_lead_time_decomposition
ORDER  BY ABS(residual_days) DESC;


\echo '=== 8. How much of Livingston''s overrun is which? ==='

WITH liv AS (
    SELECT
        ROUND(MAX(site_effect_days), 1)                                  AS livingston_site_effect,
        ROUND(SUM(cell_mean_overrun_days * n) / NULLIF(SUM(n), 0), 1)    AS livingston_mean_overrun,
        SUM(n)                                                           AS n
    FROM   vw_lead_time_decomposition
    WHERE  warehouse_code = 'LIV'
),

network AS (
    SELECT ROUND(MAX(grand_mean_days), 1) AS grand_mean FROM vw_lead_time_decomposition
),

monday AS (
    SELECT
        ROUND(AVG(lead_time_variance_days) FILTER (WHERE booked_on_monday)
              - AVG(lead_time_variance_days) FILTER (WHERE NOT booked_on_monday), 1)
                                                                         AS monday_penalty_days,
        ROUND(100.0 * COUNT(*) FILTER (WHERE booked_on_monday) / COUNT(*), 1)
                                                                         AS monday_share_pct
    FROM   vw_receipt_performance
    WHERE  is_in_primary_window AND receipt_sequence = 1 AND warehouse_code = 'LIV'
),

baseline_monday AS (
    SELECT ROUND(100.0 * COUNT(*) FILTER (WHERE booked_on_monday) / COUNT(*), 1) AS monday_share_pct
    FROM   vw_receipt_performance
    WHERE  is_in_primary_window AND receipt_sequence = 1 AND warehouse_code <> 'LIV'
)

SELECT
    l.n                                                                  AS livingston_receipts_modelled,
    n.grand_mean                                                         AS network_grand_mean_days,
    l.livingston_mean_overrun                                            AS livingston_mean_overrun_days,
    l.livingston_site_effect                                             AS site_effect_days,
    m.monday_share_pct                                                   AS livingston_monday_share_pct,
    b.monday_share_pct                                                   AS other_sites_monday_share_pct,
    m.monday_penalty_days                                                AS monday_penalty_days,
    -- Excess Monday bookings above the network's own rate, multiplied by the
    -- penalty those bookings carry. An estimate of the days attributable to
    -- the batching practice, not a measurement of it.
    ROUND((m.monday_share_pct - b.monday_share_pct) / 100.0 * m.monday_penalty_days, 2)
                                                                         AS days_attributable_to_batching,
    ROUND(100.0 * ((m.monday_share_pct - b.monday_share_pct) / 100.0 * m.monday_penalty_days)
          / NULLIF(l.livingston_site_effect, 0), 1)                      AS share_of_site_effect_pct
FROM       liv             AS l
CROSS JOIN network         AS n
CROSS JOIN monday          AS m
CROSS JOIN baseline_monday AS b;


\echo '=== 9. Meridian with and without the Livingston effect ==='

-- The specific confound D-08 warned about, resolved.
SELECT
    warehouse_code,
    COUNT(*)                                                             AS n_first_receipts,
    ROUND(AVG(quoted_lead_time_days), 0)                                 AS quoted_days,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY actual_lead_time_days)::numeric, 0)
                                                                         AS median_actual_days,
    ROUND(AVG(lead_time_variance_days), 1)                               AS mean_overrun_days,
    ROUND(100.0 * COUNT(*) FILTER (WHERE is_on_time)
          / NULLIF(COUNT(*) FILTER (WHERE is_measurable), 0), 1)         AS on_time_pct,
    ROUND(100.0 * COUNT(*) FILTER (WHERE booked_on_monday) / COUNT(*), 1) AS monday_share_pct
FROM   vw_receipt_performance
WHERE  is_in_primary_window
  AND  receipt_sequence = 1
  AND  supplier_code = 'MERID'
GROUP  BY warehouse_code
ORDER  BY mean_overrun_days DESC;


-- And the trend at one site only, so the site cannot move underneath it.
SELECT
    order_half_year,
    COUNT(*) FILTER (WHERE warehouse_code = 'DAV')                       AS n_daventry,
    ROUND(100.0 * COUNT(*) FILTER (WHERE is_on_time AND warehouse_code = 'DAV')
          / NULLIF(COUNT(*) FILTER (WHERE is_measurable AND warehouse_code = 'DAV'), 0), 1)
                                                                         AS on_time_daventry_pct,
    COUNT(*) FILTER (WHERE warehouse_code = 'LIV')                       AS n_livingston,
    ROUND(100.0 * COUNT(*) FILTER (WHERE is_on_time AND warehouse_code = 'LIV')
          / NULLIF(COUNT(*) FILTER (WHERE is_measurable AND warehouse_code = 'LIV'), 0), 1)
                                                                         AS on_time_livingston_pct
FROM   vw_receipt_performance
WHERE  is_in_primary_window
  AND  receipt_sequence = 1
  AND  supplier_code = 'MERID'
GROUP  BY order_half_year
ORDER  BY order_half_year;


\echo '=== 10. Reconciliation ==='

SELECT
    'First receipts, comparable window'                                  AS measure,
    (SELECT COUNT(*) FROM vw_receipt_performance
     WHERE is_in_primary_window AND receipt_sequence = 1)::numeric        AS value
UNION ALL
SELECT 'All receipts, comparable window',
       (SELECT COUNT(*) FROM vw_receipt_performance WHERE is_in_primary_window)::numeric
UNION ALL
SELECT 'Receipts with a negative lead time (must be 0)',
       (SELECT COUNT(*) FROM vw_receipt_performance WHERE actual_lead_time_days < 0)::numeric
UNION ALL
SELECT 'Weighted mean fitted site effect (near 0 if the fit converged)',
       ROUND((SELECT SUM(site_effect_days * n) / NULLIF(SUM(n), 0)
              FROM vw_lead_time_decomposition), 2)
UNION ALL
SELECT 'Weighted mean fitted supplier effect (near 0 if the fit converged)',
       ROUND((SELECT SUM(supplier_effect_days * n) / NULLIF(SUM(n), 0)
              FROM vw_lead_time_decomposition), 2)
UNION ALL
SELECT 'Mean absolute residual, days',
       ROUND((SELECT SUM(ABS(residual_days) * n) / NULLIF(SUM(n), 0)
              FROM vw_lead_time_decomposition), 2);
