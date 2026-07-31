function out = run_phase13B_limiting_case_verification(cfg)
%RUN_PHASE13B_LIMITING_CASE_VERIFICATION Verify Phase 13A limiting behavior.

if ~exist(cfg.outputDir, 'dir')
    mkdir(cfg.outputDir);
end

sourceProvenance = build_source_provenance(cfg);
inputs = load_phase13B_inputs(cfg);
limitingCaseSpecification = build_limiting_case_specification();
syntheticProxyResponse = build_synthetic_proxy_response( ...
    limitingCaseSpecification, inputs.priors);
deviceExpectedBehavior = build_device_expected_behavior( ...
    inputs.mechanicalSummary, inputs.priors);
componentAblationSummary = build_component_ablation_summary( ...
    inputs.mechanicalSummary, inputs.priors);
monotonicityChecks = build_monotonicity_checks(inputs.mechanicalSummary, ...
    inputs.priors, cfg);
calibrationFirewall = build_calibration_firewall(cfg);
gateSummary = build_gate_summary(cfg, inputs, syntheticProxyResponse, ...
    componentAblationSummary, monotonicityChecks, calibrationFirewall, ...
    sourceProvenance);
handoffStatus = build_handoff_status(cfg, gateSummary, sourceProvenance);

writetable(limitingCaseSpecification, ...
    cfg.phase13B.limitingCaseSpecificationFile);
writetable(syntheticProxyResponse, cfg.phase13B.syntheticProxyResponseFile);
writetable(deviceExpectedBehavior, cfg.phase13B.deviceExpectedBehaviorFile);
writetable(componentAblationSummary, ...
    cfg.phase13B.componentAblationSummaryFile);
writetable(monotonicityChecks, cfg.phase13B.monotonicityChecksFile);
writetable(calibrationFirewall, cfg.phase13B.calibrationFirewallFile);
writetable(gateSummary, cfg.phase13B.gateSummaryFile);
writetable(handoffStatus, cfg.phase13B.handoffStatusFile);
writetable(sourceProvenance, cfg.phase13B.sourceProvenanceFile);

try
    h = v800.plot_phase13B_limiting_case_summary(cfg, ...
        syntheticProxyResponse, deviceExpectedBehavior, ...
        componentAblationSummary, monotonicityChecks, calibrationFirewall, ...
        gateSummary);
catch ME
    warning('v8:phase13BPlotFailed', ...
        'Phase 13B limiting-case summary plot failed: %s', ME.message);
    h = [];
end

out = struct();
out.config = cfg;
out.inputs = inputs;
out.limitingCaseSpecification = limitingCaseSpecification;
out.syntheticProxyResponse = syntheticProxyResponse;
out.deviceExpectedBehavior = deviceExpectedBehavior;
out.componentAblationSummary = componentAblationSummary;
out.monotonicityChecks = monotonicityChecks;
out.calibrationFirewall = calibrationFirewall;
out.gateSummary = gateSummary;
out.handoffStatus = handoffStatus;
out.sourceProvenance = sourceProvenance;
out.figure = h;
out.paths = struct();
out.paths.limitingCaseSpecification = ...
    cfg.phase13B.limitingCaseSpecificationFile;
out.paths.syntheticProxyResponse = cfg.phase13B.syntheticProxyResponseFile;
out.paths.deviceExpectedBehavior = cfg.phase13B.deviceExpectedBehaviorFile;
out.paths.componentAblationSummary = ...
    cfg.phase13B.componentAblationSummaryFile;
out.paths.monotonicityChecks = cfg.phase13B.monotonicityChecksFile;
out.paths.calibrationFirewall = cfg.phase13B.calibrationFirewallFile;
out.paths.gateSummary = cfg.phase13B.gateSummaryFile;
out.paths.handoffStatus = cfg.phase13B.handoffStatusFile;
out.paths.sourceProvenance = cfg.phase13B.sourceProvenanceFile;
out.paths.figurePng = [cfg.phase13B.figureBaseFile '.png'];
out.paths.figurePdf = [cfg.phase13B.figureBaseFile '.pdf'];
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
    "phase13B_limiting_case_verification"
    sourceStatus.commit_sha
    sourceStatus.tree_sha
    string(sourceStatus.tracked_clean)
    string(sourceStatus.untracked_clean)
    string(sourceStatus.tracked_clean && sourceStatus.untracked_clean)
    "verify_frozen_constitutive_behavior_before_experimental_fitting"
    "Commit Phase 13B source first; rerun from clean source; commit generated artifacts separately."
    ];
