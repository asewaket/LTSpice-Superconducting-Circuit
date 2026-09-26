function out = run_phase18BR_legacy_bidirectional_recovery_audit(cfg)
%RUN_PHASE18BR_LEGACY_BIDIRECTIONAL_RECOVERY_AUDIT
% Read-only recovery audit for legacy nonlinear transport scan metadata.

if ~exist(cfg.outputDir, 'dir')
    mkdir(cfg.outputDir);
end

paths = phase18BR_paths(cfg);
sourceProvenance = build_source_provenance(cfg);
inputs = load_inputs(paths);

candidateAudit = inputs.candidateAudit;
inputLedger = inputs.inputLedger;
candidateSummary = inputs.candidateSummary;

recoveryManifest = build_recovery_manifest(paths, inputs);
deviceRecoverySummary = build_device_recovery_summary(candidateSummary);
canonicalReadiness = build_canonical_readiness(candidateSummary, inputLedger);
legacyRateContext = build_legacy_rate_context(candidateAudit);
gateSummary = build_gate_summary(candidateAudit, inputLedger, ...
    candidateSummary, recoveryManifest, legacyRateContext);
handoffStatus = build_handoff_status(deviceRecoverySummary, gateSummary);

writetable(recoveryManifest, paths.recoveryManifest);
writetable(deviceRecoverySummary, paths.deviceRecoverySummary);
writetable(candidateAudit, paths.candidateScanAudit);
writetable(canonicalReadiness, paths.canonicalReadiness);
writetable(legacyRateContext, paths.legacyRateContext);
writetable(gateSummary, paths.gateSummary);
writetable(handoffStatus, paths.handoffStatus);
writetable(sourceProvenance, paths.sourceProvenance);

try
    h = plot_summary(paths, deviceRecoverySummary, canonicalReadiness, ...
        legacyRateContext, gateSummary);
catch ME
    warning('v8:phase18BRPlotFailed', ...
        'Phase 18B-R summary plot failed: %s', ME.message);
    h = [];
end

out = struct();
out.config = cfg;
out.inputs = inputs;
out.recoveryManifest = recoveryManifest;
out.deviceRecoverySummary = deviceRecoverySummary;
out.candidateScanAudit = candidateAudit;
out.canonicalReadiness = canonicalReadiness;
out.legacyRateContext = legacyRateContext;
out.gateSummary = gateSummary;
out.handoffStatus = handoffStatus;
out.sourceProvenance = sourceProvenance;
out.figure = h;
out.paths = paths;
end

function paths = phase18BR_paths(cfg)
outputDir = cfg.outputDir;
paths = struct();
paths.outputDir = outputDir;
paths.phase18BInputLedger = fullfile(outputDir, ...
    'phase18B_raw_bidirectional_data_input_ledger.csv');
paths.phase18BCandidateAudit = fullfile(outputDir, ...
    'phase18B_raw_bidirectional_candidate_audit.csv');
paths.phase18BCandidateSummary = fullfile(outputDir, ...
    'phase18B_raw_bidirectional_candidate_summary.csv');
paths.recoveryManifest = fullfile(outputDir, ...
    'phase18BR_legacy_recovery_manifest.csv');
paths.deviceRecoverySummary = fullfile(outputDir, ...
    'phase18BR_device_recovery_summary.csv');
paths.candidateScanAudit = fullfile(outputDir, ...
    'phase18BR_candidate_scan_audit.csv');
paths.canonicalReadiness = fullfile(outputDir, ...
    'phase18BR_canonical_readiness.csv');
paths.legacyRateContext = fullfile(outputDir, ...
    'phase18BR_legacy_rate_context.csv');
paths.gateSummary = fullfile(outputDir, ...
    'phase18BR_gate_summary.csv');
paths.handoffStatus = fullfile(outputDir, ...
    'phase18BR_handoff_status.csv');
