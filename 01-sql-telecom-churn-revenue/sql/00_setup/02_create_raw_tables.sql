/* ============================================================
   Project : 01 — Telecommunications Revenue Retention
   File    : 00_setup/02_create_raw_tables.sql
   Stage   : PREPARE
   Purpose : Landing tables. EVERY column TEXT.
             Rationale: a type failure then surfaces as an explicit, catchable
             error at the promotion step rather than as a silent coercion at
             load time. Column ORDER matches the source workbooks exactly so
             \copy can map by position.
   Author  : Peters
   Created : 2026-08-19
   ============================================================ */

DROP TABLE IF EXISTS raw.demographics;
CREATE TABLE raw.demographics (
    customer_id           text,
    count_col             text,
    gender                text,
    age                   text,
    under_30              text,
    senior_citizen        text,
    married               text,
    dependents            text,
    number_of_dependents  text
);

DROP TABLE IF EXISTS raw.location;
CREATE TABLE raw.location (
    customer_id  text,
    count_col    text,
    country      text,
    state        text,
    city         text,
    zip_code     text,
    lat_long     text,
    latitude     text,
    longitude    text
);

DROP TABLE IF EXISTS raw.population;
CREATE TABLE raw.population (
    population_id  text,
    zip_code       text,
    population     text
);

DROP TABLE IF EXISTS raw.services;
CREATE TABLE raw.services (
    customer_id                        text,
    count_col                          text,
    quarter                            text,
    referred_a_friend                  text,
    number_of_referrals                text,
    tenure_in_months                   text,
    offer                              text,
    phone_service                      text,
    avg_monthly_long_distance_charges  text,
    multiple_lines                     text,
    internet_service                   text,
    internet_type                      text,
    avg_monthly_gb_download            text,
    online_security                    text,
    online_backup                      text,
    device_protection_plan             text,
    premium_tech_support               text,
    streaming_tv                       text,
    streaming_movies                   text,
    streaming_music                    text,
    unlimited_data                     text,
    contract                           text,
    paperless_billing                  text,
    payment_method                     text,
    monthly_charge                     text,
    total_charges                      text,
    total_refunds                      text,
    total_extra_data_charges           text,
    total_long_distance_charges        text,
    total_revenue                      text
);

DROP TABLE IF EXISTS raw.status;
CREATE TABLE raw.status (
    customer_id         text,
    count_col           text,
    quarter             text,
    satisfaction_score  text,   -- EXCLUDED D-14: never promoted to core
    customer_status     text,
    churn_label         text,
    churn_value         text,
    churn_score         text,   -- EXCLUDED D-11: never promoted to core
    cltv                text,   -- EXCLUDED D-12: never promoted to core
    churn_category      text,   -- EXCLUDED D-13: never promoted to core
    churn_reason        text    -- EXCLUDED D-13: never promoted to core
);

/* The merged 33-column workbook. Decision C-1 / D-06: reconciliation ONLY.
   No core or analytics object may reference this table. Check VAL-09 enforces it. */
DROP TABLE IF EXISTS raw.merged_reconciliation;
CREATE TABLE raw.merged_reconciliation (
    customer_id        text,
    count_col          text,
    country            text,
    state              text,
    city               text,
    zip_code           text,
    lat_long           text,
    latitude           text,
    longitude          text,
    gender             text,
    senior_citizen     text,
    partner            text,
    dependents         text,
    tenure_months      text,
    phone_service      text,
    multiple_lines     text,
    internet_service   text,
    online_security    text,
    online_backup      text,
    device_protection  text,
    tech_support       text,
    streaming_tv       text,
    streaming_movies   text,
    contract           text,
    paperless_billing  text,
    payment_method     text,
    monthly_charges    text,
    total_charges      text,
    churn_label        text,
    churn_value        text,
    churn_score        text,
    cltv               text,
    churn_reason       text
);

COMMENT ON TABLE raw.merged_reconciliation IS
  'C-1 / D-06: RECONCILIATION ONLY. Contains 11 corrupted rows (tenure 0, blank '
  'Total Charges), a contradictory payment-method taxonomy (1,227 customers), and '
  'inconsistently collapsed internet categories (830 Cable customers). '
  'MUST NOT be used as an analytical source.';

SELECT table_schema, table_name,
       (SELECT count(*) FROM information_schema.columns c
         WHERE c.table_schema = t.table_schema AND c.table_name = t.table_name) AS columns
FROM   information_schema.tables t
WHERE  table_schema = 'raw'
ORDER  BY table_name;
