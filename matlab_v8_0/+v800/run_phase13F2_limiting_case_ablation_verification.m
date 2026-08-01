function out = run_phase13F2_limiting_case_ablation_verification(cfg)
%RUN_PHASE13F2_LIMITING_CASE_ABLATION_VERIFICATION Verify 13F variants.
%
% Phase 13F.2 is a pre-fit synthetic/limiting-case check. It confirms that
% the four Phase 13F.1 variants have the intended mathematical effects
% before any experimental residual improvement campaign is run.

if ~exist(cfg.outputDir, 'dir')
    mkdir(cfg.outputDir);
end

sourceProvenance = build_source_provenance(cfg);
inputs = load_inputs(cfg);
limitingCases = build_limiting_case_manifest();
variantResponse = build_variant_response_summary(cfg, inputs, limitingCases);
ablationVerification = build_ablation_verification(cfg, variantResponse);
identifiabilityChecks = build_identifiability_checks(cfg, inputs, ...
    ablationVerification, variantResponse);
numericalSanityChecks = build_numerical_sanity_checks(cfg, variantResponse);
calibrationFirewall = build_calibration_firewall(cfg);
gateSummary = build_gate_summary(cfg, inputs, limitingCases, variantResponse, ...
    ablationVerification, identifiabilityChecks, numericalSanityChecks, ...
    calibrationFirewall, sourceProvenance);
handoffStatus = build_handoff_status(cfg, gateSummary, sourceProvenance);

writetable(limitingCases, cfg.phase13F2.limitingCaseManifestFile);
writetable(variantResponse, cfg.phase13F2.variantResponseSummaryFile);
writetable(ablationVerification, cfg.phase13F2.ablationVerificationFile);
writetable(identifiabilityChecks, cfg.phase13F2.identifiabilityChecksFile);
writetable(numericalSanityChecks, cfg.phase13F2.numericalSanityChecksFile);
writetable(calibrationFirewall, cfg.phase13F2.calibrationFirewallFile);
writetable(gateSummary, cfg.phase13F2.gateSummaryFile);
writetable(handoffStatus, cfg.phase13F2.handoffStatusFile);
writetable(sourceProvenance, cfg.phase13F2.sourceProvenanceFile);

try
    h = v800.plot_phase13F2_limiting_case_ablation_summary(cfg, ...
        variantResponse, ablationVerification, identifiabilityChecks, ...
        numericalSanityChecks, calibrationFirewall, gateSummary);
catch ME
    warning('v8:phase13F2PlotFailed', ...
        'Phase 13F.2 summary plot failed: %s', ME.message);
    h = [];
end

out = struct();
out.config = cfg;
out.inputs = inputs;
out.limitingCaseManifest = limitingCases;
out.variantResponseSummary = variantResponse;
out.ablationVerification = ablationVerification;
out.identifiabilityChecks = identifiabilityChecks;
out.numericalSanityChecks = numericalSanityChecks;
out.calibrationFirewall = calibrationFirewall;
out.gateSummary = gateSummary;
out.handoffStatus = handoffStatus;
out.sourceProvenance = sourceProvenance;
out.figure = h;
out.paths = build_paths(cfg);
end

function paths = build_paths(cfg)
paths = struct();
paths.limitingCaseManifest = cfg.phase13F2.limitingCaseManifestFile;
paths.variantResponseSummary = cfg.phase13F2.variantResponseSummaryFile;
paths.ablationVerification = cfg.phase13F2.ablationVerificationFile;
paths.identifiabilityChecks = cfg.phase13F2.identifiabilityChecksFile;
paths.numericalSanityChecks = cfg.phase13F2.numericalSanityChecksFile;
paths.calibrationFirewall = cfg.phase13F2.calibrationFirewallFile;
paths.gateSummary = cfg.phase13F2.gateSummaryFile;
paths.handoffStatus = cfg.phase13F2.handoffStatusFile;
paths.sourceProvenance = cfg.phase13F2.sourceProvenanceFile;
paths.figurePng = [cfg.phase13F2.figureBaseFile '.png'];
paths.figurePdf = [cfg.phase13F2.figureBaseFile '.pdf'];
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
    "phase13F2_limiting_case_ablation_verification"
    sourceStatus.commit_sha
    sourceStatus.tree_sha
    string(sourceStatus.tracked_clean)
    string(sourceStatus.untracked_clean)
    string(sourceStatus.tracked_clean && sourceStatus.untracked_clean)
    "pre_fit_synthetic_verification_before_phase13F3_LODO_execution"
    "Commit Phase 13F.2 source first; rerun from clean source; commit generated artifacts separately."
    ];
