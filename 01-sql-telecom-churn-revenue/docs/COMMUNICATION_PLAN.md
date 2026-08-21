# Communication Plan

## Project 01 — Telecommunications Revenue Retention: Prioritising Retention Investment by Revenue at Risk

**Stage:** 6 — COMMUNICATE
**Status:** ✅ **APPROVED — governing specification for the COMMUNICATE stage**
**Approved:** 20 August 2026, before any chart was built
**Transcribed to file:** 21 August 2026

---

## 0. Provenance of this document

**This specification was proposed and approved before any chart existed.** It was written from
`docs/FINDING_EVIDENCE_REGISTER.md` and the committed outputs in `analysis/query_results/`, at a
point when the project contained zero figures — a fact independently confirmed by a read-only audit
of the project tree.

This file is a **transcription of that approved specification**, committed after the build to close
a reproducibility gap in the repository. It is not a retrospective redesign. No chart specification,
classification, exclusion or principle below has been revised in the light of what the finished
figures turned out to look like.

Three **presentation** deviations between this specification and the delivered figures are recorded
honestly in **§10**. None of them changed a value, a population, a source or a message.

### Standing constraints inherited by every artefact in this stage

- **Currency is unknown** (profiling check P-15). Monetary values are *currency units*. No symbol.
- **The data is fictional** (IBM sample telco, 7,043 customers, California, Q3).
- **Single observation window.** No trend. Tenure is not a time axis.
- **No retention activity data.** No campaign, offer-made, contact or save records exist.
- **Excluded fields:** `Satisfaction Score`, `Churn Score`, `CLTV`, `Churn Reason`, `Churn Category`.
- **PREPARE and ANALYSE are locked.** This stage modifies no SQL, view, KPI, population, cut point,
  segmentation rule, ranking or validation expectation.

---

## 1. The story the evidence supports

The project was designed around a premise: **that high-value customers are a distinct population,
and that prioritising by revenue would materially change where retention attention goes.** Three
independent, pre-registered tests of that premise returned weak or null results.

| Test | Result | Source |
|---|---|---|
| Is revenue concentrated enough for value targeting to have leverage? | Moderately only — top decile holds **16.71%** | F-02.1 |
| Does a revenue-led ranking differ from a churn-led one? | Near-null — max divergence **1 rank**, top two identical | F-04.5, F-04.2/.3 |
| Does the High tier have a distinctive driver profile? | Not for **four of seven** lenses | F-06.3, F-06.4 |

Meanwhile one dimension does a large amount of work. Contract type separates churn from **54.59%**
(Month-to-Month) to **5.26%** (Two Year) *within the High tier alone* (F-04.10, F-05.1), and
**78.93%** of opening-cohort recurring revenue at risk sits in two of nine segment cells, both
Month-to-Month (F-04.4).

> **INTERPRETATION.** The evidence points away from value tier as the organising dimension and
> toward contractual commitment. This is not a rescue of a failed project — it is a cleaner result
> than the original hypothesis would have produced, reached by a pre-registered test that was
> allowed to fail.

> **LIMITATION.** Contract type is *associated with* churn rate. Nothing establishes causation.
> It is heavily confounded with tenure (F-05 L2 declines monotonically, 71.57% → 15.52%) and with
> customer characteristics the dataset does not observe. Selection into long contracts is plausibly
> non-random. **This limitation must appear wherever contract type is discussed** — it is the single
> most over-readable finding in the project.

**Approved headline framing:**

> *Retention exposure in this base is organised by contractual commitment, not by customer value.
> A pre-registered value-versus-risk prioritisation test returned a near-null result; the
> segmentation that does separate is contract type, and revenue at risk is concentrated accordingly.*

**Approved secondary story (separate, not subordinate):**

> *A third of churn events and a quarter of recurring revenue at risk sit in customers acquired
> within the observation quarter — a population that behaves so differently (56.80% vs 21.23%) that
> it is a different analytical question.* (F-07.1, F-07.3, F-07.4)

---

## 2. Finding classification

### 2.1 Primary — carry the story

| ID | Finding | Why primary |
|---|---|---|
| **F-04** (contract dimension) | 78.93% of opening-cohort revenue at risk in two Month-to-Month cells; contract separates 54.59% / 19.19% / 5.26% within the High tier | Largest effect in the project, on the primary population, all nine cells reportable |
| **F-01** | 21.23% opening-cohort churn; 1,232,425.80 revenue at risk; revenue retention 74.32% below customer retention 78.77% | Sizes the exposure. F-01.9 is the analytically substantive fact |
| **F-07** | 1,051 acquired, 597 churned (56.80%) = 31.94% of all churn, 26.18% of revenue at risk | Large, clean, structurally separate. Answers a question on its own |

### 2.2 Supporting — context and constraint

| ID | Finding | Role |
|---|---|---|
| **F-02** | Revenue moderately concentrated; top decile 16.71%, High tier 45.71% | Frames what value targeting could achieve; bounds the primary claim |
| **F-03** | Non-monotonic churn by decile; peak at decile 9 (38.96%), dip at decile 10 (24.36%) | Answers BQ-03 directly and refines F-01.9 |
| **F-05** | Seven lenses, all reported; L1/L2/L6 widest, L5/L7 narrowest | The diagnostic detail behind the primary claim |

### 2.3 Negative / near-null — reported prominently, not buried

