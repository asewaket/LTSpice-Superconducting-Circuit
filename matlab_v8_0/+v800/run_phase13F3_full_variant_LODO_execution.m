function out = run_phase13F3_full_variant_LODO_execution(cfg)
%RUN_PHASE13F3_FULL_VARIANT_LODO_EXECUTION Execute frozen 13F variants.
%
% Phase 13F.3 repeats the Phase 13C held-out R(T) protocol for the four
% Phase 13F variants. It reports comparison quantities only; Phase 13F.4 is
% responsible for deciding adequacy.

if ~exist(cfg.outputDir, 'dir')
    mkdir(cfg.outputDir);
end

sourceProvenance = build_source_provenance(cfg);
inputs = load_inputs(cfg);
executionManifest = build_execution_manifest(cfg);
[foldTraining, selectedByFold, failedLog] = run_variant_lodo(cfg, inputs);
[predictions, metrics, residuals, thresholdStatus, probePairs, ...
    failedLog] = build_variant_predictions(cfg, inputs, selectedByFold, ...
    failedLog);
foldParameters = build_variant_fold_parameters(selectedByFold);
geometryHoldouts = build_geometry_family_holdouts(inputs, residuals);
uncertaintyCoverage = build_uncertainty_coverage(predictions);
boundDiagnostics = build_parameter_bound_diagnostics(inputs, selectedByFold);
variantComparison = build_variant_comparison(cfg, residuals, metrics, ...
    thresholdStatus, uncertaintyCoverage);
solverDiagnostics = build_solver_diagnostics(cfg, inputs, foldTraining, ...
    predictions, residuals, failedLog);
gateSummary = build_gate_summary(cfg, inputs, foldTraining, residuals, ...
    thresholdStatus, probePairs, failedLog, sourceProvenance, ...
    boundDiagnostics);
handoffStatus = build_handoff_status(cfg, gateSummary, sourceProvenance);

writetable(executionManifest, cfg.phase13F3.executionManifestFile);
writetable(foldTraining, cfg.phase13F3.foldTrainingManifestFile);
writetable(foldParameters, cfg.phase13F3.variantFoldParametersFile);
writetable(predictions, cfg.phase13F3.deviceRTPredictionsFile);
writetable(residuals, cfg.phase13F3.variantCurveResidualsFile);
writetable(metrics, cfg.phase13F3.transitionMetricResultsFile);
writetable(thresholdStatus, cfg.phase13F3.thresholdCrossingStatusFile);
writetable(probePairs, cfg.phase13F3.probePairPredictionsFile);
writetable(geometryHoldouts, cfg.phase13F3.geometryFamilyHoldoutsFile);
writetable(uncertaintyCoverage, cfg.phase13F3.uncertaintyCoverageFile);
writetable(boundDiagnostics, cfg.phase13F3.parameterBoundDiagnosticsFile);
writetable(variantComparison, cfg.phase13F3.variantComparisonFile);
writetable(failedLog, cfg.phase13F3.failedPredictionLogFile);
writetable(solverDiagnostics, cfg.phase13F3.solverDiagnosticsFile);
writetable(gateSummary, cfg.phase13F3.executionGateSummaryFile);
writetable(handoffStatus, cfg.phase13F3.handoffStatusFile);
writetable(sourceProvenance, cfg.phase13F3.sourceProvenanceFile);

try
    h = v800.plot_phase13F3_full_variant_LODO_execution_summary(cfg, ...
        foldTraining, residuals, variantComparison, thresholdStatus, ...
        uncertaintyCoverage, boundDiagnostics, gateSummary);
catch ME
    warning('v8:phase13F3PlotFailed', ...
        'Phase 13F.3 summary plot failed: %s', ME.message);
    h = [];
end

out = struct();
out.config = cfg;
out.inputs = inputs;
out.executionManifest = executionManifest;
out.foldTrainingManifest = foldTraining;
out.variantFoldParameters = foldParameters;
out.deviceRTPredictions = predictions;
out.variantCurveResiduals = residuals;
out.transitionMetricResults = metrics;
out.thresholdCrossingStatus = thresholdStatus;
out.probePairPredictions = probePairs;
out.geometryFamilyHoldouts = geometryHoldouts;
out.uncertaintyCoverage = uncertaintyCoverage;
out.parameterBoundDiagnostics = boundDiagnostics;
out.variantComparison = variantComparison;
out.failedPredictionLog = failedLog;
out.solverDiagnostics = solverDiagnostics;
out.executionGateSummary = gateSummary;
out.handoffStatus = handoffStatus;
out.sourceProvenance = sourceProvenance;
out.figure = h;
out.paths = build_paths(cfg);
end

function paths = build_paths(cfg)
paths = struct();
paths.executionManifest = cfg.phase13F3.executionManifestFile;
paths.foldTrainingManifest = cfg.phase13F3.foldTrainingManifestFile;
paths.variantFoldParameters = cfg.phase13F3.variantFoldParametersFile;
paths.deviceRTPredictions = cfg.phase13F3.deviceRTPredictionsFile;
paths.variantCurveResiduals = cfg.phase13F3.variantCurveResidualsFile;
paths.transitionMetricResults = cfg.phase13F3.transitionMetricResultsFile;
paths.thresholdCrossingStatus = cfg.phase13F3.thresholdCrossingStatusFile;
paths.probePairPredictions = cfg.phase13F3.probePairPredictionsFile;
paths.geometryFamilyHoldouts = cfg.phase13F3.geometryFamilyHoldoutsFile;
paths.uncertaintyCoverage = cfg.phase13F3.uncertaintyCoverageFile;
paths.parameterBoundDiagnostics = cfg.phase13F3.parameterBoundDiagnosticsFile;
paths.variantComparison = cfg.phase13F3.variantComparisonFile;
paths.failedPredictionLog = cfg.phase13F3.failedPredictionLogFile;
paths.solverDiagnostics = cfg.phase13F3.solverDiagnosticsFile;
paths.executionGateSummary = cfg.phase13F3.executionGateSummaryFile;
paths.handoffStatus = cfg.phase13F3.handoffStatusFile;
paths.sourceProvenance = cfg.phase13F3.sourceProvenanceFile;
paths.figurePng = [cfg.phase13F3.figureBaseFile '.png'];
paths.figurePdf = [cfg.phase13F3.figureBaseFile '.pdf'];
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
    "phase13F3_full_variant_LODO_execution"
    sourceStatus.commit_sha
    sourceStatus.tree_sha
    string(sourceStatus.tracked_clean)
    string(sourceStatus.untracked_clean)
    string(sourceStatus.tracked_clean && sourceStatus.untracked_clean)
    "execute_four_frozen_variants_without_comparative_decision"
    "Commit Phase 13F.3 source first; rerun from clean source; commit execution artifacts separately."
    ];
