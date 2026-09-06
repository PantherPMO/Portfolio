# Power BI Implementation Guide — Project 02: Warehouse Inventory & Supply Chain Performance

> **Calderfield Trade Supplies Ltd is fictional and this dataset is synthetic.** This guide
> describes how to build a dashboard from completed analysis. It introduces no new findings, no
> new SQL and no new recommendations.

**Status:** Build preparation. No `.pbix` exists yet.
**Design source of truth:** `docs/technical/powerbi-dashboard-spec.md` (approved).
**Visual standards source of truth:** `_portfolio/STYLE_GUIDE.md` (inspected — see §0).
**Analytical source of truth:** 32 committed results in `analysis/query_results/`, decisions D-01
to D-40.

---

## 0. Style guide reconciliation — read this before anything else

`_portfolio/STYLE_GUIDE.md` was inspected (13,033 bytes, 240 lines). It **does** provide a
validated colour palette, so the "four semantic roles with no hues" position in the approved spec
now resolves onto real values.

It also contains **seven points where it conflicts with the approved specification**. Approved
decision 5 instructs me to follow the style guide, so each is resolved in the style guide's
favour. **Nothing in `powerbi-dashboard-spec.md` has been edited** — the reconciliation lives
here, and every deviation is named.

### C-1 · Dual-axis chart — **binding conflict, spec visual redesigned**

| | |
|---|---|
| **Style guide** | Hard Rule 1: *"**Never a dual-axis chart.** Two y-scales invites false correlation and is the single most common chart mistake. Two measures of different scale → two charts, small multiples, or index both to a common base."* |
| **Spec** | P1-V1 is *"Two-axis combination — clustered column (average inventory £, left axis) with a line and markers (lines short %, right axis)"* |
| **Resolution** | **P1-V1 is split into two adjacent charts sharing one category axis** (§7, Page 1). The style guide's own remedy is used verbatim. |

This is the most consequential of the seven, and the style guide is right on the substance: the
spec's own interpretation note already warned *"the two series must not be read as a correlation —
four points is not a relationship."* A dual axis invites exactly the reading the note forbids. Two
stacked charts make coexistence visible without implying a relationship.

### C-2 · Page size

| | |
|---|---|
| **Style guide** | §6: *"Consistent page size across projects: 1280×720"* |
| **Spec** | §5.1: 1600×900 |
| **Resolution** | **1280×720.** Portfolio consistency across the three Power BI projects outranks a per-project preference. Layout coordinates in §7 are given at 1280×720. |

### C-3 · KPI tile count

| | |
|---|---|
| **Style guide** | §5: *"**4–6 KPI tiles maximum.** More than six and none of them are key"* |
| **Spec** | Page 1 carries 7 cards (K1–K7); Page 4 carries 6 (K18–K23) |
| **Scope note** | Style guide §5 is headed *"For projects 06, 07 and 08"*, so it is not strictly binding on project 02. The principle is sound regardless. |
| **Resolution** | **Page 1 presents 5 primary tiles (K1–K5) plus a visually separated 2-tile opportunity group (K6, K7).** The spec already required K6/K7 to sit inside a bordered group captioned "One-off capital · Annual cost — never added". Rendering that group as a distinct panel rather than two more tiles in the strip satisfies both documents. Page 4's 6 tiles are within the limit. |

### C-4 · KPI comparison element — **cannot be satisfied, and the reason is analytical**

| | |
|---|---|
| **Style guide** | §5: *"Every KPI tile carries a comparison (vs target, vs last period) — a number with no context supports no decision"* |
| **Project reality** | There are **no targets** anywhere in the project, and the analysis is deliberately a **single fixed period** (D-05). 2024 data exists, but the charter restricts site comparison to 2025 because Bristol has 78 weeks, not 104 (charter trap 2). |
| **Resolution** | **The comparison slot carries the basis tag instead** — `average of 52 weeks`, `at 2025-12-28`, `one-off`, `per annum · 22% assumed`, `ISO-week basis`, `calendar-year basis`. This is a **documented deviation**. Inventing a target would fabricate a benchmark the project spent forty decisions avoiding, and a 2024 comparison would breach charter trap 2. |

### C-5 · Colour — resolution, not conflict

The spec deliberately specified four semantic **roles** and no hues, pending this file. The four
roles now map onto the validated palette. See §7.0.

### C-6 · Chart titles must state the finding

| | |
|---|---|
| **Style guide** | Hard Rule 4: *"Title states the finding, not the variable."* |
| **Spec** | Visual titles are descriptive — "Inventory value by site" |
| **Resolution** | Every visual in §7 carries a **finding title** with the spec's descriptive title retained as the subtitle, so a reader can still map guide to spec. |

### C-7 · Scatter colour-series cap

| | |
|---|---|
| **Style guide** | §1: *"**Series cap for scatter, bubble and choropleth: use the first three slots only.** Beyond three, fold into 'Other', facet into small multiples, or use a second encoding channel."* |
| **Spec** | P4-V7 scatter uses `category_code` as legend — **8 categories** |
| **Resolution** | **Legend changed to `cheap_supplier_type`.** Across all 60 dual-source SKUs the cheaper source is a Far East importer in every case (F-14), so this legend resolves to **one series** — which is itself the finding, and it is stated in the title. Category moves to the tooltip. |

### Style guide points adopted without conflict
Bars start at zero · sort bars by value · axes labelled with units · legend for ≥2 series, direct
labels where ≤4 · never colour alone · no chartjunk · recessive gridlines · round to decision
precision · **state the n** · annotate the point that matters · Segoe UI, titles 14pt semibold,
axis labels 10pt · turn off default shadows and borders · custom theme JSON, never the stock
theme · screenshots at 2× downscaled to ~1600px, PNG under 500 KB, named `NN_description.png` in
`powerbi/screenshots/`.

---

## 1. Pre-build checklist

### 1.1 Required software

| Item | Requirement | Note |
|---|---|---|
| Power BI Desktop | Current release, 64-bit | Free; no licence needed to build or to open a `.pbix` |
| PostgreSQL | 16 | The version the pipeline was written and validated against |
| Npgsql provider | Bundled with current Power BI Desktop | Older Power BI builds needed a separate install; verify **Get Data → Database → PostgreSQL database** appears before starting |

### 1.2 PostgreSQL connection requirements

**Confirmed by the project:**

| Setting | Value | Confirmed by |
|---|---|---|
| Database name | `calderfield` | `sql/01_setup/02_load_synthetic_csv.sql`, README reproducibility block |
| Schema | `supply` | `SET search_path TO supply` at the head of all 35 SQL files |
| PostgreSQL version | 16 | `PROJECT_CHARTER.md` §10, README |

**Not confirmed — supply your own:**

| Setting | Placeholder | Note |
|---|---|---|
| Server / host | `<POSTGRES_HOST>` | Typically `localhost` for a local build |
| Port | `<POSTGRES_PORT>` | PostgreSQL default is 5432; the analysis session used a non-default port, so check your own instance |
| Username | `<POSTGRES_USER>` | |
| Password | `<POSTGRES_PASSWORD>` | Store in the Windows credential manager via Power BI's own prompt; **never** in a query, a parameter, or this repository |

**No credentials, hostnames or passwords are invented in this guide.** Enter them once in Power BI
Desktop's connection dialog and let Windows hold them.

### 1.3 Required permissions
`SELECT` on the `supply` schema is sufficient. No write, DDL, or superuser access is needed —
Power BI reads only. If your instance is locked down, a read-only role over `supply` is enough.

### 1.4 Pipeline prerequisite — this one will bite you

**All 35 SQL files must have been run before the first refresh.** Four of the imported views
(§2, D1–D4) are created by *analysis* files, not reporting files. A database built only as far as
Stage 5 will contain the seven reporting views and **fail on the other four**.

Verify before opening Power BI:

```sql
SELECT table_name
FROM   information_schema.views
WHERE  table_schema = 'supply'
  AND  table_name IN ('vw_sku_value_position','vw_policy_alignment',
                      'vw_purchase_quantity_structure','vw_dual_source_gap');
-- Must return 4 rows.
```

If it returns fewer, re-run the pipeline per the README reproducibility block.

### 1.5 Storage mode — Import

**Import, not DirectQuery, and not Composite.** Four reasons specific to this project:

1. **The data is frozen.** Fixed anchor dates of 2025-12-31 and 2025-12-28, a frozen synthetic
   dataset, and committed results verified byte-identical across five rebuilds. Nothing changes
   between refreshes, so DirectQuery's only advantage does not apply.
2. **Percentiles would break.** `vw_kpi_order_cycle_time` uses `PERCENTILE_CONT`. Under
   DirectQuery, Power BI pushes filter predicates into the source query, and a percentile computed
   over a slicer-filtered subset **is not the same number** as the committed result. Import freezes
   the view output exactly as `report_06_order_cycle_time.txt` shows it.
3. **`GROUPING SETS` would be re-evaluated.** Five of the seven reporting views build several
   grains in one pass. DirectQuery folding against them is unpredictable; Import takes the result
   set as it stands.
4. **Portability.** A portfolio reviewer must open the `.pbix` and see data without a database.

The whole model is roughly **4,000 rows** across 15 objects — trivially small for Import.

**Refresh cadence: manual.** This is a fixed-period analysis, not an operational report.

---

## 2. Exact data import list

**15 distinct PostgreSQL objects, imported as 17 Power BI queries.** Nothing else is imported.

### 2.1 Primary facts

| # | Object | Type | Purpose | Grain | Rows imported | Pages |
|---|---|---|---|---|---:|---|
| F1 | `vw_kpi_inventory_value_and_turnover` | Reporting view 01 | Inventory value, COGS, turns | Site × category | **32** of 45 | 1, 2, 5 |
| F1 | `vw_kpi_days_inventory_outstanding` | Reporting view 02 | DIO | Site × category | **32** of 45 | merged into F1 |
| F1 | `vw_kpi_stock_holding_cost` | Reporting view 03 | Holding cost + rate components | Site × category | **32** of 45 | merged into F1 |
| F2 | `vw_kpi_availability_and_fill_rate` | Reporting view 04 | Three availability measures | Site × category | **32** of 45 | 1, 3, 5 |
| F3 | `vw_working_capital_release_opportunity` | Reporting view 07 | Opportunity hierarchy | SKU × site @ 2025-12-28 | **515** | 1, 2, 5 |

Views 01, 02 and 03 are **merged into one table** `Fact Inventory KPI` — see §3.2.

### 2.2 Supporting facts

| # | Object | Type | Purpose | Grain | Rows imported | Pages |
|---|---|---|---|---|---:|---|
| F4 | `vw_kpi_supplier_on_time_delivery` | Reporting view 05 | On-time, all-receipt, OTIF | Supplier | **29** of 54 | 4 |
| F5 | `vw_kpi_supplier_on_time_delivery` | Reporting view 05 | Trend | Supplier type × half-year | **16** of 54 | 4 |
| F6 | `vw_kpi_order_cycle_time` | Reporting view 06 | Lead-time distribution | Supplier | **29** of 38 | 4 |
| F6b | `vw_kpi_order_cycle_time` | Reporting view 06 | Type summary | Supplier type | **4** of 38 | 4 |
| F4b | `vw_kpi_supplier_on_time_delivery` | Reporting view 05 | Network on-time cards K18–K20 | Network | **1** of 54 | 4 |
| F6c | `vw_kpi_order_cycle_time` | Reporting view 06 | Receiving-site view | Receiving site | **4** of 38 | 4 |
| D1 | `vw_sku_value_position` | Analysis view (file 02) | ABC concentration | SKU | **250** | 2 |
| D2 | `vw_policy_alignment` | Analysis view (file 16) | Alignment bands and outcome | SKU × site | **467** | 3 |
| D3 | `vw_purchase_quantity_structure` | Analysis view (file 17) | Minimum-order structural effect | Purchase order line, 2025 | **2,063** | 4 |
| D4 | `vw_dual_source_gap` | Analysis view (file 14) | Sourcing trade-off | SKU | **60** | 4 |

**Two counts, and they differ — keep them straight.**

- **15 distinct PostgreSQL objects** are imported: 7 reporting views, 4 detail views, 4 base tables.
- **17 Power BI queries** result, because reporting views 05 and 06 are each queried at more than
  one grain: view 05 → F4 (supplier), F4b (network), F5 (type × half-year); view 06 → F6
  (supplier), F6b (type), F6c (receiving site).