| ID | Result | Approved placement |
|---|---|---|
| **F-04 divergence index** | Max divergence 1 rank; top two segments identical under both rankings; index sums to 0 | **Named section with an honest title.** Presented as the tested hypothesis that did not hold. Must **not** be described as "some divergence observed" |
| **F-06** | L1 max index difference 0.15, L5 0.12, L7 0.06 — four of seven lenses barely differentiate | **Named section**, explicitly linked to charter risk R-04, which anticipated it in writing before results were seen |
| **F-05 L7** | Referral behaviour, 13.75 pp spread, narrowest lens | Reported inside the lens panel at its true magnitude, not omitted |
| **F-07.11** | Referral in early-life cohort: indices 1.01 / 0.96 | Reported as effectively null |
| **F-03.9** | High-tier churned ARPU 98.07 vs retained 99.48 — near-parity | Reported; it is the fact that prevents "we lose our most valuable customers" being said |

> This is deliberate. **The null results are a named strength of the project, not a caveat section at
> the end.** A portfolio that only shows findings that worked demonstrates less than one that shows a
> hypothesis being tested and failing.

### 2.4 Caveats and limitations — travel with the claim

**Approved rule: caveats appear adjacent to the claim, never collected only in a footer.** A
limitations section still exists, but no claim may rely on it.

| Caveat | Attaches to | Must appear |
|---|---|---|
| Currency unknown (P-15) — never £/$/USD/GBP | Every monetary figure | Every axis, every table header |
| Fictional data (IBM sample, 7,043 customers, California, Q3) | Every finding | Every figure |
| Single quarter — no trend; tenure is not a time axis (R-01) | F-01, F-03, F-05 L2, F-07.2 | Wherever tenure or month appears |
| 21.23% (opening cohort) vs 26.54% (all customers) never interchanged; never pair a rate with a mismatched revenue figure (C-2 / C-3) | F-01 | Every KPI display |
| Five caveat-flagged cells, n = 36–80; **DSL rate rests on one churned customer** | F-05 L3, L4, L5, L6 | On-chart `n` labels |
| Two below-threshold cells (n = 26, n = 22) not quotable | F-07.7 | Collapsed or omitted, never plotted as rates |
| **L6 offer direction unestablished** — offers may be extended *to* at-risk customers | F-05 L6 | Mandatory adjacent caveat |
| F-07.2 monthly rates are **not** a survival curve | F-07 | Mandatory adjacent caveat |
| No retention activity, onboarding, channel or campaign data exists | F-04, F-07 | Wherever "what the business did" could be inferred |
| No significance testing anywhere | F-06 | On the comparison chart |
| Structural absences ≠ zero results (L4 "No internet", L5 "None") | F-05 | Lens panel note |
| **B-5 and B-6 open** — no margin, no external benchmark | F-01, AQ-07 | Stated as open, never closed by assumption |

---

## 3. Approved narrative structure

Five artefacts, each with a defined reader. **None was authorised for creation by this plan** — the
chart set was the first and only build step approved.

| # | Artefact | Reader | Purpose |
|---|---|---|---|
| D-1 | `README.md` | Recruiter, 90 seconds | Problem, method, headline result including the null, tooling, links |
| D-2 | `docs/EXECUTIVE_SUMMARY.md` | Business stakeholder, 1 page | The exposure, where it sits, what was tested and failed, what is unresolved |
| D-3 | `docs/CASE_STUDY.md` | Technical reviewer / hiring manager | The full walkthrough — the substantial piece |
| D-4 | `docs/STAKEHOLDER_STORY.md` | Narrative demonstration | The same evidence told as a decision conversation |
| D-5 | `docs/METHODOLOGY.md` | Auditor | Pipeline, locked decisions, validation gates, exclusions |

**Approved case-study arc:**

1. The question and why it was reframed — from churn minimisation to retention prioritisation
2. The data, and what it cannot support — exclusions, `Satisfaction Score` contamination, currency, single quarter
3. Pre-registration — cut points, segments, thresholds and expectations fixed **before results were seen**; A-07 locked before the divergence result existed
4. The exposure — F-01, ending on F-01.9
5. Is targeting by value viable? — F-02
6. Where does churn sit in the value range? — F-03
7. **The test that failed** — F-04 divergence, near-null, with the A-07 sensitivity test
8. What does separate — F-04.10 and F-05 L1/L2/L6, with confounding stated
9. **The second test that failed** — F-06 and charter risk R-04
10. A different population — F-07
11. What this cannot tell you — limitations, B-5, B-6, AQ-07
12. What I would do next — investigation directions only, no recommendations

> Sections 7 and 9 are **named, prominent sections with honest titles, positioned mid-arc** where
> they carry weight — not appended at the end where they would read as apology.

---

## 4. Approved numbering system

```
BQ-nn  Business question       (charter, locked)
 └─ AQ-nn  Analytical question     (ANALYSE_PLAN, locked)
     └─ F-nn     Finding group          (register, locked)
         └─ F-nn.n   Observed fact  — with scope + source file
             └─ E-nn.n   Evidence pointer → exact output file + block
                 └─ INT-nn.n  Interpretation  (labelled)
                     └─ INF-nn.x  Inference   (labelled)
                         └─ LIM-nn.x  Limitation
                             └─ IMP-nn   Business implication
                                 └─ CH-nn  Chart (if any)
```

