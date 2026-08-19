# Dataset Registry

Every dataset used anywhere in this portfolio is recorded here **before** it is used.

A dataset without a working source URL cannot be used. Unverifiable provenance destroys the credibility of the analysis built on it — and an interviewer asking *"where did this data come from?"* must get a precise answer.

---

## Registry

| ID | Project | Dataset | Publisher | Type | Licence | Rows × Cols | Accessed | Source |
|----|---------|---------|-----------|------|---------|-------------|----------|--------|
| — | — | *No datasets registered yet* | — | — | — | — | — | — |

*Type: `Real` or `Synthetic`. Synthetic entries must also appear in [`SYNTHETIC_DATA_LOG.md`](SYNTHETIC_DATA_LOG.md).*

---

## Entry Template

Copy this block for each new dataset.

```markdown
### DS-01 — <Dataset Name>

| Field | Value |
|-------|-------|
| **Dataset ID** | DS-01 |
| **Used in project** | 01 — Telecom Churn |
| **Publisher** | |
| **Source URL** | <direct, working link> |
| **Type** | Real / Synthetic |
| **Licence** | e.g. Open Government Licence v3.0, CC BY 4.0, CC0 |
| **Licence permits portfolio use** | Yes / No |
| **Licence permits redistribution** | Yes / No — determines whether the file can be committed |
| **Date accessed** | |
| **Format** | CSV / XLSX / API / JSON |
| **Size** | e.g. 7,043 rows × 21 columns, 1.2 MB |
| **Granularity** | One row = ? |
| **Time period covered** | |
| **Geography** | |

**Why this dataset fits the business case**
<Two or three sentences. What business question does it let us answer that alternatives could not?>

**Alternatives considered and rejected**
| Dataset | Why rejected |
|---------|--------------|
| | |

**Known quality issues**
- <e.g. TotalCharges stored as text, 11 blanks where tenure = 0>
- <e.g. no date dimension — limits time-series analysis>

**Limitations for this analysis**
- <e.g. single snapshot, no historical churn events, so survival analysis is not possible>

**Storage**
- Raw file: `data/raw/<filename>` — committed / not committed (reason)
- Retrieval: <download instructions or script path>
```

---

## Approved Source List

Priority order, per `CLAUDE.md` §4.1.

**Tier 1 — UK Government & official statistics**
- [data.gov.uk](https://www.data.gov.uk)
- [ONS](https://www.ons.gov.uk) — Office for National Statistics
- [NHS Digital](https://digital.nhs.uk/data-and-information)
- [Department for Transport statistics](https://www.gov.uk/government/organisations/department-for-transport/about/statistics)
- [DESNZ energy statistics](https://www.gov.uk/government/organisations/department-for-energy-security-and-net-zero)
- [UK Data Service](https://ukdataservice.ac.uk)

**Tier 2 — Curated open data platforms**
- [Kaggle Datasets](https://www.kaggle.com/datasets) — check provenance; many Kaggle sets are themselves synthetic or of unclear origin. Prefer those with a documented original source.
- [UCI Machine Learning Repository](https://archive.ics.uci.edu)
- [Google Dataset Search](https://datasetsearch.research.google.com)

**Tier 3 — International bodies**
- [World Bank Open Data](https://data.worldbank.org)
- [OECD Data](https://data.oecd.org)
- [Eurostat](https://ec.europa.eu/eurostat)
- [UN Data](https://data.un.org)

**Tier 4 — Company & market data**
- Published annual reports and filings
- [Companies House API](https://developer.company-information.service.gov.uk)
- [London Stock Exchange](https://www.londonstockexchange.com)

**Tier 5 — Public APIs**
- Document the endpoint, parameters, and extraction date. Save the raw pull — APIs change.

---

## Verification Checklist

Before a dataset is registered:

- [ ] Source URL opens and the file downloads
- [ ] Publisher is identifiable and reputable
- [ ] Licence located and read
- [ ] Licence permits portfolio use
- [ ] Redistribution position understood (determines commit decision)
- [ ] Row and column counts recorded
- [ ] Granularity understood — you can state what one row represents
- [ ] Time period and geography noted
- [ ] Quality issues profiled and written down
- [ ] The dataset can actually answer the business questions — verified, not assumed
- [ ] Rejected alternatives recorded

---

## Kaggle Provenance Warning

Many popular Kaggle datasets — including several widely-used churn and retail sets — are **synthetic or heavily anonymised**, and their Kaggle pages do not always say so.

Where a Kaggle dataset is used, trace it to its original source and record that. Where the true provenance cannot be established, say so in the project README:

> *"This dataset is widely used for churn analysis and is published on Kaggle. Its original provenance is not fully documented; results should be read as a demonstration of method rather than a statement about a real operator."*

Being the analyst who spotted that is a stronger signal than being the one who did not.
