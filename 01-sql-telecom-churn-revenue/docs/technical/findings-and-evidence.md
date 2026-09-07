# Findings and Evidence

Every reported figure, traced to the query output it came from, with interpretation and inference
kept separate from observed fact.

**Related:** [Methodology](../methodology.md) · [Data Quality](data-quality.md) · [Case Study](../case-study.md) · [Technical Notes](technical-notes.md)

Telecom Customer Churn & Revenue Analysis

**Scope:** evidence chain for every reported figure
**Prepared:** 19 August 2026
**Status:** evidence record. Findings only; no recommendations.

---

## Evidence status

**The data pipeline and the analysis are locked.** No SQL, definition, population, calculation, segmentation rule, cut point, ranking or validation expectation has been modified in producing this register.

**All validation gates passed:** A-VAL-01 through A-VAL-19 report PASS in `analyse_08_validation.txt`, including the three critical controls — locked KPI reproduction (A-VAL-02a/b), driver-lens population integrity (A-VAL-11), and the prohibited-field scan (A-VAL-19).

Every figure below is quoted directly from a committed output file. **Nothing has been recomputed, rounded differently, or derived outside the locked pipeline**, except arithmetic reconciliations explicitly shown in the cross-check section, which use only figures already present in the outputs.

| Finding ID | Topic | Primary source | Validation status |
|---|---|---|---|
| **F-01** | Base position | `analyse_01_base_position.txt` | ✅ A-VAL-01, 02a, 02b, 03 PASS |
| **F-02** | Revenue concentration | `analyse_02_revenue_concentration.txt` | ✅ A-VAL-04, 05 PASS |
| **F-03** | Churn by revenue decile | `analyse_03_churn_by_decile.txt` | ✅ A-VAL-06, 07 PASS |
| **F-04** | Value–risk divergence | `analyse_04_divergence.txt` | ✅ A-VAL-08a/b, 09, 10 PASS |
| **F-05** | High-value driver lenses | `analyse_05_drivers_high_value.txt` | ✅ A-VAL-11, 12, 13, 16 PASS |
| **F-06** | High-value vs base-wide | `analyse_06_drivers_comparison.txt` | ✅ A-VAL-14 PASS |
| **F-07** | Early-life churn | `analyse_07_early_life_churn.txt` | ✅ A-VAL-15 PASS |

**Numbering:** the seven-group structure is retained as defined. No evidence supports adding, merging or splitting a finding group. One structural observation is noted at F-04 regarding the sensitivity analysis; it does not warrant a separate ID.

### Standing constraints on every statement below

- **Currency is unknown.** Profiling check P-15 found no currency symbol, code or number format in any source file. All monetary figures are quoted as **currency units** and must never be labelled £, $, USD or GBP.
- **The data is fictional.** IBM describes it as *"a fictional telco company that provided home phone and Internet services to 7043 customers in California in Q3."* No statement here is evidence about any real operator or market.
- **Single observation window.** `Quarter` is present but constant `Q3`. No trend exists and tenure must not be read as a time series.
- **Licence unresolved** (D-09). No licensing claim is made anywhere.
- **Excluded fields.** `Satisfaction Score`, `Churn Score`, `CLTV`, `Churn Reason` and `Churn Category` were excluded at the database level and contributed to nothing below.
- **No retention activity data.** The dataset contains no campaign, offer-made, contact or save records. Nothing here observes what the business actually did.

---
---

# F-01 — Base position

**Source:** `analyse_01_base_position.txt` (three blocks) · Views: `vw_kpi_churn_rate`, `vw_kpi_revenue_at_risk`, `vw_kpi_revenue_retention`

## Observed facts

| # | Fact | Scope | Source block |
|---|---|---|---|
| F-01.1 | The opening cohort contains **5,992 customers**, of whom **1,272 churned** — a churn rate of **21.23%** | Opening cohort (tenure ≥ 4) — **PRIMARY KPI, C-3** | Block 1 |
| F-01.2 | The period-end base contains **7,043 customers**, of whom **1,869 churned** — a rate of **26.54%** | All customers — **reconciliation measure only** | Block 1 |
| F-01.3 | In-period acquisitions number **1,051**, of whom **597 churned** — **56.80%** | In-period acquisitions (tenure ≤ 3) | Block 1 |
| F-01.4 | Annual recurring revenue at risk is **1,232,425.80 currency units** | Opening cohort | Block 2 |
| F-01.5 | Annual recurring revenue at risk is **1,669,570.20 currency units** | All churned customers | Block 2 |
| F-01.6 | Annual long-distance revenue at risk is **519,603.72 currency units** | All churned customers | Block 2 |
| F-01.7 | Revenue at risk represents **25.68%** of opening-cohort recurring revenue, and **30.50%** of all-customer recurring revenue | Both scopes | Block 2 |
| F-01.8 | Mean annual recurring revenue per churned customer is **968.89** (opening cohort) and **732.24** (in-period acquisitions) | Both scopes | Block 2 |
| F-01.9 | Revenue retention is **74.32%** while customer retention is **78.77%** | Opening cohort | Block 3 |
| F-01.10 | Total recurring revenue is **5,473,399.20 currency units** across all customers; **4,799,408.40** in the opening cohort | Both scopes | Block 2, 3 |

## Interpretation

The primary and reconciliation rates measure different populations, and the 5.31-percentage-point gap between them (21.23% vs 26.54%) is accounted for entirely by the in-period acquisition cohort, whose churn rate is far higher.

**F-01.9 is the most analytically substantive observation in this group.** Revenue retention (74.32%) sitting **below** customer retention (78.77%) means the customers who left carried, on average, higher recurring revenue than those who stayed. This is arithmetic, not an assumption: if leavers had been an average slice of the base, the two percentages would coincide.

