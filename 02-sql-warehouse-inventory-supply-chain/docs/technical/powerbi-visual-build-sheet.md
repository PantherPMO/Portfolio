# Power BI Visual Build Sheet
## Project 02 — Warehouse Inventory & Supply Chain Performance

**What this is.** The settings layer. `powerbi-build-guide.md` tells you *what* each
visual says and *why*; this sheet tells you which boxes to tick and what to type in them, so
building is mechanical rather than a series of judgement calls.

**How to use it.** Apply §1 to every visual you create, take the recipe for its type from §2, then
find its row in §4. Nothing in §4 repeats what §1 and §2 already cover.

**Where this sheet overrides the guide.** Three places, all flagged in §5. Everything else
matches the approved specification.

---

# 1. Universal settings — apply to every visual

Set these once per visual, before anything else. They are the reason visuals clip, overflow and
look inconsistent.

| Format pane path | Value | Why |
|---|---|---|
| General → Properties → Position | Type X, Y, W, H from §4 | Never drag. Power BI has no collision detection |
| General → Title → Font | Segoe UI Semibold, 14pt, `#0B0B0B` | §8.4 |
| General → Title → Text | The finding, from §4 | Hard Rule 4 — titles state findings, not variables |
| General → Subtitle | On where §4 gives one, 10pt, `#52514E` | |
| General → Effects → Background | On, `#FCFCFB` | Chart surface, not page background |
| General → Effects → Border | **Off** | §6 of the style guide |
| General → Effects → Shadow | **Off** | Chartjunk, Hard Rule 8 |
| General → Properties → Padding | 4px all sides | Default eats plot area |

## 1.1 The fit block — this is what stops the clipping

A bar chart with four categories in a 180px frame will silently show two of them and add a
scrollbar. These five settings buy back the space, in order of how much they give you:

| Setting | Value | Recovers |
|---|---|---|
| Y axis → Title | **Off** | ~18px of height |
| Bars → Inner padding | **10%** (default 20%) | roughly one category row |
| Y axis → Values → Font size | **9pt** | ~4px per row |
| Category labels | Short names — see §3 | up to 40% of plot **width** |
| General → Effects → Border, Shadow | Off | 4–6px each side |

**Do not go below 9pt to force a fit.** If it still clips after all five, the frame is too small —
enlarge it and move what sits below, rather than shrinking the type.

**Always verify in Focus mode.** Click the visual → the diagonal-arrows icon in its header. It
renders full-screen. If all categories appear there and not on the page, it is purely sizing.

---

# 2. Recipes by visual type

## 2.1 Clustered bar chart (horizontal)

Used for: P1-V1a, P1-V1b, P2-V1, P2-V2, P2-V5.

| Setting | Value |
|---|---|
| X axis → Title | On, with units — `Average inventory (£)` |
| X axis → **Start** | blank or `0` — **Hard Rule 2, bars start at zero** |
| X axis → Values → Display units | `None` for £ under 1m; `Thousands` above |
| Y axis → Title | Off |
| Y axis → Values | Segoe UI 9pt, `#52514E` |
| Bars → Inner padding | 10% |
| Bars → Colors | Single colour from §4 unless a rule is given |
| Data labels | **On**, Display units `None`, decimals per §4 |
| Data labels → Overflow text | Off |
| Legend | Off for single series |
| Gridlines | Horizontal off, vertical `#E1E0D9` 1px |
| Sort | ⋯ → Sort axis → field from §4 → direction from §4 |

## 2.2 Clustered / stacked column chart (vertical)

Used for: P3-V1, P3-V2, P4-V6, P5-V2.

Same as §2.1 with the axes swapped, plus:

| Setting | Value |
|---|---|
| Y axis → Title | On, with units |
| Y axis → Start | `0` |
| X axis → Values → Font size | 9pt; **Concatenate labels** Off |
| Legend | On, **Bottom**, 9pt, when 2+ series |
| Data labels | On when ≤ 4 series (style guide rule 6) |

## 2.3 Stacked bar — single bar (P1-V2 only)

| Setting | Value |
|---|---|
| Y-axis well | **Empty** — this is what gives one bar |
| Orientation | **Horizontal**, spanning the full frame width |
| Bars → Colors | Per legend value, §4 |
| Data labels | On; Overflow text **Off**; Display units `None` |
| Legend | On, Bottom, 9pt |
| X axis | Off (the labels carry the values) |

## 2.4 Matrix

Used for: P1-V3, P2-V4, P3-V3, P5-V1.

| Setting | Value |
|---|---|
| Row headers → Font | 9pt |
| Row headers → +/- icons | On only where §4 says drill |
| Row headers → Stepped layout | **Off** — each level gets its own column |
| Column headers → Font | 9pt Semibold; **units in the header text** |
| Values → Font | 9pt |
| Row subtotals | **Off** |
| Column subtotals | **Off** |
| Grand total (rows) | On only where §4 says so |
| Grid → Vert/Horiz gridlines | `#E1E0D9`, 1px |
| Specific column → Rename for this visual | Exactly as §4 gives it |

**Never add a cross-column total** anywhere a matrix carries both a one-off £ and an annual £.

## 2.5 Table

Used for: P2-V6, P3-V4, P3-V6, P4-V1, P4-V4, P4-V5, P4-V8, P5-V3.

| Setting | Value |
|---|---|
| Values → Font | 9pt; **Row padding** 2 |
| Column headers → Font | 9pt Semibold |
| Totals | Off unless §4 says otherwise |
| Aggregation on pre-computed columns | **Don't summarize** — never Sum, never Average |
| Word wrap → Column headers | On |
| Word wrap → Values | Off |

