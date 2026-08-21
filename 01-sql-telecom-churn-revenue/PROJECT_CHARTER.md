# Project Charter — 01

## Telecommunications Revenue Retention: Prioritising Retention Investment by Revenue at Risk

**Stage:** 1 — DEFINE
**Status:** ✅ **APPROVED** by Peters, 19 August 2026
**Dataset status:** ✅ **VERIFIED AND APPROVED** — Stage 2 complete, see [`docs/DATASET_VALIDATION.md`](docs/DATASET_VALIDATION.md)
**Decisions applied:** C-1, C-2 approved 19 Aug 2026 — see [`docs/DECISIONS.md`](docs/DECISIONS.md)
**FRAME specification:** proposed, awaiting approval — see [`docs/FRAME_SPECIFICATION.md`](docs/FRAME_SPECIFICATION.md)

> **Analysis may not begin until all six pre-conditions in the sign-off section are met.** See `_portfolio/CLAUDE.md` §2.1.

---

## Framing Decision

This project was originally proposed as "Telecommunications Customer Churn & Revenue Analytics." It was deliberately reframed at DEFINE stage.

**Why:** churn analysis is the most saturated project type in the analytics portfolio landscape, and conventional churn analysis has three defects for this purpose. Churn *rate* is not the business's unit of account — retention functions are funded to protect revenue, not to reduce a percentage. Churn *prediction* is not a SQL problem, and forcing a classifier into SQL would violate the tool-selection principle in `CLAUDE.md` §3. And "why do customers leave" is descriptive: it produces findings, not decisions.

**The analytical spine:**

| Element | Role |
|---|---|
| Churn | The **mechanism** |
| Revenue | The **unit of account** |
| Segmentation | The **analytical method** |
| Service / product mix | A **driver lens** |
| Retention investment | The **business decision** |

**The single question the project answers:** given a finite retention budget, where should it be allocated?

**The central analytical construct:** the **value–risk divergence index** — the extent to which ranking segments by churn rate and ranking them by revenue at risk produce *different* answers.

---

## 1. Business Context

The UK consumer telecommunications market is mature and structurally saturated. Growth through acquisition is constrained: most households already hold broadband and mobile services, so acquisition largely means taking share from competitors — expensive, and frequently margin-dilutive after promotional discounting.

Three characteristics shape the commercial problem:

- **Acquisition costs substantially exceed retention costs** in subscription telecoms — a widely observed pattern, to be evidenced with a cited source at FRAME stage rather than asserted.
- **Regulatory friction has fallen.** Ofcom's end-of-contract notification and switching reforms have made switching easier and made contract-end a predictable moment of elevated risk.
- **Revenue is concentrated.** In most subscriber bases a minority of customers generate a disproportionate share of recurring revenue, so aggregate churn statistics systematically obscure where commercial exposure sits.

In this environment retention is not a customer-service function. It is a revenue-protection function competing for capital against acquisition and network investment, and it must justify its budget in the same commercial terms.

---

## 2. Business Problem

> The retention function has a finite annual budget and no evidence-based basis for allocating it.

Current practice is that retention effort is triggered by **churn signals** — contract end date, inbound cancellation contact, tenure milestones — rather than by **commercial exposure**. Every at-risk customer is treated as equivalently worth the same intervention.

This produces three failures at once:

- **Over-investment in low-value risk.** High-cost retention offers extended where the expected retained value does not justify the discount.
- **Under-investment in high-value risk.** High-revenue customers whose risk indicators are subtler receive no proactive contact until they call to cancel, by which point the offer needed to retain them is far more expensive.
- **No defensible budget case.** The function cannot state what its spend protects, so it cannot argue for more, or defend it when cut.

**The problem is not that customers churn. It is that the business cannot rank where churn hurts.**

---

## 3. Why the Problem Matters

