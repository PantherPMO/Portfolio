# Data Dictionary — NN: <Project Name>

**Dataset:** <name>
**Registry ID:** DS-NN
**Source:** <URL>
**Version / date accessed:**
**Granularity:** One row = <?>

---

## Table: `<table_name>`

**Rows:** <n> · **Columns:** <n> · **Primary key:** `<field>`

| # | Field | Type | Nullable | Description | Example | Valid values / range | Quality notes |
|---|-------|------|----------|-------------|---------|---------------------|---------------|
| 1 | `customer_id` | text | No | Unique customer identifier | `7590-VHVEG` | 7,043 distinct | Primary key, no duplicates |
| 2 | `tenure_months` | integer | No | Months since signup | `34` | 0–72 | 11 rows at 0 — same-month signups, excluded (see D-03) |
| 3 | `monthly_charges` | numeric | No | Current monthly charge (£) | `29.85` | 18.25–118.75 | |
| 4 | | | | | | | |

---

## Derived Fields

Fields created during preparation. Every one must state its calculation and its purpose.

| Field | Type | Calculation | Created in | Purpose |
|-------|------|-------------|-----------|---------|
| `is_churned` | boolean | `churn_flag = 'Yes'` | `01_cleaning/02_derive_flags.sql` | Target variable for churn analysis |
| `tenure_band` | text | `CASE WHEN tenure_months <= 3 THEN '0-3m' ...` | `01_cleaning/02_derive_flags.sql` | Lifecycle segmentation |
| | | | | |

---

## Categorical Value Definitions

Where a coded value's meaning is not self-evident.

| Field | Value | Meaning | Count | % |
|-------|-------|---------|-------|---|
| `contract_type` | `Month-to-month` | Rolling monthly, 30-day notice | | |
| `contract_type` | `One year` | 12-month minimum term | | |
| | | | | |

---

## Relationships

| From | To | Type | Join key | Notes |
|------|----|------|----------|-------|
| `customers` | `subscriptions` | 1:N | `customer_id` | Fan-out — aggregate before joining to preserve customer grain |
| | | | | |

**Grain warning:** state here every join that changes the grain. Undetected fan-out is the most common cause of silently wrong numbers.

---

## Data Quality Summary

| Field | Missing | Missing % | Distinct | Issue | Treatment |
|-------|---------|-----------|----------|-------|-----------|
| | | | | | |

**Overall completeness:** <%>
**Duplicate rows:** <n>
**Rows failing validity rules:** <n>

---

## Units and Conventions

| Concept | Convention |
|---------|-----------|
| Currency | £ GBP, nominal (not inflation-adjusted) unless stated |
| Dates | ISO 8601 (`YYYY-MM-DD`) |
| Fiscal year | <e.g. April–March> |
| Percentages | Stored as 0–100, not 0–1 |
| Nulls | Distinguish "not applicable" from "not recorded" — state which each null means |

---

## Fields Excluded from Analysis

Excluded fields are a decision, not an oversight. Record them.

| Field | Reason for exclusion |
|-------|---------------------|
| | |
