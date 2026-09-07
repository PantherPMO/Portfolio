# Data Quality

Source selection, the checks run against the data, the issues those checks found, and the corrections
applied. Consolidates the dataset assessment and the validation record.

**Related:** [Methodology](../methodology.md) · [Data Dictionary](data-dictionary.md) ·
[Findings and Evidence](findings-and-evidence.md)

---

## 1. Source selection

Six files were supplied: one merged workbook and five normalised tables covering demographics,
location, population, services and status.

**The merged workbook was rejected.** It is the more convenient source, and it was still rejected,
because a cross-check against the five normalised tables found it internally inconsistent with its own
components. A file that disagrees with its sources cannot be trusted simply because it is easier to
query. The merged file is retained in the model as a reconciliation table only.

Other datasets were considered before this one. The two closest alternatives were rejected on
substance: one lacks contract type and payment method, which the segmentation depends on; the other
records charges as ordinal bands rather than monetary values, which makes a revenue-at-risk analysis
impossible.

### Licence status

**Unresolved.** No licence statement was located from the publisher's community publication, the
vendor documentation was inaccessible, no third-party mirror carried an unambiguous open licence, and
the source files contain no embedded licence, copyright notice or terms.

**Position: no licensing claim is made, and redistribution is assumed not to be permitted.** The raw
workbooks and the CSV intermediates derived from them are excluded from the repository. Every
committed query output is an aggregate produced by this project's own SQL.

---

## 2. Fields excluded from the analysis

Five fields are loaded to the raw layer for fidelity and then never promoted into the clean model, so
no analytical query can reach them.

| Field | Reason for exclusion |
|---|---|
| **Satisfaction Score** | Recorded with knowledge of the outcome. 100% of customers scoring 1 or 2 churned; 0% of those scoring 4 or 5 did. Correlation against the outcome is -0.7546 |
| **Churn Score** | A vendor-supplied propensity score of unknown construction |
| **CLTV** | A vendor-supplied derived value of unknown construction |
| **Churn Reason** | Recorded after the customer left. Using it produces circular findings |
| **Churn Category** | As above |

**Satisfaction Score is the one that matters most.** A model built on it would show excellent accuracy
and be worthless, because the score is assigned once the outcome is already known. This is the most
common way an analysis of this dataset goes quietly wrong, and excluding the field at the database
level is what prevents it.

**Protected characteristics** are held in a separate table that no analytical view joins. They remain
available for descriptive and fairness checks and are never used to target retention effort. Two
validation checks scan the view definitions directly and fail the build if any prohibited field
appears.

---

## 3. Checks run

| Area | Checks | Result |
|---|---|---|
| Source profiling | 15 checks across all six files | 14 pass, 1 unresolved (currency), 0 fail |
| Referential integrity, duplicates, reconciliation | Preparation-stage checks across the model | All pass after corrections below |
| Analysis validation | 19 checks covering measure reproduction, population integrity and field exclusions | **All pass** |
| Chart validation | 11 charts, 8 checks each | **88 of 88 pass** |

The analysis checks include three that are load-bearing. One re-derives the headline measures and
fails if anything upstream has changed. One confirms every segmentation dimension splits its
population exactly, catching any customer counted twice or dropped. One scans the view definitions for
excluded fields.

**A failed check returns for review. It does not license adjusting a definition or an expectation so
that the check passes.**

---

## 4. Issues found and corrected

Three defects were found during the build. All three are recorded with the original finding preserved
rather than overwritten.

### The source stores the text "None" where nulls were expected

Two cleaning checks failed unexpectedly. The cause was not in the SQL: the CSV conversion step had
silently converted the literal string `'None'` into a null value, so a real category had disappeared
before the data reached the database.

The services file contains **zero true null cells.** All 5,403 of its apparently absent values are the
literal text `'None'`. The status file uses genuine nulls and no text token. The source uses two
different conventions for the same concept, which is itself a finding and is not documented by the
publisher.

**Correction:** the transformation now maps the literal token, a genuine null and an empty string to
the same approved label, with a guard check confirming no residual token survives. A label repair, not
a change to any analytical definition.

This was caught only because the checks ran **in the database**, against the values actually loaded,
rather than against an in-memory dataframe. The conversion step was subsequently rewritten to remove
that dependency entirely.

### Decile assignment was not reproducible

Splitting customers into ten equal groups without a tie-break assigns tied charge values arbitrarily,
so two runs could produce different deciles. Five charge values were found spanning a decile boundary,
so this was not a theoretical concern.

**Correction:** decile assignment now breaks ties on customer ID, making the result reproducible.

### An early assumption about the source structure did not hold

An initial assessment of how the five normalised tables relate to the flat extract proved incorrect on
verification. It was corrected through an explicit correction entry with the original assessment
retained, so the record shows an assumption tested, found wrong and fixed rather than a clean account
that was never in doubt.

### A procedural issue: silent failures

A failing SQL script wrote its error to the console while its output file quietly captured whatever
had succeeded, so a failure looked like a partial success. Every script invocation now stops at the
first error. Documented rather than silently patched.

A related issue: console section headers do not reach output files, so population labels were missing
from the committed evidence. The fix adds explicit scope columns to the result sets themselves, so
scope travels inside the data. **No filter, population, calculation, measure, ranking, segmentation,
threshold, ordering or validation expectation was changed in that repair**, and the analytical values
were confirmed identical afterwards.

---

## 5. Known characteristics of the data

| Characteristic | Detail |
|---|---|
| **Customer Status is derived** | It reproduces exactly from tenure and churn flag on all 5,174 non-churned records. It carries no independent information |
| **Two null conventions** | The services file uses a literal `'None'` token; the status file uses genuine nulls. Both are structural, never missing. Values are never imputed |
| **Monthly Charge excludes long-distance** | Long-distance revenue is a separate field, roughly 31% of the recurring figure again |
| **Currency unspecified** | No symbol, code or number format appears in any source file |
| **Single quarter** | The quarter field is present but constant. No trend exists |

---

## 6. Reproducibility of the checks

Every check is a SQL script in [`../../sql/03_validation/`](../../sql/03_validation/) and
[`../../sql/04_analysis/08_analysis_validation.sql`](../../sql/04_analysis/08_analysis_validation.sql), and
every result is a committed text file in [`../../analysis/query_results/`](../../analysis/query_results/).
The checks can be re-run against a rebuilt database and compared line for line against the committed
outputs.
