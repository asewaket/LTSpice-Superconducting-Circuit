function out = run_phase13D_predictive_adequacy(cfg)
%RUN_PHASE13D_PREDICTIVE_ADEQUACY Assess frozen Phase 13C.2 predictions.
%
% Phase 13D is intentionally read-only. It consumes the frozen Phase 13C.2
% execution artifacts and decides predictive adequacy without rerunning the
% optimizer, changing labels, or modifying the constitutive mapping.

if ~exist(cfg.outputDir, 'dir')
    mkdir(cfg.outputDir);
end

sourceProvenance = build_source_provenance(cfg);
inputs = load_inputs(cfg);
executionValidity = build_execution_validity(inputs);
fullCurveAdequacy = build_full_curve_adequacy(cfg, inputs);
transitionCrossingStatus = build_transition_crossing_status(cfg, inputs);
transitionCrossingConfusion = build_transition_crossing_confusion( ...
    transitionCrossingStatus);
pairedProbeAdequacy = build_paired_probe_adequacy(inputs);
geometryFamilyAdequacy = build_geometry_family_adequacy(cfg, inputs);
uncertaintyCoverage = build_uncertainty_coverage(cfg, inputs);
adequacyDecision = build_predictive_adequacy_decision(cfg, ...
    executionValidity, fullCurveAdequacy, transitionCrossingStatus, ...
    pairedProbeAdequacy, geometryFamilyAdequacy, uncertaintyCoverage);
gateSummary = build_gate_summary(cfg, executionValidity, fullCurveAdequacy, ...
    transitionCrossingStatus, pairedProbeAdequacy, geometryFamilyAdequacy, ...
    uncertaintyCoverage, adequacyDecision);
handoffStatus = build_handoff_status(cfg, adequacyDecision, gateSummary, ...
    sourceProvenance);

writetable(executionValidity, cfg.phase13D.executionValidityFile);
writetable(fullCurveAdequacy, cfg.phase13D.fullCurveAdequacyFile);
writetable(transitionCrossingStatus, ...
    cfg.phase13D.transitionCrossingStatusFile);
writetable(transitionCrossingConfusion, ...
    cfg.phase13D.transitionCrossingConfusionFile);
writetable(pairedProbeAdequacy, cfg.phase13D.pairedProbeAdequacyFile);
writetable(geometryFamilyAdequacy, ...
    cfg.phase13D.geometryFamilyAdequacyFile);
writetable(uncertaintyCoverage, cfg.phase13D.uncertaintyCoverageFile);
writetable(adequacyDecision, ...
    cfg.phase13D.predictiveAdequacyDecisionFile);
writetable(gateSummary, cfg.phase13D.gateSummaryFile);
writetable(handoffStatus, cfg.phase13D.handoffStatusFile);
writetable(sourceProvenance, cfg.phase13D.sourceProvenanceFile);

try
    h = v800.plot_phase13D_predictive_adequacy_summary(cfg, ...
        fullCurveAdequacy, transitionCrossingConfusion, ...
        pairedProbeAdequacy, geometryFamilyAdequacy, ...
        uncertaintyCoverage, gateSummary);
catch ME
    warning('v8:phase13DPlotFailed', ...
        'Phase 13D predictive adequacy summary plot failed: %s', ...
        ME.message);
    h = [];
end

out = struct();
out.config = cfg;
out.inputs = inputs;
out.executionValidity = executionValidity;
out.fullCurveAdequacy = fullCurveAdequacy;
out.transitionCrossingStatus = transitionCrossingStatus;
out.transitionCrossingConfusion = transitionCrossingConfusion;
out.pairedProbeAdequacy = pairedProbeAdequacy;
out.geometryFamilyAdequacy = geometryFamilyAdequacy;
out.uncertaintyCoverage = uncertaintyCoverage;
out.predictiveAdequacyDecision = adequacyDecision;
out.gateSummary = gateSummary;
out.handoffStatus = handoffStatus;
out.sourceProvenance = sourceProvenance;
out.figure = h;
out.paths = build_paths(cfg);
end

