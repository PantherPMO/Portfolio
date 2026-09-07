# Technical Notes

Reproducibility, the chart pipeline, and the validation applied to every figure. Consolidates the
charting specification, the chart validation record and the visual review.

**Related:** [Methodology](../methodology.md) · [Data Quality](data-quality.md) ·
[Findings and Evidence](findings-and-evidence.md)

---

## 1. Running the project

**Requirements:** PostgreSQL 18 or later, Python 3.11 or later.

**Python dependencies for this project are `matplotlib` and `openpyxl`. Nothing else is needed.** The
repository-wide requirements file at the portfolio root covers eight projects and is far broader than
this one requires. In particular pandas is not used here: it was removed during data preparation after
it silently converted a real category to a null value, and the data quality checks were moved into the
database instead.

```bash
# 1. Build and validate the database
#    Full run order and psql invocations: ../../sql/README.md

# 2. Rebuild every chart from the committed query outputs
pip install matplotlib openpyxl
python scripts/build_charts.py

# 3. Verify every chart against its source data
python scripts/validate_charts.py     # exit code 0 only if all 88 checks pass
```

The chart scripts require **no database connection and no credentials.** They read the committed
query outputs, which are the sole input.

---

## 2. How the charts are built

| File | Role |
|---|---|
| [`../../scripts/psql_parse.py`](../../scripts/psql_parse.py) | Parses the committed query output files. Standard library only. Asserts the declared row count against the number of rows parsed and raises on mismatch, which catches a truncated or partially written output file |
| [`../../scripts/build_charts.py`](../../scripts/build_charts.py) | Builds all eleven charts. **No analytical value is hard-coded.** The only literals are labels, colours, axis bounds and source references |
| [`../../scripts/validate_charts.py`](../../scripts/validate_charts.py) | The validation gate described below |
| [`../../analysis/chart_data/`](../../analysis/chart_data/) | The exact rows each chart consumed, one CSV per chart, with the source file and block recorded in the header row |
| [`../../visuals/`](../../visuals/) | The eleven charts, 150 dpi, legible in a README or a case study |

**No chart value is entered by hand.** The builder parses the committed outputs, writes the rows it
used, then renders. A reviewer can open any chart data file, compare it against its named source
output, and reproduce every number on the corresponding chart.

Charts rebuild identically from a clean checkout. Deleting `visuals/` and `analysis/chart_data/` and
re-running reproduces the full set.

### Three derived display values

Three values shown on charts are arithmetic on figures already present in the source outputs. Each is
marked in the code and disclosed on the chart itself. No other arithmetic occurs anywhere in the
chart pipeline.

| Chart | Value | Arithmetic |
|---|---|---|
| Revenue vs customer retention | 4.45 point gap | 78.77 minus 74.32, both shown on the same chart |
| Revenue at risk by segment | 78.93% | 45.95 plus 32.98, both shown on the same chart |
| Early-life contribution | 68.06% | The complement of the sourced 31.94% |

Panel ordering on the seven-dimension chart is by index spread computed from the plotted values. That
affects arrangement only, never a plotted number.

---

## 3. Chart validation

Eleven charts, eight checks each. **88 of 88 pass.**

| Check | What it proves |
|---|---|
| Numeric | Every headline value on the chart appears verbatim in that chart's data file |
| Scope | The data file contains only rows of the declared population, tested against the output's own scope column |
| Excluded fields | No excluded field and no protected characteristic reached the chart |
| Causal language | No causal verb appears in any title, axis label, annotation or footer |
| Weak result honesty | The two charts showing weak results state that in their own titles |
| Dimension coverage | The driver charts contain all seven dimensions, including the weak ones |
| Labels | Source file, block and population designation are present where required |
| File integrity | The image exists, is a valid non-empty PNG, and has plausible dimensions |

Values are compared **as text, not as numbers**, so a figure that has been re-rounded or reformatted
fails rather than passing on numeric tolerance.

---

## 4. Chart design rules

Every chart carries:

- The population it describes, stated below the axes with its size
- Its source file and block
- Currency stated as unitless currency units, never a symbol
- The group size shown for any group below 100
- Caveats adjacent to the claim they qualify, never deferred to a footnote
- A note that the data is fictional, covers a single window, and shows association only

**Two charts report weak results, and both say so in their titles.** The chart form was chosen so the
weak result reads as weak: the ranking comparison uses a slope chart in which five of nine lines are
flat and are drawn flat in muted grey. A bar chart of the differences would have shown four visible
bars and looked like a result.

**All seven dimensions appear on the driver chart at their true magnitudes**, on identical axes,
including the two that barely differentiate. None is omitted, rescaled or visually de-emphasised.

### Charts deliberately not produced

| Not built | Reason |
|---|---|
| Month-by-month rate curve for new customers | Would read as a survival curve. Each month is a different joining group observed for a different length of time within one quarter. The figures are quotable in prose with that caveat; they are not plottable |
| Retention spend break-even | No profit margin was available |
| Industry benchmark comparison | No published churn benchmark source was found |
| Sensitivity version of the ranking comparison | Only two of nine groups change, each by one position. A chart would imply more substance than the result has |
| Explanation of the top-decile dip | The data does not establish a cause. Annotated as unexplained instead |

Groups below the reporting threshold are collapsed rather than plotted as rates. On the new-customer
composition chart, two contract categories with 26 and 22 customers appear as a single labelled band
with no rate shown.

---

## 5. Visual review

All eleven charts were inspected at portfolio viewing size against readability, title clarity, scope
clarity, axis readability, label and annotation collisions, legend placement, whitespace, visual
hierarchy, immediacy, caveat visibility, chart-type fit, exaggeration risk and cross-chart
consistency.

**Outcome: 5 ready as built, 5 minor presentation fixes, 1 major presentation fix.** All fixes applied
and re-verified. Fixes covered figure dimensions, axis limits, label positioning, one title line wrap
and one label backing box.

**No analytical value changed.** The chart data files were confirmed byte-identical to their
pre-review versions afterwards, and the validation gate re-ran clean at 88 of 88.

Checks that raised nothing across all eleven charts: percentage axes start at zero throughout, no dual
axis distortion, no area-encoded quantities, no colour used to inflate a weak difference, and one
consistent palette, footer format and typeface.

---

## 6. Evidence traceability

Every figure in this project traces along a fixed chain:

```
Business question
 └─ Analytical question
     └─ Finding
         └─ Observed value, with its population and source file
             └─ Interpretation
                 └─ Inference, always labelled as such
                     └─ Limitation
                         └─ Chart
```

Seventeen cross-checks reconcile the findings against each other and all hold exactly. For example the
two customer populations sum to the full base, the two sets of churn counts sum to the total, and the
revenue at risk figures sum across populations.

Full detail is in [Findings and Evidence](findings-and-evidence.md).
