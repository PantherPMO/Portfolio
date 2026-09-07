# Data Dictionary — Project 01

**Dataset:** Telco customer churn — **five-table Cognos structure** (authoritative)
**Registry ID:** DS-01
**Source:** IBM Cognos Analytics sample data — [IBM Community publication](https://community.ibm.com/community/user/businessanalytics/blogs/steven-macko/2019/07/11/telco-customer-churn-1113)
**Files dated:** 8 November 2019
**Verified:** 19 August 2026 — all values below **observed from the files**, not documented

> **This is fictional sample data supplied by IBM.** IBM describes it as "a fictional telco company that provided home phone and Internet services to 7043 customers in California in Q3."
>
> **It is not real-world telecom subscriber data and must never be described as such anywhere in this portfolio.**

> ⚠️ **Currency is unknown.** No currency symbol, code or number format exists anywhere in the source files. All monetary values are unitless. **Never present them as £.**

---

## Source Precedence

| Source | Role |
|---|---|
| Five tables (demographics, location, population, services, status) | ✅ **AUTHORITATIVE** — loaded into the database |
| `Telco_customer_churn.xlsx` (merged, 33 columns) | ⚠️ **CROSS-CHECK ONLY** — contains defects (V-03 to V-06). **Must not be loaded into the schema** |

Evidence for this precedence is in [Data Quality](data-quality.md) §9.

---

## Table: `demographics` — 7,043 × 9

**PK:** `Customer ID` · **Grain:** one row per customer · **Duplicates:** 0 · **Key nulls:** 0

| # | Field | Type | Nulls | Description | Observed values |
|---|-------|------|-------|-------------|-----------------|
| 1 | `Customer ID` | str | 0 | Unique customer identifier | 7,043 distinct |
| 2 | `Count` | int | 0 | BI reporting artefact | Constant `1` — **drop** |
| 3 | `Gender` | str | 0 | Customer gender | Male / Female — ⚠️ **restricted** |
| 4 | `Age` | int | 0 | Customer age in years | 19–80 — ⚠️ **restricted** |
| 5 | `Under 30` | str | 0 | Age band flag | Yes 1,401 / No — ⚠️ **restricted**. Verified ⟺ `Age < 30` |
| 6 | `Senior Citizen` | str | 0 | 65 or older | Yes 1,142 / No — ⚠️ **restricted**. Verified ⟺ `Age ≥ 65` |
| 7 | `Married` | str | 0 | Marital status | Yes / No. Identical to merged `Partner` |
| 8 | `Dependents` | str | 0 | Has dependents | Yes / No. Verified ⟺ `Number of Dependents > 0` |
| 9 | `Number of Dependents` | int | 0 | Count of dependents | ≥ 0 |

**Verified internal consistency:** all three derived flags (`Under 30`, `Senior Citizen`, `Dependents`) agree with their underlying continuous fields with **zero exceptions**.

---

## Table: `location` — 7,043 × 9

**PK:** `Customer ID` · **Grain:** one row per customer · **Duplicates:** 0

| # | Field | Type | Nulls | Description | Observed values |
|---|-------|------|-------|-------------|-----------------|
| 1 | `Customer ID` | str | 0 | FK → demographics | 7,043 distinct |
| 2 | `Count` | int | 0 | BI artefact | Constant `1` — **drop** |
| 3 | `Country` | str | 0 | Country | Constant `United States` — **drop** |
| 4 | `State` | str | 0 | State | Constant `California` — **drop** |
| 5 | `City` | str | 0 | City | Multiple |
| 6 | `Zip Code` | int | 0 | **FK → population** | 1,626 distinct; max 43 customers per zip |
| 7 | `Lat Long` | str | 0 | Combined composite | Redundant — **drop** |
| 8 | `Latitude` | float | 0 | Latitude | Out of scope |
| 9 | `Longitude` | float | 0 | Longitude | Out of scope |

---

## Table: `population` — 1,671 × 3

**PK:** `ID` · **Unique:** `Zip Code` · **Grain:** one row per zip code

| # | Field | Type | Nulls | Description |
|---|-------|------|-------|-------------|
| 1 | `ID` | int | 0 | Surrogate key, unique |
| 2 | `Zip Code` | int | 0 | **Join key from `location`** — unique |
| 3 | `Population` | int | 0 | Population of the zip code area |

**Referential integrity verified:** all 1,626 customer zip codes exist in `population`. 45 zips have no customers (lookup superset, not an error). **Zero orphans.**

---

## Table: `services` — 7,043 × 30

**PK:** `Customer ID` · **Grain:** one row per customer per quarter — **only Q3 present** · **Duplicates:** 0

| # | Field | Type | Nulls | Description | Observed values |
|---|-------|------|-------|-------------|-----------------|
| 1 | `Customer ID` | str | 0 | FK → demographics | 7,043 distinct |
| 2 | `Count` | int | 0 | BI artefact | Constant `1` — **drop** |
| 3 | `Quarter` | str | 0 | Reporting quarter | **Constant `Q3`** — schema anticipates a time dimension that does not exist here |
| 4 | `Referred a Friend` | str | 0 | Referral flag | Yes 3,222 / No 3,821 |
| 5 | `Number of Referrals` | int | 0 | Referral count | ≥ 0 |
| 6 | `Tenure in Months` | int | 0 | **Months with the company** | **1–72. No zeros** |
| 7 | `Offer` | str | **0 true nulls** | Promotional offer held | A 520 · B 824 · C 415 · D 602 · E 805 · **literal `'None'` token × 3,877 → mapped to `'No offer'` ** |
| 8 | `Phone Service` | str | 0 | Home phone subscription | Yes 6,361 / No 682 |
| 9 | `Avg Monthly Long Distance Charges` | float | 0 | Average monthly long-distance | 0.00–49.99. **Separate from `Monthly Charge`** |
| 10 | `Multiple Lines` | str | 0 | Multiple telephone lines | Yes 2,971 / No 4,072 |
| 11 | `Internet Service` | str | 0 | Internet subscription | Yes 5,517 / No 1,526 |
| 12 | `Internet Type` | str | **0 true nulls** | Technology | Fiber Optic 3,035 · DSL 1,652 · Cable 830 · **literal `'None'` token × 1,526 ⟺ `Internet Service = 'No'` (verified) → mapped to `'No internet'` ** |
| 13 | `Avg Monthly GB Download` | int | 0 | Average monthly data usage | ≥ 0 |
| 14 | `Online Security` | str | 0 | Add-on | Yes 2,019 / No 5,024 |
| 15 | `Online Backup` | str | 0 | Add-on | Yes 2,429 / No 4,614 |
| 16 | `Device Protection Plan` | str | 0 | Add-on | Yes 2,422 / No 4,621 |
| 17 | `Premium Tech Support` | str | 0 | Add-on | Yes 2,044 / No 4,999 |
| 18 | `Streaming TV` | str | 0 | Add-on | Yes 2,707 / No 4,336 |
| 19 | `Streaming Movies` | str | 0 | Add-on | Yes 2,732 / No 4,311 |
| 20 | `Streaming Music` | str | 0 | Add-on | Yes 2,488 / No 4,555 |
| 21 | `Unlimited Data` | str | 0 | Add-on | Yes 4,745 / No 2,298 |
| 22 | `Contract` | str | 0 | **Contract type** | Month-to-Month 3,610 · One Year 1,550 · Two Year 1,883 |
| 23 | `Paperless Billing` | str | 0 | Billing preference | Yes 4,171 / No 2,872 |
| 24 | `Payment Method` | str | 0 | **Payment method** | Bank Withdrawal 3,909 · Credit Card 2,749 · Mailed Check 385 |
| 25 | `Monthly Charge` | float | 0 | **Recurring monthly subscription charge** | 18.25–118.75, median 70.35, mean 64.76. **No zeros or negatives** |
| 26 | `Total Charges` | float | 0 | Cumulative subscription charges to date | Sum 16,060,725.24 |
| 27 | `Total Refunds` | float | 0 | Cumulative refunds | ≥ 0 |
| 28 | `Total Extra Data Charges` | int | 0 | Cumulative excess data charges | ≥ 0 |
| 29 | `Total Long Distance Charges` | float | 0 | Cumulative long-distance charges | ≈ `Avg Monthly LD × tenure` (median ratio 1.0000) |
| 30 | `Total Revenue` | float | 0 | **Total revenue to date** | Sum 21,371,131.69 |

**All eight add-on fields use clean `Yes`/`No` only.** The `No internet service` / `No phone service` sentinels exist **only in the merged file**.

---

## Table: `status` — 7,043 × 11

**PK:** `Customer ID` · **Grain:** one row per customer per quarter — **only Q3 present** · **Duplicates:** 0

| # | Field | Type | Nulls | Description | Observed values |
|---|-------|------|-------|-------------|-----------------|
| 1 | `Customer ID` | str | 0 | FK → demographics | 7,043 distinct |
| 2 | `Count` | int | 0 | BI artefact | Constant `1` — **drop** |
| 3 | `Quarter` | str | 0 | Reporting quarter | Constant `Q3` |
| 4 | `Satisfaction Score` | int | 0 | Satisfaction rating | 1–5. ❌ **EXCLUDED — recorded with knowledge of the outcome (F-EX-08)** |
| 5 | `Customer Status` | str | 0 | **Period-end status** | Stayed 4,720 · Churned 1,869 · **Joined 454** |
| 6 | `Churn Label` | str | 0 | Churn indicator | Yes 1,869 / No 5,174 |
| 7 | `Churn Value` | int | 0 | **Authoritative churn flag** | 1 = 1,869 · 0 = 5,174. **Perfect agreement with `Churn Label`** |
| 8 | `Churn Score` | int | 0 | Predicted churn likelihood | 0–100. ❌ **EXCLUDED — model output (F-EX-01)** |
| 9 | `CLTV` | int | 0 | Predicted lifetime value | ❌ **EXCLUDED — project 07 scope (F-EX-02)** |
| 10 | `Churn Category` | str | **5,174 (73.5%)** | Churn category | Competitor 841 · Attitude 314 · Dissatisfaction 303 · Price 211 · Other 200. ❌ **EXCLUDED (F-EX-09)** |
| 11 | `Churn Reason` | str | **5,174 (73.5%)** | Specific churn reason | ❌ **EXCLUDED as diagnostic (F-EX-03)** |

**`Customer Status` is the most consequential field the merged file lacks.** The 454 `Joined` customers (tenure 1–3 months) create a churn-denominator decision: 26.54% on all rows, 28.37% excluding joiners.

---

## Revenue Field Interpretation — Verified

### The revenue identity ✅

```
Total Revenue = Total Charges − Total Refunds
              + Total Extra Data Charges + Total Long Distance Charges
```

**Holds for 7,043 of 7,043 rows. Maximum absolute difference: 0.000000.**

Verified, but per portfolio policy every revenue aggregate will still be **recomputed from customer grain**, never taken from a pre-aggregated field.

### `Monthly Charge` — the unit of account ✅

**Confirmed a stable recurring rate**, not a one-month billed amount:

| Test | Result |
|---|---|
| Median `Total Charges` ÷ (`Monthly Charge` × tenure) | **1.0000** |
| Within ±5% | 80.4% |
| Within ±15% | 97.9% |

Annualisation (`× 12`) is therefore evidence-supported. Assumption A-03 stands, declared.

### ⚠️ `Monthly Charge` excludes long-distance revenue

`Total Long Distance Charges` ≈ `Avg Monthly Long Distance Charges` × tenure independently (median ratio 1.0000, 90.3% within ±1%). **`Monthly Charge` is the recurring subscription only.**

**Definition used:** revenue at risk is `Monthly Charge × 12`, the contractually recurring element a retention offer protects. Long-distance revenue is measured separately and reported alongside. See [Methodology](../methodology.md).

### `Total Charges` — resolved

Cumulative lifetime-to-date, not quarter-bounded. IBM's published description is loose. **Historical, therefore not the basis for forward-looking revenue at risk** — a validation field.

---

## Derived Fields

| Field | Type | Calculation | Purpose |
|-------|------|-------------|---------|
| `is_churned` | boolean | `Churn Value = 1` | Outcome flag |
| `is_new_joiner` | boolean | `Customer Status = 'Joined'` | Denominator control — **C-3** |
| `tenure_band` | text | `CASE` over `Tenure in Months` — **cut points fixed before results were reviewed** | Lifecycle segmentation |
| `annualised_revenue` | numeric | `Monthly Charge × 12` | Revenue-at-risk basis — **subject to C-2** |
| `revenue_decile` | int | `NTILE(10) OVER (ORDER BY monthly_charge, customer_id)` | Value segmentation. **Deterministic tie-break (V-11)** — without it, membership could shift between runs at the Mid/High boundary |
| `service_count` | int | Count of `Yes` across the 8 add-on fields | Service intensity. Clean binary — no sentinel handling needed |

---

## Units and Conventions

| Concept | Convention |
|---------|-----------|
| Currency | **Unknown — no evidence in source.** Present unitless or as "currency units". **Never as £** |
| Revenue basis | `Monthly Charge` × 12, subject to C-2 |
| Tenure | Whole months, 1–72 |
| Churn | `Churn Value` authoritative; `Churn Label` verified in perfect agreement |
| Churn denominator | **Undecided — C-3** |
| Nulls | **Two conventions in the source.** `services` uses a literal `'None'` token (0 true nulls); `status` uses true nulls. Both are **structural**, never missing. Never impute. See [Data Quality](data-quality.md) |
| Decile assignment | `NTILE(10) OVER (ORDER BY monthly_charge, customer_id)` — deterministic tie-break per V-11 |

---

## Data Quality Summary — Verified

| Measure | Result |
|---|---|
| Rows | 7,043 in all four customer tables; 1,671 in population |
| Duplicate customer IDs | **0** |
| Null keys | **0** |
| Orphan records | **0** in every relationship |
| Genuine missing values | **0** — every absent value is structural  |
| True null cells in `services` | **0** — uses a literal `'None'` token instead |
| True null cells in `status` | 10,348 — genuinely empty cells |
| Invalid charges (zero/negative) | **0** |
| Tenure zeros | **0** |
| Overall completeness | **100%** on all non-structural fields |

---

## Confirmed Relationships

| From | To | Key | Cardinality | Orphans |
|---|---|---|---|---|
| demographics | location | `Customer ID` | **1:1** | 0 |
| demographics | services | `Customer ID` | **1:1** | 0 |
| demographics | status | `Customer ID` | **1:1** | 0 |
| location | population | `Zip Code` | **N:1** | 0 |

**Final analytical grain:** one row per customer, 7,043.

**Fan-out:** none in the customer joins — all strictly 1:1. `location → population` is N:1 and safe in that direction; the reverse would multiply up to 43×.

---

## Excluded and Restricted Fields

| Field | Status | Reason |
|-------|--------|--------|
| `Churn Score` | ❌ Exclude | Model output — target leakage (F-EX-01) |
| `CLTV` | ❌ Exclude | Project 07 scope; undocumented prediction (F-EX-02) |
| `Churn Reason` | ❌ Exclude as diagnostic | Outcome-derived; post-analysis sanity check only (F-EX-03) |
| `Satisfaction Score` | ❌ Exclude | **Outcome-contaminated — 100% churn at scores 1–2, 0% at 4–5 (F-EX-08)** |
| `Churn Category` | ❌ Exclude as diagnostic | Same basis as `Churn Reason` (F-EX-09) |
| `Count`, `Country`, `State`, `Lat Long` | ❌ Drop | Confirmed constant / redundant |
| `Latitude`, `Longitude` | ❌ Out of scope | No business question requires geospatial analysis |
| `Gender`, `Age`, `Under 30`, `Senior Citizen` | ⚠️ **Restricted** | Protected characteristics — descriptive and confounding checks only, never a prioritisation rule (F-EX-07) |
