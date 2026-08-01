function out = run_phase14A_nonlinear_data_objective_lock(cfg)
%RUN_PHASE14A_NONLINEAR_DATA_OBJECTIVE_LOCK Lock nonlinear data and goals.
%
% Phase 14A is an inventory and protocol phase. It freezes which nonlinear
% observables may be used, how objectives are defined, and which flexibility
% remains prohibited before any current-switching model is executed.

if ~exist(cfg.outputDir, 'dir')
    mkdir(cfg.outputDir);
end

sourceProvenance = build_source_provenance(cfg);
inputs = load_inputs(cfg);
dataManifest = build_nonlinear_data_manifest(cfg, inputs);
observableDefinition = build_observable_definition(cfg);
probeAndSweepLock = build_probe_and_sweep_lock(cfg, inputs, dataManifest);
objectiveSpecification = build_objective_specification();
calibrationHoldoutManifest = build_calibration_holdout_manifest( ...
    dataManifest);
prohibitedFlexibilityLedger = build_prohibited_flexibility_ledger();
gateSummary = build_gate_summary(cfg, inputs, dataManifest, ...
    observableDefinition, objectiveSpecification, calibrationHoldoutManifest, ...
    prohibitedFlexibilityLedger, sourceProvenance);
handoffStatus = build_handoff_status(cfg, gateSummary, dataManifest, ...
    sourceProvenance);

writetable(dataManifest, cfg.phase14A.nonlinearDataManifestFile);
writetable(observableDefinition, cfg.phase14A.observableDefinitionFile);
writetable(probeAndSweepLock, cfg.phase14A.probeAndSweepLockFile);
writetable(objectiveSpecification, cfg.phase14A.objectiveSpecificationFile);
writetable(calibrationHoldoutManifest, ...
    cfg.phase14A.calibrationHoldoutManifestFile);
writetable(prohibitedFlexibilityLedger, ...
    cfg.phase14A.prohibitedFlexibilityLedgerFile);
writetable(gateSummary, cfg.phase14A.gateSummaryFile);
writetable(handoffStatus, cfg.phase14A.handoffStatusFile);
writetable(sourceProvenance, cfg.phase14A.sourceProvenanceFile);

try
    h = v800.plot_phase14A_nonlinear_data_objective_lock_summary( ...
        cfg, dataManifest, objectiveSpecification, ...
        calibrationHoldoutManifest, prohibitedFlexibilityLedger, ...
        gateSummary);
catch ME
    warning('v8:phase14APlotFailed', ...
        'Phase 14A summary plot failed: %s', ME.message);
    h = [];
end

out = struct();
out.config = cfg;
out.inputs = inputs;
out.nonlinearDataManifest = dataManifest;
out.observableDefinition = observableDefinition;
out.probeAndSweepLock = probeAndSweepLock;
out.objectiveSpecification = objectiveSpecification;
out.calibrationHoldoutManifest = calibrationHoldoutManifest;
out.prohibitedFlexibilityLedger = prohibitedFlexibilityLedger;
out.gateSummary = gateSummary;
out.handoffStatus = handoffStatus;
out.sourceProvenance = sourceProvenance;
out.figure = h;
out.paths = build_paths(cfg);
end

function paths = build_paths(cfg)
paths = struct();
paths.nonlinearDataManifest = cfg.phase14A.nonlinearDataManifestFile;
paths.observableDefinition = cfg.phase14A.observableDefinitionFile;
paths.probeAndSweepLock = cfg.phase14A.probeAndSweepLockFile;
paths.objectiveSpecification = cfg.phase14A.objectiveSpecificationFile;
paths.calibrationHoldoutManifest = ...
    cfg.phase14A.calibrationHoldoutManifestFile;
paths.prohibitedFlexibilityLedger = ...
    cfg.phase14A.prohibitedFlexibilityLedgerFile;
paths.gateSummary = cfg.phase14A.gateSummaryFile;
paths.handoffStatus = cfg.phase14A.handoffStatusFile;
paths.sourceProvenance = cfg.phase14A.sourceProvenanceFile;
paths.figurePng = [cfg.phase14A.figureBaseFile '.png'];
paths.figurePdf = [cfg.phase14A.figureBaseFile '.pdf'];
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
    "phase14A_nonlinear_data_objective_lock"
    sourceStatus.commit_sha
    sourceStatus.tree_sha
    string(sourceStatus.tracked_clean)
    string(sourceStatus.untracked_clean)
    string(sourceStatus.tracked_clean && sourceStatus.untracked_clean)
    "data_and_objective_lock_before_current_switching"
    "Commit Phase 14A source first; rerun from clean source; commit lock artifacts separately."
    ];
