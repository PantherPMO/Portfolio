# Project 02 — Decisions Log

Judgement calls made during the build, recorded as they were made. Interviewers
probe exactly these choices.

**Project:** Warehouse Inventory & Supply Chain Performance
**Company:** Calderfield Trade Supplies Ltd — fictional. The dataset is entirely synthetic.

---

## D-01 — SQL folder structure

**Decision.** `sql/` is organised as `01_setup / 02_validation / 03_preparation /
04_analysis / 05_reporting_views`.

**Why.** `_portfolio/SQL_STANDARDS.md` documents `00_setup / 01_cleaning / 02_eda /
03_analysis / 04_kpi_views`. Project 01 shipped with a different scheme, and neither
project follows the document. Two projects agreeing is worth more than one project
matching a standard nobody uses. Validation sits ahead of preparation because there is
no sense building views on a load that has not been proved.

**Action outstanding.** `SQL_STANDARDS.md` should be updated to match, so the written
standard and the portfolio stop disagreeing.

---

## D-02 — Table names are singular

**Decision.** `product`, `sales_order_line`, `stock_movement` — not the plural
convention in `SQL_STANDARDS.md`.

**Why.** The names come from the approved data model and match the CSV file names
one-for-one. Renaming at load would break that correspondence for no analytical gain and
make the generation scripts harder to trace against the database.

---

## D-03 — Demand excludes only cancelled lines, and fulfilment is read from quantities

**Decision.** `vw_demand_line` excludes lines with `line_status = 'Cancelled'` and nothing
else. Fulfilment is computed as `quantity_ordered - quantity_despatched`, never from
`line_status`.

**Why.** `line_status` is not a fulfilment flag. A line despatched in full and later
returned carries the status `Returned`, overwriting what it said about fulfilment — 245
lines are in that state. Filtering on `line_status = 'Despatched in full'` looks like a
clean way to get good demand and discards 2,906 lines, 77,725 units and **£2,084,119 of
unmet demand** — the entire measurement the availability analysis depends on.

A cancelled line is demand withdrawn before it became a claim on stock. A line that could
not be supplied is demand the business failed to meet and belongs in the denominator.

**Evidence.** `sql/03_preparation/02_build_demand_and_fulfilment_base.sql`, section
"The cost of filtering on line_status instead of quantities".

---

## D-04 — `shelf_life_months` typed `NUMERIC(4,0)` rather than `SMALLINT`

**Decision.** Widen the column type.

**Why.** 229 of 250 products have no shelf life, so pandas wrote the column as a float and
the surviving values appear in the CSV as `24.0`. `SMALLINT` rejects them. The dataset is
frozen, so the choice is between altering source data and widening the type. Widening the
type changes nothing analytically and leaves the source file untouched.

---

## D-05 — Fixed analysis anchor dates

**Decision.** All "as at" and "months since" logic anchors to **2025-12-31**, and all
snapshot-based logic to **2025-12-28** (the last week-ending date). `CURRENT_DATE` is never
used.

**Why.** A query anchored to the clock returns a different answer every time it runs, and
the committed result CSV stops matching the query that produced it. Reproducibility is the
whole point of committing results.

---

## D-06 — Synthetic data labelling

**Decision.** Every SQL file header and every document states that Calderfield Trade
Supplies Ltd is fictional and the data synthetic. The README will carry the notice in the
summary block at the top, not in a limitations section at the bottom.

**Why.** `_portfolio/SYNTHETIC_DATA_LOG.md`: synthetic data presented as real is
portfolio-ending if discovered at interview. Every finding demonstrates method, not a fact
about any real market.

**Action outstanding.** SD-01 entry in `SYNTHETIC_DATA_LOG.md` and a `DATASET_REGISTRY.md`
entry of type Synthetic, both still to be written.

---

## D-07 — Two on-time delivery measures, both reported

**Decision.** Supplier on-time performance is reported twice: on the **first delivery**
against each purchase order line, and on **all deliveries** (on time and in full).

**Why.** 537 of 4,853 receipts (11.1%) are the second or later delivery against a line.
A split delivery counted per receipt row penalises the supplier twice for one event, and
the second drop is late by construction. The two measures differ materially — **89.8%
against 80.1%** — and quoting either alone without the other is a choice about which
answer to give.

---

## D-08 — Supplier performance must control for receiving site

**Decision.** Supplier lead-time and on-time analysis reports site-adjusted figures
alongside raw ones.

**Why.** Livingston books goods inwards in a Monday batch. **39.8% of its receipts land on
a Monday against 14–21% at the other three sites**, and its mean overrun against quoted
lead time is **14.8 days against 7.1–7.9 elsewhere**. Livingston also buys heavily from
Meridian Pacific. An uncontrolled comparison charges Meridian for up to six days of a
Livingston process. Separating the supplier problem from the process problem is the
analysis, not a footnote to it.

---

## D-09 — Transfers are excluded from demand and cost of sales

**Decision.** `Transfer out` movements are never counted as demand or as cost of sales.
Demand is `Sales issue` only.

**Why.** A transfer is stock moving between sites, not stock sold. 441 transfer pairs move
stock out of Daventry to the regional network. Counting them as Daventry demand overstates
its throughput and flatters its inventory turnover — the opposite of the range-mix
correction the analysis is trying to make.

---

## D-10 — Cost of sales valued at ledger weighted average cost

**Decision.** Cost of sales uses `stock_movement.unit_cost_gbp` — the weighted average cost
carried at the moment of issue — not `product.standard_cost_gbp`.

**Why.** Standard cost is one rate per SKU regardless of where it was bought. Import
sources are roughly 21% cheaper than UK manufacturers, so a site buying heavily from
importers genuinely carries a lower cost per unit. Valuing at standard cost erases that
difference, which is precisely the Livingston trade-off — cheaper units, far more cash —
the project exists to quantify.

---

## D-11 — Stock holding cost rate: 22% per annum

**Decision.** Working capital and holding cost figures use **22% of average inventory value
per annum**, with sensitivity reported at 20% and 25%.

### Derivation

| Component | Rate | Basis |
|---|---:|---|
| Cost of capital | 6.00% | Bank of England Bank Rate 3.75% (set 18 December 2025, unchanged at April 2026) plus an assumed 2.25 percentage point commercial borrowing margin for a private company of this size |
| Storage and handling | 8.00% | Rent, racking, utilities, warehouse labour attributable to holding rather than moving stock |
| Service costs | 3.00% | Insurance, stock-taking, inventory systems |
| Risk — damage, obsolescence, shrinkage | 5.00% | Durable, largely non-perishable building services product |
| **Total** | **22.00%** | |

### Sources

- **Bank of England**, *Bank Rate reduced to 3.75% — December 2025 Monetary Policy Summary
  and Minutes*, bankofengland.co.uk. Used for the capital cost anchor. This is the only
  component with an authoritative primary source.
- **Oracle NetSuite**, *Inventory Carrying Costs: What It Is & How to Calculate It*.
  Establishes the 20–30% industry range and the four-component framework
  (capital / storage / service / risk).
