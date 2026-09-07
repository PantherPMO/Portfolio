# Recommendations

Eight actions, each carrying the evidence behind it and the condition that limits it.

**What these are not.** The dataset contains no campaign, offer-made, contact or save records, so no retention activity is observable and none is recommended. No return on investment, retention budget, margin, campaign cost or save rate appears here, because none can be derived from this data and inventing one would be the single most damaging thing this analysis could do. Every action below is a decision about where to direct attention and what to establish next, not an instruction to spend.

Actions are grouped by whether the evidence supports acting now, investigating first, or stopping something.

---

## Act on the evidence as it stands

### 1. Frame retention prioritisation in annual recurring revenue at risk, not customer counts

**Why.** Revenue retention is 74.32% while customer retention is 78.77% in the same population. That gap is arithmetic: it can only occur if leavers carried higher average recurring revenue than stayers. A prioritisation built on counts and one built on revenue therefore describe different exposures, and only one of them describes the commercial position.

**Evidence.** Finding 1. `analyse_01_base_position.txt`, blocks 2 and 3.

**Expected decision value.** It settles the unit of account before any target is set, which is where retention programmes most often go wrong. It also puts a size on the exposure, 1,232,425.80 in the opening cohort and 1,669,570.20 across all churned customers, that a count-based view cannot produce.

**Caution.** The two figures use different populations by design, and the rate and the revenue must not be quoted against mismatched scopes. Long-distance revenue at risk of 519,603.72 sits deliberately outside the headline, because a retention offer secures a subscription rather than a usage volume, and it should be stated wherever the headline is used rather than quietly dropped.

### 2. Concentrate the prioritisation discussion on the two Month-to-Month segments

**Why.** High value with Month-to-Month contracts and Mid value with Month-to-Month together hold 78.93% of opening-cohort recurring revenue at risk across 2,076 customers. Both rank in the top two whether the ranking is by churn rate or by revenue at risk.

**Evidence.** Finding 4. `analyse_04_divergence.txt`, blocks 1 and 2.

**Expected decision value.** It reduces a nine-segment prioritisation problem to two segments without having to choose between two competing prioritisation logics, because both logics select the same two.

**Caution.** Month-to-Month customers show substantially higher churn in this dataset, and nothing here establishes that contract type causes churn. Contract choice is plausibly related to unobserved customer characteristics, and a customer moved onto a longer contract is not thereby a customer whose churn risk has changed. Nine cells is a coarse partition and the concentration is specific to it.

### 3. Do not commission a separate high-value driver diagnostic

**Why.** Comparing the same seven dimensions between the High tier and the base as a whole, contract type, service intensity and referral behaviour all show maximum index differences below 0.16. Contract type, the strongest dimension inside the tier, is among the most similar between scopes. A base-wide driver profile describes the High tier adequately on most dimensions examined.

**Evidence.** Finding 6. `analyse_06_drivers_comparison.txt`, blocks 1 to 3.

**Expected decision value.** It avoids paying for a segment-specific analysis that the evidence says would largely reproduce the general one. This is a spending decision even though no spend is quantified here.

**Caution.** Internet type is a real exception, shifting substantially and in different directions across its three segments, and that exception rests partly on two cells of 74 and 80 customers. The comparison is between a part and its whole, so differences are attenuated by construction, and there is no significance testing behind the words large and small.

### 4. Treat early-life churn as a separate question with separate ownership

**Why.** Customers acquired within the observation quarter churn at 56.80% against the established base's 21.23%. They account for 31.94% of all churn events and 26.18% of recurring revenue at risk. 95.43% of them hold Month-to-Month contracts and only two offer categories appear among them at all.

**Evidence.** Finding 7. `analyse_07_early_life_churn.txt`, blocks 1 to 3.

**Expected decision value.** Roughly a third of churn sits in a population whose behaviour a base-retention programme is not designed to address. Separating them stops one number from being used to manage two different problems.

**Caution.** No cause has been identified and none should be asserted. The dataset holds no activation, installation, complaint, service-quality or first-contact records, so nothing here identifies an onboarding problem. The declining month-one to month-three rates are not a survival curve and must not be presented as one. This population must never be added to the opening-cohort churn KPI.

