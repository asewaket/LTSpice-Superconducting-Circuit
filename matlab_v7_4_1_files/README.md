# MoTe2 superconducting network MATLAB scaffold, v7.4.1

v7.4.1 extends the AS006 out-of-plane-field scaffold by adding a stronger
weak-link / Josephson-like bottleneck layer.

The first target remains AS006 because it has both experimental voltage-pair
channels in the available field data:

```text
ASD092_dVdIvIvB_0108.dat
columns: Bfield, I, R1, R2
R1 -> top_4_10
R2 -> bottom_3_9
```

Main entry point:

```matlab
run_v741_as006_weaklink_field_maps
```

## What v7.4.1 adds relative to v7.3

- A selected subset of links is converted into coarse Josephson-like
  bottlenecks.
- Those links have much lower local critical current `Ic`.
- Those links switch more sharply with branch current through a smaller
  `dI/Ic` width.
- The weak links have modestly enhanced `Rn` and reduced residual
  superconducting floor.
- The weak-link selection is spatially biased toward the stressor boundary,
  local PDE/Raman proxy maxima, and a few deterministic random hotspots.
- The output includes a weak-link diagnostic figure showing:
  - the PDE/Raman network proxy;
  - the selected weak-link incidence map;
  - the weak-link selection score;
  - post-weak-link `Ic`;
  - current-switching width.

## Important caveat

This is not yet a full Josephson-junction array or RCSJ model. The current
implementation is still a resistor-network solve with current-dependent link
resistance,

```text
R_link(T,I,B) = Rfloor + Rn * [ f + (1 - f) * S(T,I,B) ],
```

where weak links have smaller `Ic` and a sharper current-switching sigmoid.
True hysteresis requires explicitly sweeping current upward and downward with
state memory/retrapping; the current v7.4.1 map uses the imported rectangular
`I,B` grid and therefore does not assume a sweep direction.

## Expected output

The runner writes figures, CSV, PDF, PNG, and MAT files to:

```text
outputs/v7_4_1_as006_weaklink_field_maps
```

The key question is whether the weak-link layer produces a more realistic
low-bias current nonlinearity in `dV/dI(I,B)` than v7.3, which had field
suppression but too little current-selective switching.

## Stand-alone structure

As in v7.3, the folder bundles the v7.1 MATLAB helper functions in
`lib_v7_1/` so it can be run from this repository without depending on a
separate local copy of the v7.1 project.
