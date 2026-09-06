# Recommendations

> Calderfield Trade Supplies Ltd is fictional and the dataset is synthetic. These recommendations demonstrate how evidence is turned into decisions rather than advising any real business.

**Owner:** Operations Director. **Secondary:** Finance Director for working capital, Head of Purchasing for supplier performance and price.

---

## Three rules that govern everything below

**The opportunity figures must never be added beyond their tier.** £468,897 is the total identified working capital across all five tiers, counted once. The separate exposures it replaces sum to £1,109,016, which is the same pounds counted up to five times. Each recommendation cites its own tier's figure, and those tier figures sum to £468,897 and to nothing larger.

**£468,897 is identified, not available.** It is what the analysis can argue against. Every tier carries a service consequence, three of the four active tiers are upper bounds rather than estimates, and 48.8% of the estate carries no case at all. Nothing here should be entered into a forecast as a saving.

**Working capital released is a one-off and holding cost saved is annual.** They run on different clocks and are never added.

No return on investment is stated. Where an implementation cost would be needed to compute one, whether buyer time, supplier renegotiation or a systems change, the dataset contains no cost data at all. The return is therefore left unstated rather than estimated.

---

## Priority 1: immediate structural interventions

Both address mechanisms that are structural rather than discretionary, both rest on supported findings, and neither requires an investigation first.

### P1-1 · Break the link between supplier minimums and stock depth

**The problem.** The largest single mechanism putting capital into the warehouse is not a replenishment decision. Where a Far East importer will not sell less than its minimum, the buyer orders the minimum, and the difference between that and what the policy called for becomes stock nobody chose to hold. On 91 positions the minimum is worth more than six months of demand, and on one it is over two years.

**Evidence.** 98.3% of importer purchase lines in 2025 were placed where the minimum exceeded the policy reorder quantity, and 99.3% were ordered at exactly the minimum. This bought £995,659 of stock beyond policy requirement during 2025, 98.2% of it importer-sourced. 90 of the 91 positions whose minimum exceeds six months of demand are importer-sourced. *(`04_analysis/17`, `05_reporting_views/07`)*

**Opportunity.** £303,558 of working capital, an upper bound rather than an estimate, being tier 2 of the hierarchy. Annual holding cost £66,783 at 22%, ranging £60,712 to £75,890.

The bound is generous by construction. Stock is fungible, valued at weighted average cost, and no unit on a shelf records why it was bought, so the true figure is at or below £303,558.

**Action.** Renegotiate minimum order quantities on the 91 positions where the minimum exceeds six months of demand, starting with the 20 largest by bound value. Three levers, in order of preference: consolidate multiple sites' requirements into one order so the minimum is met across the network rather than per site; negotiate a smaller minimum in exchange for order frequency or a volume commitment; or move the line to a shorter-lead alternative source where one is qualified.

**Benefit.** Reduced standing stock on the affected lines, with the release bounded above by the tier figure, and lower exposure to the 44.4 extra lead days those sources carry. That currently obliges a pipeline premium of £276,224 across 134 dual-source positions.

**Risk, and it is real.** This release is not free, and the third lever would forfeit a measured saving. Across the 60 products bought from two sources, the cheaper source is a Far East importer in every case, at a median premium of around 30% on the dearer alternative, worth £492,020 a year against £604,231 of one-off working capital and netting +£359,089 at 22%.

Re-sourcing away from importers to release capital would therefore give up more in unit price than it saves in holding cost. Consolidation and renegotiation are the levers that release capital without forfeiting the price advantage. Re-sourcing should be the last resort, and only where the price gap on that specific product is small.

Shorter lead times also reduce the pipeline buffer that currently absorbs importer variability, at a median 78 days against 55 quoted with a tail to 166, so any re-sourcing must re-set the reorder point at the same time.

**Dependencies and limitations.** Requires Head of Purchasing to hold the supplier conversations, and the dataset contains no information on supplier willingness to renegotiate. The £303,558 is an upper bound. The price saving foregone is the binding constraint, not the holding cost. 41 of the 148 tier-2 positions are at Bristol and 34 at Daventry, which brings the Priority 3 constraint into play.

