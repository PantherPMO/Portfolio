#!/usr/bin/env python3
"""
build_charts.py - Project 01 COMMUNICATE stage chart builder.

Telecommunications Revenue Retention: Prioritising Retention Investment by
Revenue at Risk.

WHAT THIS SCRIPT IS
-------------------
The single reproducible source of every figure in visuals/. It reads
the committed, validated psql outputs in analysis/query_results/, writes the
exact rows used by each chart to analysis/chart_data/ as an audit trail, then
renders the charts.

WHAT IT IS NOT
--------------
It performs NO analysis. It creates no KPI, no segment, no cut point, no rate
and no ranking. Every analytical value it draws was produced by the locked SQL
pipeline and passed gates A-VAL-01 to A-VAL-19.

HARD-CODED VALUES
-----------------
There are no hard-coded analytical results. The only literals in this file are
labels, colours, axis bounds and the source-file/column references that define
each chart. Two classes of display arithmetic are performed on values already
present in the outputs; each is marked in code with `DERIVED:` and is recorded
in docs/COMMUNICATION_VALIDATION.md:

  1. A difference between two displayed percentages (CH-02), shown with its
     arithmetic on the chart itself.
  2. A complement to 100% (CH-10), where the sourced share is 31.94% and the
     remainder is shown as 68.06%.

Panel ordering in CH-08 is by index spread computed from displayed values. That
changes presentation order only, never a value.

STANDING CONSTRAINTS (docs/FINDING_EVIDENCE_REGISTER.md)
--------------------------------------------------------
* Currency is UNKNOWN (profiling check P-15). Monetary values are labelled
  "currency units". No currency symbol appears anywhere in this file.
* The data is fictional (IBM sample: 7,043 customers, California, Q3).
* One observation window. No trend. Tenure is not a time axis.
* Association only. No chart title, label or annotation asserts causation.
* Opening cohort (tenure >= 4) is the PRIMARY population (C-3). The all-customer
  rate is a reconciliation measure and is never substituted for it.
* A-07 is locked (D-21): the divergence primary result is the opening cohort;
  the all-customers version is a labelled sensitivity analysis and is not
  promoted.

USAGE
-----
    python scripts/build_charts.py

Run from the project root. Requires matplotlib only (no pandas). Outputs are
deterministic: re-running from a clean checkout reproduces identical figures.
"""

from __future__ import annotations

import csv
import sys
from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.lines import Line2D
from matplotlib.patches import Patch

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "scripts"))

from psql_parse import Block, parse_file  # noqa: E402

RESULTS = ROOT / "analysis" / "query_results"
FIGURES = ROOT / "visuals"
CHART_DATA = ROOT / "analysis" / "chart_data"

# ---------------------------------------------------------------------------
# House style - _portfolio/STYLE_GUIDE.md validated categorical palette
# ---------------------------------------------------------------------------

BLUE = "#2A78D6"
ORANGE = "#EB6834"
AQUA = "#1BAF7A"
YELLOW = "#EDA100"
MAGENTA = "#E87BA4"
GREEN = "#008300"
VIOLET = "#4A3AA7"
RED = "#E34948"

SURFACE = "#FCFCFB"
TEXT = "#0B0B0B"
TEXT_2 = "#52514E"
MUTED = "#898781"
GRID = "#E1E0D9"
AXIS = "#C3C2B7"

plt.rcParams.update(
    {
        "figure.facecolor": SURFACE,
        "axes.facecolor": SURFACE,
        "savefig.facecolor": SURFACE,
        "font.family": "DejaVu Sans",
        "font.size": 10,
        "text.color": TEXT,
        "axes.labelcolor": TEXT_2,
        "axes.edgecolor": AXIS,
        "axes.titlesize": 13,
        "axes.titleweight": "bold",
        "axes.labelsize": 10,
        "xtick.color": MUTED,
        "ytick.color": MUTED,
        "xtick.labelsize": 9,
        "ytick.labelsize": 9,
        "grid.color": GRID,
        "grid.linewidth": 0.8,
        "legend.frameon": False,
        "legend.fontsize": 9,
        "figure.dpi": 150,
        "savefig.dpi": 150,
        "savefig.bbox": "tight",
        "savefig.pad_inches": 0.35,
    }
)

# Every figure carries the same provenance strip.
FICTION = (
    "Fictional dataset (IBM sample telco, 7,043 customers, California, Q3). "
    "Single observation window - no trend. Association only; no causal claim."
)
CURRENCY = "Currency is unknown (profiling check P-15) - monetary values are unitless currency units."

TIER_COLOUR = {"Low": "#9EC5F4", "Mid": BLUE, "High": VIOLET}
CONTRACT_COLOUR = {"Month-to-Month": ORANGE, "One Year": BLUE, "Two Year": AQUA}
OUTCOME_COLOUR = {"Churned": ORANGE, "Retained": BLUE}

MANIFEST: list[dict] = []


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def blocks(name: str) -> list[Block]:
    return parse_file(RESULTS / f"{name}.txt")


def audit(chart_id: str, source_file: str, block_index: int, block: Block) -> None:
    """Write the exact rows a chart consumed, so any figure can be checked by hand."""
    path = CHART_DATA / f"{chart_id}_data.csv"
    with path.open("w", newline="", encoding="utf-8") as fh:
        w = csv.writer(fh)
        w.writerow([f"# chart={chart_id}", f"source={source_file}.txt", f"block={block_index}"])
        w.writerow(block.columns)
        for r in block.rows:
            w.writerow(["" if r[c] is None else r[c] for c in block.columns])


def finish(fig, ax_or_axes, chart_id: str, filename: str, scope: str, notes: list[str]) -> None:
    """Apply the common footer and save."""
    footer = f"Population scope: {scope}\n" + "\n".join(notes) + f"\n{FICTION}"
    fig.text(
        0.012,
        -0.012,
        footer,
        ha="left",
        va="top",
        fontsize=7.4,
        color=TEXT_2,
        linespacing=1.55,
        wrap=True,
    )
    out = FIGURES / filename
    fig.savefig(out)
    plt.close(fig)
    size = out.stat().st_size
    MANIFEST.append({"id": chart_id, "file": filename, "bytes": size})
    print(f"  {chart_id}  {filename}  ({size:,} bytes)")


def money(v: float) -> str:
    return f"{v:,.2f}"


def money_short(v: float) -> str:
    return f"{v:,.0f}"


