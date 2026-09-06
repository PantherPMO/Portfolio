# Power BI Step-by-Step Build Guide
## Project 02 — Warehouse Inventory & Supply Chain Performance

> **Calderfield Trade Supplies Ltd is fictional and this dataset is synthetic.** This guide teaches
> you how to build an approved dashboard. It introduces no new findings, no new SQL, no new
> measures and no new recommendations.

**What this document is.** A manual you follow with Power BI Desktop open, one step at a time.
**What it is not.** A design document. The design is already approved and frozen.

**Authorities, in order:**
1. `docs/POWER_BI_IMPLEMENTATION_GUIDE.md` — wins any conflict
2. `docs/POWER_BI_DASHBOARD_SPEC.md` — the approved design
3. `docs/DECISIONS.md`, `docs/KEY_FINDINGS.md`, `docs/RECOMMENDATIONS.md`, `README.md` — the analysis

**Estimated build time:** 8–12 hours for a first-time builder, spread across sessions. Sections 1–7
(data) take roughly half; sections 8–15 (visuals) the other half.

---

## Correction notice — read before Section 9

While preparing this guide I found **one factual error in `POWER_BI_IMPLEMENTATION_GUIDE.md` §7,
Page 1**, and I am flagging rather than silently propagating it.

| | |
|---|---|
| **Where** | Implementation guide, P1-V1a |
| **What it says** | Title: *"Livingston holds the deepest cover in the network"* |
| **What the visual shows** | **Average inventory value by site** |
| **Why it is wrong** | Livingston has the deepest *cover* (128.5 days DIO) but **not** the largest inventory value. Daventry holds £996,883 of £2,043,979 — **48.8%**, nearly half the network. A finding-led title must describe the visual it sits on. |
| **Corrected title used in this guide** | **"Daventry holds nearly half the network's inventory"** |
| **Paired title adjusted to match** | P1-V1b becomes **"…but Bristol, holding the least, serves worst"** (was "…and Bristol…") |

**No file has been modified.** The implementation guide is unchanged; this guide uses the corrected
title and records why. Livingston's 128.5-day cover is still shown — on the Page 5 scorecard, where
DIO belongs.

---

# 1. Before You Start

## 1.1 What this dashboard shows

Calderfield holds **£2,043,979** of average inventory turning **4.67** times a year, and in the
same year failed to supply **7.71%** of customer order lines in full, on demand worth up to
**£1,027,629**.

Most people read those two facts as opposite problems needing opposite fixes — "too much stock" or
"too little stock". Here they happen **at the same sites, in the same year, often on the same
shelves**.

## 1.2 The central story — this must survive the whole build

> **This is primarily an allocation and replenishment-design problem, not simply an overstock or
> understock problem.**

Every page exists to support that sentence. If a visual you build could be screenshotted and used
to argue "just cut inventory everywhere", something has gone wrong — go back and check the
interpretation notes.

## 1.3 The six pages

| Page | Name | Question it answers |
|---|---|---|
| 1 | Executive Overview | How can we hold £2.0m of stock and still miss 7.71% of order lines? |
| 2 | Inventory & Working Capital | Where is the capital, and what mechanism explains each pound? |
| 3 | Availability & Replenishment | Why do stockouts happen despite the stock? |
| 4a | Supplier Reliability & Lead Time | How reliable are our suppliers, and how long do they take? |
| 4b | Sourcing Economics | What is our sourcing structure actually costing us? |
| 5 | Site Investigations & Decision Watchlist | What do we do, and what do we still not know? |

The order is the argument. It deliberately **ends at what is not known**.

> **Page 4 was split into 4a and 4b.** As originally specified it carried 6 KPI tiles and 8 visuals
> at 1280 × 720, which gave the bottom row 112px — not enough for a scatter chart, and three
> visuals were readable only in focus mode. It also answered two questions rather than one, against
> the style guide's own rule. Splitting fixes both. See §12.

## 1.4 Analytical constraints you must not violate

These are not style preferences. Breaking any one of them makes the dashboard wrong.

| # | Constraint | Why |
|---|---|---|
| 1 | **Never add £468,897 (capital) to £103,157 (holding cost)** | One is a one-off balance-sheet figure, the other an annual cost. Different clocks (D-29) |
| 2 | **Never present £1,109,016 as an opportunity** | That is five overlapping exposures counted up to five times. It appears once, on Page 2, marked as the error (D-36) |
| 3 | **Label upper bounds as upper bounds** | Tiers 2 and 4, unmet demand, and the £6,971 buy-ahead residual are ceilings, not estimates (D-34) |
| 4 | **Never assign a cause to Daventry or Bristol** | Both service anomalies are unresolved (D-24, D-25) |
| 5 | **Never present policy age as causing poor outcomes** | Rejected twice. R² = 0.0044 (D-21, D-32) |
| 6 | **Never say "Far East importers are getting worse"** | The type-level decline is one supplier (D-26) |
| 7 | **Never present the February buy-ahead as a cause of excess** | It was net **positive**: +£145,148 (D-30) |
| 8 | **Never build a dual-axis chart** | Portfolio style guide, Hard Rule 1 |
| 9 | **Never invent a target or benchmark** | The project has none, deliberately |
| 10 | **Never recommend broad inventory reduction at Daventry or Bristol** | Their service consequence cannot be quantified (D-39) |

## 1.5 Pre-flight checklist

Tick every box before opening Power BI Desktop.

- [ ] **PostgreSQL 16 is running** and you can connect to it with a client
- [ ] **The full 35-file SQL pipeline has been executed** — not just Stages 1–5
- [ ] **The four detail views exist.** Run this and confirm it returns **4 rows**:
  ```sql
  SELECT table_name
  FROM   information_schema.views
  WHERE  table_schema = 'supply'
    AND  table_name IN ('vw_sku_value_position','vw_policy_alignment',
                        'vw_purchase_quantity_structure','vw_dual_source_gap');
  ```
- [ ] **The seven reporting views exist.** Confirm this returns **7 rows**:
  ```sql
  SELECT table_name FROM information_schema.views
  WHERE table_schema = 'supply' AND table_name LIKE 'vw_kpi%'
     OR (table_schema = 'supply' AND table_name = 'vw_working_capital_release_opportunity');
  ```
- [ ] **Power BI Desktop is installed**, current release, 64-bit
- [ ] **PostgreSQL connector is present** — open Power BI, click **Get Data**, and confirm
      **Database → PostgreSQL database** appears in the list
- [ ] **You have your connection details** — server, port, username, password (this guide uses
      placeholders and invents none)
- [ ] **The project folder is available** so you can open `analysis/query_results/*.txt` to check
      figures as you go
- [ ] **Create the output folders now:** `powerbi/`, `powerbi/screenshots/`, `powerbi/theme/`

> **If the 4-row check fails, stop.** Four views used by Pages 2, 3 and 4 are created by *analysis*
> files, not reporting files. A database built only as far as Stage 5 will not have them. Re-run
> the pipeline per the README before continuing.

---

# 2. Understanding the Data Architecture

Read this section before building. Ten minutes here saves an hour of debugging.

## 2.1 Five kinds of table, and why the distinction matters

| Kind | What it is | How many | Behaviour |
|---|---|---|---|
| **Reporting views** | Purpose-built executive outputs from `sql/05_reporting_views/` | 7 | Pre-aggregated; several contain multiple grains in one result |
| **Analysis / detail views** | Created by files in `sql/04_analysis/`; carry detail the reporting layer does not | 4 | Row-level; only exist after the full pipeline runs |
| **Dimension tables** | Real base tables — the things you slice by | 4 | Small, one row per entity, the "one" side of every relationship |
| **Disconnected parameter table** | Drives the 20/22/25% sensitivity | 1 | **No relationships** — read by a measure via `SELECTEDVALUE` |
| **Static reference tables** | Committed figures no view exposes at the needed grain | 6 | **No relationships**; must never respond to a slicer |

## 2.2 Why 15 objects become 17 queries

Two reporting views contain **several grains stacked in one result set**. Reporting view 05 holds
network, supplier-type, supplier-type-by-half-year, supplier and receiving-site rows all together.

If you import that once and let Power BI sum it, **every number is inflated several times over** —
you would be adding the network row to the site rows to the supplier rows.

The fix is to import the same view more than once, each time filtered to exactly one grain, as a
separately named query.

- **View 05** → 3 queries: `Fact Supplier Delivery` (supplier), `Fact Supplier Network` (network),
  `Fact Supplier Trend` (type × half-year)
- **View 06** → 3 queries: `Fact Cycle Time` (supplier), `Fact Cycle Time By Type` (type),
  `Fact Cycle Time By Site` (receiving site)

**15 distinct PostgreSQL objects · 17 Power BI queries.** Keep both numbers straight — you will
see both in validation.

## 2.3 The complete object table

| Power BI query | PostgreSQL source | Type | Grain | Purpose | Pages |
|---|---|---|---|---|---|
| `Fact Inventory KPI` | `vw_kpi_inventory_value_and_turnover` **+** `vw_kpi_days_inventory_outstanding` **+** `vw_kpi_stock_holding_cost` (merged) | Reporting 01/02/03 | Site × category | Inventory value, COGS, turns, DIO, holding cost | 1, 2, 5 |
| `Fact Availability` | `vw_kpi_availability_and_fill_rate` | Reporting 04 | Site × category | Three availability measures, unmet demand | 1, 3, 5 |
| `Fact Opportunity` | `vw_working_capital_release_opportunity` | Reporting 07 | SKU × site @ 2025-12-28 | The opportunity hierarchy | 1, 2, 5 |
| `Fact Supplier Delivery` | `vw_kpi_supplier_on_time_delivery` | Reporting 05 | Supplier | On-time, all-receipt, OTIF by supplier | 4 |
| `Fact Supplier Network` | `vw_kpi_supplier_on_time_delivery` | Reporting 05 | Network | Cards K18–K20 | 4 |
| `Fact Supplier Trend` | `vw_kpi_supplier_on_time_delivery` | Reporting 05 | Supplier type × half-year | Trend over four half-years | 4 |
| `Fact Cycle Time` | `vw_kpi_order_cycle_time` | Reporting 06 | Supplier | Lead-time detail | 4 |
| `Fact Cycle Time By Type` | `vw_kpi_order_cycle_time` | Reporting 06 | Supplier type | Lead-time distribution summary | 4 |
| `Fact Cycle Time By Site` | `vw_kpi_order_cycle_time` | Reporting 06 | Receiving site | Receiving-process view | 4 |
| `Detail SKU Value` | `vw_sku_value_position` | Analysis (file 02) | SKU | ABC concentration | 2 |
| `Detail Policy Alignment` | `vw_policy_alignment` | Analysis (file 16) | SKU × site | Alignment bands and outcome | 3 |
| `Detail Purchase Structure` | `vw_purchase_quantity_structure` | Analysis (file 17) | Purchase order line, 2025 | Minimum-order structural effect | 4 |
| `Detail Dual Source` | `vw_dual_source_gap` | Analysis (file 14) | SKU | Sourcing trade-off | 4 |
| `Dim Warehouse` | `warehouse` | Base table | Warehouse | Site dimension | 1, 2, 3, 5 |
| `Dim Category` | `product_category` | Base table | Category | Category dimension | 1, 2, 3, 4, 5 |
| `Dim Supplier` | `supplier` | Base table | Supplier | **Authoritative supplier type** | 4 |
| `Dim Product` | `product` | Base table | SKU | Product dimension | 2, 3, 5 |

Plus, created by hand in Power BI (Section 5): `Param Holding Rate` and six static reference
tables `Ref Exposure Comparison`, `Ref Cover Bands`, `Ref Seasonal Lag`, `Ref Meridian Trend`,
`Ref Buy Ahead`, `Ref Renewables`.

> **Do not import anything else.** In particular do not import `mv_inventory_week` (51,220 rows,
> unused) or `vw_demand_line` (33,422 rows, unused — approved decision 4 forbids the monthly
> aggregation it would enable).

---

# 3. Connecting Power BI to PostgreSQL

## 3.1 Storage mode — Import, and why

You will choose **Import**, not DirectQuery. Three reasons that matter for this project:

1. **The data is frozen.** Fixed anchor dates, a frozen synthetic dataset, results verified
   byte-identical across five rebuilds. DirectQuery's only advantage — live data — does not apply.
2. **Percentiles would break.** `vw_kpi_order_cycle_time` uses `PERCENTILE_CONT`. Under
   DirectQuery, Power BI pushes filters into the source query, and **a median computed over a
   filtered subset is not the same number** as the committed result.
3. **Portability.** A recruiter must open your `.pbix` and see data without your database.

## 3.2 Click-by-click connection

1. **Open Power BI Desktop.** Close the splash screen (**File → Close** or the ✕ on the dialog).
2. On the **Home** ribbon, click **Get Data** (large icon, left side).
3. Click **More…** at the bottom of the dropdown.
4. In the left list click **Database**.
5. In the right list click **PostgreSQL database**.
6. Click **Connect**.
7. The **PostgreSQL database** dialog appears. Fill it in:

   | Field | What to enter |
   |---|---|
   | **Server** | `<POSTGRES_HOST>:<POSTGRES_PORT>` — for example `localhost:5432`. Note the **colon**, not a comma |
   | **Database** | `calderfield` |

8. Click the small **▸ Advanced options** triangle. **Leave every field there empty.** Do not type
   a SQL statement — you are importing whole views, not writing queries.
9. Under **Data Connectivity mode**, select **● Import**.
10. Click **OK**.
11. The credentials dialog appears. In the left list choose **Database**.
    - **User name:** `<POSTGRES_USER>`
    - **Password:** `<POSTGRES_PASSWORD>`
    - Leave *"Select which level to apply these settings to"* at the default.
12. Click **Connect**.

> **Common mistake — Server field format.** `localhost, 5432` (comma) is the SQL Server format and
> will fail here. PostgreSQL uses `localhost:5432`.

> **Common mistake — the Database field.** Leave it blank and Power BI shows every database on the
> server, which makes the Navigator very long. Type `calderfield`.

## 3.3 Selecting objects in the Navigator

The **Navigator** window opens showing a tree.

1. Expand **calderfield** → **supply**.
2. Tick the checkbox beside each of these **15** objects:

   **Reporting views (7)**
   - [ ] `vw_kpi_inventory_value_and_turnover`
   - [ ] `vw_kpi_days_inventory_outstanding`
   - [ ] `vw_kpi_stock_holding_cost`
   - [ ] `vw_kpi_availability_and_fill_rate`
   - [ ] `vw_kpi_supplier_on_time_delivery`
   - [ ] `vw_kpi_order_cycle_time`
   - [ ] `vw_working_capital_release_opportunity`

   **Detail views (4)**
   - [ ] `vw_sku_value_position`
   - [ ] `vw_policy_alignment`
   - [ ] `vw_purchase_quantity_structure`
   - [ ] `vw_dual_source_gap`

   **Dimension tables (4)**
   - [ ] `warehouse`
   - [ ] `product_category`
   - [ ] `supplier`
   - [ ] `product`

3. Click a table name (not the checkbox) to preview it on the right and sanity-check it loaded.
4. Click **Transform Data** — **not** *Load*.

> **Do not click Load.** You must filter grains before anything reaches the model. Clicking Load
> imports all grains unfiltered and inflates every number.

## 3.4 Validate this now — import checkpoint

Power Query Editor opens. In the left **Queries** pane:

- [ ] **15 queries** are listed
- [ ] Names match the PostgreSQL object names
- [ ] Clicking each shows data in the preview, not an error banner
- [ ] No yellow warning bar at the top of any preview

Spot-check three row counts by clicking the query and reading the status bar bottom-left:

| Query | Expected |
|---|---:|
| `vw_kpi_inventory_value_and_turnover` | 45 rows |
| `vw_working_capital_release_opportunity` | 515 rows |
| `warehouse` | 4 rows |

> If a query shows *"DataSource.Error"*, see Section 17.1.
> If a view is missing from the Navigator entirely, see Section 17.2.

**Save now:** **File → Save As** → `powerbi/calderfield_inventory_supply_chain.pbix`. Save after
every section from here on.

---

# 4. Power Query Setup

Work through one query at a time. Tick each box before moving on.

## 4.0 Settings to apply first

1. In Power Query Editor, click **File → Options and settings → Query Options**.
2. Under **CURRENT FILE → Regional Settings**, set **Locale for import** to
   **English (United Kingdom)**.
3. Under **CURRENT FILE → Data Load**, **untick** *"Detect column types and headers for unstructured
   sources"*. You will set types explicitly.
4. Click **OK**.

> **Why.** Automatic type detection samples the first 1,000 rows and will type a sparse numeric
> column as `any`. Setting types by hand takes two minutes and prevents a class of silent bugs.

## 4.1 Query 1 — `Fact Inventory KPI` (the merge)

This is the only complex query. It combines three views that all sit at the same grain.

**Why merge?** Reporting views 02 and 03 are *derived from* view 01 in PostgreSQL (D-37) — same 32
keys, extra columns. Three separate tables would create three paths from `Dim Warehouse` to the
same numbers, which Power BI reports as an ambiguous relationship.

### Step A — filter view 01

1. Click `vw_kpi_inventory_value_and_turnover` in the Queries pane.
2. Click the **▼ filter arrow** on the `grain_level` column header.
3. Untick **(Select All)**.
4. Tick **only** `4 — site and category`.
5. Click **OK**.
6. **Expected result:** status bar reads **32 rows**.
7. Right-click the query name → **Rename** → type `Inv01` → Enter.

### Step B — filter and trim view 02

1. Click `vw_kpi_days_inventory_outstanding`.
2. Filter `grain_level` to `4 — site and category` exactly as above. **Expected: 32 rows.**
3. Hold **Ctrl** and click these five column headers:
   `warehouse_code`, `category_code`, `days_inventory_outstanding`,
   `days_inventory_outstanding_unrounded_basis`, `weeks_of_cost_of_sales_held`
4. Right-click one of the selected headers → **Remove Other Columns**.
5. Rename the query to `Inv02`.

### Step C — filter and trim view 03

1. Click `vw_kpi_stock_holding_cost`.
2. Filter `grain_level` to `4 — site and category`. **Expected: 32 rows.**
3. Ctrl-click these eleven columns:
   `warehouse_code`, `category_code`, `holding_rate`, `holding_cost_gbp`,
   `holding_cost_at_20pct_gbp`, `holding_cost_at_25pct_gbp`, `component_capital_gbp`,
   `component_storage_gbp`, `component_service_gbp`, `component_risk_gbp`,
   `holding_cost_pct_of_cost_of_sales`
4. Right-click → **Remove Other Columns**.
5. Rename the query to `Inv03`.

### Step D — merge

1. Click `Inv01`.
2. **Home** ribbon → **Merge Queries** → **Merge Queries** (not *as New*).
3. In the dialog, the top table is `Inv01`. In the dropdown below, choose `Inv02`.
4. In the **top** table, click `warehouse_code`, then **Ctrl-click** `category_code`.
5. In the **bottom** table, click `warehouse_code`, then **Ctrl-click** `category_code`.
   Small numbers **1** and **2** should appear on both pairs.
6. **Join Kind:** `Left Outer (all from first, matching from second)`.
7. Check the message at the bottom: *"The selection matches 32 of 32 rows from the first table."*
8. Click **OK**.
9. A new column `Inv02` appears. Click the **⇄ expand icon** in its header.
10. **Untick** *"Use original column name as prefix"*.
11. Untick `warehouse_code` and `category_code` (already present). Leave the other three ticked.
12. Click **OK**.
13. **Repeat steps 2–12 for `Inv03`**, expanding its nine remaining columns.
14. Rename the query to `Fact Inventory KPI`.

### Step E — remove the grain column

1. Right-click the `grain_level` column header → **Remove**.

### Step F — disable load on the helpers

1. Right-click `Inv02` → untick **Enable load**. Confirm the warning.
2. Right-click `Inv03` → untick **Enable load**.

> These two still feed the merge; they just do not become model tables.

