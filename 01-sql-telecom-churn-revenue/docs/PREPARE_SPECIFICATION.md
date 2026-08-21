# PREPARE Specification — Project 01

## Telecommunications Revenue Retention: Prioritising Retention Investment by Revenue at Risk

**Stage:** 4 — PREPARE (technical design)
**Status:** 🔴 **PROPOSED — awaiting approval. No SQL written. No analysis run.**
**Prepared:** 19 August 2026

> **Methodology is immutable.** C-1 to C-6 are locked. Nothing in this document reinterprets an approved definition. If implementation uncovers a genuine data-quality or structural contradiction, work stops and the contradiction returns for review — it is not resolved by quietly adjusting a definition.

---

# 1. PostgreSQL Staging Architecture

Three schemas, each with one job. The separation is the mechanism that makes the approved exclusions **structurally enforced** rather than merely documented.

```
┌──────────────────────────────────────────────────────────────────────┐
│  raw                                                                 │
│  Landing zone. Everything as-supplied, all columns TEXT.             │
│  Immutable after load. Includes excluded fields — for completeness   │
│  and reconciliation only. NEVER queried by analysis.                 │
│                                                                      │
│  raw.demographics · raw.location · raw.population                    │
│  raw.services · raw.status · raw.merged_reconciliation               │
└────────────────────────────┬─────────────────────────────────────────┘
                             │  typed, keyed, constrained
                             │  EXCLUDED FIELDS DROPPED HERE
                             ▼
┌──────────────────────────────────────────────────────────────────────┐
│  core                                                                │
│  Typed, constrained, referentially enforced. One row per customer.   │
│  Excluded fields are ABSENT — not filtered, absent.                  │
│  Restricted fields isolated in a separate table not joined by marts. │
│                                                                      │
│  core.dim_customer · core.dim_location · core.dim_population         │
│  core.dim_contract · core.fact_customer_status                       │
│  core.dim_service · core.bridge_customer_service                     │
│  core.restricted_demographics  ← quarantined, see §21                │
└────────────────────────────┬─────────────────────────────────────────┘
                             │  derived attributes, KPI logic
                             ▼
┌──────────────────────────────────────────────────────────────────────┐
│  analytics                                                           │
│  Segmentation, KPI views, the analytical surface.                    │
│                                                                      │
│  analytics.vw_customer_analytical_base   ← the single analysis grain │
│  analytics.vw_kpi_* · analytics.vw_segment_* · analytics.vw_driver_* │
└──────────────────────────────────────────────────────────────────────┘
```

**Why `raw` is all-TEXT.** Loading everything as text and casting on promotion means a type failure surfaces as an explicit, catchable error at a known step rather than as a silent coercion at load time. It also means the landing zone is a faithful record of what was supplied.

**Why excluded fields are dropped rather than filtered.** A field absent from `core` cannot be used by accident. `Churn Reason` sitting in an analytical table with a comment saying "do not use" is an invitation; `Churn Reason` not existing in `core` is a control.

### Extraction step

The source is `.xlsx`. Loading requires a CSV intermediate.

| Step | Method |
|---|---|
| 1 | Convert each of the five workbooks to UTF-8 CSV, one sheet each, headers preserved verbatim |
| 2 | `\copy` each CSV into its `raw` table |
| 3 | Record row counts at each hop and assert against the verified figures in §10 |

**Decision D-17 (new, for the log):** the xlsx→CSV conversion is an **extraction utility, not analysis**. It touches no values, makes no interpretive choice, and is documented so a reviewer can repeat it. It does not alter the Stage 1 decision that this project's analysis is SQL. The conversion command will be recorded in `sql/00_setup/README.md`.

---

# 2. Source-to-Staging Mapping

All 59 source columns across five tables. **Verbatim source names → snake_case targets** per `SQL_STANDARDS.md` §8.

## 2.1 `demographics` → `core.dim_customer` + `core.restricted_demographics`

| Source column | Source type | → Target | Target type | Layer | Note |
|---|---|---|---|---|---|
| `Customer ID` | text(10) | `customer_id` | `varchar(10)` | core | **PK** |
| `Count` | int const 1 | — | — | **dropped** | BI artefact (D-15/F-EX-05) |
| `Gender` | text | `gender` | `varchar(10)` | **restricted** | Protected characteristic |
| `Age` | int 19–80 | `age` | `smallint` | **restricted** | Protected characteristic |
| `Under 30` | text Y/N | `is_under_30` | `boolean` | **restricted** | Derived from `Age`; verified ⟺ `Age < 30` |
| `Senior Citizen` | text Y/N | `is_senior_citizen` | `boolean` | **restricted** | Derived from `Age`; verified ⟺ `Age ≥ 65` |
| `Married` | text Y/N | `is_married` | `boolean` | core | Household proxy |
| `Dependents` | text Y/N | `has_dependents` | `boolean` | core | Verified ⟺ `Number of Dependents > 0` |
| `Number of Dependents` | int 0–9 | `dependent_count` | `smallint` | core | |

## 2.2 `location` → `core.dim_location`