| BQ | AQ | AQ type | F | Charts |
|---|---|---|---|---|
| BQ-01 *How much ARR are we losing?* | AQ-01 | Descriptive | **F-01** | CH-01, CH-02 |
| BQ-02 *Concentrated or spread?* | AQ-02 | Descriptive | **F-02** | CH-03 |
| BQ-03 *Most valuable or least?* | AQ-03 | Diagnostic | **F-03** | CH-04, CH-05 |
| BQ-03, BQ-04 *Where would prioritisations diverge?* | AQ-04 | Prioritisation | **F-04** | CH-06, CH-07 |
| BQ-05 *What distinguishes leavers?* | AQ-05 | Diagnostic | **F-05** | CH-08 |
| BQ-05 *Are high-value drivers different?* | AQ-06 | Diagnostic | **F-06** | CH-09 |
| BQ-01 *(C-3 separation)* | — | Descriptive | **F-07** | CH-10, CH-11 |
| BQ-06 *What is it worth spending?* | **AQ-07** | Scenario | — | **None — blocked on B-5** |

> **AQ-07 / BQ-06 is shown in the chain as an open item with no finding attached.** An unanswered
> question shown as unanswered is stronger than a question quietly dropped.

---

## 5. THE A-07 DECISION — LOCKED (D-21)

> ### PRIMARY RESULT — Opening cohort
> ### SENSITIVITY ANALYSIS ONLY — All customers

This designation was **locked before any divergence result was seen**. It is carried as an explicit
`result_designation` column on every row of `analyse_04_divergence.txt` (decision D-22), so it is
visible in the evidence artefact itself and not merely in a section header.

**Binding rules for this stage:**

1. **CH-06 and CH-07 filter on `result_designation = 'PRIMARY RESULT - Opening cohort'`** and carry
   **PRIMARY RESULT — Opening cohort** in the chart title.
2. **The sensitivity analysis is never presented as the primary result**, and is never plotted at
   all under this plan (see §7).
3. Where the sensitivity result is described in prose, it is labelled *Sensitivity analysis only*.
4. The sensitivity result **must not be promoted despite differing at the top rank**. Under all
   customers, Mid / Month-to-Month takes rank 1 by revenue at risk while High / Month-to-Month
   takes rank 1 by churn rate. Seven of nine cells are unchanged.

---

## 6. Chart specifications — CH-01 to CH-11

Eleven charts. **Every metric is a column already present in a committed output. No chart requires a
new calculation.**

**Universal requirements on every chart:** currency never symbolised · fictional-data note in the
caption · population scope stated below the axes · `n` shown for any cell below 100 ·
`_portfolio/STYLE_GUIDE.md` validated 8-colour categorical palette · scatter capped at 3 series ·
caveats adjacent to the claim.

### 6.0 Figure manifest

The chart ID is the primary key throughout this stage. Filenames are recorded here so the plan, the
figures, the audit CSVs and `COMMUNICATION_VALIDATION.md` are addressable by either.

| Chart ID | Figure file (`outputs/figures/`) | Audit CSV (`outputs/chart_data/`) | Source output (`analysis/query_results/`) · block |
|---|---|---|---|
| CH-01 | `CH01_revenue_at_risk_opening_cohort.png` | `CH-01_data.csv` | `analyse_01_base_position.txt` · 3 (with block 2) |
| CH-02 | `CH02_revenue_vs_customer_retention.png` | `CH-02_data.csv` | `analyse_01_base_position.txt` · 3 |
| CH-03 | `CH03_revenue_concentration_pareto.png` | `CH-03_data.csv` | `analyse_02_revenue_concentration.txt` · 1 |
| CH-04 | `CH04_churn_by_revenue_decile.png` | `CH-04_data.csv` | `analyse_03_churn_by_decile.txt` · 1 (reference line from `analyse_01_base_position.txt` · 1) |
| CH-05 | `CH05_arpu_churned_vs_retained_by_tier.png` | `CH-05_data.csv` | `analyse_03_churn_by_decile.txt` · 3 |
| CH-06 | `CH06_divergence_primary_opening_cohort.png` | `CH-06_data.csv` | `analyse_04_divergence.txt` · 2 (PRIMARY rows) |
| CH-07 | `CH07_revenue_at_risk_by_segment.png` | `CH-07_data.csv` | `analyse_04_divergence.txt` · 2 (PRIMARY rows) |
| CH-08 | `CH08_driver_lenses_high_tier.png` | `CH-08_data.csv` | `analyse_05_drivers_high_value.txt` · 1 |
| CH-09 | `CH09_high_tier_vs_base_wide_drivers.png` | `CH-09_data.csv` | `analyse_06_drivers_comparison.txt` · 1 (with block 2) |
| CH-10 | `CH10_early_life_contribution.png` | `CH-10_data.csv` | `analyse_07_early_life_churn.txt` · 3 (with block 1) |
| CH-11 | `CH11_early_life_composition.png` | `CH-11_data.csv` | `analyse_07_early_life_churn.txt` · 2 |

---

### CH-01 — Annual recurring revenue at risk, opening cohort