**The aggregation rule is load-bearing.** Medians, percentiles and rates are valid only at their
own grain. Summing them produces nonsense; averaging them produces a wrong answer that looks
plausible.

**Use "Don't summarize", not "First".** Power BI offers First only for text and date fields — for
numeric columns the field-well list is Sum / Average / Minimum / Maximum / Count / Count (Distinct)
/ Standard deviation / Variance / Median. "Don't summarize" is the right setting anyway: it shows
each row's own value, so a table bound to the wrong source shows the wrong row count immediately
rather than hiding the error behind a plausible single number.

**Cards are the exception** — they require an aggregation and do not offer "Don't summarize". Where
the source has exactly one row (`Fact Supplier Network`), use **Minimum**: Average, Minimum and
Maximum all return the same value, and Minimum fails visibly if a second row ever appears.

## 2.6 Card / KPI tile

Four elements, grouped. Built once, copied.

| Element | Setting |
|---|---|
| Card → Callout value | Segoe UI Semibold **24pt** (not 26 — see §5), Display units **None** |
| Card → Category label | **Off** |
| Card → Effects → Background | On `#FCFCFB`; Border Off; Shadow Off |
| Text box above | Label, Segoe UI 11pt, `#52514E` |
| Text box below | Basis tag, Segoe UI **Italic 9pt**, `#898781` |
| Text box (badge, where required) | `▲ upper bound`, 9pt, `#D03B3B` |
| Finally | Ctrl-click all four → Format ribbon → **Group** |

**The basis tag is mandatory on every tile.** It occupies the slot the style guide reserves for a
"vs target" comparison, which this project cannot honestly supply.

## 2.7 Line chart

Used for: P2-V3 (line half), P4-V2, P4-V3, P3-V5 (line half).

| Setting | Value |
|---|---|
| Lines → Stroke width | **2px** |
| Lines → Markers | Off, unless individual points are read — then ≥ 8px |
| Lines → Line style | Solid; **Dashed** for any leave-one-out or counterfactual series |
| Y axis → Start | May be non-zero where the range is genuinely narrow — say so in the subtitle |
| Data labels | Endpoints and the annotated point only — never every point |

## 2.8 Scatter (P4-V7 only)

| Setting | Value |
|---|---|
| Markers → Size | ≥ 8px |
| Markers → Border | 2px in surface colour |
| Colour series | **Maximum 3** — style guide cap |
| X axis → Title | With units |

## 2.9 Text callout / warning banner

| Setting | Value |
|---|---|
| Rectangle → Fill | `#F9F9F7` |
| Rectangle → Border | 1px, `#C3C2B7` (neutral) or `#D03B3B` (unresolved) |
| Rectangle → Z-order | **Send to back** |
| Text box → Font | 9–10pt per §4, `#0B0B0B` |
| Text box → Position | Same X/Y/W/H as the rectangle, inset 8px |

**Keep callout text to what fits.** A 58px-high box holds roughly one sentence at 10pt across
760px. The detail belongs in a tooltip, not in an overflowing box.

## 2.10 Slicer

| Setting | Value |
|---|---|
| Slicer settings → Style | **Dropdown** (List only where §4 says so) |
| Header | On, 9pt, `#52514E` |
| Effects → Border, Shadow | Off |
| Placement | **One row along the top**, inside the header band — never scattered |

---

# 3. Short label mapping

Long category names are the single biggest consumer of plot width in this report. Add a short-name
column to `Dim Warehouse` and use it on every axis; keep the full name for tooltips.

```dax
Site = 
SWITCH (
    'Dim Warehouse'[warehouse_code],
    "DAV", "Daventry",
    "LIV", "Livingston",
    "WAR", "Warrington",
    "BRS", "Bristol",
    'Dim Warehouse'[warehouse_code]
)
```

| Use `Dim Warehouse[Site]` on | Use `[warehouse_name]` on |
|---|---|
| Every axis and legend | Tooltips, and the P5-V1 matrix rows |

Tier labels stay exactly as they are in the data — the leading digit is what sorts them.

---

# 4. Per-visual build tables

Positions are X, Y, Width, Height at a 1280 × 720 canvas.

## 4.1 Page 1 — Executive Overview

**Positions revised.** The guide's original frames clip four categories. These give the two bar
charts more height, taken from the gaps. See §5.

| ID | Type | X | Y | W | H |
|---|---|---:|---:|---:|---:|
| K1–K5 | Card group | 24 / 224 / 424 / 624 / 824 | 56 | 200 | 96 |
| K6 | Card group | 1024 | 56 | 240 | 96 |
| K7 | Card group | 1024 | 160 | 240 | 96 |
| K6/K7 panel | Rectangle | 1016 | 48 | 256 | 216 |
| P1-V1a | Clustered bar | 24 | 264 | 616 | 192 |
| P1-V2 | Stacked bar | 664 | 264 | 616 | 192 |
| P1-V1b | Clustered bar | 24 | 464 | 616 | 176 |
| P1-V3 | Matrix | 664 | 464 | 616 | 176 |
| P1-V4 | Text callout | 24 | 648 | 760 | 56 |
| P1-V5 | Text callout | 800 | 648 | 472 | 56 |
| Slicers ×2 | Slicer | 900 / 1080 | 8 | 170 | 40 |

