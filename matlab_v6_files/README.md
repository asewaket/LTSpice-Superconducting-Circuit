# MoTe2 superconducting network MATLAB scaffold, v6

This folder is the v6 iteration of the MATLAB project built from
`Res_Array_1.m`.

The model keeps the original local-link idea,

```text
(Rn, Tc, Ic)
```

but embeds it in a Hall-bar-aware, four-probe superconducting-network model for
AS001--AS006.

## What v6 adds

v6 is the first Raman-informed transport iteration. It keeps the v5.6 Raman
registration/visualization workflow, but now asks whether registered Raman
spatial heterogeneity improves normalized R(T) agreement for AS002, AS005, and
AS006.

The new transport test blends the original geometry-only mechanical proxy with
a support-weighted Raman proxy:

```text
eta_hybrid = eta_geometry + alpha*w*(eta_raman - eta_geometry)
```

where `w(x,y)` is the Raman interpolation-support map. Far from registered
Raman line scans, `w -> 0`, so the model falls back to the geometry-only proxy.
By default, the normalized Raman map is scaled to the maximum geometry-only
`eta` value for that device. This keeps Raman as a spatial-heterogeneity input
rather than an arbitrary new device-level stress amplitude.

v6 adds:

- `run_raman_hybrid_transport_sweep.m`;
- Raman-hybrid proxy construction through `apply_raman_hybrid_proxy.m`;
- alpha sweep over geometry-only to Raman-informed behavior;
- model-vs-experiment metric scoring for AS002, AS005, and AS006;
- normalized R(T) comparison of experiment, geometry-only model, and best
  Raman-hybrid model;
- CSV export of alpha-sweep metric scores.

## v5.6 figure cleanup retained

v5.6 keeps the v5.5 Raman registration workflow but fixes the visualization so
registered line scans are not overinterpreted as dense 2D Raman maps:

- signed Raman panels now show only measured line-scan constraints on a clean
  Hall-bar background, without a misleading full-device colored background;
- modes are distinguished by marker shape in the signed-point panels;
- interpolated `|Raman proxy|` maps are masked by Raman support, so far-away
  regions do not look equally constrained;
- a separate interpolation-support/confidence panel is plotted for each device;
- presentation-ready per-device 2x2 summary figures are exported alongside the
  compact multi-device overview;
- `raman_proxy_map_summary.csv` now reports supported node fraction,
  interpolated node fraction, and mean interpolation support.

v5/v5.5 kept the v4 network/proxy/ensemble/figure/metric structure and added a first
Raman-data layer:

- project-local digitized Raman line-scan files for AS002, AS005, and AS006;
- Raman import from comment-prefixed CSV-style text files;
- per-device/per-scan/per-mode Raman shift summaries;
- normalized signed and absolute Raman-shift proxy columns;
- thesis-friendly Raman summary figure export;
- a deliberately separate Raman workflow that does not yet alter the network
  parameters until scan-to-Hall-bar registration is defined.

The v4 model/experiment comparison layer is still included:

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

## Raman entry point

Run:

```matlab
run_raman_digitized_summary
```

The script loads:

```text
data/raman_digitized/AS002_raman_digitized.txt
data/raman_digitized/AS005_raman_digitized.txt
data/raman_digitized/AS006_raman_digitized.txt
```

and writes:

```text
outputs/raman/raman_digitized_with_proxies.csv
outputs/raman/raman_digitized_summary_metrics.csv
outputs/raman/raman_digitized_line_scan_summary.png
outputs/raman/raman_digitized_line_scan_summary.pdf
```

The Raman data are currently used as experimental spatial constraints on the
mechanical-response proxy, not as a unique quantitative strain reconstruction.
The normalized Raman-shift proxy is computed independently for each
device/scan/mode series:

```text
signed_shift_proxy = delta_peak_cm1 / max(abs(delta_peak_cm1))
abs_shift_proxy    = abs(signed_shift_proxy)
```

