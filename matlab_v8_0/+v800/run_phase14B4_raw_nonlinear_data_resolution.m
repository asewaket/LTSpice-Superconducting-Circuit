function out = run_phase14B4_raw_nonlinear_data_resolution(cfg)
%RUN_PHASE14B4_RAW_NONLINEAR_DATA_RESOLUTION Lock raw dVdI(I,T) ingestion.
%
% Phase 14B.4 performs no fitting and introduces no proxy data. It audits
% whether the AS001/AS004 nonlinear grids declared in Phase 14A have enough
% raw source metadata to support adequacy-grade Phase 14B.5 execution.

if ~exist(cfg.outputDir, 'dir')
    mkdir(cfg.outputDir);
end

sourceProvenance = build_source_provenance(cfg);
inputs = load_inputs(cfg);
rawLedger = build_raw_data_ledger(cfg, inputs);
axisIntegrity = build_axis_integrity_checks(cfg, rawLedger);
ingestionPolicy = build_ingestion_policy(cfg);
resolutionDecision = build_resolution_decision(cfg, rawLedger, ...
    axisIntegrity);
gateSummary = build_gate_summary(cfg, inputs, rawLedger, axisIntegrity, ...
    ingestionPolicy, resolutionDecision, sourceProvenance);
handoffStatus = build_handoff_status(cfg, rawLedger, resolutionDecision, ...
    gateSummary, sourceProvenance);

writetable(rawLedger, cfg.phase14B4.rawDataLedgerFile);
writetable(axisIntegrity, cfg.phase14B4.axisIntegrityFile);
writetable(ingestionPolicy, cfg.phase14B4.ingestionPolicyFile);
writetable(resolutionDecision, cfg.phase14B4.resolutionDecisionFile);
writetable(gateSummary, cfg.phase14B4.gateSummaryFile);
writetable(handoffStatus, cfg.phase14B4.handoffStatusFile);
writetable(sourceProvenance, cfg.phase14B4.sourceProvenanceFile);

try
    h = v800.plot_phase14B4_raw_nonlinear_data_resolution_summary( ...
        cfg, rawLedger, axisIntegrity, resolutionDecision, gateSummary);
catch ME
    warning('v8:phase14B4PlotFailed', ...
        'Phase 14B.4 summary plot failed: %s', ME.message);
    h = [];
end

out = struct();
out.config = cfg;
out.inputs = inputs;
out.rawDataLedger = rawLedger;
out.axisIntegrityChecks = axisIntegrity;
out.ingestionPolicy = ingestionPolicy;
out.resolutionDecision = resolutionDecision;
out.gateSummary = gateSummary;
out.handoffStatus = handoffStatus;
out.sourceProvenance = sourceProvenance;
out.figure = h;
out.paths = build_paths(cfg);
end

function paths = build_paths(cfg)
paths = struct();
paths.rawDataLedger = cfg.phase14B4.rawDataLedgerFile;
paths.axisIntegrityChecks = cfg.phase14B4.axisIntegrityFile;
paths.ingestionPolicy = cfg.phase14B4.ingestionPolicyFile;
paths.resolutionDecision = cfg.phase14B4.resolutionDecisionFile;
paths.gateSummary = cfg.phase14B4.gateSummaryFile;
paths.handoffStatus = cfg.phase14B4.handoffStatusFile;
paths.sourceProvenance = cfg.phase14B4.sourceProvenanceFile;
paths.figurePng = [cfg.phase14B4.figureBaseFile '.png'];
paths.figurePdf = [cfg.phase14B4.figureBaseFile '.pdf'];
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
    "phase14B4_raw_nonlinear_data_resolution"
    sourceStatus.commit_sha
    sourceStatus.tree_sha
    string(sourceStatus.tracked_clean)
    string(sourceStatus.untracked_clean)
    string(sourceStatus.tracked_clean && sourceStatus.untracked_clean)
    "AS001_AS004_raw_dVdI_I_T_ingestion_lock_before_raw_execution"
    "Commit Phase 14B.4 source first; rerun from clean source; commit artifacts separately."
    ];
