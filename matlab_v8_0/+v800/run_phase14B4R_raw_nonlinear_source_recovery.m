function out = run_phase14B4R_raw_nonlinear_source_recovery(cfg)
%RUN_PHASE14B4R_RAW_NONLINEAR_SOURCE_RECOVERY Locate raw nonlinear sources.
%
% Phase 14B.4R is a no-fit recovery audit. It searches documented raw-data
% locations for AS001/AS004 dVdI(I,T) numerical grids and records whether
% the candidates satisfy the metadata needed to rerun Phase 14B.4.

if ~exist(cfg.outputDir, 'dir')
    mkdir(cfg.outputDir);
end

sourceProvenance = build_source_provenance(cfg);
inputs = load_inputs(cfg);
candidateLedger = build_candidate_source_ledger(cfg);
recoveryValidation = build_recovery_validation(cfg, candidateLedger);
deviceDecision = build_device_recovery_decision(cfg, inputs, ...
    recoveryValidation);
gateSummary = build_gate_summary(cfg, inputs, candidateLedger, ...
    recoveryValidation, deviceDecision, sourceProvenance);
handoffStatus = build_handoff_status(cfg, deviceDecision, gateSummary, ...
    sourceProvenance);

writetable(candidateLedger, cfg.phase14B4R.candidateSourceLedgerFile);
writetable(recoveryValidation, cfg.phase14B4R.recoveryValidationFile);
writetable(deviceDecision, cfg.phase14B4R.deviceRecoveryDecisionFile);
writetable(gateSummary, cfg.phase14B4R.gateSummaryFile);
writetable(handoffStatus, cfg.phase14B4R.handoffStatusFile);
writetable(sourceProvenance, cfg.phase14B4R.sourceProvenanceFile);

try
    h = v800.plot_phase14B4R_raw_nonlinear_source_recovery_summary( ...
        cfg, candidateLedger, recoveryValidation, deviceDecision, ...
        gateSummary);
catch ME
    warning('v8:phase14B4RPlotFailed', ...
        'Phase 14B.4R summary plot failed: %s', ME.message);
    h = [];
end

out = struct();
out.config = cfg;
out.inputs = inputs;
out.candidateSourceLedger = candidateLedger;
out.recoveryValidation = recoveryValidation;
out.deviceRecoveryDecision = deviceDecision;
out.gateSummary = gateSummary;
out.handoffStatus = handoffStatus;
out.sourceProvenance = sourceProvenance;
out.figure = h;
out.paths = build_paths(cfg);
end

function paths = build_paths(cfg)
paths = struct();
paths.candidateSourceLedger = cfg.phase14B4R.candidateSourceLedgerFile;
paths.recoveryValidation = cfg.phase14B4R.recoveryValidationFile;
paths.deviceRecoveryDecision = cfg.phase14B4R.deviceRecoveryDecisionFile;
paths.gateSummary = cfg.phase14B4R.gateSummaryFile;
paths.handoffStatus = cfg.phase14B4R.handoffStatusFile;
paths.sourceProvenance = cfg.phase14B4R.sourceProvenanceFile;
paths.figurePng = [cfg.phase14B4R.figureBaseFile '.png'];
paths.figurePdf = [cfg.phase14B4R.figureBaseFile '.pdf'];
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
    "phase14B4R_raw_nonlinear_source_recovery"
    sourceStatus.commit_sha
    sourceStatus.tree_sha
    string(sourceStatus.tracked_clean)
    string(sourceStatus.untracked_clean)
    string(sourceStatus.tracked_clean && sourceStatus.untracked_clean)
    "AS001_AS004_raw_source_recovery_no_model_changes"
    "Commit source first; rerun from clean source; commit recovery artifacts separately."
    ];
note = [
    "Phase 14B.4R raw nonlinear source-recovery audit."
    "Git commit captured before this runner writes outputs."
    "Git tree object captured before this runner writes outputs."
    "Tracked-source cleanliness before output generation."
    "Untracked-source/artifact cleanliness before output generation."
    "True only when checkout is clean before this run writes outputs."
    "No fitting, no model retuning, no proxy substitution."
    "Artifacts are separate from source/configuration commits."
    ];
provenance = table(item, value, note);
end

function inputs = load_inputs(cfg)
inputs = struct();
inputs.phase14B4Ledger = read_required_table( ...
    cfg.phase14B4.rawDataLedgerFile);
