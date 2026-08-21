# Dataset Validation — Project 01

## Telecommunications Revenue Retention: Prioritising Retention Investment by Revenue at Risk

**Stage:** 2 — SOURCE (verification)
**Originally prepared:** 19 August 2026 (documentary verification)
**Revised:** 19 August 2026 (file-level verification)
**Status:** ✅ **FILE-LEVEL VERIFICATION COMPLETE**

> **Document history is preserved deliberately.** The original findings V-01 and V-02 were made before the files were available. V-01 proved wrong. It is **corrected below by an explicit correction entry, not deleted** — the portfolio should show a hypothesis being formed, tested, falsified and corrected, because that is what analytical work actually looks like.

---

# ⚠️ CORRECTION REGISTER

## V-01 — SUPERSEDED BY V-01-C

### Original finding (19 Aug 2026, documentary stage) — retained verbatim

> **Finding V-01 — The five-table structure is not publicly obtainable**
>
> **This invalidates the primary argument in my Stage 2 recommendation.**
>
> I recommended Candidate B principally because it comprised **five related tables**, which would require genuine relational schema design — the strongest available argument for a SQL project. Verification against IBM's own publication shows this is **not distributed as five downloadable files**.
>
> IBM's description of the five tables (Demographics, Location, Population, Services, Status) refers to a **Cognos Analytics data module**. IBM states the files are "located at: *Team content > Samples > Data*" **inside a Cognos Analytics installation** with the Base Samples package installed. No direct download URL is published, and the five `.xlsx` files do not appear in any accessible public mirror I could locate.
>
> **What is publicly available is a single merged flat file** — `Telco_customer_churn.xlsx`, 33 columns × 7,043 rows.

### V-01-C — CORRECTION (19 Aug 2026, file-level stage)

**V-01 is wrong.** All five tables were supplied by Peters and are present in `data/raw/`, alongside the merged file.

| File | Bytes | Modified |
|---|---|---|
| `Telco_customer_churn_demographics.xlsx` | 353,216 | 8 Nov 2019 |
| `Telco_customer_churn_location.xlsx` | 534,338 | 8 Nov 2019 |
| `Telco_customer_churn_population.xlsx` | 52,266 | 8 Nov 2019 |
| `Telco_customer_churn_services.xlsx` | 1,225,982 | 8 Nov 2019 |
| `Telco_customer_churn_status.xlsx` | 397,133 | 8 Nov 2019 |
| `Telco_customer_churn.xlsx` (merged) | 1,368,250 | 8 Nov 2019 |

**What I got wrong, and why:** I concluded from "no public download URL exists" that the artefact was unobtainable. That inference was unsound — absence of a public download route is not absence of the files. I should have stated "I could not locate a download route" and stopped there, rather than converting a search failure into a claim about the world.

**Corrected position:** the five-table Cognos structure is real, complete, and now the primary source. The relational-schema argument for this dataset — which I had withdrawn — is **restored, and on stronger evidence than originally claimed**: the tables have verified keys, verified cardinality, and a genuine second join dimension (zip code → population) that the merged file cannot support.

**What this does not change:** the data remains **fictional IBM sample data**. That was verified from IBM's own statement and is unaffected.

---

## V-02 — REASSESSED AGAINST THE ACTUAL FILES

### Original finding — retained

> **Finding V-02 — There are two distinct "extended" variants, commonly conflated.** The obtainable merged file does not contain `Satisfaction Score`, `Churn Category`, or itemised revenue fields.

### V-02-C — CORRECTION AND EXTENSION

**The two-variant observation was correct. The conclusion drawn from it was not.**

Confirmed by inspection: the merged file genuinely lacks `Satisfaction Score`, `Churn Category`, `Number of Referrals`, `Offer`, `Internet Type`, `Streaming Music`, `Unlimited Data`, `Avg Monthly GB Download`, `Age`, `Under 30`, `Number of Dependents`, `Population`, and all itemised revenue fields. **All of these are present in the five-table version.** The variants are materially different, not cosmetically.

**But the difference is larger and runs in the opposite direction from what I assumed.** The five-table version is not merely richer — verification found the merged file to contain **defects and taxonomy contradictions that the five-table version does not** (V-03 to V-06 below). The merged file is not a superset, a subset, or a faithful flattening. It is a different and demonstrably lower-quality extract.

---

# NEW FINDINGS FROM FILE-LEVEL VERIFICATION

## V-03 🔴 The merged file contains a data defect the relational tables do not

Eleven customers carry `Tenure Months = 0` and a **blank string** (`' '`) in `Total Charges` in the merged file. The same eleven customers in `services` carry `Tenure in Months = 10` and populated `Total Charges` between 197.54 and 808.50.

This is the well-known artefact that appears in thousands of published analyses of this dataset — routinely "fixed" by dropping the rows or imputing zero. **The relational source shows there was nothing to fix: the values exist and the tenure is 10, not 0.** The merged extract corrupted them.

Consequence: `Total Charges` in the merged file is typed as **text** (`object`), purely because of those eleven blanks. In `services` it is a clean `float64`.

**This is the single strongest piece of evidence that the five tables are authoritative** — and it is evidence, not preference, as required.

## V-04 🔴 Payment Method taxonomies are contradictory, not merely renamed

