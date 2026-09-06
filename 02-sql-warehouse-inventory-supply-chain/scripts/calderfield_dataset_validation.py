"""Validates the exported Calderfield dataset.

Reads the CSV files only. Inventory balances are rebuilt from the movement ledger
rather than taken from the generator, so the reconciliation is an independent check.
"""

from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
import pandas as pd

DATA_DIRECTORY = Path(__file__).resolve().parent.parent / "data" / "synthetic"

EXPECTED_ROWS = {
    "warehouse": 4, "product_category": 8, "product": 250, "supplier": 30,
    "product_supplier": 325, "customer": 500, "calendar_week": 104,
    "replenishment_policy": 515, "purchase_order": 1550, "purchase_order_line": 4400,
    "goods_receipt_line": 5200, "sales_order": 9600, "sales_order_line": 29800,
    "stock_movement": 37700, "inventory_snapshot": 51220,
}

PRIMARY_KEYS = {
    "warehouse": ["warehouse_code"], "product_category": ["category_code"],
    "product": ["sku"], "supplier": ["supplier_code"],
    "product_supplier": ["sku", "supplier_code"], "customer": ["customer_account"],
    "calendar_week": ["week_ending_date"],
    "replenishment_policy": ["sku", "warehouse_code"],
    "purchase_order": ["purchase_order_number"],
    "purchase_order_line": ["purchase_order_number", "line_number"],
    "goods_receipt_line": ["receipt_reference", "line_number"],
    "sales_order": ["sales_order_number"],
    "sales_order_line": ["sales_order_number", "line_number"],
    "stock_movement": ["movement_id"],
    "inventory_snapshot": ["week_ending_date", "sku", "warehouse_code"],
}

FOREIGN_KEYS = [
    ("product", ["category_code"], "product_category", ["category_code"]),
    ("product_supplier", ["sku"], "product", ["sku"]),
    ("product_supplier", ["supplier_code"], "supplier", ["supplier_code"]),
    ("customer", ["primary_warehouse_code"], "warehouse", ["warehouse_code"]),
    ("replenishment_policy", ["sku"], "product", ["sku"]),
    ("replenishment_policy", ["warehouse_code"], "warehouse", ["warehouse_code"]),
    ("purchase_order", ["supplier_code"], "supplier", ["supplier_code"]),
    ("purchase_order", ["warehouse_code"], "warehouse", ["warehouse_code"]),
    ("purchase_order_line", ["purchase_order_number"], "purchase_order", ["purchase_order_number"]),
    ("purchase_order_line", ["sku"], "product", ["sku"]),
    ("goods_receipt_line", ["purchase_order_number", "purchase_order_line_number"],
     "purchase_order_line", ["purchase_order_number", "line_number"]),
    ("goods_receipt_line", ["warehouse_code"], "warehouse", ["warehouse_code"]),
    ("sales_order", ["customer_account"], "customer", ["customer_account"]),
    ("sales_order", ["warehouse_code"], "warehouse", ["warehouse_code"]),
    ("sales_order_line", ["sales_order_number"], "sales_order", ["sales_order_number"]),
    ("sales_order_line", ["sku"], "product", ["sku"]),
    ("stock_movement", ["sku"], "product", ["sku"]),
    ("stock_movement", ["warehouse_code"], "warehouse", ["warehouse_code"]),
    ("inventory_snapshot", ["sku"], "product", ["sku"]),
    ("inventory_snapshot", ["warehouse_code"], "warehouse", ["warehouse_code"]),
    ("inventory_snapshot", ["week_ending_date"], "calendar_week", ["week_ending_date"]),
]

DATE_COLUMNS = {
    "warehouse": ["opened_date"], "product": ["introduced_date", "discontinued_date"],
    "supplier": ["account_opened_date"], "product_supplier": ["price_agreed_date"],
    "customer": ["account_opened_date"],
    "calendar_week": ["week_ending_date", "week_starting_date"],
    "replenishment_policy": ["last_reviewed_date", "stocked_since"],
    "purchase_order": ["order_date", "promised_delivery_date"],
    "goods_receipt_line": ["receipt_date"],
    "sales_order": ["order_date", "requested_delivery_date", "despatch_date"],
    "stock_movement": ["movement_date"], "inventory_snapshot": ["week_ending_date"],
}


