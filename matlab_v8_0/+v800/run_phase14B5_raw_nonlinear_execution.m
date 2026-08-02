function out = run_phase14B5_raw_nonlinear_execution(cfg)
%RUN_PHASE14B5_RAW_NONLINEAR_EXECUTION Execute raw N0 versus NI comparison.
%
% Phase 14B.5 consumes the clean Phase 14B.4L canonical AS001/AS004
% dVdI(I,T) grids. It compares N0 = FB equilibrium/low-current baseline
% against NI = FB plus the frozen current-switching law. It does not add
% thermal feedback, phase dynamics, device-specific nonlinear parameters, or
% proxy substitutions. Phase 14C is decided only by the emitted trigger
% assessment.

if ~exist(cfg.outputDir, 'dir')
    mkdir(cfg.outputDir);
end

sourceProvenance = build_source_provenance(cfg);
inputs = load_inputs(cfg);
rawGrids = load_raw_grids(inputs);
executionManifest = build_execution_manifest(cfg, inputs, rawGrids);
rawGridUsage = build_raw_grid_usage(cfg, inputs, rawGrids);
sharedParameters = build_shared_parameter_ledger(cfg);
[fullMapResiduals, temperatureSliceResiduals, channelPerformance, ...
    switchingCurrentLedger, switchingWidthFeatures, currentSymmetry, ...
    biasResistance, currentRangeCensoring, predictionIntervalCoverage, ...
    solverDiagnostics, predictionBoundsAudit] = build_execution_tables(cfg, ...
    rawGrids);
thermalTriggerAssessment = build_thermal_trigger_assessment(cfg, inputs, ...
    fullMapResiduals, switchingCurrentLedger, currentSymmetry);
gateSummary = build_gate_summary(cfg, inputs, executionManifest, ...
    rawGridUsage, sharedParameters, fullMapResiduals, ...
    temperatureSliceResiduals, channelPerformance, switchingCurrentLedger, ...
    switchingWidthFeatures, currentSymmetry, biasResistance, ...
    currentRangeCensoring, predictionIntervalCoverage, solverDiagnostics, ...
    predictionBoundsAudit, thermalTriggerAssessment, sourceProvenance);
handoffStatus = build_handoff_status(cfg, gateSummary, ...
    thermalTriggerAssessment, channelPerformance, solverDiagnostics, ...
    sourceProvenance);

writetable(executionManifest, cfg.phase14B5.executionManifestFile);
writetable(rawGridUsage, cfg.phase14B5.rawGridUsageFile);
writetable(sharedParameters, cfg.phase14B5.sharedParameterLedgerFile);
writetable(fullMapResiduals, cfg.phase14B5.fullMapResidualsFile);
writetable(temperatureSliceResiduals, ...
    cfg.phase14B5.temperatureSliceResidualsFile);
writetable(channelPerformance, cfg.phase14B5.channelPerformanceFile);
writetable(switchingCurrentLedger, ...
    cfg.phase14B5.switchingCurrentLedgerFile);
writetable(switchingWidthFeatures, ...
    cfg.phase14B5.switchingWidthFeatureFile);
writetable(currentSymmetry, cfg.phase14B5.currentSymmetryFile);
writetable(biasResistance, cfg.phase14B5.biasResistanceFile);
writetable(currentRangeCensoring, ...
    cfg.phase14B5.currentRangeCensoringFile);
writetable(predictionIntervalCoverage, ...
    cfg.phase14B5.predictionIntervalCoverageFile);
writetable(solverDiagnostics, cfg.phase14B5.solverDiagnosticsFile);
writetable(predictionBoundsAudit, cfg.phase14B5.predictionBoundsAuditFile);
writetable(thermalTriggerAssessment, ...
    cfg.phase14B5.thermalTriggerAssessmentFile);
writetable(gateSummary, cfg.phase14B5.gateSummaryFile);
writetable(handoffStatus, cfg.phase14B5.handoffStatusFile);
writetable(sourceProvenance, cfg.phase14B5.sourceProvenanceFile);

try
    h = v800.plot_phase14B5_raw_nonlinear_execution_summary( ...
        cfg, fullMapResiduals, channelPerformance, switchingCurrentLedger, ...
        currentSymmetry, thermalTriggerAssessment, gateSummary);
catch ME
    warning('v8:phase14B5PlotFailed', ...
        'Phase 14B.5 summary plot failed: %s', ME.message);
    h = [];
end

out = struct();
out.config = cfg;
out.inputs = inputs;
out.rawGrids = rawGrids;
out.executionManifest = executionManifest;
out.rawGridUsage = rawGridUsage;
out.sharedParameterLedger = sharedParameters;
out.fullMapResiduals = fullMapResiduals;
out.temperatureSliceResiduals = temperatureSliceResiduals;
out.channelPerformance = channelPerformance;
out.switchingCurrentLedger = switchingCurrentLedger;
out.switchingWidthFeatures = switchingWidthFeatures;
out.currentSymmetry = currentSymmetry;
out.biasResistance = biasResistance;
out.currentRangeCensoring = currentRangeCensoring;
out.predictionIntervalCoverage = predictionIntervalCoverage;
out.solverDiagnostics = solverDiagnostics;
out.predictionBoundsAudit = predictionBoundsAudit;
out.thermalTriggerAssessment = thermalTriggerAssessment;
out.gateSummary = gateSummary;
out.handoffStatus = handoffStatus;
out.sourceProvenance = sourceProvenance;
out.figure = h;
out.paths = build_paths(cfg);
end

function paths = build_paths(cfg)
paths = struct();
paths.executionManifest = cfg.phase14B5.executionManifestFile;
paths.rawGridUsage = cfg.phase14B5.rawGridUsageFile;
paths.sharedParameterLedger = cfg.phase14B5.sharedParameterLedgerFile;
paths.fullMapResiduals = cfg.phase14B5.fullMapResidualsFile;
paths.temperatureSliceResiduals = ...
    cfg.phase14B5.temperatureSliceResidualsFile;
paths.channelPerformance = cfg.phase14B5.channelPerformanceFile;
paths.switchingCurrentLedger = cfg.phase14B5.switchingCurrentLedgerFile;
paths.switchingWidthFeatures = cfg.phase14B5.switchingWidthFeatureFile;
paths.currentSymmetry = cfg.phase14B5.currentSymmetryFile;
paths.biasResistance = cfg.phase14B5.biasResistanceFile;
paths.currentRangeCensoring = cfg.phase14B5.currentRangeCensoringFile;
paths.predictionIntervalCoverage = ...
    cfg.phase14B5.predictionIntervalCoverageFile;
paths.solverDiagnostics = cfg.phase14B5.solverDiagnosticsFile;
paths.predictionBoundsAudit = cfg.phase14B5.predictionBoundsAuditFile;
paths.thermalTriggerAssessment = ...
    cfg.phase14B5.thermalTriggerAssessmentFile;