| Merged | → Bank Withdrawal | → Credit Card | → Mailed Check |
|---|---|---|---|
| Bank transfer (automatic) | 1,544 | 0 | 0 |
| Credit card (automatic) | 0 | 1,522 | 0 |
| Electronic check | 2,365 | 0 | 0 |
| Mailed check | 0 | **1,227** | 385 |

Two problems. `Electronic check` does not exist in the five-table version — it maps entirely to `Bank Withdrawal`. And **1,227 customers labelled "Mailed check" in the merged file are "Credit Card" in the relational source.** Those cannot both be true.

Payment method is a **driver lens in AQ-05**. Any driver analysis run on the merged file would produce different results from the same analysis on the relational source, and one of them would be wrong.

## V-05 🟠 Internet service taxonomy is inconsistently collapsed

| Merged | → (no internet) | → Cable | → DSL | → Fiber Optic |
|---|---|---|---|---|
| DSL | 0 | **769** | 1,652 | 0 |
| Fiber optic | 0 | **61** | 0 | 3,035 |
| No | 1,526 | 0 | 0 | 0 |

The merged file has no `Cable` category. Its 830 Cable customers were folded into DSL (769) and Fiber optic (61) — **not by any consistent rule**. Internet type is a likely primary driver, so this materially distorts service-mix analysis on the merged file.

## V-06 🟠 The merged file's sentinel encoding is an artefact of flattening

Merged add-on fields use three values — `Yes`, `No`, and sentinels `No internet service` / `No phone service`. The relational `services` table uses **clean binary `Yes`/`No` only**, with the dependency expressed structurally: `Internet Type` is null for exactly the 1,526 customers where `Internet Service = 'No'`.

**This resolves check P-14 favourably.** The sentinel trap I flagged as a precondition for the bridge-table design exists only in the merged file. The relational source is already correctly normalised on this point.

## V-07 🔴 `Satisfaction Score` is outcome-contaminated — exclude it

You asked me to establish its provenance and timing before deciding whether it is analytically legitimate. The data answers this decisively.

| Satisfaction Score | n | % Churned | % Stayed | % Joined |
|---|---|---|---|---|
| 1 | 922 | **100.0%** | 0.0% | 0.0% |
| 2 | 518 | **100.0%** | 0.0% | 0.0% |
| 3 | 2,665 | 16.1% | 78.0% | 5.9% |
| 4 | 1,789 | **0.0%** | 91.5% | 8.5% |
| 5 | 1,149 | **0.0%** | 87.4% | 12.6% |

Correlation with churn: **−0.7546**.

**Every customer scoring 1 or 2 churned. No customer scoring 4 or 5 churned.** That is deterministic at both extremes across 4,378 customers. A genuine pre-churn satisfaction survey does not behave this way; real satisfaction data has overlap at every level. This field was constructed from the outcome, or the outcome was constructed from it.

**Verdict: exclude, for the same reason as `Churn Reason`.** Using it would produce a "finding" that satisfaction predicts churn at near-perfect accuracy — which is a property of IBM's generation logic, not an insight. Recorded as **F-EX-08**.

**By comparison, `Churn Score` correlates 0.6608** — high, but not deterministic. It remains excluded on leakage grounds (F-EX-01) regardless.

## V-08 🟠 `Customer Status` reveals a churn-rate denominator problem

The `status` table carries a three-value `Customer Status` the merged file lacks:

| Status | n | Tenure min–max | Mean tenure |
|---|---|---|---|
| Stayed | 4,720 | 4–72 | 41.0 |
| Churned | 1,869 | 1–72 | 18.0 |
| **Joined** | **454** | **1–3** | **1.7** |

454 customers joined within the quarter. They cannot have been at risk for the full period.

| Denominator | Churn rate |
|---|---|
| All 7,043 rows | **26.54%** |
| Excluding `Joined` (6,589) | **28.37%** |

`KPI_LIBRARY.md` already requires the treatment of within-period joiners to be stated explicitly. **This is a FRAME decision, taken before results are seen.** It is not a finding and no conclusion is drawn from it here.

## V-10 🔴 The "structural nulls" in `services` are a literal `'None'` token — Stage 2 was wrong

**Discovered when the pipeline ran in PostgreSQL. Checks CLEAN-10 and CLEAN-11 both FAILED, correctly.**

`Offer` and `Internet Type` do not contain nulls. They contain the **literal four-character string `'None'`** — 3,877 and 1,526 cells respectively.

**Why Stage 2 got it wrong.** Profiling used pandas, and `pd.read_excel` includes the string `'None'` in its default `na_values`. It silently coerced the token to `NaN`, and I recorded both columns as structurally null. PostgreSQL performs no such coercion, so the promotion SQL — which coalesced nulls that were never there — relabelled nothing and both checks returned 0.

**Verified null census across all five authoritative tables:**

| File | True null cells | Literal `'None'` cells |
|---|---|---|
| demographics | 0 | 0 |
| location | 0 | 0 |
| population | 0 | 0 |
| **services** | **0** | **5,403** |
| **status** | **10,348** | **0** |

**The source uses two different conventions for the same concept.** `services` writes a `'None'` token; `status` leaves cells genuinely empty. That inconsistency is itself a finding, and it is not documented by IBM.

