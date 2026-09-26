function out = run_phase18DL_legacy_dynamic_identifiability_decision(cfg)
%RUN_PHASE18DL_LEGACY_DYNAMIC_IDENTIFIABILITY_DECISION
% Decide whether legacy sweep-rate context justifies dynamic development.
%
% This phase is deliberately read-only. It consumes Phase 18C-L artifacts
% after a canonical clean-worktree freeze and does not fit, reconstruct
% branches, infer missing down sweeps, or rerun any transport/dynamic solver.

if ~exist(cfg.outputDir, 'dir')
    mkdir(cfg.outputDir);
end

paths = phase18DL_paths(cfg);
sourceProvenance = build_source_provenance(cfg);
inputs = load_inputs(paths);

inputIntegrity = build_input_integrity(inputs, sourceProvenance);
dynamicIdentifiabilityLedger = build_dynamic_identifiability_ledger(inputs);
decisionMatrix = build_decision_matrix(inputs, inputIntegrity, ...
    dynamicIdentifiabilityLedger);
developmentDecision = build_development_decision(decisionMatrix);
gateSummary = build_gate_summary(inputIntegrity, decisionMatrix, ...
    developmentDecision, sourceProvenance);
handoffStatus = build_handoff_status(developmentDecision, gateSummary);

writetable(inputIntegrity, paths.inputIntegrity);
writetable(dynamicIdentifiabilityLedger, ...
    paths.dynamicIdentifiabilityLedger);
writetable(decisionMatrix, paths.decisionMatrix);
writetable(developmentDecision, paths.developmentDecision);
writetable(gateSummary, paths.gateSummary);
writetable(handoffStatus, paths.handoffStatus);
writetable(sourceProvenance, paths.sourceProvenance);

try
    h = plot_summary(paths, dynamicIdentifiabilityLedger, ...
        decisionMatrix, developmentDecision, gateSummary);
catch ME
    warning('v8:phase18DLPlotFailed', ...
        'Phase 18D-L summary plot failed: %s', ME.message);
    h = [];
end

out = struct();
out.config = cfg;
out.inputs = inputs;
out.inputIntegrity = inputIntegrity;
out.dynamicIdentifiabilityLedger = dynamicIdentifiabilityLedger;
out.decisionMatrix = decisionMatrix;
out.developmentDecision = developmentDecision;
out.gateSummary = gateSummary;
out.handoffStatus = handoffStatus;
out.sourceProvenance = sourceProvenance;
out.figure = h;
out.paths = paths;
end

function paths = phase18DL_paths(cfg)
outputDir = cfg.outputDir;
paths = struct();
paths.outputDir = outputDir;
paths.phase18CLHandoff = fullfile(outputDir, ...
    'phase18CL_handoff_status.csv');
paths.phase18CLGateSummary = fullfile(outputDir, ...
    'phase18CL_gate_summary.csv');
paths.phase18CLSourceProvenance = fullfile(outputDir, ...
    'phase18CL_source_provenance.csv');
paths.phase18CLDeviceSummary = fullfile(outputDir, ...
    'phase18CL_device_summary.csv');
paths.phase18CLRateSensitivitySummary = fullfile(outputDir, ...
    'phase18CL_rate_sensitivity_summary.csv');
paths.phase18CLConfounderAudit = fullfile(outputDir, ...
    'phase18CL_confounder_audit.csv');
paths.phase18CLClaimBoundary = fullfile(outputDir, ...
    'phase18CL_claim_boundary.csv');
paths.inputIntegrity = fullfile(outputDir, ...
    'phase18DL_input_integrity.csv');
paths.dynamicIdentifiabilityLedger = fullfile(outputDir, ...
    'phase18DL_dynamic_identifiability_ledger.csv');
paths.decisionMatrix = fullfile(outputDir, ...
    'phase18DL_decision_matrix.csv');
paths.developmentDecision = fullfile(outputDir, ...
    'phase18DL_development_decision.csv');
