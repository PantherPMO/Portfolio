# Recommendations

Eight things worth doing, with the evidence behind each and the condition that limits it.

A note on what is not here. The dataset holds no campaign, offer, contact or save records, so nothing in it observes retention activity and none is recommended. There is no return on investment, retention budget, margin, campaign cost or save rate anywhere in this document, because none can be derived from this data and putting a plausible-looking number in would undo the rest of the work. What follows is about where to direct attention and what to establish next.

---

## Worth acting on now

### 1. Measure retention in annual recurring revenue at risk, not customer counts

Revenue retention is 74.32% against customer retention of 78.77% in the same population. That gap can only exist if the customers who left were worth more per month than the ones who stayed, so a plan built on headcount and a plan built on revenue are describing different problems. Settling the unit of account first is where most retention programmes go wrong, and it also puts a size on the exposure that a count-based view cannot produce: 1,232,425.80 in the established base, 1,669,570.20 across all churned customers.

Keep the scopes straight. The churn rate uses the established base and revenue at risk uses every churned customer, so the two figures should not be quoted against each other. And the 519,603.72 of long-distance revenue at risk sits outside the headline by choice, because a retention offer holds a subscription rather than a usage volume. Say so wherever the headline appears rather than letting it drop out of sight.

*Finding 1. Source: `analyse_01_base_position.txt`.*

### 2. Focus the prioritisation on the two Month-to-Month segments

High value on Month-to-Month and Mid value on Month-to-Month hold 78.93% of the established base's recurring revenue at risk between them, across 2,076 customers. Both rank in the top two whether the ranking is by churn rate or by revenue. That turns a nine-segment problem into a two-segment one without needing to settle which ranking logic is right, since both pick the same pair.

Contract type separates churn sharply here, but nothing in this data shows it causing anything. Contract choice is likely bound up with customer characteristics the dataset never records, and moving a customer onto a longer contract is not the same as changing their risk. Nine cells is also a coarse partition, and this concentration belongs to it.

*Finding 4. Source: `analyse_04_divergence.txt`.*

### 3. Do not commission a separate high-value driver diagnostic

Contract type, service intensity and referral behaviour all differ by less than 0.16 on the churn index between the High tier and the base as a whole, and contract type, the strongest dimension inside the tier, is among the most similar of all. A base-wide driver profile already describes the High tier well enough on most dimensions, so a segment-specific study would mostly repeat work that exists.

Internet type is a genuine exception, moving substantially and in different directions across its three segments, and it rests partly on two cells of 74 and 80 customers. There is no significance testing behind any of these comparisons, and because the High tier is a subset of the base the differences are damped by construction.

*Finding 6. Source: `analyse_06_drivers_comparison.txt`.*

### 4. Give new customers their own analysis and their own owner

Customers who joined during the quarter churn at 56.80% against the established base's 21.23%, and they account for 31.94% of all churn events and 26.18% of recurring revenue at risk. 95.43% of them are on Month-to-Month contracts and only two offer categories appear among them at all. Roughly a third of churn is therefore sitting in a group that a base-retention programme is not built to address, and separating them stops one number being used to manage two different problems.

No cause has been identified for the higher rate and none should be claimed. There is nothing in this dataset about activation, installation, complaints, service quality or first contact, so no onboarding problem can be located here. The month-one to month-three rates are not a survival curve. And this group must stay out of the established-base churn rate.

*Finding 7. Source: `analyse_07_early_life_churn.txt`.*

---

## Worth establishing first

### 5. Settle which way the offer relationship runs before using it at all

Offer held spans 12.11% to 71.88% within the High tier, the widest range of any dimension, and it is the least usable thing in the analysis. The data records which offer a customer holds and nothing more: no date, no reason, no outcome. If offers are extended to customers already thought to be at risk, the relationship runs the opposite way to the obvious reading.

This is the item most likely to be mistaken for a lever, and treating it as one would direct retention effort on a relationship whose sign is unknown. Establishing the direction would turn the widest spread in the analysis from unusable into usable, but it needs data this dataset does not have: assignment dates, eligibility rules, and the state of the customer when the offer was made. Until that exists the dimension should stay out of any prioritisation entirely, not appear with a caveat attached.

*Finding 5. Source: `analyse_05_drivers_high_value.txt`.*

### 6. Understand the decile 9 peak and the decile 10 dip before settling a prioritisation

Churn by value decile is not monotonic. It peaks at 38.96% in decile 9, carrying 307,440.00 of recurring revenue at risk, then falls to 24.36% in decile 10, below deciles 6 through 9. The shape holds across all customers too, so it is not an artefact of the cohort definition.

A plan that assumes risk rises with customer value would aim at the wrong decile here. Working out what distinguishes decile 10 would also test whether the position at the top of the base is genuinely stronger or just differently composed. The dip is unexplained: it could be contract mix, service mix, tenure or something the data never records, and charge level is correlated with all of those without any of them being held constant in this cut.

*Finding 3. Source: `analyse_03_churn_by_decile.txt`.*

### 7. Test the ranking question at a finer segmentation, specified in advance

The churn-led and revenue-led rankings differ by at most one place across nine segments, which is close to no divergence at all. Nine cells is coarse, and the result belongs to that partition. Whether it survives a finer cut is a separate question, and answering it would either strengthen the conclusion considerably or overturn it.

The specification has to be written before the data is re-cut. Cutting at successively finer grains until divergence appears would produce a result rather than test for one, which is why it sits here as further work rather than as an extra section in the analysis.

*Finding 4. Source: `analyse_04_divergence.txt`.*

---

## Worth stopping

### 8. Drop the assumption that the business is losing its most valuable customers

In the High tier, leavers average 98.07 in monthly recurring revenue and stayers 99.48, effectively level. The revenue-weighted effect that shows up in the headline comes from the Mid and Low tiers, where leavers genuinely do carry more revenue than stayers. Churn peaks in decile 9 and falls in decile 10.

A programme designed around the belief that the top of the base is walking out would be pointed at the part of the value distribution where the evidence is thinnest. Removing that belief is probably worth more than any of the positive findings above, because it prevents a confident and wrong allocation.

This is a statement about where churn sits in the value distribution, not a statement that the top of the base is safe. Decile 10 still churns at 24.36% and still carries 217,996.20 of recurring revenue at risk.

*Findings 1 and 3. Sources: `analyse_01_base_position.txt`, `analyse_03_churn_by_decile.txt`.*

---

## Two questions left open

**No margin range was sourced**, so what level of retention spend would be justified is not attempted anywhere. No margin, break-even point or spend ceiling is estimated.

**No external churn benchmark was sourced.** The UK regulator's telecommunications market data release was checked and does not publish churn or switching rates. The 21.23% figure is therefore never called high or low against an industry number that is not in the public record.

---

*The findings behind these: [`findings.md`](findings.md). Method and definitions: [`methodology.md`](methodology.md). The full analysis: [`case-study.md`](case-study.md).*