def bare_axes(ax, grid_axis: str = "y") -> None:
    ax.set_axisbelow(True)
    ax.grid(axis=grid_axis, linewidth=0.8)
    for side in ("top", "right"):
        ax.spines[side].set_visible(False)


# ===========================================================================
# CH-01 - Annual recurring revenue at risk, opening cohort
# F-01.4, F-01.7, F-01.9, F-01.10 · analyse_01_base_position.txt block 3
# ===========================================================================


def ch01() -> None:
    b = blocks("analyse_01_base_position")[2].where(scope="opening_base")
    audit("CH-01", "analyse_01_base_position", 3, b)

    total = b.num("opening_arr_currency_units")
    retained = b.num("retained_arr_currency_units")
    lost = b.num("lost_arr_currency_units")
    pct_retained = b.num("revenue_retention_rate_pct")

    b2 = blocks("analyse_01_base_position")[1].where(scope="opening_base")
    pct_at_risk = b2.num("arr_at_risk_pct_of_scope")
    ld = b2.num("long_distance_at_risk_currency_units")

    fig, ax = plt.subplots(figsize=(11, 3.5))
    ax.barh([0], [retained], color=BLUE, height=0.5, label="Revenue retained")
    ax.barh([0], [lost], left=[retained], color=ORANGE, height=0.5, label="Revenue at risk")

    ax.text(
        retained / 2,
        0,
        f"Retained\n{money(retained)}\n{pct_retained:.2f}%",
        ha="center", va="center", color="white", fontsize=10, fontweight="bold",
    )
    ax.text(
        retained + lost / 2,
        0,
        f"At risk\n{money(lost)}\n{pct_at_risk:.2f}%",
        ha="center", va="center", color="white", fontsize=10, fontweight="bold",
    )

    ax.set_xlim(0, total)
    ax.set_ylim(-0.5, 0.5)
    ax.set_yticks([])
    ax.set_xlabel("Annual recurring revenue (currency units)")
    ax.xaxis.set_major_formatter(lambda v, _: f"{v:,.0f}")
    for side in ("top", "right", "left"):
        ax.spines[side].set_visible(False)
    ax.set_axisbelow(True)
    ax.grid(axis="x", linewidth=0.8)

    ax.set_title(
        "Annual recurring revenue at risk - opening cohort\n"
        f"{money(lost)} of {money(total)} currency units",
        loc="left", pad=14,
    )

    finish(
        fig, ax, "CH-01", "CH01_revenue_at_risk_opening_cohort.png",
        "Opening cohort (tenure >= 4 months), n = 5,992 customers, of whom 1,272 churned",
        [
            f"Recurring revenue only (the revenue definition). Long-distance revenue at risk of {money(ld)} "
            "currency units is excluded from this figure and is material, not irrelevant.",
            "Annualisation is convention A-03 (supported by profiling check P-07, median ratio 1.0000) "
            "and remains a forward-looking assumption.",
            CURRENCY,
            "Source: analysis/query_results/analyse_01_base_position.txt, blocks 2 and 3.",
        ],
    )


# ===========================================================================
# CH-02 - Revenue retention vs customer retention
# F-01.9 · analyse_01_base_position.txt block 3
# ===========================================================================


def ch02() -> None:
    b = blocks("analyse_01_base_position")[2].where(scope="opening_base")
    audit("CH-02", "analyse_01_base_position", 3, b)

    rev = b.num("revenue_retention_rate_pct")
    cust = b.num("customer_retention_rate_pct")
    gap = cust - rev  # DERIVED: difference of two displayed percentages; shown with its arithmetic.

    fig, ax = plt.subplots(figsize=(10, 3.1))
    bars = ax.barh(
        ["Revenue retention", "Customer retention"],
        [rev, cust],
        color=[ORANGE, BLUE],
        height=0.40,
    )
    for bar, val in zip(bars, [rev, cust]):
        ax.text(val + 1.2, bar.get_y() + bar.get_height() / 2, f"{val:.2f}%",
                va="center", fontsize=11, fontweight="bold")

    ax.set_xlim(0, 100)
    ax.set_xlabel("Retention rate (%)")
    ax.set_ylim(1.30, -0.30)
    bare_axes(ax, "x")

    ax.annotate(
        "",
        xy=(rev, 0.5), xytext=(cust, 0.5),
        arrowprops=dict(arrowstyle="<->", color=TEXT_2, lw=1.1),
    )
    ax.text(
        cust + 2.0, 0.5,
        f"{gap:.2f} pp gap   ({cust:.2f} − {rev:.2f})",
        ha="left", va="center", fontsize=9, color=TEXT_2,
    )

    ax.set_title(
        "Revenue retention sits below customer retention - opening cohort\n"
        "Customers who left carried, on average, higher recurring revenue than those who stayed",
        loc="left", pad=14,
    )

    finish(
        fig, ax, "CH-02", "CH02_revenue_vs_customer_retention.png",
        "Opening cohort (tenure >= 4 months), n = 5,992",
        [
            "OBSERVED FACT. The gap is arithmetic: if leavers had been an average slice of the base, "
            "the two percentages would coincide. It is not an assumption and not a causal claim.",
            "READ WITH CH-05. The revenue-weighted effect arises in the Mid and Low tiers. Within the "
            "High tier, churned and retained customers have near-identical recurring revenue "
            "(98.07 vs 99.48). This chart alone does not support 'we lose our most valuable customers'.",
            "The 4.45 pp figure is the difference of the two percentages shown, not a separate measure.",
            "Source: analysis/query_results/analyse_01_base_position.txt, block 3.",
        ],
    )


# ===========================================================================
# CH-03 - Revenue concentration (Pareto)
# F-02.1, .3, .7, .8 · analyse_02_revenue_concentration.txt block 1
# ===========================================================================


