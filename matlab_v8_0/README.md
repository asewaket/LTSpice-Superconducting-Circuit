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

Phase 5 transfer campaign report:

```matlab
cd matlab_v8_0
out = run_v800_phase5_transfer_campaign
```

When additional devices have mapped dV/dI(I,B) field files, fresh v7.4.6
reduced sweeps can be requested with:

```matlab
out = run_v800_phase5_transfer_campaign(true)
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

`run_v800_phase5_transfer_campaign` now defaults to the Phase 5A frozen-basin
primary R(T) transfer campaign. It writes `phase5_rt_manifest.csv` as the
primary/secondary-probe authority, `phase5_frozen_basin_set.csv` as the frozen
AS006 Phase 4 basin set, and `phase5_frozen_transfer_ledger.csv` as the
solver-generated Level A evidence table. The same path is available explicitly
as `run_v800_phase5A_frozen_rt_transfer`.

Phase 5A scores only declared primary R(T) curves:

- AS001 top_4_10 / R1;
- AS002 top_4_10 / R1;
- AS003 bottom_3_9 / R2;
- AS004 top_4_10 / R1;
- AS005 top_4_10 / R1;
- AS006 top_4_10 / R1.

Level A uses the curated publication `main_4p` R(T) curve as the common
six-device evidence layer and maps it to the declared primary probe. Explicit
top/bottom pair traces are reserved for Level B, except as a fallback when a
publication curve is unavailable. Secondary probes are held out for Level B.
Missing field maps are Level C availability notes, not exclusions from Level A
transfer.

`run_v800_phase5B_secondary_validation` freezes the Phase 5A artifacts and
tests the two-regime interpretation with held-out secondary probes. It does not
change Level A weights, primary probes, protected controls, or AS006 frozen
basins. It writes:

- `phase5B_frozen_phase5A_archive.csv`;
- `phase5B_secondary_probe_manifest.csv`;
- `phase5B_secondary_probe_ledger.csv`;
- `phase5B_device_evidence_table.csv`;
- `phase5B_class_heldout_validation.csv`;
- `phase5B_activation_law_plan.csv`;
- `phase5B_hierarchical_gate_results.csv`.

Phase 5B compares nested levels M0/M1/M2 with a small complexity penalty:
M0 is local-Tc/control-like, M1 is geometry-activated boundary/contact/crack
connectivity, and M2 is the full combined bottleneck. The goal is to test
whether AS001-AS003 reduce to a local-Tc/control-like regime while AS004-AS006
retain connectivity support on independent probe evidence.

Held-out validation is strict after Phase 5A regeneration: training selects the
model level, mechanism, and exact `caseName` parameter tuple, then the withheld
device is evaluated on that same tuple across the common Phase 3 seed list.

`run_v800_phase5B1_activation_law_validation` is the next nested validation
layer. It archives the current Phase 5A/5B baseline, then tests two compact
global weak-link activation laws for the half-encapsulated AS002/AS004/AS006
series:

- binary geometry activation, `lambda_W = lambda_B B_d + lambda_C C_d`;
- force-modulated activation,
  `lambda_W = clip(lambda_B B_d (abs(F_f,d)/F0)^q + lambda_C C_d)`.

The bounds are frozen in `+v800/phase5_config.m`: `0 <= lambda_B <= 1`,
`0 <= lambda_C <= 1`, `0.5 <= q <= 3`, and `F0 = 40 N/m`. Phase 5B.1 does not
fit per-device `lambda_W` values. It uses the frozen Level-A solver ledger as a
response surface, with local M0 rows at `lambda_W = 0` and solved weak-link rows
as nonzero-amplitude anchors. This is a compact activation-law validation layer,
not a retrospective rewrite of Phase 5B.

The v7.4.6 field-map scorer currently has mapped dV/dI(I,B) data only for
AS006. Missing field maps are therefore Level C availability notes, not
exclusions from Level A transfer. Probe/asymmetry and nonlinear gates remain
incomplete until Level B/C scorers are activated with mapped data.

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
