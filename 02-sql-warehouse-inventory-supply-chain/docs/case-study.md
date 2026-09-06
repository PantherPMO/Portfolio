# Case Study: Where Is the Working Capital?

**Audience:** Operations Director, copied to Finance and Purchasing
**Period analysed:** calendar 2025
**Tools:** PostgreSQL 16, Power BI

> Calderfield Trade Supplies Ltd is fictional and the dataset is synthetic. This document demonstrates analytical method rather than making claims about a real business.

---

## The question

Calderfield runs four distribution centres, stocks 250 products and buys from around 30 suppliers. Finance believes too much cash is tied up in stock. Operations believes the business is running out of the things customers want. The brief was to establish which of them is right.

Both are, and that turned out to be the finding rather than an obstacle to one.

## The position

Calderfield carried £2.04m of average inventory during 2025 against £9.55m of cost of sales, giving 4.67 turns and roughly 78 days of cover. Over the same year it failed to supply 7.71% of order lines in full, on demand worth up to £1.03m.

| Measure | 2025 | Basis |
|---|---:|---|
| Average inventory | £2,043,979 | Mean of 52 weekly snapshots |
| Cost of sales | £9,550,572 | Ledger weighted average cost, transfers excluded |
| Inventory turnover | 4.67 | Closing stock would report 5.58 |
| Annual holding cost at 22% | £449,675 | £408,796 at 20%, £510,995 at 25% |
| Order lines not supplied in full | 7.71% | 1,272 of 16,506 |
| Value of demand not met | £1,027,629 | Upper bound; substitution is not modelled |

Overstock and shortage are usually treated as opposite problems needing opposite fixes. Here they occur in the same year, at the same sites, and frequently on the same shelves. That points at how inventory is allocated and how replenishment is designed rather than at the overall level of stock.

The network average also conceals a wide split between sites.

| Site | Average stock | Turns | Days | Line fill |
|---|---:|---:|---:|---:|
| Daventry | £996,883 | 4.68 | 78 | 92.30% |
| Livingston | £473,539 | 2.84 | 129 | 94.68% |
| Warrington | £366,299 | 5.63 | 65 | 93.08% |
| Bristol | £207,258 | 7.13 | 51 | 89.23% |

Livingston holds two and a half times Bristol's cover and serves customers better. Bristol turns stock fastest and serves worst. Neither site is simply right or wrong. They sit at opposite ends of a trade-off nobody is managing.

## What is driving it

### Supplier minimums have replaced the buying decision

The largest structural mechanism putting stock into the warehouse is not a replenishment decision at all. It is a term of trade.

On 98.3% of Far East importer purchase lines, the supplier's minimum order quantity exceeded what the replenishment policy called for. On 99.3%, the buyer ordered exactly that minimum. Over 2025 this brought in £995,659 of stock beyond policy requirement, almost all of it importer-sourced. Expressed as a standing level rather than a flow, the average incremental cycle stock is £497,830, costing £109,523 a year to hold at 22%.

The reason is visible in the ratio between minimum and demand. A minimum of 400 units is unremarkable on a product selling 200 a week and is two years of trade on one selling four. On 91 positions the minimum is worth more than six months of demand, and 90 of those 91 are importer-sourced.

### Replenishment settings look backwards

Judging whether a reorder point is set correctly needs a standard. Rather than import a rule of thumb, the analysis derives one from Calderfield's own practice: the median multiple of lead-time demand at which reorder points sit on products whose demand is broadly flat, and whose settings are therefore closest to still fitting. That comes out at 3.05 times lead-time demand, and is then applied to every product at its current demand level.

On that measure, rising-demand lines sit at 0.68 of the implied level and falling-demand lines at 1.33. Settings track where demand has been.

Alignment predicts outcome cleanly, and nothing else in the policy record does.

| Alignment | Lines | Mean cover | Unmet units | Unmet value | Days at zero |
|---|---:|---:|---:|---:|---:|
| Set thin | 121 | 13.3 wks | 11.62% | £505,019 | 7.28% |
| In line | 201 | 11.8 wks | 5.97% | £436,474 | 3.18% |
| Set deep | 145 | 32.4 wks | 2.79% | £41,426 | 1.36% |

Some of that ordering is mechanical, since deeper settings buy availability and that is what they are for. The finding is the asymmetry. Stock above the calibrated rule totals £115,916 and costs £25,502 a year to hold. Unmet demand on thin-set lines over the same year is £505,019. The service cost of misalignment is roughly twenty times the capital cost, which is the opposite of the balance the project was set up to look for.

### One supplier is deteriorating, not a category

Meridian Pacific's first-receipt on-time rate fell from 95.0% to 45.5% across four half-years, ending 43 points below the network. Far East importers as a type appear to fall alongside it, from 83.6% to 56.8%.

Removing Meridian and re-measuring shows the remaining six importers running 72.9%, 64.3%, 66.7% and 65.9% across the same periods: flat to slightly improving. The type-level trend is one supplier. Responding to it as a category problem would have targeted six suppliers who did not cause it.

