# Decision Log — Project 01

## Telecommunications Revenue Retention: Prioritising Retention Investment by Revenue at Risk

Judgement calls recorded **as they are made**. Interviewers probe exactly these choices; a written decision turns *"I think I did that because…"* into a specific answer.

**Last updated:** 19 August 2026

---

## Index

| ID | Decision | Stage | Status | Date |
|----|----------|-------|--------|------|
| D-01 | Reframe from churn analysis to revenue-at-risk prioritisation | DEFINE | ✅ Approved | 19 Aug 2026 |
| D-02 | Exclude CLV modelling | DEFINE | ✅ Approved | 19 Aug 2026 |
| D-03 | Exclude churn prediction model | DEFINE | ✅ Approved | 19 Aug 2026 |
| D-04 | Frame as differentiated investment, not withdrawal | DEFINE | ✅ Approved | 19 Aug 2026 |
| D-05 | Select IBM Telco extended over four alternatives | SOURCE | ✅ Approved | 19 Aug 2026 |
| **D-06** | **Five relational tables authoritative; merged workbook cross-check only** | SOURCE | ✅ **Approved — C-1** | 19 Aug 2026 |
| **D-07** | **Revenue-at-risk basis = `Monthly Charge` × 12** | SOURCE | ✅ **Approved — C-2** | 19 Aug 2026 |
| **D-08** | **Churn-rate denominator — opening cohort (tenure ≥ 4)** | SOURCE | ✅ **Approved — C-3** | 19 Aug 2026 |
| **D-09** | **Licence position** | SOURCE | 🟠 **Unresolved, documented — C-5** | 19 Aug 2026 |
| **D-10** | **Segmentation framework — P1, P2, L1–L7** | FRAME | ✅ **Approved — C-6** | 19 Aug 2026 |
| D-11 | Exclude `Churn Score` | SOURCE | ✅ Applied | 19 Aug 2026 |
| D-12 | Exclude `CLTV` | SOURCE | ✅ Applied | 19 Aug 2026 |
| D-13 | Exclude `Churn Reason` and `Churn Category` as diagnostics | SOURCE | ✅ Applied | 19 Aug 2026 |
| D-14 | Exclude `Satisfaction Score` | SOURCE | ✅ Applied | 19 Aug 2026 |
| D-15 | Restrict protected-characteristic fields | SOURCE | ✅ Applied | 19 Aug 2026 |
| D-16 | Correct V-01 rather than delete it | SOURCE | ✅ Applied | 19 Aug 2026 |
| **D-17** | **xlsx → CSV conversion is extraction, not analysis** | PREPARE | ✅ Applied | 19 Aug 2026 |
| **D-18** | **Excluded fields dropped at raw→core; restricted fields quarantined** | PREPARE | ✅ Applied | 19 Aug 2026 |
| **D-19** | **Map the literal `'None'` token to approved category labels (V-10)** | PREPARE | ✅ Approved & applied | 19 Aug 2026 |
| **D-20** | **Deterministic tie-break on the revenue decile (V-11)** | PREPARE | ✅ Approved & applied | 19 Aug 2026 |

**C-1 to C-6 are all approved and locked as of 19 August 2026.** The methodology is immutable from this point. A genuine data-quality or structural contradiction stops work and returns for review; it does not license a definition change.

---

## D-06 — Five relational tables are the authoritative analytical source

**Stage:** SOURCE · **Status:** ✅ Approved (C-1) · **Date:** 19 August 2026

**The decision**
> The five relational customer tables (`demographics`, `location`, `population`, `services`, `status`) are the authoritative analytical source. The merged 33-column workbook (`Telco_customer_churn.xlsx`) **must not be used as an analytical source** and must not be loaded into the database schema. It is retained solely for reconciliation and validation.

**The context**

Both variants describe the same 7,043 fictional customers. Only one can be the source of record. The decision had to rest on evidence of quality, not on which was richer.

### Evidence supporting the decision

**1. Identical customer ID sets**

All four customer tables and the merged workbook contain exactly the same 7,043 `Customer ID` values. Set equality verified in both directions across every pair. **This establishes that neither variant holds customers the other lacks** — the difference is in field content, not coverage.

**2. Key uniqueness and non-null status**

