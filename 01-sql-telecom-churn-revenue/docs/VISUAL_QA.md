# Visual Quality Assurance

## Project 01 - Telecommunications Revenue Retention: Prioritising Retention Investment by Revenue at Risk

**Stage:** 6 - COMMUNICATE (visual QA pass)
**Date:** 21 August 2026
**Scope:** presentation layer only. This is not a numerical validation pass; the charts already passed 88/88 numeric checks.
**Outcome:** 11 of 11 charts visually ready. **1 MAJOR FIX, 5 MINOR FIX, 5 PASS**, all fixes applied and re-verified.

---

## 1. Method

Each of the eleven PNGs was opened and inspected at portfolio viewing size against
`COMMUNICATION_PLAN.md`, `FINDING_EVIDENCE_REGISTER.md` and `COMMUNICATION_VALIDATION.md`, on the
thirteen criteria in the brief: readability, title clarity, scope clarity, axis readability, label
collisions, annotation collisions, legend placement, whitespace, visual hierarchy, immediacy of the
main insight, caveat visibility without dominance, chart-type appropriateness, exaggeration risk,
and cross-chart consistency.

**Nothing outside the presentation layer was touched.** No SQL, no analytical output, no chart
value, no source data, no finding definition, no population scope and no communication claim was
modified. Proof is in §5.

---

## 2. Typographic normalisation applied to all eleven charts

A house rule was issued with this pass: **no em dashes and no double dashes in rendered text.**

`scripts/build_charts.py` contained **46 em dashes** across titles, annotations and footers. All were
replaced with a single hyphen, preserving every word. `scripts/validate_charts.py` was updated in
step so its V7 expectation matches.

**This improves fidelity rather than merely satisfying a style rule.** The A-07 designation as
written by the SQL pipeline into `analyse_04_divergence.txt` is `PRIMARY RESULT - Opening cohort`
with a single hyphen. The chart titles previously rendered it with an em dash. They now reproduce
the source designation **character for character**.

Two categories of double hyphen remain and are correct:

- `ls="--"` in seven places - a matplotlib linestyle argument, not text. It draws the dashed
  reference lines.
- `# ---` section rulers in code comments, which never render.

Because this change touches text on every figure, **all eleven PNGs were re-rendered and all eleven
checksums changed**, including the five rated PASS on layout. Those five received **no layout
change** - see the status column in §3 and the checksum table in §6.

**Note for the record:** `COMMUNICATION_PLAN.md`, `COMMUNICATION_VALIDATION.md` and
`FINDING_EVIDENCE_REGISTER.md` still use em dashes in their prose. The register is on the
do-not-modify list. The other two were left untouched because normalising them would produce a large
diff across documents already reconciled by the five-way check. They can be normalised on request.

---

## 3. Chart-by-chart assessment