function paths = build_paths(cfg)
paths = struct();
paths.executionValidity = cfg.phase13D.executionValidityFile;
paths.fullCurveAdequacy = cfg.phase13D.fullCurveAdequacyFile;
paths.transitionCrossingStatus = cfg.phase13D.transitionCrossingStatusFile;
paths.transitionCrossingConfusion = ...
    cfg.phase13D.transitionCrossingConfusionFile;
paths.pairedProbeAdequacy = cfg.phase13D.pairedProbeAdequacyFile;
paths.geometryFamilyAdequacy = cfg.phase13D.geometryFamilyAdequacyFile;
paths.uncertaintyCoverage = cfg.phase13D.uncertaintyCoverageFile;
paths.predictiveAdequacyDecision = ...
    cfg.phase13D.predictiveAdequacyDecisionFile;
paths.gateSummary = cfg.phase13D.gateSummaryFile;
paths.handoffStatus = cfg.phase13D.handoffStatusFile;
paths.sourceProvenance = cfg.phase13D.sourceProvenanceFile;
paths.figurePng = [cfg.phase13D.figureBaseFile '.png'];
paths.figurePdf = [cfg.phase13D.figureBaseFile '.pdf'];
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
    "phase13D_predictive_adequacy"
    sourceStatus.commit_sha
    sourceStatus.tree_sha
    string(sourceStatus.tracked_clean)
    string(sourceStatus.untracked_clean)
    string(sourceStatus.tracked_clean && sourceStatus.untracked_clean)
    "read_only_assessment_of_frozen_phase13C2_outputs"
    "Commit Phase 13D source first; rerun from clean source; commit adequacy artifacts separately."
    ];
note = [
    "Phase 13D predictive adequacy decision."
    "Git commit captured before this runner writes outputs."
    "Git tree object captured before this runner writes outputs."
    "Tracked-source cleanliness before output generation."
    "Untracked-source/artifact cleanliness before output generation."
    "True only when checkout is clean before this run writes outputs."
    "No optimizer rerun, constitutive retuning, or device relabeling."
    "Adequacy artifacts are separate from source/configuration commits."
    ];
provenance = table(item, value, note);
end

function inputs = load_inputs(cfg)
inputs = struct();
inputs.executionManifest = read_required_table( ...
    cfg.phase13C2.fullRTExecutionManifestFile);
inputs.foldTraining = read_required_table( ...
    cfg.phase13C2.foldTrainingManifestFile);
inputs.devicePredictions = read_required_table( ...
    cfg.phase13C2.deviceRTPredictionsFile);
inputs.transitionMetrics = read_required_table( ...
    cfg.phase13C2.transitionMetricPredictionsFile);
inputs.fullCurveResiduals = read_required_table( ...
    cfg.phase13C2.fullCurveResidualsFile);
inputs.probePairs = read_required_table( ...
    cfg.phase13C2.probePairPredictionsFile);
inputs.geometryFamilyHoldouts = read_required_table( ...
    cfg.phase13C2.geometryFamilyHoldoutResultsFile);
inputs.uncertaintySummary = read_required_table( ...
    cfg.phase13C2.uncertaintyEnsembleSummaryFile);
inputs.failedPredictionLog = read_required_table( ...
    cfg.phase13C2.failedPredictionLogFile);
inputs.solverDiagnostics = read_required_table( ...
    cfg.phase13C2.solverDiagnosticsFile);
inputs.executionGates = read_required_table( ...
    cfg.phase13C2.executionGateSummaryFile);
inputs.executionHandoff = read_required_table( ...
    cfg.phase13C2.executionHandoffStatusFile);
inputs.executionProvenance = read_required_table( ...
    cfg.phase13C2.executionSourceProvenanceFile);
end

function T = read_required_table(pathValue)
if ~exist(pathValue, 'file')
    error('Required Phase 13D input is missing: %s', pathValue);
end
try
    T = readtable(pathValue, 'TextType', 'string', ...
        'VariableNamingRule', 'preserve', 'Delimiter', ',');
catch
    T = readtable(pathValue, 'TextType', 'string', 'Delimiter', ',');
end
end

function T = build_execution_validity(inputs)
allFoldsCompleted = all(string(inputs.foldTraining.fold_status) == ...
    "completed");
heldoutExcluded = all(logical(inputs.foldTraining. ...
    heldout_data_excluded_from_calibration));
