/* ============================================================
   Project    : 02 — Warehouse Inventory & Supply Chain Performance
   File       : 05_reporting_views/07_vw_working_capital_release_opportunity.sql
   Question   : BQ-01 / BQ-02 — Where is working capital tied up, and how
                much of it could be released without buying a service
                problem?
   Output     : view supply.vw_working_capital_release_opportunity
                analysis/query_results/report_07_working_capital_release_opportunity.txt
   Author     : Peters
   Created    : 2026-08-23
   ============================================================

   Calderfield Trade Supplies Ltd is fictional and this data is synthetic.

   Grain: one row per SKU per warehouse holding stock at 2025-12-28.
   515 positions, £1,711,041.86. Every position appears exactly once.

   THIS FILE DOES NOT MAKE RECOMMENDATIONS. It sizes and classifies
   opportunities and states the service consequence of each. Stage 6
   decides what to do.

   ---------------------------------------------------------------
   WHY A HIERARCHY AND NOT A SUM
   ---------------------------------------------------------------

   The Stage 4 files each measured a different exposure against the same
   stock, and the exposures overlap heavily:

     Slow-moving stock (file 03)                       £123,373
     Excess above the policy ceiling (file 04)         £134,701
     High cover over 6 months (file 05)                £398,821
     Stock above the calibrated rule (file 16)         £115,916
     Minimum-order bound in closing stock (file 17)    £336,205

   Adding those gives £1,109,016 against a network holding £1,711,042 —
   65% of the estate "released" by counting the same pounds up to five
   times. 23 positions worth £70,857 are both slow-moving AND above
   policy; 54.4% of high-cover positions are ALSO minimum-order
   constrained; 85.4% are ALSO policy-authorised. The charter requires
   overlapping opportunities to be counted once under a stated
   hierarchy (§16), and D-16 requires any combined total to be a union
   under an explicit rule rather than a sum.

   ---------------------------------------------------------------
   THE HIERARCHY, IN PRIORITY ORDER
   ---------------------------------------------------------------

   Each position is tested against the tiers in order and assigned to
   the FIRST it matches. The ordering runs from the mechanism whose
   release is most certain to the one whose release is least certain,
   so a position is always explained by the strongest claim available
   rather than the largest number.

   TIER 1 — DISCONTINUED OR OBSOLETE EXPOSURE
     Test        The product carries a discontinued date and the
                 position still holds stock.
     Why first   There is no future demand by definition. No other
                 mechanism can make a stronger claim on the same units.
     Releasable  The whole position.
     Source      file 03, F-03.

   TIER 2 — IMPORTER AND MINIMUM-ORDER STRUCTURAL STOCK
     Test        The last purchase against the position carried a
                 minimum-order increment that the position could still
                 be holding.
     Why second  The quantity was set by a term of trade, not by demand
                 and not by policy: 98.3% of importer purchase lines are
                 placed where the minimum exceeds the policy reorder
                 quantity and 99.3% are ordered at exactly the minimum.
                 It ranks above policy excess because it explains WHY
                 the policy was overshot, and D-34 forbids counting it
                 twice with generic excess.
     Releasable  The minimum-order bound — an upper bound, not an
                 estimate (D-34). Stock is fungible and valued at
                 weighted average cost; no unit records why it was
                 bought.
     Source      file 17, F-17, D-18, D-34.

   TIER 3 — STOCK ABOVE THE CALIBRATED REPLENISHMENT REQUIREMENT
     Test        The position's reorder point is set deep against
                 current demand — above 1.60x what the network's own
                 working rule would set (D-31) — and it is not already
                 explained by tier 1 or 2.
     Why third   This is a settings problem the business can fix without
                 renegotiating with a supplier, but the release is a
                 judgement about demand rather than a fact about a
                 catalogue or a contract.
     Releasable  Stock above what the calibrated rule would authorise:
                 quantity on hand less (rule reorder point + reorder
                 quantity), floored at zero.
     Note        Deliberately NOT file 04's excess above the site's own
                 policy ceiling. D-17: that measure records conformance
                 to rules that may themselves be wrong. The calibrated
                 rule measures the settings against demand.
     Source      file 16, F-16, D-31, D-33.

   TIER 4 — SLOW-MOVING RESIDUAL
     Test        No issue for over 26 weeks, or over 12 months of cover
                 (file 03's stated union rule, D-16), and not already
                 explained above.
     Why fourth  The weakest signal. A slow mover is not a dead line;
                 it may sell tomorrow, and substitution is not modelled.
     Releasable  The whole position where there is no demand to measure
                 against; otherwise stock above 52 weeks of cover.
     Source      file 03, F-03, D-16.

   TIER 5 — NO IDENTIFIED RELEASE OPPORTUNITY
     Everything else. Releasable capital is zero. This tier exists so
     the classification is exhaustive and the reader can see how much of
     the estate has no case against it at all.

   ---------------------------------------------------------------
   THE FEBRUARY 2025 ARDEN BUY-AHEAD IS CARVED OUT (D-30, D-35)
   ---------------------------------------------------------------

   File 15 found the buy-ahead was net POSITIVE: an £146,490 price
   saving against a residual bounded at £6,971, re-derived independently
   in file 17 and reproducing exactly. It must not be classified as
   residual excess. The tight residual bound is therefore subtracted
   from releasable capital in whichever tier the position lands, and
   section 7 reports it separately as a known, already-assessed
   consequence of a decision that paid for itself — not as an
   opportunity. Eight positions carry a residual; they are flagged on
   every row.

   ---------------------------------------------------------------
   TWO UNRESOLVED SERVICE ISSUES CONSTRAIN TWO SITES
   ---------------------------------------------------------------

   D-24. Daventry short-ships 2.60% of units even in weeks when cover
   was adequate, four to nine times the other sites, and the anomaly
   survived every correction offered — order lumpiness, customer mix,
   range mix and transfer activity.

   D-25. Bristol's unmet demand peaks in March and April 2025, and the
   pattern fits neither the opening-ramp explanation nor the
   replenishment-lag explanation cleanly.

   Neither is resolved. Positions at those two sites therefore carry an
   explicit constraint column. This is NOT a recommendation not to act;
   it is a statement that the service consequence at those sites cannot
   be fully quantified from this dataset.

   ---------------------------------------------------------------
   HOLDING COST
   ---------------------------------------------------------------

   22% per annum (D-11), with 20% and 25% on every row. Three of the
   four components of the rate are external assumptions the dataset
   cannot corroborate, so the capital released is always shown beside
   the cost saved and a reader can apply their own rate.

   Working capital released is a one-off. Holding cost saved is annual.
   They are different clocks and are never added (D-29).
   ============================================================ */

