function out = run_phase18B_bidirectional_data_lock(cfg)
%RUN_PHASE18B_BIDIRECTIONAL_DATA_LOCK Lock bidirectional sweep-rate data.
%
% Phase 18B consumes the clean Phase 18A protocol and audits whether raw
% bidirectional sweep-rate data have been acquired/imported with independent
% up/down branches, physical sweep rates, checksums, channel identity, and
% grid metadata. It deliberately performs no fitting, no model execution, no
% proxy substitution, and no branch averaging.

if ~exist(cfg.outputDir, 'dir')
    mkdir(cfg.outputDir);
end

inputs = load_inputs(cfg);
sourceProvenance = build_source_provenance(cfg);

inputLedgerSchema = build_input_ledger_schema();
inputLedgerTemplate = build_input_ledger_template(cfg, inputs);
[inputLedger, inputStatus] = read_optional_input_ledger(cfg, ...
    inputLedgerSchema);
rawDataLock = build_raw_data_lock(cfg, inputs, inputLedger);
branchCoverage = build_branch_coverage(cfg, rawDataLock);
importIntegrityAudit = build_import_integrity_audit(cfg, inputStatus, ...
    rawDataLock, branchCoverage);
gateSummary = build_gate_summary(cfg, inputs, sourceProvenance, ...
    inputStatus, rawDataLock, branchCoverage, importIntegrityAudit);
handoffStatus = build_handoff_status(cfg, gateSummary, inputStatus, ...
    importIntegrityAudit);

writetable(inputLedgerSchema, cfg.phase18B.inputLedgerSchemaFile);
writetable(inputLedgerTemplate, cfg.phase18B.inputLedgerTemplateFile);
writetable(rawDataLock, cfg.phase18B.rawDataLockFile);
writetable(branchCoverage, cfg.phase18B.branchCoverageFile);
writetable(importIntegrityAudit, cfg.phase18B.importIntegrityAuditFile);
writetable(gateSummary, cfg.phase18B.gateSummaryFile);
writetable(handoffStatus, cfg.phase18B.handoffStatusFile);
writetable(sourceProvenance, cfg.phase18B.sourceProvenanceFile);

try
    h = v800.plot_phase18B_bidirectional_data_lock_summary(cfg, ...
        rawDataLock, branchCoverage, importIntegrityAudit, gateSummary);
catch ME
    warning('v8:phase18BPlotFailed', ...
        'Phase 18B summary plot failed: %s', ME.message);
    h = [];
end

out = struct();
out.config = cfg;
out.inputs = inputs;
out.inputLedgerSchema = inputLedgerSchema;
out.inputLedgerTemplate = inputLedgerTemplate;
out.inputStatus = inputStatus;
out.rawDataLock = rawDataLock;
out.branchCoverage = branchCoverage;
out.importIntegrityAudit = importIntegrityAudit;
out.gateSummary = gateSummary;
out.handoffStatus = handoffStatus;
out.sourceProvenance = sourceProvenance;
out.figure = h;
out.paths = build_paths(cfg);
end

function paths = build_paths(cfg)
paths = struct();
paths.inputLedger = cfg.phase18B.inputLedgerFile;
paths.inputLedgerTemplate = cfg.phase18B.inputLedgerTemplateFile;
paths.inputLedgerSchema = cfg.phase18B.inputLedgerSchemaFile;
paths.rawDataLock = cfg.phase18B.rawDataLockFile;
paths.branchCoverage = cfg.phase18B.branchCoverageFile;
paths.importIntegrityAudit = cfg.phase18B.importIntegrityAuditFile;
paths.gateSummary = cfg.phase18B.gateSummaryFile;
paths.handoffStatus = cfg.phase18B.handoffStatusFile;
paths.sourceProvenance = cfg.phase18B.sourceProvenanceFile;
paths.figurePng = [cfg.phase18B.figureBaseFile '.png'];
paths.figurePdf = [cfg.phase18B.figureBaseFile '.pdf'];
end

