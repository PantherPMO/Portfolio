# Dataset Registry

Every dataset used anywhere in this portfolio is recorded here **before** it is used.

A dataset without a working source URL cannot be used. Unverifiable provenance destroys the credibility of the analysis built on it — and an interviewer asking *"where did this data come from?"* must get a precise answer.

---

## Registry

| ID | Project | Dataset | Publisher | Type | Licence | Rows × Cols | Accessed | Source |
|----|---------|---------|-----------|------|---------|-------------|----------|--------|
| **DS-01** | 01 | Telco customer churn — **five-table Cognos structure** | IBM Corporation | **Synthetic** (fictional sample data) | ❓ **Unresolved** | 7,043 customers × 59 fields across 5 tables *(**verified**)* | 19 Aug 2026 | [IBM Community](https://community.ibm.com/community/user/businessanalytics/blogs/steven-macko/2019/07/11/telco-customer-churn-1113) |
| **DS-02** | 01 | Telecommunications Market Data Update | Ofcom | **Real** | ❓ To verify — OGL presumed | Quarterly series | 19 Aug 2026 | [Ofcom](https://www.ofcom.org.uk/phones-and-broadband/telecoms-infrastructure/telecommunications-market-data-update) |

*Type: `Real` or `Synthetic`. `Synthetic` covers both third-party fictional sample data and data we generate. Only the latter requires approval under `CLAUDE.md` §4.3 and an entry in [`SYNTHETIC_DATA_LOG.md`](SYNTHETIC_DATA_LOG.md) — which remains empty, because we have generated nothing.*

---

### DS-01 — Telco customer churn (extended, merged variant)

| Field | Value |
|-------|-------|
| **Dataset ID** | DS-01 |
| **Used in project** | 01 — Telecommunications Revenue Retention |
| **Publisher** | IBM Corporation |
| **Original source** | IBM Cognos Analytics sample data |
| **Source URL** | https://community.ibm.com/community/user/businessanalytics/blogs/steven-macko/2019/07/11/telco-customer-churn-1113 |
| **Mirrors** | [Kaggle ylchang](https://www.kaggle.com/datasets/ylchang/telco-customer-churn-1113) · [Kaggle yeanzc](https://www.kaggle.com/datasets/yeanzc/telco-customer-churn-ibm-dataset) — both require authentication |
| **Type** | **Synthetic — fictional sample data, IBM-disclosed** |
| **IBM's own description** | "a fictional telco company that provided home phone and Internet services to 7043 customers in California in Q3" |
| **Licence** | ❓ **Unresolved.** No open licence identified; IBM sample-data terms presumed to apply |
| **Licence permits portfolio use** | ❓ To resolve |
| **Licence permits redistribution** | ❓ **Assume no** — the raw file is therefore not committed |
| **Date accessed** | Metadata 19 Aug 2026; **file not yet obtained** |
| **Format** | XLSX |
| **Size** | 7,043 rows × 33 columns — **documented, not verified** |
| **Granularity** | One row = one customer *(documented)* |
| **Period covered** | Single quarter (Q3), year unstated |
| **Geography** | California, USA — fictional |
| **Currency** | ❓ Unstated; presumed USD |

**Why this dataset fits the business case**

It is the only candidate evaluated that supports the approved revenue-at-risk framing in full: monetary recurring revenue, contract type, payment method, nine service/product fields and tenure. Candidates lacking a monetary revenue field cannot support the unit of account; candidates lacking contract type lose two of the four driver lenses.

**Alternatives considered and rejected**

| Dataset | Why rejected |
|---------|--------------|
| Cell2Cell (Duke / Teradata Center for CRM) | Real data, but no contract type or payment method, unresolved licence, unverified field dictionary |
| Iranian Churn Dataset (UCI, CC BY 4.0) | Best licence of any candidate, but `Charge Amount` is an ordinal band not a monetary value — the revenue-at-risk framing cannot be executed |
| IBM Telco classic (21 columns) | Superseded by the extended variant; same data, fewer fields |
| Orange / churn-bigml (3,333 rows) | Provenance unverifiable and synthetic status undisclosed — fails the verification checklist at item 1 |

Full comparison: [`../01-sql-telecom-churn-revenue/DATASET_OPTIONS.md`](../01-sql-telecom-churn-revenue/DATASET_OPTIONS.md)

**Known quality issues** *(documented; unverified pending file)*

- `Total Charges` reportedly stored as text with blanks where `Tenure Months = 0`
- `Total Charges` definition ("to end of quarter") is inconsistent with a 72-month tenure range
- `Monthly Charge` semantics ambiguous — standing rate or billed amount
- Service add-on fields may use a third value meaning "no internet service", which must not be conflated with "No"
- `Count`, `Lat Long`, `Country`, `State` are reporting artefacts or expected constants

**Fields excluded on principle**

| Field | Reason |
|-------|--------|
| `Churn Score` | Predictive model output — target leakage |
| `CLTV` | Project 07 owns CLV; also an undocumented prediction |
| `Churn Reason` | Outcome-derived; would collapse the diagnostic analysis. Permitted only as a post-analysis sanity check |
| `Gender`, `Senior Citizen` | **Restricted** — must not enter any prioritisation rule or recommendation |

**Limitations for this analysis**

- **Fictional.** Any pattern present was designed in. Findings demonstrate method, never describe a real operator or market
- **No time dimension** — single snapshot. Trend analysis is not possible and tenure must not be used as a proxy
- **No cost or margin data** — revenue at risk is measurable; margin at risk requires a sourced assumption
- **No retention activity or intervention outcome data** — spend analysis is scenario modelling, never measured ROI
- **Five-table structure not obtainable** — see validation Finding V-01

**Storage**

- Raw file: `01-sql-telecom-churn-revenue/data/raw/Telco_customer_churn.xlsx` — **not committed** (licence unresolved + `.gitignore` policy)
- Retrieval instructions: `01-sql-telecom-churn-revenue/data/raw/README.md`

**Verification status:** ✅ **FILE-LEVEL VERIFICATION COMPLETE — 19 August 2026.** 15 pre-registered checks: 14 pass, 1 unresolved (currency), 0 fail.

- 7,043 customers across four customer tables, **identical ID sets, zero orphans**, all relationships **1:1** on a unique non-null key
- `location → population` is **N:1** with complete referential integrity (1,626 zips used of 1,671)
- **No duplicates, no key nulls, no genuine missing values, no invalid charges, no tenure zeros**
- Revenue identity `Total Revenue = Total Charges − Refunds + Extra Data + Long Distance` reconciles **exactly, 7,043/7,043**
- `Monthly Charge` confirmed a **stable recurring rate** (median `Total Charges` ÷ (`Monthly Charge` × tenure) = 1.0000)

⚠️ **The merged 33-column workbook is NOT the analytical source.** It contains 11 corrupted rows, a contradictory payment-method taxonomy (1,227 customers classified two incompatible ways) and inconsistently collapsed internet categories. Retained for reconciliation only.

⚠️ **Currency is unknown.** No currency symbol, code or number format exists in any source file. Values must be presented unitless — never as £.

Full audit trail, correction register and profiling results: [`../01-sql-telecom-churn-revenue/docs/DATASET_VALIDATION.md`](../01-sql-telecom-churn-revenue/docs/DATASET_VALIDATION.md).

**Licensing evidence (C-5):** IBM Community publication — no licence statement located. IBM Docs (Cognos 12.0.x / 12.1.x) — HTTP 403, inaccessible. Kaggle mirrors — no unambiguous open licence identified. Source files — no embedded licence, copyright notice or terms. **Position: UNRESOLVED. No licensing claim is made. Raw files are not committed.**

---

### DS-02 — Ofcom Telecommunications Market Data Update

| Field | Value |
|-------|-------|
| **Dataset ID** | DS-02 |
| **Used in project** | 01 — **external context and benchmarks only** |
| **Publisher** | Ofcom |
| **Source URL** | https://www.ofcom.org.uk/phones-and-broadband/telecoms-infrastructure/telecommunications-market-data-update |
| **Type** | **Real** — official regulatory statistics |
| **Licence** | ❓ Not stated on the page; Ofcom publications are typically Open Government Licence — **to verify before citing** |
| **Date accessed** | 19 August 2026 |
| **Format** | PDF and CSV |
| **Granularity** | **Market level, not customer level** |
| **Period** | Quarterly; latest release Q1 2026, published July 2026; series back to at least Q4 2023 |
| **Geography** | United Kingdom |

**Purpose**

`KPI_LIBRARY.md` carries several benchmarks marked *[to source]*, and `CLAUDE.md` §5.1 forbids presenting an unsourced benchmark. Ofcom supplies real UK ARPU, subscription and retail revenue figures to anchor those.

**Verified limitation**

✅ **Confirmed: this release does not publish churn or switching rates.** A churn benchmark must therefore come from a separately cited source, or the KPI ships without a benchmark and says so. **It must not be filled with a remembered figure.**

**Critical usage constraint**

⚠️ **Ofcom data describes the real UK market. DS-01 describes a fictional Californian operator.** These must never be presented as comparable populations. Ofcom is used to establish *market context* — how retention economics work in a real regulated market — and must not be used to imply that the fictional customer base represents the UK market, or to benchmark DS-01's figures against UK figures as though they were the same thing.

---

## Entry Template

Copy this block for each new dataset.

```markdown
### DS-NN — <Dataset Name>

| Field | Value |
|-------|-------|
| **Dataset ID** | DS-NN |
| **Used in project** | |
| **Publisher** | |
| **Source URL** | <direct, working link> |
| **Type** | Real / Synthetic |
| **Licence** | e.g. Open Government Licence v3.0, CC BY 4.0, CC0 |
| **Licence permits portfolio use** | Yes / No |
| **Licence permits redistribution** | Yes / No — determines whether the file can be committed |
| **Date accessed** | |
| **Format** | CSV / XLSX / API / JSON |
| **Size** | e.g. 7,043 rows × 21 columns, 1.2 MB |
| **Granularity** | One row = ? |
| **Time period covered** | |
| **Geography** | |

**Why this dataset fits the business case**
<Two or three sentences.>

**Alternatives considered and rejected**
| Dataset | Why rejected |
|---------|--------------|
| | |

**Known quality issues**
- 

**Limitations for this analysis**
- 

**Storage**
- Raw file: `data/raw/<filename>` — committed / not committed (reason)
- Retrieval: <download instructions or script path>
```

---

## Approved Source List

Priority order, per `CLAUDE.md` §4.1.

**Tier 1 — UK Government & official statistics**
- [data.gov.uk](https://www.data.gov.uk)
- [ONS](https://www.ons.gov.uk) — Office for National Statistics
- [Ofcom research and data](https://www.ofcom.org.uk/about-ofcom/our-research/about-ofcoms-research)
- [NHS Digital](https://digital.nhs.uk/data-and-information)
- [Department for Transport statistics](https://www.gov.uk/government/organisations/department-for-transport/about/statistics)
- [UK Data Service](https://ukdataservice.ac.uk)

**Tier 2 — Curated open data platforms**
- [Kaggle Datasets](https://www.kaggle.com/datasets) — check provenance; many Kaggle sets are themselves synthetic or of unclear origin. Prefer those with a documented original source
- [UCI Machine Learning Repository](https://archive.ics.uci.edu)
- [Google Dataset Search](https://datasetsearch.research.google.com)

**Tier 3 — International bodies**
- [World Bank Open Data](https://data.worldbank.org)
- [OECD Data](https://data.oecd.org)
- [Eurostat](https://ec.europa.eu/eurostat)

**Tier 4 — Company & market data**
- Published annual reports and filings
- [Companies House API](https://developer.company-information.service.gov.uk)

**Tier 5 — Public APIs**
- Document the endpoint, parameters and extraction date. Save the raw pull — APIs change

---

## Verification Checklist

Before a dataset is registered:

- [ ] Source URL opens and the file downloads
- [ ] Publisher is identifiable and reputable
- [ ] Licence located and read
- [ ] Licence permits portfolio use
- [ ] Redistribution position understood (determines the commit decision)
- [ ] Row and column counts recorded **from the file, not from documentation**
- [ ] Granularity understood — you can state what one row represents
- [ ] Time period and geography noted
- [ ] Quality issues profiled and written down
- [ ] The dataset can actually answer the business questions — verified, not assumed
- [ ] Rejected alternatives recorded

**Lesson from DS-01:** distinguish **documented** from **observed**. A field list published by the publisher is not verification that the obtainable file contains those fields — DS-01's five-table structure and three of its documented fields did not survive contact with what is actually downloadable. Mark every unobserved value as pending rather than filling it in.

---

## Kaggle Provenance Warning

Many popular Kaggle datasets — including several widely-used churn and retail sets — are **synthetic or heavily anonymised**, and their Kaggle pages do not always say so.

**DS-01 is a live example.** IBM states plainly that the data is fictional. Most Kaggle mirrors of the same file omit that statement entirely, and thousands of published analyses present it as real operator data.

Where a Kaggle dataset is used, trace it to its original source and record that. Where true provenance cannot be established, say so in the project README. Being the analyst who spotted it is a stronger signal than being the one who did not.
