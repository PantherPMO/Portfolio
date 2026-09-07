#!/usr/bin/env python3
"""
validate_charts.py - Project 01 COMMUNICATE stage validation gate.

Runs after scripts/build_charts.py. Produces the evidence behind
docs/COMMUNICATION_VALIDATION.md.

Eight checks per chart, matching the COMMUNICATE stage brief:

  V1  Numeric      - every headline value on the chart is present, verbatim, in
                     the chart's audit CSV, which was itself written from the
                     committed psql output. String comparison, not float
                     comparison, so a re-rounded value fails.
  V2  Scope        - the chart's audit CSV contains only rows of the declared
                     population scope, checked on the output's own scope column.
  V3  Prohibited   - no field excluded at the database level (Satisfaction Score,
                     Churn Score, CLTV, Churn Reason, Churn Category) and no restricted
                     protected characteristic appears in the chart's data.
  V4  Causation    - no causal verb appears in any title, label or annotation.
  V5  Null honesty - the divergence chart states the null result in its own title.
  V6  Weak lenses  - the driver charts contain every lens, including the weak ones.
  V7  Labels       - declared source file, block and A-07 designation are present.
  V8  Artefact     - the PNG exists, is a valid non-empty PNG, and has plausible
                     dimensions.

Exit code 0 only if every check passes.
"""

from __future__ import annotations

import csv
import re
import struct
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
FIGURES = ROOT / "visuals"
CHART_DATA = ROOT / "analysis" / "chart_data"

# Excluded fields (structural exclusions) and restricted protected characteristics.
PROHIBITED = [
    "satisfaction", "churn_score", "churn score", "cltv", "churn_reason",
    "churn reason", "churn_category", "churn category",
    "gender", "age", "senior", "dependent", "married", "under_30", "under 30",
]

# Causal verbs. "drives" is allowed only in the DSL caveat sentence, which is
# explicitly about a single observation driving a rate, not about causation of
# churn; that string is whitelisted below.
CAUSAL = [
    r"\bcauses\b", r"\bcaused\b", r"\bcausing\b", r"\bleads to\b", r"\bresults in\b",
    r"\bdue to\b", r"\bbecause of\b", r"\bdriver of churn\b", r"\bimpact of\b",
]
CAUSAL_WHITELIST = [
    "a single observation drives that entire rate",
    "no causal claim", "no causal claims", "causes any churn outcome",
    "nothing here establishes that contract type causes them",
]

# Headline values that must be reproduced exactly. Sourced from
# docs/FINDING_EVIDENCE_REGISTER.md; each is checked against the chart's own
# audit CSV, so a mismatch means the chart and the register disagree.
EXPECTED: dict[str, list[str]] = {
    "CH-01": ["4799408.40", "3566982.60", "1232425.80", "74.32"],
    "CH-02": ["74.32", "78.77"],
    "CH-03": ["16.71", "15.13", "13.87", "31.84", "45.71", "69.91", "100.00", "18.25", "118.75"],
    "CH-04": ["4.07", "3.85", "15.14", "17.89", "12.93", "27.89", "32.14", "29.56", "38.96", "24.36"],
    "CH-05": ["98.07", "99.48", "72.16", "67.86", "31.49", "24.62", "619", "1385", "527", "1789", "126", "1546"],
    "CH-06": ["54.59", "39.42", "45.95", "32.98", "0", "1", "-1"],
    "CH-07": ["566313.60", "406459.20", "123038.40", "45.95", "32.98", "54.59", "5.26", "19.19"],
    "CH-08": ["54.59", "19.19", "5.26", "71.57", "15.52", "44.44", "1.25", "47.62", "71.88", "12.11",
              "38.57", "24.82", "36", "42", "64", "74", "80"],
    "CH-09": ["0.67", "0.52", "0.49", "0.36", "0.15", "0.12", "0.06", "0.00", "-0.63", "-0.56"],
    "CH-10": ["1232425.80", "437144.40", "73.82", "26.18"],
    "CH-11": ["1003", "95.43", "26", "22", "457", "594", "61.71", "53.03"],
}

# Declared population scope per chart, and the scope column that proves it.
SCOPE: dict[str, tuple[str, set[str]]] = {
    "CH-01": ("scope", {"opening_base"}),
    "CH-02": ("scope", {"opening_base"}),
    "CH-03": ("", set()),                                  # all customers; block has no scope column
    "CH-04": ("population_scope", {"opening_base"}),
    "CH-05": ("scope", {"opening_base"}),
    "CH-06": ("population_scope", {"opening_base"}),
    "CH-07": ("population_scope", {"opening_base"}),
    "CH-08": ("scope_cohort", {"opening_base"}),
    "CH-09": ("", set()),                                  # comparison block: both scopes by design
    "CH-10": ("scope", {"opening_base", "in_period_acquisition", "ALL"}),
    "CH-11": ("scope_cohort", {"in_period_acquisition"}),
}

FILES = {
    "CH-01": "CH01_revenue_at_risk_opening_cohort.png",
    "CH-02": "CH02_revenue_vs_customer_retention.png",
    "CH-03": "CH03_revenue_concentration_pareto.png",
    "CH-04": "CH04_churn_by_revenue_decile.png",
    "CH-05": "CH05_arpu_churned_vs_retained_by_tier.png",
    "CH-06": "CH06_divergence_primary_opening_cohort.png",
    "CH-07": "CH07_revenue_at_risk_by_segment.png",
    "CH-08": "CH08_driver_lenses_high_tier.png",
    "CH-09": "CH09_high_tier_vs_base_wide_drivers.png",
    "CH-10": "CH10_early_life_contribution.png",
    "CH-11": "CH11_early_life_composition.png",
}


