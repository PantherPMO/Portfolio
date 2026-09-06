/* ============================================================
   Project    : 02 — Warehouse Inventory & Supply Chain Performance
   File       : 02_validation/02_reconcile_ledger_to_weekly_snapshots.sql
   Question   : Can every weekly stock position be rebuilt from the
                movement ledger alone?
   Output     : analysis/query_results/validate_02_ledger_reconciliation.txt
   Author     : Peters
   Created    : 2026-08-23
   ============================================================

   Two identities are tested on all 51,220 snapshot rows:

     (1) quantity_on_hand(W) = SUM(quantity WHERE movement_date <= W)
     (2) quantity_on_hand(W) = quantity_on_hand(W-1) + movements in W

   Identity (1) is the stronger of the two because it proves the whole
   ledger from zero rather than one week at a time. It only works
   because opening balances at 2024-01-01 were posted as dated
   'Opening balance' movements rather than set as an initial state.

   Every stocked pair has a snapshot row for every week it was stocked,
   including weeks with no movement, so no date spine needs generating.
   ============================================================ */

SET search_path TO supply;

\echo '=== 1. Movements that fall outside the weekly grid ==='

-- The last week ends 2025-12-28. Movements on 29-31 December belong to no
-- snapshot week and are excluded from the rebuild rather than being folded
-- into the final week, which would silently break both identities.
SELECT
    COUNT(*)                                         AS movements_after_last_week,
    MIN(movement_date)                               AS earliest,
    MAX(movement_date)                               AS latest,
    SUM(quantity)                                    AS net_units_excluded
FROM   stock_movement
WHERE  movement_date > (SELECT MAX(week_ending_date) FROM calendar_week);


\echo '=== 2. Rebuild and compare ==='

WITH movement_in_week AS (
    -- INNER JOIN to calendar_week is what drops the post-grid movements above.
    SELECT
        sm.sku,
        sm.warehouse_code,
        cw.week_ending_date,
        SUM(sm.quantity)                             AS week_movement_units
    FROM       stock_movement AS sm
    INNER JOIN calendar_week  AS cw
           ON  sm.movement_date BETWEEN cw.week_starting_date AND cw.week_ending_date
    GROUP  BY sm.sku, sm.warehouse_code, cw.week_ending_date
),

rebuilt AS (
    -- Grain stays one row per snapshot: movement_in_week is pre-aggregated to
    -- the same key, so the LEFT JOIN cannot fan out.
    SELECT
        inv.week_ending_date,
        inv.sku,
        inv.warehouse_code,
        inv.quantity_on_hand,
        COALESCE(mw.week_movement_units, 0)          AS week_movement_units,
        SUM(COALESCE(mw.week_movement_units, 0)) OVER (
            PARTITION BY inv.sku, inv.warehouse_code
            ORDER BY     inv.week_ending_date
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        )                                            AS rebuilt_on_hand,
        LAG(inv.quantity_on_hand) OVER (
            PARTITION BY inv.sku, inv.warehouse_code
            ORDER BY     inv.week_ending_date
        )                                            AS prior_week_on_hand
    FROM      inventory_snapshot AS inv
    LEFT JOIN movement_in_week   AS mw
           ON mw.sku            = inv.sku
          AND mw.warehouse_code = inv.warehouse_code
          AND mw.week_ending_date = inv.week_ending_date
)

SELECT
    'Rows compared'                                                       AS check_name,
    COUNT(*)                                                              AS row_count,
    NULL                                                                  AS result
FROM   rebuilt
UNION ALL
SELECT
    'Identity 1 — cumulative ledger equals snapshot on-hand',
    COUNT(*) FILTER (WHERE quantity_on_hand <> rebuilt_on_hand),
    CASE WHEN COUNT(*) FILTER (WHERE quantity_on_hand <> rebuilt_on_hand) = 0
         THEN 'PASS' ELSE 'FAIL' END
FROM   rebuilt
UNION ALL
SELECT
    'Identity 2 — week-on-week movement reconciles',
    COUNT(*) FILTER (WHERE prior_week_on_hand IS NOT NULL
                       AND quantity_on_hand <> prior_week_on_hand + week_movement_units),
    CASE WHEN COUNT(*) FILTER (WHERE prior_week_on_hand IS NOT NULL
                       AND quantity_on_hand <> prior_week_on_hand + week_movement_units) = 0
         THEN 'PASS' ELSE 'FAIL' END
FROM   rebuilt
UNION ALL
SELECT
    'First snapshot week equals its own movements',
    COUNT(*) FILTER (WHERE prior_week_on_hand IS NULL
                       AND quantity_on_hand <> week_movement_units),
    CASE WHEN COUNT(*) FILTER (WHERE prior_week_on_hand IS NULL
                       AND quantity_on_hand <> week_movement_units) = 0
         THEN 'PASS' ELSE 'FAIL' END
FROM   rebuilt;


\echo '=== 3. Balance never negative at any point in the ledger ==='

WITH running_balance AS (
    SELECT
        sku,
        warehouse_code,
        movement_date,
        SUM(quantity) OVER (
            PARTITION BY sku, warehouse_code
            ORDER BY     movement_date, movement_id
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        )                                            AS balance_after_movement
    FROM   stock_movement
)

SELECT
    COUNT(*) FILTER (WHERE balance_after_movement < 0)  AS negative_balance_events,
    MIN(balance_after_movement)                         AS lowest_balance_reached,
    CASE WHEN COUNT(*) FILTER (WHERE balance_after_movement < 0) = 0
         THEN 'PASS' ELSE 'FAIL' END                    AS result
FROM   running_balance;


\echo '=== 4. Snapshot internal consistency ==='

SELECT
    'stock_value equals on-hand x weighted average cost'  AS check_name,
    COUNT(*) FILTER (WHERE ABS(stock_value_gbp
                    - ROUND(quantity_on_hand * weighted_average_cost_gbp, 2)) > 0.01) AS breaches,
    CASE WHEN COUNT(*) FILTER (WHERE ABS(stock_value_gbp
                    - ROUND(quantity_on_hand * weighted_average_cost_gbp, 2)) > 0.01) = 0
         THEN 'PASS' ELSE 'FAIL' END                                                  AS result
FROM   inventory_snapshot
UNION ALL
SELECT
    'a full zero week closes at zero stock',
    COUNT(*) FILTER (WHERE days_at_zero_in_week = 7 AND quantity_on_hand <> 0),
    CASE WHEN COUNT(*) FILTER (WHERE days_at_zero_in_week = 7 AND quantity_on_hand <> 0) = 0
         THEN 'PASS' ELSE 'FAIL' END
FROM   inventory_snapshot
UNION ALL
SELECT
    'zero closing stock is recorded as at least one zero day',
    COUNT(*) FILTER (WHERE quantity_on_hand = 0 AND days_at_zero_in_week = 0),
    CASE WHEN COUNT(*) FILTER (WHERE quantity_on_hand = 0 AND days_at_zero_in_week = 0) = 0
         THEN 'PASS' ELSE 'FAIL' END
FROM   inventory_snapshot;
