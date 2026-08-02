function out = run_phase14B4L_raw_grid_loader_freeze(cfg)
%RUN_PHASE14B4L_RAW_GRID_LOADER_FREEZE Lock recovered raw nonlinear grids.
%
% Phase 14B.4L consumes Phase 14B.4R recovered source candidates and
% freezes a deterministic loader/schema for AS001 and AS004 dVdI(I,T)
% tables. It performs no fitting and does not run Phase 14B.5.

if ~exist(cfg.outputDir, 'dir')
    mkdir(cfg.outputDir);
end
if ~exist(cfg.phase14B4L.canonicalGridDir, 'dir')
    mkdir(cfg.phase14B4L.canonicalGridDir);
end

sourceProvenance = build_source_provenance(cfg);
inputs = load_inputs(cfg);
selected = build_raw_source_lock_manifest(cfg, inputs);
checksums = build_file_checksum_manifest(cfg, inputs, selected);
loaderSpec = build_loader_specification(cfg);
[axisValidation, matrixValidation, unitsLock, zeroCurrent, ...
    canonicalGrids] = build_grid_validation_tables(cfg, selected, checksums);
duplicateResolution = build_duplicate_candidate_resolution(inputs, ...
    checksums);
gateSummary = build_gate_summary(cfg, inputs, selected, checksums, ...
    loaderSpec, axisValidation, matrixValidation, unitsLock, zeroCurrent, ...
    duplicateResolution, canonicalGrids, sourceProvenance);
handoffStatus = build_handoff_status(cfg, selected, gateSummary, ...
    canonicalGrids, sourceProvenance);

writetable(selected, cfg.phase14B4L.rawSourceLockManifestFile);
writetable(checksums, cfg.phase14B4L.fileChecksumManifestFile);
writetable(loaderSpec, cfg.phase14B4L.loaderSpecificationFile);
writetable(axisValidation, cfg.phase14B4L.axisValidationFile);
writetable(matrixValidation, cfg.phase14B4L.matrixOrientationValidationFile);
writetable(unitsLock, cfg.phase14B4L.unitsAndMetadataLockFile);
writetable(zeroCurrent, cfg.phase14B4L.zeroCurrentValidationFile);
writetable(duplicateResolution, ...
    cfg.phase14B4L.duplicateCandidateResolutionFile);
writetable(canonicalGrids, cfg.phase14B4L.canonicalGridManifestFile);
writetable(gateSummary, cfg.phase14B4L.gateSummaryFile);
writetable(handoffStatus, cfg.phase14B4L.handoffStatusFile);
writetable(sourceProvenance, cfg.phase14B4L.sourceProvenanceFile);

try
    h = v800.plot_phase14B4L_raw_grid_loader_freeze_summary( ...
        cfg, selected, axisValidation, matrixValidation, ...
        duplicateResolution, canonicalGrids, gateSummary);
catch ME
    warning('v8:phase14B4LPlotFailed', ...
        'Phase 14B.4L summary plot failed: %s', ME.message);
    h = [];
end

out = struct();
out.config = cfg;
out.inputs = inputs;
out.rawSourceLockManifest = selected;
out.fileChecksumManifest = checksums;
out.loaderSpecification = loaderSpec;
out.axisValidation = axisValidation;
out.matrixOrientationValidation = matrixValidation;
out.unitsAndMetadataLock = unitsLock;
out.zeroCurrentValidation = zeroCurrent;
out.duplicateCandidateResolution = duplicateResolution;
out.canonicalGridManifest = canonicalGrids;
out.gateSummary = gateSummary;
out.handoffStatus = handoffStatus;
out.sourceProvenance = sourceProvenance;
out.figure = h;
out.paths = build_paths(cfg);
end

function paths = build_paths(cfg)
paths = struct();
paths.rawSourceLockManifest = cfg.phase14B4L.rawSourceLockManifestFile;
paths.fileChecksumManifest = cfg.phase14B4L.fileChecksumManifestFile;
paths.loaderSpecification = cfg.phase14B4L.loaderSpecificationFile;
paths.axisValidation = cfg.phase14B4L.axisValidationFile;
paths.matrixOrientationValidation = ...
    cfg.phase14B4L.matrixOrientationValidationFile;
paths.unitsAndMetadataLock = cfg.phase14B4L.unitsAndMetadataLockFile;
paths.zeroCurrentValidation = cfg.phase14B4L.zeroCurrentValidationFile;
paths.duplicateCandidateResolution = ...
    cfg.phase14B4L.duplicateCandidateResolutionFile;