F4/F4b/F5 and F6/F6b/F6c are **separate queries against the same view at different grains**. This is
deliberate: one table holding two grains is the fastest route to double counting.

### 2.3 Dimensions

| # | Object | Type | Rows | Key | Pages |
|---|---|---|---:|---|---|
| Dim1 | `warehouse` | Base table | **4** | `warehouse_code` | 1, 2, 3, 5 |
| Dim2 | `product_category` | Base table | **8** | `category_code` | 1, 2, 3, 4, 5 |
| Dim3 | `supplier` | Base table | **30** | `supplier_code` | 4 |
| Dim4 | `product` | Base table | **250** | `sku` | 2, 3, 5 |

### 2.4 Not imported, and why

| Object | Why not |
|---|---|
| `mv_inventory_week` (51,220 rows) | No page in the approved scope requires a weekly time series. The spec listed it as optional; nothing uses it. |
| `vw_demand_line` (33,422 rows) | Spec P3-V5 offered it as an alternative source for the Renewables quarterly series. **Approved decision 4 forbids new aggregation**, so P3-V5 uses the committed `analyse_08` figures as a static reference table instead. |
| `vw_receipt_performance`, `vw_customer_resolved` | Reporting views already aggregate everything the dashboard needs from them. |
| All other analysis views | Out of approved dashboard scope. |
| `calendar_week`, `inventory_snapshot`, `stock_movement`, `sales_order*`, `purchase_order*`, `goods_receipt_line`, `replenishment_policy`, `product_supplier` | Not required by any approved visual. |

### 2.5 Static reference tables — five, entered in Power Query

**Six tables.** These carry committed figures that no view exposes at the grain required. Each is typed by hand
from the named committed result and **must not respond to any slicer**.

| # | Name | Rows | Source result | Used by |
|---|---|---:|---|---|
| S1 | `Ref Exposure Comparison` | 8 | `analyse_03/04/05/16/17` + `report_07` | P2-V5 |
| S2 | `Ref Cover Bands` | 6 | `analyse_06` §4 | P3-V2 |
| S3 | `Ref Seasonal Lag` | 8 | `analyse_07` §2 | P3-V6 |
| S4 | `Ref Meridian Trend` | 8 | `analyse_12` §7 and §8 | P4-V2, P4-V3 |
| S5 | `Ref Buy Ahead` | 3 | `analyse_15` §6 | P4-V8 |
| S6 | `Ref Renewables` | 8 | `analyse_08` §3 | P3-V5 |

S1's exact values, since it is the one most likely to be mistyped:

| Exposure | Value | Marked |
|---|---:|---|
| Slow-moving stock (file 03) | 123373 | normal |
| Excess above the policy ceiling (file 04) | 134701 | normal |
| Cover over 6 months (file 05) | 398821 | normal |
| Stock above the calibrated rule (file 16) | 115916 | normal |
| Minimum-order bound in closing stock (file 17) | 336205 | normal |
| **Naive sum — do not use** | **1109016** | **error** |
| Counted once under the hierarchy | 468897 | headline |
| Network closing stock, for scale | 1711042 | context |

---

## 3. Power Query transformation plan

**Governing rule:** Power Query prepares data for the model. It does **not** reimplement the
PostgreSQL analysis. No calculated business logic, no re-derived rates, no re-aggregation.

### 3.1 Steps applied to every query

1. **Source** → PostgreSQL, database `calderfield`, **Import**.
2. **Navigate** to `supply.<object>`.
3. **Remove** the "Changed Type" step Power BI auto-inserts, then set types explicitly (§3.3). The
   automatic step guesses from the first 1,000 rows and will type a sparse numeric column as
   `any`.
4. **Filter** to the required grain where the object has a `grain_level` column (§3.4).
5. **Rename** the query to its model name (`Fact Inventory KPI`, `Dim Warehouse`, …).
6. **Do not** remove columns you are unsure about — hide them in the model instead (§3.6).

### 3.2 F1 — the three-view merge

The only non-trivial transformation, and it introduces no logic.

```
1. Query "Inv01" : supply.vw_kpi_inventory_value_and_turnover
                   → Filter grain_level = "4 — site and category"      → 32 rows
2. Query "Inv02" : supply.vw_kpi_days_inventory_outstanding
                   → Filter grain_level = "4 — site and category"      → 32 rows
                   → Keep only: warehouse_code, category_code,
                     days_inventory_outstanding,
                     days_inventory_outstanding_unrounded_basis,
                     weeks_of_cost_of_sales_held
3. Query "Inv03" : supply.vw_kpi_stock_holding_cost
                   → Filter grain_level = "4 — site and category"      → 32 rows
                   → Keep only: warehouse_code, category_code,
                     holding_rate, holding_cost_gbp,
                     holding_cost_at_20pct_gbp, holding_cost_at_25pct_gbp,
                     component_capital_gbp, component_storage_gbp,
                     component_service_gbp, component_risk_gbp,
                     holding_cost_pct_of_cost_of_sales
4. Merge Inv01 ← Inv02 on (warehouse_code, category_code), Left Outer, expand
5. Merge result ← Inv03 on (warehouse_code, category_code), Left Outer, expand
6. Rename to "Fact Inventory KPI"                                      → 32 rows
7. Disable load on Inv02 and Inv03 (they exist only to feed the merge)
```

**Why this is safe.** Views 02 and 03 are *derived from* view 01 in PostgreSQL (D-37) — they
carry the same 32 keys with additional columns. The merge is a lookup, not a join that can fan
out. **Verify: the result must be exactly 32 rows.** If it is more, the merge keys are wrong.

**Why it is necessary.** Three tables at an identical grain would create three paths from
`Dim Warehouse` to the same numbers and invite an ambiguous-relationship error.

### 3.3 Data types

| Column pattern | Power Query type | Model format | Note |
|---|---|---|---|
| `*_gbp`, `*_cost_*`, `unit_cost_gbp` | Decimal Number | `£#,##0` / `£#,##0.00` | **Never Fixed Decimal** — PostgreSQL `numeric(12,2)` maps cleanly to Decimal, and Fixed Decimal silently rounds at 4dp |
| `*_pct`, `*_rate_pct`, `*_share_*` | Decimal Number | `0.00%` after ÷100 — **see §3.5** | |
| `*_units`, `*_lines`, `n_*`, `positions`, `sku_weeks`, `weeks_*`, `days_*` | Whole Number | `#,##0` | |
| `*_ratio`, `*_multiple`, `*_factor` | Decimal Number | `0.00` | |
| `inventory_turns` | Decimal Number | `0.00` | |
| `*_date` (`discontinued_date`, `order_date`, `last_reviewed_date`) | Date | `dd/MM/yyyy` | Date, not DateTime — no time component exists |
| `is_*` (`is_february_buy_ahead_position`, `minimum_exceeds_policy_quantity`, `ordered_exactly_at_minimum`) | True/False | | |
| `warehouse_code`, `category_code`, `sku`, `supplier_code` | Text | | Keys — never numeric |
| Free text (`service_consequence`, `unresolved_service_constraint`, `source_reference`, `cell_note`) | Text | | |

**Locale:** set the query locale to **English (United Kingdom)** on import so `1,234.56` parses
correctly and dates read `dd/MM/yyyy`.

### 3.4 Grain filters — apply exactly these

| Query | Filter | Result rows |
|---|---|---:|
| `Fact Inventory KPI` (Inv01/02/03) | `grain_level = "4 — site and category"` | 32 |
| `Fact Availability` | `grain_level = "4 — site and category"` | 32 |
| `Fact Supplier Delivery` | `grain_level = "4 — supplier"` | 29 |
| `Fact Supplier Trend` | `grain_level = "3 — supplier type by half-year"` | 16 |
| `Fact Cycle Time` | `grain_level = "3 — supplier"` | 29 |
| `Fact Cycle Time By Type` | `grain_level = "2 — supplier type"` | 4 |
| `Fact Supplier Network` | `grain_level = "1 — network"` | 1 |
| `Fact Cycle Time By Site` | `grain_level = "4 — receiving site"` | 4 |
| `Fact Opportunity` | *(none — flat view)* | 515 |
| D1–D4 | *(none)* | 250 / 467 / 2,063 / 60 |

**Filter on the literal string, never the leading digit.** The numbering means different things
in different views — verified against the live database:

```
View 05 : 1 — network | 2 — supplier type | 3 — supplier type by half-year | 4 — supplier | 5 — receiving site
View 06 : 1 — network | 2 — supplier type | 3 — supplier                   | 4 — receiving site
```

`grain_level = "3 — ..."` means *category* in views 01–04, *supplier type by half-year* in view
05, and *supplier* in view 06. A numeric filter would silently import the wrong grain.

**After filtering, delete the `grain_level` column** from every fact. It has served its purpose
and leaving it invites someone to build a slicer on it.

### 3.5 Percentage handling — one decision, applied consistently

PostgreSQL returns percentages as **numbers out of 100** (`7.71` means 7.71%). Power BI's
percentage format multiplies by 100 on display.

**Decision: divide by 100 in Power Query and format as `0.00%` in the model.**

- Applies to every `*_pct` column on every imported object.
- Add a step: *Transform → Standard → Divide → 100*.
- The alternative — leaving them as 7.71 and formatting as `0.00` with a literal "%" suffix —
  works but breaks conditional formatting rules and data bars, which expect a true fraction.

**This is a display transformation, not an analytical one.** The underlying value is unchanged and
still reconciles to the committed result.

**Exception:** `holding_rate` in view 03 is already a fraction (`0.22`). **Do not divide it.**
Verify after import: it must read 0.22, not 0.0022.

### 3.6 Columns to hide (not remove) in the model

Keep them loaded — they are cheap and useful in tooltips — but hide from the field list:

| Table | Hide |
|---|---|
| `Fact Inventory KPI` | `warehouse_name`, `category_name` (use the dimensions), `weeks_measured`, `days_inventory_outstanding_unrounded_basis` |
| `Fact Availability` | `days_observed`, `unmet_share_of_demand_pct` |
| `Fact Opportunity` | `category_name`, `releasable_share_of_position_pct`, `qualified_sources` |
| `Fact Supplier Delivery` | `supplier_name` (use `Dim Supplier`), `units_rejected` |
| All facts | Every key column once relationships are built — `warehouse_code`, `category_code`, `sku`, `supplier_code` |

**Hide keys, never delete them.** Deleting breaks the relationship.

### 3.7 Null handling

| Situation | Treatment |
|---|---|
| `Fact Opportunity[sourcing_last_used]` — 8 nulls | **Leave null.** These are positions with no 2025 purchase. Replacing with "Unknown" would create a fifth sourcing category that does not exist. |
| `Fact Opportunity[cover_weeks]` — null where no trailing demand | **Leave null.** Null means "no demand to measure against", which is different from zero cover. Replacing with 0 would corrupt every cover average. |
| `Fact Opportunity[discontinued_date]` — null for live products | Leave null. |
| `Fact Opportunity[unresolved_service_constraint]` — empty string for WAR and LIV | **Leave as empty string.** The view returns `''`, not null; measure M14 tests for it. |
| `Fact Supplier Delivery[cell_note]` — empty for healthy cells | Leave as empty string. |
| `Fact Cycle Time` percentiles | Never null at the imported grain, but do not fill if encountered. |

**Never use "Replace Errors" or "Remove Blank Rows" on any fact.** Both would silently change a
denominator.

### 3.8 Renames

Rename **queries**, not columns. Column names stay exactly as PostgreSQL returns them, so any
figure on the dashboard can be traced to a committed `.txt` file by name.

| PostgreSQL object | Power BI table |
|---|---|
| merged 01+02+03 | `Fact Inventory KPI` |
| `vw_kpi_availability_and_fill_rate` | `Fact Availability` |
| `vw_working_capital_release_opportunity` | `Fact Opportunity` |
| `vw_kpi_supplier_on_time_delivery` (supplier) | `Fact Supplier Delivery` |
| `vw_kpi_supplier_on_time_delivery` (type × half-year) | `Fact Supplier Trend` |
| `vw_kpi_order_cycle_time` (supplier) | `Fact Cycle Time` |
| `vw_kpi_order_cycle_time` (type) | `Fact Cycle Time By Type` |
| `vw_sku_value_position` | `Detail SKU Value` |
| `vw_policy_alignment` | `Detail Policy Alignment` |
| `vw_purchase_quantity_structure` | `Detail Purchase Structure` |
| `vw_dual_source_gap` | `Detail Dual Source` |
| `warehouse` / `product_category` / `supplier` / `product` | `Dim Warehouse` / `Dim Category` / `Dim Supplier` / `Dim Product` |