inputs.phase14B4Decision = read_required_table( ...
    cfg.phase14B4.resolutionDecisionFile);
inputs.phase14B4Handoff = read_required_table( ...
    cfg.phase14B4.handoffStatusFile);
end

function T = read_required_table(pathValue)
if ~exist(pathValue, 'file')
    error('Required Phase 14B.4R input is missing: %s', pathValue);
end
try
    T = readtable(pathValue, 'TextType', 'string', ...
        'VariableNamingRule', 'preserve', 'Delimiter', ',');
catch
    T = readtable(pathValue, 'TextType', 'string', 'Delimiter', ',');
end
end

function ledger = build_candidate_source_ledger(cfg)
devices = string(cfg.phase14B4R.candidateDevices(:));
rows = empty_candidate_row();
rows(1) = [];
for d = 1:numel(devices)
    device = devices(d);
    rawLabel = raw_label_for_device(cfg, device);
    candidates = find_candidates_for_device(cfg, rawLabel);
    if isempty(candidates)
        row = empty_candidate_row();
        row.device = device;
        row.raw_label = rawLabel;
        row.candidate_file = "none";
        row.file_exists = false;
        row.file_type = "none";
        row.search_rank = NaN;
        row.discovery_basis = "no_candidate_found";
        row.figure_only = false;
        row.note = "No candidate numerical dVdI(I,T) source found.";
        rows(end + 1) = row; %#ok<AGROW>
        continue;
    end
    for k = 1:numel(candidates)
        row = empty_candidate_row();
        row.device = device;
        row.raw_label = rawLabel;
        row.candidate_file = string(candidates(k).path);
        row.file_exists = true;
        row.file_type = string(candidates(k).extension);
        row.search_rank = k;
        row.discovery_basis = string(candidates(k).basis);
        row.figure_only = is_figure_file(candidates(k).path);
        row.note = "Candidate found by raw-label pattern search.";
        rows(end + 1) = row; %#ok<AGROW>
    end
end
ledger = struct2table(rows);
end

function row = empty_candidate_row()
row = struct( ...
    'device', "", ...
    'raw_label', "", ...
    'candidate_file', "", ...
    'file_exists', false, ...
    'file_type', "", ...
    'search_rank', NaN, ...
    'discovery_basis', "", ...
    'figure_only', false, ...
    'note', "");
end

function rawLabel = raw_label_for_device(cfg, device)
idx = string(cfg.phase14B4R.deviceRawLabels.device) == string(device);
if any(idx)
    rawLabel = string(cfg.phase14B4R.deviceRawLabels.raw_label( ...
        find(idx, 1, 'first')));
else
    rawLabel = string(device);
end
end

function candidates = find_candidates_for_device(cfg, rawLabel)
candidates = struct('path', {}, 'extension', {}, 'basis', {});
patterns = [
    string(cfg.phase14B4R.preferredPatterns(:))
    string(cfg.phase14B4R.secondaryPatterns(:))
    ];
seen = strings(0, 1);
for r = 1:numel(cfg.phase14B4R.searchRoots)
    root = char(cfg.phase14B4R.searchRoots(r));
    if ~exist(root, 'dir')
        continue;
    end
    for p = 1:numel(patterns)
        pattern = sprintf(char(patterns(p)), char(rawLabel));
        matches = dir(fullfile(root, "**", pattern));
        matches = matches(~[matches.isdir]);
        for m = 1:numel(matches)
            filePath = string(fullfile(matches(m).folder, matches(m).name));
            if any(seen == filePath)
                continue;
            end
            seen(end + 1, 1) = filePath; %#ok<AGROW>
            [~, ~, ext] = fileparts(filePath);
            item = struct();
            item.path = filePath;
            item.extension = lower(string(ext));
            item.basis = "pattern:" + string(pattern);
            candidates(end + 1) = item; %#ok<AGROW>
        end
    end
end
end

function tf = is_figure_file(pathValue)
[~, ~, ext] = fileparts(string(pathValue));
tf = ismember(lower(string(ext)), [".png"; ".jpg"; ".jpeg"; ".pdf"; ".fig"]);
end

