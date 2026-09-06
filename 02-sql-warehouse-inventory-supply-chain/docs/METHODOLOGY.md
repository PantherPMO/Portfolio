# Methodology — Project 02: Warehouse Inventory & Supply Chain Performance

> **Calderfield Trade Supplies Ltd is fictional and this dataset is synthetic.** Every pattern in
> the data was placed there by a documented generator (`scripts/calderfield_dataset_generator.py`,
> seed 20240101). The deliverable is the analytical method.

**Tool:** PostgreSQL 16. Python was used only to generate the dataset, never to analyse it.

---

## 1. The shape of the pipeline

35 SQL files run in dependency order, from an empty database to a committed answer.

```
01_setup/        3 files   Schema with constraints enforced, CSV load, indexes
02_validation/   4 files   Row counts, referential integrity, ledger rebuild, coverage profile
03_preparation/  4 files   Four base views every later file reads
04_analysis/    17 files   One analytical question per file, one committed result each
05_reporting/    7 files   Six KPI views plus the working-capital opportunity hierarchy
```

32 of the 35 write a committed text result to `analysis/query_results/`. The three that do not
are the setup files, whose output is the database itself.

**Nothing downstream re-derives what an upstream file already computed.** The four preparation
views are read by every analysis file; reporting views 02 and 03 read reporting view 01 rather
than recomputing turnover, so there is one definition of average inventory and one of cost of
sales in the entire project (D-37).

---

## 2. Fixed dates, never `CURRENT_DATE`

Every date in the project is pinned: **2025-12-31** for analysis, **2025-12-28** for snapshot
logic, **2025-09-30** for the supplier measurement window (D-05, D-14).

A committed result computed against `CURRENT_DATE` stops matching the file that produced it the
day after it is written. Pinning the dates is what makes a result a piece of evidence rather than
a snapshot of a moment.

---

## 3. Validation before analysis, not after

Four validation files run before any analytical question is asked.

**Constraints are enforced at load, so a bad load fails rather than passes quietly.** All 15
tables carry primary keys, foreign keys and check constraints. One column had to be widened —
`shelf_life_months` from `SMALLINT` to `NUMERIC(4,0)` because the source carries "18.0" — and that
is recorded (D-04) rather than worked around with a cast.

**Every weekly stock position is rebuilt from the movement ledger alone** and compared against
the snapshot table. This is the check that matters most: it proves the inventory figures the
whole project rests on are internally consistent rather than merely present.

**Coverage is profiled before analysing, not after.** `04_coverage_and_cell_size_profile.sql`
establishes which breakdowns the data can carry. It found that **33.2% of supplier-by-quarter
cells hold fewer than ten receipts**, which is why every supplier trend in this project runs at
half-year granularity with counts printed beside each rate (D-15). Discovering that after writing
the analysis would have meant discarding it.

---

## 4. The four preparation views

| View | Grain | What it settles |
|---|---|---|
| `vw_customer_resolved` | Customer | 31 duplicate account groups; 500 accounts resolve to 469 customers |
| `vw_demand_line` | Sales order line | Fulfilment from quantities, cancelled lines excluded, nothing else |
| `vw_receipt_performance` | Goods receipt line | Every receipt kept, including the unmeasurable ones, with flags |
| `mv_inventory_week` | SKU × site × week | 51,220 rows carrying stock, demand, trailing windows and policy |

`mv_inventory_week` is a materialised view with a unique index — it is read by almost every
analysis file and rebuilding it per query would be wasteful.

**Denominators are never reduced by a `WHERE` clause.** `vw_receipt_performance` retains all
4,853 receipts including the 112 that cannot be measured for lateness, and carries `is_measurable`
as a flag. The population is therefore always visible. Filtering them out would have made the
on-time rate look better by hiding what it excluded.

---

## 5. Six methodological rules that shaped the answers

These are the decisions where an obvious approach would have produced a confidently wrong number.

### 5.1 Average inventory, never closing (D-10)

Closing stock at 2025-12-28 is **16.3% below** the 52-week average, because importer receipts
arrive in a sawtooth and the year ends in a trough. Turnover on closing stock reports **5.58**
against the correct **4.67** — a 19% flattery. Reporting view 01 prints both figures side by side
as a standing guard.

### 5.2 Fulfilment from quantities, never from `line_status` (D-03)

A line despatched in full and later returned carries the status `Returned`, which overwrites what
it said about fulfilment. Filtering demand on `line_status = 'Despatched in full'` discards 1,397
lines in 2025 and **the entire £1,027,629 of unmet demand** — the whole measurement. Demand
excludes `Cancelled` lines and nothing else: cancelled demand was withdrawn before it became a
claim on stock; unsupplied demand is demand the business failed to meet and belongs in the
denominator. Reporting view 04 prints what a status filter would cost, permanently.

### 5.3 Cost of sales at ledger weighted average cost (D-09, D-10)