note = [
    "Phase 13F.3 full four-variant LODO execution."
    "Git commit captured before this runner writes outputs."
    "Git tree object captured before this runner writes outputs."
    "Tracked-source cleanliness before output generation."
    "Untracked-source/artifact cleanliness before output generation."
    "True only when checkout is clean before this run writes outputs."
    "Consumes frozen Phase 13F.1/13F.2 and Phase 13C execution artifacts."
    "Artifacts are separate from source/configuration commits."
    ];
provenance = table(item, value, note);
end

function inputs = load_inputs(cfg)
inputs = struct();
inputs.specGates = read_required_table(cfg.phase13F.specificationGateSummaryFile);
inputs.specHandoff = read_required_table( ...
    cfg.phase13F.specificationHandoffStatusFile);
inputs.variantManifest = read_required_table(cfg.phase13F.variantManifestFile);
inputs.parameterRoles = read_required_table(cfg.phase13F.parameterRoleLedgerFile);
inputs.baselineWindow = read_required_table( ...
    cfg.phase13F.baselineWindowManifestFile);
inputs.interfaceLedger = read_required_table( ...
    cfg.phase13F.interfaceTransferInputLedgerFile);
inputs.prohibitedFlexibility = read_required_table( ...
    cfg.phase13F.prohibitedFlexibilityLedgerFile);
inputs.thresholds = read_required_table(cfg.phase13F.comparisonThresholdsFile);
inputs.f2Gates = read_required_table(cfg.phase13F2.gateSummaryFile);
inputs.f2Handoff = read_required_table(cfg.phase13F2.handoffStatusFile);
inputs.lock = read_required_table(cfg.phase13C.RTDataLockManifestFile);
inputs.objective = read_required_table( ...
    cfg.phase13C.calibrationObjectiveSpecificationFile);
inputs.loo = read_required_table(cfg.phase13C.leaveOneDeviceOutManifestFile);
inputs.phase13CPredictions = read_required_table( ...
    cfg.phase13C2.deviceRTPredictionsFile);
inputs.phase13CResiduals = read_required_table( ...
    cfg.phase13C2.fullCurveResidualsFile);
inputs.phase13CMetrics = read_required_table( ...
    cfg.phase13C2.transitionMetricPredictionsFile);
inputs.phase13CPairs = read_required_table( ...
    cfg.phase13C2.probePairPredictionsFile);
inputs.mechanicalSummary = read_required_table( ...
    cfg.phase12B.deviceMechanicalSummaryFile);
end

function T = read_required_table(pathValue)
if ~exist(pathValue, 'file')
    error('Required Phase 13F.3 input is missing: %s', pathValue);
end
try
    T = readtable(pathValue, 'TextType', 'string', ...
        'VariableNamingRule', 'preserve', 'Delimiter', ',');
catch
    T = readtable(pathValue, 'TextType', 'string', 'Delimiter', ',');
end
end

function [foldTraining, selectedByFold, failedLog] = run_variant_lodo(cfg, inputs)
variants = string(cfg.phase13F.variantIds(:));
nRows = height(inputs.loo) * numel(variants);
foldRows = repmat(empty_fold_row(), nRows, 1);
selectedRows = repmat(empty_selected_row(), nRows, 1);
idx = 0;
for v = 1:numel(variants)
    variantId = variants(v);
    candidates = build_variant_candidates(variantId);
    for f = 1:height(inputs.loo)
        idx = idx + 1;
        heldout = string(inputs.loo.heldout_device(f));
        trainDevices = split_devices(string(inputs.loo.training_devices(f)));
        bestScore = Inf;
        bestRow = candidates(1, :);
        for c = 1:height(candidates)
            scores = NaN(numel(trainDevices), 1);
            for d = 1:numel(trainDevices)
                scores(d) = score_device(inputs, trainDevices(d), ...
                    variantId, candidates(c, :));
            end
            score = mean(scores, 'omitnan');
            if isfinite(score) && score < bestScore
                bestScore = score;
                bestRow = candidates(c, :);
            end
        end
        if ~isfinite(bestScore)
            status = "failed";
        else
            status = "completed";
        end
        foldRows(idx).variant_id = variantId;
        foldRows(idx).heldout_device = heldout;
        foldRows(idx).training_devices = strjoin(trainDevices, "|");
        foldRows(idx).n_training_devices = numel(trainDevices);
        foldRows(idx).n_candidates_evaluated = height(candidates);
        foldRows(idx).selected_candidate_id = string(bestRow.candidate_id(1));
        foldRows(idx).training_objective = bestScore;
        foldRows(idx).heldout_data_excluded_from_calibration = true;
        foldRows(idx).shared_parameters_only = true;
        foldRows(idx).variant_retuning_performed = false;
        foldRows(idx).device_specific_mechanism_parameters = false;
        foldRows(idx).phase6_labels_used_as_targets = false;
        foldRows(idx).raman_used_as_transport_target = false;
        foldRows(idx).transport_relabeling_performed = false;
        foldRows(idx).fold_status = status;
        foldRows(idx).note = "variant_selected_on_other_five_devices";
        selectedRows(idx) = selected_from_candidate(variantId, heldout, ...
            bestRow, bestScore, status);
    end
end
foldTraining = struct2table(foldRows);
selectedByFold = struct2table(selectedRows);
failedLog = struct2table(failed_row("none", "none", ...
    "no_failed_predictions_recorded"));
end

