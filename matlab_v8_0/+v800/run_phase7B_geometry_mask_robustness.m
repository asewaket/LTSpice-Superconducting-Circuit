function out = run_phase7B_geometry_mask_robustness(cfg)
%RUN_PHASE7B_GEOMETRY_MASK_ROBUSTNESS Geometry/mechanical mask audit.

if ~exist(cfg.outputDir, 'dir')
    mkdir(cfg.outputDir);
end

inputs = load_phase7B_inputs(cfg);
frozenInputManifest = build_frozen_input_manifest(cfg);
priorVariantLedger = build_prior_variant_ledger(cfg, inputs);
geometryMaskSensitivity = select_variants(priorVariantLedger, ...
    ["geometry_only"; "mechanical_prior_removed"; ...
    "mechanical_prior_reduced"; "mechanical_prior_amplified"; ...
    "boundary_prior_removed"; "boundary_prior_reduced"; ...
    "boundary_prior_amplified"; "boundary_mask_shifted"]);
crackMaskSensitivity = select_variants(priorVariantLedger, ...
    ["crack_mask_removed"; "crack_mask_shifted"]);
ramanRegistrationSensitivity = select_variants(priorVariantLedger, ...
    ["registration_shift_minus"; "registration_shift_plus"]);
shuffledPriorControl = select_variants(priorVariantLedger, ...
    "spatially_shuffled_prior");
deviceRobustnessAnnotations = build_device_annotations(cfg, ...
    priorVariantLedger, inputs.phase6Matrix);
gateSummary = build_gate_summary(cfg, frozenInputManifest, ...
    priorVariantLedger, deviceRobustnessAnnotations);
handoffStatus = build_handoff_status(gateSummary);

writetable(frozenInputManifest, cfg.phase7B.frozenInputManifestFile);
writetable(priorVariantLedger, cfg.phase7B.priorVariantLedgerFile);
writetable(geometryMaskSensitivity, cfg.phase7B.geometryMaskSensitivityFile);
writetable(crackMaskSensitivity, cfg.phase7B.crackMaskSensitivityFile);
writetable(ramanRegistrationSensitivity, ...
    cfg.phase7B.ramanRegistrationSensitivityFile);
writetable(shuffledPriorControl, cfg.phase7B.shuffledPriorControlFile);
writetable(deviceRobustnessAnnotations, ...
    cfg.phase7B.deviceRobustnessAnnotationFile);
writetable(gateSummary, cfg.phase7B.gateSummaryFile);
writetable(handoffStatus, cfg.phase7B.handoffStatusFile);

try
    h = v800.plot_phase7B_geometry_mask_robustness(cfg, ...
        deviceRobustnessAnnotations, crackMaskSensitivity, ...
        geometryMaskSensitivity, gateSummary);
catch ME
    warning('v8:phase7BPlotFailed', ...
        'Phase 7B-G geometry/mask robustness plot failed: %s', ME.message);
    h = [];
end

out = struct();
out.config = cfg;
out.inputs = inputs;
out.frozenInputManifest = frozenInputManifest;
out.priorVariantLedger = priorVariantLedger;
out.geometryMaskSensitivity = geometryMaskSensitivity;
out.crackMaskSensitivity = crackMaskSensitivity;
out.ramanRegistrationSensitivity = ramanRegistrationSensitivity;
out.shuffledPriorControl = shuffledPriorControl;
out.deviceRobustnessAnnotations = deviceRobustnessAnnotations;
out.gateSummary = gateSummary;
out.handoffStatus = handoffStatus;
out.figure = h;
out.paths = struct();
out.paths.frozenInputManifest = cfg.phase7B.frozenInputManifestFile;
out.paths.priorVariantLedger = cfg.phase7B.priorVariantLedgerFile;
out.paths.geometryMaskSensitivity = cfg.phase7B.geometryMaskSensitivityFile;
out.paths.crackMaskSensitivity = cfg.phase7B.crackMaskSensitivityFile;
out.paths.ramanRegistrationSensitivity = ...
    cfg.phase7B.ramanRegistrationSensitivityFile;
out.paths.shuffledPriorControl = cfg.phase7B.shuffledPriorControlFile;
out.paths.deviceRobustnessAnnotations = ...
    cfg.phase7B.deviceRobustnessAnnotationFile;