note = [
    "Phase 14A nonlinear data and objective lock."
    "Git commit captured before this runner writes outputs."
    "Git tree object captured before this runner writes outputs."
    "Tracked-source cleanliness before output generation."
    "Untracked-source/artifact cleanliness before output generation."
    "True only when checkout is clean before this run writes outputs."
    "No nonlinear fitting, equilibrium retuning, relabeling, or thermal model."
    "Artifacts are separate from source/configuration commits."
    ];
provenance = table(item, value, note);
end

function inputs = load_inputs(cfg)
inputs = struct();
inputs.phase11DeviceManifest = read_required_table( ...
    cfg.phase11.deviceObservableManifestFile);
inputs.phase11NonlinearSchema = read_required_table( ...
    cfg.phase11.nonlinearDataSchemaFile);
inputs.phase11ProbeMapping = read_required_table(cfg.phase11.probeMappingFile);
inputs.phase11Uncertainty = read_required_table( ...
    cfg.phase11.uncertaintyManifestFile);
inputs.phase11Handoff = read_required_table(cfg.phase11.handoffStatusFile);
inputs.phase13F4Handoff = read_required_table( ...
    cfg.phase13F4.handoffStatusFile);
inputs.phase13F4Claims = read_required_table(cfg.phase13F4.claimUpdateFile);
inputs.phase13F4Gates = read_required_table(cfg.phase13F4.gateSummaryFile);
end

function T = read_required_table(pathValue)
if ~exist(pathValue, 'file')
    error('Required Phase 14A input is missing: %s', pathValue);
end
try
    T = readtable(pathValue, 'TextType', 'string', ...
        'VariableNamingRule', 'preserve', 'Delimiter', ',');
catch
    T = readtable(pathValue, 'TextType', 'string', 'Delimiter', ',');
end
end

function manifest = build_nonlinear_data_manifest(cfg, inputs)
devices = string(inputs.phase11DeviceManifest.device);
rows = repmat(empty_manifest_row(), numel(devices), 1);
for k = 1:numel(devices)
    device = devices(k);
    phase11Row = inputs.phase11DeviceManifest(k, :);
    probeRow = row_for_device(inputs.phase11ProbeMapping, device);
    hasIT = logical(phase11Row.has_dVdI_IT);
    hasIB = logical(phase11Row.has_dVdI_IB);
    rows(k).device = device;
    rows(k).nonlinear_dataset_available = hasIT;
    rows(k).observable_type = conditional(hasIT, cfg.phase14A.focusObservable, ...
        conditional(hasIB, "dVdI_I_B_field_context", "not_available"));
    rows(k).current_axis = conditional(hasIT || hasIB, ...
        "declared_in_source_required", "not_available");
    rows(k).temperature_axis = conditional(hasIT, ...
        "declared_temperature_grid_required", ...
        conditional(hasIB, "single_or_assumed_temperature_required", ...
        "not_available"));
    rows(k).field_condition = conditional(hasIT, ...
        "B_approx_0_or_fixed_zero_required", ...
        conditional(hasIB, "field_sweep_deferred_to_phase15", ...
        "not_available"));
    rows(k).up_sweep_available = "not_declared";
    rows(k).down_sweep_available = "not_declared";
    rows(k).hysteresis_available = "not_declared";
    rows(k).primary_probe = string(probeRow.primary_probe);
    rows(k).secondary_probe = string(probeRow.secondary_probe);
    rows(k).normalization_policy = ...
        "RN normalization allowed only with recorded RN estimator";
    rows(k).uncertainty_status = ...
        "axis_and_normalization_uncertainty_must_be_recorded";
    rows(k).allowed_model_use = allowed_model_use(hasIT, hasIB);
    rows(k).phase14A_role = conditional(hasIT, ...
        "current_temperature_candidate", ...
        conditional(hasIB, "phase15_field_context_deferred", ...
        "not_available"));
end
manifest = struct2table(rows);
end