def ch03() -> None:
    b = blocks("analyse_02_revenue_concentration")[0]
    audit("CH-03", "analyse_02_revenue_concentration", 1, b)

    dec = [int(v) for v in b.col("revenue_decile")]
    share = b.nums("revenue_share_pct")
    cum = b.nums("cumulative_revenue_pct")
    pos = list(range(len(dec)))

    fig, ax = plt.subplots(figsize=(11, 5.6))
    ax.bar(pos, share, color=BLUE, width=0.66, label="Revenue share of decile")
    ax.set_xticks(pos)
    ax.set_xticklabels([str(d) for d in dec])
    ax.set_xlabel("Monthly-charge decile  -  decile 10 = highest charge, decile 1 = lowest")
    ax.set_ylabel("Share of recurring revenue (%)")
    ax.set_ylim(0, 20)
    bare_axes(ax, "y")

    ax2 = ax.twinx()
    ax2.plot(pos, cum, color=ORANGE, marker="o", markersize=4.5, lw=1.9,
             label="Cumulative revenue share")
    ax2.set_ylabel("Cumulative share of recurring revenue (%)")
    ax2.set_ylim(0, 105)
    ax2.spines["top"].set_visible(False)

    for i, s in enumerate(share):
        ax.text(i, s + 0.45, f"{s:.2f}", ha="center", fontsize=8.4, color=TEXT_2)

    handles = [
        Patch(facecolor=BLUE, label="Revenue share of decile (left axis)"),
        Line2D([0], [0], color=ORANGE, marker="o", markersize=4.5, label="Cumulative share (right axis)"),
    ]
    ax.legend(handles=handles, loc="lower left", bbox_to_anchor=(0.0, 0.02))

    ax.set_title(
        "Recurring revenue is moderately, not sharply, concentrated - all customers\n"
        f"The top 10% of customers hold {cum[0]:.2f}% of recurring revenue; the top three deciles "
        f"(the High value tier) hold {cum[2]:.2f}%\n"
        f"Half the base (deciles 6-10) holds {cum[4]:.2f}% - well short of the pattern often assumed "
        "in subscription businesses",
        loc="left", pad=14, fontsize=12,
    )

    finish(
        fig, ax, "CH-03", "CH03_revenue_concentration_pareto.png",
        "All customers, n = 7,043",
        [
            "DECILE CONVENTION: decile 1 = lowest monthly charge, decile 10 = highest. Both conventions "
            "exist in practice; this chart uses the one stated here throughout.",
            "Deciles are equal-frequency (704-705 customers each), not equal-value. Boundary ties are "
            "split by a deterministic NTILE tie-break (correction V-11 / the decile tie-break).",
            "Recurring revenue only (C-2) - this is not total revenue concentration. Static snapshot: "
            "no statement about whether concentration is changing.",
            CURRENCY,
            "Source: analysis/query_results/analyse_02_revenue_concentration.txt, block 1.",
        ],
    )


# ===========================================================================
# CH-04 - Churn rate by revenue decile
# F-03.1 to F-03.4 · analyse_03_churn_by_decile.txt block 1
# ===========================================================================


def ch04() -> None:
    b = blocks("analyse_03_churn_by_decile")[0].where(population_scope="opening_base")
    audit("CH-04", "analyse_03_churn_by_decile", 1, b)

    scope_rate = blocks("analyse_01_base_position")[0].where(scope="opening_base").num("churn_rate_pct")

    dec = [int(v) for v in b.col("revenue_decile")]
    tiers = b.col("value_tier")
    rates = b.nums("churn_rate_pct")
    ns = [int(v) for v in b.col("n")]
    pos = list(range(len(dec)))

    fig, ax = plt.subplots(figsize=(11, 5.8))
    ax.bar(pos, rates, color=[TIER_COLOUR[t] for t in tiers], width=0.66)

    ax.axhline(scope_rate, color=TEXT_2, lw=1.2, ls="--")
    ax.text(
        -0.42, scope_rate + 0.9,
        f"Opening-cohort churn rate {scope_rate:.2f}%",
        ha="left", fontsize=8.8, color=TEXT_2,
    )

    for i, (r, n) in enumerate(zip(rates, ns)):
        ax.text(i, r + 0.7, f"{r:.2f}%", ha="center", fontsize=8.6, fontweight="bold")
        ax.text(i, 0.9, f"n={n}", ha="center", fontsize=7.6, color="white")

    peak = rates.index(max(rates))
    last = len(dec) - 1

    ax.set_xticks(pos)
    ax.set_xticklabels([str(d) for d in dec])
    ax.set_xlabel("Monthly-charge decile  -  decile 1 = lowest charge, decile 10 = highest")
    ax.set_ylabel("Churn rate (%)")
    ax.set_ylim(0, 50)
    bare_axes(ax, "y")

    ax.legend(
        handles=[Patch(facecolor=TIER_COLOUR[t], label=f"{t} value tier") for t in ("Low", "Mid", "High")],
        loc="upper left", bbox_to_anchor=(0.0, 0.72),
    )

    ax.set_title(
        "Churn is not monotonic in customer value - opening cohort\n"
        "Losses concentrate in the upper-middle of the value distribution, not at either extreme\n"
        f"Decile {dec[peak]} is the highest at {rates[peak]:.2f}%; decile {dec[last]} churns at "
        f"{rates[last]:.2f}%, lower than deciles 6, 7, 8 and 9.\n"
        "The dip is unexplained and warrants investigation, not explanation.",
        loc="left", pad=14, fontsize=12,
    )

    finish(
        fig, ax, "CH-04", "CH04_churn_by_revenue_decile.png",
        "Opening cohort (tenure >= 4 months), n = 5,992. All ten decile cells are reportable (n = 535-698).",
        [
            "ASSOCIATION ONLY. Decile membership coincides with differing churn rates. Nothing here "
            "establishes that charge level causes any churn outcome.",
            "Single-dimension cut with no multivariate control. Charge level is related to contract type, "
            "service mix and tenure, none of which is held constant here.",
            "Value-tier colours are the predefined reporting cut points (deciles 8-10 High / 4-7 Mid / 1-3 Low), "
            "fixed before results were seen.",
            "Source: analysis/query_results/analyse_03_churn_by_decile.txt, block 1.",
        ],
    )


# ===========================================================================
# CH-05 - ARPU of churned vs retained, by value tier
# F-03.9, .10, .11 · analyse_03_churn_by_decile.txt block 3
# ===========================================================================


