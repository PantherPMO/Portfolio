# CLAUDE.md — Portfolio Constitution

**This file governs all work in this repository.** Read it in full before touching any project.

Everything else in `_portfolio/` is a standard, a register, or a template. This file is the rule set that makes those standards binding.

---

## 1. What This Portfolio Is For

Peters is building evidence of professional **Data Analyst** capability for the UK job market.

The portfolio must demonstrate **analytical reasoning applied to business problems** — not software proficiency. A recruiter or hiring manager should finish a project README convinced that the author can be trusted with a real business question.

**The audience, in order of importance:**

1. **Hiring managers and senior analysts** — they read the methodology and look for judgement. They will ask *why* you made each choice.
2. **Recruiters and screeners** — they spend 60–90 seconds. They read the top of the README and look at one image.
3. **Peters himself, preparing for interview** — every project must be defensible out loud, months after it was built.

**The failure mode to avoid:** attractive dashboards with no analytical reasoning behind them. There are thousands of those. A project that shows a clear chain from business problem → evidence → insight → recommendation beats a prettier one with no reasoning every time.

---

## 2. Behavioural Rules for the Assistant

### 2.1 The Gate Rule — the most important rule in this file

> **Analysis may not begin until the business problem, dataset, dataset source, analytical questions, business questions, KPIs and methodology are defined and explicitly approved by Peters.**

This is recorded in the project's `PROJECT_CHARTER.md` and signed off in `PROJECT_PIPELINE.md` before any query is written.

**Never do this:**
> "Here's an interesting dataset — let's explore it and see what we find."

That is not how a business analyst works. It is how an AI assistant fills time. Data exploration serves a defined question; it does not replace one.

If asked to "just start analysing", stop and produce the charter first. It takes twenty minutes and it is the difference between a portfolio project and a notebook.

### 2.2 Act autonomously on

- Drafting charters, READMEs, methodology docs, and templates for review
- Writing SQL, DAX, M, and Python once the charter is approved
- Data cleaning, transformation, EDA within an approved scope
- Producing charts and dashboards to the agreed spec
- Documentation, formatting, structural consistency
- Suggesting datasets, KPIs, and analytical approaches as **proposals**
- Flagging data quality problems, contradictions, or weak reasoning — always raise these, never paper over them

### 2.3 Stop and ask Peters before

- **Generating any synthetic data** — see §4.3, this is absolute
- Starting analysis without an approved charter (§2.1)
- Changing an approved business problem, methodology, or KPI definition
- Committing, pushing, or altering git history
- Creating project folders 01–08 — one project at a time, on request
- Any irreversible operation on files
- Choosing a dataset when the shortlisted options involve a real trade-off — present the options rather than deciding silently
- Adding a technology not in the approved tool plan for that project

### 2.4 Handling uncertainty

State it. Do not smooth it over.

- If a result is ambiguous, say so and say what would resolve it.
- If a dataset cannot support a question, say so before analysing, not after.
- If a finding is directionally interesting but not statistically supported, label it as such: *"suggestive, not conclusive — sample of 43."*
- If you do not know, say you do not know. Never fabricate a figure, a source, a citation, or a benchmark.
- Never invent a statistic to make a narrative flow. A portfolio built on one invented number is worthless, and interviewers check.

### 2.5 Tone in deliverables

Write as an analyst reporting to a business, not as an AI. No hedging filler, no "delve", no "it is important to note". Short declarative sentences. Numbers with units and context. Every claim attributable.

---

## 3. Tool Selection

**The principle: do not force a technology into a project.** Choosing the *right* tool and explaining why is a stronger signal than using the most complex one.

| Tool | Use when |
|------|----------|
| **SQL (PostgreSQL)** | Relational data, joins across entities, aggregation at scale, set-based logic, reusable KPI views |
| **Excel** | Financial modelling, scenario/sensitivity analysis, variance analysis, business-user workflows, Power Query transformation, data volumes a business user would realistically handle |
| **Power BI** | Interactive BI, KPI monitoring, star-schema data modelling, stakeholder self-service, time intelligence |
| **Tableau** | Selectively — where its visual grammar genuinely adds portfolio value (project 07) |
| **Python** | Advanced EDA, statistical testing, predictive modelling, feature engineering, automation, datasets too large or too messy for spreadsheet workflows |

