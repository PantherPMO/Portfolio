# Quality Gate Checklist

The sixteen-point review every project must pass before it ships.

Copy [`templates/QUALITY_GATE_TEMPLATE.md`](templates/QUALITY_GATE_TEMPLATE.md) into the project as `QUALITY_GATE.md` and score it there.

---

## How to Score

| Score | Meaning |
|-------|---------|
| **3** | Strong — would stand up to a senior analyst's questioning |
| **2** | Acceptable — adequate, with a known weakness that is documented |
| **1** | Weak — needs work before shipping |
| **0** | Absent |

**Pass condition:** every item scores 2 or 3, **and** the six weighted items score 3.

**Score honestly.** A gate that always passes is not a gate — it is decoration. The purpose is to catch the weakness before an interviewer does.

---

## The Sixteen Dimensions

Items marked ⚖️ are **weighted** — they must score 3. They are what separates this portfolio from a collection of dashboards.

### 1. Business Problem ⚖️
- [ ] A real business problem is stated, not a dataset description
- [ ] A specific stakeholder role is named
- [ ] The decision the analysis informs is explicit
- [ ] The cost of *not* solving it is stated
- [ ] Someone in that role would recognise this as their problem

### 2. Dataset Credibility
- [ ] Source is reputable and named
- [ ] Direct URL works
- [ ] Licence checked and recorded
- [ ] Registered in `DATASET_REGISTRY.md`
- [ ] Synthetic data (if any) approved, logged and prominently labelled
- [ ] The dataset genuinely fits the business question

### 3. Data Quality
- [ ] Completeness, uniqueness, validity and consistency profiled
- [ ] Missing values quantified and their pattern investigated
- [ ] Outliers identified and a treatment decision recorded
- [ ] Quality issues documented rather than silently fixed
- [ ] Limitations flow through to the README

### 4. Data Cleaning
- [ ] Every transformation is scripted and reproducible
- [ ] `data/raw/` is untouched
- [ ] Row counts reconciled before and after; every difference explained
- [ ] Cleaning decisions justified in `DECISIONS.md`
- [ ] Data dictionary matches the cleaned data

### 5. Exploratory Data Analysis
- [ ] Distributions of key variables examined
- [ ] Relationships explored before modelling or segmentation
- [ ] EDA is directed at the framed questions, not aimless
- [ ] Findings from EDA are carried forward, not abandoned
- [ ] Surprises are investigated rather than ignored

### 6. Analytical Methodology ⚖️
- [ ] The approach is appropriate to the question
- [ ] It is documented in `METHODOLOGY.md` well enough to be repeated
- [ ] Assumptions are stated
- [ ] Statistical choices are justified (test selection, significance, effect size)
- [ ] Alternatives considered and rejection reasons recorded
- [ ] Would survive a senior analyst asking "why did you do it that way?"

### 7. Business Questions
- [ ] Written in the stakeholder's language
- [ ] Each maps to a specific analytical question
- [ ] Each is actually answered in the analysis
- [ ] Answers appear in the README, not only in the code

### 8. KPI Quality
- [ ] Each KPI has formula, grain, and unit
- [ ] Consistent with `KPI_LIBRARY.md`
- [ ] Benchmarks or targets stated, with a source
- [ ] Each KPI is decision-relevant, not decorative
- [ ] Calculations independently verifiable from committed results

### 9. Visualisation Quality
- [ ] Chart type suits the data relationship
- [ ] Follows `STYLE_GUIDE.md`
- [ ] Titles state the finding, not the variable ("Churn peaks in month 1" not "Churn by tenure")
- [ ] Axes labelled with units
- [ ] Accessible — colour is not the only signal; contrast checked
- [ ] No chartjunk, no misleading axis truncation
- [ ] Legible at GitHub's rendered width

### 10. Business Insights ⚖️
- [ ] Every insight is evidenced by a named artifact
- [ ] Finding → insight → implication → recommendation progression complete
- [ ] Insights explain *why*, with a mechanism — not just *what*
- [ ] Quantified in business terms (£, days, %, headcount)
- [ ] **Nothing invented.** Every number traceable
- [ ] Non-obvious — states something a stakeholder did not already know

### 11. Recommendations ⚖️
- [ ] Follow logically from the implications
- [ ] Specific and actionable, not "monitor closely"
- [ ] Owner identified
- [ ] Expected impact estimated, with the basis stated
- [ ] Feasibility and cost acknowledged
- [ ] Prioritised
- [ ] A stakeholder could act on these on Monday morning

### 12. Reproducibility
- [ ] Someone else could rerun this from the README alone
- [ ] Dependencies documented
- [ ] Scripts run in a stated order
- [ ] File paths relative, not absolute
- [ ] No credentials in code
- [ ] Data retrieval instructions work

### 13. Documentation
- [ ] README complete, recruiter summary at the top
- [ ] All applicable sections of the 28-section structure present
- [ ] Data dictionary complete
- [ ] Methodology, decisions and findings documented
- [ ] Links work; images render on GitHub
- [ ] British English; no typos

### 14. Code Quality
- [ ] SQL follows `SQL_STANDARDS.md`
- [ ] Files numbered in execution order
- [ ] Comments explain *why*, not *what*
- [ ] Consistent naming
- [ ] No dead code, no commented-out experiments
- [ ] DAX and M documented as readable text, not trapped in binaries
- [ ] Excel workbook logic explained in `WORKBOOK_GUIDE.md`

### 15. Stakeholder Communication ⚖️
- [ ] `STAKEHOLDER_STORY.md` complete, all six questions answered
- [ ] The 5-minute presentation narrative is written out
- [ ] Leads with the answer, not the method
- [ ] Free of unexplained jargon
- [ ] Limitations stated honestly
- [ ] A non-analyst would understand the conclusion

### 16. Portfolio Presentation ⚖️
- [ ] The 90-second summary block sells the project
- [ ] A hero image exists and is compelling
- [ ] Tools clearly listed
- [ ] Renders correctly on GitHub
- [ ] Visually consistent with the other projects
- [ ] `INTERVIEW_BRIEF.md` updated
- [ ] Peters could confidently discuss this in an interview tomorrow

---

## Final Questions

Before ticking the gate:

1. **Would I be comfortable if a senior analyst read every line of this?**
2. **Can I defend every number in it?**
3. **Does this demonstrate reasoning, or only tool use?**
4. **If asked "what would you do differently?", do I have a good answer?**
5. **Is there anything in here I could not explain out loud?**

If the answer to any of these is uncomfortable, the project is not finished.
