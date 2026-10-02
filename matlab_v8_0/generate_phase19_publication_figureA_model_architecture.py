#!/usr/bin/env python3
"""Generate publication Figure A: final model architecture.

This is a paper-facing summary figure, not a phase-history figure. It reads
the frozen Phase 6/19F/19G ledgers and emits PNG/PDF outputs plus a compact
source manifest.
"""

from __future__ import annotations

import csv
from pathlib import Path
from textwrap import fill

import matplotlib.pyplot as plt
from matplotlib import patches
import numpy as np


ROOT = Path(__file__).resolve().parent
OUT = ROOT / "outputs" / "v8_0_phase5_transfer_plan"

PHASE6 = OUT / "phase6_six_device_evidence_matrix.csv"
DEVICE_INTERP = OUT / "phase19FS_device_interpretation.csv"
FINAL_FREEZE = OUT / "phase19GS_final_multiscale_model_freeze.csv"
POLICY = OUT / "phase19FS_frozen_policy_manifest.csv"
FIGURE_MANIFEST = OUT / "phase19_publication_figure_manifest.csv"

FIG_BASE = OUT / "phase19_publication_figureA_model_architecture"
PNG = FIG_BASE.with_suffix(".png")
PDF = FIG_BASE.with_suffix(".pdf")
MANIFEST = OUT / "phase19_publication_figureA_model_architecture_manifest.csv"


STATUS_COLORS = {
    "mechanistically_unresolved": "#d8d8d8",
    "M0star_sufficient": "#9ecae1",
    "structured_supported": "#fdae6b",
}

STATUS_LABELS = {
    "mechanistically_unresolved": "unresolved",
    "M0star_sufficient": "M0* sufficient",
    "structured_supported": "structured support",
}


def read_rows(path: Path) -> list[dict[str, str]]:
    with path.open(newline="") as f:
        return list(csv.DictReader(f))


def read_item_table(path: Path) -> dict[str, str]:
    rows = read_rows(path)
    return {r["item"]: r["value"] for r in rows if "item" in r and "value" in r}


def short_geometry(text: str) -> str:
    mapping = {
        "control_or_weakly_structured": "control / weak",
        "threshold_half_encapsulated": "threshold half-cover",
        "fully_encapsulated_control": "full-cover control",
        "intermediate_half_coverage": "intermediate half-cover",
        "crack_associated": "crack / discontinuity",
        "strong_structured_AS006": "half-cover boundary",
    }
    return mapping.get(text, text.replace("_", " "))