| Source column | → Target | Target type | Note |
|---|---|---|---|
| `Customer ID` | `customer_id` | `varchar(10)` | **PK / FK → dim_customer** |
| `Count` | — | — | **dropped** — constant 1 |
| `Country` | — | — | **dropped** — constant `United States` |
| `State` | — | — | **dropped** — constant `California` |
| `City` | `city` | `varchar(64)` | |
| `Zip Code` | `zip_code` | `char(5)` | **FK → dim_population.** Stored as **text**, not integer — zip codes are identifiers, not quantities, and leading zeros must survive. Range observed 90001–96150 |
| `Lat Long` | — | — | **dropped** — redundant composite |
| `Latitude` | `latitude` | `numeric(9,6)` | Loaded; out of analytical scope |
| `Longitude` | `longitude` | `numeric(9,6)` | Loaded; out of analytical scope |

## 2.3 `population` → `core.dim_population`

| Source column | → Target | Target type | Note |
|---|---|---|---|
| `ID` | `population_id` | `integer` | Surrogate, unique 1–1671 |
| `Zip Code` | `zip_code` | `char(5)` | **PK** — unique, the join target |
| `Population` | `population` | `integer` | 11–105,285 |

## 2.4 `services` → `core.dim_contract` + `core.fact_customer_status` + `core.bridge_customer_service`

| Source column | → Target | Target type | Target table | Note |
|---|---|---|---|---|
| `Customer ID` | `customer_id` | `varchar(10)` | all three | **PK / FK** |
| `Count` | — | — | — | **dropped** — constant 1 |
| `Quarter` | `quarter` | `char(2)` | fact | Constant `Q3`. **Retained deliberately** — it documents that a period dimension exists and holds one value |
| `Referred a Friend` | `has_referred` | `boolean` | dim_contract | Driver lens L7 |
| `Number of Referrals` | `referral_count` | `smallint` | dim_contract | 0–11. Lens L7 |
| `Tenure in Months` | `tenure_months` | `smallint` | fact | 1–72, **no zeros** |
| `Offer` | `offer` | `varchar(10)` | dim_contract | 3,877 nulls → `'No offer'`, see §7. Lens L6 |
| `Phone Service` | service flag | `boolean` | **bridge** | See §2.5 |
| `Avg Monthly Long Distance Charges` | `avg_monthly_long_distance` | `numeric(12,4)` | fact | 0.00–49.99. **Separate component, C-2** |
| `Multiple Lines` | service flag | `boolean` | **bridge** | |
| `Internet Service` | service flag | `boolean` | **bridge** | |
| `Internet Type` | `internet_type` | `varchar(12)` | dim_contract | 1,526 nulls → `'No internet'`, see §7. Lens L4 |
| `Avg Monthly GB Download` | `avg_monthly_gb` | `smallint` | fact | 0–85 |
| `Online Security` | service flag | `boolean` | **bridge** | Add-on (L5 set) |
| `Online Backup` | service flag | `boolean` | **bridge** | Add-on (L5 set) |
| `Device Protection Plan` | service flag | `boolean` | **bridge** | Add-on (L5 set) |
| `Premium Tech Support` | service flag | `boolean` | **bridge** | Add-on (L5 set) |
| `Streaming TV` | service flag | `boolean` | **bridge** | Add-on (L5 set) |
| `Streaming Movies` | service flag | `boolean` | **bridge** | Add-on (L5 set) |
| `Streaming Music` | service flag | `boolean` | **bridge** | Add-on (L5 set) |
| `Unlimited Data` | service flag | `boolean` | **bridge** | Add-on (L5 set) |
| `Contract` | `contract_type` | `varchar(16)` | dim_contract | **Lens L1.** Values kept verbatim: `Month-to-Month`, `One Year`, `Two Year` |
| `Paperless Billing` | `is_paperless_billing` | `boolean` | dim_contract | |
| `Payment Method` | `payment_method` | `varchar(20)` | dim_contract | **Lens L3.** `Bank Withdrawal`, `Credit Card`, `Mailed Check` |
| `Monthly Charge` | `monthly_charge` | `numeric(12,4)` | fact | **THE UNIT OF ACCOUNT (C-2).** 18.25–118.75 |
| `Total Charges` | `total_charges` | `numeric(12,4)` | fact | Lifetime cumulative. **Validation only — never the revenue-at-risk basis** |
| `Total Refunds` | `total_refunds` | `numeric(12,4)` | fact | 0.00–49.79 |
| `Total Extra Data Charges` | `total_extra_data_charges` | `numeric(12,4)` | fact | 0–150 |
| `Total Long Distance Charges` | `total_long_distance_charges` | `numeric(12,4)` | fact | 0.00–3,564.72 |
| `Total Revenue` | `total_revenue_source` | `numeric(12,4)` | fact | **Loaded for reconciliation only.** Recomputed independently, never trusted (§10) |

**Note on precision.** `Total Long Distance Charges` and `Total Revenue` carry up to 16 decimal places in the source — binary floating-point artefacts, not meaningful precision. Monetary columns are stored as **`numeric(12,4)`** and rounded to 2dp only at presentation. Storing at 2dp would break the exact revenue identity verified in Stage 2.

## 2.5 The eleven service flags → `core.bridge_customer_service`

Unpivoted from eleven wide `Yes`/`No` columns into a long bridge.

