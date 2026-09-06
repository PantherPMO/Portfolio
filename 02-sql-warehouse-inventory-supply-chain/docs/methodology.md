# Methodology

> Calderfield Trade Supplies Ltd is fictional and the dataset is synthetic. Every pattern in the data was placed there by a documented generator (`scripts/calderfield_dataset_generator.py`, seed 20240101). The deliverable is the analytical method.

**Tool:** PostgreSQL 16. Python was used only to generate the dataset, never to analyse it.

---

## 1. Pipeline structure

35 SQL files run in dependency order, from an empty database to a committed answer.

```
01_setup/        3 files   Schema with constraints enforced, CSV load, indexes
02_validation/   4 files   Row counts, referential integrity, ledger rebuild, coverage profile
03_preparation/  4 files   Four base views every later file reads
04_analysis/    17 files   One analytical question per file, one committed result each
05_reporting/    7 files   Six KPI views plus the working-capital opportunity hierarchy
```

32 of the 35 write a committed text result to `analysis/query_results/`. The three that do not are the setup files, whose output is the database itself.

Nothing downstream re-derives what an upstream file already computed. The four preparation views are read by every analysis file, and reporting views 02 and 03 read reporting view 01 rather than recomputing turnover. There is therefore one definition of average inventory and one of cost of sales in the entire project.

## 2. Fixed dates

Every date is pinned: 2025-12-31 for analysis, 2025-12-28 for snapshot logic, and 2025-09-30 for the supplier measurement window. `CURRENT_DATE` is never used.

A committed result computed against `CURRENT_DATE` stops matching the file that produced it the day after it is written. Pinning the dates is what makes a result reproducible evidence rather than a snapshot of a moment.

## 3. Validation before analysis

Four validation files run before any analytical question is asked.

**Constraints are enforced at load**, so a bad load fails rather than passing quietly. All 15 tables carry primary keys, foreign keys and check constraints. One column had to be widened, `shelf_life_months` from `SMALLINT` to `NUMERIC(4,0)` because the source carries values like "18.0", and that is recorded rather than worked around with a cast.

**Every weekly stock position is rebuilt from the movement ledger alone** and compared against the snapshot table. This establishes that the inventory figures underpinning the analysis are internally consistent rather than merely present.

**Coverage is profiled before analysing rather than after.** The coverage file establishes which breakdowns the data can carry. It found that 33.2% of supplier-by-quarter cells hold fewer than ten receipts, which is why every supplier trend runs at half-year granularity with counts printed beside each rate. Discovering that after writing the analysis would have meant discarding it.

## 4. The four preparation views

| View | Grain | What it settles |
|---|---|---|
| `vw_customer_resolved` | Customer | 31 duplicate account groups; 500 accounts resolve to 469 customers |
| `vw_demand_line` | Sales order line | Fulfilment from quantities, cancelled lines excluded, nothing else |
| `vw_receipt_performance` | Goods receipt line | Every receipt kept, including the unmeasurable ones, with flags |
| `mv_inventory_week` | Product × site × week | 51,220 rows carrying stock, demand, trailing windows and policy |

`mv_inventory_week` is a materialised view with a unique index, since it is read by almost every analysis file and rebuilding it per query would be wasteful.

Denominators are never reduced by a `WHERE` clause. `vw_receipt_performance` retains all 4,853 receipts, including the 112 that cannot be measured for lateness, and carries `is_measurable` as a flag so the population stays visible. Filtering them out would have improved the on-time rate by hiding what it excluded.

## 5. Six decisions that shaped the answers

These are the places where an obvious approach would have produced a confidently wrong number.

### 5.1 Average inventory, never closing

Closing stock at 2025-12-28 is 16.3% below the 52-week average, because importer receipts arrive in a sawtooth and the year ends in a trough. Turnover on closing stock reports 5.58 against the correct 4.67, a 19% flattery. Reporting view 01 prints both figures side by side as a standing guard.

### 5.2 Fulfilment from quantities, never from order status

A line despatched in full and later returned carries the status `Returned`, which overwrites what it said about fulfilment. Filtering demand on `line_status = 'Despatched in full'` discards 1,397 lines in 2025 and the entire £1,027,629 of unmet demand, which is the whole measurement.