SET search_path TO supply;

\set snapshot_date '2025-12-28'
\set holding_rate 0.22
\set holding_rate_low 0.20
\set holding_rate_high 0.25
\set deep_threshold 1.60
\set slow_cover_weeks 52


CREATE OR REPLACE VIEW vw_working_capital_release_opportunity AS

WITH buy_ahead_residual AS (
    -- The tight bound, rebuilt from components rather than carried
    -- forward (D-28, D-35). Netting issues off first is the only version
    -- that says anything: the loose bound is £355,381 and the tight one
    -- £6,971 on the same positions.
    SELECT
        b.sku,
        b.warehouse_code,
        LEAST(GREATEST(b.excess_units_ordered - b.units_issued_since_receipt, 0),
              b.closing_units_on_hand)                                   AS residual_units
    FROM   vw_buy_ahead_stock AS b
),

position_base AS (
    SELECT
        s.sku,
        s.category_code,
        s.category_name,
        s.warehouse_code,
        s.quantity_on_hand,
        s.weighted_average_cost_gbp,
        s.stock_value_gbp,
        s.cover_weeks,
        s.issued_units_13w,
        s.weekly_demand_units,
        s.reorder_point_units,
        s.reorder_quantity_units,
        s.units_above_policy_ceiling,
        s.units_bounded_to_minimum,
        s.last_supplier_type,
        s.last_minimum_order_quantity,
        s.last_quoted_lead_days,
        s.shortest_lead_days,
        s.qualified_sources,
        c.product_name,
        c.discontinued_date,
        c.weeks_since_last_issue,
        c.age_band,
        c.cover_band,
        a.alignment_band,
        a.demand_direction,
        a.reorder_point_alignment_ratio,
        a.rule_reorder_point_units,
        a.policy_age_months,
        COALESCE(r.residual_units, 0)                                    AS buy_ahead_residual_units
    FROM       vw_structural_stock_position AS s
    INNER JOIN vw_closing_position          AS c
           ON  c.sku = s.sku AND c.warehouse_code = s.warehouse_code
    LEFT  JOIN vw_policy_alignment          AS a
           ON  a.sku = s.sku AND a.warehouse_code = s.warehouse_code
    LEFT  JOIN buy_ahead_residual           AS r
           ON  r.sku = s.sku AND r.warehouse_code = s.warehouse_code
),