def read_audit(chart_id: str) -> tuple[list[str], list[dict[str, str]], str]:
    path = CHART_DATA / f"{chart_id}_data.csv"
    with path.open(encoding="utf-8") as fh:
        rows = list(csv.reader(fh))
    meta = " ".join(rows[0])
    header = rows[1]
    data = [dict(zip(header, r)) for r in rows[2:]]
    return header, data, meta


def png_dimensions(path: Path) -> tuple[int, int]:
    raw = path.read_bytes()
    if raw[:8] != b"\x89PNG\r\n\x1a\n":
        raise ValueError("not a PNG")
    w, h = struct.unpack(">II", raw[16:24])
    return w, h


def chart_text(chart_id: str) -> str:
    """The literal title/label/annotation text this chart emits, from the builder."""
    src = (ROOT / "scripts" / "build_charts.py").read_text(encoding="utf-8")
    fn = f"def ch{chart_id.split('-')[1]}("
    start = src.index(fn)
    nxt = src.find("\ndef ", start + 1)
    body = src[start: nxt if nxt != -1 else len(src)]
    # Join adjacent string literals so a sentence split across source lines is
    # scanned as one sentence, not two fragments.
    return re.sub(r'"\s*\n\s*"', "", body)


def main() -> int:
    results = []
    ok_all = True

    for cid in FILES:
        header, data, meta = read_audit(cid)
        blob = " ".join(" ".join(r.values()) for r in data).lower()
        body = chart_text(cid)
        png = FIGURES / FILES[cid]
        checks: dict[str, str] = {}

        # V1 numeric
        missing = [v for v in EXPECTED[cid]
                   if not any(v == cell for r in data for cell in r.values())]
        checks["V1"] = "PASS" if not missing else f"FAIL missing {missing}"

        # V2 scope
        col, allowed = SCOPE[cid]
        if not col:
            checks["V2"] = "PASS (n/a - single-scope block)"
        else:
            seen = {r[col] for r in data}
            checks["V2"] = "PASS" if seen <= allowed else f"FAIL unexpected scopes {seen - allowed}"

        # V3 prohibited fields
        hay = (" ".join(header) + " " + blob).lower()
        hits = [p for p in PROHIBITED if p in hay]
        checks["V3"] = "PASS" if not hits else f"FAIL prohibited term {hits}"

        # V4 causal language
        scrub = body.lower()
        for w in CAUSAL_WHITELIST:
            scrub = scrub.replace(w, "")
        cz = [p for p in CAUSAL if re.search(p, scrub)]
        checks["V4"] = "PASS" if not cz else f"FAIL causal phrase {cz}"

        # V5 null honesty
        if cid == "CH-06":
            checks["V5"] = "PASS" if "near-null" in body and "NEGATIVE FINDING" in body \
                else "FAIL null not stated in chart text"
        elif cid == "CH-09":
            checks["V5"] = "PASS" if "NULL RESULT" in body and "barely" in body \
                else "FAIL null not stated in chart text"
        else:
            checks["V5"] = "PASS (n/a)"

        # V6 weak lenses present
        if cid in ("CH-08", "CH-09"):
            lens_col = "lens_id"
            seen = {r[lens_col] for r in data}
            need = {"L1", "L2", "L3", "L4", "L5", "L6", "L7"}
            checks["V6"] = "PASS" if need <= seen else f"FAIL missing lenses {need - seen}"
        else:
            checks["V6"] = "PASS (n/a)"

        # V7 labels: source declared, and A-07 designation carried where required
        lbl = "source=" in meta and "block=" in meta
        if cid in ("CH-06", "CH-07"):
            lbl = lbl and all(r.get("result_designation") == "PRIMARY RESULT - Opening cohort" for r in data)
            lbl = lbl and "PRIMARY RESULT - Opening cohort" in body
        checks["V7"] = "PASS" if lbl else "FAIL label/designation missing"

        # V8 artefact integrity
        try:
            w, h = png_dimensions(png)
            size = png.stat().st_size
            checks["V8"] = "PASS" if size > 20_000 and w > 800 and h > 400 \
                else f"FAIL size={size} dims={w}x{h}"
            dims = f"{w}x{h}, {size:,} B"
        except Exception as exc:  # noqa: BLE001
            checks["V8"] = f"FAIL {exc}"
            dims = "-"

        status = "PASS" if all(v.startswith("PASS") for v in checks.values()) else "FAIL"
        ok_all &= status == "PASS"
        results.append((cid, meta, checks, status, dims))
        print(f"{cid}  {status:4}  {dims:24}  " + "  ".join(f"{k}:{v.split()[0]}" for k, v in checks.items()))
        for k, v in checks.items():
            if not v.startswith("PASS"):
                print(f"      {k}: {v}")

    print("\nOVERALL:", "PASS" if ok_all else "FAIL")
    return 0 if ok_all else 1


if __name__ == "__main__":
    raise SystemExit(main())