function inputs = load_inputs(cfg)
inputs = struct();
inputs.phase18AHandoff = read_required_table(cfg.phase18A.handoffStatusFile);
inputs.phase18AProtocol = read_required_table(cfg.phase18A.protocolFile);
inputs.phase18ASweepRateMatrix = read_required_table( ...
    cfg.phase18A.sweepRateMatrixFile);
inputs.phase18AMetadataSchema = read_required_table( ...
    cfg.phase18A.metadataSchemaFile);
inputs.phase18AAcceptanceCriteria = read_required_table( ...
    cfg.phase18A.acceptanceCriteriaFile);
inputs.phase18ANoFitPolicy = read_required_table(cfg.phase18A.noFitPolicyFile);
end

function T = read_required_table(pathValue)
if exist(pathValue, 'file') ~= 2
    error('Required Phase 18B input is missing: %s', pathValue);
end
T = readtable(pathValue, 'TextType', 'string', ...
    'VariableNamingRule', 'preserve', 'Delimiter', ',');
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
    ];
value = [
    "phase18B_bidirectional_data_lock"
    sourceStatus.commit_sha
    sourceStatus.tree_sha
    string(sourceStatus.tracked_clean)
    string(sourceStatus.untracked_clean)
    string(sourceStatus.tracked_clean && sourceStatus.untracked_clean)
    "raw_data_lock_no_fitting_no_model_execution"
    ];
note = [
    "Raw bidirectional sweep-rate acquisition/import lock."
    "Git commit captured before this runner writes outputs."
    "Git tree captured before output generation."
    "Tracked-source cleanliness before output generation."
    "Untracked-source/artifact cleanliness before output generation."
    "True only when source tree is fully clean before output generation."
    "No branch averaging, proxy substitution, model execution, or fitting."
    ];
provenance = table(item, value, note);
end

function schema = build_input_ledger_schema()
field = [
    "device"
    "raw_file_path"
    "raw_file_sha256"
    "measurement_channel"
    "sweep_rate_tier"
    "sweep_rate_A_per_s"
    "sweep_direction"
    "current_axis_A"
    "temperature_axis_K"
    "zero_current_index"
    "units"
    "matrix_orientation"
    "finite_fraction"
    "duplicate_point_count"
    "missing_point_count"
    "run_id"
    ];
required = [
    true
    true
    false
    true
    true
    true
    true
    true
    true
    true
    true
    true
    false
    false
    false
    true
    ];
accepted_values = [
    "AS001|AS004|AS006"
    "absolute_or_repository_relative_path"
    "hex_sha256_or_blank_to_compute"
    "R1|R2"
    "slow|nominal|fast"
    "positive_numeric_A_per_s"
    "up|down"
    "axis_vector_or_declared_reference"
    "axis_vector_or_declared_temperature_point"
    "positive_integer"
    "A|K|Ohm_or_dVdI_units"
    "current_by_temperature|temperature_by_current"
    "0_to_1"
    "nonnegative_integer"
    "nonnegative_integer"
    "stable_identifier"
    ];
schema = table(field, required, accepted_values);
end

function template = build_input_ledger_template(cfg, inputs)
matrix = inputs.phase18ASweepRateMatrix;
devices = string(matrix.device);
tiers = string(matrix.sweep_rate_tier);
channels = ["R1"; "R2"];
directions = cfg.phase18B.requiredDirections;
n = numel(devices) * numel(channels) * numel(directions);

device = strings(n, 1);
raw_file_path = strings(n, 1);
raw_file_sha256 = strings(n, 1);
measurement_channel = strings(n, 1);
sweep_rate_tier = strings(n, 1);
sweep_rate_A_per_s = NaN(n, 1);
sweep_direction = strings(n, 1);
current_axis_A = strings(n, 1);
temperature_axis_K = strings(n, 1);
zero_current_index = NaN(n, 1);
units = strings(n, 1);
matrix_orientation = strings(n, 1);
finite_fraction = NaN(n, 1);
duplicate_point_count = NaN(n, 1);
missing_point_count = NaN(n, 1);
run_id = strings(n, 1);

