function out = run_phase14B_current_model_solver_freeze(cfg)
%RUN_PHASE14B_CURRENT_MODEL_SOLVER_FREEZE Freeze nonlinear switching law.
%
% Phase 14B.1 is a specification phase. It consumes the frozen Phase 14A
% data/objective lock, records the shared current-switching law and solver
% contract, and prepares Phase 14B.2 limiting-case verification. It does not
% fit AS001 or AS004 residuals.

if ~exist(cfg.outputDir, 'dir')
    mkdir(cfg.outputDir);
end

sourceProvenance = build_source_provenance(cfg);
inputs = load_inputs(cfg);
currentModelSpecification = build_current_model_specification(cfg);
parameterRoleLedger = build_parameter_role_ledger(cfg);
solverSpecification = build_solver_specification(cfg);
prohibitedFlexibilityLedger = build_prohibited_flexibility_ledger(cfg);
limitingCasePlan = build_limiting_case_plan();
trainingHoldoutManifest = build_training_holdout_manifest(cfg, inputs);
gateSummary = build_gate_summary(cfg, inputs, currentModelSpecification, ...
    parameterRoleLedger, solverSpecification, prohibitedFlexibilityLedger, ...
    limitingCasePlan, trainingHoldoutManifest, sourceProvenance);
handoffStatus = build_handoff_status(cfg, gateSummary, trainingHoldoutManifest, ...
    sourceProvenance);

writetable(currentModelSpecification, ...
    cfg.phase14B.currentModelSpecificationFile);
writetable(parameterRoleLedger, cfg.phase14B.parameterRoleLedgerFile);
writetable(solverSpecification, cfg.phase14B.solverSpecificationFile);
writetable(prohibitedFlexibilityLedger, ...
    cfg.phase14B.prohibitedFlexibilityLedgerFile);
writetable(limitingCasePlan, cfg.phase14B.limitingCasePlanFile);
writetable(trainingHoldoutManifest, ...
    cfg.phase14B.trainingHoldoutManifestFile);
writetable(gateSummary, cfg.phase14B.gateSummaryFile);
writetable(handoffStatus, cfg.phase14B.handoffStatusFile);
writetable(sourceProvenance, cfg.phase14B.sourceProvenanceFile);

try
    h = v800.plot_phase14B_current_model_solver_freeze_summary( ...
        cfg, currentModelSpecification, parameterRoleLedger, ...
        solverSpecification, limitingCasePlan, trainingHoldoutManifest, ...
        prohibitedFlexibilityLedger, gateSummary);
catch ME
    warning('v8:phase14BPlotFailed', ...
        'Phase 14B.1 summary plot failed: %s', ME.message);
    h = [];
end

out = struct();
out.config = cfg;
out.inputs = inputs;
out.currentModelSpecification = currentModelSpecification;
out.parameterRoleLedger = parameterRoleLedger;
out.solverSpecification = solverSpecification;
out.prohibitedFlexibilityLedger = prohibitedFlexibilityLedger;
out.limitingCasePlan = limitingCasePlan;
out.trainingHoldoutManifest = trainingHoldoutManifest;
out.gateSummary = gateSummary;
out.handoffStatus = handoffStatus;
out.sourceProvenance = sourceProvenance;
out.figure = h;
out.paths = build_paths(cfg);
end

function paths = build_paths(cfg)
paths = struct();
paths.currentModelSpecification = ...
    cfg.phase14B.currentModelSpecificationFile;
paths.parameterRoleLedger = cfg.phase14B.parameterRoleLedgerFile;
paths.solverSpecification = cfg.phase14B.solverSpecificationFile;
paths.prohibitedFlexibilityLedger = ...
    cfg.phase14B.prohibitedFlexibilityLedgerFile;
paths.limitingCasePlan = cfg.phase14B.limitingCasePlanFile;
paths.trainingHoldoutManifest = cfg.phase14B.trainingHoldoutManifestFile;
paths.gateSummary = cfg.phase14B.gateSummaryFile;
paths.handoffStatus = cfg.phase14B.handoffStatusFile;
paths.sourceProvenance = cfg.phase14B.sourceProvenanceFile;
paths.figurePng = [cfg.phase14B.figureBaseFile '.png'];
paths.figurePdf = [cfg.phase14B.figureBaseFile '.pdf'];
end

