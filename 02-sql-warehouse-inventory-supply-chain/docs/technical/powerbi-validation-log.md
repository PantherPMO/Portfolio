# Power BI Validation Log

**Project 02 — Warehouse Inventory & Supply Chain Performance**
Model: `calderfield_inventory_supply_chain.pbix` · Source: PostgreSQL 16, schema `supply`
Storage mode: Import · Canvas: 1280 × 720 · Pages: 6

Every figure below was checked against the committed result files in `analysis/query_results/`.
A check passes only when the dashboard value equals the committed value exactly.

---

## 1. SQL → Power BI reconciliation

The dashboard reads seven reporting views. Four of the six fact tables are filtered to a single
`grain_level` in Power Query, because the views publish several grains in one result set.

| Query | Source view | Grain filter | Expected rows | Status |
|---|---|---|---:|---|
| `Fact Inventory KPI` | views 01 + 02 + 03, merged | `4 — site and category` | 32 | ✅ |
| `Fact Availability` | `vw_kpi_availability_and_fill_rate` | `4 — site and category` | 32 | ✅ |
| `Fact Opportunity` | `vw_working_capital_release_opportunity` | none — flat view | 515 | ✅ |
| `Fact Supplier Delivery` | `vw_kpi_supplier_on_time_delivery` | `4 — supplier` | 29 | ✅ |
| `Fact Supplier Network` | `vw_kpi_supplier_on_time_delivery` | `1 — network` | 1 | ✅ |
| `Fact Supplier Trend` | `vw_kpi_supplier_on_time_delivery` | `3 — supplier type by half-year` | 16 | ✅ |
| `Fact Cycle Time` | `vw_kpi_order_cycle_time` | `3 — supplier` | 29 | ✅ |
| `Fact Cycle Time By Type` | `vw_kpi_order_cycle_time` | `2 — supplier type` | 4 | ⚠ see §7 |
| `Fact Cycle Time By Site` | `vw_kpi_order_cycle_time` | `4 — receiving site` | 4 | ⚠ see §7 |
| `Detail SKU Value` | `vw_sku_value_position` | none | 250 | ✅ |
| `Detail Policy Alignment` | `vw_policy_alignment` | none | 467 | ✅ |
| `Detail Purchase Structure` | `vw_purchase_quantity_structure` | none | 2,063 | ✅ |
| `Detail Dual Source` | `vw_dual_source_gap` | none | 60 | ✅ |

**Encoding.** The database was rebuilt with `PGCLIENTENCODING=UTF8` after a client-encoding
mismatch corrupted every em dash in the reporting-view labels. Three DAX objects held the corrupted
string literally and were rewritten using `UNICHAR(8212)` so the character is constructed rather
than typed: `[Unclassified Stock Value]`, the `Basis` calculated column, and the Power Query grain
filters.

---

## 2. KPI validation

| KPI | Expected | Source | Status |
|---|---|---|---|
| Average inventory | £2,043,979 | `report_01` | ✅ |
| Closing inventory | £1,711,042 | `report_07` | ✅ |
| Inventory turns | 4.67 | `report_01` | ✅ |
| Days inventory outstanding | see §6 | `report_02` | ⚠ |
| Order lines not supplied in full | 7.71% | `report_04` | ✅ |
| Weeks closing at zero | 3.52% | `report_04` | ✅ |
| Weeks with a zero-stock day | 5.05% | `report_04` | ✅ |
| Value of demand not met | £1,027,629 (upper bound) | `report_04` | ✅ |
| Working capital identified | £468,897 | `report_07` | ✅ |
| Annual holding cost at 22% | £103,157 | `report_07` | ✅ |
| Stock with no identified opportunity | £835,219 | `report_07` | ✅ |
| Discontinued exposure | £87,478 | `report_07` | ✅ |
| On time, first receipt | 89.8% (n = 3,766) | `report_05` | ✅ |
| On time, all receipts | 80.1% (n = 4,241) | `report_05` | ✅ |
| OTIF, line complete | 79.1% (n = 3,768) | `report_05` | ✅ |
| Split delivery rate | 11.1% | `report_05` | ✅ |
| Minimum-order increment, 2025 | £995,659 network-wide | `analyse_17` | ✅ |
| Average incremental cycle stock | £497,830 | `analyse_17` | ✅ |

**Opportunity hierarchy — must total, and must be mutually exclusive:**

| Tier | Positions | Stock value | Working capital | Annual holding |
|---|---:|---:|---:|---:|
| 1 — discontinued or obsolete | 25 | £87,478 | £87,478 | £19,245 |
| 2 — importer and minimum-order structural | 148 | £416,075 | £303,558 | £66,783 |
| 3 — above the calibrated requirement | 125 | £357,897 | £70,755 | £15,566 |
| 4 — slow-moving residual | 8 | £14,373 | £7,106 | £1,563 |
| 5 — no identified opportunity | 209 | £835,219 | £0 | £0 |
| **Total** | **515** | **£1,711,042** | **£468,897** | **£103,157** |

87,478 + 303,558 + 70,755 + 7,106 = **468,897** ✅

**Holding-rate sensitivity** — the disconnected `Param Holding Rate` table moves the holding-cost
measure only. Working capital must not move.

| Rate | Annual holding cost | Status |
|---|---:|---|
| 20% | £93,779 | ✅ |
| 22% (approved, D-11) | £103,157 | ✅ |
| 25% | £117,225 | ✅ |

**Two sums that must never appear:** one-off capital added to annual holding cost, and the five
overlapping exposures added together. £1,109,016 appears once, on P2-V5, explicitly marked
*"do not use"*. ✅

