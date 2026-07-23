# MoTe2 superconducting network MATLAB scaffold, v7.4.6

v7.4.6 is the first gap-tied weak-link scaffold for AS006.  It keeps the
v7.4.5 controlled topology logic, but stops treating critical current as an
independent empirical field in the tested weak-link cases.

Main entry point:

```matlab
run_v746_as006_gap_weaklink_sweep
```

## Physical change relative to v7.4.5

v7.4.5 varied a weak-link transparency field `W_ij` and applied it directly
to `Rn` and `Ic`.  v7.4.6 instead computes the link critical-current scale
from the local transition field and link resistance:

```text
Delta_0,ij = 0.5 * alpha_gap * k_B * Tc,ij
Ic,ij(0)   = pi * Delta_0,ij / (2 e Rn,ij)
```

The sweep uses the prior-like range

```text
2 Delta / k_B Tc = alpha_gap = 3.7 +/- 0.4
```

as `alpha_gap = [3.3, 3.7, 4.1]`.  This is a controlled modeling prior, not a
claim that the local MoTe2 gap has been independently measured.

Weak-link transparency still enters through conductance:

```text
Rn,ij -> Rn,ij / W_ij
```

so weak links automatically acquire smaller AB-like `Ic` because their
effective normal resistance is larger.  The model also includes a normalized
class-dependent temperature factor `F_k(T/Tc)` for SNS/constriction,
contact-relaxed, anisotropic, and crack/tunnel-like links.

## Cases

The cases are deliberately compact:

- `bulk_AB_reference`: no weak-link mask; gap-derived AB-like critical current;
- `boundary_sns_*`: weak constrictions near the encapsulation boundary;
- `contact_relaxed_*`: contact-relaxation halos around voltage probes/contacts;
- `crack_tunnel_*`: sharper crack/tunnel-like weak links;
- `combined_*`: combined boundary/contact/current-crowding/tear/hotspot score;
- `uniform_tau_control`: same mean weak transparency, no spatial topology;
- `shuffled_tau_control`: same weak-link histogram, randomized locations;
- `central_lane_gap_control`: keeps local transition scales but removes lateral
  bypass paths;
- `anisotropic_gap_control`: direction-dependent weak-link transparency.

Only three compact quantities are swept:

```text
alpha_gap
gammaW = G_weak / G_bulk
pW     = weak-link fraction
```

## Two calibration conventions

Every case is reported twice:

- `shape`: independently recalibrates the case to the same normal-state
  resistance.  This isolates normalized transition/field/current shape.
- `conductance`: calibrates the matched combined case once and applies that
  normal-state scale unchanged to the ablation.  This exposes the absolute
  conductance consequence of changing/removing weak-link topology.

## Runtime behavior

By default, v7.4.6 only performs the screening sweep:

```matlab
opts.runFullFieldMaps = false;
```

This avoids accidental multi-hour full-map runs.  Set that option to `true` in
`make_v746_gap_weaklink_options.m` only when you want full `dV/dI(I,B)` maps
for the best shape-controlled and conductance-preserving cases.

## Outputs

The runner writes:

```text
outputs/v7_4_6_as006_gap_weaklink
```

Key files:

- `AS006_v7_4_6_gap_weaklink_scores.csv`
- `AS006_v7_4_6_gap_weaklink_summary.png/.pdf/.fig`
- optional full field maps for the best cases;
- `AS006_v7_4_6_gap_weaklink.mat`

## Caveat

This is still not a full phase-dynamical Josephson-junction-array model.  The
current switching remains sigmoid-like around the gap-derived `Ic`; sweep
history, vortex dynamics, heating, and time-dependent Josephson phase dynamics
remain later tasks.
