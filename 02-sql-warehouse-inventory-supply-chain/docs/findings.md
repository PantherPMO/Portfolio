# Findings

> Calderfield Trade Supplies Ltd is fictional and the dataset is synthetic, generated from a documented seed. The deliverable is the analytical method rather than a claim about any real business, supplier or market.

**Period:** 1 January to 31 December 2025, anchored at 2025-12-31 (2025-12-28 for snapshot logic). All dates are fixed; `CURRENT_DATE` is never used.

---

## How this document is organised

Findings are separated by the kind of claim they make, because they do not carry equal weight and a single flat list would imply they do.

| Class | Meaning |
|---|---|
| Supported | Measured directly and survives the controls applied to it |
| Quantified opportunity | A supported finding with money attached, counted once under the hierarchy |
| Upper bound | A ceiling rather than an estimate: the true figure is at or below it |
| Assumption | Not measured, imported from outside the dataset and stated as such |
| Unresolved | Measured and real, but not explained by anything tested |
| Rejected | A hypothesis the analysis held and the evidence did not support |

Every finding cites the SQL file that produces it.

---

## 1. The headline position

| Measure | Value | Source |
|---|---:|---|
| Average inventory, 2025 | £2,043,979.36 | `05_reporting_views/01` |
| Closing inventory, 2025-12-28 | £1,711,041.86 | `05_reporting_views/01` |
| Cost of sales, 2025 | £9,550,572.04 | `05_reporting_views/01` |
| Inventory turnover | 4.67 | `05_reporting_views/01` |
| Days inventory outstanding | 78.2 | `05_reporting_views/02` |
| Annual holding cost at 22% | £449,675.46 | `05_reporting_views/03` |
| Unmet demand, 2025 (upper bound) | £1,027,628.75 | `05_reporting_views/04` |

Turnover uses average inventory, not closing. Closing stock sits 16.3% below the 52-week average because importer receipts arrive in a sawtooth and the year ends in a trough. Measured on closing stock, turnover reports 5.58 rather than 4.67, a 19% flattery. Every turnover and working-capital figure here uses the mean of 52 weekly snapshots.

---

## 2. Supported findings

### F-01 · The business is overstocked and out of stock at once

Calderfield holds around 78 days of cover and still failed to supply 7.71% of order lines in full during 2025: 1,272 of 16,506 lines, of which 835 received nothing at all.

The two conditions occur at the same sites and often on the same shelves. Livingston holds 129 days of cover and misses 5.32% of lines. Bristol holds 51 days and misses 10.77%.

The stock exists. It is not in the right places, in the right quantities, against the right demand. That makes this a question of allocation and replenishment design rather than of overall stock level.

*Source: `04_analysis/01`, `04_analysis/06`, `04_analysis/09`; `05_reporting_views/01`, `04`.*

### F-02 · Availability has three honest measures and they differ by a factor of two

| Measure | Rate | What it captures |
|---|---:|---|
| Weeks closing at zero | 3.52% | The Sunday snapshot, which is the literal KPI definition |
| Weeks containing a zero-stock day | 5.05% | Stockouts that cleared before the snapshot |
| Order lines not supplied in full | 7.71% | What the customer actually experienced |

The snapshot measure understates the daily measure by 1.26 times at Livingston and 1.67 times at Bristol. Both understate the customer measure, because a line can be short-shipped from a position that never reached zero. Quoting any one alone is a choice about which answer to give, so all three are reported together throughout.

*Source: `04_analysis/06`; `05_reporting_views/04`.*

### F-03 · Importer minimum order quantities structurally create inventory

The largest structural mechanism in the estate, and not a replenishment decision at all.

| Supplier type | Purchase lines 2025 | Minimum binds | Ordered at exactly the minimum |
|---|---:|---:|---:|
| Far East Importer | 303 | 98.3% | 99.3% |
| UK / EU Distributor | 522 | 6.9% | 10.5% |
| UK Manufacturer | 1,079 | 0.0% | 0.0% |
| Small Specialist | 159 | 0.0% | 0.0% |

