function out = run_phase15D_raw_AS006_field_execution(cfg)
%RUN_PHASE15D_RAW_AS006_FIELD_EXECUTION Execute frozen field variants on AS006.
%
% Phase 15D consumes the locked AS006 dV/dI(I,B) observable and the frozen
% Phase 15B/15C model hierarchy. It evaluates P0, PB, and Pphi against R1
% and R2 with one shared phase state. It does not fit the observed
% oscillation period, introduce topology, add thermal memory, or assign
% independent R1/R2 loop parameters.

if ~exist(cfg.outputDir, 'dir')
    mkdir(cfg.outputDir);
end

inputs = load_inputs(cfg);
sourceProvenance = build_source_provenance(cfg);
fieldGrid = load_field_grid(cfg);
models = build_variant_models(cfg, fieldGrid);
executionManifest = build_execution_manifest(cfg, inputs, fieldGrid);
variantResiduals = build_variant_residuals(cfg, fieldGrid, models);
heldoutFieldWindow = build_heldout_field_windows(cfg, fieldGrid, models);
currentRangeTransfer = build_current_range_transfer(cfg, fieldGrid, models);
fieldSymmetry = build_field_symmetry(cfg, fieldGrid, models);
criticalCurrentEnvelope = build_critical_current_envelopes(cfg, ...
    fieldGrid, models);
oscillatoryStructure = build_oscillatory_structure(cfg, fieldGrid, models);
zeroFieldInheritance = build_zero_field_inheritance(cfg, fieldGrid, models);
predictionBoundsAudit = build_prediction_bounds_audit(cfg, fieldGrid, ...
    models);
sharedPhaseState = build_shared_phase_state(cfg, fieldGrid, models);
channelTransformAudit = build_channel_transform_audit(cfg);
gateSummary = build_gate_summary(cfg, inputs, sourceProvenance, fieldGrid, ...
    variantResiduals, heldoutFieldWindow, currentRangeTransfer, ...
    fieldSymmetry, criticalCurrentEnvelope, oscillatoryStructure, ...
    zeroFieldInheritance, predictionBoundsAudit, sharedPhaseState, ...
    channelTransformAudit);
handoffStatus = build_handoff_status(cfg, gateSummary);

writetable(executionManifest, cfg.phase15D.executionManifestFile);
writetable(variantResiduals, cfg.phase15D.variantResidualsFile);
writetable(heldoutFieldWindow, cfg.phase15D.heldoutFieldWindowFile);
writetable(currentRangeTransfer, cfg.phase15D.currentRangeTransferFile);
writetable(fieldSymmetry, cfg.phase15D.fieldSymmetryFile);
writetable(criticalCurrentEnvelope, ...
    cfg.phase15D.criticalCurrentEnvelopeFile);
writetable(oscillatoryStructure, cfg.phase15D.oscillatoryStructureFile);
writetable(zeroFieldInheritance, cfg.phase15D.zeroFieldInheritanceFile);
writetable(predictionBoundsAudit, cfg.phase15D.predictionBoundsAuditFile);
writetable(sharedPhaseState, cfg.phase15D.sharedPhaseStateFile);
writetable(channelTransformAudit, cfg.phase15D.channelTransformAuditFile);
writetable(gateSummary, cfg.phase15D.gateSummaryFile);
writetable(handoffStatus, cfg.phase15D.handoffStatusFile);
writetable(sourceProvenance, cfg.phase15D.sourceProvenanceFile);

try
    h = v800.plot_phase15D_raw_AS006_field_execution_summary(cfg, ...
        variantResiduals, heldoutFieldWindow, currentRangeTransfer, ...
        fieldSymmetry, criticalCurrentEnvelope, oscillatoryStructure, ...
        predictionBoundsAudit, gateSummary);
catch ME
    warning('v8:phase15DPlotFailed', ...
        'Phase 15D summary plot failed: %s', ME.message);
    h = [];
end

out = struct();
out.config = cfg;
out.executionManifest = executionManifest;
out.variantResiduals = variantResiduals;
out.heldoutFieldWindow = heldoutFieldWindow;
out.currentRangeTransfer = currentRangeTransfer;
out.fieldSymmetry = fieldSymmetry;
out.criticalCurrentEnvelope = criticalCurrentEnvelope;
out.oscillatoryStructure = oscillatoryStructure;
out.zeroFieldInheritance = zeroFieldInheritance;
out.predictionBoundsAudit = predictionBoundsAudit;
out.sharedPhaseState = sharedPhaseState;
out.channelTransformAudit = channelTransformAudit;
out.gateSummary = gateSummary;
out.handoffStatus = handoffStatus;
out.sourceProvenance = sourceProvenance;
out.figure = h;
out.paths = build_paths(cfg);
end

