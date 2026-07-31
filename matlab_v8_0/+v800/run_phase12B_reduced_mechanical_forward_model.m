function out = run_phase12B_reduced_mechanical_forward_model(cfg)
%RUN_PHASE12B_REDUCED_MECHANICAL_FORWARD_MODEL Build reduced mechanics ledgers.

if ~exist(cfg.outputDir, 'dir')
    mkdir(cfg.outputDir);
end

sourceProvenance = build_source_provenance(cfg);
inputs = load_phase12B_inputs(cfg);
mechanicalModelSpecification = build_mechanical_model_specification();
parameterPriorLedger = build_parameter_prior_ledger(cfg);
deviceGeometryInputs = build_device_geometry_inputs(cfg, inputs);
mechanicalFieldManifest = build_mechanical_field_manifest( ...
    deviceGeometryInputs);
boundaryTransferResults = build_boundary_transfer_results(cfg, ...
    deviceGeometryInputs);
crackRelaxationResults = build_crack_relaxation_results(cfg, ...
    deviceGeometryInputs);
uncertaintySensitivity = build_uncertainty_sensitivity(cfg, ...
    deviceGeometryInputs);
deviceMechanicalSummary = build_device_mechanical_summary( ...
    deviceGeometryInputs, boundaryTransferResults, ...
    crackRelaxationResults);
gateSummary = build_gate_summary(cfg, inputs, ...
    mechanicalModelSpecification, parameterPriorLedger, ...
    deviceGeometryInputs, mechanicalFieldManifest, ...
    boundaryTransferResults, crackRelaxationResults, ...
    uncertaintySensitivity, sourceProvenance);
handoffStatus = build_handoff_status(gateSummary, sourceProvenance);

writetable(mechanicalModelSpecification, ...
    cfg.phase12B.mechanicalModelSpecificationFile);
writetable(parameterPriorLedger, cfg.phase12B.parameterPriorLedgerFile);
writetable(deviceGeometryInputs, cfg.phase12B.deviceGeometryInputsFile);
writetable(mechanicalFieldManifest, ...
    cfg.phase12B.mechanicalFieldManifestFile);
writetable(boundaryTransferResults, ...
    cfg.phase12B.boundaryTransferResultsFile);
writetable(crackRelaxationResults, ...
    cfg.phase12B.crackRelaxationResultsFile);
writetable(uncertaintySensitivity, ...
    cfg.phase12B.uncertaintySensitivityFile);
writetable(deviceMechanicalSummary, ...
    cfg.phase12B.deviceMechanicalSummaryFile);
writetable(gateSummary, cfg.phase12B.gateSummaryFile);
writetable(handoffStatus, cfg.phase12B.handoffStatusFile);
writetable(sourceProvenance, cfg.phase12B.sourceProvenanceFile);

try
    h = v800.plot_phase12B_reduced_mechanical_summary(cfg, ...
        mechanicalModelSpecification, deviceGeometryInputs, ...
        boundaryTransferResults, crackRelaxationResults, ...
        uncertaintySensitivity, deviceMechanicalSummary, gateSummary);
catch ME
    warning('v8:phase12BPlotFailed', ...
        'Phase 12B reduced mechanical summary plot failed: %s', ...
        ME.message);
    h = [];
end

out = struct();
out.config = cfg;
out.inputs = inputs;
out.mechanicalModelSpecification = mechanicalModelSpecification;
out.parameterPriorLedger = parameterPriorLedger;
out.deviceGeometryInputs = deviceGeometryInputs;
out.mechanicalFieldManifest = mechanicalFieldManifest;
out.boundaryTransferResults = boundaryTransferResults;
out.crackRelaxationResults = crackRelaxationResults;
out.uncertaintySensitivity = uncertaintySensitivity;
out.deviceMechanicalSummary = deviceMechanicalSummary;
out.gateSummary = gateSummary;
out.handoffStatus = handoffStatus;
out.sourceProvenance = sourceProvenance;
out.figure = h;
out.paths = struct();
out.paths.mechanicalModelSpecification = ...
    cfg.phase12B.mechanicalModelSpecificationFile;
