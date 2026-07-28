function out = run_phase5D2_result_freeze(cfg)
%RUN_PHASE5D2_RESULT_FREEZE Freeze Phase 5D as evidence policy.

if ~exist(cfg.outputDir, 'dir')
    mkdir(cfg.outputDir);
end

inputs = load_phase5D2_inputs(cfg);
frozenInputManifest = build_frozen_input_manifest(cfg);
freezeStatus = build_freeze_status(inputs);
interpretationPolicy = build_interpretation_policy();
validationStatus = build_validation_status(cfg);
realDeviceContext = build_real_device_score_context(cfg, inputs);
deviceEvidence = build_device_evidence_synthesis(realDeviceContext);
finalGates = build_final_gate_summary(freezeStatus, validationStatus);
handoffStatus = build_handoff_status(freezeStatus, finalGates);

writetable(freezeStatus, cfg.phase5D2.freezeStatusFile);
writetable(freezeStatus, cfg.phase5D2.resultFreezeStatusFile);
writetable(interpretationPolicy, cfg.phase5D2.interpretationPolicyFile);
writetable(validationStatus, cfg.phase5D2.validationStatusFile);
writetable(frozenInputManifest, cfg.phase5D2.frozenInputManifestFile);
writetable(realDeviceContext, cfg.phase5D2.realDeviceScoreContextFile);
writetable(deviceEvidence, cfg.phase5D2.deviceEvidenceSynthesisFile);
writetable(finalGates, cfg.phase5D2.finalGateSummaryFile);
writetable(handoffStatus, cfg.phase5D2.handoffStatusFile);

try
    h = v800.plot_phase5D2_result_freeze_summary(cfg, inputs, ...
        realDeviceContext, finalGates);
catch ME
    warning('v8:phase5D2PlotFailed', ...
        'Phase 5D.2 result-freeze plot failed: %s', ME.message);
    h = [];
end

out = struct();
out.config = cfg;
out.inputs = inputs;
out.frozenInputManifest = frozenInputManifest;
out.freezeStatus = freezeStatus;
out.interpretationPolicy = interpretationPolicy;
out.validationStatus = validationStatus;
out.realDeviceScoreContext = realDeviceContext;
out.deviceEvidenceSynthesis = deviceEvidence;
out.finalGateSummary = finalGates;
out.handoffStatus = handoffStatus;
out.figure = h;
out.paths = struct();
out.paths.freezeStatus = cfg.phase5D2.freezeStatusFile;
out.paths.resultFreezeStatus = cfg.phase5D2.resultFreezeStatusFile;
out.paths.interpretationPolicy = cfg.phase5D2.interpretationPolicyFile;
out.paths.validationStatus = cfg.phase5D2.validationStatusFile;
out.paths.frozenInputManifest = cfg.phase5D2.frozenInputManifestFile;
out.paths.realDeviceScoreContext = cfg.phase5D2.realDeviceScoreContextFile;
out.paths.deviceEvidenceSynthesis = cfg.phase5D2.deviceEvidenceSynthesisFile;
out.paths.finalGateSummary = cfg.phase5D2.finalGateSummaryFile;
out.paths.handoffStatus = cfg.phase5D2.handoffStatusFile;
out.paths.figurePng = [cfg.phase5D2.figureBaseFile '.png'];
out.paths.figurePdf = [cfg.phase5D2.figureBaseFile '.pdf'];
end

function inputs = load_phase5D2_inputs(cfg)
inputs = struct();
inputs.feasibility = read_optional_table(cfg, ...
    fullfile(cfg.outputDir, 'phase5D1b_operating_point_feasibility.csv'));
inputs.roc = read_optional_table(cfg, ...
    fullfile(cfg.outputDir, 'phase5D1b_threshold_ROC_by_evidence_tier.csv'));
inputs.sigmaAudit = read_optional_table(cfg, ...
    fullfile(cfg.outputDir, 'phase5D1b_sigmaDeltaS_audit.csv'));
inputs.nuisanceOccupancy = read_optional_table(cfg, ...
    fullfile(cfg.outputDir, 'phase5D1b_nuisance_boundary_occupancy.csv'));
