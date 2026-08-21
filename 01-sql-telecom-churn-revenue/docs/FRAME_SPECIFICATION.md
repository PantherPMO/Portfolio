# FRAME Specification (Proposed) — Project 01

## Telecommunications Revenue Retention: Prioritising Retention Investment by Revenue at Risk

**Stage:** 2 → 3 transition
**Status:** 🔴 **PROPOSED — awaiting approval. FRAME has not begun.**
**Prepared:** 19 August 2026

> **Pre-registration statement.** Every definition, cut point, threshold and segment in this document is specified **before any analytical result has been generated or reviewed**. No cut point has been tested. No segmentation has been trialled. Nothing here was chosen because it produced an interesting result.
>
> The two feasibility figures that appear (§2) are denominator arithmetic required to make the decision at all — they are not analytical results, and no business conclusion is drawn from them.

---

# 1. Decisions Already Locked

| Ref | Decision | Status |
|---|---|---|
| **C-1 / D-06** | Five relational tables authoritative; merged workbook is reconciliation-only and excluded from the schema | ✅ **Locked** |
| **C-2 / D-07** | `Annual Recurring Revenue at Risk = Monthly Charge × 12`. Long distance excluded from the headline, retained as a separate reported component | ✅ **Locked** |
| **C-5 / D-09** | Licence unresolved; no licensing claim made; raw files not committed | ✅ **Position recorded** |

---

# 2. C-3 — Churn-Rate Denominator

## 2.1 What `Customer Status` actually means — established from the data

`Customer Status` is not an independently observed field. **It is fully derived from tenure and churn.** Both rules hold with **zero exceptions** across all 7,043 rows:

```
Customer Status = 'Joined'   ⟺   Tenure in Months ≤ 3  AND  Churn Value = 0     (454 customers)
Customer Status = 'Stayed'   ⟺   Tenure in Months ≥ 4  AND  Churn Value = 0   (4,720 customers)
Customer Status = 'Churned'  ⟺   Churn Value = 1                              (1,869 customers)
```

Verified: `Joined` count 454 = rule count 454, identical membership. `Stayed` count 4,720 = rule count 4,720, identical membership.

**Tenure distribution at the boundary:**

| Tenure (months) | Churned | Joined | Stayed |
|---|---|---|---|
| 1 | 380 | 233 | **0** |
| 2 | 123 | 115 | **0** |
| 3 | 94 | 106 | **0** |
| 4 | 83 | 0 | 93 |
| 5 | 64 | 0 | 69 |
| 6 | 40 | 0 | 70 |

The boundary is exactly at 3/4 months. **No surviving customer with tenure ≤ 3 is labelled `Stayed`; no customer with tenure ≥ 4 is labelled `Joined`.**

## 2.2 What period the dataset represents

| Evidence | Finding |
|---|---|
| `Quarter` field in `services` and `status` | Present, **constant `'Q3'`** — 7,043/7,043 in both tables |
| Year | **Not stated anywhere** in the files or IBM's publication |
| IBM's description | "…to 7043 customers in California **in Q3**" |
| `Tenure in Months` range | 1–72 |
| `Joined` boundary | Exactly 3 months = **one quarter** |

**Conclusion:** the dataset is a **single-quarter observation window (Q3)** with a period-end snapshot. Tenure records total relationship length up to six years, but *status is observed over one quarter only*. The 3-month `Joined` boundary aligns exactly with the quarter length, confirming that `Joined` means **"acquired within the observation quarter."**

The `Quarter` column exists because the schema anticipates multiple periods. **Only one is present.** This is definitive confirmation of risk R-01.

## 2.3 Why this changes the denominator question

A churn rate is *churned ÷ customers at risk during the period*. Customers acquired **within** the period were not at risk for all of it.

Critically — and this is what the derivation in §2.1 exposes — **597 churned customers also have tenure ≤ 3.** They joined *and* left within the same quarter.

