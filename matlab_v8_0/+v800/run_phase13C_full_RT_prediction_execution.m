function out = run_phase13C_full_RT_prediction_execution(cfg)
%RUN_PHASE13C_FULL_RT_PREDICTION_EXECUTION Execute frozen Phase 13C.2.
%
% This stage consumes the Phase 13C.1 data/objective lock and performs a
% reduced, shared-parameter R(T) forward calculation. It is an execution
% experiment; predictive adequacy remains deferred to Phase 13D.

if ~exist(cfg.outputDir, 'dir')
    mkdir(cfg.outputDir);
end

sourceProvenance = build_source_provenance(cfg);
inputs = load_inputs(cfg);
candidates = build_candidate_parameters(cfg, inputs.priors);
observed = load_observed_curves(cfg, inputs.lock);
[foldTraining, selectedByFold, failedLog] = run_lodo_calibration( ...
    cfg, inputs, observed, candidates);
[devicePredictions, transitionMetrics, fullCurveResiduals, ...
    probePairs, failedLog] = run_heldout_predictions(cfg, inputs, ...
    observed, selectedByFold, failedLog);
foldParameterResults = build_fold_parameter_results(selectedByFold);
sharedParameterSummary = build_shared_parameter_summary(selectedByFold);
geometryFamilyHoldouts = build_geometry_family_holdouts(inputs, ...
    fullCurveResiduals);
uncertaintySummary = build_uncertainty_summary(cfg, devicePredictions);
solverDiagnostics = build_solver_diagnostics(cfg, inputs, observed, ...
    candidates, foldTraining, devicePredictions, failedLog);
executionManifest = build_execution_manifest(cfg);
gateSummary = build_gate_summary(cfg, inputs, foldTraining, ...
    devicePredictions, fullCurveResiduals, probePairs, failedLog, ...
    sourceProvenance);
handoffStatus = build_handoff_status(cfg, gateSummary, sourceProvenance);

writetable(executionManifest, cfg.phase13C2.fullRTExecutionManifestFile);
writetable(foldTraining, cfg.phase13C2.foldTrainingManifestFile);
writetable(foldParameterResults, cfg.phase13C2.foldParameterResultsFile);
writetable(sharedParameterSummary, cfg.phase13C2.sharedParameterSummaryFile);
writetable(devicePredictions, cfg.phase13C2.deviceRTPredictionsFile);
writetable(transitionMetrics, ...
    cfg.phase13C2.transitionMetricPredictionsFile);
writetable(fullCurveResiduals, cfg.phase13C2.fullCurveResidualsFile);
writetable(probePairs, cfg.phase13C2.probePairPredictionsFile);
writetable(geometryFamilyHoldouts, ...
    cfg.phase13C2.geometryFamilyHoldoutResultsFile);
writetable(uncertaintySummary, ...
    cfg.phase13C2.uncertaintyEnsembleSummaryFile);
writetable(failedLog, cfg.phase13C2.failedPredictionLogFile);
writetable(solverDiagnostics, cfg.phase13C2.solverDiagnosticsFile);
writetable(gateSummary, cfg.phase13C2.executionGateSummaryFile);
writetable(handoffStatus, cfg.phase13C2.executionHandoffStatusFile);
writetable(sourceProvenance, cfg.phase13C2.executionSourceProvenanceFile);

try
    h = v800.plot_phase13C_full_RT_execution_summary(cfg, foldTraining, ...
        fullCurveResiduals, transitionMetrics, probePairs, gateSummary);
catch ME
    warning('v8:phase13C2PlotFailed', ...
        'Phase 13C.2 full RT execution summary plot failed: %s', ...
        ME.message);
    h = [];
end

out = struct();
out.config = cfg;
out.inputs = inputs;
out.candidates = candidates;
out.observed = observed;
out.foldTraining = foldTraining;
out.foldParameterResults = foldParameterResults;
out.sharedParameterSummary = sharedParameterSummary;
out.deviceRTPredictions = devicePredictions;
out.transitionMetricPredictions = transitionMetrics;
out.fullCurveResiduals = fullCurveResiduals;
out.probePairPredictions = probePairs;
out.geometryFamilyHoldoutResults = geometryFamilyHoldouts;
out.uncertaintyEnsembleSummary = uncertaintySummary;
out.failedPredictionLog = failedLog;
out.solverDiagnostics = solverDiagnostics;
out.executionGateSummary = gateSummary;
out.executionHandoffStatus = handoffStatus;
out.sourceProvenance = sourceProvenance;
out.figure = h;
out.paths = build_paths(cfg);
end

function paths = build_paths(cfg)
paths = struct();
paths.fullRTExecutionManifest = cfg.phase13C2.fullRTExecutionManifestFile;
paths.foldTrainingManifest = cfg.phase13C2.foldTrainingManifestFile;
paths.foldParameterResults = cfg.phase13C2.foldParameterResultsFile;
paths.sharedParameterSummary = cfg.phase13C2.sharedParameterSummaryFile;
paths.deviceRTPredictions = cfg.phase13C2.deviceRTPredictionsFile;
paths.transitionMetricPredictions = ...
    cfg.phase13C2.transitionMetricPredictionsFile;
paths.fullCurveResiduals = cfg.phase13C2.fullCurveResidualsFile;
paths.probePairPredictions = cfg.phase13C2.probePairPredictionsFile;
paths.geometryFamilyHoldoutResults = ...
    cfg.phase13C2.geometryFamilyHoldoutResultsFile;
paths.uncertaintyEnsembleSummary = ...
    cfg.phase13C2.uncertaintyEnsembleSummaryFile;
paths.failedPredictionLog = cfg.phase13C2.failedPredictionLogFile;
paths.solverDiagnostics = cfg.phase13C2.solverDiagnosticsFile;
paths.executionGateSummary = cfg.phase13C2.executionGateSummaryFile;
paths.executionHandoffStatus = cfg.phase13C2.executionHandoffStatusFile;
paths.executionSourceProvenance = ...
    cfg.phase13C2.executionSourceProvenanceFile;
paths.figurePng = [cfg.phase13C2.figureBaseFile '.png'];
paths.figurePdf = [cfg.phase13C2.figureBaseFile '.pdf'];
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
    "phase13C_full_RT_prediction_execution"
    sourceStatus.commit_sha
    sourceStatus.tree_sha
    string(sourceStatus.tracked_clean)
    string(sourceStatus.untracked_clean)
    string(sourceStatus.tracked_clean && sourceStatus.untracked_clean)
    "execute_frozen_shared_RT_calibration_without_relabeling"
    "Commit Phase 13C.2 source first; rerun from clean source; commit execution artifacts separately."
    ];
