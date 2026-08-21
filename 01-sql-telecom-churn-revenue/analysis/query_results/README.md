# Query Results

**Committed text evidence from the locally-executed SQL pipeline. This directory is the numerical
source of truth for the whole project.**

Every file here was produced by running `psql` against the local PostgreSQL 18.6 instance. Nothing in
this directory was generated in any other environment, and no value here has been edited by hand.

**43 files:** 24 PREPARE outputs, 18 ANALYSE outputs, and this README.

---

## Naming

| Prefix | Stage | Produced by |
|---|---|---|
| `prepare_*` | PREPARE | `sql/00_setup/`, `sql/01_cleaning/`, `sql/02_eda/` |
| `analyse_v*` | ANALYSE | `sql/04_kpi_views/` — each view's own self-check output, one per view |
| `analyse_0*` | ANALYSE | `sql/03_analysis/` — the question-by-question extracts and the validation gate |

Output filenames map to their source script. Run order and the exact `psql` invocations are in
[`../../sql/00_setup/README.md`](../../sql/00_setup/README.md) for PREPARE and
[`../../sql/03_analysis/README.md`](../../sql/03_analysis/README.md) for ANALYSE.

---

## The eight files carrying the analytical answers

| File | Contains |
|---|---|
| `analyse_01_base_position.txt` | **F-01** churn rates, revenue at risk, revenue retention |
| `analyse_02_revenue_concentration.txt` | **F-02** Pareto curve, top-decile share |
| `analyse_03_churn_by_decile.txt` | **F-03** churn by revenue decile, ARPU by tier and outcome |
| `analyse_04_divergence.txt` | **F-04** P1 segments and the divergence index, both scopes |
| `analyse_05_drivers_high_value.txt` | **F-05** all seven driver lenses, High tier |
| `analyse_06_drivers_comparison.txt` | **F-06** High tier vs base-wide |
| `analyse_07_early_life_churn.txt` | **F-07** in-period acquisitions |
| `analyse_08_validation.txt` | **A-VAL-01 to A-VAL-19, the gate. All PASS** |

The ten `analyse_v*.txt` files are each view's self-check output. They confirm every view built at the
expected grain.

---

## Scope labels live in the data (decision D-22)

`psql \echo` writes to stdout, not to the `-o` output file, so section headers never reached the
committed evidence. Population scope is therefore carried as an **explicit column** in the result set
itself: `population_scope`, `scope`, `scope_cohort`, `scope_tier`, `result_designation` or `check_id`,
depending on the query.

`analyse_04_divergence.txt` carries `result_designation` on every row, reading either
**`PRIMARY RESULT - Opening cohort`** or **`SENSITIVITY ANALYSIS ONLY - All customers`**, so the
locked A-07 designation is visible in the artefact rather than only in a document that could drift.

---

## Re-runs

`-v ON_ERROR_STOP=1` is used on every invocation. Without it, a failing statement writes its error to
the console while the output file quietly captures whatever succeeded, which is exactly how a
cross-check failure went unnoticed once during PREPARE.

Where an approved fix required a script to be re-run, the corrected output **overwrites the original
file of the same name**, so each script has exactly one current output. During the PREPARE repair,
six re-run outputs were briefly kept alongside the originals under a `run2_` prefix for comparison.
They were confirmed byte-identical to the `prepare_*` files they duplicated and were removed at
release; no `run2_` files remain.

---

## How these files are consumed

`scripts/build_charts.py` parses these outputs with `scripts/psql_parse.py` and writes the exact rows
each chart used to `outputs/chart_data/`. **No chart value is typed by hand.** The parser asserts
psql's own declared `(N rows)` footer against the number of rows it parsed and raises on mismatch,
which is the tripwire for a truncated or partially written output file.

`scripts/validate_charts.py` then checks every figure back against these outputs and against
[`../../docs/FINDING_EVIDENCE_REGISTER.md`](../../docs/FINDING_EVIDENCE_REGISTER.md), comparing values
as strings rather than floats so a re-rounded figure fails rather than passing on tolerance.

---

## Do not edit

These files are evidence. If a number here is wrong, the fix is to correct the SQL and re-run the
script, not to edit the output. Every figure in the README, the case study, the evidence register and
all eleven charts traces back to a named file and block in this directory.