Where a supplier's minimum exceeds what the replenishment policy called for, the buyer orders the minimum. During 2025 that bought £995,659 of stock beyond policy requirement, of which £977,541 (98.2%) was importer-sourced, representing 59.8% of all importer purchase value.

Converted to a standing level, the average incremental cycle stock is £497,830, carrying £109,523 a year at 22%. Separately, the longer lead times force a pipeline premium of £276,224 across 134 dual-source positions running 44.4 extra days.

The reason is the ratio between minimum and demand. A minimum of 400 units is unremarkable on a line selling 200 a week and is two years of trade on one selling four. 91 positions carry a minimum worth over six months of demand, and 90 of those 91 are importer-sourced.

*Source: `04_analysis/17`.*

### F-04 · Rising demand lines are set thin, falling demand lines are set deep

Replenishment settings track where demand has been rather than where it is going.

Measured against a rule calibrated from the network's own flat-demand lines rather than imported from outside:

| Demand direction | Lines | Median alignment ratio | Set thin | In line | Set deep |
|---|---:|---:|---:|---:|---:|
| Rising | 95 | 0.68 | 40 | 41 | 14 |
| Broadly flat (the calibration set) | 204 | 1.00 | 54 | 92 | 58 |
| Falling | 168 | 1.33 | 27 | 68 | 73 |

Settings on rising lines sit a third below what the estate's own practice implies, and settings on falling lines a third above.

Alignment maps onto outcome. Nothing else in the policy record does.

| Alignment | Lines | Mean cover | Unmet units | Unmet value | Days at zero |
|---|---:|---:|---:|---:|---:|
| Set thin | 121 | 13.3 wks | 11.62% | £505,019 | 7.28% |
| In line | 201 | 11.8 wks | 5.97% | £436,474 | 3.18% |
| Set deep | 145 | 32.4 wks | 2.79% | £41,426 | 1.36% |

That ordering is partly mechanical and is not a ranking, since deeper settings buy availability and that is their purpose. The finding is the asymmetry. Stock above the calibrated rule totals £115,916, costing £25,502 a year to hold, while unmet demand on thin-set lines over the same year is £505,019. Misalignment costs roughly twenty times more in service than in capital.

*Source: `04_analysis/16`.*

### F-05 · Meridian's deterioration is supplier-specific, not an importer trend

Meridian Pacific Trading's first-receipt on-time rate fell from 95.0% to 45.5% across four half-years (n = 100, 82, 68, 33, all above the reporting floor), ending 43.0 points below the network.

The importer type appears to decline alongside it, from 83.6% to 56.8%. Leave-one-out testing shows the type trend is entirely Meridian.

| Half-year | All importers | Importers excluding Meridian |
|---|---:|---:|
| 2024H1 | 83.6% | 72.9% |
| 2024H2 | 77.8% | 64.3% |
| 2025H1 | 73.1% | 66.7% |
| 2025H2 | 56.8% | 65.9% |

Without Meridian the importer type is flat to improving. Treating this as a category problem would direct the intervention at six suppliers who did not cause it.

*Source: `04_analysis/12`.*

### F-06 · Supplier delivery has three measures and they differ by ten points

| Measure | n | Rate | What it measures |
|---|---:|---:|---|
| First receipt against each line | 3,766 | 89.8% | Whether the supplier started on time |
| All receipts | 4,241 | 80.1% | Every delivery, so a split counts twice |
| Line complete on time | 3,768 | 79.1% | The full quantity by the promised date |

537 of 4,853 receipts, or 11.1%, are split deliveries. Quoting the first-receipt figure alone hides every one of them, so the split rate is carried as a column on each row rather than as a footnote.

The measurable window closes on 2025-09-30. 80.0% of importer purchase lines ordered after that date had not arrived by the end of the data, against 10.6% for UK manufacturers. Including them would compute an on-time rate only on the orders that happened to come back early.

*Source: `04_analysis/12`; `05_reporting_views/05`.*

### F-07 · Order cycle times are heavily skewed, so the mean alone misdescribes them