| Group | n |
|---|---|
| Joined in-period and survived (`Joined`) | 454 |
| Joined in-period and churned (tenure ≤ 3, `Churned`) | **597** |
| **Total in-period acquisitions** | **1,051** |
| Opening base (tenure ≥ 4) | 5,992 |

### The option I proposed at Stage 2 is incoherent

I previously offered *"exclude `Joined`"* as the alternative to *"all rows."* **That option is asymmetric and biased upward.** It removes the 454 in-period joiners who survived from the denominator, while leaving the 597 in-period joiners who churned in the numerator. It penalises the base for early-life churn it was never exposed to.

I am withdrawing it rather than presenting it as a live choice.

## 2.4 The coherent options

| Option | Definition | Numerator | Denominator | Rate |
|---|---|---|---|---|
| **(a)** Period-end base | All rows | 1,869 | 7,043 | **26.54%** |
| ~~(b)~~ | ~~Exclude `Joined` only~~ | ~~1,869~~ | ~~6,589~~ | ~~28.37%~~ **withdrawn — asymmetric** |
| **(c)** Opening-cohort | Exclude **all** in-period acquisitions from both sides | 1,272 | 5,992 | **21.23%** |
| **(d)** Average base | (opening + closing) ÷ 2 | 1,869 | 5,583 | **33.48%** |

> These are denominator arithmetic, not findings. No conclusion is drawn from the spread.

## 2.5 Recommendation

**Primary KPI: option (c) — opening-cohort churn rate, 21.23%.**

**Why:** it is the only **symmetric** treatment. Numerator and denominator describe the same population — customers who existed at the start of the quarter and were exposed to churn risk for its full duration. Options (a) and (d) mix populations; (b) is incoherent.

**Reported alongside, always:**

- **Option (a), 26.54%**, labelled *"period-end base rate"* — for reconciliation with the published literature on this dataset, which universally uses it. Reporting it prevents the reasonable challenge *"why doesn't your number match everyone else's?"*
- **Early-life churn reported separately**, not folded into either rate. 597 customers joined and left within the quarter — **31.9% of all churn**. That is an onboarding and acquisition-quality question, not a base-retention question, and it warrants a different intervention.

**Revenue at risk uses a different rule, deliberately.** All 1,869 churned customers represent genuinely lost revenue regardless of when they joined, so **the revenue-at-risk numerator includes all of them** — but reported split between the established base (1,272) and in-period acquisitions (597).

This is not a denominator fudge. Churn *rate* needs a symmetric population to be a valid rate; revenue *lost* is simply lost. Separating the two is the honest treatment of both, and the split is itself decision-relevant: retention spend and onboarding spend are different budgets with different owners.

**Cost of this choice:** three numbers must be communicated instead of one, and 21.23% is lower than the figure any reader familiar with this dataset will expect. Both are handled by reporting (a) alongside and explaining why.

**🔴 Requires your approval before FRAME. Locks on approval.**

---

# 3. C-6 — Segmentation Framework

## 3.1 Governing rules — fixed before any result is seen

| Rule | Specification |
|---|---|
| **Minimum cell size — report freely** | n ≥ 100 |
| **Minimum cell size — report with explicit caveat and stated `n`** | 30 ≤ n < 100 |
| **Below reporting threshold** | n < 30 — **not reported as a rate**; collapsed into an adjacent band or an "Other" grouping |
| **`n` disclosure** | Every segment result reports its `n`, without exception |
| **Cut points** | Fixed in this document. **Any change after results are seen must be recorded in `DECISIONS.md` with its justification** — otherwise it is specification searching |
| **Ranking segments** | Segments are ranked only within a scheme, never across schemes |

## 3.2 Primary segmentation — for the divergence index

**Scheme P1: Value Tier × Contract Type (9 cells)**