- **Harding, M. L. (2004)**, 89th Annual International Supply Management Conference — the
  component methodology for building a carrying cost rate rather than asserting one.

### Why 22% is appropriate here

The published range is 20–30%. Calderfield sits at the lower end because the range is
durable and largely non-obsolescing: 13 of 250 SKUs are discontinued and only 21 carry any
shelf life at all. Copper tube and boiler flues do not spoil. A figure near 30% would
belong to fashion, electronics or food, not building services distribution.

### Limitations — stated plainly

1. **The 20–30% range has no single primary study behind it.** It is an industry convention
   repeated across practitioner sources. It is the best available anchor, not a measured
   fact, and the analysis should not present it as one.
2. **It is not UK-distribution-specific.** No published benchmark for UK building services
   wholesale carrying cost was found.
3. **The dataset contains no cost data whatsoever** — no rent, no labour, no insurance,
   no interest. Three of the four components are entirely external assumptions that the
   data cannot corroborate or contradict.
4. **The 2.25pp borrowing margin is an assumption, not a sourced figure.**
5. **The dataset cannot validate the risk component** — see D-12.

Because three components are assumptions, every recommendation quantified using this rate
is reported with its sensitivity band, and the working capital released is always shown
alongside the holding cost saved so the reader can apply their own rate.

**Action outstanding.** `_portfolio/KPI_LIBRARY.md` marks this rate *[to source]*. It should
be updated with the figure and sources above, since KPIs are defined once at portfolio level.

---

## D-12 — Observed stock loss in the dataset exceeds real-world norms

**Finding, not a decision — but it constrains what can be claimed.**

Net stock loss in the generated data runs at **7.9% of average inventory value per year**
(6.2% from stock count adjustments, 1.8% from write-offs). Real distribution shrinkage is
typically well under 2%. The synthetic generator produced monthly count adjustments at a
rate that compounds to roughly four times a realistic figure.

The dataset is frozen and will not be regenerated.

**Consequence.** Shrinkage findings must be reported **relatively, not absolutely**. The
site comparison remains valid — Bristol loses materially more stock than the other three
sites, and that is a real, discoverable pattern. The absolute £ figure must not be
presented as a realistic loss, and any recommendation resting on recovering it must say so.
The 5% risk component of the holding cost rate in D-11 therefore comes from the published
benchmark, **not** from the dataset's own shrinkage.

---

## D-13 — Demand lines dated 29–31 December 2025

**Decision.** `vw_demand_line` uses a LEFT JOIN to `calendar_week`, retaining 133 order
lines placed after the last snapshot week with a null `week_ending_date`.

**Why.** They are real demand. Dropping them with an INNER JOIN would lose 2,099 units for
no reason other than tidiness. Week-based aggregation excludes them naturally, which is
correct, because no snapshot week covers them. The same three days carry 203 stock
movements, which are excluded from the ledger rebuild for the same reason.

---

## D-14 — Supplier delivery window closes 2025-09-30

**Decision.** Headline supplier on-time and lead-time figures use purchase orders placed on
or before 2025-09-30. The excluded quarter is reported separately with its counts.

**Why.** Importer lead times run near 78 days, so orders placed late in 2025 had not
arrived by 31 December. **77.1% of Q4 2025 importer orders have no receipt at all**,
against 8.3% for UK manufacturers. Including them computes an on-time rate only on the
orders that happened to come back early — survivorship bias that flatters exactly the
suppliers whose performance is under question.

The cost is real: it removes the sharpest quarter of Meridian Pacific's decline. Reporting
the excluded quarter separately is the honest compromise.

---

## D-15 — Supplier trend analysis runs at half-year granularity

**Decision.** Supplier performance over time is reported by half-year, not by quarter, with
receipt counts printed beside every rate.

**Why.** **33.2% of supplier-by-quarter cells hold fewer than ten receipts** (smallest cell:
one). At half-year that falls to 7.8%. A 38% on-time rate on eight deliveries is noise, and
the only defence against writing one up is to establish the cell sizes before the analysis
rather than after.

---

## D-16 — Age and cover are complementary, not independent

**Decision.** Slow-moving stock is measured by **age** (weeks since last issue) for lines
that have stopped moving, and by **cover** (weeks of stock at the trailing 13-week rate)
for lines that are still moving. The two totals are never added together.

**Why.** Cover is calculated against trailing 13-week demand, so a line that has not issued
inside that window has no cover figure at all. The cross-tabulation in
`04_analysis/03` proves it: every line with a cover figure sits in the "issued in the last
13 weeks" age band, and every older band sits entirely in "no demand to measure against".
The two measures partition the range rather than overlapping it.

I originally wrote the file believing the two populations would overlap and largely
disagree. They cannot. The band boundary was also off by one — a line last issued 13 weeks
ago sits outside a window of 12 preceding rows plus the current one — and was corrected to
12 so the two measures align exactly.

**Consequence.** Any slow-moving total must be built as a union with a stated rule, not a
sum. `04_analysis/03` uses: age over 26 weeks **or** cover over 12 months.

---

## D-17 — Excess above policy measures conformance, not adequacy

**Decision.** "Excess above the policy ceiling" (`reorder point + reorder quantity`) is
reported alongside days of cover, never instead of it.

**Why.** The measure compares each position against *its own site's rules*, so it is blind
to whether those rules are right. The 2025 closing position makes the problem plain:

| Site | Closing stock | Excess above its own ceiling | Days of cover |
|---|---:|---:|---:|
| Bristol | £209,230 | **£83,272 (39.8%)** | 51 |
| Livingston | £397,597 | £18,449 (4.6%) | **129** |

Bristol registers by far the largest excess on the smallest stock, because its policies are
deliberately tight and reality overshoots a low bar. Livingston registers almost none while
holding two and a half times Bristol's cover, because its policies authorise deep stock and
it stays inside them.

**Both are real problems and they are opposite ones.** Livingston's excess is *in* the
policy, not against it. Reporting either measure alone would name the wrong site.

**Same effect on policy age.** Lines whose policies have not been reviewed for over 15
months show *less* excess (5.3%) than currently reviewed lines (8.6%) — because a stale
policy sized for higher historical demand carries a higher ceiling and is harder to breach.
Their mean cover is nonetheless higher (23.3 weeks against 19.7). Cover is the honest
measure of the stale-policy effect; excess is not.

---

## D-18 — Excess is attributed to the source actually used, not the nominated source

**Decision.** Where excess stock is attributed to a supplier type, the attribution uses the
supplier that actually delivered into that position most recently, not the supplier
nominated as primary on `product_supplier`.

**Why.** My first version classified by nominated source and produced a conclusion that was
exactly backwards:

| Attributed by | Far East Importer | UK Manufacturer |
|---|---:|---:|
| Nominated primary source | £16,366 (12%) | £101,955 (76%) |
| **Source actually used** | **£110,495 (82%)** | £14,724 (11%) |

Where a SKU has a cheaper import alternative, the buyer may use it even though the
nominated source is a UK manufacturer with a small minimum order quantity. The stock that
arrives is then the importer's, on the importer's terms, sitting against a line the
nominated-source view labels "UK Manufacturer".

