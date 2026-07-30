function out = run_phase11_multimodal_data_architecture(cfg)
%RUN_PHASE11_MULTIMODAL_DATA_ARCHITECTURE Freeze multimodal data schemas.

if ~exist(cfg.outputDir, 'dir')
    mkdir(cfg.outputDir);
end

sourceProvenance = build_source_provenance(cfg);
inputs = load_phase11_inputs(cfg);
deviceObservableManifest = build_device_observable_manifest(cfg, inputs);
transportDataSchema = build_transport_data_schema();
nonlinearDataSchema = build_nonlinear_data_schema();
ramanDataSchema = build_raman_data_schema();
geometryCoordinateSchema = build_geometry_coordinate_schema();
probeMapping = build_probe_mapping(cfg, inputs);
registrationAvailability = build_registration_availability(cfg, inputs, ...
    deviceObservableManifest);
uncertaintyManifest = build_uncertainty_manifest();
gateSummary = build_gate_summary(cfg, inputs, deviceObservableManifest, ...
    transportDataSchema, nonlinearDataSchema, ramanDataSchema, ...
    geometryCoordinateSchema, probeMapping, registrationAvailability, ...
    uncertaintyManifest, sourceProvenance);
handoffStatus = build_handoff_status(cfg, gateSummary, sourceProvenance);

writetable(deviceObservableManifest, ...
    cfg.phase11.deviceObservableManifestFile);
writetable(transportDataSchema, cfg.phase11.transportDataSchemaFile);
writetable(nonlinearDataSchema, cfg.phase11.nonlinearDataSchemaFile);
writetable(ramanDataSchema, cfg.phase11.ramanDataSchemaFile);
writetable(geometryCoordinateSchema, ...
    cfg.phase11.geometryCoordinateSchemaFile);
writetable(probeMapping, cfg.phase11.probeMappingFile);
writetable(registrationAvailability, ...
    cfg.phase11.registrationAvailabilityFile);
writetable(uncertaintyManifest, cfg.phase11.uncertaintyManifestFile);
writetable(gateSummary, cfg.phase11.gateSummaryFile);
writetable(handoffStatus, cfg.phase11.handoffStatusFile);
writetable(sourceProvenance, cfg.phase11.sourceProvenanceFile);

try
    h = v800.plot_phase11_multimodal_architecture_summary(cfg, ...
        deviceObservableManifest, registrationAvailability, ...
        transportDataSchema, nonlinearDataSchema, ramanDataSchema, ...
        geometryCoordinateSchema, gateSummary);
catch ME
    warning('v8:phase11PlotFailed', ...
        'Phase 11 multimodal architecture plot failed: %s', ME.message);
    h = [];
end

out = struct();
out.config = cfg;
out.inputs = inputs;
out.deviceObservableManifest = deviceObservableManifest;
out.transportDataSchema = transportDataSchema;
out.nonlinearDataSchema = nonlinearDataSchema;
out.ramanDataSchema = ramanDataSchema;
out.geometryCoordinateSchema = geometryCoordinateSchema;
out.probeMapping = probeMapping;
out.registrationAvailability = registrationAvailability;
out.uncertaintyManifest = uncertaintyManifest;
out.gateSummary = gateSummary;
out.handoffStatus = handoffStatus;
out.sourceProvenance = sourceProvenance;
out.figure = h;
out.paths = struct();
out.paths.deviceObservableManifest = ...
    cfg.phase11.deviceObservableManifestFile;
out.paths.transportDataSchema = cfg.phase11.transportDataSchemaFile;
out.paths.nonlinearDataSchema = cfg.phase11.nonlinearDataSchemaFile;
out.paths.ramanDataSchema = cfg.phase11.ramanDataSchemaFile;
out.paths.geometryCoordinateSchema = ...
    cfg.phase11.geometryCoordinateSchemaFile;
out.paths.probeMapping = cfg.phase11.probeMappingFile;
out.paths.registrationAvailability = ...
    cfg.phase11.registrationAvailabilityFile;