| Field(s) | `Monthly Charge` (→ tier), `Contract` |
|---|---|
| **Business rationale** | These are the two things a CVM lead can actually act on. Value determines *how much* intervention is justified; contract determines *when* the customer is exposed and *what* offer is available. Every retention conversation in a telco starts with these two facts |
| **Analytical purpose** | Provides the segment set over which the **value–risk divergence index** is computed. Nine cells is enough for ranks to diverge meaningfully, few enough that every cell is large |
| **Decision supported** | The core allocation decision — which segments receive proactive, high-touch intervention and which are served through lower-cost channels |
| **Expected minimum cell size** | ≥ 208 (derived: minimum decile × contract cell is 104, and each tier spans at least two deciles) — comfortably above the n ≥ 100 threshold |

**Value tier definition** *(fixed now)*

| Tier | Rule | Basis |
|---|---|---|
| **High** | `Monthly Charge` deciles 8–10 (top 30%) | Where retention spend is most likely justified |
| **Mid** | Deciles 4–7 (middle 40%) | The bulk of the base |
| **Low** | Deciles 1–3 (bottom 30%) | Where lower-cost channels are likely appropriate |

*Deciles, not fixed currency thresholds — the currency is unknown (V-R6) and absolute thresholds would be meaningless.*

**Contract:** `Month-to-Month` (3,610) · `One Year` (1,550) · `Two Year` (1,883) — used as-is.

## 3.3 Secondary segmentation — for concentration analysis

**Scheme P2: Revenue Decile (10 cells)**

| Field(s) | `Monthly Charge` |
|---|---|
| **Business rationale** | Answers BQ-02 and BQ-03 directly — is revenue concentrated, and are we losing the valuable customers or the cheap ones? |
| **Analytical purpose** | Pareto / concentration curve; churn rate by decile; the finer-grained view behind the tier collapse in P1 |
| **Decision supported** | Whether segment targeting is viable at all. If revenue is evenly spread, targeting has no leverage and the remedy is structural |
| **Verified cell sizes** | 695–717 per decile — all well above threshold |

## 3.4 Driver lenses — applied *within* the High value tier

These answer AQ-05 and AQ-06. Each is a **single-dimension** cut applied to the High tier, then compared against the same cut applied base-wide.

| # | Lens | Field(s) | Business rationale | Analytical purpose | Decision supported |
|---|---|---|---|---|---|
| **L1** | Contract type | `Contract` | The single strongest commercial lever; determines notice period and offer eligibility | Churn index vs base | Which contract cohorts to target with migration offers |
| **L2** | Tenure band | `Tenure in Months` | Risk is not uniform across the lifecycle; early-life and contract-anniversary risk differ in kind | Locates *when* in the lifecycle high-value risk concentrates | When to intervene — onboarding vs anniversary vs long-tenure |
| **L3** | Payment method | `Payment Method` | A behavioural signal of commitment and of billing friction; also operationally actionable (migration to direct debit) | Churn index vs base | Whether billing-method migration is a retention lever |
| **L4** | Internet type | `Internet Type` | Product technology is a proposition characteristic, not a customer one — if it dominates, the remedy sits with Propositions, not retention | Churn index vs base | **Tests decision branch 4 in the charter** — is this a product problem? |
| **L5** | Service intensity | Count of `Yes` across 8 add-ons | Breadth of relationship is a standard proxy for switching cost | Churn index vs base | Whether cross-sell is a retention lever |
| **L6** | Offer held | `Offer` | The only field resembling a commercial intervention. Its relationship to retention is directly relevant to the budget question | Churn index vs base | Whether existing offers are reaching the right customers |
| **L7** | Referral behaviour | `Referred a Friend`, `Number of Referrals` | Advocacy is a recognised loyalty signal and is cheap to act on | Churn index vs base | Whether advocacy identifies low-risk customers who need no spend |

### Fixed cut points

**L2 — Tenure bands** *(fixed now; rationale stated before results)*

