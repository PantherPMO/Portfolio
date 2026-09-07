# Methodology

How the analysis was scoped, defined and executed. This document consolidates the project scope, the
analytical definitions, the segmentation framework and the decisions that determine whether the
results can be trusted.

**Related:** [Findings](findings.md) · [Recommendations](recommendations.md) · [Case Study](case-study.md) ·
[Data Quality](technical/data-quality.md) · [Findings and Evidence](technical/findings-and-evidence.md) ·
[Technical Notes](technical/technical-notes.md)

---

## 1. Scope

### The question

Retention effort costs money. Spreading it evenly across every leaving customer wastes most of it.
The analysis therefore measures churn in **annual recurring revenue at risk** rather than customer
counts, and asks where that exposure is concentrated.

### Deliberately out of scope

| Excluded | Reason |
|---|---|
| **Churn prediction** | Answers "who will leave next", a different question from "where is the exposure now" |
| **Customer lifetime value** | The dataset supplies a `CLTV` field, but it is a vendor-derived score of unknown construction. Using it would import an unexamined model into the analysis |
| **Recommendations on retention activity** | The dataset contains no campaign, contact, offer-made or save records, so what any business did about retention is unobservable |
| **Retention spend break-even** | Requires a profit margin the dataset does not contain and no external source was obtained. Left open |

---

## 2. Definitions

### Revenue at risk

**Annualised recurring revenue attributable to all churned customers.**

Long-distance revenue is measured separately and held outside the headline figure, because a
retention offer secures a subscription rather than a usage volume. It amounts to **519,603.72
currency units** across all churned customers, roughly 31% of the recurring figure again. It is
stated wherever it is excluded, so that the exclusion reads as a scoping choice and not an oversight.

Annualisation multiplies the monthly charge by twelve. A profiling check confirmed a median ratio of
1.0000 between total charges and the tenure-weighted monthly charge, which supports the convention,
but it remains a forward-looking assumption and is described as one.

### The churn rate denominator

Two populations exist in this data and they behave very differently:

| Population | Definition | Size | Churn rate |
|---|---|---|---|
| **Established base** | Customers present at the start of the quarter, tenure of four months or more | 5,992 | **21.23%** (primary measure) |
| **New customers** | Joined during the observation quarter, tenure of three months or less | 1,051 | **56.80%** |
| Combined | All customers at period end | 7,043 | 26.54% (reconciliation only) |

**The primary churn rate uses the established base**, so numerator and denominator describe the same
population. New customers are analysed separately throughout and are never added to the primary
numerator. The combined 26.54% is retained only for reconciliation and is never substituted for the
primary figure.

This split is not an arbitrary analyst choice. Validation confirmed that the source `Customer Status`
field is fully derived from tenure and churn flag, matching exactly on all 5,174 non-churned records,
so the cohort structure is already present in the data.

An asymmetric alternative was considered during design and discarded as incoherent: excluding only
the newly joined survivors would have removed 454 customers who stayed while keeping 597 who left,
inflating the rate by construction.

### Value tiers

Customers are ranked by monthly charge and split into ten equal-frequency groups, then banded:

| Tier | Deciles | Customers | Share of recurring revenue |
|---|---|---|---|
| **High** | 8 to 10 | 2,004 | 45.71% |
| **Mid** | 4 to 7 | 2,316 | 42.40% |
| **Low** | 1 to 3 | 1,672 | 11.89% |

Decile 1 is the **lowest** monthly charge and decile 10 the highest. Both conventions exist in
practice, so the convention is stated on every output that uses it. Decile assignment breaks ties on
customer ID so that the same customer lands in the same decile on every run.

### Reporting thresholds

| Group size | Treatment |
|---|---|
| 100 or more | Reported normally |
| 30 to 99 | Reported with the group size stated alongside the rate |
| Below 30 | Not reported as a rate. Collapsed or omitted |

---

## 3. Segmentation

Two segmentation schemes were defined before any result was produced.

**Value tier by contract type**, giving nine groups. This is the primary framework for locating
revenue exposure.

**Value decile**, giving ten groups. Used to examine how churn varies across the value range.

Within the highest-value tier, seven dimensions are examined against the tier's own churn rate:

| Dimension | Groups |
|---|---|
| Contract type | Month-to-Month, One Year, Two Year |
| Customer tenure band | First year, second year, established, long tenure |
| Payment method | Bank withdrawal, credit card, mailed check |
| Internet type | Fibre optic, cable, DSL |
| Number of add-on services | Light, moderate, deep |
| Promotional offer held | Six categories including no offer |
| Referral behaviour | Has referred, has not referred |

