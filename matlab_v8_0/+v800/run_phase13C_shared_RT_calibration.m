function out = run_phase13C_shared_RT_calibration(cfg)
%RUN_PHASE13C_SHARED_RT_CALIBRATION Freeze Phase 13C RT campaign contract.

if ~exist(cfg.outputDir, 'dir')
    mkdir(cfg.outputDir);
end

sourceProvenance = build_source_provenance(cfg);
inputs = load_phase13C_inputs(cfg);
RTDataLockManifest = build_RT_data_lock_manifest(inputs);
calibrationObjectiveSpecification = ...
    build_calibration_objective_specification(cfg);
parameterFitManifest = build_parameter_fit_manifest(inputs);
leaveOneDeviceOutManifest = build_leave_one_device_out_manifest(cfg, ...
    RTDataLockManifest);
foldParameterResults = build_fold_parameter_results(cfg, ...
    leaveOneDeviceOutManifest, parameterFitManifest);
deviceRTPredictions = build_device_RT_predictions(cfg, RTDataLockManifest);
transitionMetricPredictions = build_transition_metric_predictions(cfg, ...
    RTDataLockManifest);
fullCurveResiduals = build_full_curve_residuals(cfg, RTDataLockManifest);
probePairPredictions = build_probe_pair_predictions(cfg, RTDataLockManifest);
geometryFamilyHoldoutResults = build_geometry_family_holdouts(cfg);
uncertaintyEnsembleSummary = build_uncertainty_ensemble_summary(cfg);
calibrationFirewall = build_calibration_firewall(cfg);
gateSummary = build_gate_summary(cfg, inputs, RTDataLockManifest, ...
    calibrationObjectiveSpecification, parameterFitManifest, ...
    leaveOneDeviceOutManifest, probePairPredictions, ...
    uncertaintyEnsembleSummary, calibrationFirewall, sourceProvenance);
handoffStatus = build_handoff_status(cfg, gateSummary, sourceProvenance);

writetable(RTDataLockManifest, cfg.phase13C.RTDataLockManifestFile);
writetable(calibrationObjectiveSpecification, ...
    cfg.phase13C.calibrationObjectiveSpecificationFile);
writetable(parameterFitManifest, cfg.phase13C.parameterFitManifestFile);
writetable(leaveOneDeviceOutManifest, ...
    cfg.phase13C.leaveOneDeviceOutManifestFile);
writetable(foldParameterResults, cfg.phase13C.foldParameterResultsFile);
writetable(deviceRTPredictions, cfg.phase13C.deviceRTPredictionsFile);
writetable(transitionMetricPredictions, ...
    cfg.phase13C.transitionMetricPredictionsFile);
writetable(fullCurveResiduals, cfg.phase13C.fullCurveResidualsFile);
writetable(probePairPredictions, cfg.phase13C.probePairPredictionsFile);
writetable(geometryFamilyHoldoutResults, ...
    cfg.phase13C.geometryFamilyHoldoutResultsFile);
writetable(uncertaintyEnsembleSummary, ...
    cfg.phase13C.uncertaintyEnsembleSummaryFile);
writetable(calibrationFirewall, cfg.phase13C.calibrationFirewallFile);
writetable(gateSummary, cfg.phase13C.gateSummaryFile);
writetable(handoffStatus, cfg.phase13C.handoffStatusFile);
writetable(sourceProvenance, cfg.phase13C.sourceProvenanceFile);

try
    h = v800.plot_phase13C_shared_RT_calibration_summary(cfg, ...
        RTDataLockManifest, calibrationObjectiveSpecification, ...
        leaveOneDeviceOutManifest, probePairPredictions, ...
        geometryFamilyHoldoutResults, gateSummary);
catch ME
    warning('v8:phase13CPlotFailed', ...
        'Phase 13C shared RT calibration summary plot failed: %s', ...
        ME.message);
    h = [];
end

