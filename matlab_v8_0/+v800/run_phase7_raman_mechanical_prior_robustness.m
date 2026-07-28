function out = run_phase7_raman_mechanical_prior_robustness(cfg)
%RUN_PHASE7_RAMAN_MECHANICAL_PRIOR_ROBUSTNESS Start Phase 7 prior audit.

if ~exist(cfg.outputDir, 'dir')
    mkdir(cfg.outputDir);
end

inputs = load_phase7_inputs(cfg);
scopePolicy = build_scope_policy(cfg);
frozenInputManifest = build_frozen_input_manifest(cfg);
priorEvidenceManifest = build_prior_evidence_manifest(inputs);
perturbationScenarios = build_perturbation_scenarios(cfg);
deviceRobustness = build_device_prior_robustness(inputs);
gateSummary = build_gate_summary(cfg, frozenInputManifest, ...
    deviceRobustness);
handoffStatus = build_handoff_status(gateSummary);

writetable(scopePolicy, cfg.phase7.scopePolicyFile);
writetable(frozenInputManifest, cfg.phase7.frozenInputManifestFile);
writetable(priorEvidenceManifest, cfg.phase7.priorEvidenceManifestFile);
writetable(perturbationScenarios, cfg.phase7.perturbationScenarioFile);
writetable(deviceRobustness, cfg.phase7.deviceRobustnessFile);
writetable(gateSummary, cfg.phase7.gateSummaryFile);
writetable(handoffStatus, cfg.phase7.handoffStatusFile);

try
    h = v800.plot_phase7_raman_mechanical_prior_robustness( ...
        cfg, deviceRobustness, perturbationScenarios, gateSummary);
catch ME
    warning('v8:phase7PlotFailed', ...
        'Phase 7 prior-robustness summary plot failed: %s', ME.message);
    h = [];
end

out = struct();
out.config = cfg;
out.inputs = inputs;
out.scopePolicy = scopePolicy;
out.frozenInputManifest = frozenInputManifest;
out.priorEvidenceManifest = priorEvidenceManifest;
out.perturbationScenarios = perturbationScenarios;
out.deviceRobustness = deviceRobustness;
out.gateSummary = gateSummary;
out.handoffStatus = handoffStatus;
out.figure = h;
out.paths = struct();
out.paths.scopePolicy = cfg.phase7.scopePolicyFile;
out.paths.frozenInputManifest = cfg.phase7.frozenInputManifestFile;
out.paths.priorEvidenceManifest = cfg.phase7.priorEvidenceManifestFile;
out.paths.perturbationScenarios = cfg.phase7.perturbationScenarioFile;
out.paths.deviceRobustness = cfg.phase7.deviceRobustnessFile;
out.paths.gateSummary = cfg.phase7.gateSummaryFile;
out.paths.handoffStatus = cfg.phase7.handoffStatusFile;
out.paths.figurePng = [cfg.phase7.figureBaseFile '.png'];
out.paths.figurePdf = [cfg.phase7.figureBaseFile '.pdf'];
end

function inputs = load_phase7_inputs(cfg)
inputs = struct();
inputs.phase6Matrix = read_optional_table(cfg.phase6.sixDeviceEvidenceMatrixFile);
inputs.phase6Status = read_optional_table(cfg.phase6.deviceModelStatusFile);
inputs.phase6Tiers = read_optional_table(cfg.phase6.evidenceTierAssignmentsFile);
inputs.phase6Handoff = read_optional_table(cfg.phase6.handoffStatusFile);
inputs.phase6Manifest = read_optional_table(cfg.phase6.frozenInputManifestFile);
inputs.phase5DataManifest = read_optional_table(cfg.dataManifestFile);
inputs.phase5D2Policy = read_optional_table(cfg.phase5D2.interpretationPolicyFile);
end

function T = read_optional_table(pathValue)
if exist(pathValue, 'file')
    T = readtable(pathValue, 'TextType', 'string');
else
    T = table();
end
end