**Analytical consequence: none.** The populations are identical — 3,877 and 1,526 — so every cell size, segment and downstream figure is unchanged.

**Labelling consequence: real.** `internet_type = 'None'` reads as *missing*, when it means *this customer has no internet service*. The FRAME specification locked the labels as `'No offer'` and `'No internet'` precisely to avoid that ambiguity.

**Correction applied** (approved 19 Aug 2026): `05_promote_dim_contract.sql` now maps the literal token, a true NULL and an empty string to the same approved label, with guard check CLEAN-10b asserting no residual `'None'` survives promotion. **A label repair, not a change to any approved definition.**

**Why this matters beyond this project.** A profiling tool silently converted a sentinel string into a null, and the mistake survived documentary review. It was caught only by running the same data through a system that does not guess. That is an argument for validating in the engine the analysis will actually use.

---

## V-11 🟠 Decile assignment was not reproducible

**Found while reading the first run's output.** VAL-04b passed, but reported decile sizes of 704–705 against Stage 2's 695–717 — the difference being that pandas `qcut` respects value boundaries while `NTILE` splits evenly regardless of ties.

The underlying defect was more serious. `NTILE(10) OVER (ORDER BY monthly_charge)` had **no tie-break**. `monthly_charge` has many repeated values, and PostgreSQL does not guarantee stable assignment among tied rows — so **re-running could move customers across the decile 7/8 boundary**, which is the `Mid`/`High` value-tier boundary, which feeds P1 and every driver lens.

Segment membership that can change between executions is not reproducible, and reproducibility is quality gate item 12.

**Correction applied** (approved 19 Aug 2026): `ORDER BY monthly_charge, customer_id`. `customer_id` is unique, so the ordering is total and the result is identical on every run. The window is also now computed once in a CTE rather than twice inline, so `revenue_decile` and `value_tier` cannot diverge. **The definition is unchanged** — still `NTILE(10)` over `monthly_charge` across the whole base, exactly as locked at C-6.

Note that ties still straddle decile boundaries; that is inherent to `NTILE`. The fix makes the split **deterministic, not absent**. Informational check CLEAN-21 reports how many charge values span more than one decile.

---

## V-09 🟡 `Churn Score` and `Churn Reason` disagree between variants

`Churn Score` differs for **244 customers**; `Churn Reason` differs for **519**. `Churn Value`, `CLTV` and `Monthly Charge` agree exactly.

Both differing fields are already excluded, so there is no analytical consequence — but it is further evidence the two extracts are not the same vintage, and it is recorded rather than discarded.

---

# 1. Verification Results — P-01 to P-15

| ID | Check | Result | Verdict |
|---|---|---|---|
| **P-01** | Row count | All four customer tables **7,043**; population **1,671** | ✅ PASS |
| **P-02** | Column count / names | demographics 9 · location 9 · population 3 · services 30 · status 11 · merged 33 | ✅ PASS |
| **P-03** | Key uniqueness | `Customer ID` 7,043 distinct, **0 duplicates, 0 nulls** in every customer table. `population.ID` unique | ✅ PASS |
| **P-04** | Nulls | Only 4 nullable columns portfolio-wide — see §8 | ✅ PASS, all explained |
| **P-05** | Data types | Clean throughout the relational tables. **Merged `Total Charges` is text** — caused by V-03 | ✅ PASS (relational) / ⚠️ merged |
| **P-06** | `Churn Label` vs `Churn Value` | **Perfect agreement**, 7,043/7,043. Also consistent with `Customer Status` | ✅ PASS |
| **P-07** | `Total Charges` ≈ `Monthly Charge` × tenure | **Median ratio 1.0000**; 80.4% within ±5%; 97.9% within ±15%; p05 0.925, p95 1.075 | ✅ **PASS — decisive** |
| **P-08** | Tenure = 0 | **Zero cases** in `services` (range 1–72). The 11 zeros exist only in the merged file (V-03) | ✅ PASS |
| **P-09** | Constant columns | `Count`=1 (all tables); `Country`='United States'; `State`='California'; **`Quarter`='Q3'** in services and status | ✅ PASS |
| **P-10** | Categorical inventory | Complete — see §2 | ✅ PASS |
| **P-11** | `Monthly Charge` distribution | min 18.25, median 70.35, mean 64.76, max 118.75. **No zero or negative values** | ✅ PASS |
| **P-12** | Churn baseline | 1,869 churned. 26.54% all rows / 28.37% excluding Joined. By contract: M2M **45.84%**, One Year 10.71%, Two Year 2.55% | ✅ PASS |
| **P-13** | Decile cell sizes | Deciles 695–717. **Minimum decile × contract cell = 104** across all 30 cells | ✅ **PASS — comfortable** |
| **P-14** | Service-flag encoding | Relational source uses **clean Yes/No**; sentinels exist only in the merged file (V-06) | ✅ PASS |
| **P-15** | Currency evidence | **None found.** No `$`, no `£`, no currency number formats. The string "USD" appears only as a substring of customer IDs (`6479-OAUSD`, `5751-USDBL`) | ⚠️ **UNRESOLVED — currency remains unstated** |

**15 checks run. 14 pass. 1 unresolved (currency).** No check failed.

---