out = struct();
out.config = cfg;
out.inputs = inputs;
out.RTDataLockManifest = RTDataLockManifest;
out.calibrationObjectiveSpecification = calibrationObjectiveSpecification;
out.parameterFitManifest = parameterFitManifest;
out.leaveOneDeviceOutManifest = leaveOneDeviceOutManifest;
out.foldParameterResults = foldParameterResults;
out.deviceRTPredictions = deviceRTPredictions;
out.transitionMetricPredictions = transitionMetricPredictions;
out.fullCurveResiduals = fullCurveResiduals;
out.probePairPredictions = probePairPredictions;
out.geometryFamilyHoldoutResults = geometryFamilyHoldoutResults;
out.uncertaintyEnsembleSummary = uncertaintyEnsembleSummary;
out.calibrationFirewall = calibrationFirewall;
out.gateSummary = gateSummary;
out.handoffStatus = handoffStatus;
out.sourceProvenance = sourceProvenance;
out.figure = h;
out.paths = build_paths(cfg);
end

function paths = build_paths(cfg)
paths = struct();
paths.RTDataLockManifest = cfg.phase13C.RTDataLockManifestFile;
paths.calibrationObjectiveSpecification = ...
    cfg.phase13C.calibrationObjectiveSpecificationFile;
paths.parameterFitManifest = cfg.phase13C.parameterFitManifestFile;
paths.leaveOneDeviceOutManifest = cfg.phase13C.leaveOneDeviceOutManifestFile;
paths.foldParameterResults = cfg.phase13C.foldParameterResultsFile;
paths.deviceRTPredictions = cfg.phase13C.deviceRTPredictionsFile;
paths.transitionMetricPredictions = ...
    cfg.phase13C.transitionMetricPredictionsFile;
paths.fullCurveResiduals = cfg.phase13C.fullCurveResidualsFile;
paths.probePairPredictions = cfg.phase13C.probePairPredictionsFile;
paths.geometryFamilyHoldoutResults = ...
    cfg.phase13C.geometryFamilyHoldoutResultsFile;
paths.uncertaintyEnsembleSummary = cfg.phase13C.uncertaintyEnsembleSummaryFile;
paths.calibrationFirewall = cfg.phase13C.calibrationFirewallFile;
paths.gateSummary = cfg.phase13C.gateSummaryFile;
paths.handoffStatus = cfg.phase13C.handoffStatusFile;
paths.sourceProvenance = cfg.phase13C.sourceProvenanceFile;
paths.figurePng = [cfg.phase13C.figureBaseFile '.png'];
paths.figurePdf = [cfg.phase13C.figureBaseFile '.pdf'];
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
    "phase13C_shared_RT_calibration"
    sourceStatus.commit_sha
    sourceStatus.tree_sha
    string(sourceStatus.tracked_clean)
    string(sourceStatus.untracked_clean)
    string(sourceStatus.tracked_clean && sourceStatus.untracked_clean)
    "freeze_RT_data_objective_and_prediction_campaign_before_calibration"
    "Commit Phase 13C source first; rerun from clean source; commit generated artifacts separately."
    ];
note = [
    "Phase 13C shared R(T) calibration campaign setup."
    "Git commit captured before this runner writes outputs."
    "Git tree object captured before this runner writes outputs."
    "Tracked-source cleanliness before output generation."
    "Untracked-source/artifact cleanliness before output generation."
    "True only when the checkout is clean before this run writes outputs."
    "No full R(T) prediction is claimed until the solver/curve execution step runs."
    "Phase 13C artifacts are downstream of frozen Phase 13A/13B outputs."
    ];
provenance = table(item, value, note);
end

function inputs = load_phase13C_inputs(cfg)
inputs = struct();
inputs.phase13AHandoff = read_optional_table(cfg.phase13A.handoffStatusFile);
inputs.phase13AGates = read_optional_table(cfg.phase13A.gateSummaryFile);
inputs.phase13BHandoff = read_optional_table(cfg.phase13B.handoffStatusFile);
inputs.phase13BGates = read_optional_table(cfg.phase13B.gateSummaryFile);
inputs.deviceManifest = read_optional_table( ...
    cfg.phase11.deviceObservableManifestFile);
