# Project Charter — 02: Warehouse Inventory & Supply Chain Performance

> **This dataset is synthetic.** Calderfield Trade Supplies Ltd is a fictional company.
> Every pattern in the data was placed there by a documented generator
> (`scripts/calderfield_dataset_generator.py`, seed 20240101). The deliverable is the
> analytical method, not a claim about any real business, supplier or market.

**Status:** For approval. Analysis has not begun.
**Prepared:** 23 August 2026
**Tool:** PostgreSQL 16. Python used only to generate the dataset, not to analyse it.

---

## 1. Business problem

Calderfield Trade Supplies holds around **£1.7m of stock at cost** across four warehouses
against annual revenue of roughly **£12.3m**. Network inventory turns **4.67 times a year**
(78 days of cover), but that average conceals a four-way split: Livingston turns 2.84 times
and Bristol 7.13.

At the same time the business is not supplying its customers. In 2025 it failed to supply
**7.7% of order lines in full**, and the demand it could not meet was worth **£1.03m** at the
prices those customers had already been quoted.

Cash is tied up and service is being missed — at the same time, and in some cases at the
same sites. The board has asked why, and what to do about it.

## 2. Business context

Calderfield is a UK wholesale distributor of plumbing, heating, ventilation and electrical
products, selling to trade accounts rather than the public. It operates a national
distribution centre at Daventry and three regional sites at Warrington, Bristol and
Livingston. Bristol opened on 1 July 2024 and is still ramping.

The company buys from 30 suppliers across four types — UK manufacturers, UK and European
distributors, Far East importers and small specialists — whose lead times run from 7 to 55
quoted days and whose prices vary by around 21% for equivalent goods. 88 of 250 SKUs have
more than one approved source, so for a third of the range there is a real buying choice
being made every time stock is replenished.

Replenishment runs on reorder points and reorder quantities held per SKU per site, set by
five buyers and reviewed on a nominal cycle.

## 3. Primary stakeholder

**Operations Director.** Owns the warehouse network, the replenishment policy and the
supplier relationships, and is accountable for both the working capital tied up in stock
and the service level the sales team can promise. Has authority to change reorder points,
reassign sourcing between approved suppliers, and change goods-inwards process at a site.

**Secondary:** Finance Director (working capital release), Head of Purchasing (supplier
performance and price).

## 4. Central business question

> **Where is working capital tied up, and which inventory and supply chain decisions are
> costing the business money?**

## 5. Business questions

| ID | Question |
|---|---|
| BQ-01 | Where is our working capital sitting — by site, by category, by product? |
| BQ-02 | How much of our stock is not earning its keep, and what is it costing us to hold? |
| BQ-03 | Are we holding stock where demand is going, or where demand has been? |
| BQ-04 | What is poor availability costing us, and where is it worst? |
| BQ-05 | Which warehouses are genuinely performing well once we compare like with like? |
| BQ-06 | Which suppliers can we rely on, and is anyone getting worse? |
| BQ-07 | Are we paying more than we need to for the goods we buy? |
| BQ-08 | Are our buying rules creating stock we do not need, or shortages we could avoid? |

## 6. Analytical questions