note = [
    "Phase 14B.4 raw nonlinear source-resolution audit."
    "Git commit captured before this runner writes outputs."
    "Git tree object captured before this runner writes outputs."
    "Tracked-source cleanliness before output generation."
    "Untracked-source/artifact cleanliness before output generation."
    "True only when checkout is clean before this run writes outputs."
    "No fitting, no proxy substitution, no thermal/phase terms."
    "Artifacts are separate from source/configuration commits."
    ];
provenance = table(item, value, note);
end

function inputs = load_inputs(cfg)
inputs = struct();
inputs.phase14AManifest = read_required_table( ...
    cfg.phase14A.nonlinearDataManifestFile);
inputs.phase14AProbeSweep = read_required_table( ...
    cfg.phase14A.probeAndSweepLockFile);
inputs.phase14AObjective = read_required_table( ...
    cfg.phase14A.objectiveSpecificationFile);
inputs.phase14AHandoff = read_required_table( ...
    cfg.phase14A.handoffStatusFile);
inputs.phase14B3RawResolution = read_required_table( ...
    cfg.phase14B3.rawDataResolutionFile);
inputs.phase14B3Handoff = read_required_table( ...
    cfg.phase14B3.handoffStatusFile);
end

function T = read_required_table(pathValue)
if ~exist(pathValue, 'file')
    error('Required Phase 14B.4 input is missing: %s', pathValue);
end
try
    T = readtable(pathValue, 'TextType', 'string', ...
        'VariableNamingRule', 'preserve', 'Delimiter', ',');
catch
    T = readtable(pathValue, 'TextType', 'string', 'Delimiter', ',');
end
end

function ledger = build_raw_data_ledger(cfg, inputs)
devices = string(cfg.phase14B4.candidateDevices(:));
rows = repmat(empty_raw_row(), numel(devices), 1);
for k = 1:numel(devices)
    device = devices(k);
    manifestRow = row_for_device(inputs.phase14AManifest, device);
    probeRow = row_for_device(inputs.phase14AProbeSweep, device);
    b3Row = row_for_device(inputs.phase14B3RawResolution, device);
    declaredAvailable = table_bool(manifestRow.nonlinear_dataset_available);
    observableOk = string(manifestRow.observable_type) == ...
        cfg.phase14B4.requiredObservableType;
    rawFile = "";
    rawVariable = "";
    sourcePath = "";
    if any(string(inputs.phase14B3RawResolution.Properties.VariableNames) == ...
            "source_path")
        sourcePath = string(b3Row.source_path);
    end
    [fileResolved, candidatePath] = resolve_candidate_file(cfg, ...
        device, sourcePath);
    loaderReady = declaredAvailable && observableOk && fileResolved;

    rows(k).device = device;
    rows(k).raw_file = candidatePath;
    rows(k).raw_variable = rawVariable;
    rows(k).loader_status = conditional(loaderReady, ...
        "loader_ready", "loader_path_unresolved");
    rows(k).current_axis_resolved = false;
    rows(k).temperature_axis_resolved = false;
    rows(k).dVdI_matrix_resolved = false;
    rows(k).matrix_dimensions_match = false;
    rows(k).current_units = "unresolved";
    rows(k).temperature_units = "unresolved";
    rows(k).dVdI_units = "unresolved";
    rows(k).field_condition = string(manifestRow.field_condition);
    rows(k).sweep_direction = string(probeRow.current_sweep_policy);
    rows(k).probe_mapping = string(probeRow.primary_probe) + ...
        " primary; " + string(probeRow.secondary_probe) + " secondary";
    rows(k).declared_available = declaredAvailable;
    rows(k).observable_type = string(manifestRow.observable_type);
    rows(k).raw_data_status = raw_status(declaredAvailable, ...
        observableOk, fileResolved);
    rows(k).allowed_model_use = loaderReady;
    rows(k).no_proxy_substitution = cfg.phase14B4.noProxySubstitution;
    rows(k).note = raw_note(declaredAvailable, observableOk, fileResolved);
end
ledger = struct2table(rows);
end