F-01.6 shows long-distance revenue at risk (519,603.72) is roughly 31% of the recurring figure again — a material amount held deliberately outside the headline under C-2, because a retention offer secures a subscription rather than a usage volume.

## Inferences

**Labelled as inferences — these go beyond what the output directly establishes.**

- **INFERENCE F-01.a:** the gap in F-01.9 suggests that revenue exposure is not proportional to customer-count exposure, and that a prioritisation built on customer counts alone would misstate the commercial position. *This is an inference about how one would prioritise, not an observation about the data.*
- **INFERENCE F-01.b:** the mean recurring revenue per churned customer being lower in the in-period cohort (732.24) than the opening cohort (968.89) is consistent with in-period acquisitions differing in value profile from the established base. **The data does not establish why.**

## Limitations and caveats

- **Single quarter.** No trend. It cannot be established whether 21.23% is rising, falling or stable, and tenure must not be substituted as a time axis.
- **No external benchmark (B-6 open).** Ofcom's telecommunications market data release was confirmed not to publish churn or switching rates. **No benchmark is asserted**, and 21.23% must not be described as high or low against an industry figure that has not been sourced.
- **Currency unknown.** Every monetary figure is unitless.
- **No causal content.** These are counts and rates within one observation window.
- **Revenue at risk uses all churned customers** (C-2), while the churn *rate* uses the opening cohort (C-3). The two use different populations by design. Quoting 1,232,425.80 alongside 26.54%, or 1,669,570.20 alongside 21.23%, would be a mismatch.
- **Annualisation is a convention** (assumption A-03), supported by profiling check P-07 (median ratio 1.0000) but still a forward-looking assumption.

## Business implication

The size and composition of the revenue exposure is established and quantified, which is the precondition for any prioritisation discussion. **F-01.9 warrants decision-maker attention**: it indicates that a view built on customer counts and a view built on revenue would not describe the same exposure. It does not yet indicate what should be done about that.

---

# F-02 — Revenue concentration

**Source:** `analyse_02_revenue_concentration.txt` (two blocks) · View: `vw_kpi_revenue_concentration`
**Convention:** decile 1 = lowest monthly charge; decile 10 = highest. Cumulative columns run from decile 10 downward.

## Observed facts

| # | Fact | Scope | Source block |
|---|---|---|---|
| F-02.1 | The top decile (10) holds **16.71%** of total recurring revenue while holding **10.00%** of customers | All customers | Block 1, 2 |
| F-02.2 | The top two deciles (9–10) hold **31.84%** of recurring revenue | All customers | Block 2 |
| F-02.3 | The top three deciles (8–10) — the **High value tier** — hold **45.71%** of recurring revenue | All customers | Block 2 |
| F-02.4 | The bottom three deciles (1–3) — the **Low value tier** — hold **11.89%** of recurring revenue | All customers | Block 2 |
| F-02.5 | Decile sizes are 704–705 customers, i.e. **10.00–10.01%** of the base each | All customers | Block 1 |
| F-02.6 | Monthly charge ranges from **18.25** in decile 1 to **118.75** in decile 10 | All customers | Block 1 |
| F-02.7 | Revenue share per decile falls smoothly from **16.71%** (decile 10) to **3.03%** (decile 1) — a ratio of roughly 5.5 to 1 | All customers | Block 1 |
| F-02.8 | Cumulative revenue share reaches **100.00%** at decile 1 | All customers | Block 1 |

## Interpretation

Revenue is **moderately, not sharply, concentrated**. The top 10% of customers hold 16.71% of recurring revenue — well short of the "small minority holds most of the revenue" pattern often assumed in subscription businesses. Half the base (deciles 6–10) holds 69.91%; the other half holds 30.09%.

The smooth decile-by-decile decline in F-02.7, with no step change, indicates the underlying monthly-charge distribution is continuous rather than clustered into distinct commercial tiers.

**This finding constrains what the rest of the analysis can support.** The charter (decision branch 2) anticipated that if revenue were broadly distributed, segment targeting would have limited leverage and the remedy would be structural. F-02 is evidence relevant to that branch.

## Inferences

- **INFERENCE F-02.a:** the moderate concentration suggests a value-based targeting strategy has less mechanical leverage here than it would in a base where the top decile held, say, 40% of revenue. *This is an inference about strategy viability, not an observed property of the data.*
- **INFERENCE F-02.b:** the absence of a step change in F-02.7 is consistent with a single continuous pricing structure rather than distinct product tiers. **The data does not establish the operator's pricing architecture.**

## Limitations and caveats

- **Deciles are equal-frequency, not equal-value.** Ties at decile boundaries are split by the deterministic `NTILE` tie-break (V-11 / D-20). Informational check CLEAN-21 recorded five charge values spanning a boundary.
- **Concentration is measured on recurring revenue only** (C-2). Long-distance revenue is excluded from this curve, so it does not describe total revenue concentration.
- **Static snapshot.** Concentration at a point in time; no statement about whether it is changing.
- **Currency unknown**; all values unitless.
- The High/Mid/Low tier boundaries are the predefined C-6 cut points (deciles 8–10 / 4–7 / 1–3), fixed before results were seen.

## Business implication

The degree of concentration is a direct input to whether prioritisation by value is a viable strategy at all. **It warrants attention as a framing fact** before any targeting discussion, since it bounds how much difference targeting could make.

---

# F-03 — Churn by revenue decile

**Source:** `analyse_03_churn_by_decile.txt` (three blocks) · View: `vw_segment_p2_revenue_decile`, `vw_kpi_arpu`