function row = empty_manifest_row()
row = struct( ...
    'device', "", ...
    'nonlinear_dataset_available', false, ...
    'observable_type', "", ...
    'current_axis', "", ...
    'temperature_axis', "", ...
    'field_condition', "", ...
    'up_sweep_available', "", ...
    'down_sweep_available', "", ...
    'hysteresis_available', "", ...
    'primary_probe', "", ...
    'secondary_probe', "", ...
    'normalization_policy', "", ...
    'uncertainty_status', "", ...
    'allowed_model_use', "", ...
    'phase14A_role', "");
end

function use = allowed_model_use(hasIT, hasIB)
if hasIT
    use = "phase14B_current_switching_candidate";
elseif hasIB
    use = "field_dependent_context_deferred_to_phase15";
else
    use = "not_available_not_synthetic_target";
end
end

function Trow = row_for_device(T, device)
idx = string(T.device) == string(device);
if any(idx)
    Trow = T(find(idx, 1, 'first'), :);
else
    Trow = T(1, :);
    Trow.primary_probe = "not_available";
    Trow.secondary_probe = "not_available";
end
end

function observableDefinition = build_observable_definition(cfg)
observable = [
    "dVdI_I_T"
    "dVdI_I_B"
    "I_V"
    "R_T_equilibrium"
    ];
phase14A_status = [
    "primary_focus"
    "excluded_field_oscillation_context"
    "metadata_or_reduction_context_only"
    "frozen_FB_equilibrium_baseline"
    ];
allowed_use = [
    "Phase 14B current-switching feasibility if source axes are declared."
    "Phase 15 unless a fixed B~0 slice is explicitly locked."
    "May inform sweep/current-axis metadata; not a direct map target yet."
    "Zero-current limit only; cannot be retuned in Phase 14."
    ];
normalization_policy = [
    "Optional RN normalization requires estimator ledger."
    "No field-period fitting or loop phase use in Phase 14."
    "No universal voltage normalization frozen."
    "Use frozen " + cfg.phase14A.equilibriumBaseline + " state."
    ];
observableDefinition = table(observable, phase14A_status, allowed_use, ...
    normalization_policy);
end

function lock = build_probe_and_sweep_lock(cfg, inputs, manifest)
devices = string(manifest.device);
rows = repmat(empty_lock_row(), numel(devices), 1);
for k = 1:numel(devices)
    device = devices(k);
    probeRow = row_for_device(inputs.phase11ProbeMapping, device);
    rows(k).device = device;
    rows(k).primary_probe = string(probeRow.primary_probe);
    rows(k).secondary_probe = string(probeRow.secondary_probe);
    rows(k).probe_pair_policy = string(probeRow.probe_pair_convention);
    rows(k).current_sweep_policy = conditional( ...
        manifest.nonlinear_dataset_available(k), ...
        "retain_source_current_axis_and_polarity", "not_applicable");
    rows(k).temperature_sweep_policy = conditional( ...
        manifest.nonlinear_dataset_available(k), ...
        "hold_out_declared_temperature_slices_in_phase14B", ...
        "not_applicable");
    rows(k).field_policy = conditional( ...
        manifest.observable_type(k) == cfg.phase14A.focusObservable, ...
        "B_approx_0_or_fixed_zero_only", ...
        conditional(manifest.observable_type(k) == "dVdI_I_B_field_context", ...
        "defer_field_sweeps_to_phase15", "not_available"));
    rows(k).hysteresis_policy = ...
        "record_if_available_but_do_not_fit_thermal_terms_in_phase14A";
end
lock = struct2table(rows);
end

function row = empty_lock_row()
row = struct( ...
    'device', "", ...
    'primary_probe', "", ...
    'secondary_probe', "", ...
    'probe_pair_policy', "", ...
    'current_sweep_policy', "", ...
    'temperature_sweep_policy', "", ...
    'field_policy', "", ...
    'hysteresis_policy', "");
end

function spec = build_objective_specification()
term = [
    "critical_current_position"
    "transition_width_in_current"
    "switching_feature_count"
    "low_bias_differential_resistance"
    "high_bias_differential_resistance"
    "positive_negative_current_symmetry"
    "temperature_dependence_of_Ic"
    "hysteresis_or_retrapping"
    "full_dVdI_I_T_map_residual"
    ];