| Dimension | Consequence of not solving it |
|---|---|
| **Revenue** | Recurring revenue lost from segments never prioritised, compounding annually because the loss recurs in every subsequent year |
| **Margin** | Retention discounts given where not commercially justified, converting profitable customers into marginal ones |
| **Capital efficiency** | Retention budget returns less than the same money spent elsewhere; the function loses internal credibility |
| **Strategic** | Base value erodes quietly — subscriber counts can hold steady while revenue quality deteriorates |
| **Organisational** | Without evidence, retention strategy is set by seniority and instinct rather than commercial reasoning |

The cost of inaction is not one-off. Recurring revenue lost this year is lost in every year that follows — which is why the business case is expressed in annualised terms.

---

## 4. Target Stakeholder

**Primary: Head of Customer Value Management (CVM)**

*Customer Value Management is the standard function name in UK telecoms for the team owning base retention, upsell and customer profitability, reporting to the Chief Commercial Officer.*

| | |
|---|---|
| **Accountable for** | Base revenue retention, churn against target, retention budget return |
| **Judged on** | Revenue retained vs plan; churn rate vs target; cost per save |
| **Currently does** | Runs contract-end and save-desk campaigns triggered by churn risk signals; measures success by saves, not by revenue protected |
| **Already knows** | That month-to-month customers churn more than contracted ones. The analysis must not spend its credibility restating this |
| **Does not know** | Where churn risk and revenue value diverge, and therefore which segments current allocation systematically over- and under-serves |
| **Information preference** | Numbers first, in currency. Wants the answer before the method. Will challenge any figure they cannot trace |

**Secondary stakeholders:** Chief Commercial Officer (budget authority), Finance Business Partner (validates the revenue case), Head of Propositions (owns any product or bundle remedy).

---

## 5. Business Decision This Analysis Supports

> **How should next year's retention budget be allocated across customer segments and intervention types?**

**Decision branches — stated in advance to keep the analysis honest:**

| If the analysis shows | The decision is |
|---|---|
| Revenue at risk is concentrated in a small number of identifiable segments | Reallocate budget toward proactive intervention in those segments; reduce blanket campaign spend |
| Revenue at risk is broadly distributed across the base | Retain the current broad approach and shift the investment case toward structural remedies — proposition, pricing, service quality — rather than segment targeting |
| A material share of at-risk revenue sits in low-value segments | **Differentiate intervention intensity rather than withdraw it.** Reserve high-cost, high-touch offers for segments where expected retained margin justifies them; serve lower-value segments through lower-cost channels — automated offers, self-serve retention, reactive-only contact |
| The strongest driver is a product or bundle characteristic rather than a customer characteristic | The remedy is a proposition change owned by Propositions, not a retention campaign |

If two branches led to the same action the analysis would not be decision-relevant. They do not.

**The governing principle:** the objective is not to minimise churn at any cost, nor to let low-value customers go. It is to **prioritise retention investment where the expected commercial value justifies intervention.**

---

## 6. Project Objective

To quantify and prioritise the operator's revenue exposure to customer churn, and to produce an evidence-based recommendation on how retention investment should be allocated across the customer base.

---

## 7. Analytical Objectives

1. Establish the base position: churn rate, revenue distribution and revenue concentration.
2. Quantify **annualised revenue at risk** and determine how concentrated or dispersed it is.
3. Identify where **churn-rate ranking and revenue-at-risk ranking diverge** — the analytical spine.
4. Segment the base on the two dimensions driving the decision: **value** and **risk**.
5. Identify and quantify the drivers most associated with elevated risk **within high-value segments specifically**, rather than across the base as a whole.
6. Establish a defensible **retention spend ceiling per segment** — the point beyond which further investment is not justified by expected retained value — sensitivity-tested against stated assumptions.
7. Translate the above into a prioritised allocation recommendation with quantified expected impact.

---

## 8. Scope

**In scope**

- Descriptive and diagnostic analysis of an existing customer base
- Revenue quantification and concentration analysis
- Value–risk segmentation and the divergence index
- Driver analysis focused on high-value segments
- Contract, tenure, service-mix and payment-behaviour dimensions
- Scenario analysis of retention spend under explicit, stated assumptions
- A reusable KPI view layer suitable for a downstream BI consumer
- Relational schema design and normalisation of the source extract
- SQL as the primary analytical engine; Excel only for scenario modelling if warranted