function validation = build_recovery_validation(cfg, candidateLedger)
rows = repmat(empty_validation_row(), height(candidateLedger), 1);
for k = 1:height(candidateLedger)
    row = candidateLedger(k, :);
    rows(k).device = string(row.device);
    rows(k).raw_label = string(row.raw_label);
    rows(k).candidate_file = string(row.candidate_file);
    rows(k).file_type = string(row.file_type);
    rows(k).raw_file_resolved = row.file_exists && ~row.figure_only;
    rows(k).figure_only = row.figure_only;
    [metadata, summary] = inspect_candidate_file(cfg, row);
    rows(k).raw_variable_or_sheet_resolved = metadata.variableResolved;
    rows(k).current_axis_resolved = metadata.currentAxisResolved;
    rows(k).temperature_axis_resolved = metadata.temperatureAxisResolved;
    rows(k).dVdI_matrix_resolved = metadata.matrixResolved;
    rows(k).matrix_orientation_validated = metadata.orientationValidated;
    rows(k).units_resolved = metadata.unitsResolved;
    rows(k).zero_current_identifiable = metadata.zeroCurrentIdentifiable;
    rows(k).field_condition_resolved = metadata.fieldConditionResolved;
    rows(k).probe_identity_resolved = metadata.probeIdentityResolved;
    rows(k).current_units = metadata.currentUnits;
    rows(k).temperature_units = metadata.temperatureUnits;
    rows(k).dVdI_units = metadata.dVdIUnits;
    rows(k).matrix_columns = metadata.matrixColumns;
    rows(k).current_points = metadata.currentPoints;
    rows(k).temperature_points = metadata.temperaturePoints;
    rows(k).validation_score = recovery_score(rows(k));
    rows(k).recovery_status = recovery_status(rows(k));
    rows(k).inspection_summary = summary;
end
validation = struct2table(rows);
end

function row = empty_validation_row()
row = struct( ...
    'device', "", ...
    'raw_label', "", ...
    'candidate_file', "", ...
    'file_type', "", ...
    'raw_file_resolved', false, ...
    'raw_variable_or_sheet_resolved', false, ...
    'current_axis_resolved', false, ...
    'temperature_axis_resolved', false, ...
    'dVdI_matrix_resolved', false, ...
    'matrix_orientation_validated', false, ...
    'units_resolved', false, ...
    'zero_current_identifiable', false, ...
    'field_condition_resolved', false, ...
    'probe_identity_resolved', false, ...
    'figure_only', false, ...
    'current_units', "", ...
    'temperature_units', "", ...
    'dVdI_units', "", ...
    'matrix_columns', "", ...
    'current_points', NaN, ...
    'temperature_points', NaN, ...
    'validation_score', NaN, ...
    'recovery_status', "", ...
    'inspection_summary', "");
end

function [metadata, summary] = inspect_candidate_file(cfg, row)
metadata = empty_metadata();
summary = "not_inspected";
filePath = string(row.candidate_file);
if filePath == "none" || ~exist(char(filePath), 'file') || row.figure_only
    summary = "no_numeric_candidate";
    return;
end

