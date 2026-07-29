function out = run_phase8_numerical_robustness(cfg)
%RUN_PHASE8_NUMERICAL_ROBUSTNESS Numerical and implementation audit.

if ~exist(cfg.outputDir, 'dir')
    mkdir(cfg.outputDir);
end

sourceProvenance = build_source_provenance(cfg);
inputs = load_phase8_inputs(cfg);
scopePolicy = build_scope_policy(cfg);
frozenInputManifest = build_frozen_input_manifest(cfg);
numericalTestPlan = build_numerical_test_plan(cfg);
schemaAudit = build_schema_audit(cfg);
reproducibilityAudit = build_reproducibility_audit(cfg, inputs, ...
    frozenInputManifest);
tolerancePolicy = build_tolerance_policy(cfg);
implementationAudit = build_implementation_audit(cfg, inputs);
gateSummary = build_gate_summary(cfg, frozenInputManifest, schemaAudit, ...
    reproducibilityAudit, implementationAudit);
handoffStatus = build_handoff_status(cfg, gateSummary);

writetable(scopePolicy, cfg.phase8.scopePolicyFile);
writetable(frozenInputManifest, cfg.phase8.frozenInputManifestFile);
writetable(numericalTestPlan, cfg.phase8.numericalTestPlanFile);
writetable(schemaAudit, cfg.phase8.schemaAuditFile);
writetable(reproducibilityAudit, cfg.phase8.reproducibilityAuditFile);
writetable(tolerancePolicy, cfg.phase8.tolerancePolicyFile);
writetable(implementationAudit, cfg.phase8.implementationAuditFile);
writetable(gateSummary, cfg.phase8.gateSummaryFile);
writetable(handoffStatus, cfg.phase8.handoffStatusFile);
writetable(sourceProvenance, cfg.phase8.sourceProvenanceFile);

try
    h = v800.plot_phase8_numerical_robustness(cfg, schemaAudit, ...
        reproducibilityAudit, implementationAudit, gateSummary, ...
        numericalTestPlan);
catch ME
    warning('v8:phase8PlotFailed', ...
        'Phase 8 numerical robustness plot failed: %s', ME.message);
    h = [];
end

out = struct();
out.config = cfg;
out.inputs = inputs;
out.scopePolicy = scopePolicy;
out.frozenInputManifest = frozenInputManifest;
out.numericalTestPlan = numericalTestPlan;
out.schemaAudit = schemaAudit;
out.reproducibilityAudit = reproducibilityAudit;
out.tolerancePolicy = tolerancePolicy;
out.implementationAudit = implementationAudit;
out.gateSummary = gateSummary;
out.handoffStatus = handoffStatus;
out.sourceProvenance = sourceProvenance;
out.figure = h;
out.paths = struct();
out.paths.scopePolicy = cfg.phase8.scopePolicyFile;
out.paths.frozenInputManifest = cfg.phase8.frozenInputManifestFile;
out.paths.numericalTestPlan = cfg.phase8.numericalTestPlanFile;
out.paths.schemaAudit = cfg.phase8.schemaAuditFile;
out.paths.reproducibilityAudit = cfg.phase8.reproducibilityAuditFile;
out.paths.tolerancePolicy = cfg.phase8.tolerancePolicyFile;
out.paths.implementationAudit = cfg.phase8.implementationAuditFile;
out.paths.gateSummary = cfg.phase8.gateSummaryFile;
out.paths.handoffStatus = cfg.phase8.handoffStatusFile;
out.paths.sourceProvenance = cfg.phase8.sourceProvenanceFile;
out.paths.figurePng = [cfg.phase8.figureBaseFile '.png'];
out.paths.figurePdf = [cfg.phase8.figureBaseFile '.pdf'];
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
    "phase8_numerical_robustness"
    sourceStatus.commit_sha
    sourceStatus.tree_sha
    string(sourceStatus.tracked_clean)
    string(sourceStatus.untracked_clean)
    string(sourceStatus.tracked_clean && sourceStatus.untracked_clean)
    "standalone_phase8_run"
    "Commit source/config first; rerun Phase 8 from that source; commit generated artifacts separately."
    ];
