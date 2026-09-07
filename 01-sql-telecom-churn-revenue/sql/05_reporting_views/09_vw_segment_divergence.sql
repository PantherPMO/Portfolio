/* ============================================================
   File    : 04_kpi_views/09_vw_segment_divergence.sql
   Stage   : ANALYSE
   Purpose : AQ-04. The value-risk divergence index — the project's central
             analytical construct.
   Grain   : one row per (population_scope, P1 cell). 9 cells per scope.

   THE INDEX:
     RANK() OVER (ORDER BY churn_rate DESC)  -  RANK() OVER (ORDER BY arr_at_risk DESC)

     Positive = ranks WORSE on churn rate than on revenue at risk
                (a churn-led prioritisation would over-prioritise this cell)
     Negative = ranks WORSE on revenue at risk than on churn rate
                (a churn-led prioritisation would UNDER-prioritise this cell)
     Zero     = the two prioritisations agree for this cell

   *** REPORTING RULE (C-6): the index is ORDINAL. ***
   It is emitted alongside both underlying magnitudes and n, and must NEVER be
   presented alone. A divergence of 3 ranks means nothing without knowing whether
   the underlying gap is trivial or large.

   *** A-07 — LOCKED 19 August 2026 ***
   PRIMARY  : population_scope = 'opening_base'. BOTH components of the index —
              churn rate AND revenue at risk — are computed from the opening
              cohort, so the index compares like with like. It does not combine a
              symmetric churn-rate population with an all-customer revenue
              population.
   SENSITIVITY: population_scope = 'all_customers'. Retained and clearly
              labelled. It does NOT replace the primary result. Its purpose is to
              show whether including in-period acquisitions materially changes
              segment rankings, prioritisation, the index, or where churn risk
              and revenue risk diverge.
   Customers who joined and churned within the quarter remain included in the
   separate early-life / onboarding analysis (vw_kpi_early_life_churn).
   This decision is locked and must not change after results are seen. D-21.

   HONEST LIMITATION: the data is fictional. Any divergence found is a property
   of IBM's generation logic. This demonstrates that the METHOD surfaces
   misallocation; it does not establish that misallocation exists in any real
   operator.
   ============================================================ */

DROP VIEW IF EXISTS analytics.vw_segment_divergence CASCADE;

CREATE VIEW analytics.vw_segment_divergence AS
SELECT population_scope,
       value_tier,
       contract_type,
       value_tier || ' / ' || contract_type                      AS segment_label,
       n,
       churned,
       churn_rate_pct,
       arr_at_risk_currency_units,
       long_distance_at_risk_currency_units,

       RANK() OVER (PARTITION BY population_scope
                    ORDER BY churn_rate_pct DESC)                AS rank_by_churn_rate,
       RANK() OVER (PARTITION BY population_scope
                    ORDER BY arr_at_risk_currency_units DESC)    AS rank_by_arr_at_risk,

       RANK() OVER (PARTITION BY population_scope ORDER BY churn_rate_pct DESC)
     - RANK() OVER (PARTITION BY population_scope ORDER BY arr_at_risk_currency_units DESC)
                                                                 AS divergence_index,

       /* Magnitudes, so the ordinal index is never read in isolation. */
       round(100.0 * arr_at_risk_currency_units
             / NULLIF(SUM(arr_at_risk_currency_units) OVER (PARTITION BY population_scope), 0), 2)
                                                                 AS share_of_scope_arr_at_risk_pct,
       round(churn_rate_pct / NULLIF(scope_churn_rate_pct, 0), 2) AS churn_index_vs_scope,
       scope_churn_rate_pct,
       cell_size_flag,
       scope_order
FROM   analytics.vw_segment_p1_value_contract
ORDER  BY scope_order,
          RANK() OVER (PARTITION BY population_scope ORDER BY arr_at_risk_currency_units DESC);

COMMENT ON VIEW analytics.vw_segment_divergence IS
  'AQ-04. Ordinal index — MUST be reported alongside churn_rate_pct, '
  'arr_at_risk and n, never alone (C-6). A-07 LOCKED: population_scope '
  '''opening_base'' is PRIMARY (both components from the same population); '
  '''all_customers'' is a labelled SENSITIVITY analysis and does not replace it. '
  'Data is fictional: any divergence is a property of the generation logic, not '
  'evidence about a real operator.';

SELECT * FROM analytics.vw_segment_divergence;
