function out = run_phase10_reproducible_release(cfg)
%RUN_PHASE10_REPRODUCIBLE_RELEASE Build the final v8 reproducibility dossier.

if ~exist(cfg.outputDir, 'dir')
    mkdir(cfg.outputDir);
end

sourceProvenance = build_source_provenance(cfg);
inputs = load_phase10_inputs(cfg);
releaseManifest = build_release_manifest(cfg);
artifactChecksums = build_artifact_checksums(releaseManifest);
regenerationRecipe = build_regeneration_recipe(cfg);
releaseNotes = build_release_notes(cfg, inputs);
gateSummary = build_gate_summary(cfg, inputs, releaseManifest, ...
    artifactChecksums, sourceProvenance);
handoffStatus = build_handoff_status(cfg, gateSummary, sourceProvenance);

writetable(releaseManifest, cfg.phase10.releaseManifestFile);
writetable(artifactChecksums, cfg.phase10.artifactChecksumFile);
writetable(regenerationRecipe, cfg.phase10.regenerationRecipeFile);
writetable(releaseNotes, cfg.phase10.releaseNotesFile);
writetable(gateSummary, cfg.phase10.gateSummaryFile);
writetable(handoffStatus, cfg.phase10.handoffStatusFile);
writetable(sourceProvenance, cfg.phase10.sourceProvenanceFile);

try
    h = v800.plot_phase10_reproducible_release(cfg, releaseManifest, ...
        artifactChecksums, gateSummary, sourceProvenance);
catch ME
    warning('v8:phase10PlotFailed', ...
        'Phase 10 release summary plot failed: %s', ME.message);
    h = [];
end

out = struct();
out.config = cfg;
out.inputs = inputs;
out.releaseManifest = releaseManifest;
out.artifactChecksums = artifactChecksums;
out.regenerationRecipe = regenerationRecipe;
out.releaseNotes = releaseNotes;
out.gateSummary = gateSummary;
out.handoffStatus = handoffStatus;
out.sourceProvenance = sourceProvenance;
out.figure = h;
out.paths = struct();
out.paths.releaseManifest = cfg.phase10.releaseManifestFile;
out.paths.artifactChecksums = cfg.phase10.artifactChecksumFile;
out.paths.regenerationRecipe = cfg.phase10.regenerationRecipeFile;
out.paths.releaseNotes = cfg.phase10.releaseNotesFile;
out.paths.gateSummary = cfg.phase10.gateSummaryFile;
out.paths.handoffStatus = cfg.phase10.handoffStatusFile;
out.paths.sourceProvenance = cfg.phase10.sourceProvenanceFile;
out.paths.figurePng = [cfg.phase10.figureBaseFile '.png'];
out.paths.figurePdf = [cfg.phase10.figureBaseFile '.pdf'];
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
    "phase10_reproducible_v8_release"
    sourceStatus.commit_sha
    sourceStatus.tree_sha
    string(sourceStatus.tracked_clean)
    string(sourceStatus.untracked_clean)
    string(sourceStatus.tracked_clean && sourceStatus.untracked_clean)
    "release_dossier_no_retuning"
    "Commit Phase 10 source/config first; run release dossier generation; commit generated release artifacts separately."
    ];
note = [
    "Phase 10 final reproducible-release dossier."
    "Git commit captured before this runner writes outputs."
    "Git tree object captured before this runner writes outputs."
    "Tracked-source cleanliness before output generation."
    "Untracked-source/artifact cleanliness before output generation."
    "True only when the checkout is clean before this run writes outputs."
    "Read-only packaging of frozen Phase 9 artifacts and release instructions."
    "The artifact commit need not be embedded in files generated before that commit exists."
    ];
provenance = table(item, value, note);
end

function inputs = load_phase10_inputs(cfg)
inputs = struct();
inputs.phase9Gates = read_optional_table(cfg.phase9.gateSummaryFile);
inputs.phase9Handoff = read_optional_table(cfg.phase9.handoffStatusFile);
inputs.phase9Provenance = read_optional_table(cfg.phase9.sourceProvenanceFile);
inputs.phase9Ledger = read_optional_table( ...
    cfg.phase9.finalDeviceConclusionLedgerFile);
inputs.phase9Raman = read_optional_table( ...
    cfg.phase9.ramanRegistrationDiagnosticFile);
inputs.phase8BGates = read_optional_table(cfg.phase8B.gateSummaryFile);
inputs.phase8BHandoff = read_optional_table(cfg.phase8B.handoffStatusFile);
end