out.paths.uncertaintyManifest = cfg.phase11.uncertaintyManifestFile;
out.paths.gateSummary = cfg.phase11.gateSummaryFile;
out.paths.handoffStatus = cfg.phase11.handoffStatusFile;
out.paths.sourceProvenance = cfg.phase11.sourceProvenanceFile;
out.paths.figurePng = [cfg.phase11.figureBaseFile '.png'];
out.paths.figurePdf = [cfg.phase11.figureBaseFile '.pdf'];
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
    "phase11_multimodal_data_architecture"
    sourceStatus.commit_sha
    sourceStatus.tree_sha
    string(sourceStatus.tracked_clean)
    string(sourceStatus.untracked_clean)
    string(sourceStatus.tracked_clean && sourceStatus.untracked_clean)
    "data_architecture_no_retuning"
    "Run Phase 11 on a Phase 11 branch after the v8.0 release tag; do not modify frozen v8 labels."
    ];
note = [
    "Phase 11 multimodal observable and schema architecture."
    "Git commit captured before this runner writes outputs."
    "Git tree object captured before this runner writes outputs."
    "Tracked-source cleanliness before output generation."
    "Untracked-source/artifact cleanliness before output generation."
    "True only when the checkout is clean before this run writes outputs."
    "Schema/manifest phase; no transport refit or joint forward model."
    "Generated artifacts should be committed separately from source changes."
    ];
provenance = table(item, value, note);
end

function inputs = load_phase11_inputs(cfg)
inputs = struct();
inputs.phase10Handoff = read_optional_table(cfg.phase10.handoffStatusFile);
inputs.phase10Gates = read_optional_table(cfg.phase10.gateSummaryFile);
inputs.phase9DeviceLedger = read_optional_table( ...
    cfg.phase9.finalDeviceConclusionLedgerFile);
inputs.phase6EvidenceMatrix = read_optional_table( ...
    cfg.phase6.sixDeviceEvidenceMatrixFile);
inputs.phase5D2Context = read_optional_table( ...
    cfg.phase5D2.realDeviceScoreContextFile);
inputs.phase7Prior = read_optional_table( ...
    fullfile(cfg.outputDir, 'phase7_prior_evidence_manifest.csv'));
inputs.phase9RamanDisposition = read_optional_table( ...
    cfg.phase9.ramanRegistrationDiagnosticFile);
inputs.phase5DataManifest = safe_build_data_manifest(cfg);
inputs.phase5RtManifest = safe_build_rt_manifest(cfg);
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

function T = safe_build_data_manifest(cfg)
try
    T = v800.build_phase5_data_manifest(cfg);
catch
    T = table();
end
end

function T = safe_build_rt_manifest(cfg)
try
    T = v800.build_phase5_rt_manifest(cfg);
catch
    T = table();
end
end