| | |
|---|---|
| **Proposed title** | Annual recurring revenue at risk — opening cohort |
| **BQ / AQ** | BQ-01 / AQ-01 |
| **Finding evidence** | F-01.4, F-01.7, F-01.9, F-01.10 |
| **Source file** | `analysis/query_results/analyse_01_base_position.txt`, blocks 2 and 3 |
| **Population scope** | Opening cohort (tenure ≥ 4 months), n = 5,992, of whom 1,272 churned |
| **Chart type** | Stacked single bar (part-to-whole) |
| **Communication purpose** | Size the exposure. Establish the magnitude that any prioritisation discussion is about |
| **Required annotations** | Retained and at-risk amounts with their percentages; scope line |
| **Caveats / limitations** | Recurring revenue only (C-2) — long-distance at risk of 357,222.84 excluded and **material, not irrelevant**. Annualisation is convention A-03 (supported by P-07, median ratio 1.0000) and remains forward-looking. Currency unknown |
| **Class** | **Descriptive** |
| **Merit note** | Recorded at approval as **the weakest of the eleven** — a single stacked bar carries little a KPI table does not. Approved to build with a decision point to drop it on merit after the other ten were seen. It was retained |

---

### CH-02 — Revenue retention vs customer retention

| | |
|---|---|
| **Proposed title** | Revenue retention sits below customer retention — opening cohort |
| **BQ / AQ** | BQ-01 / AQ-01 |
| **Finding evidence** | **F-01.9** |
| **Source file** | `analysis/query_results/analyse_01_base_position.txt`, block 3 |
| **Population scope** | Opening cohort, n = 5,992 |
| **Chart type** | Paired horizontal bar, gap annotated |
| **Communication purpose** | Show that customers who left carried, on average, higher recurring revenue than those who stayed — the fact that makes a revenue view differ from a customer-count view |
| **Required annotations** | Both percentages; the gap shown **with its arithmetic** (78.77 − 74.32) |
| **Caveats / limitations** | **OBSERVED FACT, arithmetic not assumption** — if leavers had been an average slice, the percentages would coincide. **Must ship with CH-05:** the effect arises in Mid and Low tiers; High tier is near-parity (98.07 vs 99.48). **This chart alone does not support "we lose our most valuable customers."** The gap figure is the difference of the two displayed percentages, not a separate measure |
| **Class** | **Comparative** |

---

### CH-03 — Revenue concentration (Pareto)

| | |
|---|---|
| **Proposed title** | Revenue share by monthly-charge decile — decile 1 = lowest |
| **BQ / AQ** | BQ-02 / AQ-02 |
| **Finding evidence** | F-02.1, F-02.3, F-02.7, F-02.8 |
| **Source file** | `analysis/query_results/analyse_02_revenue_concentration.txt`, block 1 |
| **Population scope** | All customers, n = 7,043 |
| **Chart type** | Column + cumulative line (combo) |
| **Communication purpose** | Establish that concentration is **moderate, not sharp** — bounding how much difference value-based targeting could make |
| **Required annotations** | **Decile convention stated on the chart** (both conventions exist in practice); per-decile shares; the top-decile and High-tier cumulative figures |
| **Caveats / limitations** | Deciles are equal-frequency (704–705 each), not equal-value; boundary ties split by deterministic `NTILE` tie-break (V-11 / D-20). Recurring revenue only (C-2) — not total revenue concentration. Static snapshot. Currency unknown |
| **Class** | **Descriptive** |

---

### CH-04 — Churn rate by revenue decile

| | |
|---|---|
| **Proposed title** | Churn is not monotonic in customer value — opening cohort |
| **BQ / AQ** | BQ-03 / AQ-03 *(AQ type: diagnostic)* |
| **Finding evidence** | F-03.1, F-03.2, F-03.3, F-03.4 |
| **Source file** | `analysis/query_results/analyse_03_churn_by_decile.txt`, block 1 (`population_scope = opening_base`). The 21.23% reference line is read from `analyse_01_base_position.txt`, block 1 (`scope = opening_base`, `churn_rate_pct`) |
| **Population scope** | Opening cohort, n = 5,992. All ten decile cells reportable (n = 535–698) |
| **Chart type** | Column chart with a horizontal reference line at the 21.23% scope rate |
| **Communication purpose** | Answer BQ-03 directly: losses concentrate in the **upper-middle** of the value distribution, not at either extreme |
| **Required annotations** | Scope-rate reference line labelled; all ten rates; `n` per decile; **decile-9 peak and decile-10 dip both called out**, with the dip stated as unexplained |
| **Caveats / limitations** | **ASSOCIATION ONLY** — nothing establishes that charge level causes any churn outcome. Single-dimension cut, no multivariate control; charge level is related to contract type, service mix and tenure. Deciles are relative, not absolute price bands. The decile-10 dip **warrants investigation, not explanation** (INF-03.a) |
| **Class** | **Comparative** (against scope rate) |

---

### CH-05 — ARPU of leavers vs stayers, by tier

| | |
|---|---|
| **Proposed title** | Monthly recurring revenue, churned vs retained, by value tier |
| **BQ / AQ** | BQ-03 / AQ-03 |
| **Finding evidence** | **F-03.9, F-03.10, F-03.11** |
| **Source file** | `analysis/query_results/analyse_03_churn_by_decile.txt`, block 3 (`scope = opening_base`) |
| **Population scope** | Opening cohort; High 2,004 · Mid 2,316 · Low 1,672 |
| **Chart type** | Grouped bar, 3 tiers × 2 outcomes |
| **Communication purpose** | **Corrective.** Locate where the revenue-weighted effect of CH-02 actually arises — Mid and Low tiers — and show the High tier is near-parity |
| **Required annotations** | Six values; `n` on every bar; the High-tier near-parity called out |
| **Caveats / limitations** | **This chart exists to prevent the over-reading CH-02 invites.** The register's apparent tension (F-01.9 vs F-03.9) must be resolved in the caption, not left to the reader. Mean monthly recurring revenue; long-distance excluded (C-2). Currency unknown |
| **Class** | **Comparative** |