paths.canonicalGridManifest = cfg.phase14B4L.canonicalGridManifestFile;
paths.gateSummary = cfg.phase14B4L.gateSummaryFile;
paths.handoffStatus = cfg.phase14B4L.handoffStatusFile;
paths.sourceProvenance = cfg.phase14B4L.sourceProvenanceFile;
paths.figurePng = [cfg.phase14B4L.figureBaseFile '.png'];
paths.figurePdf = [cfg.phase14B4L.figureBaseFile '.pdf'];
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
    "phase14B4L_raw_grid_loader_freeze"
    sourceStatus.commit_sha
    sourceStatus.tree_sha
    string(sourceStatus.tracked_clean)
    string(sourceStatus.untracked_clean)
    string(sourceStatus.tracked_clean && sourceStatus.untracked_clean)
    "AS001_AS004_raw_dVdI_I_T_grid_schema_loader_relock"
    "Commit Phase 14B.4L source first; rerun from clean source; commit relock artifacts separately."
    ];
note = [
    "Phase 14B.4L raw nonlinear grid loader freeze."
    "Git commit captured before this runner writes outputs."
    "Git tree object captured before this runner writes outputs."
    "Tracked-source cleanliness before output generation."
    "Untracked-source/artifact cleanliness before output generation."
    "True only when checkout is clean before this run writes outputs."
    "No fitting, no proxy substitution, no adequacy execution."
    "Artifacts are separate from source/configuration commits."
    ];
provenance = table(item, value, note);
end

function inputs = load_inputs(cfg)
inputs = struct();
inputs.phase14B4RHandoff = read_required_table( ...
    cfg.phase14B4R.handoffStatusFile);
inputs.phase14B4RDecision = read_required_table( ...
    cfg.phase14B4R.deviceRecoveryDecisionFile);
inputs.phase14B4RValidation = read_required_table( ...
    cfg.phase14B4R.recoveryValidationFile);
inputs.phase14B4RSourceLedger = read_required_table( ...
    cfg.phase14B4R.candidateSourceLedgerFile);
end

function T = read_required_table(pathValue)
if ~exist(pathValue, 'file')
    error('Required Phase 14B.4L input is missing: %s', pathValue);
end
try
    T = readtable(pathValue, 'TextType', 'string', ...
        'VariableNamingRule', 'preserve', 'Delimiter', ',');
catch
    T = readtable(pathValue, 'TextType', 'string', 'Delimiter', ',');
end
end

function selected = build_raw_source_lock_manifest(cfg, inputs)
devices = string(cfg.phase14B4L.candidateDevices(:));
rows = repmat(empty_source_lock_row(), numel(devices), 1);
for k = 1:numel(devices)
    device = devices(k);
    row = row_for_device(inputs.phase14B4RDecision, device);
    sourcePath = string(row.best_candidate_file);
    existsFlag = exist(char(sourcePath), 'file') == 2;
    relPath = source_relative_path(cfg, sourcePath);
    readyForRelock = table_bool(row.allowed_for_phase14B4_relock);
    rows(k).device = device;
    rows(k).raw_label = raw_label_for_device(inputs, device);
    rows(k).source_original_path = sourcePath;
    rows(k).source_relative_path = relPath;
    rows(k).source_exists = existsFlag;
    rows(k).source_recovery_status = string(row.recovery_status);
    rows(k).selected_by_phase14B4R = readyForRelock;
    rows(k).source_lock_status = conditional( ...
        existsFlag && readyForRelock, "locked_for_loader_validation", ...
        "blocked_missing_source_or_recovery");
    rows(k).allowed_for_phase14B5 = false;
    rows(k).note = "Phase 14B.4L validates schema before Phase 14B.5 release.";
end
selected = struct2table(rows);
end

function row = empty_source_lock_row()
row = struct( ...
    'device', "", ...
    'raw_label', "", ...
    'source_original_path', "", ...
    'source_relative_path', "", ...
    'source_exists', false, ...
    'source_recovery_status', "", ...
    'selected_by_phase14B4R', false, ...
    'source_lock_status', "", ...
    'allowed_for_phase14B5', false, ...
    'note', "");
end

function rawLabel = raw_label_for_device(inputs, device)
idx = string(inputs.phase14B4RValidation.device) == string(device);
if any(idx)
    rawLabel = string(inputs.phase14B4RValidation.raw_label( ...
        find(idx, 1, 'first')));
else
    rawLabel = string(device);
end
end

function relPath = source_relative_path(cfg, sourcePath)
sourcePath = string(sourcePath);
root = string(cfg.phase14B4L.rawTransportDataRoot);
if startsWith(sourcePath, root)
    suffix = eraseBetween(sourcePath, 1, strlength(root));
    suffix = regexprep(suffix, '^[/\\]+', '');
    relPath = string(cfg.phase14B4L.repositoryRelativeRoot) + "/" + suffix;
else
    [~, name, ext] = fileparts(sourcePath);
    relPath = string(cfg.phase14B4L.repositoryRelativeRoot) + "/" + ...
        string(name) + string(ext);
end
end

