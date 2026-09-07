# Findings

Seven findings, in the order the work produced them. Two of them came back weak, and both are here in full: they were the questions worth asking, and a weak answer to a good question is still worth reporting.

Everything below is an association observed in a single quarter of one fictional dataset. Nothing establishes cause. There are no campaign, offer, contact or save records in the data, so no statement is made about what any operator did or what any retention effort achieved. All monetary values are unitless.

Block-level source references for every figure are in [`technical/findings-and-evidence.md`](technical/findings-and-evidence.md).

---

## 1. The revenue exposure is bigger than the customer exposure

Of the 5,992 customers in the established base, 1,272 left during the quarter, a churn rate of 21.23%. They carried 1,232,425.80 of annual recurring revenue with them, 25.68% of the cohort's 4,799,408.40. So revenue retention comes out at 74.32% while customer retention is 78.77%.

That 4.45 point gap is arithmetic, not interpretation. It can only appear if the customers who left were, on average, worth more per month than the ones who stayed. Had leavers been a representative slice of the base, the two percentages would be the same number.

The practical consequence is that a retention plan built on headcount and one built on revenue are not looking at the same problem. Deciding which lens is in use has to come before any target is set.

Across all 7,043 customers the equivalent figures are 1,869 churned, 26.54%, and 1,669,570.20 of recurring revenue at risk. A further 519,603.72 of annual long-distance revenue is at risk and is quantified but kept out of the headline, because a retention offer holds a subscription rather than a usage volume.

Two cautions. The churn rate uses the established base and revenue at risk uses every churned customer, deliberately, so the two must not be quoted against each other's scope. And with one quarter of data there is no trend: whether 21.23% is rising or falling cannot be said, and tenure is not a substitute for a time axis.

*Source: `analyse_01_base_position.txt`.*

## 2. Revenue is only moderately concentrated

The highest-charge decile holds 16.71% of recurring revenue while holding 10.00% of customers. The top two deciles hold 31.84%, the top three 45.71%, and the bottom three 11.89%. Share falls smoothly from 16.71% down to 3.03%, a ratio of about 5.5 to 1, with no step anywhere in the curve.

That is a long way from the pattern subscription businesses often assume, where a small minority of accounts carries most of the money. Half the base holds 69.91% and the other half holds 30.09%. The absence of any discontinuity also suggests a single continuous pricing structure rather than distinct product tiers, though the data cannot confirm how the operator actually prices.

This matters mainly as a constraint on everything that follows. In a base where the top decile held 40% of revenue, concentrating retention effort there would have obvious mechanical leverage. Here it has much less, and that is worth knowing before designing any targeting.

Deciles here are equal-frequency rather than equal-value, decile 1 is the lowest charge, and the curve covers recurring revenue only, so it is not a picture of total revenue concentration.

*Source: `analyse_02_revenue_concentration.txt`.*

## 3. Churn peaks in the upper middle of the value range, not at the top

Churn by decile in the established base runs 4.07, 3.85, 15.14, 17.89, 12.93, 27.89, 32.14, 29.56, 38.96 and 24.36 for deciles 1 through 10. The peak is decile 9 at 38.96%, carrying 307,440.00 of recurring revenue at risk. Decile 10, the highest-charge customers, sits at 24.36%, below deciles 6, 7, 8 and 9. The same shape appears across all customers at a higher level throughout, so it is not an artefact of the cohort choice.

Average monthly recurring revenue for leavers and stayers sharpens the picture. In the High tier the two are 98.07 and 99.48, effectively level. In the Mid tier they are 72.16 and 67.86, and in the Low tier 31.49 and 24.62, with leavers ahead in both. The revenue-weighted effect from finding 1 is therefore coming from the middle and the bottom of the base, not the top.

Anyone planning retention work on the belief that the business is losing its best customers would be aiming at the part of the distribution where the evidence is weakest. The decile 9 concentration and the decile 10 dip are both worth understanding before that plan is written.

None of this says that charge level drives churn. Charge level travels with contract type, service mix and tenure, and this cut holds none of them constant. The decile 10 dip has no explanation here and none is offered.

*Source: `analyse_03_churn_by_decile.txt`.*

## 4. A weak result: ranking by churn and ranking by revenue give almost the same answer

This was the question the project was built around, and the answer was close to no.

Nine segments were formed by crossing value tier with contract type, then ranked twice over the same population, once by churn rate and once by annual recurring revenue at risk. Across all nine, the two rankings never disagree by more than a single place. Four segments shift by one, five do not move. The top two are the same under either ranking: High value on Month-to-Month, at 894 customers, 54.59% churn and 566,313.60 at risk, and Mid value on Month-to-Month, at 1,182 customers, 39.42% and 406,459.20.

Those two segments hold 78.93% of the established base's recurring revenue at risk between them.

The more useful fact here turned out to be the concentration rather than the divergence. Nearly four-fifths of the exposure sits in two of nine cells, and both ways of ranking find them. A team choosing between a churn-led and a revenue-led prioritisation would, on this data, arrive at the same place either way, which is worth knowing before commissioning the more complicated of the two.

Repeating the test across all customers, planned in advance as a sensitivity check, swaps the top two positions on the revenue ranking and leaves the other seven segments untouched. The result holds regardless of which population is used.

The index behind this is ordinal: a one-place difference conveys order and nothing more, and it should never be quoted without the rates, revenue figures and cell sizes underneath it. Nine cells is also a coarse partition, and a finer cut might behave differently. That was not tested, for reasons set out in [`methodology.md`](methodology.md). And since the data is fictional, this shows what the method returns rather than establishing anything about real misallocation.

*Source: `analyse_04_divergence.txt`.*

## 5. Contract type and tenure separate churn most sharply, and they overlap