---

### CH-06 — The divergence test (the null result)

| | |
|---|---|
| **Proposed title** | Rank by churn rate vs rank by revenue at risk — nine segments |
| **BQ / AQ** | BQ-04 / AQ-04 *(AQ type: prioritisation)* |
| **Finding evidence** | **F-04.5, F-04.6, F-04.7, F-04.8** |
| **Source file** | `analysis/query_results/analyse_04_divergence.txt`, block 2, rows where `result_designation = 'PRIMARY RESULT - Opening cohort'` |
| **Population scope** | **PRIMARY RESULT — Opening cohort.** Nine pre-registered P1 cells (value tier × contract type), all reportable (n = 442–1,182) |
| **Chart type** | Slope chart — two ranked axes, one line per cell |
| **Communication purpose** | **Show that almost nothing moves.** Present the project's central construct returning a near-null result, as a finding in its own right |
| **Required annotations** | **PRIMARY RESULT — Opening cohort** in the title. Count of non-moving segments. Non-moving cells muted, moving cells accented. Title states the null in plain words — **not** "limited divergence observed" |
| **Caveats / limitations** | **THE INDEX IS ORDINAL** — ±1 conveys rank order only and **must never be quoted without magnitudes**; magnitudes live in CH-07. Divergence index sums to zero (gate A-VAL-10). **A-07 locked:** the all-customers version is sensitivity only and is not plotted. **Nine cells is coarse;** finer-grain divergence was **not tested**, and testing it now would be a post-hoc specification change that pre-registration forbids (INF-04.c). Fictional data — this shows what the method returns, not that misallocation does or does not exist for any real operator |
| **Class** | **Comparative** |

---

### CH-07 — Where revenue at risk concentrates

| | |
|---|---|
| **Proposed title** | Recurring revenue at risk by segment — 78.93% in two Month-to-Month cells |
| **BQ / AQ** | BQ-04 / AQ-04 |
| **Finding evidence** | **F-04.2, F-04.3, F-04.4, F-04.10** |
| **Source file** | `analysis/query_results/analyse_04_divergence.txt`, block 2, PRIMARY rows only |
| **Population scope** | **PRIMARY RESULT — Opening cohort.** Nine P1 cells |
| **Chart type** | Horizontal bar, sorted descending by revenue at risk, coloured by contract type |
| **Communication purpose** | Carry the **positional** fact that the ordinal index cannot: exposure concentrates in two of nine segments, both Month-to-Month. This is what replaces divergence as the substantive result |
| **Required annotations** | **PRIMARY RESULT — Opening cohort** in the title. Per-segment amount, share of scope, churn rate and `n`. The 78.93% concentration stated **with its arithmetic** (45.95 + 32.98) |
| **Caveats / limitations** | **ASSOCIATION ONLY** — contract type is associated with these rates; nothing establishes causation, and contract choice is plausibly related to unobserved characteristics. **CONFOUNDED WITH TENURE** (see CH-08, lens L2); no figure isolates an independent contribution. **No retention activity data** — this describes where exposure sits, not what the business did. Currency unknown |
| **Class** | **Descriptive** |

---

### CH-08 — Seven driver lenses, High value tier

| | |
|---|---|
| **Proposed title** | Churn index by segment, all seven lenses — High value tier |
| **BQ / AQ** | BQ-05 / AQ-05 *(AQ type: diagnostic)* |
| **Finding evidence** | F-05.1 to F-05.12 |
| **Source file** | `analysis/query_results/analyse_05_drivers_high_value.txt`, block 1 |
| **Population scope** | Opening cohort × High value tier (deciles 8–10), **n = 2,004**, scope churn rate **30.89%**. Each lens partitions the tier to exactly 2,004 (gate A-VAL-11) |
| **Chart type** | Small-multiple dot plot, one panel per lens, reference line at index 1.00 |
| **Communication purpose** | Show which dimensions separate within the High tier and **by how much**, including the ones that barely separate |
| **Required annotations** | **All seven lenses, all 24 cells.** Panels ordered by spread, **but L5 and L7 shown at their true magnitudes on identical axes — not omitted, not rescaled.** Rate and `n` on every cell. Five `caveat_required` cells marked and showing `n`: L3 Mailed Check (36), L4 Cable (74), L4 DSL (80), L5 Light (42), L6 Offer E (64). **L4 DSL's 1.25% annotated as resting on one churned customer.** **Mandatory L6 caveat: direction unestablished** |
| **Caveats / limitations** | All seven are **single-dimension cuts with no multivariate control**; L1, L2, L5 and L6 are interrelated. **L6 direction unknown** — offers may be extended to customers already considered at risk, in which case the association runs opposite to the intuitive reading; **the most easily misread item in the register**. **Structural absences are not zero results** — L4 "No internet" and L5 "None (0)" do not appear by construction. No causal claims. `Churn Reason` was structurally excluded, so no lens is outcome-contaminated |
| **Class** | **Comparative** |

