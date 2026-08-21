# Project Tracker

Single view of all eight projects. Update at the end of every working session.

**Stage key:** ⬜ Not started · 1 DEFINE · 2 SOURCE · 3 FRAME · 4 PREPARE · 5 ANALYSE · 6 COMMUNICATE · 7 REVIEW & SHIP · ✅ Complete

**Last updated:** 21 August 2026

---

## Status Board

| # | Project | Stage | Dataset secured | Charter approved | Quality gate | Blocker |
|---|---------|-------|-----------------|------------------|--------------|---------|
| 01 | SQL — Telecom Revenue Retention | **✅ Complete** (7 REVIEW & SHIP) | ✅ **Verified** | ✅ 19 Aug | ✅ **Passed** | None. Publish-ready |
| 02 | SQL — Warehouse Inventory & Supply Chain | ⬜ | ⬜ | ⬜ | ⬜ | — |
| 03 | Excel — Retail Sales & Customer Behaviour | ⬜ | ⬜ | ⬜ | ⬜ | — |
| 04 | Excel — Financial Performance & Budget Variance | ⬜ | ⬜ | ⬜ | ⬜ | — |
| 05 | Excel — Commercial Pricing & Predictive Cost | ⬜ | ⬜ | ⬜ | ⬜ | — |
| 06 | Power BI — Sales Performance & Commercial Intelligence | ⬜ | ⬜ | ⬜ | ⬜ | — |
| 07 | Power BI/Tableau — Customer Intelligence & CLV | ⬜ | ⬜ | ⬜ | ⬜ | — |
| 08 | Power BI — Executive Operations Intelligence | ⬜ | ⬜ | ⬜ | ⬜ | — |

**Currently active:** Project 02 not yet started. **Project 01 is complete and publish-ready.**

**Project 01 outcome:** all seven stages complete. Validation gates A-VAL-01 to A-VAL-19 all pass; 11 charts built and validated at 88/88 checks. Two pre-registered hypotheses were tested and did not hold, and both are reported. See [`../01-sql-telecom-churn-revenue/README.md`](../01-sql-telecom-churn-revenue/README.md).

**Blocking:** none. Two evidence items remain deliberately open and are recorded as open in the project: **B-5** (no externally sourced margin range, so AQ-07 is not attempted) and **B-6** (no external churn benchmark; Ofcom confirmed not to publish one).

**Stage 2 outcome:** 15 checks — 14 pass, 1 unresolved (currency), 0 fail. Five relational tables confirmed authoritative; merged workbook found defective and demoted to reconciliation only.

---

## Project 01 — Stage Detail

| Stage | Status | Date | Note |
|-------|--------|------|------|
| 1 DEFINE | ✅ **Approved** | 19 Aug 2026 | Reframed from churn analysis to revenue-at-risk prioritisation. CLV and churn prediction excluded by decision |
| 2 SOURCE | ✅ **Approved** | 20 Aug 2026 | Five candidates evaluated. Five-table IBM source selected over the merged workbook on evidence (C-1 / D-06). V-01 corrected by entry, original preserved |
| **GATE** | ✅ **Passed** | 20 Aug 2026 | All pre-conditions met |
| 3 FRAME | ✅ **Approved** | 20 Aug 2026 | C-1 to C-6 locked. Cut points, segments, cell-size thresholds and validation expectations fixed before any result was seen |
| 4 PREPARE | ✅ **Validated** | 20 Aug 2026 | Three-layer schema, 42 SQL files. Defects V-10 and V-11 found and corrected by entry |
| 5 ANALYSE | ✅ **Validated** | 20 Aug 2026 | A-VAL-01 to A-VAL-19 all PASS. A-07 locked (D-21) before the divergence result existed |
| 6 COMMUNICATE | ✅ **Complete** | 21 Aug 2026 | Evidence register, communication plan, 11 charts, 88/88 validation, visual QA, README and case study |
| 7 REVIEW & SHIP | ✅ **Complete** | 21 Aug 2026 | Release audit passed; approved packaging fixes applied |

### Verification findings (all resolved)

| ID | Finding | Effect |
|----|---------|--------|
| **V-01** | The five-table structure is **not publicly obtainable** — Cognos install only | ✅ **Corrected by entry (V-01-C), original preserved.** The five tables were supplied directly and verified. The audit trail retains the falsified hypothesis deliberately |
| **V-02** | Two "extended" variants exist and are routinely conflated | `Satisfaction Score`, `Churn Category` and itemised revenue fields are **absent** from the obtainable file |
| **R-09** | `Monthly Charge` / `Total Charges` semantics ambiguous | ✅ **Resolved.** Profiling check P-07 returned a median ratio of 1.0000; annualisation convention A-03 adopted and stated as an assumption wherever it applies |
| **D** | BQ-01, BQ-04, BQ-06 require rewording | ✅ **Resolved.** All three reworded and approved at C-4. BQ-06 remains deliberately unanswered, blocked on B-5 |
| **V-10** | Source contains the literal string `'None'`, not nulls; pandas had silently coerced it | ✅ **Corrected (D-19).** Caught only because cleaning checks ran in PostgreSQL rather than against a dataframe |
| **V-11** | `NTILE(10)` without a tie-break produced non-deterministic deciles | ✅ **Corrected (D-20)** with an explicit `customer_id` tie-break |

