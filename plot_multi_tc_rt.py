#!/usr/bin/env python3
"""Parse an LTspice stepped-.op raw file and make publication R(T) plots."""

from __future__ import annotations

import argparse
import csv
import os
from pathlib import Path
import re
import tempfile

os.environ.setdefault("MPLCONFIGDIR", str(Path(tempfile.gettempdir()) / "matplotlib-codex"))

import matplotlib.pyplot as plt
from matplotlib.ticker import AutoMinorLocator, MultipleLocator
import numpy as np
from PIL import Image


def read_ltspice_raw(path: Path) -> tuple[list[str], np.ndarray]:
    payload = path.read_bytes()
    candidates = (("utf-16le", "Binary:\n"), ("utf-8", "Binary:\n"))
    for encoding, marker_text in candidates:
        marker = marker_text.encode(encoding)
        marker_at = payload.find(marker)
        if marker_at >= 0:
            binary_at = marker_at + len(marker)
            header = payload[:binary_at].decode(encoding, errors="replace")
            break
    else:
        raise ValueError(f"No LTspice Binary section found in {path}")

    nvars_match = re.search(r"No\. Variables:\s*(\d+)", header)
    npoints_match = re.search(r"No\. Points:\s*(\d+)", header)
    if not nvars_match or not npoints_match:
        raise ValueError("LTspice variable/point counts are missing")
    nvars = int(nvars_match.group(1))
    npoints = int(npoints_match.group(1))

    variable_block = header.split("Variables:\n", 1)[1].split("Binary:\n", 1)[0]
    names: list[str] = []
    for line in variable_block.splitlines():
        match = re.match(r"\s*\d+\s+([^\s]+)\s+", line)
        if match:
            names.append(match.group(1))
    if len(names) != nvars:
        raise ValueError(f"Expected {nvars} variables, found {len(names)}")

    # LTspice stores the stepped parameter as float64 and remaining real
    # variables as float32 for each operating-point record.
    dtype = np.dtype([("x", "<f8"), ("rest", "<f4", (nvars - 1,))])
    records = np.frombuffer(payload, dtype=dtype, count=npoints, offset=binary_at)
    values = np.empty((npoints, nvars), dtype=float)
    values[:, 0] = records["x"]
    values[:, 1:] = records["rest"]
    return names, values


def find_column(names: list[str], requested: str) -> int:
    normalized = [name.lower() for name in names]
    try:
        return normalized.index(requested.lower())
    except ValueError as exc:
        raise ValueError(f"{requested!r} is absent; raw variables are {names}") from exc


def extract_rt(raw_path: Path) -> tuple[np.ndarray, np.ndarray]:
    names, values = read_ltspice_raw(raw_path)
    temperature = values[:, find_column(names, "t")]
    voltage = values[:, find_column(names, "V(sense)")]
    current = values[:, find_column(names, "I(Vprobe)")]
    resistance = voltage / current
    if np.nanmedian(resistance) < 0:
        resistance = -resistance
    order = np.argsort(temperature)
    return temperature[order], resistance[order]


def digitize_experimental_trace(image_path: Path) -> tuple[np.ndarray, np.ndarray]:
    """Digitize the supplied 2291 x 1750 raster using its plotted axis bounds."""
    image = Image.open(image_path).convert("RGBA")
    background = Image.new("RGBA", image.size, "white")
    background.alpha_composite(image)
    gray = np.asarray(background.convert("L"))
    if gray.shape != (1750, 2291):
        raise ValueError("Experimental image dimensions changed; recalibrate axis pixels")

    x_left, x_right = 412, 1970
    y_bottom, y_top = 1455, 204
    rows: list[tuple[float, float]] = []
    for xpix in range(x_left + 8, x_right - 8):
        dark_y = np.flatnonzero(gray[230:1440, xpix] < 90) + 230
        temperature = (xpix - x_left) / (x_right - x_left) * 4.25
        if len(dark_y) and 0.10 <= temperature <= 4.10:
            ypix = float(np.median(dark_y))
            resistance = (y_bottom - ypix) / (y_bottom - y_top) * 52.5
            rows.append((temperature, resistance))

    points = np.asarray(rows)
    bins = np.arange(0.10, 4.111, 0.01)
    binned: list[tuple[float, float]] = []
    for low, high in zip(bins[:-1], bins[1:]):
        selected = points[(points[:, 0] >= low) & (points[:, 0] < high), 1]
        if len(selected):
            binned.append(((low + high) / 2, float(np.median(selected))))
    result = np.asarray(binned)
    return result[:, 0], result[:, 1]