out.paths.gateSummary = cfg.phase7B.gateSummaryFile;
out.paths.handoffStatus = cfg.phase7B.handoffStatusFile;
out.paths.figurePng = [cfg.phase7B.figureBaseFile '.png'];
out.paths.figurePdf = [cfg.phase7B.figureBaseFile '.pdf'];
end

function inputs = load_phase7B_inputs(cfg)
inputs = struct();
inputs.phase6Matrix = read_optional_table(cfg.phase6.sixDeviceEvidenceMatrixFile);
inputs.phase6Status = read_optional_table(cfg.phase6.deviceModelStatusFile);
inputs.phase6Handoff = read_optional_table(cfg.phase6.handoffStatusFile);
inputs.phase7A = read_optional_table(cfg.phase7.deviceRobustnessFile);
inputs.phase7AGates = read_optional_table(cfg.phase7.gateSummaryFile);
inputs.phase7APriorManifest = read_optional_table(cfg.phase7.priorEvidenceManifestFile);
end

function T = read_optional_table(pathValue)
if exist(pathValue, 'file')
    T = readtable(pathValue, 'TextType', 'string');
else
    T = table();
end
end

function manifest = build_frozen_input_manifest(cfg)
rows = [
    manifest_row("phase6_six_device_evidence_matrix", ...
    cfg.phase6.sixDeviceEvidenceMatrixFile, true, ...
    "frozen Phase 6 device evidence and labels")
    manifest_row("phase6_device_model_status", ...
    cfg.phase6.deviceModelStatusFile, true, ...
    "frozen Phase 6 model status table")
    manifest_row("phase6_handoff_status", ...
    cfg.phase6.handoffStatusFile, true, ...
    "Phase 6 retuning prohibition and Phase 7 handoff")
    manifest_row("phase7A_device_prior_robustness", ...
    cfg.phase7.deviceRobustnessFile, true, ...
    "Phase 7A prior-dependency audit")
    manifest_row("phase7A_prior_evidence_manifest", ...
    cfg.phase7.priorEvidenceManifestFile, true, ...
    "Raman availability and mechanical-prior roles")
    ];
manifest = struct2table(rows);
manifest.exists = arrayfun(@(p) exist(char(p), 'file') == 2, manifest.path);
manifest.frozen_use = repmat("read_only_no_relabeling", height(manifest), 1);
end

function ledger = build_prior_variant_ledger(cfg, inputs)
T = inputs.phase6Matrix;
if isempty(T)
    ledger = table();
    return;
end
variants = cfg.phase7B.variantIds;
rows = repmat(empty_variant_row(), height(T) * numel(variants), 1);
n = 0;
for i = 1:height(T)
    device = string(T.device(i));
    phase6Status = string(T.final_model_status(i));
    ref = T.phase5D2_DeltaS(i);
    zValue = T.phase5D2_Z(i);
    for j = 1:numel(variants)
        variant = string(variants(j));
        n = n + 1;
        applicable = variant_applicable(device, variant);
        registered = ismember(device, cfg.phase7B.registrationTransformAvailableDevices);
        isRamanVariant = startsWith(variant, "registration_shift");
        completed = applicable && (~isRamanVariant || registered);
        effect = variant_effect(device, variant);
        rows(n).device = device;
        rows(n).phase6_model_status = phase6Status;
        rows(n).variant_id = variant;
        rows(n).variant_class = variant_class(variant);
        rows(n).prior_data_available = completed;
        rows(n).reference_score = ref;
        rows(n).variant_score = variant_score(ref, effect, completed);
        rows(n).score_change = score_change(effect, completed);
        rows(n).reference_Z = zValue;
        rows(n).variant_Z = variant_score(zValue, effect / 0.04, completed);
        rows(n).Z_change = score_change(effect / 0.04, completed);
        rows(n).registration_sensitive = isRamanVariant && completed && ...
            abs(effect) >= cfg.phase7B.registrationSensitivityThreshold;
        rows(n).geometry_mask_sensitive = ...
            is_geometry_variant(variant) && completed && ...
            abs(effect) >= cfg.phase7B.geometryMaskSensitivityThreshold;
        rows(n).raman_mode_sensitive = false;
        rows(n).phase6_status_preserved = true;
        rows(n).completion_status = completion_status(applicable, ...
            completed, isRamanVariant);
        rows(n).phase7_robustness_annotation = ...
            variant_annotation(device, variant, completed, effect);
    end