paths.sourceProvenance = fullfile(outputDir, ...
    'phase18BR_source_provenance_checkpoint.csv');
paths.figureBase = fullfile(outputDir, ...
    'phase18BR_legacy_recovery_summary');
paths.figurePng = [paths.figureBase '.png'];
paths.figurePdf = [paths.figureBase '.pdf'];
end

function inputs = load_inputs(paths)
inputs = struct();
inputs.candidateAudit = read_required_table(paths.phase18BCandidateAudit);
inputs.inputLedger = read_required_table(paths.phase18BInputLedger);
inputs.candidateSummary = read_required_table(paths.phase18BCandidateSummary);
end

function T = read_required_table(pathValue)
if ~exist(pathValue, 'file')
    error('Required Phase 18B-R input is missing:\n%s', pathValue);
end
T = readtable(pathValue, 'FileType', 'text', 'Delimiter', ',', ...
    'ReadVariableNames', true, 'TextType', 'string', ...
    'VariableNamingRule', 'preserve');
T = repair_auto_header_table(T, pathValue);
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
    "phase18BR_legacy_bidirectional_recovery_audit"
    sourceStatus.commit_sha
    sourceStatus.tree_sha
    string(sourceStatus.tracked_clean)
    string(sourceStatus.untracked_clean)
    string(sourceStatus.tracked_clean && sourceStatus.untracked_clean)
    "legacy_raw_transport_metadata_audit"
    "Commit source first; rerun from clean source; commit generated artifacts separately."
    ];
note = [
    "Read-only recovery audit before canonical Phase 18B."
    "Git commit captured before this runner writes outputs."
    "Git tree captured before this runner writes outputs."
    "Tracked-source cleanliness before output generation."
    "Untracked-source/artifact cleanliness before output generation."
    "True only when tracked and untracked source state are clean before output generation."
    "This phase audits legacy metadata availability and does not execute model fitting."
    "Output artifacts may dirty the checkout after pre-run provenance is captured."
    ];
provenance = table(item, value, note);
end

function manifest = build_recovery_manifest(paths, inputs)
source_name = [
    "phase18B_raw_bidirectional_candidate_audit"
    "phase18B_raw_bidirectional_data_input_ledger"
    "phase18B_raw_bidirectional_candidate_summary"
    ];
path = [
    string(paths.phase18BCandidateAudit)
    string(paths.phase18BInputLedger)
    string(paths.phase18BCandidateSummary)
    ];
exists = arrayfun(@(p) exist(char(p), 'file') == 2, path);
row_count = [
    height(inputs.candidateAudit)
    height(inputs.inputLedger)
    height(inputs.candidateSummary)
    ];
use = [
    "scan-level legacy metadata and checksum evidence"
    "candidate canonical-18B ledger; all current rows remain noncanonical"
    "device-level raw-file and nominal-rate diversity summary"
    ];
status = repmat("consumed_read_only", numel(source_name), 1);
manifest = table(source_name, path, exists, row_count, status, use);
end

function summary = build_device_recovery_summary(candidateSummary)
device = string(table_column(candidateSummary, "device", 1));
raw_file_count_inspected = as_double(table_column(candidateSummary, ...
    "raw_file_count_inspected"));
files_with_inferred_sweep_rate = as_double( ...
    table_column(candidateSummary, "files_with_inferred_sweep_rate"));
min_rate = as_double(table_column(candidateSummary, ...
    "min_inferred_sweep_rate_A_per_s"));
max_rate = as_double(table_column(candidateSummary, ...
    "max_inferred_sweep_rate_A_per_s"));
canonical_bidirectional_files = as_double( ...
    table_column(candidateSummary, "canonical_bidirectional_files"));
rate_diversity_factor = nan(size(min_rate));
valid = min_rate > 0 & max_rate > 0;
rate_diversity_factor(valid) = max_rate(valid) ./ min_rate(valid);
legacy_monotonic_rate_context_available = ...
    files_with_inferred_sweep_rate > 0 & max_rate > 0;