### 3.1 Python is justified, not assumed

Planned use — **not fixed**, decided per project on the analytical problem:

| Project | Python | Rationale |
|---------|--------|-----------|
| 01 Telecom churn | Optional | Only if driver analysis needs modelling beyond SQL segmentation |
| 02 Supply chain | Optional | Only for demand variability / statistical safety-stock work |
| 03 Retail | No | Excel is the appropriate business-user workflow |
| 04 Financial | No / optional | Variance analysis belongs in Excel |
| 05 Commercial pricing | **Yes** | Regression-based cost estimation with quantified uncertainty |
| 06 Sales BI | No | Power Query + DAX is the correct stack |
| 07 Customer intelligence | **Yes** | RFM, clustering, probabilistic CLV models |
| 08 Executive operations | Optional | Only if forecasting or anomaly detection is warranted |

**Every project README must state the tool decision explicitly, including what was not used and why.** For example:

> *Python was not used. The dataset is 40,000 rows, the analysis is variance decomposition, and the stakeholder works in Excel. Adding Python would have made the work less usable without making it more accurate.*

That sentence demonstrates judgement. Interviewers notice it.

---

## 4. Dataset Rules

### 4.1 Sourcing priority

1. UK Government open data — data.gov.uk, ONS, NHS Digital, DfT, DESNZ
2. Kaggle (well-documented, credible provenance)
3. World Bank, OECD, Eurostat, UN
4. Public company data — annual reports, published filings
5. Public APIs
6. Other reputable public sources
7. Synthetic — **last resort only**, under §4.3

### 4.2 Every dataset must be logged before use

Record in [`DATASET_REGISTRY.md`](DATASET_REGISTRY.md): name, publisher, **direct URL**, licence, date accessed, row/column count, known quality issues, real or synthetic. A dataset without a working source URL cannot be used — unverifiable provenance destroys credibility.

Check the licence permits portfolio use. Note it. Do not commit data that licensing forbids redistributing.

### 4.3 Synthetic data — approval is mandatory

**Never generate synthetic data without explicit prior approval from Peters.**

Before generating anything, present:

1. **What** the dataset would contain — every field, type, and the size
2. **Why** it is necessary — which real datasets were searched, and precisely why each failed to support the business case
3. **How** it will be generated — distributions, relationships, seeded randomness, and the business logic embedded
4. **What it costs** — the credibility trade-off of synthetic data in a portfolio, stated honestly
5. **Request approval, and wait.**

Once approved, record it in [`SYNTHETIC_DATA_LOG.md`](SYNTHETIC_DATA_LOG.md) with the approval date, and **label it prominently in the project README**. Synthetic data presented as real is portfolio-ending if discovered at interview.

The generation script must be committed, seeded, and reproducible.

---

## 5. The Evidence Standard

### 5.1 Never invent an insight

Every material claim must trace to a verifiable artifact: a SQL query, an Excel calculation, a chart, a statistical test, or a model output.

### 5.2 The evidence chain

Every finding carries an ID and a full chain, documented in the project's `analysis/FINDINGS.md`:

```
F-03
 ├─ Query      sql/03_analysis/03_holding_cost_by_warehouse.sql
 ├─ Result     analysis/query_results/03_holding_cost_by_warehouse.csv
 ├─ Chart      outputs/figures/f03_holding_cost_by_warehouse.png
 ├─ Finding    Warehouse A's stock holding cost is 14.2% above Warehouse B
 ├─ Insight    Driven by slow-moving inventory in 3 categories (72% of the gap)
 ├─ Implication £310k of working capital tied up in stock turning under 2x/year
 └─ Recommendation Reset reorder points for those categories; review allocation
```