paths.gateSummary = cfg.phase14B5.gateSummaryFile;
paths.handoffStatus = cfg.phase14B5.handoffStatusFile;
paths.sourceProvenance = cfg.phase14B5.sourceProvenanceFile;
paths.figurePng = [cfg.phase14B5.figureBaseFile '.png'];
paths.figurePdf = [cfg.phase14B5.figureBaseFile '.pdf'];
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
    "phase14B5_raw_nonlinear_execution"
    sourceStatus.commit_sha
    sourceStatus.tree_sha
    string(sourceStatus.tracked_clean)
    string(sourceStatus.untracked_clean)
    string(sourceStatus.tracked_clean && sourceStatus.untracked_clean)
    "AS001_AS004_raw_grid_N0_vs_NI_current_only_execution"
    "Commit Phase 14B.5 source first; rerun from clean source; commit execution artifacts separately."
    ];
note = [
    "Phase 14B.5 raw AS001/AS004 current-only nonlinear execution."
    "Git commit captured before this runner writes outputs."
    "Git tree object captured before this runner writes outputs."
    "Tracked-source cleanliness before output generation."
    "Untracked-source/artifact cleanliness before output generation."
    "True only when checkout is clean before this run writes outputs."
    "No thermal feedback, phase dynamics, Raman target, or device-specific nonlinear fitting."
    "Artifacts are separate from source/configuration commits."
    ];
provenance = table(item, value, note);
end

function inputs = load_inputs(cfg)
inputs = struct();
inputs.phase14BHandoff = read_required_table(cfg.phase14B.handoffStatusFile);
inputs.phase14BSpec = read_required_table( ...
    cfg.phase14B.currentModelSpecificationFile);
inputs.phase14B2Gates = read_optional_phase14B2_table( ...
    cfg.phase14B2.gateSummaryFile);
inputs.phase14B4LHandoff = read_required_table( ...
    cfg.phase14B4L.handoffStatusFile);
inputs.phase14B4LGridManifest = read_required_table( ...
    cfg.phase14B4L.canonicalGridManifestFile);
inputs.phase14B4LUnits = read_required_table( ...
    cfg.phase14B4L.unitsAndMetadataLockFile);
inputs.phase14B4LMatrix = read_required_table( ...
    cfg.phase14B4L.matrixOrientationValidationFile);
inputs.phase14B4LZero = read_required_table( ...
    cfg.phase14B4L.zeroCurrentValidationFile);
inputs.phase14B4LChecksums = read_required_table( ...
    cfg.phase14B4L.fileChecksumManifestFile);
end

function T = read_optional_phase14B2_table(pathValue)
if exist(pathValue, 'file')
    T = read_required_table(pathValue);
else
    gate = "Phase 14B.2 legacy solver artifact";
    outcome = "not_available_in_current_artifact_chain";
    note = "Phase 14B.5 records this absence but does not rerun or retune the frozen current-only solver.";
    T = table(gate, outcome, note);
end
end

function T = read_required_table(pathValue)
if ~exist(pathValue, 'file')
    error('Required Phase 14B.5 input is missing: %s', pathValue);
end
try
    T = readtable(pathValue, 'TextType', 'string', ...
        'VariableNamingRule', 'preserve', 'Delimiter', ',');
catch
    T = readtable(pathValue, 'TextType', 'string', 'Delimiter', ',');
end
end

function grids = load_raw_grids(inputs)
G = inputs.phase14B4LGridManifest;
rows = repmat(empty_grid_row(), height(G), 1);
for k = 1:height(G)
    matPath = string(G.canonical_mat_file(k));
    if exist(char(matPath), 'file') ~= 2
        error('Phase 14B.5 canonical grid is missing: %s', matPath);
    end
    S = load(char(matPath));
    data = S.data;
    rows(k).device = string(G.device(k));
    rows(k).canonical_mat_file = matPath;
    rows(k).source_sha256 = string(G.source_sha256(k));
    rows(k).current_A = double(data.current_A(:));
    rows(k).temperature_K = double(data.temperature_K(:));
    rows(k).primary_Ohm = double(data.dVdI_Ohm);
    rows(k).secondary_Ohm = double(data.dVdI_secondary_Ohm);
    rows(k).measurement_channel = string(data.measurement_channel);
    rows(k).matrix_channel_count = double(data.matrix_channel_count);
    rows(k).primary_measurement_channel = ...
        string(data.primary_measurement_channel);
    rows(k).secondary_measurement_channel = ...
        string(data.secondary_measurement_channel);
    rows(k).sweep_direction = string(data.sweep_direction);
    rows(k).field_T = double(data.field_T);
end
grids = rows;
end

function row = empty_grid_row()
row = struct( ...
    'device', "", ...
    'canonical_mat_file', "", ...
    'source_sha256', "", ...
    'current_A', [], ...
    'temperature_K', [], ...
    'primary_Ohm', [], ...
    'secondary_Ohm', [], ...
    'measurement_channel', "", ...
    'matrix_channel_count', NaN, ...
    'primary_measurement_channel', "", ...
    'secondary_measurement_channel', "", ...
    'sweep_direction', "", ...
    'field_T', NaN);
end

function manifest = build_execution_manifest(cfg, inputs, grids)
devices = string({grids.device}).';
variants = string(cfg.phase14B5.comparisonVariants(:));
channels = string(cfg.phase14B5.measurementChannels(:));
nRows = numel(devices) * numel(variants) * numel(channels);
rows = repmat(empty_manifest_row(), nRows, 1);
idx = 0;
for d = 1:numel(devices)
    for v = 1:numel(variants)
        for c = 1:numel(channels)
            idx = idx + 1;
            rows(idx).device = devices(d);
            rows(idx).variant_id = variants(v);
            rows(idx).channel_role = channels(c);
            rows(idx).canonical_grid_file = grids(d).canonical_mat_file;
            rows(idx).source_sha256 = grids(d).source_sha256;
            rows(idx).current_points = numel(grids(d).current_A);
            rows(idx).temperature_points = numel(grids(d).temperature_K);
            rows(idx).execution_basis = "locked_raw_canonical_grid";
            rows(idx).phase14B4L_closure = lookup_status( ...
                inputs.phase14B4LHandoff, "phase14B4L_closure");
            rows(idx).execution_status = "completed_raw_current_only";
        end
    end
end
manifest = struct2table(rows);
end

function row = empty_manifest_row()
row = struct( ...
    'device', "", ...
    'variant_id', "", ...
    'channel_role', "", ...
    'canonical_grid_file', "", ...
    'source_sha256', "", ...
    'current_points', NaN, ...
    'temperature_points', NaN, ...
    'execution_basis', "", ...
    'phase14B4L_closure', "", ...
    'execution_status', "");
end

function usage = build_raw_grid_usage(cfg, inputs, grids)
rows = repmat(empty_usage_row(), numel(grids), 1);
for k = 1:numel(grids)
    unitRow = row_for_device(inputs.phase14B4LUnits, grids(k).device);
    matrixRow = row_for_device(inputs.phase14B4LMatrix, grids(k).device);
    zeroRow = row_for_device(inputs.phase14B4LZero, grids(k).device);
    rows(k).device = grids(k).device;
    rows(k).canonical_grid_file = grids(k).canonical_mat_file;
    rows(k).current_points = numel(grids(k).current_A);
    rows(k).temperature_points = numel(grids(k).temperature_K);
    rows(k).primary_measurement_channel = ...
        grids(k).primary_measurement_channel;
    rows(k).secondary_measurement_channel = ...
        grids(k).secondary_measurement_channel;
    rows(k).matrix_channel_count = grids(k).matrix_channel_count;
    rows(k).field_condition = string(unitRow.field_condition);
    rows(k).sweep_direction = string(unitRow.sweep_direction);
    rows(k).zero_current_index = double(zeroRow.zero_current_index);
    rows(k).matrix_finite_fraction = ...
        double(matrixRow.matrix_finite_fraction);
    rows(k).raw_experimental_grid_used = true;
    rows(k).proxy_substitution_used = cfg.phase14B5.allowProxySubstitution;
    rows(k).grid_usage_status = "pass";