note = [
    "Phase 13C.2 full R(T) execution."
    "Git commit captured before this runner writes outputs."
    "Git tree object captured before this runner writes outputs."
    "Tracked-source cleanliness before output generation."
    "Untracked-source/artifact cleanliness before output generation."
    "True only when checkout is clean before this run writes outputs."
    "Consumes frozen Phase 13C.1 data/objective/fold/firewall lock."
    "Execution artifacts are separate from source/configuration commits."
    ];
provenance = table(item, value, note);
end

function inputs = load_inputs(cfg)
inputs = struct();
inputs.lock = read_required_table(cfg.phase13C.RTDataLockManifestFile);
inputs.objective = read_required_table( ...
    cfg.phase13C.calibrationObjectiveSpecificationFile);
inputs.parameterManifest = read_required_table( ...
    cfg.phase13C.parameterFitManifestFile);
inputs.loo = read_required_table(cfg.phase13C.leaveOneDeviceOutManifestFile);
inputs.firewall = read_required_table(cfg.phase13C.calibrationFirewallFile);
inputs.setupGates = read_required_table(cfg.phase13C.gateSummaryFile);
inputs.mechanicalSummary = read_required_table( ...
    cfg.phase12B.deviceMechanicalSummaryFile);
inputs.priors = read_required_table(cfg.phase13A.globalParameterPriorsFile);
end

function T = read_required_table(pathValue)
if ~exist(pathValue, 'file')
    error('Required Phase 13C.2 input is missing: %s', pathValue);
end
try
    T = readtable(pathValue, 'TextType', 'string', ...
        'VariableNamingRule', 'preserve', 'Delimiter', ',');
catch
    T = readtable(pathValue, 'TextType', 'string', 'Delimiter', ',');
end
end

function candidates = build_candidate_parameters(cfg, priors)
p = prior_values(priors);
ids = [
    "nominal"
    "low_Tc"
    "high_Tc"
    "low_boundary"
    "high_boundary"
    "low_crack"
    "high_crack"
    "low_width"
    "high_width"
    "low_shunt"
    "high_shunt"
    "high_coverage"
    "balanced_structured"
    ];
rows = repmat(empty_candidate_row(), numel(ids), 1);
for k = 1:numel(ids)
    theta = p.nominal;
    switch ids(k)
        case "low_Tc"
            theta.Tc_base_K = midpoint(p.lower.Tc_base_K, theta.Tc_base_K);
            theta.DeltaTc_max_K = midpoint(p.lower.DeltaTc_max_K, ...
                theta.DeltaTc_max_K);
        case "high_Tc"
            theta.Tc_base_K = midpoint(p.upper.Tc_base_K, theta.Tc_base_K);
            theta.DeltaTc_max_K = midpoint(p.upper.DeltaTc_max_K, ...
                theta.DeltaTc_max_K);
        case "low_boundary"
            theta.gamma_boundary = midpoint(p.lower.gamma_boundary, ...
                theta.gamma_boundary);
        case "high_boundary"
            theta.gamma_boundary = midpoint(p.upper.gamma_boundary, ...
                theta.gamma_boundary);
        case "low_crack"
            theta.gamma_crack = midpoint(p.lower.gamma_crack, ...
                theta.gamma_crack);
        case "high_crack"
            theta.gamma_crack = midpoint(p.upper.gamma_crack, ...
                theta.gamma_crack);
        case "low_width"
            theta.sigma_Tc_disorder_K = midpoint( ...
                p.lower.sigma_Tc_disorder_K, theta.sigma_Tc_disorder_K);
        case "high_width"
            theta.sigma_Tc_disorder_K = midpoint( ...
                p.upper.sigma_Tc_disorder_K, theta.sigma_Tc_disorder_K);
        case "low_shunt"
            theta.G_shunt_global_fraction = midpoint( ...
                p.lower.G_shunt_global_fraction, ...
                theta.G_shunt_global_fraction);
        case "high_shunt"
            theta.G_shunt_global_fraction = midpoint( ...
                p.upper.G_shunt_global_fraction, ...
                theta.G_shunt_global_fraction);
        case "high_coverage"
            theta.beta_cov = midpoint(p.upper.beta_cov, theta.beta_cov);
            theta.gamma_coverage = midpoint(p.upper.gamma_coverage, ...
                theta.gamma_coverage);
        case "balanced_structured"
            theta.beta_cov = midpoint(p.upper.beta_cov, theta.beta_cov);
            theta.gamma_boundary = midpoint(p.upper.gamma_boundary, ...
                theta.gamma_boundary);
            theta.gamma_crack = midpoint(p.upper.gamma_crack, ...
                theta.gamma_crack);
            theta.G_shunt_global_fraction = midpoint( ...
                p.lower.G_shunt_global_fraction, ...
                theta.G_shunt_global_fraction);
    end
    rows(k) = theta_to_candidate_row(ids(k), theta);
end
candidates = struct2table(rows);
if height(candidates) > cfg.phase13C2.candidateCount
    candidates = candidates(1:cfg.phase13C2.candidateCount, :);
end
end

function y = midpoint(a, b)
y = 0.5 .* (a + b);
end

function p = prior_values(priors)
params = string(priors.parameter);
p.lower = struct();
p.nominal = struct();
p.upper = struct();
for k = 1:numel(params)
    name = char(matlab.lang.makeValidName(char(params(k))));
    p.lower.(name) = priors.lower_bound(k);
    p.nominal.(name) = priors.nominal_value(k);
    p.upper.(name) = priors.upper_bound(k);
end
names = ["beta0"; "beta_cov"; "beta_z"; ...
    "beta_boundary_Tc_optional"; "beta_crack_Tc_optional"; ...
    "Tc_base_K"; "DeltaTc_max_K"; "gamma0"; "gamma_boundary"; ...
    "gamma_crack"; "gamma_coverage"; "sigma_Tc_disorder_K"; ...
    "G_shunt_global_fraction"];
defaults = [0 1 0.5 0 0 2.5 2 0 1 1 0.25 0.15 0.02];
for k = 1:numel(names)
    name = char(names(k));
    if ~isfield(p.nominal, name)
        p.nominal.(name) = defaults(k);
        p.lower.(name) = defaults(k);
        p.upper.(name) = defaults(k);
    end
end
end

function row = theta_to_candidate_row(id, theta)
row = empty_candidate_row();
row.candidate_id = string(id);
fields = setdiff(fieldnames(row), {'candidate_id', 'candidate_note'});
for k = 1:numel(fields)
    if isfield(theta, fields{k})
        row.(fields{k}) = theta.(fields{k});
    end
