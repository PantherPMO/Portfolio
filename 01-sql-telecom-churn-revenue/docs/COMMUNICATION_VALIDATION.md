# Communication Validation

## Project 01 — Telecommunications Revenue Retention: Prioritising Retention Investment by Revenue at Risk

**Stage:** 6 — COMMUNICATE (chart validation gate)
**Prepared:** 20 August 2026
**Status:** 🟢 **11 of 11 charts built and validated — OVERALL PASS**
**Scope of this document:** the chart set only. No executive summary, no recommendations, no portfolio README.

---

## 1. What was validated, and against what

The eleven charts specified in the approved Communication Plan were built and then checked
against two independent references:

| Reference | Role |
|---|---|
| `analysis/query_results/analyse_0*.txt` | **Numerical source of truth.** The committed psql outputs of the locked ANALYSE pipeline |
| `docs/FINDING_EVIDENCE_REGISTER.md` | **Permission boundary.** Defines what each chart is allowed to communicate, and which caveats travel with it |

**Nothing in PREPARE or ANALYSE was modified.** No SQL script, view, KPI definition, population,
cut point, segmentation rule, ranking or validation expectation was touched. No analytical value
was recalculated, re-rounded or estimated.

### The mechanism that makes this checkable

No figure on any chart was typed by hand. `scripts/build_charts.py` parses the committed psql
output files with `scripts/psql_parse.py` and writes the exact rows each chart consumed to
`outputs/chart_data/CH-nn_data.csv`. Those CSVs are the audit trail: a reviewer can open one,
compare it to the source `.txt`, and reproduce every number on the corresponding figure.

`scripts/psql_parse.py` asserts psql's own declared `(N rows)` footer against the number of rows
it parsed and raises on mismatch — the tripwire for a truncated or partially written output file.

---

## 2. Validation results

Eight checks per chart. Values are compared as **strings**, not floats, so a value that has been
re-rounded or reformatted fails rather than passing on numeric tolerance.

| # | Check | What it proves |
|---|---|---|
| **V1** | Numeric | Every headline value on the chart appears verbatim in that chart's audit CSV |
| **V2** | Scope | The audit CSV contains only rows of the declared population, tested on the output's own scope column |
| **V3** | Prohibited fields | No excluded field and no restricted protected characteristic reached the chart |
| **V4** | Causation | No causal verb appears in any title, axis label, annotation or footer |
| **V5** | Null honesty | The two null-result charts state the null in their own titles |
| **V6** | Weak lenses | The driver charts contain all seven lenses, including the weak ones |
| **V7** | Labels | Source file, block, and the locked A-07 designation are present where required |
| **V8** | Artefact | The PNG exists, is a valid non-empty PNG, and has plausible dimensions |

### 2.1 Required summary table

| Chart ID | Source Finding | Source File | Population | Numeric Check | Scope Check | Status |
|----------|----------------|-------------|------------|---------------|-------------|--------|
| **CH-01** | F-01.4, .7, .9, .10 | `analyse_01_base_position.txt` blocks 2, 3 | Opening cohort, n = 5,992 | ✅ PASS | ✅ PASS | ✅ **PASS** |
| **CH-02** | F-01.9 | `analyse_01_base_position.txt` block 3 | Opening cohort, n = 5,992 | ✅ PASS | ✅ PASS | ✅ **PASS** |
| **CH-03** | F-02.1, .3, .7, .8 | `analyse_02_revenue_concentration.txt` block 1 | All customers, n = 7,043 | ✅ PASS | ✅ PASS (n/a — single-scope block) | ✅ **PASS** |
| **CH-04** | F-03.1–.4 | `analyse_03_churn_by_decile.txt` block 1 | Opening cohort, n = 5,992 | ✅ PASS | ✅ PASS | ✅ **PASS** |
| **CH-05** | F-03.9, .10, .11 | `analyse_03_churn_by_decile.txt` block 3 | Opening cohort; High 2,004 · Mid 2,316 · Low 1,672 | ✅ PASS | ✅ PASS | ✅ **PASS** |
| **CH-06** | F-04.5, .6, .7, .8 | `analyse_04_divergence.txt` block 2 (PRIMARY rows) | **PRIMARY — Opening cohort**, 9 P1 cells | ✅ PASS | ✅ PASS | ✅ **PASS** |
| **CH-07** | F-04.2, .3, .4, .10 | `analyse_04_divergence.txt` block 2 (PRIMARY rows) | **PRIMARY — Opening cohort**, 9 P1 cells | ✅ PASS | ✅ PASS | ✅ **PASS** |
| **CH-08** | F-05.1–.12 | `analyse_05_drivers_high_value.txt` block 1 | Opening cohort × High tier, n = 2,004 | ✅ PASS | ✅ PASS | ✅ **PASS** |
| **CH-09** | F-06.1–.6 | `analyse_06_drivers_comparison.txt` blocks 1, 2 | Opening cohort: High tier 2,004 vs base-wide 5,992 | ✅ PASS | ✅ PASS (n/a — comparison block carries both scopes by design) | ✅ **PASS** |
| **CH-10** | F-07.1, .3, .4, .12 | `analyse_07_early_life_churn.txt` blocks 1, 3 | In-period acquisitions n = 1,051 vs opening cohort n = 5,992 | ✅ PASS | ✅ PASS | ✅ **PASS** |
| **CH-11** | F-07.6, .7, .10 | `analyse_07_early_life_churn.txt` block 2 | In-period acquisitions, n = 1,051 | ✅ PASS | ✅ PASS | ✅ **PASS** |