## Observed facts

### Opening cohort (primary population)

| # | Fact | Source |
|---|---|---|
| F-03.1 | Churn rate by decile is non-monotonic: **4.07, 3.85, 15.14, 17.89, 12.93, 27.89, 32.14, 29.56, 38.96, 24.36** for deciles 1→10 | Block 1 |
| F-03.2 | The **highest** decile churn rate is decile 9 at **38.96%** (index 1.84 vs the 21.23% scope rate) | Block 1 |
| F-03.3 | Decile 10 churns at **24.36%** (index 1.15) — **lower than deciles 6, 7, 8 and 9** | Block 1 |
| F-03.4 | The **lowest** rates are deciles 2 (**3.85%**) and 1 (**4.07%**) | Block 1 |
| F-03.5 | Recurring revenue at risk peaks at decile 9 (**307,440.00**), then decile 10 (**217,996.20**) and decile 8 (**203,013.00**) | Block 1 |
| F-03.6 | Every decile cell is flagged `reportable` (n = 535–698) | Block 1 |

### All customers (comparison population)

| # | Fact | Source |
|---|---|---|
| F-03.7 | The same non-monotonic shape holds: **8.65, 9.65, 25.25, 24.43, 21.59, 38.07, 37.78, 34.38, 40.91, 24.72** | Block 2 |
| F-03.8 | Decile 9 is again highest at **40.91%**; decile 10 again lower at **24.72%** | Block 2 |

### ARPU by tier and outcome

| # | Fact | Source |
|---|---|---|
| F-03.9 | **High tier, opening cohort:** churned customers average **98.07** monthly recurring, retained **99.48** — churned slightly *lower* | Block 3 |
| F-03.10 | **Mid tier, opening cohort:** churned **72.16**, retained **67.86** — churned *higher* | Block 3 |
| F-03.11 | **Low tier, opening cohort:** churned **31.49**, retained **24.62** — churned *higher* | Block 3 |
| F-03.12 | Opening-cohort tier populations are High **2,004**, Mid **2,316**, Low **1,672** | Block 3 |

## Interpretation

Churn is **not monotonically increasing with customer value**. It rises through the middle of the distribution, peaks at decile 9, and falls at decile 10. Answering BQ-03 directly: on this evidence the base is losing customers disproportionately from the **upper-middle** of the value distribution rather than from either extreme.

F-03.9 to F-03.11 refine this. Within the High tier, leavers and stayers have almost identical recurring revenue (98.07 vs 99.48). Within Mid and Low, leavers carry *higher* revenue than stayers. The revenue-weighted effect observed at F-01.9 therefore arises principally from the middle and lower tiers, not from the top.

The two populations (blocks 1 and 2) show the same shape at different levels, so the pattern is not an artefact of the C-3 cohort choice.

## Inferences

- **INFERENCE F-03.a:** the decile-10 dip is consistent with the highest-charge customers differing in some respect from decile 9. **The data does not establish what that is.** It could relate to contract mix, service mix, tenure, or something unobserved. It warrants investigation rather than explanation.
- **INFERENCE F-03.b:** the near-parity of churned and retained ARPU within the High tier (F-03.9) suggests that, *within* that tier, recurring revenue alone does not distinguish leavers from stayers — which is part of the motivation for the driver lenses at F-05. *Inference about analytical direction, not an observed relationship.*
- **INFERENCE F-03.c:** the non-monotonic shape suggests value and risk are not aligned in a simple way. **This is the premise the F-04 divergence index tests; it is not itself proof of divergence.**

## Limitations and caveats

- **Association only.** Decile membership coincides with churn rate differences. Nothing here establishes that a customer's charge level *causes* any churn outcome. Charge level is correlated with contract type, service mix and tenure, none of which is controlled for in this cut.
- **No multivariate control.** These are single-dimension cuts. Confounding between value and the F-05 driver dimensions is expected and unaddressed.
- **Deciles are relative**, not absolute price bands, and are not comparable to any external segmentation.
- **Single quarter**; no statement about whether the shape is stable.
- **Currency unknown.**

## Business implication

The distribution of churn across the value range is established and is **not the simple monotonic pattern that a value-based prioritisation might assume**. The decile-9 concentration and the decile-10 dip both **warrant investigation** before any prioritisation is settled.

---

# F-04 — Value–risk divergence

**Source:** `analyse_04_divergence.txt` (four blocks) · Views: `vw_segment_p1_value_contract`, `vw_segment_divergence`
**A-07 locked (D-21):** primary = opening cohort; all-customers = sensitivity analysis only.

## Primary result — Opening cohort

*Every row of this block carries `result_designation = 'PRIMARY RESULT - Opening cohort'`.*

### Observed facts

| # | Fact | Source |
|---|---|---|
| F-04.1 | Nine P1 cells sum to **5,992** customers, matching the opening cohort exactly (A-VAL-08a) | Blocks 1–2 |
| F-04.2 | **High / Month-to-Month**: n **894**, churned **488**, rate **54.59%**, revenue at risk **566,313.60** = **45.95%** of scope revenue at risk. Rank 1 by churn rate, rank 1 by revenue at risk, **divergence 0** | Block 2 |
| F-04.3 | **Mid / Month-to-Month**: n **1,182**, rate **39.42%**, revenue at risk **406,459.20** = **32.98%**. Ranks 2 and 2, **divergence 0** | Block 2 |
| F-04.4 | The two Month-to-Month cells above together account for **78.93%** of opening-cohort recurring revenue at risk | Derived from Block 2 shares (45.95 + 32.98) |
| F-04.5 | **Maximum absolute divergence across all nine cells is 1 rank.** Four cells diverge by ±1; five cells diverge by 0 | Block 2 |
| F-04.6 | Cells diverging by **+1** (rank worse on churn rate than on revenue at risk): High / One Year, Mid / Two Year | Block 2 |
| F-04.7 | Cells diverging by **−1** (rank worse on revenue at risk than on churn rate): Low / Month-to-Month, Low / One Year | Block 2 |
| F-04.8 | The divergence index sums to **0** within the scope, as required for paired ranks (A-VAL-10) | Block 2 |
| F-04.9 | All nine cells are flagged `reportable` (n = 442–1,182) | Blocks 1–2 |
| F-04.10 | Contract type separates churn rate sharply within every tier — e.g. High tier: **54.59%** M2M, **19.19%** One Year, **5.26%** Two Year | Block 1 |