def update_figure_manifest() -> None:
    if not FIGURE_MANIFEST.exists():
        return
    rows = read_rows(FIGURE_MANIFEST)
    fields = rows[0].keys()
    for row in rows:
        if row.get("figure_id") == "Figure A":
            row["status"] = "available"
            row["source_artifacts"] = (
                "phase19_publication_figureA_model_architecture.png; "
                "phase6_six_device_evidence_matrix.csv; "
                "phase19FS_frozen_policy_manifest.csv; "
                "phase19GS_final_multiscale_model_freeze.csv; "
                "phase19FS_device_interpretation.csv"
            )
    with FIGURE_MANIFEST.open("w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fields)
        writer.writeheader()
        writer.writerows(rows)


def draw_panel_label(ax, label: str) -> None:
    ax.text(
        0.0,
        1.03,
        label,
        transform=ax.transAxes,
        fontsize=13,
        fontweight="bold",
        ha="left",
        va="bottom",
    )


def add_round_box(ax, xy, width, height, text, fc, ec="#333333", lw=1.2, fs=9):
    box = patches.FancyBboxPatch(
        xy,
        width,
        height,
        boxstyle="round,pad=0.02,rounding_size=0.025",
        facecolor=fc,
        edgecolor=ec,
        linewidth=lw,
    )
    ax.add_patch(box)
    ax.text(
        xy[0] + width / 2,
        xy[1] + height / 2,
        text,
        ha="center",
        va="center",
        fontsize=fs,
        color="#111111",
        wrap=True,
    )
    return box


def draw_device_hierarchy(ax, phase6, interp) -> None:
    ax.set_axis_off()
    draw_panel_label(ax, "a")
    ax.text(
        0.02,
        0.96,
        "Six-device hierarchy",
        fontsize=12,
        fontweight="bold",
        ha="left",
        va="top",
    )
    ax.text(
        0.02,
        0.90,
        "Nominal film force alone does not organize the transport outcomes.",
        fontsize=8.5,
        ha="left",
        va="top",
        color="#333333",
    )

    interp_by_device = {r["device"]: r for r in interp}
    x0, y0 = 0.04, 0.75
    w, h = 0.28, 0.19
    dx, dy = 0.32, 0.245
    for i, row in enumerate(phase6):
        col = i % 3
        rr = i // 3
        x = x0 + col * dx
        y = y0 - rr * dy
        dev = row["device"]
        status = row["final_model_status"]
        is_anchor = dev in {"AS005", "AS006"}
        color = STATUS_COLORS.get(status, "#eeeeee")
        edge = "#111111" if is_anchor else "#777777"
        lw = 2.0 if is_anchor else 1.0
        box = patches.FancyBboxPatch(
            (x, y),
            w,
            h,
            boxstyle="round,pad=0.018,rounding_size=0.02",
            facecolor=color,
            edgecolor=edge,
            linewidth=lw,
        )
        ax.add_patch(box)
        ax.text(x + 0.015, y + h - 0.035, dev, fontsize=11, fontweight="bold")
        ax.text(
            x + 0.015,
            y + h - 0.075,
            short_geometry(row["geometry_class"]),
            fontsize=7.6,
            color="#333333",
        )
        ax.text(
            x + 0.015,
            y + 0.065,
            STATUS_LABELS.get(status, status),
            fontsize=8.2,
            fontweight="bold" if is_anchor else "normal",
        )
        role = interp_by_device.get(dev, {}).get("critical_device_support", "0")
        if role == "1":
            ax.text(
                x + w - 0.012,
                y + 0.018,
                "anchor",
                fontsize=7.4,
                color="#5a2d00",
                ha="right",
                fontweight="bold",
            )

    legend_y = 0.08
    legend = [
        ("unresolved", STATUS_COLORS["mechanistically_unresolved"]),
        ("M0* sufficient", STATUS_COLORS["M0star_sufficient"]),
        ("structured support", STATUS_COLORS["structured_supported"]),
    ]
    for j, (lab, col) in enumerate(legend):
        x = 0.04 + j * 0.29
        ax.add_patch(patches.Rectangle((x, legend_y), 0.035, 0.035, fc=col, ec="#666666"))
        ax.text(x + 0.045, legend_y + 0.017, lab, fontsize=7.6, va="center")


def draw_architecture(ax, final_freeze) -> None:
    ax.set_axis_off()
    draw_panel_label(ax, "b")
    ax.text(
        0.02,
        0.96,
        "Frozen multiscale architecture",
        fontsize=12,
        fontweight="bold",
        ha="left",
        va="top",
    )

    boxes = [
        ("device\ngeometry", "#f2f0f7"),
        ("normalized\nmechanical\nlocalization\n$H_{grad}(x,y)$", "#dadaeb"),
        ("local\n$T_c(x,y)$\nsecondary", "#c7e9c0"),
        ("weak-link\nconnectivity\n$W_{ij}$\ndominant", "#fdd0a2"),
        ("current\nredistribution", "#bcbddc"),
        ("four-probe\ntransport", "#9ecae1"),
    ]
    xs = [0.04, 0.20, 0.39, 0.55, 0.72, 0.87]
    widths = [0.11, 0.14, 0.10, 0.12, 0.11, 0.10]
    y, h = 0.50, 0.25
    for i, ((text, color), x, width) in enumerate(zip(boxes, xs, widths)):
        add_round_box(ax, (x, y), width, h, text, color, fs=8.3)
        if i < len(boxes) - 1:
            ax.annotate(
                "",
                xy=(xs[i + 1] - 0.012, y + h / 2),
                xytext=(x + width + 0.01, y + h / 2),
                arrowprops=dict(arrowstyle="->", lw=1.5, color="#333333"),
            )

    role = final_freeze.get("dominant_supported_role", "weak_link_connectivity_dominant")
    assoc = final_freeze.get("mechanics_transport_spatial_association", "robust")
    ax.text(
        0.05,
        0.35,
        "Final frozen result: "
        + role.replace("_", " ")
        + "; spatial association = "
        + assoc,
        fontsize=9.0,
        ha="left",
        va="center",
        fontweight="bold",
    )
    ax.text(
        0.05,
        0.23,
        "Tested arrows: mechanics prior survives controls; weak-link role dominates; robustness passes.",
        fontsize=8.5,
        ha="left",
        color="#333333",
    )


def draw_network_cartoon(ax) -> None:
    ax.set_axis_off()
    draw_panel_label(ax, "c")
    ax.text(
        0.02,
        0.96,
        "Separated network fields",
        fontsize=12,
        fontweight="bold",
        ha="left",
        va="top",
    )
    ax.text(
        0.02,
        0.90,
        "Local superconducting strength and weak-link transparency are distinct.",
        fontsize=8.5,
        color="#333333",
        ha="left",
        va="top",
    )

    # Left mini-field: Tc-like local landscape.
    x = np.linspace(-1, 1, 80)
    y = np.linspace(-1, 1, 55)
    X, Y = np.meshgrid(x, y)
    Z = 0.65 + 0.22 * np.exp(-((X + 0.35) ** 2 / 0.18 + Y**2 / 0.5))
    Z += 0.15 * np.exp(-((X - 0.45) ** 2 / 0.10 + (Y + 0.20) ** 2 / 0.25))
    ax.imshow(Z, extent=(0.05, 0.43, 0.18, 0.70), origin="lower", cmap="YlGn")
    ax.add_patch(patches.Rectangle((0.05, 0.18), 0.38, 0.52, fill=False, ec="#333333", lw=1.0))
    ax.text(0.24, 0.13, "$T_c(x,y)$ proxy", ha="center", fontsize=8.3)

    # Right mini-network: W_ij connectivity.
    x0, y0 = 0.58, 0.22
    nx, ny = 5, 4
    dx, dy = 0.075, 0.105
    pts = []
    for iy in range(ny):
        for ix in range(nx):
            pts.append((x0 + ix * dx, y0 + iy * dy))
    for iy in range(ny):
        for ix in range(nx):
            xpt, ypt = x0 + ix * dx, y0 + iy * dy
            if ix < nx - 1:
                strength = 2.8 if (iy in [1, 2] and ix in [1, 2]) else 0.9
                color = "#d95f0e" if strength > 1 else "#969696"
                ax.plot([xpt, xpt + dx], [ypt, ypt], lw=strength, color=color, solid_capstyle="round")
            if iy < ny - 1:
                strength = 2.2 if (ix == 2 and iy in [0, 1, 2]) else 0.8
                color = "#d95f0e" if strength > 1 else "#bdbdbd"
                ax.plot([xpt, xpt], [ypt, ypt + dy], lw=strength, color=color, solid_capstyle="round")
    for xpt, ypt in pts:
        ax.plot(xpt, ypt, "o", ms=4.5, mfc="#ffffff", mec="#333333", mew=0.9)
    ax.text(0.73, 0.13, "$W_{ij}$ weak-link field", ha="center", fontsize=8.3)
    ax.annotate(
        "current paths",
        xy=(0.75, 0.43),
        xytext=(0.87, 0.66),
        arrowprops=dict(arrowstyle="->", color="#d95f0e", lw=1.2),
        fontsize=8,
        color="#7f2704",
        ha="center",
    )


def draw_scope_box(ax, policy, final_freeze) -> None:
    ax.set_axis_off()
    draw_panel_label(ax, "d")
    ax.text(0.02, 0.96, "Frozen scope and claim boundary", fontsize=12, fontweight="bold", va="top")

    supported = [
        "mechanics-informed model: " + final_freeze.get("mechanics_informed_transport_model", "supported"),
        "dominant role: " + final_freeze.get("dominant_supported_role", "weak_link_connectivity_dominant").replace("_", " "),
        "local Tc role: " + final_freeze.get("local_Tc_role", "supporting_not_standalone").replace("_", " "),
        "model status: " + final_freeze.get("model_development_status", "complete"),
    ]
    not_claimed = [
        "no absolute strain reconstruction",
        "no tensor inversion",
        "no retuning / relabeling",
        "no microscopic pairing-mechanism proof",
    ]

    add_round_box(ax, (0.05, 0.48), 0.40, 0.32, "Supported\n" + "\n".join(supported), "#e5f5e0", fs=8.5)
    add_round_box(ax, (0.55, 0.48), 0.40, 0.32, "Not claimed\n" + "\n".join(not_claimed), "#fee0d2", fs=8.5)
    ax.text(
        0.05,
        0.32,
        fill(
            "Manuscript phrasing: normalized mechanical-gradient structure is transport relevant, primarily through weak-link connectivity.",
            width=72,
        ),
        fontsize=9.2,
        fontweight="bold",
        ha="left",
        va="top",
    )
    ax.text(
        0.05,
        0.16,
        fill(
            "Caveat: this is a normalized forward-mechanics result, not an absolute device-specific strain reconstruction.",
            width=76,
        ),
        fontsize=8.7,
        color="#333333",
        ha="left",
        va="top",
    )


def write_manifest() -> None:
    rows = [
        ("figure_id", "Figure A"),
        ("output_png", str(PNG)),
        ("output_pdf", str(PDF)),
        ("source_phase6", str(PHASE6)),
        ("source_device_interpretation", str(DEVICE_INTERP)),
        ("source_final_freeze", str(FINAL_FREEZE)),
        ("source_policy", str(POLICY)),
        ("claim_scope", "paper_facing_architecture_no_phase_history"),
        ("absolute_strain_claims", "not_claimed"),
    ]
    with MANIFEST.open("w", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(["item", "value"])
        writer.writerows(rows)


def main() -> None:
    phase6 = read_rows(PHASE6)
    interp = read_rows(DEVICE_INTERP)
    final_freeze = read_item_table(FINAL_FREEZE)
    policy = read_item_table(POLICY)

    fig = plt.figure(figsize=(13.5, 8.2), dpi=200)
    gs = fig.add_gridspec(2, 2, left=0.045, right=0.985, top=0.92, bottom=0.07, wspace=0.12, hspace=0.19)
    fig.suptitle(
        "Figure A. Final mechanics-informed superconducting-network architecture",
        fontsize=15,
        fontweight="bold",
        x=0.045,
        ha="left",
    )

    draw_device_hierarchy(fig.add_subplot(gs[0, 0]), phase6, interp)
    draw_architecture(fig.add_subplot(gs[0, 1]), final_freeze)
    draw_network_cartoon(fig.add_subplot(gs[1, 0]))
    draw_scope_box(fig.add_subplot(gs[1, 1]), policy, final_freeze)

    fig.savefig(PNG, dpi=300)
    fig.savefig(PDF)
    plt.close(fig)
    write_manifest()
    update_figure_manifest()
    print(f"Wrote {PNG}")
    print(f"Wrote {PDF}")
    print(f"Wrote {MANIFEST}")


if __name__ == "__main__":
    main()