[~, ~, ext] = fileparts(filePath);
ext = lower(string(ext));
try
    if ismember(ext, [".dat"; ".csv"; ".txt"])
        T = readtable(char(filePath), 'TextType', 'string', ...
            'VariableNamingRule', 'preserve', 'Delimiter', ',');
        names = string(T.Properties.VariableNames);
        lowerNames = lower(names);
        currentColumn = find_first_column(lowerNames, ...
            lower(string(cfg.phase14B4R.acceptedCurrentColumns)));
        temperatureColumn = find_first_column(lowerNames, ...
            lower(string(cfg.phase14B4R.acceptedTemperatureColumns)));
        matrixMask = false(size(names));
        acceptedMatrix = lower(string(cfg.phase14B4R.acceptedMatrixColumns));
        for a = 1:numel(acceptedMatrix)
            matrixMask = matrixMask | lowerNames == acceptedMatrix(a);
        end
        if ~any(matrixMask)
            matrixMask = startsWith(lowerNames, "r") & ...
                ~ismember(lowerNames, ["run"; "row"]);
        end
        metadata.variableResolved = true;
        metadata.currentAxisResolved = currentColumn > 0;
        metadata.temperatureAxisResolved = temperatureColumn > 0;
        metadata.matrixResolved = any(matrixMask);
        metadata.matrixColumns = strjoin(names(matrixMask), "|");
        if currentColumn > 0
            current = T.(char(names(currentColumn)));
            current = double(current(:));
            current = current(isfinite(current));
            metadata.currentPoints = numel(unique(current));
            if ~isempty(current)
                metadata.zeroCurrentIdentifiable = any(abs(current) <= ...
                    max(1e-15, eps(max(abs(current))))) || ...
                    (min(current) < 0 && max(current) > 0);
            end
        end
        if temperatureColumn > 0
            temp = T.(char(names(temperatureColumn)));
            temp = double(temp(:));
            temp = temp(isfinite(temp));
            metadata.temperaturePoints = numel(unique(temp));
        end
        metadata.orientationValidated = metadata.currentAxisResolved && ...
            metadata.temperatureAxisResolved && metadata.matrixResolved && ...
            metadata.currentPoints > 1 && metadata.temperaturePoints > 1;
        metadata.unitsResolved = metadata.currentAxisResolved && ...
            metadata.temperatureAxisResolved && metadata.matrixResolved && ...
            contains(lower(filePath), "dvd");
        metadata.currentUnits = conditional(metadata.currentAxisResolved, ...
            "A_inferred_from_I_column_and_legacy_loader", "unresolved");
        metadata.temperatureUnits = conditional(metadata.temperatureAxisResolved, ...
            "K_inferred_from_temp_column_and_legacy_loader", "unresolved");
        metadata.dVdIUnits = conditional(metadata.matrixResolved, ...
            "Ohm_inferred_from_R_columns_and_legacy_loader", "unresolved");
        metadata.fieldConditionResolved = contains(lower(filePath), "ivivt");
        metadata.probeIdentityResolved = metadata.matrixResolved;
        summary = sprintf('table columns: %s', strjoin(names, '|'));
    elseif ext == ".mat"
        info = whos('-file', char(filePath));
        names = string({info.name});
        lowerNames = lower(names);
        metadata.variableResolved = ~isempty(names);
        metadata.currentAxisResolved = any(contains(lowerNames, "i")) || ...
            any(contains(lowerNames, "current"));
        metadata.temperatureAxisResolved = any(contains(lowerNames, "t")) || ...
            any(contains(lowerNames, "temp"));
        metadata.matrixResolved = any(contains(lowerNames, "dvdi")) || ...
            any(contains(lowerNames, "r"));
        metadata.matrixColumns = strjoin(names, "|");
        metadata.orientationValidated = metadata.currentAxisResolved && ...
            metadata.temperatureAxisResolved && metadata.matrixResolved;
        metadata.unitsResolved = false;
        metadata.currentUnits = "unresolved_mat_requires_loader";
        metadata.temperatureUnits = "unresolved_mat_requires_loader";
        metadata.dVdIUnits = "unresolved_mat_requires_loader";
        metadata.zeroCurrentIdentifiable = false;
        metadata.fieldConditionResolved = contains(lower(filePath), "ivivt");
        metadata.probeIdentityResolved = metadata.matrixResolved;
        summary = sprintf('MAT variables: %s', strjoin(names, '|'));
    else
        summary = "unsupported_numeric_extension";
    end
catch ME
    summary = "inspection_failed:" + string(ME.message);
end
end

function metadata = empty_metadata()
metadata = struct( ...
    'variableResolved', false, ...
    'currentAxisResolved', false, ...
    'temperatureAxisResolved', false, ...
    'matrixResolved', false, ...
    'orientationValidated', false, ...
    'unitsResolved', false, ...
    'zeroCurrentIdentifiable', false, ...
    'fieldConditionResolved', false, ...
    'probeIdentityResolved', false, ...
    'currentUnits', "unresolved", ...
    'temperatureUnits', "unresolved", ...
    'dVdIUnits', "unresolved", ...
    'matrixColumns', "", ...
    'currentPoints', NaN, ...
    'temperaturePoints', NaN);
end

function idx = find_first_column(lowerNames, candidates)
idx = 0;
for k = 1:numel(candidates)
    match = find(lowerNames == candidates(k), 1, 'first');
    if ~isempty(match)
        idx = match;
        return;
    end
end
end

function score = recovery_score(row)
fields = [
    "raw_file_resolved"
    "raw_variable_or_sheet_resolved"
    "current_axis_resolved"
    "temperature_axis_resolved"
    "dVdI_matrix_resolved"
    "matrix_orientation_validated"
    "units_resolved"
    "zero_current_identifiable"
    "field_condition_resolved"
    "probe_identity_resolved"
    ];
