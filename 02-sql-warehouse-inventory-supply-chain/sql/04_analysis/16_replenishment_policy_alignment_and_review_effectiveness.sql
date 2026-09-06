/* ============================================================
   Project    : 02 — Warehouse Inventory & Supply Chain Performance
   File       : 04_analysis/16_replenishment_policy_alignment_and_review_effectiveness.sql
   Question   : BQ-04 / AQ-16 — Are current replenishment settings aligned
                with current demand conditions, and does policy review
                recency provide any useful signal about that alignment?
   Finding ID : F-16
   Output     : analysis/query_results/analyse_16_policy_alignment_and_review_effectiveness.txt
   Author     : Peters
   Created    : 2026-08-23
   ============================================================

   Calderfield Trade Supplies Ltd is fictional and this data is synthetic.

   Grain: one row per SKU per warehouse at the closing snapshot of
   2025-12-28, with demand direction measured across the quarters that
   site actually traded and outcome measured across the 2025 weeks.

   THREE THINGS THIS FILE KEEPS APART.

   1. POLICY AGE. Months from last_reviewed_date to 2025-12-31. An
      administrative fact about the record.
   2. POLICY ALIGNMENT. Whether the reorder point and reorder quantity
      match the demand the line has NOW, measured in weeks of current
      demand against the network's own working rule.
   3. INVENTORY OUTCOME. Cover, stock value, weeks at zero and unmet
      demand during 2025. Policy is one input to this; supply, MOQ and
      demand volatility are others.

   Alignment is defined without reference to age. Outcome is defined
   without reference to either. That is what allows them to be crossed
   in section 5 rather than assumed to move together.

   WHAT THIS FILE CANNOT DO. replenishment_policy holds one row per SKU
   and site: the CURRENT settings and a single last_reviewed_date. The
   settings that existed before that review were never recorded. There
   is therefore no before-and-after comparison available, and nothing
   here can say what a review changed or that a review caused an
   improvement. A review that happened and altered nothing is
   indistinguishable from one that reset the line completely.

   D-21 STANDS. File 08 found stale policies associated with a LOWER
   unmet rate (6.03% against 7.80%) at near-identical reorder depth.
   Policy age is descriptive in this file throughout. If age carried
   signal, alignment would deteriorate with age; whether it does is the
   measurement, and a null result is a result.

   THE BENCHMARK IS CALIBRATED, NOT ASSUMED. Section 2 derives the
   network's own working rule — the median multiple of lead-time demand
   that the reorder point sits at — from lines whose demand is broadly
   flat, where current demand is closest to the demand prevailing when
   the settings were made. That rule is then applied to every line at
   its current demand. The consequence is that flat lines centre on 1.0
   by construction and are the reference, not evidence. The finding
   lives in the rising and falling groups.
   ============================================================ */

SET search_path TO supply;

\set snapshot_date '2025-12-28'
\set analysis_date '2025-12-31'
\set year_start '2025-01-01'
\set holding_rate 0.22
\set stale_months 15


\echo '=== 1. Population: what can and cannot be assessed ==='

-- A line is assessable only where current demand is non-zero (the
-- benchmark divides by it), the source actually used is known (D-18
-- supplies the lead time), and the demand slope rests on enough
-- quarters to classify direction (D-19).
-- Explicitly ordered. An unordered UNION ALL returns rows in whatever
-- order the planner produces them, which differs between runs and makes
-- the committed result non-reproducible.
SELECT
    population, positions, stock_value_gbp