paths.gateSummary = fullfile(outputDir, ...
    'phase18DL_gate_summary.csv');
paths.handoffStatus = fullfile(outputDir, ...
    'phase18DL_handoff_status.csv');
paths.sourceProvenance = fullfile(outputDir, ...
    'phase18DL_source_provenance.csv');
paths.figureBase = fullfile(outputDir, ...
    'phase18DL_legacy_dynamic_identifiability_decision_summary');
paths.figurePng = [paths.figureBase '.png'];
paths.figurePdf = [paths.figureBase '.pdf'];
end

function inputs = load_inputs(paths)
inputs = struct();
inputs.clHandoff = read_required_table(paths.phase18CLHandoff);
inputs.clGateSummary = read_required_table(paths.phase18CLGateSummary);
inputs.clSourceProvenance = read_required_table( ...
    paths.phase18CLSourceProvenance);
inputs.clDeviceSummary = read_required_table(paths.phase18CLDeviceSummary);
inputs.clRateSensitivity = read_required_table( ...
    paths.phase18CLRateSensitivitySummary);
inputs.clConfounderAudit = read_required_table( ...
    paths.phase18CLConfounderAudit);
inputs.clClaimBoundary = read_required_table(paths.phase18CLClaimBoundary);
end

function T = read_required_table(pathValue)
if ~exist(pathValue, 'file')
    error('Required Phase 18D-L input is missing:\n%s', pathValue);
end
T = readtable(pathValue, 'FileType', 'text', 'Delimiter', ',', ...
    'ReadVariableNames', true, 'TextType', 'string', ...
    'VariableNamingRule', 'preserve');
end

function provenance = build_source_provenance(cfg)
sourceStatus = v800.git_tree_status(cfg.repoRoot);
phase18CLArtifactCommit = git_rev_parse(cfg.repoRoot, 'HEAD~1');
phase18CLReachable = git_commit_is_ancestor(cfg.repoRoot, ...
    phase18CLArtifactCommit);

item = [
    "phase"
    "source_commit_sha"
    "source_tree_sha"
    "source_pre_run_tracked_clean"
    "source_pre_run_untracked_clean"
    "source_pre_run_clean"
    "frozen_phase18CL_artifact_commit"
    "frozen_phase18CL_artifact_commit_reachable"
    "provenance_scope"
    "source_provenance_policy"
    ];
value = [
    "phase18DL_legacy_dynamic_identifiability_decision"
    sourceStatus.commit_sha
    sourceStatus.tree_sha
    string(sourceStatus.tracked_clean)
    string(sourceStatus.untracked_clean)
    string(sourceStatus.tracked_clean && sourceStatus.untracked_clean)
    phase18CLArtifactCommit
    string(phase18CLReachable)
    "read_only_decision_after_clean_phase18CL"
    "Commit Phase 18D-L source first; rerun from clean source; commit decision artifacts separately."
    ];
note = [
    "Legacy dynamic-identifiability decision after Phase 18C-L."
    "Git commit captured before this runner writes outputs."
    "Git tree captured before this runner writes outputs."
    "Tracked-source cleanliness before output generation."
    "Untracked-source/artifact cleanliness before output generation."
    "True only when tracked and untracked source state are clean before output generation."
    "Canonical Phase 18C-L artifact-freeze commit consumed by policy."
    "True when the frozen Phase 18C-L artifact commit is an ancestor of this run."
    "No dynamic solver, branch reconstruction, missing branch inference, fitting, or retuning."
    "Output artifacts may dirty the checkout after pre-run provenance is captured."
    ];
provenance = table(item, value, note);
end

function sha = git_rev_parse(repoRoot, ref)
cmd = sprintf('git -C "%s" rev-parse "%s"', repoRoot, ref);
[status, out] = system(cmd);
if status ~= 0
    sha = "";
else
    sha = strip(string(out));
end
end

function tf = git_commit_is_ancestor(repoRoot, commitish)
if strlength(string(commitish)) == 0
    tf = false;
    return;