The panel rectangle must be **sent to back** and carry a caption text box at its top, 9pt semibold:
**"One-off capital · Annual cost — never added"**. That caption is the guard against the most
likely misreading in the dashboard — someone adding £468,897 to £103,157.

### KPI tiles

| # | Label | Field / measure | Basis tag | Badge | Expected |
|---|---|---|---|---|---|
| K1 | Average inventory | `[Inventory Value]` | average of 52 weeks | | £2,043,979 |
| K2 | Closing inventory | `[Stock Value at Closing]` | at 2025-12-28 | | £1,711,042 |
| K3 | Inventory turns | `[Inventory Turns]` | 2025, on average stock | | 4.67 |
| K4 | Days inventory outstanding | `[Days Inventory Outstanding]` | 365 ÷ turns | | **78.2** |
| K5 | Order lines not supplied in full | `[Lines Short Rate %]` | calendar-year basis | | 7.71% |
| K6 | Working capital identified | `[Selected Opportunity Value]` | one-off | ▲ upper bound in part | £468,897 |
| K7 | Annual holding cost | `[Selected Annual Holding Cost]` | per annum · 22% assumed | | £103,157 |

### Chart wells and settings

| ID | Well | Field | Setting | Value |
|---|---|---|---|---|
| **P1-V1a** | Y-axis | `Dim Warehouse[Site]` | X-axis title | `Average inventory (£)` |
| | X-axis | `[Inventory Value]` | Bars → Colors | `#2A78D6` |
| | | | Data labels | On, `£#,##0`, 0 dp |
| | | | Sort | `Inventory Value` descending |
| **P1-V1b** | Y-axis | `Dim Warehouse[Site]` | X-axis title | `Order lines not supplied in full (%)` |
| | X-axis | `[Lines Short Rate %]` | Bars → Colors | `#EC835A` |
| | | | Data labels | On, `0.00%` |
| | | | Sort | **`Inventory Value` descending** — same order as V1a |
| **P1-V2** | X-axis | `[Stock Value at Closing]` | Y-axis well | **Empty** |
| | Legend | `Fact Opportunity[opportunity_mechanism]` | Legend position | Bottom |
| | | | Colors | tier ramp below |
| **P1-V3** | Rows | `Fact Opportunity[opportunity_mechanism]` | Grand total (rows) | **On** |
| | Values | `[sku]` Count → `Positions` | Row/col subtotals | Off |
| | | `[Stock Value at Closing]` → `Stock value` | Conditional formatting | Data bars on Working capital, `#256ABF` |
| | | `[Selected Opportunity Value]` → `Working capital (£ one-off)` | | |
| | | `[Selected Annual Holding Cost]` → `Annual holding cost (£ p.a., 22%)` | | |
| | | `[Basis]` First → `Basis` | | |

**Tier colour ramp — dark to light as confidence falls:**

| Legend value | Hex |
|---|---|
| `1 — discontinued or obsolete exposure` | `#184F95` |
| `2 — importer and minimum-order structural stock` | `#256ABF` |
| `3 — above the calibrated replenishment requirement` | `#3987E5` |
| `4 — slow-moving residual` | `#86B6EF` |
| `5 — no identified release opportunity` | `#898781` |

**Expected:** V1a Daventry £996,883 · Livingston £473,539 · Warrington £366,299 · Bristol £207,258,
summing to £2,043,979. V1b Daventry 7.70% · Livingston 5.32% · Warrington 6.92% · Bristol 10.77% —
in inventory order, and visibly *not* descending. That mismatch is the finding.

## 4.2 Page 2 — Inventory & Working Capital

| ID | Type | X | Y | W | H |
|---|---|---:|---:|---:|---:|
| K8–K12 | Card group | 24 + 200·n | 56 | 200 | 96 |
| P2-V1 | Clustered bar | 24 | 160 | 400 | 200 |
| P2-V2 | Clustered bar | 440 | 160 | 400 | 200 |
| P2-V3 | Line + stacked column | 856 | 160 | 392 | 200 |
| P2-V4 | Matrix | 24 | 372 | 760 | 230 |
| P2-V5 | Clustered bar | 800 | 372 | 472 | 230 |
| P2-V6 | Text summary | 24 | 614 | 1232 | 72 |

| # | Label | Measure | Basis tag | Expected |
|---|---|---|---|---|
| K8 | Closing inventory | `[Stock Value at Closing]` | at 2025-12-28 | £1,711,042 |
| K9 | Working capital identified | `[Selected Opportunity Value]` | one-off · ▲ upper bound in part | £468,897 |
| K10 | Annual holding cost | `[Selected Annual Holding Cost]` | per annum | £103,157 |
| K11 | Stock with no identified opportunity | `[Unclassified Stock Value]` | at 2025-12-28 | £835,219 |
| K12 | Discontinued exposure | `[Selected Opportunity Value]` | one-off · definitional | £87,478 |

**K12 carries a visual-level filter:** `Fact Opportunity[opportunity_mechanism]` → Basic filtering
→ tick only `1 — discontinued or obsolete exposure`. That filter is why K12 reads £87,478 and K9
reads £468,897 from the same measure.