function provenance = build_source_provenance(cfg)
sourceStatus = v800.git_tree_status(cfg.repoRoot);
item = [
    "phase"
    "source_commit_sha"
    "source_tree_sha"
    "source_pre_run_tracked_clean"
    "source_pre_run_untracked_clean"
    "source_pre_run_clean"
    "provenance_scope"
    "source_provenance_policy"
    ];
value = [
    "phase14B1_current_model_solver_freeze"
    sourceStatus.commit_sha
    sourceStatus.tree_sha
    string(sourceStatus.tracked_clean)
    string(sourceStatus.untracked_clean)
    string(sourceStatus.tracked_clean && sourceStatus.untracked_clean)
    "current_law_and_solver_specification_before_nonlinear_execution"
    "Commit Phase 14B.1 source first; rerun from clean source; commit artifacts separately."
    ];
note = [
    "Phase 14B.1 current-switching law and solver freeze."
    "Git commit captured before this runner writes outputs."
    "Git tree object captured before this runner writes outputs."
    "Tracked-source cleanliness before output generation."
    "Untracked-source/artifact cleanliness before output generation."
    "True only when checkout is clean before this run writes outputs."
    "No nonlinear fitting, thermal feedback, field model, Raman target, or R(T) retuning."
    "Artifacts are separate from source/configuration commits."
    ];
provenance = table(item, value, note);
end

function inputs = load_inputs(cfg)
inputs = struct();
inputs.phase14AHandoff = read_required_table(cfg.phase14A.handoffStatusFile);
inputs.phase14AManifest = read_required_table( ...
    cfg.phase14A.nonlinearDataManifestFile);
inputs.phase14AObjective = read_required_table( ...
    cfg.phase14A.objectiveSpecificationFile);
inputs.phase14AHoldout = read_required_table( ...
    cfg.phase14A.calibrationHoldoutManifestFile);
inputs.phase14AProhibited = read_required_table( ...
    cfg.phase14A.prohibitedFlexibilityLedgerFile);
inputs.phase13F4Handoff = read_required_table( ...
    cfg.phase13F4.handoffStatusFile);
end

function T = read_required_table(pathValue)
if ~exist(pathValue, 'file')
    error('Required Phase 14B.1 input is missing: %s', pathValue);
end
try
    T = readtable(pathValue, 'TextType', 'string', ...
        'VariableNamingRule', 'preserve', 'Delimiter', ',');
catch
    T = readtable(pathValue, 'TextType', 'string', 'Delimiter', ',');
end
end

function spec = build_current_model_specification(cfg)
component = [
    "equilibrium_limit"
    "baseline_variant"
    "current_switching_variant"
    "critical_current_temperature_law"
    "zero_temperature_scale_rule"
    "link_state_superconducting"
    "link_state_dissipative"
    "switching_smoothing"
    "differential_resistance"
    "comparison_variants"
    ];
definition = [
    "limit_I_to_0_R_phase14B_T_I_equals_R_FB_T"
    cfg.phase14B.equilibriumBaseline
    cfg.phase14B.currentModelVariant
    cfg.phase14B.criticalCurrentLaw
    cfg.phase14B.Ic0CouplingRule
    "unswitched links use frozen FB equilibrium conductance"
    "switched links use shared dissipative-state resistance rule"
    "shared_switching_width applies globally to all eligible links"
    cfg.phase14B.differentialResistanceScheme
    cfg.phase14B.baselineModelVariant + "_versus_" + ...
        cfg.phase14B.currentModelVariant
    ];
status = [
    "hard_gate"
    "frozen_from_phase13F4"
    "declared_for_phase14B"
    "shared_global_law"
    "shared_global_coupling_rule"
    "frozen_equilibrium_state"
    "shared_parameter"
    "shared_parameter"
    "frozen_before_comparison"
    "thermal_feedback_absent"
    ];
note = [
    "The nonlinear model cannot alter zero-bias R(T)."
    "FB is the Phase 13F.4 selected equilibrium baseline."
    "NI adds current switching only."
    "The same p and q are used for AS001 and AS004."
    "The rule can depend on W_ij, Tc_ij, and Rn_ij but not device-specific gains."
    "No additional superconducting branch physics is introduced here."
    "The high-current limit is checked in Phase 14B.2."
    "Smoothing is a numerical regularizer, not a per-device fit."
    "dV/dI is computed after V(I,T) is solved."
    "N0 is FB-only; NI is FB plus Ic(T) switching."
    ];
spec = table(component, definition, status, note);
end