**Analytical techniques in scope**

Tenure-band cohort analysis · revenue concentration (Pareto) via window functions · conditional aggregation · decile segmentation · dual-ranking divergence measurement · cross-dimensional churn indexing · scenario and sensitivity modelling

---

## 9. Out of Scope

Each exclusion is a deliberate decision, to be recorded in `docs/DECISIONS.md` and defended in the README.

| Excluded | Why |
|---|---|
| **Churn prediction / classification model** | The decision requires segment prioritisation, not per-customer probability. A classifier in SQL would be forcing the tool; predictive work belongs to projects 05 and 07. **Approved exclusion, Stage 1** |
| **Customer lifetime value modelling** | Project 07 owns CLV and customer-value modelling. **Approved exclusion, Stage 1 — not to be introduced even if the dataset makes it possible** |
| **Individual customer targeting lists** | Operational output, not analytical insight |
| **Acquisition analysis** | Different budget, different owner, different question |
| **Network or service-quality root cause** | The data cannot support it; would be speculation dressed as analysis |
| **Competitor pricing analysis** | No credible public data at the required granularity |
| **Dashboard build** | Projects 06–08 are the BI deliverables. This project ships a KPI view layer, not a dashboard |
| **Geospatial analysis** | No business question requires it; mapping would be decorative |
| **Sentiment or complaints analysis** | Out of dataset scope |

**Backlog — good questions, deliberately deferred**

- Survival analysis of time-to-churn (requires longitudinal data)
- Price elasticity of retention offers
- Win-back economics for churned customers

---

## 10. Candidate KPIs

Consistent with `_portfolio/KPI_LIBRARY.md`. Benchmarks marked *[to source]* must carry a citation before use — an unsourced benchmark is an invented figure.

| KPI | Formula | Grain | Decision it supports | Status |
|---|---|---|---|---|
| **Churn rate** | Customers churned ÷ customers at risk × 100 | Segment | Baseline exposure | Library |
| **ARPU** | Total recurring revenue ÷ active customers | Segment | Value tiering | Library |
| **Annualised recurring revenue at risk** | Σ (`Monthly Charge` of churned customers) × 12 | Segment | Sizes the business case | Library — **locked by C-2** |
| **Long-distance revenue at risk** | Σ (`Avg Monthly Long Distance Charges` of churned customers) × 12 | Segment | Secondary revenue component — **reported separately, never folded into the headline KPI** | **New — C-2** |
| **Revenue concentration (top-decile share)** | Revenue from top 10% ÷ total revenue × 100 | Base | Tests whether targeting is viable at all | **New** |
| **Value–risk divergence index** | `RANK(churn rate) − RANK(revenue at risk)` | Segment | **Central metric** — locates misallocation | **New** |
| **Revenue retention rate** | Recurring revenue retained ÷ opening recurring revenue × 100 | Base / segment | The CVM lead's actual target measure | **New** |
| **Churn index vs base** | Segment churn rate ÷ overall churn rate | Segment × driver | Normalises driver comparison across unequal segment sizes | **New** |
| **Justifiable retention spend ceiling** | Annual margin at risk × assumed intervention success rate | Segment | Sets the offer ceiling. **Assumption-dependent — reported as a range, never a point estimate** | **New** |

**Deliberately excluded:** total customer count and gross adds — accurate, but they do not inform this decision.

Four additions to `KPI_LIBRARY.md` to be confirmed at FRAME.

---

## 11. Business Questions

Support status assessed against the verified schema in [`docs/DATASET_VALIDATION.md`](docs/DATASET_VALIDATION.md) §D. **Three require rewording before the gate.**