| Band | Months | Rationale |
|---|---|---|
| **In-period acquisition** | 1–3 | Matches the observation quarter exactly and the derived `Joined` boundary. Isolates onboarding-phase churn |
| **First year** | 4–12 | Pre-first-anniversary; no annual contract has yet renewed |
| **Second year** | 13–24 | Spans the One Year contract anniversary |
| **Established** | 25–48 | Spans the Two Year anniversary |
| **Long tenure** | 49–72 | The most tenured cohort |

Boundaries are set by **contract anniversaries and the observation window** — not by inspecting where churn happens to change.

**L5 — Service intensity bands**

| Band | Add-on count | Rationale |
|---|---|---|
| **None** | 0 | No add-on relationship |
| **Light** | 1–2 | Minimal breadth |
| **Moderate** | 3–4 | Around the midpoint of 8 possible |
| **Deep** | 5–8 | Broad relationship, high switching cost |

Counted across `Online Security`, `Online Backup`, `Device Protection Plan`, `Premium Tech Support`, `Streaming TV`, `Streaming Movies`, `Streaming Music`, `Unlimited Data` — all clean `Yes`/`No` in the relational source, so no sentinel handling is required.

**L6 — `Offer`:** six categories — A, B, C, D, E, and **"No offer"** for the 3,877 structural nulls. The nulls are a meaningful category, not missing data.

**L4 — `Internet Type`:** four categories — Fiber Optic (3,035), DSL (1,652), Cable (830), **"No internet" (1,526)**. The null is structural and verified to correspond exactly to `Internet Service = 'No'`.

## 3.5 Segments deliberately excluded

| Not used | Why |
|---|---|
| `Gender`, `Age`, `Under 30`, `Senior Citizen` | **Protected characteristics.** Descriptive/confounding checks only, never a prioritisation segment (D-15) |
| `City`, `Zip Code` | No business question requires geographic targeting; would fragment cells below threshold |
| `Population` | Available via the zip join, but no business question requires it. **Retained as an unused-but-available field, not analysed** |
| `Married`, `Dependents`, `Number of Dependents` | Household proxies — retained for confounding checks only, not as prioritisation segments |
| `Latitude`, `Longitude` | Out of scope |
| `Satisfaction Score`, `Churn Score`, `CLTV`, `Churn Reason`, `Churn Category` | Excluded fields (D-11 to D-14) |

## 3.6 Pre-registration commitment

The schemes above are fixed. Specifically:

1. **P1 is the divergence-index segmentation.** If the index shows nothing on P1, that is a **reportable null result**, not grounds for trying P2 or a driver lens until something appears.
2. **Cut points do not move to improve a result.** Any change is recorded with its justification in `DECISIONS.md`.
3. **All seven driver lenses are reported**, including those showing no effect. Reporting only the lenses that "worked" is selective reporting.
4. **Cells below n = 30 are collapsed, not dropped silently.** Collapsing is recorded.

**🔴 Requires your approval before FRAME. Locks on approval.**

---

# 4. C-4 — The Three Reworded Business Questions, Verbatim

Reproduced **exactly** as they appear in `PROJECT_CHARTER.md` §11, with their surrounding table cells intact and unparaphrased.

### BQ-01

> | **BQ-01** | How much annual recurring revenue are we losing to churn? *(trend clause removed — no time dimension)* | Sizes the problem; establishes whether it warrants budget | 🟡 Reword |

**Original:** *"How much annual recurring revenue are we losing to churn, and is it getting worse?"*
**Change:** the clause *"and is it getting worse?"* removed.
**Reason:** single-quarter snapshot; `Quarter` is constant `Q3`. No trend is computable, and tenure must not be used as a proxy for time.

### BQ-04

> | **BQ-04** | Where would a churn-rate-led prioritisation diverge from a revenue-led one? *(reworded — no retention activity data exists)* | Identifies the misallocation directly | 🟡 Reword |

