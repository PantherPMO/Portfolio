<!--
  PROJECT README TEMPLATE
  Structure: recruiter-first summary block, then full technical depth.

  The summary block above the first divider is what 90% of readers see.
  It must stand alone. Everything below it is for the hiring manager and
  the technical interviewer.

  Delete sections that genuinely do not apply — but delete deliberately,
  and never delete Limitations.
-->

# NN — <Project Title>

> **<One sentence stating the business problem and the answer.>**
> *Example: "Monthly-contract customers churn at 3.6× the rate of annual, putting £2.1m of recurring revenue at risk — concentrated in the first 90 days."*

**Tools:** `SQL (PostgreSQL)` · `Excel` · `Power BI` · `Python`
**Domain:** <Telecoms / Logistics / Retail / Finance / Construction / Operations>
**Stakeholder:** <Role — e.g. Chief Commercial Officer>

<!-- SYNTHETIC DATA NOTICE — delete if the data is real, keep prominent if not
> ⚠️ **This project uses synthetic data.** No public dataset links <X> to <Y>.
> The generation specification is documented in `data/synthetic/`. The deliverable
> here is the analytical method, not a claim about any real organisation.
-->

---

## At a Glance

| | | | |
|---|---|---|---|
| **<KPI 1 name>** | **<KPI 2 name>** | **<KPI 3 name>** | **<KPI 4 name>** |
| `<value>` | `<value>` | `<value>` | `<value>` |
| <context / vs benchmark> | <context> | <context> | <context> |

### Key Findings

1. **<Finding, with the number.>** <One line of why it happens.>
2. **<Finding, with the number.>** <One line of why it happens.>
3. **<Finding, with the number.>** <One line of why it happens.>

### Recommendations

1. **<Specific action.>** — <Owner> · Expected impact: <quantified>
2. **<Specific action.>** — <Owner> · Expected impact: <quantified>
3. **<Specific action.>** — <Owner> · Expected impact: <quantified>

![<Dashboard or hero visualisation>](outputs/figures/hero.png)

---
---

## 1. Introduction

<What this project is, in three or four sentences. Written for someone who has never seen it.>

## 2. Business Context

<The organisation, the market, the operating conditions. What pressures is this business under? Why is this analysis being commissioned now?>

## 3. Problem Statement

<The specific problem, stated as a business would state it. Include what it costs to leave unsolved. Avoid analytical language here.>

**The decision this analysis informs:** <Be explicit. If you cannot name a decision, the project has no purpose.>

## 4. Project Objectives

1. 
2. 
3. 

## 5. Dataset

| Attribute | Detail |
|-----------|--------|
| Name | |
| Size | <rows × columns> |
| Granularity | One row = <?> |
| Period covered | |
| Geography | |
| Type | Real / Synthetic |

## 6. Dataset Source

| Attribute | Detail |
|-----------|--------|
| Publisher | |
| URL | <direct working link> |
| Licence | |
| Date accessed | |
| Registry ID | DS-NN — see [`_portfolio/DATASET_REGISTRY.md`](../_portfolio/DATASET_REGISTRY.md) |

<Note any provenance caveats honestly — e.g. a Kaggle dataset whose original source cannot be established.>

## 7. Data Dictionary

Summary below; full version in [`data/DATA_DICTIONARY.md`](data/DATA_DICTIONARY.md).

| Field | Type | Description | Notes |
|-------|------|-------------|-------|
| | | | |

## 8. Case Study

<The scenario. Who has asked for this, what triggered the request, what constraints exist, what the deadline is. This frames everything that follows and makes the work read as a real engagement rather than an exercise.>

## 9. Case Study Questions

<The questions posed by the scenario, as the stakeholder would ask them.>

1. 
2. 

## 10. Business Questions

Mapped to the analytical questions that answer them.

| ID | Business question | Analytical question | Answered in |
|----|-------------------|--------------------|--------------|
| BQ-01 | | | §17, F-01 |
| BQ-02 | | | §17, F-02 |

## 11. Tools & Technologies

| Tool | Used for | Why this tool |
|------|----------|---------------|
| | | |

**Tools deliberately not used:**

> <e.g. "Python was not used. The dataset is 40,000 rows, the analysis is variance decomposition, and the stakeholder works in Excel. Adding Python would have made the deliverable less usable without making it more accurate.">

## 12. Data Preparation

<How the data was loaded and structured. Schema design, staging, joins, the shape it was put into and why.>

## 13. Data Cleaning

