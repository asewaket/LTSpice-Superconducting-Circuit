function out = run_phase12A_raman_registration_feasibility(cfg)
%RUN_PHASE12A_RAMAN_REGISTRATION_FEASIBILITY Freeze Raman registration status.

if ~exist(cfg.outputDir, 'dir')
    mkdir(cfg.outputDir);
end

sourceProvenance = build_source_provenance(cfg);
inputs = load_phase12A_inputs(cfg);
ramanRegistrationLedger = build_raman_registration_ledger(cfg, inputs);
coordinateTransformManifest = build_coordinate_transform_manifest(cfg, ...
    ramanRegistrationLedger);
mechanicalInputDefinition = build_mechanical_input_definition(cfg, inputs, ...
    ramanRegistrationLedger);
registrationGateSummary = build_registration_gate_summary(cfg, inputs, ...
    ramanRegistrationLedger, coordinateTransformManifest, ...
    mechanicalInputDefinition, sourceProvenance);
handoffStatus = build_handoff_status(cfg, registrationGateSummary, ...
    sourceProvenance);

writetable(ramanRegistrationLedger, ...
    cfg.phase12A.ramanRegistrationLedgerFile);
writetable(coordinateTransformManifest, ...
    cfg.phase12A.coordinateTransformManifestFile);
writetable(mechanicalInputDefinition, ...
    cfg.phase12A.mechanicalInputDefinitionFile);
writetable(registrationGateSummary, ...
    cfg.phase12A.registrationGateSummaryFile);
writetable(handoffStatus, cfg.phase12A.handoffStatusFile);
writetable(sourceProvenance, cfg.phase12A.sourceProvenanceFile);

try
    h = v800.plot_phase12A_raman_registration_feasibility(cfg, ...
        ramanRegistrationLedger, coordinateTransformManifest, ...
        mechanicalInputDefinition, registrationGateSummary);
catch ME
    warning('v8:phase12APlotFailed', ...
        'Phase 12A Raman registration feasibility plot failed: %s', ...
        ME.message);
    h = [];
end

out = struct();
out.config = cfg;
out.inputs = inputs;
out.ramanRegistrationLedger = ramanRegistrationLedger;
out.coordinateTransformManifest = coordinateTransformManifest;
out.mechanicalInputDefinition = mechanicalInputDefinition;
out.registrationGateSummary = registrationGateSummary;
out.handoffStatus = handoffStatus;
out.sourceProvenance = sourceProvenance;
out.figure = h;
out.paths = struct();
out.paths.ramanRegistrationLedger = ...
    cfg.phase12A.ramanRegistrationLedgerFile;
out.paths.coordinateTransformManifest = ...
    cfg.phase12A.coordinateTransformManifestFile;
out.paths.mechanicalInputDefinition = ...
    cfg.phase12A.mechanicalInputDefinitionFile;
out.paths.registrationGateSummary = ...
    cfg.phase12A.registrationGateSummaryFile;
out.paths.handoffStatus = cfg.phase12A.handoffStatusFile;
out.paths.sourceProvenance = cfg.phase12A.sourceProvenanceFile;
out.paths.figurePng = [cfg.phase12A.figureBaseFile '.png'];
out.paths.figurePdf = [cfg.phase12A.figureBaseFile '.pdf'];
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
    "phase12A_raman_registration_feasibility"
    sourceStatus.commit_sha
    sourceStatus.tree_sha
    string(sourceStatus.tracked_clean)
    string(sourceStatus.untracked_clean)
    string(sourceStatus.tracked_clean && sourceStatus.untracked_clean)
    "registration_feasibility_no_transport_relabeling"
    "Commit Phase 12A source first; rerun from clean source; commit generated artifacts separately."
    ];
note = [
    "Phase 12A Raman registration feasibility and mechanical-input definition."
    "Git commit captured before this runner writes outputs."
    "Git tree object captured before this runner writes outputs."
    "Tracked-source cleanliness before output generation."
    "Untracked-source/artifact cleanliness before output generation."
    "True only when the checkout is clean before this run writes outputs."
    "No transport retuning, no v8 status changes, no quantitative Raman coupling."
    "Phase 12A artifacts are downstream of frozen Phase 11 architecture."
    ];
provenance = table(item, value, note);
end