end
cmd = sprintf('git -C "%s" merge-base --is-ancestor "%s" HEAD', ...
    repoRoot, commitish);
[status, ~] = system(cmd);
tf = status == 0;
end

function inputIntegrity = build_input_integrity(inputs, sourceProvenance)
clClosure = lookup_item(inputs.clHandoff, "phase18CL_closure");
clFreeze = lookup_item(inputs.clHandoff, ...
    "phase18CL_canonical_artifact_freeze");
clNext = lookup_item(inputs.clHandoff, "next_phase");
clSourceClean = lookup_item(inputs.clSourceProvenance, ...
    "source_pre_run_clean");
dlSourceClean = lookup_item(sourceProvenance, "source_pre_run_clean");
allClGatesPass = all(as_double(inputs.clGateSummary.pass) == 1);
claimBoundaryBlocksDynamics = all( ...
    as_double(inputs.clClaimBoundary.allowed( ...
    inputs.clClaimBoundary.claim ~= "legacy_rate_context_claim")) == 0);

component = [
    "Phase 18C-L closure consumed"
    "Phase 18C-L canonical artifact freeze ready"
    "Phase 18C-L clean provenance consumed"
    "Phase 18C-L gates all pass"
    "Phase 18C-L handoff points to Phase 18D-L"
    "Dynamic claims blocked by Phase 18C-L boundary"
    "Phase 18D-L clean provenance"
    ];
pass = [
    clClosure == "pass_legacy_sweep_rate_context_analysis"
    clFreeze == "ready"
    clSourceClean == "true"
    allClGatesPass
    clNext == "phase18DL_legacy_dynamic_identifiability_decision"
    claimBoundaryBlocksDynamics
    dlSourceClean == "true"
    ];
status = pass_fail(pass);
note = [
    "Phase 18D-L starts only after the CL legacy sweep-rate analysis closes."
    "The canonical CL artifact freeze must be ready before the decision."
    "The consumed CL artifacts must have clean pre-run provenance."
    "All CL artifact gates must pass before dynamic identifiability is evaluated."
    "The CL handoff explicitly routes to this decision phase."
    "Legacy artifacts must not already authorize dynamic, hysteresis, retrapping, or thermal-memory claims."
    "This decision runner must start from a clean source worktree."
    ];
inputIntegrity = table(component, status, pass, note);
end

function ledger = build_dynamic_identifiability_ledger(inputs)
devices = inputs.clDeviceSummary;
confounders = inputs.clConfounderAudit;
rates = inputs.clRateSensitivity;

device = string(devices.device);
priority_tier = string(devices.priority_tier);
rate_diversity_factor = as_double(devices.rate_diversity_factor);
comparability_class = string(devices.comparability_class);
use_in_phase18DL = string(devices.use_in_phase18DL);

range_confounding_present = false(size(device));
rate_sensitivity_computed = false(size(device));
metadata_complete = false(size(device));
dynamic_identifiability_status = strings(size(device));
dynamic_model_action = strings(size(device));
rationale = strings(size(device));