inputs.probeMapping = read_optional_table(cfg.phase11.probeMappingFile);
inputs.parameterRoles = read_optional_table(cfg.phase13A.parameterRoleLedgerFile);
inputs.parameterPriors = read_optional_table(cfg.phase13A.globalParameterPriorsFile);
end

function T = read_optional_table(pathValue)
if exist(pathValue, 'file')
    try
        T = readtable(pathValue, 'TextType', 'string', ...
            'VariableNamingRule', 'preserve', 'Delimiter', ',');
    catch
        T = readtable(pathValue, 'TextType', 'string', 'Delimiter', ',');
    end
else
    T = table();
end
end

function lock = build_RT_data_lock_manifest(inputs)
D = inputs.deviceManifest;
P = inputs.probeMapping;
devices = string(D.device);
n = numel(devices);
rows = repmat(empty_RT_lock_row(), n, 1);
for k = 1:n
    pRow = P(string(P.device) == devices(k), :);
    rows(k).device = devices(k);
    rows(k).primary_probe = string(D.primary_probe(k));
    rows(k).secondary_probe = string(D.secondary_probe(k));
    rows(k).primary_experimental_channel = string(pRow.primary_experimental_channel(1));
    rows(k).secondary_status = string(pRow.secondary_status(1));
    rows(k).has_R1_RT = logical(D.has_R1_RT(k));
    rows(k).has_R2_RT = logical(D.has_R2_RT(k));
    rows(k).has_primary_RT = logical(D.has_primary_RT(k));
    rows(k).has_secondary_RT = logical(D.has_secondary_RT(k));
    rows(k).temperature_range_policy = ...
        "use_observed_overlap_without_extrapolation";
    rows(k).normalization_window_policy = ...
        "freeze_predeclared_normal_state_window";
    rows(k).low_temperature_endpoint_policy = ...
        "use_lowest_valid_measured_temperature";
    rows(k).excluded_points_policy = ...
        "exclude_only_declared_missing_or_invalid_points";
    rows(k).interpolation_policy = ...
        "monotone_temperature_grid_no_curve_shape_retuning";
    rows(k).uncertainty_policy = ...
        "normalization_interpolation_and_repeatability_terms";
    rows(k).automatic_probe_fallback_allowed = false;
    rows(k).status = "locked_before_calibration";
end
lock = struct2table(rows);
end

function objective = build_calibration_objective_specification(cfg)
metric = cfg.phase13C.objectiveMetric(:);
weight = cfg.phase13C.objectiveWeight(:);
normalization = [
    "temperature_grid_normalized_curve_distance"
    "temperature_uncertainty_scaled"
    "temperature_uncertainty_scaled"
    "temperature_uncertainty_scaled"
    "width_uncertainty_scaled"
    "normalized_resistance_uncertainty_scaled"
    "paired_probe_uncertainty_scaled"
    ];
used_for_primary_score = true(numel(metric), 1);
predeclared_before_prediction = true(numel(metric), 1);
note = [
    "Full curve residual contributes but cannot dominate the score."
    "Transition upper-tail location metric."
    "Transition midpoint metric."
    "Transition lower-tail location metric."
    "Broadening metric."
    "Residual floor metric."
    "Only evaluated where both probes exist; no independent probe refit."
    ];
objective = table(metric, weight, normalization, used_for_primary_score, ...
    predeclared_before_prediction, note);
end

function manifest = build_parameter_fit_manifest(inputs)
roles = inputs.parameterRoles;
if isempty(roles)
    manifest = table();
    return;
end
allowedMask = startsWith(string(roles.parameter_role), "shared_");
parameter = string(roles.parameter);
parameter_role = string(roles.parameter_role);
allowed_for_optimization = allowedMask & logical(roles.used_for_calibration);
device_specific_allowed = logical(roles.device_specific_allowed);
fit_scope = repmat("not_fit", numel(parameter), 1);
fit_scope(allowed_for_optimization) = "shared_global_candidate";
fit_scope(device_specific_allowed & string(roles.parameter_role) == ...
    "measured_input") = "measured_input_not_optimized";