function policy = build_scope_policy(cfg)
rows = [
    policy_row("phase_objective", "active", ...
    "Audit robustness of Phase 6 conclusions to Raman registration, mechanical prior, and mesh-resolution assumptions.")
    policy_row("phase6_status_freeze", "required", ...
    "Phase 7 may annotate confidence but may not relabel frozen Phase 6 device statuses.")
    policy_row("classifier_retuning", string(cfg.phase7.allowClassifierRetuning), ...
    "No weak-link class, score threshold, nuisance envelope, or classifier parameter may be tuned in Phase 7.")
    policy_row("status_relabeling", string(cfg.phase7.allowStatusRelabeling), ...
    "Device-level M0star_sufficient, structured_supported, and mechanistically_unresolved labels remain frozen.")
    policy_row("allowed_outputs", "contextual", ...
    "Allowed outputs are prior-sensitivity flags, robustness notes, and a handoff plan for any later spatial-prior test.")
    policy_row("prohibited_outputs", "categorical_classifier", ...
    "Do not convert Raman/mechanical priors into a universal categorical mechanism classifier.")
    ];
policy = struct2table(rows);
end

function manifest = build_frozen_input_manifest(cfg)
rows = [
    manifest_row("phase6_six_device_evidence_matrix", ...
    cfg.phase6.sixDeviceEvidenceMatrixFile, true, ...
    "frozen six-device evidence context")
    manifest_row("phase6_device_model_status", ...
    cfg.phase6.deviceModelStatusFile, true, ...
    "frozen device model statuses")
    manifest_row("phase6_evidence_tier_assignments", ...
    cfg.phase6.evidenceTierAssignmentsFile, true, ...
    "frozen evidence tiers")
    manifest_row("phase6_handoff_status", ...
    cfg.phase6.handoffStatusFile, true, ...
    "retuning and next-phase policy")
    manifest_row("phase5_data_manifest", ...
    cfg.dataManifestFile, false, ...
    "Raman and field-data availability hints")
    manifest_row("phase5D2_interpretation_policy", ...
    cfg.phase5D2.interpretationPolicyFile, true, ...
    "allowed/prohibited score-use policy")
    ];
manifest = struct2table(rows);
manifest.exists = arrayfun(@(p) exist(char(p), 'file') == 2, manifest.path);
manifest.frozen_use = repmat("read_only_no_relabeling", height(manifest), 1);
end

function priorManifest = build_prior_evidence_manifest(inputs)
devices = ["AS001"; "AS002"; "AS003"; "AS004"; "AS005"; "AS006"];
rows = repmat(empty_prior_row(), numel(devices), 1);
for k = 1:numel(devices)
    device = devices(k);
    rows(k).device = device;
    rows(k).has_raman_hint = lookup_logical(inputs.phase5DataManifest, ...
        "device", device, "has_raman", false);
    rows(k).mechanical_prior_role = mechanical_prior_role(device);
    rows(k).geometry_prior_source = geometry_prior_source(device);
    rows(k).registration_status = registration_status(rows(k).has_raman_hint);
    rows(k).phase7_use = phase7_use(device);
end
priorManifest = struct2table(rows);
end

function scenarios = build_perturbation_scenarios(cfg)
rows = [
    scenario_row("nominal", "reference", 0, 1.0, 1.0, ...
    "Reference prior; no retuning or relabeling.")
    scenario_row("registration_shift_low", "raman_registration", ...
    cfg.phase7.registrationShiftPixels(2), 1.0, 1.0, ...
    "Small Raman/probe registration displacement.")
    scenario_row("registration_shift_high", "raman_registration", ...
    cfg.phase7.registrationShiftPixels(end), 1.0, 1.0, ...
    "Larger registration displacement stress test.")
    scenario_row("spatially_shuffled_prior", "spatial_control", 0, ...
    1.0, 1.0, ...
    "Shuffle spatial prior as a nonlocal control.")
    scenario_row("boundary_mask_shifted", "geometry_mask", 0, ...
    1.0, 1.0, ...
    "Shift AS004/AS006 boundary-support mask within predeclared uncertainty.")
    scenario_row("prior_blind", "prior_weight", 0, 1.0, ...
    cfg.phase7.priorWeightScaleFactors(1), ...
    "Remove spatial prior as a confidence/context sensitivity check.")
    scenario_row("prior_amplified", "prior_weight", 0, 1.0, ...
    cfg.phase7.priorWeightScaleFactors(end), ...
    "Amplify spatial prior as an over-weighting sensitivity check.")
    scenario_row("crack_mask_removed", "geometry_mask", 0, 1.0, 0.5, ...
    "AS005 auxiliary crack-context dependency check.")
    ];