### Interpretation

**The central analytical construct of this project returns a near-null result, and that must be reported as the finding.**

The two prioritisations — ranking by churn rate and ranking by revenue at risk — **agree almost completely** on this population. The top two segments are identical under both. No cell moves more than one rank position. The project was designed to test whether a churn-led prioritisation would materially diverge from a revenue-led one; on the opening cohort, using the predefined P1 segmentation, **it does not**.

F-04.4 is the substantive positional fact: nearly four-fifths of opening-cohort recurring revenue at risk sits in two of the nine cells, both Month-to-Month.

F-04.10 shows contract type separating churn rates by roughly a factor of ten within the High tier — a much larger spread than the divergence index detects between the two ranking logics.

### Inferences

- **INFERENCE F-04.a:** the near-null divergence suggests that on this dataset, at this segmentation granularity, a churn-rate-led prioritisation would arrive at approximately the same segment ordering as a revenue-led one. *This is an inference about two prioritisation methods, not evidence about any operator's actual allocation — the dataset contains no retention activity data.*
- **INFERENCE F-04.b:** the concentration in F-04.4 suggests prioritisation effort would concentrate on a small number of cells under either logic. **The data does not establish what intervention, if any, would be appropriate.**
- **INFERENCE F-04.c:** the result may be sensitive to segmentation granularity — nine cells is a coarse partition, and divergence could differ at a finer grain. **This was not tested**, and testing it now would be a post-hoc specification change, which the the fixed specification does not allow.

## Sensitivity analysis — All customers

*Every row of this block carries `result_designation = 'SENSITIVITY ANALYSIS ONLY - All customers'`. **This does not replace the primary result.***

### Observed facts

| # | Fact | Source |
|---|---|---|
| F-04.11 | Nine cells sum to **7,043** (A-VAL-08b) | Block 3 |
| F-04.12 | **Mid / Month-to-Month** holds the largest revenue at risk (**682,805.40**, rank 1) while ranking **2** by churn rate — **divergence +1** | Block 3 |
| F-04.13 | **High / Month-to-Month** holds rank **1** by churn rate (**57.30%**) and rank **2** by revenue at risk (**660,796.80**) — **divergence −1** | Block 3 |
| F-04.14 | Of nine cells, **seven have identical divergence values in both scopes**; only the two Month-to-Month cells above change, and each by one rank | Block 4 |
| F-04.15 | The scope-sensitivity column is non-zero for exactly **two** of nine cells (+1 and −1) | Block 4 |

### Interpretation

Including in-period acquisitions **swaps the top two positions** on the revenue-at-risk ranking and leaves the remaining seven cells unchanged. The choice of population scope is therefore **immaterial to the overall ordering** but material to which single cell ranks first by revenue at risk.

This is a useful, honest outcome of having locked A-07 in advance: the sensitivity test demonstrates the primary result is robust to the scope decision, rather than the scope decision having been chosen to produce a preferred result.

### Inference

- **INFERENCE F-04.d:** the stability of seven of nine cells suggests the A-07 scope decision does not materially affect prioritisation conclusions. *Inference about robustness, not an observed property.*

## Limitations and caveats

- **The index is ordinal.** A divergence of ±1 conveys rank order only. It is reported here alongside churn rates, revenue-at-risk magnitudes and `n`, and must never be quoted alone (C-6).
- **Fictional data.** Any divergence — or its absence — is a property of IBM's data-generation logic, not evidence about a real operator. **This finding demonstrates that the method works and what it returns; it does not establish that misallocation does or does not exist anywhere real.**
- **No retention activity data.** BQ-04 was reworded at Stage 2 precisely because actual allocation is unobservable. This compares two *hypothetical* prioritisation logics.
- **Nine cells is coarse.** The result is specific to the predefined P1 segmentation.
- **No causal content.** Contract type is *associated with* differing churn rates; nothing here establishes that contract type causes them, and contract choice is plausibly related to unobserved customer characteristics.
- **Currency unknown.**

## Business implication

On this evidence, **the choice between a churn-led and a revenue-led prioritisation would not materially change which segments receive attention**, and revenue at risk is concentrated in two of nine segments. Both facts are directly relevant to a prioritisation discussion. Neither indicates what action to take.

---

# F-05 — High-value driver lenses

**Source:** `analyse_05_drivers_high_value.txt` (three blocks) · View: `vw_driver_lenses`
**Scope:** opening cohort × High value tier · **n = 2,004** · **scope churn rate = 30.89%**

**All seven predefined lenses are reported below, including those showing weak or non-differentiating results.**

## Observed facts

### L1 — Contract type

| Segment | n | Churned | Rate | Index vs 30.89% | Flag |
|---|---|---|---|---|---|
| Month-to-Month | 894 | 488 | **54.59%** | 1.77 | reportable |
| One Year | 521 | 100 | 19.19% | 0.62 | reportable |
| Two Year | 589 | 31 | **5.26%** | 0.17 | reportable |

