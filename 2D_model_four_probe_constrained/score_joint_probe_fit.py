#!/usr/bin/env python3
"""Score one shared model against any available four-probe R(T) datasets."""

from __future__ import annotations

import argparse
import csv
from pathlib import Path

import numpy as np


PROBES = ("Rxx_full_ohm", "Rxx_covered_ohm", "Rxx_boundary_ohm",
          "Rxx_uncovered_ohm", "Rtransverse_mid_ohm")


def read_numeric_csv(path: Path) -> dict[str, np.ndarray]:
    with path.open() as handle:
        rows = list(csv.DictReader(handle))
    result = {}
    for field in rows[0]:
        values = []
        valid = True
        for row in rows:
            try:
                values.append(float(row[field]))
            except (TypeError, ValueError):
                valid = False
                break
        if valid:
            result[field] = np.asarray(values)
    return result


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("measured", type=Path,
                        help="CSV with temperature_K and one or more probe columns")
    parser.add_argument("--model", type=Path, default=Path("four_probe_rt_predictions.csv"))
    parser.add_argument("--parameter-count", type=int, default=25)
    args = parser.parse_args()
    measured = read_numeric_csv(args.measured)
    modeled = read_numeric_csv(args.model)
    if "temperature_K" not in measured:
        raise ValueError("Measured CSV requires temperature_K")

    residuals = []
    for probe in PROBES:
        if probe not in measured:
            continue
        prediction = np.interp(measured["temperature_K"], modeled["temperature_K"], modeled[probe])
        residual = prediction - measured[probe]
        residuals.append(residual)
        print(f"{probe}: n={len(residual)}, RMSE={np.sqrt(np.mean(residual**2)):.5g} ohm")
    if not residuals:
        raise ValueError(f"Measured CSV contains none of {PROBES}")
    residual = np.concatenate(residuals)
    rss = float(np.sum(residual ** 2))
    n = len(residual)
    variance = max(rss / n, np.finfo(float).tiny)
    aic = n * np.log(variance) + 2 * args.parameter_count
    bic = n * np.log(variance) + args.parameter_count * np.log(n)
    print(f"joint: n={n}, RMSE={np.sqrt(rss/n):.5g} ohm, AIC={aic:.3f}, BIC={bic:.3f}")


if __name__ == "__main__":
    main()