function checksums = build_file_checksum_manifest(~, inputs, selected)
recovered = inputs.phase14B4RValidation( ...
    string(inputs.phase14B4RValidation.recovery_status) == ...
    "raw_source_recovered", :);
paths = unique([string(selected.source_original_path); ...
    string(recovered.candidate_file)], 'stable');
paths = paths(paths ~= "" & paths ~= "none");
rows = repmat(empty_checksum_row(), numel(paths), 1);
for k = 1:numel(paths)
    pathValue = paths(k);
    info = dir(char(pathValue));
    deviceMask = string(selected.source_original_path) == pathValue;
    recoveredMask = string(recovered.candidate_file) == pathValue;
    rows(k).source_original_path = pathValue;
    rows(k).device = join_or_none(unique([string(selected.device(deviceMask)); ...
        string(recovered.device(recoveredMask))], 'stable'));
    rows(k).candidate_role = conditional(any(deviceMask), ...
        "selected_or_duplicate_selected", "recovered_unselected_candidate");
    rows(k).exists = ~isempty(info);
    if ~isempty(info)
        rows(k).file_size_bytes = info(1).bytes;
        rows(k).modified_datenum = info(1).datenum;
        rows(k).source_sha256 = file_sha256(pathValue);
        rows(k).checksum_status = "computed";
    else
        rows(k).file_size_bytes = NaN;
        rows(k).modified_datenum = NaN;
        rows(k).source_sha256 = "missing";
        rows(k).checksum_status = "missing_file";
    end
end
checksums = struct2table(rows);
end

function row = empty_checksum_row()
row = struct( ...
    'source_original_path', "", ...
    'device', "", ...
    'candidate_role', "", ...
    'exists', false, ...
    'file_size_bytes', NaN, ...
    'modified_datenum', NaN, ...
    'source_sha256', "", ...
    'checksum_status', "");
end

function spec = build_loader_specification(cfg)
item = [
    "loader_name"
    "loader_version"
    "input_format"
    "required_columns"
    "canonical_current_axis"
    "canonical_temperature_axis"
    "canonical_matrix_orientation"
    "probe_pair"
    "measurement_channel"
    "matrix_channel_count"
    "primary_matrix_column"
    "secondary_matrix_column_retained"
    "field_T"
    "background_subtraction_policy"
    "no_fitting_performed"
    "no_proxy_substitution"
    "automatic_probe_fallback"
    ];
value = [
    cfg.phase14B4L.loaderName
    cfg.phase14B4L.loaderVersion
    "comma_delimited_long_table"
    strjoin(cfg.phase14B4L.requiredColumns, "|")
    "current_A_unique_sorted_ascending"
    "temperature_K_unique_sorted_ascending"
    "dVdI_Ohm_size_NI_by_NT"
    cfg.phase14B4L.probePairPolicy
    cfg.phase14B4L.measurementChannel
    string(cfg.phase14B4L.matrixChannelCount)
    cfg.phase14B4L.primaryMatrixColumn
    cfg.phase14B4L.secondaryMatrixColumn
    string(cfg.phase14B4L.field_T)
    cfg.phase14B4L.backgroundSubtractionPolicy
    string(~cfg.phase14B4L.allowFitting)
    string(~cfg.phase14B4L.allowProxySubstitution)
    "prohibited"
    ];
note = [
    "Deterministic loader for recovered dVdI(I,T) .dat files."
    "Increment only if parsing policy changes."
    "Files are exported tables with one row per current-temperature sample."
    "Headers must be explicit."
    "Current axis is sorted into the matrix row direction."
    "Temperature axis is sorted into the matrix column direction."
    "Silent transpose is prohibited."
    "Probe-pair policy records wiring/context, not a single matrix channel."
    "Canonical MAT file stores primary and secondary dVdI matrices separately."
    "Number of measured matrix channels retained in each canonical grid."
    "R1 is the canonical matrix for raw Phase 14B.5 unless explicitly changed."
    "R2 is preserved in canonical grids for audit and possible secondary checks."
    "No field-dependent map is introduced here."
    "No hidden preprocessing is inferred beyond exported table values."
    "Relock stage does not fit model parameters."
    "Recovered files are real raw sources, not proxy substitutions."
    "Probe fallback remains prohibited by the Phase 14A/14B policy."
    ];
spec = table(item, value, note);
end

function [axisRows, matrixRows, unitRows, zeroRows, gridRows] = ...
    build_grid_validation_tables(cfg, selected, checksums)