**Validate this now:**
- [ ] `Fact Inventory KPI` = **exactly 32 rows** — if more, the merge keys are wrong (Section 17.3)
- [ ] Columns include `average_stock_gbp`, `closing_stock_gbp`, `cost_of_sales_gbp`,
      `inventory_turns`, `days_inventory_outstanding`, `holding_cost_gbp`
- [ ] `grain_level` is gone
- [ ] `Inv02` and `Inv03` are italic in the Queries pane (load disabled)

## 4.2 Queries 2–9 — the grain-filtered facts

For each row: click the query, filter `grain_level` to the **exact literal string**, remove the
`grain_level` column, rename.

| # | Rename to | Source view | Filter `grain_level` = | Expected rows |
|---|---|---|---|---:|
| 2 | `Fact Availability` | `vw_kpi_availability_and_fill_rate` | `4 — site and category` | **32** |
| 3 | `Fact Opportunity` | `vw_working_capital_release_opportunity` | *(no filter — flat view)* | **515** |
| 4 | `Fact Supplier Delivery` | `vw_kpi_supplier_on_time_delivery` | `4 — supplier` | **29** |
| 5 | `Fact Supplier Network` | `vw_kpi_supplier_on_time_delivery` | `1 — network` | **1** |
| 6 | `Fact Supplier Trend` | `vw_kpi_supplier_on_time_delivery` | `3 — supplier type by half-year` | **16** |
| 7 | `Fact Cycle Time` | `vw_kpi_order_cycle_time` | `3 — supplier` | **29** |
| 8 | `Fact Cycle Time By Type` | `vw_kpi_order_cycle_time` | `2 — supplier type` | **4** |
| 9 | `Fact Cycle Time By Site` | `vw_kpi_order_cycle_time` | `4 — receiving site` | **4** |

**Queries 4, 5 and 6 all come from the same view.** To create the extra copies:

1. Right-click `vw_kpi_supplier_on_time_delivery` → **Duplicate**.
2. Rename the duplicate.
3. Apply its own grain filter.
4. Repeat for the third copy.

Do the same for view 06 to produce queries 7, 8 and 9.

> ### ⚠ Do not do this
> **Never filter on the leading digit.** The numbering means different things in different views:
> ```
> View 05 : 1 network | 2 supplier type | 3 type × half-year | 4 supplier | 5 receiving site
> View 06 : 1 network | 2 supplier type | 3 supplier        | 4 receiving site
> ```
> `grain_level = "3 — ..."` means **category** in views 01–04, **type × half-year** in view 05, and
> **supplier** in view 06. Always tick the full text in the filter list.

## 4.3 Queries 10–13 — the detail views

No grain filter. Rename only.

| # | Rename to | Source | Expected rows |
|---|---|---|---:|
| 10 | `Detail SKU Value` | `vw_sku_value_position` | **250** |
| 11 | `Detail Policy Alignment` | `vw_policy_alignment` | **467** |
| 12 | `Detail Purchase Structure` | `vw_purchase_quantity_structure` | **2,063** |
| 13 | `Detail Dual Source` | `vw_dual_source_gap` | **60** |

## 4.4 Queries 14–17 — the dimensions

| # | Rename to | Source | Expected rows |
|---|---|---|---:|
| 14 | `Dim Warehouse` | `warehouse` | **4** |
| 15 | `Dim Category` | `product_category` | **8** |
| 16 | `Dim Supplier` | `supplier` | **30** |
| 17 | `Dim Product` | `product` | **250** |

## 4.5 Setting data types

For every query: click a column header, then **Transform** ribbon → **Data Type** → choose.

| Column name pattern | Type |
|---|---|
| `*_gbp`, `*cost*`, `unit_cost_gbp` | **Decimal Number** |
| `*_pct`, `*_rate_pct` | **Decimal Number** |
| `*_units`, `*_lines`, `n_*`, `positions`, `sku_weeks`, `weeks_*`, `days_*` | **Whole Number** |
| `*_ratio`, `*_multiple`, `*_factor`, `inventory_turns` | **Decimal Number** |
| `*_date` | **Date** (not Date/Time) |
| `is_*`, `minimum_exceeds_policy_quantity`, `ordered_exactly_at_minimum` | **True/False** |
| `warehouse_code`, `category_code`, `sku`, `supplier_code` | **Text** |
| `service_consequence`, `unresolved_service_constraint`, `source_reference`, `cell_note` | **Text** |

> ### ⚠ Common mistake — Fixed Decimal Number
> Power BI offers **Fixed Decimal Number**, which silently rounds to 4 decimal places. PostgreSQL
> `numeric(12,2)` maps cleanly to **Decimal Number**. Choosing Fixed Decimal will make pennies
> disappear and your validation will fail by small amounts you cannot explain.

## 4.6 Percentage handling — one decision, applied everywhere

PostgreSQL returns percentages **out of 100** (`7.71` means 7.71%). Power BI's `%` format
multiplies by 100 on display. Left alone, 7.71% would render as **771%**.

**For every `*_pct` column in every query:**

1. Click the column header.
2. **Transform** ribbon → **Standard** → **Divide**.
3. Enter `100`.
4. Click **OK**.

Columns needing this include: `closing_zero_rate_pct`, `any_zero_day_rate_pct`,
`days_at_zero_rate_pct`, `line_fill_rate_pct`, `lines_short_rate_pct`, `unit_fill_rate_pct`,
`unmet_share_of_demand_pct`, `on_time_first_receipt_pct`, `on_time_all_receipts_pct`, `otif_pct`,
`split_delivery_rate_pct`, `units_received_pct`, `split_rate_pct`,
`releasable_share_of_position_pct`, `holding_cost_pct_of_cost_of_sales`, `dear_premium_pct`,
`unmet_units_pct`, `days_at_zero_pct`, `cumulative_stock_share_pct`, `cumulative_cogs_share_pct`.

> ### ⚠ Do not divide `holding_rate`
> `Fact Inventory KPI[holding_rate]` is **already a fraction** (0.22). Dividing it gives 0.0022.
> **After this step, click the column and confirm it reads `0.22`.**

## 4.7 Null handling — leave them alone

| Column | Nulls | Action |
|---|---|---|
| `Fact Opportunity[sourcing_last_used]` | 8 | **Leave null.** These positions had no 2025 purchase. Filling with "Unknown" invents a fifth sourcing category |
| `Fact Opportunity[cover_weeks]` | several | **Leave null.** Null means "no demand to measure against" — different from zero cover. Filling with 0 corrupts every cover average |
| `Fact Opportunity[discontinued_date]` | most | Leave null |
| `Fact Opportunity[unresolved_service_constraint]` | empty string for WAR/LIV | **Leave as empty string.** It is `''`, not null; measure M15 tests for it |
| `Fact Supplier Delivery[cell_note]` | empty string | Leave |

> ### ⚠ Do not do this
> Never use **Remove Blank Rows**, **Replace Errors**, or **Fill Down** on any fact table. Each
> would silently change a denominator, and your validation would fail with no visible cause.

## 4.8 Apply

1. **Home** ribbon → **Close & Apply**.
2. Wait for the refresh dialog to finish.

**Validate this now — Section 4 checkpoint:**

- [ ] Report view shows **17 tables** in the Data pane (plus the 2 hidden helpers)
- [ ] Row counts: `Fact Inventory KPI` 32 · `Fact Availability` 32 · `Fact Opportunity` 515 ·
      `Fact Supplier Delivery` 29 · `Fact Supplier Network` 1 · `Fact Supplier Trend` 16 ·
      `Fact Cycle Time` 29 · `Fact Cycle Time By Type` 4 · `Fact Cycle Time By Site` 4 ·
      `Detail SKU Value` 250 · `Detail Policy Alignment` 467 · `Detail Purchase Structure` 2,063 ·
      `Detail Dual Source` 60 · `Dim Warehouse` 4 · `Dim Category` 8 · `Dim Supplier` 30 ·
      `Dim Product` 250

To check a row count: click the table in the Data pane, switch to **Table view** (left rail, grid
icon), read the count at the bottom.

---

# 5. Creating the Static and Disconnected Tables

Seven tables typed by hand. All have **no relationships**.

## 5.1 `Param Holding Rate`

**Why it exists.** The 22% holding-cost rate is an assumption (D-11) — only its 6% capital
component has an authoritative source. Every quantified figure must be viewable at 20% and 25% so
a reader can apply their own judgement.

**Create it:**

1. **Home** ribbon → **Enter Data**.
2. Click the header of Column1 and rename to `Rate`.
3. Click **+** to the right to add a column; rename to `Label`.
4. Click **+** again; rename to `Sort`.
5. Type these three rows:

| Rate | Label | Sort |
|---|---|---|
| 0.20 | 20% — low sensitivity | 1 |
| 0.22 | 22% — approved rate (D-11) | 2 |
| 0.25 | 25% — high sensitivity | 3 |

6. In **Name**, type `Param Holding Rate`.
7. Click **Load**.

**Configure it:**

1. Data pane → expand `Param Holding Rate`.
2. Click `Rate` → **Column tools** ribbon → **Data type: Decimal Number**, **Format: Percentage**,
   decimals **0**.
3. Click `Sort` → **Column tools** → **Data type: Whole Number**.
4. Click `Label` → **Column tools** → **Sort by column** → `Sort`.
5. Right-click `Sort` → **Hide in report view**.

**How it works.** Measure M9 reads the selection with `SELECTEDVALUE` and returns the matching
**pre-computed column** from `Fact Opportunity` — not a multiplication. That is deliberate: the
dashboard cannot drift from the committed results.

> ### ⚠ Do not use "New parameter → Numeric range"
> That builds a continuous slider allowing 23.7%, for which **no committed figure exists**. Three
> discrete values, each backed by a stored column, is the only safe implementation.

**Validate this now:** after building M9 (Section 7), place a card with
`[Selected Annual Holding Cost]` and a slicer on `Param Holding Rate[Label]`. Selecting each in
turn must give **£93,779 / £103,157 / £117,225**. If it does not change, see Section 17.10.

## 5.2 `Ref Exposure Comparison` (S1)

**Why.** Page 2's most important methodological visual shows the five overlapping Stage 4 exposures
and the £1,109,016 error they produce when summed. No view exposes them together.

**Enter Data**, columns `Exposure` (text), `Value` (whole number), `Marker` (text):

| Exposure | Value | Marker |
|---|---:|---|
| Slow-moving stock (file 03) | 123373 | normal |
| Excess above the policy ceiling (file 04) | 134701 | normal |
| Cover over 6 months (file 05) | 398821 | normal |
| Stock above the calibrated rule (file 16) | 115916 | normal |
| Minimum-order bound in closing stock (file 17) | 336205 | normal |
| Naive sum — do not use | 1109016 | error |
| Counted once under the hierarchy | 468897 | headline |
| Network closing stock, for scale | 1711042 | context |

Name: `Ref Exposure Comparison`. **Relationships: none.** Used by: P2-V5.

## 5.3 `Ref Cover Bands` (S2)

**Why.** The relationship between stock cover and unmet demand is the strongest predictive finding
in the project, and the cross-tabulation exists only in `analyse_06` §4.

Columns `Cover Band` (text), `Unmet Unit Rate` (decimal), `SKU Weeks` (whole number):

| Cover Band | Unmet Unit Rate | SKU Weeks |
|---|---:|---:|
| 1 — under 2 weeks | 0.4670 | 1048 |
| 2 — 2 to 4 weeks | 0.0863 | 979 |
| 3 — 4 to 8 weeks | 0.0265 | 2037 |
| 4 — 2 to 6 months | 0.0179 | 4054 |
| 5 — over 6 months | 0.0046 | 2195 |
| 6 — no cover figure | 0.0575 | 141 |

Format `Unmet Unit Rate` as **Percentage, 2 decimals**. Name: `Ref Cover Bands`.
**Relationships: none.** Used by: P3-V2.

## 5.4 `Ref Seasonal Lag` (S3)

**Why.** Shortages arrive systematically after the demand peak. From `analyse_07` §2.

Columns `Category` (text), `Peak Demand Month` (text), `Peak Shortage Month` (text),
`Months Trailing` (whole number):

| Category | Peak Demand Month | Peak Shortage Month | Months Trailing |
|---|---|---|---:|
| HEAT | Jan | Mar | 2 |
| VALV | Jan | Mar | 2 |
| ELEC | Apr | Jun | 2 |
| RENW | Oct | Dec | 2 |
| VENT | Jul | Aug | 1 |
| DRAIN | Oct | Oct | 0 |
| TOOL | Oct | Oct | 0 |
| PIPE | Oct | Aug | 10 |

Name: `Ref Seasonal Lag`. **Relationships: none.** Used by: P3-V6.

## 5.5 `Ref Meridian Trend` (S4)

**Why.** The leave-one-out evidence that the importer-type decline is one supplier. From
`analyse_12` §7 and §8.

Columns `Half Year` (text), `Series` (text), `On Time Pct` (decimal), `N` (whole number):

| Half Year | Series | On Time Pct | N |
|---|---|---:|---:|
| 2024H1 | Meridian Pacific | 0.950 | 100 |
| 2024H2 | Meridian Pacific | 0.939 | 82 |
| 2025H1 | Meridian Pacific | 0.794 | 68 |
| 2025H2 | Meridian Pacific | 0.455 | 33 |
| 2024H1 | Importers excluding Meridian | 0.729 | 107 |
| 2024H2 | Importers excluding Meridian | 0.643 | 98 |
| 2025H1 | Importers excluding Meridian | 0.667 | 66 |
| 2025H2 | Importers excluding Meridian | 0.659 | 41 |

Format `On Time Pct` as **Percentage, 1 decimal**. Name: `Ref Meridian Trend`.
**Relationships: none.** Used by: P4-V2 (the dashed series) and P4-V3.

## 5.6 `Ref Buy Ahead` (S5)

**Why.** To prevent the February 2025 Arden buy-ahead being reintroduced as a cause of excess. From
`analyse_15` §6.

Columns `Component` (text), `Value` (whole number), `Basis` (text):

| Component | Value | Basis |
|---|---:|---|
| Price saving captured | 146490 | one-off, realised |
| Residual stock at 2025-12-28 | 6971 | upper bound |
| Net position at 22% | 145148 | one-off, net |

Name: `Ref Buy Ahead`. **Relationships: none.** Used by: P4-V8.

## 5.7 `Ref Renewables` (S6)

**Why.** The Renewables growth-versus-settings finding. From `analyse_08` §3.

Columns `Quarter` (text), `Demand Units` (whole number), `Line Fill Rate` (decimal),
`Unmet Value` (whole number):

| Quarter | Demand Units | Line Fill Rate | Unmet Value |
|---|---:|---:|---:|
| 2024Q1 | 629 | 0.973 | 51663 |
| 2024Q2 | 596 | 0.922 | 91024 |
| 2024Q3 | 644 | 0.982 | 21443 |
| 2024Q4 | 851 | 0.918 | 128393 |
| 2025Q1 | 869 | 0.938 | 58341 |
| 2025Q2 | 740 | 0.939 | 52242 |
| 2025Q3 | 799 | 0.950 | 70833 |
| 2025Q4 | 1167 | 0.837 | 257709 |

Format `Line Fill Rate` as **Percentage, 1 decimal**. Name: `Ref Renewables`.
**Relationships: none.** Used by: P3-V5.

**Validate this now:**
- [ ] Data pane shows 7 new tables
- [ ] `Param Holding Rate` = 3 rows; `Ref Exposure Comparison` = 8; `Ref Cover Bands` = 6;
      `Ref Seasonal Lag` = 8; `Ref Meridian Trend` = 8; `Ref Buy Ahead` = 3; `Ref Renewables` = 8
- [ ] Model view shows **no relationship lines** touching any of the seven

---

# 6. Building the Data Model

## 6.1 Concepts, briefly

**Fact tables** hold the numbers you measure — inventory value, unmet units, working capital. They
are long and narrow, with many rows.

**Dimension tables** hold the things you slice by — sites, categories, suppliers, products. They
are short, one row per entity.

**Relationships** let a dimension filter a fact. Filter flows from the **one** side to the **many**
side — from `Dim Warehouse` (4 rows) into `Fact Opportunity` (515 rows).

**Disconnected tables** have no relationships on purpose. `Param Holding Rate` is read by a measure
via `SELECTEDVALUE`; the `Ref` tables carry fixed figures that must never move under a filter.

### Why single-direction only

Power BI offers **Both** as a cross-filter direction. **This model uses Single everywhere and you
must not change that.**

With six facts at four different grains, bi-directional filtering lets a filter travel *up* into a
dimension and back *down* into a second fact that never should have been filtered. The result is
numbers that change when they should not, with no error message. It is the most common cause of
silent double counting in Power BI.

If a slicer does not filter a visual, **that is the model telling you the grains differ** — not a
problem to fix by switching to Both.

## 6.2 The 11 required relationships

| # | From (many) | From column | To (one) | To column | Cardinality | Cross-filter | Active | Why |
|---|---|---|---|---|---|---|---|---|
| R1 | `Fact Inventory KPI` | `warehouse_code` | `Dim Warehouse` | `warehouse_code` | Many-to-one | Single | Yes | Site slicing of inventory KPIs |
| R2 | `Fact Inventory KPI` | `category_code` | `Dim Category` | `category_code` | Many-to-one | Single | Yes | Category slicing |
| R3 | `Fact Availability` | `warehouse_code` | `Dim Warehouse` | `warehouse_code` | Many-to-one | Single | Yes | Site slicing of availability |
| R4 | `Fact Availability` | `category_code` | `Dim Category` | `category_code` | Many-to-one | Single | Yes | Category slicing |
| R5 | `Fact Opportunity` | `warehouse_code` | `Dim Warehouse` | `warehouse_code` | Many-to-one | Single | Yes | Site slicing of the hierarchy |
| R6 | `Fact Opportunity` | `category_code` | `Dim Category` | `category_code` | Many-to-one | Single | Yes | Category slicing |
| R7 | `Fact Opportunity` | `sku` | `Dim Product` | `sku` | Many-to-one | Single | Yes | SKU drill-through on Page 5 |
| R8 | `Fact Supplier Delivery` | `supplier_code` | `Dim Supplier` | `supplier_code` | Many-to-one | Single | Yes | **The authoritative supplier-type path** |
| R9 | `Fact Cycle Time` | `supplier_code` | `Dim Supplier` | `supplier_code` | Many-to-one | Single | Yes | Same |
| R11 | `Detail SKU Value` | `category_code` | `Dim Category` | `category_code` | Many-to-one | Single | Yes | ABC by category |
| R12 | `Detail Policy Alignment` | `warehouse_code` | `Dim Warehouse` | `warehouse_code` | Many-to-one | Single | Yes | Site slicing of alignment |

> ### ⚠ Do not create R10
>
> An earlier version of this table listed an **R10**, `Detail SKU Value[sku]` → `Dim Product[sku]`.
> **It has been removed. Do not create it.**
>
> `Detail SKU Value` and `Dim Product` both hold **exactly 250 rows, one per SKU, unique on `sku`**.
> Power BI therefore makes the relationship **one-to-one**, and **a 1:1 relationship in Power BI is
> always bidirectional — the Cross filter direction box is greyed out and you cannot set it to
> Single.**
>
> That gives `Dim Category` two routes to `Fact Opportunity` — the direct one (R6) and a second one
> through `Detail SKU Value` → `Dim Product` → `Fact Opportunity` — and Power BI throws:
>
> ```
> There are ambiguous paths between 'Fact Opportunity' and 'Dim Category'
> ```
>
> **You lose nothing.** The ABC Pareto (P2-V3) reads `Detail SKU Value` directly — its axis,
> columns, line and tooltip all come from that table's own fields, never through `Dim Product`.
>
> **R11 is the relationship that matters here** and it stays:
> `Detail SKU Value[category_code]` → `Dim Category[category_code]`. A genuine many-to-one
> (250 → 8), and it is what lets the category slicer filter the ABC/Pareto visual.
>
> R11 keeps its number — it is **not** renumbered to R10 — so this guide stays traceable to the
> original specification. See D-41.

## 6.3 Creating R1 — the full procedure, once