function ledger = build_parameter_role_ledger(cfg)
parameter = [
    cfg.phase14B.sharedParameterNames
    "device_current_range"
    "device_temperature_grid"
    "device_geometry"
    "device_specific_Ic_scale"
    "device_specific_switching_exponents"
    "thermal_feedback_gain"
    ];
role = [
    repmat("shared_fit_or_shared_scan", numel(cfg.phase14B.sharedParameterNames), 1)
    "measured_device_metadata"
    "measured_device_metadata"
    "measured_device_metadata"
    "prohibited"
    "prohibited"
    "prohibited_until_phase14C"
    ];
scope = [
    repmat("AS001_and_AS004_common", numel(cfg.phase14B.sharedParameterNames), 1)
    "device_specific_observed_axis"
    "device_specific_observed_axis"
    "device_specific_measured_input"
    "not_allowed"
    "not_allowed"
    "not_allowed_in_phase14B"
    ];
bound_policy = [
    "bounded_positive_global_scale"
    "bounded_common_shape_exponent"
    "bounded_common_shape_exponent"
    "bounded_nonnegative_width"
    "bounded_solver_tolerance"
    "bounded_common_dissipative_resistance"
    "source_current_axis_only"
    "source_temperature_slices_only"
    "frozen_measured_geometry_or_proxy"
    "blocked"
    "blocked"
    "blocked"
    ];
ledger = table(parameter, role, scope, bound_policy);
end

function spec = build_solver_specification(cfg)
step = [
    "initialize_state"
    "solve_network_currents"
    "compare_branch_current_to_Ic"
    "update_switched_links"
    "repeat_until_converged"
    "record_voltage"
    "compute_dVdI"
    "record_diagnostics"
    ];
policy = [
    "start from previous current point or FB zero-current state"
    "solve Kirchhoff network for fixed applied current and link states"
    "use abs(branch_current) >= smoothed_Ic_threshold"
    "switched links enter shared dissipative state"
    "stop when state vector and voltage meet shared tolerance"
    "store V(I,T), state count, and iteration count"
    "central finite difference except endpoints use one-sided difference"
    "retain nonconverged points in failed prediction log"
    ];
frozen_status = repmat("frozen_for_phase14B2", numel(step), 1);
spec = table(step, policy, frozen_status);

status = cfg.phase14B.allowedSolverStatuses;
status_policy = [
    "accepted_success_status"
    "failure_log_required"
    "failure_log_required"
    "failure_log_required"
    "failure_log_required"
    ];
extra = table("allowed_solver_status:" + status, status_policy, ...
    repmat("frozen_for_phase14B2", numel(status), 1), ...
    'VariableNames', {'step', 'policy', 'frozen_status'});
spec = [spec; extra];
end

function ledger = build_prohibited_flexibility_ledger(cfg)
prohibited_item = [
    "alter_frozen_FB_equilibrium_RT"
    "device_specific_Ic_scale"
    "device_specific_switching_exponents"
    "manual_switching_currents"
    "device_specific_temperature_offsets"
    "nonlinear_correction_to_equilibrium_Tc"
    "thermal_feedback"
    "phase_dynamics"
    "field_periodicity_terms"
    "Raman_target_use"
    "Phase6_label_target_use"
    "transport_relabeling_or_probe_fallback"
    ];
blocked = [
    ~cfg.phase14B.allowEquilibriumRetuning
    ~cfg.phase14B.allowDeviceSpecificIcScale
    ~cfg.phase14B.allowDeviceSpecificSwitchingExponents
    ~cfg.phase14B.allowManualSwitchingCurrents
    true
    true
    ~cfg.phase14B.allowThermalFeedback
    ~cfg.phase14B.allowPhaseDynamics
    ~cfg.phase14B.allowFieldPeriodicityTerms
    ~cfg.phase14B.allowRamanTargets
    ~cfg.phase14B.allowPhase6Targets
    ~cfg.phase14B.allowDeviceRelabeling
    ];
reason = [
    "Zero-current state must recover FB."
    "Would split the shared nonlinear law by device."
    "Would split p/q by device."
    "Switching currents must come from Ic(T), not hand-picked crossings."
    "Would hide temperature-axis or calibration problems."
    "Would reopen the equilibrium Tc map."
    "Reserved only for Phase 14C if current-only failure demands it."
    "Phase dynamics are outside Phase 14."
    "AS006 field periodicity is deferred to Phase 15."
    "Raman remains independent context."
    "Phase 6 labels are interpretive outputs, not nonlinear targets."
    "Probe labels remain locked by Phase 11/14A."
    ];
