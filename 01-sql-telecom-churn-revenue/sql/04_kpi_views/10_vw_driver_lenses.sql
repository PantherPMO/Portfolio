/* ============================================================
   File    : 04_kpi_views/10_vw_driver_lenses.sql
   Stage   : ANALYSE
   Purpose : AQ-05 and AQ-06. The seven approved driver lenses L1-L7.
   Grain   : one row per (scope_cohort, scope_tier, lens_id, segment_value).

   *** ALL SEVEN LENSES ARE ALWAYS EMITTED (C-6 commitment 3) ***
   Including any that show no effect. A uniform output shape across all seven
   makes selective reporting visible rather than easy. A lens is never dropped
   because its result is uninteresting — a null result is a finding.

   DESIGN — why one view rather than seven:
   The seven lenses each partition the SAME population in a different way. A
   single unpivoted attribute relation, crossed with a scope list, gives one
   uniform result set and makes the scope comparison (AQ-06) a filter rather
   than a join between differently-shaped tables.

   DENOMINATOR: all customers in that lens segment WITHIN THE SAME SCOPE.
   Numerator and denominator are always drawn from the same population.

   CHURN INDEX: segment churn rate / scope churn rate. The scope rate is computed
   by a window partitioned by (scope_cohort, scope_tier, lens_id). Because each
   lens partitions the whole scope exactly once, summing over a lens partition
   reconstitutes the entire scope population — so this yields the true scope rate
   regardless of how many segments the lens has.

   FAN-OUT: reads only the base view (one row per customer). The LATERAL VALUES
   expansion multiplies rows by 7 BY DESIGN, one per lens — that is an unpivot,
   not a join fan-out. Check A-VAL-11 asserts each lens partitions its scope
   exactly, which is what proves no customer is double-counted within a lens.

   SERVICE INTENSITY (L5): uses service_intensity_band from the base view, which
   counts only the eight non-Core services. PHONE, MULTI_LINE and INTERNET are
   Core and are excluded from the count, per the locked C-6 definition.

   EXCLUSIONS: no restricted or prohibited field appears in any lens.
   ============================================================ */

DROP VIEW IF EXISTS analytics.vw_driver_lenses CASCADE;

CREATE VIEW analytics.vw_driver_lenses AS
WITH attr AS (
    /* Unpivot: one row per customer per lens. */
    SELECT b.customer_id,
           b.is_churned,
           b.cohort_class,
           b.value_tier,
           b.annual_recurring_revenue,
           b.annual_long_distance_revenue,
           v.lens_id,
           v.lens_name,
           v.segment_value
    FROM   analytics.vw_customer_analytical_base AS b
    CROSS  JOIN LATERAL (VALUES
              ('L1', 'Contract type',      b.contract_type),
              ('L2', 'Tenure band',        b.tenure_band),
              ('L3', 'Payment method',     b.payment_method),
              ('L4', 'Internet type',      b.internet_type),
              ('L5', 'Service intensity',  b.service_intensity_band),
              ('L6', 'Offer held',         b.offer),
              ('L7', 'Referral behaviour',
                     CASE WHEN b.has_referred THEN 'Has referred'
                          ELSE 'Has not referred' END)
           ) AS v(lens_id, lens_name, segment_value)
),

scopes AS (
    SELECT * FROM (VALUES
        ('ALL',                   'ALL',  1),
        ('ALL',                   'High', 2),
        ('opening_base',          'ALL',  3),
        ('opening_base',          'High', 4),
        ('in_period_acquisition', 'ALL',  5),
        ('in_period_acquisition', 'High', 6)
    ) AS s(scope_cohort, scope_tier, scope_order)
),

scoped AS (
    SELECT s.scope_cohort, s.scope_tier, s.scope_order, a.*
    FROM   scopes AS s
    JOIN   attr   AS a
      ON  (s.scope_cohort = 'ALL' OR a.cohort_class = s.scope_cohort)
     AND  (s.scope_tier   = 'ALL' OR a.value_tier   = s.scope_tier)
)

SELECT scope_cohort,
       scope_tier,
       lens_id,
       lens_name,
       segment_value,
       count(*)                                                  AS n,
       count(*) FILTER (WHERE is_churned)                        AS churned,
       round(100.0 * count(*) FILTER (WHERE is_churned)
             / NULLIF(count(*), 0), 2)                           AS churn_rate_pct,

       /* Scope churn rate — window over the lens partition, which reconstitutes
          the whole scope population. */
       round(100.0 * SUM(count(*) FILTER (WHERE is_churned))
                     OVER (PARTITION BY scope_cohort, scope_tier, lens_id)
             / NULLIF(SUM(count(*)) OVER (PARTITION BY scope_cohort, scope_tier, lens_id), 0), 2)
                                                                 AS scope_churn_rate_pct,

       round((100.0 * count(*) FILTER (WHERE is_churned) / NULLIF(count(*), 0))
             / NULLIF(100.0 * SUM(count(*) FILTER (WHERE is_churned))
                              OVER (PARTITION BY scope_cohort, scope_tier, lens_id)
                      / NULLIF(SUM(count(*)) OVER (PARTITION BY scope_cohort, scope_tier, lens_id), 0), 0), 2)
                                                                 AS churn_index_vs_scope,

       round(sum(annual_recurring_revenue) FILTER (WHERE is_churned), 2)
                                                                 AS arr_at_risk_currency_units,
       round(sum(annual_long_distance_revenue) FILTER (WHERE is_churned), 2)
                                                                 AS long_distance_at_risk_currency_units,
       round(sum(annual_recurring_revenue), 2)                   AS arr_total_currency_units,

       /* Share of the scope's population — makes a small cell visible even when
          its rate looks dramatic. */
       round(100.0 * count(*)
             / NULLIF(SUM(count(*)) OVER (PARTITION BY scope_cohort, scope_tier, lens_id), 0), 2)
                                                                 AS pct_of_scope_population,

       CASE WHEN count(*) >= 100 THEN 'reportable'
            WHEN count(*) >= 30  THEN 'caveat_required'
            ELSE 'below_threshold' END                           AS cell_size_flag,
       scope_order
FROM   scoped
GROUP  BY scope_cohort, scope_tier, lens_id, lens_name, segment_value, scope_order
ORDER  BY scope_order, lens_id, segment_value;

COMMENT ON VIEW analytics.vw_driver_lenses IS
  'AQ-05 / AQ-06. All seven approved lenses L1-L7, always emitted including null '
  'results (C-6). Six scopes: cohort {ALL, opening_base, in_period_acquisition} '
  'x tier {ALL, High}. Numerator and denominator always from the same scope. '
  'L5 counts only the eight non-Core services. Currency UNKNOWN.';

/* Coverage summary — confirms all seven lenses are present in every scope. */
SELECT scope_cohort, scope_tier,
       count(DISTINCT lens_id) AS lenses_present,
       count(*)                AS segment_rows,
       CASE WHEN count(DISTINCT lens_id) = 7 THEN 'PASS' ELSE 'FAIL' END AS all_seven_present
FROM   analytics.vw_driver_lenses
GROUP  BY scope_cohort, scope_tier, scope_order
ORDER  BY scope_order;