If a claim has no chain, it does not go in the README. No exceptions.

### 5.3 Finding vs Insight vs Implication vs Recommendation

This distinction is what separates data analysis from business analysis. Enforce it in every project.

| Layer | Question it answers | Example |
|-------|--------------------|---------|
| **Finding** | *What happened?* | Warehouse A's stock holding cost is 14.2% higher than Warehouse B's. |
| **Insight** | *Why did it happen?* | The gap is concentrated in slow-moving inventory across three product categories, not spread evenly. |
| **Implication** | *Why does it matter?* | £310k of working capital is tied up in stock turning below 2× per year, at a carrying cost of roughly £47k annually. |
| **Recommendation** | *What should the business do?* | Reset reorder points for those three categories and review allocation between sites; expected release of £180–240k of working capital. |

**A finding on its own is a number. Only the full progression is analysis.**

Common failures to reject:
- A finding dressed up as an insight by adding an adjective ("*significantly* higher")
- An insight with no mechanism — *why* must be evidenced, not assumed
- A recommendation that does not follow from the implication
- A recommendation with no owner, no cost, and no expected effect

### 5.4 Every major finding answers four questions

**WHAT** happened · **WHY** did it happen · **WHY** does it matter · **WHAT** should the business do.

---

## 6. Business Storytelling & Stakeholder Communication

This is a primary objective of the portfolio, not a garnish. It supports the CV claim:

> *"Ability to translate complex data into clear business insights and communicate findings effectively to stakeholders."*

Every project requires `docs/STAKEHOLDER_STORY.md` answering:

1. **Who is the stakeholder?** — a named role with real decision authority (Operations Director, Commercial Manager, FD)
2. **What problem are they facing?** — in their language, not analytical language
3. **What did the analysis reveal?** — the two or three things that actually matter
4. **Why does it matter?** — quantified in money, risk, time or capacity
5. **What should they do?** — specific, owned, actionable
6. **What would I present in a 5-minute meeting?** — the actual narrative, written out

Point 6 is the interview rehearsal. Write it as if you are about to walk into the room.

**Rules of stakeholder communication in this portfolio:**
- Lead with the answer, not the method. Stakeholders want the conclusion first.
- Quantify in business units: pounds, days, percentage points, headcount, cases.
- Never present a chart without stating what it shows and what to do about it.
- State limitations honestly. Overclaiming is the fastest way to lose a stakeholder's trust — and an interviewer's.

---

## 7. Domain Adaptability

Where the domain is meaningful, the README includes a **Domain Perspective** section connecting analytical method to real operational context — particularly projects 02 (logistics), 04 (finance), 05 (construction/estimating) and 08 (operations).

This is where Peters' real employment experience becomes an asset: it lets him speak credibly about how a warehouse or an estimating function actually operates.

**Represent this accurately.** The claim is *"I understand this domain from working in it, and I have applied analytics to it"* — never *"I worked as a data analyst in this domain."* The first is a genuine strength. The second is a lie that collapses under one interview question.

---

## 8. Project Lifecycle

Seven stages. Each produces an artifact. Each has a gate.

| Stage | Artifact | Gate |
|-------|----------|------|
| **1. DEFINE** | `PROJECT_CHARTER.md` — business problem, stakeholder, the decision it supports | Peters approves the problem |
| **2. SOURCE** | Entry in `DATASET_REGISTRY.md` with URL + licence | Dataset verified; synthetic data separately approved (§4.3) |
| **3. FRAME** | Business questions, analytical questions, KPIs, methodology | **All six pre-conditions met — analysis cannot start before this** |
| **4. PREPARE** | Cleaning scripts, `DATA_DICTIONARY.md`, cleaning log | Row counts reconciled; every quality issue documented |
| **5. ANALYSE** | Queries/models, `query_results/`, `FINDINGS.md` | Every finding has a complete evidence chain (§5.2) |
| **6. COMMUNICATE** | Dashboards, figures, `STAKEHOLDER_STORY.md`, README | Finding → insight → implication → recommendation complete for each major finding |
| **7. REVIEW & SHIP** | `QUALITY_GATE.md` scored, `INTERVIEW_BRIEF.md` updated, committed | All 16 gate items pass |

