# Telecommunications Revenue Retention

A PostgreSQL analysis of a telecommunications base losing 21.23% of its established customers in a quarter, carrying 1,232,425.80 of annual recurring revenue with them. The work establishes where the revenue exposure actually sits, tests whether a revenue-led prioritisation would differ from a churn-led one, and reports the two tests that returned weak results alongside the five that did not.

> The operator is fictional and the dataset is IBM's published sample telecommunications data, 7,043 customers in California over one quarter. What it demonstrates is the analytical method; nothing here is a claim about any real business. All monetary values are unitless.

---

## Business problem

Retention attention is finite and not all churn is worth the same. A base can lose a large number of low-value customers or a small number of high-value ones and report a similar churn rate either way, which makes the rate a poor guide to where attention should go.

The question the analysis answers:

**Where should retention investment be directed, measured in annual recurring revenue rather than customer counts?**

Three things were excluded at the outset and stayed excluded. Churn prediction, because "who will leave" is a different question from "where is the exposure". Customer lifetime value, because the supplied field is a vendor-derived score of unknown construction and using it would import an unexamined model. Any claim about what an operator actually did, because the dataset contains no campaign, offer, contact or save records, so retention activity is unobservable.

## Tools

PostgreSQL 18 | SQL | Python (matplotlib) | Data modelling | Cohort analysis | Statistical reasoning

## Key results

| | |
|---|---|
| **21.23%** | Churn rate, opening cohort (1,272 of 5,992 established customers) |
| **1,232,425.80** | Annual recurring revenue at risk, opening cohort |
| **74.32%** | Revenue retention, against 78.77% customer retention |
| **78.93%** | Share of revenue at risk held by two of nine segments |
| **45.71%** | Share of recurring revenue held by the top three value deciles |
| **56.80%** | Churn among customers acquired within the quarter, analysed separately |

## Key findings

**Revenue exposure is larger than customer exposure.** Revenue retention is 74.32% while customer retention is 78.77%. That gap is arithmetic rather than assumption: it can only occur if the customers who left carried higher average recurring revenue than those who stayed. A prioritisation built on counts and one built on revenue do not describe the same exposure.

**The business is not losing its most valuable customers.** Churn by value decile is not monotonic. It peaks at 38.96% in decile 9 and falls to 24.36% in decile 10, below deciles 6 through 9. Within the top value tier, leavers average 98.07 in monthly recurring revenue and stayers 99.48, near parity. The revenue-weighted effect in the headline arises in the middle and lower tiers, not at the top.

**Revenue is moderately concentrated, which bounds what targeting can achieve.** The top decile holds 16.71% of recurring revenue against 10.00% of customers, and the curve falls smoothly from 16.71% to 3.03% with no step change. This is well short of the pattern subscription businesses often assume, and it limits how much mechanical leverage a value-based strategy has here.

**A churn-led and a revenue-led prioritisation reach almost the same answer.** This was the question the work was built around, and the answer came back close to no. Ranking nine value-by-contract segments twice, once by churn rate and once by revenue at risk, the maximum difference is one rank position and five of nine segments do not move at all. The top two are identical under both: High and Mid value customers on Month-to-Month contracts, holding 78.93% of the opening cohort's revenue at risk between them.

**Contract type and tenure separate churn most widely, and they overlap.** Within the high-value tier, Month-to-Month customers show substantially higher churn in this dataset than Two Year customers, 54.59% against 5.26%, and churn declines monotonically across all four tenure bands from 71.57% in the first year to 15.52% at long tenure. The two dimensions are heavily interrelated and neither cut isolates an independent contribution.

**The offer dimension has the widest spread and is the least usable.** Offer held spans 12.11% to 71.88% within the high-value tier, wider than any other dimension. Direction and assignment mechanism are unresolved: the dataset records only which offer is held, with no date, reason or outcome, so an offer extended to customers already considered at risk would produce this pattern with the relationship running the other way.

**The high-value tier has no distinctive driver profile.** Comparing the same seven dimensions between the top tier and the base as a whole, contract type, service intensity and referral behaviour all differ by less than 0.16 on the churn index. A base-wide driver profile describes the top tier well enough on most dimensions, which undercuts one of the premises the work started from.

## Recommendations

**Act on the evidence as it stands.** Frame retention prioritisation in annual recurring revenue at risk rather than customer counts. Concentrate the prioritisation discussion on the two Month-to-Month segments holding 78.93% of the exposure across 2,076 customers, which both ranking logics select. Do not commission a separate high-value driver diagnostic, since the evidence says it would largely reproduce the general one. Treat the customers acquired within the quarter as a separate question with separate ownership, since they carry 31.94% of churn events and behave nothing like the established base.

**Establish before acting.** Resolve the direction of the offer relationship before that dimension is used at all. Investigate the decile 9 peak and the decile 10 dip before a prioritisation is settled. Test the divergence question at a finer segmentation, specified in advance, before concluding the two prioritisations agree in general.

**Stop.** Retire the assumption that the business is losing its most valuable customers. A programme designed on that premise would be aimed at the part of the value distribution where the evidence is weakest.

Full detail, with the evidence and the caution attached to each action, is in [`docs/recommendations.md`](docs/recommendations.md).

---

## Selected charts

**The base position**

![Annual recurring revenue at risk, opening cohort](visuals/CH01_revenue_at_risk_opening_cohort.png)

**Churn by value decile, showing the decile 9 peak and the decile 10 dip**

