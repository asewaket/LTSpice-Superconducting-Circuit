#!/usr/bin/env python3
"""Analyze constrained four-probe LTspice R(T) and field/current sweeps."""

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
from matplotlib.ticker import AutoMinorLocator, MultipleLocator
import numpy as np
from PIL import Image


G_C, G_B, G_U = 0.37, 0.36, 0.27
LANES = (("c", "Covered", "#218c74"), ("b", "Boundary", "#c43c35"),
         ("u", "Uncovered", "#3569a8"))


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
        raise ValueError(f"No LTspice binary section in {path}")
    nvars = int(re.search(r"No\. Variables:\s*(\d+)", header).group(1))
    npoints = int(re.search(r"No\. Points:\s*(\d+)", header).group(1))
    block = header.split("Variables:\n", 1)[1].split("Binary:\n", 1)[0]
    names = []
    for line in block.splitlines():
        match = re.match(r"\s*\d+\s+(\S+)\s+", line)
        if match:
            names.append(match.group(1))
    dtype = np.dtype([("x", "<f8"), ("rest", "<f4", (nvars - 1,))])
    records = np.frombuffer(payload, dtype=dtype, count=npoints, offset=binary_at)
    values = np.empty((npoints, nvars), dtype=float)
    values[:, 0] = records["x"]
    values[:, 1:] = records["rest"]
    return names, values


def columns(names: list[str], values: np.ndarray) -> dict[str, np.ndarray]:
    return {name.lower(): values[:, index] for index, name in enumerate(names)}


def full_width_voltage(data: dict[str, np.ndarray]) -> np.ndarray:
    return sum(g * (data[f"v({lane}1)"] - data[f"v({lane}5)"])
               for g, lane in ((G_C, "c"), (G_B, "b"), (G_U, "u")))


def extract_rt(path: Path) -> dict[str, np.ndarray]:
    names, values = read_raw(path)
    data = columns(names, values)
    current = data["i(vprobe)"]
    if np.median(current) < 0:
        current = -current
    result = {
        "temperature_K": data["t"],
        "Rxx_full_ohm": full_width_voltage(data) / current,
        "Rxx_covered_ohm": (data["v(c1)"] - data["v(c5)"]) / current,
        "Rxx_boundary_ohm": (data["v(b1)"] - data["v(b5)"]) / current,
        "Rxx_uncovered_ohm": (data["v(u1)"] - data["v(u5)"]) / current,
        "Rtransverse_mid_ohm": (data["v(c3)"] - data["v(u3)"]) / current,
        "covered_current_fraction": data["i(rsrcc)"] / current,
        "boundary_current_fraction": data["i(rsrcb)"] / current,
        "uncovered_current_fraction": data["i(rsrcu)"] / current,
    }
    order = np.argsort(result["temperature_K"])
    return {key: value[order] for key, value in result.items()}


def extract_field_current(path: Path) -> tuple[dict[str, np.ndarray], dict[str, np.ndarray]]:
    names, values = read_raw(path)
    data = columns(names, values)
    field = data["b"]
    current_uA = data["v(imon)"]
    fields = np.unique(field)
    currents = np.unique(current_uA)
    voltages = {"full": full_width_voltage(data)}
    for lane, _, _ in LANES:
        voltages[lane] = data[f"v({lane}1)"] - data[f"v({lane}5)"]

    maps = {name: np.full((len(currents), len(fields)), np.nan) for name in voltages}
    for column, selected_field in enumerate(fields):
        selected = np.flatnonzero(np.isclose(field, selected_field, atol=1e-9))
        order = np.argsort(current_uA[selected])
        x_amp = current_uA[selected][order] * 1e-6
        for name, voltage in voltages.items():
            maps[name][:, column] = np.gradient(voltage[selected][order], x_amp)
    axes = {"field_T": fields, "current_uA": currents}
    return axes, maps


def digitize_rt(path: Path) -> tuple[np.ndarray, np.ndarray]:
    image = Image.open(path).convert("RGBA")
    background = Image.new("RGBA", image.size, "white")
    background.alpha_composite(image)
    gray = np.asarray(background.convert("L"))
    if gray.shape != (1750, 2291):
        raise ValueError("R(T) image dimensions changed; recalibrate axes")
    x_left, x_right, y_bottom, y_top = 412, 1970, 1455, 204
    points = []
    for xpix in range(x_left + 8, x_right - 8):
        dark_y = np.flatnonzero(gray[230:1440, xpix] < 90) + 230
        temperature = (xpix - x_left) / (x_right - x_left) * 4.25
        if len(dark_y) and 0.10 <= temperature <= 4.10:
            resistance = (y_bottom - np.median(dark_y)) / (y_bottom - y_top) * 52.5
            points.append((temperature, resistance))
    points = np.asarray(points)
    rows = []
    for low in np.arange(0.10, 4.10, 0.01):
        selected = points[(points[:, 0] >= low) & (points[:, 0] < low + 0.01), 1]
        if len(selected):
            rows.append((low + 0.005, float(np.median(selected))))
    result = np.asarray(rows)
    return result[:, 0], result[:, 1]