idx = 0;
for i = 1:numel(devices)
    for c = 1:numel(channels)
        for d = 1:numel(directions)
            idx = idx + 1;
            device(idx) = devices(i);
            measurement_channel(idx) = channels(c);
            sweep_rate_tier(idx) = tiers(i);
            sweep_direction(idx) = directions(d);
            run_id(idx) = join([device(idx), sweep_rate_tier(idx), ...
                measurement_channel(idx), sweep_direction(idx)], "_");
        end
    end
end

template = table(device, raw_file_path, raw_file_sha256, ...
    measurement_channel, sweep_rate_tier, sweep_rate_A_per_s, ...
    sweep_direction, current_axis_A, temperature_axis_K, ...
    zero_current_index, units, matrix_orientation, finite_fraction, ...
    duplicate_point_count, missing_point_count, run_id);
end

function [ledger, statusTable] = read_optional_input_ledger(cfg, schema)
pathValue = string(cfg.phase18B.inputLedgerFile);
filePresent = exist(char(pathValue), 'file') == 2;
if filePresent
    ledger = readtable(pathValue, 'TextType', 'string', ...
        'VariableNamingRule', 'preserve', 'Delimiter', ',');
else
    ledger = empty_input_ledger();
end

requiredFields = string(schema.field(schema.required));
missingFields = setdiff(requiredFields, string(ledger.Properties.VariableNames));
schemaSatisfied = filePresent && isempty(missingFields);

item = [
    "input_ledger_path"
    "input_ledger_present"
    "input_schema_satisfied"
    "missing_required_fields"
    "input_row_count"
    ];
value = [
    pathValue
    string(filePresent)
    string(schemaSatisfied)
    join(missingFields, "|")
    string(height(ledger))
    ];
note = [
    "Expected user/import-provided Phase 18B raw data ledger."
    "False means acquisition/import has not yet occurred."
    "True only when all required metadata columns are available."
    "Empty when the required input schema is satisfied."
    "Rows are raw run/channel entries, not fitted model cases."
    ];
statusTable = table(item, value, note);
end

function ledger = empty_input_ledger()
ledger = table( ...
    string.empty(0, 1), string.empty(0, 1), string.empty(0, 1), ...
    string.empty(0, 1), string.empty(0, 1), zeros(0, 1), ...
    string.empty(0, 1), string.empty(0, 1), string.empty(0, 1), ...
    zeros(0, 1), string.empty(0, 1), string.empty(0, 1), ...
    zeros(0, 1), zeros(0, 1), zeros(0, 1), string.empty(0, 1), ...
    'VariableNames', {'device', 'raw_file_path', 'raw_file_sha256', ...
    'measurement_channel', 'sweep_rate_tier', 'sweep_rate_A_per_s', ...
    'sweep_direction', 'current_axis_A', 'temperature_axis_K', ...
    'zero_current_index', 'units', 'matrix_orientation', ...
    'finite_fraction', 'duplicate_point_count', 'missing_point_count', ...
    'run_id'});
end

function rawDataLock = build_raw_data_lock(cfg, inputs, ledger)
if height(ledger) == 0
    rawDataLock = build_expected_pending_lock(cfg, inputs);
    return;
end

n = height(ledger);
device = get_string_var(ledger, "device", n);
raw_file_path = get_string_var(ledger, "raw_file_path", n);
measurement_channel = get_string_var(ledger, "measurement_channel", n);
sweep_rate_tier = get_string_var(ledger, "sweep_rate_tier", n);
sweep_direction = lower(get_string_var(ledger, "sweep_direction", n));
sweep_rate_A_per_s = get_numeric_var(ledger, "sweep_rate_A_per_s", n, NaN);
current_axis_A = get_string_var(ledger, "current_axis_A", n);
temperature_axis_K = get_string_var(ledger, "temperature_axis_K", n);
zero_current_index = get_numeric_var(ledger, "zero_current_index", n, NaN);
units = get_string_var(ledger, "units", n);
matrix_orientation = get_string_var(ledger, "matrix_orientation", n);
finite_fraction = get_numeric_var(ledger, "finite_fraction", n, NaN);
duplicate_point_count = get_numeric_var(ledger, "duplicate_point_count", n, NaN);
missing_point_count = get_numeric_var(ledger, "missing_point_count", n, NaN);
raw_file_sha256_declared = get_string_var(ledger, "raw_file_sha256", n);
run_id = get_string_var(ledger, "run_id", n);

