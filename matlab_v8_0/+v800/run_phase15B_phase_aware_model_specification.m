function out = run_phase15B_phase_aware_model_specification(cfg)
%RUN_PHASE15B_PHASE_AWARE_MODEL_SPECIFICATION Freeze Phase 15B model spec.
%
% Phase 15B introduces the smallest phase-aware field-response model class
% needed for later AS006 dV/dI(I,B) testing. It is a specification freeze:
% it consumes the Phase 15A raw-data lock but does not inspect AS006
% residual improvement, fit oscillation periods, retune Phase 14 results, or
% encode any topological interpretation.

if ~exist(cfg.outputDir, 'dir')
    mkdir(cfg.outputDir);
end

inputs = load_inputs(cfg);
sourceProvenance = build_source_provenance(cfg);
phaseModelSpec = build_phase_model_specification(cfg, inputs);
modelVariantLedger = build_model_variant_ledger();
phaseLinkEquations = build_phase_link_equations();
loopGeometryManifest = build_loop_geometry_manifest(inputs);
effectiveAreaPrior = build_effective_area_prior();
fieldSuppressionSpec = build_field_suppression_specification();
parameterRoleLedger = build_parameter_role_ledger();
prohibitedFlexibilityLedger = build_prohibited_flexibility_ledger();
validationHoldoutPlan = build_validation_holdout_plan();
syntheticTestPlan = build_synthetic_test_plan();
gateSummary = build_gate_summary(cfg, inputs, phaseModelSpec, ...
    modelVariantLedger, phaseLinkEquations, loopGeometryManifest, ...
    fieldSuppressionSpec, parameterRoleLedger, ...
    prohibitedFlexibilityLedger, validationHoldoutPlan, syntheticTestPlan, ...
    sourceProvenance);
handoffStatus = build_handoff_status(cfg, gateSummary, inputs, ...
    sourceProvenance);

writetable(phaseModelSpec, cfg.phase15B.phaseModelSpecificationFile);
writetable(modelVariantLedger, cfg.phase15B.modelVariantLedgerFile);
writetable(phaseLinkEquations, cfg.phase15B.phaseLinkEquationsFile);
writetable(loopGeometryManifest, cfg.phase15B.loopGeometryManifestFile);
writetable(effectiveAreaPrior, cfg.phase15B.effectiveAreaPriorFile);
writetable(fieldSuppressionSpec, ...
    cfg.phase15B.fieldSuppressionSpecificationFile);
writetable(parameterRoleLedger, cfg.phase15B.parameterRoleLedgerFile);
writetable(prohibitedFlexibilityLedger, ...
    cfg.phase15B.prohibitedFlexibilityLedgerFile);
writetable(validationHoldoutPlan, cfg.phase15B.validationHoldoutPlanFile);
writetable(syntheticTestPlan, cfg.phase15B.syntheticTestPlanFile);
writetable(gateSummary, cfg.phase15B.gateSummaryFile);
writetable(handoffStatus, cfg.phase15B.handoffStatusFile);
writetable(sourceProvenance, cfg.phase15B.sourceProvenanceFile);

try
    h = v800.plot_phase15B_phase_aware_model_specification_summary(cfg, ...
        modelVariantLedger, parameterRoleLedger, ...
        prohibitedFlexibilityLedger, validationHoldoutPlan, ...
        syntheticTestPlan, gateSummary);
catch ME
    warning('v8:phase15BPlotFailed', ...
        'Phase 15B summary plot failed: %s', ME.message);
    h = [];
end

out = struct();
out.config = cfg;
out.phaseModelSpecification = phaseModelSpec;
out.modelVariantLedger = modelVariantLedger;
out.phaseLinkEquations = phaseLinkEquations;
out.loopGeometryManifest = loopGeometryManifest;
out.effectiveAreaPrior = effectiveAreaPrior;
out.fieldSuppressionSpecification = fieldSuppressionSpec;
out.parameterRoleLedger = parameterRoleLedger;
out.prohibitedFlexibilityLedger = prohibitedFlexibilityLedger;
out.validationHoldoutPlan = validationHoldoutPlan;
out.syntheticTestPlan = syntheticTestPlan;
out.gateSummary = gateSummary;
out.handoffStatus = handoffStatus;
out.sourceProvenance = sourceProvenance;
out.figure = h;
out.paths = build_paths(cfg);
end