| ID | Business question | Why the stakeholder cares | Support |
|---|---|---|---|
| **BQ-01** | How much annual recurring revenue are we losing to churn? *(trend clause removed — no time dimension)* | Sizes the problem; establishes whether it warrants budget | 🟡 Reword |
| **BQ-02** | Is that lost revenue concentrated in a few segments, or spread across the base? | Determines whether targeting is a viable strategy at all | ✅ |
| **BQ-03** | Are we losing our most valuable customers, or our least valuable ones? | The question that changes the answer, and the one currently unanswered | ✅ |
| **BQ-04** | Where would a churn-rate-led prioritisation diverge from a revenue-led one? *(reworded — no retention activity data exists)* | Identifies the misallocation directly | 🟡 Reword |
| **BQ-05** | What characteristics most distinguish high-value customers who leave from high-value customers who stay? | Tells them what to act on, and whether it is a customer or a product problem | ✅ |
| **BQ-06** | Under stated assumptions, how much would it be worth spending to retain each segment, and where does that break even? *(reworded — scenario, not measurement)* | Converts insight into a budget number | 🟡 Reword |

---

## 12. Analytical Questions

| ID | Analytical question | Answers | Method | Support |
|---|---|---|---|---|
| **AQ-01** | Churn rate and annualised revenue at risk at base level | BQ-01 | Aggregation | 🟡 Period clause dropped |
| **AQ-02** | Revenue distribution across the base; top-decile share | BQ-02 | `NTILE`, cumulative `SUM() OVER` | ✅ |
| **AQ-03** | Churn rate by revenue decile | BQ-03 | Decile × outcome aggregation | ✅ |
| **AQ-04** | Do rankings by churn rate and revenue at risk agree, and where do they diverge? | BQ-03, BQ-04 | Dual `RANK()`; divergence index | ✅ |
| **AQ-05** | Which dimensions index highest for churn **within top revenue deciles**? | BQ-05 | Cross-dimensional churn indexing, filtered to high-value cohorts | ✅ |
| **AQ-06** | Do high-value drivers differ from base-wide drivers? | BQ-05 | Comparative driver analysis | ✅ |
| **AQ-07** | At what retention spend per customer does each segment break even, under stated assumptions? | BQ-06 | Scenario model with sensitivity range | 🟡 Scenario only |

**AQ-06 is the analytical crux.** If high-value churn drivers prove identical to base-wide drivers, the project's central premise weakens. That risk is registered as R-04 and a null result will be reported as a legitimate finding.

---

## 13. Tools

| Tool | For | Why |
|---|---|---|
| **PostgreSQL** | Schema design, cleaning, EDA, all analysis, KPI views | Set-based aggregation, window functions and reusable views are exactly what this analysis needs |
| **Excel** | Retention spend scenario / sensitivity model (AQ-07) only | A two-way data table communicates a break-even surface better than a query result, and matches the stakeholder's own working medium |

**Deliberately not using:**

| Tool | Why not |
|---|---|
| **Python** | The analysis is aggregation, ranking and segmentation over a modest relational dataset — all natively SQL. Adding Python would demonstrate tool use rather than judgement, and predictive capability is evidenced in projects 05 and 07. **To be stated explicitly in the README** |
| **Power BI / Tableau** | Projects 06–08 are the BI deliverables. This project ships a KPI view layer |

*If SOURCE-stage verification produces a materially larger or messier dataset, the Python decision will be revisited and re-approved rather than quietly reversed.*

---

## 14. Deliverables

| Deliverable | Location |
|---|---|
| README, recruiter summary first | `README.md` |
| Schema DDL, load and index scripts | `sql/00_setup/` |
| Cleaning scripts with row-count reconciliation | `sql/01_cleaning/` |
| EDA and profiling queries | `sql/02_eda/` |
| Analysis queries — one per business question | `sql/03_analysis/` |
| Reusable KPI views | `sql/04_kpi_views/` |
| Query results as committed CSV evidence | `analysis/query_results/` |
| Findings register with full evidence chains | `analysis/FINDINGS.md` |
| Charts to the portfolio style guide | `outputs/figures/` |
| Retention spend scenario model | `excel/` |
| Methodology, business questions, case study | `docs/` |
| Stakeholder story incl. 5-minute presentation | `docs/STAKEHOLDER_STORY.md` |
| Decision log | `docs/DECISIONS.md` |
| Data dictionary | `data/DATA_DICTIONARY.md` |
| Dataset validation audit trail | `docs/DATASET_VALIDATION.md` |
| Scored quality gate | `QUALITY_GATE.md` |
| Interview brief section | `_portfolio/INTERVIEW_BRIEF.md` |