| ID | Maps to | Question |
|---|---|---|
| AQ-01 | BQ-01 | How is average 2025 inventory value distributed across site, category and SKU, and how concentrated is it? |
| AQ-02 | BQ-01 | Does the ranking of SKUs by stock value match the ranking by cost of sales, or do they diverge? |
| AQ-03 | BQ-02 | What value of stock has not moved in 26, 52 and 104 weeks, and what value sits above the business's own reorder point plus reorder quantity? |
| AQ-04 | BQ-02 | What is the annual holding cost of that stock at a documented rate? |
| AQ-05 | BQ-03 | For each SKU and site, what is the direction of demand across eight quarters against current weeks of cover? |
| AQ-06 | BQ-04 | How do three availability measures — weeks closing at zero, weeks containing a zero day, and unmet order lines — differ, and why? |
| AQ-07 | BQ-04 | Does cover flex with seasonal demand, and where does the shortfall land relative to the demand peak? |
| AQ-08 | BQ-03 | Is the fastest-growing category being starved by reorder points set when it was small? |
| AQ-09 | BQ-05 | What are turnover, days of cover and fill rate by site for 2025? |
| AQ-10 | BQ-05 | How does that comparison change when restricted to the range all sites carry? |
| AQ-11 | BQ-05 | How has Bristol performed across its 78 weeks since opening? |
| AQ-12 | BQ-06 | What is on-time delivery by supplier and supplier type, by half-year, on both the first-delivery and all-delivery measures? |
| AQ-13 | BQ-06 | How variable is each supplier's lead time, and how much of that variability is attributable to the receiving site rather than the supplier? |
| AQ-14 | BQ-07 | For SKUs bought from more than one source, what is the like-for-like price difference, and what has been foregone by not using the cheaper approved source? |
| AQ-15 | BQ-07 | Did any supplier price change materially during the period, and what did the response to it cost or save? |
| AQ-16 | BQ-08 | Do policies not reviewed for over 15 months produce different cover and availability outcomes than current policies on comparable SKUs? |
| AQ-17 | BQ-08 | How much stock is created by minimum order quantities and by sourcing choices rather than by demand? |

## 7. Project objectives

1. Quantify where working capital sits and how much of it is not working.
2. Separate genuine site performance differences from differences in what each site stocks.
3. Separate supplier performance problems from internal process problems.
4. Establish the cost of the availability the business is currently failing to provide.
5. Produce recommendations with an owner, a quantified effect and a stated service consequence.
6. Demonstrate PostgreSQL analytical capability to a standard a hiring manager will recognise.

## 8. Scope and exclusions

**In scope**

- 1 January 2024 – 31 December 2025; 250 SKUs; 4 warehouses; 30 suppliers; 500 trade accounts.
- Inventory value, cover, ageing and excess against policy.
- Demand, fulfilment and unmet demand at order-line level.
- Supplier delivery reliability, lead-time variability and purchase price.
- Replenishment policy currency, minimum order quantities and sourcing behaviour.

**Out of scope, and why**

| Excluded | Reason |
|---|---|
| Demand forecasting | Two years gives one year-on-year comparison. A slope is directional evidence, not a forecast. |
| Price elasticity and pricing strategy | Selling prices do not respond to demand in this dataset and demand does not respond to price. Any conclusion would be circular. |
| Warehouse space and labour productivity | 4% of products carry no weight or volume, and the dataset holds no labour or cost data. |
| Product substitution when out of stock | Not modelled. Unmet demand is therefore an upper bound on lost sales. |
| Customer profitability | Cost to serve is not in the dataset. |
| Supplier capacity constraints | Lead times do not respond to order size in this dataset. |

## 9. KPIs

Defined once in `_portfolio/KPI_LIBRARY.md` and referenced here, not redefined.

| KPI | Definition | Grain | Note for this project |
|---|---|---|---|
| Inventory Turnover | Cost of sales ÷ average inventory value | Site, category, SKU | Average of 52 weekly snapshots, never closing stock — the import sawtooth distorts closing (D-10) |
| Days Inventory Outstanding | 365 ÷ turnover | Site, category | Preferred in stakeholder output |
| Stock Holding Cost | Average inventory × annual holding rate | Site, category | **22% per annum**, derived and sourced in `docs/technical/analytical-decisions.md` D-11, with 20% and 25% sensitivity |
| Stockout Rate | Periods with zero stock ÷ total periods | SKU/site/week | Reported three ways — see AQ-06 |
| On-Time Delivery / OTIF | Deliveries on time ÷ total deliveries | Supplier, half-year | Reported on both first-delivery and all-delivery bases (D-07) |
| Order Cycle Time | Mean and median (receipt date − order date) | Supplier, site | Median reported alongside mean; the importer distribution has a long right tail |