note = [
    "Phase 13F.2 limiting cases and ablation verification."
    "Git commit captured before this runner writes outputs."
    "Git tree object captured before this runner writes outputs."
    "Tracked-source cleanliness before output generation."
    "Untracked-source/artifact cleanliness before output generation."
    "True only when checkout is clean before this run writes outputs."
    "No experimental residual scoring, optimizer rerun, or variant retuning."
    "Phase 13F.2 artifacts are downstream of frozen Phase 13F.1 outputs."
    ];
provenance = table(item, value, note);
end

function inputs = load_inputs(cfg)
inputs = struct();
inputs.phase13F1Handoff = read_required_table( ...
    cfg.phase13F.specificationHandoffStatusFile);
inputs.phase13F1Gates = read_required_table( ...
    cfg.phase13F.specificationGateSummaryFile);
inputs.variantManifest = read_required_table(cfg.phase13F.variantManifestFile);
inputs.upgradeSpec = read_required_table( ...
    cfg.phase13F.upgradeModelSpecificationFile);
inputs.parameterRoles = read_required_table( ...
    cfg.phase13F.parameterRoleLedgerFile);
inputs.prohibitedFlexibility = read_required_table( ...
    cfg.phase13F.prohibitedFlexibilityLedgerFile);
inputs.comparisonThresholds = read_required_table( ...
    cfg.phase13F.comparisonThresholdsFile);
end

function T = read_required_table(pathValue)
if ~exist(pathValue, 'file')
    error('Required Phase 13F.2 input is missing: %s', pathValue);
end
try
    T = readtable(pathValue, 'TextType', 'string', ...
        'VariableNamingRule', 'preserve', 'Delimiter', ',');
catch
    T = readtable(pathValue, 'TextType', 'string', 'Delimiter', ',');
end
end

function T = build_limiting_case_manifest()
case_id = [
    "zero_reference"
    "normal_baseline_slope"
    "lowT_residual_shunt"
    "low_transfer_interface"
    "high_transfer_interface"
    "combined_shunt_low_transfer"
    "combined_baseline_high_transfer"
    "near_tie_transfer"
    ];
baseline_level_shift = [0; 0.08; 0; 0; 0; 0.04; 0.08; 0];
baseline_slope = [0; 0.30; 0; 0; 0; 0.10; 0.20; 0];
residual_shunt_fraction = [0; 0; 0.10; 0; 0; 0.08; 0.06; 0];
interface_tau = [1.00; 1.00; 1.00; 0.55; 0.85; 0.55; 0.75; 0.95];
transition_center = [0.50; 0.50; 0.50; 0.50; 0.50; 0.50; 0.50; 0.50];
transition_width = [0.08; 0.08; 0.08; 0.08; 0.08; 0.08; 0.08; 0.08];
expected_active_channel = [
    "none"
    "baseline"
    "residual_shunt"
    "interface_transfer"
    "interface_transfer"
    "residual_shunt_and_interface_transfer"
    "baseline_and_residual_shunt_and_interface_transfer"
    "weak_interface_near_boundary"
    ];
experimental_residuals_used = false(numel(case_id), 1);
status = repmat("predeclared_synthetic_case", numel(case_id), 1);
T = table(case_id, baseline_level_shift, baseline_slope, ...
    residual_shunt_fraction, interface_tau, transition_center, ...
    transition_width, expected_active_channel, experimental_residuals_used, ...
    status);
end