**The worked example.** PIPE-1201 at Bristol is £40,413 of the £134,701 network excess —
30% of the total in a single line. Its nominated source is Haldane, a UK manufacturer with
a minimum order quantity of 448 units at about £11.65. On 23 September 2025 the buyer
placed the order with Tanfield instead, a Far East importer at £9.78 — 16% cheaper, with a
minimum order quantity of **5,061 units**. Quarterly demand at that site is 1,547 units, so
one order bought roughly ten months of cover in a single drop.

Attributed by nominated source, that £40,413 lands against "UK Manufacturer" and the
finding points at the wrong supplier terms entirely.

**Both views are retained** in `04_analysis/04` sections 5 and 5b, because the difference
between them is itself the finding.

---

## D-19 — "Quarters observed" counts quarters with demand, not quarters trading

**Decision.** The demand slope in `04_analysis/05` is reported alongside the number of
quarters that actually carried demand, and slopes resting on fewer than six quarters are
treated as unusable.

**Why.** A quarter with no orders produces no row, so a slow-moving line can show four
quarters when the site traded for eight. At Daventry, 180 of 250 positions have all eight;
70 have fewer, one has a single quarter. Bristol has at most six by construction. A slope
fitted through four sporadic points is arithmetic, not evidence.

Reporting the count next to the slope is the whole safeguard. Without it the two look
identical on the page.

---

## D-20 — The seasonal shortage lags the demand peak, and the effect generalises

**Decision.** Seasonal availability findings name the demand peak and the shortage peak
separately, and report the operational peak (zero-stock days) apart from the commercial
peak (unmet demand value).

**Why.** The plan flagged Warrington Heating as a winter problem without fixing a month.
Measured from the data:

| Category | Demand peaks | Shortage peaks | Lag |
|---|---|---|---|
| Heating | January (index 2.14 at Warrington) | **March** | 2 months |
| Valves | January | March | 2 months |
| Renewables | October | December | 2 months |
| Electrical | April | June | 2 months |
| **Ventilation** | **July** | **August** | **1 month** |
| Drainage, Tools | October | October | 0 |

Warrington Heating zero-stock days run 0.611 per SKU-week in January, 0.736 in February and
**1.411 in March** — against 0.649 at the other three sites in the same month. November is
0.000. There is no Christmas shortage to find.

**Ventilation is what makes this a mechanism rather than a story about winter.** It peaks in
July and shorts in August. The lag appears wherever there is seasonality and disappears
where there is none, which points at replenishment response rather than at the season.

The structural reason is visible directly: correlation between the monthly demand index and
the monthly cover index is **−0.82 for Heating at Warrington**, −0.81 at Livingston, −0.76 at
Daventry, and −0.67 to −0.69 for Ventilation. Cover falls exactly when demand rises, because
policies are sized on an annual average and do not flex. Warrington's Heating reorder points
cover **0.43 of a peak month** (7 of 9 lines under half a peak month).

**Two caveats.**

1. Operational and commercial peaks differ. Warrington Heating loses most *days* in March
   but most *money* in January (£22,047 against £14,126), because January demand is 1.6
   times March's. Both belong in the write-up; neither alone is the answer.
2. **Pipe & Fittings shows a nominal 10-month lag, which is an artefact.** Its demand index
   runs 0.86 to 1.16 — no meaningful seasonality — so its "peak" month is noise, and the
   modulo-12 wrap turns a two-month lead into a ten-month lag. Categories with a demand
   index range under roughly 0.4 are treated as unseasonal and excluded from lag reporting.

---

## D-21 — Policy age does not explain availability, and the plan's mechanism is not supported

**Contradiction with the implementation plan, reported rather than resolved.**

The plan expected stale replenishment policies to be starving the growth range. Across all
515 stocked positions, policy age barely separates outcomes, and what separation exists runs
the wrong way:

| | n | Reorder point (weeks) | Cover (weeks) | Zero days 2025 | Unmet unit rate |
|---|---:|---:|---:|---:|---:|
| Policy over 15 months old | 121 | 10.2 | 23.3 | 13.48 | **6.03%** |
| Reviewed within 15 months | 394 | 10.6 | 19.7 | 12.79 | **7.80%** |

Stale policies show *better* unmet rates, not worse.

**What does separate outcomes is demand direction, and it separates them sharply:**

| Demand direction | n | Mean policy age | Reorder point (weeks) | Cover (weeks) |
|---|---:|---:|---:|---:|
| Rising | 103 | 11.0 | **5.8** | 13.1 |
| Broadly flat | 214 | 12.0 | 8.5 | 16.4 |
| Falling | 197 | 10.3 | **15.5** | 29.5 |

Reorder points are **2.7 times deeper on falling lines than on rising ones**, while mean
policy age is effectively identical across all three groups (10.3 to 12.0 months).

**The misalignment is real and large. The attribution to policy staleness is not supported.**
The reorder points were sized on an earlier demand level and have not tracked the change —
but a recent review date evidently did not cause them to track it either. Whether reviews
are happening but not changing anything, or the review date records something other than a
genuine reassessment, cannot be determined from this dataset: it holds only the current
policy and its review date, never the policy's history (charter §14, assumption 4).

**Within Renewables the picture is the opposite, on a population far too small to settle it.**
Nine stale positions show 44.3 mean zero-days against 16.2, and a 14.5% unmet unit rate
against 6.0%. Nine positions cannot outweigh 515, and the two results are reported together
rather than the convenient one being chosen.

**Consequence for files 09–17.** Policy currency should be treated as a describable
attribute of the buying process, not as an explanatory variable for availability. File 16
should test what a review actually changed — comparing reorder points against the demand
level at the review date — rather than assuming staleness is the mechanism.

---

## D-22 — Calendar-year and ISO-week totals differ by a known boundary amount

**Note, not a change of method.** Unmet demand for 2025 comes out at **£1,027,629** measured
by order date and **£1,025,038** measured by snapshot week. The £2,591 gap reconciles
exactly:

```
1,027,629  unmet by order date in calendar 2025
  -11,928  orders of 29-31 Dec 2025, after the last snapshot week (D-13)
   +9,337  orders of 29-31 Dec 2024, inside the week ending 2025-01-04
= 1,025,038  unmet by snapshot week in 2025
```

Both figures are correct for their own basis. Any report mixing the two must say which it
used; the order-date basis is preferred for commercial statements because it matches when
the customer actually asked.

---

## D-23 — Two range-mix corrections disagree, and the disagreement is the finding

**Decision.** File 10 carries both a common-basket comparison and a category-standardised
one, and reports where they diverge rather than choosing whichever is convenient.

**Why.** They detect different things:

| Site | Turns as reported | Common basket (70 SKUs) | Category standardised |
|---|---:|---:|---:|
| Bristol | 7.13 | 7.46 | **8.56** |
| Warrington | 5.63 | 6.03 | 5.65 |
| Daventry | 4.68 | **6.82** | 4.69 |
| Livingston | 2.84 | 2.84 | 2.86 |

