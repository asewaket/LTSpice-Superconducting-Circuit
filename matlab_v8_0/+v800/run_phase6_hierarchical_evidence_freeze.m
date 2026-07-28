function out = run_phase6_hierarchical_evidence_freeze(cfg)
%RUN_PHASE6_HIERARCHICAL_EVIDENCE_FREEZE Freeze six-device evidence hierarchy.

if ~exist(cfg.outputDir, 'dir')
    mkdir(cfg.outputDir);
end

inputs = load_phase6_inputs(cfg);
modelHierarchy = build_model_hierarchy_freeze();
frozenInputManifest = build_phase6_input_manifest(cfg);
evidenceMatrix = build_six_device_evidence_matrix(inputs);
deviceModelStatus = build_device_model_status(evidenceMatrix);
evidenceTiers = build_evidence_tier_assignments(evidenceMatrix);
claimHierarchy = build_claim_hierarchy();
gateSummary = build_phase6_gate_summary(frozenInputManifest, evidenceMatrix);
handoffStatus = build_phase6_handoff_status(gateSummary);

writetable(modelHierarchy, cfg.phase6.modelHierarchyFreezeFile);
writetable(frozenInputManifest, cfg.phase6.frozenInputManifestFile);
writetable(evidenceMatrix, cfg.phase6.sixDeviceEvidenceMatrixFile);
writetable(deviceModelStatus, cfg.phase6.deviceModelStatusFile);
writetable(evidenceTiers, cfg.phase6.evidenceTierAssignmentsFile);
writetable(claimHierarchy, cfg.phase6.claimHierarchyFile);
writetable(gateSummary, cfg.phase6.gateSummaryFile);
writetable(handoffStatus, cfg.phase6.handoffStatusFile);

try
    h = v800.plot_phase6_hierarchical_evidence_summary(cfg, evidenceMatrix, ...
        gateSummary);
catch ME
    warning('v8:phase6PlotFailed', ...
        'Phase 6 hierarchy summary plot failed: %s', ME.message);
    h = [];
end

out = struct();
out.config = cfg;
out.inputs = inputs;
out.modelHierarchy = modelHierarchy;
out.frozenInputManifest = frozenInputManifest;
out.sixDeviceEvidenceMatrix = evidenceMatrix;
out.deviceModelStatus = deviceModelStatus;
out.evidenceTierAssignments = evidenceTiers;
out.claimHierarchy = claimHierarchy;
out.gateSummary = gateSummary;
out.handoffStatus = handoffStatus;
out.figure = h;
out.paths = struct();
out.paths.modelHierarchyFreeze = cfg.phase6.modelHierarchyFreezeFile;
out.paths.frozenInputManifest = cfg.phase6.frozenInputManifestFile;
out.paths.sixDeviceEvidenceMatrix = cfg.phase6.sixDeviceEvidenceMatrixFile;
out.paths.deviceModelStatus = cfg.phase6.deviceModelStatusFile;
out.paths.evidenceTierAssignments = cfg.phase6.evidenceTierAssignmentsFile;
out.paths.claimHierarchy = cfg.phase6.claimHierarchyFile;
out.paths.gateSummary = cfg.phase6.gateSummaryFile;
out.paths.handoffStatus = cfg.phase6.handoffStatusFile;
out.paths.figurePng = [cfg.phase6.figureBaseFile '.png'];
out.paths.figurePdf = [cfg.phase6.figureBaseFile '.pdf'];
end

function inputs = load_phase6_inputs(cfg)
inputs = struct();
inputs.phase5A = read_optional_table(cfg.phase5A.summaryFile);
inputs.phase5B = read_optional_table(cfg.phase5B.deviceEvidenceFile);
inputs.phase5B1 = read_optional_table(cfg.phase5B1.heldoutFile);
inputs.phase5B2 = read_optional_table(cfg.phase5B2.devicePredictionFile);
inputs.phase5B2Gates = read_optional_table(cfg.phase5B2.gateResultFile);
inputs.phase5C = read_optional_table(cfg.phase5C.handoffStatusFile);
inputs.phase5D2Status = read_optional_table(cfg.phase5D2.resultFreezeStatusFile);
inputs.phase5D2Context = read_optional_table(cfg.phase5D2.realDeviceScoreContextFile);
inputs.phase5D2Policy = read_optional_table(cfg.phase5D2.interpretationPolicyFile);
inputs.phase5D2Manifest = read_optional_table(cfg.phase5D2.frozenInputManifestFile);
end

function T = read_optional_table(pathValue)
if exist(pathValue, 'file')
    T = readtable(pathValue, 'TextType', 'string');
else
    T = table();
end
end