classified AS (
    SELECT
        p.*,
        CASE
            WHEN p.discontinued_date IS NOT NULL AND p.quantity_on_hand > 0
                 THEN '1 — discontinued or obsolete exposure'
            WHEN p.units_bounded_to_minimum > 0
                 THEN '2 — importer and minimum-order structural stock'
            WHEN p.alignment_band = '3 — set deep against current demand'
                 THEN '3 — above the calibrated replenishment requirement'
            WHEN p.age_band IN ('3 — 27 to 52 weeks', '4 — over 52 weeks',
                                '5 — no issue in the period')
              OR p.cover_band = '5 — over 12 months'
                 THEN '4 — slow-moving residual'
            ELSE      '5 — no identified release opportunity'
        END                                                              AS opportunity_mechanism
    FROM   position_base AS p
),

quantified AS (
    SELECT
        c.*,
        -- Units the assigned mechanism can claim, before the buy-ahead
        -- carve-out. Each tier's rule is its own; a position is only
        -- ever measured by the rule of the tier it landed in.
        CASE c.opportunity_mechanism
            WHEN '1 — discontinued or obsolete exposure'
                 THEN c.quantity_on_hand
            WHEN '2 — importer and minimum-order structural stock'
                 THEN c.units_bounded_to_minimum
            WHEN '3 — above the calibrated replenishment requirement'
                 THEN GREATEST(c.quantity_on_hand
                               - (c.rule_reorder_point_units + c.reorder_quantity_units), 0)
            WHEN '4 — slow-moving residual'
                 THEN CASE WHEN c.cover_weeks IS NULL
                           THEN c.quantity_on_hand
                           ELSE GREATEST(c.quantity_on_hand
                                         - :slow_cover_weeks * c.weekly_demand_units, 0)
                      END
            ELSE 0
        END                                                              AS mechanism_units_before_carve_out
    FROM   classified AS c
)