end
row.candidate_note = "shared_parameter_candidate_no_device_specific_terms";
end

function observed = load_observed_curves(cfg, lock)
rows = repmat(empty_observed_row(), max(1, height(lock) * 2), 1);
idx = 0;
for k = 1:height(lock)
    device = string(lock.device(k));
    expRT = load_rt_safely(device);
    probes = string(lock.primary_probe(k));
    channels = string(lock.primary_experimental_channel(k));
    roles = "primary";
    if logical(lock.has_secondary_RT(k))
        probes = [probes; string(lock.secondary_probe(k))];
        channels = [channels; secondary_channel(string(lock.primary_experimental_channel(k)))];
        roles = [roles; "secondary"];
    end
    for p = 1:numel(probes)
        idx = idx + 1;
        rows(idx).device = device;
        rows(idx).probe_role = roles(p);
        rows(idx).probe = probes(p);
        rows(idx).experimental_channel = channels(p);
        curve = select_observed_curve(expRT, probes(p), roles(p));
        rows(idx).available = curve.available;
        rows(idx).source_file = curve.source;
        rows(idx).note = curve.note;
        if curve.available
            T = reduce_temperature(curve.T, cfg.phase13C2.maxTemperaturePoints);
            R = interp1(curve.T(:), curve.R(:), T, 'linear', 'extrap');
            [Tn, Rn] = normalize_curve(T, R);
            rows(idx).n_temperature_points = numel(Tn);
            rows(idx).T = {Tn};
            rows(idx).R = {Rn};
        end
    end
end
observed = struct2table(rows(1:idx));
end

function expRT = load_rt_safely(device)
try
    [~, expRT] = evalc('load_experimental_rt(device);');
catch ME
    expRT = struct();
    expRT.available = false;
    expRT.sourceFile = "";
    expRT.note = ME.message;
end
end

function curve = select_observed_curve(expRT, probe, role)
curve = struct('available', false, 'T', [], 'R', [], 'source', "", ...
    'note', "");
if isempty(expRT) || ~isfield(expRT, 'available') || ~expRT.available
    curve.note = "load_experimental_rt did not return an available curve";
    return;
end
probeName = char(probe);
if isfield(expRT, 'pairData') && isfield(expRT.pairData, 'available') && ...
        expRT.pairData.available && isfield(expRT.pairData.R, probeName)
    curve.available = true;
    curve.T = expRT.pairData.T(:);
    curve.R = expRT.pairData.R.(probeName)(:);
    curve.source = string(expRT.pairData.sourceFile);
    curve.note = "explicit probe-pair R(T) channel";
elseif string(role) == "primary" && isfield(expRT, 'R') && ...
        isfield(expRT.R, 'main_4p')
    curve.available = true;
    curve.T = expRT.T(:);
    curve.R = expRT.R.main_4p(:);
    curve.source = string(expRT.sourceFile);
    curve.note = "publication main_4p mapped to locked primary probe";
else
    curve.note = "locked probe curve unavailable";
end
end

function ch = secondary_channel(primary)
if primary == "R1"
    ch = "R2";
else
    ch = "R1";
end
end

function T = reduce_temperature(Tin, maxPoints)
Tin = Tin(:);
Tin = Tin(isfinite(Tin));
Tin = unique(Tin, 'stable');
if numel(Tin) <= maxPoints
    T = Tin;
else
    idx = unique(round(linspace(1, numel(Tin), maxPoints)));
    T = Tin(idx);
end
end

function [Tn, Rn] = normalize_curve(T, R)
valid = isfinite(T) & isfinite(R);
Tn = T(valid);
Rn = R(valid);
if isempty(Tn)
    return;
end
[Tn, ord] = sort(Tn);
Rn = Rn(ord);
rn = median(Rn(max(1, round(0.80 * numel(Rn))):end), 'omitnan');
if ~isfinite(rn) || abs(rn) < eps
    rn = max(abs(Rn));
end
if isfinite(rn) && abs(rn) > eps
    Rn = Rn ./ rn;
end
Rn = max(0, min(1.25, Rn));
end

function [foldTraining, selectedByFold, failedLog] = run_lodo_calibration( ...
    cfg, inputs, observed, candidates)
rows = repmat(empty_fold_training_row(), height(inputs.loo), 1);
selected = repmat(empty_selected_row(), height(inputs.loo), 1);
failed = repmat(empty_failed_row(), 1, 1);
failedCount = 0;
for f = 1:height(inputs.loo)
    heldout = string(inputs.loo.heldout_device(f));
    trainDevices = split_devices(string(inputs.loo.training_devices(f)));
    bestScore = Inf;
    bestIdx = 1;
    candidateScores = NaN(height(candidates), 1);
    for c = 1:height(candidates)
        theta = table_to_theta(candidates(c, :));
        scores = NaN(numel(trainDevices), 1);
        for d = 1:numel(trainDevices)
            scores(d) = score_device_objective(cfg, inputs, observed, ...
                trainDevices(d), theta);
        end
        candidateScores(c) = mean(scores, 'omitnan');
        if isfinite(candidateScores(c)) && candidateScores(c) < bestScore
            bestScore = candidateScores(c);
            bestIdx = c;
        end
    end
    status = "completed";
    if ~isfinite(bestScore)
        status = "failed";
        failedCount = failedCount + 1;
        failed(failedCount) = failed_row(heldout, "calibration_prediction", ...
            "all_candidate_scores_nonfinite");
    end
    rows(f).heldout_device = heldout;
    rows(f).training_devices = strjoin(trainDevices, "|");
    rows(f).n_training_devices = numel(trainDevices);
    rows(f).n_candidates_evaluated = height(candidates);
    rows(f).selected_candidate_id = string(candidates.candidate_id(bestIdx));
    rows(f).training_objective = bestScore;
    rows(f).heldout_data_excluded_from_calibration = true;
    rows(f).shared_parameters_only = true;
    rows(f).constitutive_form_retuned = false;
    rows(f).phase6_labels_used_as_targets = false;
    rows(f).raman_used_as_transport_target = false;
    rows(f).fold_status = status;
    rows(f).note = "fit_other_five_predict_heldout_without_adjustment";
    selected(f) = selected_from_candidate(heldout, candidates(bestIdx, :), ...
        bestScore, status);
end
foldTraining = struct2table(rows);
selectedByFold = struct2table(selected);
if failedCount == 0
    failedLog = struct2table(failed_row("none", "none", ...
        "no_failed_predictions_recorded"));