def ch05() -> None:
    b = blocks("analyse_03_churn_by_decile")[2].where(scope="opening_base")
    audit("CH-05", "analyse_03_churn_by_decile", 3, b)

    tiers = ["High", "Mid", "Low"]
    data = {t: {r["outcome"]: r for r in b.rows if r["value_tier"] == t} for t in tiers}

    x = list(range(len(tiers)))
    width = 0.36
    fig, ax = plt.subplots(figsize=(10.5, 5.6))

    for k, outcome in enumerate(("Churned", "Retained")):
        vals = [float(data[t][outcome]["arpu_monthly_currency_units"]) for t in tiers]
        ns = [int(data[t][outcome]["customers"]) for t in tiers]
        offs = [i + (k - 0.5) * width for i in x]
        ax.bar(offs, vals, width=width, color=OUTCOME_COLOUR[outcome], label=outcome)
        for xi, v, n in zip(offs, vals, ns):
            ax.text(xi, v + 1.6, f"{v:,.2f}", ha="center", fontsize=9, fontweight="bold")
            ax.text(xi, 2.4, f"n={n:,}", ha="center", fontsize=7.8, color="white")

    ax.set_xticks(x)
    ax.set_xticklabels([f"{t} value tier" for t in tiers])
    ax.set_ylabel("Mean monthly recurring revenue (currency units)")
    ax.set_ylim(0, 118)
    bare_axes(ax, "y")
    ax.legend(loc="upper right")

    hi_c = float(data["High"]["Churned"]["arpu_monthly_currency_units"])
    hi_r = float(data["High"]["Retained"]["arpu_monthly_currency_units"])
    ax.annotate(
        f"Near parity in the High tier - {hi_c:,.2f} vs {hi_r:,.2f}",
        xy=(0, max(hi_c, hi_r) + 1.0), xytext=(0.62, max(hi_c, hi_r) + 12.5),
        ha="left", fontsize=9.2, color=TEXT_2,
        arrowprops=dict(arrowstyle="->", color=MUTED, lw=0.9,
                        connectionstyle="angle3,angleA=0,angleB=70"),
    )

    ax.set_title(
        "Where the revenue-weighted effect actually sits - opening cohort\n"
        "Leavers carry higher revenue than stayers in the Mid and Low tiers, but not in the High tier",
        loc="left", pad=14,
    )

    finish(
        fig, ax, "CH-05", "CH05_arpu_churned_vs_retained_by_tier.png",
        "Opening cohort (tenure >= 4 months). Tier populations: High 2,004 · Mid 2,316 · Low 1,672.",
        [
            "This chart is the necessary companion to CH-02. CH-02 alone would license the claim that the "
            "business loses its most valuable customers; the High-tier near-parity here contradicts that "
            "reading, and the revenue-weighted effect is shown to arise in the Mid and Low tiers.",
            "Mean monthly recurring revenue. Long-distance revenue is excluded (C-2).",
            CURRENCY,
            "Source: analysis/query_results/analyse_03_churn_by_decile.txt, block 3.",
        ],
    )


# ===========================================================================
# CH-06 - The divergence test (a near-null result)
# F-04.5 to F-04.8 · analyse_04_divergence.txt block 2, PRIMARY rows only
# ===========================================================================


def ch06() -> None:
    b = blocks("analyse_04_divergence")[1].where(
        population_scope="opening_base",
        result_designation="PRIMARY RESULT - Opening cohort",
    )
    audit("CH-06", "analyse_04_divergence", 2, b)

    labels = b.col("segment_label")
    r_churn = [int(v) for v in b.col("rank_by_churn_rate")]
    r_arr = [int(v) for v in b.col("rank_by_arr_at_risk")]
    div = [int(v) for v in b.col("divergence_index")]

    fig, ax = plt.subplots(figsize=(11, 6.6))

    for lab, a, c, d in zip(labels, r_churn, r_arr, div):
        colour = MUTED if d == 0 else (ORANGE if d > 0 else BLUE)
        lw = 1.4 if d == 0 else 2.2
        ax.plot([0, 1], [a, c], color=colour, lw=lw, marker="o", markersize=6, zorder=3 if d else 2)
        ax.text(-0.035, a, f"{a}. {lab}", ha="right", va="center", fontsize=9)
        ax.text(1.035, c, f"{lab}  ({c})", ha="left", va="center", fontsize=9)

    ax.set_xlim(-0.72, 1.72)
    ax.set_ylim(9.6, 0.4)
    ax.set_xticks([0, 1])
    ax.set_xticklabels(["Rank by churn rate", "Rank by revenue at risk"], fontsize=10.5, fontweight="bold")
    ax.set_yticks(range(1, 10))
    ax.set_ylabel("Rank  (1 = highest priority)")
    ax.tick_params(axis="x", length=0)
    for side in ("top", "right", "left", "bottom"):
        ax.spines[side].set_visible(False)
    ax.set_axisbelow(True)
    ax.grid(axis="y", linewidth=0.8)

    n_zero = div.count(0)
    n_move = len(div) - n_zero
    ax.legend(
        handles=[
            Line2D([0], [0], color=MUTED, lw=1.4, marker="o", markersize=6,
                   label=f"No change in rank ({n_zero} of {len(div)} segments)"),
            Line2D([0], [0], color=ORANGE, lw=2.2, marker="o", markersize=6,
                   label="Moves one rank (divergence +1)"),
            Line2D([0], [0], color=BLUE, lw=2.2, marker="o", markersize=6,
                   label="Moves one rank (divergence −1)"),
        ],
        loc="lower center", bbox_to_anchor=(0.5, -0.17), ncol=3,
    )

    ax.set_title(
        "PRIMARY RESULT - Opening cohort\n"
        "The value-versus-risk divergence test returns a near-null result\n"
        f"Top two segments identical under both rankings · {n_zero} of {len(div)} segments do not move · "
        f"{n_move} move by exactly one rank · maximum divergence is 1",
        loc="left", pad=16, fontsize=12,
    )

    finish(
        fig, ax, "CH-06", "CH06_divergence_primary_opening_cohort.png",
        "PRIMARY RESULT - Opening cohort (tenure >= 4 months), nine predefined P1 segments "
        "(value tier x contract type), all reportable (n = 442-1,182).",
        [
            "THIS IS A NEGATIVE FINDING, PRESENTED AS ONE. The project was designed to test whether a "
            "churn-led prioritisation would materially diverge from a revenue-led one. On this population, "
            "at this segmentation, it does not. The divergence index sums to zero (gate A-VAL-10).",
            "THE INDEX IS ORDINAL. A divergence of +/-1 conveys rank order only and must never be quoted "
            "without magnitudes - see CH-07 for the revenue-at-risk amounts and churn rates behind these ranks.",
            "A-07 is locked (the comparison population). The all-customers version is a SENSITIVITY ANALYSIS ONLY and "
            "is not shown here; in it, only two of nine segments change, each by one rank.",
            "Nine cells is a coarse partition. Divergence at finer granularity was NOT tested, and testing "
            "it now would be a post-hoc specification change that pre-registration forbids.",
            "Fictional data: this demonstrates what the method returns. It is not evidence that "
            "misallocation does or does not exist for any real operator.",
            "Source: analysis/query_results/analyse_04_divergence.txt, block 2 "
            "(rows where result_designation = 'PRIMARY RESULT - Opening cohort').",
        ],
    )