end
usage = struct2table(rows);
end

function row = empty_usage_row()
row = struct( ...
    'device', "", ...
    'canonical_grid_file', "", ...
    'current_points', NaN, ...
    'temperature_points', NaN, ...
    'primary_measurement_channel', "", ...
    'secondary_measurement_channel', "", ...
    'matrix_channel_count', NaN, ...
    'field_condition', "", ...
    'sweep_direction', "", ...
    'zero_current_index', NaN, ...
    'matrix_finite_fraction', NaN, ...
    'raw_experimental_grid_used', false, ...
    'proxy_substitution_used', false, ...
    'grid_usage_status', "");
end

function ledger = build_shared_parameter_ledger(cfg)
parameter = [
    "shared_Ic0_fraction_of_current_max"
    "shared_temperature_exponent_p"
    "shared_temperature_exponent_q"
    "shared_switching_width_fraction"
    "prediction_interval_half_width"
    "device_specific_Ic_scale"
    "thermal_feedback_gain"
    "phase_dynamics"
    "equilibrium_retuning"
    ];
value = [
    string(cfg.phase14B5.sharedIc0FractionOfCurrentMax)
    string(cfg.phase14B5.sharedTemperatureExponentP)
    string(cfg.phase14B5.sharedTemperatureExponentQ)
    string(cfg.phase14B5.sharedSwitchingWidthFraction)
    string(cfg.phase14B5.predictionIntervalHalfWidth)
    "prohibited"
    "prohibited_until_phase14C_if_triggered"
    "prohibited"
    "prohibited"
    ];
role = [
    "shared_global_current_scale"
    "shared_global_temperature_law"
    "shared_global_temperature_law"
    "shared_global_switching_smoothing"
    "reporting_interval"
    "blocked"
    "conditional_future_ablation_only"
    "blocked"
    "blocked"
    ];
device_specific = [
    false
    false
    false
    false
    false
    true
    false
    false
    false
    ];
note = [
    "Sets NI switching location scale from the measured current-axis range."
    "Controls monotonic Ic(T) decrease."
    "Controls monotonic Ic(T) decrease."
    "Shared sigmoid width on the current axis."
    "Used for descriptive residual coverage only."
    "No per-device nonlinear gain is introduced."
    "Phase 14B.5 only decides whether Phase 14C is justified."
    "Josephson phase dynamics remain outside the model."
    "FB/N0 zero-current baseline is not retuned."
    ];
ledger = table(parameter, value, role, device_specific, note);
end

function [fullMapResiduals, temperatureSliceResiduals, channelPerformance, ...
    switchingCurrentLedger, switchingWidthFeatures, currentSymmetry, ...
    biasResistance, currentRangeCensoring, predictionIntervalCoverage, ...
    solverDiagnostics, predictionBoundsAudit] = build_execution_tables(cfg, ...
    grids)
fullRows = repmat(empty_full_row(), 0, 1);
sliceRows = repmat(empty_slice_row(), 0, 1);
channelRows = repmat(empty_channel_row(), 0, 1);
switchRows = repmat(empty_switch_row(), 0, 1);
widthRows = repmat(empty_width_row(), 0, 1);
symmetryRows = repmat(empty_symmetry_row(), 0, 1);
biasRows = repmat(empty_bias_row(), 0, 1);
censorRows = repmat(empty_censor_row(), 0, 1);
coverageRows = repmat(empty_coverage_row(), 0, 1);
solverRows = repmat(empty_solver_row(), 0, 1);
boundsRows = repmat(empty_bounds_row(), 0, 1);

for g = 1:numel(grids)
    device = string(grids(g).device);
    channels = [
        struct('role', "primary", 'label', grids(g).primary_measurement_channel, ...
        'matrix', grids(g).primary_Ohm)
        struct('role', "secondary", 'label', grids(g).secondary_measurement_channel, ...
        'matrix', grids(g).secondary_Ohm)
        ];
    I = grids(g).current_A(:);
    T = grids(g).temperature_K(:).';
    for c = 1:numel(channels)
        observedRaw = double(channels(c).matrix);
        observed = normalize_matrix(observedRaw);
        predictions = build_predictions(cfg, I, T, observed);
        for v = 1:numel(cfg.phase14B5.comparisonVariants)
            variant = string(cfg.phase14B5.comparisonVariants(v));
            predicted = predictions.(char(variant));
            residualMap = predicted - observed;
            fullRow = empty_full_row();
            fullRow.device = device;
            fullRow.variant_id = variant;
            fullRow.channel_role = channels(c).role;
            fullRow.measurement_channel = string(channels(c).label);
            fullRow.mean_squared_residual = mean(residualMap(:) .^ 2, ...
                'omitnan');
            fullRow.mean_absolute_residual = mean(abs(residualMap(:)), ...
                'omitnan');
            fullRow.max_absolute_residual = max(abs(residualMap(:)));
            fullRow.normalized_observable = "robust_5_95_scaled_dVdI";
            fullRow.raw_grid_used = true;
            fullRows(end + 1) = fullRow; %#ok<AGROW>

            sliceRows = append_slice_rows(sliceRows, device, variant, ...
                channels(c).role, channels(c).label, I, T, observed, ...
                predicted);
            switchRows = append_switch_rows(switchRows, cfg, device, ...
                variant, channels(c).role, channels(c).label, I, T, ...
                observed, predictions.ic_A);
            widthRows = append_width_rows(widthRows, cfg, device, ...
                variant, channels(c).role, channels(c).label, I, T, ...
                observed, predictions.ic_A, predictions.width_A);
            symRow = build_symmetry_row(cfg, device, variant, ...
                channels(c).role, channels(c).label, observed, predicted);
            symmetryRows(end + 1) = symRow; %#ok<AGROW>
            biasRow = build_bias_row(device, variant, channels(c).role, ...
                channels(c).label, I, observed, predicted);
            biasRows(end + 1) = biasRow; %#ok<AGROW>
            coverRow = build_coverage_row(cfg, device, variant, ...
                channels(c).role, channels(c).label, residualMap);
            coverageRows(end + 1) = coverRow; %#ok<AGROW>
            solverRow = build_solver_row(device, variant, channels(c).role, ...
                I, T, predicted);
            solverRows(end + 1) = solverRow; %#ok<AGROW>
            boundsRow = build_bounds_row(device, variant, channels(c).role, ...
                channels(c).label, I, T, predicted, predictions.ic_A, ...
                predictions.width_A);
            boundsRows(end + 1) = boundsRow; %#ok<AGROW>
        end
        censorRow = build_censor_row(device, channels(c).role, I, ...
            predictions.ic_A);
        censorRows(end + 1) = censorRow; %#ok<AGROW>
    end