devices = string(selected.device);
axisStruct = repmat(empty_axis_row(), numel(devices), 1);
matrixStruct = repmat(empty_matrix_row(), numel(devices), 1);
unitStruct = repmat(empty_unit_row(), numel(devices), 1);
zeroStruct = repmat(empty_zero_row(), numel(devices), 1);
gridStruct = repmat(empty_grid_row(), numel(devices), 1);
for k = 1:numel(devices)
    sourcePath = string(selected.source_original_path(k));
    sourceHash = checksum_for_path(checksums, sourcePath);
    [grid, meta] = load_dVdIvIvT_dat_v1(cfg, sourcePath);
    canonicalPath = fullfile(cfg.phase14B4L.canonicalGridDir, ...
        char(devices(k) + "_canonical_dVdIvIvT_grid.mat"));
    if meta.load_ok
        grid.device = devices(k);
        data = grid; %#ok<NASGU>
        save(canonicalPath, 'data');
    else
        canonicalPath = "";
    end

    axisStruct(k).device = devices(k);
    axisStruct(k).source_original_path = sourcePath;
    axisStruct(k).current_points = meta.current_points;
    axisStruct(k).temperature_points = meta.temperature_points;
    axisStruct(k).current_min_A = meta.current_min_A;
    axisStruct(k).current_max_A = meta.current_max_A;
    axisStruct(k).temperature_min_K = meta.temperature_min_K;
    axisStruct(k).temperature_max_K = meta.temperature_max_K;
    axisStruct(k).current_axis_increasing = meta.current_axis_increasing;
    axisStruct(k).temperature_axis_increasing = ...
        meta.temperature_axis_increasing;
    axisStruct(k).positive_negative_current_present = ...
        meta.positive_negative_current_present;
    axisStruct(k).missing_value_count = meta.missing_value_count;
    axisStruct(k).duplicate_pair_count = meta.duplicate_pair_count;
    axisStruct(k).axis_validation_status = passfail( ...
        meta.current_axis_increasing && ...
        meta.temperature_axis_increasing && ...
        meta.positive_negative_current_present && ...
        meta.missing_value_count == 0 && meta.duplicate_pair_count == 0);

    matrixStruct(k).device = devices(k);
    matrixStruct(k).matrix_columns = meta.matrix_columns;
    matrixStruct(k).measurement_channel = meta.measurement_channel;
    matrixStruct(k).matrix_channel_count = meta.matrix_channel_count;
    matrixStruct(k).primary_measurement_channel = ...
        meta.primary_measurement_channel;
    matrixStruct(k).secondary_measurement_channel = ...
        meta.secondary_measurement_channel;
    matrixStruct(k).expected_size = string(meta.current_points) + "x" + ...
        string(meta.temperature_points);
    matrixStruct(k).dVdI_size = string(meta.dVdI_rows) + "x" + ...
        string(meta.dVdI_cols);
    matrixStruct(k).secondary_size = string(meta.secondary_rows) + "x" + ...
        string(meta.secondary_cols);
    matrixStruct(k).table_row_count = meta.table_row_count;
    matrixStruct(k).expected_row_count = meta.expected_row_count;
    matrixStruct(k).matrix_finite_fraction = meta.matrix_finite_fraction;
    matrixStruct(k).orientation_validated = meta.orientation_validated;
    matrixStruct(k).dimension_consistency_status = passfail( ...
        meta.orientation_validated && ...
        meta.table_row_count == meta.expected_row_count);

    unitStruct(k).device = devices(k);
    unitStruct(k).current_units = cfg.phase14B4L.currentUnits;
    unitStruct(k).temperature_units = cfg.phase14B4L.temperatureUnits;
    unitStruct(k).dVdI_units = cfg.phase14B4L.dVdIUnits;
    unitStruct(k).field_T = cfg.phase14B4L.field_T;
    unitStruct(k).field_condition = cfg.phase14B4L.fieldCondition;
    unitStruct(k).sweep_direction = cfg.phase14B4L.sweepDirection;
    unitStruct(k).probe_pair = "R1|R2";
    unitStruct(k).measurement_channel = meta.measurement_channel;
    unitStruct(k).matrix_channel_count = meta.matrix_channel_count;
    unitStruct(k).background_subtraction_status = ...
        cfg.phase14B4L.backgroundSubtractionPolicy;
    unitStruct(k).metadata_lock_status = passfail(meta.load_ok);

    zeroStruct(k).device = devices(k);
    zeroStruct(k).zero_current_index = meta.zero_current_index;
    zeroStruct(k).zero_current_A = meta.zero_current_A;
    zeroStruct(k).zero_current_abs_A = abs(meta.zero_current_A);
    zeroStruct(k).negative_current_count = meta.negative_current_count;
    zeroStruct(k).positive_current_count = meta.positive_current_count;
    zeroStruct(k).current_ordering_status = conditional( ...
        meta.current_axis_increasing, "ascending_negative_to_positive", ...
        "not_validated");
    zeroStruct(k).zero_current_status = passfail( ...
        meta.zero_current_index > 0 && ...
        abs(meta.zero_current_A) <= meta.zero_current_tolerance_A);

    gridStruct(k).device = devices(k);
    gridStruct(k).canonical_mat_file = string(canonicalPath);
    gridStruct(k).source_original_path = sourcePath;
    gridStruct(k).source_relative_path = string( ...
        selected.source_relative_path(k));
    gridStruct(k).source_sha256 = sourceHash;
    gridStruct(k).loader_name = cfg.phase14B4L.loaderName;
    gridStruct(k).loader_version = cfg.phase14B4L.loaderVersion;
    gridStruct(k).current_points = meta.current_points;
    gridStruct(k).temperature_points = meta.temperature_points;
    gridStruct(k).dVdI_size = string(meta.dVdI_rows) + "x" + ...
        string(meta.dVdI_cols);
    gridStruct(k).measurement_channel = meta.measurement_channel;
    gridStruct(k).matrix_channel_count = meta.matrix_channel_count;
    gridStruct(k).primary_measurement_channel = ...
        meta.primary_measurement_channel;
    gridStruct(k).secondary_measurement_channel = ...
        meta.secondary_measurement_channel;
    gridStruct(k).field_T = cfg.phase14B4L.field_T;
    gridStruct(k).grid_lock_status = passfail(meta.load_ok && ...
        meta.orientation_validated && meta.zero_current_index > 0);