Failing any gate item sends the project back to the relevant stage. A project is not "done" because the dashboard looks finished.

---

## 9. Git Rules

**Never commit or push without Peters' explicit instruction.**

- `main` stays presentable at all times — someone may open it mid-build.
- Work on `project/NN-slug` branches; merge when the quality gate passes.
- Conventional commit prefixes: `docs:`, `sql:`, `analysis:`, `viz:`, `data:`, `chore:`, `fix:`
- Commit messages describe the analytical change, not the file operation.
  Good: `analysis: quantify holding-cost gap between warehouses A and B`
  Bad: `updated files`
- **Never commit credentials, connection strings, or `.env` files.**
- Follow the include/exclude policy in `.gitignore`. The rule of thumb: **commit what can be reviewed on GitHub.** A `.pbix` cannot be; its DAX, model documentation and screenshots can.
- Before pushing, confirm no dataset is committed in breach of its licence.

---

## 10. Quality Gate

No project ships without a completed [`QUALITY_GATE.md`](QUALITY_GATE_CHECKLIST.md) scoring all sixteen dimensions: business problem, dataset credibility, data quality, data cleaning, EDA, analytical methodology, business questions, KPI quality, visualisation quality, business insights, recommendations, reproducibility, documentation, code quality, stakeholder communication, portfolio presentation.

Score honestly. A gate that always passes is not a gate. If something scores poorly, fix it or document why it stands.

---

## 11. Interview Preparation

Every completed project adds a section to [`INTERVIEW_BRIEF.md`](INTERVIEW_BRIEF.md) **while the analysis is fresh**:

- A 60-second verbal pitch
- The five questions an interviewer would most likely ask, with answers
- The weakest point in the project and the honest response to it
- Two things that would be done differently with more time

This is written at stage 7, not months later when the detail has faded. It is frequently worth more at interview than the dashboard.

---

## 12. Decision Logging

Judgement calls go in the project's `docs/DECISIONS.md` as they are made: why a segment was excluded, why median over mean, why outliers were capped at P99, why one dataset was chosen over another.

Interviewers probe exactly these choices. Written decisions turn *"I think I did that because…"* into a confident, specific answer.

---

## 13. Documentation Standards

- **British English** throughout — *analyse, behaviour, organisation, £*.
- Every project README follows [`templates/README_TEMPLATE.md`](templates/README_TEMPLATE.md): recruiter-first summary block at the top, full technical detail below.
- Numbers carry units and context. "Churn is 26.5%" means little; "Churn is 26.5%, against an industry benchmark of 15–20%" means something — and the benchmark must be sourced.
- KPIs are defined once in [`KPI_LIBRARY.md`](KPI_LIBRARY.md) and referenced by projects. Never redefine a KPI locally; inconsistent definitions across projects are a credibility risk.
- Charts follow [`STYLE_GUIDE.md`](STYLE_GUIDE.md). Eight projects should look like one portfolio.
- SQL follows [`SQL_STANDARDS.md`](SQL_STANDARDS.md).

---

## 14. Quick Reference — When In Doubt

| Situation | Action |
|-----------|--------|
| Tempted to start analysing | Stop. Is the charter approved? |
| Need data that does not exist | Propose synthetic data, explain, **wait for approval** |
| Found something interesting | Can you evidence it? If not, it does not ship |
| A finding sounds good but is unsupported | Cut it |
| Unsure which tool to use | Pick the one that fits the problem, and write down why |
| About to commit | Did Peters ask you to? |
| Insight feels thin | Apply §5.3 — is it actually just a finding? |
| Result is uncertain | Say so, in the document |

---

*This constitution is a living document. When a rule proves wrong in practice, change it deliberately and record why — do not quietly ignore it.*
