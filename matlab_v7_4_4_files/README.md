# MoTe2 superconducting network MATLAB scaffold, v7.4.4

v7.4.4 is a controlled weak-link-transparency ablation sweep for AS006.
It keeps the geometry, PDE/Raman proxy, local transition field, disorder
realization, probe mapping, magnetic-field grid, and base normal-state
reference fixed, and varies only the weak-link transparency field `W_ij`.

It asks:

```text
Does the spatial topology of W_ij matter after all other model fields are
held fixed?
```

Main entry point:

```matlab
run_v744_as006_physical_bottleneck_sweep
```

## What v7.4.4 changes relative to v7.4.2

v7.4.2 ranked named weak-link hypotheses, but several weak-link-related
parameters changed together. v7.4.4 removes that underconstrained freedom.
For a link transparency

```text
W_ij = G_ij / G_bulk,
```

v7.4.4 applies only

```text
Rn_ij -> Rn_ij / W_ij
Ic_ij -> W_ij Ic_ij
```

while leaving local `Tc`, residual fraction, Raman/PDE fields, and base
disorder unchanged.

The physical bottleneck cases are:

- `combined`: boundary/contact/crowding/tear/hotspot bottlenecks combined;
- `boundary_lane`: a weak lane along the encapsulation boundary;
- `contact_relaxation`: weak-link halos around voltage probes/contact pads;
- `current_crowding`: source/drain and probe-neighbor bottlenecks;
- `tear_lane`: a crack/tear-like interrupted lane;
- `anisotropic`: direction-dependent weak-link transparency;
- `uniform`: same mean transparency without spatial structure;
- `shuffled`: same transparency histogram with randomized positions;
- `central_lane`: same local transition distribution, but lateral bypass
  paths removed;
- `no_weak_links`: all weak-link transparencies set to bulk-like coupling.

The compact sweep varies only:

```text
gammaW = G_weak / G_bulk
pW     = weak-link fraction
```

## Two calibration conventions

v7.4.4 reports two scores for every ablation:

- `shape`: each ablation is independently recalibrated to the same `R_N`.
  This asks whether `W_ij` topology changes transition/current/field shape
  after trivial resistance-scale differences are removed.
- `conductance`: for each `gammaW`/`pW` family, the combined
  physical-bottleneck model is calibrated once and that same normal-state
  scale is then applied unchanged to the other ablations in that family.
  This asks what electrical consequence the ablation would have without
  retuning the network conductance inside that family.

## Expected output

The runner writes:

```text
outputs/v7_4_4_as006_physical_bottleneck
```

Key files:

- `AS006_v7_4_4_physical_bottleneck_scores.csv`
- `AS006_v7_4_4_physical_bottleneck_summary.png/.pdf/.fig`
- optional full `dV/dI(I,B)` maps for the best shape-controlled case;
- optional full `dV/dI(I,B)` maps for the best conductance-preserving case;
- `AS006_v7_4_4_physical_bottleneck.mat`

## Caveat

`W_ij` remains a phenomenological transparency field, not a full
phase-dynamical Josephson-junction-array model. True sweep-history hysteresis,
vortex dynamics, and heating remain later tasks.