function paths = build_paths(cfg)
paths = struct();
paths.phaseModelSpecification = cfg.phase15B.phaseModelSpecificationFile;
paths.modelVariantLedger = cfg.phase15B.modelVariantLedgerFile;
paths.phaseLinkEquations = cfg.phase15B.phaseLinkEquationsFile;
paths.loopGeometryManifest = cfg.phase15B.loopGeometryManifestFile;
paths.effectiveAreaPrior = cfg.phase15B.effectiveAreaPriorFile;
paths.fieldSuppressionSpecification = ...
    cfg.phase15B.fieldSuppressionSpecificationFile;
paths.parameterRoleLedger = cfg.phase15B.parameterRoleLedgerFile;
paths.prohibitedFlexibilityLedger = ...
    cfg.phase15B.prohibitedFlexibilityLedgerFile;
paths.validationHoldoutPlan = cfg.phase15B.validationHoldoutPlanFile;
paths.syntheticTestPlan = cfg.phase15B.syntheticTestPlanFile;
paths.gateSummary = cfg.phase15B.gateSummaryFile;
paths.handoffStatus = cfg.phase15B.handoffStatusFile;
paths.sourceProvenance = cfg.phase15B.sourceProvenanceFile;
paths.figurePng = [cfg.phase15B.figureBaseFile '.png'];
paths.figurePdf = [cfg.phase15B.figureBaseFile '.pdf'];
end

function inputs = load_inputs(cfg)
inputs = struct();
inputs.phase15ARawSourceLock = read_required_table( ...
    cfg.phase15A.rawFieldSourceLockFile, ...
    "Phase 15A raw-source lock");
inputs.phase15AAxisMetadataLock = read_required_table( ...
    cfg.phase15A.axisMetadataLockFile, ...
    "Phase 15A axis-metadata lock");
inputs.phase15AChannelLock = read_required_table( ...
    cfg.phase15A.channelLockFile, ...
    "Phase 15A channel lock");
inputs.phase15ASweepHistoryAudit = read_required_table( ...
    cfg.phase15A.sweepHistoryAuditFile, ...
    "Phase 15A sweep-history audit");
inputs.phase15AHandoffStatus = read_required_table( ...
    cfg.phase15A.handoffStatusFile, ...
    "Phase 15A handoff status");
end

function T = read_required_table(pathValue, label)
if exist(char(pathValue), 'file') ~= 2
    error('v800:phase15BMissingInput', ...
        'Required %s is missing:\n%s', label, char(pathValue));
end
opts = detectImportOptions(char(pathValue), 'FileType', 'text');
try
    opts.VariableNamingRule = 'preserve';
catch
end
T = readtable(char(pathValue), opts);
end

function provenance = build_source_provenance(cfg)
sourceStatus = v800.git_tree_status(cfg.repoRoot);
phase15AReachable = git_commit_is_ancestor(cfg.repoRoot, ...
    cfg.phase15B.frozenPhase15AArtifactCommit);
item = [
    "phase";
    "source_commit_sha";
    "source_tree_sha";
    "source_pre_run_tracked_clean";
    "source_pre_run_untracked_clean";
    "source_pre_run_clean";
    "frozen_phase15A_artifact_commit";
    "frozen_phase15A_artifact_commit_reachable";
    "provenance_scope";
    ];
value = [
    "phase15B_phase_aware_model_specification";
    sourceStatus.commit_sha;
    sourceStatus.tree_sha;
    string(sourceStatus.tracked_clean);
    string(sourceStatus.untracked_clean);
    string(sourceStatus.tracked_clean && sourceStatus.untracked_clean);
    string(cfg.phase15B.frozenPhase15AArtifactCommit);
    string(phase15AReachable);
    "model_specification_freeze_no_raw_residual_fit";
    ];