sharedOnly = all(logical(inputs.foldTraining.shared_parameters_only));
noRetuning = ~any(logical(inputs.foldTraining.constitutive_form_retuned));
noLabels = ~any(logical(inputs.foldTraining.phase6_labels_used_as_targets));
noRaman = ~any(logical(inputs.foldTraining.raman_used_as_transport_target));
failedCount = failed_prediction_count(inputs.failedPredictionLog);
executionGatesPass = all(string(inputs.executionGates.outcome) == "pass");

check = [
    "all_declared_LODO_folds_completed"
    "heldout_leakage_detected"
    "shared_parameters_only"
    "device_specific_retuning"
    "phase6_labels_used_as_targets"
    "raman_used_as_transport_target"
    "failed_predictions_zero"
    "phase13C2_execution_gates_pass"
    "execution_validity"
    ];
status = [
    passfail(allFoldsCompleted)
    passfail(heldoutExcluded)
    passfail(sharedOnly)
    passfail(noRetuning)
    passfail(noLabels)
    passfail(noRaman)
    passfail(failedCount == 0)
    passfail(executionGatesPass)
    passfail(allFoldsCompleted && heldoutExcluded && sharedOnly && ...
        noRetuning && noLabels && noRaman && failedCount == 0 && ...
        executionGatesPass)
    ];
value = [
    string(allFoldsCompleted)
    string(~heldoutExcluded)
    string(sharedOnly)
    string(~noRetuning)
    string(~noLabels)
    string(~noRaman)
    string(failedCount)
    string(executionGatesPass)
    string(status(end) == "pass")
    ];
note = [
    "All six leave-one-device-out folds completed."
    "Pass means leakage was not detected."
    "All folds used shared parameters."
    "Pass means no constitutive retuning occurred."
    "Pass means frozen Phase 6 labels were not targets."
    "Pass means Raman was not used as a transport target."
    "No solver/prediction failures were recorded."
    "Frozen execution gate table passed."
    "Execution integrity is separate from predictive adequacy."
    ];
T = table(check, status, value, note);
end

function n = failed_prediction_count(failedLog)
if isempty(failedLog)
    n = 0;
elseif any(strcmp(failedLog.Properties.VariableNames, 'failure_reason')) && ...
        all(string(failedLog.failure_reason) == ...
        "no_failed_predictions_recorded")
    n = 0;
elseif any(strcmp(failedLog.Properties.VariableNames, 'n_failed'))
    vals = double(failedLog.n_failed);
    n = sum(vals(~isnan(vals)));
elseif any(strcmp(failedLog.Properties.VariableNames, 'status')) && ...
        all(string(failedLog.status) == "no_failed_predictions_recorded")
    n = 0;
else
    n = height(failedLog);
end
end

function T = build_full_curve_adequacy(cfg, inputs)
R = inputs.fullCurveResiduals;
mask = string(R.probe_role) == "primary";
R = R(mask, :);

device = string(R.device);
probe_role = string(R.probe_role);
residual_value = double(R.residual_value);
training_objective = nan(height(R), 1);
residual_to_training_ratio = nan(height(R), 1);
qualitative_shape_status = strings(height(R), 1);
adequacy_status = strings(height(R), 1);
note = strings(height(R), 1);

for k = 1:height(R)
    idx = string(inputs.foldTraining.heldout_device) == device(k);
    if any(idx)
        training_objective(k) = double(inputs.foldTraining. ...
            training_objective(find(idx, 1)));
        residual_to_training_ratio(k) = residual_value(k) ./ ...
            training_objective(k);
    end
    if residual_value(k) <= cfg.phase13D.fullCurveStrongResidualThreshold
        qualitative_shape_status(k) = "best_available_partial";
        adequacy_status(k) = "partial_predictive_signal";
        note(k) = "Residual is the lowest tier observed in this execution, but adequacy still depends on transition metrics.";
    elseif residual_value(k) <= cfg.phase13D.fullCurvePartialResidualThreshold
        qualitative_shape_status(k) = "partial_directional";
        adequacy_status(k) = "directional_only";
        note(k) = "Residual suggests partial transfer, not quantitative prediction.";
    else
        qualitative_shape_status(k) = "weak_transfer";
        adequacy_status(k) = "poor_quantitative_transfer";
        note(k) = "Residual is too large for a shared quantitative R(T) prediction claim.";
    end