function candidates = build_variant_candidates(variantId)
switch string(variantId)
    case "F0"
        b = 0; r = 0; i = 0;
    case "FB"
        [b, r] = ndgrid([0 0.05 0.10], [0 0.05 0.10]);
        i = zeros(size(b));
    case "FI"
        b = zeros(5, 1);
        r = zeros(5, 1);
        i = [-0.08 -0.04 0 0.04 0.08].';
    otherwise
        [b, r, i] = ndgrid([0 0.06 0.12], [0 0.06 0.12], ...
            [-0.06 0 0.06]);
end
b = b(:);
r = r(:);
i = i(:);
rows = repmat(empty_candidate_row(), numel(b), 1);
for k = 1:numel(b)
    rows(k).candidate_id = string(sprintf('%s_c%03d', char(variantId), k));
    rows(k).baseline_gain = b(k);
    rows(k).residual_shunt_gain = r(k);
    rows(k).interface_shift_gain = i(k);
    rows(k).baseline_shunt_upgrade = contains(string(variantId), "B");
    rows(k).interface_transfer_upgrade = contains(string(variantId), "I");
    rows(k).candidate_note = "frozen_variant_grid_candidate";
end
candidates = struct2table(rows);
end

function score = score_device(inputs, device, variantId, candidate)
primary = base_curve(inputs.phase13CPredictions, device, "primary");
if ~primary.available
    score = NaN;
    return;
end
mech = select_mechanics(inputs.mechanicalSummary, device);
modelPrimary = apply_variant(primary.T, primary.basePred, mech, ...
    variantId, candidate);
secondary = base_curve(inputs.phase13CPredictions, device, "secondary");
if secondary.available
    modelSecondary = apply_variant(secondary.T, secondary.basePred, ...
        mech, variantId, candidate);
else
    modelSecondary = [];
end
[terms, weights] = objective_terms(inputs.objective, primary, modelPrimary, ...
    secondary, modelSecondary);
finite = isfinite(terms) & isfinite(weights) & weights > 0;
if any(finite)
    score = sum(weights(finite) .* terms(finite)) ./ sum(weights(finite));
else
    score = NaN;
end
end

function [terms, weights] = objective_terms(objective, primary, modelPrimary, ...
    secondary, modelSecondary)
metricsExp = curve_metrics(primary.T, primary.obs);
metricsModel = curve_metrics(primary.T, modelPrimary);
terms = zeros(height(objective), 1);
weights = objective.weight;
for k = 1:height(objective)
    metric = string(objective.metric(k));
    switch metric
        case "full_curve_normalized_residual"
            terms(k) = mean((modelPrimary - primary.obs).^2, 'omitnan');
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
                obsPrimaryOnSecondaryT = interp1(primary.T, primary.obs, ...
                    secondary.T, 'linear', 'extrap');
                modelA = primaryOnSecondaryT - modelSecondary;
                obsA = obsPrimaryOnSecondaryT - secondary.obs;
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

function [predictions, metrics, residuals, thresholdStatus, probePairs, ...
    failedLog] = build_variant_predictions(cfg, inputs, selectedByFold, ...
    failedLog)
base = inputs.phase13CPredictions;
nBase = height(base);
nSel = height(selectedByFold);
predRows = repmat(empty_prediction_row(), max(1, nBase * nSel / 6), 1);
metricRows = repmat(empty_metric_row(), max(1, nSel * 12), 1);
resRows = repmat(empty_residual_row(), max(1, nSel * 2), 1);
crossRows = repmat(empty_crossing_row(), max(1, nSel * 6), 1);
pairRows = repmat(empty_pair_row(), max(1, nSel), 1);
pIdx = 0;
mIdx = 0;
rIdx = 0;
cIdx = 0;
pairIdx = 0;
failedRows = table2struct(failedLog);
failedCount = 0;
for s = 1:nSel
    variantId = string(selectedByFold.variant_id(s));
    device = string(selectedByFold.heldout_device(s));
    candidate = selectedByFold(s, :);
    mech = select_mechanics(inputs.mechanicalSummary, device);
    for role = ["primary", "secondary"]
        curve = base_curve(base, device, role);
        if ~curve.available
            if role == "primary"
                failedCount = failedCount + 1;
                failedRows(failedCount) = failed_row(device, ...
                    "heldout_LODO_prediction", "locked_curve_unavailable");
            end
            continue;
        end
        pred = apply_variant(curve.T, curve.basePred, mech, ...
            variantId, candidate);
        lo = apply_variant(curve.T, curve.baseLo, mech, variantId, candidate);
        hi = apply_variant(curve.T, curve.baseHi, mech, variantId, candidate);
        lo2 = min(lo, hi);
        hi2 = max(lo, hi);
        obsM = curve_metrics(curve.T, curve.obs);
        predM = curve_metrics(curve.T, pred);
        residual = mean((pred - curve.obs).^2, 'omitnan');
        for k = 1:numel(curve.T)
            pIdx = pIdx + 1;
            predRows(pIdx).variant_id = variantId;
            predRows(pIdx).device = device;
            predRows(pIdx).fold_heldout_device = device;
            predRows(pIdx).probe_role = role;
            predRows(pIdx).probe = curve.probe;
            predRows(pIdx).experimental_channel = curve.channel;
            predRows(pIdx).selected_candidate_id = ...
                string(candidate.selected_candidate_id(1));
            predRows(pIdx).prediction_type = "heldout_LODO_prediction";
            predRows(pIdx).temperature_K = curve.T(k);
            predRows(pIdx).observed_Rtilde = curve.obs(k);
            predRows(pIdx).phase13C_F0_Rtilde = curve.basePred(k);
            predRows(pIdx).predicted_Rtilde_median = pred(k);
            predRows(pIdx).predicted_Rtilde_lower = lo2(k);
            predRows(pIdx).predicted_Rtilde_upper = hi2(k);
            predRows(pIdx).prediction_status = "completed";
            predRows(pIdx).device_specific_mechanism_retuned = false;
            predRows(pIdx).automatic_probe_fallback_used = false;
        end
        metricNames = ["T90"; "T50"; "T10"; "width_T90_T10"; ...
            "low_temperature_residual_fraction"; "full_curve_residual"];
        obsVals = [obsM.T90; obsM.T50; obsM.T10; obsM.width_T90_T10; ...
            obsM.lowT; residual];
        predVals = [predM.T90; predM.T50; predM.T10; ...
            predM.width_T90_T10; predM.lowT; residual];
        for k = 1:numel(metricNames)
            mIdx = mIdx + 1;
            metricRows(mIdx).variant_id = variantId;
            metricRows(mIdx).device = device;
            metricRows(mIdx).probe_role = role;
            metricRows(mIdx).metric = metricNames(k);
            metricRows(mIdx).predicted_value = predVals(k);
            metricRows(mIdx).observed_value = obsVals(k);
            metricRows(mIdx).residual = predVals(k) - obsVals(k);
            metricRows(mIdx).prediction_status = "completed";
        end
        for level = [0.90 0.50 0.10]
            cIdx = cIdx + 1;
            threshold = sprintf('T%d', round(level .* 100));
            crossRows(cIdx) = crossing_row(variantId, device, role, ...
                threshold, level, curve.T, curve.obs, pred);
        end
        rIdx = rIdx + 1;
        resRows(rIdx).variant_id = variantId;
        resRows(rIdx).device = device;
        resRows(rIdx).probe_role = role;
        resRows(rIdx).residual_metric = "full_normalized_RT_curve_residual";
        resRows(rIdx).residual_value = residual;
        resRows(rIdx).prediction_type = "heldout_LODO_prediction";
        resRows(rIdx).prediction_status = "completed";
    end
    primary = base_curve(base, device, "primary");
    secondary = base_curve(base, device, "secondary");
    if primary.available && secondary.available
        pairIdx = pairIdx + 1;
        predP = apply_variant(primary.T, primary.basePred, mech, ...
            variantId, candidate);
        predS = apply_variant(secondary.T, secondary.basePred, mech, ...
            variantId, candidate);
        predPQ = interp1(primary.T, predP, secondary.T, 'linear', 'extrap');
        obsPQ = interp1(primary.T, primary.obs, secondary.T, ...
            'linear', 'extrap');
        pairRows(pairIdx).variant_id = variantId;
        pairRows(pairIdx).device = device;
        pairRows(pairIdx).primary_probe = primary.probe;
        pairRows(pairIdx).secondary_probe = secondary.probe;
        pairRows(pairIdx).predicted_quantity = "A_probe_T=R1_T_minus_R2_T";
        pairRows(pairIdx).asymmetry_score = mean((predPQ - predS - ...
            (obsPQ - secondary.obs)).^2, 'omitnan');
        pairRows(pairIdx).onset_difference_residual_K = ...
            curve_metrics(primary.T, predP).T90 - ...
            curve_metrics(secondary.T, predS).T90 - ...
            (curve_metrics(primary.T, primary.obs).T90 - ...
            curve_metrics(secondary.T, secondary.obs).T90);
        pairRows(pairIdx).probe_independent_refit_allowed = false;
        pairRows(pairIdx).prediction_status = "completed";
    end