note = [
    "Minimal phase-aware field-response model specification phase.";
    "Git commit captured before this runner writes outputs.";
    "Git tree object captured before this runner writes outputs.";
    "Tracked-source cleanliness before output generation.";
    "Untracked-source/artifact cleanliness before output generation.";
    "True only when checkout is clean before Phase 15B writes outputs.";
    "Canonical Phase 15A artifact-freeze commit consumed as handoff.";
    "True when the Phase 15A artifact commit is an ancestor of this run.";
    "No AS006 residual improvement, period fit, or topology claim is used.";
    ];
provenance = table(item, value, note);
end

function tf = git_commit_is_ancestor(repoRoot, commitish)
cmd = sprintf('git -C "%s" merge-base --is-ancestor "%s" HEAD', ...
    repoRoot, commitish);
[status, ~] = system(cmd);
tf = status == 0;
end

function T = build_phase_model_specification(cfg, inputs)
item = [
    "phase15B_closure_target";
    "inherited_equilibrium_baseline";
    "inherited_current_switching_baseline";
    "model_hierarchy";
    "phase_model_type";
    "link_law";
    "voltage_relation";
    "gauge_invariant_phase";
    "loop_constraint";
    "field_suppression_policy";
    "shared_quantitative_RT_predictor";
    "shared_raw_nonlinear_predictor";
    "raw_AS006_residuals_used";
    "manual_period_fit";
    "topological_term_used";
    "thermal_feedback_used";
    ];
value = [
    "pass_minimal_phase_aware_model_freeze";
    string(cfg.phase15B.inheritedEquilibriumBaseline);
    string(cfg.phase15B.inheritedCurrentSwitchingBaseline);
    "FB_to_NI_to_Pphi";
    "overdamped_resistively_shunted_josephson_link_network";
    "Iij=Icij*sin(phiij)+Vij/Rij";
    "Vij=(Phi0/2pi)*dphiij_dt";
    "phiij=theta_i-theta_j-(2pi/Phi0)*line_integral_A_dot_dl";
    "sum_loop_phiij=2pi*n-2pi*Phi_loop/Phi0";
    "monotonic_field_suppression_separate_from_phase_interference";
    string(cfg.phase15B.sharedQuantitativeRTPredictor);
    string(cfg.phase15B.sharedRawNonlinearPredictor);
    string(cfg.phase15B.rawAS006ResidualsUsed);
    string(cfg.phase15B.manualPeriodFit);
    string(cfg.phase15B.topologicalTermUsed);
    string(cfg.phase15B.thermalFeedbackUsed);
    ];
note = [
    "The phase closes as a specification freeze, not a raw-map fit.";
    "Phase 13F.4 preferred equilibrium baseline is inherited unchanged.";
    "Phase 14 current-switching layer is inherited unchanged.";
    "Phase-aware terms are an added field-response layer only.";
    "Smallest model class able to produce loop interference.";
    "A sinusoidal final-map correction is explicitly avoided.";
    "Voltage is tied to phase evolution through the Josephson relation.";
    "Magnetic field enters through vector-potential line integrals.";
    "Closed-loop constraints control interference.";
    "Ordinary critical-current suppression is not treated as oscillation.";
    "Phase 15B cannot repair the Phase 13 R(T) limitation.";
    "Phase 15B cannot repair the Phase 14 raw nonlinear limitation.";
    "Raw residuals are reserved for Phase 15D.";
    "Oscillation period is not manually fit in Phase 15B.";
    "Topological superconductivity is outside the model claim.";
    "Thermal feedback remains blocked by Phase 14D sweep metadata limits.";
    ];

axisLock = inputs.phase15AAxisMetadataLock;
T = table(item, value, note);
T.phase15A_current_points = repmat(axisLock.current_point_count(1), ...
    height(T), 1);
T.phase15A_field_points = repmat(axisLock.field_point_count(1), ...
    height(T), 1);
T.phase15A_temperature_K = repmat(axisLock.assumed_temperature_K(1), ...
    height(T), 1);
end

function T = build_model_variant_ledger()
variant = [
    "P0";
    "PB";
    "Pphi";
    ];
definition = [
    "NI_current_switching_no_magnetic_phase_no_oscillatory_response";
    "NI_plus_monotonic_field_suppression_no_phase_interference";
    "NI_plus_monotonic_field_suppression_and_phase_aware_loop_interference";
    ];