note = [
    "Phase 8 numerical and implementation robustness."
    "Git commit captured before this runner writes outputs."
    "Git tree object captured before this runner writes outputs."
    "Tracked-source cleanliness before output generation."
    "Untracked-source/artifact cleanliness before output generation."
    "True only when the source checkout is clean before this run writes outputs."
    "Standalone Phase 8 artifact-generation checkpoint."
    "The artifact commit need not be embedded in files generated before that commit exists."
    ];
provenance = table(item, value, note);
end

function inputs = load_phase8_inputs(cfg)
inputs = struct();
inputs.phase5D2Context = read_optional_table( ...
    cfg.phase5D2.realDeviceScoreContextFile);
inputs.phase5D2Status = read_optional_table( ...
    cfg.phase5D2.resultFreezeStatusFile);
inputs.phase5D2Gates = read_optional_table( ...
    cfg.phase5D2.finalGateSummaryFile);
inputs.phase6Matrix = read_optional_table( ...
    cfg.phase6.sixDeviceEvidenceMatrixFile);
inputs.phase6Status = read_optional_table( ...
    cfg.phase6.deviceModelStatusFile);
inputs.phase6Handoff = read_optional_table( ...
    cfg.phase6.handoffStatusFile);
inputs.phase7BHandoff = read_three_column_table( ...
    cfg.phase7B.handoffStatusFile, ["item", "status", "note"]);
inputs.phase7BGates = read_three_column_table( ...
    cfg.phase7B.gateSummaryFile, ["component", "outcome", "note"]);
inputs.phase7BAnnotations = read_optional_table( ...
    cfg.phase7B.deviceRobustnessAnnotationFile);
inputs.phase7BProvenance = read_three_column_table( ...
    cfg.phase7B.sourceProvenanceFile, ["item", "value", "note"]);
end

function T = read_optional_table(pathValue)
if exist(pathValue, 'file')
    T = readtable(pathValue, 'TextType', 'string');
else
    T = table();
end
end

function T = read_three_column_table(pathValue, columnNames)
if ~exist(pathValue, 'file')
    T = table();
    return;
end
fid = fopen(char(pathValue), 'r');
if fid < 0
    T = table();
    return;
end
cleanup = onCleanup(@() fclose(fid));
headerLine = fgetl(fid); %#ok<NASGU>
rows = strings(0, 3);
while true
    line = fgetl(fid);
    if ~ischar(line)
        break;
    end
    fields = split_first_csv_fields(string(line), 3);
    rows(end + 1, :) = fields; %#ok<AGROW>
end
if isempty(rows)
    T = table('Size', [0 3], 'VariableTypes', ...
        {'string', 'string', 'string'}, 'VariableNames', cellstr(columnNames));
else
    T = table(rows(:, 1), rows(:, 2), rows(:, 3), ...
        'VariableNames', cellstr(columnNames));
end
end

function policy = build_scope_policy(cfg)
rows = [
    policy_row("phase_objective", "active", ...
    "Audit numerical and implementation robustness after Phase 6/7 labels are frozen.")
    policy_row("classifier_retuning", string(cfg.phase8.allowClassifierRetuning), ...
    "No threshold, mechanism class, nuisance term, or device-specific parameter may be tuned in Phase 8.")
    policy_row("status_relabeling", string(cfg.phase8.allowStatusRelabeling), ...
    "Phase 8 may report numerical fragility but may not relabel Phase 6 device statuses.")
    policy_row("expensive_transport_sweeps", ...
    string(cfg.phase8.executeExpensiveTransportSweeps), ...
    "Phase 8A is a source/schema/reproducibility audit; transport reruns are deferred to Phase 8B.")
    policy_row("allowed_outputs", "audit_and_handoff", ...
    "Allowed outputs are tolerance policy, schema checks, reproducibility checks, and a declared numerical test plan.")
    policy_row("prohibited_outputs", "new_physics_or_classifier", ...
    "Do not add new weak-link physics, force-law terms, Raman transforms, or universal classifier thresholds.")
    ];