prohibited_reason = repmat("", numel(parameter), 1);
prohibited_reason(contains(parameter, "device_specific") | ...
    string(roles.parameter_role) == "prohibited_device_specific") = ...
    "device_specific_mechanism_parameter";
prohibited_reason(string(roles.parameter_role) == ...
    "prohibited_training_target") = "interpretive_label_not_target";
prohibited_reason(string(roles.parameter_role) == ...
    "qualitative_independent_check_only") = "not_transport_target";
manifest = table(parameter, parameter_role, allowed_for_optimization, ...
    device_specific_allowed, fit_scope, prohibited_reason);
end

function loo = build_leave_one_device_out_manifest(cfg, lock)
devices = string(lock.device);
rows = repmat(empty_loo_row(), numel(devices), 1);
for k = 1:numel(devices)
    train = devices(devices ~= devices(k));
    rows(k).heldout_device = devices(k);
    rows(k).training_devices = strjoin(train, "|");
    rows(k).primary_channel = string(lock.primary_experimental_channel(k));
    rows(k).secondary_status = string(lock.secondary_status(k));
    rows(k).shared_parameters_only = true;
    rows(k).constitutive_form_retuned = false;
    rows(k).phase6_labels_used_as_targets = false;
    rows(k).execution_status = cfg.phase13C.predictionExecutionStatus;
    rows(k).description = ...
        "fit_other_five_predict_heldout_without_adjustment";
end
loo = struct2table(rows);
end

function results = build_fold_parameter_results(cfg, loo, parameterManifest)
candidate = parameterManifest(parameterManifest.allowed_for_optimization, :);
nRows = max(1, height(loo) * max(1, height(candidate)));
rows = repmat(empty_parameter_result_row(), nRows, 1);
idx = 0;
for k = 1:height(loo)
    if isempty(candidate)
        idx = idx + 1;
        rows(idx).heldout_device = string(loo.heldout_device(k));
        rows(idx).parameter = "not_available";
    else
        for p = 1:height(candidate)
            idx = idx + 1;
            rows(idx).heldout_device = string(loo.heldout_device(k));
            rows(idx).parameter = string(candidate.parameter(p));
        end
    end
    rows(idx).fit_status = cfg.phase13C.predictionExecutionStatus;
end
rows = rows(1:idx);
results = struct2table(rows);
end

function predictions = build_device_RT_predictions(cfg, lock)
rows = repmat(empty_prediction_row(), height(lock), 1);
for k = 1:height(lock)
    rows(k).device = string(lock.device(k));
    rows(k).primary_channel = string(lock.primary_experimental_channel(k));
    rows(k).predicted_quantity = "median_Rtilde_T_with_interval";
    rows(k).prediction_status = cfg.phase13C.predictionExecutionStatus;
    rows(k).device_specific_mechanism_retuned = false;
    rows(k).automatic_probe_fallback_used = false;
    rows(k).note = "schema_locked_no_curve_generated_in_setup_step";
end
predictions = struct2table(rows);
end

function metrics = build_transition_metric_predictions(cfg, lock)
metricList = ["T90"; "T50"; "T10"; "width_T90_T10"; ...
    "onset_temperature"; "low_temperature_residual_fraction"];
rows = repmat(empty_metric_row(), height(lock) * numel(metricList), 1);
idx = 0;
for k = 1:height(lock)
    for m = 1:numel(metricList)
        idx = idx + 1;
        rows(idx).device = string(lock.device(k));
        rows(idx).metric = metricList(m);
        rows(idx).prediction_status = cfg.phase13C.predictionExecutionStatus;
    end
end
metrics = struct2table(rows);
end