oscillatory_response_allowed = [false; false; true];
phase_solver_required = [false; false; true];
field_suppression_included = [false; true; true];
role = [
    "baseline_current_only_field_independent_reference";
    "ordinary_noninterference_field_response_control";
    "minimal_phase_interference_candidate";
    ];
T = table(variant, definition, oscillatory_response_allowed, ...
    phase_solver_required, field_suppression_included, role);
end

function T = build_phase_link_equations()
equation_id = [
    "current_phase_link_law";
    "josephson_voltage_relation";
    "gauge_invariant_phase_difference";
    "closed_loop_phase_constraint";
    "flux_area_relation";
    ];
expression = [
    "Iij=Icij*sin(phiij)+Vij/Rij";
    "Vij=(Phi0/2pi)*dphiij_dt";
    "phiij=theta_i-theta_j-(2pi/Phi0)*integral_i_to_j_A_dot_dl";
    "sum_loop_phiij=2pi*n-2pi*Phi_loop/Phi0";
    "Phi_loop=B*Aeff_loop";
    ];
purpose = [
    "Define overdamped Josephson-like weak-link current.";
    "Tie voltage to phase evolution.";
    "Make field coupling gauge-invariant.";
    "Generate loop interference without manual period fitting.";
    "Connect field axis to geometry-derived loop flux.";
    ];
status = repmat("frozen_for_phase15C_implementation", 5, 1);
T = table(equation_id, expression, purpose, status);
end

function T = build_loop_geometry_manifest(inputs)
axisLock = inputs.phase15AAxisMetadataLock;
loop_family = [
    "network_plaquette_boundary_corridor";
    "two_path_half_coverage_boundary";
    "crack_boundary_hybrid_candidate";
    ];
selection_rule = [
    "plaquettes_or_connected_paths_near_phase12B_boundary_corridor";
    "paired_paths_between_fixed_probe_regions_across_coverage_boundary";
    "candidate_paths_allowed_only_if_defined_by_frozen_geometry_or_crack_mask";
    ];
allowed_source = [
    "Phase12B_boundary_corridor_and_Hall_bar_geometry";
    "fixed_probe_locations_and_measured_device_dimensions";
    "frozen_crack_boundary_annotations";
    ];
manual_period_fit_allowed = [false; false; false];
residual_lookahead_allowed = [false; false; false];
phase15A_field_span_T = repmat(axisLock.field_max_T(1) - ...
    axisLock.field_min_T(1), 3, 1);
status = repmat("predeclared_geometry_rule", 3, 1);
T = table(loop_family, selection_rule, allowed_source, ...
    manual_period_fit_allowed, residual_lookahead_allowed, ...
    phase15A_field_span_T, status);
end

function T = build_effective_area_prior()
area_component = [
    "geometry_derived_effective_area";
    "shared_effective_area_uncertainty_scale";
    "global_field_origin_correction";
    ];
role = [
    "primary_loop_flux_scale_from_geometry";
    "shared_uncertainty_interval_not_feature_specific";
    "allowed_only_with_independent_magnet_calibration";
    ];
allowed = [true; true; false];
free_per_feature = [false; false; false];
freeze_timing = [
    "before_phase15D_residual_comparison";
    "before_phase15D_residual_comparison";
    "blocked_unless_independently_justified_before_residual_comparison";
    ];
T = table(area_component, role, allowed, free_per_feature, freeze_timing);
end

function T = build_field_suppression_specification()
component = [
    "PB_monotonic_field_suppression";
    "Pphi_phase_interference";
    "oscillatory_envelope_without_phase";
    ];
expression = [
    "Icij(B)=Icij(0)*fB(B)";
    "loop_response_depends_on_Phi_loop_over_Phi0";
    "prohibited";
    ];
oscillatory = [false; true; false];
purpose = [
    "Control for ordinary noninterference field suppression.";
    "Generate oscillations only through gauge-invariant loop phase.";
    "Prevent final-map sinusoidal correction from masquerading as phase.";
    ];
status = [
    "allowed";
    "allowed_only_in_Pphi";
    "prohibited";
    ];