canonical_bidirectional_lock = canonical_bidirectional_files > 0;
branch_history_preserved = false(size(device));
phase18A_future_measurement_required = ~canonical_bidirectional_lock;
strongest_rate_context = rate_diversity_factor == ...
    max(rate_diversity_factor, [], 'omitnan');
recovery_status = strings(size(device));
for k = 1:numel(device)
    if canonical_bidirectional_lock(k)
        recovery_status(k) = "canonical_bidirectional_candidate_available";
    elseif legacy_monotonic_rate_context_available(k)
        recovery_status(k) = "legacy_monotonic_rate_context_only";
    else
        recovery_status(k) = "no_usable_legacy_rate_context";
    end
end
summary = table(device, raw_file_count_inspected, ...
    files_with_inferred_sweep_rate, min_rate, max_rate, ...
    rate_diversity_factor, canonical_bidirectional_files, ...
    canonical_bidirectional_lock, branch_history_preserved, ...
    legacy_monotonic_rate_context_available, strongest_rate_context, ...
    phase18A_future_measurement_required, recovery_status);
end

function readiness = build_canonical_readiness(candidateSummary, inputLedger)
device = string(table_column(candidateSummary, "device", 1));
ledgerDevice = string(table_column(inputLedger, "device", 1));
canonicalUse = table_column(inputLedger, "canonical_18B_use");
upSweep = table_column(inputLedger, "up_sweep_available");
downSweep = table_column(inputLedger, "down_sweep_available");
sweepRate = table_column(inputLedger, "sweep_rate_available");
branchLocked = table_column(inputLedger, "branch_direction_locked");
canonical_files = zeros(size(device));
up_available = false(size(device));
down_available = false(size(device));
sweep_rate_available = false(size(device));
branch_direction_locked = false(size(device));
for k = 1:numel(device)
    rows = ledgerDevice == device(k);
    if any(rows)
        canonical_files(k) = sum(as_logical(canonicalUse(rows)));
        up_available(k) = any(as_logical(upSweep(rows)));
        down_available(k) = any(as_logical(downSweep(rows)));
        sweep_rate_available(k) = any(as_logical(sweepRate(rows)));
        branch_direction_locked(k) = any(as_logical(branchLocked(rows)));
    end
end
canonical_bidirectional_lock = canonical_files > 0;
measured_up_down_branches_available = up_available & down_available;
branch_history_preserved = measured_up_down_branches_available & ...
    branch_direction_locked;
canonical_phase18B_ready = canonical_bidirectional_lock & ...
    branch_history_preserved & sweep_rate_available;
limitation = strings(size(device));
for k = 1:numel(device)
    if canonical_phase18B_ready(k)
        limitation(k) = "none";
    elseif sweep_rate_available(k)
        limitation(k) = "nominal_rate_available_but_down_branch_history_missing";
    else
        limitation(k) = "no_defensible_rate_or_branch_history";
    end
end
readiness = table(device, canonical_files, up_available, down_available, ...
    sweep_rate_available, branch_direction_locked, ...
    measured_up_down_branches_available, branch_history_preserved, ...
    canonical_bidirectional_lock, canonical_phase18B_ready, limitation);
end

