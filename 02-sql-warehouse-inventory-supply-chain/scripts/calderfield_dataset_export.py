"""Writes the generated Calderfield tables to CSV in a fixed column order."""

from __future__ import annotations

from pathlib import Path

import pandas as pd

OUTPUT_DIRECTORY = Path(__file__).resolve().parent.parent / "data" / "synthetic"

TABLE_COLUMNS = {
    "warehouse": ["warehouse_code", "warehouse_name", "region", "postcode_district",
                  "site_type", "opened_date", "storage_capacity_pallets", "warehouse_headcount"],
    "product_category": ["category_code", "category_name", "storage_class"],
    "product": ["sku", "product_name", "category_code", "brand", "unit_of_measure",
                "list_price_gbp", "standard_cost_gbp", "unit_weight_kg", "unit_volume_m3",
                "pallet_quantity", "shelf_life_months", "introduced_date", "discontinued_date",
                "hazardous_flag"],
    "supplier": ["supplier_code", "supplier_name", "supplier_type", "country",
                 "payment_terms_days", "account_opened_date"],
    "product_supplier": ["sku", "supplier_code", "is_primary_source", "quoted_lead_time_days",
                         "minimum_order_quantity", "order_multiple", "agreed_unit_cost_gbp",
                         "price_agreed_date"],
    "customer": ["customer_account", "customer_name", "customer_segment", "region",
                 "postcode_district", "primary_warehouse_code", "account_opened_date",
                 "credit_limit_gbp", "account_status"],
    "calendar_week": ["week_ending_date", "week_starting_date", "year", "iso_week",
                      "month_number", "month_name", "quarter", "working_days_in_week"],
    "replenishment_policy": ["sku", "warehouse_code", "reorder_point_units",
                             "reorder_quantity_units", "safety_stock_units", "review_method",
                             "last_reviewed_date", "set_by_buyer", "stocked_since"],
    "purchase_order": ["purchase_order_number", "supplier_code", "warehouse_code", "order_date",
                       "promised_delivery_date", "buyer_name", "order_status"],
    "purchase_order_line": ["purchase_order_number", "line_number", "sku", "quantity_ordered",
                            "unit_cost_gbp", "line_status"],
    "goods_receipt_line": ["receipt_reference", "line_number", "purchase_order_number",
                           "purchase_order_line_number", "warehouse_code", "receipt_date",
                           "quantity_received", "quantity_rejected"],
    "sales_order": ["sales_order_number", "customer_account", "warehouse_code", "order_date",
                    "requested_delivery_date", "despatch_date", "order_channel", "order_status"],
    "sales_order_line": ["sales_order_number", "line_number", "sku", "quantity_ordered",
                         "quantity_despatched", "unit_price_gbp", "line_discount_pct",
                         "line_status"],
    "stock_movement": ["movement_id", "sku", "warehouse_code", "movement_date", "movement_type",
                       "quantity", "unit_cost_gbp", "source_document"],
    "inventory_snapshot": ["week_ending_date", "sku", "warehouse_code", "quantity_on_hand",
                           "quantity_allocated", "quantity_on_order", "days_at_zero_in_week",
                           "weighted_average_cost_gbp", "stock_value_gbp"],
}

SORT_KEYS = {
    "product_supplier": ["sku", "supplier_code"],
    "replenishment_policy": ["sku", "warehouse_code"],
    "purchase_order": ["order_date", "purchase_order_number"],
    "purchase_order_line": ["purchase_order_number", "line_number"],
    "goods_receipt_line": ["receipt_date", "receipt_reference"],
    "sales_order": ["order_date", "sales_order_number"],
    "sales_order_line": ["sales_order_number", "line_number"],
    "stock_movement": ["movement_id"],
    "inventory_snapshot": ["week_ending_date", "warehouse_code", "sku"],
}


def export_dataset(tables, output_directory=OUTPUT_DIRECTORY):
    output_directory.mkdir(parents=True, exist_ok=True)
    written = {}
    for name, columns in TABLE_COLUMNS.items():
        frame = pd.DataFrame(tables[name])[columns]
        if name in SORT_KEYS:
            frame = frame.sort_values(SORT_KEYS[name], kind="stable").reset_index(drop=True)
        frame.to_csv(output_directory / f"{name}.csv", index=False)
        written[name] = len(frame)
    return written


if __name__ == "__main__":
    raise SystemExit("Run calderfield_dataset_generator.py to build and export the dataset.")