policy = struct2table(rows);
end

function manifest = build_frozen_input_manifest(cfg)
rows = [
    manifest_row("phase5D2_result_freeze_status", ...
    cfg.phase5D2.resultFreezeStatusFile, true, ...
    "frozen detection-limit and result-freeze status")
    manifest_row("phase5D2_real_device_score_context", ...
    cfg.phase5D2.realDeviceScoreContextFile, true, ...
    "real-device DeltaS/Z context")
    manifest_row("phase6_six_device_evidence_matrix", ...
    cfg.phase6.sixDeviceEvidenceMatrixFile, true, ...
    "frozen six-device hierarchy and labels")
    manifest_row("phase6_handoff_status", ...
    cfg.phase6.handoffStatusFile, true, ...
    "retuning prohibition and Phase 7 handoff")
    manifest_row("phase7B_gate_summary", ...
    cfg.phase7B.gateSummaryFile, true, ...
    "geometry/mechanical mask robustness gates")
    manifest_row("phase7B_device_robustness_annotations", ...
    cfg.phase7B.deviceRobustnessAnnotationFile, true, ...
    "Phase 7B claim-impact annotations")
    manifest_row("phase7B_handoff_status", ...
    cfg.phase7B.handoffStatusFile, true, ...
    "Phase 7 closure and Phase 8 handoff")
    manifest_row("phase7B_source_provenance", ...
    cfg.phase7B.sourceProvenanceFile, false, ...
    "source checkpoint from the previous artifact-generation phase")
    ];
manifest = struct2table(rows);
manifest.exists = arrayfun(@(p) exist(char(p), 'file') == 2, manifest.path);
[manifest.file_size_bytes, manifest.modified_datenum] = ...
    manifest_file_metadata(manifest.path);
manifest.frozen_use = repmat("read_only_no_relabeling_no_retuning", ...
    height(manifest), 1);
end

function plan = build_numerical_test_plan(cfg)
rows = [
    test_row("schema_contract", "implementation", "completed_in_phase8A", ...
    "Verify required CSV columns for frozen Phase 5D2/6/7B artifacts.")
    test_row("source_provenance_checkpoint", "implementation", ...
    "completed_in_phase8A", ...
    "Capture source commit/tree before Phase 8 writes outputs.")
    test_row("frozen_label_invariance", "implementation", ...
    "completed_in_phase8A", ...
    "Confirm Phase 7B preserved all frozen Phase 6 labels.")
    test_row("mesh_resolution_sweep", "mesh", "declared_for_phase8B", ...
    sprintf('Compare mesh sizes against %dx%d reference.', ...
    cfg.phase8.referenceMeshSize, cfg.phase8.referenceMeshSize))
    test_row("solver_tolerance_sweep", "solver", "declared_for_phase8B", ...
    "Repeat selected cases across solver absolute/relative tolerance settings.")
    test_row("normalization_window_sweep", "scoring", ...
    "declared_for_phase8B", ...
    "Shift normalization windows without changing mechanism labels or thresholds.")
    test_row("disorder_seed_replay", "reproducibility", ...
    "declared_for_phase8B", ...
    "Replay frozen AS006 seed ledgers and six-device contextual scores.")
    test_row("cached_artifact_replay", "reproducibility", ...
    "declared_for_phase8B", ...
    "Compare regenerated numeric tables against committed artifact checksums.")
    ];
plan = struct2table(rows);
end