function context = build_legacy_rate_context(candidateAudit)
auditDevice = string(table_column(candidateAudit, "device", 1));
devices = unique(auditDevice, 'stable');
auditRates = table_column(candidateAudit, "inferred_abs_sweep_rate_A_per_s");
auditRngMin = table_column(candidateAudit, "programmed_rng_min_V");
auditRngMax = table_column(candidateAudit, "programmed_rng_max_V");
device = strings(0, 1);
raw_file_count = zeros(0, 1);
files_with_nominal_rate = zeros(0, 1);
unique_nominal_rate_count = zeros(0, 1);
min_nominal_rate_A_per_s = zeros(0, 1);
max_nominal_rate_A_per_s = zeros(0, 1);
rate_diversity_factor = zeros(0, 1);
current_range_varies = false(0, 1);
legacy_rate_context_available = false(0, 1);
rate_context_interpretation = strings(0, 1);
for k = 1:numel(devices)
    rows = auditDevice == devices(k);
    rates = as_double(auditRates(rows));
    rates = rates(isfinite(rates) & rates > 0);
    rngMin = as_double(auditRngMin(rows));
    rngMax = as_double(auditRngMax(rows));
    finiteRange = isfinite(rngMin) & isfinite(rngMax);
    uniqueRates = unique(rates);
    device(end + 1, 1) = devices(k); %#ok<AGROW>
    raw_file_count(end + 1, 1) = sum(rows); %#ok<AGROW>
    files_with_nominal_rate(end + 1, 1) = numel(rates); %#ok<AGROW>
    unique_nominal_rate_count(end + 1, 1) = numel(uniqueRates); %#ok<AGROW>
    if isempty(rates)
        min_nominal_rate_A_per_s(end + 1, 1) = NaN; %#ok<AGROW>
        max_nominal_rate_A_per_s(end + 1, 1) = NaN; %#ok<AGROW>
        rate_diversity_factor(end + 1, 1) = NaN; %#ok<AGROW>
    else
        min_nominal_rate_A_per_s(end + 1, 1) = min(rates); %#ok<AGROW>
        max_nominal_rate_A_per_s(end + 1, 1) = max(rates); %#ok<AGROW>
        rate_diversity_factor(end + 1, 1) = max(rates) / min(rates); %#ok<AGROW>
    end
    if any(finiteRange)
        ranges = [rngMin(finiteRange), rngMax(finiteRange)];
        current_range_varies(end + 1, 1) = ...
            size(unique(ranges, 'rows'), 1) > 1; %#ok<AGROW>
    else
        current_range_varies(end + 1, 1) = false; %#ok<AGROW>
    end
    available = numel(uniqueRates) >= 1;
    legacy_rate_context_available(end + 1, 1) = available; %#ok<AGROW>
    if numel(uniqueRates) > 1 && current_range_varies(end)
        interp = "programmed_nominal_rate_diversity_range_confounded";
    elseif numel(uniqueRates) > 1
        interp = "programmed_nominal_rate_diversity_available";
    elseif available
        interp = "single_programmed_nominal_rate_only";
    else
        interp = "no_programmed_nominal_rate_available";
    end
    rate_context_interpretation(end + 1, 1) = interp; %#ok<AGROW>
end
context = table(device, raw_file_count, files_with_nominal_rate, ...
    unique_nominal_rate_count, min_nominal_rate_A_per_s, ...
    max_nominal_rate_A_per_s, rate_diversity_factor, ...
    current_range_varies, legacy_rate_context_available, ...
    rate_context_interpretation);
end

function gates = build_gate_summary(candidateAudit, inputLedger, ...
    candidateSummary, recoveryManifest, legacyRateContext)
hasAudit = height(candidateAudit) > 0;
hasLedger = height(inputLedger) > 0;
hasSummary = height(candidateSummary) > 0;
checksumsRecorded = hasAudit && any(strlength(string( ...
    table_column(candidateAudit, "sha256"))) > 0);
currentConversionRecorded = hasLedger && any(strlength( ...
    string(table_column(inputLedger, "current_conversion"))) > 0);
nominalRatesInferred = hasAudit && any(isfinite(as_double( ...
    table_column(candidateAudit, "inferred_abs_sweep_rate_A_per_s"))));
noModelFitting = true;
noProxySubstitution = true;
canonicalNotClaimed = hasLedger && ~any(as_logical( ...
    table_column(inputLedger, "canonical_18B_use")));