Follow this exactly for R1. R2–R16 are the same six clicks with different columns.

1. In the left rail, click the **Model view** icon (three connected boxes, third down).
2. Find `Fact Inventory KPI` and `Dim Warehouse`. Drag their boxes so they sit side by side —
   layout is cosmetic but makes the next steps easier.
3. In the **`Dim Warehouse`** box, click and hold on the `warehouse_code` field name.
4. Drag it onto the `warehouse_code` field in the **`Fact Inventory KPI`** box and release.
5. A line appears between the two tables.
6. **Double-click the line** to open **Edit relationship**.
7. Confirm every setting:

   | Setting | Required value |
   |---|---|
   | From table / column | `Fact Inventory KPI` / `warehouse_code` |
   | To table / column | `Dim Warehouse` / `warehouse_code` |
   | Cardinality | **Many to one (\*:1)** |
   | Cross filter direction | **Single** |
   | Make this relationship active | **Ticked** |
   | Assume referential integrity | **Unticked** |

8. Click **OK**.

**Expected result.** A solid line from `Dim Warehouse` to `Fact Inventory KPI`, with **1** at the
warehouse end and **\*** at the fact end, and a **single arrowhead** pointing at the fact.

**Validate this now:**
- [ ] The line is **solid**, not dashed (dashed = inactive)
- [ ] `1` sits at the dimension end, `*` at the fact end
- [ ] **One** arrowhead, pointing toward the fact
- [ ] No warning triangle on the line

**Why this relationship exists.** Without it, a site slicer built on `Dim Warehouse` cannot reach
inventory values, and Page 1's site comparison would show the same total four times.

> ### ⚠ Common mistake — dragging the wrong way
> Drag **from the dimension to the fact**. Dragging fact→dimension usually still works because
> Power BI infers cardinality, but if it guesses **Many to many** you have a problem — see
> Section 17.5.

## 6.4 Creating R2–R12

Repeat §6.3 for each. Quick reference for what to drag:

| # | Drag this column… | …onto this column |
|---|---|---|
| R2 | `Dim Category[category_code]` | `Fact Inventory KPI[category_code]` |
| R3 | `Dim Warehouse[warehouse_code]` | `Fact Availability[warehouse_code]` |
| R4 | `Dim Category[category_code]` | `Fact Availability[category_code]` |
| R5 | `Dim Warehouse[warehouse_code]` | `Fact Opportunity[warehouse_code]` |
| R6 | `Dim Category[category_code]` | `Fact Opportunity[category_code]` |
| R7 | `Dim Product[sku]` | `Fact Opportunity[sku]` |
| R8 | `Dim Supplier[supplier_code]` | `Fact Supplier Delivery[supplier_code]` |
| R9 | `Dim Supplier[supplier_code]` | `Fact Cycle Time[supplier_code]` |
| R11 | `Dim Category[category_code]` | `Detail SKU Value[category_code]` |
| R12 | `Dim Warehouse[warehouse_code]` | `Detail Policy Alignment[warehouse_code]` |

After each, double-click the line and confirm **Many to one · Single · Active**.

## 6.5 The 4 optional recommended relationships

Build these too — the approved implementation guide says *"Build all 15."*

| # | Drag this column… | …onto this column | Why |
|---|---|---|---|
| R13 | `Dim Category[category_code]` | `Detail Policy Alignment[category_code]` | Category slicing on Page 3's alignment matrix |
| R14 | `Dim Warehouse[warehouse_code]` | `Detail Purchase Structure[warehouse_code]` | Site slicing on P4-V6 |
| R15 | `Dim Category[category_code]` | `Detail Purchase Structure[category_code]` | Category slicing on P4-V6 |
| R16 | `Dim Category[category_code]` | `Detail Dual Source[category_code]` | Category tooltip on P4-V7 |

**Total relationships in the finished model: 15** — 11 required (R1–R9, R11, R12) plus 4 optional
(R13–R16). **R10 is not one of them.**

## 6.6 Relationships you must NOT create

Nine candidates were evaluated in the implementation guide. Four are the optional builds above.
**These five are prohibited:**

| Prohibited | Why not |
|---|---|
| **`Detail SKU Value[sku]` → `Dim Product`** *(the former R10)* | Both sides are unique on `sku` at 250 rows, so Power BI creates a **one-to-one** relationship and **forces bidirectional filtering**, which cannot be switched to Single. That produces an **ambiguous filter path** between `Dim Category` and `Fact Opportunity`. Unnecessary — the ABC Pareto reads `Detail SKU Value` directly. **Do not recreate it.** See D-41 |
| `Detail Policy Alignment[sku]` → `Dim Product` | No approved visual needs it. It adds a second path from `Dim Product` into alignment data that no measure uses, creating an ambiguity risk for zero benefit |
| `Detail Purchase Structure[supplier_code]` → `Dim Supplier` | Would create a **second supplier path**, changing what the Page 4 supplier-type slicer means. P4-V6 is a type comparison across all four types; filtering it defeats the visual |
| `Fact Supplier Trend` → any dimension | Its grain is supplier **type**, not supplier. Relating 16 type-rows to 30 suppliers would fan the data out and multiply every trend figure |
| `Fact Cycle Time By Type` → any dimension | Same reason — 4 rows at type grain |
| `Fact Opportunity[sourcing_last_used]` → `Dim Supplier` | **Impossible and wrong.** It holds a supplier *type* ("Far East Importer"), not a supplier code, and it describes a **shelf position**, not a supplier. See §12.2 |

> **A note on counting.** The implementation guide evaluates 9 relationship candidates beyond the
> required set, of which **4 are recommended** (R13–R16) and **5 are prohibited**. R10 is a
> **sixth** prohibition, added after the Power BI build revealed the 1:1 problem — it was
> originally in the *required* set, not the candidate list, which is why it is listed separately
> above.

## 6.7 Model validation checklist

In **Model view**:

- [ ] **15 relationship lines** total — 11 required plus 4 optional
- [ ] Every line is **solid** (none dashed/inactive)
- [ ] Every line has **one arrowhead** (none double-headed)
- [ ] Every line reads **Many to one** when double-clicked
- [ ] **No relationship** touches `Param Holding Rate` or any `Ref` table
- [ ] **No relationship** touches `Fact Supplier Trend`, `Fact Cycle Time By Type`,
      `Fact Cycle Time By Site` or `Fact Supplier Network`
- [ ] No warning triangles anywhere
- [ ] **R10 does NOT exist** — there is **no** line between `Detail SKU Value` and `Dim Product`
- [ ] No relationship anywhere shows **1** at *both* ends (a 1:1 line) — every line reads
      **Many to one**
- [ ] Right-click each dimension → **Manage relationships** shows nothing unexpected

**Hide the key columns** (they clutter the field list and should never be dragged into a visual):
right-click each of `warehouse_code`, `category_code`, `sku`, `supplier_code` **in the fact
tables** → **Hide in report view**. **Keep them in the dimensions** — you slice on those.

> ### ⚠ Do not delete key columns
> Hiding is safe. Deleting breaks the relationship.

---

# 7. Creating the 16 DAX Measures

## 7.1 Create the measures table first

1. **Home** ribbon → **Enter Data**.
2. Leave Column1 empty. In **Name**, type `_Measures`.
3. Click **Load**.
4. Data pane → expand `_Measures` → right-click `Column1` → **Delete**. Confirm.
5. Right-click the `_Measures` table → **Sort by** is irrelevant; instead click the table and use
   **Model view** to drag it to the top-left so it is easy to find.

The underscore keeps it at the top of the alphabetical field list.

## 7.2 How to create any measure

For every measure below:

1. In the **Data pane**, click **`_Measures`** so it is selected.
2. **Home** ribbon → **New measure**.
3. The formula bar opens with `Measure = `.
4. **Select all** the placeholder text and type the measure name, then the formula.
5. Press **Enter**.
6. **Expected result:** the measure appears under `_Measures` with a **calculator icon** (Σ), not a
   column icon.
7. With the measure selected, use the **Measure tools** ribbon to set the **Format**.

> ### ⚠ Common mistake — measure lands in the wrong table
> If you had a fact table selected when you clicked New measure, the measure is created there. Fix
> it: click the measure, then **Measure tools → Home table → `_Measures`**.

---

### M1 · Inventory Value

**Business purpose.** The additive average-inventory base for every visual on Pages 1, 2 and 5.

```dax
Inventory Value = SUM ( 'Fact Inventory KPI'[average_stock_gbp] )
```

**Where:** `_Measures` · **Format:** Currency, £ English (United Kingdom), 0 decimals

**Validation.** Drop it on a blank card with no filters. **Expected: £2,043,979.**
Source: `analysis/query_results/report_01_inventory_value_and_turnover.txt`.

**Why summing is valid.** `average_stock_gbp` at site × category grain is a sum of weekly values
divided by a constant 52. Summing 32 such cells is arithmetically identical to computing the
network average directly. Stage 5 verified sites and categories each sum to network within £0.05.

**Common mistakes.**
- Using `closing_stock_gbp` instead. Closing is **16.3% lower** — turnover would report 5.58 rather
  than 4.67 (D-10).
- Getting a figure near £8.2m: your `grain_level` filter did not apply. See Section 17.3.

---

### M2 · Inventory Turns

**Business purpose.** How many times stock turns over in a year, correct at any filter level.

```dax
Inventory Turns =
DIVIDE (
    SUM ( 'Fact Inventory KPI'[cost_of_sales_gbp] ),
    SUM ( 'Fact Inventory KPI'[average_stock_gbp] )
)
```

**Where:** `_Measures` · **Format:** Decimal number, 2 decimals. Optionally add a custom format
`0.00"×"`.

**Validation.** Blank card, no filters. **Expected: 4.67.** By site: DAV 4.68 · LIV 2.84 ·
WAR 5.63 · BRS 7.13. Source: `report_01`.

**Why aggregation is valid — and why you cannot use the view's column.** Turns is a **ratio of two
sums**, not a sum of ratios. The view's `inventory_turns` column is correct only at its own row.
Averaging 32 cell-level turns would weight a £9,760 Bristol Tools cell equally with a £468,232
Daventry Renewables cell. Recomputing from an additive numerator and denominator is the only
correct aggregation.

**Common mistakes.**
- Dragging `inventory_turns` from the table and letting Power BI **Average** it. This is the single
  most common analytical error in Power BI and it will give you a wrong network figure.
- Using `SUM(inventory_turns)` — gives a meaningless number in the hundreds.

---

### M3 · Days Inventory Outstanding

**Business purpose.** Turns expressed in days — the form stakeholders find intuitive.

```dax
Days Inventory Outstanding = DIVIDE ( 365, [Inventory Turns] )
```

**Where:** `_Measures` · **Format:** Decimal number, 1 decimal

**Validation.** Blank card, no filters. **Expected: 78.2 days.** By site: LIV 128.5 · DAV 78.0 ·
WAR 64.8 · BRS 51.2. Source: `report_02`.

**Why valid.** Derived from M2, so it inherits M2's correctness.

**Common mistakes.** Summing the view's `days_inventory_outstanding` column across cells — it would
give a number in the thousands.

**Note on 365 vs 364.** The KPI library defines DIO on a 365-day year; the period spans 364 days.
The difference is 0.27%. The library definition is kept without deviation (D-37).

---

### M4 · Lines Short Rate %

**Business purpose.** The headline service measure — the share of customer order lines not supplied
in full.

```dax
Lines Short Rate % =
DIVIDE (
    SUM ( 'Fact Availability'[lines_not_supplied_in_full] ),
    SUM ( 'Fact Availability'[demand_lines] )
)
```

**Where:** `_Measures` · **Format:** Percentage, 2 decimals

**Validation.** Blank card, no filters. **Expected: 7.71%** (1,272 ÷ 16,506). By site: BRS 10.77% ·
DAV 7.70% · WAR 6.92% · LIV 5.32%. Source: `report_04`.

**Why valid.** Both numerator and denominator are additive counts at cell grain.

**Common mistakes.**
- Averaging the view's `lines_short_rate_pct` column — weights a 12-line cell equally with a
  3,000-line cell.
- Displaying it beside an ISO-week measure without labelling both bases. This measure is on the
  **calendar-year order-date** clock (D-22).

---

### M5 · Closing Zero Rate %

**Business purpose.** The KPI library's literal stockout definition — SKU-weeks with no stock at the
Sunday snapshot.

```dax
Closing Zero Rate % =
DIVIDE (
    SUM ( 'Fact Availability'[weeks_closing_at_zero] ),
    SUM ( 'Fact Availability'[sku_weeks] )
)
```

**Where:** `_Measures` · **Format:** Percentage, 2 decimals

**Validation.** Blank card, no filters. **Expected: 3.52%** (943 ÷ 26,780). Source: `report_04`.

**Why valid.** Additive counts of SKU-weeks.

**Common mistakes.** Presenting this alone. It is on the **ISO-week** clock and understates the
day-level measure by **1.26× to 1.67×** depending on site. **Never display without M6.**

---

### M6 · Any Zero Day Rate %

**Business purpose.** Catches stockouts that started and cleared before the Sunday snapshot.

```dax
Any Zero Day Rate % =
DIVIDE (
    SUM ( 'Fact Availability'[weeks_with_a_zero_day] ),
    SUM ( 'Fact Availability'[sku_weeks] )
)
```

**Where:** `_Measures` · **Format:** Percentage, 2 decimals

**Validation.** Blank card, no filters. **Expected: 5.05%** (1,353 ÷ 26,780). Source: `report_04`.

**Why valid.** As M5.

**Common mistakes.** Treating M5 and M6 as two estimates of one quantity. They measure different
things and both understate what the customer experienced (M4).

---

### M7 · Unmet Demand Value

**Business purpose.** The value of demand the business failed to meet, at the prices those customers
had already been quoted.

```dax
Unmet Demand Value = SUM ( 'Fact Availability'[unmet_value_gbp] )
```

**Where:** `_Measures` · **Format:** Currency, £, 0 decimals

**Validation.** Blank card, no filters. **Expected: £1,027,629.** By site: DAV £500,673 ·
BRS £216,665 · WAR £179,503 · LIV £130,788. Source: `report_04`.

**Why valid.** A currency sum at cell grain.

**Common mistakes — and this one matters.** Presenting this as lost revenue. **It is an upper
bound.** Substitution is not modelled — some customers would have taken an alternative, some would
have waited. Every card showing it must carry a **▲ upper bound** badge.

**Note.** Also on the calendar-year clock. The snapshot-week basis gives £1,025,038; the **£2,591**
difference is the 133 lines dated 29–31 December (D-13, D-22). Do not reconcile it away.

---

### M8 · Selected Opportunity Value

**Business purpose.** The working capital identified against the current filter — the dashboard's
central number.

```dax
Selected Opportunity Value = SUM ( 'Fact Opportunity'[working_capital_gbp] )
```

**Where:** `_Measures` · **Format:** Currency, £, 0 decimals

**Validation.** Blank card, no filters. **Expected: £468,897.** By tier: £87,478 · £303,558 ·
£70,755 · £7,106 · £0. Source: `report_07`.

**Why summing is valid.** `Fact Opportunity` is **mutually exclusive and exhaustive** — each of the
515 positions appears exactly once and carries only its own assigned tier's figure (D-36). Summing
cannot double count.

**Common mistakes — the most consequential in the build.**
- **Adding this to M9.** One is a one-off capital figure, the other an annual cost. Never on the
  same axis, never in the same total (D-29).
- Calling it "available", "releasable now" or "savings". It is **identified**. Tiers 2 and 4 are
  upper bounds.
- Trying to reconcile it to £1,109,016 — that is the overlapping sum the hierarchy exists to
  replace.

---

### M9 · Selected Annual Holding Cost

**Business purpose.** The annual cost of holding the identified capital, at the selected rate.

```dax
Selected Annual Holding Cost =
VAR SelectedRate = SELECTEDVALUE ( 'Param Holding Rate'[Rate], 0.22 )
RETURN
    SWITCH (
        TRUE (),
        SelectedRate = 0.20, SUM ( 'Fact Opportunity'[holding_cost_at_20pct_gbp] ),
        SelectedRate = 0.25, SUM ( 'Fact Opportunity'[holding_cost_at_25pct_gbp] ),
        SUM ( 'Fact Opportunity'[annual_holding_cost_gbp] )
    )
```

**Where:** `_Measures` · **Format:** Currency, £, 0 decimals

**Validation.** Blank card plus a `Param Holding Rate[Label]` slicer. **Expected: 22% → £103,157 ·
20% → £93,779 · 25% → £117,225.** With nothing selected: **£103,157**. Source: `report_07`.

**Why valid.** As M8 — one row per position, one figure per row.

**Why it reads columns rather than multiplying.** Each rate has a **pre-computed column** in the
view. Reading them means the dashboard cannot drift from the committed results by even a penny.

**Common mistakes.**
- Writing `[Selected Opportunity Value] * SelectedRate`. Mathematically close, but it re-derives a
  figure PostgreSQL already computed and can differ by rounding.
- Omitting the `0.22` fallback in `SELECTEDVALUE` — the measure would go blank when nothing is
  selected.
- Wiring M8 to the parameter too. **Capital does not change with the holding rate.** If K6 moves
  when you change the slicer, you have made this mistake.

---

### M10 · Stock Value at Closing

**Business purpose.** The closing stock position, and the denominator for opportunity share.

```dax
Stock Value at Closing = SUM ( 'Fact Opportunity'[position_stock_value_gbp] )
```

**Where:** `_Measures` · **Format:** Currency, £, 0 decimals

**Validation.** Blank card, no filters. **Expected: £1,711,042.** Source: `report_07`.

**Why valid.** One row per position.

**Common mistakes.** Comparing it directly with M1 as though they measure the same thing. M1 is the
**52-week average**; M10 is a **single instant**, 16.3% lower.

---

### M11 · Opportunity Share of Stock %

```dax
Opportunity Share of Stock % =
DIVIDE ( [Selected Opportunity Value], [Stock Value at Closing] )
```

**Where:** `_Measures` · **Format:** Percentage, 1 decimal

**Validation.** No filters: **27.4%**. Filter to Bristol: **59.1%**. Source: `report_07`.

**Why valid.** A ratio of two measures, both additive over the same table and filter context.

**Common mistakes.** Reading a high share as good performance. Bristol's 59.1% is the highest in the
network **and** Bristol is the worst-serving site at 89.23% line fill, with an unresolved anomaly.

---

### M12 · Unclassified Stock Value

**Business purpose.** The anti-"cut everything" number — stock the analysis has no case against.

```dax
Unclassified Stock Value =
CALCULATE (
    [Stock Value at Closing],
    'Fact Opportunity'[opportunity_mechanism] = "5 — no identified release opportunity"
)
```

**Where:** `_Measures` · **Format:** Currency, £, 0 decimals

**Validation.** No filters. **Expected: £835,219** — 48.8% of closing stock, 209 positions.
Source: `report_07`.

**Common mistakes.** Typing the tier name by hand and mistyping the em dash. **Copy the exact string
from the data.** Click `Fact Opportunity` in Table view, find `opportunity_mechanism`, copy a
tier-5 value. If the measure returns blank, this is why (Section 17.9).

---

### M13 · Minimum Binds %

**Business purpose.** How often a supplier's minimum order quantity exceeded what the replenishment
policy actually called for.

```dax
Minimum Binds % =
DIVIDE (
    CALCULATE (
        COUNTROWS ( 'Detail Purchase Structure' ),
        'Detail Purchase Structure'[minimum_exceeds_policy_quantity] = TRUE ()
    ),
    COUNTROWS ( 'Detail Purchase Structure' )
)
```

**Where:** `_Measures` · **Format:** Percentage, 1 decimal

**Validation.** Table with `Detail Purchase Structure[supplier_type]` on rows.
**Expected: Far East Importer 98.3% · UK / EU Distributor 6.9% · UK Manufacturer 0.0% ·
Small Specialist 0.0%.** Source: `analyse_17` §1.

**Common mistakes.** Comparing this with any Page 2 figure. It is a **flow** over twelve months of
purchasing; Page 2 shows **stock at an instant**.