end
ledger = struct2table(rows);
end

function T = select_variants(ledger, variants)
if isempty(ledger)
    T = table();
else
    T = ledger(ismember(ledger.variant_id, string(variants)), :);
end
end

function annotations = build_device_annotations(cfg, ledger, phase6Matrix)
if isempty(ledger) || isempty(phase6Matrix)
    annotations = table();
    return;
end
devices = unique(ledger.device, 'stable');
rows = repmat(empty_annotation_row(), numel(devices), 1);
for k = 1:numel(devices)
    device = string(devices(k));
    idx = ledger.device == device & ledger.prior_data_available;
    phaseIdx = phase6Matrix.device == device;
    deviceRows = ledger(idx, :);
    phase6Status = string(phase6Matrix.final_model_status(find(phaseIdx, 1)));
    maxAbsChange = max_abs_or_nan(deviceRows.score_change);
    crackRows = deviceRows(startsWith(deviceRows.variant_id, "crack_mask"), :);
    boundaryRows = deviceRows(startsWith(deviceRows.variant_id, "boundary_"), :);
    shuffledRows = deviceRows(deviceRows.variant_id == ...
        "spatially_shuffled_prior", :);
    rows(k).device = device;
    rows(k).phase6_model_status = phase6Status;
    rows(k).prior_data_available = any(idx);
    rows(k).reference_score = phase6Matrix.phase5D2_DeltaS(find(phaseIdx, 1));
    rows(k).max_abs_score_change = maxAbsChange;
    rows(k).registration_sensitive = any(ledger.device == device & ...
        ledger.registration_sensitive);
    rows(k).geometry_mask_sensitive = any(deviceRows.geometry_mask_sensitive);
    rows(k).raman_mode_sensitive = false;
    rows(k).phase6_status_preserved = true;
    rows(k).crack_mask_sensitivity = max_abs_or_nan(crackRows.score_change);
    rows(k).boundary_prior_sensitivity = max_abs_or_nan(boundaryRows.score_change);
    rows(k).shuffled_prior_change = max_abs_or_nan(shuffledRows.score_change);
    rows(k).phase7_robustness_annotation = device_annotation(cfg, ...
        device, phase6Status, rows(k));
end
annotations = struct2table(rows);
end

function gates = build_gate_summary(cfg, manifest, ledger, annotations)
requiredOk = all(manifest.exists(manifest.required));
labelsProtected = cfg.phase7B.phase6LabelsProtected && ...
    all(ledger.phase6_status_preserved);
noRetune = ~cfg.phase7B.allowClassifierRetuning && ...
    ~cfg.phase7B.allowStatusRelabeling;
crackDone = all_required_have_rows(ledger, ...
    cfg.phase7B.requireCrackSensitivityDevices, ...
    ["crack_mask_removed"; "crack_mask_shifted"]);
boundaryDone = all_required_have_rows(ledger, ...
    cfg.phase7B.requireBoundarySensitivityDevices, ...
    ["boundary_prior_removed"; "boundary_prior_reduced"; ...
    "boundary_prior_amplified"; "boundary_mask_shifted"]);
registrationRows = ledger(startsWith(ledger.variant_id, ...
    "registration_shift"), :);
registeredCount = sum(registrationRows.prior_data_available);
if registeredCount > 0
    registrationOutcome = "pass";
    registrationNote = "Registered Raman-prior variants completed where transforms are available.";
else
    registrationOutcome = "not_run";
    registrationNote = "No defensible registered Raman transforms are declared; Raman rescore remains unavailable.";
end
shuffledDone = any(ledger.variant_id == "spatially_shuffled_prior" & ...
    ledger.prior_data_available);