### 2.2 Full check matrix

| Chart | V1 Numeric | V2 Scope | V3 Prohibited | V4 Causation | V5 Null | V6 Lenses | V7 Labels | V8 Artefact | Dimensions |
|---|---|---|---|---|---|---|---|---|---|
| CH-01 | PASS | PASS | PASS | PASS | n/a | n/a | PASS | PASS | 1570×776, 132,720 B |
| CH-02 | PASS | PASS | PASS | PASS | n/a | n/a | PASS | PASS | 1669×811, 146,021 B |
| CH-03 | PASS | n/a | PASS | PASS | n/a | n/a | PASS | PASS | 1938×1103, 232,572 B |
| CH-04 | PASS | PASS | PASS | PASS | n/a | n/a | PASS | PASS | 2624×1109, 213,538 B |
| CH-05 | PASS | PASS | PASS | PASS | n/a | n/a | PASS | PASS | 1686×1079, 167,432 B |
| **CH-06** | PASS | PASS | PASS | PASS | **PASS** | n/a | PASS | PASS | 2220×1285, 299,113 B |
| CH-07 | PASS | PASS | PASS | PASS | n/a | n/a | PASS | PASS | 1819×1254, 288,321 B |
| CH-08 | PASS | PASS | PASS | PASS | n/a | **PASS** | PASS | PASS | 2447×1605, 411,444 B |
| **CH-09** | PASS | n/a | PASS | PASS | **PASS** | **PASS** | PASS | PASS | 2189×1606, 393,122 B |
| CH-10 | PASS | PASS | PASS | PASS | n/a | n/a | PASS | PASS | 1881×958, 211,399 B |
| CH-11 | PASS | PASS | PASS | PASS | n/a | n/a | PASS | PASS | 1874×985, 205,572 B |

**OVERALL: PASS.** Reproduce with `python scripts/validate_charts.py` (exit code 0 only if every check passes).

---

## 3. Point-by-point response to the eight validation requirements

### 3.1 Displayed values match the validated analysis outputs

**PASS, mechanically.** Values are read from the outputs, never typed. V1 additionally asserts that
a fixed list of headline figures taken from `FINDING_EVIDENCE_REGISTER.md` appears verbatim in each
chart's audit CSV — so the chart, the register and the psql output are confirmed to agree, not
assumed to.

### 3.2 Correct population scope is shown

**PASS.** Every chart states its scope in a footer line beginning `Population scope:`. V2 verifies
the underlying rows against the output's own scope column (`population_scope`, `scope`,
`scope_cohort`, `result_designation`).

Specifically:

- **CH-06 and CH-07** filter on `result_designation = 'PRIMARY RESULT - Opening cohort'` and carry
  **PRIMARY RESULT — Opening cohort** in the title. Locked decision A-07 / D-21 is preserved.
- **The sensitivity analysis is not plotted.** Communication Plan §5 excluded it deliberately: only
  two of nine cells change, each by one rank, so a chart would imply more visual substance than the
  result has. It is described in the CH-06 footer and labelled *sensitivity analysis only*.
- **CH-04** uses `population_scope = opening_base` (primary). The all-customers block exists in the
  same output and was deliberately not plotted.
- **CH-10** is the one chart that legitimately spans both cohorts, and it shows **shares of a
  total, never a combined rate**.
- **CH-09's** comparison block carries both scopes by construction — that is the finding. Its
  legend names them explicitly: *Base-wide (opening cohort, all tiers)* and *High value tier*.