---

### M14 · Ordered At Minimum %

**Business purpose.** The headline structural evidence — how often the buyer ordered *exactly* the
supplier's minimum, meaning the quantity was a term of trade rather than a decision.

```dax
Ordered At Minimum % =
DIVIDE (
    CALCULATE (
        COUNTROWS ( 'Detail Purchase Structure' ),
        'Detail Purchase Structure'[ordered_exactly_at_minimum] = TRUE ()
    ),
    COUNTROWS ( 'Detail Purchase Structure' )
)
```

**Where:** `_Measures` · **Format:** Percentage, 1 decimal

**Validation.** **Expected: Far East Importer 99.3%.** Source: `analyse_17` §1.

---

### M15 · Unresolved Constraint Text

**Business purpose.** Surfaces the selected site's unresolved-service warning, in the exact words
written in the SQL view.

```dax
Unresolved Constraint Text =
VAR Constraints =
    CALCULATETABLE (
        VALUES ( 'Fact Opportunity'[unresolved_service_constraint] ),
        'Fact Opportunity'[unresolved_service_constraint] <> ""
    )
RETURN
    IF (
        COUNTROWS ( Constraints ) = 1,
        CONCATENATEX ( Constraints, 'Fact Opportunity'[unresolved_service_constraint] ),
        BLANK ()
    )
```

**Where:** `_Measures` · **Format:** Text (no format needed)

**Validation.** Card visual plus a site slicer. Daventry → text about the 2.60% anomaly. Bristol →
text about March–April. **Warrington and Livingston → blank.** No filter → blank (two distinct
constraints exist).

**Common mistakes — and this is a discipline issue, not a technical one.** **Do not paraphrase the
returned text in your visual.** The wording deliberately assigns **no cause** (D-24, D-25, D-39).
Rewriting it in your own words is exactly how an unresolved finding becomes a false claim.

---

### M16 · Dynamic Insight Title

**Business purpose.** A context-aware subtitle for Page 5 so the reader always knows what is
filtered.

```dax
Dynamic Insight Title =
VAR SiteName = SELECTEDVALUE ( 'Dim Warehouse'[warehouse_name], "All four warehouses" )
VAR Capital  = FORMAT ( [Selected Opportunity Value], "£#,##0" )
VAR Share    = FORMAT ( [Opportunity Share of Stock %], "0.0%" )
VAR Flag     = IF (
                   NOT ISBLANK ( [Unresolved Constraint Text] ),
                   "   ▲ Unresolved service constraint — see watchlist",
                   ""
               )
RETURN
    SiteName & ": " & Capital & " identified (" & Share & " of closing stock)" & Flag
```

**Where:** `_Measures` · **Format:** Text

**Validation.** Card visual. No filter →
`All four warehouses: £468,897 identified (27.4% of closing stock)`.
Bristol → `Bristol Regional Distribution Centre: £123,686 identified (59.1% of closing stock)   ▲ Unresolved service constraint — see watchlist`

**Common mistakes.** Changing "identified" to "available" or "releasable". It must say
**identified**. The `▲` flag is not optional.

---

## 7.3 Measure count check

- [ ] `_Measures` contains **exactly 16** measures
- [ ] There is **no** `Unit Fill Rate %` measure — K17 was removed by approved decision
- [ ] There is **no** on-time, OTIF or split-rate measure — those rates are read as **columns** at
      the view's own grain, because view 05 does **not** expose the on-time numerators and
      reconstructing one from a rounded percentage would introduce error
- [ ] There is **no** percentile measure — percentiles are not aggregable
- [ ] There is **no** measure containing the words cause, driver, reason or root cause

> ### ⚠ Do not add measures
> The count is exactly 16. If a visual seems to need a seventeenth, re-read the page instructions —
> the value is almost certainly a column you should drag directly.

---

# 8. Dashboard Design Setup

## 8.1 Page size

For **every** page you create:

1. Click blank canvas (deselect all visuals).
2. **Visualizations** pane → **Format** (paint-roller icon) → **Canvas settings**.
3. **Type:** `Custom`
4. **Width:** `1280` · **Height:** `720`
5. **View** ribbon → **Page view** → **Fit to page**

> **1280 × 720 is a portfolio standard**, not a preference — it keeps this project consistent with
> the other two Power BI projects.

## 8.2 The theme

Create `powerbi/theme/calderfield_theme.json` in a text editor with this content, then in Power BI:
**View** ribbon → **Themes** → **Browse for themes** → select the file.

```json
{
  "name": "Calderfield Portfolio",
  "dataColors": ["#2A78D6","#EB6834","#1BAF7A","#EDA100",
                 "#E87BA4","#008300","#4A3AA7","#E34948"],
  "background": "#FCFCFB",
  "foreground": "#0B0B0B",
  "tableAccent": "#2A78D6",
  "textClasses": {
    "title":    { "fontFace": "Segoe UI Semibold", "fontSize": 14, "color": "#0B0B0B" },
    "header":   { "fontFace": "Segoe UI Semibold", "fontSize": 12, "color": "#0B0B0B" },
    "label":    { "fontFace": "Segoe UI",          "fontSize": 10, "color": "#52514E" },
    "callout":  { "fontFace": "Segoe UI Semibold", "fontSize": 26, "color": "#0B0B0B" }
  },
  "visualStyles": {
    "*": {
      "*": {
        "background":  [{ "show": true, "color": { "solid": { "color": "#FCFCFB" } } }],
        "border":      [{ "show": false }],
        "dropShadow":  [{ "show": false }]
      }
    }
  }
}
```

## 8.3 Semantic colour roles

Four roles carry meaning. Everything else is category identity.

| Role | Where used | Hex |
|---|---|---|
| **Opportunity — tier 1** (most certain) | Discontinued | `#184F95` |
| **Opportunity — tier 2** | Importer / minimum-order | `#256ABF` |
| **Opportunity — tier 3** | Above calibrated rule | `#3987E5` |
| **Opportunity — tier 4** (weakest) | Slow-moving residual | `#86B6EF` |
| **Neutral / no case** | Tier 5, context | `#898781` |
| **Risk / service failure** | Unmet demand, stockouts, thin alignment | `#EC835A` |
| **Unresolved investigation** | Daventry & Bristol markers | `#D03B3B` |
| Chart surface / page background | | `#FCFCFB` / `#F9F9F7` |
| Primary / secondary / muted text | | `#0B0B0B` / `#52514E` / `#898781` |
| Gridline / axis | | `#E1E0D9` / `#C3C2B7` |

The tier ramp goes **dark → light as confidence falls**. That is deliberate: the colour encodes how
certain the claim is.

> ### ⚠ Do not invent colours
> Every hex above comes from the portfolio style guide, validated for colour-vision deficiency. Do
> not pick shades by eye.

> ### ⚠ Never colour high inventory red
> Colouring inventory as "bad" is exactly the simplistic reading this dashboard exists to prevent.

## 8.4 Typography and number formats

| Element | Setting |
|---|---|
| Page title | Segoe UI Semibold, 20pt, `#0B0B0B` |
| Visual title | Segoe UI Semibold, 14pt |
| KPI value | Segoe UI Semibold, 26pt |
| KPI label | Segoe UI, 11pt, `#52514E` |
| Body / table | Segoe UI, 10pt |
| Caveat / basis tag | Segoe UI Italic, 9pt, `#898781` |

| Quantity | Format |
|---|---|
| Currency on labels | `£#,##0` |
| Currency in tooltips/tables | `£#,##0.00` |
| Currency on axis only | `£#,##0,K` |
| Rates | `0.00%` |
| Shares | `0.0%` |
| Turns | `0.00` + `×` |
| Days | `0.0` + ` days` |
| Counts | `#,##0` |

## 8.5 Building a KPI tile

Every tile has four parts, in the same place every time.

1. **Insert** ribbon → **Text box**. Draw it 200 wide × 96 tall.
2. Actually, use a **Card** for the number and a **Text box** beneath for the tags. The cleanest
   method:
   - **Visualizations** → **Card** (single-number icon).
   - Drag the measure into **Fields**.
   - **Format** → **Callout value** → font 26pt Semibold; set decimal places and display units
     (**None** — no "K" abbreviation on cards).
   - **Format** → **Category label** → **Off** (you will supply your own label).
   - **Format** → **Effects → Background** → On, `#FCFCFB`; **Border** → Off; **Shadow** → Off.
3. **Insert → Text box** directly above the card: the label, 11pt, `#52514E`.
4. **Insert → Text box** directly below: the **basis tag**, 9pt italic, `#898781`.
5. Where a badge is required, add a third text box reading `▲ upper bound`, 9pt, `#D03B3B`.
6. Select all four elements (Ctrl-click) → **Format** ribbon → **Group** → **Group**.

**The basis tag is mandatory on every tile.** It is what stops a reader adding a one-off figure to
an annual one. The tags in use are: `average of 52 weeks`, `at 2025-12-28`, `one-off`,
`per annum · 22% assumed`, `ISO-week basis`, `calendar-year basis`.

> **Why no "vs target" comparison?** The portfolio style guide asks every KPI tile to carry a
> comparison. **This project has no targets and is deliberately a single fixed period.** Inventing a
> target would fabricate the benchmark the analysis spent forty decisions avoiding, and comparing to
> 2024 would breach a documented charter trap. The basis tag occupies that slot instead. This is a
> documented deviation, not an oversight.

## 8.6 Section headings and containers

- **Heading:** Insert → Text box, 12pt Semibold, `#0B0B0B`, with a 1px bottom rule
  (Insert → Shapes → Line, `#E1E0D9`).
- **Container:** Insert → Shapes → Rectangle, fill `#FCFCFB`, border `#E1E0D9` 1px, corner radius 4.
  **Send to back** (Format ribbon) so visuals sit on top.
- **Warning banner:** Rectangle, fill `#F9F9F7`, 1px border in the risk or unresolved colour
  depending on purpose, with a text box on top.

## 8.7 Global page furniture

Build once on Page 1, then copy-paste to each new page:

- **Header band** — y=0, height 56. Left: page title. Right: text box reading
  `Synthetic dataset · calendar 2025 · anchor 2025-12-31`, 9pt italic.
- **Footer strip** — y=690, height 30. Text box:
  `Figures reconcile to committed PostgreSQL results in analysis/query_results/. Decisions D-01 to D-40.`
- **Methodology button** — Insert → Buttons → Blank; position top-right of the header; text
  `Methodology`. Its action is configured in Section 15.6.

---

# 9. Page 1 — Executive Overview

**Rename the page:** double-click the tab at the bottom → type `Executive Overview` → Enter.

**Objective.** Make the paradox unavoidable in ten seconds, size the opportunity honestly, and stop
the reader concluding "cut inventory".

**Layout map (1280 × 720).** Set each visual's position via
**Format → General → Properties → Position**.

```
y=56   KPI strip — 5 tiles           K1–K5, 200×96 each, x=24, 224, 424, 624, 824
y=160  Opportunity panel             K6, K7 — 240×96 each, x=1024 and x=1024,y=56
y=272  P1-V1a Inventory by site      616×180, x=24
y=272  P1-V2  Where the capital sits 616×180, x=664
y=460  P1-V1b Service failure        616×160, x=24
y=460  P1-V3  Hierarchy matrix       616×160, x=664
y=628  P1-V4  Central finding        760×58,  x=24
y=628  P1-V5  Warning banner         472×58,  x=800
```

## 9.1 KPI tiles K1–K7

Build each per §8.5.

| # | Label | Measure | Basis tag | Badge | Expected |
|---|---|---|---|---|---|
| K1 | Average inventory | `[Inventory Value]` | average of 52 weeks | | £2,043,979 |
| K2 | Closing inventory | `[Stock Value at Closing]` | at 2025-12-28 | | £1,711,042 |
| K3 | Inventory turns | `[Inventory Turns]` | 2025, on average stock | | 4.67 |
| K4 | Days inventory outstanding | `[Days Inventory Outstanding]` | 365 ÷ turns | | 78.2 |
| K5 | Order lines not supplied in full | `[Lines Short Rate %]` | calendar-year basis | | 7.71% |
| K6 | Working capital identified | `[Selected Opportunity Value]` | one-off | ▲ upper bound in part | £468,897 |
| K7 | Annual holding cost | `[Selected Annual Holding Cost]` | per annum · 22% assumed | | £103,157 |

**K6 and K7 go inside a bordered panel.** Draw a rectangle around them (border `#C3C2B7`, 1px) and
add a caption text box at its top reading, 9pt semibold:

> **One-off capital · Annual cost — never added**

That caption is not decoration. It is the guard against the most likely misreading in the whole
dashboard.

## 9.2 P1-V1a — "Daventry holds nearly half the network's inventory"

*Subtitle: Average inventory by site, 2025*
*(Title corrected — see the Correction notice at the top of this guide.)*

**Business question:** where is the capital physically held?

1. Click blank canvas. **Visualizations** → **Clustered bar chart** (horizontal bars).
2. Position: x=24, y=272, width 616, height 180.
3. Drag `Dim Warehouse[warehouse_name]` → **Y-axis**.
4. Drag `[Inventory Value]` → **X-axis**.
5. **Format → General → Title** → On. Title text:
   `Daventry holds nearly half the network's inventory`
6. **Format → General → Subtitle** → On: `Average inventory by site, 2025`
7. **Format → Visual → X-axis** → **Title** On → `Average inventory (£)`.
8. **Format → Visual → X-axis** → confirm **Start** is blank or `0`. **Bars must start at zero.**
9. **Format → Visual → Bars → Colors** → set all bars to `#2A78D6` (categorical slot 1).
10. **Format → Visual → Data labels** → On, Display units **None**, Value decimal places **0**.
11. Sort: click the visual's **⋯ (More options)** → **Sort axis** → `Inventory Value` →
    **Sort descending**.

**Expected result:** four bars — Daventry £996,883 · Livingston £473,539 · Warrington £366,299 ·
Bristol £207,258.

**Validate this now:** the bars sum to £2,043,979 (check with K1).

## 9.3 P1-V1b — "…but Bristol, holding the least, serves worst"

*Subtitle: Order lines not supplied in full by site, 2025*

1. **Clustered bar chart**. Position x=24, y=460, width 616, height 160.
2. Drag `Dim Warehouse[warehouse_name]` → **Y-axis**.
3. Drag `[Lines Short Rate %]` → **X-axis**.
4. Title: `…but Bristol, holding the least, serves worst`
   Subtitle: `Order lines not supplied in full by site, 2025`
5. X-axis title: `Order lines not supplied in full (%)`. Start at zero.
6. Bars: `#EC835A` (risk role).
7. Data labels On, format `0.00%`.
8. **Sort: ⋯ → Sort axis → `Inventory Value` → Sort descending.**

### Why the sort order matters — read this

**Both charts must use the same site order, sorted by inventory value.** That is what makes the
pair work: the reader's eye tracks one site down through two panels and sees that the two measures
do **not** move together.

**Expected result:** Daventry 7.70% · Livingston 5.32% · Warrington 6.92% · Bristol 10.77%, in that
left-to-right order — visibly *not* descending, which is the point.

> ### ⚠ Do not do this
> **Do not combine these into one chart with a secondary axis.** The portfolio style guide forbids
> dual-axis charts outright (Hard Rule 1), and here it would be actively misleading: a shared axis
> implies a relationship between two measures across **four data points**. Four sites is not a
> sample. The pair shows **coexistence, not correlation**.
>
> **Do not add a trend line or R² to either chart.**

**Placement:** align P1-V1b directly below P1-V1a, same x, same width. Select both → **Format**
ribbon → **Align → Align left**.

## 9.4 P1-V2 — "Nearly half the estate has no case against it"

*Subtitle: Closing stock by opportunity mechanism*

1. **Visualizations** → **Stacked bar chart**.
2. Position x=664, y=272, width 616, height 180.
3. Drag `[Stock Value at Closing]` → **X-axis**.
4. Drag `Fact Opportunity[opportunity_mechanism]` → **Legend**.
5. Leave **Y-axis empty** — this gives a single stacked bar.
6. Title: `Nearly half the estate has no case against it`
7. **Format → Visual → Bars → Colors** — set each legend value:

   | Legend value | Hex |
   |---|---|
   | `1 — discontinued or obsolete exposure` | `#184F95` |
   | `2 — importer and minimum-order structural stock` | `#256ABF` |
   | `3 — above the calibrated replenishment requirement` | `#3987E5` |
   | `4 — slow-moving residual` | `#86B6EF` |
   | `5 — no identified release opportunity` | `#898781` |

8. **Data labels** On for larger segments; **Format → Data labels → Overflow text** Off.
9. **Legend** On, position **Bottom**.

**Expected result:** segments of £87,478 · £416,075 · £357,897 · £14,373 · **£835,219**, totalling
£1,711,042. The grey tier-5 segment is the largest.

> ### ⚠ Interpretation note — put this in the subtitle
> **The bar shows stock held, not capital releasable.** Tier 2 holds £416,075 of stock but only
> £303,558 is claimable, and that is an upper bound. Data labels show **stock value**; releasable
> capital appears only in the tooltip and on Page 2.

## 9.5 P1-V3 — "£468,897 identified — counted once, not summed"

*Subtitle: The opportunity hierarchy*

**First, create the Basis calculated column** (this is a column, not one of the 16 measures):

1. Data pane → click `Fact Opportunity`.
2. **Table tools** ribbon → **New column**.
3. Enter:

```dax
Basis =
SWITCH (
    'Fact Opportunity'[opportunity_mechanism],
    "1 — discontinued or obsolete exposure",             "Definitional",
    "2 — importer and minimum-order structural stock",    "Upper bound",
    "3 — above the calibrated replenishment requirement", "Measured",
    "4 — slow-moving residual",                           "Upper bound",
    "None"
)
```

> Copy the tier strings **from the data**, not by retyping the em dashes.

**Now the matrix:**

1. **Visualizations** → **Matrix**. Position x=664, y=460, width 616, height 160.
2. **Rows:** `Fact Opportunity[opportunity_mechanism]`
3. **Values**, in this order:
   - `Fact Opportunity[sku]` → change aggregation to **Count** → rename to `Positions`
     (click the field in the Values well → **Rename for this visual**)
   - `[Stock Value at Closing]` → rename to `Stock value`
   - `[Selected Opportunity Value]` → rename to **`Working capital (£ one-off)`**
   - `[Selected Annual Holding Cost]` → rename to **`Annual holding cost (£ p.a., 22%)`**
   - `Fact Opportunity[Basis]` → set aggregation to **First** → rename to `Basis`
4. **Format → Visual → Row subtotals** → Off. **Column subtotals** → Off.
5. **Format → Visual → Grand total** → **On for rows** (a total row) — this is the £468,897 line.
6. **Conditional formatting:** click the `Working capital` field in Values → dropdown →
   **Conditional formatting → Data bars** → On → positive bar `#256ABF`.

**Expected result:**

| Mechanism | Positions | Stock value | Working capital | Annual holding cost | Basis |
|---|---:|---:|---:|---:|---|
| 1 — discontinued | 25 | £87,478 | £87,478 | £19,245 | Definitional |
| 2 — importer/minimum | 148 | £416,075 | £303,558 | £66,783 | Upper bound |
| 3 — above rule | 125 | £357,897 | £70,755 | £15,566 | Measured |
| 4 — slow-moving | 8 | £14,373 | £7,106 | £1,563 | Upper bound |
| 5 — none | 209 | £835,219 | £0 | £0 | None |
| **Total** | **515** | **£1,711,042** | **£468,897** | **£103,157** | |

> ### ⚠ Do not do this
> **Do not add a total across the Working capital and Annual holding cost columns.** They are
> different types of quantity on different clocks. The column headers must carry their units —
> `£ one-off` and `£ p.a.` — exactly as written above.

## 9.6 P1-V4 — Central finding callout

1. **Insert** → **Text box**. Position x=24, y=628, width 760, height 58.
2. Type (bold the first sentence):