function audit = build_schema_audit(cfg)
specs = [
    schema_spec("phase5D2_real_device_score_context", ...
    cfg.phase5D2.realDeviceScoreContextFile, ...
    ["device"; "DeltaS"; "sigmaDeltaS"; "Z"; ...
    "directional_preference"])
    schema_spec("phase6_six_device_evidence_matrix", ...
    cfg.phase6.sixDeviceEvidenceMatrixFile, ...
    ["device"; "phase5D2_DeltaS"; "phase5D2_Z"; ...
    "directional_preference"; "final_model_status"])
    schema_spec("phase7B_device_robustness_annotations", ...
    cfg.phase7B.deviceRobustnessAnnotationFile, ...
    ["device"; "phase6_model_status"; "phase6_status_preserved"; ...
    "phase7_robustness_annotation"; "phase7_claim_impact"])
    schema_spec("phase7B_gate_summary", cfg.phase7B.gateSummaryFile, ...
    ["component"; "outcome"; "note"])
    schema_spec("phase7B_handoff_status", cfg.phase7B.handoffStatusFile, ...
    ["item"; "status"; "note"])
    ];
rows = repmat(empty_schema_row(), numel(specs), 1);
for k = 1:numel(specs)
    rows(k) = audit_schema(specs(k));
end
audit = struct2table(rows);
end

function audit = build_reproducibility_audit(cfg, inputs, manifest)
phase7Clean = lookup_string(inputs.phase7BProvenance, "item", ...
    "source_pre_run_clean", "value", "not_available");
phase7Closure = lookup_string(inputs.phase7BHandoff, "item", ...
    "phase7_closure", "status", "not_available");
labelsProtected = false;
if has_vars(inputs.phase7BAnnotations, ["phase6_status_preserved"])
    labelsProtected = all(logical(inputs.phase7BAnnotations.phase6_status_preserved));
end
rows = [
    repro_row("required_artifacts_exist", logical_status( ...
    all(manifest.exists(manifest.required))), ...
    "All required frozen inputs are present.")
    repro_row("phase7B_source_pre_run_clean_available", ...
    logical_status(phase7Clean == "true" || phase7Clean == "false"), ...
    "Previous phase provenance records whether its source checkout was clean.")
    repro_row("phase7_closure_allows_phase8", ...
    logical_status(phase7Closure == "pass_with_registered_raman_unavailable"), ...
    "Phase 7 handoff points to numerical robustness.")
    repro_row("frozen_phase6_labels_preserved", logical_status(labelsProtected), ...
    "Phase 7B annotation table preserves every frozen Phase 6 status.")
    repro_row("phase8_source_pre_run_captured", "pass", ...
    "Phase 8 captures git commit/tree before writing outputs.")
    repro_row("matlab_runtime_replay", "not_run", ...
    "MATLAB transport replay is deferred to Phase 8B because Phase 8A is a static audit.")
    ];
audit = struct2table(rows);
end

function policy = build_tolerance_policy(cfg)
rows = [
    tolerance_row("score_ledger_replay", "strict_numeric", ...
    cfg.phase8.scoreAbsTolerance, 0, ...
    "Numeric score ledgers should replay to strict absolute tolerance.")
    tolerance_row("DeltaS_context", "contextual_numeric", ...
    cfg.phase8.deltaSContextTolerance, 0, ...
    "DeltaS drift below this value is context-stable and cannot relabel devices.")
    tolerance_row("Z_context", "contextual_numeric", ...
    cfg.phase8.zContextTolerance, 0, ...
    "Z drift below this value is context-stable and cannot relabel devices.")
    tolerance_row("device_status", "categorical", 0, 0, ...
    "No automatic Phase 6 status change is allowed in Phase 8.")
    tolerance_row("figure_layout", "visual", NaN, NaN, ...
    "Figure regeneration is checked by content files, not pixel identity.")
    tolerance_row("csv_schema", "contract", 0, 0, ...
    "Required columns must be present exactly as declared.")
    ];
policy = struct2table(rows);
end

function audit = build_implementation_audit(cfg, inputs)
deviceCount = count_rows(inputs.phase6Matrix);
finiteDeltaS = count_finite_column(inputs.phase6Matrix, "phase5D2_DeltaS");
finiteZ = count_finite_column(inputs.phase6Matrix, "phase5D2_Z");
statusCount = count_nonempty_column(inputs.phase6Matrix, ...
    "final_model_status");