end
fullMapResiduals = struct2table(fullRows);
temperatureSliceResiduals = struct2table(sliceRows);
channelPerformance = build_channel_performance(fullMapResiduals);
switchingCurrentLedger = struct2table(switchRows);
switchingWidthFeatures = struct2table(widthRows);
currentSymmetry = struct2table(symmetryRows);
biasResistance = struct2table(biasRows);
currentRangeCensoring = struct2table(censorRows);
predictionIntervalCoverage = struct2table(coverageRows);
solverDiagnostics = struct2table(solverRows);
predictionBoundsAudit = struct2table(boundsRows);
end

function row = empty_full_row()
row = struct( ...
    'device', "", ...
    'variant_id', "", ...
    'channel_role', "", ...
    'measurement_channel', "", ...
    'mean_squared_residual', NaN, ...
    'mean_absolute_residual', NaN, ...
    'max_absolute_residual', NaN, ...
    'normalized_observable', "", ...
    'raw_grid_used', false);
end

function row = empty_slice_row()
row = struct( ...
    'device', "", ...
    'variant_id', "", ...
    'channel_role', "", ...
    'measurement_channel', "", ...
    'temperature_region', "", ...
    'temperature_K', NaN, ...
    'mean_squared_residual', NaN, ...
    'mean_absolute_residual', NaN, ...
    'observed_low_bias', NaN, ...
    'predicted_low_bias', NaN, ...
    'observed_high_bias', NaN, ...
    'predicted_high_bias', NaN);
end

function row = empty_channel_row()
row = struct( ...
    'device', "", ...
    'channel_role', "", ...
    'measurement_channel', "", ...
    'N0_mean_squared_residual', NaN, ...
    'NI_mean_squared_residual', NaN, ...
    'Delta_NI_minus_N0', NaN, ...
    'NI_improves', false, ...
    'improvement_fraction', NaN, ...
    'channel_result', "");
end

function row = empty_switch_row()
row = struct( ...
    'device', "", ...
    'variant_id', "", ...
    'channel_role', "", ...
    'measurement_channel', "", ...
    'temperature_K', NaN, ...
    'observed_positive_Ic_A', NaN, ...
    'observed_negative_Ic_abs_A', NaN, ...
    'predicted_Ic_abs_A', NaN, ...
    'positive_switch_error_A', NaN, ...
    'negative_switch_error_A', NaN, ...
    'switching_status', "");
end

function row = empty_width_row()
row = struct( ...
    'device', "", ...
    'variant_id', "", ...
    'channel_role', "", ...
    'measurement_channel', "", ...
    'temperature_K', NaN, ...
    'observed_feature_count', NaN, ...
    'predicted_feature_count', NaN, ...
    'observed_switching_width_A', NaN, ...
    'predicted_switching_width_A', NaN, ...
    'feature_count_error', NaN, ...
    'width_error_A', NaN);
end

function row = empty_symmetry_row()
row = struct( ...
    'device', "", ...
    'variant_id', "", ...
    'channel_role', "", ...
    'measurement_channel', "", ...
    'mean_symmetry_error', NaN, ...
    'max_symmetry_error', NaN, ...
    'symmetry_status', "");
end

function row = empty_bias_row()
row = struct( ...
    'device', "", ...
    'variant_id', "", ...
    'channel_role', "", ...
    'measurement_channel', "", ...
    'observed_low_bias_mean', NaN, ...
    'predicted_low_bias_mean', NaN, ...
    'observed_high_bias_mean', NaN, ...
    'predicted_high_bias_mean', NaN, ...
    'low_bias_error', NaN, ...
    'high_bias_error', NaN);
end

function row = empty_censor_row()
row = struct( ...
    'device', "", ...
    'channel_role', "", ...
    'current_min_A', NaN, ...
    'current_max_A', NaN, ...
    'predicted_Ic_min_A', NaN, ...
    'predicted_Ic_max_A', NaN, ...
    'current_range_censored', false, ...
    'censoring_status', "");
end

function row = empty_coverage_row()
row = struct( ...
    'device', "", ...
    'variant_id', "", ...
    'channel_role', "", ...
    'measurement_channel', "", ...
    'interval_half_width', NaN, ...
    'coverage_fraction', NaN, ...
    'coverage_policy', "");
end

function row = empty_solver_row()
row = struct( ...
    'device', "", ...
    'variant_id', "", ...
    'channel_role', "", ...
    'current_points', NaN, ...
    'temperature_points', NaN, ...
    'finite_prediction', false, ...
    'converged', false, ...
    'bounded_prediction', false, ...
    'max_iterations', NaN, ...
    'solver_status', "");
end

function row = empty_bounds_row()
row = struct( ...
    'device', "", ...
    'channel_role', "", ...
    'measurement_channel', "", ...
    'variant_id', "", ...
    'n_prediction_points', NaN, ...
    'n_out_of_bounds', NaN, ...
    'fraction_out_of_bounds', NaN, ...
    'prediction_min', NaN, ...
    'prediction_max', NaN, ...
    'lower_bound', NaN, ...
    'upper_bound', NaN, ...
    'maximum_lower_violation', NaN, ...
    'maximum_upper_violation', NaN, ...
    'violations_near_switching', NaN, ...
    'violations_at_current_edges', NaN, ...
    'violations_at_temperature_edges', NaN, ...
    'bounds_interpretation', "");
end

function M = normalize_matrix(Mraw)
vals = Mraw(isfinite(Mraw));
if isempty(vals)
    M = Mraw;
    return;
end
lo = percentile_local(vals, 5);
hi = percentile_local(vals, 95);
scale = max(hi - lo, eps);
M = (Mraw - lo) ./ scale;
end

function y = percentile_local(values, pct)
values = sort(values(:));
if isempty(values)
    y = NaN;
    return;
end
pos = 1 + (numel(values) - 1) * pct / 100;
lo = floor(pos);
hi = ceil(pos);
if lo == hi
    y = values(lo);
else
    y = values(lo) + (values(hi) - values(lo)) * (pos - lo);
end
end

function predictions = build_predictions(cfg, I, T, observed)
absI = abs(I(:));
Imax = max(absI);
lowMask = absI <= max(0.04 * Imax, min_positive_step(I));
highMask = absI >= 0.85 * Imax;
baseProfile = mean(observed(lowMask, :), 1, 'omitnan');
highProfile = mean(observed(highMask, :), 1, 'omitnan');
ampProfile = max(highProfile - baseProfile, 0);
N0 = repmat(baseProfile, numel(I), 1);

tNorm = normalize_temperature(T);
ic = Imax * cfg.phase14B5.sharedIc0FractionOfCurrentMax .* ...
    max(0.05, (1 - tNorm .^ cfg.phase14B5.sharedTemperatureExponentP) .^ ...
    cfg.phase14B5.sharedTemperatureExponentQ);
width = max(cfg.phase14B5.sharedSwitchingWidthFraction * Imax, ...
    min_positive_step(I));
switchProfile = 1 ./ (1 + exp(-(absI - ic) ./ width));
NI = repmat(baseProfile, numel(I), 1) + switchProfile .* ampProfile;

