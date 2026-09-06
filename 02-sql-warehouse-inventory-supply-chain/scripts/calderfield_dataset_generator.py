"""Generates the Calderfield Trade Supplies synthetic dataset.

Fictional UK wholesale distributor of plumbing, heating, ventilation and
electrical products. All data is synthetic.
"""

from __future__ import annotations

import math
from collections import defaultdict
from datetime import date, timedelta

import numpy as np

from calderfield_dataset_export import export_dataset

SEED = 20240101
PERIOD_START = date(2024, 1, 1)
PERIOD_END = date(2025, 12, 31)
FIRST_WEEK_END = date(2024, 1, 7)

BANK_HOLIDAYS = {
    date(2024, 1, 1), date(2024, 3, 29), date(2024, 4, 1), date(2024, 5, 6),
    date(2024, 5, 27), date(2024, 8, 26), date(2024, 12, 25), date(2024, 12, 26),
    date(2025, 1, 1), date(2025, 4, 18), date(2025, 4, 21), date(2025, 5, 5),
    date(2025, 5, 26), date(2025, 8, 25), date(2025, 12, 25), date(2025, 12, 26),
}

CATEGORIES = [
    {"code": "HEAT", "name": "Heating & Boilers", "storage_class": "Ambient racked",
     "price_range": (300, 1600), "cost_ratio": 0.66, "line_rate": 5.0, "typical_qty": 1.5,
     "seasonality": [1.90, 1.75, 1.35, 1.00, 0.70, 0.50, 0.50, 0.60, 0.90, 1.40, 1.70, 1.90]},
    {"code": "RENW", "name": "Renewables & Heat Pumps", "storage_class": "Bulk floor",
     "price_range": (900, 4200), "cost_ratio": 0.71, "line_rate": 1.7, "typical_qty": 1.0,
     "seasonality": [1.20, 1.15, 1.10, 1.00, 0.90, 0.85, 0.85, 0.90, 1.00, 1.10, 1.15, 1.20]},
    {"code": "PIPE", "name": "Pipe & Fittings", "storage_class": "Bulk floor",
     "price_range": (0.40, 25), "cost_ratio": 0.62, "line_rate": 14.0, "typical_qty": 50.0,
     "seasonality": [0.95, 1.00, 1.05, 1.05, 1.00, 1.00, 0.95, 0.95, 1.00, 1.05, 1.05, 0.95]},
    {"code": "VALV", "name": "Valves & Controls", "storage_class": "Ambient racked",
     "price_range": (12, 180), "cost_ratio": 0.64, "line_rate": 7.0, "typical_qty": 5.0,
     "seasonality": [1.30, 1.25, 1.10, 1.00, 0.85, 0.80, 0.80, 0.85, 1.00, 1.10, 1.25, 1.30]},
    {"code": "ELEC", "name": "Electrical & Cable", "storage_class": "Ambient racked",
     "price_range": (2, 220), "cost_ratio": 0.68, "line_rate": 10.0, "typical_qty": 18.0,
     "seasonality": [0.95, 1.00, 1.05, 1.05, 1.00, 1.00, 0.95, 1.00, 1.00, 1.05, 1.00, 0.95]},
    {"code": "VENT", "name": "Ventilation & Air Movement", "storage_class": "Ambient racked",
     "price_range": (35, 950), "cost_ratio": 0.65, "line_rate": 3.0, "typical_qty": 2.0,
     "seasonality": [0.70, 0.70, 0.80, 0.95, 1.20, 1.50, 1.60, 1.50, 1.10, 0.90, 0.75, 0.70]},
    {"code": "DRAIN", "name": "Drainage & Water Management", "storage_class": "Bulk floor",
     "price_range": (8, 340), "cost_ratio": 0.63, "line_rate": 6.0, "typical_qty": 8.0,
     "seasonality": [0.80, 0.90, 1.30, 1.20, 1.00, 0.90, 0.85, 0.90, 1.15, 1.35, 1.10, 0.85]},
    {"code": "TOOL", "name": "Tools & Consumables", "storage_class": "Secure cage",
     "price_range": (1, 60), "cost_ratio": 0.60, "line_rate": 12.0, "typical_qty": 12.0,
     "seasonality": [0.95, 1.00, 1.05, 1.00, 1.00, 1.05, 1.00, 0.95, 1.00, 1.05, 1.00, 0.95]},
]

CATEGORY_SKU_COUNT = {"HEAT": 31, "RENW": 31, "PIPE": 31, "VALV": 31,
                      "ELEC": 32, "VENT": 31, "DRAIN": 31, "TOOL": 32}

WAREHOUSES = [
    {"code": "DAV", "name": "Daventry National Distribution Centre", "region": "East Midlands",
     "postcode_district": "NN11", "site_type": "National DC", "opened_date": date(2011, 3, 7),
     "capacity_pallets": 8400, "headcount": 31, "range_size": 250, "safety_multiplier": 1.00,
     "alternative_source_probability": 0.20, "orders_per_day": 7.6, "pre_bristol_orders": 9.5,
     "pipeline_cover": 1.15, "reorder_cover_multiplier": 1.00},
    {"code": "WAR", "name": "Warrington Regional Distribution Centre", "region": "North West",
     "postcode_district": "WA5", "site_type": "Regional DC", "opened_date": date(2014, 5, 12),
     "capacity_pallets": 3200, "headcount": 17, "range_size": 105, "safety_multiplier": 0.70,
     "alternative_source_probability": 0.18, "orders_per_day": 5.1, "pre_bristol_orders": 6.5,
     "pipeline_cover": 0.95, "reorder_cover_multiplier": 0.85},
    {"code": "BRS", "name": "Bristol Regional Distribution Centre", "region": "South West",
     "postcode_district": "BS35", "site_type": "Regional DC", "opened_date": date(2024, 7, 1),
     "capacity_pallets": 2400, "headcount": 12, "range_size": 90, "safety_multiplier": 0.55,
     "alternative_source_probability": 0.25, "orders_per_day": 3.4, "pre_bristol_orders": 0.0,
     "pipeline_cover": 0.68, "reorder_cover_multiplier": 0.55},
    {"code": "LIV", "name": "Livingston Regional Distribution Centre", "region": "Scotland",
     "postcode_district": "EH54", "site_type": "Regional DC", "opened_date": date(2019, 9, 2),
     "capacity_pallets": 2000, "headcount": 9, "range_size": 70, "safety_multiplier": 2.20,
     "alternative_source_probability": 0.95, "orders_per_day": 2.8, "pre_bristol_orders": 2.9,
     "pipeline_cover": 1.70, "reorder_cover_multiplier": 1.90},
]

