# Findings

Seven finding groups, in the order the analysis produced them. Each is set out the same way: what was observed, what it means, what it implies for a retention decision, what limits it, and where the number came from.

Two of the seven returned weak or null results. They are here at full length, in their original position, because the project was designed to test them and the result of a test is the finding whether or not it is the one that was expected.

**Standing constraints on everything below.** Every relationship reported is an association observed in a single quarter of one fictional dataset. Nothing here establishes cause. The dataset contains no campaign, offer-made, contact or save records, so retention activity is unobservable and no statement is made about what any operator did or should spend. All monetary values are unitless. No external churn benchmark is asserted, because none was sourced.

Full evidence chains, with block-level source references for every figure, are in [`technical/findings-and-evidence.md`](technical/findings-and-evidence.md).

---

## 1. Revenue exposure is larger than customer exposure

**Observed fact.** In the opening cohort of 5,992 customers, 1,272 churned, a rate of 21.23%. Annual recurring revenue at risk is 1,232,425.80, which is 25.68% of the cohort's 4,799,408.40 of recurring revenue. Revenue retention is therefore 74.32% against customer retention of 78.77%. Across all 7,043 customers the figures are 1,869 churned, 26.54%, and 1,669,570.20 of recurring revenue at risk. Annual long-distance revenue at risk is a further 519,603.72, quantified but held outside the headline.

**Interpretation.** Revenue retention sitting below customer retention is arithmetic rather than assumption: it can only happen if the customers who left carried, on average, higher recurring revenue than those who stayed. Had leavers been an average slice of the base, the two percentages would coincide.

**Business implication.** A prioritisation built on customer counts and a prioritisation built on revenue do not describe the same exposure on this data. Establishing which lens a retention discussion is using is a precondition for the discussion, not a detail within it.

**Limitation.** One quarter, so no trend, and tenure must not be substituted for a time axis. The churn rate uses the opening cohort while revenue at risk uses all churned customers, by design; quoting 1,232,425.80 beside 26.54% would be a mismatch. Annualisation is a stated convention. The 4.45 percentage point gap is not decomposed into price, service mix and tenure effects, and no such decomposition is claimed.

**Evidence.** `analyse_01_base_position.txt`, blocks 1 to 3.

---

## 2. Revenue is moderately concentrated, not sharply

**Observed fact.** The top monthly-charge decile holds 16.71% of recurring revenue while holding 10.00% of customers. The top two deciles hold 31.84%, the top three 45.71%, and the bottom three 11.89%. Revenue share falls smoothly from 16.71% to 3.03%, a ratio of roughly 5.5 to 1, with no step change anywhere in the curve.

**Interpretation.** This is well short of the pattern often assumed in subscription businesses, where a small minority of accounts carries most of the revenue. Half the base holds 69.91% and the other half holds 30.09%. The smooth decile-by-decile decline, with no discontinuity, is consistent with a single continuous pricing structure rather than distinct product tiers, though the data does not establish the operator's pricing architecture.

**Business implication.** This bounds how much a value-based targeting strategy could achieve before any targeting is designed. In a base where the top decile held 40% of revenue, concentrating retention attention there would have obvious mechanical leverage. Here it has considerably less.

**Limitation.** Deciles are equal-frequency, not equal-value, and decile 1 is the lowest charge here, since both conventions exist in practice. Concentration is measured on recurring revenue only, so this is not total revenue concentration. Static snapshot, with no statement about whether concentration is changing.

**Evidence.** `analyse_02_revenue_concentration.txt`, blocks 1 and 2.

---

## 3. Churn peaks in the upper middle of the value range, not at the top

**Observed fact.** Churn by decile in the opening cohort runs 4.07, 3.85, 15.14, 17.89, 12.93, 27.89, 32.14, 29.56, 38.96, 24.36 for deciles 1 to 10. Decile 9 is the highest at 38.96%. Decile 10 sits at 24.36%, lower than deciles 6, 7, 8 and 9. Recurring revenue at risk peaks at decile 9 with 307,440.00. The same shape holds on all customers, at a higher level throughout.

Within value tiers, average monthly recurring revenue for churned and retained customers is 98.07 against 99.48 in the High tier, 72.16 against 67.86 in the Mid tier, and 31.49 against 24.62 in the Low tier.

**Interpretation.** Churn is not monotonically increasing with customer value. It rises through the middle of the distribution, peaks at decile 9 and falls at decile 10. The tier figures refine finding 1 in a way that matters: within the High tier, leavers and stayers carry almost identical recurring revenue, so the revenue-weighted effect seen in finding 1 arises principally in the Mid and Low tiers, where leavers do carry more revenue than stayers.

**Business implication.** The claim that the business is losing its most valuable customers is not what this data shows, and a retention programme designed on that premise would be aimed at the wrong part of the base. The decile 9 concentration and the decile 10 dip are both worth investigating before a prioritisation is settled.