FROM (
SELECT
    1                                                                    AS sort_order,
    'Stocked positions at 2025-12-28'                                    AS population,
    COUNT(*)                                                             AS positions,
    ROUND(SUM(stock_value_gbp), 0)                                       AS stock_value_gbp
FROM   vw_cover_versus_trend
UNION ALL
SELECT 2, 'With demand in the trailing 13 weeks',
       COUNT(*) FILTER (WHERE issued_units_13w > 0),
       ROUND(SUM(stock_value_gbp) FILTER (WHERE issued_units_13w > 0), 0)
FROM   vw_cover_versus_trend
UNION ALL
SELECT 3, 'With a known source actually used',
       COUNT(*) FILTER (WHERE last_source_lead_days IS NOT NULL),
       ROUND(SUM(stock_value_gbp) FILTER (WHERE last_source_lead_days IS NOT NULL), 0)
FROM   vw_cover_versus_trend
UNION ALL
SELECT 4, 'With six or more quarters of demand',
       COUNT(*) FILTER (WHERE quarters_observed >= 6),
       ROUND(SUM(stock_value_gbp) FILTER (WHERE quarters_observed >= 6), 0)
FROM   vw_cover_versus_trend
UNION ALL
SELECT 5, 'Assessable for alignment (all three)',
       COUNT(*) FILTER (WHERE issued_units_13w > 0
                          AND last_source_lead_days IS NOT NULL
                          AND quarters_observed >= 6),
       ROUND(SUM(stock_value_gbp) FILTER (WHERE issued_units_13w > 0
                          AND last_source_lead_days IS NOT NULL
                          AND quarters_observed >= 6), 0)
FROM   vw_cover_versus_trend
) AS population_ladder
ORDER  BY sort_order;


\echo '=== 2. The network working rule, calibrated on flat-demand lines ==='

DROP VIEW IF EXISTS vw_policy_alignment CASCADE;

CREATE VIEW vw_policy_alignment AS

WITH assessable AS (
    SELECT
        v.sku,
        v.category_code,
        v.category_name,
        v.warehouse_code,
        v.demand_direction,
        v.quarters_observed,
        v.slope_pct_of_mean_quarter,
        v.policy_age_months,
        v.set_by_buyer,
        v.reorder_point_units,
        v.reorder_quantity_units,
        v.quantity_on_hand,
        v.stock_value_gbp,
        v.cover_weeks,
        v.issued_units_13w,
        v.last_supplier_type,
        v.last_source_moq,
        v.last_source_lead_days,
        p.review_method,
        p.safety_stock_units,
        p.last_reviewed_date,
        v.issued_units_13w::numeric / 13                                 AS weekly_demand_units,
        v.last_source_lead_days::numeric / 7                             AS lead_time_weeks
    FROM       vw_cover_versus_trend   AS v
    INNER JOIN replenishment_policy    AS p
           ON  p.sku = v.sku AND p.warehouse_code = v.warehouse_code
    WHERE      v.issued_units_13w    > 0
      AND      v.last_source_lead_days IS NOT NULL
      AND      v.quarters_observed  >= 6
),

-- The rule the estate actually works to, read off the lines where
-- current demand is closest to the demand the settings were made for.
working_rule AS (
    SELECT
        PERCENTILE_CONT(0.5) WITHIN GROUP (
            ORDER BY reorder_point_units
                     / NULLIF(weekly_demand_units * lead_time_weeks, 0))
                                                                         AS reorder_point_multiple,
        PERCENTILE_CONT(0.5) WITHIN GROUP (
            ORDER BY reorder_quantity_units / NULLIF(weekly_demand_units, 0))
                                                                         AS reorder_quantity_weeks,
        COUNT(*)                                                         AS calibration_lines
    FROM   assessable
    WHERE  demand_direction = 'broadly flat'
),

-- Outcome, measured across the 2025 trading weeks rather than at the
-- closing snapshot alone, so a single quiet week cannot stand for a year.
outcome_2025 AS (
    SELECT
        m.sku,
        m.warehouse_code,
        COUNT(*)                                                         AS weeks_observed,
        SUM(m.days_at_zero_in_week)                                      AS days_at_zero,
        SUM(m.demand_units)                                              AS demand_units_2025,
        SUM(m.unmet_units)                                               AS unmet_units_2025,
        SUM(m.unmet_value_gbp)                                           AS unmet_value_2025_gbp,
        AVG(m.stock_value_gbp)                                           AS mean_stock_value_gbp
    FROM   mv_inventory_week AS m
    WHERE  m.week_ending_date BETWEEN DATE :'year_start' AND DATE :'snapshot_date'
    GROUP  BY m.sku, m.warehouse_code
)