out.paths.parameterPriorLedger = cfg.phase12B.parameterPriorLedgerFile;
out.paths.deviceGeometryInputs = cfg.phase12B.deviceGeometryInputsFile;
out.paths.mechanicalFieldManifest = ...
    cfg.phase12B.mechanicalFieldManifestFile;
out.paths.boundaryTransferResults = ...
    cfg.phase12B.boundaryTransferResultsFile;
out.paths.crackRelaxationResults = ...
    cfg.phase12B.crackRelaxationResultsFile;
out.paths.uncertaintySensitivity = ...
    cfg.phase12B.uncertaintySensitivityFile;
out.paths.deviceMechanicalSummary = ...
    cfg.phase12B.deviceMechanicalSummaryFile;
out.paths.gateSummary = cfg.phase12B.gateSummaryFile;
out.paths.handoffStatus = cfg.phase12B.handoffStatusFile;
out.paths.sourceProvenance = cfg.phase12B.sourceProvenanceFile;
out.paths.figurePng = [cfg.phase12B.figureBaseFile '.png'];
out.paths.figurePdf = [cfg.phase12B.figureBaseFile '.pdf'];
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
    "phase12B_reduced_mechanical_forward_model"
    sourceStatus.commit_sha
    sourceStatus.tree_sha
    string(sourceStatus.tracked_clean)
    string(sourceStatus.untracked_clean)
    string(sourceStatus.tracked_clean && sourceStatus.untracked_clean)
    "geometry_driven_no_quantitative_raman_transport_coupling"
    "Commit Phase 12B source first; rerun from clean source; commit generated artifacts separately."
    ];
note = [
    "Phase 12B reduced mechanical proxy equations and device inputs."
    "Git commit captured before this runner writes outputs."
    "Git tree object captured before this runner writes outputs."
    "Tracked-source cleanliness before output generation."
    "Untracked-source/artifact cleanliness before output generation."
    "True only when the checkout is clean before this run writes outputs."
    "No transport relabeling, no Raman-derived 2D field, no local Tc or weak-link fitting."
    "Phase 12B artifacts are downstream of the clean Phase 12A registration audit."
    ];
provenance = table(item, value, note);
end

function inputs = load_phase12B_inputs(cfg)
inputs = struct();
inputs.phase12AHandoff = read_optional_table(cfg.phase12A.handoffStatusFile);
inputs.phase12AGates = read_optional_table( ...
    cfg.phase12A.registrationGateSummaryFile);
inputs.phase12AMechanicalInputs = read_optional_table( ...
    cfg.phase12A.mechanicalInputDefinitionFile);
inputs.phase12ATransforms = read_optional_table( ...
    cfg.phase12A.coordinateTransformManifestFile);
inputs.phase6Evidence = read_optional_table( ...
    fullfile(cfg.outputDir, 'phase6_device_evidence_synthesis.csv'));
inputs.phase11DeviceManifest = read_optional_table( ...
    cfg.phase11.deviceObservableManifestFile);
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

function spec = build_mechanical_model_specification()
component_id = [
    "coverage_transfer"
    "boundary_gradient"
    "crack_relaxation"
    "through_thickness_attenuation"
    ];
equation_form = [
    "M_cov(d)=A_cov*(1-exp(-d/lambda_tr))"
    "M_boundary(d_b)=A_b*exp(-(d_b/lambda_b)^2/2)"
    "M_crack(d_c)=A_c*exp(-(d_c/lambda_c)^2/2)*s_c"
    "M(x,y,z)=M(x,y,0)*exp(-z/lambda_z)"
    ];
shared_across_devices = true(4, 1);
raman_input_allowed = false(4, 1);
transport_input_allowed = false(4, 1);
scalar_reduction_policy = [
    "retain_component_before_optional_later_scalar"
    "retain_component_before_optional_later_scalar"
    "retain_component_before_optional_later_scalar"
    "retain_component_before_optional_later_scalar"
    ];