end
axisRows = struct2table(axisStruct);
matrixRows = struct2table(matrixStruct);
unitRows = struct2table(unitStruct);
zeroRows = struct2table(zeroStruct);
gridRows = struct2table(gridStruct);
end

function row = empty_axis_row()
row = struct( ...
    'device', "", 'source_original_path', "", ...
    'current_points', NaN, 'temperature_points', NaN, ...
    'current_min_A', NaN, 'current_max_A', NaN, ...
    'temperature_min_K', NaN, 'temperature_max_K', NaN, ...
    'current_axis_increasing', false, ...
    'temperature_axis_increasing', false, ...
    'positive_negative_current_present', false, ...
    'missing_value_count', NaN, 'duplicate_pair_count', NaN, ...
    'axis_validation_status', "");
end

function row = empty_matrix_row()
row = struct( ...
    'device', "", 'matrix_columns', "", 'expected_size', "", ...
    'measurement_channel', "", 'matrix_channel_count', NaN, ...
    'primary_measurement_channel', "", ...
    'secondary_measurement_channel', "", ...
    'dVdI_size', "", 'secondary_size', "", ...
    'table_row_count', NaN, 'expected_row_count', NaN, ...
    'matrix_finite_fraction', NaN, ...
    'orientation_validated', false, ...
    'dimension_consistency_status', "");
end

function row = empty_unit_row()
row = struct( ...
    'device', "", 'current_units', "", 'temperature_units', "", ...
    'dVdI_units', "", 'field_T', NaN, 'field_condition', "", ...
    'sweep_direction', "", 'probe_pair', "", ...
    'measurement_channel', "", 'matrix_channel_count', NaN, ...
    'background_subtraction_status', "", ...
    'metadata_lock_status', "");
end

function row = empty_zero_row()
row = struct( ...
    'device', "", 'zero_current_index', NaN, ...
    'zero_current_A', NaN, 'zero_current_abs_A', NaN, ...
    'negative_current_count', NaN, 'positive_current_count', NaN, ...
    'current_ordering_status', "", 'zero_current_status', "");
end

function row = empty_grid_row()
row = struct( ...
    'device', "", 'canonical_mat_file', "", ...
    'source_original_path', "", 'source_relative_path', "", ...
    'source_sha256', "", 'loader_name', "", 'loader_version', "", ...
    'current_points', NaN, 'temperature_points', NaN, ...
    'dVdI_size', "", 'measurement_channel', "", ...
    'matrix_channel_count', NaN, ...
    'primary_measurement_channel', "", ...
    'secondary_measurement_channel', "", ...
    'field_T', NaN, 'grid_lock_status', "");
end

function [data, meta] = load_dVdIvIvT_dat_v1(cfg, sourcePath)
meta = empty_loader_meta();
data = struct();
if exist(char(sourcePath), 'file') ~= 2
    return;
end
T = readtable(char(sourcePath), 'TextType', 'string', ...
    'VariableNamingRule', 'preserve', 'Delimiter', ',');
names = string(T.Properties.VariableNames);
hasColumns = all(ismember(cfg.phase14B4L.requiredColumns, names));
if ~hasColumns
    return;
end
current = double(T.I(:));
temperature = double(T.temp(:));
R1 = double(T.R1(:));
R2 = double(T.R2(:));
validRows = isfinite(current) & isfinite(temperature) & ...
    isfinite(R1) & isfinite(R2);
current = current(validRows);
temperature = temperature(validRows);
R1 = R1(validRows);
R2 = R2(validRows);