| ID | Well | Field | Setting | Value |
|---|---|---|---|---|
| **P2-V1** | Y-axis | `Dim Warehouse[Site]` | Colors | `#2A78D6` |
| | X-axis | `[Inventory Value]` | Sort | descending, from zero |
| **P2-V2** | Y-axis | `Dim Category[category_name]` | Data labels | **On — mandatory** |
| | X-axis | `[Inventory Value]` | Sort | descending |
| | Tooltips | `[Inventory Turns]` | | |
| **P2-V3** | X-axis | `Detail SKU Value[sku]` | X-axis labels | **Off** (250 codes) |
| | Column y | `[average_stock_gbp]` | Column axis | title `Average stock (£)`, from zero |
| | Line y | `[cumulative_stock_share_pct]` | Line axis | title `Cumulative share (%)` |
| | | | Sort | `average_stock_gbp` descending |
| | | | Site slicer interaction | **None** — no site column exists |
| **P2-V4** | Rows | mechanism → `Dim Warehouse[warehouse_name]` → `sku` | +/- icons | On |
| | Values | Positions · `[Stock Value at Closing]` · `Working capital (£ one-off)` · `Annual holding cost (£ p.a.)` · `at 20%` · `at 25%` | Stepped layout | Off |
| | Tooltips | `[is_february_buy_ahead_position]` | Cross-column total | **Never** |
| **P2-V5** | Y-axis | `Ref Exposure Comparison[Exposure]` | Colors → fx → Rules on `[Marker]` | `error`→`#EC835A` · `headline`→`#256ABF` · `context`→`#898781` · `normal`→`#86B6EF` |
| | X-axis | `Ref Exposure Comparison[Value]` | Sort | `Value` descending |
| | | | Data labels | On, `£#,##0` |
| | | | **All interactions** | **None** |

P2-V5 also needs a text box over the naive-sum bar reading `✗ do not use`, 10pt, `#EC835A`. The
glyph and the label text carry the meaning, so colour is never doing the work alone.

**P2-V6 is a static text summary, not a filtered visual.** Power BI's filter pane cannot express
the OR across `weeks_since_last_issue` and `cover_weeks` that file 03 uses, and inventing a filter
expression would fabricate logic. Type the figures from `report_07` §4.

**Data labels on P2-V2 are not optional.** Eight categories exceeds the three-slot cap, and the
palette's low-contrast slots need visible direct labels on a light surface.

## 4.3 Page 3 — Availability & Replenishment

| ID | Type | X | Y | W | H |
|---|---|---:|---:|---:|---:|
| K13–K16 | Card group | 24 / 332 / 640 / 948 | 56 | 300 | 96 |
| P3-V1 | Clustered column | 24 | 160 | 616 | 200 |
| P3-V2 | Clustered column | 664 | 160 | 616 | 200 |
| P3-V3 | Matrix | 24 | 372 | 400 | 220 |
| P3-V4 | Table | 440 | 372 | 400 | 220 |
| P3-V5 | Line + clustered column | 856 | 372 | 392 | 220 |
| P3-V6 | Table | 24 | 604 | 500 | 92 |
| P3-V7 | Text panel ×3 | 540 | 604 | 732 | 92 |

| # | Label | Measure | Basis tag | Badge | Expected |
|---|---|---|---|---|---|
| K13 | Weeks closing at zero | `[Closing Zero Rate %]` | ISO-week basis | | 3.52% |
| K14 | Weeks with a zero-stock day | `[Any Zero Day Rate %]` | ISO-week basis | | 5.05% |
| K15 | Order lines not supplied in full | `[Lines Short Rate %]` | calendar-year basis | | 7.71% |
| K16 | Value of demand not met | `[Unmet Demand Value]` | calendar-year basis | ▲ upper bound | £1,027,629 |

**There is no K17.** Do not add a fourth availability KPI.

| ID | Well | Field | Setting | Value |
|---|---|---|---|---|
| **P3-V1** | X-axis | `Dim Warehouse[Site]` | Y-axis title | `Three distinct availability measures (%)` |
| | Y-axis | `[Closing Zero Rate %]` | Colors | `#86B6EF` |
| | Y-axis | `[Any Zero Day Rate %]` | Colors | `#3987E5` |
| | Y-axis | `[Lines Short Rate %]` | Colors | `#EC835A` |
| | | | Legend / data labels | On, bottom / On |
| **P3-V2** | X-axis | `Ref Cover Bands[Cover Band]` | Sort | `Cover Band` **ascending** |
| | Y-axis | `Ref Cover Bands[Unmet Unit Rate]` | Axis titles | `Unmet unit rate (%)` / `Stock cover before the week` |
| | | | **Interactions** | **None** |
| **P3-V3** | Rows | `Detail Policy Alignment[demand_direction]` | Conditional formatting | Background gradient `#CDE2FB` → `#184F95` |
| | Columns | `Detail Policy Alignment[alignment_band]` | | |
| | Values | `[sku]` Count → `Positions` | | |
| **P3-V4** | Columns | `alignment_band` · Count `sku`→`Positions` · Avg `cover_weeks`→`Mean cover (wks)` · Avg `unmet_units_pct`→`Unmet units %` · Sum `unmet_value_2025_gbp`→`Unmet value` · Avg `days_at_zero_pct`→`Days at zero %` | `policy_age_months` | **Tooltip only** |
| **P3-V5** | X-axis | `Ref Renewables[Quarter]` | Title label | `Partially supported`, 9pt, `#EDA100` |
| | Column y | `Ref Renewables[Demand Units]` | Column axis | `Demand (units)`, from zero |
| | Line y | `Ref Renewables[Line Fill Rate]` | **Interactions** | **None** |
| **P3-V6** | Columns | `Ref Seasonal Lag`: Category · Peak Demand Month · Peak Shortage Month · Months Trailing | Sort | `Months Trailing` descending |
| | | | **Interactions** | **None** |