SELECT
    q.opportunity_mechanism,
    q.sku,
    q.product_name,
    q.warehouse_code,
    q.category_code,
    q.category_name,

    -- Sourcing mechanism, carried on every row because tier 2 needs it
    -- and the other tiers are more readable with it.
    q.last_supplier_type                                                 AS sourcing_last_used,
    q.last_minimum_order_quantity,
    ROUND(q.last_minimum_order_quantity
          / NULLIF(q.weekly_demand_units, 0), 1)                         AS minimum_in_weeks_of_demand,
    q.last_quoted_lead_days,
    q.shortest_lead_days,
    q.qualified_sources,

    -- The position.
    q.quantity_on_hand,
    ROUND(q.stock_value_gbp, 2)                                          AS position_stock_value_gbp,
    q.cover_weeks,
    q.demand_direction,
    q.reorder_point_alignment_ratio,
    q.policy_age_months,
    q.weeks_since_last_issue,
    q.discontinued_date,

    -- The opportunity. The carve-out is subtracted here, so the
    -- February buy-ahead residual can never be counted as releasable
    -- capital in any tier (D-30).
    q.buy_ahead_residual_units                                           AS february_buy_ahead_residual_units,
    q.buy_ahead_residual_units > 0                                       AS is_february_buy_ahead_position,
    GREATEST(q.mechanism_units_before_carve_out - q.buy_ahead_residual_units, 0)
                                                                         AS releasable_units,
    ROUND(GREATEST(q.mechanism_units_before_carve_out - q.buy_ahead_residual_units, 0)
          * q.weighted_average_cost_gbp, 2)                              AS working_capital_gbp,
    ROUND(GREATEST(q.mechanism_units_before_carve_out - q.buy_ahead_residual_units, 0)
          * q.weighted_average_cost_gbp * :holding_rate, 2)              AS annual_holding_cost_gbp,
    ROUND(GREATEST(q.mechanism_units_before_carve_out - q.buy_ahead_residual_units, 0)
          * q.weighted_average_cost_gbp * :holding_rate_low, 2)          AS holding_cost_at_20pct_gbp,
    ROUND(GREATEST(q.mechanism_units_before_carve_out - q.buy_ahead_residual_units, 0)
          * q.weighted_average_cost_gbp * :holding_rate_high, 2)         AS holding_cost_at_25pct_gbp,
    ROUND(100.0 * GREATEST(q.mechanism_units_before_carve_out - q.buy_ahead_residual_units, 0)
          * q.weighted_average_cost_gbp / NULLIF(q.stock_value_gbp, 0), 1)
                                                                         AS releasable_share_of_position_pct,

    -- The service consequence of acting, stated per mechanism from
    -- measured figures rather than asserted.
    CASE q.opportunity_mechanism
        WHEN '1 — discontinued or obsolete exposure'
             THEN 'None from demand — the product is withdrawn. Realisation value is a disposal question this dataset cannot price.'
        WHEN '2 — importer and minimum-order structural stock'
             THEN 'Not free. Buying below the minimum means re-sourcing: the cheaper source is a Far East importer in every one of 60 dual-source SKUs, at a median 30% price advantage worth £492,020 a year (file 14). Shorter lead times would cut pipeline stock but forfeit that.'
        WHEN '3 — above the calibrated replenishment requirement'
             THEN 'Measured and modest. Deep-set lines run 2.79% unmet against 5.97% for lines in line with the rule, so trimming moves them towards network-average service rather than towards shortage.'
        WHEN '4 — slow-moving residual'
             THEN 'Weakest case. These lines still sell occasionally and substitution is not modelled, so unmet demand is an upper bound. Reducing them risks losing the occasional sale outright.'
        ELSE 'No identified opportunity. Reducing stock here has no measured justification and would be a service risk with no working-capital case behind it.'
    END                                                                  AS service_consequence,

    -- Where the mechanism came from.
    CASE q.opportunity_mechanism
        WHEN '1 — discontinued or obsolete exposure'
             THEN '04_analysis/03 — F-03'
        WHEN '2 — importer and minimum-order structural stock'
             THEN '04_analysis/17 — F-17; D-18, D-34'
        WHEN '3 — above the calibrated replenishment requirement'
             THEN '04_analysis/16 — F-16; D-31, D-33'
        WHEN '4 — slow-moving residual'
             THEN '04_analysis/03 — F-03; D-16'
        ELSE '—'
    END                                                                  AS source_reference,

    -- Unresolved service issues that constrain interpretation at two
    -- sites. Not a recommendation either way.
    CASE q.warehouse_code
        WHEN 'DAV' THEN 'Unresolved (D-24): Daventry short-ships 2.60% of units even when cover was adequate, 4-9x the other sites, and the anomaly survived every correction tested. The service consequence of reducing stock here cannot be fully quantified.'
        WHEN 'BRS' THEN 'Unresolved (D-25): Bristol''s unmet demand peaks in March and April 2025 and fits neither the opening-ramp nor the replenishment-lag explanation. The service consequence of reducing stock here cannot be fully quantified.'
        ELSE ''
    END                                                                  AS unresolved_service_constraint
FROM   quantified AS q;


\echo '=== 1. The hierarchy: exhaustive, mutually exclusive, and it must total ==='

-- Every position appears once. The position column must sum to
-- £1,711,041.86 across the five tiers, which is the proof that the
-- classification partitions the estate rather than sampling it.
SELECT
    CASE WHEN GROUPING(opportunity_mechanism) = 1 THEN 'ALL MECHANISMS'
         ELSE opportunity_mechanism END                                  AS opportunity_mechanism,
    COUNT(*)                                                             AS positions,
    SUM(quantity_on_hand)                                                AS units_on_hand,
    ROUND(SUM(position_stock_value_gbp), 2)                              AS position_stock_value_gbp,
    -- Denominator taken from the snapshot itself, not from a window over
    -- this result: a window would include the ROLLUP total row and halve
    -- every share.
    ROUND(100.0 * SUM(position_stock_value_gbp)
          / (SELECT SUM(stock_value_gbp) FROM mv_inventory_week
             WHERE week_ending_date = DATE :'snapshot_date'), 1)         AS share_of_network_stock_pct,
    ROUND(SUM(working_capital_gbp), 2)                                   AS working_capital_gbp,
    ROUND(SUM(annual_holding_cost_gbp), 2)                               AS annual_holding_cost_gbp,
    ROUND(SUM(holding_cost_at_20pct_gbp), 2)                             AS holding_cost_at_20pct_gbp,
    ROUND(SUM(holding_cost_at_25pct_gbp), 2)                             AS holding_cost_at_25pct_gbp