class Report:
    def __init__(self):
        self.failures = 0

    def check(self, description, passed, detail=""):
        status = "PASS" if passed else "FAIL"
        if not passed:
            self.failures += 1
        print(f"  [{status}] {description}{f' — {detail}' if detail else ''}")

    def measure(self, description, value):
        print(f"  {description}: {value}")


def load_tables(directory=DATA_DIRECTORY):
    tables = {}
    for name in PRIMARY_KEYS:
        frame = pd.read_csv(directory / f"{name}.csv")
        for column in DATE_COLUMNS.get(name, []):
            frame[column] = pd.to_datetime(frame[column])
        tables[name] = frame
    return tables


def report_row_counts(tables, report):
    print("\nROW COUNTS")
    total = 0
    for name, expected in EXPECTED_ROWS.items():
        actual = len(tables[name])
        total += actual
        drift = (actual - expected) / expected * 100
        print(f"  {name:<24} {actual:>7,}   specified {expected:>7,}   {drift:+6.1f}%")
    print(f"  {'TOTAL':<24} {total:>7,}   specified {sum(EXPECTED_ROWS.values()):>7,}")
    report.measure("Total rows within 80,000-150,000 band", "yes" if 80_000 <= total <= 150_000 else "NO")


def report_keys(tables, report):
    print("\nPRIMARY KEYS")
    for name, keys in PRIMARY_KEYS.items():
        duplicates = int(tables[name].duplicated(subset=keys).sum())
        report.check(f"{name} unique on {'+'.join(keys)}", duplicates == 0, f"{duplicates} duplicates")

    print("\nFOREIGN KEYS")
    for child, child_keys, parent, parent_keys in FOREIGN_KEYS:
        left = tables[child][child_keys].dropna()
        right = tables[parent][parent_keys].drop_duplicates()
        right.columns = child_keys
        merged = left.merge(right, on=child_keys, how="left", indicator=True)
        orphans = int((merged["_merge"] == "left_only").sum())
        report.check(f"{child}.{'+'.join(child_keys)} -> {parent}", orphans == 0, f"{orphans} orphans")


def rebuild_balances(movements, snapshots):
    week_ends = np.sort(snapshots["week_ending_date"].unique())
    ledger = movements.loc[movements["movement_date"] <= week_ends[-1],
                           ["sku", "warehouse_code", "movement_date", "quantity"]].copy()
    ledger["week_ending_date"] = pd.to_datetime(
        week_ends[np.searchsorted(week_ends, ledger["movement_date"].values)])
    weekly = ledger.groupby(["sku", "warehouse_code", "week_ending_date"], as_index=False)["quantity"].sum()

    grid = snapshots[["sku", "warehouse_code", "week_ending_date"]].copy()
    grid = grid.merge(weekly, on=["sku", "warehouse_code", "week_ending_date"], how="left")
    grid["quantity"] = grid["quantity"].fillna(0)
    grid = grid.sort_values(["sku", "warehouse_code", "week_ending_date"])
    grid["rebuilt_on_hand"] = grid.groupby(["sku", "warehouse_code"])["quantity"].cumsum()
    return grid


