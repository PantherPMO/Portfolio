# Visual Style Guide

Eight projects must look like **one portfolio**. Different colours in every project reads as eight unrelated pieces of work — and inconsistency is the first thing that makes a portfolio look amateur.

This guide governs every chart, dashboard and figure, whether built in Power BI, Tableau, Excel or matplotlib.

---

## 1. The Palette

Validated for colour-vision deficiency (protanopia, deuteranopia, tritanopia) and surface contrast in both light and dark modes. **Do not substitute colours by eye.**

### Categorical — series identity

Assign in **fixed slot order, never cycled.** Slot 1 is always the first series, regardless of the chart. Colour follows the *entity*, not its rank — if a filter drops a series, the survivors keep their colours.

| Slot | Hue | Light mode | Dark mode |
|------|-----|-----------|-----------|
| 1 | Blue | `#2A78D6` | `#3987E5` |
| 2 | Orange | `#EB6834` | `#D95926` |
| 3 | Aqua | `#1BAF7A` | `#199E70` |
| 4 | Yellow | `#EDA100` | `#C98500` |
| 5 | Magenta | `#E87BA4` | `#D55181` |
| 6 | Green | `#008300` | `#008300` |
| 7 | Violet | `#4A3AA7` | `#9085E9` |
| 8 | Red | `#E34948` | `#E66767` |

**Validation results** (OKLab ΔE ×100, run with the dataviz validator):

| Check | Light | Dark |
|-------|-------|------|
| Lightness band | ✅ all 8 in range | ✅ all 8 in range |
| Chroma floor | ✅ | ✅ |
| CVD separation (worst adjacent pair) | ✅ ΔE 9.1 | ✅ ΔE 8.4 |
| Normal-vision floor (worst adjacent) | ✅ ΔE 19.6 | ✅ ΔE 19.3 |
| Contrast vs surface | ⚠️ aqua, yellow, magenta below 3:1 | ✅ all ≥ 3:1 |

**The light-mode contrast warning is binding, not advisory.** Where slot 3 (aqua), 4 (yellow) or 5 (magenta) are used on a light surface, ship **visible direct labels or a data table** so the value is never carried by a low-contrast fill alone.

**Series cap for scatter, bubble and choropleth:** these put every pair of colours side by side simultaneously, and the full eight cannot clear the separation floors under those conditions. **Use the first three slots only.** Beyond three, fold into "Other", facet into small multiples, or use a second encoding channel (shape, size).

### Sequential — magnitude

One hue, light → dark. Default is blue. Used for heatmaps, choropleths, and any continuous magnitude.

| Step | Hex | Step | Hex |
|------|-----|------|-----|
| 100 | `#CDE2FB` | 450 | `#2A78D6` |
| 200 | `#9EC5F4` | 500 | `#256ABF` |
| 300 | `#6DA7EC` | 550 | `#1C5CAB` |
| 400 | `#3987E5` | 600 | `#184F95` |
| | | 700 | `#0D366B` |

For **ordinal** ramps (discrete ordered categories — funnel stages, ABC classes, tiers) start no lighter than step 250 `#86B6EF` on light surfaces, so the lightest band remains legible.

Where two sequential contexts appear in one view, the second uses orange as its own single-hue ramp.

### Diverging — polarity

**Blue ↔ Red**, with a neutral grey midpoint (light `#F0EFEC`, dark `#383835`). Equal step count each arm.

Use for budget variance, growth vs decline, above/below target — anywhere zero is meaningful. **Never a hue at the midpoint**, never a rainbow.

### Status — reserved

Never reused as a series colour. Always paired with an icon and a text label, so meaning is never colour-alone.

| Role | Hex | Use |
|------|-----|-----|
| Good / on target | `#0CA30C` | KPI meeting target |
| Warning | `#FAB219` | Approaching threshold |
| Serious | `#EC835A` | Materially off target |
| Critical | `#D03B3B` | Requires immediate action |

### Chrome & ink

