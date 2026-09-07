/* ============================================================
   Project : 01 — Telecommunications Revenue Retention
   File    : 00_setup/05_create_dim_service.sql
   Stage   : PREPARE
   Purpose : Populate the service reference dimension (11 rows).
             service_group is the mechanism that keeps the L5 add-on count
             locked at 8 services (decision C-6). It cannot drift because the
             count filters on service_group <> 'Core' rather than on a hand-
             maintained list repeated in each query.
   Author  : Peters
   Created : 2026-08-19
   ============================================================ */

TRUNCATE core.bridge_customer_service;
TRUNCATE core.dim_service CASCADE;

INSERT INTO core.dim_service (service_code, service_name, service_group, sort_order) VALUES
    ('PHONE',      'Phone Service',          'Core',          1),
    ('MULTI_LINE', 'Multiple Lines',         'Core',          2),
    ('INTERNET',   'Internet Service',       'Core',          3),
    ('ONLINE_SEC', 'Online Security',        'Add-on',        4),
    ('ONLINE_BAK', 'Online Backup',          'Add-on',        5),
    ('DEV_PROT',   'Device Protection Plan', 'Add-on',        6),
    ('TECH_SUP',   'Premium Tech Support',   'Add-on',        7),
    ('UNLIM_DATA', 'Unlimited Data',         'Add-on',        8),
    ('STREAM_TV',  'Streaming TV',           'Entertainment', 9),
    ('STREAM_MOV', 'Streaming Movies',       'Entertainment', 10),
    ('STREAM_MUS', 'Streaming Music',        'Entertainment', 11);

SELECT service_group,
       count(*) AS services,
       string_agg(service_code, ', ' ORDER BY sort_order) AS codes
FROM   core.dim_service
GROUP  BY service_group
ORDER  BY min(sort_order);

SELECT 'SETUP-01' AS check_id,
       'dim_service row count'    AS description,
       11                          AS expected,
       count(*)                    AS actual,
       CASE WHEN count(*) = 11 THEN 'PASS' ELSE 'FAIL' END AS status
FROM   core.dim_service
UNION ALL
SELECT 'SETUP-02',
       'L5 add-on services (non-Core) — LOCKED at 8 by C-6',
       8, count(*), CASE WHEN count(*) = 8 THEN 'PASS' ELSE 'FAIL' END
FROM   core.dim_service WHERE service_group <> 'Core';
