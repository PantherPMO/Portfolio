# Findings — NN: <Project Name>

**The evidence register.** Every claim made anywhere in this project traces back to an entry here.

> **Rule:** if a claim has no complete evidence chain, it does not appear in the README.
> See `_portfolio/CLAUDE.md` §5.

---

## Index

| ID | Finding | Answers | Confidence | Material? |
|----|---------|---------|-----------|-----------|
| F-01 | | BQ-01 | High | Yes |
| F-02 | | BQ-01 | Medium | Yes |
| F-03 | | BQ-02 | High | No |

*Material = drives a recommendation. Non-material findings are recorded but need not appear in the README.*

---

## F-01 — <Short finding title>

### Evidence Chain

```
F-01
 ├─ Question    BQ-01 — <the business question this answers>
 ├─ Method      <SQL aggregation / regression / variance decomposition>
 ├─ Query       sql/03_analysis/01_<name>.sql
 ├─ Result      analysis/query_results/01_<name>.csv
 ├─ Chart       outputs/figures/f01_<name>.png
 └─ Confidence  High / Medium / Low — <why>
```

### The Four Layers

**FINDING — what happened**
> <The observable fact, with its number and unit. No interpretation, no adjectives.>
> *Example: Warehouse A's stock holding cost is 14.2% higher than Warehouse B's (£412k vs £361k annually).*

**INSIGHT — why it happened**
> <The mechanism, evidenced. Not "because performance is worse" — the actual cause, demonstrated.>
> *Example: 72% of the gap is concentrated in three product categories where average stock turn is 1.8× per year against a site average of 5.4×.*

**IMPLICATION — why it matters**
> <The business consequence, quantified.>
> *Example: £310k of working capital is tied up in stock turning below 2× per year, carrying an annual holding cost of roughly £47k at a 15% carrying rate.*

**RECOMMENDATION — what to do**
> <Specific, owned, with expected impact and its basis.>
> *Example: Reset reorder points for the three categories to a 60-day cover target and review inter-site allocation. Modelled release of £180–240k of working capital within two quarters, based on bringing turn to the site average.*

### Supporting Detail

**Numbers**

| Metric | Value | Comparison |
|--------|-------|-----------|
| | | |

**Sample size / coverage:** <n = , % of total>

**Statistical support** *(where applicable)*
- Test:
- Statistic / p-value:
- Effect size:
- Interpretation in plain English:

**Alternative explanations considered and ruled out**

| Alternative explanation | How it was ruled out |
|------------------------|---------------------|
| | |

<This subsection is where analytical rigour shows. A finding with no alternatives considered is an assumption.>

**Caveats**
- 

**How to verify this independently**
> <The exact steps a reviewer would take to reproduce the number.>

---

## F-02 — <Short finding title>

*(Repeat the structure above.)*

---

## Findings Rejected

Findings investigated and dropped. Recording these demonstrates rigour — and they are excellent interview material.

| Candidate finding | Why rejected |
|-------------------|--------------|
| <e.g. "Region B outperforms Region A"> | Difference of 2.1pp, n = 43, not distinguishable from noise |
| | |

---

## Quality Check

Before this project ships:

- [ ] Every finding has a complete chain — query, result file, chart
- [ ] Every result file exists and matches the finding
- [ ] Every chart exists and follows the style guide
- [ ] All four layers written for every material finding
- [ ] No claim in the README is absent from this register
- [ ] Confidence honestly assessed; low-confidence findings labelled as such in the README
- [ ] Alternative explanations considered for every material finding
- [ ] **No number anywhere in this project that cannot be traced to a source**