function T = build_variant_response_summary(cfg, inputs, cases)
variants = inputs.variantManifest;
temperatureGrid = cfg.phase13F2.normalizedTemperatureGrid;
nRows = height(variants) * height(cases);
rows = repmat(empty_response_row(), nRows, 1);
idx = 0;
for v = 1:height(variants)
    variantId = string(variants.variant_id(v));
    hasBaseline = logical(variants.baseline_shunt_upgrade(v));
    hasInterface = logical(variants.interface_transfer_upgrade(v));
    for c = 1:height(cases)
        idx = idx + 1;
        curve = synthetic_curve(temperatureGrid, cases(c, :), ...
            hasBaseline, hasInterface);
        rows(idx).variant_id = variantId;
        rows(idx).case_id = string(cases.case_id(c));
        rows(idx).baseline_shunt_upgrade = hasBaseline;
        rows(idx).interface_transfer_upgrade = hasInterface;
        rows(idx).normal_state_mean = mean(curve(temperatureGrid >= 0.85));
        rows(idx).lowT_mean = mean(curve(temperatureGrid <= 0.15));
        rows(idx).transition_midpoint = transition_midpoint( ...
            temperatureGrid, curve);
        rows(idx).curve_min = min(curve);
        rows(idx).curve_max = max(curve);
        rows(idx).curve_span = max(curve) - min(curve);
        rows(idx).effective_tau = effective_tau(cases.interface_tau(c), ...
            hasInterface);
        rows(idx).finite_curve = all(isfinite(curve));
        rows(idx).monotonic_non_decreasing = all(diff(curve) >= -1e-10);
        rows(idx).bounded_0_to_1p5 = min(curve) >= -1e-10 && ...
            max(curve) <= 1.5;
        rows(idx).experimental_residuals_used = false;
    end
end
T = struct2table(rows);
end

function curve = synthetic_curve(t, caseRow, hasBaseline, hasInterface)
tau = effective_tau(caseRow.interface_tau(1), hasInterface);
center = caseRow.transition_center(1) + hasInterface .* (1 - tau) .* 0.16;
width = caseRow.transition_width(1) + hasInterface .* (1 - tau) .* 0.06;
switchCurve = 1 ./ (1 + exp(-(t - center) ./ width));
normalBaseline = ones(size(t));
residualFloor = zeros(size(t));
if hasBaseline
    normalBaseline = normalBaseline + caseRow.baseline_level_shift(1) + ...
        caseRow.baseline_slope(1) .* (t - 0.85);
    residualFloor = caseRow.residual_shunt_fraction(1) .* ones(size(t));
end
curve = residualFloor + (normalBaseline - residualFloor) .* switchCurve;
curve = max(curve, 0);
end

function tau = effective_tau(rawTau, hasInterface)
if hasInterface
    tau = rawTau;
else
    tau = 1;
end
end

function mid = transition_midpoint(t, curve)
lo = min(curve);
hi = max(curve);
target = lo + 0.5 .* (hi - lo);
idx = find(curve >= target, 1, 'first');
if isempty(idx)
    mid = NaN;
else
    mid = t(idx);
end
end

function T = build_ablation_verification(cfg, response)
tests = [
    "F0_zero_reference_reproduced"
    "FB_baseline_channel_active"
    "FB_residual_channel_active"
    "FI_interface_channel_active"
    "FBI_residual_channel_retained"
    "FBI_interface_channel_retained"
    "FBI_no_unintended_cancellation"
    ];
variant_pair = [
    "F0_vs_F0"
    "FB_vs_F0"
    "FB_vs_F0"
    "FI_vs_F0"
    "FBI_vs_FI"
    "FBI_vs_FB"
    "FBI_vs_FB_and_FI"
    ];
case_id = [
    "zero_reference"
    "normal_baseline_slope"
    "lowT_residual_shunt"
    "low_transfer_interface"
    "combined_shunt_low_transfer"
    "combined_shunt_low_transfer"
    "combined_shunt_low_transfer"
    ];
metric = [
    "curve_span"
    "normal_state_mean"
    "lowT_mean"
    "transition_midpoint"
    "lowT_mean"
    "transition_midpoint"
    "composite_response"
    ];
observed_delta = zeros(numel(tests), 1);
threshold = [
    0.50
    cfg.phase13F2.minimumResponseSeparation
    cfg.phase13F2.minimumResponseSeparation
    cfg.phase13F2.minimumResponseSeparation
    cfg.phase13F2.minimumResponseSeparation
    cfg.phase13F2.minimumResponseSeparation
    -cfg.phase13F2.maximumVariantCancellation
    ];
pass = false(numel(tests), 1);

observed_delta(1) = lookup_metric(response, "F0", "zero_reference", ...
    "curve_span");