### 3.3 No excluded or prohibited fields used

**PASS.** V3 scans every chart's audit CSV — headers and cell values — for the structurally
excluded fields (`Satisfaction Score`, `Churn Score`, `CLTV`, `Churn Reason`, `Churn Category`) and
for restricted protected characteristics. Zero hits across all eleven charts.

This is consistent with, and downstream of, gate **A-VAL-19**, which scanned `pg_views` definitions
for prohibited references and passed.

### 3.4 No chart implies causation where only association is supported

**PASS.** V4 scans every title, axis label, annotation and footer for causal verbs. Every relational
statement uses *is associated with*, *coincides with*, *is concentrated in*, *behaves similarly to*
or *warrants investigation*.

Every figure additionally carries the standing line: *"Single observation window — no trend.
Association only; no causal claim."*

Three charts carry explicit anti-causal caveats because they are the most misreadable:

- **CH-04** — "Nothing here establishes that charge level causes any churn outcome."
- **CH-07** — "Nothing here establishes that contract type causes them, and contract choice is
  plausibly related to customer characteristics the dataset does not observe." Plus the tenure
  confound.
- **CH-11** — "NO ONBOARDING CAUSE MAY BE ASSERTED. The dataset contains no activation,
  installation, complaint, service-quality, first-contact, acquisition-channel or campaign records
  of any kind."

### 3.5 The near-null divergence finding is not exaggerated

**PASS.** CH-06 presents the null as the finding, in its own title:

> *"The value-versus-risk divergence test returns a near-null result — top two segments identical
> under both rankings · 5 of 9 segments do not move · 4 move by exactly one rank · maximum
> divergence is 1"*

Design decisions that prevent exaggeration in either direction:

- The **slope chart is the honest form** — five of nine lines are flat and read as flat. A bar chart
  of divergence values would have given four visible bars and looked like a result.
- Non-moving segments are drawn in **muted grey**, moving segments in accent colour. The eye lands
  on five flat grey lines.
- The legend counts them: *"No change in rank (5 of 9 segments)"*.
- The footer states: *"THIS IS A NEGATIVE FINDING, PRESENTED AS ONE… The project was designed to
  test whether a churn-led prioritisation would materially diverge from a revenue-led one. On this
  population, at this segmentation, it does not."*
- The ordinal caveat is carried: the index *"must never be quoted without magnitudes — see CH-07"*.
- The untested-granularity caveat is carried, including that testing it now would breach
  pre-registration.

**No chart claims divergence was demonstrated.** CH-07 exists precisely so the *positional* fact
(78.93% of revenue at risk in two Month-to-Month cells) carries the story instead of the index.

### 3.6 Weak driver differentiation is not overstated

**PASS.**

- **CH-08** shows all seven lenses and all 24 cells. Panels are ordered by spread, and the two
  weakest — **L5 service intensity (spread 0.73)** and **L7 referral behaviour (spread 0.45)** —
  appear at their true magnitudes on identical axes. The in-figure note states: *"L5 and L7 are the
  weakest lenses and are shown here at their true magnitudes — not omitted, not rescaled."* The
  footer records L7's 13.75-percentage-point span.
- **CH-09** leads on the null in its title: *"For four of seven lenses, barely."* Every lens header
  is styled identically so the weak ones are not visually de-emphasised, and each carries its
  `max |Δ|`: L1 0.15, L5 0.12, L7 0.06.
- The footer quotes **charter risk R-04** verbatim, which anticipated this outcome in writing before
  any result existed.
- All five `caveat_required` cells (n = 36 to 80) are marked ▲ and show their `n`. **L4 DSL's 1.25%
  is annotated as resting on one churned customer in 80** — an unstable estimate, not a finding.
- **L6's unestablished direction** is stated on CH-08 in full.

### 3.7 Titles, labels and annotations match the register and plan

**PASS.** V7 asserts the declared source and block on every chart, and the A-07 designation on
CH-06 and CH-07. Every chart footer names its exact source file and block. Every monetary value is
labelled *currency units*; **no currency symbol appears anywhere** in the chart set or the builder.

### 3.8 Image files generated, not empty or corrupted

**PASS.** V8 verifies the PNG magic bytes, reads the IHDR width and height, and requires a
plausible file size. All eleven are between 132 KB and 411 KB at 150 dpi, 1570–2624 px wide — legible
inline in a GitHub README and in a portfolio case study.

---

## 4. Derived display values