Daventry moves 2.14 turns on the common basket and 0.01 on category standardisation.
Bristol does the reverse. The reason is that **Daventry's disadvantage is a within-category
effect, not a between-category one.** Its 145 exclusive SKUs are the slow tail inside every
category, not a concentration in slow categories, so reweighting categories cannot see them.
The common basket can, because it removes them.

Anyone running only the standard category adjustment would conclude Daventry has no
range-mix problem. That conclusion would be wrong.

**Two results that need no adjustment at all.**

- **Livingston stocks only common-basket SKUs.** All 70 of its lines are stocked at every
  other site, so both corrections leave it at 2.84 turns and 129 days. It has no range-mix
  defence available: its position is entirely its own.
- **Daventry's exclusive range turns at 3.75 against 6.82 on the shared range** — 145 SKUs
  holding 64.8% of its stock and generating 51.9% of its cost of sales.

---

## D-24 — Daventry's service anomaly survives every correction offered

**Contradiction with the file 09 working hypothesis, reported rather than resolved.**

File 09 tested four candidate explanations for Daventry short-shipping 2.60% of units in
weeks that opened with eight or more weeks of cover:

| Candidate | Result | Evidence |
|---|---|---|
| Order-size lumpiness | **Survives** | Demand in shortfall weeks is 5.45× the site's normal weekly rate (124.5 units against 22.8), against 1.87 at Warrington and 1.80 at Bristol |
| Customer mix | **Fails** | Daventry's Housebuilder share is 5.2%, second lowest. Livingston has the highest at 13.5% and the *best* unmet rate |
| Cover is a ratio — thin absolute stock | **Partially survives** | Daventry's well-covered positions hold a median 43 units against 193 at Livingston; 53.7% sit under 50 units against 17.4% |
| Transfers out draining the national DC | **Fails, in reverse** | Unmet rate in transfer weeks is 2.19% against 8.18% in other weeks — transfers mark well-stocked weeks |

**But the third candidate does not close the gap.** Holding absolute stock depth constant,
Daventry is still worse in the middle bands: 4.62% against 3.02% at 25–100 units, and 4.49%
against 0.79% at 100–500. And file 10 repeated the test on the common basket — the same 70
SKUs every site stocks — where Daventry runs **2.71% against Warrington's 0.16%**.

**What the evidence actually supports.** On the identical 70-SKU basket Daventry turns 6.82
against Livingston's 2.84, holding £291,166 while doing £1,986,113 of cost of sales; Livingston
holds £473,539 for £1,342,562. Daventry does roughly 48% more trade on those lines with 38%
less stock. Its shortfall is what running the shared range that lean costs in service.

That is a different trade, not a failure — and it is the opposite of what the implementation
plan assumed the range-mix correction would show.

---

## D-25 — Bristol's March–April shortfall fits neither explanation cleanly

**Contradiction with the revised plan for file 11, reported as found.**

Three tests, three partial answers:

| Test | Prediction if opening effect | Prediction if seasonal lag | Result |
|---|---|---|---|
| Decay with site age | Worst in months 1–3, falling | No relation to age | Unmet unit rate 17.34% (m1–3), 11.12%, **17.61%** (m7–9), 10.94%, 9.80%. Decaying overall but **not monotonically** |
| Other sites' monthly shape | Bristol alone | All sites share it | Bristol peaks March 17.2% and April 14.8% of its own year. **No other site does** — Warrington, Daventry and Livingston all peak September to December |
| Category composition | Spread across the range | Concentrated in spring-peaking categories | Drainage 28.2% of unmet (a genuine March–April demand peak) but **Pipe & Fittings 25.9%, which has no seasonality at all** |

**Neither explanation survives intact.** The March–April spike is Bristol-specific, so it is
not the network replenishment lag of D-20. It interrupts an otherwise decaying ramp, so it is
not simple maturation either. Bristol does *also* peak in October alongside every other site,
so it carries both a shared autumn pattern and an unexplained spring one.

**A further complication.** Bristol's replenishment settings are not the tightest in the
network. At the closing snapshot its reorder points cover 7.2 weeks against Warrington's 7.3,
and its policy ceiling is 17.7 weeks against Warrington's 16.7. Warrington's policies are
marginally tighter and its 2025 line fill is 93.08% against Bristol's 89.23%. The
"constrained Bristol" framing carried from the dataset design does not hold at snapshot: the
site's service gap is not explained by its policy depth.

**One thing this dataset cannot answer.** Bristol's accounts placed **zero** order lines
anywhere before the site opened — 725 lines in 2024Q3 and none before. The generator
redistributed Bristol's order *volume* to Daventry and Warrington by raising their rates
rather than by routing Bristol's *customers* through them, so the branch appears to have
opened with entirely new accounts. Real branch openings transfer demand. The "where did the
demand come from" question in the plan is therefore unanswerable here, and any statement
about demand transfer would be an artefact of the generator, not a finding. Recorded as a
synthetic-design limitation alongside D-12.

**Consequence.** Bristol's spring shortfall is left as an open question with the evidence
against both hypotheses stated, not resolved by choosing one. Files 12–15 may shed light: if
its March–April receipts show supplier delays, that is a third explanation this file could
not test.

---

## D-26 — A supplier-type trend must be leave-one-out tested before it is called a type trend

**Decision.** Every trend reported at supplier-type level is recomputed with that type's
largest supplier removed, and both figures are shown.

**Why.** Read at type level, Far East Importers appear to be deteriorating steadily:
83.6% → 77.8% → 73.1% → 56.8% on-time across the four half-years. Remove Meridian and the
type runs **72.9% → 64.3% → 66.7% → 65.9%** — a step down in 2024H2 and flat thereafter.
The apparent type-wide decline is one supplier, which happens to carry 315 of the type's
receipts.

The same test on Small Specialists shows their improvement is largely Kelso (69.2% → 87.9%
with, 82.8% → 83.3% without, on thin numbers). UK Manufacturers and UK/EU Distributors are
unchanged by removing their largest, so their type-level figures are genuinely type-level.

**Consequence.** "Importers are getting worse" would have been a false finding, and an
expensive one: it invites a sourcing-policy response to what is a single-relationship
problem.

**Within-type spread supports the same caution.** Standard deviation of supplier on-time
rates inside each type: UK Manufacturer 0.8 points, Small Specialist 4.3, UK/EU Distributor
5.8, Far East Importer 7.6. Supplier type predicts performance well for UK manufacturers and
poorly for importers, so the archetype is a much weaker unit of analysis at the import end.

---

## D-27 — Two-way effects are fitted by alternating adjustment, not by naive marginals

**Decision.** File 13 separates supplier and receiving-site contributions to lead-time
overrun by alternating adjustment — estimate site effects holding supplier effects fixed,
then supplier effects holding site effects fixed, four rounds — rather than by taking each
factor's raw marginal mean.