def report_reconciliation(tables, report):
    print("\nINVENTORY RECONCILIATION (rebuilt from stock_movement.csv)")
    movements, snapshots = tables["stock_movement"], tables["inventory_snapshot"]
    rebuilt = rebuild_balances(movements, snapshots)
    merged = snapshots.merge(rebuilt[["sku", "warehouse_code", "week_ending_date", "rebuilt_on_hand"]],
                             on=["sku", "warehouse_code", "week_ending_date"])
    report.check("every snapshot row matched by the rebuild", len(merged) == len(snapshots),
                 f"{len(merged):,} of {len(snapshots):,}")
    mismatches = merged[merged["quantity_on_hand"] != merged["rebuilt_on_hand"]]
    report.check("cumulative ledger equals snapshot on-hand", len(mismatches) == 0,
                 f"{len(mismatches):,} mismatched rows")

    merged = merged.sort_values(["sku", "warehouse_code", "week_ending_date"])
    merged["previous"] = merged.groupby(["sku", "warehouse_code"])["quantity_on_hand"].shift()
    merged["week_movement"] = merged.groupby(["sku", "warehouse_code"])["rebuilt_on_hand"].diff()
    stepwise = merged.dropna(subset=["previous"])
    broken = stepwise[stepwise["quantity_on_hand"] != stepwise["previous"] + stepwise["week_movement"]]
    report.check("week-on-week movement identity holds", len(broken) == 0, f"{len(broken):,} breaks")

    unledgered = movements.groupby(["sku", "warehouse_code"]).size().reset_index()[["sku", "warehouse_code"]]
    covered = snapshots[["sku", "warehouse_code"]].drop_duplicates()
    missing = unledgered.merge(covered, on=["sku", "warehouse_code"], how="left", indicator=True)
    report.check("every ledger pair appears in the snapshots",
                 int((missing["_merge"] == "left_only").sum()) == 0)

    print("\nNEGATIVE INVENTORY")
    report.check("no negative snapshot balance", int((snapshots["quantity_on_hand"] < 0).sum()) == 0)
    running = movements.sort_values(["sku", "warehouse_code", "movement_date", "movement_id"]).copy()
    running["balance"] = running.groupby(["sku", "warehouse_code"])["quantity"].cumsum()
    report.check("no negative balance after any single movement",
                 int((running["balance"] < 0).sum()) == 0,
                 f"{int((running['balance'] < 0).sum())} movements")

    values = snapshots["quantity_on_hand"] * snapshots["weighted_average_cost_gbp"]
    drift = (values.round(2) - snapshots["stock_value_gbp"]).abs()
    report.check("stock value equals on-hand x weighted average cost",
                 float(drift.max()) <= 0.01, f"max drift {drift.max():.4f}")
    zero_days = snapshots["days_at_zero_in_week"]
    report.check("days_at_zero_in_week within 0-7", bool(zero_days.between(0, 7).all()))
    full_week = snapshots[snapshots["days_at_zero_in_week"] == 7]
    report.check("a full zero week closes at zero stock",
                 int((full_week["quantity_on_hand"] != 0).sum()) == 0)


def report_purchasing(tables, report):
    print("\nPURCHASE ORDER AND RECEIPT CONSISTENCY")
    lines, receipts, movements = (tables["purchase_order_line"], tables["goods_receipt_line"],
                                  tables["stock_movement"])
    received = receipts.groupby(["purchase_order_number", "purchase_order_line_number"], as_index=False).agg(
        received=("quantity_received", "sum"), rejected=("quantity_rejected", "sum"))
    merged = lines.merge(received, left_on=["purchase_order_number", "line_number"],
                         right_on=["purchase_order_number", "purchase_order_line_number"], how="left")
    merged[["received", "rejected"]] = merged[["received", "rejected"]].fillna(0)
    over = merged[merged["received"] + merged["rejected"] > merged["quantity_ordered"]]
    report.check("receipts never exceed the quantity ordered", len(over) == 0, f"{len(over)} lines")

    full = merged[merged["line_status"] == "Received in full"]
    report.check("'Received in full' lines are fully received",
                 int((full["received"] < full["quantity_ordered"] - full["rejected"]).sum()) == 0)
    receipt_movements = movements[movements["movement_type"] == "Goods receipt"]["quantity"].sum()
    report.check("goods receipt movements equal accepted receipt quantity",
                 int(receipt_movements) == int(receipts["quantity_received"].sum()),
                 f"{int(receipt_movements):,} vs {int(receipts['quantity_received'].sum()):,}")

    orders = tables["purchase_order"]
    dated = receipts.merge(orders[["purchase_order_number", "order_date"]], on="purchase_order_number")
    report.check("no receipt precedes its order date",
                 int((dated["receipt_date"] < dated["order_date"]).sum()) == 0)


def report_sales(tables, report):
    print("\nSALES ORDER AND INVENTORY CONSISTENCY")
    lines, movements = tables["sales_order_line"], tables["stock_movement"]
    report.check("despatched never exceeds ordered",
                 int((lines["quantity_despatched"] > lines["quantity_ordered"]).sum()) == 0)
    report.check("cancelled lines despatch nothing",
                 int((lines[lines["line_status"] == "Cancelled"]["quantity_despatched"] > 0).sum()) == 0)
    issues = -movements[movements["movement_type"] == "Sales issue"]["quantity"].sum()
    report.check("sales issue movements equal despatched quantity",
                 int(issues) == int(lines["quantity_despatched"].sum()),
                 f"{int(issues):,} vs {int(lines['quantity_despatched'].sum()):,}")

    transfers = movements[movements["movement_type"].isin(["Transfer out", "Transfer in"])]
    netted = transfers.groupby("source_document")["quantity"].sum()
    report.check("transfer pairs net to zero", int((netted != 0).sum()) == 0,
                 f"{int((netted != 0).sum())} unbalanced")

    orders = tables["sales_order"]
    report.check("all order dates fall inside the period",
                 bool(orders["order_date"].between("2024-01-01", "2025-12-31").all()))
    bristol = tables["inventory_snapshot"]
    bristol = bristol[bristol["warehouse_code"] == "BRS"]
    report.check("no Bristol snapshot before 1 July 2024",
                 bool((bristol["week_ending_date"] >= "2024-07-01").all()))


