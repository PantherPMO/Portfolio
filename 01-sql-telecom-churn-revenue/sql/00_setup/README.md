# PREPARE — Setup and Execution Guide

**Target:** native **PostgreSQL 18.6** on Windows · database `telco_portfolio` · `localhost:5432`
**Docker is not used in this project.**

> **Execution model.** These scripts are written here and executed **by Peters, locally**. No script in this project has been run in any other environment, and no result in this repository was produced anywhere other than on the local machine.

---

## Step 0 — Put `psql` on PATH

The PostgreSQL Windows installer does **not** add its `bin` directory to PATH. Without this you get:

```
psql : The term 'psql' is not recognized as the name of a cmdlet, function, script file, or operable program.
```

**Find it** (works whatever the version number):

```powershell
Get-ChildItem "C:\Program Files\PostgreSQL" -Directory |
  ForEach-Object { Join-Path $_.FullName "bin\psql.exe" } |
  Where-Object { Test-Path $_ }
```

Expected for PostgreSQL 18: `C:\Program Files\PostgreSQL\18\bin\psql.exe`

**Add it for this session** — takes effect immediately, disappears when you close the window:

```powershell
$env:Path = "C:\Program Files\PostgreSQL\18\bin;" + $env:Path
psql --version    # should print: psql (PostgreSQL) 18.6
```

**Add it permanently** — optional, but saves repeating Step 0 every time. Affects your user account only, no admin rights needed. **Open a new PowerShell window afterwards**; the current one won't see it:

```powershell
[Environment]::SetEnvironmentVariable(
    "Path",
    "C:\Program Files\PostgreSQL\18\bin;" + [Environment]::GetEnvironmentVariable("Path", "User"),
    "User")
```

If the discovery command returns nothing, PostgreSQL is installed somewhere non-standard. Search for it:

```powershell
Get-ChildItem C:\ -Recurse -Filter psql.exe -ErrorAction SilentlyContinue |
  Select-Object -First 5 FullName
```

> **Session-scoped variables reset.** `$env:Path` and the `$env:PG*` variables below last only for the current PowerShell window. Open a new one and you must set them again — or use the permanent form above.

---

## Before You Start

**Everything runs from the project root.** The `\copy` paths in `03_load_raw.sql` are relative to your working directory, so this matters:

```powershell
# Set PROJECT_ROOT to wherever you cloned this repository.
$PROJECT_ROOT = "<path-to-your-clone>\01-sql-telecom-churn-revenue"
cd $PROJECT_ROOT
```

**Never put your password in a command.** `psql` will prompt. Set the connection parameters as environment variables for the session — everything except the password:

```powershell
$env:PGHOST     = "localhost"
$env:PGPORT     = "5432"
$env:PGDATABASE = "telco_portfolio"
$env:PGUSER     = "postgres"
# PGPASSWORD deliberately not set — psql will prompt per connection.
```

If prompting each time gets tedious, use a `%APPDATA%\postgresql\pgpass.conf` file, which keeps the credential out of your shell history and out of this repository. Never add it to git.

---

## Step 1 — Convert the workbooks to CSV

```powershell
python sql\00_setup\convert_xlsx_to_csv.py
```

Expected output: six rows, all `OK`, matching 7043×9, 7043×9, 1671×3, 7043×30, 7043×11, 7043×33.

**A shape mismatch means these are not the files verified at Stage 2. Stop and tell me — do not load them.**

If `pandas` is missing: `pip install pandas openpyxl`.

> **Do not substitute Excel's "Save As CSV".** Excel writes *displayed* values, which truncates the high-precision decimals in `Total Long Distance Charges` and `Total Revenue` and would break reconciliation check REC-08.

---

## Step 2 — Build the schema and load

Run in this exact order. **Note steps 2f and 2g: `dim_population` must exist before `dim_location`, because `dim_location.zip_code` has a foreign key to it.**