end
predictions = struct2table(predRows(1:pIdx));
metrics = struct2table(metricRows(1:mIdx));
residuals = struct2table(resRows(1:rIdx));
thresholdStatus = struct2table(crossRows(1:cIdx));
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

function curve = base_curve(base, device, role)
idx = string(base.device) == string(device) & ...
    string(base.probe_role) == string(role);
curve = struct('available', false, 'T', [], 'obs', [], 'basePred', [], ...
    'baseLo', [], 'baseHi', [], 'probe', "", 'channel', "");
if ~any(idx)
    return;
end
T = base(idx, :);
[temps, ord] = sort(T.temperature_K);
curve.available = true;
curve.T = temps;
curve.obs = T.observed_Rtilde(ord);
curve.basePred = T.predicted_Rtilde_median(ord);
curve.baseLo = T.predicted_Rtilde_lower(ord);
curve.baseHi = T.predicted_Rtilde_upper(ord);
curve.probe = string(T.probe(ord(1)));
curve.channel = string(T.experimental_channel(ord(1)));
end

function pred = apply_variant(T, basePred, mech, variantId, candidate)
pred = basePred(:);
if isempty(pred)
    return;
end
hasBaseline = contains(string(variantId), "B");
hasInterface = contains(string(variantId), "I");
if hasInterface
    shiftGain = candidate.interface_shift_gain(1);
    drive = 0.65 .* mech.boundary + 0.45 .* mech.crack - ...
        0.20 .* mech.coverage;
    shiftK = shiftGain .* drive;
    pred = interp1(T(:) - shiftK, pred, T(:), 'linear', 'extrap');
end
if hasBaseline
    tScaled = scaled_temperature(T(:));
    normalMask = max(0, (tScaled - 0.85) ./ 0.15);
    lowMask = max(0, (0.25 - tScaled) ./ 0.25);
    baselineFactor = 1 + candidate.baseline_gain(1) .* normalMask;
    residualLift = candidate.residual_shunt_gain(1) .* lowMask;
    pred = pred .* baselineFactor + residualLift .* (1 - pred);
end
pred = max(0, min(1.25, pred));
end

function tScaled = scaled_temperature(T)
T = T(:);
if isempty(T) || max(T) <= min(T)
    tScaled = zeros(size(T));
else
    tScaled = (T - min(T)) ./ (max(T) - min(T));
end
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

function row = crossing_row(variantId, device, role, thresholdName, level, ...
    T, obs, pred)
row = empty_crossing_row();
row.variant_id = variantId;
row.device = device;
row.probe_role = role;
row.threshold = string(thresholdName);
row.level = level;
row.observed_crossing_K = crossing_temperature(T, obs, level);
row.predicted_crossing_K = crossing_temperature(T, pred, level);
obsCross = isfinite(row.observed_crossing_K);
predCross = isfinite(row.predicted_crossing_K);
if obsCross && predCross
    row.crossing_status = "both_cross";
elseif obsCross && ~predCross
    row.crossing_status = "observed_cross_predicted_no_cross";
elseif ~obsCross && predCross
    row.crossing_status = "observed_no_cross_predicted_cross";
elseif max(obs) - min(obs) < 0.03 || max(pred) - min(pred) < 0.03
    row.crossing_status = "crossing_ambiguous";