function manifest = build_device_observable_manifest(cfg, inputs)
rows = repmat(empty_device_row(), numel(cfg.devices), 1);
for k = 1:numel(cfg.devices)
    device = string(cfg.devices(k));
    data = row_for_device(inputs.phase5DataManifest, device);
    rt = row_for_device(inputs.phase5RtManifest, device);
    phase6 = row_for_device(inputs.phase6EvidenceMatrix, device);
    phase9 = row_for_device(inputs.phase9DeviceLedger, device);
    context = row_for_device(inputs.phase5D2Context, device);

    hasRT = bool_field(data, "has_rt");
    hasSecondary = bool_field(data, "has_second_probe");
    hasDvdIIT = bool_field(data, "has_dvdi_it");
    hasIV = bool_field(data, "has_iv");
    hasDvdIIB = bool_field(data, "has_dvdi_ib");
    hasRaman = bool_field(data, "has_raman") || ...
        strlength(lookup_device_value(inputs.phase7Prior, device, ...
        "raman_status", "")) > 0;
    primaryProbe = lookup_struct_value(rt, "primary_probe", "");
    secondaryProbe = lookup_struct_value(rt, "secondary_probe", "");
    primaryLoaded = bool_field(rt, "primary_curve_loaded") || hasRT;
    secondaryLoaded = hasSecondary || ...
        lookup_struct_value(rt, "secondary_status", "") == ...
        "available_held_out";
    topLoaded = (primaryProbe == "top_4_10" && primaryLoaded) || ...
        (secondaryProbe == "top_4_10" && secondaryLoaded);
    bottomLoaded = (primaryProbe == "bottom_3_9" && primaryLoaded) || ...
        (secondaryProbe == "bottom_3_9" && secondaryLoaded);

    rows(k).device = device;
    rows(k).frozen_v8_conclusion = first_nonempty([
        lookup_struct_value(phase9, "final_model_status", "")
        lookup_struct_value(phase9, "final_device_conclusion", "")
        lookup_struct_value(phase9, "frozen_conclusion", "")
        lookup_struct_value(phase6, "final_model_status", "")
        lookup_struct_value(phase6, "frozen_model_status", "")
        lookup_struct_value(phase6, "device_model_status", "")
        ]);
    rows(k).evidence_tier = first_nonempty([
        lookup_struct_value(phase6, "evidence_tier", "")
        lookup_struct_value(context, "evidence_tier", "")
        "unassigned"
        ]);
    rows(k).primary_probe = primaryProbe;
    rows(k).secondary_probe = secondaryProbe;
    rows(k).has_RT = hasRT;
    rows(k).has_R1_RT = topLoaded;
    rows(k).has_R2_RT = bottomLoaded;
    rows(k).has_primary_RT = primaryLoaded;
    rows(k).has_secondary_RT = secondaryLoaded;
    rows(k).has_IV = hasIV;
    rows(k).has_dVdI_IT = hasDvdIIT;
    rows(k).has_dVdI_IB = hasDvdIIB;
    rows(k).has_Raman_hint = hasRaman;
    rows(k).registered_Raman_available = false;
    rows(k).geometry_context_status = geometry_context_status(device);
    rows(k).raw_data_status = raw_data_status(hasRT, hasIV, hasDvdIIT, ...
        hasDvdIIB, hasRaman);
    rows(k).processed_data_status = processed_data_status(hasRT, ...
        hasSecondary, hasDvdIIB);
    rows(k).phase11_role = phase11_role(rows(k).frozen_v8_conclusion, ...
        hasRT, hasDvdIIB, hasRaman);
    rows(k).note = "Architecture inventory only; no v8 status changes or joint fit.";
end
manifest = struct2table(rows);
end

function schema = build_transport_data_schema()
rows = [
    schema_row("R_T_main_4p", "temperature_K", ...
    "four_probe_resistance_ohm", "K; ohm", "raw_or_publication_csv", ...
    "normalized only for scoring; raw retained as authority", ...
    "monotonic temperature interpolation only for comparison grids", ...
    "AS001-AS006", "required_for_device_context")
    schema_row("R1_T_top_4_10", "temperature_K", ...
    "top_probe_resistance_ohm", "K; ohm", "raw_pair_or_reduced_dVdI", ...
    "low-bias pair curves kept separate from main_4p", ...
    "near-zero-current reduction allowed only when source is I-sweep", ...
    "devices with pairData", "secondary_probe_context")
    schema_row("R2_T_bottom_3_9", "temperature_K", ...
    "bottom_probe_resistance_ohm", "K; ohm", "raw_pair_or_reduced_dVdI", ...
    "low-bias pair curves kept separate from main_4p", ...
    "near-zero-current reduction allowed only when source is I-sweep", ...
    "devices with pairData", "secondary_probe_context")
    schema_row("transition_metrics", ...
    "temperature_K; normalized_R", ...
    "onset_width_lowT_metrics", "K; unitless", "processed", ...
    "metrics derive from declared R(T) normalization policy", ...
    "fixed grid for metrics only; raw data remains unmodified", ...
    "AS001-AS006 when R(T) exists", "derived_context")
    ];
schema = struct2table(rows);
end

