# Data

## Source

IBM sample telecommunications dataset: **7,043 customers of a fictional operator in California,
covering a single quarter.** Six files: one merged workbook and five normalised tables covering
demographics, location, population, services and status.

The analysis uses the **five normalised tables**. The merged workbook was rejected after validation
found it internally inconsistent with its own components, and is retained only for reconciliation.
See [Data Quality](../docs/technical/data-quality.md).

## Licence status: unresolved

No licence statement was located from the publisher, and the source files contain no embedded licence,
copyright notice or terms. **No licensing claim is made and redistribution is assumed not to be
permitted.**

Consequently:

- **The raw workbooks are not published in this repository.** `data/raw/` contains this note only.
- **The CSV intermediates derived from them are not published either.** They are regenerable in one
  command from the raw files.
- Every committed query output in [`../analysis/query_results/`](../analysis/query_results/) is an
  aggregate produced by this project's own SQL. No row-level source data is republished.

## Obtaining the data

The dataset is distributed as IBM sample content for Cognos Analytics and is mirrored on public data
platforms. Place the six workbooks in `data/raw/`, then convert them:

```bash
pip install openpyxl
python sql/01_setup/convert_xlsx_to_csv.py
```

This writes CSV files to `data/processed/csv/`, which the data load step reads.

## Known characteristics

| Characteristic | Detail |
|---|---|
| **Currency unspecified** | No symbol, code or number format appears in any source file. All monetary values are unitless |
| **Single quarter** | The quarter field is present but constant. No trend exists, and tenure is not a time axis |
| **Two null conventions** | The services file uses the literal text `'None'`; the status file uses genuine nulls. Both are structural, never missing. Values are never imputed |
| **Customer Status is derived** | It reproduces exactly from tenure and churn flag. It carries no independent information |
| **Monthly Charge excludes long-distance** | Long-distance revenue is a separate field, roughly 31% of the recurring figure again |

## Field reference

Field-level detail is in [`../docs/technical/data-dictionary.md`](../docs/technical/data-dictionary.md), including which
fields are excluded from the analysis and why.