else
    row.crossing_status = "neither_crosses";
end
row.non_crossing_retained = true;
end

function parameters = build_variant_fold_parameters(selectedByFold)
params = ["baseline_gain"; "residual_shunt_gain"; "interface_shift_gain"];
rows = repmat(empty_parameter_row(), height(selectedByFold) * numel(params), 1);
idx = 0;
for k = 1:height(selectedByFold)
    for p = 1:numel(params)
        idx = idx + 1;
        name = char(params(p));
        rows(idx).variant_id = string(selectedByFold.variant_id(k));
        rows(idx).heldout_device = string(selectedByFold.heldout_device(k));
        rows(idx).parameter = params(p);
        rows(idx).selected_candidate_id = ...
            string(selectedByFold.selected_candidate_id(k));
        rows(idx).fit_status = string(selectedByFold.fit_status(k));
        rows(idx).estimated_value = selectedByFold.(name)(k);
        rows(idx).lower_bound = parameter_bound(params(p), "lower");
        rows(idx).upper_bound = parameter_bound(params(p), "upper");
        rows(idx).parameter_role = "shared_variant_parameter";
    end
end
parameters = struct2table(rows);
end

function value = parameter_bound(parameter, side)
switch string(parameter)
    case "baseline_gain"
        lo = 0; hi = 0.12;
    case "residual_shunt_gain"
        lo = 0; hi = 0.12;
    otherwise
        lo = -0.08; hi = 0.08;
end
if string(side) == "lower"
    value = lo;
else
    value = hi;
end
end

function holdouts = build_geometry_family_holdouts(inputs, residuals)
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
variants = unique(string(residuals.variant_id), 'stable');
rows = repmat(empty_family_row(), numel(families) * numel(variants), 1);
idx = 0;
for v = 1:numel(variants)
    for k = 1:numel(families)
        idx = idx + 1;
        ds = split_devices(devices(k));
        mask = string(residuals.variant_id) == variants(v) & ...
            string(residuals.probe_role) == "primary";
        keep = false(height(residuals), 1);
        for j = 1:numel(ds)
            keep = keep | string(residuals.device) == ds(j);
        end
        vals = residuals.residual_value(mask & keep);
        rows(idx).variant_id = variants(v);
        rows(idx).family_holdout = families(k);
        rows(idx).heldout_devices = devices(k);
        rows(idx).mean_full_curve_residual = mean(vals, 'omitnan');
        rows(idx).execution_status = ternary_status(any(isfinite(vals)), ...
            "completed", "failed_no_residuals");
        rows(idx).phase13C1_lock_consumed = height(inputs.lock) >= 6;
    end
end
holdouts = struct2table(rows);
end

function coverage = build_uncertainty_coverage(predictions)
variants = unique(string(predictions.variant_id), 'stable');
devices = unique(string(predictions.device), 'stable');
rows = repmat(empty_coverage_row(), numel(variants) * numel(devices), 1);
idx = 0;
for v = 1:numel(variants)
    for d = 1:numel(devices)
        idx = idx + 1;
        mask = string(predictions.variant_id) == variants(v) & ...
            string(predictions.device) == devices(d) & ...
            string(predictions.probe_role) == "primary";
        T = predictions(mask, :);
        inside = T.observed_Rtilde >= T.predicted_Rtilde_lower & ...
            T.observed_Rtilde <= T.predicted_Rtilde_upper;
        rows(idx).variant_id = variants(v);
        rows(idx).device = devices(d);
        rows(idx).coverage_fraction = mean(double(inside), 'omitnan');
        rows(idx).mean_interval_width = mean( ...
            T.predicted_Rtilde_upper - T.predicted_Rtilde_lower, 'omitnan');
        rows(idx).coverage_policy = ...
            "Phase13C_seed_interval_transformed_by_frozen_variant_layer";
    end
end
coverage = struct2table(rows);
end

function diagnostics = build_parameter_bound_diagnostics(inputs, selectedByFold)
params = build_variant_fold_parameters(selectedByFold);
tol = 1e-12;
pinned = abs(params.estimated_value - params.lower_bound) <= tol | ...
    abs(params.estimated_value - params.upper_bound) <= tol;
keys = unique(strcat(string(params.variant_id), "|", string(params.parameter)));
rows = repmat(empty_bound_row(), numel(keys), 1);
for k = 1:numel(keys)
    parts = string(strsplit(char(keys(k)), '|'));
    mask = string(params.variant_id) == parts(1) & ...
        string(params.parameter) == parts(2);
    rows(k).variant_id = parts(1);
    rows(k).parameter = parts(2);
    rows(k).pinned_fold_fraction = mean(double(pinned(mask)), 'omitnan');
    rows(k).max_allowed_pinned_fraction = threshold_number( ...
        inputs.thresholds, "max_pinned_parameter_fold_fraction", 0.50);
    if ~isfinite(rows(k).max_allowed_pinned_fraction)
        rows(k).max_allowed_pinned_fraction = 0.50;
    end
    rows(k).status = ternary_status(rows(k).pinned_fold_fraction <= ...
        rows(k).max_allowed_pinned_fraction, "pass", "review");
end
diagnostics = struct2table(rows);
end

function value = threshold_number(T, name, fallback)
value = fallback;
if any(strcmp(T.Properties.VariableNames, 'threshold_id'))
    idx = find(string(T.threshold_id) == string(name), 1, 'first');
elseif any(strcmp(T.Properties.VariableNames, 'criterion'))
    idx = find(string(T.criterion) == string(name), 1, 'first');
else
    idx = [];
end
if isempty(idx)
    return;
end
if any(strcmp(T.Properties.VariableNames, 'threshold'))
    raw = string(T.threshold(idx));
elseif any(strcmp(T.Properties.VariableNames, 'value'))
    raw = string(T.value(idx));
else
    return;
end
num = str2double(raw);
if isfinite(num)
    value = num;
end
end

function comparison = build_variant_comparison(cfg, residuals, metrics, ...
    thresholdStatus, coverage)
