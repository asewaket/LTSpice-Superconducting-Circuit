#!/usr/bin/env python3
"""Analyze the three LTspice 2D model stages and create publication figures."""

from __future__ import annotations

import argparse
import csv
import os
from pathlib import Path
import re
import tempfile

os.environ.setdefault("MPLCONFIGDIR", str(Path(tempfile.gettempdir()) / "matplotlib-codex"))
os.environ.setdefault("MPLBACKEND", "Agg")

import matplotlib.pyplot as plt
from matplotlib.lines import Line2D
from matplotlib.ticker import AutoMinorLocator, MultipleLocator
import numpy as np
from PIL import Image


MODELS = {
    "control": ("multi_tc_2d_control.raw", "Identical-lane control"),
    "strain": ("multi_tc_2d_strain_contrast.raw", "Strain-contrast grid"),
    "weak": ("multi_tc_2d_weak_links.raw", "Temperature-dependent weak links"),
}


def read_raw(path: Path) -> tuple[list[str], np.ndarray]:
    payload = path.read_bytes()
    for encoding in ("utf-16le", "utf-8"):
        marker = "Binary:\n".encode(encoding)
        marker_at = payload.find(marker)
        if marker_at >= 0:
            binary_at = marker_at + len(marker)
            header = payload[:binary_at].decode(encoding, errors="replace")
            break
    else:
        raise ValueError(f"No LTspice Binary section in {path}")

    nvars = int(re.search(r"No\. Variables:\s*(\d+)", header).group(1))
    npoints = int(re.search(r"No\. Points:\s*(\d+)", header).group(1))
    block = header.split("Variables:\n", 1)[1].split("Binary:\n", 1)[0]
    names = []
    for line in block.splitlines():
        match = re.match(r"\s*\d+\s+(\S+)\s+", line)
        if match:
            names.append(match.group(1))
    if len(names) != nvars:
        raise ValueError(f"Expected {nvars} variables, found {len(names)}")

    dtype = np.dtype([("x", "<f8"), ("rest", "<f4", (nvars - 1,))])
    records = np.frombuffer(payload, dtype=dtype, count=npoints, offset=binary_at)
    values = np.empty((npoints, nvars), dtype=float)
    values[:, 0] = records["x"]
    values[:, 1:] = records["rest"]
    return names, values


def extract_model(path: Path) -> dict[str, np.ndarray]:
    names, values = read_raw(path)
    columns = {name.lower(): index for index, name in enumerate(names)}

    def col(name: str) -> np.ndarray:
        try:
            return values[:, columns[name.lower()]]
        except KeyError as exc:
            raise ValueError(f"{name} absent from {path}; found {names}") from exc

    current = col("I(Vprobe)")
    if np.nanmedian(current) < 0:
        current = -current
    result = {
        "temperature_K": col("t"),
        "total_ohm": col("V(src)") / current,
        "covered_probe_ohm": (col("V(c1)") - col("V(c5)")) / current,
        "boundary_probe_ohm": (col("V(b1)") - col("V(b5)")) / current,
        "uncovered_probe_ohm": (col("V(u1)") - col("V(u5)")) / current,
        "covered_current_fraction": col("I(RsrcC)") / current,
        "boundary_current_fraction": col("I(RsrcB)") / current,
        "uncovered_current_fraction": col("I(RsrcU)") / current,
    }
    order = np.argsort(result["temperature_K"])
    return {name: data[order] for name, data in result.items()}