| Table | Key | n | Distinct | Nulls | Duplicates |
|---|---|---|---|---|---|
| demographics | `Customer ID` | 7,043 | 7,043 | 0 | 0 |
| location | `Customer ID` | 7,043 | 7,043 | 0 | 0 |
| services | `Customer ID` | 7,043 | 7,043 | 0 | 0 |
| status | `Customer ID` | 7,043 | 7,043 | 0 | 0 |
| population | `ID` | 1,671 | 1,671 | 0 | 0 |
| merged | `CustomerID` | 7,043 | 7,043 | 0 | 0 |

Every candidate key is unique and non-null. `population.Zip Code` is additionally unique, making it a valid join target.

**3. Zero orphan records**

| Relationship | Orphans (left→right) | Orphans (right→left) |
|---|---|---|
| demographics → location | 0 | 0 |
| demographics → services | 0 | 0 |
| demographics → status | 0 | 0 |
| location → population (`Zip Code`) | **0** | 45 unused zips (lookup superset, not an error) |

All 1,626 customer zip codes exist in `population`. Referential integrity is complete.

**4. 1:1 customer-table relationships**

All three customer-table joins are strictly **1:1** on a verified unique, non-null key. Joining all four returns exactly 7,043 rows — **no fan-out risk in the customer joins**. `location → population` is **N:1** (max 43 customers per zip), safe in that direction only.

**5. Defects identified in the merged workbook**

| Defect | Detail |
|---|---|
| Corrupted rows | 11 customers carry `Tenure Months = 0` and a blank string in `Total Charges`. The relational source shows `Tenure in Months = 10` and populated `Total Charges` (197.54–808.50) for the same customers |
| Type corruption | `Total Charges` is typed as **text** in the merged file, caused solely by those 11 blanks. In `services` it is a clean `float64` |
| Missing fields | No `Customer Status`, `Satisfaction Score`, `Churn Category`, `Offer`, `Internet Type`, `Number of Referrals`, `Age`, `Population`, or itemised revenue |
| Sentinel encoding | Uses `No internet service` / `No phone service` flattening artefacts. The relational source encodes the same dependency structurally (`Internet Type` null ⟺ `Internet Service = 'No'`, verified exactly) |
| Field disagreements | `Churn Score` differs for 244 customers; `Churn Reason` for 519 |

**6. Contradictory payment-method values**

| Merged value | → Bank Withdrawal | → Credit Card | → Mailed Check |
|---|---|---|---|
| Bank transfer (automatic) | 1,544 | 0 | 0 |
| Credit card (automatic) | 0 | 1,522 | 0 |
| Electronic check | 2,365 | 0 | 0 |
| Mailed check | 0 | **1,227** | 385 |

Two irreconcilable problems. `Electronic check` exists only in the merged file and maps wholly to `Bank Withdrawal`. And **1,227 customers are classified "Mailed check" in the merged file but "Credit Card" in the relational source** — a direct contradiction, not a renaming.

Payment method is a driver lens in AQ-05. The same analysis run on each variant would produce different answers, and one would be wrong.

*A related inconsistency:* the merged file has no `Cable` internet category. Its 830 Cable customers were folded into `DSL` (769) and `Fiber optic` (61) with no discernible rule.

**7. Tenure and `Total Charges` anomalies**

The 11 corrupted rows are the well-known artefact of this dataset, routinely "cleaned" in published analyses by dropping the rows or imputing zero. **The relational source demonstrates there was never anything to clean** — the values exist, tenure is 10, and `Total Charges` reconciles normally. Every analysis that dropped those rows discarded valid data on the basis of a corrupted extract.

`services` contains **zero** tenure-zero cases; the observed range is 1–72.

### Why the relational source, stated plainly

Every material discrepancy resolves in the relational source's favour **on quality grounds**. The merged file contains defects and internal contradictions the relational tables do not, and holds no field the relational source lacks. Richness was not the criterion; correctness was.

**What this costs**

The merged file is the version used in the overwhelming majority of published work on this dataset. Results here will not match those analyses — particularly on payment method and internet type. **This is an advantage to state explicitly in the README, not a discrepancy to hide.**

**How it affects results**

Materially. Payment-method driver analysis and internet-type service analysis would both differ. Churn counts, `Monthly Charge` and `CLTV` would not — those agree exactly.