T = table(component, expression, oscillatory, purpose, status);
end

function T = build_parameter_role_ledger()
parameter = [
    "shared_zero_field_Ic_scale";
    "shared_field_suppression_scale";
    "shared_phase_damping";
    "shared_loop_inductance_or_zero_inductance_choice";
    "geometry_derived_effective_area";
    "shared_effective_area_uncertainty_scale";
    "shared_phase_solver_tolerance";
    ];
role = [
    "global_current_switching_scale_inherited_from_NI";
    "global_monotonic_field_suppression_strength";
    "global_overdamped_phase_solver_regularization";
    "predeclared_solver_assumption";
    "loop_flux_scale_from_geometry";
    "shared_area_uncertainty_not_feature_specific";
    "numerical_convergence_control";
    ];
scope = [
    "shared";
    "shared";
    "shared";
    "shared_choice";
    "geometry_derived";
    "shared";
    "solver_only";
    ];
allowed_to_fit_AS006_residuals_in_phase15B = false(7, 1);
T = table(parameter, role, scope, ...
    allowed_to_fit_AS006_residuals_in_phase15B);
end

function T = build_prohibited_flexibility_ledger()
blocked_item = [
    "manual_oscillation_period";
    "manual_field_axis_shift";
    "independent_period_per_channel";
    "independent_loop_area_per_feature";
    "topological_edge_term";
    "device_specific_phase_offset_fit";
    "manual_branch_selection";
    "hysteresis_fit_from_single_branch_data";
    "thermal_feedback";
    "Raman_target_use";
    "Phase6_label_target_use";
    ];
reason = [
    "Would tune the answer to observed oscillations.";
    "Requires independent magnet calibration before residual inspection.";
    "R1/R2 must share one underlying phase state.";
    "Feature-by-feature areas would destroy geometry constraint.";
    "Topological claims are explicitly excluded.";
    "AS006-only offsets would be unconstrained flexibility.";
    "Sweep branches are unavailable in Phase 15A raw lock.";
    "Single-branch data cannot validate hysteresis.";
    "Phase 14D found thermal feedback unidentifiable from available grids.";
    "Raman cannot be used as a target for field-period fitting.";
    "Frozen Phase 6 labels cannot train the field model.";
    ];
status = repmat("prohibited", 11, 1);
T = table(blocked_item, status, reason);
end

function T = build_validation_holdout_plan()
holdout_id = [
    "central_field_train_outer_field_holdout";
    "alternate_field_window_holdout";
    "low_current_train_high_current_holdout";
    "R1_train_R2_joint_prediction";
    "positive_field_train_negative_field_assessment";
    ];
calibration_region = [
    "central_B_window";
    "interleaved_B_windows_A";
    "low_abs_current_region";
    "R1_channel_with_shared_phase_state";
    "positive_B_window";
    ];
heldout_region = [
    "outer_B_window";
    "interleaved_B_windows_B";
    "higher_abs_current_region";
    "R2_channel_from_same_phase_solution";
    "negative_B_window_if_symmetry_assumption_declared";
    ];
purpose = [
    "Assess extrapolation of field structure.";
    "Reduce single-device overfitting risk.";
    "Test current-envelope transfer.";
    "Prevent independent channel-specific loop periods.";
    "Test expected field symmetry when applicable.";
    ];
status = repmat("predeclared_for_phase15D", 5, 1);
T = table(holdout_id, calibration_region, heldout_region, purpose, status);
end

function T = build_synthetic_test_plan()
test_id = [
    "single_josephson_link_zero_field";
    "two_path_interference";
    "flux_quantum_periodicity";
    "effective_area_scaling";
    "positive_negative_field_symmetry";
    "zero_field_recovery_of_NI";
    "PB_monotonic_envelope_no_phase_oscillation";
    "Pphi_oscillation_only_from_loop_phase";
    "phase_solver_convergence";
    "no_artificial_grid_interpolation_oscillation";
    ];