## The working capital opportunity

£468,897, counted once.

| Mechanism | Positions | Working capital | Annual holding cost |
|---|---:|---:|---:|
| Discontinued or obsolete | 25 | £87,478 | £19,245 |
| Importer and minimum-order structural (upper bound) | 148 | £303,558 | £66,783 |
| Above the calibrated requirement | 125 | £70,755 | £15,566 |
| Slow-moving residual | 8 | £7,106 | £1,563 |
| No identified opportunity | 209 | £0 | £0 |
| **Total** | **515** | **£468,897** | **£103,157** |

Three qualifications matter more than the figure itself.

**It is not the sum of the exposures measured along the way.** Five separate analyses each measured a different exposure against the same stock, and they overlap heavily. Added together they come to £1,109,016, which would release 65% of an estate holding £1.71m: the same pounds counted up to five times. Each of the 515 positions is instead assigned to exactly one mechanism, tested in priority order, and the tiers reconcile to closing stock exactly.

**It is not available cash.** Three of the four active tiers are upper bounds rather than estimates. Discontinued stock is carried at cost, which is the number leaving the balance sheet, not the number arriving in the bank.

**It is not free.** Every tier carries a service consequence, and the largest carries a price consequence. Across 60 dual-sourced products the cheaper supplier is a Far East importer in every case, worth £492,020 a year against £604,231 of additional working capital, netting +£359,089 at 22%. Reducing importer stock to release capital would forfeit more than it recovers.

And 209 positions holding £835,219, or 48.8% of closing stock, carry no identified opportunity at all. That is a ceiling on how large any programme here can honestly be.

## What to do

**Priority 1, structural.** Renegotiate minimum order quantities on the 91 positions where the minimum exceeds six months of demand, preferring network consolidation over re-sourcing. Re-set reorder points against current demand in both directions: raise the 95 starved rising lines, lower the 145 over-fed falling ones, and size the two together so the estate does not simply get deeper.

**Priority 2, targeted.** A supplier review with Meridian specifically. Clear the 25 discontinued positions. Re-size Renewables, growing 85.5% on settings built for a smaller category. Advance seasonal replenishment ahead of the peak rather than into it.

**Priority 3, investigate first.** Two service problems remain unexplained after everything the data can test.

Daventry short-ships 2.60% of units in weeks when its cover was adequate, four to nine times the rate of the other sites. Order lumpiness, customer mix, range mix and transfer activity were each tested and none accounts for it. Bristol's shortfall peaks in March and April 2025, fitting neither the site's opening ramp nor the general seasonal lag.

These two sites hold £252,435 of the identified opportunity, 53.8% of the total. Bristol shows 59.1% of its stock as releasable, the highest share in the network, while serving worst at 89.23% line fill. No broad inventory reduction should be taken at either site until the service behaviour is understood, because acting on the apparent overstock without explaining the service failure risks converting a capital gain into a service loss at the sites least able to absorb one. Clearing discontinued stock is safe at both, since there the demand claim is definitional.

## What was tested and rejected

Recording these matters, because three of them would have produced confident and wrong recommendations.

**Stale replenishment policies cause poor availability.** Rejected. Policies over 15 months old show a lower unmet rate, 6.03% against 7.80%, at near-identical depth.

**Review recency signals whether settings fit demand.** Rejected. Correlation −0.066, R² 0.0044, with the oldest policies marginally the best aligned. Policy age should not be used to target replenishment work, because it would select close to randomly.

**The Far East importer category is deteriorating.** Rejected. It is one supplier.

**The February Arden buy-ahead left excess stock behind.** Rejected. It captured £146,490 against a residual bounded at £6,971, netting +£145,148. It was a correctly timed purchase and should not be reclassified as excess.

**Excess above policy is a UK-manufacturer problem.** Rejected, and it reversed. Attributing excess to each product's nominated primary supplier put 76% of it on UK manufacturers. Attributing it to the source actually used on the most recent receipt moves 82% of it to Far East importers.

**Daventry is the worst-performing warehouse.** Rejected. On the range all four sites carry it turns 6.82, second only to Bristol. Its apparent weakness is the 145 national-only products it holds alone.

## What the figures rest on

The 22% holding rate is derived rather than asserted: 6% capital, based on Bank of England Bank Rate plus an assumed commercial margin, 8% storage, 3% service and 5% risk. Only the capital component has an authoritative primary source. Every quantified figure carries 20% and 25% alongside it, and capital released is always shown beside cost saved so a reader can substitute their own rate.

Unmet demand is an upper bound, priced at what those customers had already been quoted. Substitution is not modelled: some would have taken an alternative and some would have waited.

Two years establishes direction rather than trend. Every slope is reported with the number of quarters behind it. Nothing here is a forecast, and demand forecasting was out of scope.

---

*Findings in full: [`findings.md`](findings.md). Recommendations: [`recommendations.md`](recommendations.md). Method: [`methodology.md`](methodology.md).*