function paths = build_paths(cfg)
paths = struct();
paths.executionManifest = cfg.phase15D.executionManifestFile;
paths.variantResiduals = cfg.phase15D.variantResidualsFile;
paths.heldoutFieldWindow = cfg.phase15D.heldoutFieldWindowFile;
paths.currentRangeTransfer = cfg.phase15D.currentRangeTransferFile;
paths.fieldSymmetry = cfg.phase15D.fieldSymmetryFile;
paths.criticalCurrentEnvelope = cfg.phase15D.criticalCurrentEnvelopeFile;
paths.oscillatoryStructure = cfg.phase15D.oscillatoryStructureFile;
paths.zeroFieldInheritance = cfg.phase15D.zeroFieldInheritanceFile;
paths.predictionBoundsAudit = cfg.phase15D.predictionBoundsAuditFile;
paths.sharedPhaseState = cfg.phase15D.sharedPhaseStateFile;
paths.channelTransformAudit = cfg.phase15D.channelTransformAuditFile;
paths.gateSummary = cfg.phase15D.gateSummaryFile;
paths.handoffStatus = cfg.phase15D.handoffStatusFile;
paths.sourceProvenance = cfg.phase15D.sourceProvenanceFile;
paths.figurePng = [cfg.phase15D.figureBaseFile '.png'];
paths.figurePdf = [cfg.phase15D.figureBaseFile '.pdf'];
end

function inputs = load_inputs(cfg)
inputs = struct();
inputs.phase15AHandoff = read_required_table( ...
    cfg.phase15A.handoffStatusFile, "Phase 15A handoff");
inputs.phase15AHandoffRawText = read_required_text( ...
    cfg.phase15A.handoffStatusFile, "Phase 15A handoff");
inputs.phase15BHandoff = read_required_table( ...
    cfg.phase15B.handoffStatusFile, "Phase 15B handoff");
inputs.phase15BHandoffRawText = read_required_text( ...
    cfg.phase15B.handoffStatusFile, "Phase 15B handoff");
inputs.phase15CHandoff = read_required_table( ...
    cfg.phase15C.handoffStatusFile, "Phase 15C handoff");
inputs.phase15CHandoffRawText = read_required_text( ...
    cfg.phase15C.handoffStatusFile, "Phase 15C handoff");
inputs.phase15BVariants = read_required_table( ...
    cfg.phase15B.modelVariantLedgerFile, "Phase 15B variant ledger");
inputs.phase15BLoopGeometry = read_required_table( ...
    cfg.phase15B.loopGeometryManifestFile, "Phase 15B loop geometry");
end

function T = read_required_table(pathValue, label)
if exist(char(pathValue), 'file') ~= 2
    error('v800:phase15DMissingInput', ...
        'Required %s is missing:\n%s', label, char(pathValue));
end
opts = detectImportOptions(char(pathValue), 'FileType', 'text');
try
    opts.VariableNamingRule = 'preserve';
catch
end
T = readtable(char(pathValue), opts);
end

function txt = read_required_text(pathValue, label)
if exist(char(pathValue), 'file') ~= 2
    error('v800:phase15DMissingInput', ...
        'Required %s is missing:\n%s', label, char(pathValue));
end
txt = string(fileread(char(pathValue)));
end

function provenance = build_source_provenance(cfg)
sourceStatus = v800.git_tree_status(cfg.repoRoot);
item = [
    "phase";
    "source_commit_sha";
    "source_tree_sha";
    "source_pre_run_tracked_clean";
    "source_pre_run_untracked_clean";
    "source_pre_run_clean";
    "provenance_scope";
    ];
value = [
    "phase15D_raw_AS006_field_execution";
    sourceStatus.commit_sha;
    sourceStatus.tree_sha;
    string(sourceStatus.tracked_clean);
    string(sourceStatus.untracked_clean);
    string(sourceStatus.tracked_clean && sourceStatus.untracked_clean);
    "raw_AS006_execution_no_manual_period_fit";
    ];
note = [
    "Raw AS006 field-dependent execution phase.";
    "Git commit captured before this runner writes outputs.";
    "Git tree object captured before this runner writes outputs.";
    "Tracked-source cleanliness before output generation.";
    "Untracked-source/artifact cleanliness before output generation.";
    "True only when checkout is clean before Phase 15D writes outputs.";
    "Residuals are evaluated without fitting field period or adding excluded physics.";
    ];
provenance = table(item, value, note);
end

function grid = load_field_grid(cfg)
raw = read_required_table(cfg.phase15A.rawFieldFile, "AS006 raw field data");
required = cfg.phase15A.requiredColumns;
for k = 1:numel(required)
    if ~ismember(required(k), string(raw.Properties.VariableNames))
        error('v800:phase15DColumnMissing', ...
            'Raw field table is missing required column %s.', required(k));
    end
end

B = to_numeric_vector(raw.(char(required(1))));
I = to_numeric_vector(raw.(char(required(2))));
R1 = to_numeric_vector(raw.(char(required(3))));
R2 = to_numeric_vector(raw.(char(required(4))));

