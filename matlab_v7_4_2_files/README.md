# MoTe2 superconducting network MATLAB scaffold, v7.4.2

v7.4.2 is a focused weak-link ablation sweep for AS006. It is not a new
large physics layer. It asks one practical question:

```text
Which weak-link geometry/strength assumption best reproduces the low-bias
AS006 dV/dI(I,B) feature?
```

Main entry point:

```matlab
run_v742_as006_weaklink_ablation_sweep
```

## What v7.4.2 changes relative to v7.4.1

v7.4.1 showed that making a broad fraction of the network weak only modestly
improved the field score and did not reproduce the narrow low-bias
experimental structure. v7.4.2 therefore compares named weak-link hypotheses:

- broad lane control;
- sparse boundary lane;
- ultra-sparse boundary bottleneck lane;
- compact hotspot bottlenecks;
- contact/stressor-edge bottlenecks;
- mixed sparse lane plus hotspots;
- broad but smoother weak lane.

Each case varies:

```text
weak-link fraction
Ic multiplier
current-switching width
boundary-lane weight
covered/contact-edge weight
hotspot number and radius
current broadening
```

## Scoring

v7.4.2 adds a low-bias-weighted feature score. Lower is better.

The score includes:

- full-map RMS mismatch;
- low-bias map RMS mismatch;
- zero-bias dV/dI(B) mismatch;
- low-bias top/bottom asymmetry mismatch.

This is intentionally different from the v7.3 full-map score because the
visually important failure in v7.3/v7.4.1 was the missing narrow low-bias
current feature, not only the broad field envelope.

## Computational structure

The sweep screens cases on selected magnetic-field slices and then runs the
full v7.4.1-style `I,B` map only for the best case. This is a targeted
ablation design, not a separate quick-mode shortcut.

## Expected output

The runner writes:

```text
outputs/v7_4_2_as006_weaklink_ablation
```

Key files:

- `AS006_v7_4_2_weaklink_ablation_scores.csv`
- `AS006_v7_4_2_weaklink_ablation_summary.png/.pdf/.fig`
- best-case full `dV/dI(I,B)` maps;
- best-case weak-link diagnostic maps;
- `AS006_v7_4_2_weaklink_ablation.mat`

## Caveat

The weak links are still phenomenological current-dependent resistive links,
not a full RCSJ/Josephson-junction-array model with phase dynamics and sweep
history. True hysteresis remains a later v7.5+ task.