| Issue | Rows affected | Treatment | Rationale |
|-------|--------------|-----------|-----------|
| | | | |

**Reconciliation**

| Stage | Row count |
|-------|-----------|
| Raw | |
| After deduplication | |
| After validity filters | |
| Final analytical set | |

<Every difference explained. Unexplained row loss is a red flag to any reviewer.>

## 14. Exploratory Data Analysis

<What the data looked like before analysis. Distributions, relationships, anomalies, and what the EDA changed about the approach. Include the charts that shaped the direction of the work — EDA that had no influence on what followed did not need doing.>

## 15. Methodology

<The analytical approach and why it is appropriate. Assumptions stated. Alternatives considered and why they were rejected. Written so another analyst could repeat it.>

Full detail: [`docs/METHODOLOGY.md`](docs/METHODOLOGY.md)

## 16. KPIs

Definitions consistent with [`_portfolio/KPI_LIBRARY.md`](../_portfolio/KPI_LIBRARY.md).

| KPI | Formula | Grain | Result | Benchmark | Decision it supports |
|-----|---------|-------|--------|-----------|---------------------|
| | | | | | |

## 17. Analysis

<The core analytical narrative, question by question. Each finding shows its evidence.>

### BQ-01: <question>

**Method:** <what was done>
**Evidence:** [`sql/03_analysis/01_....sql`](...) → [`analysis/query_results/01_....csv`](...)

![](outputs/figures/f01_....png)

**Finding (F-01):** <what happened, with the number>
**Insight:** <why it happened — the mechanism, evidenced>
**Implication:** <why it matters, in business terms>

## 18. Visualisations

<Key visuals with what each shows and what it means. Every chart follows [`_portfolio/STYLE_GUIDE.md`](../_portfolio/STYLE_GUIDE.md).>

## 19. Key Findings

Full evidence chains in [`analysis/FINDINGS.md`](analysis/FINDINGS.md).

| ID | Finding | Evidence |
|----|---------|----------|
| F-01 | | |
| F-02 | | |

## 20. Business Insights

<The *why* behind the findings. This section is where data analysis becomes business analysis — each insight explains a mechanism, not just a pattern.>

## 21. Solution

<The proposed approach to the problem, drawing the insights together into a coherent response.>

## 22. Recommendations

| # | Recommendation | Owner | Effort | Expected impact | Basis for the estimate |
|---|---------------|-------|--------|-----------------|------------------------|
| 1 | | | | | |
| 2 | | | | | |

<Prioritised. Specific. Actionable on Monday morning. "Monitor closely" is not a recommendation.>

## 23. Business Impact

<Quantified. What changes if these recommendations are implemented — in £, days, percentage points or capacity. State the basis of every estimate; an unsourced impact figure is an invented insight.>

## 24. Limitations

<Honest and specific. What this analysis cannot tell you, what the data does not cover, what assumptions could be wrong, and where the conclusions are weakest.>

**Never delete this section.** Stating limitations builds more credibility than any finding.

## 25. Future Improvements

1. 
2. 

## 26. Project Structure

```
NN-project-name/
├── README.md
├── PROJECT_CHARTER.md
├── QUALITY_GATE.md
├── data/
├── sql/ | excel/ | python/
├── analysis/
├── outputs/
└── docs/
```

## 27. Reproduction Instructions

**Prerequisites**
- 

**Steps**
1. 
2. 

<Test these by following them yourself on a clean setup. Instructions that have never been run do not work.>

## 28. Author

**Peters** — Data Analyst
📧 olawalemobolajipeters@gmail.com · 🔗 <LinkedIn> · 💻 <GitHub>

---

### Project Documentation

[Charter](PROJECT_CHARTER.md) · [Methodology](docs/METHODOLOGY.md) · [Stakeholder Story](docs/STAKEHOLDER_STORY.md) · [Decisions](docs/DECISIONS.md) · [Findings](analysis/FINDINGS.md) · [Quality Gate](QUALITY_GATE.md)

<!-- DOMAIN PERSPECTIVE — include for projects 02, 04, 05, 08

## Domain Perspective

This analysis applies analytical method within the <industry> context.

Relevant operational considerations include:
- <A constraint or practice a practitioner would recognise>
- <Something that changes how the numbers should be interpreted>
- <A decision that this domain actually has to make>

The analysis was designed around the decisions stakeholders in this domain
routinely need to make.

NOTE: represent experience accurately. The claim is "I understand this domain
from working in it, and have applied analytics to it" — never "I worked as a
data analyst in this domain."
-->
