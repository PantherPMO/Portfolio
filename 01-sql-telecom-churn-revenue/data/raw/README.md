# Raw Data

> **`data/raw/` is immutable.** The source workbooks are never edited, renamed, re-saved or re-exported. All cleaning happens downstream in `sql/01_cleaning/` and writes to `core`. If a workbook is ever modified, the Stage 2 verification no longer applies to it.

**Status:** ✅ Files present locally and verified — 19 August 2026
**Version control:** ⛔ **Intentionally excluded from GitHub** — see §6

---

## 1. Dataset Provenance

| | |
|---|---|
| **Dataset name** | Telco customer churn — five-table Cognos structure |
| **Registry ID** | DS-01 |
| **Publisher** | IBM Corporation |
| **Original source** | IBM Cognos Analytics sample data, distributed at *Team content > Samples > Data* with the Base Samples package installed |
| **Primary publication** | [IBM Community — Telco customer churn (11.1.3+)](https://community.ibm.com/community/user/businessanalytics/blogs/steven-macko/2019/07/11/telco-customer-churn-1113), published 11 July 2019 |
| **File vintage** | All six workbooks modified **8 November 2019** — consistent with a single IBM release rather than a re-export |
| **Type** | **FICTIONAL / SYNTHETIC** — third-party sample data, status disclosed by the publisher |
| **Period covered** | Single quarter. `Quarter` field present in `services` and `status`, constant `Q3`. **Year not stated anywhere** |
| **Geography** | California, USA (fictional) |
| **Currency** | ❓ **Unknown.** No currency symbol, code or number format exists in any source file. Profiling check P-15 found the string "USD" only as a substring of customer identifiers (`6479-OAUSD`, `5751-USDBL`) |
| **Supplied by** | Peters, 19 August 2026 |

> ### ⚠️ This is fictional sample data supplied by IBM
>
> IBM describes it as *"a fictional telco company that provided home phone and Internet services to 7043 customers in California in Q3."*
>
> **It is not real-world telecom subscriber data and must never be described as such anywhere in this portfolio.** Any pattern present in it was designed in by its creator.

---

## 2. Required Filenames

The pipeline expects these six files, in this directory, with these **exact** names. Names are case-sensitive on Linux and inside the PostgreSQL container.

| # | Required filename | Rows × Cols | Sheet | Role |
|---|---|---|---|---|
| 1 | `Telco_customer_churn_demographics.xlsx` | 7,043 × 9 | `Telco_Churn` | ✅ **Authoritative** |
| 2 | `Telco_customer_churn_location.xlsx` | 7,043 × 9 | `Telco_Churn` | ✅ **Authoritative** |
| 3 | `Telco_customer_churn_population.xlsx` | 1,671 × 3 | `Population` | ✅ **Authoritative** |
| 4 | `Telco_customer_churn_services.xlsx` | 7,043 × 30 | `Telco_Churn` | ✅ **Authoritative** |
| 5 | `Telco_customer_churn_status.xlsx` | 7,043 × 11 | `Telco_Churn` | ✅ **Authoritative** |
| 6 | `Telco_customer_churn.xlsx` | 7,043 × 33 | `Telco_Churn` | ⚠️ **Reconciliation only** |

**Expected sizes:** 353,216 · 534,338 · 52,266 · 1,225,982 · 397,133 · 1,368,250 bytes.

Row and column counts are asserted by check **REC-01** at load. A mismatch stops the pipeline.

---

## 3. Source Precedence — decision C-1

**The five relational tables are the authoritative analytical source. The merged 33-column workbook must NOT be used as an analytical source and is not loaded into `core` or `analytics`.**

Verification established that the merged workbook contains defects the relational tables do not:

| Defect | Detail |
|---|---|
| Corrupted rows | 11 customers show `Tenure Months = 0` and a blank `Total Charges`. The relational source shows tenure 10 and populated charges (197.54–808.50) for the same customers |
| Type corruption | `Total Charges` is text-typed, caused solely by those 11 blanks |
| Contradictory taxonomy | 1,227 customers classified "Mailed check" in the merged file are "Credit Card" in the relational source. `Electronic check` exists only in the merged file |
| Inconsistent collapse | 830 Cable customers folded into DSL (769) and Fiber (61) with no discernible rule |
| Flattening sentinels | Uses `No internet service` / `No phone service`; the relational source encodes the dependency structurally |
| Field disagreements | `Churn Score` differs for 244 customers; `Churn Reason` for 519 |

Full evidence: [`../../docs/DATASET_VALIDATION.md`](../../docs/DATASET_VALIDATION.md) §9 and [`../../docs/DECISIONS.md`](../../docs/DECISIONS.md) D-06.

The merged workbook is retained **solely** so reconciliation checks REC-13 to REC-18 remain reproducible.

---

## 4. Acquisition Instructions

The five-table module is **not published as a direct download**. Two routes:

### Route A — IBM Cognos Analytics (the original)

1. Install IBM Cognos Analytics with the **Base Samples** package
2. Navigate to **Team content > Samples > Data**
3. Export the five `Telco_customer_churn_*.xlsx` workbooks
4. Place them in this directory using the exact filenames in §2

### Route B — Kaggle mirrors

Both require an authenticated Kaggle account.

| Mirror | Notes |
|---|---|
| [ylchang/telco-customer-churn-1113](https://www.kaggle.com/datasets/ylchang/telco-customer-churn-1113) | **Preferred** — title matches IBM's own publication |
| [yeanzc/telco-customer-churn-ibm-dataset](https://www.kaggle.com/datasets/yeanzc/telco-customer-churn-ibm-dataset) | Alternative |

### On receipt

1. Place files here **unmodified** — do not open and re-save; Excel will rewrite the file and change its bytes
2. Record the download date and file hashes in §7
3. Run the PREPARE load pipeline; checks REC-01 and REC-02 will confirm the files match the verified profile

---

## 5. Licensing Status

> ### ❓ UNRESOLVED — no licensing claim is made
>
> **The licence governing this dataset could not be established.** No claim, permissive or restrictive, is made anywhere in this project.

| Source checked | Finding |
|---|---|
| IBM Community publication | **No licence statement located** |
| IBM Docs (Cognos 12.0.x, 12.1.x) | **Not accessible** — HTTP 403 |
| Kaggle mirrors | **No unambiguous open licence identified**; pages not fully readable without authentication |
| The workbooks themselves | **No embedded licence, copyright notice or terms** |

IBM sample-data terms are *presumed* to apply. **This is a presumption and is labelled as one.** It has not been verified against a licence document.

Recorded as decision [D-09](../../docs/DECISIONS.md#d-09--licence-position-remains-unresolved). Provenance is fully established; licensing is not. The two are different things and are reported separately.

---

## 6. Why These Files Are Excluded From GitHub

**Deliberate policy decision, not an oversight.**

1. **Licensing is unresolved (§5).** Redistribution rights have not been established. Committing files whose licence is unknown would be publishing under an assumption — the same category of error as citing an unsourced benchmark.
2. **Portfolio binary policy.** Raw data is excluded by `.gitignore` across all eight projects; the repository stays fast to clone and useful to review.
3. **Reproducibility is preserved by documentation, not distribution.** This README records provenance, exact filenames, expected shapes and acquisition routes — enough for a reviewer to obtain the data and reproduce every result.

### `.gitignore` coverage

```gitignore
**/data/raw/*
!**/data/raw/README.md
Telco_customer_churn*.xlsx
```

⚠️ **A bug was found and fixed while implementing this policy.** The original pattern was `data/raw/*`. Because a pattern containing a slash is anchored to the location of the `.gitignore`, it matched only `<repo-root>/data/raw/` and **would not have matched** `01-sql-telecom-churn-revenue/data/raw/`. The six workbooks would have been committable. The pattern is now `**/data/raw/*`, with an explicit filename rule as a second line of defence.

**Verify before the first commit:**

```bash
git check-ignore -v "01-sql-telecom-churn-revenue/data/raw/Telco_customer_churn_services.xlsx"
git status --porcelain 01-sql-telecom-churn-revenue/data/raw/
```

The first must report a matching ignore rule. The second must list **only** `README.md`.

**This README is committed.** The data is not.

---

## 7. Local File Register

To be completed on acquisition. Hashes let a future reviewer confirm the files are byte-identical to those verified at Stage 2.

| File | Date obtained | Route | SHA-256 |
|---|---|---|---|
| `Telco_customer_churn_demographics.xlsx` | | | |
| `Telco_customer_churn_location.xlsx` | | | |
| `Telco_customer_churn_population.xlsx` | | | |
| `Telco_customer_churn_services.xlsx` | | | |
| `Telco_customer_churn_status.xlsx` | | | |
| `Telco_customer_churn.xlsx` | | | |

Generate on Windows:

```powershell
Get-FileHash -Algorithm SHA256 .\*.xlsx | Format-List Path, Hash
```

---

## 8. Verification Summary

15 pre-registered checks run 19 August 2026: **14 pass, 1 unresolved (currency), 0 fail.**

- 7,043 customers in all four customer tables, **identical ID sets, zero orphans**
- All customer relationships **1:1** on a unique, non-null key; `location → population` **N:1** with complete referential integrity
- **No duplicates, no key nulls, no genuine missing values, no invalid charges, no tenure zeros**
- Revenue identity `Total Revenue = Total Charges − Refunds + Extra Data + Long Distance` reconciles **exactly, 7,043/7,043**
- `Monthly Charge` confirmed a **stable recurring rate** — median `Total Charges` ÷ (`Monthly Charge` × tenure) = 1.0000

Full audit trail: [`../../docs/DATASET_VALIDATION.md`](../../docs/DATASET_VALIDATION.md).