function residuals = build_full_curve_residuals(cfg, lock)
rows = repmat(empty_residual_row(), height(lock), 1);
for k = 1:height(lock)
    rows(k).device = string(lock.device(k));
    rows(k).residual_metric = "full_normalized_RT_curve_residual";
    rows(k).prediction_status = cfg.phase13C.predictionExecutionStatus;
end
residuals = struct2table(rows);
end

function pairs = build_probe_pair_predictions(cfg, lock)
mask = logical(lock.has_primary_RT) & logical(lock.has_secondary_RT);
pairs = lock(mask, ["device", "primary_probe", "secondary_probe", ...
    "primary_experimental_channel", "secondary_status"]);
if isempty(pairs)
    pairs = table();
    return;
end
paired_prediction_status = repmat(cfg.phase13C.predictionExecutionStatus, ...
    height(pairs), 1);
probe_independent_refit_allowed = false(height(pairs), 1);
predicted_quantity = repmat("A_probe_T=R1_T_minus_R2_T", height(pairs), 1);
pairs = addvars(pairs, predicted_quantity, paired_prediction_status, ...
    probe_independent_refit_allowed);
end

function holdouts = build_geometry_family_holdouts(cfg)
family_holdout = [
    "cracked_full_coverage_AS005"
    "strong_half_coverage_AS006"
    "half_coverage_sequence_AS002_AS004_AS006"
    "control_limit_AS002_AS003"
    ];
heldout_devices = [
    "AS005"
    "AS006"
    "AS002|AS004|AS006"
    "AS002|AS003"
    ];
purpose = [
    "test_transfer_to_crack_geometry"
    "test_transfer_to_strong_boundary_geometry"
    "test_half_coverage_family_interpolation"
    "test_control_or_local_limit_family"
    ];
execution_status = repmat(cfg.phase13C.predictionExecutionStatus, ...
    numel(family_holdout), 1);
secondary_to_LOO = true(numel(family_holdout), 1);
holdouts = table(family_holdout, heldout_devices, purpose, ...
    execution_status, secondary_to_LOO);
end

function ensemble = build_uncertainty_ensemble_summary(cfg)
source = [
    "disorder_realization"
    "shared_parameter_uncertainty"
    "normalization_window"
    "measured_input_uncertainty"
    "numerical_resolution"
    ];
policy = [
    "predeclared_common_seed_ensemble"
    "bounded_by_phase13A_prior_ranges"
    "predeclared_window_perturbation"
    "phase11_uncertainty_manifest_context"
    "reuse_phase8_numerical_tolerance_policy"
    ];
n_realizations = [
    numel(cfg.phase13C.seedEnsemble)
    0
    0
    0
    0
    ];
status = [
    "predeclared"
    "predeclared_not_sampled_in_setup"
    "predeclared_not_sampled_in_setup"
    "predeclared_not_sampled_in_setup"
    "predeclared_not_sampled_in_setup"
    ];
ensemble = table(source, policy, n_realizations, status);
end

function firewall = build_calibration_firewall(cfg)
item = [
    "constitutive_form_retuned"
    "device_specific_mechanism_parameters_added"
    "phase6_labels_used_as_targets"
    "raman_predictions_used_as_transport_targets"
    "probe_independent_refit_allowed"
    "automatic_probe_fallback_allowed"
    "prediction_failures_discarded"
    ];
status = [
    string(cfg.phase13C.allowConstitutiveFormRetuning)
    string(cfg.phase13C.allowDeviceSpecificMechanismParameters)
    string(cfg.phase13C.allowPhase6LabelsAsTargets)
    string(cfg.phase13C.allowRamanTransportTargets)
    string(cfg.phase13C.allowProbeIndependentRefit)
    string(cfg.phase13C.allowAutomaticProbeFallback)
    "false"
    ];
allowed = false(numel(item), 1);
note = [
    "Phase 13C consumes the Phase 13A form unchanged."
    "Only shared constitutive/nuisance parameters may be optimized."
    "Frozen interpretation labels are comparison-only."
    "Raman remains qualitative independent context."
    "Both probes share the same network state."
    "AS003 and all devices retain Phase 11 probe mapping."
    "Prediction failure must be reported rather than hidden."
    ];
