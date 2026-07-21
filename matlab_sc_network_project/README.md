# MoTe2 superconducting network MATLAB scaffold

This folder is a first device-spec scaffold built from `Res_Array_1.m`.

The original code modeled a full square resistor array. This version keeps the
same local-link idea,

```text
(Rn, Tc, Ic)
```

but adds the pieces needed for the Chapter 4 MoTe2 Hall-bar devices:

- simplified old/new Hall-bar masks;
- explicit source and drain current-contact regions;
- internal passive voltage-probe regions;
- four-probe resistance extraction;
- four geometry classes: control, full encapsulation, half encapsulation, and cracked full encapsulation;
- AS001--AS006 device specifications with old/new labels;
- region-dependent distributions for `Rn`, `Tc`, `Ic`, residual fraction, and weak/crack links;
- current-biased nonlinear solving based on local branch currents.

## Main entry point

Run:

```matlab
run_six_device_scaffold
```

The script produces geometry/mask plots and first-pass simulated `R(T)` curves
for AS001--AS006. The numbers are intentionally seed distributions, not final
fits.

## Device labels

Figures and code use the thesis-facing labels AS001--AS006.

## Geometry convention used here

The scaffold uses the annotated screenshots as the geometry convention:

- AS001, AS002, AS003, AS004, AS006: new Hall-bar geometry;
- AS005: old Hall-bar geometry;
- new geometry: approximate source-drain span `18 um`, channel width `7 um`, voltage-probe spacing `5 um`, voltage-probe width `0.5 um`;
- old geometry: approximate source-drain span `4 um`, channel width `7 um`, voltage-probe spacing `1.25 um`, voltage-probe width `0.5 um`.

If the text note and screenshot are later reconciled differently, edit only
`make_device_spec.m`.

## Next intended step

Import raw transport data from:

- `/Users/asewaket/Documents/Thesis/Raw Transport Data/2022_8_17_ASD051/data`
- `/Users/asewaket/Documents/Thesis/Raw Transport Data/2023_5_26_ASD087/data`

Then fit ensembles to both absolute `R(T)` and normalized `R(T)/RN`.