---

## 15. Success Criteria

- [ ] All six business questions answered with traceable evidence, or formally rescoped with the reason recorded
- [ ] Annualised revenue at risk quantified and its concentration established
- [ ] The value–risk divergence **measured, not asserted** — query and result committed
- [ ] Every material finding carries a complete chain: query → CSV → chart → finding → insight → implication → recommendation
- [ ] Recommendations are segment-specific, owned, and carry a quantified expected impact with its basis stated
- [ ] A CVM lead could take the output into a budget meeting without further analysis
- [ ] The SQL demonstrates schema design, window functions, CTE composition and reusable views to `SQL_STANDARDS.md`
- [ ] At least one finding is genuinely non-obvious to someone who already works in retention
- [ ] The fictional nature of the data is stated prominently and no finding is framed as a claim about a real operator
- [ ] All sixteen quality gate items pass, with the six weighted items at 3
- [ ] Every number defensible out loud, without notes

---

## 16. Risks and Assumptions

### Constraint: factors the analysis cannot observe

**The analysis informs the prioritisation decision; it does not make it.** Several factors legitimately bearing on retention investment are not observable in the data and must not be implicitly overridden by a revenue-based ranking:

- **Profitability** — cost-to-serve varies by customer and is absent (R-02)
- **Strategic importance** — business accounts, reference customers, households anchoring a multi-service relationship
- **Contractual obligations** — in-term customers where obligations run regardless of value
- **Regulatory and fair-treatment duties** — Ofcom expectations on the treatment of customers, including vulnerable customers, constrain any differentiated-offer strategy. Segmentation that systematically withheld support from an identifiable group would carry regulatory and reputational risk irrespective of its commercial logic
- **Household and bundle relationships** — a low-ARPU line may sit inside a high-value household

The output is a **prioritisation input to a commercial judgement**, subject to these overlays. Stated in the README and the stakeholder story.

**Related decision:** `Gender` and `Senior Citizen` are available in the data but **must not enter any prioritisation rule or recommendation** — descriptive and confounding checks only. See validation §C.1.

### Risks

| # | Risk | Impact | Mitigation |
|---|---|---|---|
| R-01 | **Single snapshot, no time dimension** — confirmed at verification | High | BQ-01 and AQ-01 trend clauses dropped. **Tenure must not be used as a proxy for time** — it is a cohort artefact, not a time series |
| R-02 | **No cost or margin data.** Revenue at risk is measurable; margin at risk requires an assumption | High | Sourced industry margin range, every conclusion as a sensitivity band, never a point estimate presented as measured |
| R-03 | **No intervention outcome data** | Medium | Scenario-model across a stated success-rate range; AQ-07 framed as a decision framework, not a forecast |
| R-04 | **AQ-06 may return a null result** | Medium | A null result is a legitimate finding and will be reported as one. The prioritisation argument survives on concentration (AQ-02/03) regardless |
| R-05 | **Data is fictional** — confirmed, IBM-disclosed | Medium | Prominent labelling; findings framed as method demonstration, never as claims about a real operator or market |
| R-06 | **Scope creep toward prediction** | Medium | Exclusion recorded in §9 and defended in the README as a tool-selection decision |
| R-07 | **Project reads as generic churn analysis** | High | The divergence index, the differentiated-investment framing and the exclusion discipline must be foregrounded in the README summary block, not buried |
| R-08 | **Licence position unresolved** | High | Raw file not committed; provenance and retrieval instructions documented instead. To be resolved before any redistribution decision |
| R-09 | **Revenue field semantics ambiguous** (`Monthly Charge` vs `Total Charges`) | High | Profiling check P-07 decides the annualisation convention. `Total Charges` withheld from revenue-at-risk basis until reconciled |
| R-10 | **Small-cell instability** in high-value driver analysis | Medium | Minimum cell size declared at FRAME **before results are seen**; `n` reported on every segment result |