SELECT
    a.*,
    r.reorder_point_multiple,
    r.reorder_quantity_weeks                                             AS rule_reorder_quantity_weeks,
    ROUND(a.reorder_point_units / NULLIF(a.weekly_demand_units, 0), 1)   AS reorder_point_weeks,
    ROUND(a.reorder_quantity_units / NULLIF(a.weekly_demand_units, 0), 1)
                                                                         AS reorder_quantity_weeks,
    -- What the network's own rule would set for this line at the demand
    -- it has now, in units.
    ROUND((r.reorder_point_multiple * a.weekly_demand_units * a.lead_time_weeks)::numeric, 0)
                                                                         AS rule_reorder_point_units,
    ROUND((a.reorder_point_units
           / NULLIF(r.reorder_point_multiple * a.weekly_demand_units * a.lead_time_weeks, 0))::numeric, 2)
                                                                         AS reorder_point_alignment_ratio,
    ROUND((a.reorder_quantity_units
           / NULLIF(r.reorder_quantity_weeks * a.weekly_demand_units, 0))::numeric, 2)
                                                                         AS reorder_quantity_alignment_ratio,
    o.weeks_observed,
    o.days_at_zero,
    ROUND(100.0 * o.days_at_zero / NULLIF(o.weeks_observed * 7, 0), 2)   AS days_at_zero_pct,
    o.demand_units_2025,
    o.unmet_units_2025,
    ROUND(o.unmet_value_2025_gbp, 2)                                     AS unmet_value_2025_gbp,
    ROUND(100.0 * o.unmet_units_2025 / NULLIF(o.demand_units_2025, 0), 2)
                                                                         AS unmet_units_pct,
    ROUND(o.mean_stock_value_gbp, 2)                                     AS mean_stock_value_gbp,
    CASE WHEN a.policy_age_months >  :stale_months THEN '2 — over 15 months'
         ELSE                                            '1 — within 15 months'
    END                                                                  AS review_recency,
    CASE WHEN a.policy_age_months <=  6 THEN '1 — under 6 months'
         WHEN a.policy_age_months <= 12 THEN '2 — 6 to 12 months'
         WHEN a.policy_age_months <= 18 THEN '3 — 12 to 18 months'
         ELSE                                '4 — over 18 months'
    END                                                                  AS policy_age_band,
    CASE WHEN a.reorder_point_units
              / NULLIF(r.reorder_point_multiple * a.weekly_demand_units * a.lead_time_weeks, 0) < 0.60
              THEN '1 — set thin against current demand'
         WHEN a.reorder_point_units
              / NULLIF(r.reorder_point_multiple * a.weekly_demand_units * a.lead_time_weeks, 0) > 1.60
              THEN '3 — set deep against current demand'
         ELSE      '2 — in line with the network rule'
    END                                                                  AS alignment_band
FROM       assessable  AS a
CROSS JOIN working_rule AS r
LEFT  JOIN outcome_2025 AS o ON o.sku = a.sku AND o.warehouse_code = a.warehouse_code;


-- The rule itself, printed so the benchmark is auditable rather than
-- buried in a CASE expression.
SELECT DISTINCT
    ROUND(reorder_point_multiple::numeric, 2)                            AS reorder_point_multiple_of_lead_time_demand,
    ROUND(rule_reorder_quantity_weeks::numeric, 2)                       AS reorder_quantity_weeks_of_demand,
    (SELECT COUNT(*) FROM vw_policy_alignment WHERE demand_direction = 'broadly flat')
                                                                         AS calibration_lines,
    (SELECT COUNT(*) FROM vw_policy_alignment)                           AS lines_assessed
FROM   vw_policy_alignment;


\echo '=== 3. Alignment against demand direction — is the rule detecting anything? ==='

-- Flat lines centre on 1.00 by construction; they are the calibration
-- set. Rising and falling lines are the test: if settings track demand,
-- their ratios should also sit near 1.
SELECT
    demand_direction,
    COUNT(*)                                                             AS lines,
    ROUND(AVG(reorder_point_weeks), 1)                                   AS mean_reorder_point_weeks,
    ROUND(AVG(lead_time_weeks)::numeric, 1)                              AS mean_lead_time_weeks,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY reorder_point_alignment_ratio)::numeric, 2)
                                                                         AS median_alignment_ratio,
    COUNT(*) FILTER (WHERE alignment_band = '1 — set thin against current demand')
                                                                         AS n_thin,
    COUNT(*) FILTER (WHERE alignment_band = '2 — in line with the network rule')
                                                                         AS n_in_line,
    COUNT(*) FILTER (WHERE alignment_band = '3 — set deep against current demand')
                                                                         AS n_deep,
    ROUND(AVG(policy_age_months), 1)                                     AS mean_policy_age_months,
    ROUND(AVG(cover_weeks), 1)                                           AS mean_cover_weeks