note = [
    "Phase 13B limiting-case and ablation verification."
    "Git commit captured before this runner writes outputs."
    "Git tree object captured before this runner writes outputs."
    "Tracked-source cleanliness before output generation."
    "Untracked-source/artifact cleanliness before output generation."
    "True only when the checkout is clean before this run writes outputs."
    "No experimental residuals, no calibration, no device relabeling."
    "Phase 13B artifacts are downstream of frozen Phase 13A outputs."
    ];
provenance = table(item, value, note);
end

function inputs = load_phase13B_inputs(cfg)
inputs = struct();
inputs.phase13AHandoff = read_optional_table(cfg.phase13A.handoffStatusFile);
inputs.phase13AGates = read_optional_table(cfg.phase13A.gateSummaryFile);
inputs.constitutiveSpec = read_optional_table( ...
    cfg.phase13A.constitutiveModelSpecificationFile);
inputs.parameterRoles = read_optional_table(cfg.phase13A.parameterRoleLedgerFile);
inputs.priors = read_optional_table(cfg.phase13A.globalParameterPriorsFile);
inputs.TcMap = read_optional_table(cfg.phase13A.mechanicalToTcMappingFile);
inputs.WMap = read_optional_table( ...
    cfg.phase13A.mechanicalToConnectivityMappingFile);
inputs.mechanicalSummary = read_optional_table( ...
    cfg.phase12B.deviceMechanicalSummaryFile);
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

function cases = build_limiting_case_specification()
case_id = [
    "all_components_zero"
    "coverage_only_moderate"
    "coverage_only_full"
    "boundary_only_moderate"
    "boundary_only_strong"
    "crack_only_strong"
    "through_thickness_only"
    "full_coverage_no_boundary"
    "half_coverage_boundary"
    "combined_strong_boundary_crack"
    ];
coverage = [0; 0.5; 1.0; 0; 0; 0; 0; 1.0; 0.7; 0.8];
boundary = [0; 0; 0; 0.5; 1.0; 0; 0; 0; 0.8; 0.8];
crack = [0; 0; 0; 0; 0; 1.0; 0; 0; 0; 0.8];
through_thickness = [0; 0; 0; 0; 0; 0; 1.0; 0.4; 0.4; 0.4];
expected_response = [
    "baseline_M0star_proxy"
    "local_Tc_support_increase"
    "strong_local_Tc_support_increase"
    "connectivity_support_increase"
    "strong_connectivity_support_increase"
    "crack_connectivity_support_increase"
    "vertical_Tc_support_increase"
    "coverage_dominated_without_internal_bottleneck"
    "boundary_plus_coverage_intermediate"
    "combined_structured_connectivity"
    ];
experimental_residuals_used = false(numel(case_id), 1);
status = repmat("predeclared_synthetic_case", numel(case_id), 1);
cases = table(case_id, coverage, boundary, crack, through_thickness, ...
    expected_response, experimental_residuals_used, status);
end

function response = build_synthetic_proxy_response(cases, priors)
p = prior_values(priors);
n = height(cases);
local_Tc_drive = zeros(n, 1);
Tc_support_K = zeros(n, 1);
connectivity_drive = zeros(n, 1);
W_support = zeros(n, 1);
response_class = strings(n, 1);
for k = 1:n
    [local_Tc_drive(k), Tc_support_K(k), connectivity_drive(k), ...
        W_support(k)] = evaluate_proxy(cases.coverage(k), ...
        cases.boundary(k), cases.crack(k), cases.through_thickness(k), p);
    response_class(k) = classify_proxy(cases.coverage(k), cases.boundary(k), ...
        cases.crack(k), cases.through_thickness(k), local_Tc_drive(k), ...
        connectivity_drive(k));