FROM   vw_working_capital_release_opportunity
GROUP  BY ROLLUP (opportunity_mechanism)
ORDER  BY GROUPING(opportunity_mechanism), opportunity_mechanism;


\echo '=== 2. Validation: the partition is exhaustive and non-overlapping ==='

SELECT
    'Positions classified'                                               AS check_name,
    (SELECT COUNT(*) FROM vw_working_capital_release_opportunity)::text  AS value,
    (SELECT COUNT(*) FROM mv_inventory_week
     WHERE week_ending_date = DATE :'snapshot_date')::text               AS expected,
    CASE WHEN (SELECT COUNT(*) FROM vw_working_capital_release_opportunity)
            = (SELECT COUNT(*) FROM mv_inventory_week
               WHERE week_ending_date = DATE :'snapshot_date')
         THEN 'PASS' ELSE 'FAIL' END                                     AS result
UNION ALL
SELECT 'Each position appears exactly once',
       (SELECT COUNT(*) FROM (SELECT sku, warehouse_code
                              FROM vw_working_capital_release_opportunity
                              GROUP BY sku, warehouse_code HAVING COUNT(*) > 1) AS d)::text,
       '0',
       CASE WHEN (SELECT COUNT(*) FROM (SELECT sku, warehouse_code
                                        FROM vw_working_capital_release_opportunity
                                        GROUP BY sku, warehouse_code HAVING COUNT(*) > 1) AS d) = 0
            THEN 'PASS' ELSE 'FAIL' END
UNION ALL
SELECT 'Tier stock values sum to closing stock',
       (SELECT ROUND(SUM(position_stock_value_gbp), 2)::text
        FROM vw_working_capital_release_opportunity),
       (SELECT ROUND(SUM(stock_value_gbp), 2)::text FROM mv_inventory_week
        WHERE week_ending_date = DATE :'snapshot_date'),
       CASE WHEN ABS((SELECT SUM(position_stock_value_gbp)
                      FROM vw_working_capital_release_opportunity)
                     - (SELECT SUM(stock_value_gbp) FROM mv_inventory_week
                        WHERE week_ending_date = DATE :'snapshot_date')) <= 0.05
            THEN 'PASS' ELSE 'FAIL' END
UNION ALL
SELECT 'Releasable capital never exceeds the position it sits in',
       (SELECT COUNT(*) FROM vw_working_capital_release_opportunity
        WHERE working_capital_gbp > position_stock_value_gbp + 0.01)::text,
       '0',
       CASE WHEN (SELECT COUNT(*) FROM vw_working_capital_release_opportunity
                  WHERE working_capital_gbp > position_stock_value_gbp + 0.01) = 0
            THEN 'PASS' ELSE 'FAIL' END
UNION ALL
SELECT 'Tier 5 releases nothing, by construction',
       (SELECT ROUND(SUM(working_capital_gbp), 2)::text
        FROM vw_working_capital_release_opportunity
        WHERE opportunity_mechanism = '5 — no identified release opportunity'),
       '0.00',
       CASE WHEN (SELECT SUM(working_capital_gbp)
                  FROM vw_working_capital_release_opportunity
                  WHERE opportunity_mechanism = '5 — no identified release opportunity') = 0
            THEN 'PASS' ELSE 'FAIL' END;


\echo '=== 3. What the hierarchy prevents: the overlapping totals it replaces ==='

-- The same pounds, counted the way each Stage 4 file counted them, and
-- then counted once here. The gap is the double counting the charter
-- required to be removed.
SELECT
    'Slow-moving stock (file 03, age or cover union)'                    AS stage_4_exposure,
    ROUND((SELECT SUM(stock_value_gbp) FROM vw_closing_position
           WHERE age_band IN ('3 — 27 to 52 weeks', '4 — over 52 weeks',
                              '5 — no issue in the period')
              OR cover_band = '5 — over 12 months'), 0)                  AS value_gbp