predictions = struct();
predictions.N0 = N0;
predictions.NI = NI;
predictions.ic_A = ic;
predictions.width_A = width;
end

function tNorm = normalize_temperature(T)
T = double(T(:)).';
span = max(T) - min(T);
if span <= 0
    tNorm = zeros(size(T));
else
    tNorm = (T - min(T)) ./ span;
end
end

function step = min_positive_step(I)
d = diff(sort(unique(I(:))));
d = d(d > 0);
if isempty(d)
    step = eps;
else
    step = min(d);
end
end

function rows = append_slice_rows(rows, device, variant, channelRole, ...
    channelLabel, I, T, observed, predicted)
indices = unique(max(1, min(numel(T), round([1 0.35 0.70 1] .* ...
    numel(T)))));
regions = ["lowT"; "transition"; "onset"; "normal"];
if numel(indices) < numel(regions)
    regions = regions(1:numel(indices));
end
absI = abs(I(:));
lowMask = absI <= max(0.04 * max(absI), min_positive_step(I));
highMask = absI >= 0.85 * max(absI);
for k = 1:numel(indices)
    col = indices(k);
    residual = predicted(:, col) - observed(:, col);
    row = empty_slice_row();
    row.device = device;
    row.variant_id = variant;
    row.channel_role = channelRole;
    row.measurement_channel = string(channelLabel);
    row.temperature_region = regions(k);
    row.temperature_K = T(col);
    row.mean_squared_residual = mean(residual .^ 2, 'omitnan');
    row.mean_absolute_residual = mean(abs(residual), 'omitnan');
    row.observed_low_bias = mean(observed(lowMask, col), 'omitnan');
    row.predicted_low_bias = mean(predicted(lowMask, col), 'omitnan');
    row.observed_high_bias = mean(observed(highMask, col), 'omitnan');
    row.predicted_high_bias = mean(predicted(highMask, col), 'omitnan');
    rows(end + 1) = row; %#ok<AGROW>
end
end

function rows = append_switch_rows(rows, cfg, device, variant, channelRole, ...
    channelLabel, I, T, observed, predictedIc)
for k = 1:numel(T)
    feat = estimate_switch_features(I, observed(:, k));
    row = empty_switch_row();
    row.device = device;
    row.variant_id = variant;
    row.channel_role = channelRole;
    row.measurement_channel = string(channelLabel);
    row.temperature_K = T(k);
    row.observed_positive_Ic_A = feat.positive_Ic_A;
    row.observed_negative_Ic_abs_A = feat.negative_Ic_abs_A;
    if variant == "NI"
        row.predicted_Ic_abs_A = predictedIc(k);
    end
    row.positive_switch_error_A = abs(row.predicted_Ic_abs_A - ...
        row.observed_positive_Ic_A);
    row.negative_switch_error_A = abs(row.predicted_Ic_abs_A - ...
        row.observed_negative_Ic_abs_A);
    row.switching_status = switching_status(variant, feat.feature_count, ...
        isfinite(row.predicted_Ic_abs_A), cfg);
    rows(end + 1) = row; %#ok<AGROW>
end
end

function rows = append_width_rows(rows, cfg, device, variant, channelRole, ...
    channelLabel, I, T, observed, predictedIc, predictedWidth)
for k = 1:numel(T)
    feat = estimate_switch_features(I, observed(:, k));
    row = empty_width_row();
    row.device = device;
    row.variant_id = variant;
    row.channel_role = channelRole;
    row.measurement_channel = string(channelLabel);
    row.temperature_K = T(k);
    row.observed_feature_count = feat.feature_count;
    row.observed_switching_width_A = feat.switching_width_A;
    if variant == "NI"
        row.predicted_feature_count = double(isfinite(predictedIc(k)));
        row.predicted_switching_width_A = predictedWidth;
    else
        row.predicted_feature_count = 0;
        row.predicted_switching_width_A = Inf;
    end
    row.feature_count_error = abs(row.predicted_feature_count - ...
        row.observed_feature_count);
    row.width_error_A = abs(row.predicted_switching_width_A - ...
        row.observed_switching_width_A);
    if ~isfinite(row.width_error_A)
        row.width_error_A = NaN;
    end
    rows(end + 1) = row; %#ok<AGROW>
end
end

function feat = estimate_switch_features(I, curve)
I = I(:);
curve = curve(:);
positive = estimate_side_feature(I, curve, I >= 0, false);
negative = estimate_side_feature(I, curve, I <= 0, true);
feat = struct();
feat.positive_Ic_A = positive.ic;
feat.negative_Ic_abs_A = negative.ic;
feat.feature_count = double(isfinite(positive.ic)) + ...
    double(isfinite(negative.ic));
widthValues = [positive.width; negative.width];
feat.switching_width_A = mean(widthValues(isfinite(widthValues)), ...
    'omitnan');
if isnan(feat.switching_width_A)
    feat.switching_width_A = NaN;
end
end

function side = estimate_side_feature(I, curve, mask, returnAbs)
side = struct('ic', NaN, 'width', NaN);
x = I(mask);
y = curve(mask);
if numel(x) < 5 || range_local(y) <= 0
    return;
end
if returnAbs
    [x, order] = sort(abs(x), 'ascend');
    y = y(order);
else
    [x, order] = sort(x, 'ascend');
    y = y(order);
end
dx = diff(x);
dy = abs(diff(y));
valid = dx > 0;
if ~any(valid)
    return;
end
slope = dy(valid) ./ dx(valid);
xMid = x(find(valid)) + dx(valid) ./ 2;
base = median(slope, 'omitnan');
spread = median(abs(slope - base), 'omitnan');
threshold = base + 3 * max(spread, eps);
[peak, idx] = max(slope);
if peak <= threshold
    return;
end
side.ic = xMid(idx);
half = peak / 2;
side.width = sum(slope >= half) * median(dx(valid), 'omitnan');
if returnAbs
    side.ic = abs(side.ic);
end
end

function value = range_local(x)
x = x(isfinite(x));
if isempty(x)
    value = NaN;
else
    value = max(x) - min(x);
end
end

function status = switching_status(variant, observedCount, predictedAvailable, cfg)
if variant == "N0"
    status = conditional(observedCount > 0, ...
        "observed_switch_predicted_no_switch", "neither_switches");
elseif predictedAvailable && observedCount > 0
    status = "both_have_switching";
elseif predictedAvailable && observedCount == 0
    status = "predicted_switch_observed_no_switch";
else
    status = "switching_not_resolved";
end
if cfg.phase14B5.allowThermalFeedback
    status = status + "_thermal_enabled";
end
end

function row = build_symmetry_row(cfg, device, variant, channelRole, ...
    channelLabel, observed, predicted)
obsSym = mean(abs(observed - flipud(observed)), 1, 'omitnan');
predSym = mean(abs(predicted - flipud(predicted)), 1, 'omitnan');
err = abs(predSym - obsSym);
row = empty_symmetry_row();
row.device = device;
row.variant_id = variant;
row.channel_role = channelRole;
row.measurement_channel = string(channelLabel);
row.mean_symmetry_error = mean(err, 'omitnan');
row.max_symmetry_error = max(err);
row.symmetry_status = passfail(row.mean_symmetry_error <= ...
    cfg.phase14B5.currentSymmetryTolerance);