function inputs = load_phase12A_inputs(cfg)
inputs = struct();
inputs.phase11Handoff = read_optional_table(cfg.phase11.handoffStatusFile);
inputs.phase11DeviceManifest = read_optional_table( ...
    cfg.phase11.deviceObservableManifestFile);
inputs.phase11Registration = read_optional_table( ...
    cfg.phase11.registrationAvailabilityFile);
inputs.phase11RamanSchema = read_optional_table(cfg.phase11.ramanDataSchemaFile);
inputs.phase7Prior = read_optional_table(cfg.phase7.priorEvidenceManifestFile);
inputs.phase9RamanDisposition = read_optional_table( ...
    cfg.phase9.ramanRegistrationDiagnosticFile);
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

function ledger = build_raman_registration_ledger(cfg, inputs)
devices = raman_hint_devices(cfg, inputs);
rows = repmat(empty_registration_ledger_row(), numel(devices), 1);
for k = 1:numel(devices)
    device = string(devices(k));
    phase7Row = row_for_device(inputs.phase7Prior, device);
    availability = row_for_device(inputs.phase11Registration, device);

    rows(k).device = device;
    rows(k).mode = "mode_set_not_archived";
    rows(k).scan_id = "phase11_raman_hint";
    rows(k).device_coordinate_available = false;
    rows(k).scan_origin_known = false;
    rows(k).scan_endpoint_known = false;
    rows(k).scan_direction_known = false;
    rows(k).device_orientation_known = false;
    rows(k).rotation_known = false;
    rows(k).boundary_location_known = boundary_location_known(device);
    rows(k).spatial_scale_known = false;
    rows(k).mode_identity_status = "not_archived_in_phase11";
    rows(k).reference_peak_status = "not_archived";
    rows(k).reflection_ambiguity = "unresolved";
    rows(k).rotation_ambiguity = "unresolved";
    rows(k).registration_uncertainty_um = NaN;
    rows(k).registration_status = phase12_registration_status(availability);
    rows(k).allowed_model_use = allowed_model_use(rows(k).registration_status);
    rows(k).stressor_boundary_position_status = ...
        stressor_boundary_status(device);
    rows(k).crack_position_status = crack_position_status(device);
    rows(k).mechanical_prior_role = lookup_struct_value(phase7Row, ...
        "mechanical_prior_role", mechanical_prior_role(device));
    rows(k).quantitative_transport_coupling_allowed = ismember( ...
        rows(k).registration_status, ...
        cfg.phase12A.quantitativeRegistrationStatuses);
    rows(k).note = "Raman remains qualitative until scan/device transform metadata and residuals are archived.";
end
ledger = struct2table(rows);
end

function devices = raman_hint_devices(cfg, inputs)
devices = strings(0, 1);
T = inputs.phase11Registration;
if ~isempty(T)
    dev = table_column(T, "device");
    hints = table_column(T, "raman_hint_available");
    for k = 1:numel(dev)
        if any(lower(hints(k)) == ["true", "1", "yes"])
            devices(end+1, 1) = dev(k);
        end
    end
end
if isempty(devices)
    for k = 1:numel(cfg.devices)
        device = string(cfg.devices(k));
        if lookup_logical(inputs.phase7Prior, device, ...
                "has_raman_hint", false)
            devices(end+1, 1) = device;
        end
    end
end
devices = unique(devices, 'stable');
end

function manifest = build_coordinate_transform_manifest(cfg, ledger)
rows = repmat(empty_transform_row(), max(height(ledger), 1), 1);
if isempty(ledger)
    rows(1).device = "none";
    rows(1).transform_id = "no_raman_hint_devices";
    rows(1).registration_status = "unregistered";
    rows(1).transform_type = "not_available";
    rows(1).allowed_model_use = "none";
    rows(1).note = "No Raman hint devices were present in Phase 11 inputs.";