raw_file_exists = false(n, 1);
source_sha256 = strings(n, 1);
checksum_matches = false(n, 1);
for k = 1:n
    resolvedPath = resolve_path(cfg, raw_file_path(k));
    raw_file_path(k) = resolvedPath;
    raw_file_exists(k) = exist(char(resolvedPath), 'file') == 2;
    source_sha256(k) = file_sha256(resolvedPath);
    if strlength(strtrim(raw_file_sha256_declared(k))) == 0
        checksum_matches(k) = raw_file_exists(k) && ...
            source_sha256(k) ~= "missing" && source_sha256(k) ~= "unavailable";
    else
        checksum_matches(k) = source_sha256(k) == raw_file_sha256_declared(k);
    end
end

valid_device = ismember(device, cfg.phase18B.requiredDevices);
valid_channel = ismember(measurement_channel, ["R1"; "R2"]);
valid_tier = ismember(sweep_rate_tier, cfg.phase18B.requiredSweepRateTiers);
valid_direction = ismember(sweep_direction, cfg.phase18B.requiredDirections);
actual_sweep_rate_available = isfinite(sweep_rate_A_per_s) & ...
    sweep_rate_A_per_s > 0;
current_axis_available = has_text(current_axis_A);
temperature_metadata_available = has_text(temperature_axis_K);
zero_current_index_available = isfinite(zero_current_index) & ...
    zero_current_index > 0;
units_available = has_text(units);
matrix_orientation_available = has_text(matrix_orientation);
no_branch_averaging_declared = ~contains(sweep_direction, "avg") & ...
    ~contains(sweep_direction, "average") & sweep_direction ~= "up_and_down";
proxy_substitution_used = contains(lower(raw_file_path), "proxy") | ...
    contains(lower(raw_file_path), "synthetic");

row_ok = valid_device & valid_channel & valid_tier & valid_direction & ...
    raw_file_exists & checksum_matches & actual_sweep_rate_available & ...
    current_axis_available & temperature_metadata_available & ...
    zero_current_index_available & units_available & ...
    matrix_orientation_available & no_branch_averaging_declared & ...
    ~proxy_substitution_used;
row_status = strings(n, 1);
row_status(row_ok) = "locked";
row_status(~row_ok) = "incomplete_or_invalid";

ledger_row_present = true(n, 1);
expected_required = true(n, 1);
rawDataLock = table(device, measurement_channel, sweep_rate_tier, ...
    sweep_direction, run_id, expected_required, ledger_row_present, ...
    raw_file_path, raw_file_exists, raw_file_sha256_declared, ...
    source_sha256, checksum_matches, sweep_rate_A_per_s, ...
    current_axis_available, temperature_metadata_available, ...
    zero_current_index_available, units_available, ...
    matrix_orientation_available, finite_fraction, duplicate_point_count, ...
    missing_point_count, no_branch_averaging_declared, ...
    proxy_substitution_used, row_status);
end

function rawDataLock = build_expected_pending_lock(cfg, inputs)
matrix = inputs.phase18ASweepRateMatrix;
devices = string(matrix.device);
tiers = string(matrix.sweep_rate_tier);
channels = ["R1"; "R2"];
directions = cfg.phase18B.requiredDirections;
n = numel(devices) * numel(channels) * numel(directions);

