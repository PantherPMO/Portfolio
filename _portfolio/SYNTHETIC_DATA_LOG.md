# Synthetic Data Log

Synthetic data is a **last resort**, used only when no real public dataset can support a required business case.

---

## The Rule

> **No synthetic data may be generated without Peters' explicit prior approval.**

Before generating anything, the following must be presented and approved:

1. **What** — every field, its type, and the dataset size
2. **Why** — which real datasets were searched, and precisely why each failed
3. **How** — distributions, relationships, seed, and the business logic embedded
4. **The cost** — an honest statement of the credibility trade-off
5. **Approval** — obtained in writing, and recorded below

---

## Why This Matters

Synthetic data weakens a portfolio project in three specific ways, and being clear-eyed about them is part of the analytical judgement being demonstrated:

- **The findings are not real.** Any pattern discovered was, by definition, put there by the generator. "I found that customers on monthly contracts churn more" means nothing if you wrote the rule that made it so.
- **Interviewers discount it.** An experienced interviewer will ask about data provenance early. Synthetic data invites the question *"so what did you actually learn?"*
- **It removes the hardest part of the job.** Real data is messy, contradictory and incomplete. Handling that is the skill being assessed.

**When it is nonetheless legitimate:** demonstrating a technique that no public dataset supports, where the *method* is the deliverable and is presented as such — for example a cost-estimation model requiring linked tender, cost and outcome records that no public source publishes together.

The honest framing in a README:

> *This dataset is synthetic, generated to a documented specification because no public source links tender pricing to realised cost outcomes. The generation logic is in `data/synthetic/generate.py`. The deliverable here is the estimating method and its uncertainty quantification, not a claim about any real market.*

---

## Approval Register

| ID | Project | Dataset | Requested | Approved by | Date approved | Script |
|----|---------|---------|-----------|-------------|---------------|--------|
| — | — | *None. No synthetic data has been generated.* | — | — | — | — |

---

## Approval Request Template

Present this to Peters and **wait for a decision**.

```markdown
## Synthetic Data Approval Request — SD-01

**Project:** NN — <name>
**Requested:** <date>

### 1. What is needed
<The business case, and the exact data required to support it.>

### 2. Real datasets searched
| Source | Dataset | Why it does not work |
|--------|---------|---------------------|
| ONS | | |
| data.gov.uk | | |
| Kaggle | | |
| World Bank | | |

<Confirm the search was genuine and reasonably exhaustive.>

### 3. Proposed dataset
**Size:** N rows × M columns
**Granularity:** one row = ?
**Period covered:**

| Field | Type | Distribution / logic | Business meaning |
|-------|------|---------------------|------------------|
| | | | |

**Relationships embedded**
- <e.g. contract type influences churn probability, with an assumed effect size of X>
- <state every assumption — these ARE the findings, so they must be visible>

**Realism basis**
<Where do the parameters come from? Published industry benchmarks are far better than invention — cite them.>

### 4. Generation method
- Library: `numpy` / `faker` / other
- Random seed: fixed, stated
- Script location: `data/synthetic/generate_<name>.py`
- Fully reproducible: yes

### 5. Honest cost
<What this costs the project's credibility, and how the README will address it.>

### 6. Alternatives to generating data
- Could the business problem be reshaped to fit a real dataset?
- Could a real dataset be augmented rather than replaced?
- Could the project be replaced with a different one entirely?

**Recommendation:** <yes / no, and why>

---
**DECISION:** ⬜ Approved ⬜ Rejected ⬜ Revise
**Signed:** ______________  **Date:** __________
```

---

## Rules Once Approved

1. The generation script is committed, seeded, and reproducible.
2. Files live in `data/synthetic/`, never in `data/raw/`.
3. Every generation assumption is documented — the assumptions are the findings.
4. The project README carries a **prominent** synthetic-data notice in the summary block at the top, not buried in a limitations section.
5. The README never states or implies a conclusion about the real world.
6. An entry is added to `DATASET_REGISTRY.md` with type `Synthetic`.
7. Findings are framed as demonstrating method, not discovering truth.
