# MoTe2 superconducting-network model v8.0 scaffold

v8.0 is the canonical orchestration path for the final validation campaign. It
does not introduce a new physics class. Its first job is to reproduce the
v7.4.6 AS006 gap-tied weak-link result through one stable entry point before
any new fitting, pruning, or six-device calibration begins.

Main entry point:

```matlab
cd matlab_v8_0
out = run_v800_release
```

Phase 3 AS006 evidence campaign:

```matlab
cd matlab_v8_0
out = run_v800_phase3_as006_multiseed
```

Phase 4 identifiability/pruning diagnostics:

```matlab
cd matlab_v8_0
out = run_v800_phase4_identifiability_pruning
```

Phase 5 reduced transfer plan:

```matlab
cd matlab_v8_0
out = run_v800_phase5_transfer_plan
```

## Phase 2 scope

This folder consolidates the model into a release-oriented structure:

```text
config/
  global_physics.yaml
  scoring.yaml
  devices/AS006.yaml
+v800/
  canonical wrappers and manifest helpers
geometry/
priors/
network/
solver/
scoring/
validation/
figures/
tests/
outputs/
```

The current v8 wrappers call the v7.4.6 physics implementation rather than
copying it. That is intentional. The v7.4.6 solver is the current canonical
physics engine; v8 adds a single orchestration layer and a manifest discipline
around it.

## Reproduction gate

The first gate is:

```text
Existing AS006 v7.4.6 outputs must be reproducible within numerical tolerance.
```

`run_v800_release` runs the v7.4.6 AS006 screening path with a v8 output suffix,
copies the generated score ledger into `matlab_v8_0/outputs`, compares it with
the reference v7.4.6 score ledger when available, and writes a run manifest.

No new fitting should begin until this gate passes.

## Phase 3 AS006 multi-seed campaign

`run_v800_phase3_as006_multiseed` keeps the v7.4.6 gap-tied weak-link
physics path and executes the frozen 10-seed AS006 campaign:

```text
seeds = [101 202 303 404 505 606 707 808 909 1010]
alpha_gap = [3.3 3.7 4.1]
gammaW = [0.05 0.10 0.20 0.40 0.70]
pW = [0.05 0.10 0.20 0.30]
```

Full 121-by-121 field maps remain off during this evidence pass.  The campaign
writes one seed ledger per run, then aggregates mechanism statistics:

- mean, median, standard deviation, IQR, and rank distribution;
- probability of beating no-weak-link and central-lane baselines;
- ablation `Z` relative to seed scatter;
- probe-asymmetry survival;
- consistency under shape and conductance calibration modes;
- parameter-basin occupancy.

The AS006 mechanism advances only if it passes the frozen stop/go gates in
`+v800/phase3_config.m`.

## Phase 4 identifiability and pruning

`run_v800_phase4_identifiability_pruning` reads Phase 3 seed ledgers and writes
diagnostic tables for mechanism identifiability, parameter-basin occupancy, and
pruning recommendations. It does not rerun Phase 3 or alter the active seed
campaign. If fewer than 10 seeds are available, all non-control decisions are
explicitly marked provisional.

Required controls are protected from pruning:

- no weak links;
- uniform weak links;
- shuffled weak links;
- central-lane / 1D-like.

Phase 4 outputs are written to
`outputs/v8_0_phase4_identifiability_pruning`.

## Phase 5 reduced transfer plan

`run_v800_phase5_transfer_plan` prepares the six-device transfer campaign
without launching expensive simulations. It consumes Phase 4 pruning decisions
and writes:

- the reduced transfer-primary mechanism set;
- required controls and diagnostic holds;
- the AS001-AS006 validation plan;
- validation gates for leave-one-device-out and shared-rule transfer.

The transfer-primary AS006 set is:

- combined physical bottleneck;
- contact-relaxed weak links;
- crack/tunnel-like weak links.

Boundary/SNS-inspired constriction is kept only as a diagnostic hold unless a
later validation phase promotes it.

## Canonical boundaries

The scientific scope is frozen by the repository-level `MODEL_SCOPE.md`.
Development after this point should be validation, reduction, and
reproducibility work:

- AS006 multi-seed campaign;
- parameter identifiability and pruning;
- fixed train/validation manifests;
- six-device hierarchy;
- leave-one-device-out validation;
- Raman-registration and mesh robustness;
- final release manifests and tests.