inputs.penaltySensitivity = read_optional_table(cfg, ...
    fullfile(cfg.outputDir, 'phase5D1b_nuisance_penalty_sensitivity.csv'));
inputs.internalCheck = read_optional_table(cfg, ...
    fullfile(cfg.outputDir, 'phase5D1b_internal_calibration_check.csv'));
inputs.calibrationGates = read_optional_table(cfg, ...
    fullfile(cfg.outputDir, 'phase5D1b_calibration_gate_results.csv'));
inputs.sourceProvenance = read_optional_table(cfg, ...
    fullfile(cfg.outputDir, 'phase5D_source_provenance_checkpoint.csv'));
inputs.phase5DHandoff = read_optional_table(cfg, ...
    fullfile(cfg.outputDir, 'phase5D_handoff_status.csv'));
inputs.primaryLedger = read_optional_table(cfg, ...
    cfg.phase5A.frozenTransferLedgerFile);
inputs.levelADeviceSummary = read_optional_table(cfg, ...
    cfg.phase5A.summaryFile);
inputs.phase5BDeviceEvidence = read_optional_table(cfg, ...
    cfg.phase5B.deviceEvidenceFile);
inputs.phase5B1Heldout = read_optional_table(cfg, ...
    cfg.phase5B1.heldoutFile);
inputs.phase5B2DevicePredictions = read_optional_table(cfg, ...
    cfg.phase5B2.devicePredictionFile);
inputs.phase5CStatus = read_optional_table(cfg, cfg.phase5C.handoffStatusFile);
end

function manifest = build_frozen_input_manifest(cfg)
rows = [
    manifest_row("phase5D1b_operating_point_feasibility", ...
    fullfile(cfg.outputDir, 'phase5D1b_operating_point_feasibility.csv'), true, ...
    "central negative result; no feasible universal operating point")
    manifest_row("phase5D1b_threshold_ROC_by_evidence_tier", ...
    fullfile(cfg.outputDir, 'phase5D1b_threshold_ROC_by_evidence_tier.csv'), true, ...
    "evidence-tier ROC tradeoff frozen from calibration seeds")
    manifest_row("phase5D1b_sigmaDeltaS_audit", ...
    fullfile(cfg.outputDir, 'phase5D1b_sigmaDeltaS_audit.csv'), true, ...
    "label-free uncertainty audit used as contextual detection limit")
    manifest_row("phase5D1b_nuisance_boundary_occupancy", ...
    fullfile(cfg.outputDir, 'phase5D1b_nuisance_boundary_occupancy.csv'), true, ...
    "nuisance-boundary occupancy diagnostic")
    manifest_row("phase5D1b_nuisance_penalty_sensitivity", ...
    fullfile(cfg.outputDir, 'phase5D1b_nuisance_penalty_sensitivity.csv'), true, ...
    "penalty sensitivity diagnostic; not retuned in 5D.2")
    manifest_row("phase5D1b_internal_calibration_check", ...
    fullfile(cfg.outputDir, 'phase5D1b_internal_calibration_check.csv'), true, ...
    "internal calibration split diagnostic")
    manifest_row("phase5D_source_provenance_checkpoint", ...
    fullfile(cfg.outputDir, 'phase5D_source_provenance_checkpoint.csv'), false, ...
    "source provenance checkpoint when available")
    manifest_row("phase5A_primary_transfer_ledger", ...
    cfg.phase5A.frozenTransferLedgerFile, true, ...
    "real-device primary R(T) score source")
    manifest_row("phase5B_device_evidence_table", ...
    cfg.phase5B.deviceEvidenceFile, true, ...
    "secondary-probe and hierarchy evidence source")
    manifest_row("phase5B1_activation_heldout_validation", ...
    cfg.phase5B1.heldoutFile, false, ...
    "strict held-out activation-law context")
    manifest_row("phase5B2_full_series_device_predictions", ...
    cfg.phase5B2.devicePredictionFile, false, ...
    "full-series force-law descriptive context")
    manifest_row("phase5C_handoff_status", ...
    cfg.phase5C.handoffStatusFile, true, ...
    "synthetic identifiability and misspecification handoff")
    ];