firewall = table(item, status, allowed, note);
end

function gates = build_gate_summary(cfg, inputs, lock, objective, ...
    parameterManifest, loo, pairs, ensemble, firewall, sourceProvenance)
phase13APass = lookup_status(inputs.phase13AHandoff, ...
    "phase13A_closure", "") == "pass_constitutive_mapping_freeze";
phase13BPass = lookup_status(inputs.phase13BHandoff, ...
    "phase13B_closure", "") == "pass_limiting_case_verification";
as003 = lock(string(lock.device) == "AS003", :);
as003Locked = ~isempty(as003) && ...
    string(as003.primary_probe(1)) == "bottom_3_9" && ...
    string(as003.primary_experimental_channel(1)) == "R2" && ...
    ~logical(as003.has_R1_RT(1)) && logical(as003.has_R2_RT(1)) && ...
    ~logical(as003.automatic_probe_fallback_allowed(1));
objectiveFrozen = abs(sum(objective.weight) - 1) < 1e-12 && ...
    all(objective.predeclared_before_prediction);
sharedOnly = all(~parameterManifest.allowed_for_optimization | ...
    startsWith(string(parameterManifest.parameter_role), "shared_"));
looPredeclared = height(loo) == height(lock) && ...
    all(loo.shared_parameters_only) && ...
    all(~loo.constitutive_form_retuned);
pairedJoint = ~cfg.phase13C.allowProbeIndependentRefit && ...
    (height(pairs) > 0) && ...
    all(~pairs.probe_independent_refit_allowed);
seedPredeclared = any(string(ensemble.source) == "disorder_realization") && ...
    ensemble.n_realizations(string(ensemble.source) == ...
    "disorder_realization") == numel(cfg.phase13C.seedEnsemble);
firewallPass = all(string(firewall.status) == "false");
cleanProvenance = lookup_status(sourceProvenance, ...
    "source_pre_run_clean", "false") == "true";
predictionPending = all(string(loo.execution_status) == ...
    cfg.phase13C.predictionExecutionStatus);

gate = [
    "Phase 13A mapping unchanged"
    "Phase 13B behavior preserved"
    "Experimental data interface frozen"
    "AS003 primary channel locked to R2"
    "Objective and weights predeclared"
    "Shared parameters only"
    "Leave-one-device-out folds predeclared"
    "Paired probes specified jointly"
    "Seed ensemble predeclared"
    "Phase 6 labels not used as targets"
    "Raman not used as transport target"
    "Prediction failures retained"
    "Full RT prediction execution pending"
    "Clean provenance"
    ];
condition = [
    phase13APass
    phase13BPass
    all(string(lock.status) == "locked_before_calibration")
    as003Locked
    objectiveFrozen
    sharedOnly
    looPredeclared
    pairedJoint
    seedPredeclared
    ~cfg.phase13C.allowPhase6LabelsAsTargets
    ~cfg.phase13C.allowRamanTransportTargets
    firewallPass
    predictionPending
    cleanProvenance
    ];
note = [
    "Frozen constitutive mapping is consumed unchanged."
    "Frozen limiting-case verification is consumed unchanged."
    "Device/probe/channel/interface policies are written before fitting."
    "AS003 remains bottom_3_9/R2 with no R1 fallback."
    "Composite RT objective is fixed before prediction."
    "Only shared constitutive/nuisance candidates may be optimized."
    "Six leave-one-device-out folds are declared."
    "Available probe pairs must be predicted from one network state."
    "Seed ensemble is declared before fitting."
    "Interpretive status labels are comparison-only."
    "Raman is not a transport residual or target."
    "Failed predictions remain in output ledgers."
    "This setup phase does not yet claim completed RT prediction."
    "True only when the runner starts from a clean checkout."
    ];
outcome = repmat("fail", numel(gate), 1);
outcome(condition) = "pass";
gates = table(gate, outcome, note);
end

