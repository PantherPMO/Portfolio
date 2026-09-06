# Power BI Dashboard Specification — Project 02: Warehouse Inventory & Supply Chain Performance

> **Calderfield Trade Supplies Ltd is fictional and this dataset is synthetic.** This
> specification describes how to present completed analysis. It introduces no new findings, no
> new SQL and no new recommendations.

**Status:** Specification only. No `.pbix` has been built.
**Source of truth:** the 35 SQL files, 32 committed results in `analysis/query_results/`, and
decisions D-01 to D-40 in `docs/technical/analytical-decisions.md`.
**Scope rule:** every KPI, visual and callout in this document traces to an existing view or a
committed result. Where the required detail does not exist, it is listed in
§10 *Items requiring clarification* rather than invented.

---

## 1. The story the dashboard must tell

> **This is an allocation and replenishment-design problem, not simply an overstock or
> understock problem.**

Calderfield holds **£2,043,979** of average inventory turning **4.67** times, and in the same
year failed to supply **7.71%** of order lines in full on demand worth up to **£1,027,629**.
Those two facts are usually treated as opposite problems needing opposite fixes. Here they occur
at the same sites, in the same year, and frequently on the same shelves.

The dashboard exists to make that coexistence unavoidable on first glance, and then to explain
the four mechanisms behind it: supplier minimums that set order quantities instead of demand,
replenishment settings that track where demand has been, a single deteriorating supplier, and a
sourcing trade-off between unit price and working capital.

### What the dashboard must never let a reader conclude

| Wrong conclusion it could invite | Guard built into the design |
|---|---|
| "Cut inventory everywhere" | Tier 5 (£835,219, 48.8%) is given equal visual weight to the opportunity tiers on Pages 1 and 2 |
| "£1,109,016 is available" | The naive sum appears **once**, on Page 2, explicitly as the error being avoided |
| "£468,897 + £103,157 = £572,054" | Capital and holding cost are never placed in the same visual, never share an axis, and carry one-off / annual tags on every card |
| "Far East importers are getting worse" | The supplier-type trend visual carries the leave-one-out series as a second line, not a tooltip |
| "The February buy-ahead caused the excess" | Presented on Page 4 as a **completed, net-positive** decision with its residual already carved out |
| "Old policies cause poor service" | Policy age appears on Page 3 **only** in the rejected-hypothesis panel |
| "Daventry / Bristol are simply overstocked" | Both carry a persistent unresolved-constraint banner on every page where their opportunity appears |

---

## 2. Recommended Power BI Data Model

### 2.1 Connection approach

**Connector:** PostgreSQL database connector (Npgsql). Host, port, database `calderfield`,
schema `supply`.

**Import mode, not DirectQuery.** Reasons specific to this project:

- The dataset is **frozen and reproducible** — 147,589 rows against fixed anchor dates of
  2025-12-31 / 2025-12-28. Nothing changes between refreshes, so DirectQuery buys nothing.
- The largest object the dashboard needs is `mv_inventory_week` at 51,220 rows. The reporting
  views are between 4 and 515 rows. The whole model is comfortably under 100,000 rows.
- Several reporting views use `GROUPING SETS`, `PERCENTILE_CONT` and window functions.
  DirectQuery would push filter predicates into those, and a percentile computed over a
  slicer-filtered subset is **not the same number** as the committed result. Import freezes the
  view output exactly as the committed `.txt` files show it.
- A portfolio reviewer must be able to open the `.pbix` without a live database.

**Refresh:** manual. This is a fixed-period analysis, not an operational report.

### 2.2 Fact tables

| # | Model table | Source | Grain | Rows | Additive? |
|---|---|---|---|---:|---|
| F1 | `Fact Inventory KPI` | Merge of `vw_kpi_inventory_value_and_turnover` + `vw_kpi_days_inventory_outstanding` + `vw_kpi_stock_holding_cost`, filtered to `grain_level = '4 — site and category'` | Site × category | 32 | Values yes, ratios **no** |
| F2 | `Fact Availability` | `vw_kpi_availability_and_fill_rate`, filtered to `grain_level = '4 — site and category'` | Site × category | 32 | Counts yes, rates **no** |
| F3 | `Fact Opportunity` | `vw_working_capital_release_opportunity` | SKU × site at 2025-12-28 | 515 | Yes |
| F4 | `Fact Supplier Delivery` | `vw_kpi_supplier_on_time_delivery`, filtered to `grain_level = '4 — supplier'` | Supplier | 29 | See warning §2.7 |
| F5 | `Fact Supplier Trend` | `vw_kpi_supplier_on_time_delivery`, filtered to `grain_level = '3 — supplier type by half-year'` | Supplier type × half-year | 16 | See warning §2.7 |
| F6 | `Fact Cycle Time` | `vw_kpi_order_cycle_time`, filtered to `grain_level = '3 — supplier'` | Supplier | 29 | Percentiles **no** |
| F7 | `Fact Inventory Week` | `mv_inventory_week` | SKU × site × week | 51,220 | Yes |
| F8 | `Fact Demand Line` | `vw_demand_line`, filtered to `order_date` in 2025 | Order line | 16,506 | Yes |

**Three views, one table (F1).** Reporting views 01, 02 and 03 sit at the identical grain and 02
and 03 are derived from 01 (D-37). Importing them as three tables would create three paths to the
same dimensions and invite an ambiguous-relationship error. Merge them in Power Query on
`(grain_level, warehouse_code, category_code)`. **This is a modelling decision, not new database
logic** — no calculation is changed.

**Why filter to the cell grain.** All five reporting views with a `grain_level` column carry
network, site, category and cell rows in one result set. Importing them whole and summing any
measure **quadruples it**. Filtering to the finest grain and letting Power BI aggregate upward is
the correct pattern, and it was verified in Stage 5 that site rows and category rows each sum to
the network row within £0.05 (D-37).

### 2.3 Detail views for four specific visuals

These four exist in the database and carry detail the executive views do not. Each is imported
only for the named visual.

| # | Model table | Source view | Created by | Needed for |
|---|---|---|---|---|
| D1 | `Detail SKU Value` | `vw_sku_value_position` | `04_analysis/02` | P2-V3 ABC concentration |
| D2 | `Detail Policy Alignment` | `vw_policy_alignment` | `04_analysis/16` | P3-V4, P3-V5 alignment bands and outcome |
| D3 | `Detail Purchase Structure` | `vw_purchase_quantity_structure` | `04_analysis/17` | P4-V6 minimum-order structural effect |
| D4 | `Detail Dual Source` | `vw_dual_source_gap` | `04_analysis/14` | P4-V7 sourcing trade-off |

**Stated coupling, because it is a real dependency.** These four are created by *analysis* files
rather than reporting files. They persist in the database after a full pipeline run, but a
database rebuilt only as far as Stage 5 would not contain them. **The full 35-file pipeline must
have been run before a Power BI refresh.** This is recorded as a data-model limitation in §10 and
is not resolved here, because resolving it would mean writing new SQL.

### 2.4 Dimension tables

All four are existing base tables in `supply`. Nothing is invented.

| Dimension | Source table | Rows | Key |
|---|---|---:|---|
| `Dim Warehouse` | `warehouse` | 4 | `warehouse_code` |
| `Dim Category` | `product_category` | 8 | `category_code` |
| `Dim Supplier` | `supplier` | 30 | `supplier_code` |
| `Dim Product` | `product` | 250 | `sku` |

Two further dimensions are **disconnected** (no relationships) and exist only to drive measures
and labels:

| Disconnected table | Purpose | Built from |
|---|---|---|
| `Holding Rate` | 20% / **22% (default)** / 25% sensitivity toggle | Entered manually, 3 rows — the three rates already published in every reporting view |
| `Opportunity Tier Order` | Sort order for the five tiers | Entered manually, 5 rows keyed on `opportunity_mechanism` |

`Dim Supplier Type` is **not** a separate table — `supplier_type` is a column on `Dim Supplier`
and on F4/F5/F6, and creating a fifth dimension for four values would add an ambiguous path for
no benefit.

### 2.5 Relationships

```
Dim Warehouse (warehouse_code) 1 ──► * F1 Fact Inventory KPI
                               1 ──► * F2 Fact Availability
                               1 ──► * F3 Fact Opportunity
                               1 ──► * F7 Fact Inventory Week
                               1 ──► * F8 Fact Demand Line
                               1 ──► * D2 Detail Policy Alignment
                               1 ──► * D3 Detail Purchase Structure

Dim Category  (category_code)  1 ──► * F1, F2, F3, F7, F8, D1, D2, D3, D4

Dim Supplier  (supplier_code)  1 ──► * F4 Fact Supplier Delivery
                               1 ──► * F6 Fact Cycle Time

Dim Product   (sku)            1 ──► * F3, F7, F8, D2, D3      ← NOT D1, see note below

Holding Rate                   ✗ disconnected
Opportunity Tier Order         1 ──► * F3  (on opportunity_mechanism)
```

All relationships **single-direction, one-to-many, dimension filtering fact**. No bi-directional
filtering anywhere — it is the most common source of silent double counting in a model with
several facts at different grains.

`F5 Fact Supplier Trend` has **no relationship to `Dim Supplier`** — its grain is supplier *type*,
not supplier. Relating it would fan out. It is filtered by its own `supplier_type` column only.

> **Correction applied after the Power BI build (D-41).** This diagram originally listed **D1
> `Detail SKU Value`** under `Dim Product`. That relationship — later numbered **R10** in the
> implementation guide — **must not be created.** D1 and `Dim Product` both hold 250 rows unique on
> `sku`, so Power BI makes it **one-to-one** and forces **bidirectional** filtering, which produces
> an ambiguous filter path between `Dim Category` and `F3 Fact Opportunity`.
>
> D1 keeps its `category_code` relationship to `Dim Category` (**R11**), which is a genuine
> many-to-one and supports category filtering of the ABC visual (P2-V3). **P2-V3 is unaffected** —
> it reads every field directly from D1 and never reaches through `Dim Product`.
>
> No visual, KPI, measure or page in this specification changes as a result.

### 2.6 Grain of every source view, stated explicitly

