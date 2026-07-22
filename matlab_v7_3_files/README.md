# MoTe2 superconducting network MATLAB scaffold, v7.3

v7.3 adds the first magnetic-field-constrained workflow to the PDE/Raman-
informed superconducting-network model.

The first target is AS006, using the out-of-plane field sweep:

```text
ASD092_dVdIvIvB_0108.dat
columns: Bfield, I, R1, R2
R1 -> top_4_10
R2 -> bottom_3_9
```

Main entry point:

```matlab
run_v73_as006_field_maps
```

## What v7.3 adds

- Experimental `dV/dI(I,B)` import for AS006.
- Out-of-plane magnetic field as an explicit control variable.
- Phenomenological local field response:

```text
Bc2(x,y) = B0 + dB * eta(x,y)
Tc(B)   = Tc(0) * max(floor, 1 - (|B|/Bc2)^alpha)
Ic(B)   = Ic(0) * max(floor, [1 - (|B|/Bc2)^beta]^gamma)
f(B)    = f0 + flux-flow-like finite-resistance contribution
```

- Simulated model `dV/dI(I,B)` maps for top `4-10` and bottom `3-9`.
- Experiment/model/residual field-map figure.
- Zero-bias `dV/dI(B)` comparison.
- Selected current cuts at negative, zero, and positive field.
- Field-score export:
  - full map RMS;
  - zero-bias field-trace RMS;
  - combined top/bottom field score.

## Important caveat

The field model is not yet a microscopic vortex-dynamics or GL/Josephson
calculation. It is a constrained phenomenological extension of the existing
2D resistor-network model. The goal is to test whether adding an explicit
out-of-plane magnetic-field suppression of local superconducting connectivity
improves the measured `dV/dI(I,B)` topology.

## Stand-alone structure

Unlike v7.2.2, v7.3 bundles the v7.1 MATLAB helper functions in `lib_v7_1/`
so the folder can be run from this repository without depending on a separate
local copy of the v7.1 project.