function handoff = build_handoff_status(cfg, gates, sourceProvenance)
allPass = all(string(gates.outcome) == "pass");
item = [
    "phase13C_setup_closure"
    "full_RT_prediction_execution"
    "predictive_adequacy_assessed"
    "constitutive_form_retuned"
    "device_specific_mechanism_parameters"
    "heldout_predictions_completed"
    "prediction_execution_status"
    "source_commit_sha"
    "next_stage"
    ];
status = [
    ternary_status(allPass, "pass_RT_data_objective_lock", ...
        "pending_gate_review")
    "not_run"
    "false"
    string(cfg.phase13C.allowConstitutiveFormRetuning)
    string(cfg.phase13C.allowDeviceSpecificMechanismParameters)
    "false"
    cfg.phase13C.predictionExecutionStatus
    lookup_status(sourceProvenance, "source_commit_sha", "")
    cfg.phase13C.nextPhase
    ];
note = [
    "This is a campaign setup closure, not a full prediction adequacy claim."
    "Full shared R(T) calibration and held-out execution are Phase 13C.2."
    "Predictive adequacy is deferred until execution outputs exist."
    "Phase 13A equations remain frozen."
    "No device-specific mechanism knobs are allowed."
    "Full RT prediction is the next execution step."
    "Prediction tables are schemas/ledgers until solver execution runs."
    "Source commit used to generate Phase 13C setup artifacts."
    "Execute shared calibration and held-out R(T) predictions next."
    ];
handoff = table(item, status, note);
end

function row = empty_RT_lock_row()
row = struct('device', "", 'primary_probe', "", 'secondary_probe', "", ...
    'primary_experimental_channel', "", 'secondary_status', "", ...
    'has_R1_RT', false, 'has_R2_RT', false, 'has_primary_RT', false, ...
    'has_secondary_RT', false, 'temperature_range_policy', "", ...
    'normalization_window_policy', "", ...
    'low_temperature_endpoint_policy', "", 'excluded_points_policy', "", ...
    'interpolation_policy', "", 'uncertainty_policy', "", ...
    'automatic_probe_fallback_allowed', false, 'status', "");
end

function row = empty_loo_row()
row = struct('heldout_device', "", 'training_devices', "", ...
    'primary_channel', "", 'secondary_status', "", ...
    'shared_parameters_only', false, 'constitutive_form_retuned', false, ...
    'phase6_labels_used_as_targets', false, 'execution_status', "", ...
    'description', "");
end

function row = empty_parameter_result_row()
row = struct('heldout_device', "", 'parameter', "", ...
    'fit_status', "not_run_pending_full_RT_solver", ...
    'estimated_value', NaN, 'lower_interval', NaN, ...
    'upper_interval', NaN);
end

function row = empty_prediction_row()
row = struct('device', "", 'primary_channel', "", ...
    'predicted_quantity', "", 'prediction_status', "", ...
    'device_specific_mechanism_retuned', false, ...
    'automatic_probe_fallback_used', false, 'note', "");
end

function row = empty_metric_row()
row = struct('device', "", 'metric', "", 'predicted_value', NaN, ...
    'observed_value', NaN, 'residual', NaN, ...
    'prediction_status', "");
end

function row = empty_residual_row()
row = struct('device', "", 'residual_metric', "", 'residual_value', NaN, ...
    'prediction_status', "");
end

function value = lookup_status(T, itemName, fallback)
value = string(fallback);
if isempty(T) || ~any(strcmp(T.Properties.VariableNames, 'item'))
    return;
end
valueCol = "status";
if any(strcmp(T.Properties.VariableNames, 'value'))
    valueCol = "value";
end
idx = find(string(T.item) == string(itemName), 1, 'first');
if ~isempty(idx) && any(strcmp(T.Properties.VariableNames, valueCol))
    value = string(T.(valueCol)(idx));
end
end

function status = ternary_status(condition, trueValue, falseValue)
if condition
    status = string(trueValue);
else
    status = string(falseValue);
end
end