```powershell
# --- 00_setup ---
psql -f sql\00_setup\01_create_schemas.sql      -o analysis\query_results\prepare_01_schemas.txt
psql -f sql\00_setup\02_create_raw_tables.sql   -o analysis\query_results\prepare_02_raw_tables.txt
psql -f sql\00_setup\03_load_raw.sql            -o analysis\query_results\prepare_03_load_raw.txt
psql -f sql\00_setup\04_create_core_tables.sql  -o analysis\query_results\prepare_04_core_tables.txt
psql -f sql\00_setup\05_create_dim_service.sql  -o analysis\query_results\prepare_05_dim_service.txt

# --- 01_cleaning (ORDER MATTERS) ---
psql -f sql\01_cleaning\01_promote_dim_customer.sql            -o analysis\query_results\prepare_c01_dim_customer.txt
psql -f sql\01_cleaning\02_promote_restricted_demographics.sql -o analysis\query_results\prepare_c02_restricted.txt
psql -f sql\01_cleaning\04_promote_dim_population.sql          -o analysis\query_results\prepare_c04_population.txt
psql -f sql\01_cleaning\03_promote_dim_location.sql            -o analysis\query_results\prepare_c03_location.txt
psql -f sql\01_cleaning\05_promote_dim_contract.sql            -o analysis\query_results\prepare_c05_contract.txt
psql -f sql\01_cleaning\06_promote_fact_customer_status.sql    -o analysis\query_results\prepare_c06_fact.txt
psql -f sql\01_cleaning\07_build_bridge_customer_service.sql   -o analysis\query_results\prepare_c07_bridge.txt
psql -f sql\01_cleaning\08_cleaning_reconciliation.sql         -o analysis\query_results\prepare_c08_reconciliation.txt
psql -f sql\01_cleaning\09_create_analytical_base_view.sql     -o analysis\query_results\prepare_c09_base_view.txt

# --- indexes (after the tables are populated) ---
psql -f sql\00_setup\06_create_indexes.sql      -o analysis\query_results\prepare_06_indexes.txt
```

---

## Step 3 — Run the validation gates

```powershell
psql -f sql\02_eda\01_referential_integrity.sql  -o analysis\query_results\prepare_v01_referential_integrity.txt
psql -f sql\02_eda\02_duplicate_checks.sql       -o analysis\query_results\prepare_v02_duplicates.txt
psql -f sql\02_eda\03_source_reconciliation.sql  -o analysis\query_results\prepare_v03_reconciliation.txt
psql -f sql\02_eda\04_merged_cross_check.sql     -o analysis\query_results\prepare_v04_merged_crosscheck.txt
psql -f sql\02_eda\05_analytical_validation.sql  -o analysis\query_results\prepare_v05_analytical_validation.txt
psql -f sql\02_eda\06_distribution_profile.sql   -o analysis\query_results\prepare_v06_distributions.txt
psql -f sql\02_eda\07_segment_cell_sizes.sql     -o analysis\query_results\prepare_v07_cell_sizes.txt
psql -f sql\02_eda\08_categorical_inventory.sql  -o analysis\query_results\prepare_v08_categoricals.txt
psql -f sql\02_eda\09_confounding_checks.sql     -o analysis\query_results\prepare_v09_confounding.txt
```

### Run it all in one go

If you'd rather not paste sixteen commands, this runs the lot and **stops at the first error** (`-v ON_ERROR_STOP=1`):

```powershell
$PROJECT_ROOT = "<path-to-your-clone>\01-sql-telecom-churn-revenue"
cd $PROJECT_ROOT
$env:PGHOST="localhost"; $env:PGPORT="5432"
$env:PGDATABASE="telco_portfolio"; $env:PGUSER="postgres"

$steps = @(
  "sql\00_setup\01_create_schemas.sql",
  "sql\00_setup\02_create_raw_tables.sql",
  "sql\00_setup\03_load_raw.sql",
  "sql\00_setup\04_create_core_tables.sql",
  "sql\00_setup\05_create_dim_service.sql",
  "sql\01_cleaning\01_promote_dim_customer.sql",
  "sql\01_cleaning\02_promote_restricted_demographics.sql",
  "sql\01_cleaning\04_promote_dim_population.sql",
  "sql\01_cleaning\03_promote_dim_location.sql",
  "sql\01_cleaning\05_promote_dim_contract.sql",
  "sql\01_cleaning\06_promote_fact_customer_status.sql",
  "sql\01_cleaning\07_build_bridge_customer_service.sql",
  "sql\01_cleaning\08_cleaning_reconciliation.sql",
  "sql\01_cleaning\09_create_analytical_base_view.sql",
  "sql\00_setup\06_create_indexes.sql",
  "sql\02_eda\01_referential_integrity.sql",
  "sql\02_eda\02_duplicate_checks.sql",
  "sql\02_eda\03_source_reconciliation.sql",
  "sql\02_eda\04_merged_cross_check.sql",
  "sql\02_eda\05_analytical_validation.sql",
  "sql\02_eda\06_distribution_profile.sql",
  "sql\02_eda\07_segment_cell_sizes.sql",
  "sql\02_eda\08_categorical_inventory.sql",
  "sql\02_eda\09_confounding_checks.sql"
)

New-Item -ItemType Directory -Force -Path analysis\query_results | Out-Null
foreach ($s in $steps) {
    $name = ($s -replace '\\','_') -replace '\.sql$',''
    Write-Host "==> $s"
    psql -v ON_ERROR_STOP=1 -f $s -o "analysis\query_results\$name.txt"
    if ($LASTEXITCODE -ne 0) { Write-Host "FAILED at $s — stopping." -ForegroundColor Red; break }
}
```