legacyRateAvailable = any(legacyRateContext.legacy_rate_context_available);
futureMeasurementRequired = canonicalNotClaimed;
phase18BRClosure = hasAudit && hasLedger && hasSummary && ...
    checksumsRecorded && currentConversionRecorded && ...
    nominalRatesInferred && noModelFitting && noProxySubstitution && ...
    canonicalNotClaimed && legacyRateAvailable && futureMeasurementRequired;
component = [
    "Candidate raw scan audit consumed"
    "Canonical input ledger consumed"
    "Device summary consumed"
    "Raw file checksums recorded"
    "Programmed current conversion recorded"
    "Nominal sweep rates inferred"
    "No model fitting performed"
    "No proxy substitution used"
    "Canonical bidirectional lock not falsely claimed"
    "Legacy monotonic rate context available"
    "Future bidirectional measurement requirement preserved"
    "Phase 18B-R recovery audit closure"
    ];
pass = [
    hasAudit
    hasLedger
    hasSummary
    checksumsRecorded
    currentConversionRecorded
    nominalRatesInferred
    noModelFitting
    noProxySubstitution
    canonicalNotClaimed
    legacyRateAvailable
    futureMeasurementRequired
    phase18BRClosure
    ];
status = strings(size(pass));
status(pass) = "pass";
status(~pass) = "fail";
note = [
    "Legacy .mat scan audit table is available."
    "Input ledger exists but all rows remain noncanonical for Phase 18B."
    "Device-level legacy-rate summary exists."
    "SHA-256 hashes are recorded for raw scan candidates."
    "Current conversion is explicitly inferred from programmed offset voltage and load resistance."
    "Sweep rates are programmed/nominal values inferred from acquisition settings."
    "This audit does not fit or execute a transport model."
    "Legacy monotonic ramps are not substituted for bidirectional branches."
    "The phase records canonical Phase 18B as pending, not passed."
    "At least one device has usable programmed-rate context."
    "New measured bidirectional data remain required for canonical Phase 18B."
    "Phase 18B-R closes as a recovery audit, not as canonical bidirectional validation."
    ];
gates = table(component, status, pass, note);
gates.manifest_rows_consumed = repmat(height(recoveryManifest), height(gates), 1);
end

function handoff = build_handoff_status(deviceSummary, gateSummary)
strongest = deviceSummary.device(deviceSummary.strongest_rate_context);
if isempty(strongest)
    strongest = "none";
else
    strongest = strjoin(strongest, "|");
end
closurePass = any(gateSummary.component == "Phase 18B-R recovery audit closure" & ...
    gateSummary.status == "pass");
item = [
    "phase18BR_closure"
    "phase18B_status"
    "canonical_bidirectional_lock"
    "measured_up_down_branches_available"
    "branch_history_preserved"
    "proxy_substitution_used"
    "legacy_monotonic_rate_context_available"
    "legacy_rate_diversity_strongest_device"
    "phase18A_future_measurement_required"
    "legacy_only"
    "bidirectional_claim"
    "hysteresis_claim"
    "retrapping_claim"
    "thermal_memory_claim"
    "sweep_rate_source"
    "new_model_fitting"
    "next_phase"
    ];
value = [
    ternary(closurePass, "pass_legacy_recovery_audit", "fail_legacy_recovery_audit")
    "pending_raw_bidirectional_data"
    "false"
    "false"
    "false"
    "false"
    string(any(deviceSummary.legacy_monotonic_rate_context_available))
    strongest
    "true"
    "true"
    "false"
    "false"
    "false"
    "false"
    "programmed_acquisition_metadata"
    "false"
    "phase18CL_legacy_sweep_rate_dependence_analysis"
    ];