| View | Grain | Row count | Note |
|---|---|---:|---|
| `vw_kpi_inventory_value_and_turnover` | 4 grain levels in one result | 45 | Filter before use |
| `vw_kpi_days_inventory_outstanding` | Same as above | 45 | Derived from view 01 |
| `vw_kpi_stock_holding_cost` | Same as above | 45 | Derived from view 01 |
| `vw_kpi_availability_and_fill_rate` | 4 grain levels | 45 | Two clocks — see §2.8 |
| `vw_kpi_supplier_on_time_delivery` | 5 grain levels | 56 | Levels numbered 1–5 |
| `vw_kpi_order_cycle_time` | **4** grain levels | 39 | Levels numbered 1–4 — **numbering differs from view 05** |
| `vw_working_capital_release_opportunity` | SKU × site, flat | 515 | No grain column; safe to sum |
| `mv_inventory_week` | SKU × site × week | 51,220 | 2024–2025; filter to 2025 for KPI consistency |
| `vw_demand_line` | Order line | 33,422 | Filter to 2025 order dates → 16,506 |

**Gotcha worth its own line:** `grain_level = '3 — ...'` means *category* in views 01–04, *supplier
type by half-year* in view 05, and *supplier* in view 06. Filter on the literal string, never on
the leading digit.

### 2.7 How double counting is avoided

1. **Never import a `grain_level` view unfiltered.** Every import applies a Power Query filter to
   exactly one grain. Where two grains are needed (F4 and F5 from the same view), they are two
   separate queries with different names.
2. **Never sum a ratio.** Turns, DIO, fill rates, on-time percentages and percentiles are
   pre-computed at the view's grain. Recompute them in DAX from additive numerators and
   denominators — §4 lists the measures that do this.
3. **Never sum a percentile.** `median_cycle_days`, `p90_cycle_days` and `iqr_days` in F6 are
   valid only at the row's own grain. Display them in a table; never aggregate them.
4. **Never sum across opportunity tiers and Stage 4 exposures.** F3 is already mutually exclusive
   and exhaustive (D-36). The Stage 4 exposure figures appear only as static reference values in
   one visual (P2-V6).
5. **Never place `working_capital_gbp` and `annual_holding_cost_gbp` on the same axis.** They are
   different types of quantity on different clocks (D-29).

### 2.8 Two clocks, kept apart

`vw_kpi_availability_and_fill_rate` combines two time bases in one row, by design (D-22):

- **Stock measures** (`sku_weeks`, `weeks_closing_at_zero`, `weeks_with_a_zero_day`) run on the
  **52 ISO snapshot weeks** of 2025.
- **Fulfilment measures** (`demand_lines`, `unmet_units`, `unmet_value_gbp`) run on **order date
  within calendar 2025**, which includes the 133 lines dated 29–31 December that no snapshot week
  covers (D-13).

Unmet demand is **£1,027,629** on the order-date basis and **£1,025,038** on the snapshot-week
basis. The **£2,591** difference is that boundary.

**The dashboard must not silently reconcile it.** The Page 3 methodology tooltip states both
figures and names the boundary. A single "unmet demand" figure with no basis stated is a
correctness defect, not a simplification.

### 2.9 Known relationship conflicts

| Conflict | Resolution |
|---|---|
| F1, F2 at site × category; F3 at SKU × site | Both relate to `Dim Warehouse` and `Dim Category` independently. `Dim Product` filters F3 but **not** F1/F2 — a product slicer will blank Page 1/2 aggregate cards. Do not place a product slicer on those pages. |
| F4 and F5 originate from one view at two grains | Imported as two queries. F5 deliberately has no supplier relationship. |
| F5 `supplier_type` vs `Dim Supplier[supplier_type]` | A supplier-type slicer on Page 4 must be bound to **one** of them. Bind it to `Dim Supplier[supplier_type]` and cross-filter F5 by its own column via a synchronised slicer, or accept that F5 visuals use their own field. Recorded in §10. |
| `Dim Supplier` does not filter F3 | F3 carries `sourcing_last_used` (a type, not a code) rather than a supplier code, by D-18. A supplier slicer will not filter the opportunity page. |
| Holding Rate is disconnected | Intentional. It drives measures via `SELECTEDVALUE`, never a relationship. |

---

## 3. Dashboard pages

Five pages. Naming kept close to the brief.

### Global elements on every page

| Element | Content |
|---|---|
| Header band | Page title · "Calderfield Trade Supplies Ltd — synthetic dataset · calendar 2025 · fixed anchor 2025-12-31" |
| Footer strip | "Figures reconcile to committed PostgreSQL results in `analysis/query_results/`. Decisions D-01 to D-40." |
| Methodology button | Opens a bookmark overlay covering the 22% rate derivation, the upper-bound list and the two clocks |

---

## PAGE 1 — EXECUTIVE OVERVIEW

### Objective
Make the central paradox unavoidable within ten seconds, size the opportunity honestly, and stop
the reader concluding "cut inventory".

### Primary business questions
1. How can the business hold £2.0m of inventory and still fail to supply 7.71% of order lines?
2. Where is the capital, and how much of it can be argued against?
3. Which sites behave differently, and why is that not a simple ranking?

### KPI cards

| # | Metric | Definition | Source | Type |
|---|---|---|---|---|
| K1 | **Average inventory** £2,043,979 | Mean of 52 weekly snapshots, 2025 | F1 `average_stock_gbp` | Stock (level) |
| K2 | **Closing inventory** £1,711,042 | Position at 2025-12-28 | F1 `closing_stock_gbp` | Stock (level, single instant) |
| K3 | **Inventory turns** 4.67 | Cost of sales ÷ average inventory | `[Inventory Turns]` | Ratio |
| K4 | **Days inventory outstanding** 78.2 | 365 ÷ turns | `[Days Inventory Outstanding]` | Ratio (days) |
| K5 | **Order lines not supplied in full** 7.71% | 1,272 ÷ 16,506 lines | `[Lines Short Rate %]` | Percentage |
| K6 | **Identified working-capital opportunity** £468,897 | Sum of five mutually exclusive tiers | `[Selected Opportunity Value]` | **One-off** capital · partly **upper bound** |
| K7 | **Annual holding-cost opportunity** £103,157 | Opportunity × 22% | `[Selected Annual Holding Cost]` | **Annual** flow · assumption-based (D-11) |

**Card behaviour.** K1/K2 carry the subtitle "average, not closing" and "single instant"
respectively. K6 carries a persistent `▲ upper bound in part` tag. K7 carries `per annum · 22%
assumed`. K6 and K7 sit in a bordered group captioned **"One-off capital · Annual cost — never
added"**. That caption is not decoration; it is the guard against the most likely
misinterpretation in the whole dashboard.

### Visuals

---

**P1-V1 · The paradox: inventory held against demand missed**

- **Type:** Two-axis combination — clustered column (average inventory £, left axis) with a line
  and markers (lines short %, right axis), one column group per site, plus a network column.
- **Business purpose:** Show in one frame that cover and service do not move together. Livingston
  holds the deepest cover and serves well; Bristol holds the least and serves worst; Daventry
  holds the most capital and sits in between.
- **Source:** F1 (`average_stock_gbp`) and F2 (`demand_lines`, `lines_not_supplied_in_full`),
  both related to `Dim Warehouse`.
- **Fields:** Axis `Dim Warehouse[warehouse_name]`. Column `[Inventory Value]`. Line
  `[Lines Short Rate %]`.
- **Measures:** `[Inventory Value]`, `[Lines Short Rate %]`.
- **Filters/slicers:** Category slicer applies. Site slicer does **not** apply (the visual is the
  site comparison).
- **Drill-through:** Right-click a site → Page 5 *Site Investigations*, carrying the site filter.
- **Tooltip:** Site, average inventory, closing inventory, turns, DIO, line fill %, unmet value.
  Plus: *"Inventory is the mean of 52 weekly snapshots. Fulfilment is order-date basis. See
  methodology."*
- **Interpretation note:** **The two series must not be read as a correlation.** Four points is
  not a relationship. The visual shows coexistence, not causation. A site with high inventory and
  poor service is not thereby proven to be wasting the inventory.

---

**P1-V2 · Where the capital sits, and how much has a case against it**

- **Type:** Stacked horizontal bar, single bar, segmented by opportunity mechanism, showing
  **position stock value** across the five tiers.
- **Business purpose:** Show the whole £1,711,042 estate at once, with tier 5 (£835,219, 48.8%)
  visually dominant. This is the anti-"cut everywhere" visual.
- **Source:** F3 `vw_working_capital_release_opportunity`.
- **Fields:** Legend `opportunity_mechanism` (sorted by `Opportunity Tier Order`). Value
  `SUM(position_stock_value_gbp)`.
- **Measures:** `[Stock Value at Closing]`, `[Opportunity Share of Stock %]`.
- **Filters/slicers:** Site and category slicers apply.
- **Drill-through:** Right-click a segment → Page 2 *Inventory & Working Capital*.
- **Tooltip:** Tier, positions, stock value, releasable capital, annual holding cost, and the
  tier's `service_consequence` text verbatim from the view.
- **Interpretation note:** **The bar shows stock held, not capital releasable.** Tier 2 holds
  £416,075 of stock but only £303,558 is claimable, and that is an upper bound. Data labels must
  read stock value; releasable capital appears only in the tooltip and on Page 2.

---

**P1-V3 · The opportunity hierarchy, counted once**

- **Type:** Matrix, five rows plus total.
- **Business purpose:** The single most important table in the dashboard. Presents the classified
  hierarchy with capital and holding cost in separate, clearly headed columns.
- **Source:** F3.
- **Fields:** Rows `opportunity_mechanism`. Columns: Positions, Stock value, **Working capital
  (one-off)**, **Annual holding cost at 22%**, and a Basis column.
- **Measures:** `[Positions]`, `[Stock Value at Closing]`, `[Selected Opportunity Value]`,
  `[Selected Annual Holding Cost]`.
- **Filters/slicers:** Site and category apply. Holding-rate slicer applies to the holding-cost
  column only.
- **Tooltip:** Source reference from `source_reference`, e.g. `04_analysis/17 — F-17; D-18, D-34`.
- **Interpretation note:** Column headers must carry the units — "£ one-off" and "£ per annum".
  The Basis column reads *Definitional* for tier 1, *Upper bound* for tiers 2 and 4, *Measured*
  for tier 3, and *None* for tier 5. A total row is shown for capital and holding cost
  **separately**; there is no grand total across the two columns.

---

**P1-V4 · The central finding**

- **Type:** Text callout panel with a rule above and below. Static text, dynamic figures via
  measures.
- **Business purpose:** State the story in words, because a reader who takes only one thing from
  the page should take this.
- **Content:**
  > **£2.0m of inventory and a 7.71% line-fill failure are happening at the same time, at the
  > same sites.**
  > This is an **allocation and replenishment-design** problem, not an overstock or understock
  > problem. Settings track where demand has been, not where it is going: rising-demand lines sit
  > at 0.68 of the network's own working rule and falling-demand lines at 1.33. Separately,
  > supplier minimums — not replenishment decisions — set the order quantity on 98.3% of importer
  > purchase lines.