Only exception, for readability in visuals: in `Dim Warehouse`, no rename is needed —
`warehouse_name` already reads well.

### 3.9 Enable load

| Enabled | Disabled (staging only) |
|---|---|
| All 15 model tables, 5 static reference tables, 2 parameter tables | `Inv02`, `Inv03` (feed the F1 merge) |

### 3.10 Transformations that would change analytical meaning — forbidden

| Do not | Why |
|---|---|
| Group/aggregate any fact in Power Query | Would re-derive what PostgreSQL already computed, at a different grain |
| Unpivot the availability measures | The three measures have **different denominators and different clocks** — unpivoting implies they are comparable |
| Merge `Fact Availability` into `Fact Inventory KPI` | Same keys, but two clocks (D-22). One table would imply one time basis |
| Recompute any `*_pct` from its components in Power Query | Duplicates the view's logic; use DAX where re-aggregation is genuinely needed (§5) |
| Fill down / fill up anything | No fact has intentional sparse hierarchy |
| Add an index column to a fact | Invites accidental use as a key |
| Replace `null` cover with 0 | Corrupts cover averages (§3.7) |

---

## 4. Data model

### 4.1 Relationship table — 11 relationships, all single-direction

| # | From (many) | From column | To (one) | To column | Cardinality | Cross-filter | Active | Reason |
|---|---|---|---|---|---|---|---|---|
| R1 | `Fact Inventory KPI` | `warehouse_code` | `Dim Warehouse` | `warehouse_code` | Many-to-one | Single | ✅ | Site slicing of inventory KPIs |
| R2 | `Fact Inventory KPI` | `category_code` | `Dim Category` | `category_code` | Many-to-one | Single | ✅ | Category slicing |
| R3 | `Fact Availability` | `warehouse_code` | `Dim Warehouse` | `warehouse_code` | Many-to-one | Single | ✅ | Site slicing of availability |
| R4 | `Fact Availability` | `category_code` | `Dim Category` | `category_code` | Many-to-one | Single | ✅ | Category slicing |
| R5 | `Fact Opportunity` | `warehouse_code` | `Dim Warehouse` | `warehouse_code` | Many-to-one | Single | ✅ | Site slicing of the hierarchy |
| R6 | `Fact Opportunity` | `category_code` | `Dim Category` | `category_code` | Many-to-one | Single | ✅ | Category slicing |
| R7 | `Fact Opportunity` | `sku` | `Dim Product` | `sku` | Many-to-one | Single | ✅ | SKU drill-through on Page 5 |
| R8 | `Fact Supplier Delivery` | `supplier_code` | `Dim Supplier` | `supplier_code` | Many-to-one | Single | ✅ | **The authoritative supplier-type path** (§4.4) |
| R9 | `Fact Cycle Time` | `supplier_code` | `Dim Supplier` | `supplier_code` | Many-to-one | Single | ✅ | Same |
| R11 | `Detail SKU Value` | `category_code` | `Dim Category` | `category_code` | Many-to-one | Single | ✅ | ABC by category |
| R12 | `Detail Policy Alignment` | `warehouse_code` | `Dim Warehouse` | `warehouse_code` | Many-to-one | Single | ✅ | Site slicing of alignment |

**Every relationship is Many-to-one, Single cross-filter, Active. There is no bi-directional
filtering anywhere in this model, and none should be added.** Bi-directional filtering across
several facts at different grains is the most common source of silent double counting in Power BI.

> ### R10 was removed — do not recreate it
>
> This table originally carried an **R10**, `Detail SKU Value[sku]` → `Dim Product[sku]`, described
> as Many-to-one. **That was wrong, and building it breaks the model.**
>
> Both tables hold **exactly 250 rows, one per SKU, unique on `sku`**. Power BI therefore detects
> the relationship as **one-to-one**, and **Power BI forces every 1:1 relationship to bidirectional
> cross-filtering — it cannot be set to Single.** That creates a second filter path from
> `Dim Category` to `Fact Opportunity` (via `Detail SKU Value` → `Dim Product`) alongside the direct
> path R6, and Power BI raises an **ambiguous path** error.
>
> **R10 is unnecessary.** The only visual using `Detail SKU Value` is the ABC Pareto (P2-V3), whose
> axis, columns, line and tooltip all come from that table's own columns — it never reaches through
> `Dim Product`.
>
> **R11 remains and is the valid relationship** for that table: `Detail SKU Value[category_code]` →
> `Dim Category[category_code]` is a genuine many-to-one (250 → 8) and supports category filtering
> of the ABC/Pareto visual.
>
> The identifier **R11 is deliberately not renumbered to R10**, so this documentation stays
> traceable to the original specification and this correction. See D-41.

### 4.2 Deliberate additional relationships and why they are *not* built

| Candidate | Verdict | Reason |
|---|---|---|
| `Detail Policy Alignment[category_code]` → `Dim Category` | **Build it** as R13 if you want category slicing on Page 3's alignment matrix. Optional — Page 3's category slicer is more useful bound to `Fact Availability`. Adding it creates no ambiguity because it is a separate fact. |
| `Detail SKU Value[sku]` → `Dim Product` *(the former R10)* | **Do not build.** Both sides are unique on `sku` at 250 rows, so Power BI creates a **one-to-one** relationship and forces **bidirectional** filtering, producing an ambiguous filter path to `Fact Opportunity`. Unnecessary — P2-V3 reads `Detail SKU Value` directly. See D-41. |
| `Detail Policy Alignment[sku]` → `Dim Product` | **Do not build.** No approved visual needs it, and it adds a second path from `Dim Product` to alignment data that no measure uses. |
| `Detail Purchase Structure[warehouse_code]` → `Dim Warehouse` | **Build it** as R14 — P4-V6 offers site slicing. |
| `Detail Purchase Structure[category_code]` → `Dim Category` | **Build it** as R15 — P4-V6 offers category slicing. |
| `Detail Purchase Structure[supplier_code]` → `Dim Supplier` | **Do not build.** See §4.4 — it would create a second supplier path that changes what a supplier-type slicer means. |
| `Detail Dual Source[category_code]` → `Dim Category` | **Build it** as R16 — P4-V7 category tooltip. |
| `Fact Supplier Trend` → anything | **Do not build.** Its grain is supplier *type*, not supplier. Relating it to `Dim Supplier` would fan 16 rows across 30 suppliers. |
| `Fact Cycle Time By Type` → anything | **Do not build.** Same reason — 4 rows at type grain. |
| `Fact Opportunity[sourcing_last_used]` → `Dim Supplier` | **Impossible and wrong.** It is a *type*, not a code, and it describes a position, not a supplier (§4.4). |

**Final relationship count: 11 required (R1–R9, R11, R12), plus 4 optional (R13–R16) recommended
for the Page 3 and Page 4 slicers. Build all 15.**

*Was 12 required and 16 total before R10 was removed. R10 must not be created — see the box above
and D-41.*

### 4.3 Disconnected tables — 7

| Table | Rows | Relationships | Purpose |
|---|---:|---|---|
| `Param Holding Rate` | 3 | none | 20 / 22 / 25% sensitivity (§6) |
| `Dim Opportunity Tier Order` | 5 | 1 → `Fact Opportunity[opportunity_mechanism]` | Sort order — **this one IS connected**, see note |
| `Ref Exposure Comparison` | 8 | none | P2-V5 |
| `Ref Cover Bands` | 6 | none | P3-V2 |
| `Ref Seasonal Lag` | 8 | none | P3-V6 |
| `Ref Meridian Trend` | 8 | none | P4-V2, P4-V3 |
| `Ref Buy Ahead` | 3 | none | P4-V8 |

**Note on tier ordering.** The spec proposed a related `Opportunity Tier Order` table. **Simpler
and safer: do not create it.** The `opportunity_mechanism` values already begin `1 — `, `2 — `…
`5 — `, so alphabetical sort is already the correct order. Creating a sort table adds a
relationship for zero benefit. **Revised disconnected count: 6 tables, all with no relationships.**

**All five `Ref` tables must have every visual's interaction set to "None"** (§7). A static
network-level finding that moves under a slicer is a defect.

### 4.4 Supplier type — the authority question, traced not assumed

Approved decision 2 required this to be traced. It was, against the live database.

**Three fields carry the name `supplier_type`, plus a fourth that looks similar:**

| Field | Lineage | Grain | Distinct values | Population |
|---|---|---|---|---|
| `supplier.supplier_type` | Base table attribute | Supplier | 4 | **30** suppliers (7 / 5 / 10 / 8) |
| `vw_kpi_supplier_on_time_delivery.supplier_type` | `vw_receipt_performance` → `supplier sup ON sup.supplier_code = po.supplier_code` | Varies by grain | 4 | **29** suppliers at grain 4 |
| `vw_purchase_quantity_structure.supplier_type` | `supplier s ON s.supplier_code = po.supplier_code` | Purchase order line | 4 | **29** suppliers |
| `vw_working_capital_release_opportunity.sourcing_last_used` | `vw_structural_stock_position.last_supplier_type` ← `vw_purchase_quantity_structure` via `DISTINCT ON (sku, warehouse_code) … ORDER BY order_date DESC` | **SKU × site position** | 4 + null | **515 positions** (165 / 29 / 91 / 222, 8 null) |

**Conclusion.**

**The first three are the same attribute.** All three resolve to `supplier.supplier_type`, reached
through `purchase_order.supplier_code`. They differ only in *population*: the base table has 30
suppliers; the views have 29, because one Small Specialist placed no measurable purchase in the
window. The values are identical, the concept is identical.

**The fourth is a different concept.** `sourcing_last_used` is not a supplier attribute at all —
it is a **position attribute** answering *"what kind of source last replenished this shelf?"* It
carries D-18, the project's standing attribution rule: minimum order quantities and lead times
belong to the source **actually used on the most recent receipt**, not the nominated primary
source. That rule reversed a headline conclusion (excess moved from 76% UK-manufacturer to 82%
Far East importer), and it is why `Fact Opportunity` carries a type rather than a supplier code.

**Authoritative field for the Page 4 supplier-type slicer: `Dim Supplier[supplier_type]`.**

Reasons: Page 4 is about supplier and purchasing behaviour; `Dim Supplier` is the only true
dimension of the four candidates; and F4 and F6 both reach it through R8/R9, so one slicer filters
both consistently.

**Consequences to build around:**

1. **`Fact Supplier Trend` (F5) will not respond to that slicer** — it has no supplier
   relationship by design (§4.2). Use a **synchronised slicer** bound to `Fact Supplier
   Trend[supplier_type]` on the same page, synced by value, or accept that P4-V2 shows all four
   types always. **Recommended: accept all four types always.** P4-V2's whole purpose is the
   type-level comparison and the leave-one-out refutation; filtering it to one type destroys the
   finding.
2. **`Detail Purchase Structure` (D3) will not respond either** — no supplier relationship (§4.2).
   P4-V6 is a supplier-*type* comparison across all four types; filtering it defeats the visual.
   **Set P4-V6's interaction with the supplier-type slicer to "None".**
3. **The 30th supplier** appears in `Dim Supplier` but in no fact. A supplier slicer will offer a
   name that blanks every visual. Either accept it (honest — that supplier genuinely placed no
   measurable purchase) or set the slicer to hide items with no data. **Recommended: accept it,
   and let the blank state show.**
4. **Never use `sourcing_last_used` as a supplier slicer.** It is a position attribute. Using it
   to filter Page 4 would silently answer a different question.

### 4.5 Ambiguity and double-counting risks — the full list

| # | Risk | Mitigation |
|---|---|---|
| 1 | `grain_level` views imported unfiltered → measures ×4 | §3.4 filters; validation check in §10.2 |
| 2 | Three tables at the same grain (views 01/02/03) → ambiguous paths | Merged into one (§3.2) |
| 3 | One table holding two grains (view 05 / view 06) | Two separate queries each (§2.2) |
| 4 | `grain_level` digit means different things across views | Filter on literal strings (§3.4) |
| 5 | Summing a pre-computed rate across cells | Recompute in DAX from numerator and denominator (§5) |
| 6 | Aggregating percentiles in `Fact Cycle Time` | Display at row grain; disable interaction (§7 Page 4) |
| 7 | `Dim Product` filters F3 but not F1/F2 → blanked cards | **No product slicer on Pages 1, 2, 3.** Product filtering happens only via drill-through on Page 5 |
| 8 | `Dim Supplier` cannot filter F3 | Documented (§4.4); no supplier slicer on Pages 1, 2, 5 |
| 9 | Bi-directional filtering added later "to make a slicer work" | **Never add it.** If a slicer does not filter a visual, that is the model telling you the grains differ |
| 9a | A relationship between two tables that are **both unique on the key** — Power BI makes it 1:1 and forces bidirectional filtering, which cannot be turned off | Check row counts and uniqueness before creating any relationship. This is what removed R10 (D-41) |
| 10 | Adding tier capital and annual holding cost | Never on one axis; separate measures, separate columns (§5, §6) |
| 11 | Static `Ref` tables responding to slicers | Interaction set to None (§7) |
| 12 | ISO-week and calendar-year measures on one axis | Both bases labelled; §10.6 |