### Assumptions

| # | Assumption | Basis | If wrong |
|---|---|---|---|
| A-01 | The dataset supports customer-level recurring revenue, tenure, contract and churn status | Verified from IBM field metadata; file-level confirmation pending | Rescope at Stage 2 rather than proceed |
| A-02 | Recurring revenue is a reasonable proxy for customer value absent margin data | Standard practice where cost data is unavailable | Stated as a limitation; sensitivity-tested |
| A-03 | Monthly recurring revenue annualises linearly for at-risk quantification | Simplifying convention, standard in retention business cases | Overstates risk where churn occurs mid-period; the convention is stated explicitly. **Conditional on P-07** |
| A-04 | Retention intervention has a non-zero success rate | Simplifying assumption for scenario modelling | Modelled as a range, never a point estimate |
| A-05 | The dataset represents a single fictional operator at a single point in time | Verified | Affects generalisability; stated in Limitations |
| A-06 | Currency is USD | Presumed from the California setting; unstated in metadata | Presumption stated wherever monetary figures appear; **never presented as £** |

---

## 17. What Makes This Portfolio-Worthy

Churn analysis is the most common project in the field, and doing it conventionally would add nothing. Seven things differentiate this one.

**1. It reframes from a metric to a decision.** The project does not ask "why do customers churn?" It asks "where should a finite budget go?" That is the difference between a report and a piece of analysis.

**2. Its central finding is computed, not assumed.** The value–risk divergence index either shows something or it does not. Most portfolio churn projects assert that value matters; this one measures whether it does.

**3. It makes a commercially disciplined argument.** The objective is not to minimise churn at any cost, but to prioritise retention investment where expected commercial value justifies intervention — with explicit acknowledgement of the strategic, contractual and regulatory factors the data cannot see. Recommending *graduated* rather than uniform intervention, and being clear about the limits of the evidence, is stronger and more defensible than either "save everyone" or "let the low-value ones go."

**4. It demonstrates tool judgement by what it excludes.** Declining to build a churn model, and explaining why in commercial terms, is a stronger signal than building one.

**5. It demonstrates schema design, not just querying.** The source is a wide flat extract; the project normalises it into a documented relational model, including unpivoting nine service flags into a bridge table. Designing the schema evidences understanding that consuming one does not.

**6. It excludes the fields that would have done the work for it.** `Churn Score` is a leaked model output; `CLTV` is an undocumented black-box prediction; `Churn Reason` is an outcome-derived label that would collapse the diagnostic analysis into a `GROUP BY`. Identifying all three, excluding them, and explaining why is analytical judgement that most projects using this dataset miss entirely.

**7. It is defensible under questioning.** Every number traces to a query and a committed CSV. Every assumption is stated and sensitivity-tested. Every exclusion is recorded. The weakest points — R-01, R-02, R-04, R-09 — were identified before the analysis started, so the interview answers are prepared rather than improvised.

---

## Sign-Off

| # | Pre-condition | Status |
|---|---|---|
| 1 | Business problem defined | ✅ **Approved** 19 Aug 2026 — §2 |
| 2 | Dataset identified | 🔶 **Conditionally approved** — pending file verification |
| 3 | Dataset source documented | ✅ **Verified** — IBM primary source, `docs/DATASET_VALIDATION.md` |
| 4 | Analytical questions defined | 🟡 §12 — AQ-01 and AQ-07 rescoped, awaiting confirmation |
| 5 | Business questions defined | 🟡 §11 — BQ-01, BQ-04, BQ-06 reworded, awaiting confirmation |
| 6 | Methodology agreed | 🟡 §13 — approved in principle; final form depends on P-07 |

**Framing, CLV exclusion and prediction exclusion approved by Peters, 19 August 2026.**

**The gate is not yet passed.** Outstanding: file-level verification (profiling checks P-01 to P-15), resolution of the revenue field semantics, and confirmation of the three reworded business questions.

**Gate approved by:** ______________ **Date:** __________