score = 0;
for k = 1:numel(fields)
    score = score + double(row.(char(fields(k))));
end
end

function status = recovery_status(row)
if row.figure_only
    status = "figure_only_not_accepted";
elseif row.validation_score >= 10
    status = "raw_source_recovered";
elseif row.validation_score >= 6
    status = "candidate_requires_manual_lock_review";
elseif row.raw_file_resolved
    status = "weak_candidate_found";
else
    status = "not_recovered";
end
end

function decisions = build_device_recovery_decision(cfg, inputs, validation)
devices = string(cfg.phase14B4R.candidateDevices(:));
rows = repmat(empty_decision_row(), numel(devices), 1);
for d = 1:numel(devices)
    device = devices(d);
    mask = string(validation.device) == device;
    V = validation(mask, :);
    if height(V) == 0
        bestIdx = [];
    else
        [~, localIdx] = max(V.validation_score);
        bestIdx = find(mask);
        bestIdx = bestIdx(localIdx);
    end
    rows(d).device = device;
    rows(d).previous_phase14B4_status = previous_status(inputs, device);
    if isempty(bestIdx)
        rows(d).best_candidate_file = "none";
        rows(d).best_validation_score = 0;
        rows(d).recovery_status = "not_recovered";
        rows(d).allowed_for_phase14B4_relock = false;
    else
        rows(d).best_candidate_file = string(validation.candidate_file(bestIdx));
        rows(d).best_validation_score = validation.validation_score(bestIdx);
        rows(d).recovery_status = string(validation.recovery_status(bestIdx));
        rows(d).allowed_for_phase14B4_relock = ...
            string(validation.recovery_status(bestIdx)) == ...
            "raw_source_recovered";
    end
    rows(d).allowed_for_phase14B5 = false;
    rows(d).decision = conditional(rows(d).allowed_for_phase14B4_relock, ...
        "candidate_ready_for_phase14B4_source_lock_review", ...
        "raw_source_not_locked_do_not_run_phase14B5");
    rows(d).next_action = conditional(rows(d).allowed_for_phase14B4_relock, ...
        cfg.phase14B4R.nextPhaseWhenRecovered, ...
        "continue_manual_raw_source_search_or_close_phase14D_insufficient_data");
end
decisions = struct2table(rows);
end

function row = empty_decision_row()
row = struct( ...
    'device', "", ...
    'previous_phase14B4_status', "", ...
    'best_candidate_file', "", ...
    'best_validation_score', NaN, ...
    'recovery_status', "", ...
    'allowed_for_phase14B4_relock', false, ...
    'allowed_for_phase14B5', false, ...
    'decision', "", ...
    'next_action', "");
end

function status = previous_status(inputs, device)
idx = string(inputs.phase14B4Decision.device) == string(device);
if any(idx)
    status = string(inputs.phase14B4Decision.raw_data_status( ...
        find(idx, 1, 'first')));
else
    status = "missing_phase14B4_decision";
end
end

function gates = build_gate_summary(cfg, inputs, candidateLedger, ...
    recoveryValidation, deviceDecision, sourceProvenance)
b4Allowed = table_bool(inputs.phase14B4Decision.allowed_for_phase14B5);
b4BlockedConsumed = all(~b4Allowed);
mappingExplicit = height(cfg.phase14B4R.deviceRawLabels) >= ...
    numel(cfg.phase14B4R.candidateDevices);
candidateSearchDone = height(candidateLedger) >= ...
    numel(cfg.phase14B4R.candidateDevices);
numericCandidatesOnly = all(~candidateLedger.figure_only | ...
    ~cfg.phase14B4R.figureOnlyAccepted);
validationDone = height(recoveryValidation) == height(candidateLedger);
decisionsRecorded = height(deviceDecision) == ...
    numel(cfg.phase14B4R.candidateDevices);
noPhase14B5Release = all(~deviceDecision.allowed_for_phase14B5);
noModelChange = ~cfg.phase14B4R.allowModelChanges && ...
    ~cfg.phase14B4R.allowFitting && ~cfg.phase14B4R.allowProxySubstitution;
partialRecoveryAllowed = any(deviceDecision.allowed_for_phase14B4_relock) || ...
    all(~deviceDecision.allowed_for_phase14B4_relock);