**P3-V3 needs an annotation on the "broadly flat" row:** *"broadly flat = calibration set; centres
on 1.00 by construction (D-31)."* That row is the reference, not evidence — the benchmark was
calibrated from it. The finding lives in the rising and falling rows.

**P3-V4 needs its asymmetry caption**, or it reads as a ranking with "set deep" as the goal:
stock above the calibrated rule costs £25,502 a year; unmet demand on thin-set lines is £505,019
over the same year. Roughly twenty to one, service over capital.

**Policy age appears on this page in two places only** — the tooltip on P3-V4, and the Rejected
column of P3-V7. Not a slicer, not an axis, not a legend.

## 4.4 Pages 4a and 4b — Supplier & Sourcing Performance

**Page 4 is now two pages.** At 1280 × 720 the original single page gave its bottom row 112px,
which cannot hold a scatter chart — three visuals were readable only in focus mode, and a portfolio
reviewer never opens focus mode. It also answered two questions rather than one. See §5.

**Page 4a — `Supplier Reliability & Lead Time`**

| ID | Type | X | Y | W | H |
|---|---|---:|---:|---:|---:|
| K18–K21 | Card group | 24 / 224 / 424 / 624 | 56 | 200 | 96 |
| P4-V1 | Table | 24 | 168 | 616 | 240 |
| P4-V2 | Line | 664 | 168 | 616 | 240 |
| P4-V3 | Line | 24 | 424 | 400 | 230 |
| P4-V4 | Table | 440 | 424 | 400 | 230 |
| P4-V5 | Table | 856 | 424 | 392 | 230 |
| Site-effect note | Text box | 24 | 660 | 1232 | 28 |

**Page 4b — `Sourcing Economics`**

| ID | Type | X | Y | W | H |
|---|---|---:|---:|---:|---:|
| K22, K23 | Card group | 24 / 288 | 56 | 240 | 96 |
| P4-V6 | Clustered column | 24 | 168 | 616 | 240 |
| P4-V7 | Scatter | 664 | 168 | 616 | 240 |
| P4-V8 | Table | 24 | 424 | 616 | 200 |
| V7 trade-off caption | Text box | 664 | 424 | 616 | 200 |

The scatter goes from 400×112 to 616×240 — enough for 8px marks with a 2px ring, as the style guide
requires. K22 and K23 move to 4b, beside the minimum-order and dual-source evidence whose flow /
level distinction they carry.

| # | Label | Field | Aggregation | Basis tag | Expected |
|---|---|---|---|---|---|
| K18 | On time, first receipt | `Fact Supplier Network[on_time_first_receipt_pct]` | **Minimum** | n = 3,766 | 89.8% |
| K19 | On time, all receipts | `[on_time_all_receipts_pct]` | **Minimum** | n = 4,241 | 80.1% |
| K20 | OTIF, line complete | `[otif_pct]` | **Minimum** | n = 3,768 | 79.1% |
| K21 | Split delivery rate | `[split_delivery_rate_pct]` | **Minimum** | 537 of 4,853 receipts | 11.1% |
| K22 | Minimum-order increment bought 2025 | text card | — | **flow** — twelve months | £995,659 |
| K23 | Average incremental cycle stock | text card | — | **level** — derived from the flow | £497,830 |

K18–K20 must be displayed together — they differ by ten points, and the first-receipt figure alone
hides all 537 split deliveries. K22 and K23 are never added; one is a flow, one a level.

| ID | Well | Field | Setting | Value |
|---|---|---|---|---|
| **P4-V1** | Columns | `supplier_name` · `supplier_type` · `n_first_measurable` · `on_time_first_receipt_pct` · `n_all_measurable` · `on_time_all_receipts_pct` · `n_lines_measurable` · `otif_pct` · `split_delivery_rate_pct` · `cell_note` | Sort | `otif_pct` **ascending** |
| | | | Data bars | on the three rate columns |
| | | | Font colour rule | `cell_note` contains `thin cell` → `#898781` |
| **P4-V2** | X-axis | `Fact Supplier Trend[order_half_year]` | Y-axis title | `On time, first receipt (%)` |
| | Y-axis | `[on_time_first_receipt_pct]` **Average** | Supplier-type slicer | **None** |
| | Legend | `Fact Supplier Trend[supplier_type]` | | |
| | *plus* | `Ref Meridian Trend` filtered `Series = "Importers excluding Meridian"` | Line style | **Dashed** |
| **P4-V3** | X / Y | `Ref Meridian Trend[Half Year]` / `[On Time Pct]` | Filter | `Series = "Meridian Pacific"` |
| | | | **Interactions** | **None** |
| **P4-V4** | Source | **`Fact Cycle Time By Type` — 4 rows.** Not `Fact Cycle Time` (29 rows, per supplier). Repeated type names mean the wrong table. | |
| | Columns | `supplier_type` · `n_first_receipts` · `quoted_lead_time_days` · `median_cycle_days` · `p25` · `p75` · `iqr_days` · `p90` · `longest_cycle_days` · `stddev_days` · `median_overrun_vs_quoted_days` | Aggregation | **Don't summarize**, every numeric column |
| | | | **All interactions** | **None** |
| **P4-V5** | Columns | `warehouse_code` · `n_first_receipts` · `median_cycle_days` · `median_overrun_vs_quoted_days` | Aggregation | **Don't summarize** |
| | | | **Interactions** | **None** |
| **P4-V6** | X-axis | `Detail Purchase Structure[supplier_type]` | Y-axis title | `Share of 2025 purchase lines (%)`, from zero |
| | Y-axis | `[Minimum Binds %]`, `[Ordered At Minimum %]` | Supplier-type slicer | **None** |
| **P4-V7** | X-axis | `Detail Dual Source[dear_premium_pct]` | X-axis title | `Premium on the dearer source (%)` |
| | Y-axis | `cheap_moq` | Marker size | ≥ 8px |
| | Values | `Detail Dual Source[sku]` | | |
| | Size | `cheap_units` | | |
| | Legend | `cheap_supplier_type` | Series count | **1** — that is the finding |
| | | | Legend display | **Off** — state it in the subtitle instead: *60 dual-source SKUs. The cheaper source is a Far East importer in all 60 cases.* |
| **P4-V8** | Columns | `Ref Buy Ahead`: Component · Value · Basis | **Interactions** | **None** |