function row = empty_raw_row()
row = struct( ...
    'device', "", ...
    'raw_file', "", ...
    'raw_variable', "", ...
    'loader_status', "", ...
    'current_axis_resolved', false, ...
    'temperature_axis_resolved', false, ...
    'dVdI_matrix_resolved', false, ...
    'matrix_dimensions_match', false, ...
    'current_units', "", ...
    'temperature_units', "", ...
    'dVdI_units', "", ...
    'field_condition', "", ...
    'sweep_direction', "", ...
    'probe_mapping', "", ...
    'declared_available', false, ...
    'observable_type', "", ...
    'raw_data_status', "", ...
    'allowed_model_use', false, ...
    'no_proxy_substitution', true, ...
    'note', "");
end

function [resolved, candidatePath] = resolve_candidate_file(cfg, device, ...
    sourcePath)
candidatePath = "unresolved";
resolved = false;
if strlength(sourcePath) > 0 && sourcePath ~= "not_locked_in_phase14A"
    pathValue = char(sourcePath);
    if ~isfolder(pathValue) && exist(pathValue, 'file')
        resolved = true;
        candidatePath = string(pathValue);
        return;
    end
end

patterns = [
    "*" + device + "*dV*dI*T*.mat"
    "*" + device + "*dVdI*I*T*.csv"
    "*" + device + "*dVdI*I*T*.dat"
    "*" + device + "*nonlinear*.mat"
    ];
for k = 1:numel(patterns)
    matches = dir(fullfile(cfg.repoRoot, "**", char(patterns(k))));
    matches = matches(~[matches.isdir]);
    if ~isempty(matches)
        candidatePath = string(fullfile(matches(1).folder, matches(1).name));
        resolved = true;
        return;
    end
end
end

function status = raw_status(declaredAvailable, observableOk, fileResolved)
if fileResolved && declaredAvailable && observableOk
    status = "raw_data_resolved";
elseif declaredAvailable && observableOk
    status = "raw_data_partially_resolved";
elseif declaredAvailable && ~observableOk
    status = "raw_data_ambiguous";
else
    status = "raw_data_unavailable";
end
end

function note = raw_note(declaredAvailable, observableOk, fileResolved)
if fileResolved && declaredAvailable && observableOk
    note = "Raw file candidate found; axis and matrix validation required before raw execution.";
elseif declaredAvailable && observableOk
    note = "Phase 14A declares a nonlinear target, but no reproducible raw loader path is locked.";
elseif declaredAvailable
    note = "Device has a nonlinear declaration, but it is not the required dVdI(I,T) observable.";
else
    note = "No raw nonlinear target is declared for Phase 14B.4.";
end
end

function checks = build_axis_integrity_checks(cfg, rawLedger)
devices = string(rawLedger.device);
checkNames = [
    "raw_file_exists"
    "raw_variable_resolved"
    "current_axis_monotonic"
    "zero_current_identifiable"
    "temperature_axis_resolved"
    "dVdI_matrix_resolved"
    "matrix_dimensions_match"
    "units_explicit"
    "field_condition_explicit"
    "sweep_direction_explicit"
    "probe_identity_explicit"
    "no_transpose_silent"
    "no_proxy_substitution"
    ];
nRows = numel(devices) * numel(checkNames);
rows = repmat(empty_check_row(), nRows, 1);
idx = 0;
for d = 1:numel(devices)
    row = rawLedger(d, :);
    for c = 1:numel(checkNames)
        idx = idx + 1;
        checkName = checkNames(c);
        [status, detail] = evaluate_check(cfg, row, checkName);
        rows(idx).device = devices(d);
        rows(idx).check_name = checkName;
        rows(idx).status = status;
        rows(idx).detail = detail;
    end
end
checks = struct2table(rows);
end

function row = empty_check_row()
row = struct( ...
    'device', "", ...
    'check_name', "", ...
    'status', "", ...
    'detail', "");
end