manifest = struct2table(rows);
manifest.exists = arrayfun(@(p) exist(char(p), 'file') == 2, manifest.path);
manifest.frozen_use = repmat("read_only_input_no_retuning", height(manifest), 1);
end

function T = read_optional_table(~, pathValue)
if exist(pathValue, 'file')
    T = readtable(pathValue, 'TextType', 'string');
else
    T = table();
end
end

function freeze = build_freeze_status(inputs)
feasiblePrimary = feasible_for_tier(inputs.feasibility, "primary_only");
feasiblePaired = feasible_for_tier(inputs.feasibility, "primary_secondary");
inFamilyStatus = status_from_table(inputs.phase5CStatus, ...
    "in_family_recovery", "pass");
labelStatus = status_from_table(inputs.phase5CStatus, ...
    "label_consistency", "pass");
misspecStatus = status_from_table(inputs.phase5CStatus, ...
    "misspecification_robustness", "fail");
labelFreeStatus = status_from_table(inputs.phase5DHandoff, ...
    "label_free_sigmaDeltaS", "pass");
rows = [
    status_row("in_family_identifiability", inFamilyStatus, ...
    "Phase 5C in-family synthetic recovery remains frozen.")
    status_row("mixed_label_policy", labelStatus, ...
    "M0 is unstructured; M1, M2, and mixed are structured/intermediate.")
    status_row("misspecification_robustness", misspecStatus, ...
    "Phase 5C misspecification failure is retained as the reason for 5D.")
    status_row("calibration_engine", "pass", ...
    "5D.1b completed calibration, ROC, sigma, nuisance, and penalty-sensitivity reports.")
    status_row("label_free_sigmaDeltaS", labelFreeStatus, ...
    "sigmaDeltaS is case-specific and label-free.")
    status_row("nuisance_profiling", "pass", ...
    "M0* nuisance profile and boundary-occupancy ledgers are archived.")
    status_row("operating_point_search", "pass", ...
    "Threshold ROC was evaluated for primary-only and paired-probe evidence tiers.")
    status_row("feasible_operating_point_primary_only", ...
    boolean_text(feasiblePrimary), ...
    "Primary-only evidence has no threshold satisfying the predeclared targets.")
    status_row("feasible_operating_point_primary_secondary", ...
    boolean_text(feasiblePaired), ...
    "Paired-probe evidence has no threshold satisfying the predeclared targets.")
    status_row("deployable_universal_classifier", ...
    boolean_text(feasiblePrimary || feasiblePaired), ...
    "No threshold simultaneously satisfies the predeclared FPR and strong-TPR targets.")
    status_row("phase5D1b_closure", "pass_as_negative_result", ...
    "5D.1b is frozen as a scientific limitation, not implementation failure.")
    status_row("validation_seeds_consumed", "false", ...
    "Independent validation seeds remain preserved.")
    ];
freeze = struct2table(rows);
end

function policy = build_interpretation_policy()
rows = [
    policy_row("allowed", "report_DeltaS_and_Z_continuously", ...
    "DeltaS and Z may be reported as continuous directional evidence.")
    policy_row("allowed", "report_S_M0star_S_M1_and_S_M2", ...
    "Frozen score components may be reported as contextual model-comparison quantities.")
    policy_row("allowed", "compare_directional_model_preference", ...
    "DeltaS < 0 means structured candidates score better than M0*; DeltaS > 0 means M0* scores better.")
    policy_row("allowed", "identify_strongly_separated_limiting_cases", ...
    "Large absolute score separation may support qualitative limiting-case discussion.")
    policy_row("allowed", "show_uncertainty_and_nuisance_overlap", ...
    "The 5D.1b ROC and sigma tables should be used to qualify uncertainty.")
    policy_row("allowed", "qualify_by_probe_availability", ...
    "Primary-only and paired-probe evidence tiers must remain distinct.")
    policy_row("not_allowed", "universal_categorical_classification_from_normalized_RT", ...
    "No universal Z threshold met the predeclared calibration targets.")
    policy_row("not_allowed", "interpret_unresolved_as_M0", ...
    "Unresolved means insufficient separation, not local-Tc proof.")
    policy_row("not_allowed", "claim_connectivity_absent_from_M0_preference", ...
    "M0* preference does not prove absence of structured connectivity.")
    policy_row("not_allowed", "classify_M1_versus_M2_from_RT_alone", ...
    "M1/M2 distinctions require evidence beyond normalized R(T).")
    policy_row("not_allowed", "claim_validated_sensitivity_or_specificity", ...
    "Independent validation was not run because no feasible calibration operating point exists.")
    policy_row("deferred", "future_optional_full_shape_RT_classifier", ...
    "Deferred until after hierarchical model freeze; trigger only if a new evidence model is explicitly scoped.")
    ];