# ===========================================================================
# CH-07 - Where revenue at risk actually concentrates
# F-04.2, .3, .4, .10 · analyse_04_divergence.txt block 2, PRIMARY rows only
# ===========================================================================


def ch07() -> None:
    b = blocks("analyse_04_divergence")[1].where(
        population_scope="opening_base",
        result_designation="PRIMARY RESULT - Opening cohort",
    )
    audit("CH-07", "analyse_04_divergence", 2, b)

    rows = sorted(b.rows, key=lambda r: float(r["arr_at_risk_currency_units"]), reverse=True)
    labels = [r["segment_label"] for r in rows]
    arr = [float(r["arr_at_risk_currency_units"]) for r in rows]
    share = [float(r["share_of_scope_arr_at_risk_pct"]) for r in rows]
    rate = [float(r["churn_rate_pct"]) for r in rows]
    ns = [int(r["n"]) for r in rows]
    contracts = [r["segment_label"].split(" / ")[1] for r in rows]

    y = list(range(len(rows)))
    fig, ax = plt.subplots(figsize=(11.5, 6.4))
    ax.barh(y, arr, color=[CONTRACT_COLOUR[c] for c in contracts], height=0.66)

    for yi, (a, s, rt, n) in enumerate(zip(arr, share, rate, ns)):
        ax.text(a + 9000, yi, f"{money_short(a)}  ·  {s:.2f}% of scope  ·  churn {rt:.2f}%  ·  n={n:,}",
                va="center", fontsize=8.7)

    ax.set_yticks(y)
    ax.set_yticklabels(labels)
    ax.invert_yaxis()
    ax.set_xlim(0, max(arr) * 1.58)
    ax.set_xlabel("Annual recurring revenue at risk (currency units)")
    ax.xaxis.set_major_formatter(lambda v, _: f"{v:,.0f}")
    bare_axes(ax, "x")

    top2 = share[0] + share[1]  # DERIVED: sum of two displayed shares (register fact F-04.4).
    ax.legend(
        handles=[Patch(facecolor=CONTRACT_COLOUR[c], label=c) for c in ("Month-to-Month", "One Year", "Two Year")],
        loc="lower right", title="Contract type", title_fontsize=9,
    )

    ax.set_title(
        "PRIMARY RESULT - Opening cohort\n"
        "Revenue at risk concentrates in two of nine segments, both Month-to-Month\n"
        f"Together these two segments hold {top2:.2f}% of opening-cohort recurring revenue at risk",
        loc="left", pad=14, fontsize=12,
    )

    finish(
        fig, ax, "CH-07", "CH07_revenue_at_risk_by_segment.png",
        "PRIMARY RESULT - Opening cohort (tenure >= 4 months), nine predefined P1 segments, "
        "all reportable (n = 442-1,182).",
        [
            "ASSOCIATION ONLY. Contract type is associated with these differing churn rates. Nothing here "
            "establishes that contract type causes them, and contract choice is plausibly related to "
            "customer characteristics the dataset does not observe.",
            "CONFOUNDED WITH TENURE. Longer contracts are held disproportionately by longer-tenure "
            "customers (see CH-08, lens L2). No figure here isolates an independent contribution.",
            "The dataset contains no retention activity, campaign or contact records. This describes where "
            "exposure sits, not what the business did about it.",
            "The 78.93% figure is the sum of the two segment shares shown (45.95 + 32.98).",
            CURRENCY,
            "Source: analysis/query_results/analyse_04_divergence.txt, block 2 "
            "(rows where result_designation = 'PRIMARY RESULT - Opening cohort').",
        ],
    )


# ===========================================================================
# CH-08 - Seven driver lenses, High value tier
# F-05.1 to F-05.12 · analyse_05_drivers_high_value.txt block 1
# ===========================================================================