cleanSource = lookup_value(sourceProvenance, "source_pre_run_clean") == "true";

gate = [
    "Phase 14B.4 blocked-data result consumed"
    "AS-to-raw device mapping explicit"
    "Candidate source search completed"
    "Figure-only sources not accepted"
    "Candidate validation completed"
    "Device recovery decisions recorded"
    "No direct Phase 14B.5 release"
    "No model changes or fitting"
    "Partial recovery policy preserved"
    "Clean provenance"
    ];
outcome = [
    passfail(b4BlockedConsumed)
    passfail(mappingExplicit)
    passfail(candidateSearchDone)
    passfail(numericCandidatesOnly)
    passfail(validationDone)
    passfail(decisionsRecorded)
    passfail(noPhase14B5Release)
    passfail(noModelChange)
    passfail(partialRecoveryAllowed)
    passfail(cleanSource)
    ];
note = [
    "Recovery starts from the prior raw-ingestion block."
    "AS001->ASD088 and AS004->ASD087 are recorded from legacy documentation."
    "Search roots and filename patterns are recorded in configuration."
    "Map images or PDFs cannot substitute for numerical grids."
    "Each candidate receives axis/matrix/unit/probe checks."
    "Each device receives a best-candidate recovery decision."
    "Recovered sources must be relocked by Phase 14B.4 before Phase 14B.5."
    "No optimizer or model parameter is touched."
    "Single-device recovery can be carried forward explicitly."
    "True only when Phase 14B.4R starts from a clean checkout."
    ];
gates = table(gate, outcome, note);
end

function handoff = build_handoff_status(cfg, deviceDecision, gates, ...
    sourceProvenance)
recoveredDevices = string(deviceDecision.device( ...
    deviceDecision.allowed_for_phase14B4_relock));
blockedDevices = string(deviceDecision.device( ...
    ~deviceDecision.allowed_for_phase14B4_relock));
allRecovered = all(deviceDecision.allowed_for_phase14B4_relock);
anyRecovered = any(deviceDecision.allowed_for_phase14B4_relock);
allPass = all(string(gates.outcome) == "pass");
if allRecovered
    closure = "pass_raw_source_recovery_ready_for_relock";
    nextPhase = cfg.phase14B4R.nextPhaseWhenRecovered;
elseif anyRecovered
    closure = "partial_raw_source_recovery_ready_for_scoped_relock";
    nextPhase = "phase14B4_scoped_relock_or_continue_recovery";
else
    closure = "raw_source_recovery_not_complete";
    nextPhase = cfg.phase14B4R.nextPhaseWhenNotRecovered;
end

item = [
    "phase14B4R_recovery"
    "phase14B4R_closure"
    "raw_sources_all_recovered"
    "raw_sources_any_recovered"
    "recovered_devices"
    "blocked_devices"
    "phase14B5_release"
    "model_changes"
    "source_commit_sha"
    "source_pre_run_clean"
    "next_phase"
    ];
status = [
    conditional(allPass, "complete", "needs_recovery_review")
    closure
    string(allRecovered)
    string(anyRecovered)
    join_or_none(recoveredDevices)
    join_or_none(blockedDevices)
    "blocked_until_phase14B4_relock"
    "none"
    lookup_value(sourceProvenance, "source_commit_sha")
    lookup_value(sourceProvenance, "source_pre_run_clean")
    nextPhase
    ];
note = [
    "Recovery audit status."
    "Closure distinguishes full, partial, and absent recovery."
    "True only if all candidate devices have accepted raw candidates."
    "True if at least one candidate device has an accepted raw candidate."
    "Devices with candidates ready for manual lock review."
    "Devices still lacking accepted candidates."
    "Phase 14B.5 still requires Phase 14B.4 relock."
    "The frozen nonlinear model is untouched."
    "Source commit captured before output generation."
    "Clean provenance requires no tracked or untracked pre-run changes."
    "Next stage depends on recovery status."
    ];
handoff = table(item, status, note);
end

function status = lookup_value(T, item)
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

function value = conditional(tf, a, b)
if tf
    value = string(a);
else
    value = string(b);
end
end

function text = join_or_none(values)
values = string(values(:));
if isempty(values)
    text = "none";
else
    text = strjoin(values, "|");
end
end