| Supplier type | n | Quoted | Median | p90 | Longest | Std dev | Median overrun |
|---|---:|---:|---:|---:|---:|---:|---:|
| UK Manufacturer | 2,048 | 7 | 8 | 10 | 17 | 1.4 | +1 |
| UK / EU Distributor | 941 | 14 | 20 | 23 | 40 | 4.2 | +6 |
| Small Specialist | 261 | 21 | 28 | 33 | 53 | 6.6 | +7 |
| Far East Importer | 603 | 55 | 78 | 91 | 166 | 12.5 | +23 |

Importers quote 55 days and deliver in a median 78, a 42% overrun, with a tail reaching 166 days. Median and mean are reported together throughout.

*Source: `04_analysis/13`; `05_reporting_views/06`.*

### F-08 · Stock value is concentrated, and part of it sits on slow sellers

Ten products, 4% of the range, hold 36.4% of stock value and generate 45.6% of cost of sales. The top 50 hold 74.9%.

Cross-classifying by stock value and by cost of sales finds 30 products holding £116,623, or 5.7% of the network, that rank in the top ABC classes on stock and the bottom on sales, carrying £25,657 a year. The reverse cell is empty: no product is under-stocked relative to high sales on this measure.

*Source: `04_analysis/02`.*

### F-09 · Site comparison changes materially once range mix is held constant

145 of 250 products are stocked only at Daventry, so raw turnover compares different businesses.

| Site | Turns as reported | Common-basket turns | Correction |
|---|---:|---:|---:|
| Daventry | 4.68 | 6.82 | +2.14 |
| Warrington | 5.63 | 6.03 | +0.40 |
| Bristol | 7.13 | 7.46 | +0.33 |
| Livingston | 2.84 | 2.84 | 0.00 |

Daventry's apparent underperformance is very largely the national range it carries alone. Livingston stocks only the 70 common products, so no correction is possible or needed, and its 2.84 turns stand unaltered by every adjustment tested.

Two correction methods disagree, and the disagreement is itself the finding. Common-basket restriction moves Bristol +0.33 while category-mix standardisation moves it +1.43. They answer different questions and neither is the corrected number.

*Source: `04_analysis/10`.*

### F-10 · Shortages arrive about two months after the demand peak

In four of eight categories the peak shortage month trails the peak demand month by exactly two months. Heating and Valves peak in January and run short in March. Electrical peaks in April and runs short in June. Renewables peak in October and run short in December. Two categories show no lag and two are longer.

The Warrington Heating shortage is in March rather than December, and the monthly pattern was established from the data rather than assumed.

*Source: `04_analysis/07`.*

### F-11 · The receiving site contributes to lead-time variance, but far less than it appears

Livingston books goods inwards in a Monday batch, taking 39.8% of its receipts on a Monday against 14% to 21% elsewhere, and it also buys heavily from Meridian. The two are confounded.

Naive marginals attribute +10.1 days to Livingston. An alternating two-way fit, which resolves the unbalanced supplier by site design properly, attributes +1.8 days. The naive figure overstates the site effect by more than five times and would charge a Livingston process for a supplier's lead time.

This is association rather than causation. The dataset cannot demonstrate that the Monday batch causes the delay.

*Source: `04_analysis/13`.*

### F-12 · The February 2025 Arden buy-ahead was economically successful

Arden Heating Components raised prices in March 2025. Buyers bought ahead in February, placing 88 lines at a median 3.20 times normal order size for 12,291 excess units.

| Component | Value |
|---|---:|
| Price saving captured | £146,490 |
| Residual stock still held at 2025-12-28 (upper bound) | £6,971 |
| Holding cost on that residual over 314 mean days held | £1,341 |
| Net position at 22% | +£145,148 |

This should not be classified as excess inventory. It was a correctly timed purchase, and the residual is a known, bounded consequence that is carved out of every tier of the opportunity hierarchy so it can never be counted as recoverable capital.

The raw before-and-after price comparison is invalid, because the product mix changed between the two periods. Like-for-like at product level across the 57 products bought on both sides gives a median rise of +18.2%, p10 17.0% to p90 18.9%, with every other supplier over the same dates between −1.1% and +0.7%.

*Source: `04_analysis/14`, `04_analysis/15`.*

