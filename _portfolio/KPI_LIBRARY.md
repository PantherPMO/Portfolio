# KPI Library

**Every KPI is defined once, here.** Projects reference these definitions rather than redefining them.

Why this matters: if "churn rate" is calculated three different ways across three projects, an interviewer who notices has found a real credibility problem. Consistency across the portfolio is itself evidence of professional discipline.

---

## Definition Standard

Every KPI entry must specify:

| Element | Why |
|---------|-----|
| **Formula** | Unambiguous, in plain arithmetic |
| **Grain** | The level it is calculated at (customer, month, SKU, site) |
| **Unit** | %, £, days, ratio, count |
| **Period** | The time window |
| **Inclusions / exclusions** | What is deliberately left out, and why |
| **Benchmark** | Target or industry comparison — **with a source** |
| **Decision it supports** | If none, it is not a KPI, it is a number |
| **Used in** | Which projects |

**A metric without a decision attached is not a KPI.** Resist the temptation to build a dashboard of everything measurable.

---

## Seeded Definitions

These are the standard definitions to be used unless a project documents a deliberate deviation. Benchmarks marked *[to source]* must be replaced with a cited figure before use in a project — never present an unsourced benchmark.

---

### Customer & Revenue

#### Churn Rate
- **Formula:** `Customers lost in period ÷ Customers at start of period × 100`
- **Grain:** Customer, per period
- **Unit:** %
- **Inclusions:** Voluntary and involuntary churn counted separately where the data allows
- **Exclusions:** Customers acquired and lost within the same period (state the treatment explicitly)
- **Benchmark:** *[to source — telecoms monthly churn benchmarks vary widely by market and contract type; cite the specific source used]*
- **Decision supported:** Where to target retention spend
- **Used in:** 01, 07

#### Revenue at Risk
- **Formula:** `Σ (Monthly recurring revenue of customers in high-risk segment) × 12`
- **Grain:** Segment
- **Unit:** £ per annum
- **Note:** State the risk-segment definition explicitly; the figure is meaningless without it
- **Decision supported:** Sizing the retention business case
- **Used in:** 01

#### ARPU — Average Revenue Per User
- **Formula:** `Total revenue in period ÷ Average active customers in period`
- **Grain:** Customer, per period
- **Unit:** £ per customer per month
- **Note:** Use *average* active customers (start + end ÷ 2), not end-of-period, where the base is changing
- **Decision supported:** Pricing and segment prioritisation
- **Used in:** 01, 06, 07

#### Customer Lifetime Value (CLV)
- **Simple formula:** `ARPU × Gross margin % × Expected lifetime (months)`
- **Expected lifetime:** `1 ÷ monthly churn rate`
- **Probabilistic:** BG/NBD (transaction frequency) + Gamma-Gamma (monetary value)
- **Grain:** Customer
- **Unit:** £
- **Note:** State which method was used, and the discount rate if applied. The simple formula assumes constant churn — a strong assumption that must be acknowledged
- **Decision supported:** Acquisition spend ceiling; service-tier allocation
- **Used in:** 07

#### Customer Acquisition Cost (CAC)
- **Formula:** `Total acquisition spend in period ÷ New customers acquired in period`
- **Unit:** £
- **Companion metric:** CLV:CAC ratio — a widely cited healthy threshold is 3:1, *[to source]*
- **Used in:** 07

#### Retention Rate
- **Formula:** `100 − Churn rate`, or `Customers retained ÷ Customers at start × 100`
- **Unit:** %
- **Used in:** 01, 07

---

### Sales & Commercial

#### Gross Margin %
- **Formula:** `(Revenue − Cost of goods sold) ÷ Revenue × 100`
- **Grain:** Transaction, product, customer or period — **state which**
- **Unit:** %
- **Decision supported:** Product mix and pricing
- **Used in:** 03, 04, 05, 06

#### Average Order Value (AOV)
- **Formula:** `Total revenue ÷ Number of orders`
- **Grain:** Order
- **Unit:** £
- **Note:** Distinguish from basket size (items per order) — they answer different questions
- **Used in:** 03, 06

#### Sales Growth %
- **Formula:** `(Current period revenue − Prior period revenue) ÷ Prior period revenue × 100`
- **Unit:** %
- **Note:** Specify YoY or MoM. For seasonal businesses YoY is usually the honest comparison
- **Used in:** 06, 08

#### Win Rate
- **Formula:** `Opportunities won ÷ Total opportunities closed × 100`
- **Unit:** %
- **Note:** Closed opportunities only — including open ones understates the rate
- **Used in:** 05, 06

---

### Financial

#### Budget Variance (£)
- **Formula:** `Actual − Budget`
- **Sign convention:** Positive = over budget on cost, favourable on revenue. **State the convention explicitly — this is the most common source of confusion in variance reporting**
- **Used in:** 04

#### Budget Variance (%)
- **Formula:** `(Actual − Budget) ÷ Budget × 100`
- **Note:** Undefined where budget = 0; handle explicitly
- **Used in:** 04

#### Price Variance
- **Formula:** `(Actual price − Budget price) × Actual quantity`
- **Purpose:** Isolates the portion of variance caused by price
- **Used in:** 04, 05

#### Volume Variance
- **Formula:** `(Actual quantity − Budget quantity) × Budget price`
- **Purpose:** Isolates the portion caused by volume
- **Note:** Price + volume variance should reconcile to total variance; any residual is a mix effect and must be shown, not absorbed
- **Used in:** 04, 05

#### Cost Variance %
- **Formula:** `(Actual cost − Estimated cost) ÷ Estimated cost × 100`
- **Used in:** 05

---

### Inventory & Operations

#### Inventory Turnover
- **Formula:** `Cost of goods sold ÷ Average inventory value`
- **Grain:** SKU, category or site
- **Unit:** Times per year
- **Note:** Use average inventory, not closing — closing inventory distorts seasonal businesses
- **Decision supported:** Where working capital is trapped
- **Used in:** 02

#### Days Inventory Outstanding (DIO)
- **Formula:** `365 ÷ Inventory turnover`
- **Unit:** Days
- **Note:** More intuitive for stakeholders than turnover; prefer it in stakeholder-facing output
- **Used in:** 02

#### Stock Holding Cost
- **Formula:** `Average inventory value × Annual holding cost rate`
- **Unit:** £ per annum
- **Note:** State the holding cost rate and its basis (capital cost, storage, insurance, obsolescence). A commonly cited range is 20–30% of inventory value, *[to source]*
- **Used in:** 02

#### Stockout Rate
- **Formula:** `Periods with zero stock ÷ Total periods × 100`
- **Unit:** %
- **Used in:** 02

#### On-Time Delivery / OTIF
- **Formula:** `Orders delivered on time and in full ÷ Total orders × 100`
- **Unit:** %
- **Note:** OTIF is stricter than on-time alone; state which is used
- **Used in:** 02, 08

#### Order Cycle Time
- **Formula:** `Mean (Delivery date − Order date)`
- **Unit:** Days
- **Note:** Report median alongside mean where the distribution is skewed — it usually is
- **Used in:** 02, 08

---

## Adding a KPI

1. Check it is not already defined here under another name.
2. Add it using the definition standard above, in the right section.
3. State the decision it supports. If you cannot, do not add it.
4. Source the benchmark, or mark it *[to source]* and resolve before use.
5. Record it in the project README's KPI section by reference to this library.

## Deviating from a Definition

Permitted, but must be documented in the project's `DECISIONS.md` with the reason, and flagged in the README. An undocumented deviation is an inconsistency; a documented one is a judgement call.