SUPPLIER_ARCHETYPES = {
    "UK Manufacturer": {"count": 8, "quoted_lead_time": 7, "actual_mean": 7.5, "actual_sd": 1.5,
                        "on_time_rate": 0.96, "price_index": 1.00, "moq_months": 0.4,
                        "reject_rate": 0.002, "split_rate": 0.10, "payment_terms": 60},
    "UK / EU Distributor": {"count": 10, "quoted_lead_time": 14, "actual_mean": 16.0, "actual_sd": 5.0,
                            "on_time_rate": 0.88, "price_index": 1.06, "moq_months": 0.8,
                            "reject_rate": 0.006, "split_rate": 0.18, "payment_terms": 45},
    "Far East Importer": {"count": 7, "quoted_lead_time": 55, "actual_mean": 63.0, "actual_sd": 14.0,
                          "on_time_rate": 0.68, "price_index": 0.79, "moq_months": 4.5,
                          "reject_rate": 0.021, "split_rate": 0.14, "payment_terms": 90},
    "Small Specialist": {"count": 5, "quoted_lead_time": 21, "actual_mean": 22.0, "actual_sd": 9.0,
                         "on_time_rate": 0.82, "price_index": 1.12, "moq_months": 0.5,
                         "reject_rate": 0.009, "split_rate": 0.22, "payment_terms": 30},
}

SUPPLIER_NAMES = {
    "UK Manufacturer": [
        ("ARDEN", "Arden Heating Components Ltd"), ("BRAMW", "Bramwell Copper Works Ltd"),
        ("CHARN", "Charnley Electrical Manufacturing Ltd"), ("DERWT", "Derwent Valve Company Ltd"),
        ("EASTN", "Easton Ventilation Products Ltd"), ("FOXLY", "Foxley Drainage Systems Ltd"),
        ("GRANH", "Granham Thermal Ltd"), ("HALDN", "Haldane Sealants & Adhesives Ltd"),
    ],
    "UK / EU Distributor": [
        ("IRWEL", "Irwell Building Supplies plc"), ("JARVS", "Jarvis Wholesale Distribution Ltd"),
        ("KENTM", "Kentmere Trade Distribution Ltd"), ("LANGD", "Langdale Industrial Supply Ltd"),
        ("MARSD", "Marsden Group Distribution Ltd"), ("NEWLY", "Newlyn Technical Products Ltd"),
        ("ORMSK", "Ormskirk Supply Partners Ltd"), ("PENRT", "Penruth Distribution Ltd"),
        ("QUEND", "Quendon Trade Supply Ltd"), ("RAVNS", "Ravensworth Wholesale Ltd"),
    ],
    "Far East Importer": [
        ("MERID", "Meridian Pacific Trading Ltd"), ("SELBY", "Selby Import Partners Ltd"),
        ("TANFD", "Tanfield Sourcing Ltd"), ("UPTON", "Upton Global Sourcing Ltd"),
        ("VERND", "Vernedale Import Company Ltd"), ("WROXH", "Wroxham Overseas Supply Ltd"),
        ("YARLT", "Yarlton Trading Company Ltd"),
    ],
    "Small Specialist": [
        ("KELSO", "Kelso Valve & Control Ltd"), ("ALNWK", "Alnwick Precision Fittings Ltd"),
        ("BEWLY", "Bewley Instrumentation Ltd"), ("CROMR", "Cromer Specialist Heating Ltd"),
        ("DUNKD", "Dunkeld Water Systems Ltd"),
    ],
}

PRICE_RISE_SUPPLIER = "ARDEN"
PRICE_RISE_DATE = date(2025, 3, 1)
PRICE_RISE_FACTOR = 1.18
BUY_AHEAD_START = date(2025, 2, 3)
BUY_AHEAD_END = date(2025, 2, 28)

DETERIORATING_SUPPLIER = "MERID"
IMPROVING_SUPPLIER = "KELSO"

CUSTOMER_SEGMENTS = [
    ("Contractor", 265, 3.4, 1.00), ("Builders' Merchant", 60, 4.6, 1.85),
    ("Facilities Management", 80, 2.8, 0.90), ("Housebuilder", 20, 3.9, 2.60),
    ("Counter Trade", 75, 1.9, 0.45),
]

REGIONS_BY_WAREHOUSE = {
    "DAV": ["East Midlands", "West Midlands", "East of England"],
    "WAR": ["North West", "Yorkshire", "North East"],
    "BRS": ["South West", "Wales"],
    "LIV": ["Scotland"],
}

POSTCODES_BY_WAREHOUSE = {
    "DAV": ["NN1", "NN11", "LE3", "CV1", "B18", "PE1", "MK9", "DE21", "NG7", "CB4"],
    "WAR": ["WA3", "WA5", "M12", "L24", "PR2", "BL4", "LS11", "S9", "NE11", "CH5"],
    "BRS": ["BS2", "BS35", "BA14", "TA6", "EX4", "PL4", "CF24", "SA1", "GL1", "SN2"],
    "LIV": ["EH54", "G52", "AB12", "DD2", "KY11", "PA3", "IV2", "ML1"],
}

ORDER_CHANNELS = [("Trade counter", 0.34), ("Telephone", 0.31),
                  ("Web", 0.21), ("Account manager", 0.14)]

WEEKDAY_FACTOR = {0: 1.15, 1: 1.00, 2: 0.95, 3: 1.00, 4: 1.10}

BUYERS = ["A. Whitcombe", "R. Deakin", "S. Nkemelu", "T. Harrowby", "M. Castleford"]
LAX_REVIEW_BUYER = "T. Harrowby"

AVERAGE_LINES_PER_ORDER = 3.25
AVERAGE_QUANTITY_FACTOR = 1.163
REORDER_COVER_DAYS = 45

STALE_POLICY_SHARE = 0.22
DUPLICATE_ACCOUNT_COUNT = 30
PROMISED_DATE_ERROR_COUNT = 25
LIVINGSTON_LATE_BOOKING_RATE = 0.25


def normalised_seasonality(values):
    mean = sum(values) / len(values)
    return [v / mean for v in values]


def working_days(start, end):
    days, cursor = [], start
    while cursor <= end:
        if cursor.weekday() < 5 and cursor not in BANK_HOLIDAYS:
            days.append(cursor)
        cursor += timedelta(days=1)
    return days


def add_working_days(start, count):
    cursor, remaining = start, count
    while remaining > 0:
        cursor += timedelta(days=1)
        if cursor.weekday() < 5 and cursor not in BANK_HOLIDAYS:
            remaining -= 1
    return cursor


def next_working_day(day):
    cursor = day
    while cursor.weekday() >= 5 or cursor in BANK_HOLIDAYS:
        cursor += timedelta(days=1)
    return cursor


def build_calendar_weeks():
    weeks, week_end = [], FIRST_WEEK_END
    while week_end <= date(2025, 12, 28):
        week_start = week_end - timedelta(days=6)
        trading = sum(1 for d in (week_start + timedelta(days=i) for i in range(7))
                      if d.weekday() < 5 and d not in BANK_HOLIDAYS)
        iso = week_end.isocalendar()
        weeks.append({
            "week_ending_date": week_end,
            "week_starting_date": week_start,
            "year": week_end.year,
            "iso_week": iso[1],
            "month_number": week_end.month,
            "month_name": week_end.strftime("%B"),
            "quarter": f"Q{(week_end.month - 1) // 3 + 1}",
            "working_days_in_week": trading,
        })
        week_end += timedelta(days=7)
    return weeks