---

## D-07 — Revenue-at-risk basis is `Monthly Charge` × 12

**Stage:** SOURCE · **Status:** ✅ Approved (C-2) · **Date:** 19 August 2026

**The decision**
> **Annual Recurring Revenue at Risk = `Monthly Charge` × 12** is the primary revenue-at-risk KPI. Long-distance revenue is **excluded from the headline KPI** and retained as a **separate analytical revenue component**.

**Evidence that annualisation is sound**

| Test | Result |
|---|---|
| Median `Total Charges` ÷ (`Monthly Charge` × tenure) | **1.0000** |
| Mean ratio | 1.0003 |
| Within ±5% | 80.4% |
| Within ±15% | 97.9% |
| 5th / 95th percentile | 0.925 / 1.075 |

A median of exactly 1.0000 with symmetric dispersion is the signature of a **stable recurring rate**, not a volatile billed amount and not a post-repricing snapshot (which would skew in one direction). `Monthly Charge` behaves as MRR.

**Evidence that long distance is genuinely separate**

`Total Long Distance Charges` ≈ `Avg Monthly Long Distance Charges` × tenure — median ratio **1.0000**, 90.3% within ±1%. It accumulates independently of `Monthly Charge`, and both reconcile into the exact revenue identity:

```
Total Revenue = Total Charges − Total Refunds
              + Total Extra Data Charges + Total Long Distance Charges
```
*(holds 7,043/7,043, max absolute difference 0.000000)*

### Why long distance is excluded from the headline KPI

**This exclusion is about what a retention offer can protect, not about economic importance.**

1. **Contractual recurrence.** `Monthly Charge` is the standing subscription — the amount contractually recurring irrespective of behaviour. Long distance is **usage-based** (`Avg Monthly Long Distance Charges`, 0.00–49.99), and usage varies. Annualising a usage average carries materially more forecast risk than annualising a subscription rate.
2. **What the intervention protects.** A retention offer secures the subscription. It does not guarantee usage volume. Sizing the retention business case on revenue that intervention cannot secure would overstate the justifiable spend — the opposite of the conservative discipline this project requires.
3. **Comparability.** Recurring subscription revenue is the standard basis for MRR/ARR in subscription businesses. A headline mixing recurring and usage revenue is not comparable to any external benchmark.

### ⚠️ Long-distance revenue is NOT economically irrelevant

**Stated explicitly, and to be stated in the README.**

Long-distance revenue is material: for churned customers it represents a further **~519,600 annualised** on top of the ~1,669,600 recurring — roughly **31% additional exposure**. Excluding it from the headline KPI is a **definitional choice about measurement basis, not a judgement that the revenue does not matter.**

It is therefore retained as a **separate reported component**:

- Reported alongside the headline as *"plus X in annualised long-distance revenue"*
- Included in the AQ-07 spend-ceiling scenario as an **upside sensitivity band**, since a retained customer plausibly retains some usage revenue
- Analysed as a value dimension in its own right — customers with high long-distance usage may behave differently, and that is a legitimate question

**Never** presented as though the recurring figure were the total revenue exposure.

**What this costs**

The headline understates total revenue exposure by roughly 31%. This must be stated wherever the headline appears, not buried in limitations.

---

## D-08 — Churn-rate denominator 🔴 RECOMMENDED, AWAITING APPROVAL

**Stage:** SOURCE · **Status:** Recommendation only (C-3) · **Date:** —

Full evidence and recommendation: [`FRAME_SPECIFICATION.md`](FRAME_SPECIFICATION.md) §2.

**Summary of the position:** `Customer Status` was found to be **fully derived** from tenure and churn — `Joined` ⟺ (tenure ≤ 3 AND not churned), exactly, with zero exceptions. This means the denominator options are not equally coherent, and the option I proposed at Stage 2 (*"exclude Joined"*) is **asymmetric and biased upward**. See the specification for the corrected analysis.

**No denominator has been selected on the basis of which produces a stronger result.** The recommendation is made on symmetry grounds and is stated before any analytical result is generated.

---

## D-09 — Licence position remains unresolved

**Stage:** SOURCE · **Status:** 🟠 Unresolved, documented (C-5) · **Date:** 19 August 2026