---

## 3. Relationship validation

**15 relationships — 11 required (R1–R9, R11, R12) plus 4 optional (R13–R16).**

| Check | Expected | Status |
|---|---|---|
| Total relationship count | 15 | ✅ |
| Cardinality | Many-to-one on all 15 | ✅ |
| Cross-filter direction | Single on all 15 | ✅ |
| Active | All 15 active; no dotted lines | ✅ |
| One-to-one relationships | None | ✅ |
| Ambiguity warnings in Model view | None | ✅ |
| **R10 absent** | No line between `Detail SKU Value` and `Dim Product` | ✅ |

**R10 was specified and then deleted (D-41).** Both sides hold exactly 250 rows unique on `sku`, so
Power BI detects one-to-one and forces bidirectional cross-filtering, which cannot be set to
Single. That created an ambiguous filter path between `Fact Opportunity` and `Dim Category`. R11
already reaches `Dim Category` directly, so R10 was unnecessary. **It must not be recreated.**
R11 keeps its identifier and is not renumbered.

Five further relationships are documented as prohibited and were not built.

---

## 4. Dashboard and page validation

| # | Page | Visuals | Status |
|---|---|---|---|
| 1 | Executive Overview | 7 KPI tiles, 5 visuals | ⚠ see §7 |
| 2 | Inventory & Working Capital | 5 KPI tiles, 6 visuals | ⚠ see §7 |
| 3 | Availability & Replenishment | 4 KPI tiles, 7 visuals | ⚠ see §7 |
| 4 | Supplier Reliability & Lead Time | 4 KPI tiles, 5 visuals | ⚠ see §7 |
| 5 | Sourcing Economics | 2 KPI tiles, 3 visuals | ⚠ see §7 |
| 6 | Site Investigations & Decision Watchlist | title bar, 6 tiles, 4 visuals | ⚠ see §7 |

Page 4 was originally specified as one page and is built as two (D-42). As a single page it gave
its bottom row 112px, which cannot hold a scatter chart, and it answered two questions rather than
one. No measure, field or finding changed.

**Design constraints held:** page size 1280 × 720 throughout; no dual-axis chart except the Pareto,
where the line is a cumulative transformation of the same measure as the columns; bar axes start at
zero; every KPI tile carries a basis tag in place of the "vs target" comparison this project cannot
honestly supply.

**Interactions deliberately disabled** on visuals reading disconnected reference tables or
pre-computed non-aggregable values: P2-V5, P3-V2, P3-V5, P3-V6, P3-V7, P4-V2, P4-V3, P4-V4, P4-V5,
P4-V6, P4-V8, P5-V4. These are not oversights — a percentile re-aggregated by a slicer is a wrong
number that looks plausible.

---

## 5. Screenshot validation

Six PNG exports, one per page, in `powerbi/screenshots/`.

| File | Page | Status |
|---|---|---|
| `01_executive_overview.png` | 1 | ⚠ see §7 |
| `02_inventory_working_capital.png` | 2 | ⚠ see §7 |
| `03_availability_replenishment.png` | 3 | ⚠ see §7 |
| `04_supplier_reliability_lead_time.png` | 4 | ⚠ see §7 |
| `05_sourcing_economics.png` | 5 | ⚠ see §7 |
| `06_site_investigations_watchlist.png` | 6 | ⚠ see §7 |

**Naming and coverage: pass.** All six files exist, correctly named, one per page, captured at 2×
(approximately 2566 × 1446).

**Size: fail against the portfolio style guide**, which specifies ~1600px wide and under 500 KB.
Current files are 578 KB – 1.02 MB at ~2566px and need downscaling before release.

A full six-page PDF export is also committed as `calderfield_inventory_supply_chain.pdf`.

---

## 6. Known basis difference — days inventory outstanding

**The dashboard reports 78.1 days; the committed SQL result reports 78.2.** This is a documented
basis difference, not a defect, and it is retained deliberately for this release.

```
Inventory turns, unrounded   9,550,572.04 ÷ 2,043,979.36 = 4.672538
365 ÷ 4.672538  = 78.116  → 78.1     DAX measure M3
365 ÷ 4.67      = 78.158  → 78.2     reporting view 02
```

The view divides by the rounded turns; the DAX measure divides by the unrounded value. The same
mechanism gives Livingston 128.7 in Power BI against 128.5 in SQL. `report_02` already publishes
both columns — `days_inventory_outstanding` and `days_inventory_outstanding_unrounded_basis` —
and its own reconciliation check records the 0.10 difference as **PASS**.

Both figures are defensible. The dashboard is internally consistent with itself, and the
documentation is internally consistent with the committed results. Anyone comparing the two should
read this note.

---

## 7. Final QA status

# ⚠ NOT SIGNED OFF

**Analytical layer: passed.** Every KPI, every tier, the hierarchy total, the holding-rate
sensitivity, the relationship model and the interaction rules reconcile to committed results.

**Presentation layer: open.** A screenshot review found visuals whose frames are too small for
their content — categories and rows are cut off with scrollbars rather than displayed — along with
several auto-generated titles, unformatted numbers and two visuals reading a source at the wrong
grain. These are display and binding defects; none of them changes a committed number.

The outstanding items are tracked in the repair guide and must be cleared, and the screenshots
re-captured, before this log can be signed off.

---

*Figures reconcile to committed PostgreSQL results in `analysis/query_results/`.
Decisions D-01 to D-42 in `docs/technical/analytical-decisions.md`.*