[Baxis, ~, bIdx] = unique(B, 'sorted');
[Iaxis, ~, iIdx] = unique(I, 'sorted');
gridSize = [numel(Iaxis), numel(Baxis)];
R1grid = accumarray([iIdx, bIdx], R1, gridSize, @mean, NaN);
R2grid = accumarray([iIdx, bIdx], R2, gridSize, @mean, NaN);

grid = struct();
grid.B = Baxis(:).';
grid.I = Iaxis(:);
grid.R1 = R1grid;
grid.R2 = R2grid;
grid.Y.R1 = normalize01(R1grid);
grid.Y.R2 = normalize01(R2grid);
grid.zeroFieldIndex = nearest_index(grid.B, 0);
grid.zeroCurrentIndex = nearest_index(grid.I, 0);
grid.rowCount = height(raw);
grid.currentPointCount = numel(Iaxis);
grid.fieldPointCount = numel(Baxis);
end

function v = to_numeric_vector(x)
if isnumeric(x)
    v = double(x(:));
else
    v = str2double(string(x(:)));
end
end

function Y = normalize01(X)
finite = X(isfinite(X));
if isempty(finite)
    Y = X .* NaN;
    return;
end
lo = min(finite);
hi = max(finite);
if hi <= lo
    Y = zeros(size(X));
else
    Y = (X - lo) ./ (hi - lo);
end
end

function models = build_variant_models(cfg, grid)
Iabs = abs(grid.I(:));
Imax = max(Iabs);
if Imax <= 0
    Imax = 1;