else
    for k = 1:height(ledger)
        rows(k).device = string(ledger.device(k));
        rows(k).transform_id = "not_available";
        rows(k).registration_status = string(ledger.registration_status(k));
        rows(k).transform_type = "not_available";
        rows(k).scan_coordinate_system = "unknown_scan_frame";
        rows(k).device_coordinate_system = "device_frame_from_phase11";
        rows(k).origin_policy = "not_declared";
        rows(k).rotation_policy = "not_declared";
        rows(k).scale_policy = "not_declared";
        rows(k).reflection_policy = "not_declared";
        rows(k).residual_error_um = NaN;
        rows(k).allowed_model_use = string(ledger.allowed_model_use(k));
        rows(k).two_dimensional_field_allowed = false;
        rows(k).transport_coupling_allowed = false;
        rows(k).note = "No affine or nonlinear Raman-to-device transform is frozen in Phase 12A.";
    end
end
manifest = struct2table(rows);
end

function definition = build_mechanical_input_definition(cfg, inputs, ledger)
devices = string(cfg.devices(:));
rows = repmat(empty_mechanical_input_row(), numel(devices), 1);
for k = 1:numel(devices)
    device = devices(k);
    deviceRow = row_for_device(inputs.phase11DeviceManifest, device);
    ramanRow = row_for_device(ledger, device);
    rows(k).device = device;
    rows(k).frozen_v8_conclusion = lookup_struct_value(deviceRow, ...
        "frozen_v8_conclusion", "");
    rows(k).geometry_context_status = lookup_struct_value(deviceRow, ...
        "geometry_context_status", geometry_context_status(device));
    rows(k).reduced_mechanical_proxy_class = mechanical_proxy_class(device);
    rows(k).stressor_geometry_input = stressor_geometry_input(device);
    rows(k).boundary_relaxation_input = boundary_relaxation_input(device);
    rows(k).crack_relaxation_input = crack_relaxation_input(device);
    rows(k).through_thickness_input = "deferred_proxy_parameter";
    rows(k).substrate_clamping_input = "deferred_proxy_parameter";
    rows(k).raman_registration_status = lookup_struct_value(ramanRow, ...
        "registration_status", "not_applicable_no_raman_hint");
    rows(k).allowed_phase12B_use = phase12B_use(rows(k).raman_registration_status);
    rows(k).blocked_phase12_use = ...
        "no quantitative strain assignment from unregistered Raman";
    rows(k).transport_status_change_allowed = false;
    rows(k).note = "Mechanical proxy input only; transport labels remain frozen.";
end
definition = struct2table(rows);
end

function gates = build_registration_gate_summary(cfg, inputs, ledger, ...
    transforms, mechanicalInputs, sourceProvenance)
phase11Closed = lookup_status(inputs.phase11Handoff, "phase11_closure", ...
    "missing") == "pass_data_architecture";
registrationRowsComplete = height(ledger) == ...
    count_raman_hint_rows(inputs.phase11Registration);
if isempty(inputs.phase11Registration)
    registrationRowsComplete = height(ledger) > 0;
end
vocab = string(cfg.phase12A.registrationStatusVocabulary);
statusesInVocab = all(ismember(string(ledger.registration_status), vocab));
quantStatuses = string(cfg.phase12A.quantitativeRegistrationStatuses);
quantRows = ismember(string(ledger.registration_status), quantStatuses);
noInventedTransforms = ~cfg.phase12A.allowInventedTransforms && ...
    all(string(transforms.transform_type) == "not_available");
quantBlocked = all(~ledger.quantitative_transport_coupling_allowed) && ...
    all(~transforms.transport_coupling_allowed);
lineNotExpanded = ~cfg.phase12A.allow2DFieldFromLineScan && ...
    all(~transforms.two_dimensional_field_allowed);
mechanicalDefined = height(mechanicalInputs) == numel(cfg.devices) && ...
    all(strlength(mechanicalInputs.reduced_mechanical_proxy_class) > 0);
labelsProtected = ~cfg.phase12A.allowTransportRelabeling && ...
    ~cfg.phase12A.allowTransportRetuning && ...
    all(~mechanicalInputs.transport_status_change_allowed);
trackedClean = lookup_value(sourceProvenance, ...
    "source_pre_run_tracked_clean", "false") == "true";
