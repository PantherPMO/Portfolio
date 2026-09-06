/* ============================================================
   Project    : 02 — Warehouse Inventory & Supply Chain Performance
   File       : 03_preparation/01_resolve_duplicate_customer_accounts.sql
   Question   : How many customers does the business actually have?
   Output     : view supply.vw_customer_resolved
   Author     : Peters
   Created    : 2026-08-23
   ============================================================

   The trade counter opened some accounts twice — the same business,
   registered again at a different branch under a slightly different
   trading name. Left unresolved, one buyer's spend is split across two
   account numbers and every concentration measure understates the top
   of the base.

   The source table is not modified. This view adds a resolved account
   alongside the original, so any analysis can use either and the
   duplicates remain visible as a data quality finding.

   Matching rule: identical normalised trading name AND identical
   postcode district. Both must agree — name alone would merge genuinely
   separate branches of the same group, which are different customers
   with different credit limits and different buyers.
   ============================================================ */

SET search_path TO supply;

CREATE OR REPLACE VIEW vw_customer_resolved AS

WITH normalised AS (
    SELECT
        c.customer_account,
        c.customer_name,
        c.customer_segment,
        c.region,
        c.postcode_district,
        c.primary_warehouse_code,
        c.account_opened_date,
        c.credit_limit_gbp,
        c.account_status,
        -- Observed variants: " Limited" for " Ltd", upper-casing, and "JR" for
        -- "J R". Whitespace is collapsed last so the comparison is stable.
        REGEXP_REPLACE(
            REPLACE(
                REPLACE(UPPER(c.customer_name), ' LIMITED', ' LTD'),
                'JR ', 'J R '),
            '\s+', ' ', 'g')                         AS normalised_name
    FROM   customer AS c
),

ranked AS (
    SELECT
        n.*,
        COUNT(*)     OVER (PARTITION BY n.normalised_name, n.postcode_district)
                                                     AS accounts_in_group,
        -- The oldest account survives: it carries the trading history.
        FIRST_VALUE(n.customer_account) OVER (
            PARTITION BY n.normalised_name, n.postcode_district
            ORDER BY     n.account_opened_date, n.customer_account
        )                                            AS resolved_account
    FROM   normalised AS n
)

SELECT
    r.customer_account,
    r.resolved_account,
    r.customer_name,
    r.normalised_name,
    r.customer_segment,
    r.region,
    r.postcode_district,
    r.primary_warehouse_code,
    r.account_opened_date,
    r.credit_limit_gbp,
    r.account_status,
    r.accounts_in_group,
    r.customer_account <> r.resolved_account         AS is_duplicate_of_older_account
FROM   ranked AS r;


\echo '=== Duplicate resolution summary ==='

SELECT
    COUNT(*)                                                     AS accounts_on_file,
    COUNT(DISTINCT resolved_account)                             AS distinct_customers,
    COUNT(*) FILTER (WHERE is_duplicate_of_older_account)        AS duplicate_accounts,
    COUNT(DISTINCT resolved_account) FILTER (WHERE accounts_in_group > 1)
                                                                 AS affected_customer_groups
FROM   vw_customer_resolved;


\echo '=== Effect on customer concentration, 2025 ==='

-- The reason this matters: the top-10 share is the headline number in any
-- customer concentration analysis, and it moves when the duplicates are joined.
WITH line_revenue AS (
    SELECT
        so.customer_account,
        cr.resolved_account,
        sol.quantity_despatched * sol.unit_price_gbp AS revenue_gbp
    FROM       sales_order_line     AS sol
    INNER JOIN sales_order          AS so ON so.sales_order_number = sol.sales_order_number
    INNER JOIN vw_customer_resolved AS cr ON cr.customer_account = so.customer_account
    WHERE      sol.line_status <> 'Cancelled'
      AND      so.order_date BETWEEN DATE '2025-01-01' AND DATE '2025-12-31'
),

raw_rank AS (
    SELECT customer_account, SUM(revenue_gbp) AS revenue_gbp
    FROM   line_revenue GROUP BY customer_account
),

resolved_rank AS (
    SELECT resolved_account, SUM(revenue_gbp) AS revenue_gbp
    FROM   line_revenue GROUP BY resolved_account
)

SELECT
    'Raw accounts'                                                        AS basis,
    COUNT(*)                                                              AS customers,
    ROUND(100.0 * SUM(revenue_gbp) FILTER (WHERE rank_position <= 10)
          / NULLIF(SUM(revenue_gbp), 0), 1)                               AS top_10_share_pct
FROM  (SELECT revenue_gbp, ROW_NUMBER() OVER (ORDER BY revenue_gbp DESC) AS rank_position
       FROM   raw_rank) AS r
UNION ALL
SELECT
    'Resolved customers',
    COUNT(*),
    ROUND(100.0 * SUM(revenue_gbp) FILTER (WHERE rank_position <= 10)
          / NULLIF(SUM(revenue_gbp), 0), 1)
FROM  (SELECT revenue_gbp, ROW_NUMBER() OVER (ORDER BY revenue_gbp DESC) AS rank_position
       FROM   resolved_rank) AS r;