**The decision**
> **The licence governing this dataset could not be established.** No licensing claim — permissive or restrictive — is made anywhere in this project. The raw files are **not committed** to the repository.

### Provenance evidence — what IS established

| Element | Status | Evidence |
|---|---|---|
| Publisher | ✅ **Established** | IBM Corporation |
| Original source | ✅ **Established** | IBM Cognos Analytics sample data, distributed at *Team content > Samples > Data* |
| Primary publication | ✅ **Established** | IBM Community blog, 11 July 2019 |
| Fictional status | ✅ **Established** | IBM's own words: "a fictional telco company that provided home phone and Internet services to 7043 customers in California in Q3" |
| File vintage | ✅ **Established** | All six files modified 8 November 2019, consistent with a single IBM release |

### Licensing evidence — what is NOT established

| Source checked | Finding |
|---|---|
| IBM Community publication | **No licence statement located** |
| IBM Docs (Cognos 12.0.x, 12.1.x) | **Not accessible** — HTTP 403 |
| Kaggle mirrors (ylchang, yeanzc) | **No unambiguous open licence identified**; pages not fully readable without authentication |
| Files themselves | **No embedded licence, copyright notice or terms** |

**Conclusion: UNRESOLVED.** IBM sample-data terms are *presumed* to apply, but this is a presumption and is labelled as one. It has not been verified against a licence document.

### Consequences, applied

1. **Raw data files are not committed** to the repository — under `.gitignore` policy and because redistribution rights are not established
2. `data/raw/README.md` documents provenance and retrieval instead
3. `DATASET_REGISTRY.md` records the licence as ❓ unresolved, not as permissive
4. **No claim is made anywhere** that the data is openly licensed, freely redistributable, or restricted
5. The README will state the position plainly

**Why this is recorded rather than resolved:** an unverified licensing claim is the same category of error as an unsourced benchmark. Stating "unresolved" is accurate; stating "presumed permissive" would not be.

---

## D-10 — Segmentation framework 🔴 PROPOSED, AWAITING APPROVAL

**Stage:** FRAME · **Status:** Proposal only (C-6) · **Date:** —

Full proposal: [`FRAME_SPECIFICATION.md`](FRAME_SPECIFICATION.md) §3.

**Pre-registration commitment:** every segment, cut point and minimum cell size is specified **before any analytical result is generated or reviewed**. No segment has been chosen because it produces an interesting result — none has been tested.

---

## D-11 to D-15 — Field exclusions

Applied at SOURCE. Full reasoning in [`DATASET_VALIDATION.md`](DATASET_VALIDATION.md) §11.

| ID | Field | Decision | Basis |
|---|---|---|---|
| D-11 | `Churn Score` | ❌ Exclude | Predictive model output — target leakage. Correlation with churn 0.6608 |
| D-12 | `CLTV` | ❌ Exclude | Project 07 scope; also an undocumented prediction that would put an unverifiable field at the heart of value segmentation |
| D-13 | `Churn Reason`, `Churn Category` | ❌ Exclude as diagnostics | Outcome-derived; exist only for churned customers so no comparison is possible; would collapse AQ-05/06 to a `GROUP BY`; circular in fictional data. **Permitted as post-analysis sanity check only** |
| D-14 | `Satisfaction Score` | ❌ Exclude | **Outcome-contaminated.** 100% of customers scoring 1–2 churned (n=1,440); 0% of those scoring 4–5 churned (n=2,938). Correlation −0.7546. No genuine pre-churn survey behaves this way |
| D-15 | `Gender`, `Age`, `Under 30`, `Senior Citizen` | ⚠️ Restricted | Protected characteristics. Descriptive and confounding checks only; **never** a prioritisation rule. Segmenting retention spend on a protected characteristic is not commercially defensible and would raise fair-treatment concerns |

---

## D-16 — Correct V-01 rather than delete it

**Stage:** SOURCE · **Status:** ✅ Applied · **Date:** 19 August 2026

**The decision**
> The falsified finding V-01 is retained verbatim in the validation document with an explicit correction entry (V-01-C) beneath it, rather than being deleted and rewritten.

**Why**

V-01 claimed the five-table structure was not publicly obtainable. It was wrong. The error was inferential: I converted "I could not locate a download route" into "no download route exists." Peters then supplied all five files.