device = strings(n, 1);
measurement_channel = strings(n, 1);
sweep_rate_tier = strings(n, 1);
sweep_direction = strings(n, 1);
run_id = strings(n, 1);
idx = 0;
for i = 1:numel(devices)
    for c = 1:numel(channels)
        for d = 1:numel(directions)
            idx = idx + 1;
            device(idx) = devices(i);
            measurement_channel(idx) = channels(c);
            sweep_rate_tier(idx) = tiers(i);
            sweep_direction(idx) = directions(d);
            run_id(idx) = "pending";
        end
    end
end

expected_required = true(n, 1);
ledger_row_present = false(n, 1);
raw_file_path = repmat("pending_raw_data", n, 1);
raw_file_exists = false(n, 1);
raw_file_sha256_declared = repmat("pending", n, 1);
source_sha256 = repmat("missing", n, 1);
checksum_matches = false(n, 1);
sweep_rate_A_per_s = NaN(n, 1);
current_axis_available = false(n, 1);
temperature_metadata_available = false(n, 1);
zero_current_index_available = false(n, 1);
units_available = false(n, 1);
matrix_orientation_available = false(n, 1);
finite_fraction = NaN(n, 1);
duplicate_point_count = NaN(n, 1);
missing_point_count = NaN(n, 1);
no_branch_averaging_declared = true(n, 1);
proxy_substitution_used = false(n, 1);
row_status = repmat("pending_raw_data", n, 1);

rawDataLock = table(device, measurement_channel, sweep_rate_tier, ...
    sweep_direction, run_id, expected_required, ledger_row_present, ...
    raw_file_path, raw_file_exists, raw_file_sha256_declared, ...
    source_sha256, checksum_matches, sweep_rate_A_per_s, ...
    current_axis_available, temperature_metadata_available, ...
    zero_current_index_available, units_available, ...
    matrix_orientation_available, finite_fraction, duplicate_point_count, ...
    missing_point_count, no_branch_averaging_declared, ...
    proxy_substitution_used, row_status);
end

function coverage = build_branch_coverage(cfg, rawDataLock)
devices = cfg.phase18B.requiredDevices;
tiers = cfg.phase18B.requiredSweepRateTiers;
channels = ["R1"; "R2"];
n = numel(devices) * numel(tiers) * numel(channels);

device = strings(n, 1);
sweep_rate_tier = strings(n, 1);
measurement_channel = strings(n, 1);
up_branch_present = false(n, 1);
down_branch_present = false(n, 1);
both_branches_retained = false(n, 1);
actual_sweep_rates_available = false(n, 1);
row_count = zeros(n, 1);
coverage_status = strings(n, 1);

idx = 0;
for i = 1:numel(devices)
    for j = 1:numel(tiers)
        for c = 1:numel(channels)
            idx = idx + 1;
            device(idx) = devices(i);
            sweep_rate_tier(idx) = tiers(j);
            measurement_channel(idx) = channels(c);
            mask = rawDataLock.device == device(idx) & ...
                rawDataLock.sweep_rate_tier == sweep_rate_tier(idx) & ...
                rawDataLock.measurement_channel == measurement_channel(idx) & ...
                rawDataLock.ledger_row_present;
            row_count(idx) = sum(mask);
            upMask = mask & rawDataLock.sweep_direction == "up";
            downMask = mask & rawDataLock.sweep_direction == "down";
            up_branch_present(idx) = any(upMask);
            down_branch_present(idx) = any(downMask);
            both_branches_retained(idx) = up_branch_present(idx) && ...
                down_branch_present(idx);
            actual_sweep_rates_available(idx) = any(upMask & ...
                isfinite(rawDataLock.sweep_rate_A_per_s)) && any(downMask & ...
                isfinite(rawDataLock.sweep_rate_A_per_s));
            if both_branches_retained(idx) && actual_sweep_rates_available(idx)
                coverage_status(idx) = "complete";
            elseif row_count(idx) == 0
                coverage_status(idx) = "missing";
            else
                coverage_status(idx) = "partial";
            end
        end
    end