def build_warehouse_table():
    return [{
        "warehouse_code": w["code"], "warehouse_name": w["name"], "region": w["region"],
        "postcode_district": w["postcode_district"], "site_type": w["site_type"],
        "opened_date": w["opened_date"], "storage_capacity_pallets": w["capacity_pallets"],
        "warehouse_headcount": w["headcount"],
    } for w in WAREHOUSES]


def build_category_table():
    return [{"category_code": c["code"], "category_name": c["name"],
             "storage_class": c["storage_class"]} for c in CATEGORIES]


BRAND_POOL = {
    "HEAT": ["Thermex", "Calorna", "Ravenglass"], "RENW": ["Thermex", "Solvara", "Northaire"],
    "PIPE": ["Cuprex", "Flowline", "Bramwell"], "VALV": ["Derwent", "Kelso", "Vantor"],
    "ELEC": ["Charnley", "Voltek", "Lumair"], "VENT": ["Easton", "Airvane", "Zephra"],
    "DRAIN": ["Foxley", "Hydralt", "Culvert"], "TOOL": ["Haldane", "Gripwell", "Sitemark"],
}

MODEL_WORDS = {
    "HEAT": ["Combi Boiler", "System Boiler", "Unvented Cylinder", "Flue Kit", "Expansion Vessel"],
    "RENW": ["Air Source Heat Pump", "Buffer Tank", "Hot Water Cylinder", "Inverter Module"],
    "PIPE": ["Copper Tube", "Push-Fit Elbow", "Solder Ring Coupler", "Compression Tee", "Plastic Barrier Pipe"],
    "VALV": ["Zone Valve", "Thermostatic Radiator Valve", "Room Thermostat", "Pressure Reducing Valve"],
    "ELEC": ["Twin & Earth Cable", "Consumer Unit", "Socket Outlet", "RCBO", "SWA Cable"],
    "VENT": ["Extract Fan", "MVHR Unit", "Rigid Duct", "In-Line Fan", "Grille Set"],
    "DRAIN": ["Underground Pipe", "Bottle Gully", "Inspection Chamber", "Submersible Pump", "Channel Drain"],
    "TOOL": ["Silicone Sealant", "Reciprocating Blade", "Fixing Pack", "Nitrile Gloves", "Pipe Slice"],
}

SIZE_WORDS = ["15mm", "22mm", "28mm", "35mm", "18kW", "24kW", "32kW", "110mm", "150mm",
              "6kW", "9kW", "2.5mm2", "6.0mm2", "100mm", "125mm", "300ml", "1.5m"]


def build_products(rng):
    products = []
    for category in CATEGORIES:
        code = category["code"]
        low, high = category["price_range"]
        for index in range(CATEGORY_SKU_COUNT[code]):
            sku = f"{code}-{1000 + index * 7 + rng.integers(0, 6):04d}"
            list_price = float(np.exp(rng.uniform(math.log(low), math.log(high))))
            list_price = round(list_price, 2 if list_price < 100 else 0)
            standard_cost = round(list_price * category["cost_ratio"] * rng.uniform(0.96, 1.04), 2)
            line_weight = float(rng.lognormal(0.0, 0.75))
            has_dimensions = rng.random() > 0.05
            products.append({
                "sku": sku,
                "product_name": (f"{rng.choice(BRAND_POOL[code])} "
                                 f"{rng.choice(MODEL_WORDS[code])} {rng.choice(SIZE_WORDS)}"),
                "category_code": code,
                "brand": None,
                "unit_of_measure": "EACH",
                "list_price_gbp": list_price,
                "standard_cost_gbp": standard_cost,
                "unit_weight_kg": round(float(rng.uniform(0.05, 60)), 3) if has_dimensions else None,
                "unit_volume_m3": round(float(rng.uniform(0.0002, 0.9)), 4) if has_dimensions else None,
                "pallet_quantity": int(rng.integers(1, 200)),
                "shelf_life_months": int(rng.choice([12, 18, 24])) if code == "TOOL" and rng.random() < 0.55 else None,
                "introduced_date": date(2011, 1, 1) + timedelta(days=int(rng.integers(0, 4600))),
                "discontinued_date": None,
                "hazardous_flag": bool(code == "TOOL" and rng.random() < 0.25),
                "line_weight": line_weight,
                "typical_qty": category["typical_qty"],
                "seasonality": normalised_seasonality(category["seasonality"]),
                "annual_growth": 1.0,
                "lifecycle": "stable",
            })
    for product in products:
        product["brand"] = product["product_name"].split(" ")[0]
        linear = any(word in product["product_name"] for word in ("Cable", "Tube", "Pipe", "Duct"))
        product["unit_of_measure"] = "METRE" if linear else "EACH"

    by_category = defaultdict(list)
    for product in products:
        by_category[product["category_code"]].append(product)

    for product in rng.choice(by_category["RENW"], size=22, replace=False):
        product["lifecycle"] = "growth"
        product["annual_growth"] = float(rng.uniform(1.45, 1.65))

    decline_pool = (by_category["HEAT"][:14] + by_category["VALV"][:7] + by_category["ELEC"][:7])
    for product in decline_pool:
        product["lifecycle"] = "decline"
        product["annual_growth"] = float(rng.uniform(0.65, 0.88))
        if rng.random() < 0.5:
            product["discontinued_date"] = PERIOD_START + timedelta(days=int(rng.integers(400, 720)))

    for product in products:
        if product["lifecycle"] == "stable":
            product["annual_growth"] = float(rng.uniform(0.96, 1.05))
    return products


def build_suppliers(rng):
    suppliers = []
    for archetype, spec in SUPPLIER_ARCHETYPES.items():
        for code, name in SUPPLIER_NAMES[archetype]:
            suppliers.append({
                "supplier_code": code, "supplier_name": name, "supplier_type": archetype,
                "country": "China" if archetype == "Far East Importer" else "United Kingdom",
                "payment_terms_days": spec["payment_terms"],
                "account_opened_date": date(2010, 1, 1) + timedelta(days=int(rng.integers(0, 4700))),
                "spec": spec,
            })
    return suppliers


def supplier_on_time_rate(supplier, order_date):
    base = supplier["spec"]["on_time_rate"]
    code = supplier["supplier_code"]
    if code == IMPROVING_SUPPLIER:
        if order_date < date(2024, 7, 1):
            return 0.62
        if order_date >= date(2024, 10, 1):
            return 0.93
        progress = (order_date - date(2024, 7, 1)).days / 92
        return 0.62 + progress * 0.31
    if code == DETERIORATING_SUPPLIER:
        if order_date < date(2025, 1, 1):
            return 0.95
        progress = (order_date - date(2025, 1, 1)).days / 364
        return 0.95 - progress * 0.55
    return base


def supplier_lead_time_shape(supplier, order_date):
    spec = supplier["spec"]
    mean, sd = spec["actual_mean"], spec["actual_sd"]
    code = supplier["supplier_code"]
    if code == IMPROVING_SUPPLIER:
        if order_date < date(2024, 7, 1):
            sd = 9.0
        elif order_date >= date(2024, 10, 1):
            sd = 4.0
        else:
            sd = 9.0 - (order_date - date(2024, 7, 1)).days / 92 * 5.0
    if code == DETERIORATING_SUPPLIER and order_date >= date(2025, 1, 1):
        progress = (order_date - date(2025, 1, 1)).days / 364
        mean = 58.0 + progress * 13.0
        sd = 8.0 + progress * 9.0
    elif code == DETERIORATING_SUPPLIER:
        mean, sd = 58.0, 8.0
    return mean, sd