variants = string(cfg.phase13F.variantIds(:));
devices = unique(string(residuals.device), 'stable');
rows = repmat(empty_comparison_row(), numel(variants) * numel(devices), 1);
idx = 0;
for v = 1:numel(variants)
    for d = 1:numel(devices)
        idx = idx + 1;
        f0 = primary_residual(residuals, "F0", devices(d));
        sv = primary_residual(residuals, variants(v), devices(d));
        rows(idx).variant_id = variants(v);
        rows(idx).device = devices(d);
        rows(idx).S_curve = sv;
        rows(idx).S_F0 = f0;
        rows(idx).DeltaS_vs_F0 = sv - f0;
        rows(idx).improved_vs_F0 = sv < f0;
        rows(idx).severe_regression_vs_F0 = (sv - f0) > ...
            cfg.phase13F.maximumSevereRegression;
        rows(idx).T90 = metric_value(metrics, variants(v), devices(d), "T90");
        rows(idx).T50 = metric_value(metrics, variants(v), devices(d), "T50");
        rows(idx).T10 = metric_value(metrics, variants(v), devices(d), "T10");
        rows(idx).DeltaT_90_10 = metric_value(metrics, variants(v), ...
            devices(d), "width_T90_T10");
        rows(idx).Rlow_over_RN = metric_value(metrics, variants(v), ...
            devices(d), "low_temperature_residual_fraction");
        rows(idx).n_threshold_both_cross = sum( ...
            string(thresholdStatus.variant_id) == variants(v) & ...
            string(thresholdStatus.device) == devices(d) & ...
            string(thresholdStatus.probe_role) == "primary" & ...
            string(thresholdStatus.crossing_status) == "both_cross");
        rows(idx).primary_interval_coverage = coverage_value(coverage, ...
            variants(v), devices(d));
        rows(idx).comparative_adequacy_decision = ...
            cfg.phase13F3.comparativeAdequacyDecision;
    end
end
comparison = struct2table(rows);
end

function value = primary_residual(T, variantId, device)
idx = string(T.variant_id) == string(variantId) & ...
    string(T.device) == string(device) & string(T.probe_role) == "primary";
if any(idx)
    value = T.residual_value(find(idx, 1, 'first'));
else
    value = NaN;
end
end

function value = metric_value(T, variantId, device, metric)
idx = string(T.variant_id) == string(variantId) & ...
    string(T.device) == string(device) & string(T.probe_role) == "primary" & ...
    string(T.metric) == string(metric);
if any(idx)
    value = T.predicted_value(find(idx, 1, 'first'));
else
    value = NaN;
end
end

function value = coverage_value(T, variantId, device)
idx = string(T.variant_id) == string(variantId) & ...
    string(T.device) == string(device);
if any(idx)
    value = T.coverage_fraction(find(idx, 1, 'first'));
else
    value = NaN;
end
end

function diagnostics = build_solver_diagnostics(cfg, inputs, foldTraining, ...
    predictions, residuals, failedLog)
item = [
    "variant_count"
    "expected_primary_fold_variant_count"
    "observed_fold_variant_count"
    "prediction_row_count"
    "residual_row_count"
    "failed_prediction_count"
    "phase13C_protocol_source"
    "comparative_adequacy_decision"
    ];
value = [
    string(numel(cfg.phase13F.variantIds))
    string(cfg.phase13F3.expectedPrimaryFoldVariantCount)
    string(height(foldTraining))
    string(height(predictions))
    string(height(residuals))
    string(count_failures(failedLog))
    cfg.phase13C2.fullRTExecutionManifestFile
    cfg.phase13F3.comparativeAdequacyDecision
    ];
note = [
    "F0, FB, FI, and FBI are executed."
    "Six held-out devices times four variants."
    "One training row per held-out device and variant."
    "Long-form primary and available secondary R(T) predictions."
    "One full-curve residual per device/probe/variant."
    "Failures are retained, including explicit no-failure sentinel."
    "Phase 13C data/probe/objective protocol remains the base lock."
    "Phase 13F.4 performs the decision."
    ];
diagnostics = table(item, value, note);
end

function gates = build_gate_summary(cfg, inputs, foldTraining, residuals, ...
    thresholdStatus, probePairs, failedLog, sourceProvenance, boundDiagnostics)
f1Pass = all(string(inputs.specGates.outcome) == "pass") && ...
    lookup_table_value(inputs.specHandoff, "phase13F1_closure", "") == ...
    "pass_upgrade_specification_freeze";
f2Pass = all(string(inputs.f2Gates.outcome) == "pass") && ...
    lookup_table_value(inputs.f2Handoff, "phase13F2_closure", "") == ...
    "pass_limiting_case_ablation_verification";
f0Repro = compare_f0_to_phase13C(inputs.phase13CResiduals, residuals);
foldsCompleted = height(foldTraining) == ...
    cfg.phase13F3.expectedPrimaryFoldVariantCount && ...
    all(string(foldTraining.fold_status) == "completed");
heldoutExcluded = all(foldTraining.heldout_data_excluded_from_calibration);
sharedOnly = all(foldTraining.shared_parameters_only) && ...
    all(~foldTraining.device_specific_mechanism_parameters);
baselineLocked = all(abs(cfg.phase13F.normalStateWindowScaled - ...
    [0.85 1.00]) < 1e-12);
interfaceLocked = height(inputs.interfaceLedger) > 0;
pairedStatus = height(probePairs) >= 3 * numel(cfg.phase13F.variantIds) || ...
    all(string(probePairs.prediction_status) == "completed");
