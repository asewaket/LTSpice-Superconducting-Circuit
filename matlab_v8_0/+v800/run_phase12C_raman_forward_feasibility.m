function out = run_phase12C_raman_forward_feasibility(cfg)
%RUN_PHASE12C_RAMAN_FORWARD_FEASIBILITY Build Raman forward feasibility ledgers.

if ~exist(cfg.outputDir, 'dir')
    mkdir(cfg.outputDir);
end

sourceProvenance = build_source_provenance(cfg);
inputs = load_phase12C_inputs(cfg);
ramanForwardModelSpecification = build_raman_forward_model_specification();
modeResponsePriorLedger = build_mode_response_prior_ledger(cfg);
nonstrainContributionLedger = build_nonstrain_contribution_ledger(cfg);
deviceLevelModePredictions = build_device_level_mode_predictions(cfg, ...
    inputs, modeResponsePriorLedger, nonstrainContributionLedger);
registeredComparisonStatus = build_registered_comparison_status(cfg, inputs);
uncertaintySensitivity = build_uncertainty_sensitivity( ...
    deviceLevelModePredictions);
gateSummary = build_gate_summary(cfg, inputs, ...
    ramanForwardModelSpecification, modeResponsePriorLedger, ...
    deviceLevelModePredictions, nonstrainContributionLedger, ...
    registeredComparisonStatus, sourceProvenance);
handoffStatus = build_handoff_status(gateSummary, sourceProvenance);

writetable(ramanForwardModelSpecification, ...
    cfg.phase12C.ramanForwardModelSpecificationFile);
writetable(modeResponsePriorLedger, ...
    cfg.phase12C.modeResponsePriorLedgerFile);
writetable(deviceLevelModePredictions, ...
    cfg.phase12C.deviceLevelModePredictionsFile);
writetable(nonstrainContributionLedger, ...
    cfg.phase12C.nonstrainContributionLedgerFile);
writetable(registeredComparisonStatus, ...
    cfg.phase12C.registeredComparisonStatusFile);
writetable(uncertaintySensitivity, ...
    cfg.phase12C.uncertaintySensitivityFile);
writetable(gateSummary, cfg.phase12C.gateSummaryFile);
writetable(handoffStatus, cfg.phase12C.handoffStatusFile);
writetable(sourceProvenance, cfg.phase12C.sourceProvenanceFile);

try
    h = v800.plot_phase12C_raman_forward_summary(cfg, ...
        modeResponsePriorLedger, deviceLevelModePredictions, ...
        nonstrainContributionLedger, registeredComparisonStatus, ...
        uncertaintySensitivity, gateSummary);
catch ME
    warning('v8:phase12CPlotFailed', ...
        'Phase 12C Raman forward feasibility plot failed: %s', ...
        ME.message);
    h = [];
end

out = struct();
out.config = cfg;
out.inputs = inputs;
out.ramanForwardModelSpecification = ramanForwardModelSpecification;
out.modeResponsePriorLedger = modeResponsePriorLedger;
out.deviceLevelModePredictions = deviceLevelModePredictions;
out.nonstrainContributionLedger = nonstrainContributionLedger;
out.registeredComparisonStatus = registeredComparisonStatus;
out.uncertaintySensitivity = uncertaintySensitivity;
out.gateSummary = gateSummary;
out.handoffStatus = handoffStatus;
out.sourceProvenance = sourceProvenance;
out.figure = h;
out.paths = struct();
out.paths.ramanForwardModelSpecification = ...
    cfg.phase12C.ramanForwardModelSpecificationFile;
out.paths.modeResponsePriorLedger = ...
    cfg.phase12C.modeResponsePriorLedgerFile;
out.paths.deviceLevelModePredictions = ...
    cfg.phase12C.deviceLevelModePredictionsFile;
out.paths.nonstrainContributionLedger = ...
    cfg.phase12C.nonstrainContributionLedgerFile;
out.paths.registeredComparisonStatus = ...
    cfg.phase12C.registeredComparisonStatusFile;
out.paths.uncertaintySensitivity = ...
    cfg.phase12C.uncertaintySensitivityFile;