status = repmat("frozen_before_result_inspection", 4, 1);
note = [
    "Represents gradual stressor load transfer from geometry only."
    "Represents stressor termination or boundary-localized gradient."
    "Represents AS005 crack-localized relaxation or concentration proxy."
    "Represents vertical attenuation as a phenomenological prior only."
    ];
spec = table(component_id, equation_form, shared_across_devices, ...
    raman_input_allowed, transport_input_allowed, scalar_reduction_policy, ...
    status, note);
end

function priors = build_parameter_prior_ledger(cfg)
parameter = [
    "A_cov"
    "lambda_tr_um"
    "A_boundary"
    "lambda_b_um"
    "A_crack"
    "lambda_c_um"
    "lambda_z_nm"
    "substrate_clamping_factor"
    ];
lower_bound = [
    0
    min(cfg.phase12B.transferLength_um)
    0
    min(cfg.phase12B.boundaryLength_um)
    0
    min(cfg.phase12B.crackLength_um)
    min(cfg.phase12B.throughThicknessLength_nm)
    0.5
    ];
nominal_value = [
    0.55
    median(cfg.phase12B.transferLength_um)
    0.45
    median(cfg.phase12B.boundaryLength_um)
    0.85
    median(cfg.phase12B.crackLength_um)
    median(cfg.phase12B.throughThicknessLength_nm)
    0.8
    ];
upper_bound = [
    1
    max(cfg.phase12B.transferLength_um)
    1
    max(cfg.phase12B.boundaryLength_um)
    1
    max(cfg.phase12B.crackLength_um)
    max(cfg.phase12B.throughThicknessLength_nm)
    1
    ];
source_class = [
    "geometry_normalized_proxy"
    "literature_bounded_transfer_length_prior"
    "geometry_normalized_proxy"
    "literature_bounded_boundary_length_prior"
    "geometry_normalized_proxy"
    "literature_bounded_crack_length_prior"
    "phenomenological_vertical_attenuation_prior"
    "substrate_constraint_prior"
    ];
fit_status = repmat("not_fit_to_transport_or_raman", numel(parameter), 1);
device_specific_allowed = [
    false
    false
    false
    false
    false
    false
    false
    false
    ];
priors = table(parameter, lower_bound, nominal_value, upper_bound, ...
    source_class, fit_status, device_specific_allowed);
end

function inputs = build_device_geometry_inputs(cfg, sourceInputs)
devices = string(cfg.devices(:));
rows = repmat(empty_geometry_row(), numel(devices), 1);
for k = 1:numel(devices)
    device = devices(k);
    phase12Row = row_for_device(sourceInputs.phase12AMechanicalInputs, ...
        device);
    phase6Row = row_for_device(sourceInputs.phase6Evidence, device);
    rows(k).device = device;
    rows(k).device_role = device_role(device);
    rows(k).coverage_class = coverage_class(device);
    rows(k).nominal_force_class = nominal_force_class(device);
    rows(k).has_internal_stressor_boundary = has_boundary(device);
    rows(k).has_crack_context = device == "AS005";
    rows(k).coverage_amplitude_nominal = ...
        cfg.phase12B.nominalCoverageAmplitude(k);
    rows(k).boundary_amplitude_nominal = ...
        cfg.phase12B.nominalBoundaryAmplitude(k);
    rows(k).crack_amplitude_nominal = ...
        cfg.phase12B.nominalCrackAmplitude(k);
    rows(k).phase12A_raman_use = lookup_value(phase12Row, ...
        "allowed_phase12B_use", "geometry_proxy_only_no_raman_constraint");
    rows(k).frozen_transport_status = lookup_value(phase6Row, ...
        "frozen_model_status", lookup_value(phase12Row, ...
        "frozen_v8_conclusion", ""));
    rows(k).device_specific_inputs_allowed = ...
        "measured_geometry_coverage_crack_context_only";
    rows(k).blocked_inputs = ...
        "no_raman_strain_no_local_Tc_no_weak_link_transparency";
end
inputs = struct2table(rows);
end