note = [
    "Recovery audit closes if legacy files were inspected without falsely promoting them to canonical 18B."
    "Canonical Phase 18B remains pending until measured bidirectional branch data exist."
    "No inspected file preserved both up and down branches as a canonical lock."
    "Only single monotonic programmed ramps were recovered from inspected scan structs."
    "Branch history is not preserved well enough for hysteresis or retrapping claims."
    "Legacy ramps are not used as proxy bidirectional data."
    "Programmed nominal sweep-rate context exists and can support an exploratory legacy analysis."
    "Device with largest programmed-rate diversity in the inspected candidates."
    "The Phase 18A future measurement protocol remains necessary."
    "The next analysis must be explicitly legacy-only."
    "Do not claim bidirectional validation from these legacy files."
    "Do not claim hysteresis from these legacy files."
    "Do not claim retrapping from these legacy files."
    "Do not claim thermal memory from these legacy files."
    "Rates are inferred from programmed acquisition settings, not measured physical dI/dt."
    "No new model fitting may occur in this recovery stage."
    "Recommended bounded follow-up using legacy programmed-rate diversity."
    ];
handoff = table(item, value, note);
end

function h = plot_summary(paths, deviceSummary, canonicalReadiness, ...
    legacyRateContext, gateSummary)
h = figure('Name', 'v9 Phase 18B-R legacy bidirectional recovery audit', ...
    'Color', 'w', 'Position', [100 100 1500 900]);
tiledlayout(2, 3, 'Padding', 'compact', 'TileSpacing', 'compact');

nexttile;
bar(categorical(deviceSummary.device), ...
    deviceSummary.raw_file_count_inspected);
title('legacy files inspected');
ylabel('raw file count');
grid on;
style_light_axes(gca);

nexttile;
bar(categorical(legacyRateContext.device), ...
    legacyRateContext.rate_diversity_factor);
title('programmed-rate diversity');
ylabel('max / min nominal rate');
grid on;
style_light_axes(gca);

nexttile;
imagesc(double([canonicalReadiness.up_available, ...
    canonicalReadiness.down_available, ...
    canonicalReadiness.sweep_rate_available, ...
    canonicalReadiness.branch_history_preserved, ...
    canonicalReadiness.canonical_phase18B_ready]));
colormap(gca, parula);
colorbar;
set(gca, 'XTick', 1:5, 'XTickLabel', {'up', 'down', 'rate', ...
    'history', '18B ready'}, 'YTick', 1:height(canonicalReadiness), ...
    'YTickLabel', cellstr(canonicalReadiness.device));
title('canonical 18B readiness');
style_light_axes(gca);

nexttile;
bar(categorical(legacyRateContext.device), ...
    legacyRateContext.unique_nominal_rate_count);
title('unique nominal rates');
ylabel('count');
grid on;
style_light_axes(gca);

nexttile;
bar(categorical(legacyRateContext.device), ...
    double(legacyRateContext.current_range_varies));
title('rate-range confounding');
ylabel('range varies = 1');
ylim([0 1.2]);
grid on;
style_light_axes(gca);

nexttile;
statuses = categorical(gateSummary.status, {'pass', 'fail', 'not_run'});
cats = categories(statuses);
counts = zeros(numel(cats), 1);
for k = 1:numel(cats)
    counts(k) = sum(statuses == cats{k});
end
bar(categorical(cats), counts);
title('Phase 18B-R gates');
ylabel('gate count');
grid on;
style_light_axes(gca);

sgtitle('Phase 18B-R legacy bidirectional data recovery audit');
exportgraphics(h, paths.figurePng, 'Resolution', 200);
exportgraphics(h, paths.figurePdf, 'ContentType', 'vector');
end

function style_light_axes(ax)
set(ax, 'Color', 'w', 'XColor', 'k', 'YColor', 'k', ...
    'GridColor', [0.75 0.75 0.75], 'MinorGridColor', [0.85 0.85 0.85]);
ax.Title.Color = 'k';
ax.XLabel.Color = 'k';
ax.YLabel.Color = 'k';
cb = findall(ancestor(ax, 'figure'), 'Type', 'ColorBar');
for k = 1:numel(cb)
    cb(k).Color = 'k';