def style_axes(ax: plt.Axes) -> None:
    ax.set_xlim(0, 4.25)
    ax.set_ylim(0, 52.5)
    ax.set_xlabel("Temperature (K)")
    ax.set_ylabel(r"Resistance ($\Omega$)")
    ax.xaxis.set_major_locator(MultipleLocator(1))
    ax.yaxis.set_major_locator(MultipleLocator(10))
    ax.xaxis.set_minor_locator(AutoMinorLocator(2))
    ax.yaxis.set_minor_locator(AutoMinorLocator(2))
    ax.tick_params(which="both", direction="in", top=True, right=True, width=1.35)
    ax.tick_params(which="major", length=6)
    ax.tick_params(which="minor", length=3)
    for spine in ax.spines.values():
        spine.set_linewidth(1.35)


def write_csv(path: Path, temperature: np.ndarray, resistance: np.ndarray) -> None:
    with path.open("w", newline="") as handle:
        writer = csv.writer(handle)
        writer.writerow(("temperature_K", "resistance_ohm"))
        writer.writerows(zip(temperature, resistance))


def save_figure(fig: plt.Figure, stem: Path) -> None:
    fig.savefig(stem.with_suffix(".png"), dpi=600, bbox_inches="tight", facecolor="white")
    fig.savefig(stem.with_suffix(".pdf"), bbox_inches="tight", facecolor="white")
    plt.close(fig)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("raw", type=Path, help="LTspice .raw file from the fitted netlist")
    parser.add_argument("--experimental-image", type=Path)
    parser.add_argument("--output-dir", type=Path, default=None)
    args = parser.parse_args()

    output_dir = args.output_dir or args.raw.resolve().parent
    output_dir.mkdir(parents=True, exist_ok=True)
    temperature, resistance = extract_rt(args.raw)
    write_csv(output_dir / "multi_tc_1d_experiment_fit_rt.csv", temperature, resistance)

    plt.rcParams.update({
        "font.family": "Arial",
        "font.size": 9,
        "axes.labelsize": 11,
        "xtick.labelsize": 9,
        "ytick.labelsize": 9,
        "pdf.fonttype": 42,
        "ps.fonttype": 42,
    })
    fig, ax = plt.subplots(figsize=(3.55, 2.80), constrained_layout=True)
    ax.plot(temperature, resistance, color="black", lw=1.35)
    ax.plot(temperature[::30], resistance[::30], linestyle="none", marker="v",
            ms=2.7, color="black", markeredgewidth=0)
    style_axes(ax)
    save_figure(fig, output_dir / "multi_tc_1d_experiment_fit_rt")

    if args.experimental_image:
        exp_t, exp_r = digitize_experimental_trace(args.experimental_image)
        write_csv(output_dir / "experimental_rt_digitized.csv", exp_t, exp_r)
        fig, ax = plt.subplots(figsize=(3.55, 2.80), constrained_layout=True)
        ax.plot(exp_t, exp_r, linestyle="none", marker="v", ms=2.1,
                color="black", markeredgewidth=0, label="Experiment (digitized)")
        ax.plot(temperature, resistance, color="#c43c35", lw=1.5, label="1D model")
        style_axes(ax)
        ax.legend(frameon=False, loc="lower right", fontsize=7.5, handlelength=2.0)
        save_figure(fig, output_dir / "multi_tc_1d_experiment_fit_comparison")

    print(f"R(0.10 K) = {resistance[0]:.4f} ohm")
    print(f"R(4.20 K) = {resistance[-1]:.4f} ohm")
    print(f"Wrote publication outputs to {output_dir}")


if __name__ == "__main__":
    main()