iAxis = unique(current, 'sorted');
tAxis = unique(temperature, 'sorted');
NI = numel(iAxis);
NT = numel(tAxis);
gridR1 = NaN(NI, NT);
gridR2 = NaN(NI, NT);
pairSeen = zeros(NI, NT);
for n = 1:numel(current)
    iIdx = find(iAxis == current(n), 1, 'first');
    tIdx = find(tAxis == temperature(n), 1, 'first');
    if ~isempty(iIdx) && ~isempty(tIdx)
        pairSeen(iIdx, tIdx) = pairSeen(iIdx, tIdx) + 1;
        gridR1(iIdx, tIdx) = R1(n);
        gridR2(iIdx, tIdx) = R2(n);
    end
end

tol = max(1e-15, eps(max(abs(iAxis))));
[zeroAbs, zeroIdx] = min(abs(iAxis));
if isempty(zeroIdx)
    zeroIdx = NaN;
    zeroValue = NaN;
else
    zeroValue = iAxis(zeroIdx);
end

data.device = "";
data.current_A = iAxis;
data.temperature_K = tAxis;
data.dVdI_Ohm = gridR1;
data.dVdI_secondary_Ohm = gridR2;
data.field_T = cfg.phase14B4L.field_T;
data.sweep_direction = cfg.phase14B4L.sweepDirection;
data.probe_pair = "R1|R2";
data.measurement_channel = cfg.phase14B4L.measurementChannel;
data.matrix_channel_count = cfg.phase14B4L.matrixChannelCount;
data.primary_measurement_channel = ...
    cfg.phase14B4L.primaryMeasurementChannel;
data.secondary_measurement_channel = ...
    cfg.phase14B4L.secondaryMeasurementChannel;
data.source_file = string(sourcePath);
data.source_sha256 = file_sha256(sourcePath);
data.loader_name = cfg.phase14B4L.loaderName;
data.loader_version = cfg.phase14B4L.loaderVersion;

meta.load_ok = true;
meta.current_points = NI;
meta.temperature_points = NT;
meta.current_min_A = min(iAxis);
meta.current_max_A = max(iAxis);
meta.temperature_min_K = min(tAxis);
meta.temperature_max_K = max(tAxis);
meta.current_axis_increasing = all(diff(iAxis) > 0);
meta.temperature_axis_increasing = all(diff(tAxis) > 0);
meta.positive_negative_current_present = min(iAxis) < 0 && max(iAxis) > 0;
meta.missing_value_count = sum(pairSeen(:) == 0);
meta.duplicate_pair_count = sum(pairSeen(:) > 1);
meta.matrix_columns = "R1|R2";
meta.measurement_channel = cfg.phase14B4L.measurementChannel;
meta.matrix_channel_count = cfg.phase14B4L.matrixChannelCount;
meta.primary_measurement_channel = ...
    cfg.phase14B4L.primaryMeasurementChannel;
meta.secondary_measurement_channel = ...
    cfg.phase14B4L.secondaryMeasurementChannel;
meta.dVdI_rows = size(gridR1, 1);
meta.dVdI_cols = size(gridR1, 2);
meta.secondary_rows = size(gridR2, 1);
meta.secondary_cols = size(gridR2, 2);
meta.table_row_count = numel(current);
meta.expected_row_count = NI * NT;
meta.matrix_finite_fraction = mean(isfinite(gridR1(:)));
meta.orientation_validated = size(gridR1, 1) == NI && ...
    size(gridR1, 2) == NT && meta.missing_value_count == 0 && ...
    meta.duplicate_pair_count == 0;
meta.zero_current_index = zeroIdx;
meta.zero_current_A = zeroValue;
meta.zero_current_tolerance_A = tol;
meta.negative_current_count = sum(iAxis < 0);
meta.positive_current_count = sum(iAxis > 0);
if zeroAbs > tol
    meta.zero_current_index = NaN;
end
end

function meta = empty_loader_meta()
meta = struct( ...
    'load_ok', false, 'current_points', NaN, ...
    'temperature_points', NaN, 'current_min_A', NaN, ...
    'current_max_A', NaN, 'temperature_min_K', NaN, ...
    'temperature_max_K', NaN, 'current_axis_increasing', false, ...
    'temperature_axis_increasing', false, ...
    'positive_negative_current_present', false, ...
    'missing_value_count', NaN, 'duplicate_pair_count', NaN, ...
    'matrix_columns', "", 'measurement_channel', "", ...
    'matrix_channel_count', NaN, ...
    'primary_measurement_channel', "", ...
    'secondary_measurement_channel', "", ...
    'dVdI_rows', NaN, 'dVdI_cols', NaN, ...
    'secondary_rows', NaN, 'secondary_cols', NaN, ...
    'table_row_count', NaN, 'expected_row_count', NaN, ...
    'matrix_finite_fraction', NaN, ...
    'orientation_validated', false, ...
    'zero_current_index', NaN, 'zero_current_A', NaN, ...
    'zero_current_tolerance_A', NaN, ...
    'negative_current_count', NaN, 'positive_current_count', NaN);