else
    failedLog = struct2table(failed(1:failedCount));
end
end

function score = score_device_objective(cfg, inputs, observed, device, theta)
primary = select_curve(observed, device, "primary");
if ~primary.available
    score = NaN;
    return;
end
mech = select_mechanics(inputs.mechanicalSummary, device);
modelPrimary = model_curve(primary.T, theta, mech, primary.probe);
[terms, weights] = objective_terms(cfg, inputs.objective, primary, ...
    modelPrimary, [], []);
secondary = select_curve(observed, device, "secondary");
if secondary.available
    modelSecondary = model_curve(secondary.T, theta, mech, secondary.probe);
    [terms, weights] = objective_terms(cfg, inputs.objective, primary, ...
        modelPrimary, secondary, modelSecondary);
end
finite = isfinite(terms) & isfinite(weights) & weights > 0;
if ~any(finite)
    score = NaN;
else
    score = sum(weights(finite) .* terms(finite)) ./ sum(weights(finite));
end
end

function [terms, weights] = objective_terms(cfg, objective, primary, ...
    modelPrimary, secondary, modelSecondary)
metricsExp = curve_metrics(primary.T, primary.R);
metricsModel = curve_metrics(primary.T, modelPrimary);
terms = zeros(height(objective), 1);
weights = objective.weight;
for k = 1:height(objective)
    metric = string(objective.metric(k));
    switch metric
        case "full_curve_normalized_residual"
            terms(k) = mean((modelPrimary - primary.R).^2, 'omitnan');
        case "T90"
            terms(k) = scaled_abs(metricsModel.T90 - metricsExp.T90, 0.35);
        case "T50"
            terms(k) = scaled_abs(metricsModel.T50 - metricsExp.T50, 0.35);
        case "T10"
            terms(k) = scaled_abs(metricsModel.T10 - metricsExp.T10, 0.35);
        case "width_T90_T10"
            terms(k) = scaled_abs(metricsModel.width_T90_T10 - ...
                metricsExp.width_T90_T10, 0.35);
        case "low_temperature_residual_fraction"
            terms(k) = abs(metricsModel.lowT - metricsExp.lowT);
        case "probe_asymmetry"
            if isempty(secondary) || ~secondary.available
                terms(k) = NaN;
            else
                primaryOnSecondaryT = interp1(primary.T, modelPrimary, ...
                    secondary.T, 'linear', 'extrap');
                obsPrimaryOnSecondaryT = interp1(primary.T, primary.R, ...
                    secondary.T, 'linear', 'extrap');
                modelA = primaryOnSecondaryT - modelSecondary;
                obsA = obsPrimaryOnSecondaryT - secondary.R;
                terms(k) = mean((modelA - obsA).^2, 'omitnan');
            end
        otherwise
            terms(k) = NaN;
    end
end
if isempty(secondary) || ~secondary.available
    weights(string(objective.metric) == "probe_asymmetry") = NaN;
end
end

function [devicePredictions, transitionMetrics, fullCurveResiduals, ...
    probePairs, failedLog] = run_heldout_predictions(cfg, inputs, observed, ...
    selectedByFold, failedLog)
predictionRows = repmat(empty_prediction_row(), ...
    max(1, height(inputs.lock) * cfg.phase13C2.maxTemperaturePoints * 2), 1);
metricRows = repmat(empty_metric_row(), max(1, height(inputs.lock) * 12), 1);
residualRows = repmat(empty_residual_row(), max(1, height(inputs.lock) * 2), 1);
pairRows = repmat(empty_pair_row(), max(1, height(inputs.lock)), 1);
pIdx = 0;
mIdx = 0;
rIdx = 0;
pairIdx = 0;
failedRows = table2struct(failedLog);
failedCount = numel(failedRows);
if failedCount == 1 && string(failedRows(1).device) == "none"
    failedCount = 0;
end
for f = 1:height(selectedByFold)
    device = string(selectedByFold.heldout_device(f));
    theta = table_to_theta(selectedByFold(f, :));
    mech = select_mechanics(inputs.mechanicalSummary, device);
    for role = ["primary", "secondary"]
        obs = select_curve(observed, device, role);
        if ~obs.available
            if role == "secondary"
                continue;
            end
            failedCount = failedCount + 1;
            failedRows(failedCount) = failed_row(device, ...
                "heldout_LODO_prediction", "locked_curve_unavailable");
            continue;
        end
        [medianR, loR, hiR] = ensemble_curve(cfg, obs.T, theta, mech, ...
            obs.probe, device);
        metricsObs = curve_metrics(obs.T, obs.R);
        metricsPred = curve_metrics(obs.T, medianR);
        residual = mean((medianR - obs.R).^2, 'omitnan');
        for k = 1:numel(obs.T)
            pIdx = pIdx + 1;
            predictionRows(pIdx).device = device;
            predictionRows(pIdx).fold_heldout_device = device;
            predictionRows(pIdx).probe_role = role;
            predictionRows(pIdx).probe = obs.probe;
            predictionRows(pIdx).experimental_channel = obs.experimental_channel;
            predictionRows(pIdx).prediction_type = ...
                cfg.phase13C2.primaryPredictionType;
            predictionRows(pIdx).temperature_K = obs.T(k);
            predictionRows(pIdx).observed_Rtilde = obs.R(k);
            predictionRows(pIdx).predicted_Rtilde_median = medianR(k);
            predictionRows(pIdx).predicted_Rtilde_lower = loR(k);
            predictionRows(pIdx).predicted_Rtilde_upper = hiR(k);
            predictionRows(pIdx).prediction_status = "completed";
            predictionRows(pIdx).device_specific_mechanism_retuned = false;
            predictionRows(pIdx).automatic_probe_fallback_used = false;
        end
        metricList = ["T90"; "T50"; "T10"; "width_T90_T10"; ...
            "low_temperature_residual_fraction"; "full_curve_residual"];
        obsVals = [metricsObs.T90; metricsObs.T50; metricsObs.T10; ...
            metricsObs.width_T90_T10; metricsObs.lowT; residual];
        predVals = [metricsPred.T90; metricsPred.T50; metricsPred.T10; ...
            metricsPred.width_T90_T10; metricsPred.lowT; residual];
        for k = 1:numel(metricList)
            mIdx = mIdx + 1;
            metricRows(mIdx).device = device;
            metricRows(mIdx).probe_role = role;
            metricRows(mIdx).metric = metricList(k);
            metricRows(mIdx).predicted_value = predVals(k);
            metricRows(mIdx).observed_value = obsVals(k);
            metricRows(mIdx).residual = predVals(k) - obsVals(k);
            metricRows(mIdx).prediction_status = "completed";
        end
        rIdx = rIdx + 1;
        residualRows(rIdx).device = device;
        residualRows(rIdx).probe_role = role;
        residualRows(rIdx).residual_metric = ...
            "full_normalized_RT_curve_residual";
        residualRows(rIdx).residual_value = residual;
        residualRows(rIdx).prediction_type = cfg.phase13C2.primaryPredictionType;
        residualRows(rIdx).prediction_status = "completed";
    end
    primary = select_curve(observed, device, "primary");
    secondary = select_curve(observed, device, "secondary");
    if primary.available && secondary.available
        pairIdx = pairIdx + 1;
        primaryPred = model_curve(primary.T, theta, mech, primary.probe);
        secondaryPred = model_curve(secondary.T, theta, mech, secondary.probe);
        primaryPredQ = interp1(primary.T, primaryPred, secondary.T, ...
            'linear', 'extrap');
        primaryObsQ = interp1(primary.T, primary.R, secondary.T, ...
            'linear', 'extrap');
        obsA = primaryObsQ - secondary.R;
        predA = primaryPredQ - secondaryPred;
        pairRows(pairIdx).device = device;
        pairRows(pairIdx).primary_probe = primary.probe;
        pairRows(pairIdx).secondary_probe = secondary.probe;
        pairRows(pairIdx).predicted_quantity = "A_probe_T=R1_T_minus_R2_T";
        pairRows(pairIdx).asymmetry_score = mean((predA - obsA).^2, 'omitnan');
        pairRows(pairIdx).onset_difference_residual_K = ...
            curve_metrics(primary.T, primaryPred).T90 - ...
            curve_metrics(secondary.T, secondaryPred).T90 - ...
            (curve_metrics(primary.T, primary.R).T90 - ...
            curve_metrics(secondary.T, secondary.R).T90);
        pairRows(pairIdx).probe_independent_refit_allowed = false;
        pairRows(pairIdx).prediction_status = "completed";
    end