> **£2.0m of inventory and a 7.71% line-fill failure are happening at the same time, at the same
> sites.** This is an **allocation and replenishment-design** problem, not an overstock or
> understock problem. Settings track where demand has been, not where it is going: rising-demand
> lines sit at 0.68 of the network's own working rule and falling-demand lines at 1.33. Separately,
> supplier minimums — not replenishment decisions — set the order quantity on 98.3% of importer
> purchase lines.

3. Font 10pt, `#0B0B0B`.

> ### ⚠ Do not make this dynamic
> Do not bind it to a measure. This is the **network-level** finding and would become false under a
> site filter.

## 9.7 P1-V5 — Interpretation warning

1. **Insert → Shapes → Rectangle.** Position x=800, y=628, width 472, height 58. Fill `#F9F9F7`,
   border `#C3C2B7` 1px.
2. **Insert → Text box** on top, same position:

> **£468,897 is identified, not available.** Counted once across five mutually exclusive tiers;
> three of the four active tiers are upper bounds. **48.8% of the estate has no identified
> opportunity at all.** £252,435 — 53.8% — sits at two sites with unresolved service anomalies,
> where no broad inventory reduction is recommended. Capital released is one-off; holding cost
> saved is annual; they are never added.

3. Font 9pt.

## 9.8 Slicers on Page 1

1. **Visualizations** → **Slicer**. Position it in the header band, x=900, y=8, width 170,
   height 40.
2. Drag `Dim Warehouse[warehouse_name]` into **Field**.
3. **Format → Visual → Slicer settings → Style** → **Dropdown**.
4. Repeat for a second slicer with `Dim Category[category_name]`, x=1080, y=8.

**Only these two slicers.** Specifically:

- **No supplier slicer** — `Dim Supplier` has no relationship to `Fact Inventory KPI` or
  `Fact Availability`. It would appear to work and silently do nothing.
- **No product slicer** — `Dim Product` filters `Fact Opportunity` but **not** the site×category
  facts. Selecting a product would blank K1–K5 while K6 still showed a number. Confusing and wrong.
- **No date slicer** — the period is fixed at 2025 by design (D-05).

## 9.9 Page 1 Validation Checklist

- [ ] K1 = £2,043,979
- [ ] K2 = £1,711,042
- [ ] K3 = 4.67
- [ ] K4 = 78.2
- [ ] K5 = 7.71%
- [ ] K6 = £468,897 with the ▲ badge visible
- [ ] K7 = £103,157 with the `per annum` tag visible
- [ ] K6/K7 sit inside the captioned panel
- [ ] **No visual sums K6 and K7**
- [ ] P1-V1a and P1-V1b use the **same site order** (by inventory value)
- [ ] **Neither has a secondary axis**; neither has a trend line
- [ ] P1-V2 segments total £1,711,042; the grey tier-5 segment is visibly the largest
- [ ] P1-V3 total row reads £468,897 (capital) and £103,157 (holding) as **separate** columns
- [ ] P1-V3 has **no** cross-column total
- [ ] Every tile carries a basis tag
- [ ] Selecting a site in the slicer changes all visuals coherently
- [ ] Page is 1280 × 720

---

# 10. Page 2 — Inventory & Working Capital

**New page:** click the **+** beside the page tabs. Rename to `Inventory & Working Capital`. Set
canvas to 1280 × 720. Copy the header/footer furniture from Page 1 (select, Ctrl-C, switch page,
Ctrl-V).

**Objective.** Show where capital is tied up, and what mechanism explains each pound.

```
y=56   KPI strip — 5 tiles K8–K12, 240×96, x=24,272,520,768,1016
y=160  P2-V1 Inventory by site        400×200, x=24
y=160  P2-V2 Inventory by category    400×200, x=440
y=160  P2-V3 ABC Pareto               392×200, x=856
y=372  P2-V4 Hierarchy matrix         760×230, x=24
y=372  P2-V5 Why not summed           472×230, x=800
y=614  P2-V6 Slow-moving lands where  1232×72, x=24
```

## 10.1 Understanding what you are showing

Before building, be clear on five terms — visitors confuse them constantly.

| Term | What it is | Value |
|---|---|---|
| **Average inventory** | Mean of 52 weekly snapshots across 2025 | £2,043,979 |
| **Closing inventory** | The position at one instant, 2025-12-28 | £1,711,042 |
| **Inventory turns** | Cost of sales ÷ average inventory | 4.67 |
| **DIO** | 365 ÷ turns | 78.2 days |
| **Holding cost** | Average inventory × 22% | £449,675 |
| **Working capital opportunity** | Capital the analysis can argue against, counted once | £468,897 |

Closing is **16.3% below** average because importer receipts arrive in a sawtooth and the year ends
in a trough. **Turnover always uses average** (D-10).

## 10.2 KPI tiles K8–K12

| # | Label | Measure | Basis tag | Expected |
|---|---|---|---|---|
| K8 | Closing inventory | `[Stock Value at Closing]` | at 2025-12-28 | £1,711,042 |
| K9 | Working capital identified | `[Selected Opportunity Value]` | one-off · ▲ upper bound in part | £468,897 |
| K10 | Annual holding cost | `[Selected Annual Holding Cost]` | per annum | £103,157 |
| K11 | Stock with no identified opportunity | `[Unclassified Stock Value]` | at 2025-12-28 | £835,219 |
| K12 | Discontinued exposure | `[Selected Opportunity Value]` | one-off · definitional | £87,478 |

**K12 needs a visual-level filter:** with the card selected, drag
`Fact Opportunity[opportunity_mechanism]` into the **Filters on this visual** well → **Basic
filtering** → tick only `1 — discontinued or obsolete exposure`.

## 10.3 P2-V1 — "Daventry holds half the network's capital"

Clustered bar chart, x=24 y=160, 400×200. Axis `Dim Warehouse[warehouse_name]`, value
`[Inventory Value]`. X-axis title `Average inventory (£)`. Sorted descending, from zero. Bars
`#2A78D6`. Data labels on.

**Tooltip note (configured in Section 15):** the bar is **average** inventory; closing is 16.3%
lower network-wide.

## 10.4 P2-V2 — "Heating and Tools turn slowest"

1. Clustered bar chart, x=440 y=160, 400×200.
2. Y-axis `Dim Category[category_name]`; X-axis `[Inventory Value]`.
3. **Also drag `[Inventory Turns]` into the Tooltips well** so it shows on hover.
4. X-axis title `Average inventory (£)`. Sorted descending, from zero.
5. **Data labels On** — mandatory here. With eight categories you exceed three colour series and
   the palette includes low-contrast slots; the style guide requires visible direct labels.

**Expected:** RENW £726,834 · HEAT £321,202 · ELEC £265,370 · PIPE £225,370 · DRAIN £210,395 ·
VENT £122,879 · VALV £95,447 · TOOL £76,482.

**Interpretation note:** low turns is not by itself a problem. Heating is seasonal — its demand
index peaks at 1.78 in January.

## 10.5 P2-V3 — "Ten SKUs hold 36% of the capital"

1. **Visualizations** → **Line and stacked column chart**. x=856 y=160, 392×200.
2. **X-axis:** `Detail SKU Value[sku]`
3. **Column y-axis:** `Detail SKU Value[average_stock_gbp]`
4. **Line y-axis:** `Detail SKU Value[cumulative_stock_share_pct]`
5. Sort: ⋯ → **Sort axis** → `average_stock_gbp` → **descending**.
6. Column axis: title `Average stock (£)`, **start at zero**.
7. Line axis: title `Cumulative share (%)`.
8. Turn **X-axis labels Off** — 250 SKU codes are unreadable; the shape is the message.

> **Is this a dual axis?** It is a Pareto, the one accepted exception: the line is a cumulative
> transformation of the *same* measure as the columns, not a second independent measure. This is
> not the forbidden pattern of C-1 (two unrelated measures implying correlation). If you prefer to
> be strict, split it into a column chart plus a separate cumulative line chart.

**Site slicer must NOT affect this visual** — `Detail SKU Value` has no site column. Configure in
Section 14.

**Expected:** top 10 SKUs reach 36.4% cumulative; top 50 reach 74.9%.

**Interpretation note:** rank by stock value and rank by cost of sales **diverge** — 30 SKUs worth
£116,623 rank high on stock and low on sales. The reverse cell is empty: no SKU is under-stocked
relative to high sales.

## 10.6 P2-V4 — "Every pound explained once"

1. **Matrix**, x=24 y=372, 760×230.
2. **Rows**, in this order (creates the drill hierarchy):
   `Fact Opportunity[opportunity_mechanism]` → `Dim Warehouse[warehouse_name]` →
   `Fact Opportunity[sku]`
3. **Values:** Positions (count of `sku`) · `[Stock Value at Closing]` ·
   `[Selected Opportunity Value]` renamed `Working capital (£ one-off)` ·
   `[Selected Annual Holding Cost]` renamed `Annual holding cost (£ p.a.)` ·
   `Fact Opportunity[holding_cost_at_20pct_gbp]` (Sum) renamed `at 20%` ·
   `Fact Opportunity[holding_cost_at_25pct_gbp]` (Sum) renamed `at 25%`
4. **Format → Visual → Row headers → +/- icons** → On (lets you expand tiers).
5. **Stepped layout** → Off, so each level gets its own column.

**Add the buy-ahead flag:** drag `Fact Opportunity[is_february_buy_ahead_position]` into
**Tooltips**. Its tooltip text should read: *"February buy-ahead residual already carved out of this
figure (D-30, D-38)."*

> ### ⚠ Three money columns, three different meanings
> - **Stock value** = what is on the shelf
> - **Working capital** = what could be argued against — **one-off**, partly an upper bound
> - **Annual holding cost** = the yearly cost of holding it — **annual**
>
> Units in every header. **No cross-column total, ever.**

## 10.7 P2-V5 — "The same pounds, counted five times"

**The most important methodological visual in the dashboard.**

1. **Clustered bar chart**, x=800 y=372, 472×230.
2. **Y-axis:** `Ref Exposure Comparison[Exposure]`
3. **X-axis:** `Ref Exposure Comparison[Value]`
4. Sort: ⋯ → **Sort axis** → `Value` → **descending**.
5. **Format → Visual → Bars → Colors → fx (Conditional formatting)** →
   **Format style: Rules**, based on `Ref Exposure Comparison[Marker]`:
   - `error` → `#EC835A`
   - `headline` → `#256ABF`
   - `context` → `#898781`
   - `normal` → `#86B6EF`
6. **Data labels** On, `£#,##0`.
7. Title: `The same pounds, counted five times`

**Mark the error bar explicitly:**
- **Insert → Text box** positioned over the `Naive sum` bar: `✗ do not use`, 10pt, `#EC835A`.
- The label text in the table already reads "Naive sum — do not use".

> **Colour alone is never enough** (style guide rule 7). The `✗` glyph and the label text both
> carry the meaning, so a colour-blind reader is not misled.

**Interactions: NONE.** These are fixed network figures. Section 14 covers how.

**Expected bars:** 1,711,042 (context) · **1,109,016 (error)** · 468,897 (headline) · 398,821 ·
336,205 · 134,701 · 123,373 · 115,916.

> ### ⚠ This is the only place £1,109,016 may appear
> And it appears **in order to be rejected**. 23 positions worth £70,857 are both slow-moving and
> above policy; 54.4% of high-cover positions are also minimum-order constrained; 85.4% are also
> policy-authorised. Adding the five exposures "releases" 65% of the entire estate.

## 10.8 P2-V6 — "Slow-moving stock is a symptom, not a problem in itself"

1. **Table** visual, x=24 y=614, 1232×72.
2. **Columns:** `Fact Opportunity[opportunity_mechanism]` · Positions (count of `sku`) ·
   `[Stock Value at Closing]` · `[Selected Opportunity Value]`
3. **Visual-level filter:** you need positions meeting file 03's slow rule. The simplest faithful
   approach that adds no logic: filter `Fact Opportunity[weeks_since_last_issue]` to
   **is greater than 26**, **or** `cover_weeks` **is greater than 52**. Power BI's filter pane
   cannot express OR across two fields on one visual, so instead:
   - Present this as a **static text summary** using the figures below, which come directly from
     `report_07` §4. This avoids inventing a filter expression.

**Text to display:**

> Of the £123,373 of slow-moving stock measured in file 03, only **£14,373 across 8 positions**
> survives as an unexplained residual once stronger mechanisms take precedence.
> £23,725 is discontinued · £34,954 is minimum-order structural · £50,321 sits above the calibrated
> rule.

**Interpretation note:** a finding about **classification**. The £123,373 did not shrink; it was
explained.

## 10.9 Slicers on Page 2

Three: **Site** (`Dim Warehouse[warehouse_name]`), **Category** (`Dim Category[category_name]`),
and **Holding rate** (`Param Holding Rate[Label]`).

For the holding-rate slicer:
1. Slicer visual, **Style: Dropdown** or **List** (list is clearer with 3 options).
2. Field: `Param Holding Rate[Label]`.
3. **Select `22% — approved rate (D-11)`** so it is the default.
4. Add a text box beneath: `Holding cost rate — see D-11`, 9pt italic.

## 10.10 Page 2 Validation Checklist

- [ ] K8 £1,711,042 · K9 £468,897 · K10 £103,157 · K11 £835,219 · K12 £87,478
- [ ] Changing the holding-rate slicer moves **K10 only** — K9 must not move
- [ ] 20% → £93,779 · 22% → £103,157 · 25% → £117,225
- [ ] P2-V1 bars sum to £2,043,979
- [ ] P2-V2 shows 8 categories with visible data labels
- [ ] P2-V3 top-10 cumulative reaches 36.4%
- [ ] The **site slicer does not** change P2-V3
- [ ] P2-V4 expands from tier → site → SKU
- [ ] P2-V4 has **no** cross-column total
- [ ] P2-V5 shows the naive-sum bar marked `✗ do not use`
- [ ] P2-V5 does **not** respond to any slicer
- [ ] No visual anywhere adds capital to holding cost

---

# 11. Page 3 — Availability & Replenishment

New page, rename `Availability & Replenishment`, 1280 × 720, copy the furniture.

**Objective.** Explain why stockouts occur despite substantial inventory, and separate what is
supported from what is unresolved and what was rejected.

```
y=56   KPI strip — 4 tiles K13–K16, 300×96, x=24,332,640,948
y=160  P3-V1 Three measures by site   616×200, x=24
y=160  P3-V2 Availability vs cover    616×200, x=664
y=372  P3-V3 Direction × alignment    400×220, x=24
y=372  P3-V4 Outcome by alignment     400×220, x=440
y=372  P3-V5 Renewables               392×220, x=856
y=604  P3-V6 Seasonal lag             500×92,  x=24
y=604  P3-V7 Evidence status panel    732×92,  x=540
```

## 11.1 The three availability measures — why they are not interchangeable

This is the concept the page exists to teach. Understand it before building.

| Measure | What it counts | Clock | Value |
|---|---|---|---|
| **Weeks closing at zero** | SKU-weeks with no stock at the Sunday snapshot | ISO week | **3.52%** |
| **Weeks containing a zero day** | SKU-weeks where stock hit zero on any day | ISO week | **5.05%** |
| **Order lines not supplied in full** | What the customer actually experienced | Calendar year | **7.71%** |

They are **not three estimates of one number**. Measure 1 misses any stockout that started and
cleared between Mondays — it understates measure 2 by **1.26× at Livingston and 1.67× at Bristol**.
Both understate measure 3, because a line can be short-shipped from a position that never reached
zero.

**Quoting the lowest alone is a choice about which answer to give.** They travel together
everywhere on this page.

## 11.2 KPI tiles K13–K16

| # | Label | Measure | Basis tag | Badge | Expected |
|---|---|---|---|---|---|
| K13 | Weeks closing at zero | `[Closing Zero Rate %]` | ISO-week basis | | 3.52% |
| K14 | Weeks with a zero-stock day | `[Any Zero Day Rate %]` | ISO-week basis | | 5.05% |
| K15 | Order lines not supplied in full | `[Lines Short Rate %]` | calendar-year basis | | 7.71% |
| K16 | Value of demand not met | `[Unmet Demand Value]` | calendar-year basis | ▲ upper bound | £1,027,629 |

> **K17 does not exist.** The Unit Fill Rate card was removed by approved decision. Do not add a
> replacement availability KPI — three measures is the framework.

## 11.3 P3-V1 — "Weekly snapshots miss two thirds of Bristol's stockouts"

1. **Clustered column chart**, x=24 y=160, 616×200.
2. **X-axis:** `Dim Warehouse[warehouse_name]`
3. **Y-axis**, all three: `[Closing Zero Rate %]`, `[Any Zero Day Rate %]`, `[Lines Short Rate %]`
4. Y-axis title: `Three distinct availability measures (%)`. Start at zero.
5. **Legend** On, bottom. **Data labels** On (three series ≤ 4, so direct labels are required).
6. Colours: measure 1 `#86B6EF`, measure 2 `#3987E5`, measure 3 `#EC835A`.

**Expected (Bristol):** 4.49% · 7.50% · 10.77%.

> ### ⚠ Interpretation note — mandatory in the subtitle
> The three columns are **not three estimates of one quantity**. Axis label must read "three
> distinct availability measures".

## 11.4 P3-V2 — "Under two weeks of cover, nearly half of demand goes unmet"

1. **Clustered column chart**, x=664 y=160, 616×200.
2. **X-axis:** `Ref Cover Bands[Cover Band]`
3. **Y-axis:** `Ref Cover Bands[Unmet Unit Rate]`
4. Y-axis title `Unmet unit rate (%)`, start at zero. X-axis title `Stock cover before the week`.
5. Sort by `Cover Band` **ascending** (the bands have inherent order).
6. Data labels On.
7. **Annotate the first bar:** Insert → Text box near the 46.70% column reading
   `46.70% — under 2 weeks of cover`.
8. **Interactions: NONE.**

**Expected:** 46.70% · 8.63% · 2.65% · 1.79% · 0.46% · 5.75%.

**Interpretation note:** cover predicts availability strongly, **but the relationship is not linear
and the tail matters** — 2,195 SKU-weeks sat on over six months of cover and still produced £10,519
of unmet demand.

## 11.5 P3-V3 — "Rising lines are set thin; falling lines are set deep"

1. **Matrix**, x=24 y=372, 400×220.
2. **Rows:** `Detail Policy Alignment[demand_direction]`
3. **Columns:** `Detail Policy Alignment[alignment_band]`
4. **Values:** `Detail Policy Alignment[sku]` → aggregation **Count** → rename `Positions`
5. **Conditional formatting** on Positions → **Background color** → gradient, minimum `#CDE2FB`,
   maximum `#184F95`.

**Expected:**

| Demand direction | Set thin | In line | Set deep |
|---|---:|---:|---:|
| rising | 40 | 41 | 14 |
| broadly flat | 54 | 92 | 58 |
| falling | 27 | 68 | 73 |

> ### ⚠ Annotate the "broadly flat" row
> Add a text box: **"broadly flat = calibration set; centres on 1.00 by construction (D-31)"**.
>
> The benchmark was calibrated *from* flat-demand lines, so that row is the **reference, not
> evidence**. The finding lives in the rising and falling rows.

## 11.6 P3-V4 — "Thin settings cost twenty times more in service than deep settings cost in capital"

1. **Table** visual, x=440 y=372, 400×220.
2. **Columns:** `Detail Policy Alignment[alignment_band]` · Count of `sku` renamed `Positions` ·
   Average of `cover_weeks` renamed `Mean cover (wks)` · Sum of `unmet_units_2025` and
   `demand_units_2025` — **or simply** Average of `unmet_units_pct` renamed `Unmet units %` ·
   Sum of `unmet_value_2025_gbp` renamed `Unmet value` · Average of `days_at_zero_pct` renamed
   `Days at zero %`

**Expected:**

| Alignment | Positions | Mean cover | Unmet units % | Unmet value | Days at zero % |
|---|---:|---:|---:|---:|---:|
| 1 — set thin | 121 | 13.3 | 11.62% | £505,019 | 7.28% |
| 2 — in line | 201 | 11.8 | 5.97% | £436,474 | 3.18% |
| 3 — set deep | 145 | 32.4 | 2.79% | £41,426 | 1.36% |

