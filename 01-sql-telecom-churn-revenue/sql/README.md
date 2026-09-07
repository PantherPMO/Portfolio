# SQL Pipeline

42 SQL files in five stages. Run them in folder order; within each folder run in filename order.

| Folder | Purpose |
|---|---|
| `01_setup/` | Schemas, raw landing tables, source load, typed core tables, indexes |
| `02_preparation/` | Raw to core transformation, cleaning, the analytical base view |
| `03_validation/` | Data quality checks: integrity, duplicates, reconciliation, distributions |
| `04_analysis/` | The business analysis queries and the analysis validation gate |
| `05_reporting_views/` | Ten KPI and segmentation views |

**Views before extracts.** The `04_analysis/` scripts read the views in `05_reporting_views/`, so
build the views first. The numbering reflects logical grouping, not a strict left-to-right sequence:
run `01` to `03`, then `05_reporting_views`, then `04_analysis`.

---

## Prerequisites

PostgreSQL 18 or later. Set `PROJECT_ROOT` to your clone and work from the project folder, because the
data load paths are relative to it.

```powershell
$PROJECT_ROOT = "<path-to-your-clone>\01-sql-telecom-churn-revenue"
cd $PROJECT_ROOT
$env:Path = "C:\Program Files\PostgreSQL\18\bin;" + $env:Path
$env:PGHOST="localhost"; $env:PGPORT="5432"
$env:PGDATABASE="telco_portfolio"; $env:PGUSER="postgres"
psql --version
```

**Do not put a password in a command.** `psql` prompts for it. `PGPASSWORD` is deliberately not set.

---

## Source data

The raw workbooks are not published in this repository because the dataset licence is unresolved. See
[`../data/README.md`](../data/README.md) for the source and how to obtain the files.

Once the workbooks are in `data/raw/`, convert them to CSV:

```bash
pip install openpyxl
python sql/01_setup/convert_xlsx_to_csv.py
```

---

## Run order

```powershell
$steps = @(
  "sql\01_setup\01_create_schemas.sql",
  "sql\01_setup\02_create_raw_tables.sql",
  "sql\01_setup\03_load_raw.sql",
  "sql\01_setup\04_create_core_tables.sql",
  "sql\01_setup\05_create_dim_service.sql",
  "sql\01_setup\06_create_indexes.sql",
  "sql\02_preparation\01_promote_dim_customer.sql",
  "sql\02_preparation\02_promote_restricted_demographics.sql",
  "sql\02_preparation\03_promote_dim_location.sql",
  "sql\02_preparation\04_promote_dim_population.sql",
  "sql\02_preparation\05_promote_dim_contract.sql",
  "sql\02_preparation\06_promote_fact_customer_status.sql",
  "sql\02_preparation\07_build_bridge_customer_service.sql",
  "sql\02_preparation\08_cleaning_reconciliation.sql",
  "sql\02_preparation\09_create_analytical_base_view.sql",
  "sql\03_validation\01_referential_integrity.sql",
  "sql\03_validation\02_duplicate_checks.sql",
  "sql\03_validation\03_source_reconciliation.sql",
  "sql\03_validation\04_merged_cross_check.sql",
  "sql\03_validation\05_analytical_validation.sql",
  "sql\03_validation\06_distribution_profile.sql",
  "sql\03_validation\07_segment_cell_sizes.sql",
  "sql\03_validation\08_categorical_inventory.sql",
  "sql\03_validation\09_confounding_checks.sql",
  "sql\05_reporting_views\01_vw_kpi_churn_rate.sql",
  "sql\05_reporting_views\02_vw_kpi_revenue_at_risk.sql",
  "sql\05_reporting_views\03_vw_kpi_revenue_concentration.sql",
  "sql\05_reporting_views\04_vw_kpi_arpu.sql",
  "sql\05_reporting_views\05_vw_kpi_revenue_retention.sql",
  "sql\05_reporting_views\06_vw_kpi_early_life_churn.sql",
  "sql\05_reporting_views\07_vw_segment_p1_value_contract.sql",
  "sql\05_reporting_views\08_vw_segment_p2_revenue_decile.sql",
  "sql\05_reporting_views\09_vw_segment_divergence.sql",
  "sql\05_reporting_views\10_vw_driver_lenses.sql",
  "sql\04_analysis\01_base_position.sql",
  "sql\04_analysis\02_revenue_concentration.sql",
  "sql\04_analysis\03_churn_by_revenue_decile.sql",
  "sql\04_analysis\04_value_risk_divergence.sql",
  "sql\04_analysis\05_drivers_high_value.sql",
  "sql\04_analysis\06_drivers_comparison.sql",
  "sql\04_analysis\07_early_life_churn.sql",
  "sql\04_analysis\08_analysis_validation.sql"
)

New-Item -ItemType Directory -Force -Path analysis\query_results | Out-Null

foreach ($s in $steps) {
    Write-Host "==> $s"
    psql -v ON_ERROR_STOP=1 -f $s
    if ($LASTEXITCODE -ne 0) { Write-Host "FAILED at $s - stopping." -ForegroundColor Red; break }
}
```

**`-v ON_ERROR_STOP=1` is not optional.** Without it a failing statement writes its error to the
console while the output file quietly captures whatever succeeded, which is how one cross-check
failure went unnoticed during development.

To capture output to the committed evidence files, add `-o analysis\query_results\<name>.txt` to each
invocation. Existing outputs in [`../analysis/query_results/`](../analysis/query_results/) show the
expected filename for each script.

---

## What to check

The last script, `04_analysis/08_analysis_validation.sql`, is the gate. It runs 19 checks covering
measure reproduction, population integrity and field exclusions. **Every check must report PASS.**

A failed check returns for review. It does not license adjusting a definition or an expectation so
that the check passes.

---

## Conventions

Full detail in [`../docs/methodology.md`](../docs/methodology.md). In summary:

- Population scope travels as an explicit column in every result set, not as a console header
- Monetary values are unitless currency units; the source currency is unspecified
- Fields recording information known only after a customer left are never promoted into the core layer
- Decile assignment breaks ties on customer ID so results are reproducible across runs