end

coverage = table(device, sweep_rate_tier, measurement_channel, ...
    up_branch_present, down_branch_present, both_branches_retained, ...
    actual_sweep_rates_available, row_count, coverage_status);
end

function audit = build_import_integrity_audit(cfg, inputStatus, rawDataLock, ...
    branchCoverage)
ledgerPresent = lookup_status_bool(inputStatus, "input_ledger_present");
schemaSatisfied = lookup_status_bool(inputStatus, "input_schema_satisfied");
rowsPresent = any(rawDataLock.ledger_row_present);
allFilesExist = rowsPresent && all(rawDataLock.raw_file_exists);
allChecksumsLocked = rowsPresent && all(rawDataLock.checksum_matches);
allSweepRates = rowsPresent && all(isfinite(rawDataLock.sweep_rate_A_per_s) & ...
    rawDataLock.sweep_rate_A_per_s > 0);
allDirections = rowsPresent && all(ismember(rawDataLock.sweep_direction, ...
    cfg.phase18B.requiredDirections));
allChannels = rowsPresent && all(ismember(rawDataLock.measurement_channel, ...
    ["R1"; "R2"]));
allTemperature = rowsPresent && all(rawDataLock.temperature_metadata_available);
allUnits = rowsPresent && all(rawDataLock.units_available);
allGrid = rowsPresent && all(rawDataLock.current_axis_available & ...
    rawDataLock.zero_current_index_available & ...
    rawDataLock.matrix_orientation_available);
allBranches = height(branchCoverage) > 0 && ...
    all(branchCoverage.both_branches_retained);
noAverage = all(rawDataLock.no_branch_averaging_declared);
noProxy = ~any(rawDataLock.proxy_substitution_used);

item = [
    "input_ledger_present"
    "input_schema_satisfied"
    "raw_rows_present"
    "raw_files_exist"
    "raw_checksums_locked"
    "actual_sweep_rates_available"
    "up_down_branches_independent"
    "current_direction_unambiguous"
    "R1_R2_identity_explicit"
    "temperature_metadata_available"
    "units_explicit"
    "grid_integrity_metadata_present"
    "no_branch_averaging"
    "no_proxy_substitution"
    "no_fitting"
    "no_model_execution"
    ];
condition = [
    ledgerPresent
    schemaSatisfied
    rowsPresent
    allFilesExist
    allChecksumsLocked
    allSweepRates
    allBranches
    allDirections
    allChannels
    allTemperature
    allUnits
    allGrid
    noAverage
    noProxy
    cfg.phase18B.noFitting
    cfg.phase18B.noModelExecution
    ];
note = [
    "Input ledger is expected before canonical 18B data lock can pass."
    "Ledger carries all required metadata columns."
    "At least one raw run/channel row is present."
    "Every ledger row resolves to an existing raw file."
    "Every row has a computed or matching SHA-256 checksum."
    "Physical sweep rates are numeric and positive."
    "Up and down branches are retained separately for every expected cell."
    "Sweep direction labels are up or down."
    "Measurement channel is explicitly R1 or R2."
    "Temperature metadata or axis reference is available."
    "Units are explicit."
    "Current axis, zero-current index, and matrix orientation are declared."
    "Import preserves branches and does not average them."
    "No synthetic/proxy raw file is used."
    "Phase 18B is a data-lock phase only."
    "No model solver is executed in Phase 18B."
    ];
audit = table(item, condition, note);
end

function gateSummary = build_gate_summary(cfg, inputs, sourceProvenance, ...
    inputStatus, rawDataLock, branchCoverage, importIntegrityAudit)
phase18AClosure = lookup_value(inputs.phase18AHandoff, "phase18A_closure");
sourceClean = lookup_value(sourceProvenance, "source_pre_run_clean") == "true";
ledgerPresent = lookup_status_bool(inputStatus, "input_ledger_present");

gate = strings(13, 1);
condition = false(13, 1);
note = strings(13, 1);