Two project-specific measures not in the library, defined here:

- **Line fill rate** — order lines supplied in full ÷ order lines, excluding cancelled lines.
- **Unmet demand value** — (quantity ordered − quantity despatched) × unit price, at the price
  already quoted to that customer. An upper bound: substitution is not modelled.

## 10. Methodology

1. **Load** the frozen dataset into PostgreSQL with foreign keys and check constraints
   enforced throughout, so a bad load fails rather than passes quietly.
2. **Validate** against the source: row counts, referential integrity, and a rebuild of
   every weekly stock position from the movement ledger alone.
3. **Profile coverage** before analysing — establish which breakdowns the data can carry
   and which cells are too thin to conclude from.
4. **Prepare** four base views: resolved customers, demand and fulfilment, delivery
   performance, and a weekly inventory base carrying trailing demand and policy.
5. **Analyse** one business question per SQL file, each writing a committed result CSV.
6. **Report** every material finding through Finding → Insight → Implication →
   Recommendation, with a complete evidence chain.

Anchor dates are fixed at 2025-12-31 (2025-12-28 for snapshot logic). `CURRENT_DATE` is
never used, so a committed result stays reproducible (D-05).

## 11. Data sources

| Source | Type | Detail |
|---|---|---|
| `data/synthetic/` — 15 CSV files | **Synthetic** | 147,589 rows. Generated by `scripts/calderfield_dataset_generator.py`, seed 20240101, fully reproducible. Validated by `scripts/calderfield_dataset_validation.py` — 56 checks, 0 failures. |
| Bank of England Bank Rate | Real, external | 3.75% from 18 December 2025. Capital cost component of the holding cost rate. |
| Published carrying cost range | Real, external | 20–30% industry convention. See D-11 for sources and limitations. |

To be recorded before shipping: SD-01 in `_portfolio/SYNTHETIC_DATA_LOG.md`, and a
`DATASET_REGISTRY.md` entry of type Synthetic.

## 12. Known data quality issues

All confirmed against the loaded database, and all preserved in the source tables.

| Issue | Measured | Handling |
|---|---|---|
| Duplicate customer accounts | 31 accounts, 31 groups; 500 accounts resolve to 469 customers | `vw_customer_resolved`. Effect on top-10 revenue share is small (17.2% → 17.7%) but must be applied before any concentration claim. |
| Missing promised delivery dates | 22 purchase orders, 51 receipts (1.1%) | Excluded from lateness measurement; denominator stated. |
| Promised date before order date | 24 purchase orders, 61 receipts (1.3%) | Excluded from lateness measurement; reported as a buyer keying issue. |
| Livingston Monday booking | 39.8% of Livingston receipts on a Monday vs 14–21% elsewhere; mean overrun 14.8 days vs 7.1–7.9 | Supplier analysis controls for receiving site (D-08). |
| Stock count adjustments and write-offs | Net 7.9% of average stock value a year, concentrated at Bristol | **Above real-world norms.** Reported relatively, never as an absolute realistic loss (D-12). |
| Missing product dimensions | 10 of 250 products (4.0%) | Space analysis out of scope; gap stated rather than dropped. |
| Split deliveries | 537 of 4,853 receipts (11.1%) are second or later against a line | Both on-time measures reported (D-07). |
| End-of-period truncation | 77.1% of Q4 2025 importer orders never received | Delivery window closes 2025-09-30; excluded quarter reported separately (D-14). |

## 13. Key analytical risks and traps