**Limitation.** Association only. Charge level coincides with churn rate differences; nothing establishes that it drives them, and charge level is itself correlated with contract type, service mix and tenure, none of which is controlled for in this cut. Deciles are relative, not absolute price bands. The decile 10 dip is unexplained and no explanation is offered.

**Evidence.** `analyse_03_churn_by_decile.txt`, blocks 1 to 3.

---

## 4. Weak result: a churn-led and a revenue-led prioritisation reach almost the same answer

This was the central construct of the project. It returned a near-null result, and that is the finding.

**Observed fact.** Nine segments were formed by crossing value tier with contract type and ranked twice over the same population, once by churn rate and once by annual recurring revenue at risk. The maximum absolute difference between the two rankings across all nine segments is one rank position. Four segments differ by one place, five do not move at all. The top two are identical under both rankings: High value with Month-to-Month contracts, at n = 894, 54.59% churn and 566,313.60 at risk, and Mid value with Month-to-Month, at n = 1,182, 39.42% and 406,459.20.

Those two segments together hold 78.93% of opening-cohort recurring revenue at risk.

Repeating the test on all customers, designated a sensitivity analysis before results were seen, swaps the top two positions on the revenue ranking and leaves the other seven segments unchanged.

**Interpretation.** The project was designed to test whether prioritising by churn rate would materially diverge from prioritising by revenue at risk. On this population, at this segmentation granularity, it does not. The substantive positional fact is not the divergence but its absence alongside the concentration: nearly four-fifths of the revenue exposure sits in two of nine cells, and both prioritisation logics find them.

The sensitivity result is worth its place. It shows the primary result is robust to the population decision, which can be demonstrated only because that decision was locked before either result existed.

**Business implication.** On this evidence, the choice between a churn-led and a revenue-led prioritisation would not materially change which segments receive attention. That is a useful thing for a decision-maker to know before commissioning work to build the more complex of the two.

**Limitation.** The divergence index is ordinal. A difference of one rank conveys order only and must never be quoted without the underlying rates, revenue figures and cell sizes. Nine cells is a coarse partition and the result is specific to it; divergence could differ at a finer grain, which was not tested, because testing it now would be a specification change made after seeing the result. Any divergence or its absence is a property of the data-generation logic behind a fictional dataset, so this demonstrates that the method works and what it returns, not that misallocation does or does not exist anywhere real.

**Evidence.** `analyse_04_divergence.txt`, blocks 1 to 4.

---

## 5. Within the high-value tier, contract type and tenure separate churn most widely

**Observed fact.** Seven dimensions, named in advance, were cut across the 2,004 opening-cohort customers in the High value tier, whose churn rate is 30.89%. Each dimension partitions the tier to exactly 2,004 customers. The range within each:

| Dimension | Range within the High tier |
|---|---|
| Offer held | Offer A 12.11% to Offer E 71.88% |
| Tenure band | Long tenure 15.52% to first year 71.57% |
| Contract type | Two Year 5.26% to Month-to-Month 54.59% |
| Internet type | DSL 1.25% to Cable 48.65% |
| Payment method | Credit Card 19.52% to Mailed Check 44.44% |
| Service intensity | Deep 25.04% to Light 47.62% |
| Referral behaviour | Has referred 24.82% to has not referred 38.57% |

Tenure band declines monotonically across all four of its bands, from 71.57% in the first year to 15.52% at long tenure. Referral behaviour spans 13.75 percentage points, the narrowest of the seven, and is reported at that magnitude rather than omitted.

**Interpretation.** Month-to-Month customers show substantially higher churn in this dataset than customers on longer contracts, and the same holds for shorter-tenure customers against longer-tenure ones. These are the two dimensions most strongly associated with churn within the tier. They are also heavily interrelated, since long-tenure customers are more likely to hold long contracts, and neither cut isolates an independent contribution.

Offer held has the widest observed churn spread of the seven, but direction and assignment mechanism are unresolved. The dataset records only which offer a customer holds, with no date, no reason and no outcome. If offers are extended to customers already considered at risk, the association runs opposite to the intuitive reading. This is the most easily misread item in the project and warrants investigation of direction before it is discussed at all.

**Business implication.** Contractual commitment and relationship length are the dimensions that would most naturally frame a retention conversation on this base, with the caution that they overlap and that neither is shown to be a lever. The offer dimension is not usable for prioritisation until its direction is established.

**Limitation.** All seven are single-dimension cuts with no multivariate control. Five cells need their size quoted alongside the rate: Mailed Check at 36, Light service intensity at 42, Offer E at 64, Cable at 74 and DSL at 80. The DSL rate of 1.25% rests on a single churned customer in 80 and is not a stable estimate. Structural absences are not zero results: categories that cannot appear in the High tier by construction are absent for that reason, not because their churn is zero.