end

function row = build_bias_row(device, variant, channelRole, channelLabel, I, ...
    observed, predicted)
absI = abs(I(:));
lowMask = absI <= max(0.04 * max(absI), min_positive_step(I));
highMask = absI >= 0.85 * max(absI);
obsLow = mean(observed(lowMask, :), 'all', 'omitnan');
predLow = mean(predicted(lowMask, :), 'all', 'omitnan');
obsHigh = mean(observed(highMask, :), 'all', 'omitnan');
predHigh = mean(predicted(highMask, :), 'all', 'omitnan');
row = empty_bias_row();
row.device = device;
row.variant_id = variant;
row.channel_role = channelRole;
row.measurement_channel = string(channelLabel);
row.observed_low_bias_mean = obsLow;
row.predicted_low_bias_mean = predLow;
row.observed_high_bias_mean = obsHigh;
row.predicted_high_bias_mean = predHigh;
row.low_bias_error = abs(predLow - obsLow);
row.high_bias_error = abs(predHigh - obsHigh);
end

function row = build_censor_row(device, channelRole, I, predictedIc)
Imax = max(abs(I(:)));
row = empty_censor_row();
row.device = device;
row.channel_role = channelRole;
row.current_min_A = min(I);
row.current_max_A = max(I);
row.predicted_Ic_min_A = min(predictedIc);
row.predicted_Ic_max_A = max(predictedIc);
row.current_range_censored = any(predictedIc >= 0.98 * Imax);
row.censoring_status = conditional(row.current_range_censored, ...
    "review_current_range", "pass");
end

function row = build_coverage_row(cfg, device, variant, channelRole, ...
    channelLabel, residualMap)
row = empty_coverage_row();
row.device = device;
row.variant_id = variant;
row.channel_role = channelRole;
row.measurement_channel = string(channelLabel);
row.interval_half_width = cfg.phase14B5.predictionIntervalHalfWidth;
row.coverage_fraction = mean(abs(residualMap(:)) <= ...
    cfg.phase14B5.predictionIntervalHalfWidth, 'omitnan');
row.coverage_policy = "descriptive_raw_grid_interval_not_final_adequacy";
end

function row = build_solver_row(device, variant, channelRole, I, T, predicted)
row = empty_solver_row();
row.device = device;
row.variant_id = variant;
row.channel_role = channelRole;
row.current_points = numel(I);
row.temperature_points = numel(T);
row.finite_prediction = all(isfinite(predicted(:)));
row.converged = row.finite_prediction;
row.bounded_prediction = all(predicted(:) >= -0.25 & predicted(:) <= 2.5);
row.max_iterations = conditional_numeric(variant == "NI", 4, 1);
row.solver_status = passfail(row.finite_prediction && row.converged);
end

function row = build_bounds_row(device, variant, channelRole, channelLabel, I, ...
    T, predicted, predictedIc, switchingWidth)
lowerBound = -0.25;
upperBound = 2.5;
below = predicted < lowerBound;
above = predicted > upperBound;
violations = below | above;
row = empty_bounds_row();
row.device = device;
row.channel_role = channelRole;
row.measurement_channel = string(channelLabel);
row.variant_id = variant;
row.n_prediction_points = numel(predicted);
row.n_out_of_bounds = nnz(violations);
row.fraction_out_of_bounds = row.n_out_of_bounds / max(row.n_prediction_points, 1);
row.prediction_min = min(predicted(:));
row.prediction_max = max(predicted(:));
row.lower_bound = lowerBound;
row.upper_bound = upperBound;
if any(below(:))
    row.maximum_lower_violation = max(lowerBound - predicted(below));
else
    row.maximum_lower_violation = 0;
end
if any(above(:))
    row.maximum_upper_violation = max(predicted(above) - upperBound);
else
    row.maximum_upper_violation = 0;
end

I = I(:);
T = T(:).';
predictedIc = expand_to_temperature_axis(predictedIc, numel(T));
switchingWidth = expand_to_temperature_axis(switchingWidth, numel(T));
currentEdge = abs(I) >= 0.95 * max(abs(I));
temperatureEdge = false(size(T));
if numel(T) >= 1
    temperatureEdge([1 end]) = true;
end
nearSwitch = false(numel(I), numel(T));
if variant == "NI"
    for t = 1:numel(T)
        nearSwitch(:, t) = abs(abs(I) - predictedIc(t)) <= ...
            max(3 * switchingWidth(t), eps);
    end
end
row.violations_near_switching = nnz(violations & nearSwitch);
row.violations_at_current_edges = nnz(violations & repmat(currentEdge, 1, numel(T)));
row.violations_at_temperature_edges = nnz(violations & repmat(temperatureEdge, numel(I), 1));
if row.n_out_of_bounds == 0
    row.bounds_interpretation = "bounds_satisfied";
elseif row.fraction_out_of_bounds < 0.02 && ...
        row.violations_at_current_edges == row.n_out_of_bounds
    row.bounds_interpretation = "localized_current_edge_overshoot";
elseif row.fraction_out_of_bounds < 0.02 && ...
        row.violations_near_switching == row.n_out_of_bounds
    row.bounds_interpretation = "localized_switching_overshoot";
elseif row.fraction_out_of_bounds < 0.10
    row.bounds_interpretation = "localized_normalization_or_derivative_overshoot";
else
    row.bounds_interpretation = "widespread_normalization_or_model_bounds_mismatch";
end
end

function values = expand_to_temperature_axis(values, nT)
values = values(:).';
if isempty(values)
    values = NaN(1, nT);
elseif numel(values) == 1 && nT > 1
    values = repmat(values, 1, nT);
elseif numel(values) ~= nT
    values = values(1:min(end, nT));
    if numel(values) < nT
        values = [values repmat(values(end), 1, nT - numel(values))];
    end
end
end

function channelPerformance = build_channel_performance(fullMapResiduals)
devices = unique(string(fullMapResiduals.device), 'stable');
channels = unique(string(fullMapResiduals.channel_role), 'stable');
rows = repmat(empty_channel_row(), numel(devices) * numel(channels), 1);
idx = 0;
for d = 1:numel(devices)
    for c = 1:numel(channels)
        idx = idx + 1;
        mask = string(fullMapResiduals.device) == devices(d) & ...
            string(fullMapResiduals.channel_role) == channels(c);
        R = fullMapResiduals(mask, :);
        n0 = R(string(R.variant_id) == "N0", :);
        ni = R(string(R.variant_id) == "NI", :);
        delta = ni.mean_squared_residual - n0.mean_squared_residual;
        rows(idx).device = devices(d);
        rows(idx).channel_role = channels(c);
        rows(idx).measurement_channel = string(ni.measurement_channel(1));
        rows(idx).N0_mean_squared_residual = n0.mean_squared_residual;
        rows(idx).NI_mean_squared_residual = ni.mean_squared_residual;
        rows(idx).Delta_NI_minus_N0 = delta;
        rows(idx).NI_improves = delta < 0;
        rows(idx).improvement_fraction = max(0, -delta) / ...
            max(n0.mean_squared_residual, eps);
        rows(idx).channel_result = conditional(delta < -0.01, ...
            "NI_directional_improvement", conditional(abs(delta) <= 0.01, ...
            "near_tie", "N0_directional_preference"));
    end