policy = struct2table(rows);
end

function validation = build_validation_status(cfg)
rows = [
    validation_row("validation_status", "not_run", ...
    "No feasible calibration operating point exists.")
    validation_row("validation_seeds", sprintf('%d-%d', ...
    cfg.phase5D.validationSeeds(1), cfg.phase5D.validationSeeds(end)), ...
    "Reserved independent validation block.")
    validation_row("validation_seeds_consumed", "false", ...
    "Seeds are preserved for a materially revised evidence model.")
    validation_row("reason", "no_feasible_calibration_operating_point", ...
    "Running validation would test a rule already known not to satisfy calibration targets.")
    validation_row("future_use", "materially_revised_evidence_model_only", ...
    "Use reserved seeds only after adding genuinely new observables or a materially revised model.")
    ];
validation = struct2table(rows);
end

function context = build_real_device_score_context(~, inputs)
devices = ["AS001"; "AS002"; "AS003"; "AS004"; "AS005"; "AS006"];
rows = repmat(empty_context_row(), numel(devices), 1);
for k = 1:numel(devices)
    device = devices(k);
    rows(k).device = device;
    rows(k).evidence_tier = evidence_tier(inputs.phase5BDeviceEvidence, device);
    rows(k).S_M0star = model_score(inputs.primaryLedger, device, ...
        ["M0"; "protected_control"]);
    rows(k).S_M1 = model_score(inputs.primaryLedger, device, "M1");
    rows(k).S_M2 = model_score(inputs.primaryLedger, device, "M2");
    rows(k).S_structured_min = min([rows(k).S_M1, rows(k).S_M2], [], ...
        'omitnan');
    rows(k).DeltaS = rows(k).S_structured_min - rows(k).S_M0star;
    rows(k).sigmaDeltaS = reference_sigma(inputs.sigmaAudit, ...
        rows(k).evidence_tier);
    rows(k).Z = rows(k).DeltaS ./ rows(k).sigmaDeltaS;
    rows(k).directional_preference = directional_preference( ...
        rows(k).DeltaS, rows(k).sigmaDeltaS);
    rows(k).rt_score_preference = rt_preference(inputs, device);
    rows(k).levelA_best_mechanism = lookup_string(inputs.levelADeviceSummary, ...
        "device", device, "best_any_mechanism", "");
    rows(k).levelA_margin_vs_control = lookup_double(inputs.levelADeviceSummary, ...
        "device", device, "primary_margin_vs_control", NaN);
    rows(k).phase5B_preferred_model = lookup_string(inputs.phase5BDeviceEvidence, ...
        "device", device, "preferred_model", "not_available");
    rows(k).phase5B_evidence_conclusion = lookup_string(inputs.phase5BDeviceEvidence, ...
        "device", device, "evidence_conclusion", "not_available");
    rows(k).heldout_result = heldout_result(inputs.phase5B1Heldout, device);
    rows(k).phase5A_primary_result = phase5A_primary_result( ...
        inputs.levelADeviceSummary, device);
    rows(k).phase5B_heldout_result = rows(k).heldout_result;
    rows(k).secondary_probe_status = secondary_status( ...
        inputs.phase5BDeviceEvidence, device);
    rows(k).secondary_evidence = secondary_evidence( ...
        inputs.phase5BDeviceEvidence, device);
    rows(k).activation_law_context = activation_context( ...
        inputs.phase5B2DevicePredictions, device);
    rows(k).auxiliary_evidence = auxiliary_evidence(device);
    rows(k).phase5D_policy_note = ...
        "DeltaS/Z are contextual only; no universal categorical classifier";