function T = read_optional_table(pathValue)
if exist(pathValue, 'file')
    try
        T = readtable(pathValue, 'TextType', 'string', ...
            'VariableNamingRule', 'preserve', 'Delimiter', ',');
    catch
        T = readtable(pathValue, 'TextType', 'string', 'Delimiter', ',');
    end
else
    T = table();
end
end

function manifest = build_release_manifest(cfg)
rows = [
    manifest_row("phase9_final_model_specification", ...
    cfg.phase9.finalModelSpecificationFile, true, ...
    "canonical final model specification")
    manifest_row("phase9_final_device_conclusion_ledger", ...
    cfg.phase9.finalDeviceConclusionLedgerFile, true, ...
    "six-device conclusion ledger")
    manifest_row("phase9_claim_hierarchy", cfg.phase9.claimHierarchyFile, ...
    true, "permitted, required, and prohibited claims")
    manifest_row("phase9_model_limitations", cfg.phase9.modelLimitationsFile, ...
    true, "final limitation ledger")
    manifest_row("phase9_evidence_hierarchy", cfg.phase9.evidenceHierarchyFile, ...
    true, "evidence hierarchy")
    manifest_row("phase9_raman_registration_disposition", ...
    cfg.phase9.ramanRegistrationDiagnosticFile, true, ...
    "registered Raman missingness disposition")
    manifest_row("phase9_gate_summary", cfg.phase9.gateSummaryFile, true, ...
    "Phase 9 gates")
    manifest_row("phase9_handoff_status", cfg.phase9.handoffStatusFile, true, ...
    "Phase 9 closure status")
    manifest_row("phase9_source_provenance_checkpoint", ...
    cfg.phase9.sourceProvenanceFile, true, ...
    "Phase 9 source provenance")
    manifest_row("phase9_final_table_manifest", ...
    cfg.phase9.finalTableManifestFile, true, ...
    "final table manifest")
    manifest_row("phase9_final_figure_manifest", ...
    cfg.phase9.finalFigureManifestFile, true, ...
    "final figure manifest")
    manifest_row("phase9_final_model_package_summary_png", ...
    [cfg.phase9.figureBaseFile '.png'], true, ...
    "final model package summary figure")
    manifest_row("phase9_final_model_package_summary_pdf", ...
    [cfg.phase9.figureBaseFile '.pdf'], true, ...
    "final model package summary PDF")
    manifest_row("phase8B_status_stability_summary", ...
    cfg.phase8B.statusStabilityFile, true, ...
    "numerical replay stability context")
    manifest_row("phase8B_gate_summary", cfg.phase8B.gateSummaryFile, true, ...
    "Phase 8B numerical replay gates")
    manifest_row("README", fullfile(cfg.repoRoot, 'README.md'), true, ...
    "repository-level release overview")
    manifest_row("matlab_v8_0_README", fullfile(cfg.rootDir, 'README.md'), ...
    true, "v8 MATLAB release overview")
    ];
manifest = struct2table(rows);
manifest.exists = arrayfun(@(p) exist(char(p), 'file') == 2, manifest.path);
[manifest.file_size_bytes, manifest.modified_datenum] = ...
    manifest_file_metadata(manifest.path);
manifest.release_role = repmat("frozen_release_input", height(manifest), 1);
end

function checksums = build_artifact_checksums(manifest)
rows = repmat(empty_checksum_row(), height(manifest), 1);
for k = 1:height(manifest)
    rows(k).artifact_id = string(manifest.artifact_id(k));
    rows(k).path = string(manifest.path(k));
    rows(k).exists = logical(manifest.exists(k));
    if rows(k).exists
        rows(k).sha256 = file_sha256(manifest.path(k));
        rows(k).checksum_status = "computed";
    else
        rows(k).sha256 = "missing";
        rows(k).checksum_status = "missing_file";
    end
end
checksums = struct2table(rows);
end