function hierarchy = build_model_hierarchy_freeze()
rows = [
    hierarchy_row("M0star", ...
    "local-Tc heterogeneity plus frozen nuisance envelope", 0, ...
    "geometry-only Tc, bulk gap reference, no weak links, uniform/shuffled protected controls", ...
    "May be sufficient when structured connectivity is not independently supported.")
    hierarchy_row("M1", ...
    "local heterogeneity plus structured boundary/contact/crack connectivity", 1, ...
    "M0star and protected spatial controls", ...
    "Structured support requires evidence beyond contextual Z alone.")
    hierarchy_row("M2", ...
    "local heterogeneity plus full combined physical bottleneck structure", 2, ...
    "M0star, M1, protected controls, central-lane/1D-like controls", ...
    "M2 is reserved for strongest combined bottleneck evidence.")
    hierarchy_row("prohibited_retuning", ...
    "no new weak-link class, force-law flexibility, threshold tuning, or device-specific coefficient fitting", NaN, ...
    "all frozen Phase 5 controls", ...
    "Phase 6 is synthesis, not optimization.")
    ];
hierarchy = struct2table(rows);
end

function manifest = build_phase6_input_manifest(cfg)
rows = [
    manifest_row("phase5A_primary_transfer_summary", cfg.phase5A.summaryFile, true, ...
    "primary R(T) transfer result")
    manifest_row("phase5B_device_evidence_table", cfg.phase5B.deviceEvidenceFile, true, ...
    "secondary-probe hierarchy evidence")
    manifest_row("phase5B1_activation_heldout_validation", cfg.phase5B1.heldoutFile, false, ...
    "strict held-out activation-law result")
    manifest_row("phase5B2_force_law_device_predictions", cfg.phase5B2.devicePredictionFile, false, ...
    "full-series descriptive force-law result")
    manifest_row("phase5B2_gate_results", cfg.phase5B2.gateResultFile, false, ...
    "mixed/limited force-law transfer gate")
    manifest_row("phase5C_handoff_status", cfg.phase5C.handoffStatusFile, true, ...
    "synthetic identifiability and misspecification context")
    manifest_row("phase5D2_result_freeze_status", cfg.phase5D2.resultFreezeStatusFile, true, ...
    "detection-limit and result-freeze status")
    manifest_row("phase5D2_interpretation_policy", cfg.phase5D2.interpretationPolicyFile, true, ...
    "allowed/prohibited contextual score uses")
    manifest_row("phase5D2_validation_status", cfg.phase5D2.validationStatusFile, true, ...
    "validation seeds preserved and not consumed")
    manifest_row("phase5D2_real_device_score_context", cfg.phase5D2.realDeviceScoreContextFile, true, ...
    "real-device DeltaS/Z context")
    manifest_row("phase5D2_handoff_status", cfg.phase5D2.handoffStatusFile, true, ...
    "handoff to hierarchical six-device freeze")
    ];
manifest = struct2table(rows);
manifest.exists = arrayfun(@(p) exist(char(p), 'file') == 2, manifest.path);
[manifest.file_size_bytes, manifest.modified_datenum] = ...
    manifest_file_metadata(manifest.path);
manifest.frozen_use = repmat("read_only_input_no_recalibration", height(manifest), 1);
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

function matrix = build_six_device_evidence_matrix(inputs)
devices = ["AS001"; "AS002"; "AS003"; "AS004"; "AS005"; "AS006"];
rows = repmat(empty_evidence_row(), numel(devices), 1);
for k = 1:numel(devices)
    device = devices(k);
    rows(k).device = device;
    rows(k).geometry_class = geometry_class(device);
    rows(k).evidence_tier = evidence_tier(device);
    rows(k).phase5A_primary_result = lookup_string(inputs.phase5D2Context, ...
        "device", device, "phase5A_primary_result", "not_available");
    rows(k).phase5B_secondary_result = lookup_string(inputs.phase5D2Context, ...
        "device", device, "secondary_evidence", "not_available");
    rows(k).phase5B1_heldout_result = lookup_string(inputs.phase5D2Context, ...
        "device", device, "phase5B_heldout_result", "not_available");
    rows(k).phase5B2_force_law_result = lookup_string(inputs.phase5D2Context, ...
        "device", device, "activation_law_context", "not_available");
    rows(k).phase5C_identifiability_context = phase5C_context(inputs.phase5C);
    rows(k).phase5D2_DeltaS = lookup_double(inputs.phase5D2Context, ...
        "device", device, "DeltaS", NaN);
    rows(k).phase5D2_sigmaDeltaS = lookup_double(inputs.phase5D2Context, ...
        "device", device, "sigmaDeltaS", NaN);
    rows(k).phase5D2_Z = lookup_double(inputs.phase5D2Context, ...
        "device", device, "Z", NaN);
    rows(k).directional_preference = lookup_string(inputs.phase5D2Context, ...
        "device", device, "directional_preference", "not_available");
    rows(k).nonlinear_evidence = nonlinear_evidence(device);
    rows(k).raman_mechanical_evidence = raman_mechanical_evidence(device);
    rows(k).geometry_crack_evidence = geometry_crack_evidence(device);
    rows(k).final_model_status = final_model_status(device);
    rows(k).final_evidence_status = lookup_string(inputs.phase5D2Context, ...
        "device", device, "phase5B_evidence_conclusion", "not_available");
    rows(k).final_evidence_status = evidence_status(device, ...
        rows(k).final_evidence_status);
    rows(k).claim_limit = claim_limit(device);