**P4-V2's dashed leave-one-out line is not decoration.** Without it the chart states "Far East
importers are getting worse", which the analysis rejected (D-26): the type-level decline is one
supplier. Measured, importers run 83.6% → 56.8%; excluding Meridian, 72.9% → 65.9%, flat to
improving.

**P4-V4's aggregation matters more than it looks.** Percentiles set to Sum give numbers in the
hundreds that look like days. A median of medians is not a median.

## 4.5 Page 5 — Site Investigations & Decision Watchlist

| ID | Type | X | Y | W | H |
|---|---|---:|---:|---:|---:|
| Title bar | Card | 24 | 56 | 1232 | 40 |
| Context tiles ×6 | Card group | 24 + 200·n | 104 | 200 | 88 |
| P5-V1 | Matrix | 24 | 200 | 760 | 200 |
| P5-V2 | Stacked column | 800 | 200 | 472 | 200 |
| P5-V3 | Table | 24 | 412 | 1232 | 180 |
| P5-V4 | Text panels ×2 + conclusion | 24 | 604 | 1232 | 92 |

| ID | Well | Field | Setting | Value |
|---|---|---|---|---|
| **Title bar** | Fields | `[Dynamic Insight Title]` | Callout value | 16pt Semibold, **left-aligned** |
| | | | Category label | Off |
| **P5-V1** | Rows | `Dim Warehouse[warehouse_name]` | Values | `[Inventory Value]` · `[Stock Value at Closing]` · `[Inventory Turns]` · `[Days Inventory Outstanding]` · `[Closing Zero Rate %]` · `[Any Zero Day Rate %]` · `[Lines Short Rate %]` · `[Unmet Demand Value]` · `[Selected Opportunity Value]` · `[Selected Annual Holding Cost]` |
| **P5-V2** | X-axis | `Dim Warehouse[Site]` | From zero, data labels On | |
| | Y-axis | `[Selected Opportunity Value]` | Colors | tier ramp, §4.1 |
| | Legend | `Fact Opportunity[opportunity_mechanism]` | Markers | `▲` `#D03B3B` 14pt above Daventry and Bristol |
| **P5-V3** | Columns | `opportunity_mechanism` · `sku` · `product_name` · `warehouse_name` · `category_name` · `sourcing_last_used` · `minimum_in_weeks_of_demand` · `quantity_on_hand` · `position_stock_value_gbp` · `releasable_units` · `working_capital_gbp` · `annual_holding_cost_gbp` · `cover_weeks` · `demand_direction` · `reorder_point_alignment_ratio` · `source_reference` | Visual filter | `working_capital_gbp` **> 0** |
| | Tooltips | `service_consequence` · `unresolved_service_constraint` | Sort | `working_capital_gbp` descending |
| **P5-V4** | — | Fixed text, §13.6 of the guide | **All interactions** | **None** |

**P5-V1 needs its note placed prominently, not in a tooltip:** do not rank sites on raw turnover.
145 of 250 SKUs are stocked only at Daventry; on the range all four sites carry, Daventry turns
6.82. Two valid range-mix corrections disagree, and the disagreement is the finding (D-23).
Livingston's 2.84 is the figure that survives every correction.

**P5-V4 assigns no cause, and its wording must not be paraphrased.** No field named cause, driver,
reason or root cause may exist anywhere in the model.

---

# 5. Where this sheet differs from the build guide

Two changes, both deliberate.

**Page 1 positions.** §9's layout map gives P1-V1a 180px and P1-V1b 160px of height. With four
categories, a two-line title and a subtitle, both clip — Power BI truncates the category list and
adds a scrollbar rather than shrinking the bars. §4.1 raises them to 192 and 176 and moves the
callout row down to y=648. The right-hand visuals move with them so the rows stay aligned.

**KPI callout font.** §8.5 specifies 26pt. At 26pt, `£2,043,979` overflows a 200px tile and renders
as `£2,043,9…`. §2.6 uses **24pt**, which fits the widest value on the page with margin. The tiles
on pages 3 and 5 are wider and could keep 26pt, but one size across all of them reads better.

**Page 4 split into 4a and 4b.** §12 of the guide put 6 KPI tiles and 8 visuals on one 1280 × 720
page, giving the bottom row 112px. A scatter chart cannot work in 112px, and P4-V6, V7 and V8 were
legible only in focus mode — which a portfolio reviewer never opens (style guide §7: every page
gets a screenshot). The page also answered two questions, against the style guide's own
one-question-per-page rule. Splitting fixes both, and no visual, measure or finding changes.

**Neither of the first two changes a number, a measure, a field, an interaction rule or a finding.** Record them in
`analytical-decisions.md` only if you want the trail; they are presentation, not method.