function [status, detail] = evaluate_check(cfg, row, checkName)
switch string(checkName)
    case "raw_file_exists"
        passed = string(row.raw_file) ~= "unresolved" && ...
            exist(char(row.raw_file), 'file') == 2;
        detail = conditional(passed, "raw file exists", ...
            "raw file path unresolved");
    case "raw_variable_resolved"
        passed = strlength(string(row.raw_variable)) > 0;
        detail = conditional(passed, "raw variable or sheet locked", ...
            "raw variable or sheet not locked");
    case "current_axis_monotonic"
        passed = row.current_axis_resolved && ...
            cfg.phase14B4.currentAxisMonotonicRequired;
        detail = conditional(passed, "current axis validated", ...
            "current axis cannot be validated without raw grid");
    case "zero_current_identifiable"
        passed = row.current_axis_resolved && cfg.phase14B4.zeroCurrentRequired;
        detail = conditional(passed, "zero current identified", ...
            "zero current not identifiable without raw current axis");
    case "temperature_axis_resolved"
        passed = row.temperature_axis_resolved;
        detail = conditional(passed, "temperature axis resolved", ...
            "temperature axis unresolved");
    case "dVdI_matrix_resolved"
        passed = row.dVdI_matrix_resolved;
        detail = conditional(passed, "dVdI matrix resolved", ...
            "dVdI matrix unresolved");
    case "matrix_dimensions_match"
        passed = row.matrix_dimensions_match;
        detail = conditional(passed, "matrix dimensions match axes", ...
            "matrix dimensions cannot be checked without raw grid");
    case "units_explicit"
        passed = string(row.current_units) ~= "unresolved" && ...
            string(row.temperature_units) ~= "unresolved" && ...
            string(row.dVdI_units) ~= "unresolved";
        detail = conditional(passed, "all units explicit", ...
            "current, temperature, or dVdI units unresolved");
    case "field_condition_explicit"
        passed = strlength(string(row.field_condition)) > 0 && ...
            ~contains(string(row.field_condition), "field_sweep", ...
            'IgnoreCase', true);
        detail = conditional(passed, "field condition declared for I-T use", ...
            "field condition unresolved or field-map context");
    case "sweep_direction_explicit"
        passed = strlength(string(row.sweep_direction)) > 0 && ...
            string(row.sweep_direction) ~= "not_applicable";
        detail = conditional(passed, "sweep policy declared", ...
            "sweep direction unavailable");
    case "probe_identity_explicit"
        passed = strlength(string(row.probe_mapping)) > 0 && ...
            ~contains(string(row.probe_mapping), "not_declared");
        detail = conditional(passed, "probe mapping declared", ...
            "probe mapping unresolved");
    case "no_transpose_silent"
        passed = row.matrix_dimensions_match;
        detail = conditional(passed, "orientation check performed", ...
            "orientation not validated; no transpose allowed");
    case "no_proxy_substitution"
        passed = row.no_proxy_substitution;
        detail = conditional(passed, "proxy substitution prohibited", ...
            "proxy substitution allowed");
    otherwise
        passed = false;
        detail = "unknown check";
end
status = passfail(passed);
end

function policy = build_ingestion_policy(cfg)
policy_item = [
    "no_fitting_performed"
    "no_synthetic_replacement"
    "no_proxy_substitution"
    "field_dependent_maps_excluded"
    "raw_execution_requires_all_devices_resolved"
    "phase14C_deferred_until_raw_hysteresis_evidence"
    "phase14D_adequacy_requires_raw_grid_backing"
    ];
status = [
    string(~cfg.phase14B4.allowFitting)
    string(~cfg.phase14B4.allowSyntheticReplacement)
    string(cfg.phase14B4.noProxySubstitution)
    string(~cfg.phase14B4.allowFieldDependentMaps)
    cfg.phase14B4.allowedStatusForRawExecution
    "deferred"
    "required"
    ];
note = [
    "Phase 14B.4 is an ingestion audit only."
    "Unavailable raw grids are not replaced with synthetic data."
    "Locked proxy metrics remain Phase 14B.3 workflow diagnostics only."
    "dVdI(I,B) maps are deferred to Phase 15."
    "Phase 14B.5 can run only on raw_data_resolved rows."
    "Thermal/electrothermal terms require raw hysteresis or retrapping evidence."
    "Phase 14D cannot make raw nonlinear adequacy claims from proxy metrics."
    ];
policy = table(policy_item, status, note);
end

