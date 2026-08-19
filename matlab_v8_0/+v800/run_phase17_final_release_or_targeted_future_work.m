function out = run_phase17_final_release_or_targeted_future_work(cfg)
%RUN_PHASE17_FINAL_RELEASE_OR_TARGETED_FUTURE_WORK Freeze release boundary.
%
% Phase 17 is read-only. It consumes the Phase 16E final recoverability
% freeze, records the release boundary, and separates optional future work
% from the closed model. It does not rerun solvers, retune parameters, or
% introduce new physics.

if ~exist(cfg.outputDir, 'dir')
    mkdir(cfg.outputDir);
end

inputs = load_inputs(cfg);
sourceProvenance = build_source_provenance(cfg);

releaseBoundaryManifest = build_release_boundary_manifest(cfg, inputs);
finalClaimTable = build_final_claim_table(inputs);
futureWorkQueue = build_future_work_queue();
scopePolicy = build_scope_policy(cfg);
gateSummary = build_gate_summary(cfg, inputs, sourceProvenance, ...
    releaseBoundaryManifest, finalClaimTable, futureWorkQueue);
handoffStatus = build_handoff_status(cfg, gateSummary, ...
    releaseBoundaryManifest);

writetable(releaseBoundaryManifest, ...
    cfg.phase17.releaseBoundaryManifestFile);
writetable(finalClaimTable, cfg.phase17.finalClaimTableFile);
writetable(futureWorkQueue, cfg.phase17.futureWorkQueueFile);
writetable(scopePolicy, cfg.phase17.scopePolicyFile);
writetable(gateSummary, cfg.phase17.gateSummaryFile);
writetable(handoffStatus, cfg.phase17.handoffStatusFile);
writetable(sourceProvenance, cfg.phase17.sourceProvenanceFile);

try
    h = v800.plot_phase17_final_release_or_targeted_future_work_summary( ...
        cfg, releaseBoundaryManifest, finalClaimTable, ...
        futureWorkQueue, scopePolicy, gateSummary);
catch ME
    warning('v8:phase17PlotFailed', ...
        'Phase 17 summary plot failed: %s', ME.message);
    h = [];
end

out = struct();
out.config = cfg;
out.inputs = inputs;
out.sourceProvenance = sourceProvenance;
out.releaseBoundaryManifest = releaseBoundaryManifest;
out.finalClaimTable = finalClaimTable;
out.futureWorkQueue = futureWorkQueue;
out.scopePolicy = scopePolicy;
out.gateSummary = gateSummary;
out.handoffStatus = handoffStatus;
out.figure = h;
out.paths = build_paths(cfg);
end

function paths = build_paths(cfg)
paths = struct();
paths.releaseBoundaryManifest = cfg.phase17.releaseBoundaryManifestFile;
paths.finalClaimTable = cfg.phase17.finalClaimTableFile;
paths.futureWorkQueue = cfg.phase17.futureWorkQueueFile;
paths.scopePolicy = cfg.phase17.scopePolicyFile;
paths.gateSummary = cfg.phase17.gateSummaryFile;
paths.handoffStatus = cfg.phase17.handoffStatusFile;
paths.sourceProvenance = cfg.phase17.sourceProvenanceFile;
paths.figurePng = [cfg.phase17.figureBaseFile '.png'];
paths.figurePdf = [cfg.phase17.figureBaseFile '.pdf'];
end

function inputs = load_inputs(cfg)
inputs = struct();
inputs.phase16EHandoff = read_required_table(cfg.phase16E.handoffStatusFile);
inputs.phase16EGates = read_required_table(cfg.phase16E.gateSummaryFile);
inputs.phase16EClaims = read_required_table(cfg.phase16E.finalModelClaimsFile);
inputs.phase16EExcludedClaims = read_required_table( ...
    cfg.phase16E.excludedClaimsFile);
inputs.phase16EPreferred = read_required_table( ...
    cfg.phase16E.preferredReducedModelFile);
inputs.phase16ELimitations = read_required_table( ...
    cfg.phase16E.limitationLedgerFile);
inputs.phase16EProvenance = read_required_table( ...
    cfg.phase16E.sourceProvenanceFile);
end

function T = read_required_table(pathValue)
if exist(pathValue, 'file') ~= 2
    error('Required Phase 17 input is missing: %s', pathValue);
end
T = readtable(pathValue, 'TextType', 'string', ...
    'VariableNamingRule', 'preserve', 'Delimiter', ',');
end

function provenance = build_source_provenance(cfg)
sourceStatus = v800.git_tree_status(cfg.repoRoot);
phase16ECommit = string(cfg.phase17.frozenPhase16EArtifactCommit);
item = [
    "phase"
    "source_commit_sha"
    "source_tree_sha"
    "source_pre_run_tracked_clean"
    "source_pre_run_untracked_clean"
    "source_pre_run_clean"
    "frozen_phase16E_artifact_commit"
    "frozen_phase16E_artifact_commit_reachable"
    "provenance_scope"
    ];