out.paths.gateSummary = cfg.phase12C.gateSummaryFile;
out.paths.handoffStatus = cfg.phase12C.handoffStatusFile;
out.paths.sourceProvenance = cfg.phase12C.sourceProvenanceFile;
out.paths.figurePng = [cfg.phase12C.figureBaseFile '.png'];
out.paths.figurePdf = [cfg.phase12C.figureBaseFile '.pdf'];
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
    "phase12C_raman_forward_feasibility"
    sourceStatus.commit_sha
    sourceStatus.tree_sha
    string(sourceStatus.tracked_clean)
    string(sourceStatus.untracked_clean)
    string(sourceStatus.tracked_clean && sourceStatus.untracked_clean)
    "mode_specific_qualitative_device_level_raman_predictions"
    "Commit Phase 12C source first; rerun from clean source; commit generated artifacts separately."
    ];
note = [
    "Phase 12C mode-specific Raman forward-model feasibility."
    "Git commit captured before this runner writes outputs."
    "Git tree object captured before this runner writes outputs."
    "Tracked-source cleanliness before output generation."
    "Untracked-source/artifact cleanliness before output generation."
    "True only when the checkout is clean before this run writes outputs."
    "No registered spatial comparison, no device-specific coefficient fitting, no transport coupling."
    "Phase 12C artifacts are downstream of the clean Phase 12B mechanical proxy."
    ];
provenance = table(item, value, note);
end

function inputs = load_phase12C_inputs(cfg)
inputs = struct();
inputs.phase12BHandoff = read_optional_table(cfg.phase12B.handoffStatusFile);
inputs.phase12BGates = read_optional_table(cfg.phase12B.gateSummaryFile);
inputs.phase12BMechanicalSummary = read_optional_table( ...
    cfg.phase12B.deviceMechanicalSummaryFile);
inputs.phase12BFieldManifest = read_optional_table( ...
    cfg.phase12B.mechanicalFieldManifestFile);
inputs.phase12ATransforms = read_optional_table( ...
    cfg.phase12A.coordinateTransformManifestFile);
inputs.phase12ARamanLedger = read_optional_table( ...
    cfg.phase12A.ramanRegistrationLedgerFile);
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

function spec = build_raman_forward_model_specification()
term_id = [
    "mode_specific_linear_response"
    "shared_coefficients"
    "nonstrain_offset"
    "device_level_only_prediction"
    "registered_spatial_comparison_blocked"
    "transport_coupling_blocked"
    ];
equation_or_policy = [
    "Deltaomega_m=sum_j K_mj*M_j + deltaomega_m_nonstrain"
    "K_mj shared across devices and not fit device-by-device"
    "deltaomega_m_nonstrain retained as uncertainty, not absorbed into strain"
    "Predictions are relative signs/orderings for device-level context"
    "No modeled coordinate is assigned to unregistered Raman points"
    "Predicted Raman response is not passed into R(T) or weak-link fits"
    ];
status = [
    "frozen"
    "frozen"
    "frozen"
    "frozen"
    "not_run"
    "blocked"
    ];
note = [
    "Forward relation is mode-specific but component-linear."
    "Prevents AS002/AS005/AS006 coefficient overfitting."
    "Doping, thickness, heating, and interface effects remain explicit caveats."
    "Phase 12A registration limits prevent spatial residuals."
    "Missing transform is a data limitation, not a model failure."
    "Frozen v8 and Phase 6 transport conclusions remain protected."
    ];
spec = table(term_id, equation_or_policy, status, note);
end

function priors = build_mode_response_prior_ledger(cfg)
modes = string(cfg.phase12C.ramanModes(:));
components = [
    "coverage_transfer"
    "boundary_gradient"
    "crack_relaxation"
    "through_thickness_attenuation"
    ];
rows = repmat(empty_prior_row(), numel(modes) * numel(components), 1);
idx = 0;
for m = 1:numel(modes)
    for c = 1:numel(components)
        idx = idx + 1;
        [nominal, width, signPolicy] = response_prior(modes(m), ...
            components(c));
        rows(idx).mode_id = modes(m);
        rows(idx).component_id = components(c);
        rows(idx).coefficient_prior_center = nominal;
        rows(idx).coefficient_prior_half_width = width;
        rows(idx).coefficient_prior_min = nominal - width;
        rows(idx).coefficient_prior_max = nominal + width;
        rows(idx).expected_sign_policy = signPolicy;
        rows(idx).source_class = ...
            "literature_bounded_or_explicit_uncertain_prior";
        rows(idx).fit_status = "not_fit_to_device_data";
        rows(idx).shared_across_devices = true;
    end
end
priors = struct2table(rows);
end

function ledger = build_nonstrain_contribution_ledger(cfg)
modes = string(cfg.phase12C.ramanModes(:));
terms = [
    "doping_or_charge_transfer"
    "thickness_or_layer_count"
    "laser_heating"
    "interfacial_environment"
    ];
