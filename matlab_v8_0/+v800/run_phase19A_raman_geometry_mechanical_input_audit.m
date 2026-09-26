function out = run_phase19A_raman_geometry_mechanical_input_audit(cfg)
%RUN_PHASE19A_RAMAN_GEOMETRY_MECHANICAL_INPUT_AUDIT
% Read-only readiness gate for quantitative mechanics and strain inference.
%
% Phase 19A deliberately does not build an FEM, infer a strain tensor, or
% couple Raman to transport. It audits whether the archived spatial,
% registration, and materials inputs are sufficient to justify Phase 19B.

if ~exist(cfg.outputDir, 'dir')
    mkdir(cfg.outputDir);
end

paths = phase19A_paths(cfg);
sourceProvenance = build_source_provenance(cfg);
inputs = load_inputs(paths);

spatialInputInventory = build_spatial_input_inventory(inputs);
registrationReadiness = build_registration_readiness( ...
    spatialInputInventory);
materialsInventory = build_materials_inventory(spatialInputInventory);
mechanicalReadinessDecision = build_mechanical_readiness_decision( ...
    registrationReadiness, materialsInventory, inputs);
gateSummary = build_gate_summary(registrationReadiness, ...
    materialsInventory, mechanicalReadinessDecision, sourceProvenance);
handoffStatus = build_handoff_status(mechanicalReadinessDecision, ...
    gateSummary);

writetable(spatialInputInventory, paths.spatialInputInventory);
writetable(registrationReadiness, paths.registrationReadiness);
writetable(materialsInventory, paths.materialsInventory);
writetable(mechanicalReadinessDecision, ...
    paths.mechanicalReadinessDecision);
writetable(gateSummary, paths.gateSummary);
writetable(handoffStatus, paths.handoffStatus);
writetable(sourceProvenance, paths.sourceProvenance);

try
    h = plot_summary(paths, registrationReadiness, materialsInventory, ...
        mechanicalReadinessDecision, gateSummary);
catch ME
    warning('v8:phase19APlotFailed', ...
        'Phase 19A readiness summary plot failed: %s', ME.message);
    h = [];
end

out = struct();
out.config = cfg;
out.inputs = inputs;
out.spatialInputInventory = spatialInputInventory;
out.registrationReadiness = registrationReadiness;
out.materialsInventory = materialsInventory;
out.mechanicalReadinessDecision = mechanicalReadinessDecision;
out.gateSummary = gateSummary;
out.handoffStatus = handoffStatus;
out.sourceProvenance = sourceProvenance;
out.figure = h;
out.paths = paths;
end

function paths = phase19A_paths(cfg)
outputDir = cfg.outputDir;
paths = struct();
paths.outputDir = outputDir;
paths.phase18DLHandoff = fullfile(outputDir, ...
    'phase18DL_handoff_status.csv');
paths.phase18DLDevelopmentDecision = fullfile(outputDir, ...
    'phase18DL_development_decision.csv');
paths.phase9RamanRegistrationDisposition = fullfile(outputDir, ...
    'phase9_raman_registration_disposition.csv');
paths.phase9ModelLimitations = fullfile(outputDir, ...
    'phase9_model_limitations.csv');
paths.phase9DeferredWork = fullfile(outputDir, ...
    'phase9_deferred_work.csv');
paths.phase12ARamanRegistrationLedger = fullfile(outputDir, ...
    'phase12A_raman_registration_ledger.csv');
paths.phase12ACoordinateTransformManifest = fullfile(outputDir, ...
    'phase12A_coordinate_transform_manifest.csv');
paths.phase12AMechanicalInputDefinition = fullfile(outputDir, ...
    'phase12A_mechanical_input_definition.csv');
paths.phase12ARegistrationGateSummary = fullfile(outputDir, ...
    'phase12A_registration_gate_summary.csv');
paths.phase12BDeviceGeometryInputs = fullfile(outputDir, ...
    'phase12B_device_geometry_inputs.csv');
paths.phase12BMechanicalModelSpecification = fullfile(outputDir, ...
    'phase12B_mechanical_model_specification.csv');
paths.phase12BMechanicalFieldManifest = fullfile(outputDir, ...
    'phase12B_mechanical_field_manifest.csv');
paths.spatialInputInventory = fullfile(outputDir, ...
    'phase19A_spatial_input_inventory.csv');
paths.registrationReadiness = fullfile(outputDir, ...
    'phase19A_registration_readiness.csv');
paths.materialsInventory = fullfile(outputDir, ...
    'phase19A_materials_parameter_inventory.csv');
