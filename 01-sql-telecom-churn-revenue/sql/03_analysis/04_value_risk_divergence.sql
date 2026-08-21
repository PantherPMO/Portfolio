/* ============================================================
   File       : 03_analysis/04_value_risk_divergence.sql
   Stage      : ANALYSE
   Question   : AQ-04 / BQ-04 — Where would a churn-rate-led prioritisation
                diverge from a revenue-led one?
   Finding ID : F-04
   Output     : analysis/query_results/analyse_04_divergence.txt
   Type       : PRIORITISATION — the project's central analytical construct

   *** A-07 LOCKED 19 August 2026 (D-21) — decided BEFORE results were seen ***
   PRIMARY     : opening cohort. Both components of the index come from the same
                 population, so it compares like with like.
   Each output block below carries population_scope and result_designation as
   EXPLICIT COLUMNS (labelling repair, 19 Aug 2026). psql \echo writes to stdout,
   not to the -o file, so the section headers never reached the committed
   evidence and the two scopes were indistinguishable in the artefact.

   SENSITIVITY : all customers. Clearly labelled, retained to show whether
                 including in-period acquisitions materially changes segment
                 rankings, prioritisation, the index, or the interpretation of
                 where churn risk and revenue risk diverge. It does NOT replace
                 the primary result.

   *** REPORTING RULE (C-6) *** The index is ORDINAL. It appears here alongside
   churn_rate_pct, arr_at_risk and n, and must never be quoted alone.

   Interpretation of the sign:
     POSITIVE — ranks worse on churn rate than on revenue at risk; a churn-led
                prioritisation would OVER-prioritise this cell
     NEGATIVE — ranks worse on revenue at risk than on churn rate; a churn-led
                prioritisation would UNDER-prioritise this cell
     ZERO     — the two prioritisations agree
   ============================================================ */

\echo '=== F-04a  P1 segmentation (Value Tier x Contract) — OPENING COHORT :: PRIMARY ==='
SELECT population_scope,
       'PRIMARY RESULT - Opening cohort'::text AS result_designation,
       value_tier, contract_type, n, churned, churn_rate_pct,
       arr_at_risk_currency_units, long_distance_at_risk_currency_units,
       arr_total_currency_units, cell_size_flag
FROM   analytics.vw_segment_p1_value_contract
WHERE  population_scope = 'opening_base'
ORDER  BY CASE value_tier WHEN 'High' THEN 1 WHEN 'Mid' THEN 2 ELSE 3 END, contract_type;

\echo ''
\echo '=== F-04b  DIVERGENCE INDEX — OPENING COHORT :: PRIMARY RESULT (A-07 locked) ==='
SELECT population_scope,
       'PRIMARY RESULT - Opening cohort'::text AS result_designation,
       segment_label, n, churn_rate_pct, churn_index_vs_scope,
       arr_at_risk_currency_units, share_of_scope_arr_at_risk_pct,
       rank_by_churn_rate, rank_by_arr_at_risk, divergence_index, cell_size_flag
FROM   analytics.vw_segment_divergence
WHERE  population_scope = 'opening_base'
ORDER  BY rank_by_arr_at_risk;

\echo ''
\echo '=== F-04c  DIVERGENCE INDEX — ALL CUSTOMERS :: SENSITIVITY ANALYSIS ONLY ==='
SELECT population_scope,
       'SENSITIVITY ANALYSIS ONLY - All customers'::text AS result_designation,
       segment_label, n, churn_rate_pct, churn_index_vs_scope,
       arr_at_risk_currency_units, share_of_scope_arr_at_risk_pct,
       rank_by_churn_rate, rank_by_arr_at_risk, divergence_index, cell_size_flag
FROM   analytics.vw_segment_divergence
WHERE  population_scope = 'all_customers'
ORDER  BY rank_by_arr_at_risk;

\echo ''
\echo '=== F-04d  SENSITIVITY TEST — does including in-period acquisitions change the ranking? ==='
SELECT 'SENSITIVITY TEST - primary (opening cohort) vs all customers'::text
              AS result_designation,
       ob.segment_label,
       ob.divergence_index AS divergence_opening_base,
       ac.divergence_index AS divergence_all_customers,
       ob.divergence_index - ac.divergence_index AS scope_sensitivity
FROM       analytics.vw_segment_divergence AS ob
INNER JOIN analytics.vw_segment_divergence AS ac
        ON ac.segment_label = ob.segment_label
       AND ac.population_scope = 'all_customers'
WHERE  ob.population_scope = 'opening_base'
ORDER  BY abs(ob.divergence_index - ac.divergence_index) DESC, ob.segment_label;
