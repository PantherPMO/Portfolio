# Data Dictionary

Field-level reference for the five source tables, the revenue fields and their interpretation, the fields derived during preparation, and the fields withheld from analytical use.

**Dataset:** IBM Cognos Analytics telecommunications sample data, [publisher's community post](https://community.ibm.com/community/user/businessanalytics/blogs/steven-macko/2019/07/11/telco-customer-churn-1113). Source files dated 8 November 2019. Every value recorded below was observed directly in the files rather than taken from the publisher's description.

> This is fictional sample data. The publisher describes it as "a fictional telco company that provided home phone and Internet services to 7043 customers in California in Q3." It is not real subscriber data and is never presented as such in this project.

> Currency is unknown. No currency symbol, code or number format appears anywhere in the source files, so all monetary values are unitless and are never shown with a currency sign.

Source assessment, exclusion reasoning and data quality issues are in [Data Quality](data-quality.md). Analytical definitions are in the [Methodology](../methodology.md).

---

## Source precedence

| Source | Role |
|---|---|
| Five tables: `demographics`, `location`, `population`, `services`, `status` | Authoritative. Loaded into the database |
| `Telco_customer_churn.xlsx`, merged, 33 columns | Reconciliation only. Internally inconsistent with the normalised tables and not loaded into the schema |

---

## Table: `demographics`, 7,043 rows by 9 columns

Primary key `Customer ID`. One row per customer. No duplicates and no null keys.

| # | Field | Type | Nulls | Description | Observed values |
|---|-------|------|-------|-------------|-----------------|
| 1 | `Customer ID` | str | 0 | Unique customer identifier | 7,043 distinct |
| 2 | `Count` | int | 0 | Reporting artefact from the source BI tool | Constant `1`. Dropped |
| 3 | `Gender` | str | 0 | Customer gender | Male / Female. Restricted |
| 4 | `Age` | int | 0 | Customer age in years | 19 to 80. Restricted |
| 5 | `Under 30` | str | 0 | Age band flag | Yes 1,401 / No. Restricted. Equivalent to `Age < 30` |
| 6 | `Senior Citizen` | str | 0 | Aged 65 or older | Yes 1,142 / No. Restricted. Equivalent to `Age >= 65` |
| 7 | `Married` | str | 0 | Marital status | Yes / No. Identical to `Partner` in the merged file |
| 8 | `Dependents` | str | 0 | Has dependents | Yes / No. Equivalent to `Number of Dependents > 0` |
| 9 | `Number of Dependents` | int | 0 | Count of dependents | 0 or greater |

The three derived flags (`Under 30`, `Senior Citizen`, `Dependents`) agree with their underlying continuous fields on every row, with no exceptions.

---

## Table: `location`, 7,043 rows by 9 columns

Primary key `Customer ID`. One row per customer. No duplicates.

| # | Field | Type | Nulls | Description | Observed values |
|---|-------|------|-------|-------------|-----------------|
| 1 | `Customer ID` | str | 0 | Foreign key to `demographics` | 7,043 distinct |
| 2 | `Count` | int | 0 | Reporting artefact | Constant `1`. Dropped |
| 3 | `Country` | str | 0 | Country | Constant `United States`. Dropped |
| 4 | `State` | str | 0 | State | Constant `California`. Dropped |
| 5 | `City` | str | 0 | City | Multiple values |
| 6 | `Zip Code` | int | 0 | Foreign key to `population` | 1,626 distinct, maximum 43 customers per zip code |
| 7 | `Lat Long` | str | 0 | Latitude and longitude combined into one string | Redundant with fields 8 and 9. Dropped |
| 8 | `Latitude` | float | 0 | Latitude | Out of scope |
| 9 | `Longitude` | float | 0 | Longitude | Out of scope |

---

## Table: `population`, 1,671 rows by 3 columns

Primary key `ID`, with `Zip Code` unique. One row per zip code area.

| # | Field | Type | Nulls | Description |
|---|-------|------|-------|-------------|
| 1 | `ID` | int | 0 | Surrogate key, unique |
| 2 | `Zip Code` | int | 0 | Join key from `location`, unique |
| 3 | `Population` | int | 0 | Population of the zip code area |

All 1,626 customer zip codes exist in this table, with no orphans. A further 45 zip codes have no customers, which makes this a lookup superset rather than an integrity problem.

---

## Table: `services`, 7,043 rows by 30 columns

Primary key `Customer ID`. One row per customer per quarter, with only Q3 present. No duplicates.

| # | Field | Type | Nulls | Description | Observed values |
|---|-------|------|-------|-------------|-----------------|
| 1 | `Customer ID` | str | 0 | Foreign key to `demographics` | 7,043 distinct |
| 2 | `Count` | int | 0 | Reporting artefact | Constant `1`. Dropped |
| 3 | `Quarter` | str | 0 | Reporting quarter | Constant `Q3`. The schema anticipates a time dimension that this extract does not contain |
| 4 | `Referred a Friend` | str | 0 | Referral flag | Yes 3,222 / No 3,821 |
| 5 | `Number of Referrals` | int | 0 | Referral count | 0 or greater |
| 6 | `Tenure in Months` | int | 0 | Months with the company | 1 to 72, with no zeros |
| 7 | `Offer` | str | 0 true nulls | Promotional offer held | A 520, B 824, C 415, D 602, E 805, plus 3,877 rows holding the literal text `'None'`, mapped to `'No offer'` |
| 8 | `Phone Service` | str | 0 | Home phone subscription | Yes 6,361 / No 682 |
| 9 | `Avg Monthly Long Distance Charges` | float | 0 | Average monthly long-distance charge | 0.00 to 49.99. Separate from `Monthly Charge` |
| 10 | `Multiple Lines` | str | 0 | Multiple telephone lines | Yes 2,971 / No 4,072 |
| 11 | `Internet Service` | str | 0 | Internet subscription | Yes 5,517 / No 1,526 |
| 12 | `Internet Type` | str | 0 true nulls | Access technology | Fiber Optic 3,035, DSL 1,652, Cable 830, plus 1,526 rows holding the literal text `'None'`, mapped to `'No internet'`. Those 1,526 rows are exactly the rows where `Internet Service = 'No'` |
| 13 | `Avg Monthly GB Download` | int | 0 | Average monthly data usage | 0 or greater |
| 14 | `Online Security` | str | 0 | Add-on service | Yes 2,019 / No 5,024 |
| 15 | `Online Backup` | str | 0 | Add-on service | Yes 2,429 / No 4,614 |
| 16 | `Device Protection Plan` | str | 0 | Add-on service | Yes 2,422 / No 4,621 |
| 17 | `Premium Tech Support` | str | 0 | Add-on service | Yes 2,044 / No 4,999 |
| 18 | `Streaming TV` | str | 0 | Add-on service | Yes 2,707 / No 4,336 |
| 19 | `Streaming Movies` | str | 0 | Add-on service | Yes 2,732 / No 4,311 |
| 20 | `Streaming Music` | str | 0 | Add-on service | Yes 2,488 / No 4,555 |
| 21 | `Unlimited Data` | str | 0 | Add-on service | Yes 4,745 / No 2,298 |
| 22 | `Contract` | str | 0 | Contract type | Month-to-Month 3,610, One Year 1,550, Two Year 1,883 |
| 23 | `Paperless Billing` | str | 0 | Billing preference | Yes 4,171 / No 2,872 |
| 24 | `Payment Method` | str | 0 | Payment method | Bank Withdrawal 3,909, Credit Card 2,749, Mailed Check 385 |
| 25 | `Monthly Charge` | float | 0 | Recurring monthly subscription charge | 18.25 to 118.75, median 70.35, mean 64.76. No zeros or negatives |
| 26 | `Total Charges` | float | 0 | Cumulative subscription charges to date | Sum 16,060,725.24 |
| 27 | `Total Refunds` | float | 0 | Cumulative refunds | 0 or greater |
| 28 | `Total Extra Data Charges` | int | 0 | Cumulative excess data charges | 0 or greater |
| 29 | `Total Long Distance Charges` | float | 0 | Cumulative long-distance charges | Approximately `Avg Monthly Long Distance Charges` times tenure, median ratio 1.0000 |
| 30 | `Total Revenue` | float | 0 | Total revenue to date | Sum 21,371,131.69 |

All eight add-on fields hold clean `Yes` and `No` values only. The `No internet service` and `No phone service` sentinel values exist only in the merged workbook, not here.

---

## Table: `status`, 7,043 rows by 11 columns

Primary key `Customer ID`. One row per customer per quarter, with only Q3 present. No duplicates.

| # | Field | Type | Nulls | Description | Observed values |
|---|-------|------|-------|-------------|-----------------|
| 1 | `Customer ID` | str | 0 | Foreign key to `demographics` | 7,043 distinct |
| 2 | `Count` | int | 0 | Reporting artefact | Constant `1`. Dropped |
| 3 | `Quarter` | str | 0 | Reporting quarter | Constant `Q3` |
| 4 | `Satisfaction Score` | int | 0 | Satisfaction rating | 1 to 5. Excluded from analytical use as outcome-contaminated |
| 5 | `Customer Status` | str | 0 | Status at period end | Stayed 4,720, Churned 1,869, Joined 454 |
| 6 | `Churn Label` | str | 0 | Churn indicator | Yes 1,869 / No 5,174 |
| 7 | `Churn Value` | int | 0 | Churn flag used throughout the analysis | 1 for 1,869 customers, 0 for 5,174. Agrees with `Churn Label` on every row |
| 8 | `Churn Score` | int | 0 | Vendor-supplied churn propensity | 0 to 100. Excluded as an undocumented model output |
| 9 | `CLTV` | int | 0 | Vendor-supplied lifetime value estimate | Excluded as an undocumented derived value |
| 10 | `Churn Category` | str | 5,174 (73.5%) | Category of stated churn reason | Competitor 841, Attitude 314, Dissatisfaction 303, Price 211, Other 200. Excluded as outcome-derived |
| 11 | `Churn Reason` | str | 5,174 (73.5%) | Specific stated churn reason | Excluded as outcome-derived |

`Customer Status` is available here but absent from the merged workbook, which is one reason the merged workbook is not authoritative. It separates the 454 customers who joined during the observation quarter (tenure of one to three months) from the established base, and that distinction determines which population a churn rate describes: 26.54% across all 7,043 rows, or 28.37% if the 454 joiners are removed from the denominator alone. The cohort definition adopted for this analysis, and the reasoning behind it, are set out in the [Methodology](../methodology.md).

---

## Revenue fields and their interpretation

### The revenue identity

```
Total Revenue = Total Charges - Total Refunds
              + Total Extra Data Charges + Total Long Distance Charges
```

This holds on all 7,043 rows, with a maximum absolute difference of 0.000000.

The identity is useful as a check on the source, but every revenue aggregate in this project is still recomputed from customer grain rather than read from a pre-aggregated field.

### `Monthly Charge` is a stable recurring rate

`Monthly Charge` behaves as a standing subscription rate rather than a single month's billed amount, which is what makes annualisation defensible.

| Test | Result |
|---|---|
| Median of `Total Charges` divided by (`Monthly Charge` times tenure) | 1.0000 |
| Rows within 5% of that ratio | 80.4% |
| Rows within 15% | 97.9% |

Multiplying by twelve to annualise is therefore supported by the data, though it remains a forward-looking assumption and is described as one wherever it is used.

### `Monthly Charge` excludes long-distance revenue

`Total Long Distance Charges` reconciles independently against `Avg Monthly Long Distance Charges` times tenure, with a median ratio of 1.0000 and 90.3% of rows within 1%. `Monthly Charge` is therefore the recurring subscription element only.

Revenue at risk is defined as `Monthly Charge` times twelve, the contractually recurring amount a retention offer protects. Long-distance revenue is measured separately and reported alongside rather than folded in. See the [Methodology](../methodology.md).

### `Total Charges` is lifetime to date

`Total Charges` is cumulative from the start of the customer relationship, not bounded to the reporting quarter. The publisher's description is loose on this point, and the field was tested rather than assumed. Being historical, it is a validation field and not the basis for any forward-looking revenue figure.

---

## Derived fields

| Field | Type | Calculation | Purpose |
|-------|------|-------------|---------|
| `is_churned` | boolean | `Churn Value = 1` | Outcome flag |
| `is_new_joiner` | boolean | `Customer Status = 'Joined'` | Separates customers acquired during the quarter from the established base |
| `tenure_band` | text | `CASE` expression over `Tenure in Months`, with cut points fixed before results were reviewed | Lifecycle segmentation |
| `annualised_revenue` | numeric | `Monthly Charge` times 12 | Basis for revenue at risk |
| `revenue_decile` | int | `NTILE(10) OVER (ORDER BY monthly_charge, customer_id)` | Value segmentation. Ordering by customer ID after monthly charge gives a deterministic tie-break, so decile membership does not shift between runs where customers share a charge |
| `service_count` | int | Count of `Yes` across the eight add-on fields | Service intensity. The clean binary values mean no sentinel handling is needed |

---

## Units and conventions

| Concept | Convention |
|---------|-----------|
| Currency | Unknown, with no evidence in the source. Values are unitless and are written as currency units where a label is needed. Never shown with a currency sign |
| Revenue basis | `Monthly Charge` times 12, covering recurring subscription revenue only |
| Tenure | Whole months, 1 to 72 |
| Churn | `Churn Value` is the field used. `Churn Label` agrees with it on every row |
| Churn denominator | Defined in the [Methodology](../methodology.md), which sets out the cohort used for the primary rate and the population used for reconciliation |
| Nulls | Two conventions in the source. `services` uses a literal `'None'` token and has no true nulls; `status` uses true nulls. Both are structural rather than missing, and no value is imputed. See [Data Quality](data-quality.md) |
| Decile assignment | `NTILE(10) OVER (ORDER BY monthly_charge, customer_id)`, deterministic on repeat runs |

---

## Completeness and integrity

| Measure | Result |
|---|---|
| Rows | 7,043 in each of the four customer tables, 1,671 in `population` |
| Duplicate customer IDs | 0 |
| Null keys | 0 |
| Orphan records | 0 in every relationship |
| Genuine missing values | 0. Every absent value is structural |
| True null cells in `services` | 0. The table uses a literal `'None'` token instead |
| True null cells in `status` | 10,348, genuinely empty cells |
| Invalid charges, zero or negative | 0 |
| Tenure zeros | 0 |
| Completeness across all non-structural fields | 100% |

### Relationships

| From | To | Key | Cardinality | Orphans |
|---|---|---|---|---|
| `demographics` | `location` | `Customer ID` | 1:1 | 0 |
| `demographics` | `services` | `Customer ID` | 1:1 | 0 |
| `demographics` | `status` | `Customer ID` | 1:1 | 0 |
| `location` | `population` | `Zip Code` | N:1 | 0 |

The analytical grain is one row per customer, 7,043 rows. All three customer joins are strictly one to one, so they introduce no fan-out. `location` to `population` is many to one and safe in that direction; joining the other way would multiply rows by up to 43.

---

## Excluded and restricted fields

| Field | Treatment | Reason |
|-------|-----------|--------|
| `Satisfaction Score` | Excluded | Outcome-contaminated. All customers scoring 1 or 2 churned and none scoring 4 or 5 did, so the score reflects knowledge of the outcome |
| `Churn Score` | Excluded | Vendor model output of undocumented construction, and a source of target leakage |
| `CLTV` | Excluded | Vendor-derived prediction of undocumented construction. Lifetime value is addressed as a separate piece of work |
| `Churn Reason` | Excluded from analysis | Recorded after the outcome. Retained only as a post-analysis sanity check on findings reached without it |
| `Churn Category` | Excluded from analysis | Recorded after the outcome, on the same basis |
| `Count`, `Country`, `State`, `Lat Long` | Dropped | Constant or redundant |
| `Latitude`, `Longitude` | Out of scope | No business question in this project requires geospatial analysis |
| `Gender`, `Age`, `Under 30`, `Senior Citizen` | Restricted | Protected characteristics. Available for descriptive profiling and confounding checks only, and never used as a prioritisation rule |