| Chart | Status | Issue | Proposed Visual Fix | Analytical Impact |
|-------|--------|-------|---------------------|-------------------|
| **CH-01** | ✅ **PASS** | None. Part-to-whole bar reads instantly; both segments labelled with amount and percentage; footer legible and subordinate | None. Em-dash normalisation only | **None** |
| **CH-02** | 🟡 **MINOR FIX** | Excess vertical whitespace between the two bars made the gap arrow float, weakening the visual link between the two rates it connects | Reduce figure height 3.6 → 3.1 in; tighten `ylim` from ±0.42 to ±0.30 so the arrow sits in a proportionate gap | **None.** Both percentages, the gap and its arithmetic unchanged |
| **CH-03** | ✅ **PASS** | None. Pareto reads cleanly; decile convention stated on the axis; cumulative line unambiguous; legend sits in dead space at lower left | None. Em-dash normalisation only | **None** |
| **CH-04** | 🔴 **MAJOR FIX** | The third title line ran to 158 characters. Because the figure is saved with a tight bounding box, the title stretched the canvas to **2624 × 1109 px**, leaving roughly 45% dead margin on the right and compressing the bars into the left half. Aspect ratio was inconsistent with every other chart and the plot read as unbalanced at README width | Wrap the third title line onto two lines at the sentence boundary. Wording preserved exactly; one clause separator changed from a dash to a comma. Canvas returns to **1629 × 1136 px** and the bars fill the frame | **None.** All ten rates, all ten `n`, the 21.23% reference line, the tier colouring and both call-outs unchanged. The decile-9 peak and decile-10 dip are still both stated, and the dip is still described as unexplained |
| **CH-05** | ✅ **PASS** | None. Grouped bars read instantly; the High-tier near-parity call-out lands without collision; `n` on every bar | None. Em-dash normalisation only | **None** |
| **CH-06** | ✅ **PASS** | None. **The null reads as null.** Five flat grey lines dominate; four accented lines move exactly one rank; legend counts them; the title states the result plainly. No collision anywhere. **No visual treatment exaggerates the finding** - if anything the muted treatment understates the four moving lines, which is the correct direction of caution for a near-null result | None. Em-dash normalisation only | **None** |
| **CH-07** | 🟡 **MINOR FIX** | The known annotation collision was already resolved by moving the 78.93% statement into the title. Residual issue: `xlim` at 1.86 × the largest bar left a wide empty band to the right of the value labels, and the footer wrapped awkwardly | Reduce `xlim` to 1.58 × the largest bar. Labels still fit; dead space removed; footer wrap improves | **None.** All nine amounts, shares, churn rates and `n` unchanged. Bar lengths are unchanged in proportion; only the axis extent moved |
| **CH-08** | 🟡 **MINOR FIX** | Known multi-panel issue, previously rebuilt from a 1 × 7 strip into a 2 × 4 grid, which resolved the label collisions. Residual issue: value labels on markers sitting close to index 1.00 had the dashed reference line running through the glyphs | Nudge a label 0.34 index units clear when its marker sits within 0.30 of 1.00; add a surface-coloured backing box behind each label; drop label font 7.7 → 7.5 pt | **None.** All 24 cells, rates, `n`, caveat marks, panel order and spreads unchanged. **All seven lenses still shown; L5 and L7 still at true magnitude on identical axes** |
| **CH-09** | ✅ **PASS** | None. Dumbbell is the right form; lens grouping clear; every lens header identically styled so weak lenses are not de-emphasised; `max abs Δ` visible per lens; R-04 quoted in the footer. **Weak differentiation is neither hidden nor exaggerated** | None. Em-dash normalisation only | **None** |
| **CH-10** | 🟡 **MINOR FIX** | Stacked-bar spacing: excess vertical whitespace above and below the two rows. Legend was correctly centred in the inter-bar gap but the surrounding emptiness made the figure look unbalanced | Reduce figure height 4.4 → 4.0 in; tighten `ylim` to −0.52 / +1.52 | **None.** Both shares, both counts, both amounts and the cohort labels unchanged |
| **CH-11** | 🟡 **MINOR FIX** | Stacked-bar spacing: the two composition rows sat too far apart for a two-row chart, leaving a large empty band between them | Reduce figure height 4.6 → 3.9 in; tighten `ylim` from ±0.55 to ±0.42 | **None.** Counts, percentages, the collapsed below-threshold band and its label unchanged |

### 3.1 Criteria not raising any finding

Across all eleven charts the following were assessed and found sound, with no fix required:

- **Scope clarity.** Every figure carries a `Population scope:` line naming the cohort and its `n`.
  CH-06 and CH-07 additionally carry **PRIMARY RESULT - Opening cohort** in the title.
- **Caveats visible but not overpowering.** Footers are 7.4 pt in secondary grey against 13 pt bold
  titles and 8-10 pt data labels. The hierarchy holds: headline, then data, then caveat.
- **Chart-type appropriateness.** Slope chart for a rank comparison, dumbbell for paired indices,
  Pareto combo for concentration, small multiples for seven lenses, part-to-whole for shares. No
  chart type was found unsuited to its message.
- **Exaggeration.** No truncated axes, no dual-axis distortion, no 3D, no area-encoded quantity, no
  colour used to inflate a weak difference. Percentage axes start at zero throughout. CH-09
  deliberately compares indices rather than raw rates precisely because raw rates would look more
  dramatic and would mislead.
- **Cross-chart consistency.** One palette, one footer format, one scope-line format, one caveat
  style, one font, 150 dpi throughout.

---

## 4. Fixes applied

Documented above **before** application, as required. All are presentation-layer edits to
`build_charts.py`: figure dimensions, axis limits, label offsets, one title line-wrap, one font size,
one label backing box.

