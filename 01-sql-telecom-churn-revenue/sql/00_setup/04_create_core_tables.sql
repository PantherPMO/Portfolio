/* ============================================================
   Project : 01 — Telecommunications Revenue Retention
   File    : 00_setup/04_create_core_tables.sql
   Stage   : PREPARE
   Purpose : Typed, keyed, constrained core layer.
             The raw -> core boundary is where the approved field exclusions
             become STRUCTURAL. Excluded fields are not filtered here; they
             simply do not exist. See DECISIONS.md D-11..D-15, D-18.
   Author  : Peters
   Created : 2026-08-19
   ============================================================ */

/* ---- Yes/No cast helper --------------------------------------------------
   Stage 2 verified every flag in the relational source is strictly two-valued.
   A third value therefore means the verification was wrong: raise, do not
   default. Silent coercion of an unexpected value is how wrong numbers happen. */
CREATE OR REPLACE FUNCTION core.yn_to_bool(v text)
RETURNS boolean AS $fn$
BEGIN
    IF   v = 'Yes' THEN RETURN true;
    ELSIF v = 'No' THEN RETURN false;
    ELSE RAISE EXCEPTION
        'core.yn_to_bool: unexpected value %. Expected exactly Yes or No. '
        'This contradicts Stage 2 verification — STOP and escalate.', quote_literal(v);
    END IF;
END;
$fn$ LANGUAGE plpgsql IMMUTABLE;

DROP TABLE IF EXISTS core.bridge_customer_service CASCADE;
DROP TABLE IF EXISTS core.dim_service            CASCADE;
DROP TABLE IF EXISTS core.fact_customer_status   CASCADE;
DROP TABLE IF EXISTS core.dim_contract           CASCADE;
DROP TABLE IF EXISTS core.dim_location           CASCADE;
DROP TABLE IF EXISTS core.dim_population         CASCADE;
DROP TABLE IF EXISTS core.restricted_demographics CASCADE;
DROP TABLE IF EXISTS core.dim_customer           CASCADE;

/* ---- dim_customer : one row per customer -------------------------------- */
CREATE TABLE core.dim_customer (
    customer_id      varchar(10) PRIMARY KEY,
    is_married       boolean  NOT NULL,
    has_dependents   boolean  NOT NULL,
    dependent_count  smallint NOT NULL CHECK (dependent_count >= 0)
);
COMMENT ON TABLE core.dim_customer IS
  'Grain: one row per customer. Expected 7,043. Protected-characteristic fields '
  '(gender, age, under_30, senior_citizen) are deliberately NOT here — see '
  'core.restricted_demographics and DECISIONS.md D-15.';

/* ---- restricted_demographics : QUARANTINED ------------------------------ */
CREATE TABLE core.restricted_demographics (
    customer_id        varchar(10) PRIMARY KEY REFERENCES core.dim_customer(customer_id),
    gender             varchar(10) NOT NULL,
    age                smallint    NOT NULL CHECK (age BETWEEN 0 AND 120),
    is_under_30        boolean     NOT NULL,
    is_senior_citizen  boolean     NOT NULL
);
COMMENT ON TABLE core.restricted_demographics IS
  'RESTRICTED — DECISION D-15. Protected characteristics. These fields may be used '
  'ONLY for descriptive and confounding checks (sql/02_eda/09_confounding_checks.sql). '
  'They MUST NOT enter any prioritisation rule, segment definition, KPI or '
  'recommendation. No analytical view joins this table. Check VAL-09 enforces it.';

/* ---- dim_population : one row per zip code ------------------------------ */
CREATE TABLE core.dim_population (
    zip_code       char(5) PRIMARY KEY,
    population_id  integer NOT NULL UNIQUE,
    population     integer NOT NULL CHECK (population >= 0)
);
COMMENT ON COLUMN core.dim_population.zip_code IS
  'Stored as text: an identifier, not a quantity. Preserves leading zeros; no '
  'arithmetic on it is meaningful.';

/* ---- dim_location : one row per customer -------------------------------- */
CREATE TABLE core.dim_location (
    customer_id  varchar(10) PRIMARY KEY REFERENCES core.dim_customer(customer_id),
    city         varchar(64) NOT NULL,
    zip_code     char(5)     NOT NULL REFERENCES core.dim_population(zip_code),
    latitude     numeric(9,6) NOT NULL,
    longitude    numeric(9,6) NOT NULL
);
COMMENT ON TABLE core.dim_location IS
  'Country and State dropped — verified constant (United States / California). '
  'Lat Long dropped — redundant composite. latitude/longitude loaded but out of '
  'analytical scope: no business question requires geospatial analysis.';