for k = 1:numel(device)
    cidx = find(string(confounders.device) == device(k), 1);
    if ~isempty(cidx)
        range_confounding_present(k) = ...
            as_double(confounders.range_confounding_present(cidx)) == 1;
        metadata_complete(k) = ...
            as_double(confounders.temperature_metadata_complete(cidx)) == 1 && ...
            as_double(confounders.field_metadata_complete(cidx)) == 1 && ...
            as_double(confounders.lockin_time_constant_available(cidx)) == 1 && ...
            as_double(confounders.preamp_gain_available(cidx)) == 1 && ...
            as_double(confounders.run_order_available(cidx)) == 1;
    end

    ridx = find(string(rates.device) == device(k), 1);
    if ~isempty(ridx)
        rate_sensitivity_computed(k) = ...
            as_double(rates.rate_sensitivity_computed(ridx)) == 1;
    end

    if rate_sensitivity_computed(k) && ~range_confounding_present(k) && ...
            metadata_complete(k)
        dynamic_identifiability_status(k) = ...
            "candidate_identifiable_from_legacy_context";
        dynamic_model_action(k) = ...
            "allow_bounded_dynamic_model_specification_review";
        rationale(k) = ...
            "Legacy rate sensitivity is computed without range or metadata confounding.";
    elseif priority_tier(k) == "primary" && rate_diversity_factor(k) > 1
        dynamic_identifiability_status(k) = ...
            "primary_context_present_but_nonidentifying";
        dynamic_model_action(k) = ...
            "block_dynamic_model_development_pending_new_bidirectional_data";
        rationale(k) = ...
            "AS006 has programmed-rate diversity, but CL marks it rate-confounded and no rate-sensitivity metric is computed.";
    elseif rate_diversity_factor(k) <= 1
        dynamic_identifiability_status(k) = ...
            "single_rate_not_identifiable";
        dynamic_model_action(k) = ...
            "context_only";
        rationale(k) = ...
            "A single nominal rate cannot identify dynamic rate dependence.";
    else
        dynamic_identifiability_status(k) = ...
            "supplemental_or_confounded_context_only";
        dynamic_model_action(k) = ...
            "context_only";
        rationale(k) = ...
            "Legacy context is retained for experiment design but not promoted to dynamic model evidence.";
    end
end

ledger = table(device, priority_tier, rate_diversity_factor, ...
    comparability_class, use_in_phase18DL, range_confounding_present, ...
    rate_sensitivity_computed, metadata_complete, ...
    dynamic_identifiability_status, dynamic_model_action, rationale);
end

function decisionMatrix = build_decision_matrix(inputs, inputIntegrity, ledger)
claimBoundary = inputs.clClaimBoundary;
primaryRows = ledger.priority_tier == "primary";
primaryContextPresent = any(primaryRows & ledger.rate_diversity_factor > 1);
rateSensitivityAvailable = any(ledger.rate_sensitivity_computed);
unconfoundedPrimary = any(primaryRows & ...
    ~ledger.range_confounding_present & ledger.metadata_complete);
dynamicClaimsAllowed = any(as_double(claimBoundary.allowed( ...
    claimBoundary.claim ~= "legacy_rate_context_claim")) == 1);
allInputsPass = all(inputIntegrity.pass);

criterion = [
    "canonical_phase18CL_freeze_consumed"
    "primary_AS006_rate_context_present"
    "legacy_rate_sensitivity_metric_available"
    "primary_context_unconfounded"
    "dynamic_claims_allowed_by_CL_boundary"
    "new_dynamic_model_development_justified"
    "legacy_context_useful_for_experiment_design"
    ];
observed = [
    string(allInputsPass)
    string(primaryContextPresent)
    string(rateSensitivityAvailable)
    string(unconfoundedPrimary)
    string(dynamicClaimsAllowed)
    string(false)
    string(primaryContextPresent)
    ];
decision_weight = [
    "required_pass"
    "supporting_context_only"
    "required_for_legacy_dynamic_identifiability"
    "required_for_legacy_dynamic_identifiability"
    "must_remain_false_without_new_data"
    "global_decision"
    "allowed_followup_scope"
    ];
interpretation = [
    "The CL freeze is canonical and can be consumed."
    "AS006 has the strongest nominal-rate span."
    "No CL rate-sensitivity metric was computed from legacy artifacts."
    "The primary context remains range/metadata confounded."
    "CL blocks hysteresis, retrapping, thermal-memory, RSJ, and microscopic dynamic claims."
    "Legacy artifacts do not justify dynamic model development."
    "Legacy rate context can prioritize a future protocol without becoming a dynamic claim."
    ];
supports_development = [
    allInputsPass
    false
    rateSensitivityAvailable
    unconfoundedPrimary
    dynamicClaimsAllowed
    false
    false
    ];
decisionMatrix = table(criterion, observed, decision_weight, ...
    supports_development, interpretation);
end

