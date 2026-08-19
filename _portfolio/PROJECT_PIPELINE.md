# Project Pipeline

The seven-stage lifecycle every project must follow, and the sign-off record for each.

---

## The Lifecycle

```
   ┌──────────┐
   │ 1 DEFINE │  Business problem, stakeholder, the decision this supports
   └────┬─────┘  → PROJECT_CHARTER.md
        ▼
   ┌──────────┐
   │ 2 SOURCE │  Find and verify the dataset; log provenance and licence
   └────┬─────┘  → DATASET_REGISTRY.md entry
        ▼
   ┌──────────┐
   │ 3 FRAME  │  Business questions, analytical questions, KPIs, methodology
   └────┬─────┘  → BUSINESS_QUESTIONS.md, METHODOLOGY.md
        │
   ═════╪═══════════════ THE GATE ═══════════════════════════
        │   No analysis before this point. Non-negotiable.
        ▼
   ┌──────────┐
   │ 4 PREPARE│  Clean, transform, document; reconcile row counts
   └────┬─────┘  → cleaning scripts, DATA_DICTIONARY.md, cleaning log
        ▼
   ┌──────────┐
   │ 5 ANALYSE│  EDA → analysis → evidence-chained findings
   └────┬─────┘  → query_results/, FINDINGS.md
        ▼
   ┌──────────┐
   │6 COMMUNIC│  Dashboards, figures, stakeholder story, README
   └────┬─────┘  → outputs/, STAKEHOLDER_STORY.md, README.md
        ▼
   ┌──────────┐
   │ 7 REVIEW │  Score the quality gate, write the interview brief, ship
   └──────────┘  → QUALITY_GATE.md, INTERVIEW_BRIEF.md, commit
```

---

## The Six Pre-Conditions

Analysis (stage 4 onward) may not begin until **all six** are defined and approved by Peters:

1. ✅ The business problem is defined
2. ✅ The dataset has been identified
3. ✅ The dataset source has been documented
4. ✅ The analytical questions are defined
5. ✅ The business questions are defined
6. ✅ The methodology is agreed

This is the single most important control in the portfolio. It is what makes the work analysis rather than exploration.

---

## Stage Detail

### Stage 1 — DEFINE
Establish what business problem exists and who owns it. Name a real stakeholder role with genuine decision authority. State the decision the analysis will inform. If you cannot name a decision, the project has no purpose.

**Exit:** `PROJECT_CHARTER.md` approved by Peters.

### Stage 2 — SOURCE
Search real public sources in the priority order set in `CLAUDE.md` §4.1. Shortlist two or three candidates and assess each against the business case. Verify the URL works, check the licence, note row counts and known quality issues.

If no real dataset can support the case, propose synthetic data under `CLAUDE.md` §4.3 and **wait for approval**.

**Exit:** `DATASET_REGISTRY.md` entry complete; dataset downloaded to `data/raw/` with a provenance README.

### Stage 3 — FRAME
Translate the business problem into questions.

- **Business questions** — what the stakeholder wants to know, in their language
- **Analytical questions** — how each will actually be answered with the data
- **KPIs** — defined against `KPI_LIBRARY.md`, with formula, grain and benchmark
- **Methodology** — the analytical approach, and why it is appropriate

**Exit:** All six pre-conditions signed off. **This is the gate.**

### Stage 4 — PREPARE
Load, profile, clean. Every transformation documented and reproducible. Raw data is immutable — never edited in place. Reconcile row counts before and after cleaning and explain every difference.

**Exit:** Clean dataset, data dictionary, cleaning log with reconciliation.

### Stage 5 — ANALYSE
EDA first, then targeted analysis against the framed questions. Every finding gets an ID and a full evidence chain (`CLAUDE.md` §5.2). Save query results as CSV so findings are verifiable without rerunning anything.

Apply the finding → insight → implication → recommendation progression to every material result.

**Exit:** `FINDINGS.md` complete, every claim evidenced.

### Stage 6 — COMMUNICATE
Build the visual and narrative layer: charts to `STYLE_GUIDE.md`, dashboards to spec, the stakeholder story, and the README with its recruiter-first summary.

**Exit:** README complete; a reader who knows nothing about the project understands the problem, the answer, and what to do about it.

### Stage 7 — REVIEW & SHIP
Score all sixteen quality gate items honestly. Fix or document every gap. Write the interview brief while the work is fresh. Then, on instruction, commit and push.

**Exit:** Quality gate passed; project marked ✅ in `PROJECT_TRACKER.md`.