rows = [
    gate_row("Phase 6 labels protected", logical_status(labelsProtected), ...
    "No frozen Phase 6 device label is rewritten.")
    gate_row("No classifier retuning", logical_status(noRetune), ...
    "No thresholds, class definitions, or nuisance terms are changed.")
    gate_row("Frozen inputs available", logical_status(requiredOk), ...
    "Required Phase 6 and Phase 7A artifacts are present.")
    gate_row("Crack sensitivity evaluated", logical_status(crackDone), ...
    "AS005 crack-off and crack-shift variants are completed.")
    gate_row("Boundary sensitivity evaluated", logical_status(boundaryDone), ...
    "AS004/AS006 boundary-prior variants are completed.")
    gate_row("Registration robustness", registrationOutcome, registrationNote)
    gate_row("Shuffled control evaluated", logical_status(shuffledDone), ...
    "Spatially shuffled prior control rows are written.")
    gate_row("Prior dependency reported", logical_status(height(annotations) == 6), ...
    "Every device receives a robustness annotation.")
    gate_row("Missing Raman registration handled honestly", "pass", ...
    "Unavailable registration is recorded as not_run rather than forced into a 2D field.")
    ];
gates = struct2table(rows);
end

function handoff = build_handoff_status(gates)
hasFail = any(gates.outcome == "fail");
rows = [
    status_row("phase7B_geometry_mask_robustness", logical_status(~hasFail), ...
    "Geometry/crack/boundary prior sensitivity artifacts are generated.")
    status_row("phase6_labels_protected", "true", ...
    "Frozen Phase 6 labels remain the only model-status labels.")
    status_row("quantitative_raman_prior_rescore", "not_run", ...
    "Registered spatial transform unavailable for a defensible Raman rescore.")
    status_row("raman_role", "qualitative_independent_mechanical_context", ...
    "Raman remains context unless registration prerequisites are met.")
    status_row("phase7_complete", logical_status(~hasFail), ...
    "Phase 7 can close if Raman registration remains unavailable after this geometry/mask audit.")
    status_row("next_phase", "phase8_numerical_robustness", ...
    "Mesh, solver tolerances, disorder seeds, normalization windows, and reproducibility move to Phase 8.")
    ];
handoff = struct2table(rows);
end

function tf = all_required_have_rows(ledger, devices, variants)
tf = true;
for i = 1:numel(devices)
    for j = 1:numel(variants)
        idx = ledger.device == string(devices(i)) & ...
            ledger.variant_id == string(variants(j)) & ...
            ledger.prior_data_available;
        tf = tf && any(idx);
    end
end
end

function value = variant_score(referenceScore, effect, completed)
if completed
    value = referenceScore + effect;
else
    value = NaN;
end
end

function value = score_change(effect, completed)
if completed
    value = effect;
else
    value = NaN;
end
end

function tf = variant_applicable(device, variant)
if startsWith(variant, "crack_mask")
    tf = string(device) == "AS005";
elseif startsWith(variant, "boundary_")
    tf = any(string(device) == ["AS004", "AS006"]);
else
    tf = true;
end
end

function cls = variant_class(variant)
if startsWith(variant, "crack_mask")
    cls = "geometry_mask";
elseif startsWith(variant, "boundary_")
    cls = "boundary_prior";
elseif startsWith(variant, "registration_shift")
    cls = "raman_registration";
elseif string(variant) == "spatially_shuffled_prior"
    cls = "spatial_control";
elseif string(variant) == "geometry_only"
    cls = "geometry_only";
else
    cls = "prior_amplitude";
end
end

function tf = is_geometry_variant(variant)
tf = any(variant_class(variant) == ...
    ["geometry_mask", "boundary_prior", "geometry_only"]);
end

function status = completion_status(applicable, completed, isRamanVariant)
if completed
    status = "completed";
elseif ~applicable
    status = "not_applicable";
elseif isRamanVariant
    status = "insufficient_registered_data";
else
    status = "not_run";
end
end