**Why, and it changes the answer.** The design is badly unbalanced. Daventry has 21
supplier cells above the 20-receipt threshold; Livingston has three, and 52.2% of
Livingston's modelled receipts come from importers against 7.5% of Daventry's. A raw
marginal folds that supplier mix straight into the site effect.

| Site | Cells | Importer share | Naive site effect | **Fitted site effect** | Difference |
|---|---:|---:|---:|---:|---:|
| Livingston | 3 | 52.2% | +10.1 days | **+1.8 days** | 8.3 days was supplier mix |
| Warrington | 12 | 10.5% | −0.3 | 0.0 | −0.3 |
| Bristol | 8 | 10.6% | −0.2 | −0.1 | −0.1 |
| Daventry | 21 | 7.5% | −0.5 | −0.1 | −0.4 |

Mean absolute residual falls from 0.82 days to **0.18 days** after fitting — the additive
model with fitted effects describes the data far better. Supplier effects barely move
(Meridian 18.0 → 17.7) because suppliers appear at several sites and were never badly
confounded.

**This materially revises D-08.** That decision warned that Livingston's Monday booking
would charge Meridian for a Livingston process. The direction was right and the magnitude
was wrong in both places:

- **Livingston's genuine site effect is 1.8 days, not 10.1.** Four fifths of its apparent
  lead-time problem is that it buys from importers, whose overrun is 17.7 to 22.6 days
  wherever they deliver.
- **Monday batching explains about 1.05 days** — 20.1 percentage points of excess Monday
  bookings at a 5.2-day penalty. Against a 1.8-day site effect that is **58%** of it, not
  the tenth it would be against 10.1.
- **Meridian was not being unfairly blamed.** Its mean overrun runs 22.0 days at Daventry,
  23.0 at Warrington, 24.2 at Bristol and 24.9 at Livingston — a 2.9-day spread across
  sites against an 17.7-day supplier effect. Holding site constant at Daventry alone, its
  on-time rate still falls 93.8% → 100.0% → 82.8% → 58.3% across the four half-years.

**What this cannot do.** The data is observational — sites choose their suppliers — so no
decomposition can separate the two the way an experiment would. The residual column is the
honest measure of what neither factor explains, and it is reported cell by cell.

---

## D-28 — Re-measure, never carry a number forward

**Decision.** Any figure quoted inside an analysis file is computed by that file, not
inherited from an earlier note.

**Why, and it caught an error of mine.** The file 14 header originally said that the raw
before-and-after comparison of Arden's prices returns "roughly -86%", a figure carried from a
diagnostic run during dataset generation. Measured properly in file 14, the raw method
returns **+31.7%** (mean £258.82 before, £340.83 after, 816 lines against 370). The -86%
did not reproduce, because the generation-phase check aggregated on a different basis.

The header was corrected to describe the mechanism — 67 SKUs bought before, 57 after, 57 on
both sides — and to print both methods on the same data rather than assert either figure.

**The like-for-like result reproduces exactly as expected: median +18.2%**, spread p10 17.0%
to p90 18.9%, standard deviation 0.8 points, all 57 SKUs up by more than 10%, none flat,
none down. Every other supplier over the same dates falls between −1.1% and +0.7%, so the
rise is a supplier event and not a market one.

The raw method is still wrong — it overstates by 13.5 percentage points — but it is wrong by
a different amount and in the opposite direction from what the note claimed. Repeating the
old figure would have put a fabricated number in a portfolio document.

---

## D-29 — A cheaper unit price and its working-capital cost must share a time basis

**Decision.** Where a unit-price saving is netted against a holding cost, the saving is
annualised and every column states the period it covers.

**Why.** The first version of file 14 compared the price gap on **two years** of purchase
volume against **one year** of holding cost, roughly doubling the apparent benefit. Corrected
to an annual basis:

| | Two-year basis (wrong) | Annual basis (corrected) |
|---|---:|---:|
| Price saving | £984,040 | **£492,020** |
| Extra working capital (one-off) | £604,231 | £604,231 |
| Net at 22% | £851,109 | **£359,089** |

The direction survives but the magnitude halves. A column named `years_of_saving_tied_up`
(1.23) now sits beside the net figure so the working capital is visible as a stock, not
hidden inside a flow.

**What the corrected figures show.** Across the 60 SKUs bought from two sources with at
least four lines from each, the cheaper source is a Far East importer in **every case**. The
median premium on the dearer source is around 30%, and the cheaper source carries minimum
order quantities averaging 8.8 to 10.7 times larger and lead times 43 to 47 days longer.
Buyers already favour the cheaper source on 40 of the 60; on the remaining 20 they favour
the dearer, with a £566,507 gross gap across two years.

None of this is a recommendation. It is a trade with both sides measured.

---

## D-30 — The February buy-ahead was net positive, which contradicts the expected mechanism

**Contradiction with the implementation plan, reported as found.**

The plan and the dataset design both treated the February 2025 buy-ahead as a source of
residual excess stock. The ledger does not support that.

| Measure | Value |
|---|---:|
| Arden purchase lines, 3–28 February 2025 | 88 |
| Median line quantity against that SKU's own normal | **3.20×** |
| Units ordered above normal | 12,291 |
| Purchase value of those units | £825,061 |
| Price saving captured | **£146,490** (17.8% of the excess purchase value) |
| Residual still attributable at 2025-12-28, upper bound | 359 units, **£6,971** |
| Holding cost over a mean 314 days held, at 22% | £1,341 |
| **Net at 22%** | **£145,148** |
| Net at 20% / 25% | £145,270 / £144,965 |

The stock sold through. On 82 of the 87 SKU-and-site positions, issues since the first
buy-ahead receipt exceed the excess entirely. Only five positions closed the year on more
than twelve months of cover, holding £645 between them.

**February is unmistakably a cluster** — 18,519 units ordered against 7,300 in January and
1,387 in March — but a cluster that was absorbed is not excess. The £134,701 of network
excess above policy found in file 04 traces to importer minimum order quantities on other
suppliers (D-18), not to this.

### The attribution bound, and how generous it is

Stock is valued at weighted average cost and the ledger carries no batch identity, so no unit
on the shelf can be traced to a February receipt. Three positions are therefore reported:

| Scenario | Working capital | Basis |
|---|---:|---|
| Excess fully consumed (optimistic) | £0 | Every excess unit sold |
| **Upper bound on residual** | **£6,971** | Excess less everything issued since first receipt, capped at closing stock |
| All excess still held (pessimistic) | £927,759 | Nothing sold; carried since receipt |

**The upper bound is generous to the buy-ahead**: it credits every subsequent issue against
the excess first, which is the most favourable consumption order. The pessimistic scenario is
the arithmetic opposite and is clearly false — at a full year it would cost roughly £204,000
against a £146,490 saving and turn the decision negative. The ledger says the true position
sits near the optimistic end, and the conclusion rests on that.

---

## D-31 — Policy alignment is benchmarked against the network's own working rule

**Decision.** "Aligned" means a reorder point that sits near the multiple of lead-time demand
the estate itself works to, measured at the demand the line has **now**. That multiple is not
chosen; it is calibrated in-query as the median of
`reorder_point_units / (weekly demand × lead-time weeks)` across lines whose demand is broadly
flat. It comes out at **3.05**, with a companion reorder quantity of **9.41 weeks** of demand,
on 204 calibration lines out of 467 assessed.

