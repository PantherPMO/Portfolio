/* ============================================================
   File   : 01_cleaning/07_build_bridge_customer_service.sql
   Stage  : PREPARE
   Purpose: Unpivot the eleven wide Yes/No service columns in raw.services
            into core.bridge_customer_service.

   Why unpivot at all: eleven boolean columns is a wide-format anti-pattern.
   Normalising turns the service-mix driver analysis (AQ-05) from eleven CASE
   expressions into an aggregation over a relation, and makes the L5 add-on
   count a filter on service_group rather than a hand-maintained list.

   The relational source uses CLEAN Yes/No only. The 'No internet service' /
   'No phone service' sentinels exist ONLY in the merged workbook (finding V-06),
   so no sentinel handling is required here. core.yn_to_bool will raise if one
   ever appears.
   ============================================================ */

TRUNCATE core.bridge_customer_service;

INSERT INTO core.bridge_customer_service (customer_id, service_code, is_subscribed)
SELECT trim(s.customer_id), v.service_code, core.yn_to_bool(trim(v.flag))
FROM   raw.services AS s
CROSS  JOIN LATERAL (VALUES
        ('PHONE',      s.phone_service),
        ('MULTI_LINE', s.multiple_lines),
        ('INTERNET',   s.internet_service),
        ('ONLINE_SEC', s.online_security),
        ('ONLINE_BAK', s.online_backup),
        ('DEV_PROT',   s.device_protection_plan),
        ('TECH_SUP',   s.premium_tech_support),
        ('UNLIM_DATA', s.unlimited_data),
        ('STREAM_TV',  s.streaming_tv),
        ('STREAM_MOV', s.streaming_movies),
        ('STREAM_MUS', s.streaming_music)
       ) AS v(service_code, flag);

SELECT 'CLEAN-17' AS check_id, 'bridge rows (7,043 x 11)' AS description,
       77473 AS expected, count(*) AS actual,
       CASE WHEN count(*) = 77473 THEN 'PASS' ELSE 'FAIL' END AS status
FROM   core.bridge_customer_service
UNION ALL
SELECT 'CLEAN-18', 'distinct customers in bridge', 7043, count(DISTINCT customer_id),
       CASE WHEN count(DISTINCT customer_id) = 7043 THEN 'PASS' ELSE 'FAIL' END
FROM   core.bridge_customer_service
UNION ALL
SELECT 'CLEAN-19', 'services per customer (must be 11 for every customer)', 11,
       max(n), CASE WHEN min(n) = 11 AND max(n) = 11 THEN 'PASS' ELSE 'FAIL' END
FROM   (SELECT count(*) AS n FROM core.bridge_customer_service GROUP BY customer_id) q;

/* Subscribed counts per service — for the record, not a finding. */
SELECT d.service_group, d.service_code, d.service_name,
       count(*) FILTER (WHERE b.is_subscribed) AS subscribed,
       count(*)                                AS total
FROM   core.bridge_customer_service AS b
JOIN   core.dim_service             AS d ON d.service_code = b.service_code
GROUP  BY d.service_group, d.service_code, d.service_name, d.sort_order
ORDER  BY d.sort_order;