phase7AnnotationCount = count_rows(inputs.phase7BAnnotations);
gateFailCount = count_status(inputs.phase7BGates, "outcome", "fail");
gateNotRunCount = count_status(inputs.phase7BGates, "outcome", "not_run");
rows = [
    impl_row("six_device_matrix_rows", deviceCount, 6, ...
    logical_status(deviceCount == 6), ...
    "Phase 6 matrix should contain AS001-AS006.")
    impl_row("finite_DeltaS_context_rows", finiteDeltaS, 6, ...
    logical_status(finiteDeltaS == 6), ...
    "Every device should retain finite contextual DeltaS.")
    impl_row("finite_Z_context_rows", finiteZ, 6, ...
    logical_status(finiteZ == 6), ...
    "Every device should retain finite contextual Z.")
    impl_row("frozen_model_status_rows", statusCount, 6, ...
    logical_status(statusCount == 6), ...
    "Every device should have a frozen Phase 6 model status.")
    impl_row("phase7B_annotation_rows", phase7AnnotationCount, 6, ...
    logical_status(phase7AnnotationCount == 6), ...
    "Every device should have a Phase 7B robustness annotation.")
    impl_row("phase7B_failed_gates", gateFailCount, 0, ...
    logical_status(gateFailCount == 0), ...
    "Phase 7B must not hand off failed robustness gates.")
    impl_row("phase7B_not_run_gates", gateNotRunCount, 1, ...
    logical_status(gateNotRunCount <= 1), ...
    "Only registered Raman rescore is expected to remain not_run.")
    impl_row("expensive_transport_sweeps", ...
    double(cfg.phase8.executeExpensiveTransportSweeps), 0, "pass", ...
    "Phase 8A does not perform expensive transport replays.")
    ];
audit = struct2table(rows);
end

function gates = build_gate_summary(cfg, manifest, schemaAudit, ...
    reproducibilityAudit, implementationAudit)
schemaPass = all(schemaAudit.outcome == "pass");
reproPass = all(reproducibilityAudit.outcome ~= "fail");
implementationPass = all(implementationAudit.outcome == "pass");
rows = [
    gate_row("Frozen inputs available", logical_status( ...
    all(manifest.exists(manifest.required))), ...
    "Required Phase 5D2/6/7B artifacts are present.")
    gate_row("Schema contract satisfied", logical_status(schemaPass), ...
    "Required CSV columns are present.")
    gate_row("No classifier retuning", ...
    logical_status(~cfg.phase8.allowClassifierRetuning), ...
    "Phase 8A does not change thresholds, classes, or nuisance terms.")
    gate_row("No status relabeling", ...
    logical_status(~cfg.phase8.allowStatusRelabeling), ...
    "Phase 8A preserves frozen Phase 6 device statuses.")
    gate_row("Implementation audit passed", ...
    logical_status(implementationPass), ...
    "Device rows, contextual scores, and Phase 7B handoff are internally coherent.")
    gate_row("Reproducibility audit passed", logical_status(reproPass), ...
    "Static reproducibility checks pass; runtime replay is explicitly deferred.")
    gate_row("Expensive transport sweeps deferred", ...
    logical_status(~cfg.phase8.executeExpensiveTransportSweeps), ...
    "Mesh/solver/normalization replay is declared for Phase 8B.")
    ];
gates = struct2table(rows);
end