end
delta_Tc_vs_zero_K = Tc_support_K - Tc_support_K(1);
delta_W_vs_zero = W_support - W_support(1);
response = table(cases.case_id, local_Tc_drive, Tc_support_K, ...
    delta_Tc_vs_zero_K, connectivity_drive, W_support, delta_W_vs_zero, ...
    response_class, cases.expected_response, ...
    cases.experimental_residuals_used, ...
    'VariableNames', {'case_id', 'local_Tc_drive', 'Tc_support_K', ...
    'delta_Tc_vs_zero_K', 'connectivity_drive', 'W_support', ...
    'delta_W_vs_zero', 'response_class', 'expected_response', ...
    'experimental_residuals_used'});
end

function behavior = build_device_expected_behavior(mechanicalSummary, priors)
p = prior_values(priors);
devices = string(mechanicalSummary.device);
n = numel(devices);
coverage = mechanicalSummary.coverage_transfer_proxy;
boundary = mechanicalSummary.boundary_gradient_proxy;
crack = mechanicalSummary.crack_relaxation_proxy;
through_thickness = 0.4 * ones(n, 1);
local_Tc_drive = zeros(n, 1);
Tc_support_K = zeros(n, 1);
connectivity_drive = zeros(n, 1);
W_support = zeros(n, 1);
frozen_expectation = strings(n, 1);
for k = 1:n
    [local_Tc_drive(k), Tc_support_K(k), connectivity_drive(k), ...
        W_support(k)] = evaluate_proxy(coverage(k), boundary(k), crack(k), ...
        through_thickness(k), p);
    frozen_expectation(k) = expected_device_behavior(devices(k));
end
experimental_residuals_used = false(n, 1);
phase6_labels_used_as_targets = false(n, 1);
behavior = table(devices, coverage, boundary, crack, through_thickness, ...
    local_Tc_drive, Tc_support_K, connectivity_drive, W_support, ...
    frozen_expectation, experimental_residuals_used, ...
    phase6_labels_used_as_targets, ...
    'VariableNames', {'device', 'coverage_proxy', 'boundary_proxy', ...
    'crack_proxy', 'through_thickness_proxy', 'local_Tc_drive', ...
    'Tc_support_K', 'connectivity_drive', 'W_support', ...
    'frozen_expected_behavior', 'experimental_residuals_used', ...
    'phase6_labels_used_as_targets'});
end

function summary = build_component_ablation_summary(mechanicalSummary, priors)
p = prior_values(priors);
devices = string(mechanicalSummary.device);
components = ["coverage"; "boundary"; "crack"];
rows = repmat(empty_ablation_row(), numel(devices) * numel(components), 1);
idx = 0;
for d = 1:numel(devices)
    baseCoverage = mechanicalSummary.coverage_transfer_proxy(d);
    baseBoundary = mechanicalSummary.boundary_gradient_proxy(d);
    baseCrack = mechanicalSummary.crack_relaxation_proxy(d);
    baseThickness = 0.4;
    [~, baseTc, ~, baseW] = evaluate_proxy(baseCoverage, baseBoundary, ...
        baseCrack, baseThickness, p);
    for c = 1:numel(components)
        idx = idx + 1;
        coverage = baseCoverage;
        boundary = baseBoundary;
        crack = baseCrack;
        if components(c) == "coverage"
            coverage = 0;
        elseif components(c) == "boundary"
            boundary = 0;
        else
            crack = 0;
        end
        [~, ablatedTc, ~, ablatedW] = evaluate_proxy(coverage, boundary, ...
            crack, baseThickness, p);
        rows(idx).device = devices(d);
        rows(idx).removed_component = components(c);
        rows(idx).delta_Tc_support_K = baseTc - ablatedTc;
        rows(idx).delta_W_support = baseW - ablatedW;
        rows(idx).interpretation = ablation_interpretation(devices(d), ...
            components(c), baseTc - ablatedTc, baseW - ablatedW);
        rows(idx).experimental_residuals_used = false;
    end
end
summary = struct2table(rows);
end

function checks = build_monotonicity_checks(mechanicalSummary, priors, cfg)
p = prior_values(priors);
grid = [0; 0.1; 0.25; 0.5; 0.75; 1.0];
checks = repmat(empty_check_row(), 5, 1);

tcCoverage = zeros(numel(grid), 1);
for k = 1:numel(grid)
    [~, tcCoverage(k)] = evaluate_proxy(grid(k), 0, 0, 0, p);