def digitize_dvdi(path: Path) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    """Recover approximate dV/dI values from the supplied raster colorbar."""
    rgb = np.asarray(Image.open(path).convert("RGB"))
    if rgb.shape[:2] != (380, 446):
        raise ValueError("dV/dI image dimensions changed; recalibrate axes")
    palette_y = np.arange(41, 329)
    palette = rgb[palette_y, 403].astype(float)
    palette_value = (328 - palette_y) / (328 - 41) * 110.0
    crop = rgb[29:329, 47:359].astype(float)
    flat = crop.reshape(-1, 3)
    recovered = np.empty(len(flat))
    for start in range(0, len(flat), 5000):
        distance = ((flat[start:start + 5000, None, :] - palette[None, :, :]) ** 2).sum(2)
        recovered[start:start + 5000] = palette_value[np.argmin(distance, axis=1)]
    resistance = recovered.reshape(crop.shape[:2])
    field = np.linspace(-1.5, 1.5, resistance.shape[1])
    current = np.linspace(5.0, 0.0, resistance.shape[0])
    return field, current[::-1], resistance[::-1]


def write_dict_csv(path: Path, data: dict[str, np.ndarray]) -> None:
    fields = list(data)
    with path.open("w", newline="") as handle:
        writer = csv.writer(handle)
        writer.writerow(fields)
        writer.writerows(zip(*(data[field] for field in fields)))


def write_map_csv(path: Path, axes: dict[str, np.ndarray], maps: dict[str, np.ndarray]) -> None:
    with path.open("w", newline="") as handle:
        writer = csv.writer(handle)
        writer.writerow(("field_T", "current_uA", "dVdI_full_ohm", "dVdI_covered_ohm",
                         "dVdI_boundary_ohm", "dVdI_uncovered_ohm"))
        for j, field in enumerate(axes["field_T"]):
            for i, current in enumerate(axes["current_uA"]):
                writer.writerow((field, current, maps["full"][i, j], maps["c"][i, j],
                                 maps["b"][i, j], maps["u"][i, j]))


def style_axes(ax: plt.Axes) -> None:
    ax.tick_params(which="both", direction="in", top=True, right=True, width=1.2)
    ax.tick_params(which="major", length=5)
    ax.tick_params(which="minor", length=2.5)
    ax.xaxis.set_minor_locator(AutoMinorLocator(2))
    ax.yaxis.set_minor_locator(AutoMinorLocator(2))
    for spine in ax.spines.values():
        spine.set_linewidth(1.2)


