/* ============================================================
   Project : 01 — Telecommunications Revenue Retention
   File    : 01_cleaning/05_promote_dim_contract.sql
   Stage   : PREPARE
   Purpose : raw.services -> core.dim_contract.
   Revised : 2026-08-19 — DEFECT FIX, see finding V-10.

   *** V-10 CORRECTION ***
   The original version coalesced NULLs that do not exist. The source workbook
   stores the LITERAL FOUR-CHARACTER STRING 'None' — 3,877 cells in Offer and
   1,526 in Internet Type. There are ZERO true nulls in services.xlsx.

   Stage 2 profiling used pandas, whose read_excel default na_values includes
   the string 'None'. It silently coerced the token to NaN and I documented the
   columns as structurally null. PostgreSQL, which does no such guessing,
   exposed the truth: checks CLEAN-10 and CLEAN-11 both returned 0.

   The mapping below handles the literal token, a true NULL, and an empty
   string. All three resolve to the SAME approved category label. The
   population is unchanged — 3,877 and 1,526 customers, exactly as before.
   This is a LABEL repair, not a change to any approved definition.
   ============================================================ */

TRUNCATE core.dim_contract;

INSERT INTO core.dim_contract
       (customer_id, contract_type, payment_method, is_paperless_billing,
        offer, internet_type, has_referred, referral_count)
SELECT trim(customer_id),
       trim(contract),
       trim(payment_method),
       core.yn_to_bool(trim(paperless_billing)),
       /* literal 'None' | true NULL | empty string  ->  'No offer' */
       CASE WHEN offer IS NULL
              OR trim(offer) = ''
              OR trim(offer) = 'None'  THEN 'No offer'
            ELSE trim(offer) END,
       /* literal 'None' | true NULL | empty string  ->  'No internet' */
       CASE WHEN internet_type IS NULL
              OR trim(internet_type) = ''
              OR trim(internet_type) = 'None'  THEN 'No internet'
            ELSE trim(internet_type) END,
       core.yn_to_bool(trim(referred_a_friend)),
       trim(number_of_referrals)::smallint
FROM   raw.services;

SELECT 'CLEAN-09' AS check_id, 'dim_contract rows' AS description,
       7043 AS expected, count(*) AS actual,
       CASE WHEN count(*) = 7043 THEN 'PASS' ELSE 'FAIL' END AS status
FROM   core.dim_contract
UNION ALL
SELECT 'CLEAN-10', 'offer = ''No offer'' (V-10: literal ''None'' token)', 3877,
       count(*) FILTER (WHERE offer = 'No offer'),
       CASE WHEN count(*) FILTER (WHERE offer = 'No offer') = 3877 THEN 'PASS' ELSE 'FAIL' END
FROM   core.dim_contract
UNION ALL
SELECT 'CLEAN-11', 'internet_type = ''No internet'' (V-10: literal ''None'' token)', 1526,
       count(*) FILTER (WHERE internet_type = 'No internet'),
       CASE WHEN count(*) FILTER (WHERE internet_type = 'No internet') = 1526 THEN 'PASS' ELSE 'FAIL' END
FROM   core.dim_contract
UNION ALL
/* V-10 guard: no residual 'None' token may survive promotion in either column. */
SELECT 'CLEAN-10b', 'residual literal ''None'' in offer or internet_type', 0,
       count(*) FILTER (WHERE offer = 'None' OR internet_type = 'None'),
       CASE WHEN count(*) FILTER (WHERE offer = 'None' OR internet_type = 'None') = 0
            THEN 'PASS' ELSE 'FAIL' END
FROM   core.dim_contract;

/* Full inventory after promotion — confirms the populations are unchanged. */
SELECT 'offer' AS field, offer AS value, count(*) AS customers
FROM core.dim_contract GROUP BY offer
UNION ALL
SELECT 'internet_type', internet_type, count(*)
FROM core.dim_contract GROUP BY internet_type
ORDER BY 1, 3 DESC;
