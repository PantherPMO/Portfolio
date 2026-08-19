# SQL Standards

**Engine:** PostgreSQL 15+
**Applies to:** projects 01 and 02, and any SQL elsewhere in the portfolio.

SQL in a portfolio is read by a technical interviewer. It is judged on readability and reasoning as much as on whether it returns the right answer.

---

## 1. File Organisation

```
sql/
├── 00_setup/          Schema DDL, load scripts, indexes
├── 01_cleaning/       Standardisation, deduplication, type fixes
├── 02_eda/            Profiling and exploration
├── 03_analysis/       One numbered file per business question
└── 04_kpi_views/      Reusable views feeding the BI layer
```

- Files numbered in **execution order**: `03_analysis/01_churn_by_tenure.sql`
- One file per business question — a reviewer should locate the answer without reading everything
- File name describes the question, not the technique

---

## 2. File Header

Every `.sql` file opens with this block:

```sql
/* ============================================================
   Project    : 01 — Telecom Churn & Revenue Analytics
   File       : 03_analysis/01_churn_by_tenure.sql
   Question   : BQ-02 — At what point in the customer lifecycle
                do we lose most customers?
   Finding ID : F-02
   Output     : analysis/query_results/01_churn_by_tenure.csv
   Author     : Peters
   Created    : 2026-08-19
   ============================================================ */
```

This is the evidence chain made machine-findable. It is also the thing that lets you answer *"which query produced that number?"* instantly at interview.

---

## 3. Formatting

**Keywords uppercase, identifiers lowercase snake_case.**

```sql
SELECT
    c.customer_id,
    c.contract_type,
    COUNT(*)                                    AS customer_count,
    ROUND(AVG(c.monthly_charges)::numeric, 2)   AS avg_monthly_charges,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE c.churned) / COUNT(*),
        1
    )                                           AS churn_rate_pct
FROM   customers AS c
WHERE  c.tenure_months >= 1
GROUP  BY c.customer_id, c.contract_type
HAVING COUNT(*) > 10
ORDER  BY churn_rate_pct DESC;
```

Rules:
- One column per line in `SELECT`
- Column aliases aligned where it aids scanning
- Explicit `AS` for table and column aliases
- Meaningful aliases — `c` for customers is fine, `t1` is not
- Leading commas or trailing commas — pick one, stay consistent (trailing is used above)
- Indent 4 spaces; never tabs
- Line length ≤ 100 characters

---

## 4. CTEs over Nested Subqueries

Always. A nested subquery three levels deep is unreadable; a chain of named CTEs reads like an argument.

```sql
WITH monthly_revenue AS (
    -- Revenue per customer per month, active customers only
    SELECT
        customer_id,
        DATE_TRUNC('month', transaction_date) AS month,
        SUM(amount)                           AS revenue
    FROM   transactions
    WHERE  status = 'completed'
    GROUP  BY customer_id, DATE_TRUNC('month', transaction_date)
),

customer_trend AS (
    -- Month-on-month change, to identify declining accounts
    SELECT
        customer_id,
        month,
        revenue,
        LAG(revenue) OVER (PARTITION BY customer_id ORDER BY month) AS prior_revenue
    FROM   monthly_revenue
)

SELECT *
FROM   customer_trend
WHERE  prior_revenue IS NOT NULL
  AND  revenue < prior_revenue * 0.8;
```

- Name CTEs for what they contain, not `cte1`
- Comment each CTE with its purpose in one line
- Blank line between CTEs

---

## 5. Joins

- **Always explicit:** `INNER JOIN`, `LEFT JOIN` — never comma joins, never implicit
- **Always qualified:** every column prefixed with its table alias in a multi-table query
- **State the grain** in a comment when a join changes it — fan-out is the most common source of silently wrong numbers

```sql
-- LEFT JOIN: keeps customers with no transactions (needed for churn base)
-- Grain remains one row per customer — orders are pre-aggregated in the CTE
FROM       customers   AS c
LEFT JOIN  order_summary AS o ON o.customer_id = c.customer_id
```

---

## 6. Comments

Comment the **why**, never the what.

```sql
-- Bad
-- Select customers where tenure is greater than zero
WHERE tenure_months > 0

-- Good
-- Exclude tenure = 0: these are same-month signups with no billing history,
-- and their null TotalCharges would distort ARPU. 11 rows. See DECISIONS.md D-03.
WHERE tenure_months > 0
```

Every business rule, exclusion, and threshold gets a comment explaining the reasoning and, where relevant, pointing to `DECISIONS.md`.

---

## 7. Correctness Practices

- **Never `SELECT *`** in analysis queries. Acceptable in an outer CTE select; never in a final result set
- **Handle division by zero:** `NULLIF(denominator, 0)`
- **Cast before dividing:** integer division silently truncates — `100.0 * a / b` or `a::numeric / b`
- **Round only at the final step**, never mid-calculation
- **`COUNT(*)` vs `COUNT(column)`** — know which you mean; they differ on NULLs
- **Verify grain after every join.** `SELECT COUNT(*)` before and after is a habit worth keeping
- **`FILTER (WHERE ...)`** is preferred over `CASE WHEN` inside aggregates in PostgreSQL — clearer intent

---

## 8. Naming

| Object | Convention | Example |
|--------|-----------|---------|
| Table | plural snake_case | `customers`, `order_lines` |
| Column | singular snake_case | `customer_id`, `monthly_charges` |
| Boolean | `is_` / `has_` prefix | `is_churned`, `has_dependents` |
| Date | `_date` suffix | `signup_date` |
| Timestamp | `_at` suffix | `created_at` |
| Percentage | `_pct` suffix | `churn_rate_pct` |
| Currency | `_gbp` where ambiguous | `revenue_gbp` |
| CTE | descriptive noun phrase | `monthly_revenue` |
| View | `vw_` prefix | `vw_customer_kpis` |

---

## 9. Performance

Not the priority at portfolio scale, but demonstrate awareness:

- Index join keys and frequent filter columns in `00_setup/`
- Filter early inside CTEs rather than at the end
- Include `EXPLAIN ANALYZE` output in a comment where a query was deliberately optimised — that is a strong interview talking point

---

## 10. Output

Every analysis query writes its result to `analysis/query_results/` as CSV, named to match the query file. This is what makes findings verifiable without a database:

```bash
psql -d telecom -f sql/03_analysis/01_churn_by_tenure.sql \
     --csv -o analysis/query_results/01_churn_by_tenure.csv
```

---

## Pre-Commit Checklist

- [ ] Header block complete, with question and finding ID
- [ ] Runs without error on a clean database
- [ ] Result matches the committed CSV
- [ ] No `SELECT *` in a final result set
- [ ] Grain verified after joins
- [ ] Division-by-zero handled
- [ ] Business rules commented with reasoning
- [ ] Formatted to this standard
- [ ] No credentials, no absolute paths