def report_data_quality(tables, report):
    print("\nINTENTIONAL DATA QUALITY ISSUES")
    customers = tables["customer"]
    normalised = (customers["customer_name"].str.upper()
                  .str.replace(" LIMITED", " LTD", regex=False)
                  .str.replace("JR ", "J R ", regex=False))
    key = normalised + "|" + customers["postcode_district"]
    duplicate_groups = int((key.value_counts() > 1).sum())
    report.measure("duplicate customer accounts (same name and postcode)", f"{duplicate_groups} groups")

    receipts = tables["goods_receipt_line"]
    weekday = receipts.assign(day=receipts["receipt_date"].dt.day_name())
    monday_share = weekday.groupby("warehouse_code")["day"].apply(lambda s: (s == "Monday").mean())
    report.measure("Monday share of goods receipts by site",
                   {k: f"{v:.1%}" for k, v in monday_share.round(3).items()})

    orders = tables["purchase_order"]
    bad_dates = int((orders["promised_delivery_date"] < orders["order_date"]).sum())
    missing_dates = int(orders["promised_delivery_date"].isna().sum())
    report.measure("purchase orders with promised date before order date", bad_dates)
    report.measure("purchase orders with no promised date", f"{missing_dates} ({missing_dates/len(orders):.1%})")

    movements = tables["stock_movement"]
    adjustments = movements[movements["movement_type"] == "Stock adjustment"]
    issued = -movements[movements["movement_type"] == "Sales issue"].groupby("warehouse_code")["quantity"].sum()
    shrinkage = adjustments.groupby("warehouse_code")["quantity"].sum() / issued
    report.measure("net stock adjustment as a share of units issued",
                   {k: f"{v:.2%}" for k, v in shrinkage.items()})
    report.measure("stock adjustment movements", len(adjustments))

    products = tables["product"]
    report.measure("products with no weight or volume recorded",
                   f"{int(products['unit_weight_kg'].isna().sum())} ({products['unit_weight_kg'].isna().mean():.1%})")