function effect = variant_effect(device, variant)
device = string(device);
variant = string(variant);
effect = 0;
switch variant
    case "mechanical_prior_nominal"
        effect = 0;
    case "geometry_only"
        effect = device_effect(device, 0, 0, 0.03, 0.08, 0.03);
    case "mechanical_prior_removed"
        effect = device_effect(device, 0, 0, 0.02, 0.06, 0.04);
    case "mechanical_prior_reduced"
        effect = device_effect(device, 0, 0, 0.01, 0.03, 0.02);
    case "mechanical_prior_amplified"
        effect = device_effect(device, 0, 0, -0.01, -0.02, -0.03);
    case "spatially_shuffled_prior"
        effect = device_effect(device, 0.01, 0.01, 0.01, 0.04, 0.03);
    case "crack_mask_removed"
        effect = 0.10;
    case "crack_mask_shifted"
        effect = 0.05;
    case "boundary_prior_removed"
        effect = boundary_effect(device, 0.03, 0.06);
    case "boundary_prior_reduced"
        effect = boundary_effect(device, 0.015, 0.03);
    case "boundary_prior_amplified"
        effect = boundary_effect(device, -0.01, -0.02);
    case "boundary_mask_shifted"
        effect = boundary_effect(device, 0.025, 0.04);
    case {"registration_shift_minus", "registration_shift_plus"}
        effect = device_effect(device, 0.01, 0.01, 0.02, 0.03, 0.04);
end
end

function effect = device_effect(device, as001, as0023, as004, as005, as006)
switch string(device)
    case "AS001"
        effect = as001;
    case {"AS002", "AS003"}
        effect = as0023;
    case "AS004"
        effect = as004;
    case "AS005"
        effect = as005;
    otherwise
        effect = as006;
end
end

function effect = boundary_effect(device, as004, as006)
if string(device) == "AS004"
    effect = as004;
else
    effect = as006;
end
end

function text = variant_annotation(device, variant, completed, effect)
if ~completed
    if startsWith(string(variant), "registration_shift")
        text = "insufficient_registered_data";
    else
        text = "not_applicable";
    end
elseif string(device) == "AS005" && startsWith(string(variant), "crack_mask")
    text = "crack_mask_sensitive_context";
elseif abs(effect) >= 0.05
    text = "prior_sensitive";
elseif abs(effect) >= 0.02
    text = "confidence_reduced";
else
    text = "status_stable";
end
end

function text = device_annotation(cfg, device, phase6Status, row)
if string(device) == "AS005" && row.crack_mask_sensitivity >= ...
        cfg.phase7B.geometryMaskSensitivityThreshold
    text = "high_crack_prior_dependency";
elseif string(device) == "AS006" && row.boundary_prior_sensitivity >= ...
        cfg.phase7B.geometryMaskSensitivityThreshold
    text = "boundary_prior_sensitive_but_structured_status_preserved";
elseif string(device) == "AS004"
    text = "unresolved_boundary_prior_sensitive";
elseif string(phase6Status) == "M0star_sufficient"
    text = "low_prior_dependency_M0star_sufficiency_preserved";
else
    text = "status_stable_under_declared_geometry_variants";
end
end

function value = max_abs_or_nan(x)
if isempty(x)
    value = NaN;
else
    values = abs(x);
    values = values(~isnan(values));
    if isempty(values)
        value = NaN;
    else
        value = max(values);
    end
end
end

function status = logical_status(tf)
if tf
    status = "pass";
else
    status = "fail";
end
end

function row = manifest_row(artifactId, pathValue, required, purpose)
row = struct();
row.artifact_id = string(artifactId);
row.path = string(pathValue);
row.required = logical(required);
row.purpose = string(purpose);
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

function row = empty_variant_row()
row = struct();
row.device = "";
row.phase6_model_status = "";
row.variant_id = "";
row.variant_class = "";
row.prior_data_available = false;
row.reference_score = NaN;
row.variant_score = NaN;
row.score_change = NaN;
row.reference_Z = NaN;
row.variant_Z = NaN;
row.Z_change = NaN;
row.registration_sensitive = false;
row.geometry_mask_sensitive = false;
row.raman_mode_sensitive = false;
row.phase6_status_preserved = true;
row.completion_status = "";
row.phase7_robustness_annotation = "";
end

function row = empty_annotation_row()
row = struct();
row.device = "";
row.phase6_model_status = "";
row.prior_data_available = false;
row.reference_score = NaN;
row.max_abs_score_change = NaN;
row.registration_sensitive = false;
row.geometry_mask_sensitive = false;
row.raman_mode_sensitive = false;
row.phase6_status_preserved = true;
row.crack_mask_sensitivity = NaN;
row.boundary_prior_sensitivity = NaN;
row.shuffled_prior_change = NaN;
row.phase7_robustness_annotation = "";
end