**Evidence.** `analyse_05_drivers_high_value.txt`, block 1.

---

## 6. Weak result: the high-value tier is not characterised by a distinctive driver profile

**Observed fact.** The same seven dimensions were compared between the High tier and the base as a whole, using churn indices rather than raw rates so that the two scopes' differing base rates do not manufacture differences. Across all 24 comparisons the largest single index difference is 0.67. Contract type, service intensity and referral behaviour all show maximum differences below 0.16 and mean differences at or below 0.10. Contract type, the strongest dimension inside the tier, shows one of the smallest differences between scopes at 0.15. Internet type is the clear exception: all three of its segments shift substantially and in different directions, Cable rising from 0.90 to 1.57 while Fiber Optic falls from 1.65 to 1.02 and DSL from 0.60 to 0.04.

**Interpretation.** For most dimensions examined, a base-wide driver profile would describe the High tier adequately and a separate high-value analysis adds little. This partially realises a risk stated in the project charter before any analysis ran: that if high-value churn drivers proved identical to base-wide drivers, the project's central premise would weaken. For three of the seven dimensions that condition is substantially met.

**Business implication.** Whether high-value customers need a distinct diagnostic treatment is now an evidence-based question rather than an assumption, and on most dimensions the answer here is no. That bears directly on whether segment-specific analysis is worth commissioning, which is a spending decision even though no spend is quantified.

**Limitation.** These are descriptive index differences with no significance testing and no confidence intervals, so large and small are relative to each other rather than to any threshold. The High tier is a subset of all customers, so this compares a part with its whole and differences are attenuated by construction. The internet type exception rests partly on two caveat-flagged cells of 74 and 80 customers.

**Evidence.** `analyse_06_drivers_comparison.txt`, blocks 1 to 3.

---

## 7. Newly acquired customers behave differently enough to need separate treatment

**Observed fact.** 1,051 customers were acquired within the observation quarter and 597 of them churned, a rate of 56.80% against the opening cohort's 21.23%. These 597 represent 31.94% of all churn events and 437,144.40 of recurring revenue at risk, 26.18% of the total. 95.43% of the cohort holds Month-to-Month contracts. Only two offer categories appear at all: Offer E at 457 customers and 61.71%, and no offer at 594 customers and 53.03%. Offers A through D are entirely absent.

**Interpretation.** This population behaves differently enough from the established base that combining them into a single churn rate would describe neither. The Month-to-Month concentration is consistent with new customers typically starting on rolling terms, and that composition alone would produce a higher aggregate rate given the contract association in finding 5. The absence of Offers A through D is an inference from absence: it suggests those offers are associated with existing rather than new customers, but the dataset has no offer date, eligibility rule or assignment logic, so no conclusion about offer policy is available.

**Business implication.** Roughly a third of churn events and a quarter of the recurring revenue exposure sit in a population that is not answering the same question as base retention. It warrants separate analytical attention and plausibly separate ownership.

**Limitation.** This population must never be merged into the opening-cohort churn KPI; keeping the numerator and denominator on the same population is the reason the cohort exists. The month-one to month-three rates of 61.99%, 51.68% and 47.00% are not a survival curve: each month is a different acquisition group observed for a different length of time within a single quarter, and reading them as retention over time would be a methodological error. Two contract cells sit below the reporting threshold at 26 and 22 customers and their rates are not quoted. The dataset holds no activation, installation, complaint, service-quality or first-contact records, so nothing here identifies an onboarding problem and asserting one would be an unsupported causal claim.

**Evidence.** `analyse_07_early_life_churn.txt`, blocks 1 to 3.

---

## Reconciliation

Seventeen cross-finding arithmetic checks hold exactly. The cohorts sum to the base at 5,992 + 1,051 = 7,043, the churn counts at 1,272 + 597 = 1,869, and revenue at risk at 1,232,425.80 + 437,144.40 = 1,669,570.20. The primary churn KPI is 21.23% at every appearance and the all-customer rate of 26.54% is never substituted for it. Each of the seven driver dimensions partitions the High tier to exactly 2,004 customers.

One point of apparent tension is stated here rather than left for a reader to find. Finding 1 shows churned customers carrying above-average recurring revenue overall, while finding 3 shows High-tier leavers and stayers at near parity. These are consistent: the revenue-weighted effect arises in the Mid and Low tiers. Any narrative must reflect that rather than the simpler claim that the highest-value customers are the ones leaving.

Nineteen analysis validation checks pass, including one that scans view definitions directly and fails the build if a prohibited field has reached the analytics layer.

---

*Method: [`methodology.md`](methodology.md). Actions: [`recommendations.md`](recommendations.md). Full evidence register: [`technical/findings-and-evidence.md`](technical/findings-and-evidence.md).*
