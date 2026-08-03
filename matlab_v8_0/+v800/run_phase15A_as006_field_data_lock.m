function out = run_phase15A_as006_field_data_lock(cfg)
%RUN_PHASE15A_AS006_FIELD_DATA_LOCK Lock AS006 field-dependent raw data.
%
% Phase 15A is an observable/data-lock phase only. It locates and freezes
% the AS006 dV/dI(I,B,T) raw field grid, axis metadata, probe/channel
% identity, and sweep-history availability. It deliberately does not
% introduce phase dynamics, flux quantization, parameter retuning, or any
% field-dependent model fit.

if ~exist(cfg.outputDir, 'dir')
    mkdir(cfg.outputDir);
end

sourceProvenance = build_source_provenance(cfg);
rawSourceLock = build_raw_source_lock(cfg);
axisMetadataLock = build_axis_metadata_lock(cfg, rawSourceLock);
channelLock = build_channel_lock(cfg, axisMetadataLock);
sweepHistoryAudit = build_sweep_history_audit(cfg, axisMetadataLock);
phase15Policy = build_phase15_policy(cfg);
gateSummary = build_gate_summary(cfg, rawSourceLock, axisMetadataLock, ...
    channelLock, sweepHistoryAudit, sourceProvenance);
handoffStatus = build_handoff_status(cfg, rawSourceLock, axisMetadataLock, ...
    channelLock, sweepHistoryAudit, gateSummary, sourceProvenance);

writetable(rawSourceLock, cfg.phase15A.rawFieldSourceLockFile);
writetable(axisMetadataLock, cfg.phase15A.axisMetadataLockFile);
writetable(channelLock, cfg.phase15A.channelLockFile);
writetable(sweepHistoryAudit, cfg.phase15A.sweepHistoryAuditFile);
writetable(phase15Policy, cfg.phase15A.phase15PolicyFile);
writetable(gateSummary, cfg.phase15A.gateSummaryFile);
writetable(handoffStatus, cfg.phase15A.handoffStatusFile);
writetable(sourceProvenance, cfg.phase15A.sourceProvenanceFile);

try
    h = v800.plot_phase15A_as006_field_data_lock_summary(cfg, ...
        rawSourceLock, axisMetadataLock, channelLock, ...
        sweepHistoryAudit, gateSummary);
catch ME
    warning('v8:phase15APlotFailed', ...
        'Phase 15A summary plot failed: %s', ME.message);
    h = [];
end

out = struct();
out.config = cfg;
out.rawSourceLock = rawSourceLock;
out.axisMetadataLock = axisMetadataLock;
out.channelLock = channelLock;
out.sweepHistoryAudit = sweepHistoryAudit;
out.phase15Policy = phase15Policy;
out.gateSummary = gateSummary;
out.handoffStatus = handoffStatus;
out.sourceProvenance = sourceProvenance;
out.figure = h;
out.paths = build_paths(cfg);
end

function paths = build_paths(cfg)
paths = struct();
paths.rawFieldSourceLock = cfg.phase15A.rawFieldSourceLockFile;
paths.axisMetadataLock = cfg.phase15A.axisMetadataLockFile;
paths.channelLock = cfg.phase15A.channelLockFile;
paths.sweepHistoryAudit = cfg.phase15A.sweepHistoryAuditFile;
paths.phase15Policy = cfg.phase15A.phase15PolicyFile;
paths.gateSummary = cfg.phase15A.gateSummaryFile;
paths.handoffStatus = cfg.phase15A.handoffStatusFile;
paths.sourceProvenance = cfg.phase15A.sourceProvenanceFile;
paths.figurePng = [cfg.phase15A.figureBaseFile '.png'];
paths.figurePdf = [cfg.phase15A.figureBaseFile '.pdf'];
end

function provenance = build_source_provenance(cfg)
sourceStatus = v800.git_tree_status(cfg.repoRoot);
phase14DReachable = git_commit_is_ancestor(cfg.repoRoot, "cd08009");
item = [
    "phase"
    "source_commit_sha"
    "source_tree_sha"
    "source_pre_run_tracked_clean"
    "source_pre_run_untracked_clean"
    "source_pre_run_clean"
    "frozen_phase14D_artifact_commit"
    "frozen_phase14D_artifact_commit_reachable"
    "provenance_scope"
    ];