scenarios = struct2table(rows);
end

function robustness = build_device_prior_robustness(inputs)
T = inputs.phase6Matrix;
if isempty(T)
    robustness = table();
    return;
end
rows = repmat(empty_robustness_row(), height(T), 1);
for k = 1:height(T)
    device = string(T.device(k));
    status = string(T.final_model_status(k));
    deltaS = T.phase5D2_DeltaS(k);
    zValue = T.phase5D2_Z(k);
    rows(k).device = device;
    rows(k).phase6_model_status = status;
    rows(k).phase6_evidence_tier = string(T.evidence_tier(k));
    rows(k).phase6_directional_preference = string(T.directional_preference(k));
    rows(k).DeltaS = deltaS;
    rows(k).contextual_Z = zValue;
    rows(k).mechanical_prior_role = mechanical_prior_role(device);
    rows(k).prior_dependency = prior_dependency(device, status);
    rows(k).robustness_action = robustness_action(device, status, deltaS);
    rows(k).status_change_allowed = false;
    rows(k).phase7_expected_outcome = expected_outcome(device, status);
end
robustness = struct2table(rows);
end

function gates = build_gate_summary(cfg, manifest, robustness)
requiredOk = true;
if cfg.phase7.requirePhase6FrozenInputs
    requiredOk = all(manifest.exists(manifest.required));
end
hasRobustnessRows = ~isempty(robustness) && ...
    ismember("status_change_allowed", string(robustness.Properties.VariableNames));
noRelabel = hasRobustnessRows && ~cfg.phase7.allowStatusRelabeling && ...
    all(~robustness.status_change_allowed);
rows = [
    gate_row("Frozen Phase 6 inputs available", logical_status(requiredOk), ...
    "Phase 7 starts from the committed Phase 6 hierarchy outputs.")
    gate_row("No Phase 6 relabeling", logical_status(noRelabel), ...
    "All robustness rows preserve frozen device statuses.")
    gate_row("No classifier retuning", logical_status(~cfg.phase7.allowClassifierRetuning), ...
    "Raman/mechanical priors are context checks, not new thresholds.")
    gate_row("Prior perturbation grid declared", logical_status(true), ...
    "Registration, mesh, prior-weight, and crack-mask scenarios are predeclared.")
    gate_row("Raman availability documented", logical_status(true), ...
    "Unavailable quantitative Raman inputs are recorded as availability limits.")
    gate_row("Quantitative prior rescore", "not_run", ...
    "Phase 7A starts the audit; no spatial-prior rescore has been executed yet.")
    ];
gates = struct2table(rows);
end

function handoff = build_handoff_status(gates)
rows = [
    status_row("phase7A_scope_freeze", "pass", ...
    "Raman/mechanical prior robustness scope and perturbation policy are written.")
    status_row("phase6_classifications_preserved", ...
    logical_status(all(gates.outcome ~= "fail")), ...
    "Phase 7A does not reopen frozen Phase 6 model statuses.")
    status_row("quantitative_prior_rescore", "not_run", ...
    "Next step is optional execution against registered Raman/mechanical maps if available.")
    status_row("retuning_prohibited", "true", ...
    "No classifier thresholds, nuisance terms, or mechanism classes may be adjusted.")
    status_row("phase7_complete", "false", ...
    "Phase 7A is an audit/scope freeze; quantitative robustness remains incomplete.")
    status_row("next_phase7_step", "phase7B_geometry_mask_robustness", ...
    "Evaluate AS005 crack-mask and AS004/AS006 boundary-prior sensitivity before any Raman rescore.")
    status_row("phase8_deferred_scope", "mesh_solver_numerical_robustness", ...
    "Network mesh and solver convergence are deferred to Phase 8.")
    ];
handoff = struct2table(rows);
end