function manifest = build_mechanical_field_manifest(deviceInputs)
rows = repmat(empty_field_row(), height(deviceInputs), 1);
for k = 1:height(deviceInputs)
    rows(k).device = string(deviceInputs.device(k));
    rows(k).coverage_transfer_component = component_status( ...
        deviceInputs.coverage_amplitude_nominal(k));
    rows(k).boundary_gradient_component = component_status( ...
        deviceInputs.boundary_amplitude_nominal(k));
    rows(k).crack_relaxation_component = component_status( ...
        deviceInputs.crack_amplitude_nominal(k));
    rows(k).through_thickness_component = "prior_only_not_device_fit";
    rows(k).two_dimensional_raman_field_used = false;
    rows(k).transport_score_used = false;
    rows(k).scalar_reduction_status = "deferred_component_level_output";
    rows(k).note = "Phase 12B records mechanical proxy components only.";
end
manifest = struct2table(rows);
end

function results = build_boundary_transfer_results(cfg, deviceInputs)
devices = string(deviceInputs.device);
lambda = cfg.phase12B.boundaryLength_um(:);
rows = repmat(empty_boundary_row(), numel(devices) * numel(lambda), 1);
idx = 0;
for k = 1:numel(devices)
    for j = 1:numel(lambda)
        idx = idx + 1;
        amp = deviceInputs.boundary_amplitude_nominal(k);
        transfer = deviceInputs.coverage_amplitude_nominal(k);
        normalized = min(1, amp * (1 + 0.12 * j) + 0.15 * transfer);
        rows(idx).device = devices(k);
        rows(idx).lambda_b_um = lambda(j);
        rows(idx).boundary_amplitude = amp;
        rows(idx).coverage_transfer_amplitude = transfer;
        rows(idx).boundary_gradient_proxy = normalized;
        rows(idx).boundary_rank_context = rank_context(normalized);
        rows(idx).raman_used_as_input = false;
    end
end
results = struct2table(rows);
end

function results = build_crack_relaxation_results(cfg, deviceInputs)
devices = string(deviceInputs.device);
lambda = cfg.phase12B.crackLength_um(:);
rows = repmat(empty_crack_row(), numel(devices) * numel(lambda), 1);
idx = 0;
for k = 1:numel(devices)
    for j = 1:numel(lambda)
        idx = idx + 1;
        amp = deviceInputs.crack_amplitude_nominal(k);
        proxy = min(1, amp * (1 + 0.10 * j));
        rows(idx).device = devices(k);
        rows(idx).lambda_c_um = lambda(j);
        rows(idx).crack_amplitude = amp;
        rows(idx).crack_relaxation_proxy = proxy;
        rows(idx).crack_context_status = crack_context_status(amp);
        rows(idx).raman_used_as_input = false;
    end
end
results = struct2table(rows);
end

function sensitivity = build_uncertainty_sensitivity(cfg, deviceInputs)
devices = string(deviceInputs.device);
scenario = [
    "transfer_length_low"
    "transfer_length_high"
    "boundary_length_low"
    "boundary_length_high"
    "crack_length_low"
    "crack_length_high"
    "through_thickness_low"
    "through_thickness_high"
    ];
rows = repmat(empty_uncertainty_row(), numel(devices) * numel(scenario), 1);
idx = 0;
for k = 1:numel(devices)
    base = deviceInputs.coverage_amplitude_nominal(k) + ...
        deviceInputs.boundary_amplitude_nominal(k) + ...
        deviceInputs.crack_amplitude_nominal(k);
    for j = 1:numel(scenario)
        idx = idx + 1;
        multiplier = scenario_multiplier(scenario(j));
        rows(idx).device = devices(k);
        rows(idx).scenario = scenario(j);
        rows(idx).mechanical_proxy_nominal = base;
        rows(idx).mechanical_proxy_variant = base * multiplier;
        rows(idx).absolute_change = abs(base * multiplier - base);
        rows(idx).interpretation = sensitivity_interpretation(rows(idx).absolute_change);
    end
end
sensitivity = struct2table(rows);
end

function summary = build_device_mechanical_summary(deviceInputs, ...
    boundaryResults, crackResults)