value = [
    "phase15A_as006_field_data_lock"
    sourceStatus.commit_sha
    sourceStatus.tree_sha
    string(sourceStatus.tracked_clean)
    string(sourceStatus.untracked_clean)
    string(sourceStatus.tracked_clean && sourceStatus.untracked_clean)
    "cd08009"
    string(phase14DReachable)
    "field_data_observable_lock_no_phase_model"
    ];
note = [
    "AS006 raw field-data recovery and observable-lock phase."
    "Git commit captured before this runner writes outputs."
    "Git tree object captured before this runner writes outputs."
    "Tracked-source cleanliness before output generation."
    "Untracked-source/artifact cleanliness before output generation."
    "True only when checkout is clean before Phase 15A writes outputs."
    "Canonical Phase 14D artifact-freeze commit consumed as handoff."
    "True when the Phase 14D artifact commit is an ancestor of this run."
    "No phase-aware model, flux fit, or parameter retuning is introduced."
    ];
provenance = table(item, value, note);
end

function tf = git_commit_is_ancestor(repoRoot, commitish)
cmd = sprintf('git -C "%s" merge-base --is-ancestor "%s" HEAD', ...
    repoRoot, commitish);
[status, ~] = system(cmd);
tf = status == 0;
end

function rawSourceLock = build_raw_source_lock(cfg)
pathValue = string(cfg.phase15A.rawFieldFile);
existsFlag = exist(char(pathValue), 'file') == 2;
headers = strings(1, 0);
requiredPresent = false;
rowCount = NaN;
fileBytes = NaN;
if existsFlag
    info = dir(char(pathValue));
    fileBytes = info.bytes;
    headers = read_header(pathValue);
    requiredPresent = all(ismember(cfg.phase15A.requiredColumns, headers));
    rowCount = count_data_rows(pathValue);
end

rawSourceLock = table( ...
    string(cfg.phase15A.device), ...
    string(cfg.phase15A.rawSourceLabel), ...
    pathValue, ...
    string(existsFlag), ...
    string(file_sha256(pathValue)), ...
    fileBytes, ...
    rowCount, ...
    string(strjoin(cellstr(headers), '|')), ...
    string(requiredPresent), ...
    string(cfg.phase15A.legacyLoaderFile), ...
    string(exist(char(cfg.phase15A.legacyLoaderFile), 'file') == 2), ...
    "locked_raw_field_candidate", ...
    'VariableNames', {'device', 'source_label', 'raw_file', ...
    'raw_file_exists', 'source_sha256', 'file_bytes', 'data_row_count', ...
    'columns_detected', 'required_columns_present', 'legacy_loader_file', ...
    'legacy_loader_exists', 'source_status'});
end

function axisMetadataLock = build_axis_metadata_lock(cfg, rawSourceLock)
row = empty_axis_row();
row.device = string(cfg.phase15A.device);
row.observable_type = string(cfg.phase15A.requiredObservableType);
row.current_units = string(cfg.phase15A.currentUnits);
row.field_units = string(cfg.phase15A.fieldUnits);
row.temperature_units = "K";
row.assumed_temperature_K = cfg.phase15A.assumedTemperature_K;
row.field_direction = string(cfg.phase15A.fieldDirection);

if string(rawSourceLock.raw_file_exists(1)) ~= "true" || ...
        string(rawSourceLock.required_columns_present(1)) ~= "true"
    row.axis_lock_status = "blocked_missing_source_or_columns";
    axisMetadataLock = struct2table(row);
    return;
end