function schema = build_nonlinear_data_schema()
rows = [
    schema_row("I_V", "current_A; temperature_K_optional", ...
    "voltage_V", "A; K; V", "raw", ...
    "no universal normalization frozen in Phase 11", ...
    "no interpolation before source-specific schema validation", ...
    "available_if_identified", "future_predictive_input")
    schema_row("dVdI_I_T", "current_A; temperature_K", ...
    "differential_resistance_ohm", "A; K; ohm", ...
    "raw_grid_or_processed_grid", ...
    "optional RN normalization must record RN estimator", ...
    "grid interpolation only after axes and current polarity are declared", ...
    "currently AS006 loader-backed", "schema_ready_limited_scope")
    schema_row("dVdI_I_B", "current_A; magnetic_field_T", ...
    "differential_resistance_ohm", "A; T; ohm", ...
    "raw_grid_or_processed_grid", ...
    "optional RN normalization must record RN estimator", ...
    "field direction and assumed temperature must be explicit", ...
    "currently AS006 loader-backed", "schema_ready_limited_scope")
    ];
schema = struct2table(rows);
end

function schema = build_raman_data_schema()
rows = [
    schema_row("raman_spectrum", "scan_x; scan_y; wavenumber_cm_minus_1", ...
    "intensity", "um_or_pixel; cm^-1; arbitrary", "raw", ...
    "no transport-model normalization in Phase 11", ...
    "spectral preprocessing must be declared before model use", ...
    "AS002/AS005/AS006 hints", "registration_required")
    schema_row("raman_shift_proxy", "scan_x; scan_y", ...
    "relative_shift_or_proxy", "unitless_or_cm^-1", "processed", ...
    "proxy maps are qualitative until registration is defensible", ...
    "spatial interpolation forbidden without transform manifest", ...
    "historical v5-v7 scripts", "qualitative_context")
    schema_row("registered_raman_map", "device_x; device_y", ...
    "registered_raman_feature", "device_length_unit", "processed", ...
    "not available in frozen v8 release", ...
    "requires explicit affine/nonlinear transform and residual audit", ...
    "not currently accepted", "not_ready")
    ];
schema = struct2table(rows);
end

function schema = build_geometry_coordinate_schema()
rows = [
    schema_row("device_frame", "x; y", "device_coordinate", ...
    "normalized_device_length_or_um", "declared_coordinate_system", ...
    "origin/contact convention must be stated per device", ...
    "geometry masks may be resampled to model mesh only after recording rule", ...
    "AS001-AS006", "required")
    schema_row("contact_pairs", "contact_id; x; y", ...
    "electrical_contact_location", "device_length_unit", "declared", ...
    "top_4_10 and bottom_3_9 remain explicit probe pairs", ...
    "no coordinate inference from label alone", ...
    "AS001-AS006", "required")
    schema_row("crack_boundary_masks", "x; y; mask_name", ...
    "geometry_or_mechanical_mask", "unitless", "processed_context", ...
    "masks are context/priors, not automatic classifier labels", ...
    "mask perturbations must record displacement and dilation policy", ...
    "AS004-AS006 emphasis", "contextual_prior")
    ];
schema = struct2table(rows);
end

function probeMapping = build_probe_mapping(cfg, inputs)
rows = repmat(empty_probe_row(), numel(cfg.devices), 1);
for k = 1:numel(cfg.devices)
    device = string(cfg.devices(k));
    rt = row_for_device(inputs.phase5RtManifest, device);
    rows(k).device = device;
    rows(k).primary_probe = lookup_struct_value(rt, "primary_probe", "");
    rows(k).primary_experimental_channel = lookup_struct_value(rt, ...
        "experimental_channel", "");
    rows(k).secondary_probe = lookup_struct_value(rt, "secondary_probe", "");
    rows(k).secondary_status = lookup_struct_value(rt, ...
        "secondary_status", "not_applicable");
    rows(k).probe_pair_convention = ...
        "top_4_10 and bottom_3_9 are retained as separate observables";
    rows(k).coordinate_convention = ...
        "device-local; no cross-device geometric registration assumed";
    rows(k).phase11_policy = ...
        "probe mappings may be consumed by future models but not relabeled here";
end
probeMapping = struct2table(rows);
end

