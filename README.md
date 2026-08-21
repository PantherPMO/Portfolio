# Data Analytics Portfolio

**Peters** — Data Analyst | SQL · Excel · Power BI · Tableau · Python

---

## About This Portfolio

Eight end-to-end analytics projects, each built around a real business decision rather than a dataset.

Every project starts from a defined business problem and uses a documented public dataset. Each one ends with what its evidence will actually support: sometimes recommendations a stakeholder could act on, sometimes a finding that is reported without one, including results that did not hold. Where the evidence does not support a recommendation, none is offered and the reason is stated.

Every analytical claim is traceable to the query, formula or model output that produced it. The evidence chain is documented in each project, in a findings or evidence register and, where the project warrants a longer walkthrough, a case study.

The tool used in each project was chosen because it fits the analytical problem, not to demonstrate breadth. Where a technology was deliberately *not* used, the reasoning is recorded.

---

## Projects

| # | Project | Domain | Core Tools | Business Question | Status |
|---|---------|--------|-----------|-------------------|--------|
| 01 | **[Telecommunications Revenue Retention](01-sql-telecom-churn-revenue/)** | Telecoms | SQL (PostgreSQL) | How much recurring revenue is at risk from churn, and where is that exposure concentrated? | 🟢 **Complete** |
| 02 | Warehouse Inventory & Supply Chain Performance | Logistics | SQL (PostgreSQL) | Where is working capital tied up, and which stock decisions are costing us? | ⬜ Not started |
| 03 | Retail Sales & Customer Behaviour Analysis | Retail | Excel | What drives basket value, and which customer behaviours are worth encouraging? | ⬜ Not started |
| 04 | Financial Performance & Budget Variance Analysis | Finance | Excel | Where are we off budget, is it price or volume, and is it recurring? | ⬜ Not started |
| 05 | Commercial Pricing & Predictive Cost Analysis | Construction / Commercial | Excel + Python | What should we price this work at, and how confident are we in the cost estimate? | ⬜ Not started |
| 06 | Sales Performance & Commercial Intelligence | Sales | Excel → Power BI | How is commercial performance tracking, and where should sales effort go next? | ⬜ Not started |
| 07 | Customer Intelligence & Lifetime Value | Customer Analytics | Excel → Power BI / Tableau + Python | Which customers are worth the most over their lifetime, and how should we treat them differently? | ⬜ Not started |
| 08 | Executive Operations Intelligence | Operations | Excel → Power BI | Is the operation performing, and what needs executive attention this month? | ⬜ Not started |

*Status legend: ⬜ Not started · 🟡 In progress · 🟢 Quality gate passed*

---

## Capabilities Demonstrated

| Capability | Where |
|------------|-------|
| Relational querying, CTEs, window functions | 01, 02 |
| Data modelling (star schema) | 06, 07, 08 |
| Financial modelling & variance analysis | 04, 05 |
| Scenario & sensitivity analysis | 04, 05 |
| Power Query / M transformations | 03–08 |
| DAX measures & time intelligence | 06, 07, 08 |
| Exploratory data analysis | All |
| Statistical analysis | 05, 07 |
| Predictive modelling | 05, 07 |
| KPI design & definition | All |
| Dashboard design for stakeholders | 06, 07, 08 |
| Data storytelling & stakeholder communication | All (project `README.md`, and a case study where the project warrants one) |
| Evidence-chained reporting | All (findings or evidence register per project) |
| Honest reporting of null and weak results | 01 |

---

## How This Portfolio Is Organised

```
Data Portfolio/
├── _portfolio/          Portfolio control centre — standards, registries, quality gates
├── _assets/             Shared visual assets and brand palette
└── NN-<tool>-<name>/    One folder per project
```

Every project follows the same seven-stage lifecycle and must pass a sixteen-point quality gate before it is considered complete. The standards are documented in [`_portfolio/`](_portfolio/).

**Start here:** [Portfolio Charter](_portfolio/PORTFOLIO_CHARTER.md) · [Project Tracker](_portfolio/PROJECT_TRACKER.md) · [Dataset Registry](_portfolio/DATASET_REGISTRY.md)

---

## Data & Reproducibility

All datasets are public and sourced from reputable providers (Kaggle, ONS, data.gov.uk, World Bank, public APIs, published company data). Every dataset is logged in the [Dataset Registry](_portfolio/DATASET_REGISTRY.md) with its source URL, date accessed, and licence status.

**Licence status is recorded as found, not assumed.** Where a licence could not be established, the registry records it as unresolved, no licensing claim is made, and the raw files are excluded from this repository. Project 01's dataset is one such case.

Where a real dataset could not support a required business case, synthetic data was used — clearly labelled as such, with the generation method and justification documented in the [Synthetic Data Log](_portfolio/SYNTHETIC_DATA_LOG.md). No synthetic dataset is presented as real.

Large raw datasets are not committed to this repository. Each project's `data/raw/README.md` documents the source and how to obtain the data.

---

## Contact

**Peters**
📧 olawalemobolajipeters@gmail.com
🔗 LinkedIn: *[to be added]*
💻 GitHub: *[to be added]*

---

*Licensed under the MIT Licence. Datasets remain subject to their original licences.*