ledger = table(prohibited_item, blocked, reason);
end

function plan = build_limiting_case_plan()
case_id = [
    "LC1_single_link_switch"
    "LC2_parallel_path_redistribution"
    "LC3_boundary_bottleneck_multistage"
    "LC4_positive_negative_symmetry"
    "LC5_Ic_monotonic_with_temperature"
    "LC6_high_current_dissipative_limit"
    "LC7_zero_current_FB_recovery"
    "LC8_solver_convergence_no_cycle"
    ];
required_behavior = [
    "one link switches at its declared Ic(T)"
    "current redistributes after one path switches"
    "boundary bottleneck yields multiple switching stages"
    "positive and negative sweeps match without asymmetry term"
    "Ic(T) decreases monotonically as T approaches Tc"
    "high-current state approaches declared dissipative response"
    "I to 0 limit returns frozen FB"
    "iterations converge or failures are explicitly logged"
    ];
phase14B2_status = repmat("declared_for_synthetic_verification", ...
    numel(case_id), 1);
plan = table(case_id, required_behavior, phase14B2_status);
end

function holdout = build_training_holdout_manifest(cfg, inputs)
manifest = inputs.phase14AManifest;
devices = string(manifest.device(manifest.nonlinear_dataset_available));
if isempty(devices)
    devices = "none";
end
role = strings(numel(devices), 1);
train_policy = strings(numel(devices), 1);
heldout_policy = strings(numel(devices), 1);
for k = 1:numel(devices)
    if devices(k) == "AS001"
        role(k) = "control_baseline_nonlinear_switching_case";
    elseif devices(k) == "AS004"
        role(k) = "boundary_associated_current_redistribution_case";
    else
        role(k) = "unexpected_phase14B_candidate";
    end
    train_policy(k) = "calibrate_on_declared_subset_of_temperature_slices";
    heldout_policy(k) = ...
        "predict_alternating_or_leave_one_temperature_slices_and_bias_ranges";
end
shared_law_policy = repmat("same_Ic_T_law_and_parameter_bounds", ...
    numel(devices), 1);
equilibrium_policy = repmat("zero_current_limit_must_equal_FB", ...
    numel(devices), 1);
holdout = table(devices, role, train_policy, heldout_policy, ...
    shared_law_policy, equilibrium_policy, ...
    'VariableNames', {'device', 'phase14B_role', 'train_policy', ...
    'heldout_policy', 'shared_law_policy', 'equilibrium_policy'});
end

function gates = build_gate_summary(cfg, inputs, currentSpec, parameterLedger, ...
    solverSpec, prohibited, limitingPlan, holdout, sourceProvenance)
phase14AClosed = lookup_status(inputs.phase14AHandoff, ...
    "phase14A_closure") == "pass_nonlinear_data_objective_lock";
baselineFrozen = lookup_status(inputs.phase14AHandoff, ...
    "equilibrium_baseline") == cfg.phase14B.equilibriumBaseline;
partialRTPreserved = lookup_status(inputs.phase14AHandoff, ...
    "shared_quantitative_RT_predictor") == "false";
zeroCurrentSpecified = any(string(currentSpec.component) == ...
    "equilibrium_limit" & string(currentSpec.status) == "hard_gate");
candidateDevices = sort(string(holdout.device));
as001as004Only = isequal(candidateDevices, sort(cfg.phase14B.phase14BCandidateDevices));
as006Deferred = lookup_status(inputs.phase14AHandoff, ...
    "phase15_deferred_field_devices") == cfg.phase14B.phase15DeferredDevices;
sharedLaw = all(string(parameterLedger.role( ...
    startsWith(string(parameterLedger.parameter), "shared_") | ...
    string(parameterLedger.parameter) == "global_Ic_scale")) == ...
    "shared_fit_or_shared_scan");
noDeviceGains = all(prohibited.blocked);
solverStatusesDeclared = all(ismember(cfg.phase14B.allowedSolverStatuses, ...
    erase(string(solverSpec.step(startsWith(string(solverSpec.step), ...
    "allowed_solver_status:"))), "allowed_solver_status:")));
limitingCasesDeclared = height(limitingPlan) == 8;
thermalAbsent = ~cfg.phase14B.allowThermalFeedback;
cleanSource = lookup_value(sourceProvenance, "source_pre_run_clean") == "true";