function recipe = build_regeneration_recipe(cfg)
rows = [
    recipe_row(1, "checkout_source", ...
    "git checkout v8-roadmap", ...
    "Use the pushed v8-roadmap branch or a specific recorded commit SHA.")
    recipe_row(2, "enter_matlab_directory", ...
    "cd('<repo>/matlab_v8_0')", ...
    "Set MATLAB working directory to the v8 MATLAB folder.")
    recipe_row(3, "refresh_matlab_cache", ...
    "clear all; rehash toolboxcache", ...
    "Avoid stale package-function state before release generation.")
    recipe_row(4, "run_final_model_packaging", ...
    "out9 = run_v800_phase9_final_model_packaging", ...
    "Regenerates the final model package from frozen upstream artifacts.")
    recipe_row(5, "run_release_dossier", ...
    "out10 = run_v800_phase10_reproducible_release", ...
    "Regenerates Phase 10 checksums, release gates, and release summary.")
    recipe_row(6, "verify_release_gates", ...
    "read phase10_release_gate_summary.csv and phase10_handoff_status.csv", ...
    "Scientific closure can pass even when full untracked cleanliness is caveated.")
    ];
recipe = struct2table(rows);
end

function notes = build_release_notes(cfg, inputs)
phase9Closure = lookup_status(inputs.phase9Handoff, ...
    "phase9_closure", "unknown");
ramanDisposition = lookup_status(inputs.phase9Handoff, ...
    "quantitative_raman_prior_rescore", "unknown");
rows = [
    note_row("release_name", string(cfg.phase10.releaseName), ...
    "Human-readable release name.")
    note_row("release_scope", string(cfg.phase10.releaseScope), ...
    "Phase 10 performs packaging and verification only.")
    note_row("model_retuning", "false", ...
    "No model retuning is performed in Phase 10.")
    note_row("device_status_changes", "false", ...
    "Phase 10 preserves the Phase 9 final device ledger.")
    note_row("phase9_closure", phase9Closure, ...
    "Phase 9 final packaging closure consumed by Phase 10.")
    note_row("raman_registration_disposition", ramanDisposition, ...
    "Registered Raman prior remains unavailable and qualitative.")
    note_row("release_caveat", ...
    "source_pre_run_clean may be false if untracked artifacts exist before generation", ...
    "Tracked-source cleanliness is recorded separately from full untracked cleanliness.")
    ];
notes = struct2table(rows);
end

function gates = build_gate_summary(cfg, inputs, manifest, checksums, provenance)
phase9ClosurePass = lookup_status(inputs.phase9Handoff, ...
    "phase9_final_model_packaging", "fail") == "pass" && ...
    lookup_status(inputs.phase9Handoff, "phase9_closure", "fail") == ...
    "pass_final_model_packaging";
phase9ScientificGatesPass = all_phase9_scientific_gates_pass(inputs.phase9Gates);
phase8BPass = all_gate_outcomes_pass(inputs.phase8BGates);
allRequiredPresent = all(manifest.exists(manifest.required));
checksumsComputed = all(checksums.checksum_status == "computed");
noRetune = ~cfg.phase10.allowModelRetuning && ...
    ~cfg.phase10.allowDeviceStatusChanges && ...
    ~cfg.phase10.allowArtifactMutation;
trackedClean = lookup_value(provenance, "source_pre_run_tracked_clean", ...
    "false") == "true";
fullClean = lookup_value(provenance, "source_pre_run_clean", ...
    "false") == "true";
rows = [
    gate_row("Phase 9 final packaging consumed", ...
    logical_status(phase9ClosurePass), ...
    "Phase 10 consumes a passing Phase 9 final model package.")
    gate_row("Phase 9 scientific gates pass", ...
    logical_status(phase9ScientificGatesPass), ...
    "All Phase 9 gates except the clean-source provenance gate pass.")
    gate_row("Phase 8B numerical replay available", ...
    logical_status(phase8BPass), ...
    "Phase 8B frozen numerical replay gate summary is available and passing.")
    gate_row("Release manifest complete", logical_status(allRequiredPresent), ...
    "Every required release artifact exists.")
    gate_row("Artifact checksums computed", logical_status(checksumsComputed), ...
    "SHA-256 checksums were computed for every release artifact.")
    gate_row("No retuning or relabeling", logical_status(noRetune), ...
    "Phase 10 does not change model parameters, thresholds, or device labels.")
    gate_row("Tracked source provenance clean", logical_status(trackedClean), ...
    "Tracked files were clean before Phase 10 wrote outputs.")
    gate_row("Full clean checkout provenance", logical_status(fullClean), ...
    "Passes only if no untracked artifacts existed before Phase 10.")
    ];
gates = struct2table(rows);
end