**F-05.1:** the spread between Month-to-Month and Two Year is **49.33 percentage points**, the widest of any lens.

### L2 — Tenure band

| Segment | n | Churned | Rate | Index | Flag |
|---|---|---|---|---|---|
| 2. First year (4–12m) | 204 | 146 | **71.57%** | 2.32 | reportable |
| 3. Second year (13–24m) | 260 | 136 | 52.31% | 1.69 | reportable |
| 4. Established (25–48m) | 522 | 179 | 34.29% | 1.11 | reportable |
| 5. Long tenure (49–72m) | 1,018 | 158 | **15.52%** | 0.50 | reportable |

**F-05.2:** the rate declines monotonically across tenure bands, from 71.57% to 15.52%.
**F-05.3:** band 1 (in-period acquisition) is absent by construction — the opening cohort excludes tenure ≤ 3.

### L3 — Payment method

| Segment | n | Churned | Rate | Index | Flag |
|---|---|---|---|---|---|
| Mailed Check | **36** | 16 | 44.44% | 1.44 | ⚠️ **caveat_required** |
| Bank Withdrawal | 1,389 | 490 | 35.28% | 1.14 | reportable |
| Credit Card | 579 | 113 | 19.52% | 0.63 | reportable |

**F-05.4:** Mailed Check has **n = 36**, between the 30 and 100 thresholds. Its 44.44% must be reported with its `n` stated.

### L4 — Internet type

| Segment | n | Churned | Rate | Index | Flag |
|---|---|---|---|---|---|
| Cable | **74** | 36 | 48.65% | 1.57 | ⚠️ **caveat_required** |
| Fiber Optic | 1,850 | 582 | 31.46% | 1.02 | reportable |
| DSL | **80** | 1 | **1.25%** | 0.04 | ⚠️ **caveat_required** |

**F-05.5:** Fiber Optic accounts for **92.32%** of the High tier.
**F-05.6:** DSL shows **1 churned customer out of 80**. Two of three segments require a caveat.
**F-05.7:** "No internet" does not appear in the High tier — structurally consistent, as customers without internet do not reach the top three deciles by monthly charge.

### L5 — Service intensity *(eight non-Core add-ons; PHONE, MULTI_LINE, INTERNET excluded per C-6)*

| Segment | n | Churned | Rate | Index | Flag |
|---|---|---|---|---|---|
| 2. Light (1–2) | **42** | 20 | 47.62% | 1.54 | ⚠️ **caveat_required** |
| 3. Moderate (3–4) | 640 | 268 | 41.88% | 1.36 | reportable |
| 4. Deep (5–8) | 1,322 | 331 | **25.04%** | 0.81 | reportable |

**F-05.8:** the "None (0)" band does not appear in the High tier — structurally consistent.

### L6 — Offer held

| Segment | n | Churned | Rate | Index | Flag |
|---|---|---|---|---|---|
| Offer E | **64** | 46 | **71.88%** | 2.33 | ⚠️ **caveat_required** |
| Offer D | 131 | 72 | 54.96% | 1.78 | reportable |
| Offer C | 134 | 50 | 37.31% | 1.21 | reportable |
| No offer | 1,082 | 354 | 32.72% | 1.06 | reportable |
| Offer B | 337 | 66 | 19.58% | 0.63 | reportable |
| Offer A | 256 | 31 | **12.11%** | 0.39 | reportable |

**F-05.9:** the six offer categories span 12.11% to 71.88%, the widest categorical spread after L1.

### L7 — Referral behaviour

| Segment | n | Churned | Rate | Index | Flag |
|---|---|---|---|---|---|
| Has not referred | 884 | 341 | 38.57% | 1.25 | reportable |
| Has referred | 1,120 | 278 | 24.82% | 0.80 | reportable |

**F-05.10:** a spread of 13.75 percentage points — **the narrowest of the seven lenses**.

### Coverage

**F-05.11:** all seven lenses are present; **each partitions the High tier to exactly 2,004 customers** (A-VAL-11).
**F-05.12:** of 24 segment cells, **19 are `reportable`, 5 require a caveat, 0 are below the reporting threshold**.

## Interpretation

Every lens shows some separation, but the magnitudes differ substantially. Contract type (L1), tenure band (L2) and offer held (L6) show wide spreads; service intensity (L5) and referral behaviour (L7) show narrower ones.

L2's monotonic decline is the cleanest pattern in the group. L7's 13.75-point spread is real but modest — **a comparatively weak result, reported as such rather than omitted.**

The five caveat-flagged cells (L3 Mailed Check, L4 Cable, L4 DSL, L5 Light, L6 Offer E) carry the most extreme rates in their lenses while having the smallest populations. **Extreme rates on small cells are exactly where over-reading is most likely.**

## Inferences

- **INFERENCE F-05.a:** the L1 and L2 spreads suggest contractual commitment and relationship length are the dimensions most strongly associated with churn within the High tier. **Association only — these variables are heavily interrelated**, since long-tenure customers are more likely to hold long contracts.
- **INFERENCE F-05.b:** L6's spread suggests offer holding is associated with differing churn rates. **The direction of any relationship is entirely unestablished.** Offers may be extended to customers already considered at risk, in which case the association would run opposite to the intuitive reading. The dataset records only which offer is *held*, with no date, no reason and no outcome.
- **INFERENCE F-05.c:** L7's narrow spread suggests referral behaviour differentiates weakly in this tier. *A weak result, and reported as one.*

## Limitations and caveats