![Churn rate by monthly-charge decile](visuals/CH04_churn_by_revenue_decile.png)

**Seven driver dimensions within the high-value tier, all reported including the weak ones**

![Churn index by segment, all seven lenses, high value tier](visuals/CH08_driver_lenses_high_tier.png)

All eleven charts are in [`visuals/`](visuals/), each built from a committed query output with no analytical value hard-coded, and each verified against its source data by an automated gate.

---

## Analytical approach

**Data.** Five normalised source workbooks covering demographics, location, population, services and status, 7,043 customers over one quarter. A sixth merged workbook was supplied and rejected on evidence: a cross-check against the five-table source found it internally inconsistent.

**Cohort design.** The primary churn KPI uses the opening cohort of customers present at the start of the period, so numerator and denominator describe the same population. Customers acquired within the quarter are analysed separately throughout and never added to the primary numerator. The all-customer rate of 26.54% is retained as a reconciliation measure and never substituted for the primary 21.23%.

**Exclusions enforced structurally.** Five fields are loaded to the raw layer for fidelity and never promoted, so no downstream query can reach them. Satisfaction score is the one that matters: it correlates at -0.75 with the outcome and shows 100% churn at the lowest scores, because it was recorded with knowledge of the outcome. A model built on it would have looked outstanding and been worthless. Protected characteristics are quarantined in a table no analytical view joins, and a validation check scans view definitions directly to enforce it.

**Definitions fixed in advance.** Revenue at risk, the churn denominator, the value tier cut points, the minimum reportable cell size and the choice of primary versus sensitivity population were all settled in writing before the relevant results were seen. That has a visible cost: when the ranking test came back weak, re-cutting at a finer granularity until something appeared would have meant choosing a specification after seeing the answer, so the finer test is listed as further work with its own definitions still to be written.

**Segmentation.** Nine value-by-contract segments, ten monthly-charge deciles assigned with a deterministic tie-break, and seven driver dimensions named in advance and unpivoted into a single relation so that every dimension covers the same population by construction.

**Validation.** Nineteen analysis checks, all passing, including one confirming each driver dimension partitions its scope exactly and one confirming no prohibited field has reached the analytics layer. Eleven charts with eight checks each, 88 of 88 passing, comparing values as strings rather than floats so a re-rounded figure fails rather than passing on tolerance. Seventeen cross-finding arithmetic reconciliations hold exactly.

---

## Technical evidence

| | |
|---|---|
| [`docs/case-study.md`](docs/case-study.md) | The full analysis, including the dataset rejection argument and the four issues found and corrected |
| [`docs/findings.md`](docs/findings.md) | Every finding, with observation, interpretation, implication and limitation separated |
| [`docs/recommendations.md`](docs/recommendations.md) | Actions with evidence, decision value and dependencies |
| [`docs/methodology.md`](docs/methodology.md) | Definitions, cohort design, and what the analysis cannot support |
| [`docs/technical/`](docs/technical/) | Evidence register, data quality record, data dictionary, reproducibility notes |
| [`sql/`](sql/) | 42 files across setup, preparation, validation, analysis and reporting views |
| [`analysis/query_results/`](analysis/query_results/) | 42 committed query outputs, one per script |

### SQL techniques demonstrated

Window functions for decile assignment with a deterministic tie-break, since `NTILE` without one assigns tied values arbitrarily and two runs can disagree. `CROSS JOIN LATERAL (VALUES ...)` to unpivot seven driver dimensions into one uniform relation, so adding a dimension means adding a row rather than writing another query. Paired `RANK()` window functions over the same partition to build the divergence index, whose sum within a scope must be zero and is asserted as a validation check. `FILTER` clauses for conditional aggregation. A layered view architecture where fan-out from the customer-to-service bridge is collapsed to customer grain at the boundary, so no downstream aggregate can double-count. A boolean conversion function that raises on any unrecognised value rather than defaulting to false, so an unexpected category stops the build instead of silently becoming a negative.

---

## Limitations

**One quarter.** No trend is available. It cannot be established whether 21.23% is rising, falling or stable, and tenure is not a substitute for a time axis.

**Association only, throughout.** No causal claim is made anywhere in this project. Every cut is single-dimension with no multivariate control, and the dimensions are known to be interrelated.

**No retention activity data.** No campaign, offer-made, contact or save records exist, so what any operator did is unobservable. The divergence test compares two hypothetical prioritisation logics, not any actual allocation.

**No margin and no benchmark.** No margin range was sourced, so no break-even point or spend ceiling is estimated anywhere. Ofcom's telecommunications market data release was checked and confirmed not to publish churn or switching rates, so 21.23% is never described as high or low against an industry figure.

**Fictional data.** Every pattern here is a property of IBM's data-generation logic. The project demonstrates that the method works and what it returns; it does not establish anything about a real operator.

---

## Running it yourself

The database builds from the source workbooks in the documented run order, and the charts rebuild from the committed query outputs with no database connection required. Requirements are PostgreSQL 18 or later and Python 3.11 with `matplotlib` and `openpyxl`. Run order and the exact `psql` invocations are in [`sql/README.md`](sql/README.md); the chart pipeline and its validation gate are in [`docs/technical/technical-notes.md`](docs/technical/technical-notes.md).

The source workbooks are not committed, because their licensing is unresolved and no licensing claim is made. Every query output they produce is committed, so every figure quoted anywhere in this repository can be checked against the file that produced it.