*Findings: F-03, F-14, F-15.*

### P1-2 · Re-set reorder points against current demand, in both directions

**The problem.** Replenishment settings track where demand has been rather than where it is going. Rising lines are starved and falling lines are over-fed, so the business pays on both sides at once. This is the mechanism behind the central paradox of 78 days of cover alongside a 7.71% line-fill failure.

**Evidence.** Measured against the network's own working rule, calibrated from flat-demand lines rather than imported from outside, rising lines sit at a median alignment ratio of 0.68 and falling lines at 1.33. Outcome follows alignment: thin-set lines run 11.62% unmet against 5.97% for in-line lines, and 7.28% of days at zero against 3.18%. *(`04_analysis/16`)*

**Opportunity, and it is asymmetric.**

| Direction of misalignment | Positions | Measure | Value |
|---|---:|---|---:|
| Set deep | 145 | Working capital above the calibrated rule (tier 3) | £70,755 |
| | | Annual holding cost at 22% | £15,566 (£14,151 to £17,689) |
| Set thin | 121 | Unmet demand during 2025 (upper bound) | £505,019 |

The service side is roughly twenty times larger than the capital side, and that should set the emphasis of the response.

**Action.** Two coordinated changes, run together rather than in sequence. Raise reorder points on the 95 rising-demand lines toward the calibrated rule of 3.05 times lead-time demand at current demand levels, which is the estate's own working practice rather than an imported benchmark. Lower reorder points on the 145 deep-set lines toward the same rule, taking the 20 largest by capital first.

**Benefit.** Capital: up to £70,755 released and £15,566 a year in holding cost. Service: a reduction in the £505,019 of unmet demand on thin-set lines, which is not quantifiable as a recovery because substitution is not modelled and some of that demand would have gone elsewhere or waited regardless.

**Risk.** Lowering deep settings moves those lines from 2.79% unmet toward the network-average 5.97%. That is a real, measured service cost and it is the price of the capital, so it should be accepted deliberately rather than discovered afterwards.

Raising thin settings costs capital in the opposite direction, which the £70,755 partly funds. The two changes should be sized together so the estate does not simply get deeper.

**Dependencies and limitations.** Only 467 of 515 positions are assessable, since a line needs current demand, a known source and six quarters of history. The remaining 48 are stated in the view rather than silently excluded.

Policy age must not be used to target this work. Age does not predict alignment, at a correlation of −0.066 and R² of 0.0044, and the oldest policies are marginally the best aligned. Targeting the oldest review dates would select close to randomly.

*Findings: F-01, F-04, F-15.*

---

## Priority 2: targeted supplier and replenishment interventions

Four recommendations, each narrow, each resting on a supported finding, none requiring further investigation.

### P2-1 · Address Meridian Pacific specifically, and do not generalise it

**The problem.** One supplier's delivery reliability has collapsed. The importer category appears to be deteriorating alongside it, and treating this as a category problem would misdirect the intervention onto six suppliers who did not cause it.

**Evidence.** Meridian's first-receipt on-time rate fell 95.0%, 93.9%, 79.4%, 45.5% across four half-years (n = 100, 82, 68, 33, every cell above the reporting floor), ending 43.0 points below the network. Leave-one-out testing shows importers excluding Meridian running 72.9%, 64.3%, 66.7%, 65.9%: flat to improving in the final period against 56.8% with Meridian included. Meridian's mean overrun against quoted lead time also rose from 21.3 to 26.8 days. *(`04_analysis/12`)*

**Opportunity.** None stated. The dataset does not connect a specific late delivery to a specific stockout, so attributing any part of the £1,027,629 unmet demand to Meridian would be a fabrication. The case rests on the reliability trend itself.

**Action.** A supplier performance review with Meridian covering the four half-year figures and the lead-time overrun. Where Meridian supplies a product that has a qualified alternative, model the switch, including the price and minimum-order consequences rather than reliability alone.