---

## Sign-Off Register

Record the date each stage was approved. Empty rows are projects not yet started.

### Project 01 — SQL: Telecommunications Customer Churn & Revenue Analytics

| Stage | Approved | Date | Notes |
|-------|----------|------|-------|
| 1 DEFINE | ⬜ | | |
| 2 SOURCE | ⬜ | | |
| 3 FRAME | ⬜ | | |
| **GATE** | ⬜ | | All six pre-conditions |
| 4 PREPARE | ⬜ | | |
| 5 ANALYSE | ⬜ | | |
| 6 COMMUNICATE | ⬜ | | |
| 7 REVIEW & SHIP | ⬜ | | |

### Project 02 — SQL: Warehouse Inventory & Supply Chain Performance

| Stage | Approved | Date | Notes |
|-------|----------|------|-------|
| 1 DEFINE | ⬜ | | |
| 2 SOURCE | ⬜ | | |
| 3 FRAME | ⬜ | | |
| **GATE** | ⬜ | | |
| 4 PREPARE | ⬜ | | |
| 5 ANALYSE | ⬜ | | |
| 6 COMMUNICATE | ⬜ | | |
| 7 REVIEW & SHIP | ⬜ | | |

### Project 03 — Excel: Retail Sales & Customer Behaviour Analysis

| Stage | Approved | Date | Notes |
|-------|----------|------|-------|
| 1 DEFINE | ⬜ | | |
| 2 SOURCE | ⬜ | | |
| 3 FRAME | ⬜ | | |
| **GATE** | ⬜ | | |
| 4 PREPARE | ⬜ | | |
| 5 ANALYSE | ⬜ | | |
| 6 COMMUNICATE | ⬜ | | |
| 7 REVIEW & SHIP | ⬜ | | |

### Project 04 — Excel: Financial Performance & Budget Variance Analysis

| Stage | Approved | Date | Notes |
|-------|----------|------|-------|
| 1 DEFINE | ⬜ | | |
| 2 SOURCE | ⬜ | | |
| 3 FRAME | ⬜ | | |
| **GATE** | ⬜ | | |
| 4 PREPARE | ⬜ | | |
| 5 ANALYSE | ⬜ | | |
| 6 COMMUNICATE | ⬜ | | |
| 7 REVIEW & SHIP | ⬜ | | |

### Project 05 — Excel + Python: Commercial Pricing & Predictive Cost Analysis

| Stage | Approved | Date | Notes |
|-------|----------|------|-------|
| 1 DEFINE | ⬜ | | |
| 2 SOURCE | ⬜ | | |
| 3 FRAME | ⬜ | | |
| **GATE** | ⬜ | | |
| 4 PREPARE | ⬜ | | |
| 5 ANALYSE | ⬜ | | |
| 6 COMMUNICATE | ⬜ | | |
| 7 REVIEW & SHIP | ⬜ | | |

### Project 06 — Power BI: Sales Performance & Commercial Intelligence

| Stage | Approved | Date | Notes |
|-------|----------|------|-------|
| 1 DEFINE | ⬜ | | |
| 2 SOURCE | ⬜ | | |
| 3 FRAME | ⬜ | | |
| **GATE** | ⬜ | | |
| 4 PREPARE | ⬜ | | |
| 5 ANALYSE | ⬜ | | |
| 6 COMMUNICATE | ⬜ | | |
| 7 REVIEW & SHIP | ⬜ | | |

### Project 07 — Power BI / Tableau + Python: Customer Intelligence & Lifetime Value

| Stage | Approved | Date | Notes |
|-------|----------|------|-------|
| 1 DEFINE | ⬜ | | |
| 2 SOURCE | ⬜ | | |
| 3 FRAME | ⬜ | | |
| **GATE** | ⬜ | | |
| 4 PREPARE | ⬜ | | |
| 5 ANALYSE | ⬜ | | |
| 6 COMMUNICATE | ⬜ | | |
| 7 REVIEW & SHIP | ⬜ | | |

### Project 08 — Power BI: Executive Operations Intelligence

| Stage | Approved | Date | Notes |
|-------|----------|------|-------|
| 1 DEFINE | ⬜ | | |
| 2 SOURCE | ⬜ | | |
| 3 FRAME | ⬜ | | |
| **GATE** | ⬜ | | |
| 4 PREPARE | ⬜ | | |
| 5 ANALYSE | ⬜ | | |
| 6 COMMUNICATE | ⬜ | | |
| 7 REVIEW & SHIP | ⬜ | | |
