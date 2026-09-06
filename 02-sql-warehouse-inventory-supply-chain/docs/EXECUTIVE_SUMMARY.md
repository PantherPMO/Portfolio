# Executive Summary — Warehouse Inventory & Supply Chain Performance

**To:** Operations Director · **Copied:** Finance Director, Head of Purchasing
**Period:** Calendar 2025 · **Prepared:** August 2026

> **Calderfield Trade Supplies Ltd is fictional and this dataset is synthetic.** This summary
> demonstrates analytical method. It is not a claim about any real business.

---

## The question

> **Where is working capital tied up, and which inventory and supply chain decisions are costing
> the business money?**

---

## The answer in one paragraph

Calderfield carries **£2.04m of average inventory** against **£9.55m of cost of sales** — 4.67
turns, 78 days. At the same time it failed to supply **7.71% of order lines in full**, on demand
worth up to **£1.03m**. Those two facts are usually treated as opposite problems requiring
opposite fixes. Here they occur at the same sites, in the same year, and frequently on the same
shelves. **This is not an overstock problem and it is not an understock problem — it is a
problem of how inventory is allocated and how replenishment is designed.** The analysis
identifies **£468,897** of working capital against which a case can be made, carrying **£103,157**
a year to hold. Just under half the estate carries no case at all, and more than half the
identified opportunity sits at two sites whose service behaviour the data cannot explain.

---

## The position

| Measure | 2025 | Note |
|---|---:|---|
| Average inventory | **£2,043,979** | Mean of 52 weekly snapshots, never closing stock |
| Cost of sales | £9,550,572 | At ledger weighted average cost; transfers excluded |
| Inventory turnover | **4.67** | Closing stock would report 5.58 — a 19% flattery |
| Days inventory outstanding | 78.2 | |
| Annual holding cost at 22% | £449,675 | £408,796 at 20%, £510,995 at 25% |
| Order lines not supplied in full | **7.71%** | 1,272 of 16,506 |
| Value of demand not met | **£1,027,629** | **Upper bound** — substitution is not modelled |

The network average conceals a four-way split:

| Site | Average stock | Turns | Days | Line fill |
|---|---:|---:|---:|---:|
| Daventry | £996,883 | 4.68 | 78 | 92.30% |
| Livingston | £473,539 | **2.84** | **129** | 94.68% |
| Warrington | £366,299 | 5.63 | 65 | 93.08% |
| Bristol | £207,258 | 7.13 | 51 | **89.23%** |

Livingston holds two and a half times Bristol's cover and serves customers better. Bristol turns
stock fastest and serves worst. **Neither site is simply right or wrong — they sit at opposite
ends of the same unmanaged trade-off.**

---

## What is actually causing it

**1 · Supplier minimums, not replenishment decisions, are the largest structural driver.**
98.3% of Far East importer purchase lines are placed where the supplier's minimum exceeds what
the replenishment policy called for, and **99.3% are ordered at exactly that minimum**. The order
quantity has stopped being a business decision. During 2025 this bought **£995,659** of stock
beyond policy requirement, almost all of it importer-sourced. On 91 positions the minimum is worth
more than six months of demand.

**2 · Settings track where demand has been, not where it is going.** Measured against the
network's own working practice, rising-demand lines are set at **0.68** of what that practice
implies and falling-demand lines at **1.33**. Alignment predicts outcome cleanly: thin-set lines
miss 11.62% of units, in-line lines 5.97%, deep-set lines 2.79%.

**The cost of that misalignment is wildly asymmetric.** Stock above the calibrated rule totals
£115,916 and costs £25,502 a year to hold. Unmet demand on thin-set lines over the same year is
**£505,019**. **The service side is roughly twenty times the capital side** — the opposite of what
this project set out expecting to find.

**3 · One supplier is deteriorating, and it is not a category.** Meridian Pacific's on-time
delivery fell from 95.0% to 45.5% across four half-years. Importers as a type appear to fall
alongside it — until Meridian is removed, at which point the remaining six are flat to improving
(65.9% in the final period against 56.8% with Meridian included). Treating this as an importer
problem would misdirect the response onto suppliers who did not cause it.

---

## What the working capital opportunity actually is

**£468,897, counted once.**

| Mechanism | Positions | Working capital | Annual holding cost |
|---|---:|---:|---:|
| Discontinued or obsolete | 25 | £87,478 | £19,245 |
| Importer / minimum-order structural *(upper bound)* | 148 | £303,558 | £66,783 |
| Above the calibrated requirement | 125 | £70,755 | £15,566 |
| Slow-moving residual | 8 | £7,106 | £1,563 |
| **No identified opportunity** | **209** | **£0** | **£0** |
| **Total** | **515** | **£468,897** | **£103,157** |