**Benefit.** Recovery of on-time performance on Meridian's 315 receipts, the largest importer volume in the network across all four sites.

**Risk.** Switching away from Meridian could forfeit an import price advantage and would raise minimum order quantities or lead times on the affected lines. This should not be applied to importers as a category, because the other six are not deteriorating and a category-wide response would damage supplier relationships for no measured reason.

**Dependencies and limitations.** The measurable window closes on 2025-09-30, which removes the sharpest quarter of the decline: 80.0% of importer lines ordered after that date had not arrived by the end of the data. The 2025H2 figure of 45.5% therefore rests on 33 first receipts and is the last trustworthy reading rather than the current state.

*Finding: F-05.*

### P2-2 · Clear the discontinued stock

**The problem.** 13 discontinued products still hold stock across 25 site positions, an average of 166 days after withdrawal. There is no future demand for any of it by definition.

**Evidence.** 25 positions, 1,032 units, £87,478 at weighted average cost. *(`04_analysis/03`, `05_reporting_views/07`)*

**Opportunity.** £87,478 of working capital, being tier 1 and the only tier where the whole position is releasable. Annual holding cost £19,245 at 22%, ranging £17,496 to £21,870.

This is the most certain figure in the hierarchy. It is not an upper bound in the sense the others are, because the demand claim is definitional rather than inferred.

**Action.** Clearance, return to supplier, or write-off, decided position by position. 13 positions are at Daventry, 6 at Warrington, and 3 each at Bristol and Livingston.

**Benefit.** £87,478 of capital and £19,245 a year, at the highest confidence available in this analysis.

**Risk.** None arising from demand, since the products are withdrawn.

**Priority.** Ranked 2 rather than 1 only because the sum is smaller than P1-1 and P1-2, not because the evidence is weaker. On confidence alone it would rank first.

**Dependencies and limitations.** Realisation value is unknown and the dataset cannot price it. The £87,478 is carrying value rather than recoverable cash, since clearance discounting, return terms and disposal costs all sit outside the data. This is the number leaving the balance sheet, not the number arriving in the bank.

*Finding: F-15.*

### P2-3 · Size Renewables replenishment for the demand it now has

**The problem.** The fastest-growing category in the range is being replenished on settings sized for what it used to be, and service is deteriorating as growth continues.

**Evidence.** Demand grew 85.5% from 2024Q1 to 2025Q4, with a per-quarter slope of R² = 0.64 against a next-highest category at 0.24. Renewables hold 7.4 weeks of cover against 21.7 elsewhere, on reorder points worth 4.6 weeks against 11.1, with 8.61% of weeks containing a zero-stock day against 4.75%. 2025Q4 line fill fell to 83.7% with £257,709 of unmet demand, the worst quarter of eight. Median alignment ratio is 0.81 against 0.99 network-wide. *(`04_analysis/08`, `04_analysis/16`)*

**Opportunity.** None as a capital release. This recommendation costs capital rather than releasing it. It is a service recommendation and should be read as competing with P1-2's capital release for the same balance sheet.

**Action.** Re-size Renewables reorder points to the calibrated rule at current demand, and review quarterly while the growth continues rather than on the standard cycle.

**Benefit.** Recovery of Renewables line fill from 83.7% toward the network's 92.3%. Not quantified as recovered revenue, since substitution is not modelled and the £257,709 is an upper bound.

**Risk.** Deliberately adds inventory. Renewables already hold £500,334 of closing stock on 40 positions, the highest value per position in the range.

**Dependencies and limitations, which cap the confidence.** Only 40 stocked positions exist and 31 are at Daventry, so this is a category finding resting on a single site, and that site carries its own unresolved service anomaly. The direction is clear and the breadth is not.

Age is not the mechanism. Renewables policies average 12.1 months against 11.0 elsewhere, which is essentially identical. The settings are not old, they are small.

Two years gives one year-on-year comparison. The slope is directional evidence rather than a forecast, and demand forecasting is out of scope.

