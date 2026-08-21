# ANALYSE Execution Plan — Project 01

## Telecommunications Revenue Retention: Prioritising Retention Investment by Revenue at Risk

**Stage:** 5 — ANALYSE (plan)
**Status:** ✅ **PLAN APPROVED · A-07 LOCKED — scripts written, not yet executed. No findings generated.**
**Prepared:** 19 August 2026

> **The methodology is locked.** C-1 to C-6 are immutable. Nothing in this plan reinterprets an approved definition, segment, cut point or KPI. Where the approved specification is genuinely under-determined, it is **flagged as an open item for your decision** rather than resolved silently — see §6.

---

## 1. PREPARE Verification — Independently Confirmed

Before planning, I re-read the re-run outputs directly from your `analysis/query_results/` folder rather than relying on the summary. Confirmed:

| Check | Expected | Actual | Status |
|---|---|---|---|
| CLEAN-10 `offer = 'No offer'` | 3,877 | 3,877 | ✅ PASS |
| CLEAN-11 `internet_type = 'No internet'` | 1,526 | 1,526 | ✅ PASS |
| CLEAN-10b residual literal `'None'` | 0 | 0 | ✅ PASS |
| CLEAN-20 analytical base rows | 7,043 | 7,043 | ✅ PASS |
| CLEAN-21 charge values spanning a decile boundary | — | 5 | ℹ️ INFO |
| REC-13 `monthly_charge` agreement | 0 disagreements | 0 | ✅ PASS |
| REC-14 `churn_value` agreement | 0 disagreements | 0 | ✅ PASS |
| REC-15 tenure defect | exactly 11 | 11 | ✅ PASS |
| REC-16 blank `Total Charges` defect | exactly 11 | 11 | ✅ PASS |
| REC-17a payment reclassification | 1,227 | 1,227 | ✅ PASS |
| REC-17b `Electronic check` absent from source | 2,365 | 2,365 | ✅ PASS |
| REC-18 Cable absorption | 830 | 830 | ✅ PASS |
| VAL-01 to VAL-10 | all | all | ✅ PASS |

CLEAN-21's value of **5** is expected and benign: five distinct `monthly_charge` values sit across a decile boundary. `NTILE` splits ties by design; the V-11 tie-break makes that split reproducible, not absent.

---

## 2. Analytical Questions in Scope

Seven approved analytical questions. **Six are answered in SQL. AQ-07 is not** — see §5.

| ID | Question | Answers | Output type |
|---|---|---|---|
| **AQ-01** | Churn rate and annualised revenue at risk at base level | BQ-01 | **Descriptive** |
| **AQ-02** | Revenue distribution across the base; top-decile share | BQ-02 | **Descriptive** |
| **AQ-03** | Churn rate by revenue decile | BQ-03 | **Diagnostic** |
| **AQ-04** | Do rankings by churn rate and revenue at risk agree, and where do they diverge? | BQ-03, BQ-04 | **Prioritisation** — A-07 locked |
| **AQ-05** | Which dimensions index highest for churn within the High value tier? | BQ-05 | **Diagnostic** |
| **AQ-06** | Do high-value drivers differ from base-wide drivers? | BQ-05 | **Diagnostic** |
| **C-3** | Early-life churn reported separately | BQ-01 | **Descriptive** |
| **AQ-07** | Retention spend break-even per segment | BQ-06 | **Scenario — deferred, §5** |

---

## 3. Question-by-Question Specification

### AQ-01 — Base position

| | |
|---|---|
| **View** | `analytics.vw_kpi_churn_rate`, `analytics.vw_kpi_revenue_at_risk` |
| **Script** | `03_analysis/01_base_position.sql` → finding **F-01** |
| **Output grain** | One row per scope (`opening_base`, `in_period_acquisition`, `ALL`) |
| **Numerator — churn rate** | `count(*) FILTER (WHERE is_churned)` within scope |
| **Denominator — churn rate** | `count(*)` within the **same** scope — symmetric by construction (C-3) |
| **Numerator — revenue at risk** | `sum(monthly_charge) × 12` over churned customers |
| **Denominator** | None. Revenue at risk is a level, not a rate |
| **Primary KPI** | Opening-cohort churn rate, expected **21.23%** |
| **Reported alongside** | Period-end base rate, expected **26.54%** |
| **Validation** | A-VAL-01 scope populations sum to 7,043 · A-VAL-02 churn rates reproduce 21.23 / 26.54 · A-VAL-03 revenue at risk reconciles to `sum(monthly_charge)` over churned × 12 |
| **Assumptions** | A-03 linear annualisation (evidence-supported, P-07 median ratio 1.0000) |
| **Type** | Descriptive |