> ### ⚠ Caption this visual — it reads wrong without it
> **This is not a ranking and "set deep" is not the goal.** Deeper settings buy availability; that
> is what they are for. The finding is the **asymmetry**: stock above the calibrated rule costs
> **£25,502 a year** to hold, while unmet demand on thin-set lines is **£505,019** over the same
> year — roughly twenty to one, service over capital.

**Policy age:** you may include `policy_age_months` as a **tooltip** field only. It must not be a
column, an axis, a legend or a slicer anywhere on this page.

## 11.7 P3-V5 — "Renewables demand grew 85.5% while cover ran at a third of the network's"

1. **Line and clustered column chart**, x=856 y=372, 392×220.
2. **X-axis:** `Ref Renewables[Quarter]`
3. **Column y-axis:** `Ref Renewables[Demand Units]`
4. **Line y-axis:** `Ref Renewables[Line Fill Rate]`
5. Column axis title `Demand (units)`, from zero. Line axis title `Line fill rate (%)`.
6. **Interactions: NONE.**
7. **Add a label to the visual title area:** `Partially supported`, 9pt, `#EDA100`.

**Expected:** demand rising 629 → 1,167 across eight quarters; line fill falling to **83.7%** in
2025Q4 with £257,709 unmet.

> ### ⚠ Mandatory caveat — put it in the subtitle, not just a tooltip
> **Only 40 stocked positions exist and 31 of them are at Daventry.** This is a category finding
> resting on a single site — and that site carries its own unresolved service anomaly. The
> direction is clear; the breadth is not.
>
> **Age is not the mechanism.** Renewables policies average 12.1 months against 11.0 elsewhere —
> essentially identical. The settings are not old, they are **small**.

## 11.8 P3-V6 — "Shortages arrive two months after the demand peak"

1. **Table**, x=24 y=604, 500×92.
2. Columns: `Category` · `Peak Demand Month` · `Peak Shortage Month` · `Months Trailing` from
   `Ref Seasonal Lag`.
3. Sort by `Months Trailing` descending, then Category.
4. **Interactions: NONE.**

**Interpretation note:** Warrington's Heating shortage peaks in **March**, not December. The
project's original assumption was wrong and was corrected from the data (D-20). Two years gives one
observation of each seasonal cycle — this is a pattern, not a forecast.

## 11.9 P3-V7 — Evidence status panel

Three text boxes side by side inside a bordered container, x=540 y=604, 732×92.

**Column 1 — SUPPORTED** (heading in `#2A78D6`)
> Replenishment alignment and demand direction are **associated** with availability outcomes.
> Cover predicts availability strongly across six bands.
> Three availability measures diverge and must travel together.

**Column 2 — UNRESOLVED** (heading in `#D03B3B`)
> **Daventry** short-ships 2.60% of units in weeks when cover was adequate — 4–9× the other sites.
> Order lumpiness, customer mix, range mix and transfer activity were each tested and **none
> explains it**. **No cause is stated.**
> **Bristol's** shortfall peaks in March–April 2025 and fits **neither** the opening-ramp nor the
> replenishment-lag explanation. **No cause is stated.**

**Column 3 — REJECTED** (heading in `#898781`)
> **Stale policies cause poor availability** — rejected. Policies over 15 months old show a
> *lower* unmet rate: 6.03% vs 7.80%.
> **Review recency signals alignment** — rejected. Correlation −0.066, R² 0.0044; the oldest band
> is marginally the *best* aligned.
> **Policy age must not be used to target replenishment work** — it would select close to randomly.

> ### ⚠ Policy age appears on Page 3 only here
> Not as a slicer. Not as an axis. Not as a legend. Only inside the Rejected column, and as a
> descriptive tooltip field on P3-V4.

## 11.10 Slicers on Page 3

**Site** and **Category** only. **No policy-age slicer** — offering one would imply age is a
dimension worth exploring, which the analysis rejected twice.

P3-V2, P3-V5, P3-V6 and P3-V7 must have **all slicer interactions set to None** (Section 14).

## 11.11 Page 3 Validation Checklist

- [ ] K13 3.52% · K14 5.05% · K15 7.71% · K16 £1,027,629 with ▲ badge
- [ ] All three availability measures appear together in P3-V1; none appears alone
- [ ] K17 does not exist
- [ ] P3-V1 axis reads "three distinct availability measures"
- [ ] P3-V2 shows 46.70% for the under-2-weeks band and does not move under slicers
- [ ] P3-V3 "broadly flat" row is annotated as the calibration set
- [ ] P3-V4 carries the asymmetry caption
- [ ] P3-V5 is labelled "Partially supported" and states the 40-position / 31-at-Daventry caveat
- [ ] P3-V6 shows Heating peaking March, not December
- [ ] P3-V7 has all three columns and assigns **no cause** to Daventry or Bristol
- [ ] Policy age is not a slicer, axis or legend anywhere on the page

---

# 12. Pages 4a and 4b — Supplier & Sourcing Performance

**Objective.** Show the reliability / lead time / price / inventory trade-off without licensing
either "importers are bad" or "cut importers".

**This was one page and is now two.** The single-page layout below it gave the bottom row 112px,
which cannot hold a scatter chart — P4-V6, V7 and V8 were readable only in focus mode, and nobody
reviewing a portfolio opens focus mode (style guide §7). It also answered two questions on one
page. Both pages are 1280 × 720; copy the furniture to each.

**Page 4a — `Supplier Reliability & Lead Time`**

```
y=56   KPI strip — K18–K21          200×96,  x=24, 224, 424, 624
y=168  P4-V1 On-time by supplier    616×240, x=24
y=168  P4-V2 Type trend + LOO       616×240, x=664
y=424  P4-V3 Meridian               400×230, x=24
y=424  P4-V4 Lead-time by type      400×230, x=440
y=424  P4-V5 Receiving site         392×230, x=856
y=660  Site-effect note            1232×28,  x=24
```

**Page 4b — `Sourcing Economics`**

```
y=56   KPI strip — K22, K23         240×96,  x=24, 288
y=168  P4-V6 Minimums               616×240, x=24
y=168  P4-V7 Dual-source scatter    616×240, x=664
y=424  P4-V8 Buy-ahead              616×200, x=24
y=424  V7 trade-off caption         616×200, x=664
```

**What moves where.** K18–K21 and V1–V5 stay together on 4a — they are all reliability and timing.
K22 and K23 move to 4b, where the flow-versus-level distinction sits beside the minimum-order and
dual-source evidence it belongs with. The scatter goes from 400×112 to 616×240, which is the only
change that makes it a usable chart rather than a smear.

## 12.1 The authoritative supplier type — read before building

Three fields in the model are called `supplier_type`, and one more looks similar. **They are not
all the same thing.**

| Field | What it describes | Grain | Rows |
|---|---|---|---|
| `Dim Supplier[supplier_type]` | The supplier's type | Supplier | 30 |
| `Fact Supplier Trend[supplier_type]` | Same attribute, reached via the purchase order | Type × half-year | 16 |
| `Detail Purchase Structure[supplier_type]` | Same attribute, on purchase lines | Purchase line | 2,063 |
| `Fact Opportunity[sourcing_last_used]` | **The type of source that last replenished a shelf position** | SKU × site | 515 |

**The first three are the same attribute.** All resolve to `supplier.supplier_type` via
`purchase_order.supplier_code`. They differ only in population.

**The fourth is a different concept entirely.** `sourcing_last_used` is a **position attribute**,
not a supplier attribute. It carries D-18 — the rule that minimum order quantities and lead times
belong to the source **actually used on the most recent receipt**, not the nominated primary
source. That rule reversed a headline conclusion: excess attribution moved from 76% UK-manufacturer
to **82% Far East importer**.

### The rule for this page

**Use `Dim Supplier[supplier_type]` for the Page 4 slicer.** Never `sourcing_last_used`.

Using `sourcing_last_used` as a supplier filter would silently answer a different question — "what
kind of source last touched this shelf" rather than "which suppliers are we assessing".

## 12.2 KPI tiles K18–K23

K18–K20 read **columns** from `Fact Supplier Network` (1 row), not measures.

| # | Label | Field | Basis tag | Expected |
|---|---|---|---|---|
| K18 | On time, first receipt | `Fact Supplier Network[on_time_first_receipt_pct]` | n = 3,766 | 89.8% |
| K19 | On time, all receipts | `Fact Supplier Network[on_time_all_receipts_pct]` | n = 4,241 | 80.1% |
| K20 | OTIF, line complete | `Fact Supplier Network[otif_pct]` | n = 3,768 | 79.1% |
| K21 | Split delivery rate | `Fact Supplier Network[split_delivery_rate_pct]` | 537 of 4,853 receipts | 11.1% |
| K22 | Minimum-order increment bought 2025 | *(text card)* | **flow** — twelve months | £995,659 |
| K23 | Average incremental cycle stock | *(text card)* | **level** — derived from the flow | £497,830 |

For K18–K21, drag the column into a **Card**; Power BI will offer **Sum** — change it to
**Minimum**. `Fact Supplier Network` has exactly one row, so Minimum, Maximum and Average all
return the same value; Minimum is the one that fails visibly if a second row ever appears.

> **Not "First".** Power BI offers First only for text and date fields. A numeric column's
> aggregation list is Sum / Average / Minimum / Maximum / Count / Count (Distinct) / Standard
> deviation / Variance / Median.

For K22 and K23, use a **Card** with a text box, or a text box alone with the figure typed — these
come from `analyse_17` §2 and §4 and no imported table exposes them as a single value.

> ### ⚠ K18–K20 must be displayed together
> They differ by **ten points**. Quoting the first-receipt figure alone hides every one of the 537
> split deliveries (D-07).

> ### ⚠ K22 and K23 must never be added
> One is twelve months of purchasing (a **flow**); the other is a standing level at an instant.
> Different clocks (D-29).

## 12.3 P4-V1 — "Reliability spreads 34 points within the importer type alone"

1. **Table**, x=24 y=160, 616×200. Source `Fact Supplier Delivery`.
2. Columns in order: `Dim Supplier[supplier_name]` · `Dim Supplier[supplier_type]` ·
   `n_first_measurable` · `on_time_first_receipt_pct` · `n_all_measurable` ·
   `on_time_all_receipts_pct` · `n_lines_measurable` · `otif_pct` · `split_delivery_rate_pct` ·
   `cell_note`
3. Sort by `otif_pct` **ascending** (worst first).
4. **Conditional formatting → Data bars** on the three rate columns.
5. **Mute thin cells:** click `supplier_name` → dropdown → **Conditional formatting → Font color**
   → **Format style: Rules** → based on `cell_note`, "contains" `thin cell` → `#898781`.

> ### ⚠ The n columns are not decoration
> A 62.5% on-time rate on 40 receipts and one on 400 are different claims. Rows flagged `thin cell`
> carry **no interpretation** (D-15).

## 12.4 P4-V2 — "The importer decline is one supplier, not a category"

**The most important analytical guard on this page.**

1. **Line chart**, x=664 y=160, 616×200.
2. **X-axis:** `Fact Supplier Trend[order_half_year]`
3. **Y-axis:** `Fact Supplier Trend[on_time_first_receipt_pct]` (aggregation **Average** — one row
   per type per half-year, so average returns the row value)
4. **Legend:** `Fact Supplier Trend[supplier_type]`
5. **Now add the leave-one-out series.** Two options:
   - **Preferred:** build a second, transparent-background line chart directly on top, sourced from
     `Ref Meridian Trend` filtered to `Series = "Importers excluding Meridian"`, with a **dashed**
     line style, and align it precisely over the first.
   - **Simpler:** place `Ref Meridian Trend` in its own small line chart immediately beside P4-V2,
     titled `Importers excluding Meridian`.
6. Y-axis title `On time, first receipt (%)`. Legend on, bottom.
7. **Interactions with the supplier-type slicer: NONE.**

**Expected:** importers as measured 83.6% → 77.8% → 73.1% → **56.8%**. Excluding Meridian:
72.9% → 64.3% → 66.7% → **65.9%** — flat to improving.

> ### ⚠ Do not do this
> **Do not present "Far East importers are getting worse".** The type-level decline is one
> supplier. Without the leave-one-out series visible, this chart states a **rejected conclusion**
> (D-26). The dashed line is not decoration.
>
> **Do not filter this visual to one supplier type** — the whole purpose is the comparison.

## 12.5 P4-V3 — "Meridian fell 49.5 points in two years"

1. **Line chart**, x=24 y=372, 400×200. Source `Ref Meridian Trend`, filtered to
   `Series = "Meridian Pacific"`.
2. X-axis `Half Year`; Y-axis `On Time Pct`.
3. Add a reference/annotation for the network rate, or include `Series` as legend and show both.
4. **Data labels** On. Annotate the 2025H2 point.
5. **Interactions: NONE.**

**Subtitle — required, not a tooltip:**
> The measurable window closes 2025-09-30 (D-14). 80% of importer lines ordered after that date had
> not arrived by the end of the data, so **45.5% is the last trustworthy reading, not the current
> state**.

**Expected:** 95.0% → 93.9% → 79.4% → 45.5%, on n = 100 / 82 / 68 / 33.

## 12.6 P4-V4 — "Importers quote 55 days and deliver in 78"

1. **Table**, x=440 y=372, 400×200. Source `Fact Cycle Time By Type`.
2. Columns: `supplier_type` · `n_first_receipts` · `quoted_lead_time_days` · `median_cycle_days` ·
   `p25_cycle_days` · `p75_cycle_days` · `iqr_days` · `p90_cycle_days` · `longest_cycle_days` ·
   `stddev_days` · `median_overrun_vs_quoted_days`
3. All numeric columns: aggregation **Don't summarize** — **not Sum, not Average**. Click the ▼
   beside each field in the **Columns** well to set it. This shows each row's own value, so a table
   bound to the wrong source gives the wrong row count instead of a plausible single number.
4. **Interactions: set ALL to None.**

**Expected:** UK Manufacturer quoted 7 / median 8 / longest 17 · Far East Importer quoted 55 /
median **78** / longest **166** / sd 12.5.

> ### ⚠ Percentiles must never be aggregated
> A median of medians is not a median. These values are valid **only** at the row's own grain. If a
> slicer could re-aggregate them, disable the interaction. Setting aggregation to **Sum** would give
> nonsense in the hundreds.

## 12.7 P4-V5 — "Livingston's raw overrun is five times its fitted site effect"

1. **Table**, x=856 y=372, 392×200. Source `Fact Cycle Time By Site`.
2. Columns: `warehouse_code` · `n_first_receipts` · `median_cycle_days` ·
   `median_overrun_vs_quoted_days`. Aggregation **Don't summarize**.
3. **Interactions: NONE.**
4. **Add an annotation text box beneath:**

> Naive marginals attribute **+10.1 days** to Livingston; the alternating two-way fit attributes
> **+1.8** (D-27). The raw column overstates by more than five times. **This is association, not
> causation** — the dataset cannot show the Monday goods-inwards batch *causes* the delay.

Both numbers must appear. Showing only the raw figure would charge a Livingston process for a
supplier's lead time.

## 12.8 P4-V6 — "On 99.3% of importer lines the supplier's minimum, not demand, set the quantity"

1. **Clustered column chart**, x=24 y=584, 400×112.
2. **X-axis:** `Detail Purchase Structure[supplier_type]`
3. **Y-axis:** `[Minimum Binds %]` and `[Ordered At Minimum %]`
4. Y-axis title `Share of 2025 purchase lines (%)`, from zero. Data labels On, legend On.
5. **Interactions with the supplier-type slicer: NONE** (this is the type comparison itself).
   Site and category slicers **do** apply via R14/R15.

**Expected:** Far East Importer 98.3% / 99.3% · UK / EU Distributor 6.9% / 10.5% · UK Manufacturer
0% / 0% · Small Specialist 0% / 0%.

**Interpretation note:** this is a **flow** measure over twelve months of purchasing. Never compare
it with, or add it to, Page 2's standing stock figures. Put the pipeline premium (£276,224 across
134 dual-source positions) in the tooltip as separate context.

## 12.9 P4-V7 — "The cheaper source is a Far East importer in all 60 cases"