## 5.1 One correction to make in the built report

**K4 must read 78.2, not 78.1.** If it shows 78.1 it is bound to
`days_inventory_outstanding_unrounded_basis`, which exists solely as a reconciliation check that
the rounding is sound. The committed headline in `report_02` and `findings.md` is
`days_inventory_outstanding` = **78.2**.

---

---

# 6. Tooltip pages — click by click

A **tooltip page** is an ordinary report page, hidden from navigation, that Power BI draws inside
the hover box instead of its plain grey default. It exists so hover can carry a caveat sentence,
which a default tooltip cannot.

## 6.0 The one idea to hold on to

**You never link a tooltip page to a bar, and you never filter it yourself.**

When someone hovers the Daventry bar, Power BI silently passes *"warehouse = Daventry"* into the
tooltip page, and every visual on that page recalculates for Daventry. Hover Bristol and the same
page shows Bristol. You build the page once, generically, with no filters at all.

That is why one `TT Site Inventory` page serves P1-V1a, P2-V1 **and** P5-V1.

## 6.1 Build `TT Site Inventory` — the full walkthrough

Do this one slowly. The other six are the same seven steps with different fields.

### Step 1 — make the page

1. At the **bottom** of the Power BI window, click the **`+`** beside your page tabs.
2. **Double-click** the new tab. Type `TT Site Inventory`. Press **Enter**.

### Step 2 — turn it into a tooltip page