### AQ-02 — Revenue concentration

| | |
|---|---|
| **View** | `analytics.vw_kpi_revenue_concentration` |
| **Script** | `03_analysis/02_revenue_concentration.sql` → **F-02** |
| **Output grain** | One row per revenue decile (10 rows), with a cumulative curve |
| **Numerator** | Decile recurring revenue, and cumulative recurring revenue descending from decile 10 |
| **Denominator** | Total recurring revenue across all 7,043 customers |
| **Method** | `SUM() OVER (ORDER BY revenue_decile DESC)` cumulative — a genuine analytical use of a window function, not a syntax showcase |
| **Validation** | A-VAL-04 decile revenue sums to base total · A-VAL-05 cumulative share reaches exactly 100% at decile 1 · A-VAL-06 decile membership sums to 7,043 |
| **Assumptions** | None beyond A-03 |
| **Type** | Descriptive |

### AQ-03 — Churn by revenue decile

| | |
|---|---|
| **View** | `analytics.vw_segment_p2_revenue_decile` |
| **Script** | `03_analysis/03_churn_by_revenue_decile.sql` → **F-03** |
| **Output grain** | One row per decile × cohort scope |
| **Numerator** | Churned customers in the decile |
| **Denominator** | All customers in the decile **within the same cohort scope** |
| **Cell sizes** | Verified 695–717 per decile at PREPARE — all `reportable` |
| **Validation** | A-VAL-06 · A-VAL-07 every cell carries `n` and `cell_size_flag` |
| **Assumptions** | Decile 1 = lowest charge, decile 10 = highest. Stated on every output, since both conventions exist |
| **Type** | Diagnostic |

### AQ-04 — Value–risk divergence ✅ **A-07 locked (D-21)**

| | |
|---|---|
| **Views** | `analytics.vw_segment_p1_value_contract`, `analytics.vw_segment_divergence` |
| **Script** | `03_analysis/04_value_risk_divergence.sql` → **F-04** |
| **Output grain** | One row per P1 cell (9: Value Tier × Contract) **per population scope** |
| **Numerator — churn rate** | Churned customers in the cell |
| **Denominator — churn rate** | All customers in the cell, same scope |
| **Revenue at risk** | `sum(monthly_charge) × 12` over churned customers in the cell |
| **Index** | `RANK() OVER (ORDER BY churn_rate DESC) − RANK() OVER (ORDER BY revenue_at_risk DESC)` |
| **Reporting rule** | The index is **ordinal**. It is reported *alongside* both underlying magnitudes and `n`, never alone (C-6) |
| **Expected minimum cell** | ≥ 208, derived from the PREPARE cell-size check |
| **Validation** | A-VAL-08 P1 cells sum to the scope population · A-VAL-09 ranks are 1–9 with no gaps · A-VAL-10 divergence sums to zero across the 9 cells (a property of paired ranks — a useful arithmetic check) |
| **Type** | **Prioritisation** |

> **✅ A-07 LOCKED 19 August 2026 (D-21).** The **primary** index uses the **opening cohort**, with both components — churn rate and revenue at risk — computed from that same population, so it compares like with like. The **all-customers** scope is retained as a clearly labelled **sensitivity analysis** and does not replace the primary result; §F-04d measures whether including in-period acquisitions materially changes the rankings. Locked before results were seen.

### AQ-05 — Drivers within the High value tier