function handoff = build_handoff_status(cfg, gates)
ready = all(gates.outcome == "pass");
rows = [
    status_row("phase8A_numerical_robustness_audit", ...
    logical_status(ready), ...
    "Phase 8A source/schema/reproducibility audit generated.")
    status_row("all_phase8A_gates", logical_status(ready), ...
    "All Phase 8A gates pass if no required source/schema contract is missing.")
    status_row("classifier_retuning_performed", "false", ...
    "No classifier retuning or device relabeling occurred.")
    status_row("expensive_transport_sweeps_performed", ...
    string(cfg.phase8.executeExpensiveTransportSweeps), ...
    "Phase 8A does not run mesh or solver replay.")
    status_row("phase8A_closure", ...
    ternary_status(ready, "pass_static_audit", "fail_static_audit"), ...
    "Close Phase 8A as an implementation audit before Phase 8B numerical replay.")
    status_row("next_phase8_step", "phase8B_mesh_solver_replay", ...
    "Run mesh, solver-tolerance, normalization-window, and seed-replay checks without relabeling.")
    ];
handoff = struct2table(rows);
end

function [bytes, modifiedDatenum] = manifest_file_metadata(paths)
bytes = NaN(numel(paths), 1);
modifiedDatenum = NaN(numel(paths), 1);
for k = 1:numel(paths)
    info = dir(char(paths(k)));
    if ~isempty(info)
        bytes(k) = info(1).bytes;
        modifiedDatenum(k) = info(1).datenum;
    end
end
end

function spec = schema_spec(artifactId, pathValue, requiredColumns)
spec = struct();
spec.artifact_id = string(artifactId);
spec.path = string(pathValue);
spec.required_columns = string(requiredColumns);
end

function row = audit_schema(spec)
row = empty_schema_row();
row.artifact_id = spec.artifact_id;
row.path = spec.path;
row.required_columns = join_strings(spec.required_columns);
row.exists = exist(char(spec.path), 'file') == 2;
if ~row.exists
    row.present_columns = "";
    row.missing_columns = row.required_columns;
    row.missing_count = numel(spec.required_columns);
    row.row_count = NaN;
    row.outcome = "fail";
    row.note = "Missing required artifact.";
    return;
end
try
    present = read_csv_header(spec.path);
    missing = spec.required_columns(~ismember(spec.required_columns, present));
    row.present_columns = join_strings(present);
    row.missing_columns = join_strings(missing);
    row.missing_count = numel(missing);
    row.row_count = max(count_text_lines(spec.path) - 1, 0);
    row.outcome = logical_status(row.missing_count == 0);
    row.note = ternary_status(row.missing_count == 0, ...
        "Required columns present.", "Required columns missing.");
catch ME
    row.present_columns = "";
    row.missing_columns = row.required_columns;
    row.missing_count = numel(spec.required_columns);
    row.row_count = NaN;
    row.outcome = "fail";
    row.note = "Read failed: " + string(ME.message);
end
end

function header = read_csv_header(pathValue)
fid = fopen(char(pathValue), 'r');
if fid < 0
    error('Unable to open %s', char(pathValue));
end
cleanup = onCleanup(@() fclose(fid));
line = fgetl(fid);
if ~ischar(line)
    header = strings(0, 1);
else
    header = split_csv_header(string(line));
end
end

function n = count_text_lines(pathValue)
fid = fopen(char(pathValue), 'r');
if fid < 0
    n = 0;
    return;
end
cleanup = onCleanup(@() fclose(fid));
n = 0;
while true
    line = fgetl(fid); %#ok<NASGU>
    if ~ischar(line)
        break;
    end
    n = n + 1;
end
end

function fields = split_csv_header(line)
raw = split(string(line), ',');
fields = strip(raw);
for k = 1:numel(fields)
    fields(k) = clean_csv_field(fields(k));
end
end

function fields = split_first_csv_fields(line, nFields)
parts = strings(1, nFields);
remainder = string(line);
for k = 1:(nFields - 1)
    [parts(k), remainder] = take_first_csv_field(remainder);
end
parts(nFields) = clean_csv_field(remainder);
fields = parts;
end

function [field, remainder] = take_first_csv_field(line)
line = string(line);
chars = char(line);
inQuote = false;
splitIdx = 0;
for k = 1:numel(chars)
    if chars(k) == '"'
        inQuote = ~inQuote;
    elseif chars(k) == ',' && ~inQuote
        splitIdx = k;
        break;
    end