---

## 5. DAX measures

### 5.1 Change from the approved specification

The spec defined 16 measures. **Approved decision 3 removes K17 (Unit Fill Rate).** M5
`Unit Fill Rate %` existed solely to serve K17 and is referenced by no other approved visual.

**M5 is removed.** No replacement availability measure is added — the three core measures (now
M4, M5, M6) remain the availability framework, exactly as decision 3 requires.

**One measure is added, and the arithmetic is stated plainly: 16 − 1 + 1 = 16.**

The spec listed K16 (unmet demand value) with the source `[Unmet Demand Value]` but never defined
that measure among its 16. It is formalised here as **M7**. Strictly, the governing rule in §5
would not require it — `SUM('Fact Availability'[unmet_value_gbp])` is the implicit aggregation
Power BI performs anyway. It is defined explicitly for three reasons: the `▲ upper bound` caveat
needs one authoritative home rather than being retyped on two pages; the calendar-year basis needs
stating alongside it; and K16 and the Page 5 context card must use identical formatting.

**Final count: 16 measures** — one fewer than the spec's availability set, one more than the
spec's formal list.

Measure numbering below is renumbered contiguously; the spec's original number is given for
traceability.

### 5.2 Where to put them
Create one empty table named **`_Measures`** (Home → Enter Data, one dummy column, load, then
delete the column). Place all 16 measures there and hide the dummy. This keeps measures out of the
fact tables and makes the field list readable.

### 5.3 The measures

---

**M1 · `Inventory Value`** *(spec M1)*
- **Table:** `_Measures`
- **DAX:** `SUM ( 'Fact Inventory KPI'[average_stock_gbp] )`
- **Purpose:** Additive average-inventory base.
- **Format:** `£#,##0`
- **Validation:** No filters → **£2,043,979** (`report_01`).
- **Why aggregation is valid:** `average_stock_gbp` at site × category grain is a sum of weekly
  values divided by a constant 52 weeks. Summing across cells is therefore summing 32 constants ×
  the same divisor — arithmetically identical to computing the network average directly. Stage 5
  verified sites and categories each sum to network within £0.05 (D-37).
- **Caveat:** Mean of 52 weekly snapshots, **never** closing stock (D-10).

---

**M2 · `Inventory Turns`** *(spec M2)*
- **DAX:**
  ```
  Inventory Turns =
  DIVIDE (
      SUM ( 'Fact Inventory KPI'[cost_of_sales_gbp] ),
      SUM ( 'Fact Inventory KPI'[average_stock_gbp] )
  )
  ```
- **Format:** `0.00` with suffix `×`
- **Validation:** No filters → **4.67** (`report_01`).
- **Why aggregation is valid — and why the view's column cannot be used:** turns is a **ratio of
  two sums**, not a sum of ratios. The view's `inventory_turns` column is correct *only at its own
  row's grain*; averaging 32 cell-level turns would weight a £9,760 Bristol Tools cell equally
  with a £468,232 Daventry Renewables cell. Recomputing from additive numerator and denominator is
  the only correct aggregation.
- **Caveat:** COGS is at ledger weighted average cost with transfers excluded (D-09, D-10).

---

**M3 · `Days Inventory Outstanding`** *(spec M3)*
- **DAX:** `DIVIDE ( 365, [Inventory Turns] )`
- **Format:** `0.0` with suffix ` days`
- **Validation:** No filters → **78.2** (`report_02`).
- **Why aggregation is valid:** Derived from M2, so it inherits M2's correctness. Never sum the
  view's `days_inventory_outstanding` column.
- **Caveat:** KPI library defines DIO on a 365-day year; the period spans 364 days. Difference
  0.27%; library definition kept without deviation (D-37).

---

**M4 · `Lines Short Rate %`** *(spec M4)*
- **DAX:**
  ```
  Lines Short Rate % =
  DIVIDE (
      SUM ( 'Fact Availability'[lines_not_supplied_in_full] ),
      SUM ( 'Fact Availability'[demand_lines] )
  )
  ```
- **Format:** `0.00%`
- **Validation:** No filters → **7.71%** (1,272 ÷ 16,506, `report_04`).
- **Why aggregation is valid:** Both numerator and denominator are additive counts at cell grain.
  Their ratio at any aggregation is the correct rate for that aggregation.
- **Caveat:** **Calendar-year order-date basis** (D-22). Never place beside an ISO-week measure
  without labelling both bases.

---

**M5 · `Closing Zero Rate %`** *(spec M6)*
- **DAX:**
  ```
  Closing Zero Rate % =
  DIVIDE (
      SUM ( 'Fact Availability'[weeks_closing_at_zero] ),
      SUM ( 'Fact Availability'[sku_weeks] )
  )
  ```
- **Format:** `0.00%`
- **Validation:** No filters → **3.52%** (943 ÷ 26,780, `report_04`).
- **Why aggregation is valid:** Additive counts of SKU-weeks.
- **Caveat:** **ISO-week clock.** Understates the day-level measure by 1.26–1.67× depending on
  site. Never display without M6.

---

**M6 · `Any Zero Day Rate %`** *(spec M7)*
- **DAX:**
  ```
  Any Zero Day Rate % =
  DIVIDE (
      SUM ( 'Fact Availability'[weeks_with_a_zero_day] ),
      SUM ( 'Fact Availability'[sku_weeks] )
  )
  ```
- **Format:** `0.00%`
- **Validation:** No filters → **5.05%** (1,353 ÷ 26,780, `report_04`).
- **Why aggregation is valid:** As M5.
- **Caveat:** ISO-week clock; still understates the customer experience (M4).

---

**M7 · `Unmet Demand Value`** *(new — implied by spec K16, not previously formalised)*
- **DAX:** `SUM ( 'Fact Availability'[unmet_value_gbp] )`
- **Format:** `£#,##0`
- **Validation:** No filters → **£1,027,629** (`report_04`).
- **Why aggregation is valid:** A currency sum at cell grain.
- **Caveat:** **UPPER BOUND** — substitution is not modelled. Calendar-year basis; the
  snapshot-week basis gives £1,025,038, a £2,591 difference (D-22).
- **Note:** The spec listed K16 with source `[Unmet Demand Value]` but did not define the measure.
  Formalised here; it is a plain sum of an existing column and adds no logic.

---

**M8 · `Selected Opportunity Value`** *(spec M8)*
- **DAX:** `SUM ( 'Fact Opportunity'[working_capital_gbp] )`
- **Format:** `£#,##0`
- **Validation:** No filters → **£468,897** (`report_07`).
- **Why aggregation is valid:** `Fact Opportunity` is mutually exclusive and exhaustive by
  construction — each of the 515 positions appears exactly once and carries the figure of its own
  assigned tier only (D-36). Summing cannot double count.
- **Caveat — the most important in this document:** **One-off capital.** Tiers 2 and 4 are **upper
  bounds**; tier 1 is definitional; tier 3 is measured. **Never add to M9.**

---

**M9 · `Selected Annual Holding Cost`** *(spec M9)*
- **DAX:**
  ```
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
- **Format:** `£#,##0` with suffix ` p.a.`
- **Validation:** 22% → **£103,157** · 20% → **£93,779** · 25% → **£117,225** (`report_07`).
- **Why aggregation is valid:** As M8 — one row per position, one figure per row.
- **Caveat:** Reads **pre-computed columns**, never `value × rate`, so the dashboard cannot drift
  from committed results. Defaults to 22% when nothing is selected. Three of the four components
  of the rate are assumptions (D-11).

---

**M10 · `Stock Value at Closing`** *(spec M10)*
- **DAX:** `SUM ( 'Fact Opportunity'[position_stock_value_gbp] )`
- **Format:** `£#,##0`
- **Validation:** No filters → **£1,711,042** (`report_07`).
- **Why aggregation is valid:** One row per position.
- **Caveat:** Single instant at 2025-12-28. **Not comparable with M1** — closing is 16.3% below
  the 52-week average.

---

**M11 · `Opportunity Share of Stock %`** *(spec M11)*
- **DAX:** `DIVIDE ( [Selected Opportunity Value], [Stock Value at Closing] )`
- **Format:** `0.0%`
- **Validation:** No filters → **27.4%**; Bristol → **59.1%**.
- **Why aggregation is valid:** Ratio of two measures both additive over the same table and filter
  context.
- **Caveat:** A high share is **not** a performance measure. Bristol's 59.1% sits on the
  worst-serving site and is constrained by an unresolved anomaly.

---

**M12 · `Unclassified Stock Value`** *(spec M12)*
- **DAX:**
  ```
  Unclassified Stock Value =
  CALCULATE (
      [Stock Value at Closing],
      'Fact Opportunity'[opportunity_mechanism] = "5 — no identified release opportunity"
  )
  ```
- **Format:** `£#,##0`
- **Validation:** No filters → **£835,219**, 48.8% of closing stock.
- **Why aggregation is valid:** A filtered sum over the same exclusive table.
- **Caveat:** Not "safe" stock and not "correct" stock — stock the analysis has **no case
  against**.

---

**M13 · `Minimum Binds %`** *(spec M13)*
- **DAX:**
  ```
  Minimum Binds % =
  DIVIDE (
      CALCULATE (
          COUNTROWS ( 'Detail Purchase Structure' ),
          'Detail Purchase Structure'[minimum_exceeds_policy_quantity] = TRUE ()
      ),
      COUNTROWS ( 'Detail Purchase Structure' )
  )
  ```
- **Format:** `0.0%`
- **Validation:** Far East Importer → **98.3%** (`analyse_17` §1).
- **Why aggregation is valid:** Row counts over purchase order lines; the ratio is well defined at
  any grouping of lines.
- **Caveat:** 2025 purchase lines only — a **flow**, never comparable with a stock position.

---

**M14 · `Ordered At Minimum %`** *(spec M14)*
- **DAX:** as M13, with `'Detail Purchase Structure'[ordered_exactly_at_minimum] = TRUE ()`.
- **Format:** `0.0%`
- **Validation:** Far East Importer → **99.3%** (`analyse_17` §1).
- **Why aggregation is valid:** As M13.
- **Caveat:** The headline structural evidence — the order quantity is a term of trade, not a
  replenishment decision.

---

**M15 · `Unresolved Constraint Text`** *(spec M15)*
- **DAX:**
  ```
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
- **Format:** Text
- **Validation:** Daventry and Bristol return text; Warrington and Livingston return blank; no
  filter returns blank (two distinct constraints).
- **Caveat:** Returns text **written in the SQL view**, not composed in DAX. **Do not paraphrase
  it** — the wording deliberately assigns no cause (D-24, D-25, D-39).

---

**M16 · `Dynamic Insight Title`** *(spec M16)*
- **DAX:**
  ```
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
- **Format:** Text
- **Caveat:** Must say **"identified"** — never "available", "releasable now" or "saving". The
  constraint flag is not optional.

### 5.4 Measures deliberately NOT created

| Not created | Why |
|---|---|
| `Unit Fill Rate %` | **Removed by approved decision 3** |
| On-time %, OTIF %, split rate % | View 05 exposes rates and denominators but **not on-time numerators**. Reconstructing a numerator from a rounded percentage would introduce error. Read the pre-computed columns at the view's own grain (§4.5 risk 5) |
| Any percentile measure | Percentiles are not aggregable (§4.5 risk 6). Display `median_cycle_days` etc. as columns |
| `Line Fill Rate %` | The complement of M4. Use `1 - [Lines Short Rate %]` inline if a visual needs it, or read the view's `line_fill_rate_pct` at cell grain. A separate measure would be a third way to express one thing |
| Any holding-cost measure on `Fact Inventory KPI` | View 03's `holding_cost_gbp` is additive at cell grain — use the **column** directly. Only the opportunity holding cost needs a measure, because it responds to the rate parameter |
| Any "cause", "driver" or "root cause" measure for Daventry or Bristol | **Forbidden.** No such field exists and none may be constructed (§10.8) |