- **Source:** Static text from `docs/findings.md` F-01, F-03, F-04.
- **Interpretation note:** Do not make this text dynamic to the slicers. It is the network-level
  finding and would become false under a site filter.

---

**P1-V5 · Interpretation warning**

- **Type:** Persistent warning banner, bottom of page, muted background, not dismissible.
- **Content:**
  > **£468,897 is identified, not available.** It is what the analysis can argue against, counted
  > once across five mutually exclusive tiers. Three of the four active tiers are upper bounds.
  > **48.8% of the estate has no identified opportunity at all.** £252,435 — 53.8% of the
  > opportunity — sits at two sites with unresolved service anomalies, where no broad inventory
  > reduction is recommended. Capital released is one-off; holding cost saved is annual; they are
  > never added.
- **Source:** `docs/recommendations.md` preamble; D-29, D-36, D-39.

### Slicers on Page 1
**Site** and **Category** only. No supplier slicer (F1/F2 have no supplier relationship, so it
would silently do nothing). No product slicer (would blank the aggregate cards — see §2.9). No
time slicer (the period is fixed at 2025 by design, D-05).

---

## PAGE 2 — INVENTORY & WORKING CAPITAL

### Objective
Show where capital is tied up, and explain the mechanisms that put it there.

### Primary business questions
1. Which sites and categories hold the capital?
2. How concentrated is it?
3. What mechanism explains each pound, and how much is claimable under each?
4. Why can the exposures not simply be added?

### KPI cards

| # | Metric | Definition | Source | Type |
|---|---|---|---|---|
| K8 | **Closing inventory** £1,711,042 | Position at 2025-12-28 | F3 `position_stock_value_gbp` | Stock (level) |
| K9 | **Working capital identified** £468,897 | Five tiers, counted once | `[Selected Opportunity Value]` | **One-off**, partly upper bound |
| K10 | **Annual holding cost on that capital** £103,157 | At 22%; £93,779 / £117,225 at 20% / 25% | `[Selected Annual Holding Cost]` | **Annual**, assumption-based |
| K11 | **Stock with no identified opportunity** £835,219 (48.8%) | Tier 5 | `[Unclassified Stock Value]` | Stock (level) |
| K12 | **Discontinued exposure** £87,478 | Tier 1, 25 positions | `[Selected Opportunity Value]` filtered to tier 1 | **One-off**, definitional |

### Visuals

---

**P2-V1 · Inventory value by site**

- **Type:** Horizontal bar, sorted descending.
- **Business purpose:** Establish where the capital physically is. Daventry £996,883 average.
- **Source:** F1.
- **Fields:** Axis `Dim Warehouse[warehouse_name]`. Value `[Inventory Value]`.
- **Measures:** `[Inventory Value]`, `[Inventory Turns]`, `[Days Inventory Outstanding]`.
- **Filters/slicers:** Category applies.
- **Tooltip:** Average stock, closing stock, closing vs average %, turns, DIO, holding cost at 22%.
- **Interpretation note:** Tooltip must state that the bar is **average** inventory. Closing stock
  is 16.3% lower network-wide because importer receipts arrive in a sawtooth and the year ends in
  a trough (D-10).

---

**P2-V2 · Inventory value by category, with turns**

- **Type:** Clustered bar (value) with turns as a data label or secondary small-multiple.
- **Business purpose:** Renewables holds the most capital (£726,834) at healthy turns; Heating
  holds £321,202 at 2.73 turns and Tools £76,482 at 2.61 — the slowest.
- **Source:** F1.
- **Fields:** Axis `Dim Category[category_name]`. Value `[Inventory Value]`. Label
  `[Inventory Turns]`.
- **Filters/slicers:** Site applies.
- **Tooltip:** Average stock, cost of sales, turns, DIO, holding cost.
- **Interpretation note:** Low turns is not by itself a problem — it must be read against
  category demand pattern. Heating is seasonal (January peak, index 1.78).

---

**P2-V3 · Stock value concentration (ABC)**

- **Type:** Pareto — column of SKU stock value descending with a cumulative-share line.
- **Business purpose:** Ten SKUs (4% of range) hold 36.4% of stock value; the top 50 hold 74.9%.
  Concentration means a small number of decisions move the whole number.
- **Source:** **D1 `vw_sku_value_position`** — reporting views do not carry SKU-level rank or
  cumulative share.
- **Fields:** Axis `sku`. Column `average_stock_gbp`. Line `cumulative_stock_share_pct`.
- **Filters/slicers:** Category applies. Site does **not** — this view is SKU-level across the
  network and has no site column.
- **Tooltip:** SKU, product name, category, sites stocking, average stock, cost of sales, turns,
  `stock_value_class`, `cogs_class`.
- **Interpretation note:** Rank by stock value and rank by cost of sales **diverge**. 30 SKUs
  worth £116,623 rank high on stock and low on sales. Notably the reverse cell is empty — no SKU
  is under-stocked relative to high sales on this measure.

---

**P2-V4 · The opportunity hierarchy in detail**

- **Type:** Matrix — tiers as rows, expandable to site, then to SKU.
- **Business purpose:** The working table. Lets a stakeholder move from £468,897 to the individual
  position and see its service consequence.
- **Source:** F3.
- **Fields:** Rows `opportunity_mechanism` → `Dim Warehouse[warehouse_name]` → `sku`. Values:
  positions, stock value, releasable units, working capital, annual holding cost, holding cost at
  20% and 25%.
- **Measures:** `[Positions]`, `[Stock Value at Closing]`, `[Selected Opportunity Value]`,
  `[Selected Annual Holding Cost]`.
- **Filters/slicers:** Site, category, holding rate.
- **Drill-through:** SKU level → Page 5 with the SKU and site carried.
- **Tooltip:** `service_consequence`, `source_reference`, `unresolved_service_constraint`,
  `sourcing_last_used`, `minimum_in_weeks_of_demand`, `cover_weeks`, `demand_direction`.
- **Interpretation note:** **Three separate money columns and they measure different things** —
  stock held, capital claimable, annual cost. Column headers carry units. The `is_february_buy_
  ahead_position` flag should be surfaced as an icon with the tooltip "February buy-ahead residual
  already carved out of this figure (D-30, D-38)".

---

**P2-V5 · Why the exposures cannot be added**

- **Type:** Waterfall or paired bar — five Stage 4 exposures, a naive-sum bar, the hierarchy
  total, and closing stock for scale.
- **Business purpose:** The single most methodologically important visual in the dashboard. Shows
  the £1,109,016 error being avoided.
- **Source:** **Static reference values** from committed results — slow-moving £123,373
  (`analyse_03`), excess above policy £134,601… *see note*, high cover £398,821 (`analyse_05`),
  above calibrated rule £115,916 (`analyse_16`), minimum-order bound £336,205 (`analyse_17`).
  Excess above policy is **£134,701** (`analyse_04`). Naive sum £1,109,016. Hierarchy total
  £468,897. Closing stock £1,711,042.
- **Fields:** Entered as a small static table in Power Query (8 rows, 2 columns).
- **Filters/slicers:** **None.** These are fixed network-level figures and must not respond to a
  slicer.
- **Tooltip:** *"23 positions worth £70,857 are both slow-moving and above policy. 54.4% of
  high-cover positions are also minimum-order constrained; 85.4% are also policy-authorised."*
- **Interpretation note:** The naive-sum bar must be visually marked as **wrong** — hatched fill,
  strikethrough label, or an explicit "✗ do not use" annotation. It is the only place in the
  dashboard where £1,109,016 appears, and it appears in order to be rejected.

---

**P2-V6 · Slow-moving and discontinued exposure**

- **Type:** Small table, two rows plus context.
- **Business purpose:** Show that slow-moving stock is largely a **symptom**, not an independent
  problem. Of file 03's £123,373, only £14,373 across 8 positions survives as an unexplained
  residual once stronger mechanisms take precedence.
- **Source:** F3, cross-referenced against `analyse_03` committed result for the £123,373 total.
- **Fields:** Tier, positions, stock value, working capital.
- **Filters/slicers:** Site applies.
- **Tooltip:** Breakdown — £23,725 of the slow-moving stock is discontinued, £34,954 is
  minimum-order structural, £50,321 sits above the calibrated rule.
- **Interpretation note:** This is a finding about **classification**, not about the stock having
  shrunk. The £123,373 did not go away; it was explained.

### Slicers on Page 2
**Site**, **Category**, **Holding rate (20/22/25, default 22)**. The holding-rate slicer belongs
on this page specifically because it is where the holding-cost figures live. It must be labelled
"Holding cost rate — see D-11" with the methodology button adjacent.

---

## PAGE 3 — AVAILABILITY & REPLENISHMENT

### Objective
Explain why stockouts occur despite substantial network inventory, and separate what is supported
from what is unresolved and what was rejected.

### Primary business questions
1. How bad is availability, and which measure of it should be believed?
2. Does stock cover predict availability?
3. Are replenishment settings aligned with the demand each line actually has?
4. What has been ruled out?

### KPI cards

| # | Metric | Definition | Source | Type |
|---|---|---|---|---|
| K13 | **Weeks closing at zero** 3.52% | 943 ÷ 26,780 SKU-weeks | `[Closing Zero Rate %]` | Percentage, ISO-week basis |
| K14 | **Weeks with a zero-stock day** 5.05% | 1,353 ÷ 26,780 | `[Any Zero Day Rate %]` | Percentage, ISO-week basis |
| K15 | **Order lines not supplied in full** 7.71% | 1,272 ÷ 16,506 | `[Lines Short Rate %]` | Percentage, calendar-year basis |
| K16 | **Value of demand not met** £1,027,629 | Order-date basis, 2025 | `[Unmet Demand Value]` | **Upper bound** — substitution not modelled |
| K17 | **Unit fill rate** 92.64% | Units despatched as a share of 321,519 units demanded; 23,653 unmet | `[Unit Fill Rate %]` | Percentage |

**K13–K15 must be displayed as a set of three, never individually.** They measure different
things and disagree by a factor of two. K16 carries a permanent `▲ upper bound` tag.

### Visuals

---

**P3-V1 · Three availability measures, side by side**

- **Type:** Clustered column, three series, one group per site plus network.
- **Business purpose:** The snapshot measure understates the day measure by 1.26× at Livingston
  and 1.67× at Bristol; both understate what the customer experienced.
- **Source:** F2.
- **Fields:** Axis `Dim Warehouse[warehouse_name]`. Values `[Closing Zero Rate %]`,
  `[Any Zero Day Rate %]`, `[Lines Short Rate %]`.