rows = [
    gate_row("Phase 11 architecture consumed", ...
    logical_status(phase11Closed), ...
    "Phase 12A starts from frozen Phase 11 schemas and manifests.")
    gate_row("Registration status explicit for Raman hint devices", ...
    logical_status(registrationRowsComplete), ...
    "Every Raman-hint device receives a Phase 12A registration row.")
    gate_row("Registration vocabulary restricted", ...
    logical_status(statusesInVocab), ...
    "Statuses use the predeclared Phase 12A vocabulary.")
    gate_row("No invented coordinate transforms", ...
    logical_status(noInventedTransforms), ...
    "No affine/nonlinear scan-to-device transform is fabricated.")
    gate_row("Quantitative Raman transport coupling blocked", ...
    logical_status(quantBlocked && ~any(quantRows)), ...
    "Unregistered Raman remains qualitative independent context.")
    gate_row("No 2D field expanded from line scan", ...
    logical_status(lineNotExpanded), ...
    "A line or device-level association is not promoted to a 2D field.")
    gate_row("Mechanical input roles defined", ...
    logical_status(mechanicalDefined), ...
    "Reduced geometry/mechanical proxy roles are declared per device.")
    gate_row("Frozen transport conclusions protected", ...
    logical_status(labelsProtected), ...
    "Phase 12A does not alter v8/Phase 11 transport conclusions.")
    gate_row("Tracked source provenance clean", ...
    logical_status(trackedClean), ...
    "Tracked source files were clean before Phase 12A wrote outputs.")
    ];
gates = struct2table(rows);
end