**Final count: 16 measures.**

---

## 6. Holding-cost rate parameter

### 6.1 The parameter table

Create via **Home → Enter Data**, named `Param Holding Rate`:

| Rate | Label | Sort |
|---:|---|---:|
| 0.20 | 20% — low sensitivity | 1 |
| 0.22 | **22% — approved rate (D-11)** | 2 |
| 0.25 | 25% — high sensitivity | 3 |

- `Rate` → Decimal Number, format `0%`
- `Label` → Text; set **Sort by column** = `Sort`
- **No relationships.** This table is disconnected by design.
- Hide `Sort` from the field list.

**Do not use Power BI's "New parameter → Numeric range" feature.** It generates a continuous slider
that would let a user select 23.7%, for which no committed figure exists. Three discrete values,
each backed by a pre-computed column, is the safe implementation.

### 6.2 Default selection
**22%.** Set by:
1. The `SELECTEDVALUE(..., 0.22)` fallback in M9 — if nothing is selected, 22% applies.
2. A slicer default: select "22% — approved rate (D-11)" and save it into the report's default
   bookmark.

Both are needed. The fallback protects the measure; the slicer default protects what the user
sees.

### 6.3 Required DAX
M9 only (§5.3). No other measure responds to the parameter.

### 6.4 How visuals respond

| Visual | Responds? | Why |
|---|---|---|
| K7, K10 (annual holding-cost cards) | ✅ | The point of the parameter |
| P1-V3, P2-V4 (holding-cost **column** only) | ✅ | Column header must read "Annual holding cost at [selected rate]" |
| P5-V1, P5-V3 holding-cost columns | ✅ | |
| K6, K9 (working capital) | ❌ | **Capital does not change with the holding rate.** If these move, M8 has been wired to the parameter in error |
| Everything else | ❌ | Set interaction to None where a stray filter could confuse |

**Slicer placement:** Pages 2 and 5 only — the pages carrying holding-cost figures. Not on Pages
1, 3 or 4. Page 1's K7 uses the 22% default and carries the note "20%/25% sensitivity on Page 2".

### 6.5 The rule the parameter must never break

**Capital release and annual holding cost are never summed.** Enforcement:

1. M8 and M9 never appear on the same axis of the same visual.
2. Every card carries a basis tag — `one-off` or `per annum`.
3. K6/K7 and K9/K10 sit in a bordered group captioned **"One-off capital · Annual cost — never
   added"**.
4. Matrix visuals showing both use **separate column headers with units** — "£ one-off" and
   "£ per annum" — and **no grand total across the two columns**.
5. Validation check §10.10.

---

## 7. Page-by-page build instructions

### 7.0 Theme and layout foundation — do this first

**Page size:** 1280 × 720, Custom, **Fit to page** (C-2).

**Theme JSON.** Build one from the style guide palette and apply via **View → Themes → Browse for
themes**. Never the stock theme. Save as `powerbi/theme/calderfield_theme.json`.

Semantic role → style guide token:

| Role (spec §5.5) | Style guide token | Hex (light) |
|---|---|---|
| **Opportunity** — tiers 1–4, releasable capital | Sequential blue ramp, **starting no lighter than step 250** (guide §1, ordinal rule) | Tier 1 `#184F95` · Tier 2 `#256ABF` · Tier 3 `#3987E5` · Tier 4 `#86B6EF` |
| **Neutral / no case** — tier 5, context | Muted chrome | `#898781` |
| **Risk / service failure** — unmet demand, stockouts, thin alignment | Status: Serious | `#EC835A` |
| **Unresolved investigation** — Daventry, Bristol markers | Status: Critical | `#D03B3B` |
| Categorical (site, category, supplier type) | Slots 1–8 in fixed order | `#2A78D6`, `#EB6834`, `#1BAF7A`, `#EDA100`, `#E87BA4`, `#008300`, `#4A3AA7`, `#E34948` |
| Chart surface / page background | | `#FCFCFB` / `#F9F9F7` |
| Primary / secondary / muted text | | `#0B0B0B` / `#52514E` / `#898781` |
| Gridline / axis | | `#E1E0D9` / `#C3C2B7` |

**Two style-guide constraints that bind here:**
- The tier ramp uses the **ordinal** rule — no lighter than step 250 — so tier 4 stays legible.
- Slots 3 (aqua), 4 (yellow), 5 (magenta) fall below 3:1 on light surfaces. **Wherever they are
  used, ship visible direct labels or a data table.** This applies to any category chart with four
  or more series.

**Typography:** Segoe UI. Page title 20pt semibold · visual title 14pt semibold · KPI value 26pt
semibold (reduced from 28 for the smaller canvas) · KPI label 11pt · body/table 10pt · caveat and
basis tag 9pt italic.

**Number formats:** `£#,##0` labels · `£#,##0.00` tooltips and tables · `£#,##0,K` axis only ·
`0.00%` rates · `0.0%` shares · `0.00×` turns · `0.0 days` · `#,##0` counts · `0.00` ratios.

**Visual defaults:** shadows off, borders off, gridlines hairline `#E1E0D9`, bars 4px rounded at
the data end.

**Global page furniture** (repeat on all six pages):
- Header band, y=0, h=56: page title left; right — "Synthetic dataset · calendar 2025 · anchor
  2025-12-31"
- Footer strip, y=690, h=30: "Figures reconcile to committed PostgreSQL results in
  `analysis/query_results/`. Decisions D-01 to D-40."
- Methodology button, top-right, opening a bookmark overlay (§9.4)

---

### PAGE 1 — Executive Overview

**Objective:** make the paradox unavoidable in ten seconds, size the opportunity honestly, and stop
the reader concluding "cut inventory".

**Layout sequence (1280 × 720):**

```
y=56   KPI strip — 5 primary tiles              (K1–K5, each 200×96, x=24..1016)
y=160  Opportunity group — bordered panel       (K6, K7 — 240×96 each, x=1024..1256)
y=272  P1-V1a Inventory by site                 (616×180, x=24)
y=272  P1-V2  Where the capital sits            (616×180, x=664)
y=460  P1-V1b Service failure by site           (616×160, x=24)
y=460  P1-V3  Opportunity hierarchy matrix      (616×160, x=664)
y=628  P1-V4  Central finding callout           (760×58, x=24)
y=628  P1-V5  Interpretation warning            (472×58, x=800)
```

**KPI cards**

| # | Title (finding-led) | Measure/column | Basis tag | Badge |
|---|---|---|---|---|
| K1 | Average inventory | `[Inventory Value]` | average of 52 weeks | |
| K2 | Closing inventory | `[Stock Value at Closing]` | at 2025-12-28 | |
| K3 | Inventory turns | `[Inventory Turns]` | 2025, on average stock | |
| K4 | Days inventory outstanding | `[Days Inventory Outstanding]` | 365 ÷ turns | |
| K5 | Order lines not supplied in full | `[Lines Short Rate %]` | calendar-year basis | |
| K6 | Working capital identified | `[Selected Opportunity Value]` | one-off | ▲ upper bound in part |
| K7 | Annual holding cost | `[Selected Annual Holding Cost]` | per annum · 22% assumed | |

K6/K7 panel caption: **"One-off capital · Annual cost — never added"**.

---

**P1-V1a · "Livingston holds the deepest cover in the network"**
*(subtitle: Average inventory by site, 2025)*

| | |
|---|---|
| **Type** | Horizontal bar, sorted descending, **starts at zero** |
| **Source** | `Fact Inventory KPI` |
| **Axis** | `Dim Warehouse[warehouse_name]` |
| **Value** | `[Inventory Value]` |
| **Axis title** | `Average inventory (£)` |
| **Data labels** | On, `£#,##0` |
| **Filters** | Category slicer applies |
| **Interactions** | Filters P1-V2 and P1-V3 on click |
| **Tooltip** | Report page `TT Site Inventory` (§9) |
| **Colour** | Categorical slot 1 for all bars (single series — no legend) |

**P1-V1b · "…and Bristol, holding the least, serves worst"**
*(subtitle: Order lines not supplied in full by site, 2025)*

| | |
|---|---|
| **Type** | Horizontal bar, **same category order as P1-V1a** (sort by inventory value, not by rate) |
| **Source** | `Fact Availability` |
| **Axis** | `Dim Warehouse[warehouse_name]` |
| **Value** | `[Lines Short Rate %]` |
| **Axis title** | `Order lines not supplied in full (%)` |
| **Data labels** | On, `0.00%` |
| **Colour** | Risk role `#EC835A` |
| **Interactions** | Filters P1-V2 and P1-V3 |
| **Tooltip** | Report page `TT Site Service` |

> **This pair replaces the spec's dual-axis P1-V1 (conflict C-1).** Keeping the same category
> order in both charts is what carries the comparison — the reader's eye tracks one site across
> two panels and sees the two measures do not move together, **without** a shared axis implying a
> relationship. Place P1-V1b directly below P1-V1a, left-aligned, same width.
>
> **Interpretation note:** four sites is not a sample. The pair shows **coexistence**, not
> correlation, and no trendline or R² may be added to either.

---

**P1-V2 · "Nearly half the estate has no case against it"**
*(subtitle: Closing stock by opportunity mechanism)*

| | |
|---|---|
| **Type** | Stacked horizontal bar, single bar, five segments |
| **Source** | `Fact Opportunity` |
| **Legend** | `opportunity_mechanism` (already sorts correctly — values begin `1 —`…`5 —`) |
| **Value** | `[Stock Value at Closing]` |
| **Colour** | Tiers 1–4 on the blue ordinal ramp; **tier 5 in neutral `#898781`** |
| **Data labels** | On for segments over 10% of total |
| **Filters** | Site, category |
| **Drill-through** | Right-click → Page 2 |
| **Tooltip** | Report page `TT Opportunity Tier` |

**Interpretation note:** the bar shows **stock held, not capital releasable**. Tier 2 holds
£416,075 of stock but only £303,558 is claimable, and that is an upper bound. Data labels read
stock value; releasable capital appears only in the tooltip and on Page 2.

---

**P1-V3 · "£468,897 identified — counted once, not summed"**
*(subtitle: The opportunity hierarchy)*

| | |
|---|---|
| **Type** | Matrix, 5 rows + total |
| **Source** | `Fact Opportunity` |
| **Rows** | `opportunity_mechanism` |
| **Columns** | Positions `[Positions]`* · Stock value `[Stock Value at Closing]` · **Working capital (£ one-off)** `[Selected Opportunity Value]` · **Annual holding cost (£ p.a., 22%)** `[Selected Annual Holding Cost]` · Basis (text) |
| **Filters** | Site, category |
| **Totals** | Row totals **on** for each column separately; **no cross-column total** |
| **Conditional formatting** | Data bars on Working capital only, blue ramp |
| **Tooltip** | `source_reference` |

\* `[Positions]` is `COUNTROWS('Fact Opportunity')` — add inline as an implicit count, no measure
needed.

**Basis column values:** Tier 1 *Definitional* · Tier 2 *Upper bound* · Tier 3 *Measured* · Tier 4
*Upper bound* · Tier 5 *None*. Enter as a calculated column on `Fact Opportunity`:

```
Basis =
SWITCH (
    'Fact Opportunity'[opportunity_mechanism],
    "1 — discontinued or obsolete exposure",                "Definitional",
    "2 — importer and minimum-order structural stock",       "Upper bound",
    "3 — above the calibrated replenishment requirement",    "Measured",
    "4 — slow-moving residual",                              "Upper bound",
    "None"
)
```

---

**P1-V4 · Central finding callout** — text box, no data binding.

> **£2.0m of inventory and a 7.71% line-fill failure are happening at the same time, at the same
> sites.**
> This is an **allocation and replenishment-design** problem, not an overstock or understock
> problem. Settings track where demand has been, not where it is going: rising-demand lines sit at
> 0.68 of the network's own working rule and falling-demand lines at 1.33. Separately, supplier
> minimums — not replenishment decisions — set the order quantity on 98.3% of importer purchase
> lines.

**Do not make this dynamic.** It is the network-level finding and would become false under a site
filter.

---

**P1-V5 · Interpretation warning** — text box, muted tinted background, not dismissible.