Valued at `stock_movement.unit_cost_gbp` — the weighted average cost carried at the moment of
issue — not at `product.standard_cost_gbp`. Standard cost is one rate per SKU regardless of
source, which erases the roughly 21% import price advantage. That advantage is precisely the
trade-off the project exists to quantify.

Transfers are never counted as demand or cost of sales. 441 transfer pairs move stock out of
Daventry; counting them would flatter the site the range-mix analysis exists to assess honestly.

### 5.4 Attribution to the source actually used (D-18)

Attributing excess stock to each SKU's **nominated primary supplier** put 76% of it on UK
manufacturers. Attributing it to the source **actually used on the most recent receipt** moves
82% of it to Far East importers — the conclusion reverses completely.

This became a standing rule: every minimum order quantity and lead time in the project belongs to
the source actually used, resolved by `DISTINCT ON` so a repeatedly-replenished SKU cannot fan
out.

### 5.5 Overlapping exposures are counted once, never summed (D-16, D-36)

23 positions worth £70,857 are both slow-moving and above policy. 54.4% of high-cover positions
are also minimum-order constrained; 85.4% are also policy-authorised.

Summing the five Stage 4 exposures gives **£1,109,016** — 65% of an estate holding £1,711,042,
the same pounds counted up to five times. The opportunity view assigns each of the 515 positions
to exactly one mechanism by testing five tiers in priority order, and validates that the tiers sum
to closing stock to the penny.

### 5.6 A cheaper price and its working capital must share a time basis (D-29)

The dual-source comparison originally set a **two-year** price saving against a **one-year**
holding cost, roughly doubling the apparent benefit. Corrected to an annual basis it halved from
£851,109 to **£359,089**. The direction survived; the magnitude did not.

Throughout the project, working capital released is a one-off and holding cost saved is annual,
and the two are never added.

---

## 6. Techniques used where simpler ones would have misled

### Calibrating a benchmark rather than importing one (D-31)

Judging replenishment settings needs a standard. Any fixed rule — "two months' cover", "lead time
plus a month" — would measure the gap between Calderfield and that rule, not between
Calderfield's settings and Calderfield's demand.

The rule is instead **derived from the data**: the median multiple of lead-time demand that the
reorder point sits at, across lines whose demand is broadly flat and whose settings are therefore
closest to still fitting. It comes out at **3.05×**, and is then applied to every line at its
current demand.

**The cost of this choice is stated rather than hidden.** Flat lines centre on 1.00 by
construction; they are the reference, not evidence. Every finding lives in the rising and falling
groups where the rule is applied rather than fitted.

A rejected alternative is recorded: benchmarking against lead-time demand *plus the policy's own
safety stock* gave a much tighter spread, because safety stock is itself part of the policy and
carries the same staleness. **A benchmark containing the thing being measured cannot measure it.**

### Alternating adjustment for an unbalanced two-way design (D-27)

Livingston books goods inwards in a Monday batch and also buys heavily from Meridian. The two are
confounded, and the supplier×site design is unbalanced.

Naive marginals attribute **+10.1 days** to Livingston. An iterative two-way fit — four rounds of
chained CTEs alternately adjusting supplier and site effects — attributes **+1.8 days**. The naive
figure overstates by more than five times and would have charged a Livingston process for a
supplier's lead time.

### Leave-one-out before calling a type trend (D-26)

Far East importers appear to decline from 83.6% to 56.8% on-time. Removing the largest supplier
shows the remaining six at 72.9% → 64.3% → 66.7% → **65.9%** — flat to improving. The type trend
is one supplier. Any claim about a supplier *category* is now leave-one-out tested before it is
made.

### Two range-mix corrections that disagree (D-23)

145 of 250 SKUs are stocked only at Daventry, so raw site turnover compares different businesses.
Two corrections were applied: restriction to the 70-SKU common basket, and indirect
standardisation reweighting each site to the network category mix.

They disagree — common-basket moves Bristol +0.33, mix-standardisation +1.43 — and **the
disagreement is reported as the finding** rather than one being chosen. They answer different
questions and neither is "the" corrected number.

### Like-for-like comparison against Simpson's paradox (D-28)

Arden's raw before-and-after average price comparison returns +31.7%, and is invalid: 67 SKUs were
bought before the change and 57 after, so the mix moved. Like-for-like at SKU level across the 57
bought on both sides gives a median of **+18.2%**, p10 17.0% to p90 18.9%, with every other
supplier over the same dates between −1.1% and +0.7%. Both methods are printed on the same data.

### Bounds stated as bounds, and netted of consumption (D-34, D-35)

Stock is fungible and valued at weighted average cost; no unit on a shelf records why it was
bought. Where a mechanism is attributed to standing stock, the figure is the **most** it could be.

Re-deriving the February buy-ahead residual produced £355,381 on the first attempt against file
15's £6,971 — a fifty-fold disagreement. The cause was not a contradiction but a weaker method:
the first attempt ignored the 27,395 units issued since receipt. **A bound that ignores
consumption is not a bound worth reporting.** Both are printed side by side so the difference is
visible.