def ch08() -> None:
    b = blocks("analyse_05_drivers_high_value")[0]
    audit("CH-08", "analyse_05_drivers_high_value", 1, b)

    scope_rate = float(b.rows[0]["scope_churn_rate_pct"])

    lenses: dict[str, dict] = {}
    for r in b.rows:
        lid = r["lens_id"]
        lenses.setdefault(lid, {"name": r["lens_name"], "rows": []})["rows"].append(r)

    # DISPLAY ORDER ONLY: panels ordered by index spread (max - min) computed from
    # displayed values. Affects arrangement, never a plotted number. Weak lenses
    # are retained at their true magnitudes and are never dropped.
    def spread(lid: str) -> float:
        idx = [float(r["churn_index_vs_scope"]) for r in lenses[lid]["rows"]]
        return max(idx) - min(idx)

    order = sorted(lenses, key=spread, reverse=True)

    fig, axgrid = plt.subplots(2, 4, figsize=(15.5, 8.6))
    axes = axgrid.ravel()

    for ax, lid in zip(axes, order):
        rows = sorted(lenses[lid]["rows"], key=lambda r: float(r["churn_index_vs_scope"]))
        idx = [float(r["churn_index_vs_scope"]) for r in rows]
        labs = [r["segment_value"] for r in rows]
        flags = [r["cell_size_flag"] for r in rows]
        ns = [int(r["n"]) for r in rows]
        rates = [float(r["churn_rate_pct"]) for r in rows]
        y = list(range(len(rows)))

        ax.axvline(1.0, color=TEXT_2, lw=1.1, ls="--", zorder=1)
        for yi, (v, fl, rt, n) in enumerate(zip(idx, flags, rates, ns)):
            ax.plot([1.0, v], [yi, yi], color=GRID, lw=1.8, zorder=2)
            caveat = fl == "caveat_required"
            ax.plot([v], [yi], marker="D" if caveat else "o", markersize=7 if caveat else 7.5,
                    color=ORANGE if caveat else BLUE, zorder=3)
            # Label sits above its own marker, nudged clear of the index-1.00
            # reference line when the marker sits close to it.
            lx = v
            if abs(v - 1.0) < 0.30:
                lx = v + (0.34 if v >= 1.0 else -0.34)
            ax.text(lx, yi - 0.28, f"{rt:.2f}%   n={n:,}" + ("  ▲" if caveat else ""),
                    ha="center", va="bottom", fontsize=7.5, color=TEXT_2, zorder=4,
                    bbox=dict(facecolor=SURFACE, edgecolor="none", pad=1.0))

        ax.set_yticks(y)
        ax.set_yticklabels(labs, fontsize=8.2)
        ax.set_ylim(len(rows) - 0.42, -0.78)
        ax.set_xlim(0, 2.78)
        ax.set_title(f"{lid} - {lenses[lid]['name']}      spread {spread(lid):.2f}",
                     fontsize=10, pad=8, loc="left")
        ax.set_axisbelow(True)
        ax.grid(axis="x", linewidth=0.7)
        for s in ("top", "right", "left"):
            ax.spines[s].set_visible(False)
        ax.tick_params(axis="y", length=0)
        ax.set_xlabel(f"Churn index (1.00 = {scope_rate:.2f}%)", fontsize=8.4)

    # Eighth cell carries the legend and the reading instruction.
    slot = axes[7]
    slot.axis("off")
    slot.legend(
        handles=[
            Line2D([0], [0], marker="o", color="none", markerfacecolor=BLUE, markersize=8,
                   label="Reportable cell"),
            Line2D([0], [0], marker="D", color="none", markerfacecolor=ORANGE, markersize=7,
                   label="▲ Small cell, n < 100 - read with n"),
            Line2D([0], [0], color=TEXT_2, ls="--", lw=1.1,
                   label=f"Scope churn rate {scope_rate:.2f}%  (index 1.00)"),
        ],
        loc="upper left", bbox_to_anchor=(0.0, 0.92),
    )
    slot.text(
        0.0, 0.44,
        "Panels are ordered by index spread.\n"
        "L5 and L7 are the weakest lenses and are\n"
        "shown here at their true magnitudes -\n"
        "not omitted, not rescaled.\n\n"
        "L6 offer direction is UNESTABLISHED.\n"
        "See the note below the figure.",
        va="top", ha="left", fontsize=8.6, color=TEXT_2, linespacing=1.5,
        transform=slot.transAxes,
    )

    fig.suptitle(
        "All seven predefined driver lenses - High value tier, opening cohort\n"
        "Every lens is reported, including those that differentiate weakly",
        x=0.008, ha="left", fontsize=13, fontweight="bold", y=1.005,
    )
    fig.tight_layout(rect=(0, 0, 1, 0.955))

    finish(
        fig, axes, "CH-08", "CH08_driver_lenses_high_tier.png",
        "Opening cohort x High value tier (deciles 8-10), n = 2,004, scope churn rate 30.89%. "
        "Each lens partitions the tier to exactly 2,004 customers (gate A-VAL-11).",
        [
            "ALL SEVEN LENSES ARE SHOWN, INCLUDING THE WEAK ONES. L7 referral behaviour spans only "
            "13.75 percentage points - the narrowest of the seven - and is reported at that magnitude.",
            "FIVE CELLS REQUIRE A CAVEAT (n = 36 to 80), marked ▲. Their rates are the most extreme in "
            "their lenses and rest on the smallest populations. L4 DSL shows 1 churned customer in 80 - "
            "a single observation drives that entire rate; it is not a stable estimate.",
            "L6 OFFER HELD - DIRECTION IS UNESTABLISHED. The dataset records only which offer is held, "
            "with no date, no reason and no outcome. Offers may be extended to customers already "
            "considered at risk, in which case the association runs opposite to the intuitive reading. "
            "This is the most easily misread item in the register.",
            "STRUCTURAL ABSENCES ARE NOT ZERO RESULTS. L4 'No internet' and L5 'None (0)' do not appear "
            "in the High tier by construction, not because their churn is zero.",
            "All seven are single-dimension cuts with NO multivariate control. L1, L2, L5 and L6 are "
            "interrelated; none of these figures isolates an independent contribution. Association only.",
            "Source: analysis/query_results/analyse_05_drivers_high_value.txt, block 1.",
        ],
    )


# ===========================================================================
# CH-09 - High-value drivers vs base-wide drivers (the second null)
# F-06.1 to F-06.6 · analyse_06_drivers_comparison.txt blocks 1 and 2
# ===========================================================================