end
if splitIdx == 0
    field = clean_csv_field(line);
    remainder = "";
else
    field = clean_csv_field(extractBefore(line, splitIdx));
    remainder = extractAfter(line, splitIdx);
end
end

function field = clean_csv_field(value)
field = strip(string(value));
chars = char(field);
if numel(chars) >= 2 && chars(1) == '"' && chars(end) == '"'
    field = string(chars(2:end-1));
end
field = replace(field, '""', '"');
end

function tf = has_vars(T, vars)
tf = ~isempty(T) && all(ismember(string(vars), ...
    string(T.Properties.VariableNames)));
end

function value = lookup_string(T, keyVar, keyValue, valueVar, defaultValue)
value = string(defaultValue);
if isempty(T) || ~has_vars(T, [keyVar, valueVar])
    return;
end
idx = string(T.(char(keyVar))) == string(keyValue);
if any(idx)
    value = string(T.(char(valueVar))(find(idx, 1)));
end
end

function n = count_rows(T)
if isempty(T)
    n = 0;
else
    n = height(T);
end
end

function n = count_finite_column(T, col)
if isempty(T) || ~ismember(string(col), string(T.Properties.VariableNames))
    n = 0;
else
    values = T.(char(col));
    n = sum(isfinite(values));
end
end

function n = count_nonempty_column(T, col)
if isempty(T) || ~ismember(string(col), string(T.Properties.VariableNames))
    n = 0;
else
    values = string(T.(char(col)));
    n = sum(strlength(values) > 0);
end
end

function n = count_status(T, col, status)
if isempty(T) || ~ismember(string(col), string(T.Properties.VariableNames))
    n = 0;
else
    n = sum(string(T.(char(col))) == string(status));
end
end

function text = join_strings(values)
values = string(values);
if isempty(values)
    text = "";
else
    text = string(strjoin(cellstr(values(:).'), ';'));
end
end

function status = logical_status(tf)
if tf
    status = "pass";
else
    status = "fail";
end
end

function out = ternary_status(tf, a, b)
if tf
    out = string(a);
else
    out = string(b);
end
end

function row = policy_row(item, status, note)
row = struct();
row.item = string(item);
row.status = string(status);
row.note = string(note);
end

function row = manifest_row(artifactId, pathValue, required, purpose)
row = struct();
row.artifact_id = string(artifactId);
row.path = string(pathValue);
row.required = logical(required);
row.purpose = string(purpose);
end

function row = test_row(testId, testClass, status, note)
row = struct();
row.test_id = string(testId);
row.test_class = string(testClass);
row.status = string(status);
row.note = string(note);
end

function row = empty_schema_row()
row = struct();
row.artifact_id = "";
row.path = "";
row.required_columns = "";
row.exists = false;
row.present_columns = "";
row.missing_columns = "";
row.missing_count = NaN;
row.row_count = NaN;
row.outcome = "";
row.note = "";
end

function row = repro_row(item, outcome, note)
row = struct();
row.item = string(item);
row.outcome = string(outcome);
row.note = string(note);
end

function row = tolerance_row(item, toleranceClass, absoluteTolerance, ...
    relativeTolerance, note)
row = struct();
row.item = string(item);
row.tolerance_class = string(toleranceClass);
row.absolute_tolerance = absoluteTolerance;
row.relative_tolerance = relativeTolerance;
row.note = string(note);
end

function row = impl_row(item, observedCount, expectedCount, outcome, note)
row = struct();
row.item = string(item);
row.observed_count = observedCount;
row.expected_count = expectedCount;
row.outcome = string(outcome);
row.note = string(note);
end

function row = gate_row(component, outcome, note)
row = struct();
row.component = string(component);
row.outcome = string(outcome);
row.note = string(note);
end

function row = status_row(item, status, note)
row = struct();
row.item = string(item);
row.status = string(status);
row.note = string(note);
end