function handoff = build_handoff_status(cfg, gates, provenance)
coreReady = all(gates.outcome == "pass");
rows = [
    status_row("phase12A_raman_registration_feasibility", ...
    logical_status(coreReady), ...
    "Raman registration feasibility and mechanical-input definition generated.")
    status_row("phase12A_closure", ...
    ternary(coreReady, "pass_registration_feasibility", ...
    "fail_registration_feasibility"), ...
    "Phase 12A closes as registration feasibility, not a transport-coupled model.")
    status_row("quantitative_raman_transport_coupling", "blocked", ...
    "No registered quantitative Raman transform is frozen.")
    status_row("mechanical_proxy_ready_for_12B", ...
    logical_status(coreReady), ...
    "Phase 12B may build reduced geometry fields without using Raman as a 2D constraint.")
    status_row("transport_status_changes", "false", ...
    "Frozen v8/Phase 11 device conclusions are unchanged.")
    status_row("source_commit_sha", lookup_value(provenance, ...
    "source_commit_sha", "unknown"), ...
    "Source commit used to generate Phase 12A artifacts.")
    status_row("next_phase", "phase12B_reduced_mechanical_forward_model", ...
    "Build reduced mechanical proxy equations before comparing Raman observables.")
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

function tf = lookup_logical(T, device, columnName, defaultValue)
tf = logical(defaultValue);
row = row_for_device(T, device);
if isempty(fieldnames(row))
    return;
end
value = lower(lookup_struct_value(row, columnName, string(defaultValue)));
tf = any(value == ["true", "1", "yes"]);
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

function n = count_raman_hint_rows(T)
values = lower(table_column(T, "raman_hint_available"));
n = sum(ismember(values, ["true"; "1"; "yes"]));
end

function status = phase12_registration_status(availabilityRow)
available = lookup_struct_value(availabilityRow, ...
    "registered_raman_available", "false");
if any(lower(available) == ["true", "1", "yes"])
    status = "registered_with_uncertainty";
else
    hint = lookup_struct_value(availabilityRow, ...
        "raman_hint_available", "false");
    if any(lower(hint) == ["true", "1", "yes"])
        status = "device_association_only";
    else
        status = "unregistered";
    end
end
end

function use = allowed_model_use(registrationStatus)
switch string(registrationStatus)
    case {"registered_quantitative", "registered_with_uncertainty"}
        use = "quantitative_raman_forward_comparison_allowed";
    case "relative_line_coordinate_only"
        use = "one_dimensional_gradient_check_only";
    case "device_association_only"
        use = "qualitative_independent_mechanical_context_only";
    otherwise
        use = "not_used_for_model_constraint";
end
end

function status = phase12B_use(registrationStatus)
switch string(registrationStatus)
    case {"registered_quantitative", "registered_with_uncertainty"}
        status = "registered_raman_can_be_compared_after_mechanical_equations_freeze";
    case "relative_line_coordinate_only"
        status = "line_coordinate_context_only_no_2D_field";
    case "device_association_only"
        status = "geometry_proxy_only_raman_qualitative_context";
    otherwise
        status = "geometry_proxy_only_no_raman_constraint";
end
end

function tf = boundary_location_known(device)
tf = any(upper(string(device)) == ["AS002", "AS005", "AS006"]);
end

function status = stressor_boundary_status(device)
device = upper(string(device));
if device == "AS002"
    status = "half_encapsulation_boundary_context_available";
elseif device == "AS005"
    status = "boundary_context_available_with_crack";
elseif device == "AS006"
    status = "strong_boundary_context_available";
else
    status = "not_applicable_or_control_context";
end
end

function status = crack_position_status(device)
if upper(string(device)) == "AS005"
    status = "crack_context_available_registration_unverified";
else
    status = "not_applicable";
end
end

function role = mechanical_prior_role(device)
device = upper(string(device));
switch device
    case "AS002"
        role = "threshold_half_encapsulated";
    case "AS005"
        role = "crack_geometry_auxiliary";
    case "AS006"
        role = "strong_boundary_connectivity";
    otherwise
        role = "geometry_context";
end
end

function status = geometry_context_status(device)
if any(upper(string(device)) == ["AS004", "AS005", "AS006"])
    status = "geometry_mechanical_context_required";
else
    status = "geometry_control_context";
end
end

function cls = mechanical_proxy_class(device)
device = upper(string(device));
switch device
    case "AS002"
        cls = "half_encapsulation_boundary_proxy";
    case "AS005"
        cls = "crack_boundary_relaxation_proxy";
    case "AS006"
        cls = "strong_boundary_transfer_proxy";
    case "AS004"
        cls = "intermediate_boundary_context_proxy";
    otherwise
        cls = "control_geometry_proxy";
end
end

function input = stressor_geometry_input(device)
device = upper(string(device));
if any(device == ["AS002", "AS004", "AS005", "AS006"])
    input = "covered_region_and_boundary_geometry_required";
else
    input = "control_geometry_context";
end
end

function input = boundary_relaxation_input(device)
device = upper(string(device));
if any(device == ["AS002", "AS004", "AS005", "AS006"])
    input = "boundary_normal_relaxation_length_prior";
else
    input = "not_primary";
end
end

function input = crack_relaxation_input(device)
if upper(string(device)) == "AS005"
    input = "crack_relaxation_length_prior_required";
else
    input = "not_applicable";
end
end

function row = empty_registration_ledger_row()
row = struct();
row.device = "";
row.mode = "";
row.scan_id = "";
row.device_coordinate_available = false;
row.scan_origin_known = false;
row.scan_endpoint_known = false;
row.scan_direction_known = false;
row.device_orientation_known = false;
row.rotation_known = false;
row.boundary_location_known = false;
row.spatial_scale_known = false;
row.mode_identity_status = "";
row.reference_peak_status = "";
row.reflection_ambiguity = "";
row.rotation_ambiguity = "";
row.registration_uncertainty_um = NaN;
row.registration_status = "";
row.allowed_model_use = "";
row.stressor_boundary_position_status = "";
row.crack_position_status = "";
row.mechanical_prior_role = "";
row.quantitative_transport_coupling_allowed = false;
row.note = "";
end

function row = empty_transform_row()
row = struct();
row.device = "";
row.transform_id = "";
row.registration_status = "";
row.transform_type = "";
row.scan_coordinate_system = "";
row.device_coordinate_system = "";
row.origin_policy = "";
row.rotation_policy = "";
row.scale_policy = "";
row.reflection_policy = "";
row.residual_error_um = NaN;
row.allowed_model_use = "";
row.two_dimensional_field_allowed = false;
row.transport_coupling_allowed = false;
row.note = "";
end

function row = empty_mechanical_input_row()
row = struct();
row.device = "";
row.frozen_v8_conclusion = "";
row.geometry_context_status = "";
row.reduced_mechanical_proxy_class = "";
row.stressor_geometry_input = "";
row.boundary_relaxation_input = "";
row.crack_relaxation_input = "";
row.through_thickness_input = "";
row.substrate_clamping_input = "";
row.raman_registration_status = "";
row.allowed_phase12B_use = "";
row.blocked_phase12_use = "";
row.transport_status_change_allowed = false;
row.note = "";
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
