# Portfolio Charter

**Owner:** Peters
**Established:** 19 August 2026
**Status:** Active

---

## 1. Objective

To produce eight end-to-end analytics projects that demonstrate professional Data Analyst capability to UK employers — specifically, the ability to take an undefined business problem, source and interrogate data, and deliver evidence-based recommendations a stakeholder can act on.

**This portfolio is judged on analytical reasoning, not tool count.**

---

## 2. Target Roles

- Data Analyst
- Business Analyst (data-focused)
- Business Intelligence Analyst
- Commercial / Operations Analyst
- Reporting Analyst

**Market:** United Kingdom. Documentation uses British English and £ currency; datasets favour UK sources where relevant.

---

## 3. Audience

| Audience | Time spent | What they look for |
|----------|-----------|--------------------|
| Recruiter / screener | 60–90 seconds | Tools listed, a clear headline, one strong image |
| Hiring manager | 5–10 minutes | Business framing, methodology, quality of recommendation |
| Senior analyst / technical interviewer | 15+ minutes, then questions | SQL/DAX quality, statistical soundness, honest limitations |
| Peters, pre-interview | As needed | Ability to reconstruct and defend the work months later |

Every project must serve all four. The README structure — recruiter summary first, technical depth below — exists for exactly this reason.

---

## 4. Capability Map

| Capability | Primary evidence | Supporting |
|------------|-----------------|------------|
| SQL | 01, 02 | — |
| Microsoft Excel | 03, 04, 05 | 06, 07, 08 (source layer) |
| Power BI | 06, 08 | 07 |
| Tableau | 07 | — |
| Python | 05, 07 | 01, 02, 08 (as justified) |
| Exploratory Data Analysis | All | — |
| Business Intelligence | 06, 07, 08 | — |
| Predictive Analytics | 05, 07 | — |
| Data storytelling | All (`STAKEHOLDER_STORY.md`) | — |
| Stakeholder communication | All | — |
| Business problem solving | All (`PROJECT_CHARTER.md`) | — |
| Domain adaptability | 02, 04, 05, 08 | — |
| KPI development | All (`KPI_LIBRARY.md`) | — |
| Evidence-based recommendation | All (`FINDINGS.md`) | — |

---

## 5. Project Portfolio

| # | Project | Domain | Primary tools | Python |
|---|---------|--------|--------------|--------|
| 01 | Telecommunications Customer Churn & Revenue Analytics | Telecoms | PostgreSQL | Optional |
| 02 | Warehouse Inventory & Supply Chain Performance | Logistics | PostgreSQL | Optional |
| 03 | Retail Sales & Customer Behaviour Analysis | Retail | Excel | No |
| 04 | Financial Performance & Budget Variance Analysis | Finance | Excel | No / optional |
| 05 | Commercial Pricing & Predictive Cost Analysis | Construction / Commercial | Excel + Python | **Yes** |
| 06 | Sales Performance & Commercial Intelligence | Sales | Excel → Power BI | No |
| 07 | Customer Intelligence & Lifetime Value | Customer analytics | Excel → Power BI / Tableau | **Yes** |
| 08 | Executive Operations Intelligence | Operations | Excel → Power BI | Optional |

Domain spread is deliberate — it evidences adaptability. Projects 04 and 08 are the natural candidates for UK public-sector or published-company data, strengthening the dataset-credibility story for a UK employer.

---

## 6. Standards

Binding standards, all in `_portfolio/`:

| Document | Governs |
|----------|---------|
| [`CLAUDE.md`](CLAUDE.md) | **The constitution** — behaviour, gates, evidence rules |
| [`PROJECT_PIPELINE.md`](PROJECT_PIPELINE.md) | The seven-stage lifecycle and sign-offs |
| [`DATASET_REGISTRY.md`](DATASET_REGISTRY.md) | Dataset provenance and licensing |
| [`SYNTHETIC_DATA_LOG.md`](SYNTHETIC_DATA_LOG.md) | Synthetic data approvals |
| [`QUALITY_GATE_CHECKLIST.md`](QUALITY_GATE_CHECKLIST.md) | The 16-point ship criteria |
| [`KPI_LIBRARY.md`](KPI_LIBRARY.md) | Single definition of every KPI |
| [`STYLE_GUIDE.md`](STYLE_GUIDE.md) | Visual and dashboard standards |
| [`SQL_STANDARDS.md`](SQL_STANDARDS.md) | Query conventions |
| [`INTERVIEW_BRIEF.md`](INTERVIEW_BRIEF.md) | Interview readiness per project |

---

## 7. Non-Negotiables

1. **No analysis before an approved charter.** (`CLAUDE.md` §2.1)
2. **No invented insights.** Every claim traces to a verifiable artifact. (§5)
3. **No synthetic data without prior written approval.** (§4.3)
4. **No unlabelled synthetic data.** Ever.
5. **Every major finding progresses** finding → insight → implication → recommendation. (§5.3)
6. **Every project has a named stakeholder** and a stakeholder story.
7. **No project ships** without a scored quality gate.
8. **No commit or push** without explicit instruction.

---

## 8. Definition of Done

A project is complete when:

- [ ] Charter approved, all seven lifecycle stages signed off
- [ ] Dataset registered with a working source URL and licence
- [ ] All findings carry a complete evidence chain
- [ ] README complete, recruiter summary at the top
- [ ] Stakeholder story written, including the 5-minute presentation
- [ ] Decisions log complete
- [ ] Quality gate scored, all 16 items passed
- [ ] Interview brief written
- [ ] Committed to `main` and rendering correctly on GitHub

---

## 9. Build Sequence

**One project end-to-end, then the next.** Project 01 is completed and quality-gated before project 02 begins.

Rationale: a finished, interview-ready project has value immediately. Eight half-built projects have none — and the lessons from finishing the first materially improve the seven that follow.

---

*Reviewed at the completion of each project. Amend deliberately; record what changed and why.*