This makes the Raman layer useful for comparing spatial patterns while avoiding
an unsupported claim that each mode has already been converted into absolute
local MoTe2 strain.

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

Where direct low-current R(T) files contain both R1 and R2 channels, v5 also
loads them into `expData.pairData` for probe-pair metric comparisons.

## Metric definitions

For each R(T) curve, v5 extracts:

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
6. `load_raman_digitized_data.m`, `make_raman_shift_proxy.m`, and
   `summarize_raman_digitized_data.m` prepare Raman spatial-response inputs.

## Important limitation

The field `eta` is not yet a calibrated strain field. It is a normalized
mechanical-response proxy based on geometry, film force, and crack/stressor
masks. v5.5 registers Raman line-scan constraints onto the Hall-bar coordinate
system and exports Raman proxy maps. The next step is to add an optional
transport-model mode where registered Raman maps modify or blend with
`eta_geometry` before assigning `(Rn,Tc,Ic)`.

## v5.6 Raman registration

Run:

```matlab
run_raman_registration_summary
```

The script loads:

```text
data/raman_digitized/AS002_raman_digitized.txt
data/raman_digitized/AS005_raman_digitized.txt
data/raman_digitized/AS006_raman_digitized.txt
data/raman_registration/raman_scan_endpoints_hallbar_coordinates.txt
```

and writes:

```text
outputs/raman_registration/raman_registered_points.csv
outputs/raman_registration/raman_scan_registration_table.csv
outputs/raman_registration/raman_proxy_map_summary.csv
outputs/raman_registration/AS002_raman_proxy_map.mat
outputs/raman_registration/AS005_raman_proxy_map.mat
outputs/raman_registration/AS006_raman_proxy_map.mat
outputs/raman_registration/raman_registration_overlays.png
outputs/raman_registration/raman_registration_overlays.pdf
outputs/raman_registration/AS002_raman_registration_summary.png
outputs/raman_registration/AS005_raman_registration_summary.png
outputs/raman_registration/AS006_raman_registration_summary.png
```

For presentations or thesis figures, prefer the per-device
`*_raman_registration_summary` exports. The multi-device
`raman_registration_overlays` figure is intended as a compact diagnostic
overview.

Registration maps each line-scan coordinate onto the manually supplied endpoint
segment:

```text
s = (position_um - min(position_um)) / (max(position_um) - min(position_um))
x = x0 + s*(x1 - x0)
y = y0 + s*(y1 - y0)
```

The first node-level Raman map uses Gaussian-weighted interpolation of
`abs_shift_proxy`. v5.6 displays this as a support-masked spatial-response
constraint, not as a calibrated strain map and not yet as a direct replacement
for `eta` in the transport solver.

## v6 Raman-informed transport entry point

Run:

```matlab
run_raman_hybrid_transport_sweep
```

This script uses the registered Raman line-scan proxy to run:

```text
alpha = 0, 0.25, 0.50, 0.75, 1.00
```

for AS002, AS005, and AS006. `alpha = 0` is the geometry-only model. Larger
alpha values increasingly replace the geometry-only proxy with the
support-weighted Raman proxy near measured line scans.

Outputs are written to:

```text
outputs/raman_hybrid_transport/
```

Important outputs:

```text
raman_hybrid_alpha_sweep_metrics.csv
raman_hybrid_transport_sweep.mat
raman_hybrid_alpha_sweep_scores.png/.pdf
raman_hybrid_rt_comparison.png/.pdf
```

The score is a dimensionless model/experiment mismatch based on normalized R(T)
metrics:

```text
rLow
Tonset
Tmid
width90_10
```

Lower score means better agreement. The comparison is still semiquantitative:
the absolute simulated normal-state resistance is calibrated separately for
each run, so v6 tests transition shape, onset, width, and residual resistance,
not an independent prediction of R_N.