- **Filters/slicers:** Category applies.
- **Tooltip:** All three rates, `snapshot_understatement_factor`, sku_weeks, demand_lines. Plus:
  *"Weekly snapshots miss stockouts that clear before Sunday. Order-line fill is what the customer
  experienced."*
- **Interpretation note:** **The three bars are not three estimates of one quantity.** Quoting the
  lowest without the others is a choice about which answer to give (AQ-06, charter trap 3). Axis
  label must read "three distinct measures".

---

**P3-V2 · Availability against stock cover**

- **Type:** Column chart — unmet unit rate by prior cover band.
- **Business purpose:** The strongest predictive relationship in the project. Under 2 weeks of
  cover → 46.70% unmet; over 6 months → 0.46%.
- **Source:** Committed result `analyse_06_unmet_demand_availability.txt` section 4, imported as a
  static 6-row reference table. *(The cover-band cross-tabulation is not exposed by a reporting
  view — see §10.)*
- **Fields:** Axis `prior_cover_band`. Value `unmet_unit_rate_pct`.
- **Filters/slicers:** **None** — static network-level reference.
- **Tooltip:** SKU-weeks, demand units, unmet units, unmet value per band.
- **Interpretation note:** Cover predicts availability strongly, but **the relationship is not
  linear and the tail matters**: 2,195 SKU-weeks sat on over six months of cover and still
  produced £10,519 of unmet demand.

---

**P3-V3 · Demand direction against replenishment alignment**

- **Type:** Matrix — demand direction (rising / broadly flat / falling) as rows, alignment band
  (set thin / in line / set deep) as columns, position counts as values, conditionally shaded.
- **Business purpose:** The core replenishment finding. Rising lines sit at a median alignment
  ratio of 0.68; falling lines at 1.33.
- **Source:** **D2 `vw_policy_alignment`**.
- **Fields:** Rows `demand_direction`. Columns `alignment_band`. Values count of positions,
  median `reorder_point_alignment_ratio`.
- **Filters/slicers:** Site, category.
- **Tooltip:** Positions, median ratio, mean cover weeks, mean policy age.
- **Interpretation note:** **The "broadly flat" row is the calibration set and is not evidence.**
  It centres on 1.00 by construction (D-31). Annotate the row explicitly. The finding lives in
  the rising and falling rows.

---

**P3-V4 · Outcome by alignment band**

- **Type:** Table with three rows.
- **Business purpose:** Alignment maps onto outcome monotonically; and the asymmetry — the service
  cost of thin settings is roughly twenty times the capital cost of deep ones.
- **Source:** D2.
- **Fields:** `alignment_band`, positions, mean cover weeks, `unmet_units_pct`,
  `unmet_value_2025_gbp`, `days_at_zero_pct`, stock value.
- **Filters/slicers:** Category applies; site applies.
- **Tooltip:** Mean policy age (present, and deliberately *not* explanatory).
- **Interpretation note:** **This is not a ranking and "set deep" is not the goal.** Deeper
  settings buy availability; that is what they are for. The finding is the asymmetry: £25,502 a
  year of holding cost on over-deep stock against **£505,019** of unmet demand on under-set lines.
  A caption must say so, or the table reads as "deeper is better".

---

**P3-V5 · Renewables growth against replenishment settings**

- **Type:** Line chart — Renewables demand units by quarter (8 points) with a line-fill-rate
  series, plus an annotation panel.
- **Business purpose:** Demand grew 85.5% from 2024Q1 to 2025Q4 (slope R² = 0.64) while cover ran
  at 7.4 weeks against 21.7 elsewhere. 2025Q4 line fill fell to 83.7% with £257,709 unmet.
- **Source:** Committed result `analyse_08_renewables_growth.txt` sections 2–4 as a static
  reference table, or F8 `vw_demand_line` filtered to `category_code = 'RENW'` for the quarterly
  series.
- **Fields:** Axis quarter. Values demand units, line fill %.
- **Filters/slicers:** **None** — this is a specific category finding.
- **Tooltip:** Quarter, demand lines, demand units, supplied units, unmet units, unmet value.
- **Interpretation note — mandatory, and it caps the confidence:** **Only 40 stocked positions
  exist and 31 are at Daventry.** This is a category finding resting on a single site, and that
  site carries its own unresolved service anomaly. The direction is clear; the breadth is not.
  Label the visual **"Partially supported"**.

---

**P3-V6 · Seasonal lag: shortage trails the demand peak**

- **Type:** Table, eight rows.
- **Business purpose:** In four of eight categories the peak shortage month trails the peak demand
  month by exactly two months. Heating peaks in January and runs short in **March** — not
  December, which was the original assumption and was wrong (D-20).
- **Source:** Committed result `analyse_07_seasonal_cover_adequacy.txt` section 2, as a static
  8-row reference table.
- **Fields:** Category, peak demand month, peak shortage month, months trailing, peak zero-days
  per SKU-week.
- **Filters/slicers:** None.
- **Interpretation note:** Two years gives one observation of each seasonal cycle. Consistency
  across four categories is what makes it a pattern; it is not a forecast.

---

**P3-V7 · Evidence status panel**

- **Type:** Three-column text panel — Supported / Unresolved / Rejected.
- **Business purpose:** The honesty panel. Keeps rejected hypotheses visible so they are not
  quietly reintroduced.
- **Content:**

| Supported | Unresolved | Rejected |
|---|---|---|
| Replenishment alignment and demand direction are **associated** with availability outcomes (F-04) | **Daventry** short-ships 2.60% of units in weeks when cover was adequate — 4–9× the other sites. Order lumpiness, customer mix, range mix and transfer activity were each tested and **none explains it** (D-24). **No cause is stated.** | **Stale policies cause poor availability** — rejected. Policies over 15 months old show a *lower* unmet rate: 6.03% vs 7.80% (D-21) |
| Cover predicts availability strongly across six bands (F-02) | **Bristol's** shortfall peaks in March–April 2025 and fits **neither** the opening-ramp nor the replenishment-lag explanation (D-25). **No cause is stated.** | **Review recency signals alignment** — rejected. Correlation −0.066, R² 0.0044; the oldest band is marginally the *best* aligned (D-32) |
| Three availability measures diverge and must travel together (F-02) | Both are **investigation priorities**, not failed analyses | **Policy age must not be used to target replenishment work** — it would select close to randomly |

- **Interpretation note:** Policy age appears on Page 3 **only** inside the Rejected column. It
  must not be a slicer, an axis, or a tooltip field on any other visual on this page.

### Slicers on Page 3
**Site** and **Category**. No policy-age slicer — offering one would imply age is an analytic
dimension worth exploring, which D-21 and D-32 reject. Several visuals (P3-V2, V5, V6, V7) are
static network-level findings and must be excluded from slicer interaction via **Edit
interactions → None**.

---

## PAGE 4 — SUPPLIER & SOURCING PERFORMANCE

### Objective
Show the trade-off between supplier reliability, lead time, price and inventory consequence —
without licensing either "importers are bad" or "cut importers".

### Primary business questions
1. Which suppliers deliver on time, on which measure?
2. Is any supplier deteriorating, and is it a category effect?
3. What do long lead times and large minimums do to inventory?
4. What does the cheaper source actually cost?

### KPI cards

| # | Metric | Definition | Source | Type |
|---|---|---|---|---|
| K18 | **On time, first receipt** 89.8% | Share of 3,766 measurable first receipts arriving by the promised date. Read as the pre-computed rate — the on-time **count** is not exposed by view 05 (§9.2), so no numerator is quoted | F4 / view 05 network row | Percentage |
| K19 | **On time, all receipts** 80.1% | Every delivery; a split counts twice | View 05 network row | Percentage |
| K20 | **OTIF, line complete** 79.1% | Full quantity by promised date | View 05 network row | Percentage |
| K21 | **Split delivery rate** 11.1% | 537 of 4,853 receipts | View 05 `split_delivery_rate_pct` | Percentage |
| K22 | **Minimum-order increment bought, 2025** £995,659 | Units bought beyond policy requirement | D3 `minimum_increment_units × unit_cost_gbp` | **Flow** — twelve months of purchasing |
| K23 | **Average incremental cycle stock** £497,830 | The flow expressed as a standing level | Derived, `analyse_17` section 4 | **Level** — derived from the flow |

**K18–K20 must be displayed together.** They differ by ten points and quoting one alone hides
every split delivery (D-07). **K22 and K23 must never be added** — one is twelve months of
purchasing, the other an instant (D-29).

### Visuals

---

**P4-V1 · On-time delivery, three measures by supplier**

- **Type:** Table, sorted ascending by OTIF, with data bars.
- **Business purpose:** Supplier-level reliability on all three measures with denominators
  visible.
- **Source:** F4 (view 05, `grain_level = '4 — supplier'`).
- **Fields:** `supplier_name`, `supplier_type`, `n_first_measurable`,
  `on_time_first_receipt_pct`, `n_all_measurable`, `on_time_all_receipts_pct`,
  `n_lines_measurable`, `otif_pct`, `split_delivery_rate_pct`, `cell_note`.
- **Filters/slicers:** Supplier type.
- **Tooltip:** Denominators, `n_not_measurable`, `n_outside_window`.
- **Interpretation note:** **Rows carrying `cell_note = 'thin cell'` must be visually muted and
  carry no interpretation.** The `n` columns are not decoration — a 62.5% on-time rate on 40
  receipts and one on 400 are different claims.

---

**P4-V2 · Supplier-type trend, with the leave-one-out series**

- **Type:** Line chart, four half-year points. **Two series per supplier type where relevant:**
  the type as measured, and — for Far East Importer only — the type **excluding Meridian**.
- **Business purpose:** The most important analytical guard on this page. Importers appear to
  decline 83.6% → 56.8%. Excluding Meridian they run 72.9% → 64.3% → 66.7% → **65.9%** — flat to
  improving.
- **Source:** F5 (view 05, `grain_level = '3 — supplier type by half-year'`) for the measured
  series; the leave-one-out series from committed result `analyse_12_supplier_reliability.txt`
  section 8 as a static 8-row reference table.
- **Fields:** Axis `order_half_year`. Values `on_time_first_receipt_pct` by `supplier_type`, plus
  the excluding-Meridian series as a dashed line.