3. Click anywhere on the **empty canvas** (not on a visual — there aren't any yet).
4. The **Format** pane on the right now shows page settings, not visual settings.
5. Expand **Canvas settings** → **Type** → choose **Tooltip**.
   The canvas shrinks to **320 × 240**. That is correct, not a mistake.
6. Expand **Page information** → switch **Allow use as tooltip** to **On**.

> If **Page information** is missing, you clicked a visual. Press **Esc** and click bare canvas.

**Leave the page visible for now.** You hide it in step 7, after it works.

### Step 3 — add the numbers

7. **Visualizations** pane → click **Multi-row card** (a rectangle with three stacked bars).
   *No multi-row card in your build?* Use five small **Card** visuals instead — layout in §6.4.
8. With it selected, set **Format → General → Properties → Position**: X `8`, Y `8`,
   Width `304`, Height `176`.
9. From the **Data** pane, tick these five, in this order:

   | Order | Field |
   |---|---|
   | 1 | `[Inventory Value]` |
   | 2 | `[Stock Value at Closing]` |
   | 3 | `[Inventory Turns]` |
   | 4 | `[Days Inventory Outstanding]` |
   | 5 | `[Selected Annual Holding Cost]` |

10. In the **Fields** well, click each one → **Rename for this visual** → type the short label:
    `Average inventory` · `Closing` · `Turns` · `DIO` · `Holding cost 22%`.

> **No "closing vs average" field.** There is no such measure — M1–M16 do not include one, and the
> `closing_vs_average_pct` column sits at site × category grain, so aggregating it across a site's
> eight categories would not give that site's ratio. The caveat text box in step 17 carries the
> point instead. The project stays at **16 measures**.

### Step 4 — format it

11. **Format visual → Callout values** → font Segoe UI Semibold **11pt**.
12. **Format visual → Category labels** → **On**, 9pt, `#52514E`.
    *(On tooltip pages the built-in label is used — the opposite of §2.6, where the dashboard tiles
    get their own text boxes. There is no room for text boxes in 320 × 240.)*
13. **Format visual → Cards → Bars** → **Off**.
14. **Format → General → Effects** → Background `#FCFCFB`, Border **Off**, Shadow **Off**.

### Step 5 — add the caveat

15. **Insert** ribbon → **Text box**.
16. Set its position: X `8`, Y `190`, Width `304`, Height `42`.
17. Type, at 8pt italic, `#898781`:

    > Inventory is the mean of 52 weekly snapshots, never closing stock (D-10).

**This sentence is the entire reason the page exists.** A default tooltip cannot carry it.

### Step 6 — attach the page to a visual

18. Go to **Page 1**. Click **P1-V1a**.
19. **Format** pane → **General** → **Tooltips**.
20. **Type** → `Report page`.
21. **Page** → `TT Site Inventory`.

### Step 7 — test, then hide

22. **Hover over a bar** on P1-V1a. Your card should appear with that site's figures.
23. Hover a **different** bar. The numbers must change. If they do not, see §6.5.
24. Once it works: **right-click the `TT Site Inventory` tab → Hide page.**

Hidden pages still function as tooltips. Hiding only removes them from the navigation.

25. Repeat steps 18–21 for **P2-V1** and **P5-V1**. Same page, nothing else to change.

## 6.2 The other six

Identical procedure. Only the fields and the caveat differ.

| Page | Attach to | Fields on the card | Caveat text box |
|---|---|---|---|
| `TT Site Service` | P1-V1b | `demand_lines` · `lines_not_supplied_in_full` · `line_fill_rate_pct` · `unmet_units` · `unmet_value_gbp` | *Order-date basis, calendar 2025. Unmet demand is an upper bound — substitution is not modelled.* |
| `TT Opportunity Tier` | P1-V2, P1-V3, P2-V4, P5-V2 | Count of `sku` as `Positions` · `[Stock Value at Closing]` · `[Selected Opportunity Value]` · `[Selected Annual Holding Cost]`, plus a **second text box** bound to `service_consequence` and `source_reference` | *Capital is one-off; holding cost is annual. Never added.* |
| `TT Three Measures` | P3-V1 | `[Closing Zero Rate %]` · `[Any Zero Day Rate %]` · `[Lines Short Rate %]` · `weeks_closing_at_zero` · `weeks_with_a_zero_day` · `sku_weeks` · `lines_not_supplied_in_full` · `demand_lines` · `snapshot_understatement_factor` | *Weekly snapshots miss stockouts that clear before Sunday. ISO-week basis for measures 1–2, calendar-year for measure 3; the £2,591 difference is the 133 lines dated 29–31 December (D-13, D-22).* |
| `TT Supplier Cell` | P4-V1 | `on_time_first_receipt_pct` · `n_first_measurable` · `on_time_all_receipts_pct` · `n_all_measurable` · `otif_pct` · `n_lines_measurable` · `n_not_measurable` · `n_outside_window` · `cell_note` | *Cells under ten observations carry no interpretation (D-15).* |
| `TT Cycle Distribution` | P4-V4 | `n_first_receipts` · `quoted_lead_time_days` · `median_cycle_days` · `mean_cycle_days` · `p25_cycle_days` · `p75_cycle_days` · `p90_cycle_days` · `longest_cycle_days` · `stddev_days` | *Percentiles are valid only at this grain and are never aggregated.* |
| `TT Position` | P5-V3 | Text boxes only: `service_consequence` · `unresolved_service_constraint` · `source_reference`, each in full | — |

**Where a page carries nine fields**, a multi-row card at 320 × 240 will be cramped. Either widen
the canvas to **420 × 300** (Canvas settings → Type: Tooltip still allows a custom size) or split
the fields across two cards side by side.

**`TT Position` is the one that solves a real limitation.** The Table visual has no Tooltips well
at all, so a report-page tooltip is the only way to surface `service_consequence` on P5-V3.

## 6.3 Where a tooltip page will NOT work

**Any visual sourced from a `Ref` table** — P2-V5, P3-V2, P3-V5, P3-V6, P4-V3, P4-V8. Those tables
are deliberately disconnected, so there are no relationships to carry filter context. A tooltip
page attached to them shows network totals whatever you hover, which is worse than no tooltip
because it looks specific.

Give those a **default tooltip** instead: drag the relevant columns into the visual's own
**Tooltips** well. Never turn tooltips off entirely — a dashboard that ignores hover feels broken.

## 6.4 Fallback layout — individual Cards instead of a multi-row card

| Card | X | Y | W | H |
|---|---:|---:|---:|---:|
| 1 | 8 | 8 | 100 | 84 |
| 2 | 110 | 8 | 100 | 84 |
| 3 | 212 | 8 | 100 | 84 |
| 4 | 8 | 96 | 100 | 84 |
| 5 | 110 | 96 | 100 | 84 |
| 6 | 212 | 96 | 100 | 84 |

`TT Site Inventory` uses the first five; leave slot 6 empty or close the gap.

Caveat text box at 8, 186, 304 × 46. Callout value 11pt Semibold; **Category label On**, 9pt.

**Do not use a Table visual here.** Six columns across 304px gives about 50px each, and
`£2,043,979` needs roughly 70. It truncates.

## 6.5 When it does not work

| Symptom | Cause |
|---|---|
| Nothing appears on hover | *Allow use as tooltip* is Off, **or** canvas Type is not Tooltip. Both are required |
| Same numbers whatever you hover | No relationship path from the hovered field to the tooltip page's visuals — see §6.3 |
| Tooltip is clipped | 320 × 240 is small. Widen the canvas, or move fields to a second card |
| Page shows in the navigation | You skipped step 24. Right-click tab → Hide page |
| Works on one visual, not another | Steps 18–21 are per visual. Each one needs Type and Page set |

# 7. Verification numbers

Check these after each page. Every one traces to a committed result in `analysis/query_results/`.

| Page | Check | Value |
|---|---|---|
| 1 | K1 · K2 · K3 · K4 · K5 | £2,043,979 · £1,711,042 · 4.67 · 78.2 · 7.71% |
| 1 | K6 · K7 | £468,897 · £103,157 |
| 1 | P1-V1a bars sum | £2,043,979 |
| 1 | P1-V2 segments sum | £1,711,042, grey tier 5 largest |
| 1 | P1-V3 tier capital sums | 87,478 + 303,558 + 70,755 + 7,106 = **468,897** |
| 2 | Holding-rate slicer moves K10 only | 20% £93,779 · 22% £103,157 · 25% £117,225 |
| 2 | P2-V3 top-10 cumulative | 36.4% |
| 2 | P2-V5 error bar | £1,109,016, marked `✗ do not use` |
| 3 | K13 · K14 · K15 · K16 | 3.52% · 5.05% · 7.71% · £1,027,629 |
| 3 | P3-V2 first band | 46.70% |
| 3 | P3-V4 unmet value by alignment | £505,019 · £436,474 · £41,426 |
| 4 | K18 · K19 · K20 · K21 | 89.8% · 80.1% · 79.1% · 11.1% |
| 4 | P4-V2 importers, measured vs excl. Meridian | 56.8% vs 65.9% at 2025H2 |
| 4 | P4-V4 importer quoted vs median | 55 vs 78 days |
| 5 | P5-V2 columns total | £468,897; DAV + BRS = £252,435 = 53.8% |

**Three sums that must never appear anywhere:** K6 + K7 · capital + holding cost in any matrix ·
the five exposures added together, except in P2-V5 where £1,109,016 appears in order to be
rejected.