paths.mechanicalReadinessDecision = fullfile(outputDir, ...
    'phase19A_mechanical_readiness_decision.csv');
paths.gateSummary = fullfile(outputDir, ...
    'phase19A_gate_summary.csv');
paths.handoffStatus = fullfile(outputDir, ...
    'phase19A_handoff_status.csv');
paths.sourceProvenance = fullfile(outputDir, ...
    'phase19A_source_provenance.csv');
paths.figureBase = fullfile(outputDir, ...
    'phase19A_raman_geometry_mechanical_readiness_summary');
paths.figurePng = [paths.figureBase '.png'];
paths.figurePdf = [paths.figureBase '.pdf'];
end

function inputs = load_inputs(paths)
inputs = struct();
inputs.phase18DLHandoff = read_optional_table(paths.phase18DLHandoff);
inputs.phase18DLDevelopmentDecision = read_optional_table( ...
    paths.phase18DLDevelopmentDecision);
inputs.phase9RamanRegistrationDisposition = read_optional_table( ...
    paths.phase9RamanRegistrationDisposition);
inputs.phase9ModelLimitations = read_optional_table( ...
    paths.phase9ModelLimitations);
inputs.phase9DeferredWork = read_optional_table(paths.phase9DeferredWork);
inputs.phase12ARamanRegistrationLedger = read_optional_table( ...
    paths.phase12ARamanRegistrationLedger);
inputs.phase12ACoordinateTransformManifest = read_optional_table( ...
    paths.phase12ACoordinateTransformManifest);
inputs.phase12AMechanicalInputDefinition = read_optional_table( ...
    paths.phase12AMechanicalInputDefinition);
inputs.phase12ARegistrationGateSummary = read_optional_table( ...
    paths.phase12ARegistrationGateSummary);
inputs.phase12BDeviceGeometryInputs = read_optional_table( ...
    paths.phase12BDeviceGeometryInputs);
inputs.phase12BMechanicalModelSpecification = read_optional_table( ...
    paths.phase12BMechanicalModelSpecification);
inputs.phase12BMechanicalFieldManifest = read_optional_table( ...
    paths.phase12BMechanicalFieldManifest);
end

function T = read_optional_table(pathValue)
if exist(pathValue, 'file')
    T = readtable(pathValue, 'FileType', 'text', 'Delimiter', ',', ...
        'ReadVariableNames', true, 'TextType', 'string', ...
        'VariableNamingRule', 'preserve');
else
    T = table();
end
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
    "phase19A_raman_geometry_mechanical_input_audit"
    sourceStatus.commit_sha
    sourceStatus.tree_sha
    string(sourceStatus.tracked_clean)
    string(sourceStatus.untracked_clean)
    string(sourceStatus.tracked_clean && sourceStatus.untracked_clean)
    "readiness_gate_no_FEM_no_strain_tensor_no_transport_coupling"
    "Commit Phase 19A source first; rerun from clean source; commit readiness artifacts separately."
    ];
note = [
    "Phase 19A audits whether quantitative mechanics inputs exist."
    "Git commit captured before this runner writes outputs."
    "Git tree captured before this runner writes outputs."
    "Tracked-source cleanliness before output generation."
    "Untracked-source/artifact cleanliness before output generation."
    "True only when tracked and untracked source state are clean before output generation."
    "No FEM, no tensor inversion, no Raman-to-transport fitting, no model update."
    "Artifacts may dirty the checkout after pre-run provenance is captured."
    ];
provenance = table(item, value, note);
end

