# Decision Log — NN: <Project Name>

Judgement calls made during this project, recorded **as they are made**.

Interviewers probe exactly these choices. A written decision turns *"I think I did that because…"* into a specific, confident answer.

---

## Index

| ID | Decision | Stage | Date |
|----|----------|-------|------|
| D-01 | | SOURCE | |
| D-02 | | PREPARE | |
| D-03 | | ANALYSE | |

---

## D-01 — <Short title>

**Stage:** DEFINE / SOURCE / FRAME / PREPARE / ANALYSE / COMMUNICATE
**Date:**

**The decision**
> <What was decided, in one sentence.>

**The context**
> <What made a decision necessary?>

**Options considered**

| Option | Pros | Cons |
|--------|------|------|
| A — <chosen> | | |
| B | | |
| C | | |

**Chosen:** <A>

**Why**
> <The reasoning. This is the part that matters.>

**What this costs**
> <Every decision has a downside. Naming it is what makes the reasoning credible.>

**How it affects the results**
> <Would a different choice have changed a finding? If yes, say so — and say by how much if it can be tested.>

**Would I decide the same again?**
> <Answered honestly at review stage.>

---

## D-02 — <Short title>

*(Repeat the structure above.)*

---

## Common Decisions to Record

If any of these arose in this project, they need an entry:

**Data**
- Which dataset was chosen, and over what
- Which fields were excluded, and why
- How missing values were treated, and why that treatment
- How outliers were handled — capped, removed, retained — and the threshold used
- How duplicates were identified and resolved
- Which rows were filtered out and on what basis

**Analysis**
- Mean vs median, and why
- Time period chosen, and why that window
- Segmentation cut points — why those boundaries and not others
- Statistical test selected, and why it suits the data
- Significance threshold, and whether it was set before or after looking
- Model chosen over alternatives
- Features included or dropped

**Presentation**
- Chart type, where the choice was non-obvious
- What was left out of the dashboard, and why
- Level of aggregation shown to the stakeholder
- Which findings were promoted to the README and which were not

**Scope**
- Questions deferred to the backlog
- Analysis attempted and abandoned — **record these; they are honest and interviewers respect them**

---

## Decision Quality Check

- [ ] Every non-obvious choice has an entry
- [ ] Each entry states what the decision costs, not only its benefits
- [ ] Alternatives are recorded, not just the choice
- [ ] Anything that materially affects a finding is flagged in the README's Limitations section
- [ ] I could defend each of these out loud without notes