> **£468,897 is identified, not available.** Counted once across five mutually exclusive tiers;
> three of the four active tiers are upper bounds. **48.8% of the estate has no identified
> opportunity at all.** £252,435 — 53.8% — sits at two sites with unresolved service anomalies,
> where no broad inventory reduction is recommended. Capital released is one-off; holding cost
> saved is annual; they are never added.

**Slicers:** Site, Category. **No supplier slicer** (no relationship — it would silently do
nothing). **No product slicer** (would blank K1–K5 — §4.5 risk 7). **No time slicer** (fixed
period, D-05).

---

### PAGE 2 — Inventory & Working Capital

**Objective:** show where capital is tied up and what mechanism explains each pound.

**Layout:**
```
y=56   KPI strip — 5 tiles (K8–K12), 240×96
y=160  P2-V1 Inventory by site        (400×200, x=24)
y=160  P2-V2 Inventory by category    (400×200, x=440)
y=160  P2-V3 ABC Pareto               (392×200, x=856)
y=372  P2-V4 Hierarchy matrix         (760×230, x=24)
y=372  P2-V5 Why not summed           (472×230, x=800)
y=614  P2-V6 Slow-moving lands where  (1232×72, x=24)
```

**KPI cards:** K8 Closing inventory `[Stock Value at Closing]` *(at 2025-12-28)* · K9 Working
capital identified `[Selected Opportunity Value]` *(one-off, ▲ upper bound in part)* · K10 Annual
holding cost `[Selected Annual Holding Cost]` *(per annum)* · K11 Stock with no identified
opportunity `[Unclassified Stock Value]` *(at 2025-12-28)* · K12 Discontinued exposure —
`[Selected Opportunity Value]` with a visual-level filter on tier 1 *(one-off, definitional)*.

**P2-V1 · "Daventry holds half the network's capital"** — horizontal bar, `Fact Inventory KPI`,
axis `Dim Warehouse[warehouse_name]`, value `[Inventory Value]`, axis title `Average inventory
(£)`, sorted descending, from zero. Tooltip: `TT Site Inventory`.
*Note:* the bar is **average** inventory; closing is 16.3% lower network-wide (D-10).

**P2-V2 · "Heating and Tools turn slowest"** — horizontal bar, `Fact Inventory KPI`, axis
`Dim Category[category_name]`, value `[Inventory Value]`, **data label showing `[Inventory Turns]`
as a secondary label**, sorted by value, from zero. Category colours from slots 1–8; because that
exceeds three and includes low-contrast slots, **direct labels are mandatory** (style guide §1).
*Note:* low turns is not by itself a problem — Heating is seasonal (January index 1.78).

**P2-V3 · "Ten SKUs hold 36% of the capital"** — Pareto: column `average_stock_gbp` by `sku`
descending, line `cumulative_stock_share_pct`, from `Detail SKU Value`. **Line chart may use a
non-zero axis; the column axis starts at zero.** Category slicer applies; **site slicer does not**
(this view has no site column — set interaction to None). Tooltip: SKU, product name, sites
stocking, turns, `stock_value_class`, `cogs_class`.
*Note:* stock rank and COGS rank diverge — 30 SKUs worth £116,623 rank high on stock and low on
sales. The reverse cell is empty.

**P2-V4 · "Every pound explained once"** — matrix, `Fact Opportunity`. Rows
`opportunity_mechanism` → `Dim Warehouse[warehouse_name]` → `sku`. Values: Positions · Stock value
· **Working capital (£ one-off)** · **Annual holding cost (£ p.a.)** · at 20% · at 25%. Filters:
site, category, holding rate. Drill-through from SKU → Page 5. Tooltip: `service_consequence`,
`source_reference`, `unresolved_service_constraint`, `sourcing_last_used`,
`minimum_in_weeks_of_demand`, `cover_weeks`, `demand_direction`.
Add an icon column driven by `is_february_buy_ahead_position` with the tooltip *"February
buy-ahead residual already carved out of this figure (D-30, D-38)"*.
**Three money columns measuring different things. Units in every header. No cross-column total.**

**P2-V5 · "The same pounds, counted five times"** — waterfall or paired bar from
`Ref Exposure Comparison`. **Interactions: None** (static network figures). The naive-sum bar
`1109016` must be **hatched, labelled `✗ do not use`, in the risk colour** — style guide rule 7
requires meaning not to depend on colour alone, so the `✗` and the hatch are both required.
Tooltip: *"23 positions worth £70,857 are both slow-moving and above policy. 54.4% of high-cover
positions are also minimum-order constrained; 85.4% are also policy-authorised."*
**This is the only place £1,109,016 appears, and it appears in order to be rejected.**

**P2-V6 · "Slow-moving stock is a symptom, not a problem in itself"** — small table, `Fact
Opportunity` filtered to positions meeting file 03's slow rule, grouped by tier. Site slicer
applies. Tooltip: £23,725 discontinued · £34,954 minimum-order structural · £50,321 above the
calibrated rule · £14,373 unexplained residual.
*Note:* a finding about **classification**. The £123,373 did not shrink; it was explained.

**Slicers:** Site · Category · **Holding rate** (labelled "Holding cost rate — see D-11", with the
methodology button adjacent).

---

### PAGE 3 — Availability & Replenishment

**Objective:** explain why stockouts occur despite substantial inventory, and separate supported
from unresolved from rejected.

**Layout:**
```
y=56   KPI strip — 4 tiles (K13–K16), 300×96
y=160  P3-V1 Three measures by site      (616×200, x=24)
y=160  P3-V2 Availability vs cover       (616×200, x=664)
y=372  P3-V3 Direction × alignment       (400×220, x=24)
y=372  P3-V4 Outcome by alignment        (400×220, x=440)
y=372  P3-V5 Renewables                  (392×220, x=856)
y=604  P3-V6 Seasonal lag                (500×92, x=24)
y=604  P3-V7 Evidence status panel       (732×92, x=540)
```

**KPI cards — four, and they are a set:** K13 Weeks closing at zero `[Closing Zero Rate %]`
*(ISO-week basis)* · K14 Weeks with a zero-stock day `[Any Zero Day Rate %]` *(ISO-week basis)* ·
K15 Order lines not supplied in full `[Lines Short Rate %]` *(calendar-year basis)* · K16 Value of
demand not met `[Unmet Demand Value]` *(calendar-year basis, ▲ upper bound)*.

**K13–K15 must be displayed as a set of three, never individually.** *(K17 removed by approved
decision 3; no replacement added.)*

**P3-V1 · "Weekly snapshots miss two thirds of Bristol's stockouts"** — clustered column, three
series, `Fact Availability`, axis `Dim Warehouse[warehouse_name]`, values `[Closing Zero Rate %]`,
`[Any Zero Day Rate %]`, `[Lines Short Rate %]`. Axis title: `Three distinct availability measures
(%)`. Legend on; direct labels on (three series ≤ 4). Tooltip: `TT Three Measures`.
*Note:* **not three estimates of one quantity.** Quoting the lowest without the others is a choice
about which answer to give.

**P3-V2 · "Under two weeks of cover, nearly half of demand goes unmet"** — column chart from
`Ref Cover Bands`, axis `prior_cover_band`, value `unmet_unit_rate_pct`, from zero.
**Interactions: None.** Annotate the 46.70% bar (style guide rule 12).
*Note:* the relationship is not linear and the tail matters — 2,195 SKU-weeks sat on over six
months of cover and still produced £10,519 of unmet demand.

**P3-V3 · "Rising lines are set thin; falling lines are set deep"** — matrix from `Detail Policy
Alignment`. Rows `demand_direction`, columns `alignment_band`, values count of rows and median
`reorder_point_alignment_ratio`. Conditional shading on the count, blue ramp. Site and category
slicers apply.
**Annotate the "broadly flat" row: "calibration set — centres on 1.00 by construction (D-31)".**
The finding lives in the rising and falling rows.

**P3-V4 · "Thin settings cost twenty times more in service than deep settings cost in capital"** —
table from `Detail Policy Alignment` grouped by `alignment_band`: positions, mean cover weeks,
`unmet_units_pct`, `unmet_value_2025_gbp`, `days_at_zero_pct`, stock value.
*Note, and it must be a visible caption:* **this is not a ranking and "set deep" is not the goal.**
Deeper settings buy availability; that is what they are for. The finding is the asymmetry —
£25,502 a year of holding cost against **£505,019** of unmet demand.
Policy age may appear in the tooltip as descriptive only; it is **not** a column, axis or slicer.

**P3-V5 · "Renewables demand grew 85.5% while cover ran at a third of the network's"** — line
chart from `Ref Renewables` *(static table S6, §2.5)*, axis quarter, values demand units and line fill %. **Interactions: None.**
**Label the visual "Partially supported".**
*Mandatory note:* **only 40 stocked positions exist and 31 are at Daventry** — a category finding
resting on one site, and that site carries its own unresolved anomaly. Direction clear; breadth
not.

**P3-V6 · "Shortages arrive two months after the demand peak"** — table from `Ref Seasonal Lag`:
category, peak demand month, peak shortage month, months trailing, peak zero-days.
**Interactions: None.**
*Note:* Warrington Heating peaks in **March**, not December — the original assumption was wrong
and was corrected from the data (D-20). Two years gives one observation of each cycle.

**P3-V7 · Evidence status panel** — three-column text panel: **Supported · Unresolved · Rejected**.
Content exactly as `powerbi-dashboard-spec.md` P3-V7, which reproduces `findings.md`.

> **Policy age appears on Page 3 only inside the Rejected column.** It must not be a slicer, an
> axis, or a legend on any visual on this page.

**Slicers:** Site · Category. **No policy-age slicer** — offering one would imply age is a
dimension worth exploring, which D-21 and D-32 reject.

---

### PAGE 4 — Supplier & Sourcing Performance

> **Built as two pages.** The implemented dashboard splits this into **4a Supplier Reliability &
> Lead Time** and **4b Sourcing Economics**. As one page it carried 6 KPI tiles and 8 visuals at
> 1280 × 720, leaving the bottom row 112px — too little for a scatter chart, and three visuals were
> legible only in focus mode. It also answered two questions rather than one. The visuals, measures
> and findings below are unchanged; only their page allocation is. See D-42.

**Objective:** show the reliability / lead time / price / inventory trade-off without licensing
either "importers are bad" or "cut importers".

**Layout:**
```
y=56   KPI strip — 6 tiles (K18–K23), 200×96
y=160  P4-V1 On-time by supplier      (616×200, x=24)
y=160  P4-V2 Type trend + LOO         (616×200, x=664)
y=372  P4-V3 Meridian                 (400×200, x=24)
y=372  P4-V4 Lead-time distribution   (400×200, x=440)
y=372  P4-V5 Receiving site           (392×200, x=856)
y=584  P4-V6 Minimums                 (400×112, x=24)
y=584  P4-V7 Dual-source scatter      (400×112, x=440)
y=584  P4-V8 Buy-ahead                (392×112, x=856)
```

**KPI cards — six:** K18 On time, first receipt · K19 On time, all receipts · K20 OTIF, line
complete · K21 Split delivery rate · K22 Minimum-order increment bought 2025 *(**flow** — twelve
months of purchasing)* · K23 Average incremental cycle stock *(**level** — derived from the flow)*.

K18–K20 read the pre-computed columns from `Fact Supplier Delivery` **at the network row**, not
from a measure (§5.4). Implement as card visuals over `vw_kpi_supplier_on_time_delivery` filtered
to `grain_level = '1 — network'` — **query F4b `Fact Supplier Network`, 1 row (§2.2)**, rather than reconstructing numerators.

> **K22 and K23 must never be added.** One is twelve months of purchasing; the other an instant.

**P4-V1 · "Reliability spreads 34 points within the importer type alone"** — table from `Fact
Supplier Delivery`, sorted ascending by `otif_pct`, data bars on the three rate columns. Columns:
supplier name, type, `n_first_measurable`, `on_time_first_receipt_pct`, `n_all_measurable`,
`on_time_all_receipts_pct`, `n_lines_measurable`, `otif_pct`, `split_delivery_rate_pct`,
`cell_note`. Supplier-type slicer applies.
**Rows where `cell_note` contains "thin cell" must be visually muted** (conditional formatting on
font colour → muted `#898781`) **and carry no interpretation.** The `n` columns are not decoration
(style guide rule 11).