end
context = struct2table(rows);
end

function tier = evidence_tier(T, device)
status = secondary_status(T, device);
if startsWith(status, "ready")
    tier = "primary_secondary";
else
    tier = "primary_only";
end
end

function score = model_score(T, device, modelLevels)
score = NaN;
required = ["device"; "model_level"; "total_LevelA_score"; "run_status"];
if isempty(T) || ~all(ismember(required, string(T.Properties.VariableNames)))
    return;
end
idx = T.device == device & ismember(T.model_level, modelLevels) & ...
    T.run_status == "scored";
if any(idx)
    score = min(T.total_LevelA_score(idx), [], 'omitnan');
end
end

function sigma = reference_sigma(T, tier)
sigma = NaN;
required = ["evidence_tier"; "median_sigmaDeltaS"];
if isempty(T) || ~all(ismember(required, string(T.Properties.VariableNames)))
    return;
end
idx = T.evidence_tier == tier;
if any(idx)
    sigma = median(T.median_sigmaDeltaS(idx), 'omitnan');
end
end

function pref = directional_preference(deltaS, sigmaDeltaS)
if isnan(deltaS)
    pref = "not_available";
elseif isnan(sigmaDeltaS) || sigmaDeltaS <= 0 || abs(deltaS) < sigmaDeltaS
    pref = "near_tie";
elseif deltaS < 0
    pref = "structured_direction";
else
    pref = "M0star_direction";
end
end

function pref = rt_preference(inputs, device)
model = lookup_string(inputs.phase5BDeviceEvidence, "device", device, ...
    "preferred_model", "");
switch model
    case {"M1", "M2", "structured"}
        pref = "structured directional preference";
    case "M0"
        pref = "M0*/local-like or protected-control preference";
    otherwise
        pref = "weak/mixed or unresolved";
end
end

function result = heldout_result(T, device)
if isempty(T) || ~ismember("withheld_device", string(T.Properties.VariableNames)) || ...
        ~ismember("status", string(T.Properties.VariableNames)) || ...
        ~ismember("note", string(T.Properties.VariableNames)) || ...
        ~any(T.withheld_device == device)
    result = "not_applicable_or_not_available";
    return;
end
idx = find(T.withheld_device == device, 1);
result = string(T.status(idx)) + ": " + string(T.note(idx));
end

function txt = phase5A_primary_result(T, device)
mech = lookup_string(T, "device", device, "best_any_mechanism", ...
    "not_available");
margin = lookup_double(T, "device", device, "primary_margin_vs_control", NaN);
if isnan(margin)
    txt = mech;
else
    txt = mech + "; margin_vs_control=" + string(margin);
end
end

function status = secondary_status(T, device)
status = lookup_string(T, "device", device, "secondary_probe_status", ...
    "not_available");
end

function txt = secondary_evidence(T, device)
status = secondary_status(T, device);
model = lookup_string(T, "device", device, "secondary_preferred_model", "");
if strlength(model) > 0 && model ~= "not_applicable"
    txt = status + "; secondary preferred " + model;
else
    txt = status;
end
end

function txt = activation_context(T, device)
required = ["device"; "force_lambda_W"; "force_margin_vs_protected"; ...
    "diagnostic_note"];
if isempty(T) || ~all(ismember(required, string(T.Properties.VariableNames))) || ...
        ~any(T.device == device)
    txt = "not_applicable_or_not_available";
    return;
end
idx = find(T.device == device, 1);
lambdaW = T.force_lambda_W(idx);
margin = T.force_margin_vs_protected(idx);
note = string(T.diagnostic_note(idx));
txt = "force-law lambda_W=" + string(lambdaW) + ...
    "; margin_vs_protected=" + string(margin) + "; " + note;