/* ---- dim_contract : one row per customer -------------------------------- */
CREATE TABLE core.dim_contract (
    customer_id           varchar(10) PRIMARY KEY REFERENCES core.dim_customer(customer_id),
    contract_type         varchar(16) NOT NULL
        CHECK (contract_type IN ('Month-to-Month','One Year','Two Year')),
    payment_method        varchar(20) NOT NULL
        CHECK (payment_method IN ('Bank Withdrawal','Credit Card','Mailed Check')),
    is_paperless_billing  boolean     NOT NULL,
    offer                 varchar(10) NOT NULL,   -- nulls -> 'No offer'
    internet_type         varchar(12) NOT NULL,   -- nulls -> 'No internet'
    has_referred          boolean     NOT NULL,
    referral_count        smallint    NOT NULL CHECK (referral_count >= 0)
);
COMMENT ON COLUMN core.dim_contract.offer IS
  'Source nulls (3,877) mapped to ''No offer''. STRUCTURAL, not missing data: '
  'absence of a promotional offer is a meaningful commercial state and is the '
  'comparison group for driver lens L6. Never imputed.';
COMMENT ON COLUMN core.dim_contract.internet_type IS
  'Source nulls (1,526) mapped to ''No internet''. STRUCTURAL: verified to '
  'correspond exactly to Internet Service = No. Never imputed.';

/* ---- fact_customer_status : one row per customer per quarter ------------ */
CREATE TABLE core.fact_customer_status (
    customer_id                  varchar(10) PRIMARY KEY REFERENCES core.dim_customer(customer_id),
    quarter                      char(2)      NOT NULL,
    tenure_months                smallint     NOT NULL CHECK (tenure_months BETWEEN 1 AND 72),
    monthly_charge               numeric(12,4) NOT NULL CHECK (monthly_charge > 0),
    avg_monthly_long_distance    numeric(12,4) NOT NULL CHECK (avg_monthly_long_distance >= 0),
    avg_monthly_gb               smallint      NOT NULL CHECK (avg_monthly_gb >= 0),
    total_charges                numeric(12,4) NOT NULL,
    total_refunds                numeric(12,4) NOT NULL,
    total_extra_data_charges     numeric(12,4) NOT NULL,
    total_long_distance_charges  numeric(12,4) NOT NULL,
    total_revenue_source         numeric(12,4) NOT NULL,
    customer_status              varchar(10)   NOT NULL
        CHECK (customer_status IN ('Stayed','Churned','Joined')),
    is_churned                   boolean       NOT NULL
);
COMMENT ON COLUMN core.fact_customer_status.monthly_charge IS
  'THE UNIT OF ACCOUNT — decision C-2 / D-07. Verified a stable recurring rate '
  '(median Total Charges / (Monthly Charge x tenure) = 1.0000). Annualised x12 for '
  'revenue at risk. Currency UNKNOWN — see DATASET_VALIDATION P-15. Never label as GBP.';
COMMENT ON COLUMN core.fact_customer_status.total_charges IS
  'Lifetime cumulative. VALIDATION ONLY (check REC-08). Never the revenue-at-risk basis.';
COMMENT ON COLUMN core.fact_customer_status.total_revenue_source IS
  'Loaded so the independent recomputation in REC-08 has something to be checked '
  'against. NEVER used in analysis — every revenue aggregate is recomputed.';
COMMENT ON COLUMN core.fact_customer_status.quarter IS
  'Constant Q3. Retained deliberately: it documents that the schema anticipates a '
  'period dimension and that only one period exists. Confirms risk R-01.';

/* ---- dim_service / bridge ----------------------------------------------- */
CREATE TABLE core.dim_service (
    service_code   varchar(12) PRIMARY KEY,
    service_name   varchar(32) NOT NULL,
    service_group  varchar(16) NOT NULL
        CHECK (service_group IN ('Core','Add-on','Entertainment')),
    sort_order     smallint    NOT NULL
);
COMMENT ON COLUMN core.dim_service.service_group IS
  'Drives the L5 add-on count, which is LOCKED at the 8 non-Core services by '
  'decision C-6. Core services (phone, multi-line, internet) are in the bridge for '
  'service-mix analysis but are excluded from the intensity count.';

CREATE TABLE core.bridge_customer_service (
    customer_id    varchar(10) NOT NULL REFERENCES core.dim_customer(customer_id),
    service_code   varchar(12) NOT NULL REFERENCES core.dim_service(service_code),
    is_subscribed  boolean     NOT NULL,
    PRIMARY KEY (customer_id, service_code)
);
COMMENT ON TABLE core.bridge_customer_service IS
  'THE ONLY FAN-OUT IN THE MODEL. Joining this multiplies customer rows. It is '
  'aggregated to customer grain INSIDE analytics.vw_customer_analytical_base so '
  'downstream queries never touch it. Check VAL-02 asserts row count unchanged.';

SELECT table_name,
       (SELECT count(*) FROM information_schema.columns c
         WHERE c.table_schema='core' AND c.table_name=t.table_name) AS columns
FROM   information_schema.tables t
WHERE  table_schema='core' AND table_type='BASE TABLE'
ORDER  BY table_name;