function decisions = build_resolution_decision(cfg, rawLedger, axisIntegrity)
devices = string(rawLedger.device);
rows = repmat(empty_decision_row(), numel(devices), 1);
for d = 1:numel(devices)
    device = devices(d);
    mask = string(axisIntegrity.device) == device;
    allChecksPass = all(string(axisIntegrity.status(mask)) == "pass");
    rawResolved = string(rawLedger.raw_data_status(d)) == ...
        cfg.phase14B4.allowedStatusForRawExecution;
    allowed = rawResolved && allChecksPass && rawLedger.allowed_model_use(d);
    rows(d).device = device;
    rows(d).raw_data_status = string(rawLedger.raw_data_status(d));
    rows(d).all_integrity_checks_pass = allChecksPass;
    rows(d).allowed_for_phase14B5 = allowed;
    rows(d).resolution_result = conditional(allowed, ...
        "raw_data_resolved", string(rawLedger.raw_data_status(d)));
    rows(d).decision = conditional(allowed, ...
        "release_to_raw_nonlinear_execution", ...
        "block_raw_execution_until_source_lock");
    rows(d).next_action = conditional(allowed, ...
        cfg.phase14B4.nextPhaseWhenResolved, ...
        "locate_and_lock_raw_source_file_axes_units_orientation");
end
decisions = struct2table(rows);
end

function row = empty_decision_row()
row = struct( ...
    'device', "", ...
    'raw_data_status', "", ...
    'all_integrity_checks_pass', false, ...
    'allowed_for_phase14B5', false, ...
    'resolution_result', "", ...
    'decision', "", ...
    'next_action', "");
end

function gates = build_gate_summary(cfg, inputs, rawLedger, axisIntegrity, ...
    ingestionPolicy, resolutionDecision, sourceProvenance)
phase14ALock = lookup_status(inputs.phase14AHandoff, ...
    "phase14A_closure") == "pass_nonlinear_data_objective_lock";
b3Read = height(inputs.phase14B3Handoff) > 0 && ...
    height(inputs.phase14B3RawResolution) > 0;
as001Explicit = any(string(rawLedger.device) == "AS001");
as004Explicit = any(string(rawLedger.device) == "AS004");
currentAxesValidated = all(check_status(axisIntegrity, ...
    "current_axis_monotonic") == "pass");
temperatureAxesValidated = all(check_status(axisIntegrity, ...
    "temperature_axis_resolved") == "pass");
matrixValidated = all(check_status(axisIntegrity, ...
    "matrix_dimensions_match") == "pass");
unitsExplicit = all(check_status(axisIntegrity, "units_explicit") == "pass");
probeExplicit = all(check_status(axisIntegrity, ...
    "probe_identity_explicit") == "pass");
fieldExplicit = all(check_status(axisIntegrity, ...
    "field_condition_explicit") == "pass");
sweepExplicit = all(check_status(axisIntegrity, ...
    "sweep_direction_explicit") == "pass");
noProxy = cfg.phase14B4.noProxySubstitution && ...
    all(rawLedger.no_proxy_substitution) && ...
    lookup_policy(ingestionPolicy, "no_proxy_substitution") == "true";
noFit = ~cfg.phase14B4.allowFitting && ...
    lookup_policy(ingestionPolicy, "no_fitting_performed") == "true";
cleanSource = lookup_value(sourceProvenance, "source_pre_run_clean") == "true";
resolutionRecorded = all(strlength(string( ...
    resolutionDecision.resolution_result)) > 0);

gate = [
    "Phase 14A objective lock consumed"
    "Phase 14B.3 raw caveat consumed"
    "AS001 raw source status explicit"
    "AS004 raw source status explicit"
    "Current axes validated"
    "Temperature axes validated"
    "Matrix orientation validated"
    "Units explicit"
    "Probe identity explicit"
    "Field condition explicit"
    "Sweep direction explicit"
    "No proxy substitution"
    "No fitting performed"
    "Resolution decision recorded"
    "Clean provenance"
    ];
outcome = [
    passfail(phase14ALock)
    passfail(b3Read)
    passfail(as001Explicit)
    passfail(as004Explicit)
    passfail(currentAxesValidated)
    passfail(temperatureAxesValidated)
    passfail(matrixValidated)
    passfail(unitsExplicit)
    passfail(probeExplicit)
    passfail(fieldExplicit)
    passfail(sweepExplicit)
    passfail(noProxy)
    passfail(noFit)
    passfail(resolutionRecorded)
    passfail(cleanSource)
    ];