| `service_code` | `service_name` | `service_group` | In L5 add-on count? |
|---|---|---|---|
| `PHONE` | Phone Service | Core | ❌ |
| `MULTI_LINE` | Multiple Lines | Core | ❌ |
| `INTERNET` | Internet Service | Core | ❌ |
| `ONLINE_SEC` | Online Security | Add-on | ✅ |
| `ONLINE_BAK` | Online Backup | Add-on | ✅ |
| `DEV_PROT` | Device Protection Plan | Add-on | ✅ |
| `TECH_SUP` | Premium Tech Support | Add-on | ✅ |
| `STREAM_TV` | Streaming TV | Entertainment | ✅ |
| `STREAM_MOV` | Streaming Movies | Entertainment | ✅ |
| `STREAM_MUS` | Streaming Music | Entertainment | ✅ |
| `UNLIM_DATA` | Unlimited Data | Add-on | ✅ |

⚠️ **The L5 service-intensity band counts the eight `Add-on`/`Entertainment` services only** — exactly the set locked in the FRAME specification. `PHONE`, `MULTI_LINE` and `INTERNET` are in the bridge for service-mix analysis but are **not** in the intensity count. The `service_group` column enforces this so the count cannot drift.

## 2.6 `status` → `core.fact_customer_status` (+ dropped)

| Source column | → Target | Target type | Note |
|---|---|---|---|
| `Customer ID` | `customer_id` | `varchar(10)` | **PK / FK** |
| `Count` | — | — | **dropped** — constant 1 |
| `Quarter` | (already in fact from services) | — | Cross-checked for agreement, then not duplicated |
| `Satisfaction Score` | — | — | ❌ **DROPPED — D-14.** Outcome-contaminated |
| `Customer Status` | `customer_status` | `varchar(10)` | Loaded. **Verified derived** — see §14 |
| `Churn Label` | — | — | Dropped after agreement check; `churn_value` is authoritative |
| `Churn Value` | `is_churned` | `boolean` | **Authoritative outcome** |
| `Churn Score` | — | — | ❌ **DROPPED — D-11.** Model output, leakage |
| `CLTV` | — | — | ❌ **DROPPED — D-12.** Project 07 scope |
| `Churn Category` | — | — | ❌ **DROPPED — D-13** |
| `Churn Reason` | — | — | ❌ **DROPPED — D-13** |

**Five fields are dropped at the `raw` → `core` boundary and exist nowhere in the analytical layer.**

---

# 3. Confirmed Grain

| Table | Grain | Expected rows |
|---|---|---|
| `core.dim_customer` | one row per customer | 7,043 |
| `core.restricted_demographics` | one row per customer | 7,043 |
| `core.dim_location` | one row per customer | 7,043 |
| `core.dim_population` | one row per zip code | 1,671 |
| `core.dim_contract` | one row per customer | 7,043 |
| `core.fact_customer_status` | one row per customer per quarter (**one quarter present**) | 7,043 |
| `core.dim_service` | one row per service | 11 |
| `core.bridge_customer_service` | **one row per customer × subscribed service** | ≤ 77,473 (7,043 × 11); actual determined by load |
| `analytics.vw_customer_analytical_base` | **one row per customer** | **7,043 — asserted** |

---

# 4. Primary and Foreign Keys

| Table | Primary key | Foreign keys |
|---|---|---|
| `core.dim_customer` | `customer_id` | — |
| `core.restricted_demographics` | `customer_id` | → `dim_customer` |
| `core.dim_location` | `customer_id` | → `dim_customer`; `zip_code` → `dim_population` |
| `core.dim_population` | `zip_code` | — |
| `core.dim_contract` | `customer_id` | → `dim_customer` |
| `core.fact_customer_status` | `customer_id` | → `dim_customer` |
| `core.dim_service` | `service_code` | — |
| `core.bridge_customer_service` | `(customer_id, service_code)` | → `dim_customer`, → `dim_service` |

All constraints declared as **enforced database constraints**, not conventions. A referential-integrity violation should fail the load, not appear as a wrong number three queries later.

---

# 5. Relationship Model

```
                          core.dim_customer
                          PK customer_id  (7,043)
                                 │
        ┌────────────┬───────────┼───────────┬──────────────────┐
        │ 1:1        │ 1:1       │ 1:1       │ 1:1              │ 1:N
        ▼            ▼           ▼           ▼                  ▼
 restricted_    dim_location  dim_contract  fact_customer   bridge_customer
 demographics        │                        _status          _service
 (quarantined)       │ N:1                                        │ N:1
                     ▼                                            ▼
              dim_population                                 dim_service
              PK zip_code (1,671)                            PK service_code (11)
```

**Verified cardinality (Stage 2):** all customer relationships **1:1**, zero orphans in either direction. `dim_location → dim_population` is **N:1**, complete referential integrity, max 43 customers per zip.

**The only fan-out is `bridge_customer_service`.** Joining it multiplies customer rows. §22 specifies the control.

---

# 6. Data Types