# 2. Confirmed Schema

## `demographics` — 7,043 × 9

`Customer ID` (PK, str) · `Count` (const 1) · `Gender` · `Age` (19–80) · `Under 30` · `Senior Citizen` · `Married` · `Dependents` · `Number of Dependents`

**Verified internal consistency:** `Senior Citizen = 'Yes'` ⟺ `Age ≥ 65` (exactly 1,142). `Under 30 = 'Yes'` ⟺ `Age < 30` (exactly 1,401). `Number of Dependents > 0` ⟺ `Dependents = 'Yes'`. All three hold with zero exceptions — the derived flags are internally sound.

`Age` is continuous and absent from the merged file. **Restricted alongside `Senior Citizen` under F-EX-07** (see §11).

## `location` — 7,043 × 9

`Customer ID` (PK) · `Count` · `Country` (const) · `State` (const) · `City` · `Zip Code` (int) · `Lat Long` · `Latitude` · `Longitude`

## `population` — 1,671 × 3

`ID` (PK, unique) · `Zip Code` (**unique**) · `Population`

The only table not keyed on customer. **A genuine second join dimension.**

## `services` — 7,043 × 30

`Customer ID` (PK) · `Count` · `Quarter` (const 'Q3') · `Referred a Friend` · `Number of Referrals` · `Tenure in Months` (1–72) · `Offer` · `Phone Service` · `Avg Monthly Long Distance Charges` · `Multiple Lines` · `Internet Service` · `Internet Type` · `Avg Monthly GB Download` · `Online Security` · `Online Backup` · `Device Protection Plan` · `Premium Tech Support` · `Streaming TV` · `Streaming Movies` · `Streaming Music` · `Unlimited Data` · `Contract` · `Paperless Billing` · `Payment Method` · `Monthly Charge` · `Total Charges` · `Total Refunds` · `Total Extra Data Charges` · `Total Long Distance Charges` · `Total Revenue`

**Eleven service dimensions** (vs seven in the merged file), and **five revenue fields** (vs two).

## `status` — 7,043 × 11

`Customer ID` (PK) · `Count` · `Quarter` (const 'Q3') · `Satisfaction Score` · `Customer Status` · `Churn Label` · `Churn Value` · `Churn Score` · `CLTV` · `Churn Category` · `Churn Reason`

## Categorical inventory (relational source)

| Field | Values |
|---|---|
| `Contract` | Month-to-Month 3,610 · Two Year 1,883 · One Year 1,550 |
| `Payment Method` | Bank Withdrawal 3,909 · Credit Card 2,749 · Mailed Check 385 |
| `Internet Service` | Yes 5,517 · No 1,526 |
| `Internet Type` | Fiber Optic 3,035 · DSL 1,652 · Cable 830 · null 1,526 |
| `Phone Service` | Yes 6,361 · No 682 |
| `Offer` | null 3,877 · B 824 · E 805 · D 602 · A 520 · C 415 |
| `Churn Category` | null 5,174 · Competitor 841 · Attitude 314 · Dissatisfaction 303 · Price 211 · Other 200 |
| `Customer Status` | Stayed 4,720 · Churned 1,869 · Joined 454 |
| Add-ons (8 fields) | `Yes` / `No` only |

---

# 3. Confirmed Relationships

```
                    ┌──────────────────────────┐
                    │  demographics            │
                    │  PK: Customer ID  (7043) │
                    └────────────┬─────────────┘
                                 │ 1:1  (identical key sets, 0 orphans)
         ┌───────────────┬───────┴────────┬──────────────────┐
         │ 1:1           │ 1:1            │ 1:1              │
         ▼               ▼                ▼                  ▼
┌─────────────────┐ ┌──────────────┐ ┌──────────────┐ ┌──────────────────┐
│ location        │ │ services     │ │ status       │ │ merged (7043)    │
│ PK: Customer ID │ │ PK: Cust ID  │ │ PK: Cust ID  │ │ SECONDARY ONLY   │
│ (7043)          │ │ (7043)       │ │ (7043)       │ │ cross-check      │
└────────┬────────┘ └──────────────┘ └──────────────┘ └──────────────────┘
         │
         │ N:1   Zip Code → Zip Code
         │       1,626 distinct zips used · max 43 customers per zip
         ▼
┌──────────────────────────┐
│  population              │
│  PK: ID · UQ: Zip Code   │
│  (1671)                  │
└──────────────────────────┘
```

## Confirmed grain

| Table | Grain | Rows |
|---|---|---|
| demographics | one row per customer | 7,043 |
| location | one row per customer | 7,043 |
| services | one row per customer per quarter (**single quarter present**) | 7,043 |
| status | one row per customer per quarter (**single quarter present**) | 7,043 |
| population | one row per zip code | 1,671 |
| merged | one row per customer | 7,043 |

## Confirmed join keys

| From | To | Key | Cardinality | Orphans |
|---|---|---|---|---|
| demographics | location | `Customer ID` | **1:1** | 0 |
| demographics | services | `Customer ID` | **1:1** | 0 |
| demographics | status | `Customer ID` | **1:1** | 0 |
| demographics | merged | `Customer ID` ↔ `CustomerID` | **1:1** | 0 |
| location | population | `Zip Code` | **N:1** | **0** |