gate(1) = "Phase 18A protocol consumed unchanged";
condition(1) = phase18AClosure == cfg.phase18B.requiredClosure;
note(1) = "Phase 18B must consume the clean 18A protocol freeze.";

gate(2) = "Raw files checksum-locked";
condition(2) = audit_condition(importIntegrityAudit, ...
    "raw_checksums_locked");
note(2) = "Every raw file must have an available or matching SHA-256.";

gate(3) = "Actual sweep rates available";
condition(3) = audit_condition(importIntegrityAudit, ...
    "actual_sweep_rates_available");
note(3) = "Slow/nominal/fast labels must map to physical A/s values.";

gate(4) = "Up/down branches independently retained";
condition(4) = audit_condition(importIntegrityAudit, ...
    "up_down_branches_independent");
note(4) = "No averaging of up and down branches is allowed.";

gate(5) = "Current direction unambiguous";
condition(5) = audit_condition(importIntegrityAudit, ...
    "current_direction_unambiguous");
note(5) = "Rows must use up/down sweep direction labels.";

gate(6) = "Temperature metadata available";
condition(6) = audit_condition(importIntegrityAudit, ...
    "temperature_metadata_available");
note(6) = "Temperature axis or point metadata must be retained.";

gate(7) = "R1/R2 identity explicit";
condition(7) = audit_condition(importIntegrityAudit, ...
    "R1_R2_identity_explicit");
note(7) = "Channels must not be relabeled or collapsed.";

gate(8) = "Units explicit";
condition(8) = audit_condition(importIntegrityAudit, "units_explicit");
note(8) = "Units must be declared before any downstream observable analysis.";

gate(9) = "Grid integrity checked";
condition(9) = audit_condition(importIntegrityAudit, ...
    "grid_integrity_metadata_present");
note(9) = "Current axis, zero index, and orientation must be declared.";

gate(10) = "No branch averaging";
condition(10) = cfg.phase18B.noBranchAveraging && ...
    audit_condition(importIntegrityAudit, "no_branch_averaging");
note(10) = "Branch separation is the point of this phase.";

gate(11) = "No proxy substitution";
condition(11) = cfg.phase18B.noProxySubstitution && ...
    audit_condition(importIntegrityAudit, "no_proxy_substitution");
note(11) = "Synthetic/proxy data cannot satisfy the raw-data lock.";

gate(12) = "No fitting or model execution";
condition(12) = cfg.phase18B.noFitting && cfg.phase18B.noModelExecution;
note(12) = "18B only locks import state; it does not analyze dynamics.";

gate(13) = "Clean provenance";
condition(13) = sourceClean;
note(13) = "Source tree was clean before output generation.";

outcome = repmat("fail", numel(gate), 1);
outcome(condition) = "pass";
dataDependent = 2:9;
if ~ledgerPresent
    outcome(dataDependent) = "not_run";
end

gateSummary = table(gate, outcome, condition, note);

if ~ledgerPresent && any(rawDataLock.ledger_row_present)
    error('Internal Phase 18B error: ledger absent but rows marked present.');
end
if height(branchCoverage) == 0
    error('Internal Phase 18B error: branch coverage table is empty.');
end
end

function handoff = build_handoff_status(cfg, gateSummary, inputStatus, audit)
ledgerPresent = lookup_status_bool(inputStatus, "input_ledger_present");
allPass = all(gateSummary.outcome == "pass");
if allPass
    closure = "pass_bidirectional_sweep_data_lock";
    workflow = "pass";
elseif ~ledgerPresent
    closure = "pending_raw_bidirectional_data";
    workflow = "pending";
else
    closure = "fail_bidirectional_sweep_data_lock";
    workflow = "fail";
end

item = [
    "phase18B_closure"
    "workflow_integrity"
    "phase18A_protocol_consumed"
    "raw_data_status"
    "allowed_devices"
    "required_sweep_tiers"
    "required_sweep_directions"
    "required_channels"
    "actual_sweep_rates_available"
    "up_down_branches_independent"
    "no_branch_averaging"
    "proxy_substitution_used"
    "fitting_performed"
    "model_execution_performed"
    "next_phase"
    ];