- **All seven lenses are single-dimension cuts with no multivariate control.** L1, L2, L5 and L6 are certainly interrelated; none of these figures isolates an independent contribution.
- **Five cells require a caveat** (n = 36 to 80). Their rates must always be quoted with `n`.
- **L4's DSL cell shows 1 churned customer in 80.** A single observation drives the entire rate; it is not a stable estimate.
- **L6 direction is unknown** — see INFERENCE F-05.b. This is the most easily misread lens in the register.
- **Structural absences are not zero results.** L4 "No internet" and L5 "None" are absent from the High tier by construction, not because their churn is zero.
- **No causal claims.** Every relationship is an association within a single fictional quarter.
- **Excluded fields.** `Churn Reason` was excluded at the database level, so no lens here is contaminated by an outcome-derived label.

## Business implication

Seven dimensions have been examined against a predefined specification, with the strength of each recorded, including the weak ones. Contract type, tenure band and offer held **warrant the most investigative attention**; the offer lens in particular **warrants investigation of direction before it is discussed at all**. None of this establishes what should be done.

---

# F-06 — High-value versus base-wide comparison

**Source:** `analyse_06_drivers_comparison.txt` (three blocks) · View: `vw_driver_lenses`
**Comparison:** High tier vs all customers, both within the opening cohort. Compares **churn indices**, not raw rates, so the two scopes' differing base rates do not create spurious differences.

## Observed differences

| Lens | Segments compared | Max abs index difference | Mean abs index difference |
|---|---|---|---|
| **L4** Internet type | 3 | **0.67** | **0.62** |
| **L6** Offer held | 6 | **0.52** | 0.19 |
| **L2** Tenure band | 4 | **0.49** | 0.26 |
| **L3** Payment method | 3 | 0.36 | 0.22 |
| **L1** Contract type | 3 | **0.15** | 0.10 |
| **L5** Service intensity | 3 | **0.12** | 0.08 |
| **L7** Referral behaviour | 2 | **0.06** | 0.04 |

**F-06.1:** the largest single index difference across all 24 comparisons is **0.67** (L4, Cable: 0.90 base-wide → 1.57 High tier).
**F-06.2:** L4 Fiber Optic moves **1.65 → 1.02** (−0.63); L4 DSL moves **0.60 → 0.04** (−0.56).
**F-06.3:** **L1, L5 and L7 all have maximum differences below 0.16** and mean differences at or below 0.10.
**F-06.4:** L1 Contract type — the strongest lens within the High tier — shows one of the **smallest** differences between scopes (max 0.15).
**F-06.5:** L6 "No offer" shows an index difference of exactly **0.00**.
**F-06.6:** every High-tier lens row has an all-customer counterpart; **zero orphans** (A-VAL-14).

## Interpretation

**AQ-06 returns a largely null result for four of seven lenses, and that is the finding.**

For contract type (L1), service intensity (L5) and referral behaviour (L7), the churn indices in the High tier are close to those base-wide. These dimensions behave **similarly** in the High tier and across the base.

L4 (internet type) is the clear exception: all three of its segments shift substantially, and in **different directions** — Cable's index rises while Fiber Optic's and DSL's fall.

L2 and L6 show intermediate differences concentrated in particular segments rather than across the lens.

**Charter risk R-04 anticipated this outcome explicitly:** *"if high-value churn drivers prove identical to base-wide drivers, the project's central premise weakens… a null result is a legitimate finding and will be reported as one."* For L1, L5 and L7 that condition is substantially met.

## Inferences

- **INFERENCE F-06.a:** the small differences for L1, L5 and L7 suggest that for those dimensions, a base-wide driver profile would describe the High tier adequately, and a separate High-tier analysis adds little. *Inference about analytical value, not an observed property.*
- **INFERENCE F-06.b:** L4's large, direction-varying shifts suggest internet type interacts with value tier differently from the other dimensions. **The data does not establish the nature of that interaction**, and two of L4's three High-tier cells are caveat-flagged (n = 74 and n = 80), so the shift rests partly on small cells.
- **INFERENCE F-06.c:** taken together, F-06 suggests the High tier is **not** characterised by a distinctive driver profile across most dimensions examined. *This weakens one of the premises stated in the project charter and should be reported plainly rather than minimised.*

## Limitations and caveats

- **No significance testing.** These are descriptive index differences with no confidence interval. "Large" and "small" are relative to each other, not to any statistical threshold.
- **Small cells propagate.** L4's differences rest on High-tier cells of n = 74 and n = 80.
- **The scopes overlap.** The High tier is a subset of all customers, so the comparison is between a part and its whole, not between independent groups. Differences are therefore attenuated by construction.
- **Index comparison is a choice** — it normalises for different base rates. Comparing raw rates would give a different-looking picture and would be misleading for that reason.
- **Single quarter, fictional data, no causal content.**

## Business implication

Whether high-value customers require a distinct diagnostic treatment is now an evidence-based question rather than an assumption. For most dimensions examined the answer appears to be **no**, which **warrants attention** because it bears directly on whether segment-specific analysis is worth commissioning. It does not indicate any action.

---

# F-07 — Early-life churn

**Source:** `analyse_07_early_life_churn.txt` (three blocks) · Views: `vw_kpi_early_life_churn`, `vw_driver_lenses`, `vw_kpi_revenue_at_risk`
**Population:** in-period acquisitions (tenure ≤ 3), **n = 1,051** — **analytically separate from the opening cohort throughout.**

## Observed facts