**Original:** *"Where is our current retention effort mismatched to where the money actually is?"*
**Change:** reframed from *actual* current allocation to a *comparison of two prioritisation logics*.
**Reason:** the dataset contains no campaigns, offers-made, contacts or saves. Actual current allocation is unobservable. The divergence between a churn-led and a revenue-led ranking is observable, and answers the same underlying business need honestly.

### BQ-06

> | **BQ-06** | Under stated assumptions, how much would it be worth spending to retain each segment, and where does that break even? *(reworded — scenario, not measurement)* | Converts insight into a budget number | 🟡 Reword |

**Original:** *"How much is it worth spending to retain each segment, and where does that break even?"*
**Change:** prefixed *"Under stated assumptions,"*.
**Reason:** no margin data and no intervention-outcome data exist. The output is a decision framework under declared assumptions, not a measurement. The rewording makes that visible in the question itself rather than only in a caveat.

**🔴 Requires your confirmation. BQ-02, BQ-03 and BQ-05 are unchanged and already approved.**

---

# 5. C-5 — Licensing Position

Recorded in full at [`DECISIONS.md`](DECISIONS.md) D-09.

**Summary:** provenance is fully established — IBM Corporation, Cognos Analytics sample data, published July 2019, files dated November 2019, fictional status stated by IBM in its own words. **Licensing is not established.** No licence statement was located in the IBM publication, the files themselves, or accessible mirror pages; IBM Docs returned HTTP 403.

**The position taken: UNRESOLVED.** No licensing claim of any kind is made. Raw files are not committed. `DATASET_REGISTRY.md` records ❓ rather than a presumption dressed as a fact.

✅ **No approval required — this is a statement of position, not a proposal.**

---

# 6. Charter and Validation Defects — Fixed

The three defects identified during your document review:

| # | Defect | Status |
|---|---|---|
| 1 | Charter §17 stated "Six things differentiate this one" then listed seven | ✅ **Fixed** — now reads "Seven things" |
| 2 | Validation §D recommended splitting BQ-01 into "BQ-01a" while the charter simply removed the trend clause | ✅ **Resolved** — the superseded support matrix was replaced during the Stage 2 rewrite; the charter wording is now the single source, reproduced verbatim in §4 above |
| 3 | Validation §D.1 used "spend up to **£X**" while charter A-06 forbids presenting figures in £ | ✅ **Resolved** — that passage was removed in the Stage 2 rewrite. Currency is now documented as **unknown** (P-15 found no evidence), and the standing instruction is to present values unitless |

---

# 7. What FRAME Will Produce, On Approval

**No analytical work. No SQL. No results.** FRAME produces specification documents only:

| Deliverable | Content |
|---|---|
| `docs/BUSINESS_QUESTIONS.md` | Final BQ set with analytical mapping and answer location |
| `docs/METHODOLOGY.md` | The analytical approach per question, assumptions, alternatives considered and rejected |
| `docs/CASE_STUDY.md` | The stakeholder scenario framing the engagement |
| `_portfolio/KPI_LIBRARY.md` update | The five new KPI definitions, with the C-2 and C-3 conventions written in |
| Charter §11–§12 update | Question set marked final rather than proposed |

The first SQL is written at PREPARE, after FRAME is signed off.

---

# 8. Outstanding Approvals

| Ref | Item | Status |
|---|---|---|
| **C-3** | Churn denominator — **option (c) opening-cohort recommended**, with (a) reported alongside and early-life churn separated | 🔴 **Awaiting decision** |
| **C-4** | The three reworded business questions, reproduced verbatim in §4 | 🔴 **Awaiting confirmation** |
| **C-6** | Segmentation framework — P1, P2, L1–L7, all cut points and thresholds | 🔴 **Awaiting approval** |
| C-5 | Licensing position | ✅ Recorded, no approval needed |
| C-1, C-2 | Source precedence, revenue basis | ✅ Locked |

**Nothing in FRAME begins until C-3, C-4 and C-6 are resolved.**