### F-13 · Renewables demand growth has outpaced replenishment settings

*Reported with its sample limitation stated, which is material here.*

Renewables demand grew 85.5% from 2024Q1 to 2025Q4, the fastest in the range, with a per-quarter slope of R² = 0.64 against a next-highest of 0.24.

| | Renewables | All other categories |
|---|---:|---:|
| Stocked positions | 40 | 475 |
| Mean cover | 7.4 wks | 21.7 wks |
| Mean reorder point | 4.6 wks of cover | 11.1 wks |
| Weeks with a zero-stock day | 8.61% | 4.75% |
| Median alignment ratio | 0.81 | 0.99 |

Service is deteriorating as growth continues. 2025Q4 line fill fell to 83.7% with £257,709 of unmet demand, the worst quarter of the eight.

The limitation is material. Only 40 stocked positions exist and 31 of them are at Daventry, a site carrying its own unresolved service anomaly. This is a category finding resting on one site. The direction is clear and the breadth is not.

Mean policy age is 12.1 months against 11.0 elsewhere, which is essentially identical. The settings are not old. They are small.

*Source: `04_analysis/08`, `04_analysis/16`.*

### F-14 · Cheaper import pricing is real, and it is bought with working capital

Across 60 products purchased from two sources with at least four lines from each, the cheaper source is a Far East importer in every case, at a median premium on the dearer source of around 30%.

| Component | Value | Basis |
|---|---:|---|
| Annual price saving from using the cheaper source | £492,020 | Twelve months |
| Additional working capital it requires | £604,231 | One-off |
| Net at 22% | +£359,089 | Annualised |

The cheaper source carries minimum order quantities 8.8 to 10.7 times larger and lead times 43 to 47 days longer. Buyers already favour the cheaper source on 40 of the 60.

An earlier version of this comparison set a two-year saving against a one-year holding cost, roughly doubling the apparent benefit. Correcting both sides to an annual basis halved it to £359,089. The direction survived and the magnitude did not.

*Source: `04_analysis/14`.*

---

## 3. The quantified opportunity

### F-15 · £468,897 of working capital is identified, counted once

Each of the 515 stock positions is assigned to exactly one mechanism, testing five tiers in priority order and taking the first match.

| Tier | Mechanism | Positions | Stock held | Working capital | Holding cost at 22% |
|---|---|---:|---:|---:|---:|
| 1 | Discontinued or obsolete | 25 | £87,478 | £87,478 | £19,245 |
| 2 | Importer and minimum-order structural (upper bound) | 148 | £416,075 | £303,558 | £66,783 |
| 3 | Above the calibrated requirement | 125 | £357,897 | £70,755 | £15,566 |
| 4 | Slow-moving residual | 8 | £14,373 | £7,106 | £1,563 |
| 5 | No identified opportunity | 209 | £835,219 | £0 | £0 |
| | **Total** | **515** | **£1,711,042** | **£468,897** | **£103,157** |

Sensitivity on the holding cost: £93,779 at 20%, £117,225 at 25%.

**Why a hierarchy rather than a sum.** Each analysis file measured a different exposure against the same stock, and the exposures overlap heavily. 23 positions worth £70,857 are both slow-moving and above policy. 54.4% of high-cover positions are also minimum-order constrained, and 85.4% are also policy-authorised.

| Exposure as each file measured it | Value |
|---|---:|
| Slow-moving stock (file 03) | £123,373 |
| Excess above the policy ceiling (file 04) | £134,701 |
| Cover over six months (file 05) | £398,821 |
| Stock above the calibrated rule (file 16) | £115,916 |
| Minimum-order bound in closing stock (file 17) | £336,205 |
| Naive sum, the same pounds up to five times | £1,109,016 |
| Counted once under the hierarchy | £468,897 |

The naive sum would release 65% of the entire estate. These figures must never be added.

£468,897 is what has been identified, not what can be removed. Every tier carries a service consequence and none of it is free.

*Source: `05_reporting_views/07`.*

### F-16 · Two structural facts emerged from building the hierarchy