| Chart | Edit |
|---|---|
| CH-02 | `figsize` 3.6 → 3.1 in height; `ylim` ±0.42 → ±0.30 |
| CH-04 | Third title line wrapped at the sentence boundary; one clause separator dash → comma |
| CH-07 | `xlim` multiplier 1.86 → 1.58 |
| CH-08 | Label nudge when `abs(v - 1.0) < 0.30`; surface-coloured label backing; font 7.7 → 7.5 pt |
| CH-10 | `figsize` 4.4 → 4.0 in height; `ylim` tightened |
| CH-11 | `figsize` 4.6 → 3.9 in height; `ylim` ±0.55 → ±0.42 |
| All 11 | Em dashes replaced with single hyphens in rendered text |

**Not changed:** no query, no filter, no `.where()` clause, no block selection, no column reference,
no sort order, no value, no rounding, no colour mapping, no caveat wording, no scope wording, and no
communication claim. **No finding was added and none was removed.**

---

## 5. Confirmation that no analytical value changed

Three independent confirmations.

**5.1 Audit CSVs byte-identical.** The eleven `outputs/chart_data/*.csv` files, which contain the
exact rows each chart consumes, were regenerated by the rebuild and then diffed against the copies
committed to the project before this QA pass:

```
ALL 11 chart_data CSVs byte-identical to the committed copies - no analytical value changed
```

**5.2 Validation gate re-run.** `scripts/validate_charts.py` re-run after the rebuild:

```
CH-01 PASS   CH-02 PASS   CH-03 PASS   CH-04 PASS   CH-05 PASS   CH-06 PASS
CH-07 PASS   CH-08 PASS   CH-09 PASS   CH-10 PASS   CH-11 PASS
OVERALL: PASS
```

**11 charts × 8 checks = 88 checks, 88 PASS, 0 FAIL.** V1 compares headline values as **strings**
against the audit CSVs, so any re-rounding or reformatting would have failed rather than passed on
numeric tolerance.

**5.3 Sources untouched.** `analysis/query_results/`, `sql/`, `data/` and
`docs/FINDING_EVIDENCE_REGISTER.md` were not written to at any point in this pass.

---

## 6. PNG integrity and before/after checksums

All eleven files verified as valid PNGs by magic bytes, with IHDR dimensions read and plausible file
sizes (V8). All re-rendered because the em-dash normalisation touches text on every figure.

| Chart | MD5 before | MD5 after | Dimensions after | Bytes | Layout changed |
|---|---|---|---|---|---|
| CH-01 | `6ed43463…` | `aa0f5999…` | 1570 × 776 | 132,022 | No - text only |
| CH-02 | `34a72c44…` | `17f53fc1…` | 1669 × 744 | 145,013 | **Yes** |
| CH-03 | `e4449035…` | `c5fa023a…` | 1938 × 1103 | 233,052 | No - text only |
| CH-04 | `dcfed6be…` | `1d126b4d…` | **1629 × 1136** | 206,661 | **Yes** (was 2624 × 1109) |
| CH-05 | `af4bf8a8…` | `169be5fb…` | 1686 × 1079 | 167,501 | No - text only |
| CH-06 | `a5db5d48…` | `57fb4970…` | 2220 × 1285 | 299,177 | No - text only |
| CH-07 | `178398f7…` | `c9d5c3ec…` | 1819 × 1254 | 288,826 | **Yes** |
| CH-08 | `868760ac…` | `a2354855…` | 2446 × 1605 | 409,107 | **Yes** |
| CH-09 | `97bd0d5d…` | `f42f087c…` | 2189 × 1606 | 391,524 | No - text only |
| CH-10 | `faa543e0…` | `4053c79c…` | 1881 × 905 | 210,454 | **Yes** |
| CH-11 | `ce407f3e…` | `a82ce0ac…` | 1863 × 891 | 203,753 | **Yes** |

---

## 7. Final tally

| Status | Count | Charts |
|---|---|---|
| ✅ **PASS** | **5** | CH-01, CH-03, CH-05, CH-06, CH-09 |
| 🟡 **MINOR FIX** | **5** | CH-02, CH-07, CH-08, CH-10, CH-11 |
| 🔴 **MAJOR FIX** | **1** | CH-04 |

**All six fixes applied and re-verified. All eleven charts are now visually ready for a portfolio
README and a case study.**

Both null results remain presented as null results after this pass: **CH-06's near-null divergence**
and **CH-09's four weakly differentiating lenses.** Neither was softened, shrunk, reordered or
visually de-emphasised by any fix in this pass.

**B-5 and B-6 remain open.** No recommendations, executive summary, README or portfolio narrative
has been created.