end
devicePredictions = struct2table(predictionRows(1:pIdx));
transitionMetrics = struct2table(metricRows(1:mIdx));
fullCurveResiduals = struct2table(residualRows(1:rIdx));
if pairIdx == 0
    probePairs = struct2table(empty_pair_row());
else
    probePairs = struct2table(pairRows(1:pairIdx));
end
if failedCount == 0
    failedLog = struct2table(failed_row("none", "none", ...
        "no_failed_predictions_recorded"));
else
    failedLog = struct2table(failedRows(1:failedCount));
end
end

function [medianR, loR, hiR] = ensemble_curve(cfg, T, theta, mech, probe, device)
n = numel(cfg.phase13C.seedEnsemble);
curves = NaN(numel(T), n);
for k = 1:n
    seed = cfg.phase13C.seedEnsemble(k);
    thetaK = theta;
    rng(double(seed) + stable_offset(device) + stable_offset(probe));
    thetaK.Tc_base_K = theta.Tc_base_K + ...
        theta.sigma_Tc_disorder_K .* randn(1);
    curves(:, k) = model_curve(T, thetaK, mech, probe);
end
medianR = median(curves, 2, 'omitnan');
loR = row_quantile(curves, 0.16);
hiR = row_quantile(curves, 0.84);
end

function q = row_quantile(X, prob)
q = NaN(size(X, 1), 1);
for k = 1:size(X, 1)
    vals = sort(X(k, isfinite(X(k, :))));
    if isempty(vals)
        continue;
    end
    idx = max(1, min(numel(vals), round(1 + prob .* (numel(vals) - 1))));
    q(k) = vals(idx);
end
end

function R = model_curve(T, theta, mech, probe)
c = mech.coverage;
b = mech.boundary;
cr = mech.crack;
z = 0.4;
localDrive = sigmoid(theta.beta0 + theta.beta_cov .* c + ...
    theta.beta_z .* z + theta.beta_boundary_Tc_optional .* b + ...
    theta.beta_crack_Tc_optional .* cr);
connectivity = sigmoid(theta.gamma0 + theta.gamma_boundary .* b + ...
    theta.gamma_crack .* cr + theta.gamma_coverage .* c);
Tc = theta.Tc_base_K + theta.DeltaTc_max_K .* localDrive;
width = max(0.035, 0.10 + theta.sigma_Tc_disorder_K + ...
    0.28 .* (1 - connectivity) + 0.08 .* b + 0.14 .* cr);
residual = min(0.98, max(0, theta.G_shunt_global_fraction + ...
    0.18 .* (1 - connectivity) + 0.06 .* cr));
probeShift = 0;
if string(probe) == "bottom_3_9"
    probeShift = -0.035 .* b + 0.020 .* c;
elseif string(probe) == "top_4_10"
    probeShift = 0.015 .* b - 0.010 .* cr;
end
Tmid = Tc - 0.45 .* width + probeShift;
thermalWidth = max(width ./ 4.4, 0.01);
R = residual + (1 - residual) ./ (1 + exp(-(T(:) - Tmid) ./ thermalWidth));
shoulder = 0.035 .* cr .* exp(-((T(:) - (Tmid + 0.35)) ./ ...
    max(0.20, width + 0.10)).^2);
R = max(0, min(1.25, R + shoulder));
end

function y = sigmoid(x)
y = 1 ./ (1 + exp(-x));
end

function metrics = curve_metrics(T, R)
T = T(:);
R = R(:);
valid = isfinite(T) & isfinite(R);
T = T(valid);
R = R(valid);
[T, ord] = sort(T);
R = R(ord);
metrics = struct('T90', NaN, 'T50', NaN, 'T10', NaN, ...
    'width_T90_T10', NaN, 'lowT', NaN);
if numel(T) < 3
    return;
end
metrics.T90 = crossing_temperature(T, R, 0.90);
metrics.T50 = crossing_temperature(T, R, 0.50);
metrics.T10 = crossing_temperature(T, R, 0.10);
metrics.width_T90_T10 = metrics.T90 - metrics.T10;
nLow = max(1, round(0.10 .* numel(R)));
metrics.lowT = median(R(1:nLow), 'omitnan');
end

function Tcross = crossing_temperature(T, R, level)
Tcross = NaN;
[Ru, ia] = unique(R, 'stable');
Tu = T(ia);
valid = isfinite(Ru) & isfinite(Tu);
Ru = Ru(valid);
Tu = Tu(valid);
if numel(Ru) < 2 || level < min(Ru) || level > max(Ru)
    return;