function inventory = build_spatial_input_inventory(inputs)
devices = ["AS002"; "AS005"; "AS006"];
rows = repmat(empty_spatial_row(), numel(devices), 1);
for k = 1:numel(devices)
    device = devices(k);
    phase12Row = row_for_device(inputs.phase12ARamanRegistrationLedger, ...
        device);
    geometryRow = row_for_device(inputs.phase12BDeviceGeometryInputs, ...
        device);

    rows(k).device = device;
    rows(k).raw_raman_coordinates = availability_from_phase12( ...
        phase12Row, "device_coordinate_available", "missing");
    rows(k).raman_scan_direction = availability_from_phase12( ...
        phase12Row, "scan_direction_known", "missing");
    rows(k).device_optical_or_sem_image = availability_from_geometry( ...
        geometryRow, "device_image_status", "not_archived");
    rows(k).hall_bar_coordinates = availability_from_geometry( ...
        geometryRow, "hall_bar_coordinate_status", ...
        ternary(device == "AS006", "geometry_proxy_only", ...
        "not_archived"));
    rows(k).stressor_boundary_coordinates = availability_from_phase12( ...
        phase12Row, "stressor_boundary_position_status", ...
        boundary_status(device));
    rows(k).crack_coordinates = availability_from_phase12( ...
        phase12Row, "crack_position_status", crack_status(device));
    rows(k).stage_coordinate_metadata = availability_from_phase12( ...
        phase12Row, "scan_origin_known", "missing");
    rows(k).mote2_thickness = availability_from_geometry( ...
        geometryRow, "mote2_thickness_status", "not_archived");
    rows(k).crystal_axis_orientation = availability_from_geometry( ...
        geometryRow, "crystal_axis_orientation_status", "unknown");
    rows(k).stressor_thickness = availability_from_geometry( ...
        geometryRow, "stressor_thickness_status", "not_archived");
    rows(k).film_force_or_residual_stress = availability_from_geometry( ...
        geometryRow, "film_force_status", "not_archived");
    rows(k).substrate_oxide_stack = availability_from_geometry( ...
        geometryRow, "substrate_stack_status", "not_archived");
    rows(k).elastic_constants = availability_from_geometry( ...
        geometryRow, "elastic_constants_status", "literature_not_bound_to_device");
    rows(k).raman_mode_assignment = availability_from_phase12( ...
        phase12Row, "mode_identity_status", "not_archived");
    rows(k).polarization_information = availability_from_geometry( ...
        geometryRow, "polarization_status", "not_archived");
    rows(k).source_basis = source_basis(phase12Row, geometryRow);
end
inventory = struct2table(rows);
end

function readiness = build_registration_readiness(inventory)
rows = repmat(empty_readiness_row(), height(inventory), 1);
for k = 1:height(inventory)
    row = inventory(k, :);
    hasRamanCoords = is_positive(row.raw_raman_coordinates);
    hasScanDirection = is_positive(row.raman_scan_direction);
    hasHallBar = is_positive(row.hall_bar_coordinates);
    hasBoundary = is_positive(row.stressor_boundary_coordinates);
    hasStage = is_positive(row.stage_coordinate_metadata);
    hasMode = is_positive(row.raman_mode_assignment);
    hasThickness = is_positive(row.mote2_thickness);
    hasStress = is_positive(row.film_force_or_residual_stress);
    hasElastic = is_positive(row.elastic_constants);

    quantitative2D = hasRamanCoords && hasScanDirection && hasHallBar && ...
        hasBoundary && hasStage && hasMode && hasThickness && ...
        hasStress && hasElastic;
    quantitative1D = hasRamanCoords && hasScanDirection && hasBoundary && ...
        hasMode;
    geometryOnly = hasHallBar || hasBoundary || ...
        contains(lower(string(row.crack_coordinates)), "known");

    rows(k).device = string(row.device);
    rows(k).registration_class = classify_registration(quantitative2D, ...
        quantitative1D, geometryOnly);
    rows(k).quantitative_2D_mechanics_allowed = quantitative2D;
    rows(k).quantitative_1D_mechanics_allowed = quantitative1D && ...
        ~quantitative2D;
    rows(k).geometry_proxy_allowed = geometryOnly;
    rows(k).strain_tensor_recovery_allowed = quantitative2D;
    rows(k).reason = readiness_reason(rows(k).registration_class);
end
readiness = struct2table(rows);
end

function materials = build_materials_inventory(inventory)
rows = repmat(empty_material_row(), height(inventory), 1);
for k = 1:height(inventory)
    row = inventory(k, :);
    hasThickness = is_positive(row.mote2_thickness);
    hasAxis = is_positive(row.crystal_axis_orientation);
    hasStressorThickness = is_positive(row.stressor_thickness);
    hasStress = is_positive(row.film_force_or_residual_stress);
    hasStack = is_positive(row.substrate_oxide_stack);
    hasElastic = is_positive(row.elastic_constants);
    hasMode = is_positive(row.raman_mode_assignment);
    hasPolarization = is_positive(row.polarization_information);

    rows(k).device = string(row.device);
    rows(k).mote2_thickness_available = hasThickness;
    rows(k).crystal_axis_available = hasAxis;
    rows(k).stressor_thickness_available = hasStressorThickness;
    rows(k).film_force_or_residual_stress_available = hasStress;
    rows(k).substrate_stack_available = hasStack;
    rows(k).elastic_constants_available = hasElastic;
    rows(k).raman_mode_assignment_available = hasMode;
    rows(k).polarization_available = hasPolarization;
    rows(k).quantitative_mechanics_materials_complete = hasThickness && ...
        hasAxis && hasStressorThickness && hasStress && hasStack && ...
        hasElastic && hasMode;
    rows(k).tensor_component_scope = tensor_scope(rows(k));