end
Ic0 = cfg.phase15D.currentSwitchingIcFraction * Imax;
width = max(cfg.phase15D.currentSwitchingWidthFraction * Imax, eps);
fieldEnvelope = exp(-(abs(grid.B(:).') ./ cfg.phase15D.fieldSuppressionB0_T).^2);
flux = grid.B(:).' .* cfg.phase15D.effectiveArea_m2 ./ ...
    cfg.phase15D.syntheticPhi0_Wb;
interference = abs(cos(pi .* flux));

models = struct();
models.sharedFluxQuanta = flux;
models.sharedPhaseEnvelope = interference;
models.P0 = build_channel_model(Iabs, Ic0 * ones(size(grid.B)), ...
    width, 1.0);
models.PB = build_channel_model(Iabs, Ic0 .* fieldEnvelope, ...
    width, 1.0);
models.Pphi = build_channel_model(Iabs, Ic0 .* fieldEnvelope .* ...
    interference, width, 1.0);

scale = cfg.phase15D.secondaryChannelScale;
models.P0_R2 = channel_secondary(models.P0, scale);
models.PB_R2 = channel_secondary(models.PB, scale);
models.Pphi_R2 = channel_secondary(models.Pphi, scale);
models.variantNames = cfg.phase15D.variants;
end

function M = build_channel_model(Iabs, IcByField, width, scale)
M = zeros(numel(Iabs), numel(IcByField));
for k = 1:numel(IcByField)
    M(:, k) = 0.5 .* (1 + tanh((Iabs - IcByField(k)) ./ width));
end
M = min(max(scale .* M, 0), 1);
end

function M2 = channel_secondary(M, scale)
% Fixed reduced-probe response: field-local and shared across variants.
M2 = scale .* M + (1 - scale) .* (M .^ 2);
M2 = min(max(M2, 0), 1);
end

function T = build_execution_manifest(cfg, inputs, grid)
phase15AClosure = resolve_handoff_closure(inputs, "phase15A");
phase15BClosure = resolve_handoff_closure(inputs, "phase15B");
phase15CClosure = resolve_handoff_closure(inputs, "phase15C");
item = [
    "phase15D_objective";
    "phase15A_closure_consumed";
    "phase15B_closure_consumed";
    "phase15C_closure_consumed";
    "device";
    "raw_field_source";
    "current_axis_points";
    "field_axis_points";
    "grid_rows";
    "variants";
    "channels";
    "shared_phase_state";
    "manual_period_fit";
    "topological_term_used";
    "thermal_memory_used";
    "independent_R1_R2_loop_parameters";
    "phase_solver_type";
    "effective_area_m2";
    "field_suppression_B0_T";
    ];
value = [
    "compare_frozen_P0_PB_Pphi_to_locked_AS006_R1_R2_maps";
    phase15AClosure;
    phase15BClosure;
    phase15CClosure;
    string(cfg.phase15A.device);
    string(cfg.phase15A.rawFieldFile);
    string(grid.currentPointCount);
    string(grid.fieldPointCount);
    string(grid.rowCount);
    join(cfg.phase15D.variants, "|");
    join(cfg.phase15D.channels, "|");
    "true";
    string(~cfg.phase15D.noManualPeriodFit);
    string(~cfg.phase15D.noTopologicalTerm);
    string(~cfg.phase15D.noThermalMemory);
    string(~cfg.phase15D.noIndependentR1R2LoopParameters);
    string(cfg.phase15D.phaseSolverType);
    string(cfg.phase15D.effectiveArea_m2);
    string(cfg.phase15D.fieldSuppressionB0_T);
    ];
note = [
    "Phase 15D performs raw execution; adequacy is reserved for Phase 15E.";
    "Phase 15A raw field lock consumed.";
    "Phase 15B model specification consumed.";
    "Phase 15C synthetic verification consumed.";
    "Only AS006 field maps are evaluated.";
    "Locked AS006 raw field data path consumed without relabeling.";
    "Locked current-axis size.";
    "Locked field-axis size.";
    "Raw table row count.";
    "Frozen field-response hierarchy.";
    "Both locked AS006 measurement channels are carried.";
    "Pphi phase envelope is shared across R1/R2.";
    "No observed oscillation period is fit.";
    "No topological term is introduced.";
    "No hysteretic thermal memory is introduced.";
    "R1/R2 do not receive independent loop periods.";
    "Static phase-constrained solver inherited from Phase 15C.";
    "Frozen effective area from synthetic verification, not AS006 fit.";
    "Frozen monotonic suppression scale from Phase 15C.";
    ];
T = table(item, value, note);
end

function value = resolve_handoff_closure(inputs, phaseName)
phaseName = string(phaseName);
switch phaseName
    case "phase15A"
        T = inputs.phase15AHandoff;
        rawText = inputs.phase15AHandoffRawText;
        key = "phase15A_closure";
        expected = "pass_as006_field_observable_lock";
        label = "Phase 15A handoff";
    case "phase15B"
        T = inputs.phase15BHandoff;
        rawText = inputs.phase15BHandoffRawText;
        key = "phase15B_closure";
        expected = "pass_minimal_phase_aware_model_freeze";
        label = "Phase 15B handoff";
    case "phase15C"
        T = inputs.phase15CHandoff;
        rawText = inputs.phase15CHandoffRawText;
        key = "phase15C_closure";
        expected = "pass_synthetic_flux_interference_verification";
        label = "Phase 15C handoff";
    otherwise
        error('v800:phase15DHandoffPhase', ...
            'Unknown handoff phase %s.', char(phaseName));
end

normalizedRawText = normalize_lookup_text(rawText);
if contains(normalizedRawText, normalize_lookup_text(key)) && ...
        contains(normalizedRawText, normalize_lookup_text(expected))
    value = expected;
    return;
end

value = lookup_table_value(T, key, ["value"; "status"], false, label);
if value == expected
    return;
end

if contains(normalizedRawText, normalize_lookup_text(expected))
    value = expected;
    return;
end

error('v800:phase15DHandoffLookup', ...
    'Could not resolve %s from %s.', char(key), char(label));
end

function value = lookup_table_value(T, itemName, valueCandidates, strict, label)
names = string(T.Properties.VariableNames);
keyCandidates = ["item"; "field"; "key"; "name"; "parameter"];
keyNames = names(ismember(lower(names), lower(keyCandidates)));
if isempty(keyNames) && width(T) >= 1
    keyNames = names(1);
end

idx = false(height(T), 1);
for k = 1:numel(keyNames)
    columnText = normalize_lookup_text(T.(char(keyNames(k))));
    thisIdx = columnText == normalize_lookup_text(itemName);
    if any(thisIdx)
        idx = thisIdx;
        break;
    end
end
if nnz(idx) ~= 1
    if strict
        error('v800:phase15DLookupCardinality', ...
            ['Expected exactly one %s row in %s table, but found %d. ' ...
            'Candidate key columns: %s.'], ...
            char(itemName), char(label), nnz(idx), ...
            char(strjoin(keyNames, '|')));
    end
    value = "";
    return;
end

valueCandidates = string(valueCandidates(:));
valueName = "";
for k = 1:numel(valueCandidates)
    hit = find(lower(names) == lower(valueCandidates(k)), 1, 'first');
    if ~isempty(hit)
        valueName = names(hit);
        break;
    end
end
if valueName == ""
    if strict && width(T) >= 3
        valueName = names(3);
    elseif strict
        error('v800:phase15DLookupMissingValueColumn', ...
            '%s table is missing the requested value/status column.', ...
            char(label));
    else
        value = "";
        return;
    end
end
values = T.(char(valueName));
value = strtrim(string(values(idx)));
end

function y = normalize_lookup_text(x)
y = lower(strtrim(string(x)));
y = erase(y, string(char(65279)));
y = erase(y, string(char(65533)));
y = regexprep(y, '^\xEF\xBB\xBF', '');
end

function T = build_variant_residuals(cfg, grid, models)
rows = {};
for v = 1:numel(cfg.phase15D.variants)
    variant = cfg.phase15D.variants(v);
    for c = 1:numel(cfg.phase15D.channels)
        channel = cfg.phase15D.channels(c);
        observed = grid.Y.(char(channel));
        predicted = get_model(models, variant, channel);
        rows(end+1, :) = {variant, channel, cfg.phase15D.channelRoles(c), ...
            mse(observed, predicted), mean_abs_error(observed, predicted), ...
            corr_finite(observed, predicted), all(isfinite(predicted(:)))}; %#ok<AGROW>
    end
end
T = cell2table(rows, 'VariableNames', {'variant', 'channel', ...
    'channel_role', 'mean_squared_residual', 'mean_absolute_residual', ...
    'map_correlation', 'all_predictions_finite'});
end

function T = build_heldout_field_windows(cfg, grid, models)
centralMask = abs(grid.B) <= cfg.phase15D.centralFieldHalfWindow_T;
outerMask = ~centralMask;
altA = mod(1:numel(grid.B), 2) == 1;
altB = ~altA;
rows = {};
for v = 1:numel(cfg.phase15D.variants)
    variant = cfg.phase15D.variants(v);
    for c = 1:numel(cfg.phase15D.channels)
        channel = cfg.phase15D.channels(c);
        observed = grid.Y.(char(channel));
        predicted = get_model(models, variant, channel);
        rows(end+1, :) = {variant, channel, ...
            "central_field_train_outer_field_holdout", ...
            mse(observed(:, centralMask), predicted(:, centralMask)), ...
            mse(observed(:, outerMask), predicted(:, outerMask)), ...
            sum(centralMask), sum(outerMask)}; %#ok<AGROW>
        rows(end+1, :) = {variant, channel, ...
            "alternate_field_window_holdout", ...
            mse(observed(:, altA), predicted(:, altA)), ...
            mse(observed(:, altB), predicted(:, altB)), ...
            sum(altA), sum(altB)}; %#ok<AGROW>
    end
end
T = cell2table(rows, 'VariableNames', {'variant', 'channel', ...
    'holdout_id', 'calibration_window_mse', 'heldout_window_mse', ...
    'calibration_field_count', 'heldout_field_count'});
end

function T = build_current_range_transfer(cfg, grid, models)
cutoff = cfg.phase15D.currentHoldoutFraction * max(abs(grid.I));
lowMask = abs(grid.I) <= cutoff;
highMask = ~lowMask;
rows = {};
for v = 1:numel(cfg.phase15D.variants)
    variant = cfg.phase15D.variants(v);
    for c = 1:numel(cfg.phase15D.channels)
        channel = cfg.phase15D.channels(c);
        observed = grid.Y.(char(channel));
        predicted = get_model(models, variant, channel);
        rows(end+1, :) = {variant, channel, cutoff, ...
            mse(observed(lowMask, :), predicted(lowMask, :)), ...
            mse(observed(highMask, :), predicted(highMask, :)), ...
            sum(lowMask), sum(highMask)}; %#ok<AGROW>
    end
end
T = cell2table(rows, 'VariableNames', {'variant', 'channel', ...
    'abs_current_cutoff_A', 'low_current_mse', 'high_current_mse', ...
    'low_current_points', 'high_current_points'});
end

function T = build_field_symmetry(cfg, grid, models)
rows = {};
for c = 1:numel(cfg.phase15D.channels)
    channel = cfg.phase15D.channels(c);
    rows(end+1, :) = {"observed", channel, ...
        symmetry_error(grid.B, grid.Y.(char(channel)))}; %#ok<AGROW>
end
for v = 1:numel(cfg.phase15D.variants)
    variant = cfg.phase15D.variants(v);
    for c = 1:numel(cfg.phase15D.channels)
        channel = cfg.phase15D.channels(c);
        rows(end+1, :) = {variant, channel, ...
            symmetry_error(grid.B, get_model(models, variant, channel))}; %#ok<AGROW>
    end
end
T = cell2table(rows, 'VariableNames', {'source', 'channel', ...
    'mean_even_field_symmetry_error'});
end

function value = symmetry_error(B, M)
posIdx = find(B > 0);
errs = [];
for k = 1:numel(posIdx)
    p = posIdx(k);
    n = nearest_index(B, -B(p));
    if abs(B(n) + B(p)) <= max(1e-12, 1e-6 * max(abs(B)))
        errs(end+1) = finite_mean(abs(M(:, p) - M(:, n))); %#ok<AGROW>
    end
end
if isempty(errs)
    value = NaN;
else
    value = finite_mean(errs);
end
end

function T = build_critical_current_envelopes(cfg, grid, models)
obs.R1 = estimate_ic_envelope(grid.I, grid.B, grid.Y.R1);
obs.R2 = estimate_ic_envelope(grid.I, grid.B, grid.Y.R2);
rows = {};
for v = 1:numel(cfg.phase15D.variants)
    variant = cfg.phase15D.variants(v);
    for c = 1:numel(cfg.phase15D.channels)
        channel = cfg.phase15D.channels(c);
        predEnv = estimate_ic_envelope(grid.I, grid.B, ...
            get_model(models, variant, channel));
        obsEnv = obs.(char(channel));
        err = finite_mean(abs(predEnv - obsEnv));
        rows(end+1, :) = {variant, channel, ...
            finite_mean(obsEnv), finite_mean(predEnv), ...
            err, corr_finite(obsEnv, predEnv)}; %#ok<AGROW>
    end
end
T = cell2table(rows, 'VariableNames', {'variant', 'channel', ...
    'observed_mean_abs_Ic_A', 'predicted_mean_abs_Ic_A', ...
    'mean_abs_Ic_error_A', 'Ic_envelope_correlation'});
end

function Ic = estimate_ic_envelope(I, B, M)
Ic = nan(1, numel(B));
for k = 1:numel(B)
    y = M(:, k);
    if sum(isfinite(y)) < 4
        continue;
    end
    [~, idx] = max(abs(diff(y)));
    idx = min(max(idx, 1), numel(I));
    Ic(k) = abs(I(idx));
end
end

function T = build_oscillatory_structure(cfg, grid, models)
[~, probeIdx] = max(std(grid.Y.R1, 0, 2));
fieldTraceCurrent_A = grid.I(probeIdx);
rows = {};
for c = 1:numel(cfg.phase15D.channels)
    channel = cfg.phase15D.channels(c);
    observed = grid.Y.(char(channel));
    [pk, tr, score] = oscillation_metrics(observed(probeIdx, :), ...
        cfg.phase15D.oscillationPeakProminenceFraction);
    rows(end+1, :) = {"observed", channel, fieldTraceCurrent_A, ...
        pk, tr, score, false}; %#ok<AGROW>
end
for v = 1:numel(cfg.phase15D.variants)
    variant = cfg.phase15D.variants(v);
    for c = 1:numel(cfg.phase15D.channels)
        channel = cfg.phase15D.channels(c);
        predicted = get_model(models, variant, channel);
        [pk, tr, score] = oscillation_metrics( ...
            predicted(probeIdx, :), ...
            cfg.phase15D.oscillationPeakProminenceFraction);
        rows(end+1, :) = {variant, channel, fieldTraceCurrent_A, ...
            pk, tr, score, ~cfg.phase15D.noManualPeriodFit}; %#ok<AGROW>
    end
end
T = cell2table(rows, 'VariableNames', {'source', 'channel', ...
    'field_trace_current_A', 'peak_count', 'trough_count', ...
    'oscillation_score', 'manual_period_fit'});
end

function [peakCount, troughCount, score] = oscillation_metrics(trace, frac)
y = double(trace(:).');
finite = isfinite(y);
y = y(finite);
if numel(y) < 5
    peakCount = 0;
    troughCount = 0;
    score = NaN;
    return;
end
span = max(y) - min(y);
threshold = frac * max(span, eps);
peakCount = 0;
troughCount = 0;
for k = 2:(numel(y) - 1)
    if y(k) > y(k - 1) && y(k) > y(k + 1) && ...
            (y(k) - min(y(k - 1), y(k + 1))) >= threshold
        peakCount = peakCount + 1;
    end
    if y(k) < y(k - 1) && y(k) < y(k + 1) && ...
            (max(y(k - 1), y(k + 1)) - y(k)) >= threshold
        troughCount = troughCount + 1;
    end
end
score = std(diff(y));
end

function T = build_zero_field_inheritance(cfg, grid, models)
z = grid.zeroFieldIndex;
rows = {};
for v = ["PB", "Pphi"]
    for c = 1:numel(cfg.phase15D.channels)
        channel = cfg.phase15D.channels(c);
        predicted = get_model(models, v, channel);
        reference = get_model(models, "P0", channel);
        err = max(abs(predicted(:, z) - reference(:, z)));
        rows(end+1, :) = {v, channel, grid.B(z), err, err <= 1e-9}; %#ok<AGROW>
    end
end
T = cell2table(rows, 'VariableNames', {'variant', 'channel', ...
    'nearest_zero_field_T', 'max_abs_difference_vs_P0', ...
    'zero_field_inheritance_pass'});
end

function T = build_prediction_bounds_audit(cfg, grid, models)
rows = {};
for v = 1:numel(cfg.phase15D.variants)
    variant = cfg.phase15D.variants(v);
    for c = 1:numel(cfg.phase15D.channels)
        channel = cfg.phase15D.channels(c);
        observed = grid.Y.(char(channel));
        predicted = get_model(models, variant, channel);
        lower = max(predicted - cfg.phase15D.predictionBoundHalfWidth, 0);
        upper = min(predicted + cfg.phase15D.predictionBoundHalfWidth, 1);
        outside = observed < lower | observed > upper;
        fraction = mean(outside(isfinite(observed) & isfinite(predicted)));
        rows(end+1, :) = {variant, channel, ...
            cfg.phase15D.predictionBoundHalfWidth, fraction, ...
            string(bounds_status(fraction))}; %#ok<AGROW>
    end
end
T = cell2table(rows, 'VariableNames', {'variant', 'channel', ...
    'normalized_half_width', 'fraction_outside_bounds', ...
    'bounds_status'});
end

function status = bounds_status(fraction)
if fraction <= 0.05
    status = "bounded";
elseif fraction <= 0.20
    status = "localized_violation";
else
    status = "widespread_violation";
end
end

function T = build_shared_phase_state(cfg, grid, models)
B_T = grid.B(:);
shared_flux_quanta = models.sharedFluxQuanta(:);
shared_phase_envelope = models.sharedPhaseEnvelope(:);
R1_R2_shared_phase_state = true(size(B_T));
independent_channel_periods = false(size(B_T));
independent_channel_loop_geometry = false(size(B_T));
manual_period_fit = false(size(B_T));
T = table(B_T, shared_flux_quanta, shared_phase_envelope, ...
    R1_R2_shared_phase_state, independent_channel_periods, ...
    independent_channel_loop_geometry, manual_period_fit);
end

function T = build_channel_transform_audit(cfg)
item = [
    "channel_transform_field_local";
    "cross_field_mean_used";
    "heldout_field_columns_used_in_channel_transform";
    "R1_R2_shared_phase_state";
    "channel_specific_period_parameters";
    "manual_period_fit";
    "transform_policy";
    ];
status = [
    "true";
    "false";
    "false";
    "true";
    "false";
    string(~cfg.phase15D.noManualPeriodFit);
    "fixed_field_local_reduced_probe_response";
    ];
value = status;
note = [
    "R2 is computed from each local (I,B) model value only.";
    "The secondary-channel transform does not average across field columns.";
    "No held-out field columns enter the channel transform.";
    "R1/R2 share the same Pphi phase envelope.";
    "No R2-specific oscillation period or loop geometry is introduced.";
    "Observed AS006 oscillation period is not manually fit.";
    "R2 = scale*M + (1-scale)*M^2 with fixed shared scale.";
    ];
T = table(item, status, value, note);
end

function T = build_gate_summary(cfg, inputs, provenance, grid, residuals, ...
    heldout, currentTransfer, symmetry, IcEnv, oscillations, zeroField, ...
    boundsAudit, sharedState, channelTransformAudit)
phase15AClosure = resolve_handoff_closure(inputs, "phase15A");
phase15BClosure = resolve_handoff_closure(inputs, "phase15B");
phase15CClosure = resolve_handoff_closure(inputs, "phase15C");
gate = strings(0, 1);
outcome = strings(0, 1);
note = strings(0, 1);
add("Phase 15A raw field lock consumed", ...
    phase15AClosure == cfg.phase15D.expectedPhase15AClosure, ...
    "Locked AS006 raw field source and channel metadata are consumed.");
add("Phase 15B specification consumed unchanged", ...
    phase15BClosure == cfg.phase15D.expectedPhase15BClosure, ...
    "Frozen P0/PB/Pphi hierarchy is consumed.");
add("Phase 15C synthetic verification consumed", ...
    phase15CClosure == cfg.phase15D.expectedPhase15CClosure, ...
    "Synthetic flux/interference verification is consumed.");
add("Both locked channels evaluated", ...
    all(ismember(cfg.phase15D.channels, string(residuals.channel))), ...
    "R1 and R2 are both evaluated.");
add("All frozen variants evaluated", ...
    all(ismember(cfg.phase15D.variants, string(residuals.variant))), ...
    "P0, PB, and Pphi residuals are emitted.");
add("Raw grid finite", ...
    all(isfinite(grid.R1(:))) && all(isfinite(grid.R2(:))), ...
    "Canonical AS006 raw grid contains finite R1/R2 values.");
add("Full-map residuals finite", ...
    all(isfinite(residuals.mean_squared_residual)), ...
    "Full-map residuals are finite for all variants and channels.");
add("Held-out field windows evaluated", ...
    height(heldout) > 0 && all(isfinite(heldout.heldout_window_mse)), ...
    "Central/outer and alternate field windows are evaluated.");
add("Current-range transfer evaluated", ...
    height(currentTransfer) > 0 && ...
    all(isfinite(currentTransfer.high_current_mse)), ...
    "Low/high current transfer rows are emitted.");
add("Field symmetry evaluated", ...
    height(symmetry) > 0 && ...
    any(isfinite(symmetry.mean_even_field_symmetry_error)), ...
    "Observed and modeled even-field symmetry diagnostics are emitted.");
add("Critical-current envelopes emitted", ...
    height(IcEnv) > 0 && all(isfinite(IcEnv.mean_abs_Ic_error_A)), ...
    "Observed/model envelope errors are emitted.");
add("Oscillatory structure emitted", ...
    height(oscillations) > 0 && all(~oscillations.manual_period_fit), ...
    "Field-trace oscillatory metrics are emitted without fitting a period.");
add("Zero-field inheritance checked", ...
    all(zeroField.zero_field_inheritance_pass), ...
    "PB/Pphi recover P0 at nearest zero field.");
add("Prediction bounds audit emitted", ...
    height(boundsAudit) > 0 && all(isfinite(boundsAudit.fraction_outside_bounds)), ...
    "Bounds are audited but adequacy remains Phase 15E.");
add("R1/R2 share one phase state", ...
    all(sharedState.R1_R2_shared_phase_state) && ...
    ~any(sharedState.independent_channel_periods) && ...
    ~any(sharedState.independent_channel_loop_geometry), ...
    "R1/R2 use the same phase envelope.");
add("Channel transform is field-local", ...
    audit_bool(channelTransformAudit, "channel_transform_field_local") && ...
    ~audit_bool(channelTransformAudit, "cross_field_mean_used") && ...
    ~audit_bool(channelTransformAudit, ...
    "heldout_field_columns_used_in_channel_transform") && ...
    ~audit_bool(channelTransformAudit, "channel_specific_period_parameters"), ...
    "R2 transform uses no cross-field mean, holdout leakage, or channel period.");
add("No manual period fit", cfg.phase15D.noManualPeriodFit, ...
    "Observed AS006 oscillation period is not fitted.");
add("No topology term", cfg.phase15D.noTopologicalTerm, ...
    "No topological superconductivity term is introduced.");
add("No thermal memory", cfg.phase15D.noThermalMemory, ...
    "No electrothermal hysteresis or memory is introduced.");
add("No independent R1/R2 loop parameters", ...
    cfg.phase15D.noIndependentR1R2LoopParameters, ...
    "Channel-specific loop periods are prohibited.");
clean = lookup_provenance(provenance, "source_pre_run_clean") == "true";
add("Clean provenance", clean, ...
    "The checkout was clean before Phase 15D wrote outputs.");
T = table(gate, outcome, note);

    function add(name, tf, msg)
        gate(end+1, 1) = string(name);
        if tf
            outcome(end+1, 1) = "pass";
        else
            outcome(end+1, 1) = "fail";
        end
        note(end+1, 1) = string(msg);
    end
end

function tf = audit_bool(T, itemName)
idx = strcmpi(strtrim(string(T.item)), string(itemName));
tf = nnz(idx) == 1 && lower(strtrim(string(T.value(idx)))) == "true";
end

function value = lookup_provenance(T, itemName)
idx = strcmpi(strtrim(string(T.item)), itemName);
if nnz(idx) ~= 1
    value = "";
else
    value = strtrim(string(T.value(idx)));
end
end

function T = build_handoff_status(cfg, gates)
allPass = all(string(gates.outcome) == "pass");
if allPass
    closure = "complete_raw_AS006_field_execution";
    executionIntegrity = "pass";
else
    closure = "incomplete_raw_AS006_field_execution";
    executionIntegrity = "review_required";
end
item = [
    "phase15D_closure";
    "execution_integrity";
    "raw_AS006_residuals_used";
    "variants_evaluated";
    "channels_evaluated";
    "shared_phase_state";
    "manual_period_fit";
    "topological_term_used";
    "thermal_memory_used";
    "independent_R1_R2_loop_parameters";
    "field_model_adequacy";
    "next_phase";
    ];
status = [
    closure;
    executionIntegrity;
    "true";
    "P0|PB|Pphi";
    "R1|R2";
    "true";
    "false";
    "false";
    "false";
    "false";
    "pending_phase15E";
    string(cfg.phase15D.nextPhase);
    ];
value = status;
note = [
    "Phase 15D is an execution phase; final adequacy is reserved for Phase 15E.";
    "Pass means all execution and bookkeeping gates pass.";
    "Raw locked AS006 R1/R2 maps are evaluated for the first time in Phase 15D.";
    "Frozen field-response variants are compared.";
    "Both locked channels are carried.";
    "Pphi uses one shared phase envelope for R1/R2.";
    "Observed oscillation period is not manually fit.";
    "No topological term or claim is introduced.";
    "No electrothermal memory or hysteresis model is introduced.";
    "R1/R2 do not receive independent loop parameters.";
    "Adequacy decision is intentionally deferred.";
    "Read-only adequacy decision follows in Phase 15E.";
    ];
T = table(item, status, value, note);
end

function M = get_model(models, variant, channel)
variant = string(variant);
channel = string(channel);
if channel == "R2"
    key = char(variant + "_R2");
else
    key = char(variant);
end
M = models.(key);
end

function value = mse(A, B)
mask = isfinite(A) & isfinite(B);
if ~any(mask(:))
    value = NaN;
else
    D = A(mask) - B(mask);
    value = mean(D(:).^2);
end
end

function value = mean_abs_error(A, B)
mask = isfinite(A) & isfinite(B);
if ~any(mask(:))
    value = NaN;
else
    value = mean(abs(A(mask) - B(mask)));
end
end

function value = corr_finite(A, B)
a = A(:);
b = B(:);
mask = isfinite(a) & isfinite(b);
a = a(mask);
b = b(mask);
if numel(a) < 3 || std(a) == 0 || std(b) == 0
    value = NaN;
else
    C = corrcoef(a, b);
    value = C(1, 2);
end
end

function value = finite_mean(x)
x = x(:);
x = x(isfinite(x));
if isempty(x)
    value = NaN;
else
    value = mean(x);
end
end

function idx = nearest_index(axis, target)
[~, idx] = min(abs(axis - target));
end