def digitize_experiment(path: Path) -> tuple[np.ndarray, np.ndarray]:
    image = Image.open(path).convert("RGBA")
    background = Image.new("RGBA", image.size, "white")
    background.alpha_composite(image)
    gray = np.asarray(background.convert("L"))
    if gray.shape != (1750, 2291):
        raise ValueError("Experimental image dimensions changed; recalibrate axes")
    x_left, x_right = 412, 1970
    y_bottom, y_top = 1455, 204
    points = []
    for xpix in range(x_left + 8, x_right - 8):
        dark_y = np.flatnonzero(gray[230:1440, xpix] < 90) + 230
        temperature = (xpix - x_left) / (x_right - x_left) * 4.25
        if len(dark_y) and 0.10 <= temperature <= 4.10:
            resistance = (y_bottom - float(np.median(dark_y))) / (y_bottom - y_top) * 52.5
            points.append((temperature, resistance))
    points = np.asarray(points)
    rows = []
    for low in np.arange(0.10, 4.10, 0.01):
        selected = points[(points[:, 0] >= low) & (points[:, 0] < low + 0.01), 1]
        if len(selected):
            rows.append((low + 0.005, float(np.median(selected))))
    data = np.asarray(rows)
    return data[:, 0], data[:, 1]


def write_csv(path: Path, data: dict[str, np.ndarray]) -> None:
    fields = list(data)
    with path.open("w", newline="") as handle:
        writer = csv.writer(handle)
        writer.writerow(fields)
        writer.writerows(zip(*(data[field] for field in fields)))


def style_rt(ax: plt.Axes, ylabel: str = r"Resistance ($\Omega$)") -> None:
    ax.set_xlim(0, 4.25)
    ax.set_xlabel("Temperature (K)")
    ax.set_ylabel(ylabel)
    ax.xaxis.set_major_locator(MultipleLocator(1))
    ax.xaxis.set_minor_locator(AutoMinorLocator(2))
    ax.yaxis.set_minor_locator(AutoMinorLocator(2))
    ax.tick_params(which="both", direction="in", top=True, right=True, width=1.2)
    ax.tick_params(which="major", length=5)
    ax.tick_params(which="minor", length=2.5)
    for spine in ax.spines.values():
        spine.set_linewidth(1.2)


def save(fig: plt.Figure, output_dir: Path, stem: str) -> None:
    fig.savefig(output_dir / f"{stem}.png", dpi=600, bbox_inches="tight", facecolor="white")
    fig.savefig(output_dir / f"{stem}.pdf", bbox_inches="tight", facecolor="white")
    plt.close(fig)


