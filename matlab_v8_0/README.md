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

`run_v800_phase5B2_full_series_activation_consolidation` closes the shared
film-force activation attempt by fitting one coefficient set to the complete
AS002/AS004/AS006 half-encapsulated series. It excludes the crack coefficient
from this half-series analysis and fits only `{lambda_B, q}` for:

```text
lambda_W,d = lambda_B * (abs(F_f,d) / F0)^q
```

Phase 5B.2 reports both the frozen strict 5B.1 held-out result and the
full-series interpretive fit. It also writes a joint comparison against M0,
binary activation, uniform weak links, shuffled weak links, and central-lane
controls; an `AS004` `S(lambda_W)` profile; and seed-wise activation-coefficient
uncertainty intervals. The predeclared stopping rule is that the shared
film-force law is retained only if it beats binary activation, beats protected
alternatives overall, at least two of three strict 5B.1 held-out folds beat
protected controls, and secondary preservation remains intact. If this fails,
the conclusion is limited or mixed transfer rather than another retuning round.

Phase 5B.2 is closed as a mixed/limited transfer result. The force-modulated
law can remain as a descriptive ordering diagnostic, but robust quantitative
transfer is determined by the strict held-out evidence. No additional
film-force-law flexibility should be introduced after this point.

`run_v800_phase5C_synthetic_recovery` starts the revised final validation path:
synthetic mechanism recovery. It generates primary and optional secondary
normalized R(T) curves from known M0, M1, M2, and mixed generators, adds
realistic noise, normalization uncertainty, and disorder, then runs the same
nested M0/M1/M2 scoring procedure without exposing the true label. It writes:

- `phase5C_synthetic_recovery_manifest.csv`;
- `phase5C_label_mapping_policy.csv`;
- `phase5C_synthetic_score_ledger.csv`;
- `phase5C_recovery_matrix.csv`;
- `phase5C_recovery_summary.csv`;
- `phase5C_misspecification_manifest.csv`;
- `phase5C_misspecification_score_ledger.csv`;
- `phase5C_misspecification_summary.csv`;
- `phase5C_misspecification_gate_results.csv`;
- `phase5C_handoff_status.csv`;
- `phase5C_synthetic_recovery_gate_results.csv`.

Phase 5C is the methodological gate for the final hierarchical model. The
real-device classifications should be treated as mechanistically informative
only if the synthetic study shows that the available observables can recover
structured versus unstructured connectivity at an acceptable rate. Primary-only
classifications are explicitly lower-confidence evidence; M1 versus M2 may
remain unresolved even when structured versus M0 is recoverable.

The binary label policy is explicit and shared across exact recovery and gates:
`M0` is unstructured, while `M1`, `M2`, and `mixed` are
structured/intermediate. Phase 5C also includes a compact misspecification
challenge with shifted or broadened M0 curves, extra normal shunt, weak
near-boundary structured activation, probe/registration displacement, and
outside-prior disorder. These misspecified cases primarily test robust
M0-versus-structured discrimination and unresolved near-boundary behavior, not
exact M1-versus-M2 recovery.

Phase 5C should be frozen even when the misspecification robustness gates fail.
That failure is the intended handoff to Phase 5D, not a reason to tune the 5C
classifier against the same challenge cases. The final 5C handoff status is:

```text
in_family_recovery: pass
label_consistency: pass
misspecification_robustness: fail
required_next_phase: uncertainty_and_nuisance_calibration
```

`run_v800_phase5D_calibration_plan` prepares the Phase 5D calibration scope
without changing any Phase 5C result. It writes:

- `phase5D_calibration_scope.csv`;
- `phase5D_M0star_nuisance_family.csv`;
- `phase5D_score_difference_calibration_plan.csv`;
- `phase5D_calibration_validation_split.csv`;
- `phase5D_boundary_strength_sweep_plan.csv`;
- `phase5D_success_criteria.csv`;
- `phase5D_decision_hierarchy.csv`;
- `phase5D_execution_output_schema.csv`;
- `phase5D_source_provenance_checkpoint.csv`;
- `phase5D_phase5C_frozen_handoff_archive.csv`.

Phase 5D must define a nuisance-aware `M0*` envelope, calibrate score
differences rather than only winning labels, and predeclare unresolved
thresholds before evaluating an independent validation set. The current 5C
misspecification set is retained as the diagnostic set that revealed the
calibration problem; it is not the final post-calibration proof set.

The Phase 5D planning checkpoint freezes numeric nuisance bounds before
calibration execution. It also freezes the decision hierarchy:

```text
source validity
structured versus M0*
M1 versus M2 only after structured support
evidence-tier label
```

The execution-output schema is fixed before calibration starts and separates
calibration gates from independent validation gates:

- `phase5D_nuisance_profile_ledger.csv`;
- `phase5D_deltaS_distribution.csv`;
- `phase5D_calibrated_thresholds.csv`;
- `phase5D_boundary_detection_curves.csv`;
- `phase5D_nuisance_boundary_occupancy.csv`;
- `phase5D_calibration_selection_ledger.csv`;
- `phase5D_calibration_gate_results.csv`;
- `phase5D_validation_gate_results.csv`;
- `phase5D_real_device_reclassification.csv`.

`phase5D_source_provenance_checkpoint.csv` records source cleanliness at the
start of the planning run when Phase 5D is run alone. For artifact freezing,
use `run_v800_phase5C_phase5D_artifact_generation`, which captures provenance
once before either Phase 5C or Phase 5D writes output files, verifies that the
session begins from a clean source tree, and writes the shared session snapshot
into both `phase5C_source_provenance_checkpoint.csv` and
`phase5D_source_provenance_checkpoint.csv`.

The provenance checkpoint separates two cleanliness concepts. The
`artifact_session_*` fields describe the source state before the combined
Phase 5C/5D artifact-generation session began:

```text
artifact_session_source_commit_sha
artifact_session_source_tree_sha
artifact_session_pre_run_tracked_clean
artifact_session_pre_run_untracked_clean
artifact_session_pre_run_clean
artifact_session_started_at
```

The `phase5D_entry_*` fields describe the repository state when Phase 5D
itself begins. In a correct combined artifact run, `phase5D_entry_clean` may be
false because Phase 5C regenerated or created outputs earlier in the same
controlled session. That is recorded as phase-entry artifact dirtiness, not as
a failure of the source checkout.

`run_v800_phase5D1_calibrate_m0star` begins Phase 5D execution. It uses only
the frozen calibration seed block `101-160` to build the nuisance-expanded
`M0*` profile grid, compute `Delta S = S_structured - S_M0star`, estimate
`sigmaDeltaS` by case-specific perturbation/resampling without true-label
pooling, jointly select the nuisance-penalty weight and evidence-tier `Zcrit`
thresholds, and write the calibration-only execution artifacts:

- `phase5D_nuisance_profile_ledger.csv`;
- `phase5D_deltaS_distribution.csv`;
- `phase5D_calibrated_thresholds.csv`;
- `phase5D_boundary_detection_curves.csv`;
- `phase5D_nuisance_boundary_occupancy.csv`;
- `phase5D_calibration_selection_ledger.csv`;
- `phase5D_calibration_gate_results.csv`;
- `phase5D_calibration_summary.png`;
- `phase5D_calibration_summary.pdf`.

The Phase 5D.1 refinement keeps the uncertainty rule deployable on real
devices: `sigmaDeltaS` is a robust spread over resampled versions of the same
case, including measurement noise, normalization-window variation,
temperature-offset variation, and probe-registration variation. It is never
pooled by synthetic `true_group`. The calibration search first protects the
false-structured and confident-M0* error constraints, then favors stronger
structured detection and conservative tie-breaking. The original pointwise
two-probe gate is retained as an audit note and replaced by a documented
aggregate two-probe criterion before any validation seeds are used.

Validation seeds `1001-1080` are intentionally not touched by this runner.

`run_v800_phase5D1b_calibration_revision` is the versioned Phase 5D.1b
calibration revision. It preserves the 5D.1a artifacts by writing
`phase5D1b_*` files, keeps the same mechanism classes, and uses only the
calibration seed block. Seeds `101-140` tune nuisance penalties and
evidence-tier thresholds; seeds `141-160` are reserved for an internal
calibration check. It additionally writes:

- `phase5D1b_operating_point_feasibility.csv`;
- `phase5D1b_threshold_ROC_by_evidence_tier.csv`;
- `phase5D1b_sigmaDeltaS_audit.csv`;
- `phase5D1b_uncertainty_component_decomposition.csv`;
- `phase5D1b_nuisance_penalty_sensitivity.csv`;
- `phase5D1b_internal_calibration_check.csv`.

The 5D.1b feasibility table explicitly records whether any threshold can
simultaneously satisfy the false-structured, strong-structured sensitivity,
and weak-structured collapse constraints before moving toward validation.
The observed 5D.1b result is a negative calibration result: no feasible
operating point exists for either primary-only or paired-probe normalized
`R(T)` evidence under the frozen `M0*` nuisance family and predeclared targets.
Phase 5D.1b should therefore be frozen as a scientific stopping point rather
than tuned further.

`phase5D_handoff_status.csv` records the closure policy:

```text
calibration_engine: pass
label_free_sigmaDeltaS: pass
operating_point_analysis: pass
deployable_universal_classifier: fail
phase5D1_closure: pass_as_negative_result
independent_validation: not_run
validation_seeds_consumed: false
next_phase: evidence_synthesis_and_hierarchical_freeze
```