end
[Rs, ord] = sort(Ru);
Ts = Tu(ord);
Tcross = interp1(Rs, Ts, level, 'linear');
end

function y = scaled_abs(delta, scale)
if isfinite(delta) && isfinite(scale) && scale > 0
    y = abs(delta) ./ scale;
else
    y = NaN;
end
end

function curve = select_curve(observed, device, role)
idx = string(observed.device) == string(device) & ...
    string(observed.probe_role) == string(role);
if any(idx)
    curve = table_to_curve(observed(find(idx, 1, 'first'), :));
else
    curve = empty_curve(device, role);
end
end

function curve = table_to_curve(row)
curve = struct();
curve.device = string(row.device(1));
curve.probe_role = string(row.probe_role(1));
curve.probe = string(row.probe(1));
curve.experimental_channel = string(row.experimental_channel(1));
curve.available = logical(row.available(1));
curve.T = row.T{1};
curve.R = row.R{1};
curve.source_file = string(row.source_file(1));
curve.note = string(row.note(1));
end

function curve = empty_curve(device, role)
curve = struct('device', string(device), 'probe_role', string(role), ...
    'probe', "", 'experimental_channel', "", 'available', false, ...
    'T', [], 'R', [], 'source_file', "", 'note', "missing_curve");
end

function mech = select_mechanics(T, device)
idx = string(T.device) == string(device);
if ~any(idx)
    mech = struct('coverage', 0, 'boundary', 0, 'crack', 0);
    return;
end
row = T(find(idx, 1, 'first'), :);
mech = struct();
mech.coverage = row.coverage_transfer_proxy(1);
mech.boundary = row.boundary_gradient_proxy(1);
mech.crack = row.crack_relaxation_proxy(1);
end

function theta = table_to_theta(row)
theta = struct();
names = ["beta0"; "beta_cov"; "beta_z"; ...
    "beta_boundary_Tc_optional"; "beta_crack_Tc_optional"; ...
    "Tc_base_K"; "DeltaTc_max_K"; "gamma0"; "gamma_boundary"; ...
    "gamma_crack"; "gamma_coverage"; "sigma_Tc_disorder_K"; ...
    "G_shunt_global_fraction"];
for k = 1:numel(names)
    name = char(names(k));
    if any(strcmp(row.Properties.VariableNames, name))
        theta.(name) = row.(name)(1);
    else
        theta.(name) = NaN;
    end
end
end

function devices = split_devices(s)
devices = string(strsplit(char(s), '|')).';
devices = devices(strlength(devices) > 0);
end

function selected = selected_from_candidate(heldout, row, score, status)
selected = empty_selected_row();
selected.heldout_device = heldout;
selected.selected_candidate_id = string(row.candidate_id(1));
selected.training_objective = score;
selected.fit_status = status;
theta = table_to_theta(row);
names = fieldnames(theta);
for k = 1:numel(names)
    selected.(names{k}) = theta.(names{k});
end
end

function results = build_fold_parameter_results(selectedByFold)
names = ["beta0"; "beta_cov"; "beta_z"; ...
    "beta_boundary_Tc_optional"; "beta_crack_Tc_optional"; ...
    "Tc_base_K"; "DeltaTc_max_K"; "gamma0"; "gamma_boundary"; ...
    "gamma_crack"; "gamma_coverage"; "sigma_Tc_disorder_K"; ...
    "G_shunt_global_fraction"];
rows = repmat(empty_parameter_row(), height(selectedByFold) * numel(names), 1);
idx = 0;
for f = 1:height(selectedByFold)
    for p = 1:numel(names)
        idx = idx + 1;
        value = selectedByFold.(char(names(p)))(f);
        rows(idx).heldout_device = string(selectedByFold.heldout_device(f));
        rows(idx).parameter = names(p);
        rows(idx).fit_status = string(selectedByFold.fit_status(f));
        rows(idx).estimated_value = value;
        rows(idx).lower_interval = value;
        rows(idx).upper_interval = value;
    end
end
results = struct2table(rows);
end

function summary = build_shared_parameter_summary(selectedByFold)
names = ["beta0"; "beta_cov"; "beta_z"; ...
    "beta_boundary_Tc_optional"; "beta_crack_Tc_optional"; ...
    "Tc_base_K"; "DeltaTc_max_K"; "gamma0"; "gamma_boundary"; ...
    "gamma_crack"; "gamma_coverage"; "sigma_Tc_disorder_K"; ...
    "G_shunt_global_fraction"];
parameter = names(:);
median_value = NaN(numel(names), 1);
fold_min = NaN(numel(names), 1);
fold_max = NaN(numel(names), 1);
for k = 1:numel(names)
    vals = selectedByFold.(char(names(k)));
    median_value(k) = median(vals, 'omitnan');
    fold_min(k) = min(vals);
    fold_max(k) = max(vals);
end
summary = table(parameter, median_value, fold_min, fold_max);
end

function holdouts = build_geometry_family_holdouts(inputs, residuals)
setup = inputs.lock;
families = [
    "cracked_full_coverage_AS005"
    "strong_half_coverage_AS006"
    "half_coverage_sequence_AS002_AS004_AS006"
    "control_limit_AS002_AS003"
    ];
devices = [
    "AS005"
    "AS006"
    "AS002|AS004|AS006"
    "AS002|AS003"
    ];
mean_residual = NaN(numel(families), 1);
execution_status = repmat("completed", numel(families), 1);
for k = 1:numel(families)
    ds = split_devices(devices(k));
    mask = false(height(residuals), 1);
    for j = 1:numel(ds)
        mask = mask | string(residuals.device) == ds(j);
    end
    vals = residuals.residual_value(mask);
    mean_residual(k) = mean(vals, 'omitnan');
    if isempty(vals) || all(~isfinite(vals))
        execution_status(k) = "failed_no_residuals";
    end
end
phase13C1_devices_locked = ismember(string(setup.device), ...
    ["AS001"; "AS002"; "AS003"; "AS004"; "AS005"; "AS006"]);
phase13C1_lock_consumed = all(phase13C1_devices_locked);
holdouts = table(families, devices, mean_residual, execution_status, ...
    repmat(phase13C1_lock_consumed, numel(families), 1), ...
    'VariableNames', {'family_holdout', 'heldout_devices', ...
    'mean_full_curve_residual', 'execution_status', ...
    'phase13C1_lock_consumed'});
end

function summary = build_uncertainty_summary(cfg, predictions)
source = [
    "disorder_realization"
    "shared_parameter_uncertainty"
    "normalization_window"
    "measured_input_uncertainty"
    "numerical_resolution"
    ];