rows = repmat(empty_nonstrain_row(), numel(modes) * numel(terms), 1);
idx = 0;
for m = 1:numel(modes)
    for t = 1:numel(terms)
        idx = idx + 1;
        rows(idx).mode_id = modes(m);
        rows(idx).nonstrain_term = terms(t);
        rows(idx).separable_in_phase12C = false;
        rows(idx).uncertainty_role = "retained_as_unresolved_offset";
        rows(idx).absorbed_into_strain = false;
        rows(idx).note = ...
            "Phase 12C cannot separate this term without registered controls.";
    end
end
ledger = struct2table(rows);
end

function predictions = build_device_level_mode_predictions(cfg, inputs, ...
    priors, nonstrainLedger)
summary = inputs.phase12BMechanicalSummary;
if isempty(summary)
    summary = fallback_mechanical_summary(cfg);
end
devices = string(summary.device);
modes = string(cfg.phase12C.ramanModes(:));
rows = repmat(empty_prediction_row(), numel(devices) * numel(modes), 1);
idx = 0;
for d = 1:numel(devices)
    components = [
        summary.coverage_transfer_proxy(d)
        summary.boundary_gradient_proxy(d)
        summary.crack_relaxation_proxy(d)
        0.20 * double(summary.mechanical_proxy_present(d))
        ];
    for m = 1:numel(modes)
        idx = idx + 1;
        modePriors = priors(string(priors.mode_id) == modes(m), :);
        coeffCenter = modePriors.coefficient_prior_center;
        coeffMin = modePriors.coefficient_prior_min;
        coeffMax = modePriors.coefficient_prior_max;
        nominal = sum(coeffCenter .* components, 'omitnan');
        lower = min([sum(coeffMin .* components, 'omitnan'), ...
            sum(coeffMax .* components, 'omitnan')]);
        upper = max([sum(coeffMin .* components, 'omitnan'), ...
            sum(coeffMax .* components, 'omitnan')]);
        rows(idx).device = devices(d);
        rows(idx).mode_id = modes(m);
        rows(idx).prediction_scope = cfg.phase12C.predictionScope;
        rows(idx).predicted_response_nominal = nominal;
        rows(idx).predicted_response_min = lower;
        rows(idx).predicted_response_max = upper;
        rows(idx).predicted_sign = sign_label(nominal);
        rows(idx).dominant_mechanical_context = ...
            string(summary.dominant_mechanical_context(d));
        rows(idx).nonstrain_uncertainty_retained = ...
            any(string(nonstrainLedger.mode_id) == modes(m));
        rows(idx).registered_spatial_comparison = "not_run";
        rows(idx).transport_coupling_performed = false;
    end
end
predictions = struct2table(rows);
end

function status = build_registered_comparison_status(cfg, inputs)
devices = string(cfg.phase12C.comparisonDevices(:));
rows = repmat(empty_registered_row(), numel(devices), 1);
for k = 1:numel(devices)
    device = devices(k);
    transformRow = row_for_device(inputs.phase12ATransforms, device);
    rows(k).device = device;
    rows(k).quantitative_registered_comparison = "not_run";
    rows(k).registration_status = lookup_value(transformRow, ...
        "registration_status", "device_association_only");
    rows(k).transform_type = lookup_value(transformRow, ...
        "transform_type", "not_available");
    rows(k).reason = "no_defensible_device_to_model_transform";
    rows(k).spatial_residuals_computed = false;
    rows(k).mode_coefficients_fit_to_device = false;
    rows(k).transport_coupling_performed = false;
end
status = struct2table(rows);
end

function sensitivity = build_uncertainty_sensitivity(predictions)
rows = repmat(empty_uncertainty_row(), height(predictions), 1);
for k = 1:height(predictions)
    lo = predictions.predicted_response_min(k);
    hi = predictions.predicted_response_max(k);
    nominal = predictions.predicted_response_nominal(k);
    rows(k).device = string(predictions.device(k));
    rows(k).mode_id = string(predictions.mode_id(k));
    rows(k).nominal_response = nominal;
    rows(k).uncertainty_half_range = 0.5 * abs(hi - lo);
    rows(k).sign_stable = sign_stable(lo, hi);
    rows(k).confidence_class = confidence_class(nominal, lo, hi);
end
sensitivity = struct2table(rows);
end

function gates = build_gate_summary(cfg, inputs, spec, priors, ...
    predictions, nonstrainLedger, registeredStatus, sourceProvenance)
phase12BPass = lookup_status(inputs.phase12BHandoff, ...
    "phase12B_closure", "") == "pass_reduced_mechanical_proxy";