Phase 5D.2 is consequently reinterpreted as a result freeze, not a classifier
freeze. Allowed uses are continuous `DeltaS`/`Z` reporting, uncertainty
visualization, directional preferences, detection-limit discussion, and
evidence-tier qualification. Prohibited uses are universal categorical
classification, interpreting unresolved as M0, claiming structured
connectivity is absent from unresolved cases, or assigning M1/M2 from
normalized `R(T)` alone.

`run_v800_phase5D2_result_freeze` freezes that negative calibration outcome
and writes the evidence-policy and six-device context artifacts:

- `phase5D2_result_freeze_status.csv`;
- `phase5D2_freeze_status.csv`;
- `phase5D2_interpretation_policy.csv`;
- `phase5D2_validation_status.csv`;
- `phase5D2_frozen_input_manifest.csv`;
- `phase5D2_real_device_score_context.csv`;
- `phase5D2_device_evidence_synthesis.csv`;
- `phase5D2_final_gate_summary.csv`;
- `phase5D2_handoff_status.csv`;
- `phase5D2_result_freeze_summary.png`;
- `phase5D2_result_freeze_summary.pdf`.

This runner does not tune `Zcrit`, alter the `M0*` nuisance family, change
penalties, consume validation seeds, or assign automatic categorical labels to
real devices. It records that normalized `R(T)` can provide directional score
context but cannot support a universal nuisance-robust classifier under the
predeclared operating-point targets. The next phase is the hierarchical
six-device model freeze and multi-evidence synthesis.

The real-device score-context table reports `S_M0star`, `S_M1`, `S_M2`,
`DeltaS`, reference `sigmaDeltaS`, and contextual `Z` values from frozen
inputs. These quantities describe directional score preference and detection
limits; they are not validated categorical labels.

`run_v800_phase6_hierarchical_evidence_freeze` starts Phase 6: the
hierarchical six-device evidence and model freeze. It consumes frozen Phase 5A,
5B, 5B.1, 5B.2, 5C, and 5D.2 artifacts and writes:

- `phase6_model_hierarchy_freeze.csv`;
- `phase6_frozen_input_manifest.csv`;
- `phase6_six_device_evidence_matrix.csv`;
- `phase6_device_model_status.csv`;
- `phase6_evidence_tier_assignments.csv`;
- `phase6_claim_hierarchy.csv`;
- `phase6_gate_summary.csv`;
- `phase6_handoff_status.csv`;
- `phase6_hierarchical_evidence_freeze_summary.png`;
- `phase6_hierarchical_evidence_freeze_summary.pdf`.

Phase 6 is not a classifier-calibration or optimization phase. It freezes the
M0*/M1/M2 hierarchy, separates model status from evidence tier, and records
device conclusions as multi-evidence synthesis. The working model statuses are
`M0star_sufficient`, `structured_supported`, and
`mechanistically_unresolved`; evidence tiers include `paired_probe_and_heldout`,
`primary_only`, `control_limit`, `mixed_probe`, and `auxiliary_supported`.
The deferred full-shape `R(T)` classifier remains outside the active roadmap
unless it is explicitly rescoped after the hierarchical freeze.

`run_v800_phase7_raman_mechanical_prior_robustness` starts Phase 7A: the
Raman/mechanical prior robustness audit. It consumes the frozen Phase 6
hierarchy plus the Phase 5 data manifest and writes:

- `phase7_scope_policy.csv`;
- `phase7_frozen_input_manifest.csv`;
- `phase7_prior_evidence_manifest.csv`;
- `phase7_perturbation_scenarios.csv`;
- `phase7_device_prior_robustness.csv`;
- `phase7_gate_summary.csv`;
- `phase7_handoff_status.csv`;
- `phase7_raman_mechanical_prior_robustness_summary.png`;
- `phase7_raman_mechanical_prior_robustness_summary.pdf`.

Phase 7A is not a relabeling phase. It declares Raman registration,
prior-weight, spatial-shuffle, boundary-mask, and crack-mask perturbation
scenarios, then audits which frozen device conclusions depend most strongly on
mechanical or geometry priors. Device statuses remain the Phase 6 statuses:
`M0star_sufficient`, `structured_supported`, or `mechanistically_unresolved`.
No classifier threshold, nuisance bound, weak-link class, or device-specific
parameter may be changed in Phase 7. Quantitative Raman/mechanical rescoring is
deferred to a later Phase 7B only if registered maps and transforms are
available.

`run_v800_phase7B_geometry_mask_robustness` runs the feasible Phase 7B-G
geometry/mechanical-mask robustness layer without requiring a registered Raman
field. It writes:

- `phase7B_frozen_input_manifest.csv`;
- `phase7B_prior_variant_ledger.csv`;
- `phase7B_geometry_mask_sensitivity.csv`;
- `phase7B_crack_mask_sensitivity.csv`;
- `phase7B_raman_registration_sensitivity.csv`;
- `phase7B_shuffled_prior_control.csv`;
- `phase7B_device_robustness_annotations.csv`;
- `phase7B_gate_summary.csv`;
- `phase7B_handoff_status.csv`;
- `phase7B_source_provenance_checkpoint.csv`;
- `phase7B_geometry_mask_robustness_summary.png`;
- `phase7B_geometry_mask_robustness_summary.pdf`.

Phase 7B-G evaluates AS005 crack-mask dependence and AS004/AS006 boundary-prior
sensitivity as robustness annotations only. It also records Raman registration
robustness as `not_run` when registered coordinate transforms are unavailable.
The correct output for a prior-sensitive device is an annotation such as
`high_crack_prior_dependency`, not a rewritten Phase 6 model label. Broad
network mesh convergence, solver tolerances, disorder seeds, normalization
windows, and numerical reproducibility are deferred to Phase 8.

Phase 7B-G closes Phase 7 when no defensible registered Raman transform is
available. The closure policy is:

```text
phase7A_scope_audit = pass
phase7B_geometry_mask_robustness = pass
phase6_labels_preserved = true
classifier_retuning_performed = false
quantitative_raman_prior_rescore = not_run
raman_rescore_reason = no_defensible_registered_spatial_transform
raman_role = qualitative_independent_mechanical_context
phase7_closure = pass_with_registered_raman_unavailable
next_phase = phase8_numerical_robustness
```

The device-level claim impacts are frozen as robustness annotations:

- AS005: structured interpretation is strongly crack-prior dependent; crack-off
  approaches a near-tie.
- AS006: structured interpretation is boundary-prior sensitive but remains
  robust under declared variants.
- AS004: directional preference is boundary-prior sensitive; mechanistic status
  remains unresolved.
- AS001-AS003: no material status sensitivity under declared geometry-prior
  variants.

`run_v800_phase8_numerical_robustness` starts Phase 8A: the numerical and
implementation robustness audit. It consumes frozen Phase 5D.2, Phase 6, and
Phase 7B-G outputs and writes:

- `phase8_scope_policy.csv`;
- `phase8_frozen_input_manifest.csv`;
- `phase8_numerical_test_plan.csv`;
- `phase8_schema_audit.csv`;
- `phase8_reproducibility_audit.csv`;
- `phase8_tolerance_policy.csv`;
- `phase8_implementation_audit.csv`;
- `phase8_gate_summary.csv`;
- `phase8_handoff_status.csv`;
- `phase8_source_provenance_checkpoint.csv`;
- `phase8_numerical_robustness_summary.png`;
- `phase8_numerical_robustness_summary.pdf`.

Phase 8A is a static audit and scope freeze. It checks that frozen inputs are
available, required CSV schemas are intact, source provenance is captured,
Phase 6 labels remain protected, and tolerance policies are explicit. It does
not run expensive mesh, solver-tolerance, normalization-window, or disorder
seed replay. Those checks are declared for Phase 8B and must also preserve the
Phase 6 device labels unless the roadmap is explicitly reopened.

`run_v800_phase8B_numerical_replay` runs Phase 8B: a frozen-context numerical
replay audit. It consumes the Phase 8A tolerance policy and frozen Phase 6 score
context, then writes:

- `phase8B_frozen_input_manifest.csv`;
- `phase8B_mesh_resolution_replay.csv`;
- `phase8B_solver_tolerance_replay.csv`;
- `phase8B_normalization_window_replay.csv`;
- `phase8B_disorder_seed_replay.csv`;
- `phase8B_cached_artifact_replay.csv`;
- `phase8B_status_stability_summary.csv`;
- `phase8B_gate_summary.csv`;
- `phase8B_handoff_status.csv`;
- `phase8B_source_provenance_checkpoint.csv`;
- `phase8B_numerical_replay_summary.png`;
- `phase8B_numerical_replay_summary.pdf`.

Phase 8B is still label-preserving. It reports how frozen contextual `DeltaS`
and `Z` values move under declared mesh, solver, normalization, and seed replay
perturbations. It does not refit candidate mechanisms, change the Phase 6 model
status, or promote contextual replay drift into a new classifier result. Full
v7.4.6 field-map recomputation remains outside Phase 8B unless separately
rescoped.

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
- synthetic mechanism recovery;
- score uncertainty and significance calibration;
- Raman-registration and mesh robustness;
- final hierarchical release manifests and tests.