**P4-V2 · "The importer decline is one supplier, not a category"** — line chart. Measured series
from `Fact Supplier Trend` (`on_time_first_receipt_pct` by `supplier_type`, axis
`order_half_year`); **dashed leave-one-out series from `Ref Meridian Trend`**, labelled
*"Importers excluding Meridian"*. Four solid + one dashed = five series; legend on, direct labels
on the endpoints only.
**Interactions with the supplier-type slicer: None** (§4.4 consequence 1) — filtering to one type
destroys the comparison.
> **Mandatory:** the dashed line is not decoration. Without it the visual states a rejected
> conclusion (D-26). **Do not present "Far East importers are getting worse".**

**P4-V3 · "Meridian fell 49.5 points in two years"** — line chart from `Ref Meridian Trend`:
Meridian on-time % and network on-time %, axis half-year. **Interactions: None.** Annotate the
2025H2 point.
**Subtitle, not a tooltip:** *"The measurable window closes 2025-09-30 (D-14). 80% of importer
lines ordered after that date had not arrived by the end of the data, so 45.5% is the last
trustworthy reading, not the current state."*

**P4-V4 · "Importers quote 55 days and deliver in 78"** — table from `Fact Cycle Time By Type`
(4 rows) with `Fact Cycle Time` (29 rows) available on drill. Columns: type, `n_first_receipts`,
`quoted_lead_time_days`, `median_cycle_days`, `p25`, `p75`, `iqr_days`, `p90_cycle_days`,
`longest_cycle_days`, `stddev_days`, `median_overrun_vs_quoted_days`.
> **Percentiles must never be aggregated** (§4.5 risk 6). Set **all** slicer interactions on this
> visual to **None**. Mean and median shown together because the distribution is skewed.

**P4-V5 · "Livingston's raw overrun is five times its fitted site effect"** — small table from
view 06 `grain_level = '4 — receiving site'` *(query F6c `Fact Cycle Time By Site`, 4 rows — §2.2)*. Columns: site, `n_first_receipts`, `median_cycle_days`, `median_overrun_vs_quoted_days`.
**Interactions: None.**
> **Mandatory annotation:** naive marginals attribute **+10.1 days** to Livingston; the alternating
> two-way fit attributes **+1.8** (D-27). **Association, not causation** — the dataset cannot show
> the Monday goods-inwards batch *causes* the delay.

**P4-V6 · "On 99.3% of importer lines the supplier's minimum, not demand, set the quantity"** —
clustered column from `Detail Purchase Structure`, axis `supplier_type`, values `[Minimum Binds %]`
and `[Ordered At Minimum %]`, from zero, direct labels on (two series).
**Interactions with the supplier-type slicer: None** (§4.4 consequence 2). Site and category
slicers apply via R14/R15.
*Note:* a **flow** measure over twelve months. Never compared with, or added to, Page 2's standing
stock. Pipeline premium (£276,224 across 134 dual-source positions) goes in the tooltip.

**P4-V7 · "The cheaper source is a Far East importer in all 60 cases"** — scatter from
`Detail Dual Source`. X `dear_premium_pct`, Y ratio of `cheap_moq` to `dear_moq`, size
`cheap_units`, **legend `cheap_supplier_type`** — which resolves to a single series, and that is
the finding (conflict C-7 resolution). Category moves to the tooltip. Points ≥ 8px with a 2px
surface ring.
> **Mandatory caption:** annualised, the price saving is **£492,020** against **£604,231** of
> one-off working capital — net **+£359,089** at 22%. **Re-sourcing away from importers to release
> capital would forfeit more than it releases.** Do not present importer reduction as a
> recommendation.

**P4-V8 · "The February buy-ahead paid for itself a hundred times over"** — three-row card or
small table from `Ref Buy Ahead`: price saving £146,490 · residual at 2025-12-28 **£6,971 (upper
bound)** · net **+£145,148** at 22%. **Interactions: None.**
> **Mandatory:** economically successful; **must not be classified as excess inventory** (D-30).
> Its residual is already carved out of every Page 2 tier (D-38), so it cannot be double counted.

**Slicers:** **Supplier type** — bound to `Dim Supplier[supplier_type]` (§4.4) — and **Category**.
A Supplier slicer is optional; if added, it will not filter F5, D3 or D4, and will offer one
supplier name that blanks every visual (§4.4 consequence 3). **No site slicer** as a primary
control.

---

### PAGE 5 — Site Investigations & Decision Watchlist

**Objective:** let leadership compare sites and reach the two unresolved investigations without
either being softened into a conclusion.

**Layout:**
```
y=56   Dynamic title bar — [Dynamic Insight Title]   (1232×40, x=24)
y=104  KPI strip — 6 context tiles                    (200×88)
y=200  P5-V1 Site scorecard                           (760×200, x=24)
y=200  P5-V2 Opportunity by site and mechanism        (472×200, x=800)
y=412  P5-V3 Position watchlist                       (1232×180, x=24)
y=604  P5-V4 Unresolved Constraints panel             (1232×92, x=24)
```

**Dynamic title:** card visual bound to `[Dynamic Insight Title]`, 16pt semibold.

**KPI cards (context, respond to the site slicer):** average inventory · turns · DIO · line fill %
· unmet value *(▲ upper bound)* · working capital identified *(one-off)*. All carry the same basis
tags as their Page 1 and 2 equivalents.

**P5-V1 · "Livingston's 2.84 turns survive every correction; Daventry's 4.68 does not"** — matrix,
four site rows. Columns from `Fact Inventory KPI`, `Fact Availability`, `Fact Opportunity`:
average inventory · closing inventory · turns · DIO · closing-zero % · any-zero-day % · line fill %
· unmet value · mean cover weeks · working capital · annual holding cost. Category slicer applies.
> **Mandatory note, prominently placed:** **do not rank sites on raw turnover.** 145 of 250 SKUs
> are stocked only at Daventry. On the range all four carry, Daventry turns **6.82** — second only
> to Bristol. Two valid range-mix corrections **disagree** and the disagreement is the finding
> (D-23).

**P5-V2 · "More than half the opportunity sits at the two constrained sites"** — stacked column,
`Fact Opportunity`, axis `Dim Warehouse[warehouse_name]`, legend `opportunity_mechanism`, value
`[Selected Opportunity Value]`, from zero. Category and holding-rate slicers apply.
**Daventry and Bristol columns carry a `▲` marker in the unresolved colour `#D03B3B`**, linked to
P5-V4. Colour is not alone — the glyph carries it too.

**P5-V3 · Position watchlist** — table, `Fact Opportunity` filtered to `working_capital_gbp > 0`.
Columns: mechanism · SKU · product name · site · category · `sourcing_last_used` ·
`minimum_in_weeks_of_demand` · `quantity_on_hand` · `position_stock_value_gbp` · `releasable_units`
· `working_capital_gbp` · `annual_holding_cost_gbp` · `cover_weeks` · `demand_direction` ·
`reorder_point_alignment_ratio` · `source_reference`. Sorted by `working_capital_gbp` descending.
**Drill-through target** from P1-V1a/b, P2-V4 and P5-V2 — keep the filter card visible.
Tooltip: `service_consequence` and `unresolved_service_constraint` in full.
> **The `service_consequence` column must not be hidden.** It is the reason each row is not free
> money.

**P5-V4 · Unresolved Constraints / Further Investigation** — two bordered text panels plus a shared
conclusion. **A first-class section, not a footnote. Interactions: None** — the text is fixed and
must never appear to change under a filter.

Content **verbatim** from `powerbi-dashboard-spec.md` P5-V4, which reproduces `findings.md`
F-U1 and F-U2: the Daventry panel (2.60% unmet in well-covered weeks, 33 short weeks, £68,451, six
tested-and-failed explanations, **no cause stated**, constrains £128,749); the Bristol panel (March–
April peak, three explanations that do not fit, **no cause stated**, constrains £123,686, 59.1%
releasable on the worst-serving site); and the shared conclusion panel (**no broad inventory
reduction at either site until the service behaviour is understood**; discontinued clearance is
safe because the demand claim is definitional; **investigation priorities, not failed analyses**).

> **No visual on this page may display a computed "cause", "driver" or "root cause" field for
> either site.** No such field exists in any view and none may be constructed in DAX.

**Slicers:** Site · Category · Opportunity mechanism · Holding rate.

---

## 8. Navigation

### 8.1 Buttons
A persistent 40px navigation rail along the bottom of every page, above the footer strip: five
page buttons in narrative order, plus **Home** and **Back**.

| Button | Action | State |
|---|---|---|
| Overview / Inventory / Availability / Supplier / Sites | Page navigation | Current page highlighted, others in secondary text tone |
| **Home** | Page navigation → Page 1 | Always enabled |
| **Back** | Back (returns from a drill-through to the originating page) | Only visible on Page 5 and on the methodology overlay |

Use **Buttons → Navigator → Page navigator** for the five page buttons — it stays in sync if a page
is renamed. Add Home and Back as separate buttons; the page navigator does not provide Back.

Set **on-hover** and **on-press** states for every button. A dashboard that does not respond to
hover feels broken (style guide §5).

### 8.2 Page flow
**Overview → Inventory & Working Capital → Availability & Replenishment → Supplier Reliability &
Lead Time → Sourcing Economics → Site Investigations.** The order follows the argument: *here is the paradox* → *where the capital
is* → *why service fails anyway* → *what upstream causes it* → *what to do and what we still do
not know*.

The journey deliberately **ends at what is not known**.

### 8.3 Drill-through — where it is appropriate

| From | To | Carries | Rationale |
|---|---|---|---|
| P1-V1a / P1-V1b site bar | Page 5 | Site | Executive → site investigation |
| P1-V2 tier segment | Page 2 | Mechanism | Overview → mechanism detail |
| P2-V4 SKU row | Page 5 (P5-V3) | SKU + site | Hierarchy → position detail |
| P5-V2 site column | P5-V3 | Site + mechanism | Within-page refinement |

Configure Page 5 as a drill-through target with `Dim Warehouse[warehouse_name]`,
`Fact Opportunity[opportunity_mechanism]` and `Dim Product[sku]` in the drill-through field well.
**Keep "Keep all filters" on**, and leave the filter card visible so context is never invisible.

### 8.4 Drill-through — where it must NOT be used

| Not from | Why |
|---|---|
| Any `Ref` static table visual (P2-V5, P3-V2, P3-V5, P3-V6, P4-V3, P4-V8) | No relationships — drill-through would carry no filter and produce a misleading unfiltered page |
| P3-V7 evidence status panel | Text, not data |
| P5-V4 unresolved panel | Text, and drilling from an unresolved finding into filtered data implies the filter explains it |
| P4-V4 lead-time distribution | Percentiles are not aggregable; a drill-through would re-aggregate them |
| P4-V2 type trend | F5 has no dimension relationships |

### 8.5 Serving both audiences

**Recruiter (60 seconds, Page 1 only):** KPI strip → P1-V1a/b pair → P1-V4 callout → P1-V3
hierarchy → P1-V5 warning. They should leave with: *this analyst quantified an opportunity, then
spent equal effort explaining why it is smaller and more conditional than it looks.*

**Operations stakeholder (full journey):** Pages 1→5 with slicers and drill-through, ending at the
watchlist and the two open investigations.

---

## 9. Tooltip strategy

**Principle:** the primary pages stay executive-friendly. Methodology lives in tooltips and the
overlay, one hover away — never on the canvas.

### 9.1 Report-page tooltips to build

Create each as a hidden page, size **Tooltip** (320×240), with *Page information → Allow use as
tooltip* on.

| Tooltip page | Attached to | Contents |
|---|---|---|
| `TT Site Inventory` | P1-V1a, P2-V1, P5-V1 | Average stock · closing stock · closing vs average % · turns · DIO · holding cost at 22% · *"Inventory is the mean of 52 weekly snapshots, never closing stock (D-10)."* |
| `TT Site Service` | P1-V1b | Demand lines · lines not in full · line fill % · unmet units · unmet value · *"Order-date basis, calendar 2025. Unmet demand is an upper bound — substitution is not modelled."* |
| `TT Opportunity Tier` | P1-V2, P1-V3, P2-V4, P5-V2 | Tier · positions · stock value · working capital · annual holding cost · `service_consequence` · `source_reference` · *"Capital is one-off; holding cost is annual. Never added."* |
| `TT Three Measures` | P3-V1 | All three rates with numerators and denominators · `snapshot_understatement_factor` · *"Weekly snapshots miss stockouts that clear before Sunday. ISO-week basis for measures 1–2, calendar-year for measure 3; the £2,591 difference is the 133 lines dated 29–31 December (D-13, D-22)."* |
| `TT Supplier Cell` | P4-V1 | All three on-time measures with denominators · `n_not_measurable` · `n_outside_window` · `cell_note` · *"Cells under ten observations carry no interpretation (D-15)."* |
| `TT Cycle Distribution` | P4-V4 | n · quoted · median · mean · p25/p75/p90 · longest · stddev · *"Percentiles are valid only at this grain and are never aggregated."* |
| `TT Position` | P5-V3 | `service_consequence` · `unresolved_service_constraint` · `source_reference` in full |

