# MATLAB superconducting-network model v7.7

v7.7 is a scoring and evidence-audit layer.  It does not introduce a new
transport mechanism.  Instead, it reads real candidate score tables from the
v7.4.x AS006 sweeps and applies the v7.6 multi-observable logic to rank which
mechanisms are currently most defensible.

## Main entry point

```matlab
cd matlab_v7_7_files
out = run_v77_multiobservable_scoring
```

This is the fast/read-only scoring pass.  It does not rerun the expensive
v7.4.x sweeps; it only scores whatever real candidate ledgers already exist.

The script exports:

- `AS006_v7_7_candidate_scores.csv`
- `AS006_v7_7_mechanism_summary.csv`
- `AS006_v7_7_gate_summary.csv`
- `AS006_v7_7_source_status.csv`
- `v7_7_mechanism_ranking.png`
- `v7_7_mechanism_ranking.fig`

## Optional multi-seed screening

To turn the ranking into a robustness test, run:

```matlab
cd matlab_v7_7_files
seedOut = run_v77_multiseed_screening
out = run_v77_multiobservable_scoring
```

The multi-seed launcher reruns the v7.4.5 and v7.4.6 screening sweeps for the
disorder seeds listed in `make_v77_scoring_options.m`.  It disables the
expensive full 2D magnetic-field map export during these seed sweeps, then
copies the resulting score ledgers into:

```text
matlab_v7_7_files/outputs/v7_7_multiobservable_scoring/seed_ledgers
```

After those seed ledgers exist, `run_v77_multiobservable_scoring` recomputes
the mechanism summary using the true seed-to-seed scatter of the best
within-seed score.  The ablation significance is then reported as

```text
Z_ablation = (S_ablation - S_full) / sigma_seed
```

where `sigma_seed` is the standard deviation across disorder seeds for the
reference full weak-link mechanism.  If fewer than the required number of
seeds are present, v7.7 will still rank mechanisms, but the
`physicalClaimPass` gate remains false.

## What v7.7 scores

The current implementation consumes any available score CSVs from:

- `matlab_v7_4_3_files`
- `matlab_v7_4_4_files`
- `matlab_v7_4_5_files`
- `matlab_v7_4_6_files`

At the moment, the most complete real candidate ledgers are the v7.4.5
physical-bottleneck sweep and the v7.4.6 gap-tied weak-link sweep.  Missing
source tables are recorded in `AS006_v7_7_source_status.csv`; if those older
sweeps are regenerated later, v7.7 will ingest them automatically.

## Interpretation

Lower scores are better.  However, v7.7 separates two levels of language:

1. `screeningPass`: a candidate is numerically competitive among the available
   one-seed candidate ledgers.
2. `physicalClaimPass`: a candidate survives the stricter thesis/journal
   gates, including multi-seed robustness and an ablation-Z significance test.

With only one seed available, the model can rank mechanisms but should not yet
turn a small score improvement into a physical conclusion.

## Probe-aware scoring status

For AS006, v7.7 uses both available probe pairs through the inherited v7.4.x
shape, held-out, and asymmetry columns.  For future AS001--AS005 extensions,
devices with only one recorded probe pair should contribute R(T), onset,
breadth, and residual metrics while explicitly skipping the asymmetry term.