end

T = table(device, probe_role, residual_value, training_objective, ...
    residual_to_training_ratio, qualitative_shape_status, ...
    adequacy_status, note);
end

function T = build_transition_crossing_status(cfg, inputs)
devices = unique(string(inputs.devicePredictions.device), 'stable');
probeRoles = unique(string(inputs.devicePredictions.probe_role), 'stable');
thresholdNames = string(cfg.phase13D.transitionThresholdNames(:));
thresholds = double(cfg.phase13D.transitionThresholds(:));
rows = repmat(empty_crossing_row(), ...
    numel(devices) * numel(probeRoles) * numel(thresholds), 1);
idx = 0;

for d = 1:numel(devices)
    for p = 1:numel(probeRoles)
        curveMask = string(inputs.devicePredictions.device) == devices(d) & ...
            string(inputs.devicePredictions.probe_role) == probeRoles(p);
        C = inputs.devicePredictions(curveMask, :);
        if isempty(C)
            continue;
        end
        for m = 1:numel(thresholds)
            idx = idx + 1;
            obs = classify_curve_crossing(C.observed_Rtilde, thresholds(m));
            pred = classify_curve_crossing(C.predicted_Rtilde_median, ...
                thresholds(m));
            metricMask = string(inputs.transitionMetrics.device) == ...
                devices(d) & string(inputs.transitionMetrics.probe_role) == ...
                probeRoles(p) & string(inputs.transitionMetrics.metric) == ...
                thresholdNames(m);
            predictedValue = NaN;
            observedValue = NaN;
            numericalError = NaN;
            if any(metricMask)
                row = inputs.transitionMetrics(find(metricMask, 1), :);
                predictedValue = double(row.predicted_value);
                observedValue = double(row.observed_value);
                numericalError = double(row.residual);
            end

            rows(idx).device = devices(d);
            rows(idx).probe_role = probeRoles(p);
            rows(idx).metric = thresholdNames(m);
            rows(idx).threshold_Rtilde = thresholds(m);
            rows(idx).observed_crosses = obs.crosses;
            rows(idx).predicted_crosses = pred.crosses;
            rows(idx).T_metric_predicted_K = predictedValue;
            rows(idx).T_metric_observed_K = observedValue;
            rows(idx).numerical_error_K = numericalError;
            rows(idx).T_comparison_status = crossing_status(obs, pred);
            rows(idx).note = crossing_note(rows(idx).T_comparison_status);
        end
    end
end

rows = rows(1:idx);
T = struct2table(rows);
end

function row = empty_crossing_row()
row = struct('device', "", 'probe_role', "", 'metric', "", ...
    'threshold_Rtilde', NaN, 'observed_crosses', false, ...
    'predicted_crosses', false, 'T_metric_predicted_K', NaN, ...
    'T_metric_observed_K', NaN, 'numerical_error_K', NaN, ...
    'T_comparison_status', "", 'note', "");
end

function out = classify_curve_crossing(values, threshold)
v = double(values);
v = v(isfinite(v));
out = struct();
out.ambiguous = numel(v) < 3;
if out.ambiguous
    out.crosses = false;
else
    out.crosses = min(v) <= threshold && max(v) >= threshold;
end
end

function status = crossing_status(obs, pred)
if obs.ambiguous || pred.ambiguous
    status = "crossing_ambiguous";
elseif obs.crosses && pred.crosses
    status = "both_cross";
elseif obs.crosses && ~pred.crosses
    status = "observed_cross_predicted_no_cross";
elseif ~obs.crosses && pred.crosses
    status = "observed_no_cross_predicted_cross";
else
    status = "neither_crosses";
end
end

function note = crossing_note(status)
switch string(status)
    case "both_cross"
        note = "Numerical threshold error can be interpreted.";
    case "observed_cross_predicted_no_cross"
        note = "Categorical prediction failure for this transition threshold.";
    case "observed_no_cross_predicted_cross"
        note = "False predicted transition depth for this threshold.";
    case "neither_crosses"
        note = "Correctly predicts censored/non-crossing behavior for this threshold.";
    otherwise
        note = "Crossing definition is ambiguous for this curve/threshold.";
