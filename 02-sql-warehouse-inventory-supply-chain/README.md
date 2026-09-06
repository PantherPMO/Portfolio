# Warehouse Inventory & Supply Chain Performance

A PostgreSQL and Power BI analysis of a UK trade distributor holding £2.0m of stock while failing to supply 7.71% of its order lines. The work identifies where working capital is trapped, explains why the two problems occur together, and sets out what the business should do about it.

> Calderfield Trade Supplies Ltd is a fictional company and the dataset is synthetic, generated from a documented seed. The deliverable is the analytical method, not a claim about any real business.

---

## Business problem

Calderfield is a builders' merchant running four distribution centres, 250 stocked products and around 30 suppliers. Finance sees too much cash sitting in inventory. Operations sees customers going unserved. Both are right, which is why neither had been able to act.

The Operations Director asked one question:

**Where is working capital tied up, and which inventory and supply chain decisions are costing the business money?**

## Tools

PostgreSQL 16 | SQL | Power BI | DAX | Data modelling | Statistical analysis

## Key results

| | |
|---|---|
| **£2,043,979** | Average inventory, 2025 (mean of 52 weekly snapshots) |
| **7.71%** | Order lines not supplied in full |
| **£468,897** | Working capital opportunity identified, counted once |
| **£103,157** | Annual cost of holding it, at a 22% holding rate |
| **£995,659** | Stock bought in 2025 beyond what replenishment policy required |
| **£492,020** | Annual price saving currently earned through import sourcing |

## Key findings

**The business is overstocked and out of stock at the same time.** Calderfield holds roughly 78 days of cover and still missed 7.71% of order lines during 2025, on demand worth up to £1,027,629. The two conditions occur at the same sites and often on the same shelves. This is a problem of how inventory is allocated and how replenishment is designed, rather than a simple case of holding too much or too little.

**Supplier minimums, not buying decisions, are the largest structural driver.** On 98.3% of Far East importer purchase lines the supplier's minimum order quantity exceeded what the replenishment policy called for, and on 99.3% the buyer ordered exactly that minimum. During 2025 this brought in £995,659 of stock beyond policy requirement. On 91 positions the minimum is worth more than six months of demand.

**Replenishment settings track where demand has been, not where it is going.** Measured against a benchmark calibrated from the business's own flat-demand lines, rising lines sit at 0.68 of the implied level and falling lines at 1.33. The cost is heavily one-sided. Stock above the benchmark totals £115,916 and costs £25,502 a year to hold, while unmet demand on the thin-set lines runs to £505,019 over the same period.

**One supplier is deteriorating, not a category.** Meridian Pacific's on-time delivery fell from 95.0% to 45.5% across four half-years. Far East importers as a group appear to decline alongside it until Meridian is removed, at which point the remaining six run flat to slightly improving. Treating this as an importer problem would have directed the response at six suppliers who did not cause it.

**Cheaper import pricing is real, and it is bought with working capital.** Across 60 dual-sourced products the cheaper supplier is a Far East importer in every case, worth £492,020 a year against £604,231 of additional working capital. The net position is +£359,089 at a 22% holding rate, so cutting importer stock to release cash would forfeit more than it recovers.

**Just under half the estate has no case against it.** 209 of 515 stock positions, holding £835,219 or 48.8% of closing stock, show no identified release opportunity. That figure sets a ceiling on how large any inventory reduction programme can honestly be.

## Recommendations

**Act now.** Renegotiate minimum order quantities on the 91 positions where the minimum exceeds six months of demand, favouring network consolidation over re-sourcing so the import price advantage is not lost. Re-set reorder points against current demand in both directions, raising the 95 starved rising lines and lowering the 145 over-fed falling ones together, so the estate does not simply get deeper.

**Targeted actions.** Hold a supplier review with Meridian specifically. Clear the 25 discontinued positions holding £87,478, the most certain figure in the analysis. Re-size Renewables replenishment for a category whose demand grew 85.5% on settings built for a smaller business. Bring seasonal replenishment forward, since shortages currently arrive about two months after the demand peak.

**Investigate before acting.** Two service problems survived every test the data could apply. Daventry short-ships 2.60% of units in weeks when its cover was adequate, four to nine times the rate of the other sites. Bristol's shortfall peaks in March and April 2025 and fits neither the site's opening ramp nor the general seasonal pattern. These two sites hold £252,435 of the identified opportunity, so no broad inventory reduction should be taken at either until the service behaviour is understood.

Full detail, with the risk and dependencies attached to each action, is in [`docs/recommendations.md`](docs/recommendations.md).

---

## Power BI dashboard