value = [
    "phase17_final_release_or_targeted_future_work"
    sourceStatus.commit_sha
    sourceStatus.tree_sha
    string(sourceStatus.tracked_clean)
    string(sourceStatus.untracked_clean)
    string(sourceStatus.tracked_clean && sourceStatus.untracked_clean)
    phase16ECommit
    string(git_commit_is_ancestor(cfg.repoRoot, phase16ECommit))
    "read_only_release_boundary_and_future_work_handoff"
    ];
note = [
    "Final release boundary and targeted future-work handoff."
    "Git commit captured before this runner writes outputs."
    "Git tree captured before output generation."
    "Tracked-source cleanliness before output generation."
    "Untracked-source/artifact cleanliness before output generation."
    "True only when source tree is fully clean before output generation."
    "Closed Phase 16E artifact commit."
    "True when Phase 16E artifact commit is in history."
    "No solver rerun, residual lookahead, new mechanism, or parameter retuning."
    ];
provenance = table(item, value, note);
end

function tf = git_commit_is_ancestor(repoRoot, commit)
[status, ~] = system(sprintf( ...
    'git -C "%s" merge-base --is-ancestor %s HEAD', repoRoot, commit));
tf = status == 0;
end

function manifest = build_release_boundary_manifest(cfg, inputs)
item = [
    "phase16E_closure"
    "closed_model_family"
    "primary_field_model"
    "preferred_spatial_representation"
    "unique_Wij_recovery"
    "shared_quantitative_predictor"
    "future_work_status"
    "release_boundary"
    ];
value = [
    lookup_value(inputs.phase16EHandoff, "phase16E_closure")
    string(cfg.phase17.closedModelFamily)
    lookup_value(inputs.phase16EHandoff, "preferred_field_model")
    lookup_value(inputs.phase16EHandoff, ...
        "preferred_spatial_representation")
    lookup_value(inputs.phase16EHandoff, "unique_Wij_recovery")
    lookup_value(inputs.phase16EHandoff, "shared_quantitative_predictor")
    "optional_targeted_work_only"
    "closed_after_phase16E"
    ];
status = [
    "consumed"
    "frozen"
    "frozen"
    "frozen"
    "blocked_claim_preserved"
    "blocked_claim_preserved"
    "separated_from_closed_model"
    "declared"
    ];
manifest = table(item, value, status);
end

function claims = build_final_claim_table(inputs)
allowed = inputs.phase16EClaims;
if any(strcmp(allowed.Properties.VariableNames, "claim"))
    allowed.claim_text = allowed.claim;
elseif any(strcmp(allowed.Properties.VariableNames, "item"))
    allowed.claim_text = allowed.item;
else
    allowed.claim_text = string(allowed{:, 1});
end
if any(strcmp(allowed.Properties.VariableNames, "allowed_in_manuscript"))
    allowed.allowed = logical(allowed.allowed_in_manuscript);
else
    allowed.allowed = true(height(allowed), 1);
end
allowed.claim_source = repmat("phase16E_final_claims", height(allowed), 1);

blocked = inputs.phase16EExcludedClaims;
blocked.claim_source = repmat("phase16E_blocked", height(blocked), 1);
if any(strcmp(blocked.Properties.VariableNames, "claim"))
    blocked.claim_text = blocked.claim;
elseif any(strcmp(blocked.Properties.VariableNames, "excluded_claim"))
    blocked.claim_text = blocked.excluded_claim;
elseif any(strcmp(blocked.Properties.VariableNames, "item"))
    blocked.claim_text = blocked.item;
else
    blocked.claim_text = string(blocked{:, 1});
end
blocked.allowed = false(height(blocked), 1);

claim_text = [allowed.claim_text; blocked.claim_text];
claim_source = [allowed.claim_source; blocked.claim_source];
allowed_in_closed_model = [allowed.allowed; blocked.allowed];
claims = table(claim_text, claim_source, allowed_in_closed_model);
end

function queue = build_future_work_queue()
work_item = [
    "registered_Raman_spatial_rescore"
    "raw_field_metadata_expansion"
    "sparse_phase_loop_exploration"
    "additional_device_field_maps"
    "manuscript_claim_packaging"
    ];
priority = [2; 1; 3; 2; 1];
status = [
    "optional_data_dependent"
    "targeted_if_raw_metadata_available"
    "deferred_after_closed_model"
    "future_experimental_extension"
    "ready_after_phase17"
    ];
guardrail = [
    "No Raman-transport fitting or unique strain-map claim."
    "No electrothermal or hysteresis claim without sweep branches."
    "No dense Pphi primary claim or manual period fitting."
    "No relabeling of Phase 16E device conclusions."
    "Use frozen allowed/blocked claim tables."
    ];
queue = table(work_item, priority, status, guardrail);
end

function policy = build_scope_policy(cfg)
policy_item = [
    "closed_model_family"
    "new_physics"
    "parameter_retuning"
    "solver_rerun"
    "future_work"
    "claim_boundary"
    ];
policy_value = [
    string(cfg.phase17.closedModelFamily)
    "prohibited_in_phase17"
    "prohibited_in_phase17"
    "prohibited_in_phase17"
    "allowed_only_as_separate_targeted_queue"
    "Phase 16E claims are historical frozen input"
    ];