**Slow-moving stock is largely a symptom rather than an independent problem.** Of the £123,373 measured in file 03, only £14,373 across 8 positions survives as an unexplained residual. £23,725 is discontinued, £34,954 is minimum-order structural, and £50,321 sits above the calibrated rule.

**Nearly half the estate has no case against it.** Tier 5 holds £835,219, or 48.8% of the network, with no identified release opportunity. That is a ceiling on how large any recommendation can honestly be.

*Source: `05_reporting_views/07`.*

---

## 4. Upper bounds

These four figures are the most likely to be misread. Each is the largest the quantity could be, not the amount anyone should expect.

| Figure | Value | Why it is a ceiling |
|---|---:|---|
| Unmet demand, 2025 | £1,027,628.75 | Substitution is not modelled. Some customers would have taken an alternative and some would have waited. Priced at what those customers had already been quoted. |
| Minimum-order bound in closing stock | £336,205 | Stock is fungible and valued at weighted average cost. No unit on a shelf records why it was bought, so this is the most the minimum could still account for. |
| Tier 2 working capital | £303,558 | The same bound, after tier 1 takes precedence. |
| February buy-ahead residual | £6,971 | Credits every subsequent issue against the excess first, which is the consumption order most favourable to the buy-ahead. |

---

## 5. Assumptions

1. **The 22% holding rate is derived rather than asserted:** 6% capital (Bank of England Bank Rate of 3.75% at 18 December 2025 plus an assumed 2.25pp commercial margin), 8% storage, 3% service and 5% risk. Only the capital component has an authoritative primary source. The other three are industry convention, and the published 20% to 30% range has no single primary study behind it. Sensitivity at 20% and 25% is carried on every quantified figure, and capital is always printed beside cost so a reader can apply their own rate.
2. **The rate applies uniformly across sites and categories.** Livingston's cost per pallet almost certainly differs from Daventry's, and the dataset holds no site cost data to say so.
3. **Sales issues are customer demand and transfers are not.** 441 transfer pairs move stock out of Daventry, and counting them as demand would flatter the site the range-mix work exists to assess honestly.
4. **The reorder points on file were in force throughout the period.** The dataset carries only their current state and one review date, never their history.
5. **Weekly snapshots plus a days-at-zero count are sufficient to measure availability.** Sub-day stockouts are invisible either way.
6. **Two years establishes direction rather than trend.** Every slope is reported with the number of quarters behind it, and nothing here is a forecast.

One dataset artefact constrains what can be claimed. Net stock loss in the generated data runs at 7.9% of average inventory a year against a real-world norm well under 2%, roughly four times realistic. The dataset is frozen, so shrinkage is reported comparatively between sites and never as an absolute, and the 5% risk component of the holding rate comes from the published benchmark rather than from this data.

---

## 6. Unresolved

Neither of these has been converted into a recommendation, and neither should be.

### F-U1 · Daventry short-ships when it has the stock

Daventry fails to supply 2.60% of units in weeks when inventory cover was adequate, four to nine times the rate of the other sites (Livingston 1.20%, Bristol 0.54%, Warrington 0.30%). That covers 33 short weeks and £68,451 of unmet demand from positions that were not short of stock.

Everything tested failed to explain it. Order lumpiness does not, since demand in Daventry's short weeks runs 5.45 times normal while Livingston's runs 4.73 times with a fifth of the shortfall rate. Customer mix, range mix and transfer activity were each examined and none accounts for it. The anomaly survived every correction offered.

### F-U2 · Bristol's shortfall peaks in March and April

Bristol's unmet demand peaks in March and April 2025, and the pattern fits neither available explanation cleanly. It is not the opening ramp, since the site opened in July 2024 and its worst months are eight months later rather than its first. It is not the general replenishment lag described in F-10, since Bristol's peak does not sit two months after a Bristol demand peak.

**Why this matters for anything that follows.** These two sites hold £252,435 of the £468,897 identified opportunity, or 53.8%. Bristol shows 59.1% of its closing stock as releasable, the highest share in the network, on a site already missing 10.77% of its order lines. A working-capital case at either site cannot state its service consequence with confidence, and every row of the opportunity view carries that constraint explicitly.

---

## 7. Rejected