---

## Portfolio Milestones

| Milestone | Target | Status |
|-----------|--------|--------|
| Portfolio architecture approved | 19 Aug 2026 | ✅ Done |
| Control layer built | 19 Aug 2026 | ✅ Done |
| Git initialised, GitHub connected | 19 Aug 2026 | ✅ Done |
| Project 01 charter approved | 19 Aug 2026 | ✅ Done |
| Project 01 dataset verified | 20 Aug 2026 | ✅ Done |
| Project 01 complete | 21 Aug 2026 | ✅ **Done** |
| Project 02 complete | — | ⬜ |
| Project 03 complete | — | ⬜ |
| Project 04 complete | — | ⬜ |
| Project 05 complete | — | ⬜ |
| Project 06 complete | — | ⬜ |
| Project 07 complete | — | ⬜ |
| Project 08 complete | — | ⬜ |
| Portfolio README finalised with results | — | ⬜ |
| CV and LinkedIn updated with portfolio | — | ⬜ |

---

## Session Log

Newest first.

| Date | Project | Work done | Next action |
|------|---------|-----------|-------------|
| 21 Aug 2026 | 01 | Release audit and approved packaging fixes. Portable run paths, redundant query-result duplicates removed, root README and tracker brought into line with the delivered project | **Commit and publish Project 01; start Project 02** |
| 21 Aug 2026 | 01 | Stage 6 COMMUNICATE complete: evidence register, communication plan, 11 charts (88/88 validation), visual QA, README and case study | Release audit |
| 20 Aug 2026 | 01 | Stages 3 to 5. FRAME locked (C-1 to C-6), PREPARE built and validated (42 SQL files, defects V-10 and V-11 corrected), ANALYSE validated (A-VAL-01 to A-VAL-19 all PASS). A-07 locked before results | Begin COMMUNICATE |
| 19 Aug 2026 | 01 | Stage 2 verification. Five candidates compared across 20 criteria. Candidate B conditionally approved. Documentary verification found the five-table premise false (V-01) and two variants conflated (V-02). Project folder created with charter, dataset options, data dictionary, validation audit trail | **Obtain `Telco_customer_churn.xlsx`, run P-01 to P-15, confirm the three reworded business questions** |
| 19 Aug 2026 | 01 | Stage 1 DEFINE. Charter approved — reframed to revenue-at-risk prioritisation; CLV and churn prediction excluded; "differentiated retention investment" framing adopted | Proceed to SOURCE |
| 19 Aug 2026 | Portfolio | Architecture agreed; control layer created (`CLAUDE.md`, standards, registries, templates) | Kick off project 01 |

---

## Open Decisions

| # | Decision needed | Options | Owner | Status |
|---|----------------|---------|-------|--------|
| D-01 | GitHub repository name | `data-analytics-portfolio` / other | Peters | Open |
| D-02 | ~~Project 01 dataset~~ | Candidate B — IBM Telco extended | Peters | ✅ Approved and verified |
| ~~D-03~~ | ~~How to obtain the DS-01 file~~ | Files supplied directly to the connected folder | Peters | ✅ Resolved |
| ~~D-04~~ | ~~Confirm reworded BQ-01, BQ-04, BQ-06~~ | Rewordings accepted at C-4 | Peters | ✅ Resolved |
| **D-05 / B-6** | **Churn benchmark source** | Cite a published source / ship the KPI with no benchmark and say so | Peters | **Open.** Ofcom confirmed not to publish churn or switching rates. Project 01 ships without a benchmark and states this |
| **B-5** | **Sourced margin range for AQ-07** | Obtain a published margin range / leave AQ-07 unanswered | Peters | **Open.** AQ-07 and BQ-06 are shown as not attempted |

---

## Risks

| Risk | Impact | Mitigation |
|------|--------|-----------|
| ~~Dataset file cannot be obtained~~ | ✅ **Retired.** Files supplied and verified at Stage 2 | — |
| DS-01 licence unresolved | Cannot redistribute the raw file | Raw data excluded from git by policy; provenance and retrieval documented instead |
| Fictional data weakens credibility | Reduced portfolio value | Prominent labelling; findings framed as method demonstration; differentiation carried by the reframing and the exclusion discipline |
| No suitable real dataset for a later project's business case | Forces synthetic data | Shortlist datasets at SOURCE before committing to the business problem |
| Scope creep within a project | Nothing finishes | Charter fixes scope; new questions go to the backlog |
| Eight projects started, none finished | Portfolio has no value | Strict one-at-a-time build sequence |
| Dashboards prioritised over reasoning | Portfolio looks generic | Quality gate weights insight and recommendation quality above visual polish |
| Detail forgotten before interview | Cannot defend the work | `INTERVIEW_BRIEF.md` written at stage 7, while fresh |