---

### CH-09 — High-value drivers vs base-wide drivers (the second null)

| | |
|---|---|
| **Proposed title** | Do high-value churn drivers differ from base-wide drivers? For four of seven lenses, barely. |
| **BQ / AQ** | BQ-05 / AQ-06 *(AQ type: diagnostic)* |
| **Finding evidence** | **F-06.1 to F-06.6** |
| **Source file** | `analysis/query_results/analyse_06_drivers_comparison.txt`, blocks 1 and 2 |
| **Population scope** | Opening cohort. High value tier (n = 2,004) vs **base-wide (opening cohort, all tiers, n = 5,992)**. Zero orphans (gate A-VAL-14) |
| **Chart type** | Dumbbell / paired-dot, one row per segment, grouped by lens, lenses ordered by `max_abs_index_difference` |
| **Communication purpose** | Present a **largely null result** — for most dimensions the High tier is not characterised by a distinctive driver profile, weakening a stated project premise |
| **Required annotations** | Title leads with the null. Each lens labelled with its `max |Δ|` — L4 0.67, L6 0.52, L2 0.49, L3 0.36, L1 0.15, L5 0.12, L7 0.06. **All lens headers styled identically so weak lenses are not visually de-emphasised.** Small High-tier cells marked. **Charter risk R-04 quoted verbatim** to show the outcome was anticipated in writing before results existed |
| **Caveats / limitations** | **NO SIGNIFICANCE TESTING** — descriptive index differences, no confidence interval; "large" and "small" are relative to each other, not to any threshold. **INDICES COMPARED, NOT RAW RATES** — this normalises for differing base rates; comparing raw rates would look more dramatic and would mislead. **THE SCOPES OVERLAP BY CONSTRUCTION** — part versus whole, so differences are attenuated. L4's exception rests partly on cells of n = 74 and n = 80 |
| **Class** | **Comparative** |

---

### CH-10 — Early-life churn contribution

| | |
|---|---|
| **Proposed title** | In-period acquisitions: 31.94% of churn events, 26.18% of revenue at risk |
| **BQ / AQ** | BQ-01 / C-3 separation |
| **Finding evidence** | **F-07.1, F-07.3, F-07.4, F-07.12** |
| **Source file** | `analysis/query_results/analyse_07_early_life_churn.txt`, blocks 1 and 3; `analyse_01_base_position.txt`, block 1 |
| **Population scope** | In-period acquisitions (tenure ≤ 3 months), **n = 1,051**, of whom 597 churned (56.80%), shown against the opening cohort (n = 5,992, 1,272 churned, 21.23%) |
| **Chart type** | Two stacked share bars — churn events, and recurring revenue at risk |
| **Communication purpose** | Establish the size of the second story: a materially different population carrying a third of churn events and a quarter of revenue at risk |
| **Required annotations** | Both cohorts labelled with their tenure definitions. Counts and amounts alongside shares. Complement share disclosed as a complement |
| **Caveats / limitations** | **⚠️ THESE 597 ARE NOT IN THE PRIMARY CHURN KPI NUMERATOR AND MUST NEVER BE ADDED TO IT** (C-3). **The chart shows shares of a total, never a combined rate.** Revenue at risk correctly includes this cohort (C-2) — the opening-cohort restriction applies to the churn *rate* only. Reconciles at register checks X-02, X-05, X-15, X-16. Currency unknown |
| **Class** | **Comparative** |

---

### CH-11 — Composition of in-period acquisitions

| | |
|---|---|
| **Proposed title** | Contract and offer composition of in-period acquisitions |
| **BQ / AQ** | BQ-01 / C-3 separation |
| **Finding evidence** | **F-07.6, F-07.7, F-07.10** |
| **Source file** | `analysis/query_results/analyse_07_early_life_churn.txt`, block 2 |
| **Population scope** | In-period acquisitions (tenure ≤ 3 months), n = 1,051 |
| **Chart type** | Two horizontal composition bars |
| **Communication purpose** | Show the structural character of the cohort: almost entirely Month-to-Month, and only two offer categories present |
| **Required annotations** | 95.43% Month-to-Month. **One Year (n = 26) and Two Year (n = 22) collapsed to a single labelled band, "below the n = 30 reporting threshold — rates not reportable"; no rate shown for them.** Absence of Offers A–D stated |
| **Caveats / limitations** | **BELOW-THRESHOLD CELLS COLLAPSED, NOT QUOTED** — bar width reflects counts only. **INFERENCE, NOT OBSERVATION:** the absence of Offers A–D suggests those offers are associated with existing rather than newly acquired customers — an inference from absence; the dataset has no offer date, eligibility rule or assignment logic (INF-07.b). The Month-to-Month concentration is consistent with new customers starting on rolling terms, but **the data does not establish acquisition practice**. **NO ONBOARDING CAUSE MAY BE ASSERTED** — no activation, installation, complaint, service-quality, first-contact, acquisition-channel or campaign records exist |
| **Class** | **Descriptive** |

---

## 7. Deliberate exclusions

Five charts were specified as **not to be built**. All five remain unbuilt.

### 7.1 F-07.2 monthly rate curve — EXCLUDED (methodological)