value = [
    closure
    workflow
    "pass_bidirectional_sweep_protocol_freeze"
    ternary(ledgerPresent, "input_ledger_present", "future_data_required")
    join(cfg.phase18B.requiredDevices, "|")
    join(cfg.phase18B.requiredSweepRateTiers, "|")
    join(cfg.phase18B.requiredDirections, "|")
    "R1|R2"
    string(audit_condition(audit, "actual_sweep_rates_available"))
    string(audit_condition(audit, "up_down_branches_independent"))
    string(audit_condition(audit, "no_branch_averaging"))
    string(~audit_condition(audit, "no_proxy_substitution"))
    "false"
    "false"
    string(cfg.phase18B.nextPhase)
    ];
handoff = table(item, value);
end

function value = lookup_value(T, itemName)
varNames = string(T.Properties.VariableNames);
keyCandidates = ["item"; "field"; "gate"; "criterion"];
valueCandidates = ["value"; "status"; "outcome"; "condition"];
keyCol = "";
valueCol = "";
for k = 1:numel(keyCandidates)
    if any(varNames == keyCandidates(k))
        keyCol = keyCandidates(k);
        break;
    end
end
for k = 1:numel(valueCandidates)
    if any(varNames == valueCandidates(k))
        valueCol = valueCandidates(k);
        break;
    end
end
if keyCol == "" || valueCol == ""
    error('Could not resolve key/value columns for lookup of %s.', itemName);
end
idx = string(T.(keyCol)) == itemName;
if nnz(idx) ~= 1
    error('Expected exactly one %s row, found %d.', itemName, nnz(idx));
end
value = string(T.(valueCol)(idx));
end

function tf = lookup_status_bool(T, itemName)
tf = lookup_value(T, itemName) == "true";
end

function tf = audit_condition(audit, itemName)
idx = string(audit.item) == itemName;
if nnz(idx) ~= 1
    error('Expected exactly one audit row %s, found %d.', itemName, nnz(idx));
end
tf = logical(audit.condition(idx));
end

function x = get_string_var(T, name, n)
if any(string(T.Properties.VariableNames) == name)
    x = string(T.(name));
else
    x = strings(n, 1);
end
x = reshape(x, [], 1);
end

function x = get_numeric_var(T, name, n, defaultValue)
if any(string(T.Properties.VariableNames) == name)
    x = T.(name);
    if isstring(x) || iscellstr(x) || ischar(x)
        x = str2double(string(x));
    end
else
    x = repmat(defaultValue, n, 1);
end
x = double(reshape(x, [], 1));
end

function tf = has_text(x)
tf = strlength(strtrim(string(x))) > 0 & ...
    ~ismissing(string(x)) & lower(strtrim(string(x))) ~= "missing" & ...
    lower(strtrim(string(x))) ~= "pending";
end

function pathOut = resolve_path(cfg, pathIn)
pathOut = strtrim(string(pathIn));
if strlength(pathOut) == 0
    pathOut = "missing";
    return;
end
if startsWith(pathOut, filesep) || startsWith(pathOut, "~")
    return;
end
pathOut = string(fullfile(cfg.repoRoot, char(pathOut)));
end

function hash = file_sha256(pathValue)
hash = "unavailable";
pathValue = string(pathValue);
if exist(char(pathValue), 'file') ~= 2
    hash = "missing";
    return;
end
quotedPath = ['"' char(pathValue) '"'];
[statusCode, textOut] = system(sprintf('shasum -a 256 %s', quotedPath));
if statusCode == 0
    parts = split(strtrim(string(textOut)));
    if ~isempty(parts)
        hash = parts(1);
    end
end
end

function value = ternary(condition, trueValue, falseValue)
if condition
    value = string(trueValue);
else
    value = string(falseValue);
end
end
