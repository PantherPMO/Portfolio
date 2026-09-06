# Technical and supporting material

Supporting evidence for the analysis. None of this is required reading to understand the project. Start with the [project README](../../README.md), then [`docs/case-study.md`](../case-study.md).

| Document | What it contains |
|---|---|
| [`analytical-decisions.md`](analytical-decisions.md) | The full decision record: 42 methodological decisions taken during the analysis, each with the evidence behind it and the alternative that was rejected |
| [`powerbi-dashboard-spec.md`](powerbi-dashboard-spec.md) | Dashboard specification: pages, visuals, KPI definitions and the basis attached to each figure |
| [`powerbi-implementation-guide.md`](powerbi-implementation-guide.md) | Data model design: tables, relationships, the 16 DAX measures and the reasoning behind each |
| [`powerbi-build-guide.md`](powerbi-build-guide.md) | Step-by-step build instructions, from the PostgreSQL connection through to the finished report |
| [`powerbi-visual-build-sheet.md`](powerbi-visual-build-sheet.md) | Per-visual settings: field wells, positions, formatting and interaction rules |
| [`powerbi-validation-log.md`](powerbi-validation-log.md) | Reconciliation of every dashboard KPI against its committed SQL result |
| [`database-setup.md`](database-setup.md) | How to rebuild the PostgreSQL database from the committed CSV files |

## Why the data model documentation is this detailed

The dashboard is a presentation layer over results that already exist in this repository. The specification records which reporting view feeds each visual, at what grain, and why certain interactions are deliberately disabled, so that any figure on screen can be traced back to the SQL that produced it.

Several of those design constraints are analytical rather than cosmetic. Percentile and median columns are pre-computed in SQL and cannot be re-aggregated by a slicer without producing a wrong answer. One-off working capital and annual holding cost are never placed in a visual that could total them. The reference tables carrying fixed network figures are deliberately disconnected from the model so they cannot be filtered into something they are not.