T = read_field_table(string(rawSourceLock.raw_file(1)));
B = to_numeric_vector(T.Bfield);
I = to_numeric_vector(T.I);
validAxes = isfinite(B) & isfinite(I);
B = B(validAxes);
I = I(validAxes);
Bu = unique(B(:), 'sorted');
Iu = unique(I(:), 'sorted');
row.current_point_count = numel(Iu);
row.field_point_count = numel(Bu);
row.grid_point_count = numel(Iu) * numel(Bu);
row.observed_row_count = numel(B);
row.current_min_A = min(Iu);
row.current_max_A = max(Iu);
row.field_min_T = min(Bu);
row.field_max_T = max(Bu);
row.zero_current_available = any(abs(Iu) <= eps(max(abs(Iu))));
row.zero_field_available = any(abs(Bu) <= eps(max(abs(Bu))));
row.zero_current_index = find_zero_index(Iu);
row.zero_field_index = find_zero_index(Bu);
row.current_axis_monotonic = all(diff(Iu) > 0);
row.field_axis_monotonic = all(diff(Bu) > 0);
row.grid_complete = row.observed_row_count == row.grid_point_count;
row.axis_lock_status = conditional(row.zero_current_available && ...
    row.zero_field_available && row.grid_complete, ...
    "locked", "locked_with_limitations");
axisMetadataLock = struct2table(row);
end

function channelLock = build_channel_lock(cfg, axisMetadataLock)
columns = [cfg.phase15A.primaryMatrixColumn; ...
    cfg.phase15A.secondaryMatrixColumn];
channels = [cfg.phase15A.primaryMeasurementChannel; ...
    cfg.phase15A.secondaryMeasurementChannel];
probePairs = ["top_4_10"; "bottom_3_9"];
roles = ["primary"; "secondary"];
rows = repmat(empty_channel_row(), numel(columns), 1);

sourceUsable = string(axisMetadataLock.axis_lock_status(1)) ~= ...
    "blocked_missing_source_or_columns";
if sourceUsable
    rawPath = string(cfg.phase15A.rawFieldFile);
    T = read_field_table(rawPath);
end

for k = 1:numel(columns)
    rows(k).device = string(cfg.phase15A.device);
    rows(k).channel_role = roles(k);
    rows(k).matrix_column = columns(k);
    rows(k).measurement_channel = channels(k);
    rows(k).probe_pair = probePairs(k);
    rows(k).dVdI_units = string(cfg.phase15A.dVdIUnits);
    rows(k).channel_identity_locked = true;
    if sourceUsable && ismember(char(columns(k)), T.Properties.VariableNames)
        vals = to_numeric_vector(T.(char(columns(k))));
        rows(k).finite_fraction = mean(isfinite(vals));
        rows(k).normalization_policy = "raw_ohm_values_retained";
        rows(k).channel_status = conditional(rows(k).finite_fraction == 1, ...
            "locked", "locked_with_nonfinite_values");
    else
        rows(k).finite_fraction = NaN;
        rows(k).normalization_policy = "not_evaluated";
        rows(k).channel_status = "blocked_missing_channel";
    end
end
channelLock = struct2table(rows);
end

function sweepHistoryAudit = build_sweep_history_audit(cfg, axisMetadataLock)
rows = repmat(empty_sweep_row(), 7, 1);
labels = [
    "current_axis"
    "field_axis"
    "current_sweep_direction"
    "field_sweep_direction"
    "up_down_current_branches"
    "up_down_field_branches"
    "sweep_rate_metadata"
    ];
statuses = [
    "locked"
    "locked"
    "single_branch_inferred"
    "single_branch_inferred"
    "not_available"
    "not_available"
    "not_available"
    ];
values = [
    string(sprintf('%d points, zero index %d', ...
    axisMetadataLock.current_point_count(1), ...
    axisMetadataLock.zero_current_index(1)))
    string(sprintf('%d points, zero index %d', ...
    axisMetadataLock.field_point_count(1), ...
    axisMetadataLock.zero_field_index(1)))
    "negative_to_positive_current_per_field_step"
    infer_field_sweep_direction(cfg)
    "false"
    "false"
    "false"
    ];
notes = [
    "Current axis is locked from raw I column."
    "Magnetic-field axis is locked from raw Bfield column."
    "The table contains one monotonic current branch per field value."
    "Field order is inferred from first occurrence in the raw table."
    "Separate up/down current branches are not encoded."
    "Separate up/down field branches are not encoded."
    "Sweep-rate metadata are not encoded in the recovered file."
    ];