**Why calibrate rather than assume.** Any fixed rule — "two months' cover", "lead time plus a
month" — would be imported from outside the business and would measure the gap between
Calderfield and that rule rather than the gap between Calderfield's settings and Calderfield's
demand. Flat-demand lines are the natural reference because current demand is closest there to
the demand the settings were originally made for.

**The cost of the choice, stated plainly.** Flat lines centre on a ratio of 1.00 by
construction. They are the reference, not evidence. Every finding in file 16 lives in the
rising and falling groups, where the rule is applied rather than fitted:

| Demand direction | Lines | Median alignment ratio | Thin | In line | Deep |
|---|---:|---:|---:|---:|---:|
| Rising | 95 | **0.68** | 40 | 41 | 14 |
| Broadly flat *(calibration)* | 204 | 1.00 | 54 | 92 | 58 |
| Falling | 168 | **1.33** | 27 | 68 | 73 |

The rule detects what it was built to detect: settings on rising lines are a third below what
the estate's own practice implies, settings on falling lines a third above.

**Rejected alternative.** Benchmarking against `lead-time demand + safety_stock_units` gave a
much tighter spread (medians 0.99 to 1.20 across the three directions) because safety stock is
itself part of the policy and carries the same staleness as the reorder point. A benchmark
containing the thing being measured cannot measure it.

---

## D-32 — Policy age carries no signal about alignment either, and D-21 is extended

**Decision.** Policy age remains descriptive. D-21 established that age does not explain
availability; file 16 extends the same null to alignment, so age is not used as an
explanatory variable anywhere in the project.

**The measurement.** If a recent review meant settings matched current demand, the share in
line with the working rule would fall as age rises. It does not:

| Policy age | Lines | In line % | Thin % | Deep % | Median ratio | Mean absolute log departure |
|---|---:|---:|---:|---:|---:|---:|
| Under 6 months | 141 | 41.1 | 27.0 | 31.9 | 1.05 | 0.789 |
| 6 to 12 months | 156 | 43.6 | 27.6 | 28.8 | 0.98 | 0.754 |
| 12 to 18 months | 75 | 41.3 | 22.7 | 36.0 | 0.91 | 0.734 |
| Over 18 months | 95 | **46.3** | 24.2 | 29.5 | 0.98 | **0.700** |

The oldest band has the *highest* share in line and the *smallest* mean departure. As a
continuous association, age against absolute log departure gives a correlation of **−0.066**,
a slope of −0.0054 per month and an **R² of 0.0044** — nothing, and what little there is
points the wrong way for the original hypothesis.

**The four-way grid, all four cells populated.** Age and alignment were defined independently,
so crossing them is meaningful rather than circular:

| Review recency | Alignment | Lines | Stock | Mean cover | Unmet units % | Days at zero % |
|---|---|---:|---:|---:|---:|---:|
| Within 15 months | Aligned | 152 | £571,271 | 11.6 wks | 6.21 | 3.06 |
| Within 15 months | Misaligned | 208 | £667,649 | 23.7 wks | 9.02 | 4.06 |
| Over 15 months | Aligned | 49 | £184,260 | 12.4 wks | 5.46 | 3.53 |
| Over 15 months | Misaligned | 58 | £163,306 | 24.0 wks | 6.75 | 4.01 |

No cell falls below the ten-line reporting floor. Reading down the alignment dimension the
outcome moves sharply; reading down the recency dimension it barely moves, and moves slightly
*against* the recency hypothesis in both alignment groups.

**Category control.** Renewables carries the sharpest demand growth (+5.4% mean quarterly
slope against negative slopes everywhere else) and the thinnest settings. Holding category
constant does not rescue the age signal: recent lines beat old ones in Valves (37.3 vs 71.4),
Pipe (35.9 vs 50.0), Tools (38.5 vs 68.8) and Drainage (31.7 vs 58.3) — that is, old policies
are *more* often in line in four of eight categories. Two categories run the other way and
Ventilation's old cell (n=13, 0.0%) is too thin to read. There is no consistent direction.

**What cannot be settled.** `replenishment_policy` holds one row per SKU and site: the current
settings and one `last_reviewed_date`. The prior settings were never recorded. Nothing in this
project can say what a review changed, or that a review caused an improvement. A review that
happened and altered nothing is indistinguishable from one that reset the line completely.
The first redesign of file 16 proposed measuring the change; it was withdrawn for this reason.

---

## D-33 — Thin and deep misalignment are reported separately and never netted

**Decision.** Misalignment is split by direction throughout. A pound of holding cost and a
pound of lost margin are not the same pound and are not summed.

**Why.** Averaging the two cancels the effect. Kept apart, alignment maps onto outcome
monotonically while age does not:

| Alignment band | Lines | Stock | Mean cover | Unmet units % | Unmet value | Days at zero % |
|---|---:|---:|---:|---:|---:|---:|
| Set thin against current demand | 121 | £438,994 | 13.3 wks | **11.62** | £505,019 | **7.28** |
| In line with the network rule | 201 | £755,531 | 11.8 wks | 5.97 | £436,474 | 3.18 |
| Set deep against current demand | 145 | £391,962 | **32.4 wks** | 2.79 | £41,426 | 1.36 |

**The ordering is partly mechanical and must not be read as a ranking.** Deeper settings buy
better availability; that is what they are for. The finding is not that deep is good but that
the two failure modes are wildly asymmetric in cost. Stock standing above what the working
rule would authorise totals **£115,916**, of which £85,133 sits on deep-set lines — an annual
holding cost of **£25,502** at 22%. Unmet demand on thin-set lines over the same year is
**£505,019**. The estate's misalignment costs roughly twenty times more in service than in
capital, which reverses the direction the original plan expected.

---

## D-34 — Minimum-order attribution is a bound across the partition, not a fourth bucket

**Decision.** Closing stock is partitioned three ways — cover to the reorder point, depth
authorised by the policy ceiling, and depth above it — exhaustively and exclusively. The
minimum-order attribution is reported separately as a bound that cuts across the first two,
and is never added to them.

**The partition, which reconciles to file 04 exactly:**

| Bucket | Units | Value | Share |
|---|---:|---:|---:|
| Closing stock at 2025-12-28 | 77,492 | £1,711,042 | 100.0% |
| 1 — cover to the reorder point | 38,841 | £836,830 | 48.9% |
| 2 — authorised by the policy ceiling | 26,710 | £739,510 | 43.2% |
| 3 — above the policy ceiling *(file 04)* | 11,941 | **£134,701** | 7.9% |

Bucket 3 reproduces file 04's excess to the pound, which is the check that the partition is
the same object viewed differently rather than a new measurement.

**Why the minimum cannot be a fourth bucket.** A unit can be simultaneously inside the policy
ceiling and present only because the supplier would not sell fewer. Adding the minimum-order
attribution to buckets 1 and 2 would count those units twice, which is precisely the fan-out
the project has guarded against since D-16.