weight = [0.22; 0.12; 0.10; 0.10; 0.08; 0.10; 0.18; 0.05; 0.05];
missing_data_policy = [
    "disabled_if_no_switching_feature"
    "disabled_if_no_current_width_observable"
    "disabled_if_no_feature_count_observable"
    "requires_low_bias_window"
    "requires_high_bias_window"
    "requires_positive_and_negative_current"
    "requires_multiple_temperature_slices"
    "optional_if_up_down_sweeps_available"
    "requires_registered_current_temperature_grid"
    ];
phase14A_status = [
    "frozen_for_phase14B"
    "frozen_for_phase14B"
    "frozen_for_phase14B"
    "frozen_for_phase14B"
    "frozen_for_phase14B"
    "frozen_for_phase14B"
    "frozen_for_phase14B"
    "diagnostic_only_until_phase14C"
    "secondary_summary_metric"
    ];
spec = table(term, weight, missing_data_policy, phase14A_status);
end

function holdout = build_calibration_holdout_manifest(manifest)
usable = manifest(manifest.nonlinear_dataset_available, :);
if isempty(usable)
    device = "none";
    calibration_role = "not_available";
    train_policy = "no_dVdI_I_T_dataset_locked";
    heldout_policy = "not_available";
    cross_device_policy = "not_available";
else
    device = string(usable.device);
    calibration_role = repmat("candidate_within_device_holdout", ...
        height(usable), 1);
    train_policy = repmat( ...
        "calibrate_on_declared_subset_of_temperature_slices", ...
        height(usable), 1);
    heldout_policy = repmat( ...
        "predict_held_out_temperature_slices_and_bias_ranges", ...
        height(usable), 1);
    cross_device_policy = repmat( ...
        "only_compare_across_devices_with_matching_observable_schema", ...
        height(usable), 1);
end
holdout = table(device, calibration_role, train_policy, heldout_policy, ...
    cross_device_policy);
end

function ledger = build_prohibited_flexibility_ledger()
prohibited_item = [
    "alter_frozen_FB_equilibrium_RT"
    "repair_AS004_or_AS005_equilibrium_residuals"
    "change_preferred_13F4_variant"
    "device_specific_Ic_gain_fitted_to_each_map"
    "device_specific_thermal_gain"
    "manual_switching_thresholds"
    "device_specific_curve_shifts"
    "nonlinear_correction_to_equilibrium_Tc"
    "Phase6_status_used_as_target"
    "Raman_used_as_nonlinear_target"
    "field_oscillation_period_fitted_in_Phase14"
    "transport_relabeling_or_probe_fallback"
    ];
blocked = true(numel(prohibited_item), 1);
reason = [
    "Equilibrium baseline is frozen by Phase 13F.4."
    "Phase 13D partial-scope limitation remains active."
    "Phase 13F.4 selected FB by parsimony."
    "Would convert nonlinear phase into device-specific fitting."
    "Thermal terms are reserved for declared Phase 14C ablation."
    "Switching thresholds must arise from shared law."
    "Would hide missing calibration/axis information."
    "Would reopen equilibrium R(T) calibration."
    "Phase 6 is interpretive evidence, not fitting target."
    "Raman remains independent context."
    "Field oscillations require Phase 15 phase/flux model."
    "Probe labels remain locked from Phase 11."
    ];
ledger = table(prohibited_item, blocked, reason);
end

function gates = build_gate_summary(cfg, inputs, manifest, observableDef, ...
    objectiveSpec, holdout, prohibited, sourceProvenance)
phase11Closed = lookup_status(inputs.phase11Handoff, "phase11_closure") == ...
    "pass_data_architecture" || ...
    lookup_status(inputs.phase11Handoff, "phase11_closure") == ...
    "pass_multimodal_data_architecture";
f4Closed = lookup_status(inputs.phase13F4Handoff, ...
    "phase13F4_closure") == ...
    "pass_read_only_comparative_adequacy_assessment";
baselineFrozen = lookup_status(inputs.phase13F4Handoff, ...
    "preferred_revised_variant") == cfg.phase14A.equilibriumBaseline && ...
    lookup_status(inputs.phase13F4Handoff, ...
    "shared_quantitative_RT_predictor") == "false";
usableIT = sum(manifest.nonlinear_dataset_available) >= 1;
fieldDeferred = all(manifest.allowed_model_use( ...
    string(manifest.observable_type) == "dVdI_I_B_field_context") == ...
    "field_dependent_context_deferred_to_phase15");