def draw_network(output_dir: Path) -> None:
    colors = {"Covered": "#218c74", "Boundary": "#c43c35", "Uncovered": "#3569a8"}
    yvalues = {"Covered": 2, "Boundary": 1, "Uncovered": 0}
    fig, ax = plt.subplots(figsize=(6.6, 2.35), constrained_layout=True)
    for lane, y in yvalues.items():
        color = colors[lane]
        for x in range(6):
            ax.plot([x, x + 1], [y, y], color=color, lw=3, solid_capstyle="round")
        ax.scatter(range(7), [y] * 7, s=25, facecolor="white", edgecolor=color,
                   linewidth=1.4, zorder=3)
        ax.text(-0.35, y, lane, ha="right", va="center", fontsize=9, color=color)
    for x in range(7):
        ax.plot([x, x], [1, 2], color="#555555", lw=1.0)
        ax.plot([x, x], [0, 1], color="#888888", lw=1.0, linestyle="--")
    ax.annotate("source", (-0.02, 2.38), ha="left", va="bottom", fontsize=8)
    ax.annotate("drain", (6.02, 2.38), ha="right", va="bottom", fontsize=8)
    ax.annotate("current direction", (3, 2.38), ha="center", va="bottom", fontsize=8)
    ax.annotate("", xy=(4.2, 2.42), xytext=(1.8, 2.42),
                arrowprops={"arrowstyle": "->", "lw": 1.0, "color": "black"})
    ax.set_xlim(-1.05, 6.25)
    ax.set_ylim(-0.35, 2.65)
    ax.set_aspect("equal")
    ax.axis("off")
    save(fig, output_dir, "multi_tc_2d_network_schematic")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--directory", type=Path, default=Path(__file__).resolve().parent)
    parser.add_argument("--experimental-image", type=Path)
    args = parser.parse_args()
    output_dir = args.directory.resolve()

    plt.rcParams.update({
        "font.family": "Arial",
        "font.size": 9,
        "axes.labelsize": 10,
        "xtick.labelsize": 8.5,
        "ytick.labelsize": 8.5,
        "pdf.fonttype": 42,
        "ps.fonttype": 42,
    })
    models = {}
    for key, (filename, _) in MODELS.items():
        models[key] = extract_model(output_dir / filename)
        write_csv(output_dir / filename.replace(".raw", "_rt.csv"), models[key])

    experiment = None
    if args.experimental_image:
        experiment = digitize_experiment(args.experimental_image)

    colors = {"control": "#777777", "strain": "#d58b27", "weak": "#c43c35"}
    fig, ax = plt.subplots(figsize=(3.55, 2.80), constrained_layout=True)
    if experiment:
        ax.plot(*experiment, linestyle="none", marker="v", ms=2.0, color="black",
                markeredgewidth=0, label="Experiment (digitized)")
    for key in ("control", "strain", "weak"):
        label = MODELS[key][1]
        linestyle = ":" if key == "control" else "-"
        ax.plot(models[key]["temperature_K"], models[key]["total_ohm"],
                color=colors[key], lw=1.35, linestyle=linestyle, label=label)
    ax.set_ylim(0, 52.5)
    style_rt(ax)
    ax.legend(frameon=False, fontsize=6.6, loc="lower right", handlelength=2.1)
    save(fig, output_dir, "multi_tc_2d_model_progression")

    final = models["weak"]
    fig, ax = plt.subplots(figsize=(3.55, 2.80), constrained_layout=True)
    if experiment:
        ax.plot(*experiment, linestyle="none", marker="v", ms=2.1, color="black",
                markeredgewidth=0, label="Experiment (digitized)")
    ax.plot(final["temperature_K"], final["total_ohm"], color="#c43c35", lw=1.5,
            label="2D weak-link model")
    ax.set_ylim(0, 52.5)
    style_rt(ax)
    ax.legend(frameon=False, fontsize=7.2, loc="lower right")
    save(fig, output_dir, "multi_tc_2d_experiment_comparison")

    fig, ax = plt.subplots(figsize=(3.55, 2.80), constrained_layout=True)
    lane_styles = (
        ("covered_probe_ohm", "Covered", "#218c74"),
        ("boundary_probe_ohm", "Boundary", "#c43c35"),
        ("uncovered_probe_ohm", "Uncovered", "#3569a8"),
    )
    for field, label, color in lane_styles:
        ax.plot(final["temperature_K"], final[field], label=label, color=color, lw=1.4)
    style_rt(ax, r"Four-probe analog ($\Omega$)")
    ax.legend(frameon=False, fontsize=7.2, loc="upper left")
    save(fig, output_dir, "multi_tc_2d_lane_responses")

    fig, ax = plt.subplots(figsize=(3.55, 2.80), constrained_layout=True)
    current_styles = (
        ("covered_current_fraction", "Covered", "#218c74"),
        ("boundary_current_fraction", "Boundary", "#c43c35"),
        ("uncovered_current_fraction", "Uncovered", "#3569a8"),
    )
    for field, label, color in current_styles:
        ax.plot(final["temperature_K"], 100 * final[field], label=label, color=color, lw=1.4)
    style_rt(ax, "Source current (%)")
    ax.set_ylim(0, 100)
    ax.legend(frameon=False, fontsize=7.2, loc="center right")
    save(fig, output_dir, "multi_tc_2d_current_redistribution")
    draw_network(output_dir)

    if experiment:
        exp_t, exp_r = experiment
        for key in MODELS:
            prediction = np.interp(exp_t, models[key]["temperature_K"], models[key]["total_ohm"])
            rmse = np.sqrt(np.mean((prediction - exp_r) ** 2))
            print(f"{key}: RMSE = {rmse:.4f} ohm")
    print(f"final R(0.10 K) = {final['total_ohm'][0]:.4f} ohm")
    print(f"final R(4.20 K) = {final['total_ohm'][-1]:.4f} ohm")


if __name__ == "__main__":
    main()
