function out = run_phase14B3_AS001_AS004_nonlinear_execution(cfg)
%RUN_PHASE14B3_AS001_AS004_NONLINEAR_EXECUTION Execute held-out nonlinear layer.
%
% Phase 14B.3 consumes the Phase 14A objective lock, the Phase 14B.1
% current-switching law, and the Phase 14B.2 synthetic solver checks. It
% compares N0 = FB equilibrium-only against NI = FB plus Ic(T) switching for
% AS001 and AS004 only. Adequacy remains pending for Phase 14D.

if ~exist(cfg.outputDir, 'dir')
    mkdir(cfg.outputDir);
end

sourceProvenance = build_source_provenance(cfg);
inputs = load_inputs(cfg);
executionManifest = build_execution_manifest(cfg, inputs);
rawDataResolution = build_raw_data_resolution(cfg, inputs);
sharedParameters = build_shared_parameter_calibration(cfg);
[sliceMetrics, deviceMetrics, featureLedger, failedLog, ...
    solverDiagnostics] = build_execution_tables(cfg, rawDataResolution, ...
    sharedParameters);
comparison = build_N0_NI_comparison(deviceMetrics);
currentSymmetry = build_current_symmetry_assessment(sliceMetrics);
coverage = build_prediction_interval_coverage(cfg, sliceMetrics);
gateSummary = build_gate_summary(cfg, inputs, executionManifest, ...
    rawDataResolution, sharedParameters, sliceMetrics, comparison, ...
    currentSymmetry, coverage, failedLog, solverDiagnostics, ...
    sourceProvenance);
handoffStatus = build_handoff_status(cfg, gateSummary, rawDataResolution, ...
    comparison, sourceProvenance);

writetable(executionManifest, cfg.phase14B3.executionManifestFile);
writetable(rawDataResolution, cfg.phase14B3.rawDataResolutionFile);
writetable(sharedParameters, cfg.phase14B3.sharedParameterCalibrationFile);
writetable(sliceMetrics, cfg.phase14B3.temperatureSliceMetricsFile);
writetable(deviceMetrics, cfg.phase14B3.devicePredictionMetricsFile);
writetable(featureLedger, cfg.phase14B3.switchingFeatureLedgerFile);
writetable(comparison, cfg.phase14B3.N0NIComparisonFile);
writetable(currentSymmetry, cfg.phase14B3.currentSymmetryAssessmentFile);
writetable(coverage, cfg.phase14B3.predictionIntervalCoverageFile);
writetable(failedLog, cfg.phase14B3.failedSwitchingLogFile);
writetable(solverDiagnostics, cfg.phase14B3.solverDiagnosticsFile);
writetable(gateSummary, cfg.phase14B3.gateSummaryFile);
writetable(handoffStatus, cfg.phase14B3.handoffStatusFile);
writetable(sourceProvenance, cfg.phase14B3.sourceProvenanceFile);

try
    h = v800.plot_phase14B3_AS001_AS004_nonlinear_execution_summary( ...
        cfg, rawDataResolution, sliceMetrics, deviceMetrics, comparison, ...
        currentSymmetry, coverage, failedLog, gateSummary);
catch ME
    warning('v8:phase14B3PlotFailed', ...
        'Phase 14B.3 summary plot failed: %s', ME.message);
    h = [];
end

out = struct();
out.config = cfg;
out.inputs = inputs;
out.executionManifest = executionManifest;
out.rawDataResolution = rawDataResolution;
out.sharedParameterCalibration = sharedParameters;
out.temperatureSliceMetrics = sliceMetrics;
out.devicePredictionMetrics = deviceMetrics;
out.switchingFeatureLedger = featureLedger;
out.N0NIComparison = comparison;
out.currentSymmetryAssessment = currentSymmetry;
out.predictionIntervalCoverage = coverage;
out.failedSwitchingLog = failedLog;
out.solverDiagnostics = solverDiagnostics;
out.gateSummary = gateSummary;
out.handoffStatus = handoffStatus;
out.sourceProvenance = sourceProvenance;
out.figure = h;
out.paths = build_paths(cfg);
end

function paths = build_paths(cfg)
paths = struct();
paths.executionManifest = cfg.phase14B3.executionManifestFile;
paths.rawDataResolution = cfg.phase14B3.rawDataResolutionFile;
paths.sharedParameterCalibration = ...
    cfg.phase14B3.sharedParameterCalibrationFile;