Deleting the finding would produce a cleaner document and a less honest one. The portfolio's purpose is to evidence analytical judgement, and **forming a hypothesis, testing it, finding it false and correcting it is what analytical work actually looks like.** A document with no corrections in it either had nothing tested, or had the corrections quietly removed.

**What this costs**

The validation document is longer and shows me being wrong in writing. That is the intended effect.

---

## Common Decisions Still To Be Recorded

To be added as they arise at PREPARE and ANALYSE:

- Tenure band cut points *(proposed in the FRAME specification — locks on approval)*
- Value tier boundaries *(proposed in the FRAME specification)*
- Minimum cell size for reporting a rate *(proposed in the FRAME specification)*
- Service-count banding *(proposed in the FRAME specification)*
- Treatment of the `Offer` field's 3,877 structural nulls
- Schema normalisation choices at PREPARE
- Chart type selections where non-obvious
- Which findings are promoted to the README

---

## Decision Quality Check

- [x] Every non-obvious choice has an entry
- [x] Each entry states what the decision costs, not only its benefits
- [x] Alternatives are recorded, not just the choice
- [x] Anything materially affecting a finding is flagged for the README's Limitations section
- [x] **No decision has been made on the basis of which produces a stronger result** — D-08 and D-10 are explicitly pre-registered
- [ ] I could defend each of these out loud without notes *(to confirm at REVIEW)*

---

## D-17 — xlsx → CSV conversion is an extraction utility, not analysis

**Stage:** PREPARE · **Status:** ✅ Applied · **Date:** 19 August 2026

**The decision**
> The five source workbooks are converted to UTF-8 CSV before loading into PostgreSQL. This conversion is treated as an **extraction step**, not as analytical tooling, and does not alter the Stage 1 decision that this project's analysis is SQL.

**The context**

PostgreSQL cannot read `.xlsx` directly. A CSV intermediate is required. The question is whether using a conversion utility contradicts the approved tool decision (charter §13: PostgreSQL primary, Excel for scenario modelling, Python deliberately not used).

**Why it does not**

The conversion touches no values, makes no interpretive choice, applies no logic, and produces no output that could be mistaken for a result. It is the equivalent of unzipping an archive. The Stage 1 decision was about where *analysis* happens — every join, aggregation, segmentation and KPI calculation is SQL, and that is unchanged.

**What this costs**

One step in the reproduction instructions that is not SQL. Mitigated by recording the exact command in `sql/00_setup/README.md` so a reviewer can repeat it, and by asserting row counts at every hop (REC-01) so a conversion error cannot pass silently.

**Alternative considered:** a Postgres foreign-data wrapper for spreadsheets. Rejected — it adds an extension dependency that makes reproduction harder for a reviewer, to avoid a conversion step that is trivially auditable.

---

## D-18 — Excluded fields are dropped at the raw→core boundary, not filtered downstream

**Stage:** PREPARE · **Status:** ✅ Applied · **Date:** 19 August 2026

**The decision**
> `Satisfaction Score`, `Churn Score`, `CLTV`, `Churn Reason` and `Churn Category` are loaded into `raw` and **not promoted to `core`**. They exist nowhere in the analytical layer. Restricted fields (`gender`, `age`, `is_under_30`, `is_senior_citizen`) are promoted into a separate `core.restricted_demographics` table that no analytical view joins.

**Why**

A field sitting in an analytical table with a comment saying "do not use" is an invitation. A field that does not exist in the schema is a control. The exclusions approved at D-11 to D-15 are analytically important enough to be enforced structurally rather than by discipline.

Retaining them in `raw` keeps the exclusion **auditable** — a reviewer can confirm the field was present and deliberately not used, which is stronger evidence of judgement than the field simply being absent.

Check VAL-09 scans for any `core` or `analytics` object referencing an excluded field, the restricted table, or the merged workbook. It must return zero.

**What this costs**

Two extra objects and one extra validation check. Cheap relative to the risk of a leaked field reaching a finding.

---

## D-19 — Map the literal `'None'` token to the approved category labels

**Stage:** PREPARE · **Status:** ✅ Approved and applied · **Date:** 19 August 2026

**The decision**
> `Offer` and `Internet Type` contain the literal string `'None'`, not nulls. The promotion SQL maps the literal token, a true NULL and an empty string to the same approved labels — `'No offer'` and `'No internet'`.