The three monthly rates (month 1 **61.99%**, month 2 **51.68%**, month 3 **47.00%**) are **not a
survival curve.** Each month is a different acquisition group observed for a different length of time
within a single quarter — not one group tracked over time. Plotting them as a descending line would
invite exactly the reading the register warns against, and the register names it a methodological
error. The figures remain quotable in prose **with their caveat**; they are not plottable.

Two explanations for the decline — genuinely elevated first-month risk, or differing observation
exposure — **cannot be distinguished with a single-quarter snapshot** (INF-07.c).

### 7.2 AQ-07 retention spend scenario — BLOCKED ON B-5

`AQ-07 / BQ-06` asks what it would be worth spending to retain each segment and where that breaks
even. It requires a **margin range the dataset cannot supply**. **B-5 remains open: no externally
sourced margin range exists.** No margin is assumed, estimated or inferred. AQ-07 is scenario
analysis, not measurement, and remains **deferred to Excel**. It appears in the evidence chain as an
**open item with no finding attached**.

### 7.3 External benchmark comparison — BLOCKED ON B-6

**B-6 remains open.** Ofcom's telecommunications market data release was checked and confirmed **not
to publish churn or switching rates**. No benchmark is asserted, and **21.23% is never described as
high or low** against any figure that has not been sourced. The approved position is that the KPI
ships without an external benchmark **and says so explicitly** — a stronger portfolio signal than a
benchmark of unstated provenance.

### 7.4 F-04 sensitivity slope chart — EXCLUDED (would overstate)

Under all customers, **only two of nine cells change, and each by one rank**: Mid / Month-to-Month
moves to rank 1 by revenue at risk (+1) and High / Month-to-Month to rank 2 (−1). Seven cells are
identical. A second slope chart would imply more visual substance than the result has. The sensitivity
test is described in the CH-06 footer, labelled *sensitivity analysis only*, and — per §5 — is never
promoted despite differing at the top rank.

### 7.5 Decile-10 explanatory chart — EXCLUDED (unsupported)

The decile-10 dip (24.36%, below deciles 6, 7, 8 and 9) is real and unexplained. **The data does not
establish the cause** (INF-03.a) — it could relate to contract mix, service mix, tenure, or something
unobserved. Any explanatory chart would assert a cause the evidence cannot support. The dip is
**annotated on CH-04 as unexplained and warranting investigation, not explanation.**

### 7.6 Additional exclusion applied within charts

**Below-threshold cells are collapsed, never plotted as rates.** CH-11's One Year (n = 26) and Two
Year (n = 22) sit below the pre-registered n = 30 threshold and are shown as a single labelled band.

---

## 8. Communication principles

These govern every artefact in the COMMUNICATE stage, not only the charts.

### P-1 — Observed facts must be distinguished from interpretation and inference

Four labels, used consistently: **OBSERVED FACT** (a value present in a committed output),
**INTERPRETATION** (what the facts, taken together, describe), **INFERENCE** (a step beyond what the
output establishes — always labelled as such), **LIMITATION** (what the evidence cannot support). An
inference is never presented as a finding.

### P-2 — No causal claims from associative analysis

Every relational statement uses *is associated with*, *coincides with*, *is concentrated in*,
*behaves similarly to*, or *warrants investigation*. Never *causes*, *drives*, *leads to*, *results
in*, *due to*, or *because of*. All lenses are single-dimension cuts with no multivariate control;
no figure isolates an independent contribution.

### P-3 — Population scope must be visible on every chart

Every figure carries a `Population scope:` line stating the cohort and its `n`. Scope is verified
against the output's own scope column (`population_scope`, `scope`, `scope_cohort`,
`result_designation`), not asserted in a caption. **The 21.23% opening-cohort rate and the 26.54%
all-customer reconciliation rate are never interchanged**, and a rate is never paired with a
revenue figure from a different population.

### P-4 — Sensitivity analysis must never be presented as the primary result

See §5. The A-07 designation is carried on every row of the source artefact and in the titles of
CH-06 and CH-07.

### P-5 — Negative or near-null findings must not be hidden

F-04's near-null divergence and F-06's four weakly differentiating lenses are **named in chart
titles**, positioned mid-narrative, and given their own sections. Chart form is chosen so the null
reads as null: the CH-06 slope chart shows five flat lines as five flat lines. **A null result is a
legitimate finding and is reported as one.**

### P-6 — Weakly differentiating driver lenses must not be exaggerated

All seven lenses are reported at their true magnitudes on identical axes. L5 (max index difference
0.12) and L7 (0.06) are never omitted, never rescaled, and never visually de-emphasised relative to
the strong lenses. Small cells (n < 100) are marked and always shown with their `n`; L4 DSL's rate
is annotated as resting on a single churned customer.

### P-7 — Excluded and prohibited fields must not appear in communication artefacts

`Satisfaction Score`, `Churn Score`, `CLTV`, `Churn Reason` and `Churn Category` were structurally
excluded and contribute to nothing. Restricted protected characteristics are quarantined in
`core.restricted_demographics`, which no analytical view joins, and are **restricted to
descriptive/fairness checks only — never used to target retention investment.** Compliance is
verified mechanically, not asserted.

### P-8 — Recommendations are outside the scope of this document

**No recommendation, budget figure, ROI number or prescribed intervention appears in this plan or in
any chart built under it.** Findings state what is observed and what warrants attention. Converting
that into recommended action requires separate authorisation.

### P-9 — No invented values