| Role | Light | Dark |
|------|-------|------|
| Chart surface | `#FCFCFB` | `#1A1A19` |
| Page background | `#F9F9F7` | `#0D0D0D` |
| Primary text | `#0B0B0B` | `#FFFFFF` |
| Secondary text | `#52514E` | `#C3C2B7` |
| Muted (axis, labels) | `#898781` | `#898781` |
| Gridline | `#E1E0D9` | `#2C2C2A` |
| Axis / baseline | `#C3C2B7` | `#383835` |
| Positive delta text | `#006300` | `#0CA30C` |

**Text never wears the series colour.** Values, labels and legend text stay in ink tokens; a small coloured mark beside the text carries the identity.

---

## 2. Choosing the Chart

Pick the form from the data's *job*, before choosing any colour.

| The data's job | Form |
|----------------|------|
| Compare magnitude across categories | Horizontal bar, sorted by value |
| Change over time | Line (continuous), column (discrete periods) |
| Part of a whole | Stacked bar — **never a pie beyond 3 slices** |
| Relationship between two measures | Scatter (max 3 colour series) |
| Distribution | Histogram, box plot |
| Polarity vs a reference | Diverging bar |
| Density across two dimensions | Heatmap |
| A single headline number | **A stat tile, not a chart** |
| Rank change over time | Slope chart, bump chart |

**Often the right answer is not a chart.** A single number, large, with its comparison beneath it, beats a two-bar chart every time.

---

## 3. Hard Rules

These are non-negotiable across all eight projects.

1. **Never a dual-axis chart.** Two y-scales invites false correlation and is the single most common chart mistake. Two measures of different scale → two charts, small multiples, or index both to a common base.
2. **Bar charts start at zero.** Always. Truncating a bar axis misrepresents magnitude. Line charts may use a non-zero axis where the range is genuinely narrow — say so in the caption.
3. **Sort bars by value**, not alphabetically, unless the category has an inherent order (months, tiers, age bands).
4. **Title states the finding, not the variable.** "Churn peaks in the first three months" — not "Churn by tenure". The title is the sentence you want the reader to leave with.
5. **Axes labelled with units.** `Revenue (£000s)`, not `Revenue`.
6. **Legend present for two or more series**; direct labels as well when there are four or fewer. A single-series chart needs no legend — the title names it.
7. **Never colour alone** to carry meaning. Position, label, shape or texture must also encode it.
8. **No chartjunk.** No 3-D, no gradient fills for decoration, no drop shadows, no background images.
9. **Recessive grid and axes.** Gridlines are hairlines in the muted tone; the data is the loudest thing on the chart.
10. **Round to decision precision.** £1.2m, not £1,234,567.89. Show the precision the decision needs.
11. **State the n.** Where a segment is small, put the count on or beside the chart.
12. **Annotate the point that matters.** One callout on the chart carrying the finding is worth more than a paragraph beneath it.

---

## 4. Mark Specifications

- **Lines:** 2px, no marker on every point; markers ≥ 8px only where individual points are read
- **Bars:** 4px rounded on the data end, square at the baseline; 2px surface gap between adjacent bars and between stacked segments
- **Scatter points:** ≥ 8px, 2px surface ring where marks overlap
- **Direct labels:** selective — the endpoints, the max, the annotated point. Never a number on every data point
- **Reference lines:** 1px dashed in muted tone, always labelled (`Target: 95%`)

---

## 5. Dashboard Layout

For projects 06, 07 and 08.