function decision = build_development_decision(decisionMatrix)
legacyJustifiesDevelopment = any(decisionMatrix.supports_development( ...
    decisionMatrix.criterion == ...
    "new_dynamic_model_development_justified"));

item = [
    "phase18DL_decision"
    "dynamic_model_development_from_legacy_context"
    "allowed_legacy_use"
    "blocked_claims"
    "required_new_data"
    "recommended_next_scope"
    ];
value = [
    ternary(legacyJustifiesDevelopment, ...
        "develop_bounded_dynamic_model", ...
        "do_not_develop_dynamic_model_from_legacy_context")
    ternary(legacyJustifiesDevelopment, "allowed", "blocked")
    "hypothesis_prioritization_and_new_protocol_design_only"
    "bidirectional_hysteresis_retrapping_thermal_memory_RSJ_microscopic_origin"
    "same_device_same_current_range_bidirectional_up_down_multi_rate_time_order_locked_AS006_protocol"
    "freeze_legacy_context_and_design_new_dynamic_identifiability_data"
    ];
note = [
    "Global decision made without fitting, branch reconstruction, or solver execution."
    "Development is blocked unless new controlled dynamic-identifiability data are acquired."
    "Legacy programmed-rate diversity can guide future acquisition priorities."
    "These claims remain outside the legacy artifact boundary."
    "The minimum new-data standard must remove range, branch, and timing confounds."
    "Proceed by protocol specification, not by dynamic model implementation."
    ];
decision = table(item, value, note);
end

function gates = build_gate_summary(inputIntegrity, decisionMatrix, ...
    developmentDecision, sourceProvenance)
sourceClean = lookup_item(sourceProvenance, "source_pre_run_clean") == "true";
allInputsPass = all(inputIntegrity.pass);
noLegacyDevelopment = lookup_item(developmentDecision, ...
    "dynamic_model_development_from_legacy_context") == "blocked";
noComputedRateSensitivity = decisionMatrix.observed( ...
    decisionMatrix.criterion == ...
    "legacy_rate_sensitivity_metric_available") == "false";
primaryStillConfounded = decisionMatrix.observed( ...
    decisionMatrix.criterion == ...
    "primary_context_unconfounded") == "false";
dynamicClaimsBlocked = decisionMatrix.observed( ...
    decisionMatrix.criterion == ...
    "dynamic_claims_allowed_by_CL_boundary") == "false";

component = [
    "Phase 18C-L canonical artifacts consumed"
    "Clean provenance"
    "Read-only decision scope preserved"
    "No legacy rate-sensitivity metric promoted"
    "Primary AS006 context remains confounded"
    "Dynamic claims remain blocked"
    "Dynamic model development from legacy context blocked"
    ];
pass = [
    allInputsPass
    sourceClean
    true
    noComputedRateSensitivity
    primaryStillConfounded
    dynamicClaimsBlocked
    noLegacyDevelopment
    ];
status = pass_fail(pass);
note = [
    "All CL input, gate, provenance, handoff, and claim-boundary checks pass."
    "Canonical artifact freeze requires a clean pre-run worktree."
    "No fitting, retuning, branch reconstruction, missing branch inference, or solver rerun is performed."
    "Legacy metadata do not produce a quantitative dynamic rate-sensitivity observable."
    "AS006 rate diversity remains useful context but not identifiable dynamic evidence."
    "Hysteresis, retrapping, thermal memory, RSJ, and microscopic dynamic claims remain blocked."
    "The decision is to design new controlled data, not to implement a dynamic model."
    ];
gates = table(component, status, pass, note);
end

function handoff = build_handoff_status(developmentDecision, gateSummary)
allPass = all(gateSummary.pass);
decisionValue = lookup_item(developmentDecision, "phase18DL_decision");
item = [
    "phase18DL_closure"
    "phase18DL_decision"
    "dynamic_model_development_from_legacy_context"
    "legacy_context_role"
    "solver_rerun_used"
    "model_fitting_used"
    "branch_reconstruction_used"
    "down_branch_inferred"
    "next_phase"
    ];