end
end

function x = as_double(value)
if isnumeric(value)
    x = double(value);
elseif iscell(value)
    x = str2double(string(value));
else
    x = str2double(string(value));
end
end

function value = table_column(T, candidateNames, fallbackIndex)
if nargin < 3
    fallbackIndex = [];
end
if isempty(T)
    error('Cannot resolve column from an empty table.');
end
varNames = string(T.Properties.VariableNames);
candidateNames = string(candidateNames);
for k = 1:numel(candidateNames)
    exact = find(varNames == candidateNames(k), 1);
    if ~isempty(exact)
        value = T.(char(varNames(exact)));
        return;
    end
end
normVars = normalize_column_name(varNames);
normCandidates = normalize_column_name(candidateNames);
for k = 1:numel(normCandidates)
    matched = find(normVars == normCandidates(k), 1);
    if ~isempty(matched)
        value = T.(char(varNames(matched)));
        return;
    end
end
if ~isempty(fallbackIndex) && fallbackIndex >= 1 && fallbackIndex <= width(T)
    value = T.(char(varNames(fallbackIndex)));
    return;
end
error('Could not resolve required table column: %s. Present columns: %s', ...
    strjoin(candidateNames, "|"), strjoin(varNames, ", "));
end

function normalized = normalize_column_name(names)
normalized = lower(regexprep(string(names), '[^A-Za-z0-9]', ''));
end

function T = repair_auto_header_table(T, pathValue)
varNames = string(T.Properties.VariableNames);
isAutoName = ~cellfun('isempty', regexp(cellstr(varNames), '^Var\d+$', 'once'));
if ~all(isAutoName)
    return;
end

headerNames = read_csv_header(pathValue);
if numel(headerNames) ~= width(T)
    error('CSV header repair failed for %s: found %d headers for %d table columns.', ...
        pathValue, numel(headerNames), width(T));
end

validNames = matlab.lang.makeValidName(cellstr(headerNames));
validNames = matlab.lang.makeUniqueStrings(validNames);

dropFirstRow = false;
if height(T) > 0
    firstRow = strings(1, width(T));
    for k = 1:width(T)
        firstRow(k) = first_table_value_as_string(T{1, k});
    end
    dropFirstRow = all(normalize_column_name(firstRow) == ...
        normalize_column_name(headerNames));
end

T.Properties.VariableNames = validNames;
if dropFirstRow
    T(1, :) = [];
end
end

function headerNames = read_csv_header(pathValue)
fid = fopen(pathValue, 'r');
if fid < 0
    error('Could not open CSV file for header repair: %s', pathValue);
end
cleanup = onCleanup(@() fclose(fid));
line = fgetl(fid);
if ~ischar(line)
    error('Could not read CSV header from: %s', pathValue);
end
headerNames = string(strsplit(line, ','));
headerNames = strip(headerNames);
if ~isempty(headerNames)
    headerNames(1) = erase(headerNames(1), char(65279));
end
end

function value = first_table_value_as_string(rawValue)
if iscell(rawValue)
    if isempty(rawValue)
        value = "";
    else
        value = string(rawValue{1});
    end
elseif isstring(rawValue)
    if isempty(rawValue)
        value = "";
    else
        value = rawValue(1);
    end
elseif ischar(rawValue)
    value = string(rawValue);
elseif isnumeric(rawValue) || islogical(rawValue)
    if isempty(rawValue)
        value = "";
    else
        value = string(rawValue(1));
    end
else
    value = string(rawValue);
end
end

function x = as_logical(value)
if islogical(value)
    x = value;
elseif isnumeric(value)
    x = value ~= 0;
else
    s = lower(strtrim(string(value)));
    x = s == "true" | s == "1" | s == "yes" | s == "pass";
end
end

function value = ternary(condition, trueValue, falseValue)
if condition
    value = string(trueValue);
else
    value = string(falseValue);
end
end