| | |
|---|---|
| **View** | `analytics.vw_driver_lenses` |
| **Script** | `03_analysis/05_drivers_high_value.sql` → **F-05** |
| **Output grain** | One row per scope × lens × segment value |
| **Lenses** | **All seven, L1–L7, always reported** — including any showing no effect (C-6 commitment 3) |
| **Numerator** | Churned customers in the lens segment, within scope |
| **Denominator** | All customers in that lens segment, within the **same** scope |
| **Churn index** | Segment churn rate ÷ **scope** churn rate. Scope rate computed by window over the lens partition, which reconstitutes the whole scope population |
| **Small cells** | `n ≥ 100` reportable · `30–99` caveat with `n` stated · `< 30` flagged `below_threshold`, **surfaced not dropped** |
| **Validation** | A-VAL-11 each lens partitions its scope exactly · A-VAL-12 all seven lenses present in every scope · A-VAL-13 no cell silently absent |
| **Assumptions** | Service intensity uses the locked eight non-Core services; `PHONE`, `MULTI_LINE`, `INTERNET` excluded from the count |
| **Type** | Diagnostic |

### AQ-06 — High-value drivers vs base-wide

| | |
|---|---|
| **View** | `analytics.vw_driver_lenses` (same view, different scope rows) |
| **Script** | `03_analysis/06_drivers_comparison.sql` → **F-06** |
| **Output grain** | One row per lens × segment, with High-tier and all-customer figures side by side |
| **Comparison measure** | Difference in churn index between the High-tier scope and the all-customer scope |
| **Validation** | A-VAL-14 both scopes present for every lens × segment pair |
| **Assumptions** | None |
| **Type** | Diagnostic |

> **Charter risk R-04 stands.** If high-value drivers prove indistinguishable from base-wide drivers, that is a **legitimate null result and will be reported as one.** It is not grounds for trying another lens until something appears.

### C-3 — Early-life churn, reported separately

| | |
|---|---|
| **View** | `analytics.vw_kpi_early_life_churn` |
| **Script** | `03_analysis/07_early_life_churn.sql` |
| **Output grain** | One row per tenure month 1–3, plus a total |
| **Numerator** | Churned customers with `tenure_months ≤ 3` |
| **Denominator** | Reported two ways, both labelled: share of **all churn**, and share of **in-period acquisitions** |
| **Rationale** | 597 customers joined and left within the quarter — 31.9% of all churn. Early-life churn is an onboarding and acquisition-quality question, not a base-retention one. Pooling them would produce a driver profile describing neither |
| **Validation** | A-VAL-15 in-period acquisitions = 1,051 (454 survived + 597 churned) · A-VAL-16 opening base + in-period = 7,043 |
| **Type** | Descriptive |

---

## 4. Supporting KPI Views

| View | Purpose | Grain |
|---|---|---|
| `vw_kpi_churn_rate` | Opening-cohort and period-end rates | Scope |
| `vw_kpi_revenue_at_risk` | ARR at risk **and** long-distance at risk, always together (C-2) | Scope × cohort |
| `vw_kpi_revenue_concentration` | Pareto curve and top-decile share | Decile |
| `vw_kpi_arpu` | Average recurring revenue per customer | Scope × segment |
| `vw_kpi_revenue_retention` | Retained recurring revenue ÷ opening recurring revenue | Opening cohort |
| `vw_kpi_early_life_churn` | In-period acquisition churn | Tenure month |
| `vw_segment_p1_value_contract` | P1 — 9 cells | Value tier × contract × scope |
| `vw_segment_p2_revenue_decile` | P2 — 10 cells | Decile × scope |
| `vw_segment_divergence` | The divergence index | P1 cell × scope |
| `vw_driver_lenses` | L1–L7, uniform output shape | Scope × lens × segment |

**Every view carries `n` and `cell_size_flag`.** A uniform output shape across all seven lenses makes selective reporting visible rather than easy.

**No view emits a currency symbol.** Column names use `_currency_units` and comments record that the currency is unknown (P-15).

---

## 5. AQ-07 — Deliberately Not in This Batch

The retention spend break-even is **scenario analysis, not measurement** (C-2/D-01 framing, BQ-06 as reworded). It depends on two assumptions the dataset cannot supply:

- **Gross margin** — no cost data exists (risk R-02). Blocker **B-5**: a *cited* industry range is required before this can be built
- **Intervention success rate** — no campaign or outcome data exists (risk R-03)

It will be built in Excel as a sensitivity surface, because a two-way data table communicates a break-even better than a query result — and because a SQL view would lend it the false authority of a measured figure.