**The bound.** £336,205 of closing stock — 19.6% of the network — could still be accounted for
by the minimum on the last purchase, of which **£335,194 (99.7%) sits on positions last bought
from a Far East importer**. It is an upper bound, not an estimate: stock is fungible, valued at
weighted average cost, and no unit on the shelf carries a record of why it was bought.

---

## D-35 — A bound that ignores consumption is not a bound worth reporting

**Decision.** Where a residual is bounded, everything issued since receipt is netted off
first. The loose form is shown alongside only to demonstrate how little it says.

**Why, and it is a self-check on D-28.** D-28 requires figures to be re-derived rather than
carried forward. Re-deriving the February buy-ahead residual in file 17 first produced
**£355,381** against file 15's £6,971 — a fifty-fold disagreement. The cause was not a
contradiction between the files but a weaker method: the first attempt bounded the residual at
`LEAST(closing stock, excess units ordered)` and ignored the 27,395 units issued from those
positions since receipt. Netting issues off first reproduces **£6,971** exactly, on 8 of 87
matched positions, of which £6,432 also sits above the policy ceiling.

The lesson is that re-measurement under D-28 has to reproduce the *method*, not merely
recompute from the same tables. A number that disagrees is a prompt to find out which of the
two is wrong, and in this case it was the new one.

---

## D-36 — Working-capital opportunities are assigned by hierarchy, never summed

**Decision.** Every SKU-site stock position at 2025-12-28 is assigned to exactly one
opportunity mechanism, by testing five tiers in a fixed priority order and taking the first
match. Releasable capital is then measured by that tier's own rule and by no other.

**Why.** Each Stage 4 file measured a different exposure against the same stock, and the
exposures overlap heavily — 23 positions worth £70,857 are both slow-moving and above policy;
54.4% of high-cover positions are also minimum-order constrained; 85.4% are also
policy-authorised. Added together they give a total larger than any release could ever be:

| Stage 4 exposure | Value |
|---|---:|
| Slow-moving stock (file 03) | £123,373 |
| Excess above the policy ceiling (file 04) | £134,701 |
| Cover over 6 months (file 05) | £398,821 |
| Stock above the calibrated rule (file 16) | £115,916 |
| Minimum-order bound in closing stock (file 17) | £336,205 |
| **Naive sum** | **£1,109,016** |
| **Counted once under the hierarchy** | **£468,897** |
| Network closing stock, for scale | £1,711,042 |

The naive sum "releases" 65% of the entire estate. The hierarchy releases 27.4%.

**The order, and why it runs this way.** From the mechanism whose release is most certain to
the one whose release is least certain, so a position is always explained by the strongest
claim available rather than by the largest number:

| Tier | Mechanism | Positions | Stock | Releasable |
|---|---|---:|---:|---:|
| 1 | Discontinued or obsolete exposure | 25 | £87,478 | £87,478 |
| 2 | Importer and minimum-order structural stock | 148 | £416,075 | £303,558 |
| 3 | Above the calibrated replenishment requirement | 125 | £357,897 | £70,755 |
| 4 | Slow-moving residual | 8 | £14,373 | £7,106 |
| 5 | No identified release opportunity | 209 | £835,219 | £0 |
| | **Total** | **515** | **£1,711,042** | **£468,897** |

Tier 1 first because a discontinued product has no future demand by definition — no other
mechanism can make a stronger claim on the same units. Tier 2 above tier 3 because a supplier
minimum explains *why* a policy was overshot, and D-34 forbids counting it twice with generic
excess. Tier 3 uses the calibrated rule of D-31 rather than file 04's excess above the site's
own policy ceiling, because D-17 established that the latter measures conformance to rules
that may themselves be wrong. Tier 4 last because a slow mover is not a dead line.

**A finding, not just a method.** Of file 03's £123,373 of slow-moving stock, only **£14,373
across 8 positions** survives as an unexplained residual. The rest is absorbed by stronger
mechanisms: £23,725 is discontinued, £34,954 is minimum-order structural, £50,321 sits above
the calibrated rule. Slow-moving stock at Calderfield is very largely a *symptom* of
discontinuation and import buying, not an independent problem.

**The other finding is the size of tier 5.** 209 positions holding **£835,219 — 48.8% of the
network — carry no identified release opportunity at all**. Nearly half the estate is stock
the analysis cannot argue against, which is a constraint on how large any recommendation can
honestly be.

**Two limits on the total.** Releasable capital is a one-off; the holding cost saved
(£103,157 at 22%, £93,779 to £117,225 across the sensitivity band) is annual. They are
different clocks and are never added (D-29). And tier 2's figure is an upper bound, not an
estimate (D-34) — stock is fungible and carries no record of why it was bought.

---

## D-37 — KPI views are layered, and grain reconciliation carries a stated penny tolerance

**Decision.** Reporting views 02 and 03 read view 01 rather than recomputing turnover from
the weekly base. Reconciliation checks between grain levels pass within **£0.05**.

**Why layer.** Days inventory outstanding and stock holding cost are both functions of the
same average inventory and the same cost of sales. Recomputing them independently would
create three definitions that could drift apart under future edits — precisely the failure
the portfolio KPI library exists to prevent. View 02 additionally prints DIO computed from
the rounded turnover figure *and* from the raw components, so any rounding propagation is
visible rather than hidden.

**Why a tolerance.** Each view rounds to the penny at row level. Summing four site rows or
32 site-by-category cells therefore differs from the single network row by a few pence —
observed at £0.01 and −£0.02. The tolerance is two orders of magnitude below anything
actionable, and a genuine partitioning error would show as thousands, not pence. Reporting
these as FAIL would train the reader to ignore the check.

**Deviation from the library, documented.** The library defines DIO as `365 / turnover`. The
period here is 52 weekly snapshots spanning 364 days. The library definition is kept, and
the 364-day figure is printed beside it: the difference is 0.27%, under a quarter of a day
at 78 days of cover.

---

## D-38 — The February buy-ahead residual is carved out of every opportunity tier

**Decision.** The tight residual bound on the February 2025 Arden buy-ahead is subtracted
from releasable capital in whichever tier the position lands, and reported separately as a
known consequence rather than as an opportunity.

**Why.** D-30 established the buy-ahead was net **positive**: £146,490 of price saving
against a residual bounded at £6,971, giving £144,956 net at 22%. Classifying that residual
as recoverable working capital would count the cost of a decision that paid for itself as a
problem to be fixed, and would double-count against the saving already credited in file 15.

**Where the eight positions landed on their own merits**, after the carve-out:

| Tier | Positions | Residual units carved out | Working capital after carve-out |
|---|---:|---:|---:|
| 3 — above the calibrated rule | 6 | 246 | £3,781 |
| 4 — slow-moving residual | 1 | 97 | £143 |
| 5 — no identified opportunity | 1 | 16 | £0 |

The carve-out reproduces **£6,971** exactly against file 15 and file 17, which is the check
that the same bound is being applied and not a third variant of it (D-35).