**The context**

Checks CLEAN-10 and CLEAN-11 failed on the first run, both returning 0 where 3,877 and 1,526 were expected. Investigation established that `services.xlsx` contains **zero true null cells**: the 5,403 "absent" values are the four-character string `'None'`. Stage 2 profiling used pandas, whose `read_excel` treats `'None'` as a missing value by default, and I documented the columns as structurally null on that basis.

**Options considered**

| Option | Assessment |
|---|---|
| A — map to `'No offer'` / `'No internet'` (**chosen**) | Preserves the labels locked at C-6; removes the ambiguity |
| B — leave `'None'` as the category label | Zero code change, but `internet_type = 'None'` reads as *missing* rather than *no internet service* — the exact ambiguity C-6 chose those labels to avoid |
| C — convert the token to a true NULL, then coalesce | Two steps to reach the same place, and it would put a null into a `NOT NULL` column mid-pipeline |

**Why**

The population is identical under all three options — 3,877 and 1,526 customers. This is a **label repair, not a change to any approved definition, segment, cut point or KPI.** Option A is the only one that leaves an unambiguous label in the analytical layer.

The mapping also handles true NULL and empty string defensively, so the promotion is correct whether or not a future extract changes convention. Guard check **CLEAN-10b** asserts no residual `'None'` survives promotion.

**What this costs**

`Offer` and `Internet Type` no longer render exactly as stored in the source. The transformation is documented in the data dictionary, the validation document (V-10) and the script header, so it is traceable.

**How it affects results**

Not at all. Same customers, same cells, same counts.

---

## D-20 — Deterministic tie-break on the revenue decile

**Stage:** PREPARE · **Status:** ✅ Approved and applied · **Date:** 19 August 2026

**The decision**
> `revenue_decile` is computed as `NTILE(10) OVER (ORDER BY monthly_charge, customer_id)`. The window is calculated once in a CTE, and `value_tier` derives from it.

**The context**

The original ordered only by `monthly_charge`, which has many tied values. PostgreSQL does not guarantee stable assignment among ties, so decile membership could differ between executions — including across the decile 7/8 boundary, which is the `Mid`/`High` boundary feeding P1 and all seven driver lenses.

**Why**

Reproducibility is quality gate item 12, and a segment whose membership can change between runs fails it. `customer_id` is unique, so adding it makes the ordering total and the result identical on every execution.

Computing the window once rather than twice inline also removes the possibility of `revenue_decile` and `value_tier` disagreeing.

**What this costs**

Nothing analytically. `NTILE` still splits ties across boundaries — that is inherent to equal-frequency binning. The fix makes the split **deterministic, not absent.** Informational check CLEAN-21 reports how many charge values span more than one decile, so the extent is visible rather than assumed.

**How it affects results**

Decile membership may differ from the first run for tied customers at boundaries. All figures from the first run are therefore superseded by the re-run — which is why the affected validation checks are re-executed rather than carried forward.

**Would I decide the same again?**

The deterministic ordering should have been there from the start. Any window function used for segmentation needs a total order, and I did not apply that rule when writing the view.

---

## D-21 — Divergence index population: opening cohort primary, all customers sensitivity

**Stage:** ANALYSE · **Status:** ✅ Approved and locked · **Date:** 19 August 2026 · **Ref:** A-07

**The decision**
> The **primary** value–risk divergence index uses the **opening cohort**. Both components — the churn rate *and* the annual recurring revenue at risk — are computed from that same population. The **all-customers** version is retained as a clearly labelled **sensitivity analysis** and does not replace the primary result. Customers who joined and churned within the observation quarter remain included in the separate early-life / onboarding analysis.

**The context**

The FRAME specification defined the index before C-3 fixed the churn denominator. Two locked decisions then pointed in different directions: C-3 puts the churn KPI on the opening cohort for symmetry; C-2 includes all churned customers in revenue at risk, because lost revenue is lost regardless of when the customer joined. The index ranks segments by both measures simultaneously, so the populations must agree.

**Options considered**