end
materials = struct2table(rows);
end

function decision = build_mechanical_readiness_decision(readiness, ...
    materials, inputs)
anyQuant2D = any(readiness.quantitative_2D_mechanics_allowed);
anyQuant1D = any(readiness.quantitative_1D_mechanics_allowed);
materialsComplete = any(materials.quantitative_mechanics_materials_complete);
phase18Closed = lookup_item(inputs.phase18DLHandoff, ...
    "phase18DL_closure") == ...
    "pass_no_dynamic_model_development_from_legacy_context";
phase9RamanQualitative = phase9_raman_remains_qualitative(inputs);

phase19BAllowed = anyQuant2D && materialsComplete;
phase19BSpecOnly = ~phase19BAllowed && (anyQuant1D || ...
    any(readiness.geometry_proxy_allowed));

item = [
    "phase18_dynamic_branch_endpoint_consumed"
    "phase9_raman_disposition_consumed"
    "quantitative_2D_registered_device_available"
    "quantitative_1D_registered_device_available"
    "complete_materials_parameter_set_available"
    "strain_tensor_recovery_allowed"
    "phase19B_mechanical_forward_model_allowed"
    "recommended_next_scope"
    ];
value = [
    string(phase18Closed)
    ternary(phase9RamanQualitative, ...
        "raman_qualitative_or_registration_unavailable", "unknown")
    string(anyQuant2D)
    string(anyQuant1D)
    string(materialsComplete)
    string(anyQuant2D && materialsComplete)
    ternary(phase19BAllowed, "allowed", ...
        ternary(phase19BSpecOnly, "specification_only_no_FEM_execution", ...
        "blocked_pending_registration_and_materials_inputs"))
    ternary(phase19BAllowed, ...
        "phase19B_bounded_mechanical_forward_model", ...
        "freeze_readiness_gap_and_archive_required_input_list")
    ];
note = [
    "Phase 18D-L closes the legacy dynamics branch before mechanics work begins."
    "Phase 9 already held Raman as qualitative unless registration is available."
    "Requires Raman coordinates, transform metadata, Hall-bar frame, boundary frame, and mode identity."
    "Requires at least a defensible registered line/axis relation."
    "Requires thickness, crystal axes, stressor stack, residual stress, substrate stack, elastic constants, and Raman modes."
    "No strain tensor is recoverable without quantitative registration and materials closure."
    "Phase 19B should not run FEM from incomplete metadata."
    "Next scope preserves the readiness gate rather than pretending a tensor is recoverable."
    ];
decision = table(item, value, note);
end

function gates = build_gate_summary(readiness, materials, decision, ...
    sourceProvenance)
sourceClean = lookup_item(sourceProvenance, "source_pre_run_clean") == "true";
dynamicClosed = lookup_item(decision, ...
    "phase18_dynamic_branch_endpoint_consumed") == "true";
noTensorClaim = lookup_item(decision, ...
    "strain_tensor_recovery_allowed") == "false";
phase19BPolicy = lookup_item(decision, ...
    "phase19B_mechanical_forward_model_allowed");
materialsHonest = ~any(materials.quantitative_mechanics_materials_complete);
registrationHonest = ~any(readiness.quantitative_2D_mechanics_allowed);

component = [
    "Clean provenance"
    "Dynamic branch endpoint consumed"
    "Registration readiness audited"
    "Materials readiness audited"
    "No premature strain tensor claim"
    "Phase 19B blocked or limited when inputs incomplete"
    ];
pass = [
    sourceClean
    dynamicClosed
    registrationHonest || any(readiness.quantitative_2D_mechanics_allowed)
    materialsHonest || any(materials.quantitative_mechanics_materials_complete)
    noTensorClaim
    phase19BPolicy ~= "allowed"
    ];
status = pass_fail(pass);
note = [
    "Canonical artifact freeze requires clean pre-run source state."
    "Phase 19 starts after Phase 18D-L closes legacy dynamics."
    "Per-device registration classes are written without fabricating transforms."
    "Per-device material and Raman-physics inputs are written without fabricating constants."
    "Tensor recovery remains blocked unless registration and materials both close."
    "Incomplete inputs route to a gap archive/specification, not FEM execution."
    ];