| Domain | Type | Rationale |
|---|---|---|
| Customer identifier | `varchar(10)` | Observed max length 10, format `NNNN-XXXXX` |
| Zip code | `char(5)` | **Identifier, not a quantity.** Text preserves leading zeros; no arithmetic is meaningful |
| Yes/No flags | `boolean` | All verified strictly two-valued in the relational source. Cast `'Yes' → true`, `'No' → false`; **any third value raises an error rather than defaulting** |
| Money | `numeric(12,4)` | Exact decimal. **Never `float`** — the source's 16-decimal artefacts are binary noise, and monetary arithmetic must not inherit floating-point error |
| Counts, tenure, age | `smallint` | All observed ranges fit comfortably |
| Population | `integer` | Max 105,285 |
| Lat/long | `numeric(9,6)` | 6 decimal places observed |
| Categorical | `varchar(n)` sized to observed max | Values kept **verbatim** from source — no re-labelling, so any future comparison to source is direct |

---

# 7. Null-Handling Rules

Stage 2 established that **the relational source contains no genuine missing values.** All four nullable columns are structural. Each therefore gets an explicit, documented treatment — **none is imputed**.

| Column | Nulls | Rule | Justification |
|---|---|---|---|
| `Offer` | 3,877 (55.0%) | → `'No offer'` (a category) | Absence of an offer is a meaningful commercial state, not missing data. Lens L6 requires it as a comparison group |
| `Internet Type` | 1,526 (21.7%) | → `'No internet'` (a category) | Verified to correspond **exactly** to `Internet Service = 'No'`. Structural dependency, not absence |
| `Churn Category` | 5,174 | n/a — field dropped | D-13 |
| `Churn Reason` | 5,174 | n/a — field dropped | D-13 |

**Standing rules:**

1. **No imputation anywhere.** Not for revenue, not for tenure, not for categoricals.
2. **`NOT NULL` on every promoted `core` column.** If a null reaches `core`, the load fails and the cause is investigated — it would mean the Stage 2 profile was wrong.
3. **"Not applicable" and "not recorded" are never conflated.** Both structural nulls above are *not applicable* and are labelled as such.
4. Any *new* null found during load is a **structural contradiction** under the immutability rule — stop and escalate.

---

# 8. Referential-Integrity Checks

Run after every `core` load. Each must return zero rows.

| ID | Check | Expected |
|---|---|---|
| RI-01 | `dim_location` customer_ids not in `dim_customer` | 0 |
| RI-02 | `dim_contract` customer_ids not in `dim_customer` | 0 |
| RI-03 | `fact_customer_status` customer_ids not in `dim_customer` | 0 |
| RI-04 | `restricted_demographics` customer_ids not in `dim_customer` | 0 |
| RI-05 | `dim_customer` customer_ids missing from any of the four | 0 |
| RI-06 | `dim_location.zip_code` not in `dim_population` | 0 |
| RI-07 | `bridge_customer_service.customer_id` not in `dim_customer` | 0 |
| RI-08 | `bridge_customer_service.service_code` not in `dim_service` | 0 |

RI-06 is expected to pass in one direction only: 45 population zip codes have no customers. That is a **lookup superset, not an orphan**, and the check is written directionally so it does not raise a false failure.

---

# 9. Duplicate Checks

| ID | Check | Expected |
|---|---|---|
| DUP-01 | `count(*)` vs `count(distinct customer_id)` in each customer table | Equal, 7,043 |
| DUP-02 | Duplicate `zip_code` in `dim_population` | 0 |
| DUP-03 | Duplicate `(customer_id, service_code)` in the bridge | 0 |
| DUP-04 | Duplicate `service_code` in `dim_service` | 0 |
| DUP-05 | Null keys anywhere | 0 |

---

# 10. Source Reconciliation Checks

Every check asserts against a **Stage 2 verified figure**. A mismatch means the load is wrong.

## Row counts

| ID | Assertion | Expected |
|---|---|---|
| REC-01 | `raw` rows = source workbook rows | 7,043 × 4; 1,671 |
| REC-02 | `core` rows = `raw` rows | No loss at promotion |
| REC-03 | `analytics.vw_customer_analytical_base` rows | **7,043 exactly** |

## Customer set

| ID | Assertion | Expected |
|---|---|---|
| REC-04 | Identical `customer_id` sets across all four core customer tables | Symmetric difference empty |

## Churn

| ID | Assertion | Expected |
|---|---|---|
| REC-05 | `count(*) where is_churned` | **1,869** |
| REC-06 | `customer_status` distribution | Stayed 4,720 · Churned 1,869 · Joined 454 |
| REC-07 | `Churn Label` vs `Churn Value` agreement in `raw` | 7,043/7,043 before `Churn Label` is dropped |

## Revenue

| ID | Assertion | Expected |
|---|---|---|
| REC-08 | **Revenue identity recomputed:** `total_charges − total_refunds + total_extra_data_charges + total_long_distance_charges` vs `total_revenue_source` | Max absolute difference ≤ 0.01 across 7,043 rows |
| REC-09 | `sum(monthly_charge)` | Reconciles to the Stage 2 profile |
| REC-10 | `sum(total_charges)` | **16,060,725.24** |
| REC-11 | `min/max monthly_charge` | 18.25 / 118.75 |
| REC-12 | `min/max tenure_months` | 1 / 72; **count where tenure = 0 is zero** |

**REC-08 is the reconciliation of record.** Per the standing rule, `total_revenue_source` is loaded but **never used** — it exists so the recomputation has something to be checked against.