**All four customer tables contain exactly the same 7,043 customer IDs.** Set equality verified in both directions — no missing records, no orphans, anywhere.

---

# 4. Fan-Out Findings

**No fan-out risk exists in the customer-table joins.** All four are strictly 1:1 on a verified unique, non-null key. Joining all four returns exactly 7,043 rows. This was the largest structural risk flagged before verification and it is **eliminated**.

**One fan-out direction does exist:** `location → population` on `Zip Code` is **N:1**. Joining customers to population is safe (each customer gains one population value). Joining *population to customers* would multiply — up to 43 rows for the densest zip.

- 1,626 distinct zip codes appear among customers
- **0 customer zip codes are missing from `population`** — referential integrity is complete
- 45 population zip codes have no customers (a lookup superset, not an error)
- Maximum 43 customers per zip

**The row-count assertion discipline in `SQL_STANDARDS.md` §7 still applies**, but the pre-verification concern about revenue double-counting across a service bridge is now a *design* consideration rather than a *source data* risk — the source is already normalised.

---

# 5. Reconciliation Results

## Customer count
**7,043 in all six files. Identical ID sets. Zero orphans.** ✅

## Churn count
**1,869 churned in both `status` and `merged`.** `Churn Value` agrees 7,043/7,043. `Churn Label` agrees perfectly with `Churn Value`, and both agree with `Customer Status`. ✅

## Merged vs relational — field by field

| Field pair | Match | Mismatch | Assessment |
|---|---|---|---|
| `Monthly Charges` ↔ `Monthly Charge` | 7,043 | **0** | ✅ Identical |
| `Churn Value` | 7,043 | **0** | ✅ Identical |
| `CLTV` | 7,043 | **0** | ✅ Identical |
| `Tenure Months` ↔ `Tenure in Months` | 7,032 | **11** | 🔴 V-03 — merged corrupt |
| `Total Charges` | 7,032 | **11** | 🔴 V-03 — merged blank |
| `Churn Score` | 6,799 | **244** | 🟡 V-09 |
| `Churn Reason` | 6,524 | **519** | 🟡 V-09 |
| `Contract` | 0 | 7,043 | ⚪ **Case only** — "Month-to-month" vs "Month-to-Month". Not material |
| `Payment Method` | 0 | 7,043 | 🔴 **V-04 — contradictory taxonomies** |
| `Partner` ↔ `Married` | 7,043 | **0** | ✅ Same field, renamed |
| `Senior Citizen` | 7,043 | **0** | ✅ Identical |

## Revenue reconciliation ✅ **exact**

```
Total Revenue = Total Charges − Total Refunds
              + Total Extra Data Charges + Total Long Distance Charges
```

**Holds for 7,043 of 7,043 rows. Maximum absolute difference: 0.000000.**

A perfectly reconciling derived field. It will still be **recomputed rather than trusted**, per your item #7 — but the check confirms the source is internally coherent.

| Aggregate | Value (currency unstated) |
|---|---|
| `Total Revenue`, all customers | 21,371,131.69 |
| `Total Charges`, all customers | 16,060,725.24 |
| Mean `Total Revenue` per customer | 3,034.38 |

---

# 6. Revenue-Field Assessment

## `Monthly Charge` — P-07 resolved in favour of annualisation ✅

The critical open question was whether `Monthly Charge` is a stable recurring rate or a one-month billed amount. **It behaves as a stable recurring rate.**

| Test | Result |
|---|---|
| Median ratio `Total Charges` ÷ (`Monthly Charge` × tenure) | **1.0000** |
| Mean ratio | 1.0003 |
| Within ±5% | 80.4% |
| Within ±15% | 97.9% |
| 5th / 95th percentile | 0.925 / 1.075 |

A median of exactly 1.0000 with symmetric dispersion is the signature of a stable rate with modest price movement over tenure — not a volatile billed amount, and not a post-repricing snapshot (which would skew systematically in one direction).

**Assumption A-03 (linear annualisation) is supported by evidence.** It remains an assumption about *future* behaviour and stays declared — but it is no longer resting on nothing.

## `Total Charges` — definitional problem resolved ✅

The pre-verification concern was that IBM describes it as "to end of quarter" while tenure runs to 72 months. **Resolved:** it is cumulative lifetime-to-date. The IBM description is loose; the field reconciles cleanly against `Monthly Charge` × tenure and feeds the exact `Total Revenue` identity.

**The prior withholding decision can be lifted** — with the caveat that `Total Charges` is *historical cumulative* revenue and therefore **not** the right basis for forward-looking revenue at risk. It is a validation field, not the unit of account.

## 🟠 NEW: `Monthly Charge` excludes long-distance revenue

`Total Long Distance Charges` ≈ `Avg Monthly Long Distance Charges` × tenure — median ratio **1.0000**, 90.3% within ±1%. Long distance accumulates *separately* from `Monthly Charge`, and both reconcile independently into `Total Revenue`.

**Therefore `Monthly Charge` is the recurring subscription charge only.** Usage-based long-distance revenue (up to 49.99/month) sits outside it.

This creates a **definitional choice that must be made at FRAME, before any result is seen**, because it changes the headline number substantially:

| Candidate basis for annualised revenue at risk | Value |
|---|---|
| `Monthly Charge` × 12 | ~1,670,000 |
| (`Monthly Charge` + `Avg Monthly Long Distance`) × 12 | ~2,189,000 |
| `Total Revenue` (lifetime, not annualised) | ~3,684,000 |

> ⚠️ **These are feasibility figures demonstrating that the definition matters. They are not findings, and no business conclusion is drawn from them.** Per your item #10, this is documented and stopped at.

**My recommendation, for your decision at FRAME:** use `Monthly Charge` × 12 as the primary basis — it is the contractually recurring element, it is what a retention offer actually protects, and it is the conservative choice. Report the long-distance uplift as a stated sensitivity. Recording the choice and its rationale is itself a `DECISIONS.md` entry.

---

# 7. Satisfaction Score Assessment

**Verdict: EXCLUDE. Recorded as F-EX-08.**

Full evidence in **V-07**. The field is deterministic at both extremes — 1,440 customers scoring 1–2 all churned; 2,938 scoring 4–5 all did not — with correlation −0.7546. No genuine pre-churn satisfaction measurement behaves this way.

**Provenance and timing, as you asked:** IBM publishes no collection methodology for this field, and the distribution is inconsistent with a survey captured *before* the outcome. Whether it was derived from the churn flag or the churn flag from it cannot be determined, and does not need to be — either direction makes it unusable as an explanatory variable.

**Permitted use:** identical to `Churn Reason` — as a post-analysis sanity check only, run *after* the driver analysis is complete, reported as corroboration, never as a source of findings.

**This is a good outcome for the project.** Establishing contamination from the data — rather than assuming it or, worse, building the analysis on it — is precisely the judgement the quality gate weights. Most published work on this dataset treats `Satisfaction Score` as a genuine driver.

---

# 8. Data-Quality Issues

**The relational source is in notably good condition** — and better than Stage 2 described, once V-10 corrected the characterisation.

**Corrected position:** four columns carry an "absent" marker, but they use **two different conventions**, and only two of them are true nulls.

| Table | Column | Absent marker | Count | % | Cause | Treatment |
|---|---|---|---|---|---|---|
| services | `Offer` | **literal `'None'`** | 3,877 | 55.0% | **Structural** — customer received no promotional offer | Mapped to category `'No offer'`. **Not missing data** |
| services | `Internet Type` | **literal `'None'`** | 1,526 | 21.7% | **Structural** — exactly matches `Internet Service = 'No'`, verified | Mapped to `'No internet'`. Never imputed |
| status | `Churn Category` | true NULL | 5,174 | 73.5% | **Structural** — exactly matches non-churned, verified | Excluded field regardless (F-EX-09) |
| status | `Churn Reason` | true NULL | 5,174 | 73.5% | **Structural** — as above | Excluded field (F-EX-03) |

**`services.xlsx` contains zero true null cells.** All 5,403 of its "absent" values are the literal token. `status.xlsx` contains 10,348 true nulls and no tokens. See V-10.

**No genuine missing values anywhere in the relational source.** No duplicates. No key nulls. No orphans. No negative or zero charges. No tenure zeros. Every absent value is structural and carries a documented meaning.

**Issues confined to the merged file:** V-03 (11 corrupt rows, text-typed `Total Charges`), V-04 (contradictory payment taxonomy), V-05 (inconsistent internet collapse), V-06 (sentinel encoding), V-09 (244 + 519 field disagreements).

**Structural inconsistency of note:** `Quarter` is present in `services` and `status` but is constant `'Q3'`. The schema anticipates a time dimension that this extract does not contain. **This is the strongest possible confirmation of risk R-01** — the data model expects periods; only one exists.

---

# 9. Which Source Is Authoritative — Established From Evidence

Per your item #7, this is not decided on richness.

| Evidence | Points to |
|---|---|
| Merged has 11 corrupted rows (tenure 0 + blank charges) that the relational source has correctly populated (V-03) | **Relational** |
| Merged `Total Charges` is text-typed *because of* those corruptions | **Relational** |
| Merged payment taxonomy is internally contradictory — 1,227 customers classified two incompatible ways (V-04) | **Relational** |
| Merged collapses Cable inconsistently across two categories with no discernible rule (V-05) | **Relational** |
| Merged uses flattening sentinels; relational expresses the same dependency structurally (V-06) | **Relational** |
| Relational carries `Customer Status`, exposing 454 within-period joiners the merged file conceals (V-08) | **Relational** |
| Relational reconciles a five-field revenue identity exactly, 7,043/7,043 | **Relational** |
| Relational has verified referential integrity across five tables and a second join dimension | **Relational** |
| Merged has no field the relational source lacks | Neutral |