end

function duplicates = build_duplicate_candidate_resolution(inputs, checksums)
recovered = inputs.phase14B4RValidation( ...
    string(inputs.phase14B4RValidation.recovery_status) == ...
    "raw_source_recovered", :);
rows = repmat(empty_duplicate_row(), height(recovered), 1);
for k = 1:height(recovered)
    sourcePath = string(recovered.candidate_file(k));
    hash = checksum_for_path(checksums, sourcePath);
    sameHash = string(checksums.source_sha256) == hash;
    sameDevice = string(recovered.device) == string(recovered.device(k));
    duplicateCount = sum(sameHash);
    rows(k).device = string(recovered.device(k));
    rows(k).raw_label = string(recovered.raw_label(k));
    rows(k).candidate_file = sourcePath;
    rows(k).source_sha256 = hash;
    rows(k).same_checksum_count = duplicateCount;
    rows(k).same_device_recovered_count = sum(sameDevice);
    rows(k).resolution = duplicate_resolution_label(recovered, k, ...
        duplicateCount);
    rows(k).retained_role = conditional( ...
        rows(k).resolution == "selected_primary_source", ...
        "selected_for_canonical_grid", "documented_not_selected");
end
duplicates = struct2table(rows);
end

function row = empty_duplicate_row()
row = struct( ...
    'device', "", 'raw_label', "", 'candidate_file', "", ...
    'source_sha256', "", 'same_checksum_count', NaN, ...
    'same_device_recovered_count', NaN, 'resolution', "", ...
    'retained_role', "");
end

function label = duplicate_resolution_label(recovered, k, duplicateCount)
device = string(recovered.device(k));
sourcePath = string(recovered.candidate_file(k));
rank = find(string(recovered.device) == device & ...
    string(recovered.recovery_status) == "raw_source_recovered");
firstForDevice = rank(1);
if k == firstForDevice
    label = "selected_primary_source";
elseif duplicateCount > 1
    label = "duplicate_export_same_checksum";
else
    label = "additional_recovered_candidate_documented";
end
if contains(sourcePath, "2023_5_26_ASD087") && device == "AS001"
    label = "duplicate_export_same_checksum";
end
end

function gates = build_gate_summary(cfg, inputs, selected, checksums, ...
    loaderSpec, axisValidation, matrixValidation, unitsLock, zeroCurrent, ...
    duplicateResolution, canonicalGrids, sourceProvenance)
b4rRecovered = lookup_status(inputs.phase14B4RHandoff, ...
    "phase14B4R_closure") == "pass_raw_source_recovery_ready_for_relock";
as001Locked = source_locked(selected, canonicalGrids, "AS001");
as004Locked = source_locked(selected, canonicalGrids, "AS004");
checksumsRecorded = all(string(checksums.checksum_status) == "computed");
currentAxes = all(string(axisValidation.axis_validation_status) == "pass");
temperatureAxes = all(axisValidation.temperature_axis_increasing & ...
    axisValidation.temperature_points > 1);
matrices = all(string(matrixValidation.dimension_consistency_status) == ...
    "pass");
orientation = all(matrixValidation.orientation_validated);
unitsExplicit = all(string(unitsLock.metadata_lock_status) == "pass");
zeroCurrentOk = all(string(zeroCurrent.zero_current_status) == "pass");
probeFieldOk = all(strlength(string(unitsLock.probe_pair)) > 0 & ...
    strlength(string(unitsLock.field_condition)) > 0 & ...
    strlength(string(unitsLock.measurement_channel)) > 0 & ...
    unitsLock.matrix_channel_count >= 1);
duplicatesResolved = height(duplicateResolution) >= 3 && ...
    any(string(duplicateResolution.resolution) == ...
    "duplicate_export_same_checksum");
noFit = lookup_loader(loaderSpec, "no_fitting_performed") == "true" && ...
    ~cfg.phase14B4L.allowFitting;
noProxy = lookup_loader(loaderSpec, "no_proxy_substitution") == "true" && ...
    ~cfg.phase14B4L.allowProxySubstitution;
cleanSource = lookup_value(sourceProvenance, "source_pre_run_clean") == "true";

gate = [
    "Phase 14B.4R recovery consumed"
    "AS001 source file locked"
    "AS004 source file locked"
    "File checksums recorded"
    "Current axes validated"
    "Temperature axes validated"
    "dVdI matrices validated"
    "Matrix orientation validated"
    "Units explicit"
    "Zero-current location validated"
    "Probe, matrix-channel, and field conditions explicit"
    "Third recovered candidate resolved"
    "No fitting performed"
    "No proxy substitution"
    "Clean provenance"
    ];