## Merged-workbook cross-check (C-1)

`raw.merged_reconciliation` is loaded **for these checks only** and is never joined into `core` or `analytics`.

| ID | Assertion | Expected |
|---|---|---|
| REC-13 | `monthly_charge` agreement | 7,043/7,043 |
| REC-14 | `churn_value` agreement | 7,043/7,043 |
| REC-15 | Tenure disagreement | **Exactly 11** (the known merged-file defect) |
| REC-16 | `Total Charges` blank in merged | **Exactly 11**, same customers as REC-15 |
| REC-17 | Payment-method disagreement | **1,227** reclassified + `Electronic check` absent from source |
| REC-18 | Internet-type disagreement | **830** Cable customers absorbed into DSL (769) / Fiber (61) |

REC-15 to REC-18 are expected to **fail agreement** — they reproduce the documented defects that justified C-1. They pass by matching the expected disagreement counts exactly. If a count differs, the C-1 evidence base needs re-examination.

---

# 11. Analytical Model

`analytics.vw_customer_analytical_base` is the single analytical grain. **Every analysis query selects from it.** Building the derived attributes once, in one place, is what prevents a definition drifting between queries.

| Attribute | Derivation | Locked by |
|---|---|---|
| `customer_id` | PK | — |
| `is_churned` | from `fact_customer_status` | — |
| `tenure_months` | from `fact_customer_status` | — |
| `monthly_charge` | from `fact_customer_status` | C-2 |
| `annual_recurring_revenue` | `monthly_charge × 12` | **C-2** |
| `annual_long_distance_revenue` | `avg_monthly_long_distance × 12` | **C-2 — separate component** |
| `cohort_class` | `'opening_base'` if `tenure_months ≥ 4`, else `'in_period_acquisition'` | **C-3** |
| `tenure_band` | 5 bands, §15 | **C-6** |
| `revenue_decile` | `NTILE(10) OVER (ORDER BY monthly_charge)` | **C-6** |
| `value_tier` | deciles 8–10 High · 4–7 Mid · 1–3 Low | **C-6** |
| `contract_type` | from `dim_contract` | — |
| `payment_method` | from `dim_contract` | — |
| `internet_type` | from `dim_contract`, nulls → `'No internet'` | — |
| `offer` | from `dim_contract`, nulls → `'No offer'` | — |
| `has_referred`, `referral_count` | from `dim_contract` | — |
| `addon_service_count` | count over the bridge **where `service_group <> 'Core'`** | **C-6 — the locked 8** |
| `service_intensity_band` | 0 None · 1–2 Light · 3–4 Moderate · 5–8 Deep | **C-6** |

**`addon_service_count` is the only attribute requiring the bridge**, and it is aggregated to customer grain **inside the view**. Downstream queries therefore never touch the bridge and cannot fan out. This is the primary fan-out control.

---

# 12. KPI Definitions and SQL Implementation Plan

| KPI | Definition | Implementation | View |
|---|---|---|---|
| **Opening-cohort churn rate** | `churned(tenure≥4) ÷ all(tenure≥4) × 100` | `count(*) FILTER (WHERE is_churned) / count(*)` over `cohort_class = 'opening_base'` | `vw_kpi_churn_rate` |
| **Period-end base rate** | `all churned ÷ all rows × 100` | Same over the full base | `vw_kpi_churn_rate` |
| **Early-life churn** | `churned(tenure≤3)` count and share of all churn | Filtered aggregate | `vw_kpi_early_life_churn` |
| **ARPU** | `sum(monthly_charge) ÷ count(*)` | Segment-level aggregate | `vw_kpi_arpu` |
| **Annual recurring revenue at risk** | `sum(monthly_charge) × 12` over churned | **C-2 basis** | `vw_kpi_revenue_at_risk` |
| **Annual long-distance revenue at risk** | `sum(avg_monthly_long_distance) × 12` over churned | **Separate column, never added into the headline** | `vw_kpi_revenue_at_risk` |
| **Revenue concentration** | top-decile revenue ÷ total × 100; full Pareto curve | `SUM() OVER (ORDER BY monthly_charge DESC)` cumulative | `vw_kpi_revenue_concentration` |
| **Revenue retention rate** | retained recurring ÷ opening recurring × 100 | Opening cohort basis, consistent with C-3 | `vw_kpi_revenue_retention` |
| **Churn index vs base** | segment churn rate ÷ overall churn rate | Segment aggregate ÷ scalar, `NULLIF` guarded | `vw_driver_*` |
| **Value–risk divergence index** | `RANK(churn rate DESC) − RANK(revenue at risk DESC)` | Dual `RANK()` over the P1 segment set | `vw_segment_divergence` |
| **Justifiable retention spend ceiling** | `annual revenue at risk × assumed margin × assumed success rate` | **Parameterised, never a point estimate** | Excel, not SQL |

**Guards applied throughout:** `NULLIF(denominator, 0)`; `numeric` casting before division (never integer division); rounding only in the final `SELECT`; every rate accompanied by its `n`.

**The spend ceiling is deliberately not a SQL view.** It depends on two unsourced assumptions and must be presented as a sensitivity surface, which Excel communicates better and which prevents it acquiring the false authority of a database view.

---

# 13. Revenue-at-Risk Implementation (C-2)