FROM   vw_policy_alignment
GROUP  BY demand_direction
ORDER  BY demand_direction;


\echo '=== 4. Does review recency carry any signal about alignment? ==='

-- The direct test. If a recent review means settings match current
-- demand, the share in line should rise as age falls.
SELECT
    policy_age_band,
    COUNT(*)                                                             AS lines,
    ROUND(AVG(policy_age_months), 1)                                     AS mean_age_months,
    ROUND(100.0 * COUNT(*) FILTER (WHERE alignment_band = '2 — in line with the network rule')
          / COUNT(*), 1)                                                 AS in_line_pct,
    ROUND(100.0 * COUNT(*) FILTER (WHERE alignment_band = '1 — set thin against current demand')
          / COUNT(*), 1)                                                 AS thin_pct,
    ROUND(100.0 * COUNT(*) FILTER (WHERE alignment_band = '3 — set deep against current demand')
          / COUNT(*), 1)                                                 AS deep_pct,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY reorder_point_alignment_ratio)::numeric, 2)
                                                                         AS median_alignment_ratio,
    ROUND(AVG(ABS(LN(GREATEST(reorder_point_alignment_ratio, 0.01))))::numeric, 3)
                                                                         AS mean_absolute_log_departure
FROM   vw_policy_alignment
GROUP  BY policy_age_band
ORDER  BY policy_age_band;


-- Same question as a continuous association, so the answer does not
-- depend on where the band boundaries were drawn.
SELECT
    'Policy age against absolute departure from the rule'                AS association,
    COUNT(*)                                                             AS lines,
    ROUND(CORR(policy_age_months,
               ABS(LN(GREATEST(reorder_point_alignment_ratio, 0.01))))::numeric, 3)
                                                                         AS correlation,
    ROUND(REGR_SLOPE(ABS(LN(GREATEST(reorder_point_alignment_ratio, 0.01))),
                     policy_age_months)::numeric, 5)                     AS slope_per_month,
    ROUND(REGR_R2(ABS(LN(GREATEST(reorder_point_alignment_ratio, 0.01))),
                  policy_age_months)::numeric, 4)                        AS r_squared
FROM   vw_policy_alignment
WHERE  reorder_point_alignment_ratio IS NOT NULL;


\echo '=== 5. The four-way grid: review recency crossed with alignment ==='

-- Age and alignment are defined independently, so this table is the
-- crossing the brief asks for rather than a restatement of one variable.
-- Cells under ten lines carry no interpretation and are marked.
SELECT
    review_recency,
    CASE WHEN alignment_band = '2 — in line with the network rule' THEN 'aligned'
         ELSE 'misaligned'
    END                                                                  AS alignment,
    COUNT(*)                                                             AS lines,
    CASE WHEN COUNT(*) < 10 THEN 'thin cell' ELSE '' END                 AS cell_note,
    ROUND(AVG(policy_age_months), 1)                                     AS mean_age_months,
    ROUND(SUM(stock_value_gbp), 0)                                       AS stock_value_gbp,
    ROUND(AVG(cover_weeks), 1)                                           AS mean_cover_weeks,
    ROUND(100.0 * SUM(unmet_units_2025) / NULLIF(SUM(demand_units_2025), 0), 2)
                                                                         AS unmet_units_pct,
    ROUND(100.0 * SUM(days_at_zero) / NULLIF(SUM(weeks_observed) * 7, 0), 2)
                                                                         AS days_at_zero_pct
FROM   vw_policy_alignment
GROUP  BY review_recency, alignment
ORDER  BY review_recency, alignment;


\echo '=== 6. Outcome by alignment band, with thin and deep kept apart ==='

