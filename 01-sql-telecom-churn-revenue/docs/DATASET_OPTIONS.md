# Dataset Options — Project 01

## Telecommunications Revenue Retention: Prioritising Retention Investment by Revenue at Risk

**Stage:** 2 — SOURCE
**Status:** ⬜ Awaiting dataset approval
**Prepared:** 19 August 2026
**Nothing downloaded. Nothing generated.**

---

## Verification Convention

Because provenance is the point of this stage, every claim below is marked:

- **✅ Verified** — confirmed directly from the publisher or a primary source, cited
- **🔶 Reported** — widely documented in secondary sources, to be confirmed on first profiling
- **❓ Unverified** — could not be established without downloading; flagged as a risk, not asserted

I have not stated a single figure as fact that I could not source. Several fields below are deliberately left as ❓ rather than filled with a plausible number.

---

## The Headline Finding of This Search

**No public, customer-level, longitudinal telecommunications dataset appears to exist.**

Real subscriber panels — monthly records per customer over time — are among the most commercially sensitive assets a telecoms operator holds, and none is published openly. Every credible candidate is either a **single snapshot** or a **fixed observation window with aggregated features**.

This resolves the Stage 2 question you deferred, but not in the way it was framed. The choice is not *longitudinal vs snapshot*. It is:

> **Real but analytically ill-fitting, or fictional but analytically complete — and openly labelled as such.**

That trade-off is the substance of this document.

---

## Candidate Summary

| | A. IBM Telco (classic) | B. IBM Telco (extended) | C. Cell2Cell (Duke) | D. Iranian Churn (UCI) | E. Orange / churn-bigml |
|---|---|---|---|---|---|
| **Real or fictional** | Fictional ✅ | Fictional ✅ | **Real** ✅ | **Real** ✅ | Likely artificial 🔶 |
| **Disclosure of status** | By IBM ✅ / not on Kaggle | By IBM ✅ | Anonymised, disclosed ✅ | Disclosed ✅ | **Not disclosed** ⚠️ |
| **Rows** | 7,043 ✅ | 7,043 ✅ | ~71,000 🔶 | 3,150 ✅ | 3,333 🔶 |
| **Columns** | 21 🔶 | ~33 across 5 tables ✅ | ~58 🔶 | 13 ✅ | 20 🔶 |
| **Monetary revenue field** | ✅ Yes (£/$ values) | ✅ Yes, itemised | 🔶 Yes (monthly revenue) | ❌ **Ordinal band only** | 🔶 Usage charges only |
| **Contract type** | ✅ Yes | ✅ Yes | ❌ No | ❌ No | ❌ No |
| **Service / product mix** | ✅ Yes (9 fields) | ✅ Yes | 🔶 Partial | ❌ No | 🔶 Partial |
| **Payment method** | ✅ Yes | ✅ Yes | ❌ No | ❌ No | ❌ No |
| **Tenure** | ✅ Yes (months) | ✅ Yes | 🔶 Months in service | ✅ Subscription length | 🔶 Account length |
| **Time dimension** | ❌ None | ❌ None | 🔶 3-month averages | ✅ 9-month window → month-12 outcome | ❌ None |
| **Relational structure** | Single flat file | ✅ **5 tables** | Single flat file | Single flat file | Single flat file |
| **Licence clarity** | ❓ Unclear | ❓ Unclear | ❓ **Unclear** | ✅ **CC BY 4.0** | ❓ Unclear |
| **Provenance confidence** | **High** | **High** | Medium–High | **High** | **Low** |
| **Analytical fit to our framing** | Good | **Excellent** | Moderate | Poor | Poor |

---
---

# Candidate A — IBM Telco Customer Churn (classic)