```
┌──────────────────────────────────────────────────────────────┐
│  Title                                    [Filters — one row]│
├──────────────────────────────────────────────────────────────┤
│  ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐                 │
│  │ KPI 1  │ │ KPI 2  │ │ KPI 3  │ │ KPI 4  │   ← 4–6 max     │
│  │ value  │ │ value  │ │ value  │ │ value  │                 │
│  │ ▲ vs   │ │ ▼ vs   │ │ ▲ vs   │ │ ─ vs   │                 │
│  └────────┘ └────────┘ └────────┘ └────────┘                 │
├──────────────────────────────────────────────────────────────┤
│  ┌────────────────────────────┐ ┌─────────────────────────┐  │
│  │  Primary chart — the       │ │  Supporting breakdown   │  │
│  │  headline trend or driver  │ │                         │  │
│  └────────────────────────────┘ └─────────────────────────┘  │
├──────────────────────────────────────────────────────────────┤
│  ┌──────────┐ ┌──────────┐ ┌──────────────────────────────┐  │
│  │ Detail   │ │ Detail   │ │  Detail table                │  │
│  └──────────┘ └──────────┘ └──────────────────────────────┘  │
└──────────────────────────────────────────────────────────────┘
```

**Layout rules**

- Filters in **one row along the top**, never scattered
- **4–6 KPI tiles maximum.** More than six and none of them are key
- Every KPI tile carries a comparison (vs target, vs last period) — a number with no context supports no decision
- Reading order top-left → bottom-right, in decreasing importance
- Whitespace is a design element; do not fill every pixel
- Every page answers **one question** and its title says which
- A tooltip on every chart element — an interactive dashboard that does not respond to hover feels broken

**The test:** can a stakeholder answer "how are we doing, and what needs my attention?" within ten seconds of opening page one?

---

## 6. Tool-Specific Application

### Power BI
- Build a **custom theme JSON** from the palette above and apply it to all three Power BI projects. Never use the stock Power BI theme
- Font: Segoe UI. Titles 14pt semibold, axis labels 10pt
- Turn off default drop shadows and borders on visuals
- Consistent page size across projects: 1280×720
- Use bookmarks sparingly and only where they aid the stakeholder narrative

### Tableau
- Create a **custom colour palette in `Preferences.tps`** using the same hex values
- Match Power BI layout conventions so the two projects read as one portfolio
- Publish to Tableau Public and link from the README

### Excel
- Define the palette as the workbook **theme colours** so charts inherit it
- Remove default gridlines and chart borders; Excel's defaults are the visual signature of an untouched template
- Number formats: `£#,##0`, `0.0%`, `#,##0` — consistent across all sheets
- Conditional formatting uses the sequential ramp, not Excel's default red-yellow-green

### Python (matplotlib / seaborn)
- Define the palette once in a shared `viz_style.py` and import it everywhere
- `plt.style.use()` with a saved style file; never rely on defaults
- Export at 150 DPI PNG, sized to be legible at ~880px wide on GitHub

---

## 7. Screenshots for GitHub

- Capture at 2× resolution and downscale — a native-resolution screenshot looks soft
- Target ~1600px wide, rendering at GitHub's ~880px
- PNG, under 500 KB
- Named `NN_description.png` in `powerbi/screenshots/` or `outputs/figures/`
- **Every dashboard page gets a screenshot.** Nobody installs Power BI Desktop to review a candidate's work

---

## 8. Accessibility

- Colour-vision safety is validated above — do not deviate from the palette without re-running the validator
- Text contrast: minimum 4.5:1 for body, 3:1 for large text
- Never red/green alone to signal good/bad — pair with an icon and label
- Every chart has a text alternative: the finding stated in the README, and the underlying data available as CSV

---

## 9. Before Publishing Any Chart

- [ ] Chart type suits the data's job
- [ ] Title states the finding
- [ ] Axes labelled with units; bar axis starts at zero
- [ ] Colours from this palette, in fixed slot order
- [ ] Legend for ≥ 2 series; direct labels where ≤ 4
- [ ] Meaning does not depend on colour alone
- [ ] Low-contrast slots (aqua/yellow/magenta on light) carry visible labels
- [ ] No dual axis
- [ ] Scatter / bubble limited to 3 colour series
- [ ] n stated where segments are small
- [ ] Legible at 880px
- [ ] **Rendered and actually looked at** — no clipped labels, no overflow, no collisions