function availability = build_registration_availability(cfg, inputs, manifest)
rows = repmat(empty_registration_row(), numel(cfg.devices), 1);
for k = 1:numel(cfg.devices)
    device = string(cfg.devices(k));
    rows(k).device = device;
    rows(k).raman_hint_available = logical(manifest.has_Raman_hint(k));
    rows(k).registered_raman_available = false;
    rows(k).registration_status = ternary(rows(k).raman_hint_available, ...
        "not_run_no_defensible_transform", "not_applicable_no_raman_hint");
    rows(k).transform_manifest = "not_available";
    rows(k).residual_error_policy = ...
        "required before quantitative Raman-to-transport use";
    rows(k).geometry_registration_status = geometry_context_status(device);
    rows(k).phase11_policy = ...
        "Raman remains qualitative context until transform and residuals are archived";
end
availability = struct2table(rows);
end

function manifest = build_uncertainty_manifest()
rows = [
    uncertainty_row("temperature_axis", "K", ...
    "calibration offset; sweep history; interpolation grid", ...
    "record source axis and any resampling in downstream fits")
    uncertainty_row("resistance_axis", "ohm", ...
    "contact resistance; normal-state normalization; shunt paths", ...
    "retain raw R and normalized R as separate fields")
    uncertainty_row("current_bias", "A", ...
    "excitation amplitude; zero-current reduction for pair files", ...
    "record current selected for low-bias R(T) reductions")
    uncertainty_row("magnetic_field", "T", ...
    "field direction; remanence; assumed temperature", ...
    "field-sweep files require explicit direction metadata")
    uncertainty_row("probe_registration", "device coordinate", ...
    "contact assignment and probe-pair mapping uncertainty", ...
    "do not merge top/bottom probes without declared mapping")
    uncertainty_row("raman_registration", "device coordinate", ...
    "scan-to-device transform and residual uncertainty", ...
    "quantitative use blocked until transform manifest exists")
    uncertainty_row("geometry_masks", "device coordinate", ...
    "crack/boundary mask dilation and displacement", ...
    "future perturbation ledgers must preserve raw mask provenance")
    ];
manifest = struct2table(rows);
end

function gates = build_gate_summary(cfg, inputs, deviceManifest, ...
    transportSchema, nonlinearSchema, ramanSchema, geometrySchema, ...
    probeMapping, registrationAvailability, uncertaintyManifest, ...
    sourceProvenance)
phase10Pass = lookup_status(inputs.phase10Handoff, ...
    "phase10_all_gates", "fail") == "pass";
hasAllDevices = height(deviceManifest) == numel(cfg.devices) && ...
    all(strlength(deviceManifest.device) > 0);
schemasWritten = all([height(transportSchema), height(nonlinearSchema), ...
    height(ramanSchema), height(geometrySchema), height(uncertaintyManifest)] > 0);
probeReady = height(probeMapping) == numel(cfg.devices);
registrationExplicit = height(registrationAvailability) == numel(cfg.devices) && ...
    all(strlength(registrationAvailability.registration_status) > 0);
rawProcessedSeparated = all(strlength(deviceManifest.raw_data_status) > 0) && ...
    all(strlength(deviceManifest.processed_data_status) > 0);
noRetune = ~cfg.phase11.allowV8StatusChanges && ...
    ~cfg.phase11.allowModelRetuning && ~cfg.phase11.allowJointForwardFit;
trackedClean = lookup_value(sourceProvenance, ...
    "source_pre_run_tracked_clean", "false") == "true";
rows = [
    gate_row("Phase 10 release boundary consumed", ...
    logical_status(phase10Pass), ...
    "Phase 11 starts after the clean v8.0 release artifact freeze.")
    gate_row("Device observable manifest complete", ...
    logical_status(hasAllDevices), ...
    "AS001-AS006 all appear in the multimodal manifest.")
    gate_row("Observable schemas written", logical_status(schemasWritten), ...
    "Transport, nonlinear, Raman, geometry, and uncertainty schemas are present.")
    gate_row("Probe mapping explicit", logical_status(probeReady), ...
    "Primary and secondary probe mappings are declared per device.")
    gate_row("Registration availability explicit", ...
    logical_status(registrationExplicit), ...
    "Raman registration unavailable states are recorded rather than inferred.")
    gate_row("Raw/processed separation declared", ...
    logical_status(rawProcessedSeparated), ...
    "Raw and processed data roles are distinct in the manifest.")
    gate_row("No v8 status changes or retuning", logical_status(noRetune), ...
    "Phase 11 is a data architecture phase only.")
    gate_row("Tracked source provenance clean", logical_status(trackedClean), ...
    "Tracked source files were clean before Phase 11 wrote outputs.")
    ];