gate = [
    "Phase 14A lock consumed unchanged"
    "FB equilibrium baseline preserved"
    "Limited equilibrium R(T) status preserved"
    "Zero-current FB recovery declared as hard gate"
    "AS001 and AS004 only"
    "AS006 remains deferred to Phase 15"
    "Shared Ic(T) law declared"
    "No device-specific nonlinear gains"
    "Solver failure statuses declared"
    "Synthetic limiting cases declared"
    "Training and holdout policy frozen"
    "Field and Raman targets excluded"
    "Thermal feedback absent"
    "Clean provenance"
    ];
outcome = [
    passfail(phase14AClosed)
    passfail(baselineFrozen)
    passfail(partialRTPreserved)
    passfail(zeroCurrentSpecified)
    passfail(as001as004Only)
    passfail(as006Deferred)
    passfail(sharedLaw)
    passfail(noDeviceGains)
    passfail(solverStatusesDeclared)
    passfail(limitingCasesDeclared)
    passfail(height(holdout) == 2)
    passfail(~cfg.phase14B.allowFieldPeriodicityTerms && ...
        ~cfg.phase14B.allowRamanTargets)
    passfail(thermalAbsent)
    passfail(cleanSource)
    ];
note = [
    "Phase 14B.1 consumes the frozen data/objective lock."
    "N0 and NI both start from FB."
    "Phase 13F.4 limitation remains active."
    "Nonlinear switching cannot repair R(T)."
    "Only dVdI(I,T) candidates enter Phase 14B."
    "Field sweeps are Phase 15 context."
    "One law and one parameter set apply to AS001 and AS004."
    "Manual currents, device gains, and device exponents are blocked."
    "Nonconverged points must be kept in failure logs."
    "Phase 14B.2 must verify implementation before AS001/AS004 fitting."
    "Held-out temperature and bias policies are frozen before execution."
    "No Raman, Phase 6, or field-period target is opened."
    "Thermal physics requires Phase 14C decision."
    "True only when Phase 14B.1 starts from a clean checkout."
    ];
gates = table(gate, outcome, note);
end

function status = lookup_status(T, item)
idx = string(T.item) == string(item);
if any(idx)
    row = find(idx, 1, 'first');
    names = string(T.Properties.VariableNames);
    if any(names == "status")
        status = string(T.status(row));
    elseif any(names == "value")
        status = string(T.value(row));
    else
        status = "";
    end
else
    status = "";
end
end

function value = lookup_value(T, item)
value = lookup_status(T, item);
end

function value = passfail(tf)
if tf
    value = "pass";
else
    value = "fail";
end
end

function handoff = build_handoff_status(cfg, gates, holdout, sourceProvenance)
allPass = all(string(gates.outcome) == "pass");
item = [
    "phase14B1_closure"
    "phase14B_execution"
    "equilibrium_baseline"
    "zero_current_recovery_required"
    "current_switching_variant"
    "thermal_feedback_used"
    "phase14B_candidate_devices"
    "shared_Ic_law"
    "nonlinear_adequacy_decision"
    "source_commit_sha"
    "next_phase"
    ];
status = [
    conditional(allPass, "pass_current_model_solver_freeze", ...
        "needs_current_model_solver_review")
    "not_started_specification_only"
    cfg.phase14B.equilibriumBaseline
    "hard_gate"
    cfg.phase14B.currentModelVariant
    "false"
    strjoin(string(holdout.device), "|")
    "frozen_common_AS001_AS004"
    "pending"
    lookup_value(sourceProvenance, "source_commit_sha")
    cfg.phase14B.nextPhase
    ];
note = [
    "Closure means current law, parameter roles, solver rules, and tests are frozen."
    "No synthetic or experimental nonlinear execution occurs in Phase 14B.1."
    "Frozen by Phase 13F.4 and consumed through Phase 14A."
    "The I to 0 response must equal FB."
    "NI means FB plus current-dependent switching."
    "Electrothermal feedback is absent unless Phase 14C is explicitly triggered."
    "Only AS001 and AS004 have dVdI(I,T) targets."
    "No device-specific nonlinear gains or exponents."
    "Adequacy is decided after Phase 14B execution."
    "Source commit captured before output generation."
    "Proceed to synthetic limiting-case verification."
    ];
handoff = table(item, status, note);
end

function value = conditional(tf, a, b)
if tf
    value = string(a);
else
    value = string(b);
end
end