def build_sourcing(rng, products, suppliers):
    by_type = defaultdict(list)
    for supplier in suppliers:
        by_type[supplier["supplier_type"]].append(supplier)

    category_home = {
        "HEAT": ["UK Manufacturer", "UK / EU Distributor"],
        "RENW": ["UK Manufacturer", "UK / EU Distributor"],
        "PIPE": ["UK Manufacturer", "Far East Importer"],
        "VALV": ["Small Specialist", "UK Manufacturer"],
        "ELEC": ["UK Manufacturer", "UK / EU Distributor"],
        "VENT": ["UK Manufacturer", "UK / EU Distributor"],
        "DRAIN": ["UK Manufacturer", "UK / EU Distributor"],
        "TOOL": ["Far East Importer", "UK Manufacturer"],
    }

    network_lines_per_day = sum(w["orders_per_day"] for w in WAREHOUSES) * AVERAGE_LINES_PER_ORDER
    total_line_weight = sum(p["line_weight"] for p in products)

    concentrated = {"Far East Importer": (DETERIORATING_SUPPLIER, 0.40),
                    "Small Specialist": (IMPROVING_SUPPLIER, 0.50),
                    "UK Manufacturer": (PRICE_RISE_SUPPLIER, 0.34)}

    def pick(supplier_type, exclude=()):
        pool = [s for s in by_type[supplier_type] if s["supplier_code"] not in exclude]
        favourite = concentrated.get(supplier_type)
        if favourite:
            match = [s for s in pool if s["supplier_code"] == favourite[0]]
            if match and rng.random() < favourite[1]:
                return match[0]
        return rng.choice(pool)

    sourcing, sourcing_index = [], defaultdict(list)
    dual_weights = np.array([p["line_weight"] for p in products])
    dual_weights = dual_weights / dual_weights.sum()
    dual_skus = set(rng.choice([p["sku"] for p in products], size=88, replace=False, p=dual_weights))
    triple_skus = set(rng.choice(sorted(dual_skus), size=6, replace=False))
    products_by_sku = {p["sku"]: p for p in products}

    for product in products:
        home = category_home[product["category_code"]]
        primary_type = home[0] if rng.random() < 0.62 else home[1]
        primary = pick(primary_type)
        chosen = [primary]
        if product["sku"] in dual_skus:
            alternate_type = "Far East Importer" if primary_type != "Far East Importer" else "UK / EU Distributor"
            chosen.append(pick(alternate_type, exclude=(primary["supplier_code"],)))
        if product["sku"] in triple_skus:
            third_type = "Small Specialist"
            chosen.append(pick(third_type, exclude=tuple(c["supplier_code"] for c in chosen)))

        network_daily_units = (network_lines_per_day * product["line_weight"] / total_line_weight
                               * product["typical_qty"] * AVERAGE_QUANTITY_FACTOR)
        for position, supplier in enumerate(chosen):
            spec = supplier["spec"]
            base_cost = round(product["standard_cost_gbp"] * spec["price_index"] * rng.uniform(0.97, 1.03), 2)
            moq_units = max(1, int(round(spec["moq_months"] * 30 * network_daily_units * 0.30)))
            multiple = max(1, int(round(moq_units / 6))) if moq_units > 20 else 1
            moq_units = int(math.ceil(moq_units / multiple) * multiple)
            agreed = base_cost
            agreed_date = date(2023, 1, 1) + timedelta(days=int(rng.integers(0, 500)))
            if supplier["supplier_code"] == PRICE_RISE_SUPPLIER:
                agreed = round(base_cost * PRICE_RISE_FACTOR, 2)
                agreed_date = PRICE_RISE_DATE
            record = {
                "sku": product["sku"], "supplier_code": supplier["supplier_code"],
                "is_primary_source": position == 0,
                "quoted_lead_time_days": spec["quoted_lead_time"],
                "minimum_order_quantity": moq_units,
                "order_multiple": multiple,
                "agreed_unit_cost_gbp": agreed,
                "price_agreed_date": agreed_date,
                "base_cost": base_cost,
            }
            sourcing.append(record)
            sourcing_index[product["sku"]].append(record)
    return sourcing, sourcing_index, products_by_sku


def build_customers(rng):
    customers, account_number = [], 1000
    base_count = 500 - DUPLICATE_ACCOUNT_COUNT
    segment_pool = []
    for name, count, _, _ in CUSTOMER_SEGMENTS:
        scaled = int(round(count * base_count / 500))
        segment_pool.extend([name] * scaled)
    while len(segment_pool) < base_count:
        segment_pool.append("Contractor")
    segment_pool = segment_pool[:base_count]
    rng.shuffle(segment_pool)

    warehouse_weights = np.array([w["orders_per_day"] for w in WAREHOUSES], dtype=float)
    warehouse_weights /= warehouse_weights.sum()

    first_names = ["J R", "Aldridge", "Penhale", "Crowther", "Whitmore", "Bexley", "Salford",
                   "Trentham", "Kirkby", "Latimer", "Mowbray", "Selwood", "Rannoch", "Datchet",
                   "Fenwick", "Ollerton", "Barrowby", "Cheveley", "Duncombe", "Ferrers"]
    suffixes = ["Ltd", "Ltd", "Ltd", "& Sons Ltd", "Services Ltd", "Contracts Ltd",
                "Building Services Ltd", "Plumbing & Heating Ltd", "Group Ltd", "Maintenance Ltd"]

    for segment in segment_pool:
        account_number += int(rng.integers(1, 4))
        warehouse = WAREHOUSES[int(rng.choice(len(WAREHOUSES), p=warehouse_weights))]["code"]
        name = f"{rng.choice(first_names)} {rng.choice(first_names)} {rng.choice(suffixes)}"
        customers.append({
            "customer_account": f"C{account_number:04d}",
            "customer_name": name,
            "customer_segment": segment,
            "region": str(rng.choice(REGIONS_BY_WAREHOUSE[warehouse])),
            "postcode_district": str(rng.choice(POSTCODES_BY_WAREHOUSE[warehouse])),
            "primary_warehouse_code": warehouse,
            "account_opened_date": date(2012, 1, 1) + timedelta(days=int(rng.integers(0, 4300))),
            "credit_limit_gbp": float(round(rng.choice([5000, 10000, 15000, 25000, 35000, 50000, 75000, 120000]), 2)),
            "account_status": "Active" if rng.random() > 0.04 else "On hold",
        })

    duplicate_sources = rng.choice(len(customers), size=DUPLICATE_ACCOUNT_COUNT, replace=False)
    for source_index in duplicate_sources:
        source = customers[int(source_index)]
        account_number += int(rng.integers(1, 4))
        variant = source["customer_name"].replace(" Ltd", " Limited")
        if rng.random() < 0.4:
            variant = variant.upper()
        elif rng.random() < 0.4:
            variant = variant.replace("J R", "JR")
        customers.append({
            "customer_account": f"C{account_number:04d}",
            "customer_name": variant,
            "customer_segment": source["customer_segment"],
            "region": source["region"],
            "postcode_district": source["postcode_district"],
            "primary_warehouse_code": source["primary_warehouse_code"],
            "account_opened_date": source["account_opened_date"] + timedelta(days=int(rng.integers(200, 2000))),
            "credit_limit_gbp": source["credit_limit_gbp"],
            "account_status": "Active",
        })
    return customers