**Three things this number is not.**

It is **not the sum of the exposures the analysis measured.** Those overlap heavily and add to
£1,109,016 — 65% of the entire estate, the same pounds counted up to five times. Each position is
assigned to exactly one mechanism precisely so the total is defensible.

It is **not available cash.** Three of the four tiers are upper bounds. Discontinued stock is
carrying value, not realisation value — the number leaving the balance sheet, not the number
arriving in the bank.

It is **not free.** Every tier carries a service consequence, and the largest tier carries a
price consequence: the cheaper source is a Far East importer in **all 60** dual-source cases,
worth £492,020 a year. Re-sourcing away from importers to release capital would forfeit more than
it saves.

**And nearly half the estate has no case against it at all** — 209 positions holding £835,219, or
48.8%. That is a hard ceiling on how large any programme here can honestly be.

---

## What to do

**Priority 1 — structural, act now**
Renegotiate minimum order quantities on the 91 positions where the minimum exceeds six months of
demand, preferring network consolidation over re-sourcing. Re-set reorder points against current
demand **in both directions** — raise the 95 starved rising lines, lower the 145 over-fed falling
ones, and size the two together so the estate does not simply get deeper.

**Priority 2 — targeted**
A supplier review with Meridian, specifically and not as a category. Clear the 25 discontinued
positions. Re-size Renewables, which is growing 85.5% on settings built for a smaller category.
Advance seasonal replenishment ahead of the peak rather than into it.

**Priority 3 — find out before acting**
Two service problems remain **unresolved** after everything the data can test, and are recorded
as such rather than explained away.

- **Daventry short-ships 2.60% of units in weeks when it had adequate cover** — four to nine times
  the other sites. Order lumpiness, customer mix, range mix and transfers were each tested and
  none explains it.
- **Bristol's shortfall peaks in March–April 2025**, fitting neither the opening ramp nor the
  general seasonal lag.

**These two sites hold £252,435 — 53.8% — of the identified opportunity.** Bristol shows 59.1% of
its stock as releasable, the highest in the network, while serving worst at 89.23%.

**No broad inventory reduction should be taken at either site until the service behaviour is
understood.** Acting on the apparent overstock without explaining the service failure risks
converting a capital gain into a service loss at the sites least able to absorb one. Clearing
discontinued stock is safe at both, because there the demand claim is definitional.

---

## What was tested and rejected

Recording these matters: three would have produced confident, wrong recommendations.

- **Stale replenishment policies cause poor availability.** Rejected. Policies over 15 months old
  show a *lower* unmet rate (6.03% against 7.80%) at near-identical depth.
- **Review recency signals whether settings fit demand.** Rejected. Correlation −0.066, R² 0.0044;
  the oldest policies are marginally the best aligned. **Policy age must not be used to target
  replenishment work** — it would select close to randomly.
- **The Far East importer category is deteriorating.** Rejected. It is one supplier.
- **The February Arden buy-ahead left excess stock.** Rejected. It captured £146,490 against a
  residual bounded at £6,971 — **net +£145,148**. It was a correctly-timed purchase and must not
  be reclassified as excess.
- **Excess above policy is a UK-manufacturer problem.** Rejected, and it reversed: attributing to
  the source *actually used* rather than the nominated one moves 82% of it to Far East importers.
- **Daventry is the worst-performing warehouse.** Rejected. On the range all four sites carry it
  turns 6.82, second only to Bristol. Its apparent weakness is the 145 national-only SKUs it holds
  alone.

---

## What the figures rest on

The **22% holding rate** is derived, not asserted — 6% capital (Bank of England Bank Rate 3.75%
plus an assumed commercial margin), 8% storage, 3% service, 5% risk. **Only the capital component
has an authoritative primary source.** Every quantified figure carries 20% and 25% alongside, and
capital released is always shown beside cost saved so the rate can be substituted.

**Unmet demand is an upper bound**, priced at what those customers had already been quoted.
Substitution is not modelled: some would have taken an alternative, some would have waited.

**Two years establishes direction, not trend.** Every slope is reported with the number of
quarters behind it. Nothing here is a forecast, and demand forecasting is out of scope.

---

*Findings: `docs/KEY_FINDINGS.md`. Recommendations in full: `docs/RECOMMENDATIONS.md`. Method:
`docs/METHODOLOGY.md`. Decisions D-01 to D-40: `docs/DECISIONS.md`.*