UNION ALL
SELECT 'Excess above the policy ceiling (file 04)',
       ROUND((SELECT SUM(excess_value_on_hand_gbp) FROM vw_excess_position), 0)
UNION ALL
SELECT 'Cover over 6 months (file 05)',
       ROUND((SELECT SUM(stock_value_gbp) FROM vw_cover_versus_trend WHERE cover_weeks > 26), 0)
UNION ALL
SELECT 'Stock above the calibrated rule (file 16)',
       ROUND((SELECT SUM(GREATEST(quantity_on_hand
                                  - (rule_reorder_point_units + reorder_quantity_units), 0)
                         * NULLIF(stock_value_gbp, 0) / NULLIF(quantity_on_hand, 0))
              FROM vw_policy_alignment), 0)
UNION ALL
SELECT 'Minimum-order bound in closing stock (file 17)',
       ROUND((SELECT SUM(units_bounded_to_minimum * weighted_average_cost_gbp)
              FROM vw_structural_stock_position), 0)
UNION ALL
SELECT 'Naive sum of the five — counts the same pounds up to five times',
       ROUND((SELECT SUM(stock_value_gbp) FROM vw_closing_position
              WHERE age_band IN ('3 — 27 to 52 weeks', '4 — over 52 weeks',
                                 '5 — no issue in the period')
                 OR cover_band = '5 — over 12 months')
             + (SELECT SUM(excess_value_on_hand_gbp) FROM vw_excess_position)
             + (SELECT SUM(stock_value_gbp) FROM vw_cover_versus_trend WHERE cover_weeks > 26)
             + (SELECT SUM(GREATEST(quantity_on_hand
                                    - (rule_reorder_point_units + reorder_quantity_units), 0)
                           * NULLIF(stock_value_gbp, 0) / NULLIF(quantity_on_hand, 0))
                FROM vw_policy_alignment)
             + (SELECT SUM(units_bounded_to_minimum * weighted_average_cost_gbp)
                FROM vw_structural_stock_position), 0)
UNION ALL
SELECT 'Counted once under the hierarchy',
       ROUND((SELECT SUM(working_capital_gbp)
              FROM vw_working_capital_release_opportunity), 0)
UNION ALL
SELECT 'Network closing stock, for scale',
       ROUND((SELECT SUM(stock_value_gbp) FROM mv_inventory_week
              WHERE week_ending_date = DATE :'snapshot_date'), 0);


\echo '=== 4. Where file 03''s slow-moving stock actually lands ==='

-- File 03 measured £123,373 of slow-moving stock. Under the hierarchy
-- most of it is explained by a stronger mechanism, and only the
-- remainder is a residual. This is the reconciliation that shows the
-- tiers are absorbing overlap rather than discarding it.
SELECT
    o.opportunity_mechanism,
    COUNT(*)                                                             AS slow_moving_positions,
    ROUND(SUM(o.position_stock_value_gbp), 0)                            AS slow_moving_stock_gbp,
    ROUND(SUM(o.working_capital_gbp), 0)                                 AS working_capital_gbp
FROM       vw_working_capital_release_opportunity AS o
INNER JOIN vw_closing_position                    AS c
       ON  c.sku = o.sku AND c.warehouse_code = o.warehouse_code
WHERE      c.age_band IN ('3 — 27 to 52 weeks', '4 — over 52 weeks',
                          '5 — no issue in the period')
       OR  c.cover_band = '5 — over 12 months'
GROUP  BY  o.opportunity_mechanism
ORDER  BY  o.opportunity_mechanism;


\echo '=== 5. Opportunity by site, with the unresolved constraint marked ==='

SELECT
    warehouse_code,
    COUNT(*)                                                             AS positions,
    ROUND(SUM(position_stock_value_gbp), 0)                              AS closing_stock_gbp,
    ROUND(SUM(working_capital_gbp), 0)                                   AS working_capital_gbp,
    ROUND(100.0 * SUM(working_capital_gbp)
          / NULLIF(SUM(position_stock_value_gbp), 0), 1)                 AS releasable_share_pct,
    ROUND(SUM(annual_holding_cost_gbp), 0)                               AS annual_holding_cost_gbp,
    ROUND(SUM(holding_cost_at_20pct_gbp), 0)                             AS at_20pct_gbp,
    ROUND(SUM(holding_cost_at_25pct_gbp), 0)                             AS at_25pct_gbp,
    MAX(CASE WHEN unresolved_service_constraint <> '' THEN 'yes' ELSE '' END)
                                                                         AS unresolved_service_issue
