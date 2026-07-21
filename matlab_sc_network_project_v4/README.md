# MoTe2 superconducting network MATLAB scaffold, v4

This folder is the fourth iteration of the MATLAB project built from
`Res_Array_1.m`.

The model keeps the original local-link idea,

```text
(Rn, Tc, Ic)
```

but embeds it in a Hall-bar-aware, four-probe superconducting-network model for
AS001--AS006.

## What v4 adds

v4 keeps the v3 network/proxy/ensemble/figure structure and adds a metric-based
model/experiment comparison layer:

- AS001--AS006 device specs and thesis-facing labels;
- simplified old/new Hall-bar geometry masks;
- source/drain contacts and internal voltage probes;
- four-probe extraction for the 4--10 and 3--9 probe pairs;
- control, full-coverage, half-coverage, and cracked-coverage masks;
- normalized mechanical-response proxy `eta(x,y)`;
- shared `eta -> (Rn,Tc,Ic)` rules;
- disorder ensembles and qualitative metrics;
- AS005 ablation demo;
- AS005 3x3/4x4/5x5 coarse-grid demo;
- exported experimental R(T) import where mapped;
- absolute and normalized model-vs-experiment overlays;
- chapter-style PNG/PDF figure export.
- thesis-friendly light-background axes and legend styling, independent of MATLAB dark mode.
- explicit R(T) metric extraction for experiment and model;
- CSV metric tables for all sources/channels and selected model-experiment comparisons;
- support for both 4--10 and 3--9 experimental channels where available.
- lightweight proxy/parameter sensitivity sweep ranked by R(T) metric agreement.

The important modeling shift is still:

```text
hand-selected local link parameters
    -> shared parameter-assignment rules plus device-specific geometry/proxy inputs
```

## Main entry point

Run:

```matlab
run_six_device_scaffold
```

The script produces:

- geometry/mask/proxy plots;
- representative model `R(T)` curves;
- ensemble mean ± one-standard-deviation `R(T)` curves;
- absolute model/experiment overlays;
- normalized model/experiment overlays;
- six-device normalized model/experiment comparison matching the Chapter 4 caption;
- AS005 geometry/dimensionality/null-model test figure;
- separate ensemble/robustness figures with uncertainty bands;
- `six_device_scaffold_results.mat`;
- `AS005_ablation_demo.mat`;
- `AS005_grid_size_demo.mat`.
- `metric_tables/rt_metrics_all_sources.csv`;
- `metric_tables/rt_metrics_model_experiment_comparison.csv`.
- `sensitivity/proxy_sensitivity_ranked_samples.csv`;
- `sensitivity/proxy_sensitivity_device_scores.csv`;
- `sensitivity/proxy_sensitivity_summary.png/.pdf`.

Chapter-style figures are saved as PNG and PDF in:

```text
outputs/chapter_figures/
```

## Experimental R(T) mapping status

The data table is in:

```matlab
make_experiment_data_table.m
```

Currently mapped publication-curve CSV exports:

| AS label | Raw label | Mapped file |
|---|---|---|
| AS001 | ASD088 | `ASD088_RT_curve.csv` |
| AS002 | ASD093 | `ASD093_RT_curve.csv` |
| AS003 | ASD094 | `ASD094_RT_curve.csv` |
| AS004 | ASD087 | `ASD087_RT_curve.csv` |
| AS005 | ASD051 | `ASD051_RT_curve.csv` |
| AS006 | ASD092 | `ASD092_RT_curve.csv` |

These files live in the separate transport-plots output folder:

```text
/Users/asewaket/Documents/Thesis/Raw Transport Data/transport plots/rt_curves_publication/
```

Where direct low-current R(T) files contain both R1 and R2 channels, v4 also
loads them into `expData.pairData` for probe-pair metric comparisons.

## Metric definitions

For each R(T) curve, v4 extracts:

- `RN_ohm`: high-temperature reference resistance;
- `Rlow_ohm`: low-temperature residual resistance;
- `rLow = Rlow/RN`;
- `suppressionFrac = 1-rLow`;
- `Tonset_K`: highest temperature where `R/RN < 0.98` for at least two consecutive points;
- `Tmid_K`: temperature where half of the observed suppression has occurred;
- `T90_K` and `T10_K`: temperatures at 90% and 10% of the observed suppression interval;
- `width90_10_K = T90_K - T10_K`.

## Helper functions

These can be run directly:

```matlab
run_device_ensemble          % defaults to AS005
run_device_ensemble('AS004')

run_grid_size_demo           % defaults to AS005
run_grid_size_demo('AS005')

run_ablation_demo            % defaults to AS005
```

## Model layers

1. `make_device_spec.m` defines fixed device geometry and metadata.
2. `apply_mechanical_proxy.m` converts geometry/film force into `eta(x,y)`.
3. `make_shared_model_params.m` and `assign_link_parameters.m` generate `(Rn,Tc,Ic)`.
4. `solve_network_linear.m`, `solve_network_nonlinear.m`, and `solve_rt_sweep.m` solve the electrical network.
5. `load_experimental_rt.m` and `plot_model_experiment_overlay.m` compare model and data.

## Important limitation

The field `eta` is not yet a calibrated strain field. It is a normalized
mechanical-response proxy based on geometry, film force, and crack/stressor
masks. A later version can replace or constrain it with registered Raman maps.
