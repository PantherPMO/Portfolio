# Data Quality

An assessment of the source data: which files were used and why, what problems were found in them, what was done about each, and which fields were withheld from analytical use. Field-level detail is in the [Data Dictionary](data-dictionary.md); analytical definitions are in the [Methodology](../methodology.md).

---

## 1. Source and dataset assessment

Six files were supplied: one merged workbook of 33 columns, and five normalised tables covering demographics, location, population, services and status.

**The five normalised tables are the authoritative source.** The merged workbook is the more convenient of the two, and it was still not used, because a cross-check against the normalised tables found it internally inconsistent with its own components. A file that disagrees with its sources cannot be trusted simply because it is easier to query. The merged workbook is retained for reconciliation only and is never loaded into the analytical schema.

Two of its shortcomings matter beyond the inconsistency. It omits `Customer Status`, which distinguishes established customers from those who joined during the observation quarter, and it introduces `No internet service` and `No phone service` sentinel values in the add-on fields that the normalised source does not use.

Two other public telecoms datasets were assessed before this one and rejected on substance rather than convenience. One lacks contract type and payment method, both of which the segmentation depends on. The other records charges as ordinal bands rather than monetary values, which makes a revenue-at-risk analysis impossible.

### Licence status

Unresolved. No licence statement was located in the publisher's community publication, the vendor documentation was inaccessible, no third-party mirror carried an unambiguous open licence, and the source files contain no embedded licence, copyright notice or terms.

The position taken is that no licensing claim is made and redistribution is assumed not to be permitted. The raw workbooks and the CSV intermediates derived from them are therefore excluded from this repository. Every committed query output is an aggregate produced by this project's own SQL, so no row-level source data is republished.

---

## 2. Data quality issues and resolutions

### The source stores the text "None" where nulls would be expected

The `services` table contains **no true null cells**. All 5,403 of its apparently absent values are the literal text `'None'`. The `status` table uses genuine nulls and no text token. The source therefore applies two different conventions for the same concept, which the publisher does not document.

This surfaced when two cleaning checks failed unexpectedly. The cause was not in the SQL: the spreadsheet-to-CSV conversion step had coerced the literal string `'None'` into a null, so a real category had disappeared before the data reached the database.

The transformation now maps the literal token, a genuine null and an empty string to a single approved label, with a follow-up check confirming no residual token survives. This is a labelling repair; no analytical definition changed. The conversion step was rewritten to remove the dependency that caused the coercion.

The wider point is that the problem was only visible because the checks run inside the database against the values actually loaded, rather than against an in-memory dataframe upstream of it.

### Decile assignment was not reproducible

Splitting customers into ten equal-frequency groups on monthly charge alone leaves tied values to be assigned arbitrarily, so two runs of the same query could place the same customer in different deciles. Five charge values were found spanning a decile boundary, so this was a live problem rather than a theoretical one.

Revenue deciles now order by monthly charge followed by customer ID, giving a deterministic tie-break and stable decile membership across runs.

### An early structural assumption did not hold

An initial assessment of how the five normalised tables relate to the merged extract proved incorrect when tested against the files. The corrected position is the one documented throughout this project: the normalised tables are authoritative, and the merged workbook is a reconciliation source only.

### Failures could look like partial successes

A failing SQL script wrote its error to the console while its output file captured whatever had already succeeded, so an incomplete run could be mistaken for a complete one. Every script invocation now halts at the first error, which makes a failed run unambiguous.

Related to this, console section headers do not reach an output file, so population labels were absent from the committed evidence. Population scope is now carried as an explicit column inside each result set, which means the scope of a figure travels with the figure rather than sitting in a header that could drift away from it. No filter, population, calculation, measure, ranking, segmentation, threshold or ordering was altered in that repair, and the analytical values were identical before and after.

---

## 3. Fields excluded from analytical use

Five fields are loaded into the raw layer for fidelity and are never promoted into the clean model, so no analytical query can reach them.

| Field | Reason for exclusion |
|---|---|
| `Satisfaction Score` | Recorded with knowledge of the churn outcome, and therefore a source of outcome leakage. 100% of customers scoring 1 or 2 churned and none of those scoring 4 or 5 did, with a correlation against the outcome of -0.7546 |
| `Churn Score` | A vendor-supplied propensity score whose construction is undocumented |
| `CLTV` | A vendor-supplied lifetime-value estimate whose construction is undocumented |
| `Churn Reason` | Recorded after the customer left, so any finding built on it would be circular |
| `Churn Category` | Recorded after the customer left, on the same basis |

`Satisfaction Score` is the one that matters most. A model built on it would report excellent accuracy and be worthless, because the score is assigned once the outcome is already known. Excluding it at the database level, rather than remembering to filter it out of each query, is what prevents it being used by accident.

`Churn Reason` and `Churn Category` remain available as a post-analysis sanity check on findings reached without them, but they inform no result.

### Protected characteristics

`Gender`, `Age`, `Under 30` and `Senior Citizen` are held in a separate table that no analytical view joins. They remain available for descriptive profiling and for checking whether an observed relationship is confounded by demographics, and they are never used to target or prioritise retention effort. Two validation checks read the analytical view definitions directly and will report a failure if any of these fields, or any of the five excluded fields above, appears in one.

---

## 4. Known characteristics and limitations

| Characteristic | Detail |
|---|---|
| `Customer Status` is derived | It reproduces exactly from tenure and the churn flag on all 5,174 non-churned records, so it carries no information the two underlying fields do not already hold |
| Two null conventions | `services` uses a literal `'None'` token and `status` uses genuine nulls. Both are structural rather than missing data, and no value is imputed |
| `Monthly Charge` excludes long distance | Long-distance revenue is a separate field, amounting to roughly 31% of the recurring figure again |
| Currency unspecified | No symbol, code or number format appears in any source file, so all monetary values are unitless |
| Single quarter | The quarter field is present but constant, so no trend can be measured and tenure is not a substitute for a time axis |
| Fictional data | The dataset describes a fictional operator, so no observation in it is evidence about a real business or market |

---

## 5. Validation and reproducibility

Profiling covered all six supplied files across fifteen checks. Fourteen resolved cleanly; the fifteenth, the currency question above, could not be resolved from the files and is carried as a stated limitation rather than an assumption.

Within the model, referential integrity, duplicate and reconciliation checks resolved cleanly once the corrections in section 2 were applied. There are no duplicate customer IDs, no null keys and no orphan records in any relationship.

Nineteen further checks run at the end of the analysis stage. They re-derive the headline measures from the underlying tables, confirm that every segmentation dimension partitions its population exactly so that no customer is counted twice or dropped, and read the analytical view definitions to confirm no excluded or restricted field has reached them. All eleven charts were separately reconciled against the query results that produced them, on eight criteria each, with values compared as text so that a re-rounded or reformatted figure is caught rather than passing on numeric tolerance.

Where a check reports a discrepancy, the response is to investigate the discrepancy. Adjusting a definition or an expected value so that a check passes is not a permitted resolution.

Every check is a SQL script in [`../../sql/03_validation/`](../../sql/03_validation/) and [`../../sql/04_analysis/08_analysis_validation.sql`](../../sql/04_analysis/08_analysis_validation.sql), and every result is a committed text file in [`../../analysis/query_results/`](../../analysis/query_results/). The checks can be re-run against a rebuilt database and compared line for line against the committed outputs.