| # | Trap | Why it bites | Handling |
|---|---|---|---|
| 1 | Filtering demand on `line_status = 'Despatched in full'` | Returns overwrite fulfilment status. Loses 2,906 lines and £2.08m of unmet demand — the whole measurement | Fulfilment read from quantities only (D-03) |
| 2 | Dividing Bristol by 104 weeks | It has 78 | Site comparison on 2025 only |
| 3 | Reporting one stockout number | Weekly snapshots miss stockouts that clear before Sunday | Three measures reported together (AQ-06) |
| 4 | Blaming Meridian for Livingston's Monday batch | The two are correlated | Site held constant (D-08) |
| 5 | Comparing Arden's raw average price before and after March 2025 | SKU mix changed; returns roughly −86% | Like-for-like per SKU only |
| 6 | Turnover on closing stock | Import sawtooth distorts it | Average of weekly snapshots |
| 7 | Ranking sites on raw turnover | 145 of 250 SKUs are stocked only at Daventry | Range-mix adjusted comparison (AQ-10) |
| 8 | Assuming Warrington's Heating shortage is in December | Zero-stock days peak in **March**, after the winter demand peak | Monthly cover against monthly demand, lag examined |
| 9 | Cost of sales at standard cost | Erases the import price advantage | Ledger weighted average cost (D-10) |
| 10 | Counting transfers as demand | Overstates Daventry | `Sales issue` only (D-09) |
| 11 | Supplier trends by quarter | 33.2% of cells hold under 10 receipts | Half-year, with n printed (D-15) |
| 12 | Fanning out receipts against purchase order lines | A line can be received more than once | Receipts pre-aggregated before comparison |
| 13 | Treating unmet demand as lost sales | Substitution is not modelled | Reported as an upper bound |

## 14. Assumptions

1. The 22% holding cost rate applies uniformly across sites and categories. In reality
   Livingston's storage cost per pallet almost certainly differs from Daventry's; the
   dataset holds no site cost data to say so.
2. Unmet demand at quoted prices is an upper bound on lost revenue. Some customers would
   have bought a substitute; some would have waited.
3. `Sales issue` movements represent genuine customer demand and transfers do not.
4. The reorder points and reorder quantities on file were the rules actually in force
   throughout the period. The dataset carries only their current state and review date, not
   their history.
5. Weekly snapshots plus `days_at_zero_in_week` are together sufficient to measure
   availability. Sub-day stockouts are invisible either way.
6. Two years is enough to establish direction, not enough to establish trend.

## 15. Expected deliverables

| Deliverable | Location |
|---|---|
| Schema, load and index scripts | `sql/01_setup/` |
| Post-load validation | `sql/02_validation/` |
| Preparation views | `sql/03_preparation/` |
| Analysis — 17 files, one per analytical question | `sql/04_analysis/` |
| KPI and opportunity views | `sql/05_reporting_views/` |
| Committed query results | `analysis/query_results/` |
| Findings with full evidence chains | `analysis/FINDINGS.md` |
| Charts | `visuals/`, to `_portfolio/STYLE_GUIDE.md` |
| Stakeholder narrative including a written 5-minute presentation | `docs/STAKEHOLDER_STORY.md` |
| Decisions log | `docs/technical/analytical-decisions.md` |
| Recruiter-first README | `README.md` |

## 16. Decision criteria for recommendations

A recommendation ships only if all six hold:

1. **Evidenced.** Traceable to a numbered SQL file and its committed result CSV.
2. **Quantified in money.** Working capital released or holding cost saved, at 22% with a
   20–25% sensitivity band.
3. **Service consequence stated.** No working capital recommendation ships without saying
   what it does to availability. Releasing cash by cutting stock at a site that already
   misses 7.7% of lines is not an improvement.
4. **Owned.** A named role can act on it — reorder points, sourcing, or goods-inwards process.
5. **Mechanism explained.** Why the problem exists, not just that it does. A finding without
   a mechanism is a number.
6. **Honest about the synthetic basis.** Framed as demonstrating method, never as a claim
   about a real market.

Where two opportunities overlap — stock that is both slow-moving and above policy — they
are counted once under a stated hierarchy, so the total is defensible rather than the sum of
four overlapping numbers.

---

**Approval**

⬜ Approved  ⬜ Revise  ⬜ Rejected

Signed: ______________________  Date: ______________