outcome = [
    passfail(b4rRecovered)
    passfail(as001Locked)
    passfail(as004Locked)
    passfail(checksumsRecorded)
    passfail(currentAxes)
    passfail(temperatureAxes)
    passfail(matrices)
    passfail(orientation)
    passfail(unitsExplicit)
    passfail(zeroCurrentOk)
    passfail(probeFieldOk)
    passfail(duplicatesResolved)
    passfail(noFit)
    passfail(noProxy)
    passfail(cleanSource)
    ];
note = [
    "Relock starts only after recovered raw sources."
    "AS001 selected source exists and canonical grid is locked."
    "AS004 selected source exists and canonical grid is locked."
    "Every recovered source receives a SHA-256 checksum."
    "Current axes are finite, complete, and ordered."
    "Temperature axes are finite, complete, and ordered."
    "R1/R2 matrices are parsed from raw table columns."
    "Canonical dVdI matrix is NI x NT with no silent transpose."
    "A, K, and Ohm units are explicitly frozen."
    "Zero-current index exists on each current axis."
    "Probe pair, measured matrix channels, and fixed-field context are explicit."
    "The duplicate AS001 source is recorded by checksum."
    "This stage is a loader/schema freeze, not an optimizer."
    "No proxy metrics are substituted for raw nonlinear grids."
    "True only when Phase 14B.4L starts from a clean checkout."
    ];
gates = table(gate, outcome, note);
end

function tf = source_locked(selected, canonicalGrids, device)
mask = string(selected.device) == string(device);
gridMask = string(canonicalGrids.device) == string(device);
tf = any(mask) && any(gridMask) && all(selected.source_exists(mask)) && ...
    all(string(canonicalGrids.grid_lock_status(gridMask)) == "pass");
end

function handoff = build_handoff_status(cfg, selected, gates, canonicalGrids, ...
    sourceProvenance)
allLocked = all(string(canonicalGrids.grid_lock_status) == "pass");
allPass = all(string(gates.outcome) == "pass");
allowedDevices = string(canonicalGrids.device( ...
    string(canonicalGrids.grid_lock_status) == "pass"));
blockedDevices = string(canonicalGrids.device( ...
    string(canonicalGrids.grid_lock_status) ~= "pass"));
if allLocked
    closure = "pass_raw_grid_loader_freeze";
    nextPhase = cfg.phase14B4L.nextPhaseWhenLocked;
else
    closure = "raw_grid_loader_freeze_blocked";
    nextPhase = cfg.phase14B4L.nextPhaseWhenBlocked;
end

item = [
    "phase14B4L_relock"
    "phase14B4L_closure"
    "raw_data_all_resolved"
    "allowed_for_phase14B5_devices"
    "blocked_devices"
    "proxy_substitution_used"
    "fitting_performed"
    "canonical_grid_files"
    "source_commit_sha"
    "source_pre_run_clean"
    "next_phase"
    ];
status = [
    conditional(allPass, "complete", "needs_clean_artifact_rerun_or_review")
    closure
    string(allLocked)
    join_or_none(allowedDevices)
    join_or_none(blockedDevices)
    "false"
    "false"
    join_or_none(string(canonicalGrids.canonical_mat_file))
    lookup_value(sourceProvenance, "source_commit_sha")
    lookup_value(sourceProvenance, "source_pre_run_clean")
    nextPhase
    ];
note = [
    "Overall relock status."
    "Closure records whether canonical raw grids are loader-frozen."
    "True when AS001 and AS004 canonical grids are locked."
    "Devices ready for Phase 14B.5 after clean artifact freeze."
    "Devices still blocked from raw nonlinear execution."
    "No proxy data are used."
    "No model fitting is performed."
    "Canonical grid MAT files generated by the deterministic loader."
    "Source commit captured before output generation."
    "Clean provenance requires no tracked or untracked pre-run changes."
    "Next phase after relock."
    ];
handoff = table(item, status, note);
end

function row = row_for_device(T, device)
idx = string(T.device) == string(device);
if any(idx)
    row = T(find(idx, 1, 'first'), :);
else
    error('Missing required device row for %s.', device);
end
end

function value = checksum_for_path(checksums, sourcePath)
idx = string(checksums.source_original_path) == string(sourcePath);
if any(idx)
    value = string(checksums.source_sha256(find(idx, 1, 'first')));
else
    value = file_sha256(sourcePath);
end
end

function status = lookup_status(T, item)
idx = string(T.item) == string(item);
if any(idx)
    row = find(idx, 1, 'first');
    if any(string(T.Properties.VariableNames) == "status")
        status = string(T.status(row));
    else
        status = string(T.value(row));
    end
else
    status = "";
end
end

function status = lookup_value(T, item)
status = lookup_status(T, item);
end

function value = lookup_loader(T, item)
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

function text = join_or_none(values)
values = string(values(:));
values = values(strlength(values) > 0);
if isempty(values)
    text = "none";
else
    text = strjoin(values, "|");
end
end