1. **Scatter chart**, x=440 y=584, 400×112. Source `Detail Dual Source`.
2. **X-axis:** `dear_premium_pct` (aggregation **Average** or **Don't summarize**)
3. **Y-axis:** create the MOQ ratio inline — drag `cheap_moq` to Y and `dear_moq` to Tooltips, or
   simply use `cheap_moq` on Y with `dear_moq` in the tooltip. **Do not create a new measure** —
   the count must stay at 16.
4. **Values (the point identity):** `Detail Dual Source[sku]`
5. **Size:** `cheap_units`
6. **Legend:** `Detail Dual Source[cheap_supplier_type]`
7. Points ≥ 8px. X-axis title `Premium on the dearer source (%)`.

> **Why the legend is `cheap_supplier_type` and not category.** The style guide caps scatter at
> three colour series; category would give eight. And `cheap_supplier_type` resolves to **one
> series** — because across all 60 SKUs the cheaper source is a Far East importer **every single
> time**. That single-colour legend *is* the finding.

**Mandatory caption beneath the visual:**

> Annualised, the price saving from the cheaper source is **£492,020** against **£604,231** of
> one-off working capital — net **+£359,089** at 22%. **Re-sourcing away from importers to release
> capital would forfeit more than it releases.**

> ### ⚠ Do not present importer reduction as a recommendation
> The trade-off runs the other way. Cheaper unit price is bought with working capital, and cutting
> the working capital destroys the larger saving.

## 12.10 P4-V8 — "The February buy-ahead paid for itself a hundred times over"

1. **Table** or three cards, x=856 y=584, 392×112. Source `Ref Buy Ahead`.
2. Columns: `Component` · `Value` · `Basis`.
3. **Interactions: NONE.**

**Expected:** Price saving £146,490 · Residual **£6,971 (upper bound)** · Net **+£145,148**.

> ### ⚠ Mandatory
> This decision was **economically successful** and must **not** be classified as excess inventory
> (D-30). Its residual bound is already carved out of every Page 2 tier (D-38), so it cannot be
> double counted.
>
> Related context for the tooltip: the like-for-like Arden price rise reproduces at a median
> **+18.2%** across 57 SKUs. The raw before/after comparison is invalid because the SKU mix changed
> (D-28).

## 12.11 Slicers on Pages 4a and 4b

**Supplier type** — bound to `Dim Supplier[supplier_type]` — and **Category**.

A **Supplier** slicer is optional. If you add it:
- It will **not** filter `Fact Supplier Trend`, `Detail Purchase Structure` or `Detail Dual Source`
- It will offer **one supplier name that blanks every visual** — the 30th supplier placed no
  measurable purchase in the window

**No site slicer** as a primary control. Site appears only in P4-V5, which is deliberately a
process view.

## 12.12 Pages 4a and 4b Validation Checklist

- [ ] K18 89.8% · K19 80.1% · K20 79.1% · K21 11.1%, all displayed together
- [ ] K22 and K23 carry `flow` and `level` tags and are never summed
- [ ] P4-V1 shows n columns; thin-cell rows are muted
- [ ] **P4-V2 shows the leave-one-out series** — without it the visual states a rejected conclusion
- [ ] The supplier-type slicer does **not** affect P4-V2 or P4-V6
- [ ] P4-V3 carries the 2025-09-30 window caveat in its subtitle
- [ ] P4-V4 reads `Fact Cycle Time By Type` (**4 rows**); aggregations are **Don't summarize**, never Sum or Average; all interactions None
- [ ] P4-V5 shows both +10.1 and +1.8 and says "association, not causation"
- [ ] P4-V7 legend is `cheap_supplier_type`, resolving to one series
- [ ] P4-V7 carries the £492,020 / £604,231 / £359,089 caption
- [ ] P4-V8 presents the buy-ahead as net positive
- [ ] No visual or title says "Far East importers are getting worse"
- [ ] No visual uses `sourcing_last_used` as a supplier filter

---

# 13. Page 5 — Site Investigations & Decision Watchlist

New page, rename `Site Investigations & Decision Watchlist`, 1280 × 720, copy the furniture.

**Objective.** Let leadership compare sites and reach the two unresolved investigations without
either being softened into a conclusion.

**This page intentionally contains unresolved findings.** That is a feature. A dashboard that
explains everything has usually explained something it cannot support.

```
y=56   Dynamic title bar                1232×40,  x=24
y=104  KPI strip — 6 context tiles      200×88
y=200  P5-V1 Site scorecard             760×200,  x=24
y=200  P5-V2 Opportunity by site        472×200,  x=800
y=412  P5-V3 Position watchlist         1232×180, x=24
y=604  P5-V4 Unresolved Constraints     1232×92,  x=24
```

## 13.1 Dynamic title bar

1. **Card** visual, x=24 y=56, 1232×40.
2. Field: `[Dynamic Insight Title]`.
3. **Format → Callout value** → 16pt Semibold, left-aligned. **Category label** Off.

**Expected, no filter:** `All four warehouses: £468,897 identified (27.4% of closing stock)`
**Filtered to Bristol:** the same pattern plus `▲ Unresolved service constraint — see watchlist`

## 13.2 Context KPI tiles

Six tiles that respond to the site slicer: average inventory `[Inventory Value]` · turns
`[Inventory Turns]` · DIO `[Days Inventory Outstanding]` · line fill (use
`1 - [Lines Short Rate %]` inline, or show `[Lines Short Rate %]` labelled as lines short) ·
unmet value `[Unmet Demand Value]` (▲ upper bound) · working capital
`[Selected Opportunity Value]` (one-off).

Add a **seventh element**: a Card bound to `[Unresolved Constraint Text]`, spanning wider, which
stays blank for Warrington and Livingston.

## 13.3 P5-V1 — "Livingston's 2.84 turns survive every correction; Daventry's 4.68 does not"

1. **Matrix**, x=24 y=200, 760×200.
2. **Rows:** `Dim Warehouse[warehouse_name]`
3. **Values:** `[Inventory Value]` · `[Stock Value at Closing]` · `[Inventory Turns]` ·
   `[Days Inventory Outstanding]` · `[Closing Zero Rate %]` · `[Any Zero Day Rate %]` ·
   `[Lines Short Rate %]` · `[Unmet Demand Value]` · `[Selected Opportunity Value]` ·
   `[Selected Annual Holding Cost]`

**Expected:** DAV £996,883 / 4.68 / 78.0 · LIV £473,539 / 2.84 / 128.5 · WAR £366,299 / 5.63 /
64.8 · BRS £207,258 / 7.13 / 51.2.

> ### ⚠ Mandatory note — place it prominently, not in a tooltip
> **Do not rank sites on raw turnover.** 145 of 250 SKUs are stocked only at Daventry. On the range
> all four sites carry, Daventry turns **6.82** — second only to Bristol. Two valid range-mix
> corrections **disagree** (common-basket moves Bristol +0.33; mix-standardisation +1.43) and the
> disagreement is itself the finding (D-23). Livingston's 2.84 is the figure that survives every
> correction.

## 13.4 P5-V2 — "More than half the opportunity sits at the two constrained sites"

1. **Stacked column chart**, x=800 y=200, 472×200.
2. **X-axis:** `Dim Warehouse[warehouse_name]`
3. **Y-axis:** `[Selected Opportunity Value]`
4. **Legend:** `Fact Opportunity[opportunity_mechanism]`, coloured per §8.3.
5. From zero. Data labels On.
6. **Add constraint markers:** Insert → Text box `▲` in `#D03B3B`, 14pt, positioned above the
   Daventry and Bristol columns.

**Expected:** DAV £128,749 · LIV £127,882 · BRS £123,686 · WAR £88,579. **DAV + BRS = £252,435 =
53.8%.**

> The `▲` glyph carries the meaning alongside the colour, so a colour-blind reader is not misled.

## 13.5 P5-V3 — Position watchlist

1. **Table**, x=24 y=412, 1232×180. Source `Fact Opportunity`.
2. **Visual-level filter:** `working_capital_gbp` → **is greater than** `0`.
3. Columns: `opportunity_mechanism` · `sku` · `product_name` · `Dim Warehouse[warehouse_name]` ·
   `category_name` · `sourcing_last_used` · `minimum_in_weeks_of_demand` · `quantity_on_hand` ·
   `position_stock_value_gbp` · `releasable_units` · `working_capital_gbp` ·
   `annual_holding_cost_gbp` · `cover_weeks` · `demand_direction` ·
   `reorder_point_alignment_ratio` · `source_reference`
4. Sort by `working_capital_gbp` **descending**.
5. This page is the **drill-through target** — configured in Section 15.

> ### ⚠ Do not hide the service_consequence field
> Add it to the **Tooltips** well along with `unresolved_service_constraint`. It is the reason each
> row is **not free money**.

## 13.6 P5-V4 — Unresolved Constraints / Further Investigation

**A first-class section, not a footnote.** Two bordered panels plus a shared conclusion, x=24 y=604,
1232×92. Border `#D03B3B` 1px, fill `#F9F9F7`.

### Panel 1 — DAVENTRY

> **DAVENTRY — service anomaly, unresolved**
>
> Daventry fails to supply **2.60% of units in weeks when inventory cover was adequate** — four to
> nine times the other sites (Livingston 1.20%, Bristol 0.54%, Warrington 0.30%). 33 short weeks,
> **£68,451** of unmet demand from positions that were **not short of stock**.
>
> The anomaly survives: range-mix correction · common-basket comparison · stock-depth controls ·
> customer-mix testing · transfer-activity testing · order-lumpiness testing (demand in Daventry's
> short weeks runs 5.45× normal, but Livingston's runs 4.73× with a fifth of the shortfall rate).
>
> **No cause is stated.** Investigation belongs outside this dataset: goods-out picking accuracy,
> allocation logic when orders compete for the same stock, stock accuracy between system and bin,
> and cut-off timing.
>
> **Constrains:** £128,749 of identified opportunity sits at Daventry. *(D-24, D-39)*

### Panel 2 — BRISTOL

> **BRISTOL — March–April shortfall, unresolved**
>
> Bristol's unmet demand peaks in March and April 2025.
>
> The pattern fits: **not** a simple opening-ramp explanation — the site opened 1 July 2024 and its
> worst months are eight months later, not its first · **not** the general replenishment-lag
> pattern cleanly — its peak does not sit two months after a Bristol demand peak · **no** supported
> supplier-delay explanation — Bristol's Monday-booking share is the lowest in the network at 14.3%.
>
> **No cause is stated.**
>
> **Constrains:** £123,686 of identified opportunity sits at Bristol, which shows **59.1% of its
> closing stock as releasable — the highest share in the network — while serving worst at 89.23%
> line fill.** *(D-25, D-39)*

### Shared conclusion

> **No broad inventory reduction is recommended at either site until the service behaviour is
> understood.** Acting on the apparent overstock without explaining the service failure risks
> converting a capital gain into a service loss at the sites least able to absorb one. Clearing
> discontinued stock is safe at both, because there the demand claim is definitional.
>
> **These are investigation priorities, not failed analyses.**

## 13.7 How to communicate unresolved status visually

| What to show | How |
|---|---|
| **Known evidence** | Bullet the measured figures — 2.60%, 33 weeks, £68,451 — in normal text |
| **Rejected explanations** | List them with the word "survives" or "not", in secondary text `#52514E` |
| **Unresolved status** | The `#D03B3B` border and the `▲` glyph on P5-V2, plus the bold **"No cause is stated"** |
| **Recommended investigation** | The specific outside-the-dataset checks, in normal text |

> ### ⚠ Do not do this
> **Do not create a "likely cause" field, a "probable driver" column, or a RAG status implying
> diagnosis.** No such field exists in any view and none may be built in DAX. Do not paraphrase the
> panel text — the wording deliberately assigns no cause.

## 13.8 Slicers on Page 5

**Site** · **Category** · **Opportunity mechanism** (`Fact Opportunity[opportunity_mechanism]`) ·
**Holding rate** (`Param Holding Rate[Label]`, default 22%).

**P5-V4 must have all slicer interactions set to None.** The text is fixed and must never appear to
change under a filter.

## 13.9 Page 5 Validation Checklist

- [ ] Dynamic title updates with the site slicer and says "identified", never "available"
- [ ] Selecting Bristol or Daventry adds the `▲ Unresolved service constraint` flag
- [ ] Selecting Warrington or Livingston shows no flag and blanks the constraint card
- [ ] P5-V1 carries the "do not rank on raw turnover" note prominently
- [ ] P5-V2 shows `▲` markers on Daventry and Bristol
- [ ] P5-V2 columns total £468,897 with no filters
- [ ] P5-V3 sorted by working capital descending; `service_consequence` in the tooltip
- [ ] P5-V4 assigns **no cause** to either site
- [ ] P5-V4 does not respond to any slicer
- [ ] No field named cause, driver, reason or root cause exists

---

# 14. Slicers, Filters and Interactions

## 14.1 Slicer placement by page

| Page | Slicers | Deliberately absent |
|---|---|---|
| 1 Executive Overview | Site, Category | Supplier (no relationship), Product (blanks the cards), Date (fixed period) |
| 2 Inventory & Working Capital | Site, Category, **Holding rate** | Product, Supplier |
| 3 Availability & Replenishment | Site, Category | **Policy age** — would imply age is worth exploring |
| 4a Supplier Reliability & Lead Time | **Supplier type** (`Dim Supplier[supplier_type]`), Category | Site as a primary control |
| 4b Sourcing Economics | **Supplier type** (`Dim Supplier[supplier_type]`), Category | Site as a primary control |
| 5 Site Investigations | Site, Category, Opportunity mechanism, Holding rate | Supplier |

## 14.2 Setting Edit Interactions

1. Click the **source** visual (the slicer, or the chart doing the filtering).
2. **Format** ribbon (top) → **Edit interactions**.
3. Small icons appear on every other visual: **filter (funnel)**, **highlight (bar chart)**,
   **none (⊘)**.
4. Click the icon you want on each target visual.
5. Click **Edit interactions** again to exit.

## 14.3 The complete interaction restriction list

Set the **⊘ None** icon for each of these:

| Page | Source | Must NOT affect |
|---|---|---|
| 2 | Site slicer | **P2-V3** (ABC Pareto — `Detail SKU Value` has no site column) |
| 2 | All slicers | **P2-V5** (static exposure comparison) |
| 3 | All slicers | **P3-V2**, **P3-V5**, **P3-V6**, **P3-V7** |
| 4 | **Supplier-type slicer** | **P4-V2** (destroys the type comparison), **P4-V6** (type comparison itself) |
| 4 | All slicers | **P4-V3**, **P4-V4**, **P4-V5**, **P4-V8** |
| 5 | All slicers | **P5-V4** (unresolved panel) |

> ### ⚠ Page 4 supplier filtering — the trap
> `Fact Supplier Trend` and `Detail Purchase Structure` have **no supplier relationship** by design.
> If you filter the supplier-type slicer to "Far East Importer", P4-V2 and P4-V6 would either not
> respond (confusing) or, if you "fixed" it with a bi-directional relationship, would show a
> single-type view that **destroys the very comparison the visual exists to make**.
>
> The answer is not to make them respond. It is to **set their interaction to None** and let them
> always show all four types.

## 14.4 Synchronising slicers

The Site and Category slicers should hold their selection as you move between pages.

1. **View** ribbon → tick **Sync slicers**.
2. Click the Site slicer on Page 1.
3. In the **Sync slicers** pane, tick **Sync** for Pages 1, 2, 3 and 5. **Leave Page 4 unticked**
   (no site slicer there).
4. Tick **Visible** only on the pages where the slicer should appear.
5. Repeat for Category across all six pages.
6. **Do not sync the holding-rate slicer** — Pages 2 and 5 only, and both default to 22%.

## 14.5 Resetting filters

1. **Insert** ribbon → **Buttons** → **Blank**.
2. Position it in the header, beside the slicers.
3. **Format → Button → Style → Text** → `Reset filters`.
4. **Format → Button → Action** → On → **Type: Bookmark** → select a bookmark you capture with all
   slicers cleared (see Section 15.5 for how to capture a bookmark).

---

# 15. Tooltips and Drill-Through

## 15.1 Creating a report-page tooltip

Do this once, then repeat for each tooltip page.

1. Click **+** to add a new page. Rename it `TT Site Inventory`.
2. Click blank canvas → **Format** pane → **Canvas settings** → **Type: Tooltip**
   (320 × 240 automatically).
3. **Page information** → **Allow use as tooltip** → **On**.
4. Right-click the page tab → **Hide page**.
5. Add the visuals or cards you want to appear on hover.

## 15.2 The seven tooltip pages

| Page name | Attached to | Contents |
|---|---|---|
| `TT Site Inventory` | P1-V1a, P2-V1, P5-V1 | Average stock · closing stock · closing vs average % · turns · DIO · holding cost at 22% · note: *"Inventory is the mean of 52 weekly snapshots, never closing stock (D-10)."* |
| `TT Site Service` | P1-V1b | Demand lines · lines not in full · line fill % · unmet units · unmet value · note: *"Order-date basis, calendar 2025. Unmet demand is an upper bound — substitution is not modelled."* |
| `TT Opportunity Tier` | P1-V2, P1-V3, P2-V4, P5-V2 | Tier · positions · stock value · working capital · annual holding cost · `service_consequence` · `source_reference` · note: *"Capital is one-off; holding cost is annual. Never added."* |
| `TT Three Measures` | P3-V1 | All three rates with numerators and denominators · `snapshot_understatement_factor` · note: *"Weekly snapshots miss stockouts that clear before Sunday. ISO-week basis for measures 1–2, calendar-year for measure 3; the £2,591 difference is the 133 lines dated 29–31 December (D-13, D-22)."* |
| `TT Supplier Cell` | P4-V1 | All three on-time measures with denominators · `n_not_measurable` · `n_outside_window` · `cell_note` · note: *"Cells under ten observations carry no interpretation (D-15)."* |
| `TT Cycle Distribution` | P4-V4 | n · quoted · median · mean · p25/p75/p90 · longest · stddev · note: *"Percentiles are valid only at this grain and are never aggregated."* |
| `TT Position` | P5-V3 | `service_consequence` · `unresolved_service_constraint` · `source_reference` in full |

## 15.3 Assigning a tooltip to a visual

1. Click the target visual (for example P1-V1a).
2. **Format** pane → **General** → **Tooltips**.
3. **Type:** `Report page`
4. **Page:** select `TT Site Inventory`.

**Test it:** hover over a bar. The tooltip page should appear. If it does not, check that *Allow use
as tooltip* is On and the page is set to **Tooltip** canvas type.

## 15.4 Default tooltips everywhere else

Every visual without a report-page tooltip must still have a default tooltip with useful fields.
Drag relevant columns into the visual's **Tooltips** well. **Do not turn tooltips off** — an
interactive dashboard that ignores hover feels broken.

## 15.5 Drill-through configuration

**Set up Page 5 as the target:**

1. Go to the Page 5 tab.
2. Click blank canvas.
3. In the **Filters** pane, find the **Drill through** section.
4. Drag `Dim Warehouse[warehouse_name]` into **Add drill-through fields here**.
5. Drag `Fact Opportunity[opportunity_mechanism]` in as well.
6. Drag `Dim Product[sku]` in as well.
7. Set **Keep all filters** to **On**.
8. Power BI automatically adds a **back arrow** button top-left. Leave it — it is your Back
   navigation.

**Where drill-through is used:**

| From | To | Carries |
|---|---|---|
| P1-V1a / P1-V1b site bar | Page 5 | Site |
| P1-V2 tier segment | Page 2 | Mechanism |
| P2-V4 SKU row | Page 5 | SKU + site |
| P5-V2 site column | P5-V3 | Site + mechanism |

**Test it:** right-click a Daventry bar on Page 1 → **Drill through** → **Site Investigations**.
Page 5 should open filtered to Daventry, with the filter card visible and the back arrow present.

**Where drill-through must NOT be used:**

| Not from | Why |
|---|---|
| Any `Ref` static visual (P2-V5, P3-V2, P3-V5, P3-V6, P4-V3, P4-V8) | No relationships — it would carry no filter and open an unfiltered page that looks filtered |
| P3-V7 evidence status panel | Text, not data |
| **P5-V4 unresolved panel** | Drilling from an unresolved finding into filtered data implies the filter explains it |
| P4-V4 lead-time distribution | Percentiles would be re-aggregated |
| P4-V2 type trend | `Fact Supplier Trend` has no dimension relationships |

## 15.6 The methodology overlay

1. Add a new page, rename `Methodology`, canvas 1280 × 720. **Hide the page.**
2. Add text boxes covering: the 22% rate derivation (6% capital, 8% storage, 3% service, 5% risk)
   and the note that **only the capital component has a primary source** (D-11) · the 20%/25%
   sensitivity · the list of upper bounds · the two clocks and the £2,591 boundary · the note that
   the 5% risk component comes from the published benchmark, **not** this dataset's 7.9% observed
   loss (D-12).
3. Add a **Back** button: Insert → Buttons → **Back**.
4. On each main page, select the `Methodology` header button → **Format → Action** → **On** →
   **Type: Page navigation** → **Destination: Methodology**.

## 15.7 Navigation rail

1. On Page 1, **Insert** → **Buttons** → **Navigator** → **Page navigator**. Position it y=676,
   height 30, spanning the width.
2. It auto-generates a button per visible page and stays in sync if you rename a page.
3. In **Format → Visual → Style**, set **On hover** and **On press** states — different fill and
   font colour.
4. Copy the navigator to all six pages (Ctrl-C, Ctrl-V).
5. Add a separate **Home** button (Insert → Buttons → Blank, Action → Page navigation → Executive
   Overview).

---

# 16. Full Dashboard Validation

Work through in order. Record results in `powerbi/VALIDATION_LOG.md`.

## 16.1 Data validation

- [ ] **17 queries** loaded; **15 distinct PostgreSQL objects** plus 7 hand-entered tables
- [ ] Row counts: `Fact Inventory KPI` **32** · `Fact Availability` **32** · `Fact Opportunity`
      **515** · `Fact Supplier Delivery` **29** · `Fact Supplier Network` **1** ·
      `Fact Supplier Trend` **16** · `Fact Cycle Time` **29** · `Fact Cycle Time By Type` **4** ·
      `Fact Cycle Time By Site` **4** · `Detail SKU Value` **250** · `Detail Policy Alignment`
      **467** · `Detail Purchase Structure` **2,063** · `Detail Dual Source` **60**
- [ ] Dimensions: `Dim Warehouse` **4** · `Dim Category` **8** · `Dim Supplier` **30** ·
      `Dim Product` **250**
- [ ] Static: S1 **8** · S2 **6** · S3 **8** · S4 **8** · S5 **3** · S6 **8** ·
      `Param Holding Rate` **3**
- [ ] `grain_level` column removed from every fact
- [ ] `Fact Opportunity` distinct `(sku, warehouse_code)` = **515** — no duplicates
- [ ] Nulls preserved where documented: `sourcing_last_used` (8), `cover_weeks`,
      `discontinued_date`
- [ ] `holding_rate` reads **0.22**, not 0.0022
- [ ] **15 relationships**, all Many-to-one, Single, Active
- [ ] **R10 absent** — no `Detail SKU Value` ↔ `Dim Product` line, and no 1:1 relationship anywhere
- [ ] No relationship touches `Param Holding Rate` or any `Ref` table

## 16.2 Measure validation

Put each measure on a blank card with no filters:

| Measure | Expected | Source |
|---|---:|---|
| `Inventory Value` | £2,043,979 | `report_01` |
| `Inventory Turns` | 4.67 | `report_01` |
| `Days Inventory Outstanding` | 78.2 | `report_02` |
| `Lines Short Rate %` | 7.71% | `report_04` |
| `Closing Zero Rate %` | 3.52% | `report_04` |
| `Any Zero Day Rate %` | 5.05% | `report_04` |
| `Unmet Demand Value` | £1,027,629 | `report_04` |
| `Selected Opportunity Value` | £468,897 | `report_07` |
| `Selected Annual Holding Cost` | £103,157 | `report_07` |
| `Stock Value at Closing` | £1,711,042 | `report_07` |
| `Opportunity Share of Stock %` | 27.4% | `report_07` |
| `Unclassified Stock Value` | £835,219 | `report_07` |
| `Minimum Binds %` (importer) | 98.3% | `analyse_17` |
| `Ordered At Minimum %` (importer) | 99.3% | `analyse_17` |
| `Unresolved Constraint Text` | blank; text for DAV/BRS | `report_07` |
| `Dynamic Insight Title` | "All four warehouses: £468,897 identified (27.4%…)" | derived |

Additional committed figures to check on the pages:

- [ ] Cost of sales **£9,550,572** (add `cost_of_sales_gbp` to a card)
- [ ] Holding cost on total inventory **£449,675** at 22%
- [ ] Supplier on-time: **89.8% / 80.1% / 79.1%** — read as columns, **not** reconstructed
- [ ] Importer median cycle **78 days**, n **603**
- [ ] Tier capital sums: 87,478 + 303,558 + 70,755 + 7,106 = **468,897**
- [ ] Tier holding sums: 19,245 + 66,783 + 15,566 + 1,563 = **103,157**
- [ ] `_Measures` contains **exactly 16** measures

## 16.3 Interaction validation

- [ ] Site slicer changes Pages 1, 2, 3, 5 coherently
- [ ] Category slicer works on all six pages
- [ ] Site slicer does **not** change P2-V3
- [ ] Supplier-type slicer does **not** change P4-V2 or P4-V6
- [ ] All `Ref`-sourced visuals are inert under every slicer
- [ ] Holding-rate parameter: 20% → £93,779 · 22% → £103,157 · 25% → £117,225
- [ ] Holding-rate parameter does **not** change `[Selected Opportunity Value]`
- [ ] Drill-through works from P1-V1a, P1-V2, P2-V4, P5-V2
- [ ] The back arrow returns to the originating page
- [ ] All seven tooltip pages appear on hover
- [ ] Every visual has some tooltip
- [ ] Sync slicers hold Site and Category across pages
- [ ] Reset filters button clears all slicers

## 16.4 Analytical integrity validation

- [ ] **No visual, total or text adds `[Selected Opportunity Value]` to
      `[Selected Annual Holding Cost]`**
- [ ] £1,109,016 appears **only** on P2-V5, marked `✗ do not use`
- [ ] Every upper bound carries a **▲** badge: K6, K9, K16, tiers 2 and 4, the £6,971 residual
- [ ] Tier 1 labelled *Definitional*, tier 3 *Measured* — neither mislabelled
- [ ] **No text anywhere assigns a cause to Daventry's anomaly**
- [ ] **No text anywhere assigns a cause to Bristol's March–April shortfall**
- [ ] No field named cause, driver, reason or root cause
- [ ] Policy age is not a slicer, axis or legend on any page
- [ ] Review recency is not presented as causal
- [ ] The February buy-ahead is presented as **net positive**
- [ ] No visual or title says "Far East importers are getting worse"
- [ ] P4-V2 shows the leave-one-out series
- [ ] No site ranking on raw turnover without the range-mix warning
- [ ] **No invented targets or benchmarks anywhere** — no "vs target" on any KPI tile
- [ ] No visual recommends broad inventory reduction at Daventry or Bristol
- [ ] K17 / Unit Fill Rate does not exist
- [ ] ISO-week and calendar-year measures are labelled with their basis
- [ ] The £2,591 timing difference is stated in `TT Three Measures` and the methodology overlay

---

# 17. Troubleshooting Guide

## 17.1 PostgreSQL connection fails

**Symptoms:** *"Unable to connect to the database"*, *"connection refused"*, or a timeout.

**Likely causes and diagnosis:**
1. **Server field format.** Did you type `localhost:5432` with a **colon**? A comma is the SQL
   Server format and fails here.
2. **PostgreSQL is not running.** Test with a client (`psql`, pgAdmin, DBeaver). If that fails,
   Power BI is not the problem.
3. **Wrong port.** PostgreSQL defaults to 5432 but instances vary. Check your server config.
4. **Firewall.** If the server is not on your machine, port 5432 may be blocked.
5. **Credentials cached wrong.** **File → Options and settings → Data source settings** → find the
   PostgreSQL entry → **Clear permissions** → reconnect.

**Fix:** correct the connection string, then **Home → Transform data → Data source settings →
Change Source**.

## 17.2 A required view does not appear in the Navigator

**Symptom:** you expand `supply` and one of the four detail views is missing.

**Diagnosis:** run the §1.5 verification query. If it returns fewer than 4 rows, the view genuinely
does not exist.

**Cause:** the four detail views (`vw_sku_value_position`, `vw_policy_alignment`,
`vw_purchase_quantity_structure`, `vw_dual_source_gap`) are created by files in
`sql/04_analysis/`, **not** `sql/05_reporting_views/`. A database built only as far as Stage 5 will
not have them.

**Fix:** re-run the full 35-file pipeline per the README reproducibility block. Then in Power Query,
**Home → Refresh Preview**.

> **Do not substitute a static table for a missing view.** Approved decision 1 requires these to be
> imported.

## 17.3 A query returns an unexpected row count

**Symptom:** `Fact Inventory KPI` shows 45 or 96 rows instead of 32.

**Diagnosis:** click the query → look at the **Applied Steps** on the right. Is there a
**Filtered Rows** step? Click it and read the formula bar.

**Causes:**
- The grain filter was not applied.
- The filter used the wrong literal — remember `3 — ...` means different things in views 04, 05 and
  06.
- For `Fact Inventory KPI` at 96 rows: the merge matched more than one row per key, meaning you
  merged on only one column instead of both `warehouse_code` **and** `category_code`.

**Fix:** delete the offending step (✕ beside it) and redo it. For the merge, delete the merge steps
and repeat §4.1 Step D, ensuring **both** key columns show the small **1** and **2** markers.

## 17.4 A relationship cannot be created

**Symptom:** dragging one column onto another does nothing, or Power BI refuses.

**Causes and fixes:**
1. **Data types differ.** `warehouse_code` must be **Text** on both sides. Check in Power Query and
   fix the type there, not in the model.
2. **Trailing whitespace.** Rare with these views, but if suspected: in Power Query,
   **Transform → Format → Trim** on both key columns.
3. **A relationship already exists** between those tables. Power BI will make the new one inactive
   (dashed line). Check **Manage relationships**.
4. **The column is hidden.** Hidden columns can still be dragged in Model view — but if you deleted
   it, re-add it in Power Query.

## 17.5 A many-to-many relationship appears

**Symptom:** the Edit relationship dialog shows **Many to many (\*:\*)**.

**This is always a mistake in this model.** Every relationship here is Many-to-one.

**Diagnosis:** the "one" side has duplicate key values. Check: click the dimension in Table view,
click the key column header, and look for repeated values.

**Causes:**
- You dragged onto a **fact-to-fact** pair by accident (e.g. `Fact Availability` onto
  `Fact Inventory KPI`). Both have 32 rows with the same keys, so neither side is unique on one
  column alone.
- You imported a dimension unfiltered and it has more rows than expected.

**Fix:** delete the relationship. Confirm you are dragging **dimension → fact**. Never join two
facts directly — they connect *through* a shared dimension.

## 17.5a "There are ambiguous paths between X and Y"

**Symptom:** creating a relationship fails with, for example:

```
There are ambiguous paths between 'Fact Opportunity' and 'Dim Category':
'Fact Opportunity'->'Dim Product'->'Detail SKU Value'->'Dim Category'
and 'Fact Opportunity'->'Dim Category'
```

**What it means.** Power BI has found **two routes** for a filter to travel between the same two
tables and refuses to guess which one you meant. A model with only single-direction relationships
cannot produce this — so somewhere a relationship is **bidirectional**.

**The usual culprit is a hidden one-to-one relationship.** Power BI silently upgrades a
relationship to 1:1 when **both** sides are unique on the key, and **a 1:1 relationship is always
bidirectional — the Cross filter direction box is greyed out.**

**Diagnose:**
1. Go to **Model view**.
2. Read the error message — it names the path. The extra hop is the offender.
3. Look at each line on that path. A 1:1 shows **1 at both ends**; a bidirectional line shows
   **arrowheads at both ends**.
4. Double-click the suspect line. If **Cardinality** reads *One to one* and **Cross filter
   direction** is greyed out on *Both*, that is your problem.

**Fix:**
1. Right-click the offending line → **Delete** → confirm.
2. Re-create the relationship you were trying to add.

**In this project the known instance is R10** — `Detail SKU Value[sku]` → `Dim Product[sku]`, both
250 rows unique on `sku`. It was removed from the design (§6.6, D-41). **Do not recreate it.**

**If you find a different 1:1 relationship**, ask before deleting — it may be load-related rather
than a design error. Two tables at the same grain usually means one of them imported wrongly.

## 17.6 A slicer filters the wrong visual

**Symptom:** selecting a site changes a visual that should be static.

**Diagnosis:** click the slicer → **Format** ribbon → **Edit interactions**. Look at the icon on the
offending visual.

**Fix:** click the **⊘ None** icon on that visual. See the full list in §14.3.

**If the reverse happens** — a slicer should filter a visual and does not — **do not fix it by
switching a relationship to bi-directional.** That is the model telling you the grains differ.
Check §14.3: the visual may be deliberately inert.

## 17.7 The supplier-type slicer produces blank visuals

**Symptom:** you select a supplier in a Supplier slicer and every Page 4 visual goes blank.

**Cause:** one of the 30 suppliers in `Dim Supplier` placed **no measurable purchase** in the
window, so it appears in the slicer but matches no fact rows. `Fact Supplier Delivery` has 29 rows,
not 30.

**This is honest behaviour, not a bug.** Two options:
1. **Accept it** (recommended) — let the blank state show.
2. **Hide it:** slicer → **Format → Visual → Slicer settings → Options → Show items with no data**
   → Off. Or add a visual-level filter on the slicer.

**A different blank symptom:** selecting a supplier type leaves P4-V2 and P4-V6 unchanged. **That
is correct and deliberate** — their interactions are set to None (§14.3).

## 17.8 A percentage changes unexpectedly

**Symptom:** 7.71% becomes 771%, or 0.0771%.

**Cause:** the §4.6 divide-by-100 step was skipped, applied twice, or applied to `holding_rate`.

**Diagnosis:** Power Query → click the column → look for a **Divided Column** step in Applied Steps.
Count how many there are.

**Fix:** ensure exactly **one** divide-by-100 per `*_pct` column, and **none** on `holding_rate`
(which must read 0.22).

**A different cause:** you dragged a `*_pct` column into a visual and Power BI defaulted to **Sum**.
Change the aggregation to **Average** — or better, use the DAX measure, which recomputes from
numerator and denominator.

## 17.9 A DAX measure returns blank

**Symptom:** the card shows nothing.

**Diagnosis by measure:**
- **`Unclassified Stock Value` blank:** the tier string does not match. Em dashes (—) are easy to
  mistype as hyphens. **Copy the exact value from Table view.**
- **`Selected Annual Holding Cost` blank:** the `SELECTEDVALUE` fallback is missing, or
  `Param Holding Rate` did not load.
- **`Unresolved Constraint Text` blank with no filter:** **this is correct.** Two distinct
  constraints exist, so `COUNTROWS = 2` and the measure returns BLANK by design. Filter to one site.
- **Any measure blank:** check it references the right table name. Renaming a query after writing a
  measure breaks it — Power BI usually updates references, but not always.

**General fix:** click the measure, read the formula bar for a red squiggle, and hover it for the
error text.

## 17.10 The holding-rate parameter does not update visuals

**Symptom:** changing the slicer leaves `[Selected Annual Holding Cost]` unchanged.

**Diagnosis and fixes:**
1. **Is the slicer bound to `Param Holding Rate[Label]`?** If it is bound to `[Rate]`, the numbers
   0.2/0.22/0.25 appear — the measure still works, but confirm.
2. **Does the measure reference the right table?** `SELECTEDVALUE ( 'Param Holding Rate'[Rate], 0.22 )`
   — the table name must match exactly.
3. **Is the interaction disabled?** Click the slicer → Edit interactions → confirm the card shows
   **filter**, not **⊘**.
4. **Did you accidentally relate the parameter table?** It must be **disconnected**. Check Model
   view; delete any line touching it.

**If `[Selected Opportunity Value]` also moves:** you wired M8 to the parameter. It must not be.
Capital does not change with the holding rate.

## 17.11 A visual total does not match the committed result

**Symptom:** `[Inventory Value]` shows £8,175,917 instead of £2,043,979 — roughly 4×.

**Cause:** the `grain_level` filter did not apply, so network, site, category **and** cell rows are
all being summed.

**Fix:** Power Query → `Fact Inventory KPI` → confirm the **Filtered Rows** step exists and the
result is 32 rows. Re-apply if needed.

**Other mismatches:**
- **Turns near 150:** you summed `inventory_turns` instead of using M2.
- **A rate near 700%:** the divide-by-100 step is missing (§17.8).
- **Off by pennies:** you set a currency column to **Fixed Decimal Number**. Change it to **Decimal
  Number** in Power Query.

## 17.12 Opportunity tiers do not reconcile to £468,897

**Diagnosis, in order:**
1. **Row count.** `Fact Opportunity` must be **exactly 515**. More means a relationship is fanning
   it out.
2. **Duplicates.** In Table view, check no `(sku, warehouse_code)` pair appears twice.
3. **Tier 5.** Its `working_capital_gbp` must sum to **exactly 0**. If not, you filtered wrongly.
4. **A stray filter.** Check the **Filters** pane at report, page and visual level.
5. **The wrong measure.** Confirm you are using `[Selected Opportunity Value]`
   (`working_capital_gbp`), not `[Stock Value at Closing]` (`position_stock_value_gbp`). The latter
   gives £1,711,042.

**Tier values to check individually:** £87,478 · £303,558 · £70,755 · £7,106 · £0.

## 17.13 A static reference table behaves incorrectly

**Symptom:** P2-V5's bars change when you move a slicer, or a `Ref` visual goes blank.

**Causes:**
1. **A relationship was created.** Model view → check nothing touches the `Ref` table → delete any
   line.
2. **Interactions not disabled.** §14.3 → set **⊘ None**.
3. **Blank visual:** a page-level or report-level filter is applied to a field the `Ref` table does
   not have. Check the Filters pane and remove it.
4. **Wrong values:** you mistyped an Enter Data figure. **Home → Transform data**, click the query,
   click the **Source** step gear icon to reopen the grid and correct it.

## 17.14 When to stop rather than modify the analytical model

**Stop and ask** rather than changing anything if you find yourself about to:

- Write a new DAX measure not among the 16
- Add a calculated column that derives a business figure (the `Basis` column is the only approved
  one)
- Change a relationship to **bi-directional** cross-filter
- Modify a PostgreSQL view to make a visual easier
- Group, filter or aggregate a fact in Power Query beyond the documented grain filter
- Reconstruct an on-time numerator from a rounded percentage
- Add a target line or benchmark to any visual
- Write a "likely cause" for Daventry or Bristol
- Combine capital release and annual holding cost into one figure

**Each of these would break an approved analytical decision.** A dashboard that disagrees with its
own committed results is worse than one with a missing visual.

---

# 18. Final Pre-Portfolio Checklist

## Data model
- [ ] 15 PostgreSQL objects imported as 17 queries
- [ ] All row counts match §16.1
- [ ] 15 relationships, all Many-to-one / Single / Active
- [ ] R10 not present; no one-to-one relationship anywhere
- [ ] No bi-directional relationships
- [ ] `Param Holding Rate` and all six `Ref` tables disconnected
- [ ] `Inv02` and `Inv03` load-disabled
- [ ] Key columns hidden in facts, visible in dimensions
- [ ] No unused tables in the model

## DAX
- [ ] Exactly **16** measures, all in `_Measures`
- [ ] Every measure validated against its committed figure (§16.2)
- [ ] No `Unit Fill Rate %`
- [ ] No on-time / OTIF / percentile measure
- [ ] `Basis` is the only calculated column
- [ ] No measure named cause, driver, reason or root cause

## Page design
- [ ] All six pages at 1280 × 720
- [ ] Custom theme applied; stock theme not in use
- [ ] Segoe UI throughout
- [ ] **No dual-axis chart** (the Pareto exception noted in §10.5 aside)
- [ ] Every bar chart starts at zero
- [ ] Bars sorted by value except where order is inherent
- [ ] **Every visual title states a finding**, not a variable
- [ ] Axes labelled with units
- [ ] Legend for ≥2 series; direct labels where ≤4
- [ ] Meaning never depends on colour alone
- [ ] Scatter uses one colour series
- [ ] Shadows and borders off
- [ ] `n` stated wherever a segment is small
- [ ] Every page has header, footer and navigation

## KPI validation
- [ ] Average inventory **£2,043,979**
- [ ] Closing inventory **£1,711,042**
- [ ] COGS **£9,550,572**
- [ ] Turns **4.67**
- [ ] DIO **78.2**
- [ ] Holding cost on total inventory **£449,675**
- [ ] Availability **3.52% / 5.05% / 7.71%**
- [ ] Unmet demand **£1,027,629** with ▲ badge
- [ ] Supplier on-time **89.8% / 80.1% / 79.1%**
- [ ] Opportunity **£468,897**
- [ ] Annual holding cost **£103,157**; 20% **£93,779**; 25% **£117,225**
- [ ] Tier 5 unclassified **£835,219**

## Slicers
- [ ] Correct slicers on each page per §14.1
- [ ] All interaction restrictions from §14.3 applied
- [ ] Site and Category synced across pages
- [ ] Holding rate on Pages 2 and 5 only, defaulting to 22%
- [ ] Reset filters button works

## Tooltips
- [ ] All seven tooltip pages built and hidden
- [ ] Each assigned to its target visuals
- [ ] Every other visual has a default tooltip
- [ ] Methodology overlay reachable from every page

## Drill-through
- [ ] Page 5 configured as target with three fields
- [ ] Keep all filters On
- [ ] Works from all four approved sources
- [ ] Back arrow present
- [ ] **Not** enabled on any `Ref` visual, P3-V7, P5-V4, P4-V4 or P4-V2

## Analytical integrity
- [ ] Capital and holding cost never summed
- [ ] £1,109,016 appears once, marked as the error
- [ ] All upper bounds badged
- [ ] Daventry unresolved, **no cause stated**
- [ ] Bristol unresolved, **no cause stated**
- [ ] Policy age never causal
- [ ] Buy-ahead net positive
- [ ] No "importers are getting worse"
- [ ] No invented targets
- [ ] No broad inventory reduction recommended at DAV or BRS
- [ ] Every headline number traces to a committed result

## Portfolio presentation
- [ ] Every page rendered and **actually looked at** — no clipped labels, no overflow, no collisions
- [ ] Legible at 880px width
- [ ] **Six** screenshots captured at 2×, downscaled to ~1600px, PNG under 500 KB
- [ ] Named in `powerbi/screenshots/`:
      `01_executive_overview.png` · `02_inventory_working_capital.png` ·
      `03_availability_replenishment.png` · `04_supplier_reliability_lead_time.png` ·
      `05_sourcing_economics.png` · `06_site_investigations_watchlist.png`
- [ ] `.pbix` saved as `powerbi/calderfield_inventory_supply_chain.pbix`
- [ ] `powerbi/VALIDATION_LOG.md` completed
- [ ] Synthetic-data disclaimer visible on Page 1

**The final test:** can a stakeholder answer *"how are we doing, and what needs my attention?"*
within ten seconds of opening Page 1 — **without** concluding "cut inventory everywhere"?

---

*Build manual only. Derived from `docs/POWER_BI_DASHBOARD_SPEC.md` and
`docs/POWER_BI_IMPLEMENTATION_GUIDE.md`, which remain the authorities. No SQL, view, analysis file
or existing document was modified in producing this guide.*