```
Annual Recurring Revenue at Risk (segment)
  = SUM(monthly_charge) FILTER (WHERE is_churned) × 12
```

**Rules:**

1. `monthly_charge` is the **sole** basis. `total_charges` and `total_revenue_source` are never used.
2. Long-distance revenue is computed and reported as a **separate named column**, `annual_long_distance_revenue_at_risk` — never summed into the headline.
3. **Every output carrying the headline must also carry the long-distance column.** Enforced by keeping both in the same view, so one cannot be selected without the other being visible.
4. All churned customers are included, **split by `cohort_class`** — lost revenue is lost regardless of when the customer joined (C-3).
5. **No currency symbol anywhere.** Column comments read "currency units — unknown, see DATASET_VALIDATION P-15".

---

# 14. Opening-Cohort Churn Implementation (C-3)

```
cohort_class = CASE WHEN tenure_months >= 4 THEN 'opening_base'
                    ELSE 'in_period_acquisition' END
```

**Primary KPI:**
```
opening_cohort_churn_rate
  = churned WHERE cohort_class = 'opening_base'
  ÷ all     WHERE cohort_class = 'opening_base'  × 100
```
Expected: 1,272 ÷ 5,992 = **21.23%**

**Reported alongside, always:** period-end base rate 1,869 ÷ 7,043 = **26.54%**.

**Derivation is from `tenure_months`, not from `customer_status`.** Stage 2 proved `customer_status` is itself derived from tenure and churn with zero exceptions, so deriving from tenure is equivalent, transparent, and does not depend on an opaque source field.

**Validation:** assert that `cohort_class = 'in_period_acquisition' AND NOT is_churned` reproduces `customer_status = 'Joined'` exactly (454). If it does not, the Stage 2 derivation was wrong — a structural contradiction, escalate.

---

# 15. P1 — Value Tier × Contract Segmentation (C-6)

Nine cells. The segment set for the divergence index.

```sql
value_tier = CASE WHEN revenue_decile >= 8 THEN 'High'    -- deciles 8-10
                  WHEN revenue_decile >= 4 THEN 'Mid'     -- deciles 4-7
                  ELSE 'Low' END                          -- deciles 1-3
```
× `contract_type` ∈ {`Month-to-Month`, `One Year`, `Two Year`}

**Tenure bands (L2), locked:**

| Band | Rule |
|---|---|
| `1. In-period acquisition` | 1–3 months |
| `2. First year` | 4–12 |
| `3. Second year` | 13–24 |
| `4. Established` | 25–48 |
| `5. Long tenure` | 49–72 |

**Divergence index:**
```sql
RANK() OVER (ORDER BY churn_rate DESC)
  - RANK() OVER (ORDER BY annual_revenue_at_risk DESC)
```
Reported **alongside** both underlying magnitudes and `n` — never alone (the index is ordinal, C-6).

---

# 16. P2 — Revenue Decile Segmentation (C-6)

```sql
revenue_decile = NTILE(10) OVER (ORDER BY monthly_charge)
```

Computed **once**, in `vw_customer_analytical_base`, over the **whole base** — not recomputed per segment, which would make deciles non-comparable.

Verified cell sizes 695–717. Used for concentration (BQ-02) and churn-by-value (BQ-03). Decile 1 = lowest charge; decile 10 = highest. Stated explicitly on every output, because both conventions exist in practice.

---

# 17. The Seven Driver Lenses (C-6)

Each applied **within the High value tier**, then to the whole base, and compared.

| Lens | Field | Categories | View |
|---|---|---|---|
| **L1** | `contract_type` | 3 | `vw_driver_contract` |
| **L2** | `tenure_band` | 5 | `vw_driver_tenure` |
| **L3** | `payment_method` | 3 | `vw_driver_payment` |
| **L4** | `internet_type` | 4 incl. `No internet` | `vw_driver_internet` |
| **L5** | `service_intensity_band` | 4 | `vw_driver_service_intensity` |
| **L6** | `offer` | 6 incl. `No offer` | `vw_driver_offer` |
| **L7** | `has_referred` / `referral_count` | 2 / banded | `vw_driver_referral` |

Every lens view returns the same columns: segment · `n` · churned · churn rate · churn index vs base · annual revenue at risk · long-distance revenue at risk · cell-size flag.

**All seven are reported, including those showing nothing** (C-6 commitment 3). A uniform output shape makes selective reporting visible rather than easy.

---

# 18. Minimum-Cell Rules (C-6)

```sql
cell_size_flag = CASE WHEN n >= 100 THEN 'reportable'
                      WHEN n >= 30  THEN 'caveat_required'
                      ELSE 'below_threshold' END
```

- **≥ 100** — report freely
- **30–99** — report with explicit caveat and stated `n`
- **< 30** — **not reported as a rate**; collapsed into an adjacent band or `Other`, and the collapse recorded in `DECISIONS.md`

`n` appears on **every** segment output. The flag is a column in every driver view, so a below-threshold cell cannot be silently promoted into a chart.

---

# 19. Treatment of the 597 Early-Life Churners (C-3)

These customers joined **and** left within the observation quarter — 31.9% of all churn.