### 9.2 What tooltips must carry
Definitions · denominators · **upper-bound warnings** · sample sizes · measurement limitations ·
the relevant decision ID. A reader hovering a number should be one second from knowing what it does
**not** mean.

### 9.3 Default tooltips
Every other visual keeps a default tooltip with its own fields — style guide §5 requires a tooltip
on every chart element. Do not leave any visual with tooltips off.

### 9.4 Methodology overlay
A bookmark-driven full-page overlay, opened by the header button on every page, containing: the
22% rate derivation with all four components and the note that **only the capital component has a
primary source** (D-11) · the 20%/25% sensitivity · the list of upper bounds · the two clocks and
the £2,591 boundary · the note that the 5% risk component comes from the published benchmark, not
this dataset's 7.9% observed loss (D-12). Close via a Back button.

---

## 10. Validation procedure

Run in order. Pass/fail; no partial passes. Record results in `docs/technical/powerbi-validation-log.md`.

### 10.1 KPI reconciliation

| KPI | Expected | Source |
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
| Annual holding cost | £103,157.38 | `report_07` |
| Tier 5 unclassified | £835,218.54 | `report_07` |

☐ All 17 reconcile.
☐ **Availability rates read from M4/M5/M6, which divide committed integer counts** — not from a
numerator reconstructed by multiplying a rounded percentage.

### 10.2 Grain validation
☐ Row counts after import exactly: F1 **32** · F2 **32** · F3 **515** · F4 **29** · F4b **1** ·
F5 **16** · F6 **29** · F6b **4** · F6c **4** · D1 **250** · D2 **467** · D3 **2,063** · D4 **60** ·
Dim **4 / 8 / 30 / 250**. Static: S1 **8** · S2 **6** · S3 **8** · S4 **8** · S5 **3** · S6 **8**.
☐ `[Inventory Value]` unfiltered = **£2,043,979**, not a multiple. Near £8.2m means an unfiltered
`grain_level` import.
☐ `[Stock Value at Closing]` unfiltered = **£1,711,042**.
☐ Site totals sum to network within £0.05; category totals likewise.
☐ Adding a category slicer to a site visual does not change the network total.
☐ `grain_level` column deleted from every fact after filtering.
☐ No product slicer on Pages 1, 2 or 3.

### 10.3 Opportunity hierarchy
☐ F3 = **515** rows; distinct `(sku, warehouse_code)` = **515**.
☐ `SUM(position_stock_value_gbp)` = **£1,711,041.86** — total stock, subject only to documented
penny rounding.
☐ Five tiers are the only values of `opportunity_mechanism`.
☐ Tier 5 `working_capital_gbp` = exactly **0**.
☐ No row has `working_capital_gbp > position_stock_value_gbp`.
☐ Tier capital sums 87,478 + 303,558 + 70,755 + 7,106 = **468,897**.
☐ Tier holding costs sum 19,245 + 66,783 + 15,566 + 1,563 = **103,157** at 22%.
☐ **£1,109,016 appears in exactly one place — P2-V5 — and is marked as the error.**

### 10.4 Inventory KPI reconciliation
☐ Average stock £2,043,979.36 · closing £1,711,041.86 · COGS £9,550,572.04 · turns 4.67 · DIO 78.2.
☐ Site figures: DAV 4.68 / 78 · LIV 2.84 / 129 · WAR 5.63 / 65 · BRS 7.13 / 51.
☐ M2 and M3 are recomputed ratios, not sums of the views' rate columns.

### 10.5 Availability reconciliation
☐ **3.52%** · **5.05%** · **7.71%**, each from its committed integer numerator and denominator.
☐ All three appear together on Page 3; none appears alone anywhere.
☐ K17 does not exist.

### 10.6 Supplier KPI reconciliation
☐ 89.8% / 80.1% / 79.1% read from the view's own network row, at the view's grain.
☐ No DAX measure recomputes an on-time or OTIF percentage.
☐ Percentiles displayed only at their own row grain; all slicer interactions on P4-V4 set to None.
☐ Thin cells muted and uninterpreted.

### 10.7 Timing convention
☐ ISO-week measures (M5, M6) and calendar-year measures (M4, M7) are labelled with their basis on
every card and axis.
☐ The **£2,591** difference is stated in `TT Three Measures` and the methodology overlay, and is
**not silently reconciled**.
☐ No visual places an ISO-week rate and a calendar-year rate on one axis without both bases
labelled.
☐ No date slicer offers a period other than 2025.

### 10.8 Upper bounds
☐ K6, K9, K16 and the tier 2 / tier 4 rows carry a visible `▲ upper bound` marker.
☐ No card, title or tooltip calls an upper bound a "saving", "benefit realised", "available" or
"releasable now".
☐ Tier 1 marked *Definitional*, tier 3 *Measured* — neither mislabelled as a bound.
☐ £6,971 labelled an upper bound wherever it appears.

### 10.9 Unresolved findings
☐ No visual, title, tooltip, insight card or narrative assigns a cause to **Daventry's** anomaly.
☐ No visual, title, tooltip, insight card or narrative assigns a cause to **Bristol's** March–April
shortfall.
☐ No measure or calculated column named "cause", "driver", "reason" or "root cause" exists for
either site.
☐ P5-V4 wording matches `findings.md` F-U1/F-U2 verbatim, not paraphrased.
☐ Constraint markers appear on Daventry and Bristol on **every** page where their opportunity is
shown — 1, 2 and 5.
☐ Both presented as **investigation priorities**, not failed analyses.

### 10.10 Rejected hypotheses
☐ **Policy age** is not a slicer, axis or legend anywhere; it appears only in P3-V7's Rejected
column and as a descriptive tooltip field.
☐ **Review recency** is not presented as causal anywhere.
☐ The **February buy-ahead** is presented as net positive and never as the cause of network excess.
☐ P4-V2 carries the dashed leave-one-out series; **no visual states "Far East importers are getting
worse"**.
☐ No site ranking on raw turnover without the range-mix warning.

### 10.11 One-off versus annual
☐ M8 and M9 never share a visual axis.
☐ No measure, calculated column, matrix total or text sums the two.
☐ Every card carries `one-off` or `per annum`.
☐ K6/K7 and K9/K10 sit in the captioned group.
☐ K22 (flow, £995,659) and Page 2's stock figures never share a visual.
☐ The holding-rate parameter changes M9 and **does not** change M8.

### 10.12 Style guide compliance
☐ **No dual-axis chart anywhere** (Hard Rule 1).
☐ Every bar chart starts at zero.
☐ Bars sorted by value unless the category has inherent order (tiers, months, cover bands).
☐ Every visual title states a finding.
☐ Axes labelled with units.
☐ Legend for ≥2 series; direct labels where ≤4.
☐ Meaning never depends on colour alone — every colour paired with a label, glyph or texture.
☐ Scatter (P4-V7) uses one colour series.
☐ Low-contrast slots (aqua/yellow/magenta) carry visible direct labels.
☐ `n` stated wherever a segment is small.
☐ Page size 1280×720 on all six pages.
☐ Custom theme applied; stock theme not in use.
☐ Shadows and borders off.
☐ Legible at 880px.
☐ **Rendered and actually looked at** — no clipped labels, no overflow, no collisions.

---

## 11. Build order

| # | Step | Gate before proceeding |
|---|---|---|
| 1 | Confirm the PostgreSQL pipeline is available | §1.4 query returns 4 rows |
| 2 | Create the theme JSON from §7.0 and apply it | Theme visible in View → Themes |
| 3 | Import the 15 objects as 17 queries (§2) | All 17 load without error |
| 4 | Apply Power Query transformations (§3) — grain filters, types, percentage divide, merges | **§10.2 row counts exactly correct** |
| 5 | Create the 6 static reference tables S1–S6 (§2.5) | Values match committed results |
| 6 | Build the 15 relationships (§4.1–4.2) — **R10 is not among them** | Model view shows no dotted/inactive lines and no ambiguity warnings |
| 7 | Validate raw grain: unfiltered `[Inventory Value]` and `[Stock Value at Closing]` | §10.2 passes |
| 8 | Create `Param Holding Rate` and the `Basis` calculated column | 3 rows, default 22% |
| 9 | Create `_Measures` and the 16 DAX measures (§5) | Each returns its §10.1 validation value |
| 10 | Build **Page 1** | §10.1, §10.11 pass for Page 1 |
| 11 | **Validate Page 1 before building anything else** | Every Page 1 card reconciles |
| 12 | Build Pages 2, 3, 4, 5 | Each page's figures reconcile as built |
| 13 | Configure interactions — every `Ref` visual set to None; §4.4 exceptions on P4-V2, P4-V4, P4-V5, P4-V6 | Slicers move only what they should |
| 14 | Configure navigation (§8) — rail, Home, Back, drill-through targets | Round-trip works from every entry point |
| 15 | Build the 7 tooltip pages and the methodology overlay (§9) | Every visual has a tooltip |
| 16 | Full reconciliation — §10.1 to §10.12 end to end | All boxes ticked |
| 17 | Presentation QA — render every page, look at it, fix clipping and collisions | Legible at 880px |
| 18 | Capture screenshots — 2× downscaled to ~1600px, PNG < 500 KB, `NN_description.png` in `powerbi/screenshots/` | One per page, **six total** |
| 19 | Save as `powerbi/calderfield_inventory_supply_chain.pbix` | |

**Do not skip step 11.** Validating Page 1 before building Pages 2–5 catches a model error while
one page needs fixing rather than five.

---

## 12. Items requiring your input in Power BI Desktop

Six things this guide cannot supply.

1. **Connection credentials** — host, port, username, password (§1.2). Enter once at the Power BI
   prompt; let Windows credential manager hold them.
2. **Whether the full 35-file pipeline has been run** on your instance (§1.4). If not, D1–D4 will
   not exist and the import fails at step 3.
3. **Theme JSON authoring.** §7.0 gives every hex and every role mapping, but the JSON file itself
   must be written and applied in Desktop.
4. **The six static reference tables** must be typed by hand via Enter Data. S1's exact
   values are given in §2.5; the rest come from the named committed results.
5. **Exact pixel placement.** §7 gives a layout grid at 1280×720; final nudging is a Desktop
   activity.
6. **Whether to include the optional Supplier slicer on Page 4** (§4.4 consequence 3). It will
   offer one supplier name that blanks every visual, which is honest but may look like a bug to a
   reviewer.

---

## 13. Verification of this guide

☑ **Consistent with `powerbi-dashboard-spec.md`** — same visuals and measures; Page 4 is built
as two pages (4a / 4b, D-42), giving six in total. Same
constraints. Seven style-guide conflicts documented in §0 and resolved in the style guide's favour
per approved decision 5. The spec itself is unedited.
☑ **K17 removed** — the card, and the spec's measure M5 `Unit Fill Rate %` which served only it.
No replacement availability KPI added; the three core measures remain (§5.1, §10.5). The measure
count is **16**, not 15: one removed, and one (`Unmet Demand Value`) formalised because the spec
named it as K16's source without defining it. Arithmetic stated in §5.1.
☑ **No new SQL required** — all 15 objects already exist; verified against `information_schema`.
☑ **No monthly supplier aggregation introduced** — approved decision 4 respected. `vw_demand_line`
is not imported and P3-V5 uses committed `analyse_08` figures at the existing quarterly grain.
☑ **Supplier-type authority traced, not assumed** (§4.4) — all four candidate fields lineage-traced
to source and value-profiled against the live database. Three are the same base attribute; the
fourth is a different concept (position, not supplier) carrying D-18.
☑ **Style guide inspected** — 13,033 bytes staged from the device and read in full. Palette,
hard rules, mark specs, layout rules, tool-specific Power BI section and publishing checklist all
applied.
☑ **No unsupported finding introduced** — every figure traces to a committed result; every
interpretation note cites a finding ID or decision.
☑ **Row counts verified against the live database**, not estimated.

---

*Build preparation only. No `.pbix` exists. Implementation awaits approval.*