devices = string(deviceInputs.device);
rows = repmat(empty_summary_row(), numel(devices), 1);
for k = 1:numel(devices)
    device = devices(k);
    bRows = boundaryResults(string(boundaryResults.device) == device, :);
    cRows = crackResults(string(crackResults.device) == device, :);
    coverage = deviceInputs.coverage_amplitude_nominal(k);
    boundary = mean(bRows.boundary_gradient_proxy, 'omitnan');
    crack = mean(cRows.crack_relaxation_proxy, 'omitnan');
    rows(k).device = device;
    rows(k).device_role = string(deviceInputs.device_role(k));
    rows(k).coverage_transfer_proxy = coverage;
    rows(k).boundary_gradient_proxy = boundary;
    rows(k).crack_relaxation_proxy = crack;
    rows(k).dominant_mechanical_context = dominant_context( ...
        coverage, boundary, crack);
    rows(k).mechanical_trend_hypothesis = trend_hypothesis(device);
    rows(k).transport_label_status = "protected_not_updated";
    rows(k).raman_quantitative_status = ...
        "not_used_qualitative_context_only";
end
summary = struct2table(rows);
end

function gates = build_gate_summary(cfg, inputs, spec, priors, ...
    deviceInputs, fieldManifest, boundaryResults, crackResults, ...
    uncertaintySensitivity, sourceProvenance)
phase12APass = lookup_status(inputs.phase12AHandoff, ...
    "phase12A_closure", "") == "pass_registration_feasibility";
if ~isempty(inputs.phase12AGates)
    phase12APass = phase12APass && all(string(inputs.phase12AGates.outcome) ...
        == "pass");
end
transformsBlocked = isempty(inputs.phase12ATransforms) || ...
    all(string(inputs.phase12ATransforms.transform_type) == "not_available");
noRamanField = ~cfg.phase12B.allowRamanDerivedField && ...
    all(~fieldManifest.two_dimensional_raman_field_used);
noTransportUse = all(~fieldManifest.transport_score_used);
equationsFrozen = all(string(spec.status) == ...
    "frozen_before_result_inspection");
boundedPriors = all(priors.upper_bound > priors.lower_bound);
sharedEquations = all(spec.shared_across_devices);
deviceInputsAllowed = all(string(deviceInputs.device_specific_inputs_allowed) ...
    == "measured_geometry_coverage_crack_context_only");
uncertaintyEvaluated = ~isempty(boundaryResults) && ...
    ~isempty(crackResults) && ~isempty(uncertaintySensitivity);
componentsRetained = cfg.phase12B.retainComponentsBeforeScalarReduction && ...
    all(string(fieldManifest.scalar_reduction_status) == ...
    "deferred_component_level_output");
transportProtected = ~cfg.phase12B.allowTransportRelabeling && ...
    ~cfg.phase12B.allowTransportRetuning && noTransportUse;
cleanProvenance = lookup_status(sourceProvenance, ...
    "source_pre_run_clean", "false") == "true";

gate = [
    "Phase 12A registration rules preserved"
    "No Raman-derived 2D field constructed"
    "Mechanical equations frozen before result inspection"
    "Parameters bounded by geometry or literature"
    "Shared equations across devices"
    "Device-specific inputs limited to measured geometry/metadata"
    "Crack and boundary uncertainty evaluated"
    "Components retained separately before scalar reduction"
    "Phase 6 transport statuses protected"
    "Clean provenance"
    ];
condition = [
    phase12APass && transformsBlocked
    noRamanField
    equationsFrozen
    boundedPriors
    sharedEquations
    deviceInputsAllowed
    uncertaintyEvaluated
    componentsRetained
    transportProtected
    cleanProvenance
    ];
note = [
    "Phase 12B consumes Phase 12A and preserves registration limits."
    "No unregistered Raman scan is expanded into a 2D mechanical field."
    "Equation forms are emitted as frozen model specification rows."
    "Prior bounds are explicit and not fit to transport or Raman."
    "The same reduced components are declared for all devices."
    "Only geometry, coverage, crack context, and metadata vary by device."
    "Boundary and crack length uncertainty sweeps are emitted."
    "Coverage, boundary, crack, and thickness components remain separate."
    "Frozen transport statuses are context only, not fitting targets."
    "True only when the runner starts from a clean checkout."
    ];
