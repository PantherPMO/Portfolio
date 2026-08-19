# Templates

Copy these into a project at the stage they are needed. Do not edit them in place — edit the copy.

| Template | Copy to | Created at stage |
|----------|---------|------------------|
| `PROJECT_CHARTER_TEMPLATE.md` | `NN-project/PROJECT_CHARTER.md` | 1 DEFINE |
| `DATA_DICTIONARY_TEMPLATE.md` | `NN-project/data/DATA_DICTIONARY.md` | 4 PREPARE |
| `DECISIONS_TEMPLATE.md` | `NN-project/docs/DECISIONS.md` | 1 DEFINE, appended throughout |
| `FINDINGS_TEMPLATE.md` | `NN-project/analysis/FINDINGS.md` | 5 ANALYSE |
| `STAKEHOLDER_STORY_TEMPLATE.md` | `NN-project/docs/STAKEHOLDER_STORY.md` | 6 COMMUNICATE |
| `README_TEMPLATE.md` | `NN-project/README.md` | 6 COMMUNICATE |
| `QUALITY_GATE_TEMPLATE.md` | `NN-project/QUALITY_GATE.md` | 7 REVIEW & SHIP |

---

## Canonical Project Structure

Every project uses this shape, with the tool-specific branch that applies.

```
NN-tool-project-name/
├── README.md                    ← recruiter summary first, then 28 sections
├── PROJECT_CHARTER.md           ← approved before analysis begins
├── QUALITY_GATE.md              ← scored last
│
├── data/
│   ├── raw/                     ← immutable; README.md documents provenance
│   ├── processed/               ← cleaned outputs
│   ├── synthetic/               ← only if approved; includes generate.py
│   └── DATA_DICTIONARY.md
│
├── analysis/
│   ├── query_results/           ← CSV evidence — committed, always
│   └── FINDINGS.md              ← the evidence register
│
├── outputs/
│   ├── figures/                 ← exported charts (PNG)
│   └── reports/                 ← executive summary
│
└── docs/
    ├── METHODOLOGY.md
    ├── BUSINESS_QUESTIONS.md
    ├── CASE_STUDY.md
    ├── STAKEHOLDER_STORY.md
    └── DECISIONS.md
```

### Tool branches

**SQL projects (01, 02)**

```
├── sql/
│   ├── 00_setup/                ← DDL, load scripts, indexes
│   ├── 01_cleaning/
│   ├── 02_eda/
│   ├── 03_analysis/             ← one numbered file per business question
│   └── 04_kpi_views/
```

**Excel projects (03, 04, 05)**

```
├── excel/
│   ├── 01_raw_import.xlsx
│   ├── 02_cleaned_model.xlsx
│   ├── 03_analysis_workbook.xlsx    ← the deliverable
│   └── WORKBOOK_GUIDE.md            ← sheet map, formula logic, Power Query steps
├── power_query/                      ← M code exported as .txt so it is reviewable
```

> A `.xlsx` on GitHub is an opaque binary. Exporting the M code and key formulas as text is what makes Excel work *reviewable* — most Excel portfolios fail precisely here.

**BI projects (06, 07, 08)**

```
├── powerbi/
│   ├── <project>.pbix               ← not committed by default; see .gitignore
│   ├── dax/MEASURES.md              ← every measure as documented code
│   ├── model/DATA_MODEL.md          ← star schema, relationships, grain
│   └── screenshots/                 ← every dashboard page
├── tableau/                          ← project 07 only; + Tableau Public link
└── docs/DASHBOARD_SPEC.md            ← audience, decisions supported, wireframe
```

> Screenshots are non-negotiable. Nobody installs Power BI Desktop to review a candidate.

**Python** — added only where justified (`CLAUDE.md` §3.1):

```
├── python/
│   ├── notebooks/                   ← exploration
│   └── src/                         ← reusable functions
```