-- Thin and deep are both misalignment but they fail in opposite
-- directions, and averaging them would cancel the effect out.
SELECT
    alignment_band,
    COUNT(*)                                                             AS lines,
    ROUND(SUM(stock_value_gbp), 0)                                       AS stock_value_gbp,
    ROUND(SUM(stock_value_gbp) * :holding_rate, 0)                       AS annual_holding_cost_gbp,
    ROUND(AVG(cover_weeks), 1)                                           AS mean_cover_weeks,
    ROUND(AVG(reorder_point_weeks), 1)                                   AS mean_reorder_point_weeks,
    ROUND(100.0 * SUM(unmet_units_2025) / NULLIF(SUM(demand_units_2025), 0), 2)
                                                                         AS unmet_units_pct,
    ROUND(SUM(unmet_value_2025_gbp), 0)                                  AS unmet_value_2025_gbp,
    ROUND(100.0 * SUM(days_at_zero) / NULLIF(SUM(weeks_observed) * 7, 0), 2)
                                                                         AS days_at_zero_pct,
    ROUND(AVG(policy_age_months), 1)                                     AS mean_policy_age_months
FROM   vw_policy_alignment
GROUP  BY alignment_band
ORDER  BY alignment_band;


\echo '=== 7. Category control — does the age signal survive it? ==='

-- Renewables carries both the youngest policies and the sharpest growth
-- in the estate, so a naive age comparison would be reading Renewables.
-- Within-category shares hold that constant.
SELECT
    category_code,
    category_name,
    COUNT(*)                                                             AS lines,
    ROUND(AVG(policy_age_months), 1)                                     AS mean_age_months,
    ROUND(AVG(slope_pct_of_mean_quarter), 1)                             AS mean_demand_slope_pct,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY reorder_point_alignment_ratio)::numeric, 2)
                                                                         AS median_alignment_ratio,
    COUNT(*) FILTER (WHERE review_recency = '1 — within 15 months')      AS n_recent,
    COUNT(*) FILTER (WHERE review_recency = '2 — over 15 months')        AS n_old,
    ROUND(100.0 * COUNT(*) FILTER (WHERE review_recency = '1 — within 15 months'
                               AND alignment_band = '2 — in line with the network rule')
          / NULLIF(COUNT(*) FILTER (WHERE review_recency = '1 — within 15 months'), 0), 1)
                                                                         AS recent_in_line_pct,
    ROUND(100.0 * COUNT(*) FILTER (WHERE review_recency = '2 — over 15 months'
                               AND alignment_band = '2 — in line with the network rule')
          / NULLIF(COUNT(*) FILTER (WHERE review_recency = '2 — over 15 months'), 0), 1)
                                                                         AS old_in_line_pct
FROM   vw_policy_alignment
GROUP  BY category_code, category_name
ORDER  BY mean_demand_slope_pct DESC;


\echo '=== 8. Review method, which is recorded and age is not a proxy for ==='

SELECT
    review_method,
    COUNT(*)                                                             AS lines,
    ROUND(AVG(policy_age_months), 1)                                     AS mean_age_months,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY reorder_point_alignment_ratio)::numeric, 2)
                                                                         AS median_alignment_ratio,
    ROUND(100.0 * COUNT(*) FILTER (WHERE alignment_band = '2 — in line with the network rule')
          / COUNT(*), 1)                                                 AS in_line_pct,
    ROUND(AVG(cover_weeks), 1)                                           AS mean_cover_weeks,
    ROUND(100.0 * SUM(unmet_units_2025) / NULLIF(SUM(demand_units_2025), 0), 2)
                                                                         AS unmet_units_pct,
    ROUND(SUM(stock_value_gbp), 0)                                       AS stock_value_gbp
FROM   vw_policy_alignment
GROUP  BY review_method
ORDER  BY lines DESC;


\echo '=== 9. Reproduction check — Renewables, against files 08 and 05 ==='

-- File 08 reported Renewables at 7.4 weeks cover against 21.7 elsewhere
-- and a reorder point of 4.6 weeks against 11.1. Those figures were
-- measured on a different population; this file restricts to assessable
-- lines, so the comparison is like for like only within its own row.
SELECT
    CASE WHEN category_code = 'RENW' THEN 'Renewables' ELSE 'All other categories' END
                                                                         AS grouping,
    COUNT(*)                                                             AS lines,
    ROUND(AVG(policy_age_months), 1)                                     AS mean_age_months,
    ROUND(AVG(reorder_point_weeks), 1)                                   AS mean_reorder_point_weeks,
    ROUND(AVG(cover_weeks), 1)                                           AS mean_cover_weeks,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY reorder_point_alignment_ratio)::numeric, 2)
                                                                         AS median_alignment_ratio,
    ROUND(100.0 * COUNT(*) FILTER (WHERE alignment_band = '1 — set thin against current demand')
          / COUNT(*), 1)                                                 AS thin_pct,
    ROUND(100.0 * SUM(days_at_zero) / NULLIF(SUM(weeks_observed) * 7, 0), 2)
                                                                         AS days_at_zero_pct,
    ROUND(100.0 * SUM(unmet_units_2025) / NULLIF(SUM(demand_units_2025), 0), 2)
                                                                         AS unmet_units_pct