gates = table(component, status, pass, note);
end

function handoff = build_handoff_status(decision, gateSummary)
allPass = all(gateSummary.pass);
phase19BPolicy = lookup_item(decision, ...
    "phase19B_mechanical_forward_model_allowed");
item = [
    "phase19A_closure"
    "phase19B_forward_model_status"
    "strain_tensor_recovery_allowed"
    "raman_transport_coupling_allowed"
    "FEM_execution_allowed"
    "legacy_dynamic_model_reopened"
    "next_phase"
    ];
value = [
    ternary(allPass, ...
        "pass_readiness_gap_freeze_no_quantitative_strain_tensor", ...
        "fail_mechanical_readiness_audit")
    phase19BPolicy
    lookup_item(decision, "strain_tensor_recovery_allowed")
    "false"
    ternary(phase19BPolicy == "allowed", "true", "false")
    "false"
    ternary(phase19BPolicy == "allowed", ...
        "phase19B_mechanical_forward_model_specification", ...
        "phase19A_required_input_recovery_or_metadata_archive")
    ];
note = [
    "Closure records the readiness state before any FEM or strain inference."
    "Phase 19B is allowed only if quantitative registration and materials closure exist."
    "No tensor recovery is claimed from the current canonical artifact set."
    "Raman is not coupled to transport in Phase 19A."
    "FEM execution is blocked unless readiness gates support it."
    "Phase 18D-L remains closed; dynamic physics is not reopened."
    "Next work is input recovery unless the readiness gate passes."
    ];
handoff = table(item, value, note);
end

function h = plot_summary(paths, readiness, materials, decision, gateSummary)
h = figure('Name', 'v8 Phase 19A mechanical readiness audit', ...
    'Color', 'w', 'Position', [100 100 1400 820]);
tiledlayout(2, 3, 'Padding', 'compact', 'TileSpacing', 'compact');

nexttile;
bar(categorical(readiness.device), ...
    double(readiness.quantitative_2D_mechanics_allowed));
title('quantitative 2D registration');
ylim([0 1.2]);
grid on;

nexttile;
bar(categorical(readiness.device), double(readiness.geometry_proxy_allowed));
title('geometry proxy availability');
ylim([0 1.2]);
grid on;

nexttile;
bar(categorical(materials.device), ...
    double(materials.quantitative_mechanics_materials_complete));
title('materials closure');
ylim([0 1.2]);
grid on;

nexttile;
bar(categorical(gateSummary.component), double(gateSummary.pass));
title('phase gates');
ylim([0 1.2]);
xtickangle(35);
grid on;

nexttile;
classes = categorical(readiness.registration_class);
bar(categorical(categories(classes)), countcats(classes));
title('registration classes');
xtickangle(35);
grid on;

nexttile;
axis off;
text(0, 0.86, 'Phase 19A decision', 'FontWeight', 'bold', ...
    'FontSize', 14);
text(0, 0.66, strrep(lookup_item(decision, ...
    "phase19B_mechanical_forward_model_allowed"), '_', '\_'), ...
    'FontSize', 11);
text(0, 0.46, 'No FEM or strain tensor until inputs close', ...
    'FontSize', 11);
text(0, 0.30, 'Legacy dynamics remain closed', 'FontSize', 11);

exportgraphics(h, paths.figurePng, 'Resolution', 200);
exportgraphics(h, paths.figurePdf, 'ContentType', 'vector');
end

function row = empty_spatial_row()
row = struct();
row.device = "";
row.raw_raman_coordinates = "";
row.raman_scan_direction = "";
row.device_optical_or_sem_image = "";
row.hall_bar_coordinates = "";
row.stressor_boundary_coordinates = "";
row.crack_coordinates = "";
row.stage_coordinate_metadata = "";
row.mote2_thickness = "";
row.crystal_axis_orientation = "";
row.stressor_thickness = "";
row.film_force_or_residual_stress = "";
row.substrate_oxide_stack = "";
row.elastic_constants = "";
row.raman_mode_assignment = "";
row.polarization_information = "";
row.source_basis = "";
end

function row = empty_readiness_row()
row = struct();
row.device = "";
row.registration_class = "";
row.quantitative_2D_mechanics_allowed = false;
row.quantitative_1D_mechanics_allowed = false;
row.geometry_proxy_allowed = false;
row.strain_tensor_recovery_allowed = false;
row.reason = "";
end