def save(fig: plt.Figure, directory: Path, stem: str) -> None:
    fig.savefig(directory / f"{stem}.png", dpi=600, bbox_inches="tight", facecolor="white")
    fig.savefig(directory / f"{stem}.pdf", bbox_inches="tight", facecolor="white")
    plt.close(fig)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--directory", type=Path, default=Path(__file__).resolve().parent)
    parser.add_argument("--rt-image", type=Path)
    parser.add_argument("--dvdi-image", type=Path)
    args = parser.parse_args()
    directory = args.directory.resolve()

    plt.rcParams.update({"font.family": "Arial", "font.size": 9, "axes.labelsize": 10,
                         "xtick.labelsize": 8.5, "ytick.labelsize": 8.5,
                         "pdf.fonttype": 42, "ps.fonttype": 42})
    rt = extract_rt(directory / "four_probe_rt.raw")
    axes, maps = extract_field_current(directory / "four_probe_field_current.raw")
    write_dict_csv(directory / "four_probe_rt_predictions.csv", rt)
    write_map_csv(directory / "four_probe_field_current_dvdi.csv", axes, maps)

    experiment_rt = digitize_rt(args.rt_image) if args.rt_image else None
    fig, ax = plt.subplots(figsize=(3.55, 2.80), constrained_layout=True)
    if experiment_rt:
        ax.plot(*experiment_rt, linestyle="none", marker="v", ms=2.0, color="black",
                markeredgewidth=0, label="Experiment (digitized)")
    ax.plot(rt["temperature_K"], rt["Rxx_full_ohm"], color="#c43c35", lw=1.5,
            label="Constrained 2D model")
    ax.set(xlim=(0, 4.25), ylim=(0, 52.5), xlabel="Temperature (K)",
           ylabel=r"Four-probe resistance ($\Omega$)")
    ax.xaxis.set_major_locator(MultipleLocator(1))
    style_axes(ax)
    ax.legend(frameon=False, fontsize=7.1, loc="lower right")
    save(fig, directory, "constrained_four_probe_rt_comparison")

    fig, ax = plt.subplots(figsize=(3.55, 2.80), constrained_layout=True)
    ax.plot(rt["temperature_K"], rt["Rxx_full_ohm"], color="black", lw=1.5, label="Full-width")
    for lane, label, color in LANES:
        ax.plot(rt["temperature_K"], rt[f"Rxx_{label.lower()}_ohm"], color=color,
                lw=1.25, label=label)
    ax.set(xlim=(0, 4.25), xlabel="Temperature (K)",
           ylabel=r"Four-probe response ($\Omega$)")
    ax.xaxis.set_major_locator(MultipleLocator(1))
    style_axes(ax)
    ax.legend(frameon=False, fontsize=7.0, loc="upper left")
    save(fig, directory, "constrained_probe_predictions")

    fig, ax = plt.subplots(figsize=(3.55, 2.80), constrained_layout=True)
    for field, (_, label, color) in zip(("covered", "boundary", "uncovered"), LANES):
        ax.plot(rt["temperature_K"], 100 * rt[f"{field}_current_fraction"],
                color=color, lw=1.4, label=label)
    ax.set(xlim=(0, 4.25), ylim=(0, 100), xlabel="Temperature (K)",
           ylabel="Source current (%)")
    style_axes(ax)
    ax.legend(frameon=False, fontsize=7.0, loc="center right")
    save(fig, directory, "constrained_current_redistribution")

    model_extent = [axes["field_T"][0], axes["field_T"][-1],
                    axes["current_uA"][0], axes["current_uA"][-1]]
    fig, ax = plt.subplots(figsize=(3.65, 3.05), constrained_layout=True)
    image = ax.imshow(maps["full"], origin="lower", aspect="auto", extent=model_extent,
                      cmap="seismic", vmin=0, vmax=110, interpolation="bilinear")
    ax.set(xlabel="Magnetic field (T)", ylabel=r"Current ($\mu$A)")
    style_axes(ax)
    fig.colorbar(image, ax=ax, label=r"$dV/dI$ ($\Omega$)", pad=0.03)
    save(fig, directory, "constrained_model_dvdi_map")

    if args.dvdi_image:
        exp_b, exp_i, exp_map = digitize_dvdi(args.dvdi_image)
        fig, axs = plt.subplots(1, 2, figsize=(7.0, 2.85), constrained_layout=True,
                                sharex=True, sharey=True)
        exp_extent = [exp_b[0], exp_b[-1], exp_i[0], exp_i[-1]]
        for ax, values, extent, title in (
                (axs[0], exp_map, exp_extent, "Experiment (raster extraction)"),
                (axs[1], maps["full"], model_extent, "Constrained 2D model")):
            plotted = ax.imshow(values, origin="lower", aspect="auto", extent=extent,
                                cmap="seismic", vmin=0, vmax=110, interpolation="bilinear")
            ax.set_title(title, fontsize=9)
            ax.set_xlabel("Magnetic field (T)")
            style_axes(ax)
        axs[0].set_ylabel(r"Current ($\mu$A)")
        fig.colorbar(plotted, ax=axs, label=r"$dV/dI$ ($\Omega$)", pad=0.02)
        save(fig, directory, "experimental_vs_constrained_dvdi")

    fig, ax = plt.subplots(figsize=(3.55, 2.80), constrained_layout=True)
    for selected, color in zip((0.0, 0.25, 0.50, 1.00),
                               ("#111111", "#218c74", "#c43c35", "#3569a8")):
        index = int(np.argmin(np.abs(axes["field_T"] - selected)))
        ax.plot(axes["current_uA"], maps["full"][:, index], color=color, lw=1.35,
                label=f"{axes['field_T'][index]:.2f} T")
    ax.set(xlim=(0, 5), xlabel=r"Current ($\mu$A)", ylabel=r"$dV/dI$ ($\Omega$)")
    style_axes(ax)
    ax.legend(frameon=False, fontsize=7.0)
    save(fig, directory, "constrained_dvdi_linecuts")

    if experiment_rt:
        exp_t, exp_r = experiment_rt
        prediction = np.interp(exp_t, rt["temperature_K"], rt["Rxx_full_ohm"])
        print(f"R(T) raster RMSE = {np.sqrt(np.mean((prediction-exp_r)**2)):.4f} ohm")
    print(f"R4p(0.10 K) = {rt['Rxx_full_ohm'][0]:.4f} ohm")
    print(f"R4p(4.20 K) = {rt['Rxx_full_ohm'][-1]:.4f} ohm")


if __name__ == "__main__":
    main()