Demand excludes cancelled lines and nothing else. Cancelled demand was withdrawn before it became a claim on stock, whereas unsupplied demand is demand the business failed to meet and belongs in the denominator. Reporting view 04 prints what a status filter would cost, permanently.

### 5.3 Cost of sales at ledger weighted average cost

Valued at the weighted average cost carried at the moment of issue, not at standard cost. Standard cost is one rate per product regardless of source, which erases the roughly 21% import price advantage. That advantage is precisely the trade-off the analysis needs to quantify.

Transfers are never counted as demand or cost of sales. 441 transfer pairs move stock out of Daventry, and counting them would flatter the site the range-mix analysis exists to assess honestly.

### 5.4 Attribution to the source actually used

Attributing excess stock to each product's nominated primary supplier put 76% of it on UK manufacturers. Attributing it to the source actually used on the most recent receipt moves 82% of it to Far East importers, reversing the conclusion completely.

This became a standing rule. Every minimum order quantity and lead time belongs to the source actually used, resolved with `DISTINCT ON` so a repeatedly replenished product cannot fan out.

### 5.5 Overlapping exposures counted once, never summed

23 positions worth £70,857 are both slow-moving and above policy. 54.4% of high-cover positions are also minimum-order constrained, and 85.4% are also policy-authorised.

Summing the five exposures gives £1,109,016, which is 65% of an estate holding £1,711,042: the same pounds counted up to five times. The opportunity view instead assigns each of the 515 positions to exactly one mechanism by testing five tiers in priority order, and validates that the tiers sum to closing stock to the penny.

### 5.6 A price saving and its working capital must share a time basis

The dual-source comparison originally set a two-year price saving against a one-year holding cost, roughly doubling the apparent benefit. Corrected to an annual basis it halved from £851,109 to £359,089. The direction survived and the magnitude did not.

Throughout the project, working capital released is a one-off and holding cost saved is annual, and the two are never added.

## 6. Techniques used where simpler ones would have misled

### Calibrating a benchmark rather than importing one

Judging replenishment settings needs a standard. Any fixed rule, whether two months' cover or lead time plus a month, would measure the gap between Calderfield and that rule rather than between Calderfield's settings and Calderfield's demand.

The rule is instead derived from the data: the median multiple of lead-time demand at which reorder points sit, across lines whose demand is broadly flat and whose settings are therefore closest to still fitting. That comes out at 3.05 times, and is then applied to every line at its current demand.

The cost of this choice is stated rather than hidden. Flat lines centre on 1.00 by construction, so they are the reference rather than evidence, and every finding lives in the rising and falling groups where the rule is applied rather than fitted.

A rejected alternative is recorded. Benchmarking against lead-time demand plus the policy's own safety stock gave a much tighter spread, because safety stock is itself part of the policy and carries the same staleness. A benchmark containing the thing being measured cannot measure it.

### Alternating adjustment for an unbalanced two-way design

Livingston books goods inwards in a Monday batch and also buys heavily from Meridian, so the two effects are confounded and the supplier by site design is unbalanced.

Naive marginals attribute +10.1 days to Livingston. An iterative two-way fit, four rounds of chained CTEs alternately adjusting supplier and site effects, attributes +1.8 days. The naive figure overstates by more than five times and would charge a Livingston process for a supplier's lead time.

### Leave-one-out testing before claiming a category trend

Far East importers appear to decline from 83.6% to 56.8% on-time. Removing the largest supplier shows the remaining six at 72.9%, 64.3%, 66.7% and 65.9%: flat to improving. The type trend is one supplier. Any claim about a supplier category is now leave-one-out tested before it is made.

### Two range-mix corrections that disagree

145 of 250 products are stocked only at Daventry, so raw site turnover compares different businesses. Two corrections were applied: restriction to the 70-product common basket, and indirect standardisation reweighting each site to the network category mix.

They disagree, with common-basket moving Bristol +0.33 and mix-standardisation +1.43, and the disagreement is reported as the finding rather than one being chosen. They answer different questions and neither is the corrected number.

### Like-for-like comparison to avoid a mix effect

Arden's raw before-and-after average price comparison returns +31.7% and is invalid, because 67 products were bought before the change and 57 after, so the mix moved. Like-for-like at product level across the 57 bought on both sides gives a median of +18.2%, p10 17.0% to p90 18.9%, with every other supplier over the same dates between −1.1% and +0.7%. Both methods are printed on the same data.