| # | Fact | Source |
|---|---|---|
| F-07.1 | **1,051** customers were acquired within the observation quarter; **597 churned** — **56.80%** | Block 1 |
| F-07.2 | By tenure month: month 1 **613 acquired / 380 churned (61.99%)**; month 2 **238 / 123 (51.68%)**; month 3 **200 / 94 (47.00%)** | Block 1 |
| F-07.3 | These 597 customers represent **31.94% of all 1,869 churned customers** | Block 1 |
| F-07.4 | Recurring revenue at risk is **437,144.40 currency units** — **26.18%** of the total 1,669,570.20 | Blocks 1, 3 |
| F-07.5 | Long-distance revenue at risk is **162,380.88 currency units** | Block 1 |
| F-07.6 | **95.43%** of this cohort (1,003 of 1,051) holds Month-to-Month contracts, churning at **59.32%** | Block 2 |
| F-07.7 | One Year (**n = 26**) and Two Year (**n = 22**) cells are **below the n = 30 reporting threshold** | Block 2 |
| F-07.8 | Internet type: Fiber Optic **422 / 76.07%**; Cable **136 / 58.82%**; DSL **241 / 52.28%**; No internet **252 / 27.78%** | Block 2 |
| F-07.9 | Service intensity: Moderate **199 / 71.36%**; Light **509 / 64.83%**; Deep **49 / 63.27%**; None **294 / 31.97%** | Block 2 |
| F-07.10 | Offer held: **only two categories appear** — Offer E (**457 / 61.71%**) and No offer (**594 / 53.03%**). Offers A–D are **absent** from this cohort | Block 2 |
| F-07.11 | Referral behaviour: has not referred **872 / 57.22%** (index 1.01); has referred **179 / 54.75%** (index 0.96) | Block 2 |
| F-07.12 | The cohort split of revenue at risk is **73.82%** opening cohort / **26.18%** in-period | Block 3 |

## Interpretation

This population behaves very differently from the opening cohort — 56.80% against 21.23% — which is why C-3 requires them to be kept separate. **These 597 customers are not part of the primary churn KPI numerator and must never be added to it.**

F-07.2 shows the rate declining across the three months. **This must be read carefully:** each month is a different acquisition group observed for a different length of time within the quarter, not the same group tracked over time. It is not a survival curve.

F-07.10 is the most structurally notable observation. Only Offer E and "No offer" appear at all in this cohort — Offers A through D are entirely absent from in-period acquisitions.

F-07.11 is effectively null: indices of 1.01 and 0.96 against a scope rate of 56.80%.

## Inferences

- **INFERENCE F-07.a:** the concentration in Month-to-Month contracts (95.43%) is consistent with new customers typically starting on rolling terms. **The data does not establish acquisition practice**, and this composition alone would produce a higher aggregate churn rate for the cohort given the contract-type association observed at F-05.
- **INFERENCE F-07.b:** the absence of Offers A–D suggests those offers are associated with existing rather than newly acquired customers. **This is an inference from absence.** The dataset has no offer date, eligibility rule or assignment logic, so no conclusion about offer policy is available.
- **INFERENCE F-07.c:** the declining month-1-to-3 rates are **consistent with** either genuinely elevated first-month risk or with differing observation exposure across the three groups. **These two explanations cannot be distinguished with a single-quarter snapshot.**
- **INFERENCE F-07.d:** early-life churn and established-base churn plausibly represent different phenomena warranting different treatment. *This was the predefined rationale for separating them (C-3); this finding is consistent with it, not proof of it.*

## Limitations and caveats

- **⚠️ This population must never be merged into the opening-cohort churn KPI.** Doing so would break the symmetry that C-3 exists to preserve.
- **Not a survival analysis.** F-07.2's monthly rates reflect groups with differing exposure windows. **Reading them as a retention curve would be a methodological error.**
- **Two cells below threshold** (n = 26, n = 22 at F-07.7). Their rates are not reportable and must be collapsed or omitted from any narrative, not quoted.
- **No onboarding data.** The dataset contains no activation, installation, complaint, service-quality or first-contact records. **Nothing here identifies an onboarding problem** — that would be an unsupported causal claim.
- **No acquisition channel or campaign data.** Whether these customers differ by source is unobservable.
- **Revenue at risk correctly includes this cohort** (C-2). It is excluded from the churn-*rate* denominator, not from revenue.
- **Single quarter, fictional data.**

## Business implication

Approximately a third of churn events and a quarter of recurring revenue at risk sit in a population that behaves very differently from the established base. **This warrants separate analytical attention and, plausibly, separate ownership** — it is not the same question as base retention. **No specific cause has been identified and none should be asserted.**

---
---

# Cross-finding consistency checks

Every check below uses only figures quoted in the outputs above.

| # | Check | Expected | Observed | Status |
|---|---|---|---|---|
| X-01 | Cohort populations sum to the base | 5,992 + 1,051 = 7,043 | **7,043** | ✅ |
| X-02 | Churn counts sum to the total | 1,272 + 597 = 1,869 | **1,869** | ✅ |
| X-03 | Primary churn KPI unchanged across F-01, F-05 scope rate derivation, A-VAL-02a | 21.23% | **21.23%** | ✅ |
| X-04 | Period-end comparison rate unchanged | 26.54% | **26.54%** | ✅ |
| X-05 | Recurring revenue at risk sums across cohorts | 1,232,425.80 + 437,144.40 = 1,669,570.20 | **1,669,570.20** | ✅ |
| X-06 | Long-distance revenue at risk sums across cohorts | 357,222.84 + 162,380.88 = 519,603.72 | **519,603.72** | ✅ |
| X-07 | F-03 opening-cohort decile populations sum | 565+572+535+570+588+545+613+636+670+698 | **5,992** | ✅ |
| X-08 | F-03 opening-cohort decile churn counts sum | 23+22+81+102+76+152+197+188+261+170 | **1,272** | ✅ |
| X-09 | F-03 tier populations sum (opening cohort) | 2,004 + 2,316 + 1,672 | **5,992** | ✅ |
| X-10 | F-03 High-tier population matches F-05 scope | 2,004 both | **2,004** | ✅ |
| X-11 | F-03 High-tier churned matches F-05 scope rate | 619 / 2,004 = 30.89% | **30.89%** | ✅ |
| X-12 | F-04 primary cells sum to opening cohort | 5,992 | **5,992** | ✅ |
| X-13 | F-04 sensitivity cells sum to all customers | 7,043 | **7,043** | ✅ |
| X-14 | Each F-05 lens partitions the High tier | 2,004 × 7 lenses | **2,004 each** | ✅ |
| X-15 | F-07 cohort revenue share | 437,144.40 / 1,669,570.20 = 26.18% | **26.18%** | ✅ |
| X-16 | F-07 share of all churn | 597 / 1,869 = 31.94% | **31.94%** | ✅ |
| X-17 | F-04 divergence sums to zero per scope | 0 | **0, 0** | ✅ |