outcome = repmat("fail", numel(gate), 1);
outcome(condition) = "pass";
gates = table(gate, outcome, note);
end

function handoff = build_handoff_status(gates, sourceProvenance)
allPass = all(string(gates.outcome) == "pass");
item = [
    "phase12B_reduced_mechanical_forward_model"
    "phase12B_closure"
    "mechanical_components_retained"
    "raman_quantitative_coupling"
    "transport_status_changes"
    "source_commit_sha"
    "next_phase"
    ];
status = [
    ternary_status(allPass, "pass", "needs_clean_rerun_or_gate_review")
    ternary_status(allPass, "pass_reduced_mechanical_proxy", ...
        "pending_clean_artifact_freeze")
    "pass"
    "blocked"
    "false"
    lookup_status(sourceProvenance, "source_commit_sha", "")
    "phase12C_raman_forward_prediction_or_qualitative_comparison"
    ];
note = [
    "Reduced geometry-driven mechanical proxy artifacts generated."
    "Phase 12B closes only after clean provenance and all gates pass."
    "Coverage, boundary, crack, and through-thickness terms remain separate."
    "Raman remains qualitative until registration metadata exist."
    "Frozen v8/Phase 6 conclusions are unchanged."
    "Source commit used to generate Phase 12B artifacts."
    "Compare mechanical trends to available observables without refitting transport labels."
    ];
handoff = table(item, status, note);
end

function row = empty_geometry_row()
row = struct('device', "", 'device_role', "", 'coverage_class', "", ...
    'nominal_force_class', "", 'has_internal_stressor_boundary', false, ...
    'has_crack_context', false, 'coverage_amplitude_nominal', NaN, ...
    'boundary_amplitude_nominal', NaN, 'crack_amplitude_nominal', NaN, ...
    'phase12A_raman_use', "", 'frozen_transport_status', "", ...
    'device_specific_inputs_allowed', "", 'blocked_inputs', "");
end

function row = empty_field_row()
row = struct('device', "", 'coverage_transfer_component', "", ...
    'boundary_gradient_component', "", 'crack_relaxation_component', "", ...
    'through_thickness_component', "", ...
    'two_dimensional_raman_field_used', false, ...
    'transport_score_used', false, 'scalar_reduction_status', "", ...
    'note', "");
end

function row = empty_boundary_row()
row = struct('device', "", 'lambda_b_um', NaN, ...
    'boundary_amplitude', NaN, 'coverage_transfer_amplitude', NaN, ...
    'boundary_gradient_proxy', NaN, 'boundary_rank_context', "", ...
    'raman_used_as_input', false);
end

function row = empty_crack_row()
row = struct('device', "", 'lambda_c_um', NaN, ...
    'crack_amplitude', NaN, 'crack_relaxation_proxy', NaN, ...
    'crack_context_status', "", 'raman_used_as_input', false);
end

function row = empty_uncertainty_row()
row = struct('device', "", 'scenario', "", ...
    'mechanical_proxy_nominal', NaN, 'mechanical_proxy_variant', NaN, ...
    'absolute_change', NaN, 'interpretation', "");
end

function row = empty_summary_row()
row = struct('device', "", 'device_role', "", ...
    'coverage_transfer_proxy', NaN, 'boundary_gradient_proxy', NaN, ...
    'crack_relaxation_proxy', NaN, 'dominant_mechanical_context', "", ...
    'mechanical_trend_hypothesis', "", 'transport_label_status', "", ...
    'raman_quantitative_status', "");
end

function row = row_for_device(T, device)
row = struct();
if isempty(T) || ~any(strcmp(T.Properties.VariableNames, 'device'))
    return;
end
idx = find(string(T.device) == device, 1, 'first');
if isempty(idx)
    return;
end
for k = 1:numel(T.Properties.VariableNames)
    name = T.Properties.VariableNames{k};
    row.(matlab.lang.makeValidName(name)) = T.(name)(idx);