requirement = [
    "Recover current-switching behavior at B=0.";
    "Produce SQUID-like interference in a two-path synthetic loop.";
    "Recover periodicity in Phi/Phi0.";
    "Show period scales inversely with effective area.";
    "Recover symmetry when geometry and envelope are symmetric.";
    "Pphi must reduce to NI at zero field without phase frustration.";
    "PB may suppress Ic but must not oscillate.";
    "Oscillations must be absent unless loop phase is active.";
    "Solver converges across flux-state choices.";
    "Interpolation alone cannot generate periodic structure.";
    ];
status = repmat("required_before_phase15D", 10, 1);
T = table(test_id, requirement, status);
end

function gates = build_gate_summary(cfg, inputs, phaseModelSpec, ...
    modelVariantLedger, phaseLinkEquations, loopGeometryManifest, ...
    fieldSuppressionSpec, parameterRoleLedger, prohibitedFlexibilityLedger, ...
    validationHoldoutPlan, syntheticTestPlan, sourceProvenance)

phase15AConsumed = lookup_status(inputs.phase15AHandoffStatus, ...
    "phase15A_closure") == "pass_as006_field_observable_lock";
phase15AReachable = lookup_provenance(sourceProvenance, ...
    "frozen_phase15A_artifact_commit_reachable") == "true";
inheritancePreserved = has_spec_value(phaseModelSpec, ...
    "inherited_equilibrium_baseline", "FB") && ...
    has_spec_value(phaseModelSpec, ...
    "inherited_current_switching_baseline", "NI");
equationsFrozen = height(phaseLinkEquations) >= 4 && ...
    any(string(phaseLinkEquations.equation_id) == ...
    "gauge_invariant_phase_difference");
gaugeInvariant = any(contains(string(phaseLinkEquations.expression), ...
    "integral_i_to_j_A_dot_dl"));
geometryIndependent = all(~loopGeometryManifest.manual_period_fit_allowed) && ...
    all(~loopGeometryManifest.residual_lookahead_allowed);
suppressionSeparated = any(string(fieldSuppressionSpec.component) == ...
    "PB_monotonic_field_suppression") && ...
    any(string(fieldSuppressionSpec.component) == ...
    "Pphi_phase_interference");
sharedR1R2 = any(string(validationHoldoutPlan.holdout_id) == ...
    "R1_train_R2_joint_prediction");
noManualPeriod = any(string(prohibitedFlexibilityLedger.blocked_item) == ...
    "manual_oscillation_period");
noHysteresisClaim = any(string(prohibitedFlexibilityLedger.blocked_item) == ...
    "hysteresis_fit_from_single_branch_data");
noTopology = any(string(prohibitedFlexibilityLedger.blocked_item) == ...
    "topological_edge_term") && ~cfg.phase15B.topologicalTermUsed;
validationPredeclared = height(validationHoldoutPlan) >= 5;
syntheticPredeclared = height(syntheticTestPlan) >= 10;
clean = lookup_provenance(sourceProvenance, "source_pre_run_clean") == "true";
noResidualsUsed = ~cfg.phase15B.rawAS006ResidualsUsed && ...
    all(~parameterRoleLedger.allowed_to_fit_AS006_residuals_in_phase15B);

gate = [
    "Phase 15A raw-data lock consumed unchanged";
    "Phase 15A artifact commit reachable";
    "FB and NI inheritance preserved";
    "Phase-aware equations frozen";
    "Gauge-invariant field coupling used";
    "Loop geometry independent of oscillation fit";
    "Field suppression separated from phase interference";
    "R1/R2 share one underlying phase state";
    "No manual oscillation-period fitting";
    "No hysteresis claims from single-branch data";
    "No topological interpretation encoded";
    "Validation windows predeclared";
    "Synthetic flux tests predeclared";
    "No raw AS006 residuals used";
    "Clean provenance";
    ];
outcome = [
    passfail(phase15AConsumed);
    passfail(phase15AReachable);
    passfail(inheritancePreserved);
    passfail(equationsFrozen);
    passfail(gaugeInvariant);
    passfail(geometryIndependent);
    passfail(suppressionSeparated);
    passfail(sharedR1R2);
    passfail(noManualPeriod);
    passfail(noHysteresisClaim);
    passfail(noTopology);
    passfail(validationPredeclared);
    passfail(syntheticPredeclared);
    passfail(noResidualsUsed);
    passfail(clean);
    ];