for k = 1:numel(rows)
    rows(k).item = labels(k);
    rows(k).status = statuses(k);
    rows(k).value = values(k);
    rows(k).note = notes(k);
end
sweepHistoryAudit = struct2table(rows);
end

function phase15Policy = build_phase15_policy(cfg)
item = [
    "phase15A_scope"
    "phase_aware_model"
    "flux_quantization_fit"
    "topological_superconductivity_claim"
    "parameter_retuning"
    "raw_data_relabeling"
    "allowed_next_step"
    ];
status = [
    "locked"
    "prohibited"
    "prohibited"
    "prohibited"
    "prohibited"
    "prohibited"
    "allowed"
    ];
value = [
    "raw_AS006_dVdI_I_B_fixed_T_observable_lock"
    string(cfg.phase15A.allowPhaseAwareModel)
    string(cfg.phase15A.allowFluxQuantizationFit)
    string(cfg.phase15A.allowTopologicalClaim)
    string(cfg.phase15A.allowParameterRetuning)
    string(cfg.phase15A.allowRawDataRelabeling)
    string(cfg.phase15A.nextPhase)
    ];
note = [
    "Phase 15A locks data availability and coordinates only."
    "Phase dynamics are deferred until Phase 15B specification freeze."
    "No field period or flux quantum is fit in Phase 15A."
    "Oscillatory field response cannot imply topology in this roadmap."
    "Frozen Phase 14 baseline/current-switching conclusions are unchanged."
    "R1/R2 and axis identities are recorded, not reassigned."
    "Phase 15B may specify a minimal phase-aware model after this lock."
    ];
phase15Policy = table(item, status, value, note);
end

function gates = build_gate_summary(cfg, rawSourceLock, axisMetadataLock, ...
    channelLock, sweepHistoryAudit, sourceProvenance)
rawExists = string(rawSourceLock.raw_file_exists(1)) == "true";
columnsPresent = string(rawSourceLock.required_columns_present(1)) == "true";
checksumComputed = string(rawSourceLock.source_sha256(1)) ~= "missing" && ...
    string(rawSourceLock.source_sha256(1)) ~= "unavailable";
axesLocked = string(axisMetadataLock.axis_lock_status(1)) ~= ...
    "blocked_missing_source_or_columns";
zeroCurrent = axisMetadataLock.zero_current_available(1);
zeroField = axisMetadataLock.zero_field_available(1);
completeGrid = axisMetadataLock.grid_complete(1);
bothChannels = height(channelLock) == 2 && ...
    all(string(channelLock.channel_status) == "locked");
sweepLimitsRecorded = all(ismember(["up_down_current_branches"; ...
    "up_down_field_branches"; "sweep_rate_metadata"], ...
    string(sweepHistoryAudit.item)));
noPhaseModel = ~cfg.phase15A.allowPhaseAwareModel && ...
    ~cfg.phase15A.allowFluxQuantizationFit;
clean = lookup_provenance(sourceProvenance, "source_pre_run_clean") == "true";

gates = table( ...
    [
    "Raw AS006 field source exists"
    "Required B/I/R1/R2 columns present"
    "Raw source checksum recorded"
    "Current and field axes locked"
    "Zero-current index available"
    "Zero-field index available"
    "Raw grid complete"
    "R1/R2 channel identity locked"
    "Sweep-history limitations recorded"
    "No phase-aware model introduced"
    "Clean provenance"
    ].', ...
    [
    passfail(rawExists)
    passfail(columnsPresent)
    passfail(checksumComputed)
    passfail(axesLocked)
    passfail(zeroCurrent)
    passfail(zeroField)
    passfail(completeGrid)
    passfail(bothChannels)
    passfail(sweepLimitsRecorded)
    passfail(noPhaseModel)
    passfail(clean)
    ], ...
    [
    "The mapped AS006 dVdI(I,B) source is present."
    "The raw table contains Bfield, I, R1, and R2."
    "SHA-256 provenance is recorded for the external raw file."
    "Axis sizes, ranges, and zero indices are frozen."
    "Current-zero location is available for future zero-bias checks."
    "Field-zero location is available for future zero-field consistency."
    "Observed rows equal current-by-field grid size."
    "R1 and R2 are retained with fixed probe-pair meaning."
    "Missing up/down branches and sweep-rate metadata are explicit."
    "Phase 15A remains a data lock; model specification is deferred."
    "The checkout was clean before Phase 15A wrote outputs."
    ], ...
    'VariableNames', {'gate', 'outcome', 'note'});
