# MoTe2 superconducting network MATLAB scaffold, v2

This folder is the second iteration of the MATLAB project built from
`Res_Array_1.m`.

The original code modeled a generic square array of superconducting resistor
links. This version keeps the same local-link idea,

```text
(Rn, Tc, Ic)
```

but embeds it in a Hall-bar-aware, four-probe network model for AS001--AS006.

## What v2 adds

- simplified old/new Hall-bar geometry masks;
- explicit source and drain current-contact regions;
- internal passive voltage-probe regions;
- four-probe resistance extraction for the 4--10 and 3--9 probe pairs;
- control, full-coverage, half-coverage, and cracked-coverage masks;
- a normalized mechanical-response proxy `eta(x,y)`;
- shared constitutive rules mapping `eta -> (Rn,Tc,Ic)`;
- small disorder ensembles instead of a single hand-picked realization;
- qualitative metrics: onset, residual fraction, probe asymmetry, current participation, and percolation;
- an AS005 ablation demo comparing full, uniform, randomized, weak-transverse, and crack-off cases.
- a coarse-grid AS005 demo for 3x3, 4x4, and 5x5 effective-domain networks.

The important change from v1 is that local parameters are no longer primarily
chosen device-by-device. Device-specific inputs are mostly geometry, film force,
stressor/crack masks, and normal-resistance scale. The same shared mapping rules
are then applied across the device series.

## Main entry point

Run:

```matlab
run_six_device_scaffold
```

The script produces:

- geometry/mask/proxy plots;
- representative `R(T)` curves;
- ensemble mean ± one-standard-deviation `R(T)` curves;
- `six_device_scaffold_results.mat`;
- `AS005_ablation_demo.mat`.
- `AS005_grid_size_demo.mat`.

Outputs are saved in:

```text
outputs/
```

Helper functions can also be run directly with defaults:

```matlab
run_device_ensemble          % defaults to AS005
run_device_ensemble('AS004')

run_grid_size_demo           % defaults to AS005
run_grid_size_demo('AS005')

run_ablation_demo            % defaults to AS005
```

## Device labels

Figures and code use only the thesis-facing labels AS001--AS006.

## Model layers

The code is organized around four layers:

1. `make_device_spec.m` defines the fixed device geometry and experimental metadata.
2. `apply_mechanical_proxy.m` converts geometry and film force into a normalized mechanical proxy `eta`.
3. `make_shared_model_params.m` and `assign_link_parameters.m` generate link-level `(Rn,Tc,Ic)` from shared rules.
4. `solve_network_linear.m`, `solve_network_nonlinear.m`, and `solve_rt_sweep.m` solve the electrical network and extract four-probe observables.

## Geometry convention used here

The scaffold uses the annotated screenshots as the geometry convention:

- AS001, AS002, AS003, AS004, AS006: new Hall-bar geometry;
- AS005: old Hall-bar geometry;
- new geometry: approximate source-drain span `18 um`, channel width `7 um`, voltage-probe spacing `5 um`, voltage-probe width `0.5 um`;
- old geometry: approximate source-drain span `4 um`, channel width `7 um`, voltage-probe spacing `1.25 um`, voltage-probe width `0.5 um`.

If the geometry needs correction, edit `make_device_spec.m`.

## Important limitation

The field `eta` is not yet a calibrated strain field. It is a normalized
mechanical-response proxy based on geometry, film force, and crack/stressor
masks. A later version can replace or constrain it with registered Raman maps.