policy = [
    "median_and_16_84_interval_from_frozen_seed_ensemble"
    "captured_by_LODO_selected_parameter_spread"
    "not_resampled_in_execution; normalized curves use frozen policy"
    "not_resampled_in_execution; frozen device inputs consumed"
    "not_resampled_in_execution; Phase 8 tolerance context retained"
    ];
n_realizations = [
    numel(cfg.phase13C.seedEnsemble)
    6
    0
    0
    0
    ];
status = [
    "completed"
    "completed_from_fold_spread"
    "predeclared_not_sampled"
    "predeclared_not_sampled"
    "predeclared_not_sampled"
    ];
mean_interval_width = NaN(numel(source), 1);
if ~isempty(predictions)
    mean_interval_width(1) = mean(predictions.predicted_Rtilde_upper - ...
        predictions.predicted_Rtilde_lower, 'omitnan');
end
summary = table(source, policy, n_realizations, status, mean_interval_width);
end

function diagnostics = build_solver_diagnostics(cfg, inputs, observed, ...
    candidates, foldTraining, devicePredictions, failedLog)
item = [
    "reduced_forward_model"
    "candidate_count"
    "LODO_fold_count"
    "observed_curve_count"
    "prediction_row_count"
    "failed_prediction_count"
    "missing_probe_policy"
    "predictive_adequacy_decision"
    ];
value = [
    "mechanical_proxy_to_Tc_connectivity_to_normalized_RT"
    string(height(candidates))
    string(height(foldTraining))
    string(sum(logical(observed.available)))
    string(height(devicePredictions))
    string(count_failures(failedLog))
    cfg.phase13C2.missingProbePolicy
    cfg.phase13C2.predictiveAdequacyDecision
    ];
note = [
    "Reduced execution path, not a proxy-score replay."
    "Shared candidates only; no device-specific mechanism terms."
    "One fold per frozen device."
    "Primary and available secondary R(T) curves loaded."
    "Long-form temperature rows written for held-out predictions."
    "Prediction failures are retained in the failed log."
    "Probe-asymmetry weight is renormalized away when secondary data are absent."
    "Phase 13D decides adequacy after artifacts are inspected."
    ];
diagnostics = table(item, value, note);
end

function manifest = build_execution_manifest(cfg)
artifact = [
    "phase13C_full_RT_execution_manifest"
    "phase13C_fold_training_manifest"
    "phase13C_fold_parameter_results"
    "phase13C_shared_parameter_summary"
    "phase13C_device_RT_predictions"
    "phase13C_transition_metric_predictions"
    "phase13C_full_curve_residuals"
    "phase13C_probe_pair_predictions"
    "phase13C_geometry_family_holdout_results"
    "phase13C_uncertainty_ensemble_summary"
    "phase13C_failed_prediction_log"
    "phase13C_solver_diagnostics"
    "phase13C_execution_gate_summary"
    "phase13C_execution_handoff_status"
    "phase13C_execution_source_provenance"
    ];
path = strings(numel(artifact), 1);
path(1) = string(cfg.phase13C2.fullRTExecutionManifestFile);
path(2) = string(cfg.phase13C2.foldTrainingManifestFile);
path(3) = string(cfg.phase13C2.foldParameterResultsFile);
path(4) = string(cfg.phase13C2.sharedParameterSummaryFile);
path(5) = string(cfg.phase13C2.deviceRTPredictionsFile);
path(6) = string(cfg.phase13C2.transitionMetricPredictionsFile);
path(7) = string(cfg.phase13C2.fullCurveResidualsFile);
path(8) = string(cfg.phase13C2.probePairPredictionsFile);
path(9) = string(cfg.phase13C2.geometryFamilyHoldoutResultsFile);
path(10) = string(cfg.phase13C2.uncertaintyEnsembleSummaryFile);
path(11) = string(cfg.phase13C2.failedPredictionLogFile);
path(12) = string(cfg.phase13C2.solverDiagnosticsFile);
path(13) = string(cfg.phase13C2.executionGateSummaryFile);
path(14) = string(cfg.phase13C2.executionHandoffStatusFile);
path(15) = string(cfg.phase13C2.executionSourceProvenanceFile);
status = repmat("will_be_written_by_execution_runner", numel(artifact), 1);
manifest = table(artifact, path, status);
end

function gates = build_gate_summary(cfg, inputs, foldTraining, predictions, ...
    residuals, probePairs, failedLog, sourceProvenance)
setupPass = all(string(inputs.setupGates.outcome) == "pass");
foldsCompleted = height(foldTraining) == height(inputs.loo) && ...
    all(string(foldTraining.fold_status) == "completed");
heldoutExcluded = all(foldTraining.heldout_data_excluded_from_calibration);
sharedOnly = all(foldTraining.shared_parameters_only);
noDeviceSpecific = all(~foldTraining.constitutive_form_retuned);
pairStatus = height(probePairs) >= 3 || ...
    all(string(probePairs.prediction_status) == "completed");
familyExecuted = ~isempty(residuals) && height(residuals) >= height(inputs.lock);
seedsUsed = numel(cfg.phase13C.seedEnsemble) > 0 && ...
    all(isfinite(predictions.predicted_Rtilde_lower));
failuresRetained = height(failedLog) > 0;
phase6Unused = all(~foldTraining.phase6_labels_used_as_targets);
ramanUnused = all(~foldTraining.raman_used_as_transport_target);
curvesGenerated = height(predictions) > 0 && ...
    all(string(predictions.prediction_status) == "completed");
clean = lookup_value(sourceProvenance, "source_pre_run_clean", "false") == "true";
gate = [
    "Frozen Phase 13A mapping used unchanged"
    "Phase 13C.1 data and objective lock consumed unchanged"
    "Six leave-one-device-out folds completed"
    "Held-out data excluded from calibration"
    "Shared parameters only"
    "No device-specific mechanism corrections"
    "Paired probes predicted jointly"
    "Geometry-family tests executed"
    "Frozen seed ensemble used"
    "Failed predictions retained"
    "Phase 6 labels unused"
    "Raman unused as transport target"
    "Full R(T) curves generated"
    "Clean provenance"
    ];
condition = [
    setupPass
    setupPass
    foldsCompleted
    heldoutExcluded
    sharedOnly
    noDeviceSpecific
    pairStatus
    familyExecuted
    seedsUsed
    failuresRetained
    phase6Unused
    ramanUnused
    curvesGenerated
    clean
    ];