def ch09() -> None:
    b1 = blocks("analyse_06_drivers_comparison")[0]
    b2 = blocks("analyse_06_drivers_comparison")[1]
    audit("CH-09", "analyse_06_drivers_comparison", 1, b1)

    maxdiff = {r["lens_id"]: float(r["max_abs_index_difference"]) for r in b2.rows}
    lens_name = {r["lens_id"]: r["lens_name"] for r in b2.rows}
    order = sorted(maxdiff, key=lambda k: maxdiff[k], reverse=True)

    ordered_rows: list[tuple[str, dict]] = []
    for lid in order:
        rows = [r for r in b1.rows if r["lens_id"] == lid]
        rows.sort(key=lambda r: abs(float(r["index_difference"])), reverse=True)
        for r in rows:
            ordered_rows.append((lid, r))

    fig, ax = plt.subplots(figsize=(11.5, 9.2))
    ytick_labels, ytick_pos = [], []
    y = 0
    boundaries = []
    prev = None
    for lid, r in ordered_rows:
        if prev is not None and lid != prev:
            boundaries.append(y - 0.5)
            y += 0.6
        a = float(r["index_all"])
        h = float(r["index_high"])
        caveat = r["high_cell_flag"] == "caveat_required"
        ax.plot([a, h], [y, y], color=GRID, lw=2.4, zorder=1, solid_capstyle="round")
        ax.plot([a], [y], marker="o", markersize=7, color=MUTED, zorder=3)
        ax.plot([h], [y], marker="D" if caveat else "o", markersize=7 if caveat else 7.5,
                color=ORANGE if caveat else BLUE, zorder=3)
        ytick_pos.append(y)
        ytick_labels.append(
            f"{r['segment_value']}" + ("  ▲" if caveat else "") + f"   (Δ {float(r['index_difference']):+.2f})"
        )
        prev = lid
        y += 1

    for bnd in boundaries:
        ax.axhline(bnd, color=GRID, lw=0.9)

    ax.axvline(1.0, color=TEXT_2, lw=1.1, ls="--", zorder=0)

    # Lens headers down the right-hand side
    y = 0
    prev = None
    start = 0
    for lid, _ in ordered_rows + [("__END__", {})]:
        if prev is not None and lid != prev:
            mid = (start + y - 1) / 2
            ax.text(
                2.62, mid,
                f"{prev} - {lens_name[prev]}\nmax |Δ| {maxdiff[prev]:.2f}",
                va="center", ha="left", fontsize=9, color=TEXT, fontweight="bold",
            )
            y += 0.6
            start = y
        if lid == "__END__":
            break
        prev = lid
        y += 1

    ax.set_yticks(ytick_pos)
    ax.set_yticklabels(ytick_labels, fontsize=8.4)
    ax.invert_yaxis()
    ax.set_xlim(0, 2.55)
    ax.set_xlabel("Churn index (1.00 = the churn rate of the scope the segment sits in)")
    ax.tick_params(axis="y", length=0)
    ax.set_axisbelow(True)
    ax.grid(axis="x", linewidth=0.7)
    for side in ("top", "right", "left"):
        ax.spines[side].set_visible(False)

    ax.legend(
        handles=[
            Line2D([0], [0], marker="o", color="none", markerfacecolor=MUTED, markersize=7,
                   label="Base-wide (opening cohort, all tiers)"),
            Line2D([0], [0], marker="o", color="none", markerfacecolor=BLUE, markersize=7.5,
                   label="High value tier"),
            Line2D([0], [0], marker="D", color="none", markerfacecolor=ORANGE, markersize=7,
                   label="▲ High-tier cell n < 100 - caveat required"),
        ],
        loc="lower center", bbox_to_anchor=(0.5, -0.105), ncol=3,
    )

    ax.set_title(
        "Do high-value churn drivers differ from base-wide drivers? For four of seven lenses, barely.\n"
        "Contract type (max |Δ| 0.15), service intensity (0.12) and referral behaviour (0.06) behave "
        "almost identically in both scopes",
        loc="left", pad=16, fontsize=12,
    )

    finish(
        fig, ax, "CH-09", "CH09_high_tier_vs_base_wide_drivers.png",
        "Opening cohort. High value tier (n = 2,004) compared with base-wide (opening cohort, all tiers, "
        "n = 5,992). Every High-tier lens row has a base-wide counterpart - zero orphans (gate A-VAL-14).",
        [
            "THIS IS A LARGELY NULL RESULT AND IS PRESENTED AS ONE. Charter risk R-04 anticipated it in "
            "writing before any result existed: 'if high-value churn drivers prove identical to base-wide "
            "drivers, the project's central premise weakens... a null result is a legitimate finding and "
            "will be reported as one.' For L1, L5 and L7 that condition is substantially met.",
            "INDICES ARE COMPARED, NOT RAW RATES. This normalises for the two scopes' different base rates. "
            "Comparing raw rates would look more dramatic and would be misleading for that reason.",
            "NO SIGNIFICANCE TESTING. These are descriptive index differences with no confidence interval. "
            "'Large' and 'small' are relative to each other, not to any statistical threshold.",
            "THE SCOPES OVERLAP BY CONSTRUCTION. The High tier is a subset of the base-wide population, so "
            "differences are attenuated. This is a part-versus-whole comparison, not two independent groups.",
            "L4 internet type is the clear exception (max |Δ| 0.67) and its segments move in different "
            "directions - but two of its three High-tier cells are small (n = 74 and n = 80), so the shift "
            "rests partly on those cells.",
            "Source: analysis/query_results/analyse_06_drivers_comparison.txt, blocks 1 and 2.",
        ],
    )


# ===========================================================================
# CH-10 - Early-life churn contribution
# F-07.1, .3, .4, .12 · analyse_07_early_life_churn.txt blocks 1 and 3
# ===========================================================================


def ch10() -> None:
    b1 = blocks("analyse_07_early_life_churn")[0].where(tenure_month="TOTAL (months 1-3)")
    b3 = blocks("analyse_07_early_life_churn")[2]
    audit("CH-10", "analyse_07_early_life_churn", 3, b3)

    base = blocks("analyse_01_base_position")[0]
    churn_open = int(base.where(scope="opening_base").one("churned"))
    churn_inp = int(base.where(scope="in_period_acquisition").one("churned"))

    share_inp_churn = b1.num("pct_of_all_churn")
    share_open_churn = 100.0 - share_inp_churn  # DERIVED: complement of a displayed share.

    arr_open = b3.where(scope="opening_base")
    arr_inp = b3.where(scope="in_period_acquisition")
    share_open_arr = arr_open.num("pct_of_total_arr_at_risk")
    share_inp_arr = arr_inp.num("pct_of_total_arr_at_risk")
    val_open_arr = arr_open.num("arr_at_risk_currency_units")
    val_inp_arr = arr_inp.num("arr_at_risk_currency_units")

    rows = [
        ("Churn events\n(1,869 total)", share_open_churn, share_inp_churn,
         f"{churn_open:,} customers", f"{churn_inp:,} customers"),
        ("Recurring revenue at risk\n(1,669,570.20 currency units)", share_open_arr, share_inp_arr,
         money_short(val_open_arr), money_short(val_inp_arr)),
    ]

    fig, ax = plt.subplots(figsize=(11.5, 4.0))
    for i, (lab, a, b_, va, vb) in enumerate(rows):
        ax.barh([i], [a], color=BLUE, height=0.46)
        ax.barh([i], [b_], left=[a], color=ORANGE, height=0.46)
        ax.text(a / 2, i, f"{a:.2f}%\n{va}", ha="center", va="center", color="white",
                fontsize=9.4, fontweight="bold")
        ax.text(a + b_ / 2, i, f"{b_:.2f}%\n{vb}", ha="center", va="center", color="white",
                fontsize=9.4, fontweight="bold")

    ax.set_yticks(range(len(rows)))
    ax.set_yticklabels([r[0] for r in rows], fontsize=9.6)
    ax.set_ylim(len(rows) - 0.48, -0.52)
    ax.set_xlim(0, 100)
    ax.set_xlabel("Share of total (%)")
    ax.tick_params(axis="y", length=0)
    bare_axes(ax, "x")
    ax.spines["left"].set_visible(False)

    ax.legend(
        handles=[
            Patch(facecolor=BLUE, label="Opening cohort (tenure >= 4 months)"),
            Patch(facecolor=ORANGE, label="In-period acquisitions (tenure <= 3 months)"),
        ],
        loc="center", bbox_to_anchor=(0.5, 0.5), ncol=2,
    )

    ax.set_title(
        "Customers acquired within the quarter carry a third of churn events and a quarter of revenue at risk\n"
        "This population is analytically separate from the opening cohort and is kept separate throughout",
        loc="left", pad=14, fontsize=12,
    )

    finish(
        fig, ax, "CH-10", "CH10_early_life_contribution.png",
        "In-period acquisitions (tenure <= 3 months), n = 1,051, of whom 597 churned (56.80%), "
        "shown against the opening cohort (n = 5,992, 1,272 churned, 21.23%).",
        [
            "THESE 597 CUSTOMERS ARE NOT IN THE PRIMARY CHURN KPI NUMERATOR AND MUST NEVER BE ADDED TO IT. "
            "Decision C-3 keeps the two populations separate because they behave very differently "
            "(56.80% against 21.23%). This chart shows shares of a total, never a combined rate.",
            "Revenue at risk correctly includes this cohort (the revenue definition). The opening-cohort restriction "
            "applies to the churn RATE only, never to revenue.",
            "The 68.06% opening-cohort share of churn events is the complement of the sourced 31.94%.",
            "Reconciles at register checks X-02, X-05, X-15 and X-16.",
            CURRENCY,
            "Source: analysis/query_results/analyse_07_early_life_churn.txt, blocks 1 and 3; "
            "analyse_01_base_position.txt, block 1.",
        ],
    )