end

function txt = auxiliary_evidence(device)
switch string(device)
    case "AS001"
        txt = "control geometry; probe-dependent/mixed evidence";
    case "AS002"
        txt = "weak onset; threshold/local-like regime";
    case "AS003"
        txt = "fully encapsulated control-limit device";
    case "AS004"
        txt = "intermediate half coverage; paired probes available";
    case "AS005"
        txt = "crack-associated interpretation; primary-only transport";
    otherwise
        txt = "strongest combined transport and nonlinear evidence";
end
end

function synthesis = build_device_evidence_synthesis(context)
rows = repmat(empty_synthesis_row(), height(context), 1);
for k = 1:height(context)
    device = context.device(k);
    rows(k).device = device;
    rows(k).directional_preference = context.directional_preference(k);
    rows(k).DeltaS = context.DeltaS(k);
    rows(k).Z = context.Z(k);
    rows(k).RT_score_preference = context.rt_score_preference(k);
    rows(k).phase5A_primary_result = context.phase5A_primary_result(k);
    rows(k).phase5B_heldout_result = context.phase5B_heldout_result(k);
    rows(k).secondary_evidence = context.secondary_evidence(k);
    rows(k).activation_law_context = context.activation_law_context(k);
    rows(k).auxiliary_evidence = context.auxiliary_evidence(k);
    rows(k).final_evidence_status = final_status(device);
    rows(k).classification_policy = ...
        "multi-evidence synthesis; not an automatic Z-classifier output";
end
synthesis = struct2table(rows);
end

function status = final_status(device)
switch string(device)
    case "AS001"
        status = "mixed/unresolved";
    case "AS002"
        status = "local-like/threshold";
    case "AS003"
        status = "control-limit support";
    case "AS004"
        status = "mechanistically unresolved structured tendency";
    case "AS005"
        status = "primary-only crack-associated structured interpretation";
    otherwise
        status = "strongest connectivity support";
end
end

function gates = build_final_gate_summary(freezeStatus, validationStatus)
rows = [
    gate_row("In-family recovery", ...
    freeze_note(freezeStatus, "in_family_identifiability"), ...
    "Phase 5C positive-control recovery is frozen.")
    gate_row("Label policy", ...
    freeze_note(freezeStatus, "mixed_label_policy"), ...
    "Mixed synthetic cases are treated as structured/intermediate.")
    gate_row("Label-free uncertainty", ...
    freeze_note(freezeStatus, "label_free_sigmaDeltaS"), ...
    "5D.1b uses case-specific sigmaDeltaS.")
    gate_row("Nuisance profiling", "pass", ...
    "M0* nuisance profile and boundary diagnostics are frozen.")
    gate_row("Operating-point search", "pass", ...
    "5D.1b ROC tables establish no feasible threshold.")
    gate_row("Feasible universal classifier", "fail", ...
    freeze_detail(freezeStatus, "deployable_universal_classifier"))
    gate_row("Scientific limitation established", "pass", ...
    "Normalized R(T) alone is insufficient for universal categorical classification.")
    gate_row("Validation seeds preserved", "pass", ...
    "validation_seeds_consumed=" + validation_note(validationStatus, ...
    "validation_seeds_consumed"))
    gate_row("Evidence-synthesis handoff", "pass", ...
    "Phase 5D.2 freezes policy for hierarchical six-device synthesis.")
    ];
gates = struct2table(rows);
end

function handoff = build_handoff_status(freezeStatus, finalGates)
ready = any(finalGates.component == "Evidence-synthesis handoff" & ...
    finalGates.outcome == "pass");