---

## Establish before acting

### 5. Resolve the direction of the offer relationship before the offer dimension is used at all

**Why.** Offer held has the widest observed churn spread of the seven dimensions, running from 12.11% to 71.88% within the High tier. Direction and assignment mechanism are unresolved. The dataset records only which offer a customer holds, with no date, no reason and no outcome, so an offer extended to a customer already considered at risk would produce exactly this pattern with the causation running the other way.

**Evidence.** Finding 5. `analyse_05_drivers_high_value.txt`, block 1.

**Expected decision value.** This is the item in the project most likely to be misread as a lever, and reading it that way would direct retention attention on the strength of a relationship whose sign is unknown. Establishing the direction converts the widest spread in the analysis from unusable into usable.

**Caution.** Resolving it requires data this dataset does not contain: offer assignment dates, eligibility rules and the state of the customer at the point the offer was made. Until that exists the dimension should not appear in a prioritisation at all, not even with a caveat attached.

### 6. Investigate the decile 9 peak and the decile 10 dip before settling a prioritisation

**Why.** Churn by value decile is not monotonic. It peaks at 38.96% in decile 9 and falls to 24.36% in decile 10, below deciles 6 through 9. Recurring revenue at risk peaks in decile 9 at 307,440.00. The same shape holds on all customers, so it is not an artefact of the cohort definition.

**Evidence.** Finding 3. `analyse_03_churn_by_decile.txt`, blocks 1 and 2.

**Expected decision value.** A prioritisation that assumes churn risk rises with customer value would aim at the wrong decile on this base. Understanding what distinguishes decile 10 would also test whether the retention position at the top of the base is genuinely stronger or merely differently composed.

**Caution.** The dip is unexplained and no explanation is offered here. It could relate to contract mix, service mix, tenure or something unobserved. Charge level coincides with churn differences; it is not shown to drive them, and it is itself correlated with dimensions this cut does not control for.

### 7. Test the divergence question at a finer segmentation before concluding the two prioritisations agree in general

**Why.** The churn-led and revenue-led rankings differ by at most one rank position across nine segments, which is close to no divergence at all. Nine cells is a coarse partition, and the result is a property of that partition.

**Evidence.** Finding 4. `analyse_04_divergence.txt`, block 2.

**Expected decision value.** The near-null result is worth knowing at this granularity and is reported as such. Whether it survives a finer cut is a different question, and answering it would either strengthen the conclusion considerably or overturn it.

**Caution.** This has to be specified before the data is re-cut, not while looking at it. Re-cutting at successively finer grains until divergence appears would manufacture a result rather than test for one, which is precisely what the fixed specification exists to prevent. It is listed here as future work for that reason.

---

## Stop

### 8. Retire the assumption that the business is losing its most valuable customers

**Why.** Within the High tier, churned customers average 98.07 in monthly recurring revenue and retained customers 99.48, near parity. The revenue-weighted effect visible in the headline arises in the Mid and Low tiers, where leavers do carry higher revenue than stayers. Churn peaks in decile 9 and falls in decile 10.

**Evidence.** Findings 1 and 3. `analyse_01_base_position.txt` block 3, `analyse_03_churn_by_decile.txt` blocks 1 and 3.

**Expected decision value.** A retention programme designed around the premise that the top of the base is leaving would be aimed at the part of the distribution where the evidence is weakest. Removing the premise is worth more than any of the positive findings above, because it prevents a confident and wrong allocation.

**Caution.** This is a statement about where churn sits in the value distribution, not a statement that the top of the base is safe. Decile 10 still churns at 24.36% and still carries 217,996.20 of recurring revenue at risk.

---

## Two things that remain open and should not be closed by assumption

**No sourced margin range exists**, so the question of what retention spend would be justified is not attempted anywhere in this project. No margin, break-even point or spend ceiling is estimated.

**No external churn benchmark was sourced.** Ofcom's telecommunications market data release was checked and confirmed not to publish churn or switching rates. The 21.23% figure is therefore never described as high or low against an industry number that does not exist in the public record.

---

*Findings: [`findings.md`](findings.md). Method and definitions: [`methodology.md`](methodology.md). Full analysis: [`case-study.md`](case-study.md).*