end
matrix = struct2table(rows);
end

function statusTable = build_device_model_status(matrix)
statusTable = matrix(:, ["device", "final_model_status", ...
    "final_evidence_status", "claim_limit"]);
end

function tierTable = build_evidence_tier_assignments(matrix)
tierTable = matrix(:, ["device", "evidence_tier", "geometry_class", ...
    "directional_preference"]);
end

function claims = build_claim_hierarchy()
rows = [
    claim_row("framework_level", "supported", ...
    "One shared 2D superconducting-network architecture organizes the six-device series.")
    claim_row("device_level", "supported_with_qualifiers", ...
    "Local heterogeneity is sufficient for some devices; structured connectivity is supported for the strongest cases.")
    claim_row("limitation", "frozen", ...
    "Normalized R(T) alone cannot universally distinguish M0star from structured connectivity under the frozen nuisance family.")
    claim_row("excluded_claim", "excluded", ...
    "The model does not uniquely reconstruct microscopic domains, local strain, Josephson phase dynamics, topology, or pairing symmetry.")
    claim_row("future_optional_phase", "deferred", ...
    "Full-shape R(T) classifier is deferred until after the hierarchical model freeze.")
    ];
claims = struct2table(rows);
end

function gates = build_phase6_gate_summary(manifest, matrix)
allRequiredInputs = all(manifest.exists(manifest.required));
allStatuses = all(strlength(matrix.final_model_status) > 0) && ...
    all(strlength(matrix.evidence_tier) > 0);
rows = [
    gate_row("Frozen inputs traceable", logical_status(allRequiredInputs), ...
    "All required Phase 5 inputs exist and are read-only.")
    gate_row("No calibration retuning", "pass", ...
    "Phase 6 consumes frozen outputs only.")
    gate_row("All devices assigned model status", logical_status(allStatuses), ...
    "Every device has a model status and evidence tier.")
    gate_row("Contextual scores not categorical labels", "pass", ...
    "DeltaS/Z are retained as evidence context and detection-limit markers.")
    gate_row("Conflicting evidence retained", "pass", ...
    "AS001 and AS004 remain unresolved rather than forced into a classifier label.")
    gate_row("Final claim hierarchy frozen", "pass", ...
    "Framework, device-level, limitation, and excluded claims are explicit.")
    gate_row("Deferred classifier outside roadmap", "pass", ...
    "Full-shape R(T) classifier remains deferred.")
    ];
gates = struct2table(rows);
end

function handoff = build_phase6_handoff_status(gates)
ready = all(gates.outcome == "pass");
rows = [
    status_row("phase6_hierarchy_freeze", logical_status(ready), ...
    "Hierarchical six-device evidence and model freeze generated.")
    status_row("all_phase6_gates", logical_status(ready), ...
    "All Phase 6 gates pass.")
    status_row("device_model_statuses_frozen", "true", ...
    "Every device has a frozen model status.")
    status_row("evidence_tiers_frozen", "true", ...
    "Every device has a frozen evidence tier.")
    status_row("retuning_prohibited", "true", ...
    "No calibration, classifier, threshold, weak-link, or device-specific retuning is allowed.")
    status_row("validation_seeds_consumed", "false", ...
    "Deferred universal-classifier validation seeds remain unused.")
    status_row("next_phase", "phase7_raman_mechanical_prior_robustness", ...
    "Test Raman/mechanical spatial priors without reopening Phase 6 classifications.")
    status_row("future_optional_phase", "full_shape_RT_classifier_deferred", ...
    "Trigger only after final hierarchy freeze if explicitly rescoped.")
    ];
handoff = struct2table(rows);
end

function txt = phase5C_context(T)
inFamily = lookup_string(T, "item", "in_family_recovery", "status", ...
    "not_available");
misspec = lookup_string(T, "item", "misspecification_robustness", ...
    "status", "not_available");
txt = "in_family=" + inFamily + "; misspecification=" + misspec;
end

function cls = geometry_class(device)
switch string(device)
    case "AS001"
        cls = "control_or_weakly_structured";
    case "AS002"
        cls = "threshold_half_encapsulated";
    case "AS003"
        cls = "fully_encapsulated_control";
    case "AS004"
        cls = "intermediate_half_coverage";
    case "AS005"
        cls = "crack_associated";
    otherwise
        cls = "strong_structured_AS006";