| Option | Assessment |
|---|---|
| **A — both components on the opening cohort (chosen)** | Compares like with like. Consistent with the primary KPI. Excludes 597 early-life churners from the revenue side, but they are already reported separately under C-3, so nothing is lost from the overall picture |
| B — both components on all customers | Uses the full revenue picture, but the churn rate then becomes the period-end rate, which is explicitly *not* the primary KPI |
| C — mixed populations | Rejected. Ranking a symmetric rate against an asymmetric level is not a valid comparison |

**Why**

The index exists to show where a churn-led prioritisation would diverge from a revenue-led one. If the two rankings are computed over different populations, part of any observed divergence is an artefact of the population difference rather than a real disagreement between the two prioritisation logics — which would defeat the purpose of the measure.

**Why the sensitivity analysis is retained**

Excluding 597 customers who represent 31.9% of all churn is a material choice. The all-customers scope is kept, labelled, so it can be established whether including in-period acquisitions materially changes segment rankings, prioritisation, the index itself, or the interpretation of where churn and revenue risk diverge. If it does not, the choice is immaterial and can be reported as such; if it does, that is itself worth stating.

`04_value_risk_divergence.sql` §F-04d computes the scope sensitivity directly.

**What this costs**

The primary index excludes roughly a third of total churn from its revenue side. Mitigated by the early-life analysis (F-07) and by the sensitivity scope.

**Timing — the point of the whole exercise**

**Locked before any result was seen.** Decided now, in the open, it is methodology. Decided after seeing which scope produced the better story, it would be specification searching. That distinction is the difference between analysis and advocacy, and it is the reason this was escalated rather than resolved silently.

**Not to be changed after results are reviewed.**

---

## D-22 — Output labelling repaired: explicit columns replace `\echo` section headers

**Stage:** ANALYSE · **Status:** ✅ Approved and applied · **Date:** 19 August 2026
**Type:** Documentation / evidence-chain repair. **Not** a methodological or analytical change.

**The decision**
> Extract scripts identify each output block's population scope with an **explicit column in the `SELECT`**, rather than relying on a `psql \echo` header. The A-VAL-17 fan-out block carries an explicit `check_id` column.

**The defect**

`psql -o <file>` redirects **query results** to the file; `\echo` writes to **stdout**. Every section header — including `PRIMARY RESULT` and `SENSITIVITY ANALYSIS ONLY` on the divergence blocks — went to the console and never reached the committed evidence. Four extract files contained adjacent, identically-shaped result blocks distinguishable only by position:

| File | Unlabelled blocks |
|---|---|
| `03_churn_by_revenue_decile.sql` | 2 decile blocks (opening cohort vs all customers) |
| `04_value_risk_divergence.sql` | 2 divergence blocks (**primary vs sensitivity**) |
| `05_drivers_high_value.sql` | 3 blocks (scope not stated) |
| `07_early_life_churn.sql` | 2 blocks (scope not stated) |

**Why it mattered**

No value was wrong and no information was lost — the scope-bearing columns exist in the `analyse_v*.txt` view outputs. But `CLAUDE.md` §5.2 requires every finding to trace to a committed result file, and quality gate item 13 requires documentation sufficient for a reviewer. **A result table that cannot state which population it describes cannot anchor an evidence chain.** For the divergence extract specifically, the locked A-07 designation was invisible in the artefact that carries it.

**What changed — and what deliberately did not**

Added: `population_scope`, `result_designation`, `scope_cohort`, `scope_tier`, `check_id` columns.
Unchanged and verified line-by-line: every `WHERE` clause, every `ORDER BY`, every aggregate, `CASE`, `round()` and `RANK()` expression, every threshold and expected value, every population definition, KPI, segmentation rule and cut point.

Two mechanical consequences, both verified no-ops:
- `05` F-05b gains `scope_cohort, scope_tier` in its `GROUP BY`. Both are single-valued under the existing `WHERE`, so no row is added or split and no aggregate changes.
- `08` A-VAL-17 changes `ORDER BY 1` to `ORDER BY 2`, preserving the sort by `view_name` now that `check_id` occupies position 1.

**What this costs**

The affected extracts must be re-run, and their previous outputs are superseded. Output tables are slightly wider.

**Lesson recorded**

An artefact intended as evidence must be **self-describing**. Relying on a channel that does not reach the artefact — `\echo` to a redirected file — produced correct data in an unusable record. Any future extract that filters a scope in `WHERE` should also select it.