| Context | Treatment |
|---|---|
| Opening-cohort churn rate | **Excluded** from both numerator and denominator — they were not in the opening base |
| Period-end base rate | Included (that rate uses all rows by definition) |
| **Revenue at risk** | **Included** — the revenue is genuinely lost. Reported under `cohort_class = 'in_period_acquisition'` |
| Early-life churn KPI | **Reported separately** as count, share of total churn, and revenue at risk |
| Driver analysis (L1–L7) | Run **separately** for each `cohort_class`, never pooled |

**Why separate rather than pooled:** early-life churn is an onboarding and acquisition-quality problem; established-base churn is a retention problem. Different budget, different owner, different intervention. Pooling them would produce a driver profile describing neither.

**This is a pre-registered structural choice, not a response to any result.** No driver analysis has been run.

---

# 20. Treatment of Long-Distance Revenue (C-2)

| Aspect | Treatment |
|---|---|
| In the headline KPI | ❌ **Excluded** |
| As a separate component | ✅ `annual_long_distance_revenue_at_risk`, in the same view as the headline |
| In the spend-ceiling scenario | ✅ As an **upside sensitivity band** |
| As a value dimension | ✅ Available for analysis in its own right |
| In documentation | ✅ Every headline figure states the long-distance component alongside |

⚠️ **Standing instruction: long-distance revenue is material and must never be characterised as economically irrelevant.** For churned customers it represents roughly 31% additional annualised exposure beyond the recurring figure. Its exclusion from the headline is a statement about *what a retention offer can secure* (a subscription, not usage volume), not about whether the revenue matters.

---

# 21. Treatment of Excluded and Restricted Fields

## Excluded — structurally absent from `core` and `analytics`

| Field | Decision | Enforcement |
|---|---|---|
| `Satisfaction Score` | D-14 | Not promoted from `raw` |
| `Churn Score` | D-11 | Not promoted from `raw` |
| `CLTV` | D-12 | Not promoted from `raw` |
| `Churn Reason` | D-13 | Not promoted from `raw` |
| `Churn Category` | D-13 | Not promoted from `raw` |

**They exist only in `raw`**, retained so the exclusion is auditable — a reviewer can confirm the field was present and deliberately not used. **No `core` or `analytics` object references them.**

## Restricted — isolated, not joined

`gender`, `age`, `is_under_30`, `is_senior_citizen` live in **`core.restricted_demographics`**, which:

- is **not joined** by `vw_customer_analytical_base` or any segment, KPI or driver view
- is referenced by exactly one script, `sql/02_eda/09_confounding_checks.sql`, whose header states its purpose and its prohibition
- carries a table comment recording D-15

**These fields must not enter any prioritisation rule or recommendation.** Physical separation makes accidental inclusion require a deliberate join, which is visible in review.

## Merged workbook

`raw.merged_reconciliation` exists for REC-13 to REC-18 only. **No `core` or `analytics` object references it.** Enforced by convention and verified by a dependency check (VAL-09).

---

# 22. Data-Quality and Validation Workflow

Six gates. **Each must pass before the next stage runs.**

```
  [1] EXTRACT        xlsx → CSV, row counts recorded
        ↓
  [2] LOAD → raw     REC-01. Text only, no casting
        ↓
  [3] PROMOTE → core REC-02 · type casts · NOT NULL · PK/FK enforced
        ↓  ── fails on any null, any bad cast, any RI violation
  [4] STRUCTURAL     RI-01→08 · DUP-01→05 · grain assertions
        ↓
  [5] RECONCILE      REC-03→18 against Stage 2 verified figures
        ↓
  [6] ANALYTICAL     VAL-01→10 below
        ↓
      ANALYSE  (only on approval)
```

## Analytical validation checks

| ID | Check | Expected |
|---|---|---|
| VAL-01 | `vw_customer_analytical_base` row count | **7,043 exactly** |
| VAL-02 | Row count before vs after every bridge join | **Unchanged** — the fan-out control |
| VAL-03 | `sum(annual_recurring_revenue)` = `sum(monthly_charge) × 12` | Exact |
| VAL-04 | Decile membership sums to 7,043; sizes 695–717 | Match Stage 2 |
| VAL-05 | Value tiers sum to 7,043; High = deciles 8–10 | Exact |
| VAL-06 | `cohort_class = 'in_period_acquisition' AND NOT is_churned` = 454 | Reproduces `Joined` |
| VAL-07 | Opening-cohort churn rate | **21.23%** (1,272 / 5,992) |
| VAL-08 | Period-end base rate | **26.54%** (1,869 / 7,043) |
| VAL-09 | **Dependency scan:** no `core`/`analytics` object references an excluded field, `restricted_demographics`, or `merged_reconciliation` | Zero references |
| VAL-10 | Every driver view returns an `n` and a `cell_size_flag` column | All seven |

**VAL-09 is the control that makes the exclusions real** rather than aspirational.

**Failure protocol.** Any failed check stops work. The failure is recorded in `DATASET_VALIDATION.md` and brought back for review. **No definition is adjusted to make a check pass.**

---

# 23. SQL Project Structure and File List

Per `SQL_STANDARDS.md` §1. **Numbered in execution order.** Every file opens with the standard header block (project, file, question, finding ID, output, author, date).