end
checks(1) = check_row("coverage_to_Tc", all(diff(tcCoverage) >= -eps), ...
    min(diff(tcCoverage)), "Coverage-only Tc support should not decrease.");

wBoundary = zeros(numel(grid), 1);
for k = 1:numel(grid)
    [~, ~, ~, wBoundary(k)] = evaluate_proxy(0, grid(k), 0, 0, p);
end
checks(2) = check_row("boundary_to_Wij", all(diff(wBoundary) >= -eps), ...
    min(diff(wBoundary)), "Boundary-only connectivity should not decrease.");

wCrack = zeros(numel(grid), 1);
for k = 1:numel(grid)
    [~, ~, ~, wCrack(k)] = evaluate_proxy(0, 0, grid(k), 0, p);
end
checks(3) = check_row("crack_to_Wij", all(diff(wCrack) >= -eps), ...
    min(diff(wCrack)), "Crack-only connectivity should not decrease.");

tcThickness = zeros(numel(grid), 1);
for k = 1:numel(grid)
    [~, tcThickness(k)] = evaluate_proxy(0, 0, 0, grid(k), p);
end
checks(4) = check_row("through_thickness_to_Tc", ...
    all(diff(tcThickness) >= -eps), min(diff(tcThickness)), ...
    "Through-thickness Tc support should not decrease.");

orderedDevices = ["AS002"; "AS004"; "AS006"];
orderedW = zeros(numel(orderedDevices), 1);
for k = 1:numel(orderedDevices)
    row = mechanicalSummary(string(mechanicalSummary.device) == ...
        orderedDevices(k), :);
    [~, ~, ~, orderedW(k)] = evaluate_proxy( ...
        row.coverage_transfer_proxy(1), row.boundary_gradient_proxy(1), ...
        row.crack_relaxation_proxy(1), 0.4, p);
end
checks(5) = check_row("half_coverage_boundary_order_AS002_AS004_AS006", ...
    all(diff(orderedW) > 0), min(diff(orderedW)), ...
    "Increasing half-coverage amplitude should increase W support.");

checkOutcomes = string({checks.outcome}).';
passFraction = mean(checkOutcomes == "pass");
checks(1).required_pass_fraction = cfg.phase13B.minimumMonotonicityPassFraction;
for k = 2:numel(checks)
    checks(k).required_pass_fraction = checks(1).required_pass_fraction;
end
checks(1).observed_pass_fraction = passFraction;
for k = 2:numel(checks)
    checks(k).observed_pass_fraction = passFraction;
end
checks = struct2table(checks);
end

function firewall = build_calibration_firewall(cfg)
item = [
    "experimental_RT_residuals_used"
    "parameter_retuning_performed"
    "transport_labels_changed"
    "phase6_labels_used_as_targets"
    "raman_predictions_used_as_transport_targets"
    "device_specific_mechanism_parameters_added"
    ];
status = [
    string(cfg.phase13B.allowExperimentalResidualUse)
    string(cfg.phase13B.allowParameterRetuning)
    string(cfg.phase13B.allowTransportRelabeling)
    string(cfg.phase13A.allowPhase6LabelsAsTargets)
    string(cfg.phase13A.allowRamanTransportFit)
    string(cfg.phase13A.allowDeviceSpecificMechanismParameters)
    ];
allowed = false(numel(item), 1);
note = [
    "Phase 13B uses synthetic/proxy behavior only."
    "Frozen Phase 13A priors are read without modification."
    "Frozen v8/Phase 6 device conclusions are protected."
    "Interpretive labels cannot train the forward model."
    "Raman remains qualitative independent context."
    "No AS005/AS006 escape hatch is permitted."
    ];
firewall = table(item, status, allowed, note);
end

function gates = build_gate_summary(cfg, inputs, response, ablations, ...
    checks, firewall, sourceProvenance)
phase13APass = lookup_status(inputs.phase13AHandoff, ...
    "phase13A_closure", "") == "pass_constitutive_mapping_freeze";
if ~isempty(inputs.phase13AGates)
    phase13APass = phase13APass && all(string(inputs.phase13AGates.outcome) ...
        == "pass");
end
casesPredeclared = height(response) >= 10 && ...
    all(~response.experimental_residuals_used);
zeroBaseline = response.delta_Tc_vs_zero_K(1) == 0 && ...
    response.delta_W_vs_zero(1) == 0;