rows = [
    status_row("phase5D2_closure", "pass_result_freeze", ...
    "Phase 5D.2 freezes the negative calibration result and evidence policy.")
    status_row("feasible_operating_point_primary_only", freeze_note(freezeStatus, ...
    "feasible_operating_point_primary_only"), ...
    "No further threshold or nuisance tuning is allowed in Phase 5D.")
    status_row("feasible_operating_point_primary_secondary", freeze_note(freezeStatus, ...
    "feasible_operating_point_primary_secondary"), ...
    "No further threshold or nuisance tuning is allowed in Phase 5D.")
    status_row("deployable_universal_classifier", freeze_note(freezeStatus, ...
    "deployable_universal_classifier"), ...
    "Use continuous score context, not categorical Z classification.")
    status_row("validation_required", "false", ...
    "Independent validation is not run without a feasible calibration rule.")
    status_row("next_phase", "hierarchical_six_device_model_freeze", ...
    "Proceed to multi-evidence device synthesis and final hierarchy freeze.")
    status_row("future_optional_phase", "full_shape_RT_classifier", ...
    "Deferred; trigger only after hierarchical model freeze.")
    status_row("evidence_synthesis_ready", logical_status(ready), ...
    "Device conclusions are framed as evidence synthesis.")
    ];
handoff = struct2table(rows);
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

function value = freeze_note(T, item)
value = lookup_string(T, "item", item, "status", "not_available");
end

function value = freeze_detail(T, item)
value = lookup_string(T, "item", item, "note", "not_available");
end

function value = validation_note(T, item)
value = lookup_string(T, "item", item, "status", "not_available");
end

function tf = feasible_for_tier(T, tier)
tf = false;
required = ["evidence_tier"; "feasible_operating_point_exists"];
if isempty(T) || ~all(ismember(required, string(T.Properties.VariableNames)))
    return;
end
idx = T.evidence_tier == tier;
if any(idx)
    tf = logical(T.feasible_operating_point_exists(find(idx, 1)));
end
end

function status = status_from_table(T, item, defaultStatus)
status = lookup_string(T, "item", item, "status", defaultStatus);
end

function status = logical_status(tf)
if tf
    status = "pass";
else
    status = "fail";
end
end

function status = boolean_text(tf)
if tf
    status = "true";
else
    status = "false";
end
end

function row = status_row(item, status, note)
row = struct();
row.item = string(item);
row.status = string(status);
row.note = string(note);
end

function row = policy_row(policyClass, item, interpretation)
row = struct();
row.policy_class = string(policyClass);
row.item = string(item);
row.interpretation = string(interpretation);
end

function row = validation_row(item, status, note)
row = struct();
row.item = string(item);
row.status = string(status);
row.note = string(note);
end

function row = gate_row(component, outcome, note)
row = struct();
row.component = string(component);
row.outcome = string(outcome);
row.note = string(note);
end

function row = manifest_row(artifactId, pathValue, required, purpose)
row = struct();
row.artifact_id = string(artifactId);
row.path = string(pathValue);
row.required = logical(required);
row.purpose = string(purpose);
end

function row = empty_context_row()
row = struct();
row.device = "";
row.evidence_tier = "";
row.S_M0star = NaN;
row.S_M1 = NaN;
row.S_M2 = NaN;
row.S_structured_min = NaN;
row.DeltaS = NaN;
row.sigmaDeltaS = NaN;
row.Z = NaN;
row.directional_preference = "";
row.rt_score_preference = "";
row.levelA_best_mechanism = "";
row.levelA_margin_vs_control = NaN;
row.phase5B_preferred_model = "";
row.phase5B_evidence_conclusion = "";
row.heldout_result = "";
row.phase5A_primary_result = "";
row.phase5B_heldout_result = "";
row.secondary_probe_status = "";
row.secondary_evidence = "";
row.activation_law_context = "";
row.auxiliary_evidence = "";
row.phase5D_policy_note = "";
end

function row = empty_synthesis_row()
row = struct();
row.device = "";
row.directional_preference = "";
row.DeltaS = NaN;
row.Z = NaN;
row.RT_score_preference = "";
row.phase5A_primary_result = "";
row.phase5B_heldout_result = "";
row.secondary_evidence = "";
row.activation_law_context = "";
row.auxiliary_evidence = "";
row.final_evidence_status = "";
row.classification_policy = "";
end