end
end

function T = build_transition_crossing_confusion(statusTable)
metrics = unique(string(statusTable.metric), 'stable');
statuses = [
    "both_cross"
    "observed_cross_predicted_no_cross"
    "observed_no_cross_predicted_cross"
    "neither_crosses"
    "crossing_ambiguous"
    ];
rows = repmat(struct('metric', "", 'T_comparison_status', "", ...
    'count', 0, 'fraction', NaN), numel(metrics) * numel(statuses), 1);
idx = 0;
for m = 1:numel(metrics)
    metricMask = string(statusTable.metric) == metrics(m);
    denom = sum(metricMask);
    for s = 1:numel(statuses)
        idx = idx + 1;
        n = sum(metricMask & string(statusTable.T_comparison_status) == ...
            statuses(s));
        rows(idx).metric = metrics(m);
        rows(idx).T_comparison_status = statuses(s);
        rows(idx).count = n;
        if denom > 0
            rows(idx).fraction = n ./ denom;
        end
    end
end
T = struct2table(rows);
end

function T = build_paired_probe_adequacy(inputs)
P = inputs.probePairs;
device = string(P.device);
primary_probe = string(P.primary_probe);
secondary_probe = string(P.secondary_probe);
asymmetry_score = double(P.asymmetry_score);
onset_difference_residual_K = double(P.onset_difference_residual_K);
probe_transfer_status = strings(height(P), 1);
note = strings(height(P), 1);

for k = 1:height(P)
    if isnan(onset_difference_residual_K(k))
        probe_transfer_status(k) = "asymmetry_scored_onset_undefined";
        note(k) = "A_probe(T) score is available, but relative onset could not be compared.";
    elseif abs(onset_difference_residual_K(k)) <= 0.1
        probe_transfer_status(k) = "paired_probe_transfer_supported";
        note(k) = "Both asymmetry and onset metrics are finite.";
    else
        probe_transfer_status(k) = "paired_probe_transfer_limited";
        note(k) = "The paired-probe onset residual is too large for spatial prediction.";
    end
end

T = table(device, primary_probe, secondary_probe, asymmetry_score, ...
    onset_difference_residual_K, probe_transfer_status, note);
end

function T = build_geometry_family_adequacy(cfg, inputs)
G = inputs.geometryFamilyHoldouts;
family_holdout = string(G.family_holdout);
heldout_devices = string(G.heldout_devices);
mean_full_curve_residual = double(G.mean_full_curve_residual);
execution_status = string(G.execution_status);
family_transfer_status = strings(height(G), 1);
note = strings(height(G), 1);

for k = 1:height(G)
    if execution_status(k) ~= "completed"
        family_transfer_status(k) = "not_executed";
        note(k) = "Family holdout was declared but not completed.";
    elseif mean_full_curve_residual(k) <= ...
            cfg.phase13D.familyAdequacyResidualThreshold
        family_transfer_status(k) = "family_transfer_partial";
        note(k) = "Residual is within the predeclared partial family-transfer band.";
    else
        family_transfer_status(k) = "family_transfer_weak";
        note(k) = "Residual is too large for quantitative geometry-family transfer.";
    end
end

T = table(family_holdout, heldout_devices, mean_full_curve_residual, ...
    execution_status, family_transfer_status, note);
end

function T = build_uncertainty_coverage(cfg, inputs)
D = inputs.devicePredictions;
devices = unique(string(D.device), 'stable');
rows = repmat(struct('device', "", 'probe_role', "", ...
    'n_points', 0, 'coverage_fraction', NaN, ...
    'mean_interval_width', NaN, 'coverage_status', "", 'note', ""), ...
    numel(devices) * 2, 1);