### Bounds stated as bounds, and netted of consumption

Stock is fungible and valued at weighted average cost, and no unit on a shelf records why it was bought. Where a mechanism is attributed to standing stock, the figure is the most it could be.

Re-deriving the February buy-ahead residual produced £355,381 on the first attempt against the committed £6,971. The cause was a weaker method rather than a contradiction: the first attempt ignored the 27,395 units issued since receipt. A bound that ignores consumption is not a useful bound. Both are printed side by side so the difference is visible.

## 7. Traps identified before analysis began

Thirteen were identified in the project charter and each is handled structurally rather than remembered.

| Trap | Handling |
|---|---|
| Filtering demand on order status | Fulfilment from quantities; reporting view 04 prints the cost permanently |
| Dividing Bristol by 104 weeks when it has 78 | Site comparison on 2025 only |
| Reporting one stockout number | Three measures travel together everywhere |
| Blaming Meridian for Livingston's Monday batch | Receiving site held constant, then fitted |
| Arden's raw price comparison | Like-for-like per product only |
| Turnover on closing stock | Average of 52 weekly snapshots |
| Ranking sites on raw turnover | Range-mix adjusted comparison, two ways |
| Assuming Warrington's Heating shortage is in December | Validated from the data; it is March |
| Cost of sales at standard cost | Ledger weighted average cost |
| Counting transfers as demand | Sales issues only |
| Supplier trends by quarter | Half-year with sample sizes printed |
| Fanning out receipts against order lines | Receipts pre-aggregated before comparison |
| Treating unmet demand as lost sales | Reported as an upper bound throughout |

## 8. Reproducibility

The pipeline rebuilds from an empty database with zero failures, and all 35 files run clean in dependency order.

Committed results are byte-identical across repeated rebuilds. This was verified by dropping the database, rebuilding, and comparing checksums five consecutive times.

That test found a defect that reading the SQL would not have caught. Four files contained `UNION ALL` blocks with no `ORDER BY`. The numbers were always correct and only the row order moved between runs, but SQL guarantees no ordering without `ORDER BY`, and a committed result that changes between identical runs cannot be diffed or cited. All four were given explicit sort keys.

A static scan flags roughly forty further blocks carrying the same theoretical risk. None varied across five rebuilds, so they were left alone and the residual risk is recorded rather than fixed silently.

Reproducibility is checked by rebuilding and comparing checksums rather than by re-reading the SQL.

## 9. Working practice

**Every result is committed.** 32 text files in `analysis/query_results/`, regenerated by the pipeline and diffable.

**Denominators and sample sizes are printed beside every rate.** Cells below ten observations are marked as thin and carry no interpretation.

**Reconciliation is built into the files rather than performed afterwards.** Each reporting view contains explicit pass and fail checks against its analysis source, 26 across the seven files, all passing. The opportunity view proves its five tiers sum to closing stock to the penny, and that its third tier reproduces the excess figure from file 04 exactly.

**Findings are classified by the kind of claim they are** (supported, quantified, upper bound, assumption, unresolved, rejected) because presenting them as one list would imply they carry equal weight. Two findings remain unresolved and are recorded as such rather than explained away.

## 10. What the method cannot do

- **No forecasting.** Two years gives one year-on-year comparison. Every slope is reported with the number of quarters behind it, and a slope is directional evidence rather than a trend estimate.
- **No causal claims from observational structure.** The receiving-site effect is association. The dataset cannot show the Monday batch causes the delay.
- **No policy history.** The policy table holds current settings and one review date. What a review changed cannot be measured, and a design that proposed to was withdrawn.
- **No substitution model.** Unmet demand is an upper bound on lost revenue.
- **No cost data.** Three of the four components of the holding rate are external assumptions the dataset cannot corroborate, and no implementation cost can be estimated, which is why no return on investment is stated.
- **Shrinkage is not realistic.** Observed stock loss runs at 7.9% of average inventory a year against a real-world norm well under 2%, which is an artefact of the generator in a frozen dataset. It is reported comparatively between sites and never as an absolute.

---

*Findings: [`findings.md`](findings.md). The full decision record is in [`technical/analytical-decisions.md`](technical/analytical-decisions.md).*