No benchmark, margin, industry statistic, assumption or causal explanation is invented to close a
gap. **B-5 and B-6 remain open and are stated as open.**

---

## 9. Reproducibility

```bash
# from the project root
python scripts/build_charts.py       # reads analysis/query_results/, writes figures + audit CSVs
python scripts/validate_charts.py    # exit 0 only if all 88 checks pass
```

| Path | Role |
|---|---|
| `scripts/psql_parse.py` | Deterministic parser for psql aligned output. Standard library only. **Asserts psql's declared `(N rows)` footer against rows parsed and raises on mismatch** — the tripwire for a truncated output file |
| `scripts/build_charts.py` | Builds all eleven figures. **No hard-coded analytical results.** Only literals are labels, colours, axis bounds and source references. Matplotlib only — no pandas. Three `DERIVED:` display values are marked in code and disclosed on the figures |
| `scripts/validate_charts.py` | The validation gate: eight checks per chart — numeric, scope, prohibited fields, causal language, null honesty, weak-lens presence, labels, artefact integrity. **String comparison, not float tolerance**, so a re-rounded value fails |
| `outputs/chart_data/CH-nn_data.csv` | **The audit trail.** The exact rows each chart consumed, with source file and block recorded in the header row |

**Audit-CSV convention, stated so it is not mistaken for completeness.** Each chart writes **one**
audit CSV, capturing its **primary** source block. Four charts additionally read a scalar or a
secondary block, disclosed in §6 and in the chart specification but **not captured in the CSV**:

| Chart | Secondary read | What it supplies |
|---|---|---|
| CH-01 | `analyse_01_base_position.txt` · 2 | `arr_at_risk_pct_of_scope`, `long_distance_at_risk_currency_units` |
| CH-04 | `analyse_01_base_position.txt` · 1 | the 21.23% scope reference line |
| CH-09 | `analyse_06_drivers_comparison.txt` · 2 | per-lens `max_abs_index_difference`, used for ordering and labels |
| CH-10 | `analyse_01_base_position.txt` · 1 | churned counts 1,272 and 597 |

A reviewer verifying one of these four charts end-to-end must open both the audit CSV **and** the
secondary block named above. Every such value is quoted in `FINDING_EVIDENCE_REGISTER.md` and
asserted by `validate_charts.py` check **V1**.
| `outputs/figures/CHnn_*.png` | The eleven figures, 150 dpi, 1570–2624 px wide — legible in a GitHub README and in a case study |
| `docs/COMMUNICATION_VALIDATION.md` | The gate result: **11 charts × 8 checks = 88 checks, 88 PASS, 0 FAIL** |

**No figure value was typed by hand.** The builder parses the committed outputs, writes the rows it
consumed, then renders. A reviewer can open any `chart_data` CSV, compare it to the named source
`.txt` and block, and reproduce every number on the corresponding figure.

Charts rebuild identically from a clean checkout of `analysis/query_results/`. Deleting `outputs/`
and re-running reproduces the full set. The scripts require **no database connection and no
credentials**.

---

## 10. Deviations between this specification and the delivered figures

Three deviations. **All are presentation-only. None changed a value, a population, a source file, a
scope, a caveat or a message.** Recorded rather than silently absorbed.

| # | Chart | Specified | Delivered | Why |
|---|---|---|---|---|
| **DEV-1** | CH-03 | Top-decile and High-tier cumulative figures as **in-plot annotations with leader lines** | Same figures as **title lines** (16.71%, 45.71%, 69.91%) | The in-plot annotations collided with the per-decile value labels and were illegible. Identical figures, identical source, better legibility |
| **DEV-2** | CH-04 | Decile-9 peak and decile-10 dip as **in-plot annotations with arrows** | Both stated as a **title line**, including "unexplained; warrants investigation, not explanation" | The two arrows overlapped each other and the reference-line label. The requirement — that both be called out and the dip stated as unexplained — is met |
| **DEV-3** | CH-07 | 78.93% concentration as an **in-plot annotation with an arrow** | Same figure as a **title line**, with its arithmetic (45.95 + 32.98) in the footer | The annotation overlapped the segment value labels. Identical figure, identical arithmetic disclosure |

One further item is recorded for completeness: **CH-08 panel ordering by index spread** was specified
and delivered. It affects arrangement only — weak lenses are reordered, **never removed and never
rescaled** — and is marked in code as a display-order derivation.

**Execution-environment note.** Unlike the PREPARE and ANALYSE SQL, which was executed only on the
local PostgreSQL 18.6 instance, the figures were rendered from the committed output files, which are
the sole input. The scripts need no database and reproduce the identical set from the identical
inputs when run locally.

---

## 11. Status

| Item | Status |
|---|---|
| Eleven charts CH-01 to CH-11 | ✅ Built and validated (88/88 checks PASS) |
| Five deliberate exclusions | ✅ Remain unbuilt |
| A-07 designation | ✅ Preserved on source rows, chart filters and chart titles |
| **B-5** — sourced margin range | 🔓 **OPEN.** AQ-07 deferred to Excel. No margin assumed |
| **B-6** — external churn benchmark | 🔓 **OPEN.** No benchmark asserted |
| D-1 to D-5 narrative artefacts | ⬜ **Not created.** Requires separate authorisation |
| Recommendations, executive summary, README | ⬜ **Not created.** Out of scope per principle P-8 |