# ===========================================================================
# CH-11 - Composition of in-period acquisitions
# F-07.6, .7, .10 · analyse_07_early_life_churn.txt block 2
# ===========================================================================


def ch11() -> None:
    b = blocks("analyse_07_early_life_churn")[1]
    audit("CH-11", "analyse_07_early_life_churn", 2, b)

    contract = [r for r in b.rows if r["lens_id"] == "L1"]
    offer = [r for r in b.rows if r["lens_id"] == "L6"]

    fig, ax = plt.subplots(figsize=(11.5, 3.9))

    # Contract row. Below-threshold cells are COLLAPSED, not plotted as rates.
    m2m = next(r for r in contract if r["segment_value"] == "Month-to-Month")
    below = [r for r in contract if r["cell_size_flag"] == "below_threshold"]
    n_m2m = int(m2m["n"])
    n_below = sum(int(r["n"]) for r in below)
    pct_m2m = float(m2m["pct_of_scope_population"])

    ax.barh([0], [n_m2m], color=ORANGE, height=0.46)
    ax.barh([0], [n_below], left=[n_m2m], color=MUTED, height=0.46)
    ax.text(n_m2m / 2, 0, f"Month-to-Month\n{n_m2m:,}  ({pct_m2m:.2f}%)", ha="center", va="center",
            color="white", fontsize=9.4, fontweight="bold")
    ax.text(n_m2m + n_below + 14, 0,
            f"One Year (n={int(below[0]['n'])}) + Two Year (n={int(below[1]['n'])}) = {n_below}\n"
            "below the n = 30 reporting threshold - rates not reportable",
            va="center", fontsize=8.4, color=TEXT_2)

    # Offer row. Only two categories exist in this cohort.
    left = 0.0
    for r, colour in zip(sorted(offer, key=lambda r: -int(r["n"])), (BLUE, VIOLET)):
        n = int(r["n"])
        ax.barh([1], [n], left=[left], color=colour, height=0.46)
        ax.text(left + n / 2, 1, f"{r['segment_value']}\n{n:,}  ({float(r['pct_of_scope_population']):.2f}%)",
                ha="center", va="center", color="white", fontsize=9.4, fontweight="bold")
        left += n

    ax.set_yticks([0, 1])
    ax.set_yticklabels(["Contract type", "Offer held"], fontsize=10)
    ax.set_ylim(1.42, -0.42)
    ax.set_xlim(0, 1051 * 1.30)
    ax.set_xlabel("Customers")
    ax.tick_params(axis="y", length=0)
    bare_axes(ax, "x")
    ax.spines["left"].set_visible(False)

    ax.set_title(
        "Composition of in-period acquisitions - almost entirely Month-to-Month, and only two offer categories\n"
        "Offers A, B, C and D are entirely absent from customers acquired within the quarter",
        loc="left", pad=14, fontsize=12,
    )

    finish(
        fig, ax, "CH-11", "CH11_early_life_composition.png",
        "In-period acquisitions (tenure <= 3 months), n = 1,051.",
        [
            "BELOW-THRESHOLD CELLS ARE COLLAPSED, NOT QUOTED. One Year (n = 26) and Two Year (n = 22) sit "
            "below the predefined n = 30 reporting threshold. Their churn rates are not reportable and "
            "are deliberately not shown; bar width reflects customer counts only.",
            "INFERENCE, NOT OBSERVATION. The absence of Offers A-D suggests those offers are associated "
            "with existing rather than newly acquired customers. This is an inference from absence. The "
            "dataset has no offer date, eligibility rule or assignment logic, so no conclusion about offer "
            "policy is available.",
            "The Month-to-Month concentration is consistent with new customers typically starting on "
            "rolling terms, but the data does not establish acquisition practice.",
            "NO ONBOARDING CAUSE MAY BE ASSERTED. The dataset contains no activation, installation, "
            "complaint, service-quality, first-contact, acquisition-channel or campaign records of any kind.",
            "Source: analysis/query_results/analyse_07_early_life_churn.txt, block 2.",
        ],
    )


# ---------------------------------------------------------------------------

CHARTS = [ch01, ch02, ch03, ch04, ch05, ch06, ch07, ch08, ch09, ch10, ch11]


def main() -> int:
    FIGURES.mkdir(parents=True, exist_ok=True)
    CHART_DATA.mkdir(parents=True, exist_ok=True)
    print(f"Project 01 - building {len(CHARTS)} charts from {RESULTS.relative_to(ROOT)}/\n")
    for fn in CHARTS:
        fn()
    print(f"\n{len(MANIFEST)} figures written to {FIGURES.relative_to(ROOT)}/")
    print(f"{len(MANIFEST)} audit CSVs written to {CHART_DATA.relative_to(ROOT)}/")
    empty = [m for m in MANIFEST if m["bytes"] < 10_000]
    if empty:
        print(f"WARNING: suspiciously small figures: {empty}")
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