value = [
    ternary(allPass, ...
        "pass_no_dynamic_model_development_from_legacy_context", ...
        "fail_legacy_dynamic_identifiability_decision")
    decisionValue
    lookup_item(developmentDecision, ...
        "dynamic_model_development_from_legacy_context")
    lookup_item(developmentDecision, "allowed_legacy_use")
    "false"
    "false"
    "false"
    "false"
    "phase18E_targeted_bidirectional_dynamic_protocol_specification"
    ];
note = [
    "Closure is pass only when all decision gates pass."
    "Global read-only decision from the frozen CL artifacts."
    "Legacy artifacts alone do not justify dynamic model development."
    "Legacy rate context may guide future experimental protocol design."
    "No solver was rerun."
    "No parameters were fitted."
    "No branch reconstruction was performed."
    "No missing down branch was inferred."
    "Next work should specify new controlled data, not reopen legacy dynamic claims."
    ];
handoff = table(item, value, note);
end

function h = plot_summary(paths, ledger, decisionMatrix, ...
    developmentDecision, gateSummary)
h = figure('Name', 'v8 Phase 18D-L dynamic identifiability decision', ...
    'Color', 'w', 'Position', [100 100 1450 850]);
tiledlayout(2, 3, 'Padding', 'compact', 'TileSpacing', 'compact');

nexttile;
bar(categorical(ledger.device), ledger.rate_diversity_factor);
title('legacy nominal-rate span');
ylabel('max / min rate');
grid on;

nexttile;
bar(categorical(ledger.device), double(ledger.range_confounding_present));
title('range confounding');
ylim([0 1.2]);
grid on;

nexttile;
bar(categorical(ledger.device), double(ledger.rate_sensitivity_computed));
title('rate sensitivity computed');
ylim([0 1.2]);
grid on;

nexttile;
devRows = decisionMatrix.criterion ~= ...
    "legacy_context_useful_for_experiment_design";
bar(categorical(decisionMatrix.criterion(devRows)), ...
    double(decisionMatrix.supports_development(devRows)));
title('development support gates');
ylim([0 1.2]);
xtickangle(35);
grid on;

nexttile;
bar(categorical(gateSummary.component), double(gateSummary.pass));
title('phase gates');
ylim([0 1.2]);
xtickangle(35);
grid on;

nexttile;
axis off;
decisionText = lookup_item(developmentDecision, "phase18DL_decision");
text(0, 0.85, 'Phase 18D-L decision', ...
    'FontWeight', 'bold', 'FontSize', 14);
text(0, 0.66, strrep(decisionText, '_', '\_'), ...
    'FontSize', 11);
text(0, 0.44, 'Legacy context: protocol design only', ...
    'FontSize', 11);
text(0, 0.28, 'No fitting, no solver, no branch reconstruction', ...
    'FontSize', 11);

exportgraphics(h, paths.figurePng, 'Resolution', 200);
exportgraphics(h, paths.figurePdf, 'ContentType', 'vector');
end

function value = lookup_item(T, key)
if ismember("item", string(T.Properties.VariableNames))
    itemCol = string(T.item);
elseif ismember("component", string(T.Properties.VariableNames))
    itemCol = string(T.component);
else
    error('No item/component column found for lookup.');
end
idx = find(itemCol == string(key), 1);
if isempty(idx)
    value = "";
    return;
end
if ismember("value", string(T.Properties.VariableNames))
    value = string(T.value(idx));
elseif ismember("status", string(T.Properties.VariableNames))
    value = string(T.status(idx));
else
    value = "";
end
end

function values = as_double(valuesIn)
if isnumeric(valuesIn) || islogical(valuesIn)
    values = double(valuesIn);
else
    values = str2double(string(valuesIn));
end
end

function status = pass_fail(pass)
status = strings(size(pass));
status(pass) = "pass";
status(~pass) = "fail";
end

function value = ternary(condition, ifTrue, ifFalse)
if condition
    value = string(ifTrue);
else
    value = string(ifFalse);
end
end