*Finding: F-13.*

### P2-4 · Advance replenishment ahead of the seasonal peak

**The problem.** Shortages arrive systematically after the demand peak has passed. Stock is being ordered in response to the peak rather than ahead of it, so the shortfall lands during the recovery.

**Evidence.** In four of eight categories the peak shortage month trails the peak demand month by exactly two months. Heating and Valves peak in January and run short in March, Electrical peaks in April and runs short in June, Renewables peak in October and run short in December. Two categories show no lag and two are longer. The Warrington Heating shortage is in March rather than December, established from the data rather than assumed. *(`04_analysis/07`)*

**Opportunity.** None stated. Isolating the portion of unmet demand attributable to timing rather than to level would require a counterfactual the dataset cannot support.

**Action.** Bring the replenishment trigger forward by approximately one lead time ahead of the known seasonal peak in the four affected categories, rather than relying on the reorder point to react. For UK-manufactured Heating lines that is around one week, and for importer-sourced lines around eleven.

**Benefit.** Shortages that currently land two months after the peak arrive with stock in place.

**Risk.** Holds seasonal stock earlier and therefore longer, adding holding cost. On importer-sourced lines the eleven-week advance is substantial and interacts directly with P1-1, since buying earlier and buying at the minimum compound each other.

**Dependencies and limitations.** Two years gives one observation of each seasonal cycle. The pattern is consistent across four categories, which is what makes it a pattern rather than a coincidence, but it is not a forecast.

*Finding: F-10.*

---

## Priority 3: investigations required before action

Neither of these is a recommendation to act. Both are recommendations to find out, and both constrain action elsewhere until they are resolved.

### P3-1 · Investigate why Daventry short-ships when it has stock

**The problem.** Daventry fails to supply units in weeks when its inventory cover was adequate, at four to nine times the rate of the other three sites. If this is a picking, allocation or goods-out process problem, no inventory decision will fix it.

**Evidence.** 2.60% of units unmet in well-covered weeks, against Livingston 1.20%, Bristol 0.54% and Warrington 0.30%. 33 short weeks and £68,451 of unmet demand from positions that were not short of stock.

Every explanation tested failed. Order lumpiness does not account for it, since demand in Daventry's short weeks runs 5.45 times normal while Livingston's runs 4.73 times with a fifth of the shortfall rate. Customer mix, range mix and transfer activity were each examined and none accounts for it. *(`04_analysis/09`, `04_analysis/06`)*

**Opportunity.** Not quantifiable from this dataset. £68,451 is the unmet demand in well-covered weeks, which bounds the size of the phenomenon without measuring a recoverable amount, and it is itself an upper bound since substitution is not modelled.

**Action.** An operational investigation outside the dataset, covering goods-out picking accuracy, allocation logic when multiple orders compete for the same stock, stock accuracy between the system and the bin, and cut-off timing. The analysis has exhausted what the data can say.

**Benefit.** Unknown until the mechanism is identified, and deliberately not estimated.

**Dependencies and limitations, which constrain Priority 1.** Daventry holds £128,749 of the £468,897 identified opportunity. Until the anomaly is explained, the service consequence of reducing stock at Daventry cannot be stated with confidence. P1-1 and P1-2 should be executed at Warrington and Livingston first, and at Daventry only on tier-1 discontinued positions, where the demand claim is definitional and therefore unaffected by whatever the anomaly turns out to be.

*Finding: F-U1.*

### P3-2 · Investigate Bristol's March and April shortfall

**The problem.** Bristol's unmet demand peaks in March and April 2025 and fits neither available explanation. It is the worst-serving site in the network at 89.23% line fill, and it also shows the highest proportion of releasable stock, a combination that makes any inventory reduction there hazardous.

**Evidence.** The peak is not the opening ramp, since the site opened on 1 July 2024 and its worst months are eight months later rather than its first. It is not the general seasonal lag described in P2-4, since Bristol's peak does not sit two months after a Bristol demand peak. Bristol also carries the network's highest excess above its own policy ceiling at 39.8% of closing stock, on the smallest stock holding, because its policies are deliberately tight and reality overshoots a low bar. *(`04_analysis/11`, `04_analysis/07`)*