localAndConnectivityMove = any(response.delta_Tc_vs_zero_K > 0) && ...
    any(response.delta_W_vs_zero > 0);
monotonicPassFraction = mean(string(checks.outcome) == "pass");
monotonicPass = monotonicPassFraction >= ...
    cfg.phase13B.minimumMonotonicityPassFraction;
as005Crack = ablations(string(ablations.device) == "AS005" & ...
    string(ablations.removed_component) == "crack", :);
as006Boundary = ablations(string(ablations.device) == "AS006" & ...
    string(ablations.removed_component) == "boundary", :);
targetedAblations = ~isempty(as005Crack) && ~isempty(as006Boundary) && ...
    as005Crack.delta_W_support(1) > 0.05 && ...
    as006Boundary.delta_W_support(1) > 0.05;
firewallPass = all(string(firewall.status) == "false");
cleanProvenance = lookup_status(sourceProvenance, ...
    "source_pre_run_clean", "false") == "true";

gate = [
    "Phase 13A freeze consumed unchanged"
    "Limiting cases predeclared"
    "Zero-field baseline preserved"
    "Local Tc and connectivity channels respond"
    "Component monotonicity checks pass"
    "AS005 crack and AS006 boundary ablations active"
    "Calibration firewall intact"
    "No transport relabeling"
    "No experimental residual use"
    "Clean provenance"
    ];
condition = [
    phase13APass
    casesPredeclared
    zeroBaseline
    localAndConnectivityMove
    monotonicPass
    targetedAblations
    firewallPass
    ~cfg.phase13B.allowTransportRelabeling
    ~cfg.phase13B.allowExperimentalResidualUse
    cleanProvenance
    ];
note = [
    "Consumes Phase 13A source/artifacts without changing equations."
    "Required synthetic limiting cases are emitted before Phase 13C."
    "The all-zero case defines the unperturbed proxy baseline."
    "Coverage/thickness and boundary/crack produce separate responses."
    "Frozen mapping is directionally coherent under component sweeps."
    "Required AS005 crack and AS006 boundary removals are nonzero."
    "No residual inspection, Raman fitting, or label training is enabled."
    "Phase 13B cannot change frozen v8/Phase 6 conclusions."
    "Experimental R(T) data are reserved for Phase 13C."
    "True only when the runner starts from a clean checkout."
    ];
outcome = repmat("fail", numel(gate), 1);
outcome(condition) = "pass";
gates = table(gate, outcome, note);
end

function handoff = build_handoff_status(cfg, gates, sourceProvenance)
allPass = all(string(gates.outcome) == "pass");
item = [
    "phase13B_limiting_case_verification"
    "phase13B_closure"
    "experimental_RT_residuals_used"
    "parameter_retuning_performed"
    "transport_relabeling_performed"
    "full_RT_prediction_performed"
    "source_commit_sha"
    "next_phase"
    ];
status = [
    ternary_status(allPass, "pass", "needs_clean_rerun_or_gate_review")
    ternary_status(allPass, "pass_limiting_case_verification", ...
        "pending_clean_artifact_freeze")
    string(cfg.phase13B.allowExperimentalResidualUse)
    string(cfg.phase13B.allowParameterRetuning)
    string(cfg.phase13B.allowTransportRelabeling)
    "false"
    lookup_status(sourceProvenance, "source_commit_sha", "")
    cfg.phase13B.nextPhase
    ];
note = [
    "Frozen constitutive mapping passes synthetic/proxy sanity checks."
    "Phase 13B closes only after clean provenance and all gates pass."
    "Experimental R(T) residuals are reserved for Phase 13C."
    "No Phase 13A parameters are edited during Phase 13B."
    "Frozen device conclusions are unchanged."
    "Phase 13B verifies behavior but does not run full R(T) prediction."
    "Source commit used to generate Phase 13B artifacts."
    "Next step fits shared parameters and predicts held-out R(T)."
    ];
handoff = table(item, status, note);
end

function p = prior_values(priors)
p = struct();
p.beta0 = prior_value(priors, "beta0", 0);
p.beta_cov = prior_value(priors, "beta_cov", 1);
p.beta_z = prior_value(priors, "beta_z", 0.5);
p.beta_boundary_Tc_optional = prior_value(priors, ...
    "beta_boundary_Tc_optional", 0);