```
01-sql-telecom-churn-revenue/
└── sql/
    ├── 00_setup/
    │   ├── README.md                          Environment setup + xlsx→CSV conversion (D-17)
    │   ├── 01_create_schemas.sql              raw / core / analytics
    │   ├── 02_create_raw_tables.sql           6 tables, all TEXT
    │   ├── 03_load_raw.sql                    \copy from CSV
    │   ├── 04_create_core_tables.sql          DDL + PK/FK/NOT NULL/CHECK
    │   ├── 05_create_dim_service.sql          11 service reference rows
    │   └── 06_create_indexes.sql              Join keys + filter columns
    │
    ├── 01_cleaning/
    │   ├── 01_promote_dim_customer.sql
    │   ├── 02_promote_restricted_demographics.sql   ⚠️ quarantined
    │   ├── 03_promote_dim_location.sql
    │   ├── 04_promote_dim_population.sql
    │   ├── 05_promote_dim_contract.sql              null → 'No offer' / 'No internet'
    │   ├── 06_promote_fact_customer_status.sql
    │   ├── 07_build_bridge_customer_service.sql     unpivot 11 flags
    │   └── 08_cleaning_reconciliation.sql           REC-01, REC-02
    │
    ├── 02_eda/
    │   ├── 01_referential_integrity.sql             RI-01→08
    │   ├── 02_duplicate_checks.sql                  DUP-01→05
    │   ├── 03_source_reconciliation.sql             REC-03→12
    │   ├── 04_merged_cross_check.sql                REC-13→18
    │   ├── 05_analytical_validation.sql             VAL-01→10
    │   ├── 06_distribution_profile.sql
    │   ├── 07_segment_cell_sizes.sql                min-cell verification
    │   ├── 08_categorical_inventory.sql
    │   └── 09_confounding_checks.sql                ⚠️ restricted fields, descriptive only
    │
    ├── 03_analysis/                                 ← ANALYSE stage, not written now
    │   ├── 01_base_position.sql                     AQ-01 → F-01
    │   ├── 02_revenue_concentration.sql             AQ-02 → F-02
    │   ├── 03_churn_by_revenue_decile.sql           AQ-03 → F-03
    │   ├── 04_value_risk_divergence.sql             AQ-04 → F-04
    │   ├── 05_drivers_high_value.sql                AQ-05 → F-05
    │   ├── 06_drivers_comparison.sql                AQ-06 → F-06
    │   └── 07_early_life_churn.sql                  C-3 separate reporting
    │
    └── 04_kpi_views/
        ├── 01_vw_customer_analytical_base.sql       THE analytical grain
        ├── 02_vw_kpi_churn_rate.sql
        ├── 03_vw_kpi_revenue_at_risk.sql
        ├── 04_vw_kpi_revenue_concentration.sql
        ├── 05_vw_kpi_arpu.sql
        ├── 06_vw_kpi_early_life_churn.sql
        ├── 07_vw_segment_p1_value_contract.sql
        ├── 08_vw_segment_p2_revenue_decile.sql
        ├── 09_vw_segment_divergence.sql
        └── 10_vw_driver_lenses.sql                  L1–L7
```

**Files to be created at PREPARE (on approval): 24** — six setup, eight cleaning, nine EDA/validation, one setup README.
**Files at ANALYSE (not yet): 7 analysis + 10 view files.**

Also created at PREPARE: `data/processed/` (CSV intermediates, gitignored), `analysis/query_results/` (validation outputs, committed as evidence).

---

# 24. Remaining Blockers

| # | Blocker | Severity | Detail |
|---|---|---|---|
| **B-1** | **PostgreSQL availability on your machine** | 🔴 **Blocking execution** | The deliverable must be reproducible on your setup. I can validate DDL in this session's container, but the project's reproduction instructions have to match what you actually run. **Do you have PostgreSQL 15+, or should the setup script target Docker?** |
| **B-2** | **Local execution route** | 🟠 High | The Linux VM on your machine is not starting, so I cannot run `psql` against your disk. Scripts will be written here and delivered for you to run, with outputs returned for verification — or run in this container and the results committed. **Your preference needed** |
| **B-3** | Currency unknown | 🟠 High | P-15 found no evidence. All outputs labelled "currency units". **Standing constraint, not resolvable** |
| **B-4** | Licence unresolved | 🟠 High | D-09. Raw files not committed; no licensing claim made. **Standing constraint** |
| **B-5** | No sourced margin assumption | 🟡 Medium | Needed for the spend ceiling. Must be a **cited** industry range before AQ-07. Not blocking PREPARE |
| **B-6** | No sourced churn benchmark | 🟡 Medium | Ofcom confirmed not to publish one. Either cite another source or ship the KPI without a benchmark and say so. Not blocking PREPARE |

---

# 25. What Approval Authorises

On approval I will write **only** the 24 setup, cleaning and validation files listed in §23 — DDL, promotion logic, and the six validation gates.

**Not authorised by this approval:** any file in `03_analysis/`, any KPI or segment view producing a business number, any interpretation, any finding, any chart.

The validation gates will run and their outputs returned as evidence. **If any gate fails, work stops and the failure comes back to you** rather than being resolved by adjusting a definition.

**🔴 Awaiting approval, plus decisions on B-1 and B-2.**