if ~isempty(inputs.phase12BGates)
    phase12BPass = phase12BPass && all(string(inputs.phase12BGates.outcome) ...
        == "pass");
end
equationsFrozen = all(string(spec.status) ~= "draft");
priorsDocumented = ~isempty(priors) && ...
    all(string(priors.fit_status) == "not_fit_to_device_data");
sharedCoefficients = all(priors.shared_across_devices);
nonstrainRetained = ~isempty(nonstrainLedger) && ...
    all(~nonstrainLedger.absorbed_into_strain);
qualitativeOnly = all(string(predictions.prediction_scope) == ...
    string(cfg.phase12C.predictionScope));
registeredNotRun = ~cfg.phase12C.allowRegisteredSpatialComparison && ...
    all(string(registeredStatus.quantitative_registered_comparison) == ...
    "not_run");
noDeviceFit = ~cfg.phase12C.allowCoefficientFitByDevice && ...
    all(~registeredStatus.mode_coefficients_fit_to_device);
noTransport = ~cfg.phase12C.allowTransportCoupling && ...
    all(~predictions.transport_coupling_performed) && ...
    all(~registeredStatus.transport_coupling_performed);
noAbsoluteStrain = ~cfg.phase12C.allowAbsoluteStrainInference;
cleanProvenance = lookup_status(sourceProvenance, ...
    "source_pre_run_clean", "false") == "true";

gate = [
    "Phase 12B mechanical proxy consumed"
    "Mode-response equations frozen"
    "Coefficient priors documented"
    "Mode coefficients shared across devices"
    "Nonstrain contributions retained"
    "Predictions limited to qualitative device-level scope"
    "Registered spatial comparison explicitly not run"
    "No device-specific Raman coefficient fitting"
    "No Raman-to-transport coupling"
    "No absolute strain inference"
    "Clean provenance"
    ];
condition = [
    phase12BPass
    equationsFrozen
    priorsDocumented
    sharedCoefficients
    nonstrainRetained
    qualitativeOnly
    registeredNotRun
    noDeviceFit
    noTransport
    noAbsoluteStrain
    cleanProvenance
    ];
note = [
    "Phase 12C starts from frozen Phase 12B component proxies."
    "Forward equations are emitted before any registered comparison."
    "K_mj priors are bounded and not device-fit."
    "Prevents AS002/AS005/AS006 overfitting."
    "Doping, thickness, heating, and interface offsets remain explicit."
    "Outputs are relative signs/orderings, not spatial residuals."
    "Phase 12A found no defensible transform."
    "No mode coefficient is fitted separately by device."
    "Predicted Raman response does not alter R(T) or weak-link labels."
    "Peak shifts are not converted to absolute strain."
    "True only when the runner starts from a clean checkout."
    ];
outcome = repmat("fail", numel(gate), 1);
outcome(condition) = "pass";
gates = table(gate, outcome, note);
end

function handoff = build_handoff_status(gates, sourceProvenance)
allPass = all(string(gates.outcome) == "pass");
item = [
    "phase12C_raman_forward_feasibility"
    "phase12C_closure"
    "quantitative_registered_comparison"
    "raman_predictions"
    "transport_coupling_performed"
    "source_commit_sha"
    "next_phase"
    ];
status = [
    ternary_status(allPass, "pass", "needs_clean_rerun_or_gate_review")
    ternary_status(allPass, "pass_mode_specific_forward_feasibility", ...
        "pending_clean_artifact_freeze")
    "not_run"
    "qualitative_device_level_only"
    "false"
    lookup_status(sourceProvenance, "source_commit_sha", "")
    "phase13_predictive_RT_forward_model"
    ];
note = [
    "Mode-specific Raman forward feasibility artifacts generated."
    "Phase 12C closes only after clean provenance and all gates pass."
    "No defensible device-to-model transform exists."
    "Predictions are relative mode-response context only."
    "Raman predictions are not passed to transport."
    "Source commit used to generate Phase 12C artifacts."
    "Future phase may predeclare mechanical-to-transport constitutive reduction."
    ];
handoff = table(item, status, note);
end

function row = empty_prior_row()
row = struct('mode_id', "", 'component_id', "", ...
    'coefficient_prior_center', NaN, ...
    'coefficient_prior_half_width', NaN, ...
    'coefficient_prior_min', NaN, ...
    'coefficient_prior_max', NaN, ...
    'expected_sign_policy', "", 'source_class', "", ...
    'fit_status', "", 'shared_across_devices', false);
end