def report_plausibility(tables, report):
    print("\nPLAUSIBILITY MEASUREMENTS (diagnostics, not pass/fail)")
    snapshots, movements = tables["inventory_snapshot"], tables["stock_movement"]
    products, orders, lines = tables["product"], tables["sales_order"], tables["sales_order_line"]

    closing = snapshots[snapshots["week_ending_date"] == snapshots["week_ending_date"].max()]
    report.measure("closing inventory value", f"£{closing['stock_value_gbp'].sum():,.0f}")
    revenue = (lines["quantity_despatched"] * lines["unit_price_gbp"]).sum()
    report.measure("revenue across the two years", f"£{revenue:,.0f}")

    issues = movements[(movements["movement_type"] == "Sales issue")
                       & (movements["movement_date"] >= "2025-01-01")].copy()
    issues["cogs"] = -issues["quantity"] * issues["unit_cost_gbp"]
    cogs = issues.groupby("warehouse_code")["cogs"].sum()
    average_stock = (snapshots[snapshots["week_ending_date"] >= "2025-01-01"]
                     .groupby("warehouse_code")["stock_value_gbp"].sum() / 52)
    print("\n  2025 inventory performance by warehouse")
    print(f"    {'site':<6}{'avg stock':>12}{'COGS':>14}{'turns':>8}{'DIO':>7}")
    for site in sorted(cogs.index):
        turns = cogs[site] / average_stock[site]
        print(f"    {site:<6}{average_stock[site]:>12,.0f}{cogs[site]:>14,.0f}{turns:>8.2f}{365/turns:>7.0f}")
    network_turns = cogs.sum() / average_stock.sum()
    print(f"    {'ALL':<6}{average_stock.sum():>12,.0f}{cogs.sum():>14,.0f}"
          f"{network_turns:>8.2f}{365/network_turns:>7.0f}")

    print("\n  availability")
    with_site = lines.merge(orders[["sales_order_number", "warehouse_code"]], on="sales_order_number")
    active = with_site[with_site["line_status"] != "Cancelled"].copy()
    active["unmet"] = active["quantity_ordered"] - active["quantity_despatched"]
    report.measure("line fill rate", f"{1 - (active['unmet'] > 0).mean():.1%}")
    report.measure("unit fill rate",
                   f"{active['quantity_despatched'].sum() / active['quantity_ordered'].sum():.1%}")
    report.measure("short or unavailable line rate by site",
                   {k: f"{v:.1%}" for k, v in
                    active.groupby("warehouse_code")["unmet"].apply(lambda s: (s > 0).mean()).items()})
    report.measure("snapshot weeks containing a zero-stock day",
                   f"{(snapshots['days_at_zero_in_week'] > 0).mean():.1%}")

    by_category = snapshots.merge(products[["sku", "category_code"]], on="sku")
    report.measure("mean zero-stock days per week by category",
                   by_category.groupby("category_code")["days_at_zero_in_week"].mean().round(2).to_dict())

    print("\n  Daventry range mix")
    site_ranges = snapshots.groupby("sku")["warehouse_code"].nunique()
    daventry_only = set(site_ranges[site_ranges == 1].index)
    daventry = closing[closing["warehouse_code"] == "DAV"]
    exclusive = daventry[daventry["sku"].isin(daventry_only)]
    report.measure("SKUs stocked only at Daventry", f"{len(daventry_only)} of {len(products)}")
    report.measure("share of Daventry stock value in those lines",
                   f"{exclusive['stock_value_gbp'].sum() / daventry['stock_value_gbp'].sum():.1%}")
    exclusive_issues = issues[issues["warehouse_code"] == "DAV"]
    exclusive_cogs = exclusive_issues[exclusive_issues["sku"].isin(daventry_only)]["cogs"].sum()
    report.measure("share of 2025 Daventry cost of sales in those lines",
                   f"{exclusive_cogs / exclusive_issues['cogs'].sum():.1%}")
    exclusive_stock = (snapshots[(snapshots["warehouse_code"] == "DAV")
                                 & (snapshots["week_ending_date"] >= "2025-01-01")]
                       .assign(exclusive=lambda d: d["sku"].isin(daventry_only))
                       .groupby("exclusive")["stock_value_gbp"].sum() / 52)
    exclusive_sales = (exclusive_issues.assign(exclusive=lambda d: d["sku"].isin(daventry_only))
                       .groupby("exclusive")["cogs"].sum())
    report.measure("Daventry 2025 turns, shared range versus Daventry-only range",
                   f"{exclusive_sales[False]/exclusive_stock[False]:.2f} versus "
                   f"{exclusive_sales[True]/exclusive_stock[True]:.2f}")

    print("\n  replenishment policy")
    policies = tables["replenishment_policy"]
    stale = policies["last_reviewed_date"] < "2024-09-30"
    report.measure("policies not reviewed for over 15 months", f"{stale.mean():.1%}")
    report.measure("stale share by buyer",
                   {k: f"{v:.0%}" for k, v in policies.assign(stale=stale)
                    .groupby("set_by_buyer")["stale"].mean().items()})

    print("\n  purchasing behaviour")
    purchase_lines = tables["purchase_order_line"].merge(tables["purchase_order"], on="purchase_order_number")
    sourcing = tables["product_supplier"]
    alternates = sourcing[~sourcing["is_primary_source"]][["sku", "supplier_code"]].assign(alternate=True)
    tagged = purchase_lines.merge(alternates, on=["sku", "supplier_code"], how="left")
    tagged["alternate"] = tagged["alternate"].fillna(False)
    report.measure("share of purchase lines placed on an alternative source",
                   {k: f"{v:.1%}" for k, v in tagged.groupby("warehouse_code")["alternate"].mean().items()})

    arden = purchase_lines[purchase_lines["supplier_code"] == "ARDEN"]
    window = arden["order_date"].between("2025-02-03", "2025-02-28")
    report.measure("Arden purchase lines in February 2025", int(window.sum()))
    report.measure("median order quantity, February 2025 versus other months",
                   f"{arden[window]['quantity_ordered'].median():.0f} versus "
                   f"{arden[~window]['quantity_ordered'].median():.0f}")
    period = arden.assign(after=arden["order_date"] >= "2025-03-01")
    paired = period.groupby(["sku", "after"])["unit_cost_gbp"].median().unstack()
    paired = paired.dropna()
    report.measure("Arden SKUs priced both sides of March 2025", len(paired))
    report.measure("median like-for-like Arden price change",
                   f"{(paired[True] / paired[False]).median() - 1:+.1%}")
    others = purchase_lines[purchase_lines["supplier_code"] != "ARDEN"]
    other_period = others.assign(after=others["order_date"] >= "2025-03-01")
    other_paired = other_period.groupby(["sku", "after"])["unit_cost_gbp"].median().unstack().dropna()
    report.measure("median like-for-like change, all other suppliers",
                   f"{(other_paired[True] / other_paired[False]).median() - 1:+.1%}")

    dual = sourcing.groupby("sku").size()
    report.measure("SKUs with more than one approved source", int((dual > 1).sum()))

    print("\n  supplier delivery performance")
    receipts = tables["goods_receipt_line"]
    joined = (receipts.merge(tables["purchase_order_line"].rename(columns={"line_number": "po_line"}),
                             left_on=["purchase_order_number", "purchase_order_line_number"],
                             right_on=["purchase_order_number", "po_line"])
              .merge(tables["purchase_order"], on="purchase_order_number")
              .merge(tables["supplier"], on="supplier_code"))
    measurable = joined.dropna(subset=["promised_delivery_date"])
    measurable = measurable[measurable["promised_delivery_date"] >= measurable["order_date"]].copy()
    measurable["on_time"] = measurable["receipt_date"] <= measurable["promised_delivery_date"]
    measurable["lead_time"] = (measurable["receipt_date"] - measurable["order_date"]).dt.days
    summary = measurable.groupby("supplier_type").agg(
        receipts=("on_time", "size"), on_time=("on_time", "mean"),
        median_lead=("lead_time", "median"), lead_spread=("lead_time", "std"))
    print(f"    {'supplier type':<24}{'receipts':>10}{'on time':>10}{'median LT':>12}{'LT sd':>8}")
    for name, row in summary.iterrows():
        print(f"    {name:<24}{int(row['receipts']):>10}{row['on_time']:>9.1%}"
              f"{row['median_lead']:>12.0f}{row['lead_spread']:>8.1f}")

    for code, label in [("MERID", "Meridian Pacific Trading"), ("KELSO", "Kelso Valve & Control")]:
        supplier_rows = measurable[measurable["supplier_code"] == code]
        by_quarter = supplier_rows.groupby(
            supplier_rows["order_date"].dt.to_period("Q").astype(str))["on_time"].agg(["size", "mean"])
        formatted = {q: f"{r['mean']:.0%} (n={int(r['size'])})" for q, r in by_quarter.iterrows()}
        print(f"\n    {label} on-time by quarter:")
        for quarter, value in formatted.items():
            print(f"      {quarter}  {value}")

    print("\n  growth and decline")
    renewables = by_category[by_category["category_code"] == "RENW"]
    report.measure("Renewables mean zero-stock days per week",
                   f"{renewables['days_at_zero_in_week'].mean():.2f} "
                   f"against {by_category['days_at_zero_in_week'].mean():.2f} network")
    quarterly = (lines.merge(orders[["sales_order_number", "order_date"]], on="sales_order_number")
                 .merge(products[["sku", "category_code"]], on="sku"))
    quarterly["quarter"] = quarterly["order_date"].dt.to_period("Q").astype(str)
    renewable_demand = quarterly[quarterly["category_code"] == "RENW"].groupby("quarter")["quantity_ordered"].sum()
    report.measure("Renewables units ordered, first quarter to last",
                   f"{renewable_demand.iloc[0]:,} -> {renewable_demand.iloc[-1]:,}")


def main():
    tables = load_tables()
    report = Report()
    report_row_counts(tables, report)
    report_keys(tables, report)
    report_reconciliation(tables, report)
    report_purchasing(tables, report)
    report_sales(tables, report)
    report_data_quality(tables, report)
    report_plausibility(tables, report)
    print(f"\n{'VALIDATION PASSED' if report.failures == 0 else f'VALIDATION FAILED: {report.failures} checks'}")
    return 1 if report.failures else 0


if __name__ == "__main__":
    sys.exit(main())