Three values shown on charts are arithmetic on figures already present in the outputs. Each is
marked `DERIVED:` in `scripts/build_charts.py` and disclosed on the chart itself. **No other
arithmetic is performed anywhere in the chart pipeline.**

| Chart | Value | Arithmetic | Disclosed on the chart as |
|---|---|---|---|
| CH-02 | 4.45 pp | 78.77 − 74.32, both displayed on the same chart | *"4.45 pp gap (78.77 − 74.32)"*, plus a footer line stating it is the difference of the two percentages shown, not a separate measure |
| CH-07 | 78.93% | 45.95 + 32.98, both displayed on the same chart. Equals register fact **F-04.4** | *"The 78.93% figure is the sum of the two segment shares shown (45.95 + 32.98)."* |
| CH-10 | 68.06% | 100.00 − 31.94, the sourced share | *"The 68.06% opening-cohort share of churn events is the complement of the sourced 31.94%."* |

One further derivation affects **presentation order only, never a plotted value**: CH-08 orders its
panels by index spread (max − min of displayed indices). Weak lenses are reordered, never removed
and never rescaled.

---

## 5. Deliberate omissions

Five charts were specified as excluded in the Communication Plan. All five remain excluded.

| Not built | Reason |
|---|---|
| F-07.2 monthly rate curve (61.99 / 51.68 / 47.00) | **Would read as a survival curve.** Three acquisition groups with different exposure windows within one quarter. The register names this as a methodological error to avoid. Quotable in prose with its caveat; not plottable |
| AQ-07 spend-ceiling chart | **Blocked on B-5.** No margin range has been sourced. AQ-07 remains deferred to Excel |
| Any benchmark comparison | **Blocked on B-6.** Ofcom was checked and confirmed not to publish churn or switching rates. No benchmark is asserted |
| F-04 sensitivity slope chart | Only two of nine cells move, each by one rank. A chart would imply more substance than the result has |
| Decile-10-dip explanatory chart | The data does not establish the cause (INFERENCE F-03.a). Annotated in the CH-04 title as unexplained and warranting investigation |

Two below-threshold cells are **collapsed, not plotted**: CH-11 shows One Year (n = 26) and Two Year
(n = 22) as a single band labelled *"below the n = 30 reporting threshold — rates not reportable"*.
Bar width reflects customer counts only; no rate is shown for them.

---

## 6. Reproducibility

```bash
# from the project root
python scripts/build_charts.py       # reads analysis/query_results/, writes figures + audit CSVs
python scripts/validate_charts.py    # exit 0 only if all 88 checks pass
```

| File | Role |
|---|---|
| `scripts/psql_parse.py` | Deterministic parser for psql aligned output. Standard library only. Asserts declared row counts |
| `scripts/build_charts.py` | Builds all eleven figures. **No hard-coded analytical results.** Matplotlib only — no pandas |
| `scripts/validate_charts.py` | The validation gate that produced §2 |
| `outputs/chart_data/CH-nn_data.csv` | The exact rows each chart consumed, with source file and block recorded in the header |
| `outputs/figures/CHnn_*.png` | The figures |

Charts rebuild identically from a clean checkout of `analysis/query_results/`. Deleting
`outputs/` and re-running reproduces the full set.

**Note on execution environment.** Unlike the PREPARE and ANALYSE SQL — which was executed only on
the local PostgreSQL 18.6 instance — these figures were rendered from the committed output files,
which are the sole input. The scripts require no database connection and no credentials, and
running them locally reproduces the same figures from the same inputs.

---

## 7. Open items — not closed by this stage

| Item | Status |
|---|---|
| **B-5** — externally sourced margin range | 🔓 **OPEN.** AQ-07 / BQ-06 remains deferred to Excel. No margin assumed |
| **B-6** — external churn benchmark | 🔓 **OPEN.** No benchmark asserted. 21.23% is never described as high or low |
| `docs/COMMUNICATION_PLAN.md` | ⬜ **Not committed.** The governing specification for this stage currently exists only in conversation. Awaiting instruction |
| `outputs/figures/README.md` figure index | ⬜ Not created — deliberately out of scope for this step |

---

## 8. Gate outcome

> **11 charts built · 88 checks run · 88 PASS · 0 FAIL · 0 charts unbuildable.**
>
> Both null results — **F-04's near-null divergence** and **F-06's four weakly differentiating
> lenses** — are built, titled as null results, and validated as such. Neither is hidden, minimised
> or visually softened.

**No executive summary, recommendations document or portfolio README has been created.**
The next stage requires explicit approval.