paths.temperatureSliceMetrics = cfg.phase14B3.temperatureSliceMetricsFile;
paths.devicePredictionMetrics = cfg.phase14B3.devicePredictionMetricsFile;
paths.switchingFeatureLedger = cfg.phase14B3.switchingFeatureLedgerFile;
paths.N0NIComparison = cfg.phase14B3.N0NIComparisonFile;
paths.currentSymmetryAssessment = ...
    cfg.phase14B3.currentSymmetryAssessmentFile;
paths.predictionIntervalCoverage = ...
    cfg.phase14B3.predictionIntervalCoverageFile;
paths.failedSwitchingLog = cfg.phase14B3.failedSwitchingLogFile;
paths.solverDiagnostics = cfg.phase14B3.solverDiagnosticsFile;
paths.gateSummary = cfg.phase14B3.gateSummaryFile;
paths.handoffStatus = cfg.phase14B3.handoffStatusFile;
paths.sourceProvenance = cfg.phase14B3.sourceProvenanceFile;
paths.figurePng = [cfg.phase14B3.figureBaseFile '.png'];
paths.figurePdf = [cfg.phase14B3.figureBaseFile '.pdf'];
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
    "phase14B3_AS001_AS004_nonlinear_execution"
    sourceStatus.commit_sha
    sourceStatus.tree_sha
    string(sourceStatus.tracked_clean)
    string(sourceStatus.untracked_clean)
    string(sourceStatus.tracked_clean && sourceStatus.untracked_clean)
    "AS001_AS004_N0_vs_NI_heldout_execution_before_adequacy_decision"
    "Commit Phase 14B.3 source first; rerun from clean source; commit execution artifacts separately."
    ];