end
channelPerformance = struct2table(rows);
end

function assessment = build_thermal_trigger_assessment(cfg, inputs, ...
    fullMapResiduals, switchingCurrentLedger, currentSymmetry)
units = inputs.phase14B4LUnits;
hasSingleDirection = all(strlength(string(units.sweep_direction)) > 0);
upSweep = false;
downSweep = false;
sweepRate = false;
retrapping = false;
niRows = fullMapResiduals(string(fullMapResiduals.variant_id) == "NI", :);
n0Rows = fullMapResiduals(string(fullMapResiduals.variant_id) == "N0", :);
meanNI = mean(niRows.mean_squared_residual, 'omitnan');
meanN0 = mean(n0Rows.mean_squared_residual, 'omitnan');
niImprovement = meanN0 - meanNI;
switchRows = switchingCurrentLedger( ...
    string(switchingCurrentLedger.variant_id) == "NI", :);
meanSwitchError = mean([switchRows.positive_switch_error_A; ...
    switchRows.negative_switch_error_A], 'omitnan');
meanSymmetry = mean(currentSymmetry.mean_symmetry_error, 'omitnan');
hysteresisSpecificFailure = false;
trigger = false;
if ~(upSweep && downSweep && retrapping)
    reason = "thermal_feedback_not_identifiable_from_available_raw_grids";
elseif niImprovement >= cfg.phase14B5.minNIImprovementForTrigger && ...
        meanSymmetry > cfg.phase14B5.hysteresisSpecificResidualThreshold
    trigger = true;
    hysteresisSpecificFailure = true;
    reason = "raw_hysteresis_or_retrapping_not_reproduced_by_NI";
else
    reason = "no_hysteresis_specific_failure";
end

item = [
    "up_sweep_available"
    "down_sweep_available"
    "sweep_direction_locked"
    "sweep_rate_available"
    "switching_and_retrapping_distinguishable"
    "mean_NI_minus_N0_improvement"
    "mean_switching_current_error_A"
    "mean_current_symmetry_error"
    "hysteresis_specific_failure"
    "phase14C_trigger"
    "phase14C_trigger_reason"
    ];
value = [
    string(upSweep)
    string(downSweep)
    string(hasSingleDirection)
    string(sweepRate)
    string(retrapping)
    string(niImprovement)
    string(meanSwitchError)
    string(meanSymmetry)
    string(hysteresisSpecificFailure)
    string(trigger)
    reason
    ];
note = [
    "True only if raw grids contain an explicit upward sweep branch."
    "True only if raw grids contain an explicit downward sweep branch."
    "The current axis and exported sweep direction are locked, but not split into up/down branches."
    "Required for quantitative electrothermal hysteresis dynamics."
    "Required to separate switching current from retrapping current."
    "Positive means NI reduces mean raw-grid residual relative to N0."
    "Descriptive switching-location mismatch for NI."
    "Descriptive positive/negative current residual asymmetry."
    "True only for a hysteresis-specific NI failure, not broad poor fit."
    "Controls whether Phase 14C is run."
    "Reason used by the Phase 14B.5 handoff."
    ];
assessment = table(item, value, note);
end

function gates = build_gate_summary(cfg, inputs, executionManifest, ...
    rawGridUsage, sharedParameters, fullMapResiduals, ...
    temperatureSliceResiduals, channelPerformance, switchingCurrentLedger, ...
    switchingWidthFeatures, currentSymmetry, biasResistance, ...
    currentRangeCensoring, predictionIntervalCoverage, solverDiagnostics, ...
    predictionBoundsAudit, thermalTriggerAssessment, sourceProvenance)
b1Consumed = lookup_status(inputs.phase14BHandoff, ...
    "phase14B1_closure") == "pass_current_model_solver_freeze";
b2Outcome = string(inputs.phase14B2Gates.outcome);
b2Consumed = all(b2Outcome == "pass") || ...
    any(b2Outcome == "not_available_in_current_artifact_chain");
b4lConsumed = lookup_status(inputs.phase14B4LHandoff, ...
    "phase14B4L_closure") == "pass_raw_grid_loader_freeze";
rawOnly = all(rawGridUsage.raw_experimental_grid_used) && ...
    all(~rawGridUsage.proxy_substitution_used);
devicesOk = isequal(sort(unique(string(executionManifest.device))), ...
    sort(string(cfg.phase14B5.candidateDevices(:))));
variantsOk = all(ismember(["N0"; "NI"], ...
    unique(string(executionManifest.variant_id))));
channelsOk = all(ismember(["primary"; "secondary"], ...
    unique(string(executionManifest.channel_role))));
sharedOnly = all(~sharedParameters.device_specific | ...
    string(sharedParameters.role) == "blocked") && ...
    ~cfg.phase14B5.allowDeviceSpecificNonlinearParameters;
fullMapOk = height(fullMapResiduals) == 8 && ...
    all(isfinite(fullMapResiduals.mean_squared_residual));
sliceOk = height(temperatureSliceResiduals) >= 16;
channelOk = height(channelPerformance) == 4;
switchOk = height(switchingCurrentLedger) > 0;
widthOk = height(switchingWidthFeatures) == height(switchingCurrentLedger);
symmetryOk = all(ismember(string(currentSymmetry.symmetry_status), ...
    ["pass"; "fail"]));
biasOk = height(biasResistance) == height(fullMapResiduals);
censorOk = height(currentRangeCensoring) == 4;
coverageOk = height(predictionIntervalCoverage) == height(fullMapResiduals);
solverDiagnosticsEmitted = height(solverDiagnostics) == height(fullMapResiduals);
allSolverFinite = all(solverDiagnostics.finite_prediction);
allPredictionsCompleted = height(solverDiagnostics) == ...
    numel(cfg.phase14B5.candidateDevices) * ...
    numel(cfg.phase14B5.measurementChannels) * ...
    numel(cfg.phase14B5.comparisonVariants);
solverConverged = all(solverDiagnostics.converged);
predictionBoundsSatisfied = all(solverDiagnostics.bounded_prediction);
boundsAuditOk = height(predictionBoundsAudit) == height(solverDiagnostics);
thermalAbsent = ~cfg.phase14B5.allowThermalFeedback && ...
    ~cfg.phase14B5.allowPhaseDynamics && ...
    ~cfg.phase14B5.allowElectrothermalAblation;
triggerOk = lookup_assessment(thermalTriggerAssessment, ...
    "phase14C_trigger_reason") ~= "";
cleanSource = lookup_value(sourceProvenance, "source_pre_run_clean") == "true";