p.beta_crack_Tc_optional = prior_value(priors, ...
    "beta_crack_Tc_optional", 0);
p.Tc_base_K = prior_value(priors, "Tc_base_K", 2.5);
p.DeltaTc_max_K = prior_value(priors, "DeltaTc_max_K", 2.0);
p.gamma0 = prior_value(priors, "gamma0", 0);
p.gamma_boundary = prior_value(priors, "gamma_boundary", 1);
p.gamma_crack = prior_value(priors, "gamma_crack", 1);
p.gamma_coverage = prior_value(priors, "gamma_coverage", 0.25);
end

function value = prior_value(priors, parameter, fallback)
value = fallback;
if isempty(priors) || ~any(strcmp(priors.Properties.VariableNames, 'parameter'))
    return;
end
idx = find(string(priors.parameter) == string(parameter), 1, 'first');
if ~isempty(idx)
    value = priors.nominal_value(idx);
end
end

function [tcDrive, tcSupport, wDrive, wSupport] = evaluate_proxy( ...
    coverage, boundary, crack, throughThickness, p)
tcDrive = p.beta0 + p.beta_cov .* coverage + ...
    p.beta_z .* throughThickness + ...
    p.beta_boundary_Tc_optional .* boundary + ...
    p.beta_crack_Tc_optional .* crack;
tcSupport = p.Tc_base_K + p.DeltaTc_max_K .* sigmoid(tcDrive);
wDrive = p.gamma0 + p.gamma_boundary .* boundary + ...
    p.gamma_crack .* crack + p.gamma_coverage .* coverage;
wSupport = sigmoid(wDrive);
end

function y = sigmoid(x)
y = 1 ./ (1 + exp(-x));
end

function label = classify_proxy(coverage, boundary, crack, throughThickness, ...
    tcDrive, wDrive)
if coverage == 0 && boundary == 0 && crack == 0 && throughThickness == 0
    label = "baseline_M0star_proxy";
elseif wDrive > tcDrive
    label = "connectivity_dominated_proxy";
elseif coverage > 0 && boundary == 0 && crack == 0
    label = "local_Tc_dominated_proxy";
elseif throughThickness > 0 && coverage == 0 && boundary == 0 && crack == 0
    label = "vertical_Tc_dominated_proxy";
else
    label = "combined_proxy";
end
end

function label = expected_device_behavior(device)
switch string(device)
    case "AS001"
        label = "near_baseline_transition_response";
    case "AS002"
        label = "weak_boundary_associated_modification";
    case "AS003"
        label = "broad_continuous_coverage_limited_bottlenecking";
    case "AS004"
        label = "intermediate_boundary_associated_modification";
    case "AS005"
        label = "strong_crack_dependent_current_redistribution";
    case "AS006"
        label = "strongest_half_coverage_boundary_response";
    otherwise
        label = "not_predeclared";
end
end

function textValue = ablation_interpretation(device, component, deltaTc, deltaW)
if device == "AS005" && component == "crack"
    textValue = "required_crack_removal_test";
elseif device == "AS006" && component == "boundary"
    textValue = "required_boundary_removal_test";
elseif component == "coverage" && deltaTc > deltaW
    textValue = "mostly_local_Tc_channel";
elseif component == "boundary" || component == "crack"
    textValue = "mostly_connectivity_channel";
else
    textValue = "minor_or_shared_channel";
end
end

function row = empty_ablation_row()
row = struct('device', "", 'removed_component', "", ...
    'delta_Tc_support_K', 0, 'delta_W_support', 0, ...
    'interpretation', "", 'experimental_residuals_used', false);
end

function row = empty_check_row()
row = struct('check_id', "", 'outcome', "fail", ...
    'minimum_increment', 0, 'observed_pass_fraction', 0, ...
    'required_pass_fraction', 0, 'note', "");
end

function row = check_row(checkId, condition, minimumIncrement, note)
row = empty_check_row();
row.check_id = string(checkId);
row.outcome = ternary_status(condition, "pass", "fail");
row.minimum_increment = minimumIncrement;
row.note = string(note);
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

function status = ternary_status(condition, trueValue, falseValue)
if condition
    status = string(trueValue);
else
    status = string(falseValue);
end
end