Three of these would have produced confident and wrong recommendations.

### R-01 · Stale replenishment policies cause poor availability

Rejected. Policies not reviewed for over 15 months (n = 121) show a reorder point of 10.2 weeks and an unmet rate of 6.03%. Recent policies (n = 394) show 10.6 weeks and 7.80%. The stale group performs better, at near-identical reorder depth.

### R-02 · Policy review recency signals whether settings fit demand

Rejected. A redesigned analysis tested the weaker version of the same idea and it also failed.

| Policy age | Lines | In line with the rule | Mean absolute departure |
|---|---:|---:|---:|
| Under 6 months | 141 | 41.1% | 0.789 |
| 6 to 12 months | 156 | 43.6% | 0.754 |
| 12 to 18 months | 75 | 41.3% | 0.734 |
| Over 18 months | 95 | 46.3% | 0.700 |

The oldest band has the highest share in line and the smallest departure. As a continuous association, correlation is −0.066 and R² is 0.0044. Holding category constant does not rescue it, since old policies are more often in line in four of eight categories.

Policy age is descriptive throughout this project and is never presented as a driver of performance.

A related question cannot be answered at all. The policy table holds one row per product and site: current settings and a single review date. Prior settings were never recorded, so nothing here can say what a review changed, or that a review caused an improvement. A review that happened and altered nothing is indistinguishable from one that reset the line completely. An earlier design that proposed to measure this was withdrawn for that reason.

### R-03 · The Far East importer type is getting worse

Rejected. The type-level decline is one supplier. See F-05.

### R-04 · The February buy-ahead left excess inventory behind

Rejected. Net +£145,148. See F-12.

### R-05 · Excess above policy is a UK-manufacturer problem

Rejected, and it reversed. Attributing excess to each product's nominated primary supplier put 76% of it on UK manufacturers. Attributing it to the source actually used on the most recent receipt reverses the conclusion entirely.

| Source actually used | Excess on hand | Share |
|---|---:|---:|
| Far East Importer | £110,495 | 82.0% |
| UK Manufacturer | £14,724 | 10.9% |
| UK / EU Distributor | £9,368 | 7.0% |
| Small Specialist | £115 | 0.1% |

This became a standing rule: every minimum order quantity and lead time in the project belongs to the source actually used.

### R-06 · Daventry is the network's worst-performing warehouse

Rejected. On raw turnover Daventry looks weak at 4.68. On the range all four sites carry it turns 6.82, second only to Bristol. Its apparent underperformance is the 145 national-only products it holds alone. Livingston, not Daventry, is the site whose 2.84 turns survive every correction.

---

## Evidence map

| Mechanism | Status | Where |
|---|---|---|
| Minimum order quantities structurally create inventory | Supported | F-03 |
| Long importer lead times deepen the pipeline | Supported | F-03, F-07 |
| Settings misaligned to current demand drive both overstock and shortage | Supported | F-04 |
| Excess concentrates in imported sourcing | Supported | R-05 |
| Meridian's delivery performance deteriorated | Supported | F-05 |
| Renewables growth has outrun replenishment settings | Partially supported: 40 positions, 31 at one site | F-13 |
| Receiving site contributes to lead-time variance | Partially supported: association only, +1.8 days once fitted | F-11 |
| Stale policies cause poor availability | Rejected | R-01 |
| Review recency signals alignment | Rejected | R-02 |
| The importer type is deteriorating | Rejected | R-03 |
| The February buy-ahead left excess | Rejected | R-04 |
| Excess is a UK-manufacturer problem | Rejected and reversed | R-05 |
| Daventry is the worst-performing site | Rejected | R-06 |
| Range mix explains Daventry's service anomaly | Rejected | F-U1 |
| Daventry's service anomaly | Unresolved | F-U1 |
| Bristol's March to April shortfall | Unresolved | F-U2 |
| What a policy review changed | Unanswerable from this dataset | R-02 |

---

*All figures trace to committed results in [`../analysis/query_results/`](../analysis/query_results/). Method: [`methodology.md`](methodology.md). The full decision record is in [`technical/analytical-decisions.md`](technical/analytical-decisions.md).*