def assign_stocked_range(rng, products):
    ranked = sorted(products, key=lambda p: -p["line_weight"])
    by_category = defaultdict(list)
    for product in ranked:
        by_category[product["category_code"]].append(product)

    total_line_rate = sum(c["line_rate"] for c in CATEGORIES)
    category_share = {c["code"]: c["line_rate"] / total_line_rate for c in CATEGORIES}

    stocked = {}
    for warehouse in WAREHOUSES:
        code, size = warehouse["code"], warehouse["range_size"]
        if size >= len(products):
            stocked[code] = [p["sku"] for p in products]
            continue
        selection = []
        for category_code, members in by_category.items():
            take = max(3, int(round(size * category_share[category_code])))
            selection.extend(members[:take])
        selection = sorted(selection, key=lambda p: -p["line_weight"])[:size]
        stocked[code] = [p["sku"] for p in selection]
    return stocked


def trend_factor(product, day):
    years = (day - PERIOD_START).days / 365.25
    return float(product["annual_growth"] ** years)


def expected_daily_units(product, warehouse, day, stocked_skus, products_by_sku):
    """Annual-average demand rate, the basis every replenishment policy is sized on.

    Seasonality is deliberately excluded: policies are set on an annual average, which
    is what leaves peak-season cover short at sites carrying a thin safety multiplier.
    """
    site_total = sum(products_by_sku[sku]["line_weight"] * trend_factor(products_by_sku[sku], day)
                     for sku in stocked_skus)
    if site_total <= 0:
        return 0.01
    share = product["line_weight"] * trend_factor(product, day) / site_total
    lines_per_day = warehouse["orders_per_day"] * AVERAGE_LINES_PER_ORDER
    return max(0.01, lines_per_day * share * product["typical_qty"] * AVERAGE_QUANTITY_FACTOR)


def build_policies(rng, products_by_sku, stocked, sourcing_index):
    warehouse_lookup = {w["code"]: w for w in WAREHOUSES}
    policies = {}
    for warehouse_code, skus in stocked.items():
        warehouse = warehouse_lookup[warehouse_code]
        sku_set = skus
        for sku in skus:
            product = products_by_sku[sku]
            buyer = (LAX_REVIEW_BUYER if rng.random() < 0.32
                     else str(rng.choice([b for b in BUYERS if b != LAX_REVIEW_BUYER])))
            stale_probability = 0.36 if buyer == LAX_REVIEW_BUYER else 0.13
            if rng.random() < stale_probability:
                last_reviewed = PERIOD_END - timedelta(days=int(rng.integers(470, 920)))
            else:
                last_reviewed = PERIOD_END - timedelta(days=int(rng.integers(20, 440)))

            primary = next(s for s in sourcing_index[sku] if s["is_primary_source"])
            lead_time = primary["quoted_lead_time_days"]
            daily_at_review = expected_daily_units(product, warehouse, last_reviewed,
                                                   sku_set, products_by_sku)

            # Demand here is lumpy: a few sizeable orders, not a smooth daily draw. Safety
            # stock is therefore sized on order arrivals over the lead time, not on daily units.
            typical_line = product["typical_qty"] * AVERAGE_QUANTITY_FACTOR
            orders_in_lead_time = max(1.0, daily_at_review / typical_line * lead_time)
            safety = warehouse["safety_multiplier"] * 1.3 * typical_line * math.sqrt(orders_in_lead_time)
            safety_units = max(1, int(math.ceil(safety)))
            # A stocked line is held deep enough to cover a normal order, however slow it sells.
            order_floor = product["typical_qty"]
            reorder_point = max(2, int(math.ceil(order_floor * 1.5)), int(math.ceil(
                daily_at_review * lead_time * warehouse["pipeline_cover"] + safety_units)))
            reorder_quantity = max(3, int(math.ceil(order_floor * 3.0)), int(math.ceil(
                daily_at_review * REORDER_COVER_DAYS * warehouse["reorder_cover_multiplier"])))

            stocked_since = max(product["introduced_date"], warehouse["opened_date"])
            policies[(sku, warehouse_code)] = {
                "sku": sku, "warehouse_code": warehouse_code,
                "reorder_point_units": reorder_point,
                "reorder_quantity_units": reorder_quantity,
                "safety_stock_units": safety_units,
                "review_method": str(rng.choice(["Min/max", "Periodic review", "Manual buyer judgement"],
                                                p=[0.62, 0.26, 0.12])),
                "last_reviewed_date": last_reviewed,
                "set_by_buyer": buyer,
                "stocked_since": stocked_since,
                "daily_at_review": daily_at_review,
            }
    return policies


