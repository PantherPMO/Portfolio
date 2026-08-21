/* ============================================================
   Project : 01 — Telecommunications Revenue Retention
   File    : 01_cleaning/09_create_analytical_base_view.sql
   Stage   : PREPARE
   Purpose : analytics.vw_customer_analytical_base — THE single analytical grain.
             One row per customer. Every analysis query selects from this view.
   Revised : 2026-08-19 — REPRODUCIBILITY FIX, see finding V-11.

   *** V-11 CORRECTION ***
   The original used NTILE(10) OVER (ORDER BY monthly_charge) with no tie-break.
   monthly_charge has many repeated values, and PostgreSQL does not guarantee a
   stable assignment among tied rows — so re-running could move customers across
   the decile 7/8 boundary, which is the Mid/High value-tier boundary, which
   feeds P1 and every driver lens. Segment membership that can change between
   runs is not reproducible.

   ORDER BY monthly_charge, customer_id makes the assignment deterministic.
   customer_id is unique, so the ordering is total and the result is identical
   on every execution. The DEFINITION is unchanged: still NTILE(10) over
   monthly_charge across the whole base, exactly as locked at C-6.

   The window is also now computed ONCE in a CTE rather than twice inline,
   so revenue_decile and value_tier cannot diverge.

   NOTE ON FILE PLACEMENT: the PREPARE specification listed this view under
   04_kpi_views/ as an ANALYSE artefact. That was an inconsistency — validation
   checks VAL-01..VAL-08 depend on it and those are a PREPARE gate. The view is
   infrastructure: it derives approved definitions and produces no business
   number of its own. Flagged rather than changed silently.

   EVERY derived attribute implements a LOCKED decision:
     annual_recurring_revenue  C-2  monthly_charge x 12, long distance SEPARATE
     cohort_class              C-3  opening_base = tenure >= 4
     tenure_band               C-6  fixed cut points
     revenue_decile            C-6  NTILE(10) over the whole base
     value_tier                C-6  deciles 8-10 / 4-7 / 1-3
     addon_service_count       C-6  the locked 8 non-Core services
     service_intensity_band    C-6  fixed cut points
   None may be changed on the basis of a result.
   ============================================================ */

DROP VIEW IF EXISTS analytics.vw_customer_analytical_base CASCADE;

CREATE VIEW analytics.vw_customer_analytical_base AS
WITH addon_counts AS (
    -- Bridge aggregated to customer grain HERE, so no downstream query
    -- touches the bridge and no downstream query can fan out. (VAL-02)
    SELECT b.customer_id,
           count(*) FILTER (WHERE b.is_subscribed AND d.service_group <> 'Core')
               AS addon_service_count
    FROM   core.bridge_customer_service AS b
    JOIN   core.dim_service             AS d ON d.service_code = b.service_code
    GROUP  BY b.customer_id
),

base AS (
    SELECT c.customer_id,
           f.is_churned,
           f.tenure_months,
           f.quarter,
           f.monthly_charge,
           f.avg_monthly_long_distance,
           f.avg_monthly_gb,
           f.total_charges,
           f.customer_status,
           k.contract_type,
           k.payment_method,
           k.is_paperless_billing,
           k.offer,
           k.internet_type,
           k.has_referred,
           k.referral_count,
           c.is_married,
           c.has_dependents,
           c.dependent_count,
           l.city,
           l.zip_code,
           p.population,
           a.addon_service_count
    FROM       core.dim_customer          AS c
    INNER JOIN core.fact_customer_status  AS f ON f.customer_id = c.customer_id
    INNER JOIN core.dim_contract          AS k ON k.customer_id = c.customer_id
    INNER JOIN core.dim_location          AS l ON l.customer_id = c.customer_id
    INNER JOIN core.dim_population        AS p ON p.zip_code    = l.zip_code
    INNER JOIN addon_counts               AS a ON a.customer_id = c.customer_id
    -- All customer joins verified 1:1 with zero orphans (Stage 2).
    -- dim_population is N:1 in this direction: each customer gains one row.
),

deciled AS (
    -- V-11: deterministic tie-break. customer_id is unique, so the ordering is
    -- total and decile membership is identical on every execution.
    SELECT b.*,
           NTILE(10) OVER (ORDER BY b.monthly_charge, b.customer_id)::smallint
               AS revenue_decile
    FROM   base AS b
)

SELECT d.*,

       /* --- C-2: revenue basis ------------------------------------------ */
       (d.monthly_charge * 12)::numeric(14,4)             AS annual_recurring_revenue,
       (d.avg_monthly_long_distance * 12)::numeric(14,4)  AS annual_long_distance_revenue,

       /* --- C-3: cohort ------------------------------------------------- */
       CASE WHEN d.tenure_months >= 4 THEN 'opening_base'
            ELSE 'in_period_acquisition' END              AS cohort_class,

       /* --- C-6: tenure bands ------------------------------------------- */
       CASE WHEN d.tenure_months <= 3  THEN '1. In-period acquisition (1-3m)'
            WHEN d.tenure_months <= 12 THEN '2. First year (4-12m)'
            WHEN d.tenure_months <= 24 THEN '3. Second year (13-24m)'
            WHEN d.tenure_months <= 48 THEN '4. Established (25-48m)'
            ELSE                            '5. Long tenure (49-72m)'
       END                                                AS tenure_band,

       /* --- C-6: value tier, derived from the single decile calculation -- */
       CASE WHEN d.revenue_decile >= 8 THEN 'High'
            WHEN d.revenue_decile >= 4 THEN 'Mid'
            ELSE 'Low' END                                AS value_tier,

       /* --- C-6: service intensity -------------------------------------- */
       CASE WHEN d.addon_service_count = 0  THEN '1. None (0)'
            WHEN d.addon_service_count <= 2 THEN '2. Light (1-2)'
            WHEN d.addon_service_count <= 4 THEN '3. Moderate (3-4)'
            ELSE                                 '4. Deep (5-8)'
       END                                                AS service_intensity_band

FROM deciled AS d;

COMMENT ON VIEW analytics.vw_customer_analytical_base IS
  'THE analytical grain: one row per customer, 7,043 expected. Every derived '
  'attribute implements a decision locked at C-2, C-3 or C-6 and must not be '
  'altered on the basis of a result. revenue_decile uses a deterministic '
  'tie-break (monthly_charge, customer_id) per finding V-11 so segment '
  'membership is identical on every run. Monetary values are in UNKNOWN '
  'currency units (check P-15 found no evidence) — never label as GBP. Excluded '
  'fields and restricted protected characteristics are absent by design.';

SELECT 'CLEAN-20' AS check_id, 'analytical base rows' AS description,
       7043 AS expected, count(*) AS actual,
       CASE WHEN count(*) = 7043 THEN 'PASS' ELSE 'FAIL' END AS status
FROM   analytics.vw_customer_analytical_base
UNION ALL
SELECT 'CLEAN-21',
       'V-11 INFO: monthly_charge values spanning >1 decile. NTILE splits ties '
       'by design; the tie-break makes that split DETERMINISTIC, not absent.',
       NULL,
       (SELECT count(*) FROM (
            SELECT monthly_charge FROM analytics.vw_customer_analytical_base
            GROUP BY monthly_charge HAVING count(DISTINCT revenue_decile) > 1) q),
       'INFO';