| # | Field | Detail |
|---|---|---|
| 1 | **Dataset name** | Telco customer churn |
| 2 | **Original source** | IBM Cognos Analytics sample data |
| 3 | **Direct URL** | Primary: [IBM Community — Telco customer churn](https://community.ibm.com/community/user/businessanalytics/blogs/steven-macko/2019/07/11/telco-customer-churn-1113) · Mirror: [Kaggle — blastchar/telco-customer-churn](https://www.kaggle.com/datasets/blastchar/telco-customer-churn) |
| 4 | **Publisher / owner** | IBM Corporation |
| 5 | **Licence** | ❓ **Unclear.** IBM sample-data terms apply to the original; the Kaggle mirror does not carry an unambiguous open licence. Must be resolved before any redistribution decision |
| 6 | **Date accessed** | 19 August 2026 |
| 7 | **Real vs synthetic** | **Fictional** ✅ |
| 8 | **Status disclosed?** | **By IBM, yes — explicitly.** IBM describes "a fictional telco company that provided home phone and Internet services to 7043 customers in California in Q3." **Most Kaggle mirrors do not repeat this** — the single most important provenance fact about the most-used churn dataset in the world is routinely omitted downstream |
| 9 | **Rows** | 7,043 ✅ |
| 10 | **Columns** | 21 🔶 |
| 11 | **Relevant fields** | `customerID`, `gender`, `SeniorCitizen`, `Partner`, `Dependents`, `tenure`, `PhoneService`, `MultipleLines`, `InternetService`, `OnlineSecurity`, `OnlineBackup`, `DeviceProtection`, `TechSupport`, `StreamingTV`, `StreamingMovies`, `Contract`, `PaperlessBilling`, `PaymentMethod`, `MonthlyCharges`, `TotalCharges`, `Churn` 🔶 |
| 12 | **Time dimension** | ❌ None — single Q3 snapshot |
| 13 | **Revenue fields** | `MonthlyCharges` (monetary), `TotalCharges` (cumulative) ✅ |
| 14 | **Churn fields** | `Churn` (Yes/No) ✅ |
| 15 | **Customer identifier** | `customerID` ✅ |
| 16 | **Data-quality concerns** | `TotalCharges` reportedly stored as text with ~11 blank values where `tenure = 0` 🔶 — to confirm on profiling. No stated currency unit. Class imbalance ~26.5% churn 🔶 |
| 17 | **Known limitations** | No time dimension. No cost or margin data. Single operator, single quarter, California. Fictional — patterns present were designed in |
| 18 | **Supports BQ-01 to BQ-06** | BQ-01 ⚠️ level only, no trend · BQ-02 ✅ · BQ-03 ✅ · BQ-04 ✅ · BQ-05 ✅ · BQ-06 ⚠️ requires margin assumption |
| 19 | **Supports AQ-01 to AQ-07** | AQ-01 ⚠️ partial · AQ-02 ✅ · AQ-03 ✅ · AQ-04 ✅ · AQ-05 ✅ · AQ-06 ✅ · AQ-07 ⚠️ assumption-dependent |
| 20 | **Provenance confidence** | **High** — traceable to a named publisher with an explicit statement of status. The data is fictional, but its *provenance is excellent* |

---

# Candidate B — IBM Telco Customer Churn (extended, 5-table)

| # | Field | Detail |
|---|---|---|
| 1 | **Dataset name** | Telco customer churn (extended / Cognos 11.1.3 sample) |
| 2 | **Original source** | IBM Cognos Analytics sample data |
| 3 | **Direct URL** | [IBM Community — Telco customer churn](https://community.ibm.com/community/user/businessanalytics/blogs/steven-macko/2019/07/11/telco-customer-churn-1113) · Mirror: [Kaggle — yeanzc/telco-customer-churn-ibm-dataset](https://www.kaggle.com/datasets/yeanzc/telco-customer-churn-ibm-dataset) |
| 4 | **Publisher / owner** | IBM Corporation |
| 5 | **Licence** | ❓ Unclear — as Candidate A |
| 6 | **Date accessed** | 19 August 2026 |
| 7 | **Real vs synthetic** | **Fictional** ✅ |
| 8 | **Status disclosed?** | **Yes, explicitly by IBM** ✅ (same statement as A) |
| 9 | **Rows** | 7,043 customers ✅ |
| 10 | **Columns** | ~33 fields across **5 tables** — Demographics, Location, Population, Services, Status ✅ |
| 11 | **Relevant fields** | All of Candidate A, **plus**: itemised revenue (monthly charges, total charges, total refunds, extra data charges, long-distance charges), geography (state, city, zip, lat/long), `Satisfaction Score` (1–5), `Churn Score` (0–100), `Churn Reason`, `Churn Category`, `CLTV`, `CLTV` category ✅ |
| 12 | **Time dimension** | ❌ None — single Q3 snapshot |
| 13 | **Revenue fields** | ✅ **Itemised** — enables revenue decomposition, not just a single ARPU figure |
| 14 | **Churn fields** | `Churn Label`, `Churn Score`, `Churn Reason`, `Churn Category` ✅ |
| 15 | **Customer identifier** | `Customer ID`, joinable across all five tables ✅ |
| 16 | **Data-quality concerns** | As A, plus **two fields that must be excluded on principle** — see the leakage note below |
| 17 | **Known limitations** | As A. Additionally contains `CLTV`, which is **out of scope by your Stage 1 decision** and must be dropped, not analysed |
| 18 | **Supports BQ-01 to BQ-06** | BQ-01 ⚠️ level only · BQ-02 ✅ · BQ-03 ✅ · BQ-04 ✅ · BQ-05 ✅✅ strongest of any candidate · BQ-06 ⚠️ assumption-dependent |
| 19 | **Supports AQ-01 to AQ-07** | AQ-01 ⚠️ · AQ-02 ✅ · AQ-03 ✅ · AQ-04 ✅ · AQ-05 ✅✅ · AQ-06 ✅✅ · AQ-07 ⚠️ |
| 20 | **Provenance confidence** | **High** — same as A |

### ⚠️ Two fields that must be excluded: `Churn Reason` and `Churn Score`

This dataset ships with the answer in the box.

- **`Churn Reason`** states why each customer left. Using it would reduce AQ-05 and AQ-06 — the diagnostic core of the project — to a `GROUP BY`. It would also be circular: in fictional data, the reason field *is* the generation rule.
- **`Churn Score`** is a model output, not an observation. Using a pre-computed propensity score as an input is textbook target leakage.

**Both must be dropped at PREPARE stage**, with the decision recorded in `DECISIONS.md`.

This is not a drawback. Recognising and excluding leakage — then explaining why in the README — is a stronger analytical signal than any finding the fields could have produced. It is also exactly the kind of thing an interviewer probes, and most portfolio projects using this dataset happily analyse `Churn Reason` without noticing the problem.

---

# Candidate C — Cell2Cell (Duke University / Teradata Center for CRM)

**The real-data option.**

| # | Field | Detail |
|---|---|---|
| 1 | **Dataset name** | Cell2Cell — churn management for a US wireless carrier |
| 2 | **Original source** | Teradata Center for Customer Relationship Management, Fuqua School of Business, **Duke University** ✅ |
| 3 | **Direct URL** | Mirror: [Kaggle — jpacse/datasets-for-churn-telecom](https://www.kaggle.com/datasets/jpacse/datasets-for-churn-telecom). ❓ No live primary distribution URL located — the Duke/Teradata programme appears no longer to publish it openly |
| 4 | **Publisher / owner** | Duke University (Teradata Center for CRM); underlying data from an unnamed US wireless carrier |
| 5 | **Licence** | ❓ **Unclear and a material risk.** Originally distributed for academic research; no open licence identified on the mirror |
| 6 | **Date accessed** | 19 August 2026 |
| 7 | **Real vs synthetic** | **Real** — genuine anonymised customer records ✅ |
| 8 | **Status disclosed?** | Yes — anonymisation and academic origin are stated ✅ |
| 9 | **Rows** | ~71,000 across calibration and holdout samples 🔶 — **to verify** |
| 10 | **Columns** | ~58 🔶 — **to verify** |
| 11 | **Relevant fields** | Reported to include monthly revenue, monthly minutes, months in service, handset/equipment attributes, credit rating, customer-service calls, churn flag 🔶 — full dictionary not verified |
| 12 | **Time dimension** | 🔶 Three-month aggregated averages — a window, not a panel |
| 13 | **Revenue fields** | 🔶 Monthly revenue (monetary) |
| 14 | **Churn fields** | 🔶 Binary churn flag |
| 15 | **Customer identifier** | 🔶 Anonymised ID |
| 16 | **Data-quality concerns** | Heavily anonymised, abbreviated field names requiring interpretation; ~58 variables is a modelling feature set rather than a business schema; missing values reported across several fields 🔶 |
| 17 | **Known limitations** | **No contract-type field** — US wireless, so the contract dimension central to the retention narrative is absent. No payment-method field. Limited service/product mix. US market, circa early 2000s |
| 18 | **Supports BQ-01 to BQ-06** | BQ-01 ⚠️ · BQ-02 ✅ · BQ-03 ✅ · BQ-04 ✅ · **BQ-05 ⚠️ weakened — no contract, no payment method, thin product mix** · BQ-06 ⚠️ |
| 19 | **Supports AQ-01 to AQ-07** | AQ-01 ⚠️ · AQ-02 ✅ · AQ-03 ✅ · AQ-04 ✅ · **AQ-05 ⚠️ driver lens substantially narrowed** · AQ-06 ✅ · AQ-07 ⚠️ |
| 20 | **Provenance confidence** | **Medium–High on origin** (named academic publisher, real data), **Low on licence and on the current dictionary** |

**Honest assessment:** this is the only candidate that would let the README say *"real anonymised customer records from a US wireless carrier."* That is a genuine credibility advantage. It costs the contract-type and payment-method dimensions, which are two of the four driver lenses in AQ-05, and it carries unresolved licence ambiguity.

---

# Candidate D — Iranian Churn Dataset (UCI)

**The best-licensed option, and the poorest fit.**

| # | Field | Detail |
|---|---|---|
| 1 | **Dataset name** | Iranian Churn Dataset |
| 2 | **Original source** | An Iranian telecommunications company, via UCI ML Repository ✅ |
| 3 | **Direct URL** | [UCI ML Repository — Dataset 563](https://archive.ics.uci.edu/dataset/563/iranian+churn+dataset) ✅ |
| 4 | **Publisher / owner** | UCI Machine Learning Repository |
| 5 | **Licence** | ✅ **Creative Commons Attribution 4.0 International (CC BY 4.0)** — the only candidate with an unambiguous open licence |
| 6 | **Date accessed** | 19 August 2026 |
| 7 | **Real vs synthetic** | **Real** — "randomly collected from an Iranian telecom company's database over a period of 12 months" ✅ |
| 8 | **Status disclosed?** | Yes ✅ |
| 9 | **Rows** | 3,150 ✅ |
| 10 | **Columns** | 13 ✅ |
| 11 | **Relevant fields** | Call Failure, Complains, Subscription Length, **Charge Amount**, Seconds of Use, Frequency of Use, Frequency of SMS, Distinct Called Numbers, Age Group, Tariff Plan, Status, Churn, **Customer Value** ✅ |
| 12 | **Time dimension** | ✅ **Best of any candidate** — features aggregated over the first 9 months, churn status observed at month 12. A properly defined observation window with a forward-looking outcome gap |
| 13 | **Revenue fields** | ❌ **`Charge Amount` is an ordinal band (0–9), not a monetary value.** `Customer Value` is a derived field of undocumented construction |
| 14 | **Churn fields** | `Churn` (binary) ✅ |
| 15 | **Customer identifier** | ❓ No explicit ID column — rows are customers |
| 16 | **Data-quality concerns** | No missing values reported ✅. But `Customer Value` has no published formula, making it unusable as evidence |
| 17 | **Known limitations** | **No monetary revenue.** No contract type, no service mix, no payment method. Prepaid-style mobile market with different retention economics from UK fixed/broadband |
| 18 | **Supports BQ-01 to BQ-06** | **BQ-01 ❌ cannot quantify revenue at risk in currency · BQ-02 ❌ · BQ-03 ⚠️ ordinal proxy only · BQ-04 ⚠️ · BQ-05 ⚠️ · BQ-06 ❌** |
| 19 | **Supports AQ-01 to AQ-07** | AQ-01 ❌ · AQ-02 ❌ · AQ-03 ⚠️ · AQ-04 ⚠️ · AQ-05 ⚠️ · AQ-06 ⚠️ · AQ-07 ❌ |
| 20 | **Provenance confidence** | **High** — real, licensed, institutionally hosted |

**Why this fails despite the best provenance:** the project's unit of account is **money**. Without a monetary revenue field there is no revenue at risk, no concentration curve, no spend ceiling — the entire analytical spine collapses. Choosing this dataset would mean abandoning the approved framing.

Worth recording as a rejected alternative precisely because the reason is analytical rather than convenient.

---

# Candidate E — Orange Telecom / "Churn in Telecom's dataset" — REJECT

| # | Field | Detail |
|---|---|---|
| 1 | **Dataset name** | Churn in Telecom's dataset (also circulated as "Orange Telecom churn") |
| 2 | **Original source** | ❓ **Cannot be established.** Traced through secondary literature to the churn dataset accompanying Larose, *Discovering Knowledge in Data*, itself derived from earlier artificial teaching data |
| 3 | **Direct URL** | [Kaggle — becksddf/churn-in-telecoms-dataset](https://www.kaggle.com/datasets/becksddf/churn-in-telecoms-dataset) |
| 4 | **Publisher / owner** | ❓ Unattributable. The "Orange Telecom" attribution appears to have been added by redistributors — I found no evidence Orange published it |
| 5 | **Licence** | ❓ Unclear |
| 6 | **Date accessed** | 19 August 2026 |
| 7 | **Real vs synthetic** | 🔶 **Widely described as artificial** |
| 8 | **Status disclosed?** | ⚠️ **No.** Circulated as real operator data with an attribution that does not survive scrutiny |
| 9–19 | | 3,333 rows × 20 columns 🔶; usage-based day/evening/night/international charges; account length; international and voicemail plans; customer-service calls; churn. **No MRR, no contract type, no payment method, no service mix** |
| 20 | **Provenance confidence** | **Low — recommend rejection** |

**Rejected on provenance.** A dataset whose stated publisher cannot be verified and whose synthetic status is undisclosed fails `DATASET_REGISTRY.md`'s verification checklist at the first item. Using it would put an unverifiable claim into the portfolio.

---

# Supplement — Ofcom Telecommunications Market Data Update

**Not a primary dataset. A real benchmark layer, and it solves a real problem.**

| # | Field | Detail |
|---|---|---|
| 1 | **Dataset name** | Telecommunications Market Data Update |
| 2–4 | **Source / publisher** | **Ofcom** — UK communications regulator ✅ |
| 3 | **Direct URL** | [Ofcom — Telecommunications Market Data Update](https://www.ofcom.org.uk/phones-and-broadband/telecoms-infrastructure/telecommunications-market-data-update) ✅ |
| 5 | **Licence** | ❓ Not stated on the page; Ofcom publications are typically Open Government Licence — **to verify** |
| 6 | **Date accessed** | 19 August 2026 |
| 7 | **Real vs synthetic** | **Real** — official regulatory statistics ✅ |
| 9–11 | **Content** | Quarterly UK market data: active mobile subscriptions, fixed line and broadband counts by technology, data and voice volumes, retail revenues, and **ARPU by subscription type**. Latest release Q1 2026, published July 2026 ✅ |
| 12 | **Time dimension** | ✅ Quarterly series back to at least Q4 2023 |
| 16 | **Limitation** | **Market-level, not customer-level.** ✅ Confirmed: this release does **not** publish churn or switching rates |
| 20 | **Provenance confidence** | **Very high** — official statistics, CSV and PDF |

**Why include it:** `KPI_LIBRARY.md` currently carries several benchmarks marked *[to source]*, and `CLAUDE.md` forbids presenting an unsourced benchmark. Ofcom gives real UK ARPU and market-context figures to anchor those. It cannot supply a churn benchmark — that will need a separately cited source at FRAME stage, or the KPI ships without a benchmark and says so.

Using real regulatory data to frame an analysis is also a differentiator in itself: almost no portfolio churn project bothers.

---
---

# Recommendation

## Primary: **Candidate B — IBM Telco Customer Churn (extended), with Ofcom as a real benchmark layer**

### Why

**1. It is the only candidate that supports the approved framing in full.** Contract type, itemised revenue, service mix, payment method and tenure are all present. Those are the four driver lenses in AQ-05 plus the unit of account. Candidate C loses two of the four; Candidate D loses the unit of account entirely.

**2. Five tables, not one flat file.** This is the strongest argument for a **SQL** project and it is easy to overlook. Candidate B requires schema design, primary and foreign keys, deliberate join strategy and grain management across Demographics, Location, Services and Status. Candidates A, C, D and E are single flat files where the SQL reduces to `SELECT … GROUP BY` over one table. For a project whose purpose is demonstrating SQL capability, a genuine relational structure is worth more than extra rows.

**3. Its provenance is excellent even though the data is fictional.** These are different properties, and conflating them is a common error. IBM is a named publisher with an explicit, quotable statement of status. We can say precisely what this data is and who made it — which is more than can be said for Candidate C's licence or Candidate E's attribution.

**4. The leakage problem is an asset.** Identifying `Churn Reason` and `Churn Score` as unusable, excluding them, and explaining why turns a dataset flaw into evidence of analytical judgement. Thousands of projects use this dataset; very few notice this.

**5. Itemised revenue enables decomposition.** Monthly charges, long-distance charges, extra data charges and refunds as separate fields allow revenue-at-risk to be broken down by component — a materially richer analysis than a single ARPU column.

### What this costs, stated plainly

- **The data is fictional.** Any pattern found was designed in. The README must say so in the summary block, not in a footnote, and no finding may be framed as a statement about a real operator or a real market.
- **No time dimension.** BQ-01's trend component is unanswerable. AQ-01 narrows to a level measurement, and `LAG`/`LEAD` come out of the technique list. This must be recorded as a limitation, not quietly dropped.
- **No cost or margin data.** Risk R-02 stands: revenue at risk is measurable, margin at risk requires a sourced assumption and a sensitivity band.
- **The dataset is heavily used.** The reframing and the divergence index are what differentiate this project — not the data. That places real weight on execution.

### Important: this is *not* synthetic data generation

Candidate B is **third-party fictional sample data with disclosed status** — materially different from us generating data ourselves. No approval under `CLAUDE.md` §4.3 is required. It is registered in `DATASET_REGISTRY.md` with type `Synthetic`, labelled in the README per the template's notice block, and `SYNTHETIC_DATA_LOG.md` remains empty because we have generated nothing.

---

## Alternative: **Candidate C — Cell2Cell**, if you weight real-world provenance above analytical completeness

This is a legitimate choice and I would not argue hard against it. Choose it if the credibility of *"real anonymised carrier data"* matters more to you than the contract and payment dimensions.

If you do, three things must be accepted up front:
1. **AQ-05 narrows** — the driver analysis loses contract type and payment method, two of its four lenses
2. **The licence must be resolved first.** I could not establish one. If it cannot be established, the dataset cannot be used under `DATASET_REGISTRY.md`'s checklist
3. **The field dictionary needs verification before FRAME.** ~58 abbreviated, anonymised columns require interpretation work that Candidate B does not

---

## Rejected

| Candidate | Reason |
|---|---|
| **A — IBM classic** | Superseded by B. Same data, fewer fields, no relational structure. No reason to prefer it |
| **D — Iranian Churn** | Best licence of any candidate, but `Charge Amount` is an ordinal band. Without monetary revenue there is no revenue at risk, and the approved framing cannot be executed |
| **E — Orange / churn-bigml** | Provenance unverifiable and synthetic status undisclosed. Fails the registry checklist at item one |

---

# Two Decisions I Need

1. **Approve Candidate B** (IBM extended, with Ofcom benchmarks), or **redirect to Candidate C** (Cell2Cell, real data, narrower driver analysis)?
2. **Approve creation of the project folder** `01-sql-telecom-churn-revenue/`, so the approved charter and this document can be committed? Per `CLAUDE.md` §2.3 I need explicit authorisation before creating project folders — this document is currently delivered to chat only, not written to disk.

On approval I will download the dataset, verify every 🔶 and ❓ above against the actual file, complete the `DATASET_REGISTRY.md` entry, and return the verified profile — **before** FRAME.

Anything that fails verification comes back to you rather than proceeding on an assumption.

---

## Sources

- [IBM Community — Telco customer churn (Cognos Analytics sample)](https://community.ibm.com/community/user/businessanalytics/blogs/steven-macko/2019/07/11/telco-customer-churn-1113)
- [IBM Docs — Telco customer churn sample](https://www.ibm.com/docs/en/cognos-analytics/12.1.x?topic=samples-telco-customer-churn)
- [Kaggle — Telco Customer Churn (blastchar)](https://www.kaggle.com/datasets/blastchar/telco-customer-churn)
- [Kaggle — Telco customer churn: IBM dataset (yeanzc)](https://www.kaggle.com/datasets/yeanzc/telco-customer-churn-ibm-dataset)
- [Kaggle — telecom churn (Cell2Cell)](https://www.kaggle.com/datasets/jpacse/datasets-for-churn-telecom)
- [UCI ML Repository — Iranian Churn Dataset](https://archive.ics.uci.edu/dataset/563/iranian+churn+dataset)
- [Kaggle — Churn in Telecom's dataset](https://www.kaggle.com/datasets/becksddf/churn-in-telecoms-dataset)
- [Ofcom — Telecommunications Market Data Update](https://www.ofcom.org.uk/phones-and-broadband/telecoms-infrastructure/telecommunications-market-data-update)

---
---

# Addendum — 19 August 2026: Verification Correction

**This addendum records that the primary argument for the recommendation above did not survive verification.** It is retained rather than edited away, so the audit trail is intact.

## What was claimed

> "Five tables, not one flat file. This is the strongest argument for a **SQL** project… Candidate B requires schema design, primary and foreign keys, deliberate join strategy and grain management across Demographics, Location, Services and Status."

## What verification established

The five-table structure is a **Cognos Analytics data module**, distributed only inside a Cognos installation at *Team content > Samples > Data*. It is not publicly downloadable, and no accessible mirror of the five `.xlsx` files was located.

**The obtainable artefact is a single merged flat file of 33 columns.** See [`docs/DATASET_VALIDATION.md`](DATASET_VALIDATION.md) Finding V-01.

A second error is corrected there too (Finding V-02): two distinct "extended" variants exist and are routinely conflated. The obtainable merged file does **not** contain `Satisfaction Score`, `Churn Category`, or the itemised revenue fields (refunds, extra data charges, long-distance charges) that this document attributed to it. The revenue-decomposition benefit claimed above is therefore unavailable.

## Effect on the recommendation

**The recommendation stands, on narrower grounds.** The dataset remains the only candidate supporting the approved framing in full — monetary revenue, contract type, payment method, service mix and tenure. But the relational-structure argument is replaced by a different one:

> The project **normalises the wide flat extract into a documented relational schema itself**, including unpivoting nine service flags into a bridge table. Designing a schema demonstrates understanding that consuming someone else's does not.

That is a defensible repositioning and arguably a stronger SQL artefact — but it is a repositioning after a failed premise, and the README will say so rather than present the normalisation as though the dataset had arrived that way.

## Effect on the alternative

**Candidate C (Cell2Cell) is not re-opened by this.** Its own limitations — no contract type, no payment method, unresolved licence, unverified dictionary — are unaffected, and it is also a single flat file. The comparison outcome does not change.