Six pages built on seven PostgreSQL reporting views, imported into a star schema with 16 DAX measures. Each page answers one question.

📄 **[Full six-page PDF export](powerbi/calderfield_inventory_supply_chain.pdf)**

**1. Executive Overview**

![Executive Overview](powerbi/screenshots/01_executive_overview.png)

**2. Inventory & Working Capital**

![Inventory and Working Capital](powerbi/screenshots/02_inventory_working_capital.png)

**3. Availability & Replenishment**

![Availability and Replenishment](powerbi/screenshots/03_availability_replenishment.png)

**4. Supplier Reliability & Lead Time**

![Supplier Reliability and Lead Time](powerbi/screenshots/04_supplier_reliability_lead_time.png)

**5. Sourcing Economics**

![Sourcing Economics](powerbi/screenshots/05_sourcing_economics.png)

**6. Site Investigations & Decision Watchlist**

![Site Investigations and Decision Watchlist](powerbi/screenshots/06_site_investigations_watchlist.png)

The `.pbix` file is excluded from the repository because a binary cannot be reviewed or diffed. The screenshots, the PDF, the data model documentation and the SQL that produces every figure are all here instead.

---

## Analytical approach

**Data.** 147,589 rows across 15 tables covering two years of orders, receipts, stock movements and weekly inventory snapshots for four sites and 250 products.

**Preparation.** Four base views resolve duplicate customer accounts, derive fulfilment from despatched quantities rather than order status, retain every goods receipt including those that cannot be measured for lateness, and build a product by site by week inventory position from the movement ledger.

**Inventory and replenishment.** Turnover, cover and holding cost calculated on average inventory rather than closing stock. Availability measured three ways, since a weekly snapshot, a daily zero and a short-shipped order line are different quantities. Replenishment settings judged against a benchmark calibrated from the business's own flat-demand lines rather than an imported rule of thumb.

**Supplier performance.** On-time delivery measured on first receipt, all receipts and complete lines, with sample sizes printed beside every rate. Lead-time variance separated into supplier and receiving-site effects using an alternating two-way fit, because the design is unbalanced and the naive comparison overstates the site effect fivefold.

**Sourcing economics.** Minimum order quantities and lead times attributed to the source actually used on the most recent receipt rather than the nominated primary supplier, which reversed the headline conclusion. Price comparisons run like-for-like at product level to avoid a mix effect.

**Reporting.** Seven reporting views feed Power BI. The working-capital view assigns each of the 515 stock positions to exactly one of five mechanisms, so the total is defensible rather than a sum of overlapping exposures.

**Reproducibility.** 35 SQL files run in dependency order from an empty database and write 32 committed result files. All dates are fixed rather than relative, so a committed result still matches the file that produced it. Rebuilding and comparing checksums confirms the outputs are stable across runs.

---

## Technical evidence

| | |
|---|---|
| [`docs/case-study.md`](docs/case-study.md) | The full analysis, written for the business audience |
| [`docs/findings.md`](docs/findings.md) | Every finding, classified by the kind of claim it makes |
| [`docs/recommendations.md`](docs/recommendations.md) | Actions with evidence, risk and dependencies |
| [`docs/methodology.md`](docs/methodology.md) | How the numbers were built and what they exclude |
| [`sql/`](sql/) | 35 files: setup, validation, preparation, analysis, reporting views |
| [`analysis/query_results/`](analysis/query_results/) | 32 committed result files, one per SQL file |
| [`data/synthetic/`](data/synthetic/) | The frozen dataset, 15 CSV files |
| [`docs/technical/`](docs/technical/) | Data model and Power BI specification, validation log, decision record, database setup |

### SQL techniques used

Window functions for running stock positions and cumulative concentration. Chained CTEs for the iterative two-way lead-time fit. `GROUPING SETS` and `ROLLUP` for multi-grain reporting views. `DISTINCT ON` to resolve the most recent receipt per product without fan-out. `PERCENTILE_CONT` for cycle-time distributions, with `REGR_SLOPE` and `CORR` for demand trends. `FILTER` clauses for conditional aggregation. Materialised views with unique indexes where a base view is read by almost every downstream file.

### Skills demonstrated

Business problem framing | Data modelling | SQL analysis at scale | Statistical reasoning and confounding control | Inventory and replenishment analysis | Supplier performance measurement | Sourcing economics | Power BI and DAX | Reproducible pipelines | Communicating uncertainty to a non-technical audience

---

## Running it yourself

The database rebuilds from the committed CSV files in about five minutes. Full instructions are in [`docs/technical/database-setup.md`](docs/technical/database-setup.md).