function role = mechanical_prior_role(device)
switch string(device)
    case "AS005"
        role = "crack_geometry_auxiliary";
    case "AS006"
        role = "strong_boundary_connectivity";
    case "AS004"
        role = "intermediate_half_coverage";
    case "AS002"
        role = "threshold_half_encapsulated";
    case "AS003"
        role = "control_prior";
    otherwise
        role = "mixed_control_or_weak_structure";
end
end

function src = geometry_prior_source(device)
switch string(device)
    case {"AS004", "AS005", "AS006"}
        src = "geometry_and_mechanical_context_required";
    otherwise
        src = "geometry_control_context";
end
end

function status = registration_status(hasRaman)
if hasRaman
    status = "raman_hint_available_registration_unverified";
else
    status = "quantitative_raman_not_available";
end
end

function txt = phase7_use(device)
switch string(device)
    case {"AS005", "AS006"}
        txt = "stress structured-support confidence";
    case {"AS001", "AS004"}
        txt = "test whether unresolved status remains unresolved";
    otherwise
        txt = "confirm control/local sufficiency is not overruled by prior context";
end
end

function dep = prior_dependency(device, status)
switch string(device)
    case "AS005"
        dep = "high_auxiliary_crack_context";
    case "AS006"
        dep = "moderate_boundary_context";
    case "AS004"
        dep = "moderate_unresolved_context";
    otherwise
        if string(status) == "M0star_sufficient"
            dep = "low_control_context";
        else
            dep = "moderate_mixed_context";
        end
end
end

function action = robustness_action(device, status, deltaS)
if string(status) == "mechanistically_unresolved"
    action = "preserve_unresolved_under_prior_perturbation";
elseif string(device) == "AS005"
    action = "audit_crack_mask_dependency";
elseif abs(deltaS) < 0.04
    action = "treat_contextual_score_as_near_tie";
else
    action = "audit_confidence_without_relabeling";
end
end

function txt = expected_outcome(device, status)
if string(status) == "structured_supported" && string(device) == "AS006"
    txt = "structured support should remain strongest if boundary prior is stable";
elseif string(device) == "AS005"
    txt = "structured support should be reported with crack-prior qualification";
elseif string(status) == "M0star_sufficient"
    txt = "M0star sufficiency should not be interpreted as weak-link absence";
else
    txt = "unresolved status should remain available under prior perturbation";
end
end

function value = lookup_logical(T, keyName, keyValue, fieldName, defaultValue)
value = defaultValue;
if isempty(T) || ~ismember(keyName, string(T.Properties.VariableNames)) || ...
        ~ismember(fieldName, string(T.Properties.VariableNames))
    return;
end
idx = T.(char(keyName)) == string(keyValue);
if ~any(idx)
    return;
end
rawValue = T.(char(fieldName))(find(idx, 1));
if islogical(rawValue)
    value = rawValue;
elseif isnumeric(rawValue)
    value = rawValue ~= 0;
else
    value = any(lower(string(rawValue)) == ["true", "1", "yes"]);
end
end

function status = logical_status(tf)
if tf
    status = "pass";
else
    status = "fail";
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

function row = scenario_row(scenarioId, category, registrationShiftPx, ...
    meshScaleFactor, priorWeightScale, note)
row = struct();
row.scenario_id = string(scenarioId);
row.category = string(category);
row.registration_shift_px = registrationShiftPx;
row.mesh_scale_factor = meshScaleFactor;
row.prior_weight_scale = priorWeightScale;
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

function row = empty_prior_row()
row = struct();
row.device = "";
row.has_raman_hint = false;
row.mechanical_prior_role = "";
row.geometry_prior_source = "";
row.registration_status = "";
row.phase7_use = "";
end

function row = empty_robustness_row()
row = struct();
row.device = "";
row.phase6_model_status = "";
row.phase6_evidence_tier = "";
row.phase6_directional_preference = "";
row.DeltaS = NaN;
row.contextual_Z = NaN;
row.mechanical_prior_role = "";
row.prior_dependency = "";
row.robustness_action = "";
row.status_change_allowed = false;
row.phase7_expected_outcome = "";
end
