# ANALYSE — Execution Guide

**Target:** native PostgreSQL 18.6 · `telco_portfolio` · `localhost:5432`
**Executed locally by Peters.** No script in this project has been run in any other environment.

> **Plan first:** [`../../docs/ANALYSE_PLAN.md`](../../docs/ANALYSE_PLAN.md). **A-07 is locked (D-21):** primary = opening cohort; all-customers is a labelled sensitivity analysis.

---

## Prerequisites

PREPARE must be complete and validated. If this is a fresh PowerShell window:

```powershell
$PROJECT_ROOT = "<path-to-your-clone>\01-sql-telecom-churn-revenue"
cd $PROJECT_ROOT
$env:Path = "C:\Program Files\PostgreSQL\18\bin;" + $env:Path
$env:PGHOST="localhost"; $env:PGPORT="5432"
$env:PGDATABASE="telco_portfolio"; $env:PGUSER="postgres"
psql --version
```

---

## Run Order

**Views first, then extracts, then validation.** The extracts read the views; the validation reads both.

```powershell
$analyse = @(
  # --- 04_kpi_views : the analytical logic ---
  "sql\04_kpi_views\01_vw_kpi_churn_rate.sql",
  "sql\04_kpi_views\02_vw_kpi_revenue_at_risk.sql",
  "sql\04_kpi_views\03_vw_kpi_revenue_concentration.sql",
  "sql\04_kpi_views\04_vw_kpi_arpu.sql",
  "sql\04_kpi_views\05_vw_kpi_revenue_retention.sql",
  "sql\04_kpi_views\06_vw_kpi_early_life_churn.sql",
  "sql\04_kpi_views\07_vw_segment_p1_value_contract.sql",
  "sql\04_kpi_views\08_vw_segment_p2_revenue_decile.sql",
  "sql\04_kpi_views\09_vw_segment_divergence.sql",
  "sql\04_kpi_views\10_vw_driver_lenses.sql",
  # --- 03_analysis : the question-by-question extracts ---
  "sql\03_analysis\01_base_position.sql",
  "sql\03_analysis\02_revenue_concentration.sql",
  "sql\03_analysis\03_churn_by_revenue_decile.sql",
  "sql\03_analysis\04_value_risk_divergence.sql",
  "sql\03_analysis\05_drivers_high_value.sql",
  "sql\03_analysis\06_drivers_comparison.sql",
  "sql\03_analysis\07_early_life_churn.sql",
  # --- validation gate, runs last ---
  "sql\03_analysis\08_analysis_validation.sql"
)

$map = @{
  "01_vw_kpi_churn_rate"           = "analyse_v01_churn_rate.txt"
  "02_vw_kpi_revenue_at_risk"      = "analyse_v02_revenue_at_risk.txt"
  "03_vw_kpi_revenue_concentration"= "analyse_v03_concentration.txt"
  "04_vw_kpi_arpu"                 = "analyse_v04_arpu.txt"
  "05_vw_kpi_revenue_retention"    = "analyse_v05_revenue_retention.txt"
  "06_vw_kpi_early_life_churn"     = "analyse_v06_early_life.txt"
  "07_vw_segment_p1_value_contract"= "analyse_v07_p1_segments.txt"
  "08_vw_segment_p2_revenue_decile"= "analyse_v08_p2_deciles.txt"
  "09_vw_segment_divergence"       = "analyse_v09_divergence_view.txt"
  "10_vw_driver_lenses"            = "analyse_v10_driver_lenses.txt"
  "01_base_position"               = "analyse_01_base_position.txt"
  "02_revenue_concentration"       = "analyse_02_revenue_concentration.txt"
  "03_churn_by_revenue_decile"     = "analyse_03_churn_by_decile.txt"
  "04_value_risk_divergence"       = "analyse_04_divergence.txt"
  "05_drivers_high_value"          = "analyse_05_drivers_high_value.txt"
  "06_drivers_comparison"          = "analyse_06_drivers_comparison.txt"
  "07_early_life_churn"            = "analyse_07_early_life_churn.txt"
  "08_analysis_validation"         = "analyse_08_validation.txt"
}

New-Item -ItemType Directory -Force -Path analysis\query_results | Out-Null

foreach ($s in $analyse) {
    $key = [IO.Path]::GetFileNameWithoutExtension($s)
    $out = "analysis\query_results\" + $map[$key]
    Write-Host "==> $s"
    psql -v ON_ERROR_STOP=1 -f $s -o $out
    if ($LASTEXITCODE -ne 0) { Write-Host "FAILED at $s - stopping." -ForegroundColor Red; break }
}
Write-Host "Done."
```

**`-v ON_ERROR_STOP=1` is not optional.** Without it a failing statement writes its error to the console while the output file quietly captures whatever succeeded — which is exactly how the merged cross-check failure went unnoticed at PREPARE.

---

## Note — Output Labelling (D-22)

Extract blocks identify their population scope with an **explicit column** in the result set. `psql \echo` writes to stdout, not to the `-o` file, so section headers never reach the committed evidence — the `\echo` lines remain only as console aids while running interactively.

`analyse_04_divergence.txt` carries a `result_designation` column reading **`PRIMARY RESULT - Opening cohort`** or **`SENSITIVITY ANALYSIS ONLY - All customers`** on every row, so the locked A-07 designation is visible in the artefact itself.

---

## Output Files to Send Back

Eighteen files. The eight that carry the analytical answers:

| File | Contains |
|---|---|
| `analyse_01_base_position.txt` | **F-01** — churn rates, revenue at risk, revenue retention |
| `analyse_02_revenue_concentration.txt` | **F-02** — Pareto curve, top-decile share |
| `analyse_03_churn_by_decile.txt` | **F-03** — churn by revenue decile, ARPU by tier |
| `analyse_04_divergence.txt` | **F-04** — P1 segments and the divergence index, both scopes |
| `analyse_05_drivers_high_value.txt` | **F-05** — all seven lenses, High tier |
| `analyse_06_drivers_comparison.txt` | **F-06** — High tier vs base-wide |
| `analyse_07_early_life_churn.txt` | **F-07** — in-period acquisitions |
| `analyse_08_validation.txt` | **A-VAL-01 to A-VAL-19 — the gate** |

The ten `analyse_v*.txt` files are the views' own self-check output. Send them too — they are cheap and they let me confirm each view built at the expected grain.

---

## What These Scripts Do Not Do

**No findings. No insights. No recommendations. No charts. No narrative.**

The scripts produce numbered, evidenced outputs. Interpretation is a separate step requiring your approval, and every claim will then need a complete evidence chain back to a specific query and a committed result file.

---

## Stop Conditions

Stop and send me the output if any of these occur:

1. **Any check in `analyse_08_validation.txt` reports FAIL**
2. **A-VAL-02a or A-VAL-02b fails** — the locked KPIs are not reproducing; something upstream has changed
3. **A-VAL-11 fails** — a lens is not partitioning its scope, meaning a customer is double-counted or missing
4. **A-VAL-19 fails** — a prohibited field has reached an analytics view
5. `psql` reports any error at all

Under the immutability rule a failure returns for review. It does not license adjusting a definition or an expectation.

---

## Convention Note

PREPARE validation lives in `02_eda/`. This ANALYSE validation sits in `03_analysis/08_analysis_validation.sql` because it depends on the analysis views and must run after them. Flagged here rather than filed silently against convention.