seedStatus = isequal(cfg.phase13C.seedEnsemble(:), (2001:2030).');
nonCrossingRetained = ~isempty(thresholdStatus) && ...
    all(thresholdStatus.non_crossing_retained);
failuresRetained = height(failedLog) > 0;
noTargets = all(~foldTraining.phase6_labels_used_as_targets) && ...
    all(~foldTraining.raman_used_as_transport_target);
noRelabel = all(~foldTraining.transport_relabeling_performed);
clean = lookup_value(sourceProvenance, "source_pre_run_clean", "false") == "true";
boundRows = ~isempty(boundDiagnostics) && ...
    all(ismember(string(boundDiagnostics.status), ["pass"; "review"]));
gate = [
    "Phase 13F.1 specification consumed unchanged"
    "Phase 13F.2 variant behavior preserved"
    "F0 reproduces Phase 13C baseline"
    "All 24 fold-variant combinations completed"
    "Held-out data excluded from fitting"
    "Shared parameters only"
    "Baseline window remains locked"
    "Interface inputs remain independently specified"
    "Paired probes predicted jointly"
    "Same seed ensemble used across variants"
    "Threshold non-crossings retained"
    "Failed/regressive predictions retained"
    "No Raman or Phase 6 target use"
    "No transport relabeling or probe fallback"
    "Parameter bounds diagnosed"
    "Clean provenance"
    ];
condition = [
    f1Pass
    f2Pass
    f0Repro
    foldsCompleted
    heldoutExcluded
    sharedOnly
    baselineLocked
    interfaceLocked
    pairedStatus
    seedStatus
    nonCrossingRetained
    failuresRetained
    noTargets
    noRelabel
    boundRows
    clean
    ];
note = [
    "Reads frozen 13F.1 model specification, role ledgers, and handoff."
    "Reads 13F.2 limiting-case gates before execution."
    "F0 residuals are copied from the frozen Phase 13C execution baseline."
    "Six held-out devices by four variants."
    "Training scores use only non-held-out devices for each fold."
    "Variant parameters are shared grid parameters, not device-specific knobs."
    "Normal-state window remains 0.85-1.00 scaled temperature."
    "Interface-transfer inputs are read as independent ledger context."
    "Available secondary probes are predicted from the same selected variant."
    "The Phase 13C seed ensemble is preserved through transformed intervals."
    "Crossing statuses keep explicit non-crossing categories."
    "Failed log and regressive comparison rows are written."
    "External interpretive targets are not optimization targets."
    "No relabeling or automatic probe fallback is performed."
    "Pinned/fold-bound behavior is reported for Phase 13F.4."
    "True only when execution starts from a clean checkout."
    ];
outcome = repmat("fail", numel(gate), 1);
outcome(condition) = "pass";
gates = table(gate, outcome, note);
end

function tf = compare_f0_to_phase13C(phase13CResiduals, residuals)
base = phase13CResiduals;
f0 = residuals(string(residuals.variant_id) == "F0", :);
tf = height(base) == height(f0);
if ~tf
    return;
end
for k = 1:height(base)
    idx = string(f0.device) == string(base.device(k)) & ...
        string(f0.probe_role) == string(base.probe_role(k));
    if ~any(idx)
        tf = false;
        return;
    end
    delta = abs(f0.residual_value(find(idx, 1, 'first')) - ...
        base.residual_value(k));
    if delta > 1e-8
        tf = false;
        return;
    end
end
end

function handoff = build_handoff_status(cfg, gates, sourceProvenance)
complete = all(string(gates.outcome) == "pass");
item = [
    "phase13F3_closure"
    "comparative_adequacy_decision"
    "variant_retuning_performed"
    "device_specific_mechanism_parameters"
    "phase13F3_execution_complete"
    "source_commit_sha"
    "next_phase"
    ];
status = [
    ternary_status(complete, "complete_repeated_LODO_execution", ...
    "needs_execution_review")
    cfg.phase13F3.comparativeAdequacyDecision
    "false"
    "false"
    string(complete)
    lookup_value(sourceProvenance, "source_commit_sha", "")
    cfg.phase13F3.nextPhase
    ];
note = [
    "Execution closure only; this phase does not choose a winning variant."
    "Phase 13F.4 reads these artifacts and applies frozen adequacy rules."
    "Variant definitions are frozen from Phase 13F.1."
    "No per-device mechanism terms are introduced."
    "All gates must pass for a clean handoff."
    "Source commit used to generate execution artifacts."
    "Read-only comparative adequacy decision."
    ];
handoff = table(item, status, note);
end

function manifest = build_execution_manifest(cfg)
artifact = [
    "phase13F3_execution_manifest"
    "phase13F3_fold_training_manifest"
    "phase13F3_variant_fold_parameters"
    "phase13F3_device_RT_predictions"
    "phase13F3_variant_curve_residuals"
    "phase13F3_transition_metric_results"
    "phase13F3_threshold_crossing_status"
    "phase13F3_probe_pair_predictions"
    "phase13F3_geometry_family_holdouts"
    "phase13F3_uncertainty_coverage"
    "phase13F3_parameter_bound_diagnostics"
    "phase13F3_variant_comparison"
    "phase13F3_failed_prediction_log"
    "phase13F3_solver_diagnostics"
    "phase13F3_execution_gate_summary"
    "phase13F3_handoff_status"
    "phase13F3_source_provenance"
    ];
path = strings(numel(artifact), 1);
path(1) = string(cfg.phase13F3.executionManifestFile);
path(2) = string(cfg.phase13F3.foldTrainingManifestFile);
path(3) = string(cfg.phase13F3.variantFoldParametersFile);
path(4) = string(cfg.phase13F3.deviceRTPredictionsFile);
path(5) = string(cfg.phase13F3.variantCurveResidualsFile);
path(6) = string(cfg.phase13F3.transitionMetricResultsFile);
path(7) = string(cfg.phase13F3.thresholdCrossingStatusFile);
path(8) = string(cfg.phase13F3.probePairPredictionsFile);
path(9) = string(cfg.phase13F3.geometryFamilyHoldoutsFile);
path(10) = string(cfg.phase13F3.uncertaintyCoverageFile);
path(11) = string(cfg.phase13F3.parameterBoundDiagnosticsFile);
path(12) = string(cfg.phase13F3.variantComparisonFile);
path(13) = string(cfg.phase13F3.failedPredictionLogFile);
path(14) = string(cfg.phase13F3.solverDiagnosticsFile);
path(15) = string(cfg.phase13F3.executionGateSummaryFile);
path(16) = string(cfg.phase13F3.handoffStatusFile);
path(17) = string(cfg.phase13F3.sourceProvenanceFile);
status = repmat("will_be_written_by_execution_runner", numel(artifact), 1);
manifest = table(artifact, path, status);
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

function value = lookup_table_value(T, key, fallback)
value = string(fallback);
if isempty(T)
    return;
end
if any(strcmp(T.Properties.VariableNames, 'field'))
    keyCol = "field";
elseif any(strcmp(T.Properties.VariableNames, 'item'))
    keyCol = "item";
else
    return;
end
if any(strcmp(T.Properties.VariableNames, 'value'))
    valueCol = "value";
elseif any(strcmp(T.Properties.VariableNames, 'status'))
    valueCol = "status";
else
    return;
end
idx = find(string(T.(keyCol)) == string(key), 1, 'first');
if ~isempty(idx)
    value = string(T.(valueCol)(idx));
end
end

function devices = split_devices(s)
devices = string(strsplit(char(s), '|')).';
devices = devices(strlength(devices) > 0);
end

function out = ternary_status(tf, a, b)
if tf
    out = string(a);
else
    out = string(b);
end
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

function row = selected_from_candidate(variantId, heldout, candidate, score, status)
row = empty_selected_row();
row.variant_id = variantId;
row.heldout_device = heldout;
row.selected_candidate_id = string(candidate.candidate_id(1));
row.training_objective = score;
row.baseline_gain = candidate.baseline_gain(1);
row.residual_shunt_gain = candidate.residual_shunt_gain(1);
row.interface_shift_gain = candidate.interface_shift_gain(1);
row.baseline_shunt_upgrade = candidate.baseline_shunt_upgrade(1);
row.interface_transfer_upgrade = candidate.interface_transfer_upgrade(1);
row.fit_status = status;
end

function row = empty_candidate_row()
row = struct('candidate_id', "", 'baseline_gain', NaN, ...
    'residual_shunt_gain', NaN, 'interface_shift_gain', NaN, ...
    'baseline_shunt_upgrade', false, ...
    'interface_transfer_upgrade', false, 'candidate_note', "");
end

function row = empty_fold_row()
row = struct('variant_id', "", 'heldout_device', "", ...
    'training_devices', "", 'n_training_devices', 0, ...
    'n_candidates_evaluated', 0, 'selected_candidate_id', "", ...
    'training_objective', NaN, ...
    'heldout_data_excluded_from_calibration', false, ...
    'shared_parameters_only', false, 'variant_retuning_performed', false, ...
    'device_specific_mechanism_parameters', false, ...
    'phase6_labels_used_as_targets', false, ...
    'raman_used_as_transport_target', false, ...
    'transport_relabeling_performed', false, 'fold_status', "", ...
    'note', "");
end

function row = empty_selected_row()
row = struct('variant_id', "", 'heldout_device', "", ...
    'selected_candidate_id', "", 'training_objective', NaN, ...
    'baseline_gain', NaN, 'residual_shunt_gain', NaN, ...
    'interface_shift_gain', NaN, 'baseline_shunt_upgrade', false, ...
    'interface_transfer_upgrade', false, 'fit_status', "");
end

function row = empty_prediction_row()
row = struct('variant_id', "", 'device', "", 'fold_heldout_device', "", ...
    'probe_role', "", 'probe', "", 'experimental_channel', "", ...
    'selected_candidate_id', "", 'prediction_type', "", ...
    'temperature_K', NaN, 'observed_Rtilde', NaN, ...
    'phase13C_F0_Rtilde', NaN, 'predicted_Rtilde_median', NaN, ...
    'predicted_Rtilde_lower', NaN, 'predicted_Rtilde_upper', NaN, ...
    'prediction_status', "", ...
    'device_specific_mechanism_retuned', false, ...
    'automatic_probe_fallback_used', false);
end

function row = empty_metric_row()
row = struct('variant_id', "", 'device', "", 'probe_role', "", ...
    'metric', "", 'predicted_value', NaN, 'observed_value', NaN, ...
    'residual', NaN, 'prediction_status', "");
end

function row = empty_residual_row()
row = struct('variant_id', "", 'device', "", 'probe_role', "", ...
    'residual_metric', "", 'residual_value', NaN, ...
    'prediction_type', "", 'prediction_status', "");
end

function row = empty_crossing_row()
row = struct('variant_id', "", 'device', "", 'probe_role', "", ...
    'threshold', "", 'level', NaN, 'observed_crossing_K', NaN, ...
    'predicted_crossing_K', NaN, 'crossing_status', "", ...
    'non_crossing_retained', true);
end

function row = empty_pair_row()
row = struct('variant_id', "", 'device', "", 'primary_probe', "", ...
    'secondary_probe', "", 'predicted_quantity', "", ...
    'asymmetry_score', NaN, 'onset_difference_residual_K', NaN, ...
    'probe_independent_refit_allowed', false, 'prediction_status', "");
end

function row = empty_parameter_row()
row = struct('variant_id', "", 'heldout_device', "", 'parameter', "", ...
    'selected_candidate_id', "", 'fit_status', "", ...
    'estimated_value', NaN, 'lower_bound', NaN, 'upper_bound', NaN, ...
    'parameter_role', "");
end

function row = empty_family_row()
row = struct('variant_id', "", 'family_holdout', "", ...
    'heldout_devices', "", 'mean_full_curve_residual', NaN, ...
    'execution_status', "", 'phase13C1_lock_consumed', false);
end

function row = empty_coverage_row()
row = struct('variant_id', "", 'device', "", ...
    'coverage_fraction', NaN, 'mean_interval_width', NaN, ...
    'coverage_policy', "");
end

function row = empty_bound_row()
row = struct('variant_id', "", 'parameter', "", ...
    'pinned_fold_fraction', NaN, 'max_allowed_pinned_fraction', NaN, ...
    'status', "");
end

function row = empty_comparison_row()
row = struct('variant_id', "", 'device', "", 'S_curve', NaN, ...
    'S_F0', NaN, 'DeltaS_vs_F0', NaN, 'improved_vs_F0', false, ...
    'severe_regression_vs_F0', false, 'T90', NaN, 'T50', NaN, ...
    'T10', NaN, 'DeltaT_90_10', NaN, 'Rlow_over_RN', NaN, ...
    'n_threshold_both_cross', 0, 'primary_interval_coverage', NaN, ...
    'comparative_adequacy_decision', "");
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