function handoff = build_handoff_status(cfg, gates, provenance)
coreGateNames = [
    "Phase 9 final packaging consumed"
    "Phase 9 scientific gates pass"
    "Phase 8B numerical replay available"
    "Release manifest complete"
    "Artifact checksums computed"
    "No retuning or relabeling"
    "Tracked source provenance clean"
    ];
coreReady = all(gates.outcome(ismember(gates.gate, coreGateNames)) == "pass");
allReady = all(gates.outcome == "pass");
rows = [
    status_row("phase10_reproducible_release", logical_status(coreReady), ...
    "Final reproducible v8 release dossier generated.")
    status_row("phase10_all_gates", logical_status(allReady), ...
    "Includes full clean-checkout provenance.")
    status_row("phase10_closure", ...
    ternary_status(coreReady, "pass_reproducible_release", ...
    "fail_reproducible_release"), ...
    "Release closure ignores no scientific gate; full untracked cleanliness may be caveated.")
    status_row("release_name", string(cfg.phase10.releaseName), ...
    "Frozen release name.")
    status_row("model_retuning_performed", "false", ...
    "No model retuning occurred.")
    status_row("device_status_changes", "false", ...
    "No device status was changed.")
    status_row("source_commit_sha", lookup_value(provenance, ...
    "source_commit_sha", "unknown"), ...
    "Source commit used to generate Phase 10 release artifacts.")
    status_row("source_pre_run_clean", lookup_value(provenance, ...
    "source_pre_run_clean", "unknown"), ...
    "Full clean-checkout state before Phase 10 wrote outputs.")
    status_row("next_phase", "release_tag_or_archive", ...
    "Optional next step: tag, archive, or export the frozen v8 release.")
    ];
handoff = struct2table(rows);
end

function tf = all_phase9_scientific_gates_pass(T)
tf = ~isempty(T);
if ~tf
    return;
end
gates = table_column(T, "gate");
outcomes = table_column(T, "outcome");
if isempty(gates) || isempty(outcomes)
    tf = false;
    return;
end
scienceRows = gates ~= "Clean source provenance";
tf = all(outcomes(scienceRows) == "pass");
end

function tf = all_gate_outcomes_pass(T)
outcomes = table_column(T, "outcome");
tf = ~isempty(outcomes) && all(outcomes == "pass");
end

function status = lookup_status(T, itemName, defaultValue)
status = lookup_value(T, itemName, defaultValue);
end

function value = lookup_value(T, itemName, defaultValue)
value = string(defaultValue);
items = table_column(T, "item");
values = table_column(T, "status");
if isempty(values)
    values = table_column(T, "value");
end
if isempty(items) || isempty(values)
    return;
end
idx = items == string(itemName);
if any(idx)
    value = values(find(idx, 1, 'first'));
end
end

function values = table_column(T, requestedName)
values = strings(0, 1);
if isempty(T)
    return;
end
varNames = string(T.Properties.VariableNames);
requested = normalize_table_name(requestedName);
idx = find(normalize_table_name(varNames) == requested, 1, 'first');
if isempty(idx) && ~isempty(T.Properties.VariableDescriptions)
    descriptions = string(T.Properties.VariableDescriptions);
    idx = find(normalize_table_name(descriptions) == requested, 1, 'first');
end
if isempty(idx)
    return;
end
values = string(T.(char(varNames(idx))));
end

function out = normalize_table_name(name)
out = lower(regexprep(string(name), '[^A-Za-z0-9]+', ''));
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

function hash = file_sha256(pathValue)
hash = "unavailable";
if exist(pathValue, 'file') ~= 2
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

function row = manifest_row(id, pathValue, required, purpose)
row = struct();
row.artifact_id = string(id);
row.path = string(pathValue);
row.required = logical(required);
row.purpose = string(purpose);
end

function row = empty_checksum_row()
row = struct();
row.artifact_id = "";
row.path = "";
row.exists = false;
row.sha256 = "";
row.checksum_status = "";
end

function row = recipe_row(stepIndex, stepId, commandText, note)
row = struct();
row.step_index = stepIndex;
row.step_id = string(stepId);
row.command = string(commandText);
row.note = string(note);
end

function row = note_row(item, value, note)
row = struct();
row.item = string(item);
row.value = string(value);
row.note = string(note);
end

function row = gate_row(gate, outcome, note)
row = struct();
row.gate = string(gate);
row.outcome = string(outcome);
row.note = string(note);
end

function row = status_row(item, status, note)
row = struct();
row.item = string(item);
row.status = string(status);
row.note = string(note);
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