**Conclusion: the five-table version is authoritative.** Every material discrepancy resolves in its favour on quality grounds, not on breadth. The merged file is retained as a **cross-check artefact only**, and the discrepancies above are recorded rather than discarded (your item #8).

---

# 10. Updated Risks

| # | Risk | Prior | Now | Change |
|---|---|---|---|---|
| **V-R1** | Files not obtained | 🔴 Blocking | ✅ **CLOSED** | All six staged and profiled |
| **V-R2** | Licence unresolved | 🟠 High | 🟠 **High — unchanged** | Still no open licence identified. Raw files remain uncommitted |
| **V-R3** | Five-table premise failed | 🟠 High | ✅ **CLOSED** | V-01 was wrong; structure confirmed |
| **V-R4** | `Total Charges` definition | 🟠 High | ✅ **CLOSED** | Lifetime cumulative, reconciles exactly |
| **V-R5** | `Monthly Charge` semantics | 🟠 High | ✅ **CLOSED** | Stable recurring rate confirmed (P-07) |
| **V-R6** | Currency unstated | 🟡 Medium | 🟠 **RAISED** | Searched the file internals; **no evidence found**. Must be stated as unknown, never as £ |
| **V-R7** | Data is fictional | 🟡 Medium | 🟡 **Unchanged — inherent** | Reinforced: the outcome-derived `Satisfaction Score` is direct evidence of generation logic |
| **V-R8** | No time dimension | 🟡 Medium | 🟠 **CONFIRMED** | `Quarter` present but constant 'Q3'. Schema anticipates periods; one exists |
| **V-R9** | No margin/intervention data | 🟡 Medium | 🟡 Unchanged | AQ-07 stays scenario-only |
| **V-R10** | Small-cell instability | 🟡 Medium | 🟢 **DOWNGRADED** | Min decile × contract cell = **104**. Comfortable |
| **V-R11** | Dataset heavily used | 🟡 Medium | 🟡 Unchanged | Differentiation now also includes the merged-file defects most analyses inherit |
| **V-R12** | No Ofcom churn benchmark | 🟡 Medium | 🟡 Unchanged | Still requires a separate citation or ships absent |
| **V-R13** | 🆕 **Revenue definition ambiguity** — subscription vs subscription + long distance | — | 🟠 **NEW** | Changes the headline by ~31%. Must be decided at FRAME before results are seen |
| **V-R14** | 🆕 **Churn denominator ambiguity** — 454 `Joined` customers | — | 🟠 **NEW** | 26.54% vs 28.37%. Must be decided at FRAME |
| **V-R15** | 🆕 **Merged-file contamination risk** | — | 🟡 **NEW** | If any query accidentally sources the merged file, results silently differ. Mitigation: load only the five tables into PostgreSQL; keep the merged file out of the schema entirely |

---

# 11. Excluded and Restricted Fields — Updated

| Ref | Field | Status | Basis |
|---|---|---|---|
| F-EX-01 | `Churn Score` | ❌ Exclude | Model output; leakage. Correlation 0.6608 |
| F-EX-02 | `CLTV` | ❌ Exclude | Project 07 scope + undocumented prediction |
| F-EX-03 | `Churn Reason` | ❌ Exclude as diagnostic | Outcome-derived; post-analysis sanity check only |
| **F-EX-08** | **`Satisfaction Score`** | ❌ **Exclude — NEW** | **Outcome-contaminated; deterministic at extremes (V-07)** |
| **F-EX-09** | **`Churn Category`** | ❌ **Exclude as diagnostic — NEW** | Same basis as `Churn Reason`; null for exactly the non-churned |
| F-EX-05 | `Count`, `Country`, `State`, `Lat Long` | ❌ Drop | Confirmed constant / redundant composite |
| F-EX-06 | `Latitude`, `Longitude` | ❌ Out of scope | No business question requires geospatial analysis |
| F-EX-07 | `Gender`, `Senior Citizen`, **`Age`**, **`Under 30`** | ⚠️ **Restricted** | Protected characteristics. **`Age` and `Under 30` newly added** — the relational source exposes exact age, which does not change the position: descriptive and confounding checks only, never a prioritisation rule |

**Newly available and usable:** `Number of Referrals`, `Referred a Friend`, `Offer`, `Internet Type`, `Streaming Music`, `Unlimited Data`, `Avg Monthly GB Download`, `Number of Dependents`, `Population`, and four itemised revenue fields. These materially strengthen AQ-05 and AQ-06.

**`Offer` deserves particular note:** it records which promotional offer a customer holds, for 45% of the base. It is the closest thing in the dataset to a *commercial intervention* variable — and its relationship to retention is exactly the kind of thing this project exists to examine. **Not analysed here.** Flagged for FRAME.

---

# 12. Updated Stage 2 Verdict

## ✅ **FIT FOR PURPOSE — verified**

Upgraded from *conditionally fit*. The verification did not merely confirm the earlier assessment; it **strengthened the case on every dimension that had been in doubt**, and closed four of the five high risks.

**What verification established:**

- Five tables, 7,043 customers, **verified 1:1 relationships with zero orphans** — real relational structure, not an assumption
- **A second join dimension** (zip → population, N:1, complete referential integrity) that the merged file cannot support
- **`Monthly Charge` confirmed as a stable recurring rate** — the annualisation convention underpinning every revenue figure now has evidence behind it
- **An exact five-field revenue identity**, 7,043/7,043
- **Excellent data quality** — no duplicates, no key nulls, no orphans, no genuine missing values, no invalid charges
- **Comfortable cell sizes** — minimum 104 across 30 decile × contract cells
- **Eleven service dimensions and five revenue fields**, against seven and two in the merged file

**What verification found that was not expected:**

- The merged file — the version used in thousands of published analyses — **contains defects and contradictions the relational source does not**
- **`Satisfaction Score` is outcome-contaminated** and must join the exclusion list
- **`Monthly Charge` excludes long-distance revenue**, creating a definitional choice worth ~31% of the headline figure
- **454 within-period joiners** create a churn-denominator choice worth ~1.8 percentage points

The last three are the kind of thing that quietly corrupts an analysis if found late. All three were found before a single analytical query was written.

**What has not changed:** the data is fictional, IBM-disclosed, and must be labelled as such everywhere. No finding may be framed as a claim about a real operator or market.

---

# 13. Conditions Before FRAME

Four remain. All are decisions for Peters, not further verification.

| # | Condition | Status |
|---|---|---|
| **C-1** | **Confirm the five-table source as authoritative**, merged file as cross-check only and excluded from the database schema | Evidence in §9 — awaiting sign-off |
| **C-2** | **Decide the revenue-at-risk basis** — `Monthly Charge` × 12 (recommended) vs including long distance. **Must be fixed before any result is seen** | 🔴 **Open — V-R13** |
| **C-3** | **Decide the churn-rate denominator** — all 7,043 vs excluding the 454 `Joined`. **Must be fixed before any result is seen** | 🔴 **Open — V-R14** |
| **C-4** | **Confirm reworded BQ-01, BQ-04, BQ-06** (charter §11) | 🟡 Open from the previous round |
| **C-5** | Licence position formally recorded, even if the conclusion is "unclear, therefore not redistributed" | 🟠 Open — V-R2 |
| **C-6** | Segment scheme and minimum cell sizes declared | 🟢 De-risked by P-13; still to be stated at FRAME |

**C-2 and C-3 are the important ones.** Both are pre-registration decisions: taken now, in the open, they are methodology. Taken after seeing which produces the better headline, they are specification searching. That distinction is the difference between analysis and advocacy, and it is worth being pedantic about.

---

# Appendix A — Profiling Checks (as pre-registered, now executed)

Retained in original form with results appended. Pre-registration held: **no check was added, removed or altered after the data was seen.** Findings V-03 to V-09 arose from checks already listed, or from the extended verification scope in Peters' Stage 2 approval.

*(Results table in §1.)*

---

## Audit Trail

| Date | Action | Outcome |
|---|---|---|
| 19 Aug 2026 | Located IBM primary publication | ✅ Fictional status verified and quoted |
| 19 Aug 2026 | Attempted to locate five-table distribution | ❌ Concluded Cognos-install only — **Finding V-01** |
| 19 Aug 2026 | Attempted IBM Docs (Cognos 12.0.x / 12.1.x) | ❌ 403 — not accessible |
| 19 Aug 2026 | Searched public mirrors for the five `.xlsx` files | ❌ None located |
| 19 Aug 2026 | Verified 33-column merged schema from IBM field metadata | ✅ Documentary only |
| 19 Aug 2026 | Identified variant divergence | **Finding V-02** |
| 19 Aug 2026 | Attempted file download | ❌ Blocked — authentication / Cognos required |
| 19 Aug 2026 | Reassessed BQ-01–06, AQ-01–07 documentarily | ✅ 3 rewordings recommended |
| 19 Aug 2026 | Pre-registered profiling checks P-01 to P-15 | ✅ Fixed before data seen |
| **19 Aug 2026** | **Peters supplied all six files** | ✅ **V-01 falsified** |
| 19 Aug 2026 | Staged six files; profiled all sheets | ✅ Structure confirmed |
| 19 Aug 2026 | Ran P-01 to P-15 | ✅ **14 pass, 1 unresolved (currency), 0 fail** |
| 19 Aug 2026 | Verified keys, cardinality, orphans, fan-out | ✅ 1:1 × 4, N:1 × 1, zero orphans |
| 19 Aug 2026 | Reconciled merged vs relational | 🔴 **V-03, V-04, V-05, V-06, V-09** recorded |
| 19 Aug 2026 | Tested `Satisfaction Score` provenance | 🔴 **V-07 — outcome-contaminated, excluded** |
| 19 Aug 2026 | Tested revenue identity and P-07 | ✅ Exact; annualisation supported |
| 19 Aug 2026 | Established authoritative source from evidence | ✅ §9 — relational |
| 19 Aug 2026 | Issued V-01-C and V-02-C corrections | ✅ Originals preserved |
| **PENDING** | **C-1 to C-6 sign-off** | ⬜ **Blocking FRAME** |

---

## Sources

- [IBM Community — Telco customer churn (11.1.3+)](https://community.ibm.com/community/user/businessanalytics/blogs/steven-macko/2019/07/11/telco-customer-churn-1113) — fictional status; five-table module
- Local files supplied by Peters, `data/raw/`, modified 8 November 2019 — the evidentiary basis for all §1–§9 results
- [Ofcom — Telecommunications Market Data Update](https://www.ofcom.org.uk/phones-and-broadband/telecoms-infrastructure/telecommunications-market-data-update) — external context; confirmed no churn rate published

---

## Note on Method

Profiling was performed with a throwaway pandas script in the session scratch directory. **It is not project code and has not been written into the repository** — no Python exists in `01-sql-telecom-churn-revenue/`, consistent with the Stage 1 tool decision. Every figure in this document is reproducible from the six source files by the checks described.