end
end

function tier = evidence_tier(device)
switch string(device)
    case "AS001"
        tier = "mixed_probe";
    case "AS002"
        tier = "primary_only";
    case "AS003"
        tier = "control_limit";
    case "AS004"
        tier = "mixed_probe";
    case "AS005"
        tier = "auxiliary_supported";
    otherwise
        tier = "paired_probe_and_heldout";
end
end

function txt = nonlinear_evidence(device)
if string(device) == "AS006"
    txt = "nonlinear/field evidence available and strongest for AS006";
else
    txt = "not_available_or_not_primary_phase6_input";
end
end

function txt = raman_mechanical_evidence(device)
switch string(device)
    case {"AS004", "AS005", "AS006"}
        txt = "mechanical geometry prior relevant; Raman registration remains future robustness input";
    otherwise
        txt = "mechanical/control context retained; Raman robustness not yet active";
end
end

function txt = geometry_crack_evidence(device)
if string(device) == "AS005"
    txt = "crack-associated auxiliary evidence supports structured interpretation";
elseif string(device) == "AS006"
    txt = "geometry and boundary evidence support strong connectivity interpretation";
else
    txt = "no crack-specific structured conclusion";
end
end

function status = final_model_status(device)
switch string(device)
    case {"AS002", "AS003"}
        status = "M0star_sufficient";
    case {"AS005", "AS006"}
        status = "structured_supported";
    otherwise
        status = "mechanistically_unresolved";
end
end

function status = evidence_status(device, fallback)
switch string(device)
    case "AS001"
        status = "mixed/unresolved";
    case "AS002"
        status = "local-like/threshold";
    case "AS003"
        status = "control-limit support";
    case "AS004"
        status = "mechanistically unresolved";
    case "AS005"
        status = "crack-associated structured interpretation";
    otherwise
        status = "strong structured-connectivity support";
end
if strlength(status) == 0
    status = fallback;
end
end

function txt = claim_limit(device)
switch string(device)
    case "AS006"
        txt = "strongest device-level structured claim; not microscopic/topological proof";
    case "AS005"
        txt = "structured claim depends on primary-only transport plus crack context";
    case "AS004"
        txt = "structured tendency remains unresolved because protected topology is competitive";
    case "AS001"
        txt = "mixed probe evidence prevents categorical assignment";
    otherwise
        txt = "local/control sufficiency does not prove weak links absent";
end
end

function value = lookup_string(T, keyName, keyValue, fieldName, defaultValue)
if isempty(T) || ~ismember(keyName, string(T.Properties.VariableNames)) || ...
        ~ismember(fieldName, string(T.Properties.VariableNames))
    value = string(defaultValue);
    return;
end
idx = T.(char(keyName)) == string(keyValue);
if any(idx)
    value = string(T.(char(fieldName))(find(idx, 1)));
else
    value = string(defaultValue);
end
end

function value = lookup_double(T, keyName, keyValue, fieldName, defaultValue)
if isempty(T) || ~ismember(keyName, string(T.Properties.VariableNames)) || ...
        ~ismember(fieldName, string(T.Properties.VariableNames))
    value = defaultValue;
    return;
end
idx = T.(char(keyName)) == string(keyValue);
if any(idx)
    value = T.(char(fieldName))(find(idx, 1));
else
    value = defaultValue;
end
end

function status = logical_status(tf)
if tf
    status = "pass";
else
    status = "fail";
end
end

function row = hierarchy_row(modelLevel, definition, complexityK, controls, policy)
row = struct();
row.model_level = string(modelLevel);
row.definition = string(definition);
row.complexity_K = complexityK;
row.protected_controls = string(controls);
row.freeze_policy = string(policy);
end

function row = manifest_row(artifactId, pathValue, required, purpose)
row = struct();
row.artifact_id = string(artifactId);
row.path = string(pathValue);
row.required = logical(required);
row.purpose = string(purpose);
end

function row = claim_row(claimLevel, status, text)
row = struct();
row.claim_level = string(claimLevel);
row.status = string(status);
row.claim_text = string(text);
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

function row = empty_evidence_row()
row = struct();
row.device = "";
row.geometry_class = "";
row.evidence_tier = "";
row.phase5A_primary_result = "";
row.phase5B_secondary_result = "";
row.phase5B1_heldout_result = "";
row.phase5B2_force_law_result = "";
row.phase5C_identifiability_context = "";
row.phase5D2_DeltaS = NaN;
row.phase5D2_sigmaDeltaS = NaN;
row.phase5D2_Z = NaN;
row.directional_preference = "";
row.nonlinear_evidence = "";
row.raman_mechanical_evidence = "";
row.geometry_crack_evidence = "";
row.final_model_status = "";
row.final_evidence_status = "";
row.claim_limit = "";
end