pass(1) = observed_delta(1) > 0.50;
observed_delta(2) = lookup_metric(response, "FB", "normal_baseline_slope", ...
    "normal_state_mean") - lookup_metric(response, "F0", ...
    "normal_baseline_slope", "normal_state_mean");
pass(2) = observed_delta(2) >= threshold(2);
observed_delta(3) = lookup_metric(response, "FB", "lowT_residual_shunt", ...
    "lowT_mean") - lookup_metric(response, "F0", ...
    "lowT_residual_shunt", "lowT_mean");
pass(3) = observed_delta(3) >= threshold(3);
observed_delta(4) = abs(lookup_metric(response, "FI", ...
    "low_transfer_interface", "transition_midpoint") - ...
    lookup_metric(response, "F0", "low_transfer_interface", ...
    "transition_midpoint"));
pass(4) = observed_delta(4) >= threshold(4);
observed_delta(5) = lookup_metric(response, "FBI", ...
    "combined_shunt_low_transfer", "lowT_mean") - ...
    lookup_metric(response, "FI", "combined_shunt_low_transfer", ...
    "lowT_mean");
pass(5) = observed_delta(5) >= threshold(5);
observed_delta(6) = abs(lookup_metric(response, "FBI", ...
    "combined_shunt_low_transfer", "transition_midpoint") - ...
    lookup_metric(response, "FB", "combined_shunt_low_transfer", ...
    "transition_midpoint"));
pass(6) = observed_delta(6) >= threshold(6);
fbiComposite = composite_metric(response, "FBI", ...
    "combined_shunt_low_transfer");
fbComposite = composite_metric(response, "FB", ...
    "combined_shunt_low_transfer");
fiComposite = composite_metric(response, "FI", ...
    "combined_shunt_low_transfer");
observed_delta(7) = fbiComposite - max(fbComposite, fiComposite);
pass(7) = observed_delta(7) >= threshold(7);

outcome = repmat("fail", numel(tests), 1);
outcome(pass) = "pass";
experimental_residuals_used = false(numel(tests), 1);
T = table(tests, variant_pair, case_id, metric, observed_delta, ...
    threshold, outcome, experimental_residuals_used, ...
    'VariableNames', {'test_id', 'variant_pair', 'case_id', 'metric', ...
    'observed_delta', 'threshold', 'outcome', ...
    'experimental_residuals_used'});
end

function value = lookup_metric(response, variantId, caseId, metricName)
mask = string(response.variant_id) == string(variantId) & ...
    string(response.case_id) == string(caseId);
if ~any(mask)
    value = NaN;
else
    value = response.(char(metricName))(find(mask, 1));
end
end

function value = composite_metric(response, variantId, caseId)
value = lookup_metric(response, variantId, caseId, "lowT_mean") + ...
    abs(lookup_metric(response, variantId, caseId, "transition_midpoint") - ...
    lookup_metric(response, "F0", caseId, "transition_midpoint"));
end

function T = build_identifiability_checks(cfg, inputs, ablations, response)
check_id = [
    "phase13F1_specification_closed"
    "all_four_variants_present"
    "FB_and_FI_are_distinguishable"
    "FBI_not_identical_to_single_upgrade"
    "near_boundary_case_remains_small"
    "no_device_specific_parameters_added"
    ];
condition = false(numel(check_id), 1);
condition(1) = lookup_status(inputs.phase13F1Handoff, ...
    "phase13F1_closure", "") == "pass_upgrade_specification_freeze";
condition(2) = all(ismember(["F0"; "FB"; "FI"; "FBI"], ...
    string(inputs.variantManifest.variant_id)));
fbBaseline = lookup_metric(response, "FB", "normal_baseline_slope", ...
    "normal_state_mean");
fiBaseline = lookup_metric(response, "FI", "normal_baseline_slope", ...
    "normal_state_mean");
fbInterface = lookup_metric(response, "FB", "low_transfer_interface", ...
    "transition_midpoint");
fiInterface = lookup_metric(response, "FI", "low_transfer_interface", ...
    "transition_midpoint");
condition(3) = abs(fbBaseline - fiBaseline) >= ...
    cfg.phase13F2.minimumResponseSeparation && ...
    abs(fbInterface - fiInterface) >= cfg.phase13F2.minimumResponseSeparation;
