# MoTe2 superconducting-network model v7.6

v7.6 is a scoring and optimization workflow update.  It does not introduce a new superconducting mechanism.  Its purpose is to judge future candidate models more carefully, so a model cannot appear successful merely because it reproduces one global normalized `R(T)` curve.

## Main entry point

Run:

```matlab
run_v76_scoring_workflow_demo
```

This exports a score-component template, a physical-meaningfulness gate table, an ablation `Z`-score template, and a summary figure under:

```text
matlab_v7_6_files/outputs/v7_6_scoring_workflow
```

## Core scoring function

Use:

```matlab
score = compute_v76_multiobservable_score(deviceName, modelRun, expData, opts, modelInfo, nonlinearData);
```

The result contains:

- `score.primary`: weighted `R(T)` chi-square over available probe pairs.
- `score.secondary`: compact transition metrics: onset, low-temperature residual, and breadth.
- `score.asymmetry`: top/bottom probe-pair asymmetry where both pairs are available.
- `score.nonlinear`: optional selected `dV/dI(I)` linecut validation.
- `score.complexity`: parameter count, optional AIC/AICc/BIC bookkeeping, and normalized complexity penalty.
- `score.objectiveScore`: weighted RMS-style aggregate score. Lower is better.

## Primary objective

The primary objective follows:

```text
chi2_RT = sum_{d,p,k} [(R_model(d,p,T_k) - R_exp(d,p,T_k)) / sigma(d,p,T_k)]^2
```

where:

- `d` is device,
- `p` is probe pair,
- `k` is temperature index,
- `sigma` contains a digitization/readout floor plus fractional uncertainty.

By default, v7.6 scores independently normalized `R/RN` curves because most current model figures compare transition shape rather than claiming an independent absolute normal-state resistance prediction.

## Secondary observables

v7.6 adds separate penalties for:

- onset temperature,
- low-temperature residual resistance `R_low/R_N`,
- transition breadth,
- probe-pair asymmetry:

```text
A_probe = |R_4-10 - R_3-9| / ((R_4-10 + R_3-9)/2)
```

These metrics are deliberately reported separately from the primary curve error.

## Nonlinear and magnetic-field data

Selected `dV/dI(I)` linecuts can be included as validation data.  The complete magnetic-field raster is not part of the core objective yet, because the present network does not contain superconducting phase, fluxoid quantization, or vortex dynamics.

Field maps should therefore remain diagnostic plots until a phase-aware Josephson/edge-loop module exists.

## Complexity and ablation significance

v7.6 includes:

- parameter-count bookkeeping,
- optional AIC/AICc/BIC-style terms,
- ablation significance:

```text
Z_ablation = (S_ablation - S_full) / sigma_seed
```

A positive `Z_ablation` means the ablated model is worse than the full model.  A weak-link or Raman contribution should only be interpreted physically when the improvement is larger than seed-to-seed, disorder, and registration uncertainty.

## Interpretation rule

A model addition is scientifically meaningful only if it:

1. improves the multi-observable score across multiple seeds;
2. improves both probe pairs or explains their difference;
3. survives reasonable parameter variation;
4. helps held-out data;
5. exceeds disorder and Raman-registration uncertainty.

This makes v7.6 the optimization “courtroom” for future physics revisions.