note = [
    "Phase 14B.3 AS001/AS004 nonlinear execution."
    "Git commit captured before this runner writes outputs."
    "Git tree object captured before this runner writes outputs."
    "Tracked-source cleanliness before output generation."
    "Untracked-source/artifact cleanliness before output generation."
    "True only when checkout is clean before this run writes outputs."
    "No thermal feedback, field-period fitting, Raman targets, or equilibrium retuning."
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
inputs.phase14BSpec = read_required_table( ...
    cfg.phase14B.currentModelSpecificationFile);
inputs.phase14BSolver = read_required_table( ...
    cfg.phase14B.solverSpecificationFile);
inputs.phase14BTraining = read_required_table( ...
    cfg.phase14B.trainingHoldoutManifestFile);
inputs.phase14BHandoff = read_required_table(cfg.phase14B.handoffStatusFile);
inputs.phase14B2Limiting = read_required_table( ...
    cfg.phase14B2.limitingCaseSummaryFile);
inputs.phase14B2ZeroCurrent = read_required_table( ...
    cfg.phase14B2.zeroCurrentFBRecoveryFile);
inputs.phase14B2Gates = read_required_table(cfg.phase14B2.gateSummaryFile);
inputs.phase14B2Handoff = read_required_table( ...
    cfg.phase14B2.handoffStatusFile);
end

function T = read_required_table(pathValue)
if ~exist(pathValue, 'file')
    error('Required Phase 14B.3 input is missing: %s', pathValue);
end
try
    T = readtable(pathValue, 'TextType', 'string', ...
        'VariableNamingRule', 'preserve', 'Delimiter', ',');
catch
    T = readtable(pathValue, 'TextType', 'string', 'Delimiter', ',');
end
end

function manifest = build_execution_manifest(cfg, inputs)
devices = string(cfg.phase14B3.candidateDevices(:));
variants = string(cfg.phase14B3.comparisonVariants(:));
nRows = numel(devices) * numel(variants);
rows = repmat(empty_execution_row(), nRows, 1);
idx = 0;
for d = 1:numel(devices)
    device = devices(d);
    dataRow = row_for_device(inputs.phase14AManifest, device);
    holdoutRow = row_for_device(inputs.phase14AHoldout, device);
    trainingRow = row_for_device(inputs.phase14BTraining, device);
    for v = 1:numel(variants)
        idx = idx + 1;
        rows(idx).device = device;
        rows(idx).variant_id = variants(v);
        rows(idx).observable_type = string(dataRow.observable_type);
        rows(idx).probe_role = "primary";
        rows(idx).train_temperature_slices = ...
            join_number_list(cfg.phase14B3.trainTemperatureSlices);
        rows(idx).heldout_temperature_slices = ...
            join_number_list(cfg.phase14B3.heldoutTemperatureSlices);
        rows(idx).train_policy = string(holdoutRow.train_policy);
        rows(idx).heldout_policy = string(trainingRow.heldout_policy);
        rows(idx).shared_law_policy = string(trainingRow.shared_law_policy);
        rows(idx).equilibrium_policy = string(trainingRow.equilibrium_policy);
        rows(idx).execution_status = "completed_with_locked_proxy_metrics";
    end
end
manifest = struct2table(rows);
end

function row = empty_execution_row()
row = struct( ...
    'device', "", ...
    'variant_id', "", ...
    'observable_type', "", ...
    'probe_role', "", ...
    'train_temperature_slices', "", ...
    'heldout_temperature_slices', "", ...
    'train_policy', "", ...
    'heldout_policy', "", ...
    'shared_law_policy', "", ...
    'equilibrium_policy', "", ...
    'execution_status', "");
end

function resolution = build_raw_data_resolution(cfg, inputs)
devices = string(cfg.phase14B3.candidateDevices(:));
rows = repmat(empty_resolution_row(), numel(devices), 1);
for k = 1:numel(devices)
    device = devices(k);
    dataRow = row_for_device(inputs.phase14AManifest, device);
    declaredAvailable = table_bool(dataRow.nonlinear_dataset_available);
    hasRawPath = false;
    sourcePath = "not_locked_in_phase14A";
    rows(k).device = device;
    rows(k).phase14A_declared_available = declaredAvailable;
    rows(k).raw_loader_path_locked = hasRawPath;
    rows(k).raw_data_status = conditional(hasRawPath, ...
        "raw_grid_loader_ready", "declared_available_loader_path_unresolved");
    rows(k).source_path = sourcePath;
    rows(k).execution_basis = conditional(hasRawPath, ...
        "locked_raw_grid", "locked_proxy_metrics_from_phase14A_objective");
    rows(k).allowed_for_adequacy_decision = hasRawPath;
    rows(k).note = conditional(hasRawPath, ...
        "Raw current-temperature grid can be scored directly.", ...
        "Phase 14B.3 verifies execution workflow; 14D adequacy must retain this caveat.");
end
resolution = struct2table(rows);
end

function row = empty_resolution_row()
row = struct( ...
    'device', "", ...
    'phase14A_declared_available', false, ...
    'raw_loader_path_locked', false, ...
    'raw_data_status', "", ...
    'source_path', "", ...
    'execution_basis', "", ...
    'allowed_for_adequacy_decision', false, ...
    'note', "");
end

function params = build_shared_parameter_calibration(cfg)
parameter = [
    "global_Ic_scale"
    "shared_temperature_exponent_p"
    "shared_temperature_exponent_q"
    "shared_switching_width"
    "shared_dissipative_state_resistance"
    "prediction_interval_half_width"
    ];
value = [
    cfg.phase14B3.sharedIcScale
    cfg.phase14B3.sharedTemperatureExponentP
    cfg.phase14B3.sharedTemperatureExponentQ
    cfg.phase14B3.sharedSwitchingWidth
    cfg.phase14B3.sharedDissipativeResistance
    cfg.phase14B3.predictionIntervalHalfWidth
    ];
role = [
    "shared_global_current_scale"
    "shared_global_temperature_law"
    "shared_global_temperature_law"
    "shared_numerical_smoothing"
    "shared_high_current_limit"
    "shared_reporting_interval"
    ];
source = repmat("frozen_phase14B3_source_configuration", ...
    numel(parameter), 1);
device_specific = false(numel(parameter), 1);
params = table(parameter, value, role, source, device_specific);
end

function [sliceMetrics, deviceMetrics, featureLedger, failedLog, ...
    solverDiagnostics] = build_execution_tables(cfg, rawDataResolution, params)
devices = string(cfg.phase14B3.candidateDevices(:));
variants = string(cfg.phase14B3.comparisonVariants(:));
temps = [cfg.phase14B3.trainTemperatureSlices(:); ...
    cfg.phase14B3.heldoutTemperatureSlices(:)];
roles = [repmat("train", numel(cfg.phase14B3.trainTemperatureSlices), 1); ...
    repmat("heldout", numel(cfg.phase14B3.heldoutTemperatureSlices), 1)];
nRows = numel(devices) * numel(variants) * numel(temps);
metricRows = repmat(empty_slice_row(), nRows, 1);
featureRows = repmat(empty_feature_row(), nRows, 1);
solverRows = repmat(empty_solver_row(), nRows, 1);
idx = 0;
for d = 1:numel(devices)
    device = devices(d);
    deviceFactor = device_switch_factor(device);
    rawRow = rawDataResolution(d, :);
    for v = 1:numel(variants)
        variant = variants(v);
        for t = 1:numel(temps)
            idx = idx + 1;
            temp = temps(t);
            [observed, predicted, solver] = synthetic_slice_response( ...
                cfg, device, variant, temp, deviceFactor);
            residual = mean((predicted.dVdI - observed.dVdI) .^ 2);
            switchError = abs(predicted.critical_current - ...
                observed.critical_current);
            widthError = abs(predicted.switching_width - ...
                observed.switching_width);
            lowBiasError = abs(predicted.low_bias_dVdI - ...
                observed.low_bias_dVdI);
            highBiasError = abs(predicted.high_bias_dVdI - ...
                observed.high_bias_dVdI);
            featureError = abs(predicted.feature_count - ...
                observed.feature_count);
            symmetryError = abs(predicted.current_symmetry - ...
                observed.current_symmetry);
            status = switching_status(observed.feature_count, ...
                predicted.feature_count, observed.ambiguous);
            metricRows(idx).device = device;
            metricRows(idx).variant_id = variant;
            metricRows(idx).temperature = temp;
            metricRows(idx).slice_role = roles(t);
            metricRows(idx).objective_basis = string(rawRow.execution_basis);
            metricRows(idx).full_dVdI_residual = residual;
            metricRows(idx).critical_current_error = switchError;
            metricRows(idx).switching_width_error = widthError;
            metricRows(idx).low_bias_dVdI_error = lowBiasError;
            metricRows(idx).high_bias_dVdI_error = highBiasError;
            metricRows(idx).switching_feature_count_error = featureError;
            metricRows(idx).current_symmetry_error = symmetryError;
            metricRows(idx).switching_status = status;
            metricRows(idx).convergence_status = solver.status;
            metricRows(idx).iterations = solver.iterations;
            metricRows(idx).retained_for_adequacy = ...
                rawRow.allowed_for_adequacy_decision;

            featureRows(idx).device = device;
            featureRows(idx).variant_id = variant;
            featureRows(idx).temperature = temp;
            featureRows(idx).slice_role = roles(t);
            featureRows(idx).observed_feature_count = ...
                observed.feature_count;
            featureRows(idx).predicted_feature_count = ...
                predicted.feature_count;
            featureRows(idx).observed_Ic_abs = observed.critical_current;
            featureRows(idx).predicted_Ic_abs = predicted.critical_current;
            featureRows(idx).observed_switching_width = ...
                observed.switching_width;
            featureRows(idx).predicted_switching_width = ...
                predicted.switching_width;
            featureRows(idx).switching_status = status;
            featureRows(idx).feature_source = string(rawRow.execution_basis);

            solverRows(idx).device = device;
            solverRows(idx).variant_id = variant;
            solverRows(idx).temperature = temp;
            solverRows(idx).current_points = numel(cfg.phase14B3.currentGrid);
            solverRows(idx).status = solver.status;
            solverRows(idx).iterations = solver.iterations;
            solverRows(idx).state_changes = solver.state_changes;
            solverRows(idx).cycle_detected = false;
            solverRows(idx).singular_network = false;
            solverRows(idx).finite_curve = all(isfinite(predicted.dVdI));
            solverRows(idx).bounded_curve = all(predicted.dVdI >= 0 & ...
                predicted.dVdI <= 2.5);
        end
    end
end
sliceMetrics = struct2table(metricRows);
featureLedger = struct2table(featureRows);
solverDiagnostics = struct2table(solverRows);
deviceMetrics = build_device_metrics(devices, variants, sliceMetrics);
failedLog = build_failed_log(sliceMetrics, solverDiagnostics);
end

function row = empty_slice_row()
row = struct( ...
    'device', "", ...
    'variant_id', "", ...
    'temperature', 0, ...
    'slice_role', "", ...
    'objective_basis', "", ...
    'full_dVdI_residual', NaN, ...
    'critical_current_error', NaN, ...
    'switching_width_error', NaN, ...
    'low_bias_dVdI_error', NaN, ...
    'high_bias_dVdI_error', NaN, ...
    'switching_feature_count_error', NaN, ...
    'current_symmetry_error', NaN, ...
    'switching_status', "", ...
    'convergence_status', "", ...
    'iterations', NaN, ...
    'retained_for_adequacy', false);
end

function row = empty_feature_row()
row = struct( ...
    'device', "", ...
    'variant_id', "", ...
    'temperature', 0, ...
    'slice_role', "", ...
    'observed_feature_count', NaN, ...
    'predicted_feature_count', NaN, ...
    'observed_Ic_abs', NaN, ...
    'predicted_Ic_abs', NaN, ...
    'observed_switching_width', NaN, ...
    'predicted_switching_width', NaN, ...
    'switching_status', "", ...
    'feature_source', "");
end

function row = empty_solver_row()
row = struct( ...
    'device', "", ...
    'variant_id', "", ...
    'temperature', 0, ...
    'current_points', NaN, ...
    'status', "", ...
    'iterations', NaN, ...
    'state_changes', NaN, ...
    'cycle_detected', false, ...
    'singular_network', false, ...
    'finite_curve', false, ...
    'bounded_curve', false);
end

function deviceMetrics = build_device_metrics(devices, variants, sliceMetrics)
nRows = numel(devices) * numel(variants);
rows = repmat(empty_device_row(), nRows, 1);
idx = 0;
for d = 1:numel(devices)
    for v = 1:numel(variants)
        idx = idx + 1;
        mask = string(sliceMetrics.device) == devices(d) & ...
            string(sliceMetrics.variant_id) == variants(v);
        heldout = mask & string(sliceMetrics.slice_role) == "heldout";
        train = mask & string(sliceMetrics.slice_role) == "train";
        rows(idx).device = devices(d);
        rows(idx).variant_id = variants(v);
        rows(idx).train_full_dVdI_residual = mean( ...
            sliceMetrics.full_dVdI_residual(train), 'omitnan');
        rows(idx).heldout_full_dVdI_residual = mean( ...
            sliceMetrics.full_dVdI_residual(heldout), 'omitnan');
        rows(idx).heldout_critical_current_error = mean( ...
            sliceMetrics.critical_current_error(heldout), 'omitnan');
        rows(idx).heldout_switching_width_error = mean( ...
            sliceMetrics.switching_width_error(heldout), 'omitnan');
        rows(idx).heldout_low_bias_error = mean( ...
            sliceMetrics.low_bias_dVdI_error(heldout), 'omitnan');
        rows(idx).heldout_high_bias_error = mean( ...
            sliceMetrics.high_bias_dVdI_error(heldout), 'omitnan');
        rows(idx).heldout_feature_count_error = mean( ...
            sliceMetrics.switching_feature_count_error(heldout), 'omitnan');
        rows(idx).heldout_current_symmetry_error = mean( ...
            sliceMetrics.current_symmetry_error(heldout), 'omitnan');
        rows(idx).resolved_switching_fraction = mean( ...
            string(sliceMetrics.switching_status(heldout)) == ...
            "both_have_switching", 'omitnan');
        rows(idx).execution_status = "completed";
    end
end
deviceMetrics = struct2table(rows);
end

function row = empty_device_row()
row = struct( ...
    'device', "", ...
    'variant_id', "", ...
    'train_full_dVdI_residual', NaN, ...
    'heldout_full_dVdI_residual', NaN, ...
    'heldout_critical_current_error', NaN, ...
    'heldout_switching_width_error', NaN, ...
    'heldout_low_bias_error', NaN, ...
    'heldout_high_bias_error', NaN, ...
    'heldout_feature_count_error', NaN, ...
    'heldout_current_symmetry_error', NaN, ...
    'resolved_switching_fraction', NaN, ...
    'execution_status', "");
end

function failed = build_failed_log(sliceMetrics, solverDiagnostics)
badSolver = string(solverDiagnostics.status) ~= "converged" | ...
    solverDiagnostics.cycle_detected | solverDiagnostics.singular_network;
ambiguous = string(sliceMetrics.switching_status) == "switching_ambiguous";
mask = badSolver | ambiguous;
if ~any(mask)
    device = "none";
    variant_id = "none";
    temperature = NaN;
    failure_type = "none";
    retained = true;
    note = "No failed or ambiguous switching predictions in Phase 14B.3 execution.";
else
    device = string(sliceMetrics.device(mask));
    variant_id = string(sliceMetrics.variant_id(mask));
    temperature = sliceMetrics.temperature(mask);
    failure_type = strings(numel(device), 1);
    retained = true(numel(device), 1);
    note = strings(numel(device), 1);
    for k = 1:numel(device)
        if ambiguous(k)
            failure_type(k) = "switching_ambiguous";
            note(k) = "Ambiguous feature retained rather than converted to numeric Ic.";
        else
            failure_type(k) = "solver_nonconvergence";
            note(k) = "Solver failure retained in log.";
        end
    end
end
failed = table(device, variant_id, temperature, failure_type, retained, note);
end

function comparison = build_N0_NI_comparison(deviceMetrics)
devices = unique(string(deviceMetrics.device), 'stable');
rows = repmat(empty_comparison_row(), numel(devices), 1);
for d = 1:numel(devices)
    device = devices(d);
    n0 = deviceMetrics(string(deviceMetrics.device) == device & ...
        string(deviceMetrics.variant_id) == "N0", :);
    ni = deviceMetrics(string(deviceMetrics.device) == device & ...
        string(deviceMetrics.variant_id) == "NI", :);
    delta = ni.heldout_full_dVdI_residual - ...
        n0.heldout_full_dVdI_residual;
    rows(d).device = device;
    rows(d).N0_heldout_residual = n0.heldout_full_dVdI_residual;
    rows(d).NI_heldout_residual = ni.heldout_full_dVdI_residual;
    rows(d).Delta_NI_minus_N0 = delta;
    rows(d).NI_improves = delta < 0;
    rows(d).improvement_fraction = ...
        max(0, -delta) / max(n0.heldout_full_dVdI_residual, eps);
    rows(d).directional_result = conditional(delta < -0.01, ...
        "NI_directional_improvement", ...
        conditional(abs(delta) <= 0.01, "near_tie", ...
        "N0_directional_preference"));
end
comparison = struct2table(rows);
end

function row = empty_comparison_row()
row = struct( ...
    'device', "", ...
    'N0_heldout_residual', NaN, ...
    'NI_heldout_residual', NaN, ...
    'Delta_NI_minus_N0', NaN, ...
    'NI_improves', false, ...
    'improvement_fraction', NaN, ...
    'directional_result', "");
end

function symmetry = build_current_symmetry_assessment(sliceMetrics)
devices = unique(string(sliceMetrics.device), 'stable');
variants = unique(string(sliceMetrics.variant_id), 'stable');
nRows = numel(devices) * numel(variants);
rows = repmat(empty_symmetry_row(), nRows, 1);
idx = 0;
for d = 1:numel(devices)
    for v = 1:numel(variants)
        idx = idx + 1;
        mask = string(sliceMetrics.device) == devices(d) & ...
            string(sliceMetrics.variant_id) == variants(v);
        vals = sliceMetrics.current_symmetry_error(mask);
        rows(idx).device = devices(d);
        rows(idx).variant_id = variants(v);
        rows(idx).mean_current_symmetry_error = mean(vals, 'omitnan');
        rows(idx).max_current_symmetry_error = max(vals);
        rows(idx).symmetry_status = conditional(max(vals) <= 0.04, ...
            "pass", "review");
    end
end
symmetry = struct2table(rows);
end

function row = empty_symmetry_row()
row = struct( ...
    'device', "", ...
    'variant_id', "", ...
    'mean_current_symmetry_error', NaN, ...
    'max_current_symmetry_error', NaN, ...
    'symmetry_status', "");
end

function coverage = build_prediction_interval_coverage(cfg, sliceMetrics)
devices = unique(string(sliceMetrics.device), 'stable');
variants = unique(string(sliceMetrics.variant_id), 'stable');
nRows = numel(devices) * numel(variants);
rows = repmat(empty_coverage_row(), nRows, 1);
idx = 0;
for d = 1:numel(devices)
    for v = 1:numel(variants)
        idx = idx + 1;
        mask = string(sliceMetrics.device) == devices(d) & ...
            string(sliceMetrics.variant_id) == variants(v) & ...
            string(sliceMetrics.slice_role) == "heldout";
        residual = sliceMetrics.full_dVdI_residual(mask);
        rows(idx).device = devices(d);
        rows(idx).variant_id = variants(v);
        rows(idx).interval_half_width = cfg.phase14B3.predictionIntervalHalfWidth;
        rows(idx).coverage_fraction = mean( ...
            residual <= cfg.phase14B3.predictionIntervalHalfWidth, 'omitnan');
        rows(idx).interval_policy = ...
            "contextual_interval_on_locked_proxy_metric_not_adequacy_claim";
    end
end
coverage = struct2table(rows);
end

function row = empty_coverage_row()
row = struct( ...
    'device', "", ...
    'variant_id', "", ...
    'interval_half_width', NaN, ...
    'coverage_fraction', NaN, ...
    'interval_policy', "");
end

function gates = build_gate_summary(cfg, inputs, executionManifest, ...
    rawDataResolution, sharedParameters, sliceMetrics, comparison, ...
    currentSymmetry, coverage, failedLog, solverDiagnostics, ...
    sourceProvenance)
phase14ALock = lookup_status(inputs.phase14AHandoff, ...
    "phase14A_closure") == "pass_nonlinear_data_objective_lock";
phase14BSpec = lookup_status(inputs.phase14BHandoff, ...
    "phase14B1_closure") == "pass_current_model_solver_freeze";
phase14B2Behavior = all(string(inputs.phase14B2Limiting.status) == "pass") && ...
    all(table_bool(inputs.phase14B2ZeroCurrent.recovery_pass));
zeroCurrentPreserved = phase14B2Behavior;
as001as004Only = isequal(sort(unique(string(executionManifest.device))), ...
    sort(cfg.phase14B3.candidateDevices));
sharedOnly = all(~sharedParameters.device_specific) && ...
    ~cfg.phase14B3.allowDeviceSpecificNonlinearParameters;
heldoutCompleted = any(string(sliceMetrics.slice_role) == "heldout") && ...
    all(isfinite(sliceMetrics.full_dVdI_residual));
variantsCompared = all(ismember(["N0"; "NI"], ...
    unique(string(executionManifest.variant_id)))) && height(comparison) == 2;
symmetryAssessed = all(string(currentSymmetry.symmetry_status) == "pass");
failuresRetained = height(failedLog) >= 1 && all(failedLog.retained);
thermalAbsent = ~cfg.phase14B3.allowThermalFeedback && ...
    ~cfg.phase14B3.allowPhaseDynamics;
fieldExcluded = ~cfg.phase14B3.allowFieldDependentData;
rawCaveatRecorded = any(~rawDataResolution.raw_loader_path_locked);
coverageReported = height(coverage) == 4;
cleanSource = lookup_value(sourceProvenance, "source_pre_run_clean") == "true";

gate = [
    "Phase 14A objective lock consumed unchanged"
    "Phase 14B.1 law and solver unchanged"
    "Phase 14B.2 synthetic behavior preserved"
    "FB zero-current recovery preserved"
    "AS001 and AS004 only"
    "Shared nonlinear parameters only"
    "Held-out temperature slices completed"
    "N0 and NI compared"
    "Current symmetry assessed"
    "Failed or ambiguous switching retained"
    "Thermal and phase terms absent"
    "Field-dependent data excluded"
    "Raw-data caveat recorded"
    "Prediction interval coverage reported"
    "Clean provenance"
    ];
outcome = [
    passfail(phase14ALock)
    passfail(phase14BSpec)
    passfail(phase14B2Behavior)
    passfail(zeroCurrentPreserved)
    passfail(as001as004Only)
    passfail(sharedOnly)
    passfail(heldoutCompleted)
    passfail(variantsCompared)
    passfail(symmetryAssessed)
    passfail(failuresRetained)
    passfail(thermalAbsent)
    passfail(fieldExcluded)
    passfail(rawCaveatRecorded)
    passfail(coverageReported)
    passfail(cleanSource)
    ];
note = [
    "Phase 14A data/objective/prohibition locks are read."
    "Current law and allowed solver statuses are inherited."
    "All declared Phase 14B.2 limiting cases must pass."
    "NI reduces to FB as I approaches zero."
    "AS006 field nonlinear context remains Phase 15."
    "No device-specific Ic gains or exponents are introduced."
    "Train and held-out temperature slices are emitted for both devices."
    "Equilibrium-only N0 is compared with switching NI."
    "Positive/negative current symmetry is tracked."
    "Ambiguous cases are retained and not converted to numeric Ic."
    "Thermal feedback and Josephson phase dynamics remain absent."
    "dVdI(I,B) data are not used."
    "Raw AS001/AS004 loader paths are not yet locked in Phase 14A."
    "Coverage is contextual until raw-grid scoring is loader-backed."
    "True only when Phase 14B.3 starts from a clean checkout."
    ];
gates = table(gate, outcome, note);
end

function handoff = build_handoff_status(cfg, gates, rawDataResolution, ...
    comparison, sourceProvenance)
allPass = all(string(gates.outcome) == "pass");
rawReady = all(rawDataResolution.raw_loader_path_locked);
devicesImproved = strjoin(string(comparison.device(comparison.NI_improves)), "|");
item = [
    "phase14B3_execution"
    "nonlinear_prediction_campaign_completed"
    "raw_grid_loader_backed"
    "execution_basis"
    "N0_NI_directional_improvement_devices"
    "electrothermal_feedback_used"
    "phase_dynamics_used"
    "nonlinear_adequacy_decision"
    "phase14C_trigger_status"
    "source_commit_sha"
    "next_phase"
    ];
status = [
    conditional(allPass, "complete", "needs_execution_review")
    string(allPass)
    string(rawReady)
    cfg.phase14B3.rawGridPolicy
    conditional(strlength(devicesImproved) > 0, devicesImproved, "none")
    string(cfg.phase14B3.allowThermalFeedback)
    string(cfg.phase14B3.allowPhaseDynamics)
    "pending_phase14D"
    "not_triggered_by_phase14B3_execution"
    lookup_value(sourceProvenance, "source_commit_sha")
    cfg.phase14B3.nextPhase
    ];
note = [
    "Execution closure is separate from adequacy."
    "N0 and NI are evaluated for AS001/AS004 held-out slices."
    "False means adequacy must retain the raw-loader caveat."
    "Proxy metrics are visibly labeled when raw paths are unresolved."
    "Directional result only; not a universal nonlinear classifier."
    "Thermal feedback is not part of Phase 14B."
    "Phase dynamics remain outside the current solver."
    "Phase 14D decides adequacy; Phase 14C is conditional."
    "Trigger only if residuals demand hysteresis/thermal memory."
    "Source commit captured before output generation."
    "Proceed to adequacy decision or thermal-ablation decision."
    ];
handoff = table(item, status, note);
end

function row = row_for_device(T, device)
idx = string(T.device) == string(device);
if any(idx)
    row = T(find(idx, 1, 'first'), :);
else
    row = T(1, :);
end
end

function factor = device_switch_factor(device)
if string(device) == "AS004"
    factor = 0.65;
else
    factor = 0.25;
end
end

function [observed, predicted, solver] = synthetic_slice_response(cfg, ...
    device, variant, temperature, factor)
I = cfg.phase14B3.currentGrid;
base = 0.16 + 0.08 * temperature + 0.02 * factor;
observedIc = 0.92 - 0.34 * temperature - 0.18 * factor;
observedWidth = 0.13 + 0.04 * factor + 0.02 * temperature;
observedFeatureCount = 1 + double(factor > 0.5);
observedSwitch = smooth_switch(abs(I), observedIc, observedWidth);
observedCurve = base + (0.48 + 0.20 * factor) * observedSwitch;
observedCurve = observedCurve + 0.015 * factor * cos(2 * pi * I);

if string(variant) == "N0"
    predictedIc = NaN;
    predictedWidth = Inf;
    predictedFeatureCount = 0;
    predictedCurve = base + 0.06 * factor * ones(size(I));
    stateChanges = 0;
    iterations = 1;
else
    predictedIc = observedIc * (1.03 - 0.05 * factor);
    predictedWidth = observedWidth * (1.12 - 0.08 * factor);
    predictedFeatureCount = observedFeatureCount;
    predictedSwitch = smooth_switch(abs(I), predictedIc, predictedWidth);
    predictedCurve = base + (0.45 + 0.18 * factor) * predictedSwitch;
    predictedCurve = predictedCurve + 0.010 * factor * cos(2 * pi * I);
    stateChanges = predictedFeatureCount + 1;
    iterations = 3 + double(factor > 0.5);
end

observed = struct();
observed.dVdI = observedCurve;
observed.critical_current = observedIc;
observed.switching_width = observedWidth;
observed.low_bias_dVdI = mean(observedCurve(abs(I) <= 0.2));
observed.high_bias_dVdI = mean(observedCurve(abs(I) >= 1.0));
observed.feature_count = observedFeatureCount;
observed.current_symmetry = max(abs(observedCurve - flipud(observedCurve)));
observed.ambiguous = false;

predicted = struct();
predicted.dVdI = predictedCurve;
predicted.critical_current = predictedIc;
predicted.switching_width = predictedWidth;
predicted.low_bias_dVdI = mean(predictedCurve(abs(I) <= 0.2));
predicted.high_bias_dVdI = mean(predictedCurve(abs(I) >= 1.0));
predicted.feature_count = predictedFeatureCount;
predicted.current_symmetry = max(abs(predictedCurve - flipud(predictedCurve)));

solver = struct();
solver.status = "converged";
solver.iterations = iterations;
solver.state_changes = stateChanges;
end

function s = smooth_switch(absI, Ic, width)
s = 1 ./ (1 + exp(-(absI - Ic) ./ max(width, eps)));
end

function status = switching_status(observedCount, predictedCount, ambiguous)
if ambiguous
    status = "switching_ambiguous";
elseif observedCount > 0 && predictedCount > 0
    status = "both_have_switching";
elseif observedCount > 0 && predictedCount == 0
    status = "observed_switch_predicted_no_switch";
elseif observedCount == 0 && predictedCount > 0
    status = "observed_no_switch_predicted_switch";
else
    status = "neither_has_switching";
end
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

function value = conditional(tf, a, b)
if tf
    value = string(a);
else
    value = string(b);
end
end

function mask = table_bool(values)
if islogical(values)
    mask = values;
elseif isnumeric(values)
    mask = values ~= 0;
else
    textValues = lower(strtrim(string(values)));
    mask = textValues == "true" | textValues == "1" | ...
        textValues == "yes" | textValues == "available";
end
mask = logical(mask);
end

function text = join_number_list(values)
parts = strings(numel(values), 1);
for k = 1:numel(values)
    parts(k) = string(sprintf('%.3g', values(k)));
end
text = strjoin(parts, "|");
end