note = [
    "The frozen Phase 15A handoff is read as an input.";
    "The Phase 15A artifact-freeze commit is part of this source history.";
    "Phase-aware terms are added after FB and NI without retuning them.";
    "Current-phase, voltage, gauge, and loop equations are present.";
    "Magnetic coupling enters through vector-potential line integrals.";
    "Loop choices are geometry-driven, not residual-driven.";
    "PB and Pphi separate monotonic suppression from interference.";
    "R1 and R2 must be predicted from one phase solution.";
    "Manual field periods are blocked.";
    "Sweep-history claims remain blocked by Phase 15A metadata.";
    "No topological term appears in the model specification.";
    "Single-device field validation windows are frozen before execution.";
    "Phase 15C tests are declared before implementation adequacy.";
    "This phase freezes the specification only.";
    "The checkout was clean before Phase 15B wrote outputs.";
    ];
gates = table(gate, outcome, note);
end

function handoff = build_handoff_status(cfg, gates, inputs, sourceProvenance)
allPass = all(string(gates.outcome) == "pass");
axisLock = inputs.phase15AAxisMetadataLock;
item = [
    "phase15B_closure";
    "raw_AS006_residuals_used";
    "manual_period_fit";
    "topological_term_used";
    "thermal_feedback_used";
    "field_points_locked";
    "current_points_locked";
    "temperature_K";
    "sweep_history_status";
    "next_phase";
    "source_pre_run_clean";
    ];
status = [
    conditional(allPass, "pass_minimal_phase_aware_model_freeze", ...
    "blocked_minimal_phase_aware_model_freeze");
    string(cfg.phase15B.rawAS006ResidualsUsed);
    string(cfg.phase15B.manualPeriodFit);
    string(cfg.phase15B.topologicalTermUsed);
    string(cfg.phase15B.thermalFeedbackUsed);
    "locked_from_phase15A";
    "locked_from_phase15A";
    "locked_from_phase15A";
    "single_branch_no_sweep_rate";
    string(cfg.phase15B.nextPhase);
    lookup_provenance(sourceProvenance, "source_pre_run_clean");
    ];
value = [
    status(1);
    string(cfg.phase15B.rawAS006ResidualsUsed);
    string(cfg.phase15B.manualPeriodFit);
    string(cfg.phase15B.topologicalTermUsed);
    string(cfg.phase15B.thermalFeedbackUsed);
    string(axisLock.field_point_count(1));
    string(axisLock.current_point_count(1));
    string(axisLock.assumed_temperature_K(1));
    "up/down branches and sweep rate unavailable";
    string(cfg.phase15B.nextPhase);
    lookup_provenance(sourceProvenance, "source_pre_run_clean");
    ];
note = [
    "Phase 15B closes only as a model-specification freeze.";
    "Raw AS006 residuals are reserved for Phase 15D.";
    "No oscillation period is fit in Phase 15B.";
    "No topological claim or term is introduced.";
    "Thermal feedback remains outside this phase.";
    "Phase 15A field axis is consumed unchanged.";
    "Phase 15A current axis is consumed unchanged.";
    "Fixed/assumed temperature is inherited from the data lock.";
    "Hysteresis and sweep-rate claims remain unavailable.";
    "Phase 15C must verify the implementation synthetically.";
    "Pre-run clean provenance is captured before writing outputs.";
    ];
handoff = table(item, status, value, note);
end

function value = lookup_status(T, item)
idx = string(T.item) == string(item);
if any(idx)
    value = string(T.status(find(idx, 1, 'first')));
else
    value = "";
end
end

function value = lookup_provenance(T, item)
idx = string(T.item) == string(item);
if any(idx)
    value = string(T.value(find(idx, 1, 'first')));
else
    value = "";
end
end

function tf = has_spec_value(T, item, expected)
idx = string(T.item) == string(item);
tf = any(idx) && any(string(T.value(idx)) == string(expected));
end

function value = passfail(tf)
if tf
    value = "pass";
else
    value = "fail";
end
end

function value = conditional(tf, a, b)
if tf
    value = string(a);
else
    value = string(b);
end
end