note = [
    "Phase 14B.4 inherits the locked nonlinear objective."
    "Phase 14B.3 proxy-execution caveat is read rather than overwritten."
    "The AS001 raw-data ledger row exists."
    "The AS004 raw-data ledger row exists."
    "Requires a monotonic raw current axis."
    "Requires a resolved raw temperature axis."
    "Requires matrix dimensions and orientation to match axes."
    "Current, temperature, and dVdI units must be explicit."
    "Probe pair identity must be explicit."
    "B≈0/fixed-zero field condition must be explicit."
    "Up/down or source sweep policy must be explicit."
    "Unavailable raw grids are not replaced by Phase 14B.3 proxy metrics."
    "This phase is an ingestion lock, not an optimizer."
    "Each device receives a release/block decision."
    "True only when Phase 14B.4 starts from a clean checkout."
    ];
gates = table(gate, outcome, note);
end

function statuses = check_status(axisIntegrity, checkName)
statuses = string(axisIntegrity.status( ...
    string(axisIntegrity.check_name) == string(checkName)));
end

function status = lookup_policy(T, item)
idx = string(T.policy_item) == string(item);
if any(idx)
    status = string(T.status(find(idx, 1, 'first')));
else
    status = "";
end
end

function handoff = build_handoff_status(cfg, rawLedger, resolutionDecision, ...
    gates, sourceProvenance)
allRawResolved = all(resolutionDecision.allowed_for_phase14B5);
allPass = all(string(gates.outcome) == "pass");
anyRawResolved = any(resolutionDecision.allowed_for_phase14B5);
if allRawResolved
    closure = "pass_raw_nonlinear_ingestion_lock";
    nextPhase = cfg.phase14B4.nextPhaseWhenResolved;
elseif anyRawResolved
    closure = "partial_raw_nonlinear_ingestion_lock";
    nextPhase = "resolve_remaining_raw_sources_before_phase14B5";
else
    closure = "raw_nonlinear_ingestion_blocked";
    nextPhase = cfg.phase14B4.nextPhaseWhenUnresolved;
end

item = [
    "phase14B4_resolution"
    "phase14B4_closure"
    "raw_data_all_resolved"
    "raw_data_any_resolved"
    "allowed_for_phase14B5_devices"
    "blocked_devices"
    "no_proxy_substitution"
    "no_fitting_performed"
    "raw_experimental_nonlinear_adequacy"
    "phase14C_trigger_status"
    "source_commit_sha"
    "source_pre_run_clean"
    "next_phase"
    ];
allowedDevices = string(resolutionDecision.device( ...
    resolutionDecision.allowed_for_phase14B5));
blockedDevices = string(resolutionDecision.device( ...
    ~resolutionDecision.allowed_for_phase14B5));
status = [
    conditional(allPass, "complete", "needs_resolution_review")
    closure
    string(allRawResolved)
    string(anyRawResolved)
    join_or_none(allowedDevices)
    join_or_none(blockedDevices)
    string(cfg.phase14B4.noProxySubstitution)
    string(~cfg.phase14B4.allowFitting)
    conditional(allRawResolved, "ready_for_phase14B5", ...
        "not_assessed_raw_sources_unresolved")
    "not_triggered_by_phase14B4"
    lookup_value(sourceProvenance, "source_commit_sha")
    lookup_value(sourceProvenance, "source_pre_run_clean")
    nextPhase
    ];
note = [
    "Overall ingestion audit status; failed raw checks block raw execution."
    "Closure distinguishes successful source lock from honest unresolved data."
    "True only if every AS001/AS004 raw grid and integrity check is resolved."
    "True if at least one candidate raw grid is executable."
    "Devices released to raw nonlinear execution."
    "Devices that require source/path/axis/unit/orientation resolution."
    "Proxy metrics are not promoted to raw data."
    "No model parameters are fit in Phase 14B.4."
    "Raw adequacy remains deferred until raw grids are loader-backed."
    "Thermal terms require later raw hysteresis/retrapping evidence."
    "Source commit captured before output generation."
    "Clean provenance requires no tracked or untracked pre-run changes."
    "Raw execution proceeds only after source resolution."
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

function text = join_or_none(values)
values = string(values(:));
if isempty(values)
    text = "none";
else
    text = strjoin(values, "|");
end
end