All seven are reported, including those that turn out to differentiate weakly.

---

## 4. Why the definitions were fixed in advance

**Analysis definitions, segment thresholds, group-size rules and validation criteria were all fixed in
writing before any result was reviewed.** The purpose is to prevent the analysis being reshaped around
whatever the data happened to show.

This has a visible consequence. Two of the tests returned weak results, and the obvious response would
have been to re-cut the data at a finer granularity until something appeared. That was not done,
because it would mean choosing a specification after seeing the answer. A finer-grained test may well
be worth running, and it is listed as further work, but it would need its own definitions written
before the data is re-cut.

The same principle applies to the comparison population used for the ranking test. Whether the primary
result would use the established base or the full customer base was decided **before that result
existed.** The full-base version is retained as a sensitivity check, is labelled as such on every row
of its output, and is never promoted to the primary result even though it differs at the top rank.

---

## 5. Data model

Three layers in PostgreSQL, 42 SQL files.

| Layer | Contents | Purpose |
|---|---|---|
| `raw` | Every source column as text | Loaded without coercion, cleaning or loss. Preserves the source exactly as supplied |
| `core` | Typed, constrained, deduplicated tables | The clean model. Excluded fields never reach this layer |
| `analytics` | One analytical base view, ten reporting views | Everything the analysis queries |

Three design choices are worth naming:

**Excluded fields are blocked at the database level, not by convention.** Fields that record
information only known after a customer left are loaded to `raw` for fidelity, then never promoted to
`core`. A field that does not exist in `core` cannot be used by accident in `analytics`. Two
validation checks scan the view definitions directly and fail the build if any prohibited field
appears.

**Customers cannot be counted twice.** The customer-to-service relationship is one row per customer
per service. It is aggregated back to one row per customer inside the analytical base view, so no
downstream aggregate can multiply a customer by their service count. A validation check confirms each
of the seven dimensions splits the high-value tier into exactly 2,004 customers.

**Type conversion fails loudly.** The yes/no conversion function raises an error on any value it does
not recognise rather than defaulting to false, so an unexpected category stops the build instead of
silently becoming a negative.

**Protected characteristics** are held in a separate table that no analytical view joins. They are
available for descriptive and fairness checks only and are never used to target retention effort.

---

## 6. Key decisions

Twenty-two decisions are recorded during the project. These are the ones that determine the results.

| Decision | Choice | Why |
|---|---|---|
| **Source files** | Five normalised tables over the single merged file | Validation showed the merged file disagreed with its own components. Convenience is not grounds to trust a file inconsistent with its sources |
| **Revenue basis** | Recurring revenue only, long-distance measured separately | A retention offer secures a subscription, not a usage volume |
| **Churn denominator** | Established base for the primary rate | Numerator and denominator describe the same population |
| **Value bands** | Deciles 8-10 / 4-7 / 1-3 | Fixed before results, equal-frequency, deterministic tie-break |
| **Ranking comparison population** | Established base primary, full base as a sensitivity check | Fixed before the result existed, and carried as a column on every output row |
| **Field exclusions** | Five fields excluded structurally | See [Data Quality](technical/data-quality.md) |
| **Population labels** | Carried as explicit columns in the result sets | Console section headers do not reach output files, so scope travels inside the data instead |

---

## 7. What the analysis cannot support

These constrain every finding in the project.

- **A single observation window.** No trend can be established. It cannot be said whether 21.23% is
  rising, falling or stable, and customer tenure must not be read as a time axis.
- **Fictional data.** No statement in this project is evidence about a real operator or market.
- **Unspecified currency.** Every monetary figure is unitless.
- **Association only.** Every relationship reported is a single-dimension comparison within one
  quarter with no multivariate control. No causal claim is made anywhere.
- **No retention activity data.** No campaign, contact, offer-made or save records exist, so nothing
  observes what a business did or should do.
- **No profit margin**, so no retention spend or break-even figure is produced.
- **No external churn benchmark.** The UK regulator's telecommunications market data release was
  checked and does not publish churn or switching rates. The 21.23% figure is never described as high
  or low against an unsourced comparison.

---

*Findings: [`findings.md`](findings.md). Actions: [`recommendations.md`](recommendations.md). The full analysis: [`case-study.md`](case-study.md). Supporting technical documentation: [`technical/`](technical/).*