gates = struct2table(rows);
end

function handoff = build_handoff_status(cfg, gates, provenance)
coreReady = all(gates.outcome == "pass");
rows = [
    status_row("phase11_multimodal_data_architecture", ...
    logical_status(coreReady), ...
    "Device-centered multimodal observable architecture generated.")
    status_row("phase11_closure", ...
    ternary(coreReady, "pass_data_architecture", ...
    "fail_data_architecture"), ...
    "Phase 11 closes only as schema/manifest architecture, not as a joint model.")
    status_row("v8_release_tag_consumed", ...
    "v8.0-core-inference-release", ...
    "Frozen v8 mechanism hierarchy is treated as input.")
    status_row("model_retuning_performed", "false", ...
    "No model parameters are retuned.")
    status_row("device_status_changes", "false", ...
    "Frozen v8 device conclusions are preserved.")
    status_row("joint_forward_fit_performed", "false", ...
    "No unified predictive model is fit in Phase 11.")
    status_row("source_commit_sha", lookup_value(provenance, ...
    "source_commit_sha", "unknown"), ...
    "Source commit used to generate Phase 11 artifacts.")
    status_row("next_phase", "phase12_multimodal_loader_validation", ...
    "Recommended next step: validate loaders/raw-data links before predictive modeling.")
    ];
handoff = struct2table(rows);
end

function row = row_for_device(T, device)
row = struct();
if isempty(T)
    return;
end
devices = table_column(T, "device");
idx = find(devices == string(device), 1, 'first');
if isempty(idx)
    return;
end
names = string(T.Properties.VariableNames);
for k = 1:numel(names)
    row.(matlab.lang.makeValidName(char(names(k)))) = T.(char(names(k)))(idx);
end
end

function value = lookup_device_value(T, device, columnName, defaultValue)
value = string(defaultValue);
row = row_for_device(T, device);
if isempty(fieldnames(row))
    return;
end
value = lookup_struct_value(row, columnName, defaultValue);
end

function value = lookup_struct_value(row, requestedName, defaultValue)
value = string(defaultValue);
if isempty(row) || isempty(fieldnames(row))
    return;
end
names = string(fieldnames(row));
idx = find(normalize_name(names) == normalize_name(requestedName), ...
    1, 'first');
if isempty(idx)
    return;
end
value = string(row.(char(names(idx))));
end

function tf = bool_field(row, requestedName)
tf = false;
if isempty(row) || isempty(fieldnames(row))
    return;
end
value = lookup_struct_value(row, requestedName, "false");
tf = any(lower(value) == ["true", "1", "yes"]);
end

function values = table_column(T, requestedName)
values = strings(0, 1);
if isempty(T)
    return;
end
names = string(T.Properties.VariableNames);
idx = find(normalize_name(names) == normalize_name(requestedName), ...
    1, 'first');
if isempty(idx) && ~isempty(T.Properties.VariableDescriptions)
    desc = string(T.Properties.VariableDescriptions);
    idx = find(normalize_name(desc) == normalize_name(requestedName), ...
        1, 'first');
end
if isempty(idx)
    return;
end
values = string(T.(char(names(idx))));
end

function out = normalize_name(name)
out = lower(regexprep(string(name), '[^A-Za-z0-9]+', ''));
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

function out = first_nonempty(values)
values = string(values);
values = values(strlength(values) > 0 & values ~= "missing");
if isempty(values)
    out = "";
else
    out = values(1);
end
end

function status = geometry_context_status(device)
device = upper(string(device));
if any(device == ["AS004", "AS005", "AS006"])
    status = "geometry_mechanical_context_required";
