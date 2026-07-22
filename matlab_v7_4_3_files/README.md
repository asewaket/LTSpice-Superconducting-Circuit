# MoTe2 superconducting network MATLAB scaffold, v7.4.3

v7.4.3 is a controlled weak-link-transparency ablation sweep for AS006.
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
run_v743_as006_wij_ablation_sweep
```

## What v7.4.3 changes relative to v7.4.2

v7.4.2 ranked named weak-link hypotheses, but several weak-link-related
parameters changed together. v7.4.3 removes that underconstrained freedom.
For a link transparency

```text
W_ij = G_ij / G_bulk,
```

v7.4.3 applies only

```text
Rn_ij -> Rn_ij / W_ij
Ic_ij -> W_ij Ic_ij
```

while leaving local `Tc`, residual fraction, Raman/PDE fields, and base
disorder unchanged.

The ablations are:

- full geometry-correlated `W_ij`;
- no weak links;
- uniform `W_ij` with the same mean transparency;
- shuffled `W_ij` with the same transparency histogram but randomized
  positions;
- boundary/crack-specific weak-link mask off;
- central-lane topology with the same local transition distribution but
  without alternative lateral paths.

The compact sweep varies only:

```text
gammaW = G_weak / G_bulk
pW     = weak-link fraction
```

## Two calibration conventions

v7.4.3 reports two scores for every ablation:

- `shape`: each ablation is independently recalibrated to the same `R_N`.
  This asks whether `W_ij` topology changes transition/current/field shape
  after trivial resistance-scale differences are removed.
- `conductance`: for each `gammaW`/`pW` family, the full weak-link model is
  calibrated once and that same normal-state scale is then applied unchanged
  to the no-weak, uniform, shuffled, boundary-off, and central-lane ablations.
  This asks what electrical consequence the ablation would have without
  retuning the network conductance inside that family.

## Expected output

The runner writes:

```text
outputs/v7_4_3_as006_wij_ablation
```

Key files:

- `AS006_v7_4_3_wij_ablation_scores.csv`
- `AS006_v7_4_3_wij_ablation_summary.png/.pdf/.fig`
- full `dV/dI(I,B)` maps for the best shape-controlled case;
- full `dV/dI(I,B)` maps for the best conductance-preserving case;
- `AS006_v7_4_3_wij_ablation.mat`

## Caveat

`W_ij` remains a phenomenological transparency field, not a full
phase-dynamical Josephson-junction-array model. True sweep-history hysteresis,
vortex dynamics, and heating remain later tasks.