function row = empty_material_row()
row = struct();
row.device = "";
row.mote2_thickness_available = false;
row.crystal_axis_available = false;
row.stressor_thickness_available = false;
row.film_force_or_residual_stress_available = false;
row.substrate_stack_available = false;
row.elastic_constants_available = false;
row.raman_mode_assignment_available = false;
row.polarization_available = false;
row.quantitative_mechanics_materials_complete = false;
row.tensor_component_scope = "";
end

function row = row_for_device(T, device)
row = table();
if isempty(T) || ~ismember("device", string(T.Properties.VariableNames))
    return;
end
idx = find(string(T.device) == string(device), 1);
if ~isempty(idx)
    row = T(idx, :);
end
end

function value = availability_from_phase12(row, variableName, fallback)
value = fallback;
if ~isempty(row) && ismember(variableName, string(row.Properties.VariableNames))
    raw = row.(variableName)(1);
    if islogical(raw) || isnumeric(raw)
        value = ternary(logical(raw), "available", "missing");
    else
        value = string(raw);
    end
end
end

function value = availability_from_geometry(row, variableName, fallback)
value = fallback;
if ~isempty(row) && ismember(variableName, string(row.Properties.VariableNames))
    value = string(row.(variableName)(1));
end
end

function value = boundary_status(device)
switch string(device)
    case {"AS005", "AS006"}
        value = "geometry_context_present_not_quantitatively_registered";
    otherwise
        value = "not_archived";
end
end

function value = crack_status(device)
if string(device) == "AS005"
    value = "crack_context_present_not_quantitatively_registered";
else
    value = "not_applicable_or_not_archived";
end
end

function basis = source_basis(phase12Row, geometryRow)
if ~isempty(phase12Row) || ~isempty(geometryRow)
    basis = "phase12_artifact_context";
else
    basis = "phase19A_canonical_artifact_gap_audit";
end
end

function tf = is_positive(value)
text = lower(string(value));
if contains(text, "missing") || contains(text, "unavailable") || ...
        contains(text, "unknown") || contains(text, "not_archived")
    tf = false;
    return;
end
tf = any(text == ["true", "1", "yes", "available", "known", ...
    "quantitative", "complete", "geometry_proxy_only"]) || ...
    contains(text, "available") || contains(text, "known") || ...
    contains(text, "present") || contains(text, "geometry_context");
tf = tf && ~contains(text, "unregistered");
end

function cls = classify_registration(quantitative2D, quantitative1D, ...
    geometryOnly)
if quantitative2D
    cls = "quantitative_2D_registered";
elseif quantitative1D
    cls = "quantitative_1D_registered";
elseif geometryOnly
    cls = "geometry_registered_only";
else
    cls = "device_association_only";
end
end

function reason = readiness_reason(cls)
switch string(cls)
    case "quantitative_2D_registered"
        reason = "All spatial and material prerequisites support bounded 2D mechanics.";
    case "quantitative_1D_registered"
        reason = "A registered line/axis exists, but 2D field recovery remains blocked.";
    case "geometry_registered_only"
        reason = "Geometry context exists, but Raman/device coordinate transform is not quantitative.";
    otherwise
        reason = "Only device-level association is available in the canonical artifact set.";
end
end

function scope = tensor_scope(row)
if row.quantitative_mechanics_materials_complete && row.polarization_available
    scope = "candidate_in_plane_tensor_components_eps_xx_eps_yy_eps_xy";
elseif row.quantitative_mechanics_materials_complete
    scope = "candidate_scalar_or_gradient_mechanics_without_polarization";
else
    scope = "tensor_recovery_blocked";
end
end

function tf = phase9_raman_remains_qualitative(inputs)
tf = true;
T = inputs.phase9RamanRegistrationDisposition;
if ~isempty(T)
    values = strings(0, 1);
    for c = 1:width(T)
        values = [values; string(T.(c))]; %#ok<AGROW>
    end
    tf = any(values == "qualitative_independent_mechanical_context") || ...
        any(values == "not_run") || any(contains(values, ...
        "no_defensible_registered_spatial_transform"));
end
end

function value = lookup_item(T, key)
value = "";
if isempty(T)
    return;
end
names = string(T.Properties.VariableNames);
if ismember("item", names)
    itemCol = string(T.item);
elseif ismember("component", names)
    itemCol = string(T.component);
else
    return;
end
idx = find(itemCol == string(key), 1);
if isempty(idx)
    return;
end
if ismember("value", names)
    value = string(T.value(idx));
elseif ismember("status", names)
    value = string(T.status(idx));
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