elseif any(device == ["AS001", "AS002", "AS003"])
    status = "geometry_control_context";
else
    status = "unassigned";
end
end

function status = raw_data_status(hasRT, hasIV, hasDvdIIT, hasDvdIIB, hasRaman)
items = strings(0, 1);
if hasRT
    items(end+1, 1) = "RT_raw_or_publication";
end
if hasIV
    items(end+1, 1) = "IV_hint";
end
if hasDvdIIT
    items(end+1, 1) = "dVdI_IT";
end
if hasDvdIIB
    items(end+1, 1) = "dVdI_IB";
end
if hasRaman
    items(end+1, 1) = "Raman_hint";
end
if isempty(items)
    status = "no_declared_raw_observable";
else
    status = string(strjoin(cellstr(items), "; "));
end
end

function status = processed_data_status(hasRT, hasSecondary, hasDvdIIB)
items = strings(0, 1);
if hasRT
    items(end+1, 1) = "normalized_RT_allowed";
end
if hasSecondary
    items(end+1, 1) = "paired_probe_context_allowed";
end
if hasDvdIIB
    items(end+1, 1) = "field_nonlinear_context_allowed";
end
if isempty(items)
    status = "processed_role_not_ready";
else
    status = string(strjoin(cellstr(items), "; "));
end
end

function role = phase11_role(frozenStatus, hasRT, hasDvdIIB, hasRaman)
frozenStatus = lower(string(frozenStatus));
if contains(frozenStatus, "structured") && hasDvdIIB
    role = "structured_anchor_with_nonlinear_context";
elseif contains(frozenStatus, "structured")
    role = "structured_context_device";
elseif contains(frozenStatus, "m0") || contains(frozenStatus, "sufficient")
    role = "control_or_local_limit_context";
elseif hasRT || hasRaman
    role = "unresolved_context_device";
else
    role = "data_gap_device";
end
end

function row = empty_device_row()
row = struct();
row.device = "";
row.frozen_v8_conclusion = "";
row.evidence_tier = "";
row.primary_probe = "";
row.secondary_probe = "";
row.has_RT = false;
row.has_R1_RT = false;
row.has_R2_RT = false;
row.has_primary_RT = false;
row.has_secondary_RT = false;
row.has_IV = false;
row.has_dVdI_IT = false;
row.has_dVdI_IB = false;
row.has_Raman_hint = false;
row.registered_Raman_available = false;
row.geometry_context_status = "";
row.raw_data_status = "";
row.processed_data_status = "";
row.phase11_role = "";
row.note = "";
end

function row = empty_probe_row()
row = struct();
row.device = "";
row.primary_probe = "";
row.primary_experimental_channel = "";
row.secondary_probe = "";
row.secondary_status = "";
row.probe_pair_convention = "";
row.coordinate_convention = "";
row.phase11_policy = "";
end

function row = empty_registration_row()
row = struct();
row.device = "";
row.raman_hint_available = false;
row.registered_raman_available = false;
row.registration_status = "";
row.transform_manifest = "";
row.residual_error_policy = "";
row.geometry_registration_status = "";
row.phase11_policy = "";
end

function row = schema_row(observable, independentAxes, dependentQuantity, ...
    units, dataLayer, normalizationPolicy, interpolationPolicy, ...
    deviceScope, schemaStatus)
row = struct();
row.observable = string(observable);
row.independent_axes = string(independentAxes);
row.dependent_quantity = string(dependentQuantity);
row.units = string(units);
row.data_layer = string(dataLayer);
row.normalization_policy = string(normalizationPolicy);
row.interpolation_policy = string(interpolationPolicy);
row.device_scope = string(deviceScope);
row.schema_status = string(schemaStatus);
end

function row = uncertainty_row(source, units, uncertainty, policy)
row = struct();
row.uncertainty_source = string(source);
row.units = string(units);
row.uncertainty_description = string(uncertainty);
row.phase11_policy = string(policy);
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

function out = ternary(tf, a, b)
if tf
    out = string(a);
else
    out = string(b);
end
end