function row = empty_nonstrain_row()
row = struct('mode_id', "", 'nonstrain_term', "", ...
    'separable_in_phase12C', false, 'uncertainty_role', "", ...
    'absorbed_into_strain', false, 'note', "");
end

function row = empty_prediction_row()
row = struct('device', "", 'mode_id', "", 'prediction_scope', "", ...
    'predicted_response_nominal', NaN, 'predicted_response_min', NaN, ...
    'predicted_response_max', NaN, 'predicted_sign', "", ...
    'dominant_mechanical_context', "", ...
    'nonstrain_uncertainty_retained', false, ...
    'registered_spatial_comparison', "", ...
    'transport_coupling_performed', false);
end

function row = empty_registered_row()
row = struct('device', "", 'quantitative_registered_comparison', "", ...
    'registration_status', "", 'transform_type', "", 'reason', "", ...
    'spatial_residuals_computed', false, ...
    'mode_coefficients_fit_to_device', false, ...
    'transport_coupling_performed', false);
end

function row = empty_uncertainty_row()
row = struct('device', "", 'mode_id', "", 'nominal_response', NaN, ...
    'uncertainty_half_range', NaN, 'sign_stable', false, ...
    'confidence_class', "");
end

function [nominal, width, signPolicy] = response_prior(mode, component)
mode = string(mode);
component = string(component);
nominal = 0;
width = 0.20;
if mode == "A1g_like"
    switch component
        case "coverage_transfer"
            nominal = 0.35; width = 0.15; signPolicy = "positive_prior";
        case "boundary_gradient"
            nominal = 0.25; width = 0.20; signPolicy = "positive_prior";
        case "crack_relaxation"
            nominal = 0.45; width = 0.25; signPolicy = "positive_prior";
        otherwise
            nominal = 0.15; width = 0.20; signPolicy = "weak_or_ambiguous";
    end
elseif mode == "E2g_like"
    switch component
        case "coverage_transfer"
            nominal = -0.30; width = 0.15; signPolicy = "negative_prior";
        case "boundary_gradient"
            nominal = -0.50; width = 0.20; signPolicy = "negative_prior";
        case "crack_relaxation"
            nominal = -0.20; width = 0.25; signPolicy = "negative_prior";
        otherwise
            nominal = 0.05; width = 0.20; signPolicy = "weak_or_ambiguous";
    end
else
    switch component
        case "coverage_transfer"
            nominal = 0.10; width = 0.20; signPolicy = "weak_or_ambiguous";
        case "boundary_gradient"
            nominal = 0.20; width = 0.25; signPolicy = "positive_prior";
        case "crack_relaxation"
            nominal = 0.65; width = 0.30; signPolicy = "positive_prior";
        otherwise
            nominal = 0.35; width = 0.25; signPolicy = "positive_prior";
    end
end
end

function row = row_for_device(T, device)
row = struct();
if isempty(T) || ~any(strcmp(T.Properties.VariableNames, 'device'))
    return;
end
idx = find(string(T.device) == string(device), 1, 'first');
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

function summary = fallback_mechanical_summary(cfg)
device = string(cfg.devices(:));
coverage_transfer_proxy = cfg.phase12B.nominalCoverageAmplitude(:);
boundary_gradient_proxy = cfg.phase12B.nominalBoundaryAmplitude(:);
crack_relaxation_proxy = cfg.phase12B.nominalCrackAmplitude(:);
mechanical_proxy_present = (coverage_transfer_proxy + ...
    boundary_gradient_proxy + crack_relaxation_proxy) > 0;
dominant_mechanical_context = repmat("fallback_context", numel(device), 1);
summary = table(device, coverage_transfer_proxy, boundary_gradient_proxy, ...
    crack_relaxation_proxy, mechanical_proxy_present, ...
    dominant_mechanical_context);
end

function label = sign_label(value)
tol = 1e-12;
if value > tol
    label = "positive";
elseif value < -tol
    label = "negative";
else
    label = "near_zero";
end
end

function tf = sign_stable(lo, hi)
tf = (lo > 0 && hi > 0) || (lo < 0 && hi < 0);
end

function cls = confidence_class(nominal, lo, hi)
width = 0.5 * abs(hi - lo);
if width >= abs(nominal)
    cls = "low_sign_confidence";
elseif width > 0.5 * abs(nominal)
    cls = "moderate_sign_confidence";
else
    cls = "higher_relative_confidence";
end
end

function status = ternary_status(condition, trueValue, falseValue)
if condition
    status = string(trueValue);
else
    status = string(falseValue);
end
end
