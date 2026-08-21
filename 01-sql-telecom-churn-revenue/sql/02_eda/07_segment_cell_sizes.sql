/* ============================================================
   File   : 02_eda/07_segment_cell_sizes.sql
   Stage  : PREPARE — pre-registration verification
   Purpose: Confirm every pre-registered segment cell clears the C-6 minimum
            size rules BEFORE any analysis is run.
              n >= 100  reportable
              30-99     caveat required, n stated
              < 30      not reported as a rate; collapse and record
   NOTE   : cell SIZES only. No churn rate or revenue figure is produced here —
            that would be analysis.
   ============================================================ */

/* P1 — Value Tier x Contract (9 cells), the divergence-index segmentation */
SELECT 'P1' AS scheme, value_tier, contract_type, count(*) AS n,
       CASE WHEN count(*) >= 100 THEN 'reportable'
            WHEN count(*) >= 30  THEN 'caveat_required'
            ELSE 'below_threshold' END AS cell_size_flag
FROM   analytics.vw_customer_analytical_base
GROUP  BY value_tier, contract_type
ORDER  BY CASE value_tier WHEN 'High' THEN 1 WHEN 'Mid' THEN 2 ELSE 3 END, contract_type;

/* P2 — Revenue decile (10 cells) */
SELECT 'P2' AS scheme, revenue_decile, count(*) AS n,
       to_char(min(monthly_charge),'FM990.00') AS charge_min,
       to_char(max(monthly_charge),'FM990.00') AS charge_max,
       CASE WHEN count(*) >= 100 THEN 'reportable'
            WHEN count(*) >= 30  THEN 'caveat_required'
            ELSE 'below_threshold' END AS cell_size_flag
FROM   analytics.vw_customer_analytical_base
GROUP  BY revenue_decile ORDER BY revenue_decile;

/* Driver lenses L1-L7, cell sizes WITHIN the High value tier — where AQ-05 runs */
WITH hv AS (SELECT * FROM analytics.vw_customer_analytical_base WHERE value_tier = 'High')
SELECT 'L1 contract' AS lens, contract_type::text AS segment, count(*) AS n_high_tier,
       CASE WHEN count(*)>=100 THEN 'reportable' WHEN count(*)>=30 THEN 'caveat_required'
            ELSE 'below_threshold' END AS cell_size_flag
FROM hv GROUP BY contract_type
UNION ALL
SELECT 'L2 tenure band', tenure_band, count(*),
       CASE WHEN count(*)>=100 THEN 'reportable' WHEN count(*)>=30 THEN 'caveat_required'
            ELSE 'below_threshold' END FROM hv GROUP BY tenure_band
UNION ALL
SELECT 'L3 payment method', payment_method, count(*),
       CASE WHEN count(*)>=100 THEN 'reportable' WHEN count(*)>=30 THEN 'caveat_required'
            ELSE 'below_threshold' END FROM hv GROUP BY payment_method
UNION ALL
SELECT 'L4 internet type', internet_type, count(*),
       CASE WHEN count(*)>=100 THEN 'reportable' WHEN count(*)>=30 THEN 'caveat_required'
            ELSE 'below_threshold' END FROM hv GROUP BY internet_type
UNION ALL
SELECT 'L5 service intensity', service_intensity_band, count(*),
       CASE WHEN count(*)>=100 THEN 'reportable' WHEN count(*)>=30 THEN 'caveat_required'
            ELSE 'below_threshold' END FROM hv GROUP BY service_intensity_band
UNION ALL
SELECT 'L6 offer', offer, count(*),
       CASE WHEN count(*)>=100 THEN 'reportable' WHEN count(*)>=30 THEN 'caveat_required'
            ELSE 'below_threshold' END FROM hv GROUP BY offer
UNION ALL
SELECT 'L7 referral', CASE WHEN has_referred THEN 'Has referred' ELSE 'Has not referred' END,
       count(*), CASE WHEN count(*)>=100 THEN 'reportable' WHEN count(*)>=30 THEN 'caveat_required'
            ELSE 'below_threshold' END FROM hv GROUP BY has_referred
ORDER BY 1, 2;

/* Same lenses split by cohort_class — driver analysis runs separately per cohort (C-3). */
SELECT cohort_class, value_tier, count(*) AS n,
       CASE WHEN count(*)>=100 THEN 'reportable' WHEN count(*)>=30 THEN 'caveat_required'
            ELSE 'below_threshold' END AS cell_size_flag
FROM   analytics.vw_customer_analytical_base
GROUP  BY cohort_class, value_tier
ORDER  BY cohort_class, CASE value_tier WHEN 'High' THEN 1 WHEN 'Mid' THEN 2 ELSE 3 END;