**Opportunity.** Not quantifiable. Bristol's total 2025 unmet demand is £216,665, but no part of it has been attributed to a mechanism.

**Action.** Investigate the March and April window specifically: what was ordered, from whom, when it arrived, and what the site had committed. Bristol's Monday-booking share is the lowest in the network at 14.3%, so the Livingston goods-inwards pattern is not the explanation here either.

**Benefit.** Unknown until the mechanism is identified. Not estimated.

**Dependencies and limitations, and this is the sharpest constraint in the document.** Bristol shows 59.1% of its closing stock as releasable, the highest share in the network, on a site already missing 10.77% of its order lines. £123,686 of the identified opportunity sits there, £106,167 of it in tier 2.

Do not execute a broad inventory reduction at Bristol. The site has an unexplained service problem and the largest apparent overstock, and acting on the second without understanding the first risks converting a capital gain into a service failure at the site least able to absorb one. Tier-1 discontinued clearance, being 3 positions and £17,096, is safe because the demand claim is definitional. Nothing else at Bristol is.

*Finding: F-U2.*

---

## What is deliberately not recommended

Stating these matters as much as the recommendations, because each is a plausible action the evidence does not support.

| Not recommended | Why |
|---|---|
| Any broad inventory reduction at Daventry or Bristol | Both carry unresolved service anomalies and together hold 53.8% of the identified opportunity. The service consequence cannot be stated. |
| Targeting old replenishment policies for review | Age does not predict availability or alignment, with an R² of 0.0044, and the oldest band is marginally the best aligned. Targeting by age would select close to randomly. |
| Treating Far East importers as a category problem | The type-level decline is one supplier. Six others are flat to improving. |
| Reclassifying the February buy-ahead as excess | Net +£145,148, with its residual carved out of every tier of the opportunity hierarchy. |
| Re-sourcing away from importers to release capital | The cheaper source is an importer in all 60 dual-source cases, worth £492,020 a year and netting £359,089. Re-sourcing forfeits more than it releases. |
| A network-wide turnover target | Site turnover is not comparable without a range-mix correction, and two valid corrections disagree. Livingston's 2.84 is real; Daventry's 4.68 is an artefact of range. |
| Treating any opportunity figure as a forecast saving | Three of four tiers are upper bounds, and realisation value on discontinued stock is unknown. |
| Adding the £1,109,016 of separate exposures | The same pounds counted up to five times. |

---

## Summary

| Priority | Recommendation | Working capital | Annual holding cost | Type |
|---|---|---:|---:|---|
| 1 | P1-1 Break the minimum-order link | £303,558 (upper bound) | £66,783 | Structural |
| 1 | P1-2 Re-set reorder points both ways | £70,755 | £15,566 | Structural |
| 2 | P2-1 Meridian supplier review | | | Supplier |
| 2 | P2-2 Clear discontinued stock | £87,478 | £19,245 | Capital |
| 2 | P2-3 Re-size Renewables | *costs capital* | | Service |
| 2 | P2-4 Advance seasonal replenishment | | | Timing |
| 3 | P3-1 Investigate Daventry | *blocking* | | Investigation |
| 3 | P3-2 Investigate Bristol | *blocking* | | Investigation |
| | **Total identified, counted once** | **£468,897** | **£103,157** | |

Tier 4, the slow-moving residual of £7,106 across 8 positions, carries no standalone recommendation. It is too small to warrant one and it is the weakest evidence in the hierarchy.

Sensitivity on the total holding cost: £93,779 at 20%, £117,225 at 25%.

£468,897 is identified, not available. £252,435 of it, being 53.8%, sits at two sites whose service behaviour is unexplained.

---

*Every figure traces to committed results in [`../analysis/query_results/`](../analysis/query_results/). Findings: [`findings.md`](findings.md).*