---

## 7. Guarding against the specific traps in this dataset

Thirteen traps were identified in the project charter before analysis began. Each is handled
structurally rather than remembered.

| Trap | Handling |
|---|---|
| Filtering demand on `line_status` | Fulfilment from quantities (D-03); reporting view 04 prints the cost permanently |
| Dividing Bristol by 104 weeks when it has 78 | Site comparison on 2025 only |
| Reporting one stockout number | Three measures travel together everywhere (AQ-06) |
| Blaming Meridian for Livingston's Monday batch | Receiving site held constant (D-08), then fitted (D-27) |
| Arden's raw price comparison | Like-for-like per SKU only (D-28) |
| Turnover on closing stock | Average of 52 weekly snapshots (D-10) |
| Ranking sites on raw turnover | Range-mix adjusted comparison, two ways (D-23) |
| Assuming Warrington's Heating shortage is in December | Validated from the data — it is **March** (D-20) |
| Cost of sales at standard cost | Ledger weighted average cost (D-10) |
| Counting transfers as demand | `Sales issue` only (D-09) |
| Supplier trends by quarter | Half-year with n printed (D-15) |
| Fanning out receipts against order lines | Receipts pre-aggregated before comparison |
| Treating unmet demand as lost sales | Reported as an upper bound throughout |

---

## 8. Reproducibility

**The pipeline rebuilds from an empty database with zero failures.** All 35 files run clean in
dependency order.

**Committed results are byte-identical across repeated rebuilds.** This was verified by dropping
the database, rebuilding, and comparing checksums — five consecutive times.

**That test found a defect no amount of reading would have caught (D-40).** Four files contained
`UNION ALL` blocks with no `ORDER BY`. The numbers were always correct; only the row order moved
between runs. SQL guarantees no ordering without `ORDER BY`, and a committed result that changes
between identical runs cannot be diffed and cannot be trusted as evidence. All four were given
explicit sort keys.

A static scan flags roughly forty further blocks carrying the same theoretical risk. None of them
varied across five rebuilds, and Stage 4 was complete, so **they were left alone and the residual
risk is recorded rather than fixed silently**.

**Reproducibility is now checked by rebuilding and comparing checksums, not by re-reading the
SQL.**

---

## 9. Working practice

**Every result is committed.** 32 text files in `analysis/query_results/`, regenerated by the
pipeline and diffable.

**Denominators and sample sizes are printed beside every rate.** Cells below ten observations are
marked as thin and carry no interpretation.

**Reconciliation is built into the files, not performed afterwards.** Each reporting view contains
explicit `PASS`/`FAIL` checks against its Stage 4 source — 26 across the seven files, all passing.
The opportunity view proves its five tiers sum to closing stock to the penny, and that its third
tier reproduces file 04's excess figure exactly.

**Where a result contradicted an expectation, the contradiction was reported rather than the query
adjusted.** Six of the forty recorded decisions exist because a measurement disagreed with what
the plan expected, and in each case the plan was wrong:

- Excess attribution reversed from UK manufacturers to importers (D-18)
- The Livingston site effect fell from +10.1 days to +1.8 (D-27)
- A price figure carried from a generation-phase note did not reproduce (D-28)
- A saving halved once the time bases were aligned (D-29)
- The February buy-ahead proved net positive, contradicting the expected mechanism (D-30)
- Policy staleness was rejected twice, forcing a file to be redesigned and then redesigned again
  (D-21, D-32)

**Findings are classified by the kind of claim they are** — supported, quantified, upper bound,
assumption, unresolved, rejected — because presenting them as one list would imply they carry
equal weight. Two findings remain unresolved and are recorded as such rather than explained away.

---

## 10. What the method cannot do

- **No forecasting.** Two years gives one year-on-year comparison. Every slope is reported with
  the number of quarters behind it. A slope is directional evidence, not a trend estimate.
- **No causal claims from observational structure.** The receiving-site effect is association.
  The dataset cannot show the Monday batch *causes* the delay.
- **No policy history.** `replenishment_policy` holds current settings and one review date. What
  a review changed cannot be measured, and a design that proposed to was withdrawn (D-32).
- **No substitution model.** Unmet demand is an upper bound on lost revenue.
- **No cost data of any kind.** Three of the four components of the holding rate are external
  assumptions the dataset cannot corroborate. No implementation cost can be estimated, which is
  why no ROI is stated.
- **Shrinkage is not realistic.** Observed stock loss runs at 7.9% of average inventory a year
  against a real-world norm well under 2% — a generator artefact in a frozen dataset. Reported
  comparatively between sites, never as an absolute (D-12).

---

*Decisions D-01 to D-40: `docs/DECISIONS.md`. Findings: `docs/KEY_FINDINGS.md`. Scope, stakeholder
and KPI definitions: `PROJECT_CHARTER.md` and `_portfolio/KPI_LIBRARY.md`.*