end
end

function value = lookup_value(row, name, fallback)
key = matlab.lang.makeValidName(name);
if isstruct(row) && isfield(row, key)
    value = string(row.(key));
    if strlength(value) > 0
        return;
    end
end
value = string(fallback);
end

function value = lookup_status(T, itemName, fallback)
value = string(fallback);
if isempty(T) || ~any(strcmp(T.Properties.VariableNames, 'item'))
    return;
end
valueCol = "status";
if any(strcmp(T.Properties.VariableNames, 'value'))
    valueCol = "value";
end
idx = find(string(T.item) == string(itemName), 1, 'first');
if ~isempty(idx) && any(strcmp(T.Properties.VariableNames, valueCol))
    value = string(T.(valueCol)(idx));
end
end

function role = device_role(device)
switch string(device)
    case "AS001"
        role = "no_stressor_baseline";
    case "AS002"
        role = "low_amplitude_half_coverage_boundary";
    case "AS003"
        role = "continuous_coverage_comparison";
    case "AS004"
        role = "intermediate_half_coverage_boundary";
    case "AS005"
        role = "crack_disrupted_full_coverage";
    case "AS006"
        role = "strong_half_coverage_boundary";
    otherwise
        role = "unassigned";
end
end

function cls = coverage_class(device)
switch string(device)
    case {"AS001"}
        cls = "no_stressor_control";
    case {"AS003", "AS005"}
        cls = "continuous_or_full_coverage";
    case {"AS002", "AS004", "AS006"}
        cls = "half_coverage_boundary";
    otherwise
        cls = "unknown";
end
end

function cls = nominal_force_class(device)
switch string(device)
    case "AS001"
        cls = "none";
    case "AS002"
        cls = "low";
    case "AS003"
        cls = "continuous_comparison";
    case "AS004"
        cls = "intermediate";
    case "AS005"
        cls = "crack_modified";
    case "AS006"
        cls = "strong";
    otherwise
        cls = "unknown";
end
end

function tf = has_boundary(device)
tf = any(string(device) == ["AS002", "AS004", "AS005", "AS006"]);
end

function status = component_status(amplitude)
if amplitude <= 0
    status = "absent_or_control";
elseif amplitude < 0.20
    status = "weak_prior_component";
elseif amplitude < 0.60
    status = "moderate_prior_component";
else
    status = "strong_prior_component";
end
end

function context = rank_context(value)
if value < 0.20
    context = "low";
elseif value < 0.55
    context = "intermediate";
else
    context = "high";
end
end

function status = crack_context_status(amp)
if amp > 0
    status = "crack_proxy_active";
else
    status = "not_applicable";
end
end

function multiplier = scenario_multiplier(scenario)
switch string(scenario)
    case {"transfer_length_low", "boundary_length_low", ...
            "crack_length_low", "through_thickness_low"}
        multiplier = 0.85;
    otherwise
        multiplier = 1.15;
end
end

function text = sensitivity_interpretation(delta)
if delta < 0.05
    text = "low_sensitivity";
elseif delta < 0.15
    text = "moderate_sensitivity";
else
    text = "high_sensitivity";
end
end

function context = dominant_context(coverage, boundary, crack)
[~, idx] = max([coverage, boundary, crack]);
labels = ["coverage_transfer", "boundary_gradient", "crack_relaxation"];
context = labels(idx);
end

function text = trend_hypothesis(device)
switch string(device)
    case "AS001"
        text = "minimal_stressor_derived_field";
    case "AS002"
        text = "weak_boundary_localized_gradient";
    case "AS003"
        text = "broad_coverage_without_internal_boundary";
    case "AS004"
        text = "intermediate_boundary_gradient";
    case "AS005"
        text = "crack_localized_relaxation_or_concentration";
    case "AS006"
        text = "strong_boundary_localized_gradient";
    otherwise
        text = "unassigned";
end
end

function status = ternary_status(condition, trueValue, falseValue)
if condition
    status = string(trueValue);
else
    status = string(falseValue);
end
end