weightsFrozen = abs(sum(objectiveSpec.weight) - 1) < 1e-9;
noForbidden = all(prohibited.blocked);
cleanSource = lookup_value(sourceProvenance, "source_pre_run_clean") == ...
    "true";

gate = [
    "Phase 11 nonlinear architecture consumed"
    "Phase 13F.4 FB baseline consumed"
    "Equilibrium limitations preserved"
    "Nonlinear data availability explicit"
    "dVdI(I,T) separated from dVdI(I,B)"
    "Objective weights and missing-data policy frozen"
    "Calibration/holdout policy declared"
    "No prohibited flexibility enabled"
    "No electrothermal terms in Phase 14A"
    "Clean provenance"
    ];
outcome = [
    passfail(phase11Closed)
    passfail(f4Closed && baselineFrozen)
    passfail(~cfg.phase14A.sharedQuantitativeRTPredictor && ...
        cfg.phase14A.interfaceTransferTerm == "not_identifiable")
    passfail(height(manifest) == 6 && usableIT)
    passfail(fieldDeferred && any(observableDef.observable == "dVdI_I_B"))
    passfail(weightsFrozen)
    passfail(height(holdout) >= 1)
    passfail(noForbidden && ~cfg.phase14A.allowDeviceSpecificIcGain && ...
        ~cfg.phase14A.allowDeviceRelabeling)
    passfail(~cfg.phase14A.allowElectrothermalTerms)
    passfail(cleanSource)
    ];
note = [
    "Phase 14A reads the Phase 11 device-centered inventory."
    "FB is frozen as the equilibrium nonlinear baseline."
    "Partial R(T) predictive scope remains visible."
    "Devices without dVdI(I,T) are not filled with synthetic targets."
    "AS006 field data are deferred to Phase 15 unless a fixed-B slice is locked later."
    "Objective terms are declared before any current-switching execution."
    "Within-device held-out temperature/bias policy is declared."
    "No device labels, probes, Raman targets, or device-specific gains are opened."
    "Thermal feedback requires Phase 14C ablation."
    "True only when Phase 14A starts from a clean checkout."
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

function handoff = build_handoff_status(cfg, gates, manifest, sourceProvenance)
allPass = all(string(gates.outcome) == "pass");
usableDevices = strjoin(string(manifest.device( ...
    manifest.nonlinear_dataset_available)), "|");
fieldDeferred = strjoin(string(manifest.device( ...
    string(manifest.allowed_model_use) == ...
    "field_dependent_context_deferred_to_phase15")), "|");
item = [
    "phase14A_closure"
    "equilibrium_baseline"
    "equilibrium_RT_status"
    "shared_quantitative_RT_predictor"
    "interface_transfer_term"
    "phase14B_candidate_devices"
    "phase15_deferred_field_devices"
    "electrothermal_terms"
    "source_commit_sha"
    "next_phase"
    ];
status = [
    conditional(allPass, "pass_nonlinear_data_objective_lock", ...
        "needs_nonlinear_lock_review")
    cfg.phase14A.equilibriumBaseline
    cfg.phase14A.equilibriumRTStatus
    string(cfg.phase14A.sharedQuantitativeRTPredictor)
    cfg.phase14A.interfaceTransferTerm
    conditional(strlength(usableDevices) > 0, usableDevices, "none")
    conditional(strlength(fieldDeferred) > 0, fieldDeferred, "none")
    "not_enabled_until_phase14C_ablation"
    lookup_value(sourceProvenance, "source_commit_sha")
    cfg.phase14A.nextPhase
    ];
note = [
    "Closure means data availability, objectives, and prohibitions are frozen."
    "Frozen by Phase 13F.4."
    "The equilibrium R(T) predictor remains partial-scope."
    "Phase 13F.4 rejected a universal quantitative R(T) predictor."
    "Phase 13F.4 marked interface transfer as not independently identifiable."
    "Only devices with declared dVdI(I,T) evidence enter Phase 14B candidates."
    "Field-dependent nonlinear evidence is reserved for Phase 15."
    "Thermal physics requires a later explicit ablation."
    "Source commit captured before output generation."
    "Proceed to current-switching limiting cases and feasibility."
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