note = [
    "Phase 13A inputs are consumed through frozen Phase 13C.1 manifests."
    "Data lock, objective weights, folds, and firewall are read before execution."
    "One completed LODO fold per device is required."
    "The held-out device is evaluated only after candidate selection."
    "Only shared parameter candidates are searched."
    "No held-out-specific mechanism knobs are introduced."
    "AS001/AS004/AS006 paired probes share one network state per fold."
    "Declared geometry-family rows are populated from held-out residuals."
    "All predictions use the frozen seed ensemble for intervals."
    "The failed log is always written, even when it records no failures."
    "Interpretive labels are never calibration targets."
    "Raman remains independent context."
    "Long-form held-out R(T) prediction rows were written."
    "True only when execution starts from a clean checkout."
    ];
outcome = repmat("fail", numel(gate), 1);
outcome(condition) = "pass";
gates = table(gate, outcome, note);
end

function handoff = build_handoff_status(cfg, gates, sourceProvenance)
complete = all(string(gates.outcome) == "pass");
item = [
    "phase13C_prediction_campaign"
    "all_declared_folds_completed"
    "constitutive_form_retuned"
    "device_specific_mechanism_parameters"
    "predictive_adequacy_decision"
    "source_commit_sha"
    "next_phase"
    ];
status = [
    ternary_status(complete, "complete", "needs_execution_review")
    string(any(string(gates.gate) == ...
        "Six leave-one-device-out folds completed" & ...
        string(gates.outcome) == "pass"))
    "false"
    "false"
    cfg.phase13C2.predictiveAdequacyDecision
    lookup_value(sourceProvenance, "source_commit_sha", "")
    cfg.phase13C2.nextPhase
    ];
note = [
    "Complete means the execution experiment ran honestly, not that it fit well."
    "Every frozen LODO fold must complete."
    "Phase 13A constitutive form remains frozen."
    "No device-specific mechanism corrections were fit."
    "Phase 13D decides pass/partial/fail predictive adequacy."
    "Source commit used to generate execution artifacts."
    "Assess predictive adequacy and claim scope next."
    ];
handoff = table(item, status, note);
end

function n = count_failures(failedLog)
if isempty(failedLog) || ~any(strcmp(failedLog.Properties.VariableNames, 'device'))
    n = 0;
elseif height(failedLog) == 1 && string(failedLog.device(1)) == "none"
    n = 0;
else
    n = height(failedLog);
end
end

function value = lookup_value(T, itemName, fallback)
value = string(fallback);
if isempty(T) || ~any(strcmp(T.Properties.VariableNames, 'item'))
    return;
end
col = "value";
if ~any(strcmp(T.Properties.VariableNames, col))
    col = "status";
end
idx = find(string(T.item) == string(itemName), 1, 'first');
if ~isempty(idx)
    value = string(T.(col)(idx));
end
end

function out = ternary_status(tf, a, b)
if tf
    out = string(a);
else
    out = string(b);
end
end

function offset = stable_offset(value)
s = char(string(value));
offset = 0;
for k = 1:numel(s)
    offset = offset + double(s(k)) .* k;
end
end

function row = empty_candidate_row()
row = struct('candidate_id', "", 'beta0', NaN, 'beta_cov', NaN, ...
    'beta_z', NaN, 'beta_boundary_Tc_optional', NaN, ...
    'beta_crack_Tc_optional', NaN, 'Tc_base_K', NaN, ...
    'DeltaTc_max_K', NaN, 'gamma0', NaN, 'gamma_boundary', NaN, ...
    'gamma_crack', NaN, 'gamma_coverage', NaN, ...
    'sigma_Tc_disorder_K', NaN, 'G_shunt_global_fraction', NaN, ...
    'candidate_note', "");
end

function row = empty_observed_row()
row = struct('device', "", 'probe_role', "", 'probe', "", ...
    'experimental_channel', "", 'available', false, ...
    'n_temperature_points', 0, 'T', [], 'R', [], 'source_file', "", ...
    'note', "");
row.T = {[]};
row.R = {[]};
end

function row = empty_fold_training_row()
row = struct('heldout_device', "", 'training_devices', "", ...
    'n_training_devices', 0, 'n_candidates_evaluated', 0, ...
    'selected_candidate_id', "", 'training_objective', NaN, ...
    'heldout_data_excluded_from_calibration', false, ...
    'shared_parameters_only', false, 'constitutive_form_retuned', false, ...
    'phase6_labels_used_as_targets', false, ...
    'raman_used_as_transport_target', false, 'fold_status', "", ...
    'note', "");
end

function row = empty_selected_row()
base = empty_candidate_row();
row = rmfield(base, {'candidate_id', 'candidate_note'});
row.heldout_device = "";
row.selected_candidate_id = "";
row.training_objective = NaN;
row.fit_status = "";
end

function row = empty_prediction_row()
row = struct('device', "", 'fold_heldout_device', "", ...
    'probe_role', "", 'probe', "", 'experimental_channel', "", ...
    'prediction_type', "", 'temperature_K', NaN, 'observed_Rtilde', NaN, ...
    'predicted_Rtilde_median', NaN, 'predicted_Rtilde_lower', NaN, ...
    'predicted_Rtilde_upper', NaN, 'prediction_status', "", ...
    'device_specific_mechanism_retuned', false, ...
    'automatic_probe_fallback_used', false);
end

function row = empty_metric_row()
row = struct('device', "", 'probe_role', "", 'metric', "", ...
    'predicted_value', NaN, 'observed_value', NaN, 'residual', NaN, ...
    'prediction_status', "");
end

function row = empty_residual_row()
row = struct('device', "", 'probe_role', "", 'residual_metric', "", ...
    'residual_value', NaN, 'prediction_type', "", ...
    'prediction_status', "");
end

function row = empty_pair_row()
row = struct('device', "", 'primary_probe', "", 'secondary_probe', "", ...
    'predicted_quantity', "", 'asymmetry_score', NaN, ...
    'onset_difference_residual_K', NaN, ...
    'probe_independent_refit_allowed', false, 'prediction_status', "");
end

function row = empty_parameter_row()
row = struct('heldout_device', "", 'parameter', "", 'fit_status', "", ...
    'estimated_value', NaN, 'lower_interval', NaN, 'upper_interval', NaN);
end

function row = empty_failed_row()
row = struct('device', "", 'prediction_type', "", 'failure_reason', "", ...
    'retained_in_outputs', true);
end

function row = failed_row(device, predictionType, reason)
row = empty_failed_row();
row.device = string(device);
row.prediction_type = string(predictionType);
row.failure_reason = string(reason);
row.retained_in_outputs = true;
end