- **Filters/slicers:** Supplier type (F5's own column).
- **Tooltip:** n per cell, all three on-time measures.
- **Interpretation note — mandatory:** **Do not present "Far East importers are getting worse".**
  The type-level decline is one supplier. The dashed leave-one-out line is not optional decoration
  — without it the visual states a rejected conclusion (D-26). Label the dashed series clearly:
  *"Importers excluding Meridian"*.

---

**P4-V3 · Meridian Pacific, specifically**

- **Type:** Line chart with annotation, four points.
- **Business purpose:** 95.0% → 93.9% → 79.4% → 45.5% on first receipt, every cell above the
  reporting floor (n = 100 / 82 / 68 / 33), ending 43.0 points below the network.
- **Source:** Committed result `analyse_12` section 7, as a static reference table.
- **Fields:** Axis half-year. Values Meridian on-time %, network on-time %.
- **Filters/slicers:** None.
- **Tooltip:** n, points above network, mean days over quoted (21.3 → 26.8).
- **Interpretation note:** The measurable window closes 2025-09-30 (D-14). 80.0% of importer lines
  ordered after that date had not arrived by the end of the data, so **45.5% is the last
  trustworthy reading, not the current state**. This caveat belongs in the visual subtitle, not
  only the tooltip.

---

**P4-V4 · Lead time distribution by supplier type**

- **Type:** Table or box-plot-style visual (a custom visual is acceptable; a table is sufficient).
- **Business purpose:** Importers quote 55 days and deliver in a median 78 — a 42% overrun — with
  a tail to 166 days.
- **Source:** F6 (view 06, `grain_level = '3 — supplier'`) for supplier detail; view 06
  `grain_level = '2 — supplier type'` for the type summary.
- **Fields:** `supplier_type`, `n_first_receipts`, `quoted_lead_time_days`, `median_cycle_days`,
  `p25`, `p75`, `iqr_days`, `p90_cycle_days`, `longest_cycle_days`, `stddev_days`,
  `median_overrun_vs_quoted_days`.
- **Filters/slicers:** Supplier type.
- **Tooltip:** Mean vs median, `mean_minus_median_days`, split rate.
- **Interpretation note:** **Percentiles must never be aggregated.** They are valid only at the
  row's own grain. If a slicer could re-aggregate them, disable the interaction. Mean and median
  are shown together because the distribution is skewed (KPI library requirement).

---

**P4-V5 · Receiving site effect — a process view, not a supplier view**

- **Type:** Small table, four rows, with an annotation.
- **Business purpose:** Livingston's raw lead-time overrun looks large; the fitted site effect is
  small.
- **Source:** View 06 `grain_level = '4 — receiving site'`; the fitted figure from committed
  result `analyse_13` as a static annotation.
- **Fields:** `warehouse_code`, `n_first_receipts`, `median_cycle_days`,
  `median_overrun_vs_quoted_days`.
- **Filters/slicers:** None.
- **Interpretation note — mandatory:** Naive marginals attribute **+10.1 days** to Livingston; the
  alternating two-way fit attributes **+1.8 days** (D-27). The raw column overstates by more than
  five times. **This is association, not causation** — the dataset cannot show the Monday
  goods-inwards batch *causes* the delay. The annotation must carry both numbers.

---

**P4-V6 · Minimum order quantities: how buying quantities are actually set**

- **Type:** Clustered column by supplier type — % of lines where the minimum binds, and % ordered
  at exactly the minimum.
- **Business purpose:** The structural mechanism. 98.3% of importer lines are placed where the
  minimum exceeds the policy reorder quantity and **99.3% are ordered at exactly the minimum** —
  the order quantity has stopped being a replenishment decision.
- **Source:** **D3 `vw_purchase_quantity_structure`**.
- **Fields:** Axis `supplier_type`. Values % where `minimum_exceeds_policy_quantity`, %
  `ordered_exactly_at_minimum`.
- **Measures:** `[Minimum Binds %]`, `[Ordered At Minimum %]`.
- **Filters/slicers:** Site, category.
- **Tooltip:** Purchase lines, mean minimum, mean policy reorder quantity, mean quoted lead days,
  minimum increment value.
- **Interpretation note:** This is a **flow** measure over twelve months of purchasing. It must
  not be compared with, or added to, the standing-stock figures on Page 2. The pipeline premium
  from long lead times (£276,224 across 134 dual-source positions) belongs in the tooltip as
  separate context.

---

**P4-V7 · The dual-source trade-off**

- **Type:** Scatter — price premium on the dearer source (x) against minimum-order ratio (y),
  one point per SKU, sized by volume.
- **Business purpose:** Across 60 SKUs bought from two sources, the cheaper source is a Far East
  importer in **every single case**, at a median premium around 30%, with minimums 8.8–10.7×
  larger and lead times 43–47 days longer.
- **Source:** **D4 `vw_dual_source_gap`**.
- **Fields:** X `dear_premium_pct`. Y ratio of `cheap_moq` to `dear_moq`. Size `cheap_units`.
  Legend `category_code`.
- **Filters/slicers:** Category.
- **Tooltip:** SKU, both suppliers and types, both unit costs, both minimums, both lead times,
  `gross_gap_on_dear_volume_gbp`.
- **Interpretation note — mandatory:** Annualised, the price saving from using the cheaper source
  is **£492,020** against **£604,231** of one-off working capital — net **+£359,089** at 22%.
  **Re-sourcing away from importers to release capital would forfeit more than it releases.**
  The visual must carry that sentence. Do not present importer reduction as a recommendation.

---

**P4-V8 · The February 2025 Arden buy-ahead — a completed decision**

- **Type:** Small three-row summary card or table.
- **Business purpose:** Prevent the buy-ahead being reintroduced as a cause of excess inventory.
- **Content:** Price saving captured **£146,490** · Residual still held at 2025-12-28 **£6,971
  (upper bound)** · **Net +£145,148** at 22%.
- **Source:** Committed result `analyse_15_buy_ahead_trade.txt` section 6.
- **Filters/slicers:** None.
- **Interpretation note — mandatory:** **This was economically successful and must not be
  classified as excess inventory** (D-30). Its residual bound is already carved out of every tier
  of the Page 2 opportunity hierarchy (D-38), so it cannot be double-counted. Like-for-like the
  Arden price rise reproduces at a median **+18.2%** across 57 SKUs; the raw before/after
  comparison is invalid because the SKU mix changed (D-28).

### Slicers on Page 4
**Supplier type** and **Category**. A **Supplier** slicer is optional and, if included, must be
bound to `Dim Supplier` and will not filter F5, D3 or D4. No site slicer as a primary control —
site appears here only in P4-V5, which is deliberately a process view and should not be
cross-filtered from a supplier context.

---

## PAGE 5 — SITE INVESTIGATIONS & DECISION WATCHLIST

### Objective
Let leadership compare sites and reach the two unresolved investigations without either being
softened into a conclusion.

### Primary business questions
1. How do the four sites compare on capital, throughput and service?
2. Where is the opportunity by site, and where is it constrained?
3. What must be investigated before acting?

### KPI cards
Context cards responding to the site slicer, showing for the selected site: average inventory,
turns, DIO, line fill %, unmet value (upper bound), working capital identified, annual holding
cost. All seven carry the same type tags as their Page 1 and 2 equivalents.

An eighth card, **`[Unresolved Constraint Text]`**, displays the selected site's
`unresolved_service_constraint` verbatim from F3 — blank for Warrington and Livingston, populated
for Daventry and Bristol.

### Visuals

---

**P5-V1 · Site scorecard**

- **Type:** Matrix, four site rows.
- **Business purpose:** The like-for-like comparison, with the caveat that a raw turnover ranking
  is not valid.
- **Source:** F1, F2, F3.
- **Fields:** Site; average inventory; closing inventory; turns; DIO; closing-zero %; any-zero-day
  %; line fill %; unmet value; mean cover weeks; working capital identified; annual holding cost.
- **Filters/slicers:** Category applies.
- **Tooltip:** Skus stocked, weeks measured, holding cost at 20% and 25%.
- **Interpretation note — mandatory:** **Do not rank sites on raw turnover.** 145 of 250 SKUs are
  stocked only at Daventry. On the range all four sites carry, Daventry turns **6.82**, not 4.68 —
  second only to Bristol. Two valid range-mix corrections **disagree** (common-basket moves Bristol
  +0.33, mix-standardisation +1.43) and the disagreement is itself the finding (D-23). Livingston's
  2.84 is the figure that survives every correction.

---

**P5-V2 · Working capital opportunity by site and mechanism**

- **Type:** Stacked column — one column per site, segmented by tier.
- **Business purpose:** Show that Bristol's 59.1% releasable share is the highest in the network
  while it is also the worst-serving site at 89.23% line fill.
- **Source:** F3.
- **Fields:** Axis `Dim Warehouse[warehouse_name]`. Legend `opportunity_mechanism`. Value
  `[Selected Opportunity Value]`.
- **Filters/slicers:** Category.
- **Tooltip:** Positions, stock value, capital, annual holding cost, releasable share of position
  %, and the site's unresolved constraint where present.
- **Interpretation note:** Columns for Daventry and Bristol must carry a visible constraint marker
  (an icon or hatched border) linking to P5-V4. **£252,435 — 53.8% of the total — sits at the two
  constrained sites.**

---

**P5-V3 · Position-level watchlist**

- **Type:** Table, drill-through target.
- **Business purpose:** The working list. Every position with a non-zero opportunity, with
  everything needed to judge it.
- **Source:** F3, filtered to `working_capital_gbp > 0`.
- **Fields:** `opportunity_mechanism`, `sku`, `product_name`, site, category,
  `sourcing_last_used`, `minimum_in_weeks_of_demand`, `quantity_on_hand`,
  `position_stock_value_gbp`, `releasable_units`, `working_capital_gbp`,
  `annual_holding_cost_gbp`, `cover_weeks`, `demand_direction`,
  `reorder_point_alignment_ratio`, `source_reference`.
- **Filters/slicers:** Site, category, mechanism, holding rate.
- **Drill-through:** This page is the drill-through target from P1-V1, P2-V4 and P5-V2.
- **Tooltip:** `service_consequence` and `unresolved_service_constraint` in full.
- **Interpretation note:** Sort by `working_capital_gbp` descending by default. **The
  `service_consequence` column must not be hidden** — it is the reason each row is not free money.

---

**P5-V4 · Unresolved Constraints / Further Investigation**

- **Type:** Two-panel text section with a distinct border. **This is a first-class section, not a
  footnote.**
- **Business purpose:** Preserve two unresolved findings as investigation priorities without
  assigning a cause to either.

**DAVENTRY — service anomaly, unresolved**

> Daventry fails to supply **2.60% of units in weeks when inventory cover was adequate** — four to
> nine times the other sites (Livingston 1.20%, Bristol 0.54%, Warrington 0.30%). 33 short weeks,
> **£68,451** of unmet demand from positions that were not short of stock.
>
> The anomaly survives:
> - range-mix correction
> - common-basket comparison
> - stock-depth controls
> - customer-mix testing
> - transfer-activity testing
> - order-lumpiness testing — demand in Daventry's short weeks runs 5.45× normal, but Livingston's
>   runs 4.73× with a fifth of the shortfall rate
>
> **No cause is stated.** Investigation belongs outside this dataset: goods-out picking accuracy,
> allocation logic when orders compete for the same stock, stock accuracy between system and bin,
> and cut-off timing.
>
> **Constrains:** £128,749 of identified opportunity sits at Daventry. *(D-24, D-39)*

**BRISTOL — March–April shortfall, unresolved**

> Bristol's unmet demand peaks in March and April 2025.
>
> The pattern fits:
> - **not** a simple opening-ramp explanation — the site opened 1 July 2024 and its worst months
>   are eight months later, not its first
> - **not** the general replenishment-lag pattern cleanly — its peak does not sit two months after
>   a Bristol demand peak
> - **no** supported supplier-delay explanation — Bristol's Monday-booking share is the lowest in
>   the network at 14.3%
>
> **No cause is stated.**
>
> **Constrains:** £123,686 of identified opportunity sits at Bristol, which shows **59.1% of its
> closing stock as releasable — the highest share in the network — while serving worst at 89.23%
> line fill.** *(D-25, D-39)*

**Shared conclusion panel:**

> **No broad inventory reduction is recommended at either site until the service behaviour is
> understood.** Acting on the apparent overstock without explaining the service failure risks
> converting a capital gain into a service loss at the sites least able to absorb one. Clearing
> discontinued stock is safe at both, because there the demand claim is definitional.
>
> **These are investigation priorities, not failed analyses.**

- **Interpretation note:** No visual on this page may display a computed "cause", "driver" or
  "root cause" field for either site. No such field exists in any view, and none may be
  constructed in DAX.

### Slicers on Page 5
**Site**, **Category**, **Opportunity mechanism**, **Holding rate**. P5-V4 must be excluded from
all slicer interaction — the unresolved text is fixed and must never appear to change under a
filter.

---

## 4. Required DAX Measures

**Rule applied throughout:** a measure is defined here **only** where the metric cannot be read
directly from a view at the grain the visual needs. Every rate that a reporting view already
computes is used as a column wherever the visual sits at that view's own grain; a DAX measure
exists only where the visual aggregates across rows and the pre-computed rate would therefore be
wrong.

### Group A — Ratios that cannot be summed (5)

---

**M1 · `Inventory Value`**
- **Purpose:** Additive average-inventory base for every visual.
- **DAX:** `SUM ( 'Fact Inventory KPI'[average_stock_gbp] )`
- **Source:** F1.
- **Format:** `£#,##0` (whole pounds on visuals; `£#,##0.00` in tooltips).
- **Caveat:** This is the **mean of 52 weekly snapshots**, never closing stock (D-10). Do not
  substitute `closing_stock_gbp` — turnover would report 5.58 instead of 4.67.

---

**M2 · `Inventory Turns`**
- **Purpose:** Turnover for any filter context. Required because a ratio cannot be summed across
  site × category cells.
- **DAX:**
  ```
  Inventory Turns =
  DIVIDE (
      SUM ( 'Fact Inventory KPI'[cost_of_sales_gbp] ),
      SUM ( 'Fact Inventory KPI'[average_stock_gbp] )
  )
  ```
- **Source:** F1. **Reproduces `vw_kpi_inventory_value_and_turnover[inventory_turns]` exactly at
  matching grain** — verified network 4.67.
- **Format:** `0.00` + suffix "×".
- **Caveat:** Cost of sales is at **ledger weighted average cost**, transfers excluded (D-09,
  D-10).

---

**M3 · `Days Inventory Outstanding`**
- **Purpose:** DIO for any filter context.
- **DAX:** `DIVIDE ( 365, [Inventory Turns] )`
- **Source:** Derived from M2. Reproduces `vw_kpi_days_inventory_outstanding` (network 78.2).
- **Format:** `0.0` + " days".
- **Caveat:** The KPI library defines DIO on a **365-day** year; the period spans 364 days. The
  difference is 0.27% and the library definition is kept without deviation (D-37).

---

**M4 · `Lines Short Rate %`**
- **Purpose:** The headline service measure, aggregable across sites and categories.
- **DAX:**
  ```
  Lines Short Rate % =
  DIVIDE (
      SUM ( 'Fact Availability'[lines_not_supplied_in_full] ),
      SUM ( 'Fact Availability'[demand_lines] )
  )
  ```
- **Source:** F2. Reproduces 7.71% network.
- **Format:** `0.00%`.
- **Caveat:** **Calendar-year order-date basis**, not ISO-week (D-22). Do not display beside a
  snapshot-basis measure without stating both bases.

---

**M5 · `Unit Fill Rate %`**
- **Purpose:** Unit-level fill, aggregable.
- **DAX:**
  ```
  Unit Fill Rate % =
  DIVIDE (
      SUM ( 'Fact Availability'[demand_units] ) - SUM ( 'Fact Availability'[unmet_units] ),
      SUM ( 'Fact Availability'[demand_units] )
  )
  ```
- **Source:** F2. Network 92.64%.
- **Format:** `0.00%`.
- **Caveat:** Differs from line fill because a partially-supplied line counts as a failure on the
  line measure and a partial success on the unit measure.

### Group B — Availability rates on the ISO-week clock (2)

---

**M6 · `Closing Zero Rate %`**
- **DAX:**
  ```
  Closing Zero Rate % =
  DIVIDE (
      SUM ( 'Fact Availability'[weeks_closing_at_zero] ),
      SUM ( 'Fact Availability'[sku_weeks] )
  )
  ```
- **Source:** F2. Network 3.52% (943 ÷ 26,780).
- **Format:** `0.00%`.
- **Caveat:** **ISO-week clock.** Understates the day-level measure by 1.26–1.67× depending on
  site. Never display without M7.

---

**M7 · `Any Zero Day Rate %`**
- **DAX:**
  ```
  Any Zero Day Rate % =
  DIVIDE (
      SUM ( 'Fact Availability'[weeks_with_a_zero_day] ),
      SUM ( 'Fact Availability'[sku_weeks] )
  )
  ```
- **Source:** F2. Network 5.05% (1,353 ÷ 26,780).
- **Format:** `0.00%`.
- **Caveat:** ISO-week clock. Still understates what the customer experienced (M4).

### Group C — Opportunity measures (5)

---

**M8 · `Selected Opportunity Value`**
- **Purpose:** Working capital under the current filter. Additive by construction — F3 is mutually
  exclusive and exhaustive.
- **DAX:** `SUM ( 'Fact Opportunity'[working_capital_gbp] )`
- **Source:** F3. Network £468,897.07.
- **Format:** `£#,##0`.
- **Caveat — the most important in this document:** **One-off capital.** Tiers 2 and 4 are **upper
  bounds**, tier 1 is definitional, tier 3 is measured. **Never add to M9.**

---

**M9 · `Selected Annual Holding Cost`**
- **Purpose:** Annual holding cost on the selected opportunity, responding to the rate slicer.
- **DAX:**
  ```
  Selected Annual Holding Cost =
  VAR SelectedRate = SELECTEDVALUE ( 'Holding Rate'[Rate], 0.22 )
  RETURN
      SWITCH (
          TRUE (),
          SelectedRate = 0.20, SUM ( 'Fact Opportunity'[holding_cost_at_20pct_gbp] ),
          SelectedRate = 0.25, SUM ( 'Fact Opportunity'[holding_cost_at_25pct_gbp] ),
          SUM ( 'Fact Opportunity'[annual_holding_cost_gbp] )
      )
  ```
- **Source:** F3. At 22%: £103,157.38. At 20%: £93,779.41. At 25%: £117,224.65.
- **Format:** `£#,##0` + " p.a.".
- **Caveat:** Reads the **pre-computed** column for each rate rather than multiplying, so the
  dashboard cannot drift from the committed results. Defaults to 22% when nothing is selected.
  Three of the four components of the rate are assumptions (D-11).

---

**M10 · `Stock Value at Closing`**
- **DAX:** `SUM ( 'Fact Opportunity'[position_stock_value_gbp] )`
- **Source:** F3. Network £1,711,041.86.
- **Format:** `£#,##0`.
- **Caveat:** Single instant at 2025-12-28. **Not** comparable with M1 (average inventory) — the
  closing position is 16.3% lower network-wide.

---

**M11 · `Opportunity Share of Stock %`**
- **DAX:** `DIVIDE ( [Selected Opportunity Value], [Stock Value at Closing] )`
- **Source:** F3. Network 27.4%; Bristol 59.1%.
- **Format:** `0.0%`.
- **Caveat:** A high share is **not** a performance measure. Bristol's 59.1% sits on the
  worst-serving site and is constrained by an unresolved anomaly.

---

**M12 · `Unclassified Stock Value`**
- **Purpose:** The anti-"cut everywhere" number.
- **DAX:**
  ```
  Unclassified Stock Value =
  CALCULATE (
      [Stock Value at Closing],
      'Fact Opportunity'[opportunity_mechanism] = "5 — no identified release opportunity"
  )
  ```
- **Source:** F3. £835,218.54 — 48.8% of closing stock.
- **Format:** `£#,##0`.
- **Caveat:** Not "safe" stock and not "correct" stock. It is stock the analysis has **no case
  against**.

### Group D — Purchase structure (2)

---

**M13 · `Minimum Binds %`**
- **DAX:**
  ```
  Minimum Binds % =
  DIVIDE (
      CALCULATE ( COUNTROWS ( 'Detail Purchase Structure' ),
                  'Detail Purchase Structure'[minimum_exceeds_policy_quantity] = TRUE () ),
      COUNTROWS ( 'Detail Purchase Structure' )
  )
  ```
- **Source:** D3. Far East Importer 98.3%.
- **Format:** `0.0%`.
- **Caveat:** 2025 purchase lines only — a **flow**, not a stock position.

---

**M14 · `Ordered At Minimum %`**
- **DAX:** as M13 with `[ordered_exactly_at_minimum] = TRUE ()`.
- **Source:** D3. Far East Importer 99.3%.
- **Format:** `0.0%`.
- **Caveat:** The headline structural evidence — the order quantity is a term of trade, not a
  replenishment decision.

### Group E — Narrative measures (2)

---

**M15 · `Unresolved Constraint Text`**
- **Purpose:** Surface the selected site's constraint verbatim; blank where none exists.
- **DAX:**
  ```
  Unresolved Constraint Text =
  VAR Constraints =
      CALCULATETABLE (
          VALUES ( 'Fact Opportunity'[unresolved_service_constraint] ),
          'Fact Opportunity'[unresolved_service_constraint] <> ""
      )
  RETURN
      IF ( COUNTROWS ( Constraints ) = 1, CONCATENATEX ( Constraints, [unresolved_service_constraint] ), BLANK () )
  ```
- **Source:** F3 `unresolved_service_constraint`.
- **Format:** Text.
- **Caveat:** Returns text **written in the SQL view**, not composed in DAX. Do not paraphrase it
  in the visual — the wording deliberately assigns no cause.

---

**M16 · `Dynamic Insight Title`**
- **Purpose:** A context-aware subtitle for Page 5 so the reader knows what is filtered.
- **DAX:**
  ```
  Dynamic Insight Title =
  VAR SiteName = SELECTEDVALUE ( 'Dim Warehouse'[warehouse_name], "All four warehouses" )
  VAR Capital  = FORMAT ( [Selected Opportunity Value], "£#,##0" )
  VAR Share    = FORMAT ( [Opportunity Share of Stock %], "0.0%" )
  VAR Flag     = IF ( NOT ISBLANK ( [Unresolved Constraint Text] ),
                      "  ▲ Unresolved service constraint — see watchlist", "" )
  RETURN SiteName & ": " & Capital & " identified (" & Share & " of closing stock)" & Flag
  ```
- **Source:** F3, `Dim Warehouse`.
- **Format:** Text.
- **Caveat:** Must say **"identified"**, never "available", "releasable now" or "saving". The
  constraint flag is not optional.

**Total: 16 measures.** Everything else the dashboard needs is read directly from a view column.

---

## 5. Visual Design System

### 5.1 Page setup
- **Canvas:** 1600 × 900 (16:9), *Custom* page size, **Fit to page** view.
- **Grid:** 12-column layout, 16 px gutter, 24 px page margin. Snap to grid on.
- **Vertical rhythm:** header band 72 px · KPI strip 120 px · content 620 px · footer 48 px.

### 5.2 KPI card behaviour — consistent across all six pages
Every card carries four elements in the same position:

1. **Label** (11 pt, sentence case) — e.g. "Average inventory"
2. **Value** (28 pt, semibold) — e.g. "£2,043,979"
3. **Basis tag** (9 pt, muted) — one of: `average of 52 weeks` · `at 2025-12-28` · `one-off` ·
   `per annum · 22% assumed` · `ISO-week basis` · `calendar-year basis`
4. **Qualifier badge** where applicable — `▲ upper bound`

**The basis tag is mandatory on every card.** It is the mechanism that stops a reader adding a
one-off to an annual figure, and it costs one line.

### 5.3 Typography
- **Family:** Segoe UI throughout (Power BI native; no font dependency for a reviewer).
- **Scale:** page title 20 pt semibold · visual title 14 pt semibold · KPI value 28 pt semibold ·
  KPI label 11 pt · body and table 10 pt · caveat and basis tag 9 pt italic.
- **Case:** Sentence case everywhere. No all-caps except the two site names in the watchlist
  headings.

### 5.4 Number formatting
| Quantity | Format | Example |
|---|---|---|
| Currency, visual labels | `£#,##0` | £468,897 |
| Currency, tooltips and tables | `£#,##0.00` | £468,897.07 |
| Currency, axis only | `£#,##0,K` | £469K |
| Percentage, rates | `0.00%` | 7.71% |
| Percentage, shares | `0.0%` | 48.8% |
| Turns | `0.00` + "×" | 4.67× |
| Days | `0.0` + " days" | 78.2 days |
| Counts | `#,##0` | 16,506 |
| Alignment ratio | `0.00` | 0.68 |

**No abbreviation below axis level.** A KPI card reading "£469K" invites a reader to lose the
precision the project spent forty decisions protecting.

### 5.5 Colour — used for meaning, never decoration

Four semantic roles only. Exact hues are a build-time choice; the **roles** are the specification.

| Role | Applied to | Requirement |
|---|---|---|
| **Opportunity** | Tiers 1–4, releasable capital | One accent hue, four tints — tier 1 darkest (most certain) to tier 4 lightest (weakest evidence). The tint ramp **encodes confidence**, which is the point. |
| **Neutral / no case** | Tier 5, unclassified stock, context | Grey. Must be visually **quiet but large** — it is 48.8% of the estate. |
| **Risk / service failure** | Unmet demand, stockout rates, thin alignment | A single warm hue, used **only** for service exposure |
| **Unresolved investigation** | Daventry and Bristol constraint markers, watchlist borders | One distinct hue used **nowhere else**, so the marker is unambiguous |

**Category colours** (site, product category, supplier type) come from a neutral qualitative
palette and must **not** reuse any of the four semantic hues.

**Never encode good/bad on inventory value.** Colouring high inventory red is exactly the
simplistic reading the dashboard exists to prevent.

### 5.6 Accessibility
- Contrast ≥ 4.5:1 for all text; ≥ 3:1 for chart marks against background.
- **Never colour alone.** Tiers carry a number prefix (`1 —`, `2 —`…) already present in the data.
  The unresolved marker pairs its hue with a `▲` glyph. The rejected naive-sum bar uses a hatched
  fill plus a `✗` label.
- Alt text on every visual, stating what it shows and its main caveat.
- Tab order set explicitly: KPI strip → main visual → supporting visuals → warning banner.
- Colour-vision check: the opportunity ramp and the risk hue must remain distinguishable under
  deuteranopia simulation — verify with Power BI's built-in view or an external simulator.

### 5.7 Restraint
No gradients, shadows, 3-D effects, gauge visuals, donut charts or background images. No
decorative icons. No logo. Every pixel that is not data, label or caveat should be removed.

**One deliberate exception:** the warning banners and the watchlist panel carry a light tinted
background. They are the elements most likely to be skipped, and the tint is functional.

---

## 6. Storytelling and UX

### 6.1 Page navigation order
Left-to-right tabs in narrative order: **Executive Overview → Inventory & Working Capital →
Availability & Replenishment → Supplier Reliability & Lead Time → Sourcing Economics →
Site Investigations**.

The order follows the argument: *here is the paradox* → *here is where the capital is* → *here is
why service fails anyway* → *here is what upstream causes it* → *here is what to do and what we
still do not know*.

### 6.2 The recruiter's 60 seconds
Page 1 alone must carry it:

- **0–10 s** — KPI strip. £2.0m inventory, 4.67 turns, 7.71% lines short. The tension is visible
  before anything is read.
- **10–25 s** — P1-V1. Inventory and service failure by site, plainly not moving together.
- **25–40 s** — P1-V4 callout. "This is an allocation and replenishment-design problem."
- **40–55 s** — P1-V3 hierarchy. £468,897 across five tiers, with tier 5 at £835,219 showing the
  analyst knew when to stop.
- **55–60 s** — P1-V5 warning banner. Upper bounds, one-off vs annual, two constrained sites.

**What the recruiter should take away:** this analyst quantified an opportunity, then spent equal
effort explaining why it is smaller and more conditional than it looks. That is the signal.

### 6.3 The Operations Director's path
1. **Page 1** — confirms the position and the size of the prize.
2. **Page 2** — "where is it?" Filters to a site, reads the hierarchy, sees three money columns
   that mean different things.
3. **Page 3** — "why are we still short?" Finds alignment, not policy age, is the mechanism.
4. **Page 4** — "is it our suppliers?" Finds one supplier, not a category, and a price/capital
   trade-off that caps the obvious action.
5. **Page 5** — drills to positions, and hits the watchlist. **The journey deliberately ends at
   what is not known.**

### 6.4 Where tooltips carry methodology
Report-page tooltips (not default) on: P1-V1 (two clocks), P2-V1 (average vs closing), P2-V4
(upper bounds and service consequence), P3-V1 (three measures), P4-V1 (thin cells), P4-V4
(percentiles not aggregable), P5-V1 (range-mix correction).

Each carries a one-line methodology note and its decision reference. A reader hovering a number
should be one second from knowing what it does not mean.

### 6.5 Where drill-through is used
| From | To | Carries |
|---|---|---|
| P1-V1 site column | Page 5 | Site |
| P1-V2 tier segment | Page 2 | Mechanism |
| P2-V4 SKU row | Page 5 (P5-V3) | SKU + site |
| P5-V2 site column | P5-V3 | Site + mechanism |

All drill-through pages keep their filter card visible so the reader always knows the context.

### 6.6 What belongs as a callout, not a chart
The central finding (P1-V4), the interpretation warning (P1-V5), the evidence-status panel
(P3-V7), the buy-ahead summary (P4-V8) and the unresolved watchlist (P5-V4). These are arguments,
not measurements. Charting them would weaken them.

### 6.7 What stays in the documentation and off the dashboard
| Stays in docs | Why |
|---|---|
| The full 40-decision log | Reference material; the dashboard cites decision IDs and links out |
| The alternating two-way lead-time fit | Method detail; only its **result** (+1.8 days) appears |
| Two disagreeing range-mix corrections | Both numbers would confuse an executive; the *warning not to rank on raw turnover* appears instead |
| The £2,591 two-clock reconciliation | Appears in a tooltip, not a visual |
| Arden like-for-like price method (Simpson's paradox) | Result (+18.2%) appears; the method does not |
| Six rejected hypotheses in full | Three most consequential appear on P3-V7; the rest stay in `findings.md` |
| Reproducibility and byte-identical rebuild evidence | Belongs in `README.md` |

---

## 7. Power BI Validation Checklist

Run in order. Every item is pass/fail; there are no partial passes.

### 7.1 KPI reconciliation
Each dashboard figure must equal its committed result exactly.

| KPI | Expected | Committed source |
|---|---:|---|
| Average inventory | £2,043,979.36 | `report_01` |
| Closing inventory | £1,711,041.86 | `report_01`, `report_07` |
| Cost of sales | £9,550,572.04 | `report_01` |
| Inventory turns | 4.67 | `report_01` |
| DIO | 78.2 | `report_02` |
| Holding cost at 22% | £449,675.46 | `report_03` |
| Weeks closing at zero | 3.52% (943 / 26,780) | `report_04` |
| Weeks with a zero day | 5.05% (1,353 / 26,780) | `report_04` |
| Lines not supplied in full | 7.71% (1,272 / 16,506) | `report_04` |
| Unmet demand | £1,027,628.75 | `report_04` |
| On time, first receipt | 89.8% (n 3,766) | `report_05` |
| On time, all receipts | 80.1% (n 4,241) | `report_05` |
| OTIF | 79.1% (n 3,768) | `report_05` |
| Importer median cycle | 78 days (n 603) | `report_06` |
| Opportunity total | £468,897.07 | `report_07` |
| Annual holding cost on it | £103,157.38 | `report_07` |
| Tier 5 unclassified | £835,218.54 | `report_07` |

☐ All 17 reconcile to the penny where the source carries pence, and to the stated rounding
otherwise.

### 7.2 Grain validation
☐ Every `grain_level` view is filtered to exactly one grain in Power Query.
☐ `[Inventory Value]` with no filters returns **£2,043,979**, not a multiple of it. A result near
£8.2m means an unfiltered `grain_level` import.
☐ `[Stock Value at Closing]` with no filters returns **£1,711,042**.
☐ Site totals sum to network within £0.05; category totals likewise.
☐ Adding a category slicer to a site visual does not change the network total.
☐ `Dim Product` is confirmed **not** to filter F1 or F2, and no product slicer is placed on Pages
1–2.

### 7.3 Opportunity hierarchy
☐ F3 returns exactly **515** rows.
☐ Distinct `(sku, warehouse_code)` = 515 — no position appears twice.
☐ Sum of `position_stock_value_gbp` = **£1,711,041.86**.
☐ The five tiers are the only values of `opportunity_mechanism`.
☐ Tier 5 `working_capital_gbp` sums to exactly **0**.
☐ No row has `working_capital_gbp > position_stock_value_gbp`.
☐ Tier capital sums: 87,478 + 303,558 + 70,755 + 7,106 = **468,897**.
☐ **£1,109,016 appears in exactly one place** — P2-V5 — and is visually marked as the error.

### 7.4 Time handling
☐ Availability visuals label ISO-week measures and calendar-year measures distinctly.
☐ The **£2,591** difference between the two unmet-demand bases is stated in the P3 methodology
tooltip and **not** silently reconciled.
☐ No visual mixes an ISO-week rate and a calendar-year rate on a single axis without both bases
labelled.
☐ No date slicer offers a period other than 2025 for KPI visuals — the anchor is fixed (D-05).

### 7.5 Upper bounds
☐ K6, K9, K16 and the tier 2 / tier 4 rows carry a visible `▲ upper bound` marker.
☐ No card, title or tooltip describes an upper bound as a "saving", "benefit realised",
"available" or "releasable now".
☐ Tier 1 is marked *definitional*, tier 3 *measured* — they are **not** upper bounds and must not
be mislabelled either way.
☐ The £6,971 buy-ahead residual is labelled an upper bound wherever it appears.

### 7.6 Unresolved findings
☐ No dashboard text assigns a cause to Daventry's anomaly.
☐ No dashboard text assigns a cause to Bristol's March–April shortfall.
☐ No calculated column or measure named "cause", "driver", "reason" or "root cause" exists for
either site.
☐ P5-V4 wording matches `docs/findings.md` F-U1 and F-U2 and is not paraphrased.
☐ The constraint marker appears on Daventry and Bristol on **every** page where their opportunity
is shown — Pages 1, 2 and 5.
☐ Both are presented as **investigation priorities**, not failed analyses.

### 7.7 Holding cost
☐ The 22% rate is the default everywhere.
☐ The methodology overlay states the four components — 6% capital, 8% storage, 3% service, 5% risk
— and that **only the capital component has an authoritative primary source** (D-11).
☐ The 20% and 25% sensitivity is reachable within one interaction from any holding-cost figure.
☐ M9 reads pre-computed columns, never `value × rate`, so it cannot drift from committed results.
☐ The overlay states that the 5% risk component comes from the published benchmark, **not** from
this dataset's 7.9% observed loss (D-12).

### 7.8 One-off versus annual
☐ `[Selected Opportunity Value]` and `[Selected Annual Holding Cost]` never appear in the same
visual on the same axis.
☐ No measure, calculated column or table sums the two.
☐ Every card carries its basis tag — `one-off` or `per annum`.
☐ K6/K7 and K9/K10 sit inside a captioned group stating they are never added.
☐ P4-V6's flow figure (£995,659) and P2's stock figures never share a visual.

### 7.9 Rejected hypotheses
☐ Policy age is not a slicer, axis or legend anywhere.
☐ The only appearance of policy age is P3-V7's Rejected column and the P2-V4 tooltip, where it is
descriptive.
☐ P4-V2 shows the leave-one-out series; no visual states "importers are getting worse".
☐ The February buy-ahead is presented as net positive and never as a cause of excess.
☐ No visual ranks sites on raw turnover without the range-mix warning.

---

## 8. Existing views used

| View | Type | Used on |
|---|---|---|
| `vw_kpi_inventory_value_and_turnover` | Reporting 01 | Pages 1, 2, 5 |
| `vw_kpi_days_inventory_outstanding` | Reporting 02 | Pages 1, 5 |
| `vw_kpi_stock_holding_cost` | Reporting 03 | Pages 1, 2, 5 |
| `vw_kpi_availability_and_fill_rate` | Reporting 04 | Pages 1, 3, 5 |
| `vw_kpi_supplier_on_time_delivery` | Reporting 05 | Page 4 |
| `vw_kpi_order_cycle_time` | Reporting 06 | Page 4 |
| `vw_working_capital_release_opportunity` | Reporting 07 | Pages 1, 2, 5 |
| `mv_inventory_week` | Preparation 04 | Optional weekly detail |
| `vw_demand_line` | Preparation 02 | Page 3 (Renewables quarterly series) |
| `vw_sku_value_position` | Analysis 02 | Page 2 (ABC) |
| `vw_policy_alignment` | Analysis 16 | Page 3 (alignment) |
| `vw_purchase_quantity_structure` | Analysis 17 | Page 4 (minimums) |
| `vw_dual_source_gap` | Analysis 14 | Page 4 (sourcing trade-off) |
| `warehouse`, `product_category`, `supplier`, `product` | Base tables | Dimensions |

`vw_receipt_performance` and `vw_customer_resolved` are **not** required — the reporting views
already aggregate what the dashboard needs from them.

---

## 9. Data-model limitations

1. **Four detail views are created by analysis files, not reporting files.** D1–D4 exist only
   after the full 35-file pipeline has run. A database built only to Stage 5 will fail the
   refresh. Not resolved here, because resolving it would mean writing new SQL.
2. **View 05 exposes rates and denominators but not on-time numerators.** `n_first_measurable`
   and `on_time_first_receipt_pct` are present; the on-time **count** is not. On-time and OTIF
   percentages therefore **cannot be safely recomputed** for arbitrary slicer combinations.
   Mitigation: display them at the view's own grain and disable cross-filtering on those visuals.
   Reconstructing a numerator from a rounded percentage would introduce error and is not done.
3. **Percentiles in view 06 are not aggregable.** Valid only at the row's grain.
4. **`grain_level` numbering differs between views 05 and 06.** Filter on literal strings.
5. **`Dim Supplier` cannot filter the opportunity fact.** F3 carries `sourcing_last_used` (a
   supplier *type*) rather than a supplier code, following D-18. A supplier slicer will not filter
   Pages 1, 2 or 5.
6. **`Dim Product` does not filter F1/F2.** Those views are aggregated to site × category. A
   product slicer would blank Page 1 and 2 aggregate cards.
7. **Four visuals rely on static reference tables** entered in Power Query from committed results:
   P2-V5 (exposure comparison), P3-V2 (cover bands), P3-V6 (seasonal lag), P4-V3 (Meridian) and
   P4-V8 (buy-ahead). These figures are not exposed by any view at the grain required. They are
   fixed network-level findings and must be excluded from slicer interaction.
8. **No date dimension.** The analysis is a fixed single period (D-05). `calendar_week` exists and
   could support a weekly trend from `mv_inventory_week` if a time series is later wanted, but no
   page in this specification requires one.

---

## 10. Items requiring clarification before implementation

Five decisions I cannot make from the completed project alone.

1. **Should D1–D4 be imported, or should those four visuals use static reference tables instead?**
   Importing couples the refresh to the full pipeline (§9.1); static tables decouple it but freeze
   the values. My recommendation is **import**, with the pipeline dependency documented in the
   `.pbix` description — but this is a portfolio-portability judgement that is yours.

2. **Supplier-type slicer binding on Page 4.** `supplier_type` exists on `Dim Supplier`, on F5 and
   on D3. One must be authoritative. Recommendation: bind the slicer to `Dim Supplier[supplier_type]`
   and accept that F5 and D3 visuals use their own column, with a synchronised slicer if you want
   them to move together.

3. **Whether K17 (unit fill rate, 92.64%) should appear at all.** It is computable from
   `report_04` (`unit_fill_rate_pct`, and 23,653 unmet of 321,519 demand units) but it was not a
   headline figure in Stage 6. Including it adds a fourth availability number to a page that
   already asks the reader to hold three. My inclination is to **drop it** and keep the three
   established measures.

4. **Whether Page 4 should carry a weekly or monthly time series.** No page currently does. A
   monthly demand-versus-unmet series from `vw_demand_line` would strengthen the Renewables and
   seasonal-lag narratives, but the project deliberately reports at half-year for supplier trends
   (D-15) and no committed result presents a monthly network series. Adding one would mean new
   aggregation — I have not specified it.

5. **Colour palette.** §5.5 specifies four semantic **roles** and deliberately no hues. If the
   portfolio has a house palette in `_portfolio/STYLE_GUIDE.md`, the roles should map onto it
   rather than introducing a project-specific scheme. I have not read that file, since it sits
   outside this project directory.

---

## 11. Verification performed on this specification

☑ **Every proposed KPI traced to an existing reporting view or committed result.** All 23 KPI
cards (K1–K23) map to a named view column or a named committed result file. Column names were
read from `information_schema` against the live database, not assumed.

☑ **Every proposed finding traced to existing documentation.** Each interpretation note cites a
finding ID (F-01 to F-16, F-U1, F-U2) or a decision (D-01 to D-40).

☑ **No rejected hypothesis reintroduced as a finding.** Policy age appears only in P3-V7's
Rejected column. The importer-type decline appears only alongside its leave-one-out refutation.
The February buy-ahead appears only as net positive. Site turnover ranking carries the range-mix
warning.

☑ **Unresolved findings remain unresolved.** Daventry and Bristol carry no cause anywhere. §7.6
makes that a build-time gate, and §3 P5-V4 forbids any computed cause field.

☑ **No new recommendation invented.** The dashboard presents the eight recommendations already in
`docs/recommendations.md` and adds none. P1-V5 and P5-V4 restate existing constraints verbatim.

☑ **No factual contradiction found** between the reporting views, the committed results and the
Stage 6 documentation during this review.

---

*Specification only. Implementation awaits approval. Source of truth: 35 SQL files, 32 committed
results in `analysis/query_results/`, and decisions D-01 to D-40 in `docs/technical/analytical-decisions.md`.*
