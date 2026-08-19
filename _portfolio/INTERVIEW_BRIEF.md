# Interview Brief

**Purpose:** to be able to discuss any project in this portfolio confidently, months after building it.

**Rule: each project's section is written at stage 7, while the analysis is fresh.** Written six months later from memory, it is worth a fraction as much. This document is frequently more valuable at interview than the dashboards.

---

## Portfolio-Level Answers

### "Tell me about your portfolio."

> *[Write this once two or three projects are complete. Target: 45 seconds. Structure: what the portfolio demonstrates, the range of business problems covered, and the principle behind it — every project starts from a business decision, not a dataset.]*

### "Why did you build it this way?"

> Every project starts from a business problem and a named stakeholder, not from a dataset. Analysis doesn't begin until the problem, the questions and the method are agreed — because that's how the work is actually done in a business. Each finding is traceable to the query or calculation that produced it, so I can defend any number in there.

### "Which project are you most proud of?"

> *[Complete once projects exist. Pick the one with the strongest reasoning, not the prettiest dashboard.]*

### "What was the hardest part?"

> *[A real difficulty, honestly described, with what you did about it. "Nothing was difficult" is a bad answer.]*

### "What would you do differently?"

> *[Specific and self-aware. This question rewards honesty and punishes defensiveness.]*

---

## Per-Project Template

Copy this block for each completed project.

```markdown
## Project NN — <Name>

**Status:** Complete · Quality gate passed <date>

### 60-Second Pitch
> <Written out verbatim, as you would say it. Structure:
>  1. The business situation and who cared about it
>  2. What you did — one sentence on method
>  3. The headline finding, with a number
>  4. The recommendation and its expected impact>

### The Numbers I Must Remember
| Metric | Value | Context |
|--------|-------|---------|
| Dataset size | | |
| Headline finding | | |
| Quantified impact | | |
| Key KPI result | | |

### Five Likely Questions

**Q1: Why did you choose this dataset?**
> 

**Q2: Why this analytical method rather than <obvious alternative>?**
> 

**Q3: How do you know this finding is real and not noise?**
> 

**Q4: How would you implement this recommendation?**
> 

**Q5: What are the limitations of this analysis?**
> 

### The Weakest Point
**What it is:** <Be honest. Every project has one.>
**How I'd answer it:** <Acknowledge, explain the constraint, state what you'd do with more time or better data. Never defend the indefensible — interviewers respect the analyst who knows where the work is thin.>

### If I Had More Time
1. 
2. 

### Technical Detail I Should Be Able to Recall
- Key SQL technique used and why: 
- Key DAX / Excel technique and why: 
- Statistical method and its assumptions: 
- One thing in the code I'd point to as good work: 

### Tool Decision — Defending What I Didn't Use
> <e.g. "I didn't use Python here because the dataset was 40k rows and the stakeholder worked in Excel. Adding Python would have made the deliverable less usable without making it more accurate.">
```

---

## Project Sections

*None yet — completed as each project passes its quality gate.*

---

## General Interview Preparation

### Questions to expect about any analytics project

| Question | What they're really testing |
|----------|----------------------------|
| Where did the data come from? | Data provenance awareness, honesty |
| How did you handle missing data? | Rigour, and whether you thought about *why* it was missing |
| How do you know that's significant? | Statistical literacy |
| What would you have done with more data? | Awareness of your own limitations |
| How did you decide what to measure? | Business thinking over tool thinking |
| Who was this for? | Stakeholder orientation |
| What happened next / would happen next? | Commercial awareness |
| What did you find that surprised you? | Whether you actually engaged with the data |

### Questions worth asking them

- How does the analytics team currently take a request from question to delivery?
- Who are the main stakeholders, and how do they prefer to receive findings?
- What's the balance between ad-hoc analysis and recurring reporting?
- Where does the team feel its data quality is weakest?

Asking about *process* and *stakeholders* rather than only tools signals that you think like an analyst rather than a report builder.