idx = 0;
for d = 1:numel(devices)
    probeRoles = unique(string(D.probe_role(string(D.device) == ...
        devices(d))), 'stable');
    for p = 1:numel(probeRoles)
        mask = string(D.device) == devices(d) & ...
            string(D.probe_role) == probeRoles(p);
        C = D(mask, :);
        obs = double(C.observed_Rtilde);
        lo = double(C.predicted_Rtilde_lower);
        hi = double(C.predicted_Rtilde_upper);
        finite = isfinite(obs) & isfinite(lo) & isfinite(hi);
        idx = idx + 1;
        rows(idx).device = devices(d);
        rows(idx).probe_role = probeRoles(p);
        rows(idx).n_points = sum(finite);
        if any(finite)
            rows(idx).coverage_fraction = mean(obs(finite) >= lo(finite) & ...
                obs(finite) <= hi(finite));
            rows(idx).mean_interval_width = mean(hi(finite) - lo(finite));
        end
        if rows(idx).coverage_fraction >= cfg.phase13D.minimumCoverageTarget
            rows(idx).coverage_status = "coverage_supported";
            rows(idx).note = "Prediction interval covers a sufficient fraction of observed points.";
        elseif rows(idx).mean_interval_width > 0.25
            rows(idx).coverage_status = "broad_uncertain";
            rows(idx).note = "Coverage may be acceptable only because intervals are broad.";
        else
            rows(idx).coverage_status = "overconfident_or_mismatched";
            rows(idx).note = "Prediction interval coverage is low relative to the target.";
        end
    end
end
rows = rows(1:idx);
T = struct2table(rows);
end

function T = build_predictive_adequacy_decision(cfg, executionValidity, ...
    fullCurveAdequacy, transitionCrossingStatus, pairedProbeAdequacy, ...
    geometryFamilyAdequacy, uncertaintyCoverage)
executionPass = any(string(executionValidity.check) == ...
    "execution_validity" & string(executionValidity.status) == "pass");
residuals = double(fullCurveAdequacy.residual_value);
strongEnough = residuals <= ...
    cfg.phase13D.predictiveAdequacyPassResidualThreshold;
passFraction = mean(strongEnough);
missingNumericalTransitionFraction = mean(isnan(double( ...
    transitionCrossingStatus.numerical_error_K)));
pairedLimited = any(contains(string( ...
    pairedProbeAdequacy.probe_transfer_status), "undefined"));
familyWeak = any(string(geometryFamilyAdequacy.family_transfer_status) == ...
    "family_transfer_weak");
coverageWeak = any(string(uncertaintyCoverage.coverage_status) == ...
    "overconfident_or_mismatched");

if ~executionPass
    decision = "fail_invalid_execution";
elseif passFraction >= cfg.phase13D.predictiveAdequacyPassFractionTarget && ...
        missingNumericalTransitionFraction < 0.5 && ~coverageWeak
    decision = "pass_shared_RT_forward_model";
elseif passFraction > 0 && (familyWeak || pairedLimited || coverageWeak)
    decision = "pass_partial_predictive_scope";
else
    decision = "fail_constitutive_mapping_not_transferable";
end

field = [
    "phase13D_assessment_mode"
    "execution_validity"
    "primary_residual_pass_fraction"
    "minimum_required_residual_pass_fraction"
    "missing_numerical_transition_fraction"
    "paired_probe_limitation_present"
    "geometry_family_weak_transfer_present"
    "uncertainty_coverage_limitation_present"
    "shared_quantitative_RT_predictive_model"
    "phase13D_decision"
    ];
value = [
    "read_only_no_refit"
    string(executionPass)
    string(passFraction)
    string(cfg.phase13D.predictiveAdequacyPassFractionTarget)
    string(missingNumericalTransitionFraction)
    string(pairedLimited)
    string(familyWeak)
    string(coverageWeak)
    string(decision == "pass_shared_RT_forward_model")
    decision
    ];
note = [
    "Consumes frozen Phase 13C.2 outputs only."
    "Execution integrity is evaluated separately from adequacy."
    "Fraction of primary held-out devices below the adequacy residual threshold."
    "Predeclared target for a shared quantitative R(T) claim."
    "NaN transition errors are treated as explicit censored/categorical outcomes."
    "Paired-probe onset comparison is unavailable for at least one paired device."
    "At least one geometry-family holdout has weak transfer."
    "At least one device/probe has low predictive interval coverage."
    "False means no universal quantitative shared R(T) claim is frozen."
    "Final Phase 13D adequacy decision."
    ];