---

## D-39 — Two unresolved service issues are carried on every opportunity row

**Decision.** Every opportunity at Daventry and Bristol carries an explicit
`unresolved_service_constraint`. Unresolved findings are stated as constraints on
interpretation and are never converted into recommendations.

**Why.** Two service problems survived Stage 4 without an explanation:

- **D-24.** Daventry short-ships 2.60% of units even in weeks when cover was adequate,
  four to nine times the other sites. Order lumpiness, customer mix, range mix and transfer
  activity were each tested and none accounts for it.
- **D-25.** Bristol's unmet demand peaks in March and April 2025 and fits neither the
  opening-ramp nor the replenishment-lag explanation cleanly.

Those two sites hold **£252,435 of the £468,897 identified opportunity — 53.8%**. Bristol in
particular shows 59.1% of its closing stock as releasable, the highest share in the network,
on a site that already misses 10.77% of its order lines. A working-capital case at either
site cannot state its service consequence with the confidence the charter requires
(§16, criterion 3), and the constraint column says so on the row rather than in a footnote
someone may not read.

This is not a recommendation to leave the stock alone. It is a statement of what the dataset
can and cannot support.

---

## D-40 — An unordered UNION ALL is not a committed result

**Decision.** Every `UNION ALL` block whose output is written to
`analysis/query_results/` carries an explicit `ORDER BY`. Where the natural sort key is a
label rather than a value, a `sort_order` integer is added inside a subquery so the reading
order is the author's and not the planner's.

**Why, and it was caught by a test rather than by reading.** Verifying Stage 5 meant
rebuilding the database from empty twice and comparing checksums. Two files differed. A third
and fourth appeared on later runs. In every case the query was correct and the numbers
identical — only the row order had moved:

| File | Symptom |
|---|---|
| `02_validation/01_row_counts_and_key_integrity.sql` | three blocks reordered; one ordered block had ties on row count with no tiebreak |
| `04_analysis/11_bristol_site_opening_performance_ramp.sql` | coverage rows swapped |
| `04_analysis/16_replenishment_policy_alignment_and_review_effectiveness.sql` | the population ladder reordered |
| `05_reporting_views/03_vw_kpi_stock_holding_cost.sql` | the rate decomposition reordered |

**Why it matters more than it looks.** SQL guarantees no row order without `ORDER BY`, and
PostgreSQL is free to change it between runs, versions and machines. A committed result that
changes between identical runs cannot be diffed, cannot be trusted as evidence, and quietly
destroys the reproducibility claim D-05 exists to protect. The numbers were never wrong; the
artefact was.

**Scope of the fix, and what was deliberately left alone.** Four files were changed, each
because it demonstrably varied. A static scan flags roughly forty more blocks that carry the
same theoretical risk, and those were **not** modified: Stage 4 is complete and the standing
instruction is to leave completed analysis files alone unless a reproducibility or
reconciliation failure requires it. Five consecutive rebuilds from empty now produce all 32
committed results byte-identical. The residual risk is real but unrealised, and is recorded
here rather than fixed silently.

**The test is now part of the method.** Reproducibility is checked by rebuilding from empty
and comparing checksums, not by re-reading the SQL. Reading the SQL would not have found any
of these four.

---

## D-41 — R10 removed from the Power BI model: a 1:1 relationship cannot be single-direction

**This is a Power BI model correction. It is not an analytical finding, and it changes no SQL,
no dataset, no committed result, no KPI definition and no recommendation.**

**Decision.** The relationship specified as **R10**, `Detail SKU Value[sku]` →
`Dim Product[sku]`, is **not built**. It was deleted from the implemented model and removed
from the required relationship list. The model has **11 required relationships (R1–R9, R11,
R12)** plus 4 optional (R13–R16), **15 in total**. **R11 is deliberately not renumbered to
R10**, so that this record and the documents that reference it stay traceable.

**Why.** R10 was specified as Many-to-one. It is not. `Dim Product` and
`vw_sku_value_position` (`Detail SKU Value`) both hold **exactly 250 rows, one per SKU,
unique on `sku`** — verified against the database:

| Object | Rows | Distinct `sku` |
|---|---:|---:|
| `supply.product` → `Dim Product` | 250 | 250 |
| `supply.vw_sku_value_position` → `Detail SKU Value` | 250 | 250 |

Power BI detects that cardinality as **one-to-one**, and a 1:1 relationship **cannot be set to
single-direction cross-filtering** — Power BI forces it to Both. That created a second filter
path into `Dim Category`, and the model refused the relationship with:

> *There are ambiguous paths between 'Fact Opportunity' and 'Dim Category':
> 'Fact Opportunity'->'Dim Product'->'Detail SKU Value'->'Dim Category' and
> 'Fact Opportunity'->'Dim Category'*

**Why removing it costs nothing.** R10 was specified to let product attributes slice the ABC /
Pareto visual. `Detail SKU Value` already reaches `Dim Category` directly through **R11**,
which remains a valid Many-to-one, single-direction relationship, and it carries its own SKU
identity. No visual, KPI, measure, page or finding in the specification depends on R10.

**The origin of the error is worth stating plainly.** The cardinality was asserted in the
implementation guide from the shape of the join key rather than from the row counts. A shared
key does not imply a many side. Where both tables are at the same grain, the relationship is
1:1 and Power BI's forced bidirectional filtering makes it a modelling hazard, not a
convenience. The three Power BI documents now carry an explicit prohibition against
recreating R10 and a troubleshooting entry for the ambiguous-path error.


---

## D-42 — Page 4 built as two pages

**This is a dashboard layout decision. It changes no measure, no visual, no finding and no SQL.**

**Decision.** The Power BI report has **six pages**, not five. `Supplier & Sourcing Performance` is
built as **4a Supplier Reliability & Lead Time** (K18–K21, P4-V1 to P4-V5) and **4b Sourcing
Economics** (K22, K23, P4-V6 to P4-V8).

**Why.** As one page it carried 6 KPI tiles and 8 visuals at 1280 × 720. That left the bottom row
**112px** of height for a scatter chart, a clustered column chart and a table. A scatter plot
cannot work in 112px — P4-V6, P4-V7 and P4-V8 were legible only in Power BI's focus mode, and the
portfolio style guide (§7) requires every page to survive as a static screenshot, because nobody
reviewing a candidate's work opens focus mode.

**And it answered two questions.** The style guide asks that every page answer one. Page 4 asked
*how reliable are our suppliers, and how long do they take?* and *what is our sourcing structure
costing us?* — different questions for different readers. The split is what the guide already
implies; the space problem resolves as a consequence rather than being the justification.

**What moved.** K18–K21 and P4-V1 to P4-V5 to 4a. K22 and K23 to 4b, beside the minimum-order and
dual-source evidence whose flow-versus-level distinction they carry. P4-V7 goes from 400 × 112 to
616 × 240 — the change that makes it a readable chart rather than a smear.

**What did not move.** Every field well, measure, colour, interaction rule and expected value is
unchanged. No number on the dashboard differs because of this.