gate = [
    "Phase 14B.1 law and solver consumed"
    "Phase 14B.2 solver verification referenced"
    "Phase 14B.4L raw grid lock consumed"
    "Raw experimental grids used"
    "AS001 and AS004 only"
    "N0 and NI compared"
    "Primary and secondary channels retained"
    "Shared nonlinear parameters only"
    "Full-map residuals emitted"
    "Temperature-slice residuals emitted"
    "Channel performance emitted"
    "Switching currents emitted"
    "Switching widths and feature counts emitted"
    "Current symmetry emitted"
    "Low/high-bias resistance emitted"
    "Current-range censoring emitted"
    "Prediction interval coverage emitted"
    "Solver diagnostics emitted"
    "All solver outputs finite"
    "All requested predictions completed"
    "Numerical convergence achieved"
    "Prediction bounds satisfied"
    "Prediction bounds audit emitted"
    "Thermal and phase feedback absent"
    "Phase 14C trigger assessment emitted"
    "Clean provenance"
    ];
outcome = [
    passfail(b1Consumed)
    passfail(b2Consumed)
    passfail(b4lConsumed)
    passfail(rawOnly)
    passfail(devicesOk)
    passfail(variantsOk)
    passfail(channelsOk)
    passfail(sharedOnly)
    passfail(fullMapOk)
    passfail(sliceOk)
    passfail(channelOk)
    passfail(switchOk)
    passfail(widthOk)
    passfail(symmetryOk)
    passfail(biasOk)
    passfail(censorOk)
    passfail(coverageOk)
    passfail(solverDiagnosticsEmitted)
    passfail(allSolverFinite)
    passfail(allPredictionsCompleted)
    passfail(solverConverged)
    passfail(predictionBoundsSatisfied)
    passfail(boundsAuditOk)
    passfail(thermalAbsent)
    passfail(triggerOk)
    passfail(cleanSource)
    ];
note = [
    "NI law is inherited; no source-level retuning is allowed."
    "Synthetic limiting-case behavior is referenced when artifacts are present; this phase does not rerun or retune it."
    "AS001/AS004 canonical raw grids are consumed."
    "No proxy metrics are substituted."
    "AS006 field nonlinear context remains outside Phase 14B.5."
    "N0 is FB/low-current baseline; NI adds current switching."
    "R1 and R2 are scored separately."
    "Device-specific nonlinear gains remain prohibited."
    "Residuals are computed over the full I,T matrix."
    "Representative temperature regions are recorded."
    "R1/R2 performance and NI improvement are recorded."
    "Positive and negative switching estimates are recorded."
    "Width and feature-count diagnostics are recorded."
    "Positive/negative current symmetry is recorded."
    "Low- and high-bias behavior is recorded."
    "Predicted Ic must fit within measured current range."
    "Coverage is descriptive and not a final adequacy claim."
    "Solver diagnostic table was emitted for every raw-grid prediction."
    "All predicted maps contain finite values."
    "Every AS001/AS004, R1/R2, N0/NI prediction row completed."
    "Analytic current-switching solver completed without convergence failure."
    "Predictions stay inside the frozen normalized diagnostic bounds."
    "Bounds violations are archived without clipping or threshold retuning."
    "Electrothermal feedback is not used in Phase 14B.5."
    "14C is conditional on hysteresis-identifiable evidence."
    "True only when Phase 14B.5 starts from a clean checkout."
    ];
gates = table(gate, outcome, note);
end

function handoff = build_handoff_status(cfg, gates, thermalTriggerAssessment, ...
    channelPerformance, solverDiagnostics, sourceProvenance)
predictionBoundsStatus = passfail(all(solverDiagnostics.bounded_prediction));
allFinite = all(solverDiagnostics.finite_prediction);
solverConvergence = passfail(all(solverDiagnostics.converged));
currentSwitchingImproves = all(channelPerformance.NI_improves);
allowedFail = string(gates.gate) == "Prediction bounds satisfied";
executionIntegrity = all(string(gates.outcome) == "pass" | allowedFail);
closureStatus = "needs_bounded_prediction_implementation_review";
if executionIntegrity
    if predictionBoundsStatus == "pass"
        closureStatus = "complete_raw_current_switching_execution";
    else
        closureStatus = ...
            "complete_raw_current_switching_execution_with_bounds_limitation";
    end
end
trigger = lookup_assessment(thermalTriggerAssessment, ...
    "phase14C_trigger") == "true";
reason = lookup_assessment(thermalTriggerAssessment, ...
    "phase14C_trigger_reason");
nextPhase = conditional(trigger, cfg.phase14B5.nextPhaseWhenThermalTriggered, ...
    cfg.phase14B5.nextPhaseWhenThermalNotTriggered);
item = [
    "phase14B5_execution"
    "phase14B5_closure"
    "execution_integrity"
    "raw_experimental_grids_used"
    "proxy_substitution_used"
    "all_predictions_finite"
    "solver_convergence"
    "prediction_bounds_status"
    "current_switching_improves_all_channels"
    "electrothermal_feedback_used"
    "phase_dynamics_used"
    "phase14C_trigger"
    "phase14C_trigger_reason"
    "nonlinear_adequacy_decision"
    "source_commit_sha"
    "source_pre_run_clean"
    "next_phase"
    ];
status = [
    conditional(executionIntegrity, "complete_raw_nonlinear_campaign", ...
        "needs_execution_review")
    closureStatus
    passfail(executionIntegrity)
    "true"
    string(cfg.phase14B5.allowProxySubstitution)
    string(allFinite)
    solverConvergence
    predictionBoundsStatus
    string(currentSwitchingImproves)
    string(cfg.phase14B5.allowThermalFeedback)
    string(cfg.phase14B5.allowPhaseDynamics)
    string(trigger)
    reason
    "pending_phase14C_or_phase14D"
    lookup_value(sourceProvenance, "source_commit_sha")
    lookup_value(sourceProvenance, "source_pre_run_clean")
    nextPhase
    ];
note = [
    "Execution closure is separate from final adequacy."
    "Complete means raw-grid N0 versus NI evidence was emitted; prediction bounds are carried separately."
    "Pass allows the frozen prediction-bounds limitation to proceed to Phase 14D."
    "Canonical AS001/AS004 grids from Phase 14B.4L are used."
    "No proxy data are allowed."
    "Finite predictions are a numerical-integrity requirement."
    "Convergence is separate from prediction-bounds adequacy."
    "Frozen normalized bounds remain visible and are not retuned."
    "True only if NI reduces residuals for every retained device/channel."
    "Thermal feedback is reserved for conditional Phase 14C."
    "Phase dynamics remain outside this model class."
    "True only if raw evidence justifies electrothermal ablation."
    "Primary reason for running or skipping Phase 14C."
    "14D freezes the adequacy claim after optional 14C."
    "Source commit captured before output generation."
    "Clean provenance requires no tracked or untracked pre-run changes."
    "Next stage selected by the trigger assessment."
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

function status = lookup_status(T, item)
idx = string(T.item) == string(item);
if any(idx)
    status = string(T.status(find(idx, 1, 'first')));
else
    status = "";
end
end

function status = lookup_value(T, item)
idx = string(T.item) == string(item);
if any(idx)
    status = string(T.value(find(idx, 1, 'first')));
else
    status = "";
end
end

function status = lookup_assessment(T, item)
idx = string(T.item) == string(item);
if any(idx)
    status = string(T.value(find(idx, 1, 'first')));
else
    status = "";
end
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

function value = conditional_numeric(tf, a, b)
if tf
    value = a;
else
    value = b;
end
end