Seven dimensions, chosen in advance, were cut across the 2,004 established-base customers in the High value tier, whose own churn rate is 30.89%. Each dimension splits the tier into exactly 2,004 customers.

| Dimension | Range within the High tier |
|---|---|
| Offer held | Offer A 12.11% to Offer E 71.88% |
| Tenure band | Long tenure 15.52% to first year 71.57% |
| Contract type | Two Year 5.26% to Month-to-Month 54.59% |
| Internet type | DSL 1.25% to Cable 48.65% |
| Payment method | Credit Card 19.52% to Mailed Check 44.44% |
| Service intensity | Deep 25.04% to Light 47.62% |
| Referral behaviour | Has referred 24.82% to has not referred 38.57% |

Month-to-Month customers churn far more heavily than Two Year customers here, and churn falls steadily across all four tenure bands, from 71.57% in the first year to 15.52% at long tenure. Tenure is the cleanest gradient of the seven. Both dimensions are also entangled with each other, since customers who have been around longer are more likely to be on longer contracts, and neither cut isolates an independent effect.

Referral behaviour spans 13.75 percentage points, the narrowest range of the seven. It is reported at that size rather than left out.

Offer held has the widest spread of all, and it is the least usable thing in the analysis. The data records which offer a customer holds and nothing else: no date, no reason, no outcome. If offers go to customers already thought to be at risk, the relationship runs the opposite way to the obvious reading. Until that direction is established the dimension should stay out of any prioritisation.

Five cells need their size quoted with the rate: Mailed Check at 36, Light service intensity at 42, Offer E at 64, Cable at 74 and DSL at 80. The DSL figure of 1.25% rests on one churned customer in eighty and should not be treated as a stable estimate. Where a category is absent from the High tier it is absent by construction, not because nobody in it churned.

*Source: `analyse_05_drivers_high_value.txt`.*

## 6. A weak result: the high-value tier has no driver profile of its own

Comparing the same seven dimensions between the High tier and the base as a whole, using churn indices so the two scopes' different base rates cannot manufacture a difference, the largest gap across all 24 comparisons is 0.67. Contract type, service intensity and referral behaviour all come in below 0.16 at their widest and at or below 0.10 on average. Contract type, the strongest dimension inside the tier, is among the most similar between scopes at 0.15.

Internet type is the exception, and a real one: all three of its segments move substantially and in different directions, Cable rising from 0.90 to 1.57 while Fiber Optic falls from 1.65 to 1.02 and DSL from 0.60 to 0.04.

For most dimensions, then, a base-wide driver profile describes the High tier well enough, and a separate high-value diagnostic would largely reproduce work already done. The charter flagged this possibility before any analysis ran, as a risk to the premise that high-value churn behaves distinctively. For three of the seven dimensions that risk materialised.

These are descriptive index differences with no significance testing behind them, so "large" and "small" are relative to each other and nothing else. The High tier is a subset of all customers, so this compares a part against its whole and differences are damped by construction. And the internet type exception leans on two cells of 74 and 80 customers.

*Source: `analyse_06_drivers_comparison.txt`.*

## 7. New customers behave differently enough to need separate handling

1,051 customers joined during the observation quarter and 597 of them left within it, a churn rate of 56.80% against the established base's 21.23%. They account for 31.94% of all churn events and 437,144.40 of recurring revenue at risk, 26.18% of the total.

The composition explains part of the gap. 95.43% of this group is on Month-to-Month contracts, and given the contract association in finding 5 that alone would push the rate up. Only two offer categories appear at all: Offer E at 457 customers and 61.71%, and no offer at 594 customers and 53.03%. Offers A through D are entirely absent, which suggests they attach to existing rather than new customers, though with no offer date or eligibility rule in the data that stays an inference from absence.

Around a third of all churn events and a quarter of the revenue exposure therefore sit in a population that is not answering the same question as base retention. It deserves its own analysis and probably its own owner.

Some care is needed with this group. These customers must not be folded into the established-base churn rate, since keeping numerator and denominator on one population is the point of the cohort. The month-one to month-three rates of 61.99%, 51.68% and 47.00% are not a survival curve: each month is a different intake observed for a different length of time inside a single quarter, and reading them as retention over time would be a mistake. Two contract cells fall below the reporting threshold at 26 and 22 customers, so their rates are not quoted. And there is nothing in this dataset about activation, installation, complaints, service quality or first contact, so no onboarding problem can be identified here and asserting one would be a causal claim the data cannot carry.

*Source: `analyse_07_early_life_churn.txt`.*

---

## Reconciliation

Seventeen arithmetic checks across the findings hold exactly. The cohorts sum to the base at 5,992 + 1,051 = 7,043, the churn counts at 1,272 + 597 = 1,869, and revenue at risk at 1,232,425.80 + 437,144.40 = 1,669,570.20. The primary churn rate reads 21.23% at every appearance and the all-customer 26.54% is never put in its place. Each of the seven dimensions splits the High tier into exactly 2,004 customers.

One apparent contradiction is worth naming rather than leaving for a reader to trip over. Finding 1 shows churned customers carrying above-average recurring revenue overall, while finding 3 shows High-tier leavers and stayers at near parity. Both are true: the revenue-weighted effect comes from the Mid and Low tiers. Any summary has to reflect that rather than the easier claim that the highest-value customers are the ones leaving.

Nineteen validation checks pass, including one that reads the view definitions directly and fails the build if an excluded field has reached the analytics layer.

---

*Method and definitions: [`methodology.md`](methodology.md). What follows from these findings: [`recommendations.md`](recommendations.md). Full evidence register: [`technical/findings-and-evidence.md`](technical/findings-and-evidence.md).*