condition(4) = all(string(ablations.outcome) == "pass");
nearBoundaryShift = abs(lookup_metric(response, "FI", ...
    "near_tie_transfer", "transition_midpoint") - ...
    lookup_metric(response, "F0", "near_tie_transfer", ...
    "transition_midpoint"));
condition(5) = nearBoundaryShift <= 2 .* cfg.phase13F2.minimumResponseSeparation;
condition(6) = all(logical(inputs.prohibitedFlexibility.blocked));
outcome = repmat("fail", numel(check_id), 1);
outcome(condition) = "pass";
note = [
    "Phase 13F.2 consumes a closed Phase 13F.1 specification."
    "F0, FB, FI, and FBI are all required."
    "Baseline/residual and interface channels should be separable."
    "Combined upgrade should not collapse to a single-upgrade response."
    "Weak transfer near the boundary should remain modest."
    "Device-specific mechanism parameters remain blocked."
    ];
T = table(check_id, outcome, note);
end

function T = build_numerical_sanity_checks(cfg, response)
variant_id = string(response.variant_id);
case_id = string(response.case_id);
finite_curve = logical(response.finite_curve);
monotonic_non_decreasing = logical(response.monotonic_non_decreasing);
bounded_0_to_1p5 = logical(response.bounded_0_to_1p5);
curve_span_positive = response.curve_span > 0.05;
outcome = repmat("fail", height(response), 1);
outcome(finite_curve & monotonic_non_decreasing & bounded_0_to_1p5 & ...
    curve_span_positive) = "pass";
minimum_pass_fraction = repmat(cfg.phase13F2.minimumMonotonicPassFraction, ...
    height(response), 1);
experimental_residuals_used = false(height(response), 1);
T = table(variant_id, case_id, finite_curve, monotonic_non_decreasing, ...
    bounded_0_to_1p5, curve_span_positive, outcome, ...
    minimum_pass_fraction, experimental_residuals_used);
end

function firewall = build_calibration_firewall(cfg)
item = [
    "experimental_RT_residuals_used"
    "optimizer_rerun_performed"
    "variant_retuning_performed"
    "device_specific_fitting_performed"
    "transport_relabeling_performed"
    "full_LODO_prediction_performed"
    ];
status = [
    string(cfg.phase13F2.allowExperimentalResidualUse)
    string(cfg.phase13F2.allowOptimizerRerun)
    string(cfg.phase13F2.allowVariantRetuning)
    string(cfg.phase13F2.allowDeviceSpecificFitting)
    string(cfg.phase13F2.allowTransportRelabeling)
    "false"
    ];
allowed = false(numel(item), 1);
note = [
    "Phase 13F.2 uses synthetic limiting cases only."
    "No parameter search is run in Phase 13F.2."
    "F0/FB/FI/FBI definitions are read from Phase 13F.1."
    "No per-device mechanism escape hatch is introduced."
    "Frozen transport/probe labels remain unchanged."
    "Full six-fold R(T) execution is deferred to Phase 13F.3."
    ];
firewall = table(item, status, allowed, note);
end

function gates = build_gate_summary(cfg, inputs, cases, response, ablations, ...
    identifiability, sanity, firewall, sourceProvenance)
phase13F1Pass = lookup_status(inputs.phase13F1Handoff, ...
    "phase13F1_closure", "") == "pass_upgrade_specification_freeze" && ...
    all(string(inputs.phase13F1Gates.outcome) == "pass");
casesPredeclared = height(cases) >= 8 && ...
    all(~logical(cases.experimental_residuals_used));
variantsAllPresent = all(ismember(["F0"; "FB"; "FI"; "FBI"], ...
    unique(string(response.variant_id))));
ablationsPass = mean(string(ablations.outcome) == "pass") >= ...
    cfg.phase13F2.minimumAblationPassFraction;
identifiabilityPass = all(string(identifiability.outcome) == "pass");
sanityPass = mean(string(sanity.outcome) == "pass") >= ...
    cfg.phase13F2.minimumMonotonicPassFraction;
firewallPass = all(string(firewall.status) == "false");
trackedProvenance = lookup_status(sourceProvenance, ...
    "source_pre_run_tracked_clean", "false") == "true";