## Methodological compliance checks

| Check | Status |
|---|---|
| **Period-end rate is never substituted for the primary KPI** — it is labelled a reconciliation measure at every appearance (F-01.2, X-04) | ✅ |
| **F-04 respects the locked A-07 designation** — primary is opening cohort, all-customers is labelled sensitivity only, and the sensitivity result is not promoted despite differing at the top rank | ✅ |
| **Early-life churn is not added to the opening-cohort numerator** — the 597 appear only in F-07 and in all-customer totals, never in the 1,272 | ✅ |
| **Revenue at risk correctly includes all churned customers** — the opening-cohort exclusion is applied to the churn *rate* only, never to revenue (F-01.4/F-01.5, X-05) | ✅ |
| **All seven driver lenses reported**, including L5 (max index difference 0.12) and L7 (0.06) | ✅ |
| **No causal language.** Every relational statement uses "is associated with", "coincides with", "is concentrated in" or "warrants investigation" | ✅ |
| **No recommendation, budget, ROI figure or prescribed intervention appears anywhere** | ✅ |
| **No benchmark invented** — B-5 and B-6 remain open and are stated as open | ✅ |
| **No currency symbol used** anywhere | ✅ |
| **Small cells surfaced, not dropped** — five caveat-flagged cells in F-05 and two below-threshold cells in F-07 are named explicitly | ✅ |

## Contradictions found

**None.** All seventeen arithmetic reconciliations hold exactly, and no finding contradicts another.

One point of **apparent** tension is worth stating plainly rather than leaving for a reader to notice: **F-01.9** shows churned customers carrying above-average recurring revenue overall, while **F-03.9** shows churned and retained High-tier customers having near-identical revenue (98.07 vs 99.48). These are consistent, not contradictory — F-03.10 and F-03.11 show the revenue-weighted effect arising in the Mid and Low tiers, where leavers carry higher revenue than stayers. Any narrative must reflect this rather than the simpler claim that "we lose our most valuable customers".

---

# Communication readiness

| Finding | Rating | Reason |
|---|---|---|
| **F-01** | ✅ **READY** | Clean counts and rates, all reconciled, all validated. The only discipline required is keeping the 21.23% / 26.54% distinction explicit and never pairing a rate with a mismatched revenue figure |
| **F-02** | ✅ **READY** | Straightforward descriptive distribution, fully validated. Requires stating the decile convention (1 = lowest) on every output, since both conventions exist in practice |
| **F-03** | ⚠️ **READY WITH CAVEAT** | All cells reportable and validated. **Caveat:** the pattern is non-monotonic and the decile-10 dip is unexplained. It must be presented as observed shape, not as a value–risk relationship, and the F-01.9 / F-03.9 relationship must be handled as described above |
| **F-04** | ⚠️ **READY WITH CAVEAT** | Fully validated, and the A-07 designation is now visible on every row. **Caveat:** the project's central construct returns a near-null result — maximum divergence of one rank. This is a legitimate finding and must be reported as such rather than presented as though divergence had been demonstrated. The ordinal index must never be quoted without its magnitudes |
| **F-05** | ⚠️ **READY WITH CAVEAT** | All seven lenses present, each partitioning to 2,004. **Caveats:** five cells require `n` to be stated; L4's DSL rate rests on a single churned customer; **L6's direction is unestablished and is the most easily misread item in the register**; structural absences must not be read as zero results |
| **F-06** | ⚠️ **READY WITH CAVEAT** | Validated, zero orphans. **Caveat:** four of seven lenses show little differentiation between scopes. This partially realises charter risk R-04 and weakens a stated project premise. It must be reported plainly, and L4's exception rests partly on small cells |
| **F-07** | ⚠️ **READY WITH CAVEAT** | Validated and correctly separated from the opening cohort. **Caveats:** two cells below threshold must not be quoted; the monthly rates are **not** a survival curve; and no onboarding cause may be asserted — the dataset contains no onboarding data of any kind |

**No finding is rated NEEDS REVIEW.** All seven are supported by validated outputs with complete evidence chains.

---

## Recommended next step

Before any narrative is written, **which findings carry the story and which are context** should be settled, because two results push against the project's original framing:

- **F-04** returns a near-null divergence — the central construct did not find what it was designed to detect
- **F-06** shows most driver dimensions behaving similarly in the High tier and base-wide

Both are legitimate, well-evidenced outcomes. How prominently they feature is a judgement about honesty versus narrative convenience, and is settled deliberately in advance rather than while drafting.

**Still open and not to be closed by assumption:** B-5 (a sourced margin range, required before AQ-07) and B-6 (a churn benchmark source, or the KPI ships without one and says so).