end

function handoff = build_handoff_status(cfg, rawSourceLock, axisMetadataLock, ...
    channelLock, sweepHistoryAudit, gates, sourceProvenance)
allCorePass = all(string(gates.outcome(1:10)) == "pass");
sourceClean = lookup_provenance(sourceProvenance, ...
    "source_pre_run_clean") == "true";
phase15AClosure = conditional(allCorePass, ...
    "pass_as006_field_observable_lock", ...
    "blocked_as006_field_observable_lock");
readyFor15B = allCorePass;
separateBranches = lookup_sweep(sweepHistoryAudit, ...
    "up_down_current_branches") == "true" || ...
    lookup_sweep(sweepHistoryAudit, "up_down_field_branches") == "true";

item = [
    "phase15A_closure"
    "field_observable_locked"
    "raw_field_source"
    "current_axis_points"
    "field_axis_points"
    "temperature_status"
    "measurement_channels"
    "sweep_history_status"
    "phase_aware_model_status"
    "ready_for_phase15B"
    "phase15C_dependency"
    "source_pre_run_clean"
    ];
status = [
    phase15AClosure
    conditional(readyFor15B, "pass", "fail")
    string(rawSourceLock.source_status(1))
    "locked"
    "locked"
    "fixed_or_assumed"
    conditional(all(string(channelLock.channel_status) == "locked"), ...
    "locked", "incomplete")
    conditional(separateBranches, "branches_available", ...
    "single_branch_no_sweep_rate")
    "not_introduced"
    conditional(readyFor15B, "true", "false")
    "phase15B_model_spec_then_phase15C_synthetic_flux_verification"
    string(sourceClean)
    ];
value = [
    phase15AClosure
    string(readyFor15B)
    string(rawSourceLock.raw_file(1))
    string(axisMetadataLock.current_point_count(1))
    string(axisMetadataLock.field_point_count(1))
    string(sprintf('%.4g K', axisMetadataLock.assumed_temperature_K(1)))
    string(strjoin(cellstr(string(channelLock.measurement_channel)), '|'))
    "up/down branches and sweep rate unavailable in locked raw table"
    "false"
    string(readyFor15B)
    string(cfg.phase15A.nextPhase)
    string(sourceClean)
    ];
note = [
    "Phase 15A closes if the raw field observable is locked."
    "No field-dependent model adequacy is assessed in this phase."
    "External raw file path is frozen with checksum."
    "Current axis is available for I-dependent maps."
    "Magnetic field axis is available for B-dependent maps."
    "The legacy loader records an assumed fixed low temperature."
    "Both R1 and R2 are carried forward."
    "Hysteresis/sweep-rate conclusions remain unavailable."
    "Phase-aware equations begin only after Phase 15B."
    "True means Phase 15B may freeze a minimal model specification."
    "Phase 15C must verify flux/phase behavior synthetically before AS006 residual fitting."
    "Pre-run clean provenance is recorded separately from generated artifacts."
    ];
handoff = table(item, status, value, note);
end

function T = read_field_table(pathValue)
opts = detectImportOptions(char(pathValue), 'FileType', 'text');
try
    opts.VariableNamingRule = 'preserve';
catch
end
T = readtable(char(pathValue), opts);
end

function headers = read_header(pathValue)
fid = fopen(char(pathValue), 'r');
if fid < 0
    headers = strings(1, 0);
    return;
end
line = fgetl(fid);
fclose(fid);
if ~ischar(line)
    headers = strings(1, 0);
else
    headers = string(strsplit(strtrim(line), ','));