policy = table(policy_item, policy_value);
end

function gates = build_gate_summary(cfg, inputs, sourceProvenance, ...
    releaseBoundaryManifest, finalClaimTable, futureWorkQueue)
gate = [
    "Phase 16E closure consumed"
    "Phase 16E artifact commit reachable"
    "Closed model family retained"
    "PB retained as field model"
    "Reduced geometry basis retained"
    "Unique Wij claim remains blocked"
    "Shared quantitative predictor remains blocked"
    "Allowed and blocked claims separated"
    "Targeted future work queue emitted"
    "No new mechanism"
    "No parameter retuning"
    "No solver rerun"
    "Clean provenance"
    ];
condition = [
    lookup_value(inputs.phase16EHandoff, "phase16E_closure") == ...
        "pass_final_recoverability_claim_freeze"
    git_commit_is_ancestor(cfg.repoRoot, ...
        string(cfg.phase17.frozenPhase16EArtifactCommit))
    releaseBoundaryManifest.value( ...
        releaseBoundaryManifest.item == "closed_model_family") == ...
        string(cfg.phase17.closedModelFamily)
    releaseBoundaryManifest.value( ...
        releaseBoundaryManifest.item == "primary_field_model") == ...
        string(cfg.phase17.primaryFieldModel)
    releaseBoundaryManifest.value( ...
        releaseBoundaryManifest.item == ...
        "preferred_spatial_representation") == ...
        "reduced_geometry_class_basis"
    releaseBoundaryManifest.value( ...
        releaseBoundaryManifest.item == "unique_Wij_recovery") == "false"
    releaseBoundaryManifest.value( ...
        releaseBoundaryManifest.item == ...
        "shared_quantitative_predictor") == "not_established"
    any(finalClaimTable.allowed_in_closed_model) && ...
        any(~finalClaimTable.allowed_in_closed_model)
    height(futureWorkQueue) >= 3
    logical(cfg.phase17.noNewMechanism)
    logical(cfg.phase17.noParameterRetuning)
    logical(cfg.phase17.noSolverRerun)
    lookup_provenance_bool(sourceProvenance, "source_pre_run_clean")
    ];
outcome = strings(numel(gate), 1);
outcome(condition) = "pass";
outcome(~condition) = "fail";
note = [
    "Phase 17 consumes the closed Phase 16E result."
    "The Phase 16E artifact commit is reachable from this run."
    "The reduced model family is unchanged."
    "The monotonic AS006 field baseline remains PB."
    "The spatial representation remains reduced geometry classes."
    "Unique local W_ij recovery is not promoted."
    "A universal quantitative predictor is not promoted."
    "Allowed uses and prohibited claims are machine-readable."
    "Future work is queued without reopening the closed model."
    "No new physics class is introduced."
    "No model parameter is retuned."
    "No solver or residual campaign is rerun."
    "Source tree was clean before artifact generation."
    ];
gates = table(gate, outcome, condition, note);
end

function handoff = build_handoff_status(cfg, gateSummary, releaseBoundaryManifest)
allPass = all(gateSummary.outcome == "pass");
item = [
    "phase17_closure"
    "workflow_integrity"
    "release_boundary"
    "closed_model_family"
    "preferred_field_model"
    "future_work_status"
    "next_phase"
    ];
value = [
    choose_string(allPass, ...
        "pass_final_release_future_work_handoff", ...
        "fail_phase17_release_handoff")
    choose_string(allPass, "pass", "fail")
    releaseBoundaryManifest.value( ...
        releaseBoundaryManifest.item == "release_boundary")
    string(cfg.phase17.closedModelFamily)
    string(cfg.phase17.primaryFieldModel)
    "optional_targeted_work_only"
    string(cfg.phase17.nextPhase)
    ];
handoff = table(item, value);
end

function value = lookup_value(T, key)
names = string(T.Properties.VariableNames);
keyColumns = ["item"; "field"; "key"; "gate"; "quantity"];
valueColumns = ["value"; "status"; "outcome"; "claim_status"; "closure"];
keyColumn = keyColumns(find(ismember(keyColumns, names), 1));
valueColumn = valueColumns(find(ismember(valueColumns, names), 1));
if isempty(keyColumn) || isempty(valueColumn)
    value = "";
    return;
end
rows = normalize_lookup_text(T.(keyColumn)) == normalize_lookup_text(key);
if nnz(rows) ~= 1
    value = "";
    return;
end
value = clean_lookup_value(T.(valueColumn)(rows));
end

function tf = lookup_provenance_bool(T, key)
value = lookup_value(T, key);
tf = any(strcmpi(value, ["true", "1"]));
end

function out = normalize_lookup_text(value)
out = lower(strtrim(string(value)));
out = replace(out, char(65279), "");
out = replace(out, '"', "");
end

function out = clean_lookup_value(value)
out = strtrim(string(value));
out = replace(out, char(65279), "");
out = replace(out, '"', "");
end

function value = choose_string(condition, trueValue, falseValue)
if condition
    value = string(trueValue);
else
    value = string(falseValue);
end
end