T = table(field, value, note);
end

function T = build_gate_summary(cfg, executionValidity, fullCurveAdequacy, ...
    transitionCrossingStatus, pairedProbeAdequacy, geometryFamilyAdequacy, ...
    uncertaintyCoverage, adequacyDecision)
executionPass = any(string(executionValidity.check) == ...
    "execution_validity" & string(executionValidity.status) == "pass");
noRefit = ~cfg.phase13D.allowOptimizerRerun && ...
    ~cfg.phase13D.allowConstitutiveRetuning && ...
    ~cfg.phase13D.allowDeviceRelabeling;
crossingsClassified = all(string(transitionCrossingStatus. ...
    T_comparison_status) ~= "");
pairedAssessed = ~isempty(pairedProbeAdequacy);
familyAssessed = ~isempty(geometryFamilyAdequacy);
coverageAssessed = ~isempty(uncertaintyCoverage);
decisionFrozen = any(string(adequacyDecision.field) == ...
    "phase13D_decision");
quantitativePass = any(string(adequacyDecision.field) == ...
    "shared_quantitative_RT_predictive_model" & ...
    string(adequacyDecision.value) == "true");

component = [
    "Phase 13C.2 execution validity separated"
    "Read-only assessment policy preserved"
    "Full-curve residuals assessed"
    "Transition crossing classes recorded"
    "Paired-probe transfer assessed"
    "Geometry-family transfer assessed"
    "Uncertainty coverage assessed"
    "Shared quantitative RT predictor"
    "Phase 13D decision frozen"
    ];
outcome = [
    passfail(executionPass)
    passfail(noRefit)
    passfail(~isempty(fullCurveAdequacy))
    passfail(crossingsClassified)
    passfail(pairedAssessed)
    passfail(familyAssessed)
    passfail(coverageAssessed)
    passfail(quantitativePass)
    passfail(decisionFrozen)
    ];
note = [
    "Execution integrity is not conflated with predictive adequacy."
    "No optimizer rerun, retuning, or relabeling is allowed."
    "Held-out full-curve residuals were classified by device."
    "T90/T50/T10 NaN values are explicit status outcomes."
    "AS001/AS004/AS006 paired probes were evaluated."
    "Declared geometry-family holdouts were evaluated."
    "Prediction intervals were compared with observations."
    "This gate may fail while the assessment phase itself passes."
    "The final adequacy decision was written."
    ];
T = table(component, outcome, note);
end

function T = build_handoff_status(cfg, adequacyDecision, gateSummary, ...
    sourceProvenance)
decision = lookup_value(adequacyDecision, "phase13D_decision");
sourceCommit = lookup_value(sourceProvenance, "source_commit_sha");
phasePass = all(string(gateSummary.outcome( ...
    string(gateSummary.component) ~= "Shared quantitative RT predictor")) == ...
    "pass");
field = [
    "phase13D_closure"
    "predictive_adequacy_decision"
    "shared_quantitative_RT_predictor"
    "source_commit_sha"
    "next_phase"
    ];
value = [
    conditional(phasePass, "pass_read_only_adequacy_assessment", ...
        "fail_assessment_incomplete")
    decision
    string(decision == "pass_shared_RT_forward_model")
    sourceCommit
    cfg.phase13D.nextPhase
    ];
note = [
    "Phase closure concerns assessment completeness, not model adequacy."
    "Frozen decision from the adequacy table."
    "False preserves the distinction between execution integrity and prediction adequacy."
    "Source commit captured before outputs were written."
    "Recommended handoff after this adequacy decision."
    ];
T = table(field, value, note);
end

function out = lookup_value(T, key)
if any(strcmp(T.Properties.VariableNames, 'field'))
    mask = string(T.field) == string(key);
elseif any(strcmp(T.Properties.VariableNames, 'item'))
    mask = string(T.item) == string(key);
else
    mask = false(height(T), 1);
end
if any(mask)
    out = string(T.value(find(mask, 1)));
else
    out = "";
end
end

function s = passfail(tf)
if tf
    s = "pass";
else
    s = "fail";
end
end

function s = conditional(tf, a, b)
if tf
    s = string(a);
else
    s = string(b);
end
end