FROM   vw_policy_alignment
GROUP  BY grouping
ORDER  BY grouping;


\echo '=== 10. Reproduction check — high-cover positions against file 05 ==='

-- File 05 found 103 positions over 26 weeks cover worth £398,821, of
-- which 85.4% were policy-authorised. This file asks the narrower
-- question of how many of those settings are deep against CURRENT
-- demand, which is not the same test and need not give the same share.
SELECT
    CASE WHEN cover_weeks > 26 THEN 'Cover over 6 months' ELSE 'Cover 6 months or under' END
                                                                         AS cover_group,
    COUNT(*)                                                             AS lines,
    ROUND(SUM(stock_value_gbp), 0)                                       AS stock_value_gbp,
    COUNT(*) FILTER (WHERE alignment_band = '3 — set deep against current demand')
                                                                         AS n_set_deep,
    ROUND(100.0 * COUNT(*) FILTER (WHERE alignment_band = '3 — set deep against current demand')
          / COUNT(*), 1)                                                 AS set_deep_pct,
    ROUND(SUM(stock_value_gbp) FILTER (WHERE alignment_band = '3 — set deep against current demand'), 0)
                                                                         AS stock_where_set_deep_gbp,
    ROUND(AVG(policy_age_months), 1)                                     AS mean_policy_age_months,
    COUNT(*) FILTER (WHERE demand_direction = 'falling')                 AS n_falling_demand
FROM   vw_policy_alignment
GROUP  BY cover_group
ORDER  BY cover_group;


\echo '=== 11. Value at stake, split by which way the setting departs ==='

-- Deep settings tie up capital; thin settings cost service. The two are
-- reported in their own units and never netted, because a pound of
-- holding cost and a pound of lost margin are not the same pound.
WITH departure AS (
    SELECT
        alignment_band,
        demand_direction,
        stock_value_gbp,
        unmet_value_2025_gbp,
        cover_weeks,
        -- Stock above what the network rule would authorise for this
        -- line at its current demand, valued at the position's own
        -- carrying value. Bounded below at zero: a line under the rule
        -- does not create negative capital.
        GREATEST(quantity_on_hand - (rule_reorder_point_units + reorder_quantity_units), 0)
        * NULLIF(stock_value_gbp, 0) / NULLIF(quantity_on_hand, 0)       AS stock_above_rule_gbp
    FROM   vw_policy_alignment
)

SELECT
    alignment_band,
    demand_direction,
    COUNT(*)                                                             AS lines,
    ROUND(SUM(stock_value_gbp), 0)                                       AS stock_value_gbp,
    ROUND(SUM(stock_above_rule_gbp), 0)                                  AS stock_above_rule_gbp,
    ROUND(SUM(stock_above_rule_gbp) * :holding_rate, 0)                  AS holding_cost_above_rule_gbp,
    ROUND(SUM(unmet_value_2025_gbp), 0)                                  AS unmet_value_2025_gbp
FROM   departure
GROUP  BY GROUPING SETS ((alignment_band, demand_direction), (alignment_band), ())
ORDER  BY alignment_band NULLS LAST, demand_direction NULLS LAST;


\echo '=== 12. The twenty largest departures by value ==='

SELECT
    sku,
    category_code,
    warehouse_code,
    demand_direction,
    slope_pct_of_mean_quarter,
    reorder_point_units,
    rule_reorder_point_units,
    reorder_point_alignment_ratio,
    reorder_point_weeks,
    cover_weeks,
    ROUND(stock_value_gbp, 0)                                            AS stock_value_gbp,
    policy_age_months,
    review_method,
    last_supplier_type,
    unmet_units_pct
FROM   vw_policy_alignment
WHERE  alignment_band <> '2 — in line with the network rule'
ORDER  BY stock_value_gbp DESC
LIMIT  20;