gate = [
    "Phase 13F.1 specification consumed"
    "Synthetic limiting cases predeclared"
    "Four frozen variants evaluated"
    "Baseline/residual and interface ablations active"
    "Variant identifiability checks pass"
    "Numerical monotonicity and boundedness pass"
    "Calibration firewall intact"
    "No experimental residual use"
    "No full LODO execution in Phase 13F.2"
    "Tracked source provenance captured"
    ];
condition = [
    phase13F1Pass
    casesPredeclared
    variantsAllPresent
    ablationsPass
    identifiabilityPass
    sanityPass
    firewallPass
    ~cfg.phase13F2.allowExperimentalResidualUse
    true
    trackedProvenance
    ];
note = [
    "Phase 13F.2 starts only from the closed Phase 13F.1 specification."
    "Cases are synthetic and declared before 13F.3."
    "F0, FB, FI, and FBI are all tested."
    "Each selected upgrade moves the intended limiting-case channel."
    "Upgrades remain distinguishable before experimental execution."
    "Synthetic R(T) proxy curves stay finite, bounded, and monotonic."
    "No optimizer, residual scoring, retuning, or relabeling is enabled."
    "Experimental residual improvement is reserved for Phase 13F.3."
    "This phase does not claim held-out predictive adequacy."
    "Tracked files were clean at run start; untracked artifacts are recorded separately."
    ];
outcome = repmat("fail", numel(gate), 1);
outcome(condition) = "pass";
gates = table(gate, outcome, note);
end

function handoff = build_handoff_status(cfg, gates, sourceProvenance)
allPass = all(string(gates.outcome) == "pass");
field = [
    "phase13F2_closure"
    "phase13F2_decision"
    "experimental_RT_residuals_used"
    "optimizer_rerun_performed"
    "variant_retuning_performed"
    "source_commit_sha"
    "next_phase"
    ];
value = [
    conditional(allPass, "pass_limiting_case_ablation_verification", ...
        "fail_or_pending_verification_review")
    conditional(allPass, "ready_for_phase13F3_full_LODO_execution", ...
        "do_not_start_phase13F3")
    string(cfg.phase13F2.allowExperimentalResidualUse)
    string(cfg.phase13F2.allowOptimizerRerun)
    string(cfg.phase13F2.allowVariantRetuning)
    lookup_status(sourceProvenance, "source_commit_sha", "")
    cfg.phase13F2.nextPhase
    ];
note = [
    "Closure means variants behave correctly under synthetic limiting cases."
    "Phase 13F.3 may run only after Phase 13F.2 passes."
    "No measured R(T) residuals are inspected in Phase 13F.2."
    "No optimizer is run before the full LODO execution phase."
    "F0/FB/FI/FBI remain frozen after Phase 13F.1."
    "Source commit used to generate Phase 13F.2 artifacts."
    "Next step is the repeated six-fold R(T) prediction campaign."
    ];
handoff = table(field, value, note);
end

function row = empty_response_row()
row = struct('variant_id', "", 'case_id', "", ...
    'baseline_shunt_upgrade', false, 'interface_transfer_upgrade', false, ...
    'normal_state_mean', 0, 'lowT_mean', 0, 'transition_midpoint', 0, ...
    'curve_min', 0, 'curve_max', 0, 'curve_span', 0, ...
    'effective_tau', 1, 'finite_curve', false, ...
    'monotonic_non_decreasing', false, 'bounded_0_to_1p5', false, ...
    'experimental_residuals_used', false);
end

function value = lookup_status(T, itemName, fallback)
value = string(fallback);
if isempty(T)
    return;
end
names = string(T.Properties.VariableNames);
normalized = lower(regexprep(names, '[^A-Za-z0-9]', ''));
fieldIdx = find(normalized == "field" | normalized == "item" | ...
    normalized == "gate", 1);
valueIdx = find(normalized == "value" | normalized == "status" | ...
    normalized == "outcome", 1);
if isempty(fieldIdx) || isempty(valueIdx)
    return;
end
keys = lower(regexprep(strtrim(string(T{:, fieldIdx})), '[^A-Za-z0-9]', ''));
target = lower(regexprep(strtrim(string(itemName)), '[^A-Za-z0-9]', ''));
idx = find(keys == target, 1, 'first');
if ~isempty(idx)
    values = string(T{:, valueIdx});
    value = values(idx);
end
end

function s = conditional(tf, a, b)
if tf
    s = string(a);
else
    s = string(b);
end
end