FROM   vw_working_capital_release_opportunity
GROUP  BY warehouse_code
ORDER  BY working_capital_gbp DESC;


\echo '=== 6. Opportunity by mechanism and site ==='

SELECT
    opportunity_mechanism,
    warehouse_code,
    COUNT(*)                                                             AS positions,
    ROUND(SUM(working_capital_gbp), 0)                                   AS working_capital_gbp,
    ROUND(SUM(annual_holding_cost_gbp), 0)                               AS annual_holding_cost_gbp
FROM   vw_working_capital_release_opportunity
WHERE  working_capital_gbp > 0
GROUP  BY opportunity_mechanism, warehouse_code
ORDER  BY opportunity_mechanism, working_capital_gbp DESC;


\echo '=== 7. The February buy-ahead carve-out (D-30, D-35) ==='

-- Reported, excluded from every tier's releasable capital, and NOT an
-- opportunity. File 15 measured the decision as net positive.
SELECT
    'Positions carrying a February buy-ahead residual'                   AS measure,
    COUNT(*)                                                             AS positions,
    NULL::numeric                                                        AS value_gbp
FROM   vw_working_capital_release_opportunity
WHERE  is_february_buy_ahead_position
UNION ALL
SELECT 'Tight residual bound carved out of releasable capital',
       NULL,
       ROUND(SUM(february_buy_ahead_residual_units * position_stock_value_gbp
                 / NULLIF(quantity_on_hand, 0)), 0)
FROM   vw_working_capital_release_opportunity
WHERE  is_february_buy_ahead_position
UNION ALL
SELECT 'Price saving the buy-ahead captured (file 15)',
       NULL, ROUND((SELECT SUM(price_saving_gbp) FROM vw_buy_ahead_lines), 0)
UNION ALL
SELECT 'Net position of the decision, at 22% (file 15, D-30)',
       NULL,
       ROUND((SELECT SUM(price_saving_gbp) FROM vw_buy_ahead_lines)
             - (SELECT SUM(LEAST(GREATEST(excess_units_ordered - units_issued_since_receipt, 0),
                                 closing_units_on_hand)
                           * NULLIF(closing_stock_value_gbp, 0)
                           / NULLIF(closing_units_on_hand, 0))
                FROM vw_buy_ahead_stock) * :holding_rate, 0);


-- Which tiers those eight positions landed in, on their own merits.
SELECT
    opportunity_mechanism,
    COUNT(*)                                                             AS buy_ahead_positions,
    SUM(february_buy_ahead_residual_units)                               AS residual_units_carved_out,
    ROUND(SUM(working_capital_gbp), 0)                                   AS working_capital_after_carve_out_gbp
FROM   vw_working_capital_release_opportunity
WHERE  is_february_buy_ahead_position
GROUP  BY opportunity_mechanism
ORDER  BY opportunity_mechanism;


\echo '=== 8. The twenty largest opportunities, with everything needed to judge them ==='

SELECT
    opportunity_mechanism,
    sku,
    warehouse_code,
    category_code,
    sourcing_last_used,
    minimum_in_weeks_of_demand,
    quantity_on_hand,
    position_stock_value_gbp,
    releasable_units,
    working_capital_gbp,
    annual_holding_cost_gbp,
    holding_cost_at_20pct_gbp,
    holding_cost_at_25pct_gbp,
    cover_weeks,
    demand_direction,
    reorder_point_alignment_ratio,
    source_reference,
    CASE WHEN unresolved_service_constraint <> '' THEN 'constrained' ELSE '' END
                                                                         AS site_constraint
FROM   vw_working_capital_release_opportunity
WHERE  working_capital_gbp > 0
ORDER  BY working_capital_gbp DESC, sku, warehouse_code
LIMIT  20;


\echo '=== 9. Service consequence and source reference, one row per mechanism ==='

SELECT DISTINCT
    opportunity_mechanism,
    source_reference,
    service_consequence
FROM   vw_working_capital_release_opportunity
ORDER  BY opportunity_mechanism;