**Its SQL input already exists:** `vw_kpi_revenue_at_risk` and `vw_segment_p1_value_contract` supply revenue at risk per segment. Nothing further is needed from this batch.

---

## 6. Open Items and Assumptions

### 6.1 ✅ CLOSED — A-07 locked 19 August 2026 (D-21)

> **DECISION: the PRIMARY divergence index uses the OPENING COHORT**, with both components — churn rate and revenue at risk — computed from that same population. The all-customers version is retained as a clearly labelled **sensitivity analysis** and does not replace the primary result. In-period acquisitions remain in the separate early-life analysis. **Locked before results were seen; not to be changed afterwards.**

The reasoning that led to the decision is preserved below.

#### Original open item

**The approved specification does not say, and I am not going to choose silently.**

The FRAME specification (§E.1) defined the index before C-3 fixed the churn denominator. Two locked decisions now pull in different directions:

- **C-3**: the churn-rate KPI is the **opening cohort** (tenure ≥ 4), for symmetry
- **C-2 / §19**: revenue at risk includes **all churned customers**, because lost revenue is lost regardless of when they joined

The index ranks segments by both measures at once. Computing it on mixed populations would rank a symmetric rate against an asymmetric level.

**Three coherent options:**

| Option | Definition | Character |
|---|---|---|
| **A** | Both measures on the **opening cohort** | Internally consistent; excludes 597 early-life churners from the revenue side |
| **B** | Both measures on **all customers** | Uses the full revenue picture; the churn rate is then the period-end rate, not the primary KPI |
| **C** | Report **both**, designate one as headline | Fullest picture; two tables to communicate |

**What I have done:** the view emits **both scopes**, each explicitly labelled. **No headline is designated and no interpretation is drawn.** The choice is yours, and it must be made **before** results are reviewed — otherwise it becomes a selection made in light of which produces the better story.

**My recommendation is Option A** for the headline, with Option B reported alongside for completeness. Option A keeps the index internally consistent with the primary KPI, and the early-life churners are already reported separately under C-3, so nothing is lost from the overall picture.

### 6.2 Assumptions carried into ANALYSE

| # | Assumption | Basis |
|---|---|---|
| A-02 | Recurring revenue proxies customer value absent margin data | Standard where cost data is unavailable |
| A-03 | Monthly recurring revenue annualises linearly | Evidence-supported: P-07 median ratio 1.0000, 80.4% within ±5% |
| A-05 | Single fictional operator, single quarter | Verified |
| A-06 | **Currency unknown** | P-15 found no evidence. All outputs unitless |
| **A-07** | **Divergence population — opening cohort (primary), all customers (sensitivity)** | ✅ **Locked, D-21** |

### 6.3 Standing prohibitions, restated

No time trend. Tenure is **not** a time-series proxy — it is a cohort artefact. No currency symbol. No excluded field. No invented margin or campaign data. No causal claim from observational data. All seven lenses reported regardless of result. Small cells flagged, never silently dropped.

---

## 7. Validation Strategy

Sixteen analysis-stage checks (**A-VAL-01 to A-VAL-16**) in `03_analysis/08_analysis_validation.sql`, covering:

| Category | Checks |
|---|---|
| Population integrity | Scope populations sum to 7,043; segment memberships sum to their scope |
| Denominator consistency | Every rate's numerator is a subset of its own denominator |
| Revenue reconciliation | Every revenue aggregate recomputes to `sum(monthly_charge) × 12` |
| Fan-out absence | Row counts unchanged through every view |
| Reproducibility | Decile membership stable across two executions of the same view |
| Small-cell handling | Every segment row carries `n` and `cell_size_flag`; no cell absent |
| KPI reproduction | 21.23% and 26.54% reproduced from the analysis views, not just the base view |

**Any failure stops work and returns for review.** No expectation is adjusted to make a check pass.

---

## 8. What This Plan Does Not Do

No findings. No insights. No recommendations. No charts. No stakeholder narrative. No portfolio conclusions.

The scripts produce **numbered, evidenced outputs**. Interpretation is a separate, later step requiring your approval — and under `CLAUDE.md` §5 every claim will then need a complete evidence chain back to a specific query and committed result file.