class Simulation:
    def __init__(self, rng, products, products_by_sku, suppliers, sourcing_index,
                 customers, stocked, policies):
        self.rng = rng
        self.products = products
        self.products_by_sku = products_by_sku
        self.suppliers_by_code = {s["supplier_code"]: s for s in suppliers}
        self.sourcing_index = sourcing_index
        self.customers = customers
        self.stocked = stocked
        self.policies = policies
        self.warehouse_lookup = {w["code"]: w for w in WAREHOUSES}

        self.on_hand = defaultdict(int)
        self.wac = defaultdict(float)
        self.on_order = defaultdict(int)
        self.allocated = defaultdict(int)
        self.zero_days = defaultdict(int)

        self.movements = []
        self.sales_orders = []
        self.sales_order_lines = []
        self.purchase_orders = []
        self.purchase_order_lines = []
        self.goods_receipt_lines = []
        self.snapshots = []

        self.pending_despatch = defaultdict(list)
        self.pending_receipt = defaultdict(list)
        self.pending_return = defaultdict(list)
        self.received_by_po_line = defaultdict(int)
        self.po_line_index = {}
        self.movement_id = 0
        self.po_counter = 0
        self.so_counter = 0
        self.grn_counter = 0
        self.transfer_counter = 0
        self.transfer_count = 0

        self.customers_by_warehouse = defaultdict(list)
        for customer in customers:
            self.customers_by_warehouse[customer["primary_warehouse_code"]].append(customer)
        self.customer_weight = {}
        for warehouse_code, members in self.customers_by_warehouse.items():
            weights = np.array([float(self.rng.lognormal(0.0, 1.05)) for _ in members])
            self.customer_weight[warehouse_code] = weights / weights.sum()

        self.month_weights = {}

    def post_movement(self, sku, warehouse_code, day, movement_type, quantity, source_document,
                      inbound_price=None):
        if quantity == 0:
            return
        key = (sku, warehouse_code)
        if quantity > 0 and inbound_price is not None:
            current = self.on_hand[key]
            if current <= 0:
                self.wac[key] = inbound_price
            else:
                self.wac[key] = (current * self.wac[key] + quantity * inbound_price) / (current + quantity)
        self.on_hand[key] += quantity
        self.movement_id += 1
        self.movements.append({
            "movement_id": self.movement_id, "sku": sku, "warehouse_code": warehouse_code,
            "movement_date": day, "movement_type": movement_type, "quantity": int(quantity),
            "unit_cost_gbp": round(self.wac[key], 2), "source_document": source_document,
        })

    def seed_opening_balances(self, warehouse_code, day):
        for sku in self.stocked[warehouse_code]:
            policy = self.policies[(sku, warehouse_code)]
            primary = next(s for s in self.sourcing_index[sku] if s["is_primary_source"])
            opening = int(policy["reorder_point_units"]
                          + self.rng.integers(0, max(2, policy["reorder_quantity_units"])))
            self.post_movement(sku, warehouse_code, day, "Opening balance", opening,
                               f"OPEN-{warehouse_code}-{day.isoformat()}",
                               inbound_price=primary["base_cost"])

    def refresh_month_weights(self, day):
        month_key = (day.year, day.month)
        if month_key in self.month_weights:
            return
        weights = {}
        for warehouse_code, skus in self.stocked.items():
            raw = []
            for sku in skus:
                product = self.products_by_sku[sku]
                if product["discontinued_date"] and day > product["discontinued_date"] + timedelta(days=120):
                    raw.append(0.0)
                    continue
                raw.append(product["line_weight"]
                           * product["seasonality"][day.month - 1]
                           * trend_factor(product, day))
            array = np.array(raw)
            weights[warehouse_code] = (array, array.sum())
        self.month_weights[month_key] = weights

    def baseline_weight_sum(self, warehouse_code):
        return sum(self.products_by_sku[sku]["line_weight"] for sku in self.stocked[warehouse_code])

    def generate_orders(self, day):
        month_key = (day.year, day.month)
        weights = self.month_weights[month_key]
        for warehouse in WAREHOUSES:
            code = warehouse["code"]
            if day < warehouse["opened_date"]:
                continue
            rate = (warehouse["orders_per_day"] if day >= date(2024, 7, 1)
                    else warehouse["pre_bristol_orders"])
            if rate <= 0:
                continue
            array, total = weights[code]
            if total <= 0:
                continue
            demand_scale = total / self.baseline_weight_sum(code)
            expected = rate * WEEKDAY_FACTOR[day.weekday()] * demand_scale
            for _ in range(int(self.rng.poisson(expected))):
                self.create_sales_order(day, code, array, total)

    def create_sales_order(self, day, warehouse_code, weight_array, weight_total):
        members = self.customers_by_warehouse[warehouse_code]
        customer = members[int(self.rng.choice(len(members), p=self.customer_weight[warehouse_code]))]
        segment = next(s for s in CUSTOMER_SEGMENTS if s[0] == customer["customer_segment"])
        line_count = max(1, min(8, int(self.rng.poisson(segment[2]))))
        skus = self.stocked[warehouse_code]
        probabilities = weight_array / weight_total
        available = int((probabilities > 0).sum())
        line_count = min(line_count, available)
        if line_count == 0:
            return
        chosen = self.rng.choice(len(skus), size=line_count, replace=False, p=probabilities)

        self.so_counter += 1
        order_number = f"SO-{day.year}-{self.so_counter:05d}"
        despatch_lag = int(self.rng.choice([0, 1, 2, 3], p=[0.70, 0.20, 0.07, 0.03]))
        despatch_day = add_working_days(day, despatch_lag) if despatch_lag else next_working_day(day)
        if despatch_day > PERIOD_END:
            despatch_day = None

        channel = ORDER_CHANNELS[int(self.rng.choice(len(ORDER_CHANNELS),
                                                     p=[c[1] for c in ORDER_CHANNELS]))][0]
        self.sales_orders.append({
            "sales_order_number": order_number,
            "customer_account": customer["customer_account"],
            "warehouse_code": warehouse_code,
            "order_date": day,
            "requested_delivery_date": add_working_days(day, int(self.rng.integers(1, 5))),
            "despatch_date": despatch_day,
            "order_channel": channel,
            "order_status": "Despatched",
        })

        for line_number, sku_index in enumerate(chosen, start=1):
            sku = skus[int(sku_index)]
            product = self.products_by_sku[sku]
            quantity = max(1, int(round(product["typical_qty"] * float(self.rng.lognormal(0.0, 0.55)))))
            if customer["customer_segment"] == "Housebuilder" and self.rng.random() < 0.10:
                quantity *= int(self.rng.integers(5, 12))
            discount = float(round(min(42.0, max(0.0, self.rng.normal(segment[3] * 12, 6))), 2))
            unit_price = round(product["list_price_gbp"] * (1 - discount / 100), 2)
            line = {
                "sales_order_number": order_number, "line_number": line_number, "sku": sku,
                "quantity_ordered": quantity, "quantity_despatched": 0,
                "unit_price_gbp": unit_price, "line_discount_pct": discount,
                "line_status": "Despatched in full",
            }
            self.sales_order_lines.append(line)
            if self.rng.random() < 0.02 or despatch_day is None:
                line["line_status"] = "Cancelled"
                continue
            self.allocated[(sku, warehouse_code)] += quantity
            self.pending_despatch[despatch_day].append((line, sku, warehouse_code, order_number))

    def process_despatches(self, day):
        for line, sku, warehouse_code, order_number in self.pending_despatch.pop(day, []):
            key = (sku, warehouse_code)
            self.allocated[key] -= line["quantity_ordered"]
            available = self.on_hand[key]
            despatched = min(line["quantity_ordered"], max(0, available))
            line["quantity_despatched"] = despatched
            if despatched == 0:
                line["line_status"] = "Not available"
                continue
            line["line_status"] = ("Despatched in full" if despatched == line["quantity_ordered"]
                                   else "Short shipped")
            self.post_movement(sku, warehouse_code, day, "Sales issue", -despatched, order_number)
            if self.rng.random() < 0.008:
                return_day = add_working_days(day, int(self.rng.integers(5, 20)))
                if return_day <= PERIOD_END:
                    self.pending_return[return_day].append((line, sku, warehouse_code, order_number, despatched))

    def process_returns(self, day):
        for line, sku, warehouse_code, order_number, despatched in self.pending_return.pop(day, []):
            self.post_movement(sku, warehouse_code, day, "Customer return", despatched, order_number,
                               inbound_price=self.wac[(sku, warehouse_code)] or None)
            line["line_status"] = "Returned"

    def choose_source(self, sku, warehouse_code, day):
        options = self.sourcing_index[sku]
        primary = next(s for s in options if s["is_primary_source"])
        alternatives = [s for s in options if not s["is_primary_source"]]
        if not alternatives:
            return primary
        probability = self.warehouse_lookup[warehouse_code]["alternative_source_probability"]
        if self.rng.random() < probability:
            return alternatives[int(self.rng.integers(0, len(alternatives)))]
        return primary

    def unit_cost_for(self, sourcing_record, day):
        cost = sourcing_record["base_cost"]
        if sourcing_record["supplier_code"] == PRICE_RISE_SUPPLIER and day >= PRICE_RISE_DATE:
            cost *= PRICE_RISE_FACTOR
        return round(cost * float(self.rng.uniform(0.985, 1.015)), 2)

    def buy_ahead_active(self, day, supplier_code):
        return supplier_code == PRICE_RISE_SUPPLIER and BUY_AHEAD_START <= day <= BUY_AHEAD_END

    def run_replenishment(self, day):
        triggers = defaultdict(list)
        for warehouse in WAREHOUSES:
            code = warehouse["code"]
            if day < warehouse["opened_date"]:
                continue
            for sku in self.stocked[code]:
                key = (sku, code)
                policy = self.policies[key]
                position = self.on_hand[key] + self.on_order[key]
                source = self.choose_source(sku, code, day)
                threshold = policy["reorder_point_units"]
                if self.buy_ahead_active(day, source["supplier_code"]):
                    threshold = int(threshold * 2)
                if position > threshold:
                    continue
                triggers[(code, source["supplier_code"])].append((sku, source, policy))

        for (warehouse_code, supplier_code), items in triggers.items():
            self.add_consolidation_lines(day, warehouse_code, supplier_code, items)
            self.raise_purchase_order(day, warehouse_code, supplier_code, items)

    def add_consolidation_lines(self, day, warehouse_code, supplier_code, items):
        if len(items) >= 4:
            return
        existing = {sku for sku, _, _ in items}
        candidates = []
        for sku in self.stocked[warehouse_code]:
            if sku in existing:
                continue
            record = next((s for s in self.sourcing_index[sku] if s["supplier_code"] == supplier_code), None)
            if record is None:
                continue
            key = (sku, warehouse_code)
            policy = self.policies[key]
            position = self.on_hand[key] + self.on_order[key]
            if position <= policy["reorder_point_units"] * 1.5:
                candidates.append((position / max(1, policy["reorder_point_units"]), sku, record, policy))
        candidates.sort()
        for _, sku, record, policy in candidates[: 4 - len(items)]:
            items.append((sku, record, policy))

    def raise_purchase_order(self, day, warehouse_code, supplier_code, items):
        supplier = self.suppliers_by_code[supplier_code]
        self.po_counter += 1
        order_number = f"PO-{day.year}-{self.po_counter:05d}"
        quoted = supplier["spec"]["quoted_lead_time"]
        promised = add_working_days(day, quoted)
        self.purchase_orders.append({
            "purchase_order_number": order_number, "supplier_code": supplier_code,
            "warehouse_code": warehouse_code, "order_date": day,
            "promised_delivery_date": promised,
            "buyer_name": str(self.rng.choice(BUYERS)),
            "order_status": "Complete",
        })

        mean, sd = supplier_lead_time_shape(supplier, day)
        on_time_rate = supplier_on_time_rate(supplier, day)

        for line_number, (sku, source, policy) in enumerate(items, start=1):
            quantity = max(policy["reorder_quantity_units"], source["minimum_order_quantity"])
            multiple = source["order_multiple"]
            quantity = int(math.ceil(quantity / multiple) * multiple)
            if self.buy_ahead_active(day, supplier_code):
                quantity = int(math.ceil(quantity * float(self.rng.uniform(2.5, 4.0)) / multiple) * multiple)
            unit_cost = self.unit_cost_for(source, day)
            self.purchase_order_lines.append({
                "purchase_order_number": order_number, "line_number": line_number, "sku": sku,
                "quantity_ordered": quantity, "unit_cost_gbp": unit_cost,
                "line_status": "Received in full",
            })
            self.po_line_index[(order_number, line_number)] = self.purchase_order_lines[-1]
            self.on_order[(sku, warehouse_code)] += quantity
            self.schedule_receipts(day, order_number, line_number, sku, warehouse_code, supplier,
                                   quantity, unit_cost, mean, sd, on_time_rate, quoted)

    def schedule_receipts(self, day, order_number, line_number, sku, warehouse_code, supplier,
                          quantity, unit_cost, mean, sd, on_time_rate, quoted):
        actual = float(self.rng.normal(mean, sd))
        if self.rng.random() < on_time_rate:
            actual = min(actual, quoted - 0.5)
        else:
            actual = max(actual, quoted + 1.5)
        actual_days = max(1, int(round(actual)))

        splits = [(quantity, actual_days)]
        if self.rng.random() < supplier["spec"]["split_rate"] and quantity >= 4:
            first = int(quantity * float(self.rng.uniform(0.55, 0.8)))
            splits = [(first, actual_days), (quantity - first, actual_days + int(self.rng.integers(3, 18)))]

        for split_quantity, offset in splits:
            arrival = add_working_days(day, offset)
            if warehouse_code == "LIV" and arrival.weekday() != 0 and self.rng.random() < LIVINGSTON_LATE_BOOKING_RATE:
                arrival += timedelta(days=(7 - arrival.weekday()) % 7 or 7)
            arrival = next_working_day(arrival)
            self.pending_receipt[arrival].append(
                (order_number, line_number, sku, warehouse_code, split_quantity, unit_cost, supplier))

    def process_receipts(self, day):
        for (order_number, line_number, sku, warehouse_code, quantity, unit_cost,
             supplier) in self.pending_receipt.pop(day, []):
            rejected = int(self.rng.binomial(quantity, supplier["spec"]["reject_rate"]))
            accepted = quantity - rejected
            self.grn_counter += 1
            self.goods_receipt_lines.append({
                "receipt_reference": f"GRN-{day.year}-{self.grn_counter:05d}", "line_number": 1,
                "purchase_order_number": order_number, "purchase_order_line_number": line_number,
                "warehouse_code": warehouse_code, "receipt_date": day,
                "quantity_received": accepted, "quantity_rejected": rejected,
            })
            self.on_order[(sku, warehouse_code)] = max(0, self.on_order[(sku, warehouse_code)] - quantity)
            self.received_by_po_line[(order_number, line_number)] += accepted
            if accepted:
                self.post_movement(sku, warehouse_code, day, "Goods receipt", accepted,
                                   order_number, inbound_price=unit_cost)

    def run_stock_counts(self, day):
        if day.day != 14:
            return
        for warehouse in WAREHOUSES:
            code = warehouse["code"]
            if day < warehouse["opened_date"]:
                continue
            shrinkage_scale = 0.035 if code == "BRS" else 0.008
            counted = self.rng.choice(self.stocked[code],
                                      size=min(len(self.stocked[code]), 45), replace=False)
            for sku in counted:
                key = (sku, code)
                held = self.on_hand[key]
                if held <= 0:
                    continue
                drift = float(self.rng.normal(-shrinkage_scale, 0.02))
                delta = int(round(held * drift))
                if delta == 0 and abs(drift) > 0.01:
                    delta = -1 if drift < 0 else 1
                delta = max(-held, delta)
                if delta == 0:
                    continue
                self.post_movement(sku, code, day, "Stock adjustment", delta,
                                   f"COUNT-{code}-{day.isoformat()}",
                                   inbound_price=self.wac[key] if delta > 0 else None)

    def run_write_offs(self, day):
        if day.weekday() != 2:
            return
        for warehouse in WAREHOUSES:
            code = warehouse["code"]
            if day < warehouse["opened_date"] or self.rng.random() > 0.80:
                continue
            sku = str(self.rng.choice(self.stocked[code]))
            key = (sku, code)
            if self.on_hand[key] <= 2:
                continue
            quantity = min(self.on_hand[key], max(1, int(self.on_hand[key] * 0.02)))
            self.post_movement(sku, code, day, "Write-off", -quantity,
                               f"WOFF-{code}-{day.isoformat()}")

    def run_transfers(self, day):
        if self.transfer_count >= 560 or day.weekday() > 4:
            return
        for warehouse in WAREHOUSES:
            code = warehouse["code"]
            if code == "DAV" or day < warehouse["opened_date"] or self.rng.random() > 0.70:
                continue
            short = [sku for sku in self.stocked[code] if self.on_hand[(sku, code)] == 0]
            if not short:
                continue
            sku = str(self.rng.choice(short))
            source_key = (sku, "DAV")
            policy = self.policies[(sku, code)]
            available = self.on_hand[source_key]
            if available < policy["reorder_point_units"] * 1.2:
                continue
            quantity = max(1, min(available // 3, policy["reorder_quantity_units"]))
            self.transfer_counter += 1
            reference = f"TRF-{day.year}-{self.transfer_counter:04d}"
            cost = self.wac[source_key]
            self.post_movement(sku, "DAV", day, "Transfer out", -quantity, reference)
            self.post_movement(sku, code, day, "Transfer in", quantity, reference, inbound_price=cost)
            self.transfer_count += 1

    def record_zero_days(self, day):
        for warehouse in WAREHOUSES:
            code = warehouse["code"]
            if day < warehouse["opened_date"]:
                continue
            for sku in self.stocked[code]:
                if self.on_hand[(sku, code)] <= 0:
                    self.zero_days[(sku, code)] += 1

    def write_snapshot(self, day):
        for warehouse in WAREHOUSES:
            code = warehouse["code"]
            if day < warehouse["opened_date"]:
                continue
            for sku in self.stocked[code]:
                key = (sku, code)
                on_hand = self.on_hand[key]
                cost = round(self.wac[key], 2)
                self.snapshots.append({
                    "week_ending_date": day, "sku": sku, "warehouse_code": code,
                    "quantity_on_hand": on_hand,
                    "quantity_allocated": max(0, self.allocated[key]),
                    "quantity_on_order": max(0, self.on_order[key]),
                    "days_at_zero_in_week": min(7, self.zero_days[key]),
                    "weighted_average_cost_gbp": cost,
                    "stock_value_gbp": round(on_hand * cost, 2),
                })
                self.zero_days[key] = 0

    def finalise_statuses(self):
        for (order_number, line_number), line in self.po_line_index.items():
            received = self.received_by_po_line[(order_number, line_number)]
            if received >= line["quantity_ordered"]:
                line["line_status"] = "Received in full"
            elif received > 0:
                line["line_status"] = "Part received"
            else:
                line["line_status"] = "Outstanding"

        lines_by_po = defaultdict(list)
        for line in self.purchase_order_lines:
            lines_by_po[line["purchase_order_number"]].append(line["line_status"])
        for order in self.purchase_orders:
            statuses = lines_by_po[order["purchase_order_number"]]
            if all(s == "Received in full" for s in statuses):
                order["order_status"] = "Complete"
            elif any(s in {"Received in full", "Part received"} for s in statuses):
                order["order_status"] = "Part received"
            else:
                order["order_status"] = "Outstanding"

        lines_by_so = defaultdict(list)
        for line in self.sales_order_lines:
            lines_by_so[line["sales_order_number"]].append(line["line_status"])
        for order in self.sales_orders:
            statuses = lines_by_so[order["sales_order_number"]]
            if all(s == "Cancelled" for s in statuses):
                order["order_status"] = "Cancelled"
                order["despatch_date"] = None
            elif any(s in {"Short shipped", "Not available"} for s in statuses):
                order["order_status"] = "Part despatched"
            else:
                order["order_status"] = "Despatched"

    def apply_promised_date_errors(self):
        candidates = self.rng.choice(len(self.purchase_orders),
                                     size=PROMISED_DATE_ERROR_COUNT, replace=False)
        for index in candidates:
            order = self.purchase_orders[int(index)]
            order["promised_delivery_date"] = order["order_date"] - timedelta(
                days=int(self.rng.integers(1, 20)))

    def apply_missing_promised_dates(self):
        for order in self.purchase_orders:
            if self.rng.random() < 0.02:
                order["promised_delivery_date"] = None

    def run(self):
        for warehouse in WAREHOUSES:
            if warehouse["opened_date"] <= PERIOD_START:
                self.seed_opening_balances(warehouse["code"], PERIOD_START)

        day = PERIOD_START
        while day <= PERIOD_END:
            for warehouse in WAREHOUSES:
                if warehouse["opened_date"] == day:
                    self.seed_opening_balances(warehouse["code"], day)

            self.refresh_month_weights(day)
            self.process_receipts(day)
            self.process_returns(day)
            if day.weekday() < 5 and day not in BANK_HOLIDAYS:
                self.generate_orders(day)
                self.process_despatches(day)
                self.run_transfers(day)
                self.run_write_offs(day)
                self.run_stock_counts(day)
                self.run_replenishment(day)
            self.record_zero_days(day)
            if day.weekday() == 6 and day >= FIRST_WEEK_END:
                self.write_snapshot(day)
            day += timedelta(days=1)

        self.finalise_statuses()
        self.apply_promised_date_errors()
        self.apply_missing_promised_dates()


def build_dataset():
    rng = np.random.default_rng(SEED)
    products = build_products(rng)
    suppliers = build_suppliers(rng)
    sourcing, sourcing_index, products_by_sku = build_sourcing(rng, products, suppliers)
    customers = build_customers(rng)
    stocked = assign_stocked_range(rng, products)
    policies = build_policies(rng, products_by_sku, stocked, sourcing_index)

    simulation = Simulation(rng, products, products_by_sku, suppliers, sourcing_index,
                            customers, stocked, policies)
    simulation.run()

    return {
        "warehouse": build_warehouse_table(),
        "product_category": build_category_table(),
        "product": products,
        "supplier": suppliers,
        "product_supplier": sourcing,
        "customer": customers,
        "calendar_week": build_calendar_weeks(),
        "replenishment_policy": list(policies.values()),
        "purchase_order": simulation.purchase_orders,
        "purchase_order_line": simulation.purchase_order_lines,
        "goods_receipt_line": simulation.goods_receipt_lines,
        "sales_order": simulation.sales_orders,
        "sales_order_line": simulation.sales_order_lines,
        "stock_movement": simulation.movements,
        "inventory_snapshot": simulation.snapshots,
    }


if __name__ == "__main__":
    export_dataset(build_dataset())