---

## Step 4 — Return the evidence

Send me the contents of `analysis\query_results\`. The files that matter most:

| File | Contains |
|---|---|
| `prepare_03_load_raw.txt` | REC-01 |
| `prepare_c08_reconciliation.txt` | REC-02 |
| `prepare_v01_referential_integrity.txt` | RI-01 to RI-08 |
| `prepare_v02_duplicates.txt` | DUP-01 to DUP-05 |
| `prepare_v03_reconciliation.txt` | REC-03 to REC-12 |
| `prepare_v04_merged_crosscheck.txt` | REC-13 to REC-18 |
| `prepare_v05_analytical_validation.txt` | **VAL-01 to VAL-10 — the final gate** |

I'll validate them against the Stage 2 verified figures and document the results.

**If any check reports FAIL, stop there and send me the output.** Under the immutability rule a failure returns for review — it does not license changing a definition or an expectation to make it pass.

---

## What These Scripts Do and Do Not Do

**Created:** three schemas (`raw`, `core`, `analytics`), six raw tables, eight core tables, one helper function, one view, seven indexes. **Nothing else in your database is touched.**

**Not created:** any analytical query, any KPI or segment view producing a business number, any finding, any chart. Those are ANALYSE stage and require your approval.

**Structurally enforced:**

- **Five excluded fields** (`Satisfaction Score`, `Churn Score`, `CLTV`, `Churn Reason`, `Churn Category`) load into `raw` and are **never promoted to `core`**. They exist nowhere in the analytical layer. Retained in `raw` so the exclusion stays auditable.
- **Four restricted fields** (`gender`, `age`, `under_30`, `senior_citizen`) live in `core.restricted_demographics`, which **no analytical view joins**. One script references it, and its header states the prohibition.
- **The merged workbook** is referenced by exactly one script — `04_merged_cross_check.sql`.
- **VAL-09** scans every `core` and `analytics` view definition for a prohibited reference and must return zero.

---

## Deviation From the Approved Specification — flagged, not silent

The PREPARE specification listed `vw_customer_analytical_base` under `04_kpi_views/` as an ANALYSE artefact. **That was an inconsistency in my own specification:** validation checks VAL-01 to VAL-08 depend on that view, and those checks are a PREPARE gate.

The view is infrastructure — it derives approved definitions and produces no business number of its own — so it is built at PREPARE as `01_cleaning/09_create_analytical_base_view.sql`. The KPI, segment and driver views remain ANALYSE-stage and are not written.

**File count is therefore 25, not the 24 stated in the specification.** Flagging rather than quietly adjusting the count.

---

## Troubleshooting

| Symptom | Cause and fix |
|---|---|
| `psql : The term 'psql' is not recognized...` | PostgreSQL's `bin` is not on PATH. See **Step 0** |
| `python : ... is not recognized` | Same problem, different program. Locate it with `Get-Command python -All`, or use the full path to `python.exe` |
| `openpyxl is not installed for this interpreter` | Run `python -m pip install openpyxl`. If it reports "already satisfied", you have more than one Python — use the fully-qualified `-m pip install` form the script prints |
| `could not open file "data/processed/csv/..."` | `psql` was not started from the project root. `\copy` paths are relative to your working directory |
| `ERROR: relation "core.dim_population" does not exist` | Cleaning scripts run out of order. `04_promote_dim_population.sql` must run **before** `03_promote_dim_location.sql` |
| `core.yn_to_bool: unexpected value ...` | A service flag holds something other than `Yes`/`No`. **This contradicts Stage 2 verification — stop and send me the value** |
| `null value in column ... violates not-null constraint` | A null reached `core`. Stage 2 found no genuine missing values, so this is a structural contradiction — **stop and escalate** |
| `numeric field overflow` | A value exceeds `numeric(12,4)`. Send me the row |
| Any check reports `FAIL` | Stop. Send the output. Do not adjust anything to make it pass |