end
end

function n = count_data_rows(pathValue)
quotedPath = shell_quote(pathValue);
[statusCode, textOut] = system(sprintf('wc -l %s', quotedPath));
if statusCode ~= 0
    n = NaN;
    return;
end
parts = split(strtrim(string(textOut)));
nLines = str2double(parts(1));
n = max(nLines - 1, 0);
end

function direction = infer_field_sweep_direction(cfg)
direction = "not_available";
pathValue = string(cfg.phase15A.rawFieldFile);
if exist(char(pathValue), 'file') ~= 2
    return;
end
T = read_field_table(pathValue);
B = to_numeric_vector(T.Bfield);
Bstable = unique(B(isfinite(B)), 'stable');
if numel(Bstable) < 2
    direction = "single_field_value";
elseif all(diff(Bstable) > 0)
    direction = "increasing_field";
elseif all(diff(Bstable) < 0)
    direction = "decreasing_field";
else
    direction = "nonmonotonic_or_segmented_field_order";
end
end

function y = to_numeric_vector(x)
if istable(x)
    x = table2array(x);
end
if isnumeric(x) || islogical(x)
    y = double(x);
elseif iscell(x)
    y = str2double(x);
elseif ischar(x)
    y = str2double(cellstr(x));
elseif isstring(x)
    y = str2double(cellstr(x));
elseif iscategorical(x)
    y = str2double(cellstr(x));
else
    try
        y = double(x);
    catch
        y = str2double(cellstr(x));
    end
end
y = y(:);
end

function idx = find_zero_index(axisValues)
[~, idx] = min(abs(axisValues));
if isempty(idx) || abs(axisValues(idx)) > eps(max(abs(axisValues)))
    idx = NaN;
end
end

function row = empty_axis_row()
row = struct( ...
    'device', "", ...
    'observable_type', "", ...
    'current_units', "", ...
    'field_units', "", ...
    'temperature_units', "", ...
    'assumed_temperature_K', NaN, ...
    'field_direction', "", ...
    'current_point_count', NaN, ...
    'field_point_count', NaN, ...
    'grid_point_count', NaN, ...
    'observed_row_count', NaN, ...
    'current_min_A', NaN, ...
    'current_max_A', NaN, ...
    'field_min_T', NaN, ...
    'field_max_T', NaN, ...
    'zero_current_available', false, ...
    'zero_field_available', false, ...
    'zero_current_index', NaN, ...
    'zero_field_index', NaN, ...
    'current_axis_monotonic', false, ...
    'field_axis_monotonic', false, ...
    'grid_complete', false, ...
    'axis_lock_status', "");
end

function row = empty_channel_row()
row = struct( ...
    'device', "", ...
    'channel_role', "", ...
    'matrix_column', "", ...
    'measurement_channel', "", ...
    'probe_pair', "", ...
    'dVdI_units', "", ...
    'channel_identity_locked', false, ...
    'finite_fraction', NaN, ...
    'normalization_policy', "", ...
    'channel_status', "");
end

function row = empty_sweep_row()
row = struct('item', "", 'status', "", 'value', "", 'note', "");
end

function value = lookup_provenance(T, item)
idx = string(T.item) == string(item);
if any(idx)
    value = string(T.value(find(idx, 1, 'first')));
else
    value = "";
end
end

function value = lookup_sweep(T, item)
idx = string(T.item) == string(item);
if any(idx)
    value = string(T.value(find(idx, 1, 'first')));
else
    value = "";
end
end

function hash = file_sha256(pathValue)
hash = "unavailable";
if exist(char(pathValue), 'file') ~= 2
    hash = "missing";
    return;
end
quotedPath = shell_quote(pathValue);
[statusCode, textOut] = system(sprintf('shasum -a 256 %s', quotedPath));
if statusCode == 0
    parts = split(string(strtrim(textOut)));
    if ~isempty(parts)
        hash = parts(1);
    end
end
end

function quoted = shell_quote(pathValue)
pathText = char(pathValue);
pathText = strrep(pathText, '"', '\"');
quoted = ['"' pathText '"'];
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
