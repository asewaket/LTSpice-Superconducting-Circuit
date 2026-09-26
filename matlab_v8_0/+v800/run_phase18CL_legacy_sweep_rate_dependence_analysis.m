function out = run_phase18CL_legacy_sweep_rate_dependence_analysis(cfg)
%RUN_PHASE18CL_LEGACY_SWEEP_RATE_DEPENDENCE_ANALYSIS
% Metadata-only legacy sweep-rate context analysis after Phase 18B-R.

if ~exist(cfg.outputDir, 'dir')
    mkdir(cfg.outputDir);
end

paths = phase18CL_paths(cfg);
sourceProvenance = build_source_provenance(cfg);
inputs = load_inputs(paths);

scanComparabilityLedger = build_scan_comparability_ledger( ...
    inputs.candidateAudit);
rateContextMatrix = build_rate_context_matrix(scanComparabilityLedger, ...
    inputs.legacyRateContext);
confounderAudit = build_confounder_audit(rateContextMatrix);
normalizedCurveMetrics = build_normalized_curve_metrics(rateContextMatrix);
featureSummary = build_feature_summary();
rateSensitivitySummary = build_rate_sensitivity_summary(rateContextMatrix, ...
    confounderAudit);
deviceSummary = build_device_summary(rateContextMatrix, ...
    rateSensitivitySummary);
claimBoundary = build_claim_boundary();
gateSummary = build_gate_summary(inputs.handoffStatus, ...
    scanComparabilityLedger, confounderAudit, deviceSummary, ...
    claimBoundary, sourceProvenance);
handoffStatus = build_handoff_status(deviceSummary, gateSummary);

writetable(scanComparabilityLedger, paths.scanComparabilityLedger);
writetable(rateContextMatrix, paths.rateContextMatrix);
writetable(confounderAudit, paths.confounderAudit);
writetable(normalizedCurveMetrics, paths.normalizedCurveMetrics);
writetable(featureSummary, paths.featureSummary);
writetable(rateSensitivitySummary, paths.rateSensitivitySummary);
writetable(deviceSummary, paths.deviceSummary);
writetable(claimBoundary, paths.claimBoundary);
writetable(gateSummary, paths.gateSummary);
writetable(handoffStatus, paths.handoffStatus);
writetable(sourceProvenance, paths.sourceProvenance);

try
    h = plot_summary(paths, rateContextMatrix, confounderAudit, ...
        deviceSummary, claimBoundary, gateSummary);
catch ME
    warning('v8:phase18CLPlotFailed', ...
        'Phase 18C-L summary plot failed: %s', ME.message);
    h = [];
end

out = struct();
out.config = cfg;
out.inputs = inputs;
out.scanComparabilityLedger = scanComparabilityLedger;
out.rateContextMatrix = rateContextMatrix;
out.confounderAudit = confounderAudit;
out.normalizedCurveMetrics = normalizedCurveMetrics;
out.featureSummary = featureSummary;
out.rateSensitivitySummary = rateSensitivitySummary;
out.deviceSummary = deviceSummary;
out.claimBoundary = claimBoundary;
out.gateSummary = gateSummary;
out.handoffStatus = handoffStatus;
out.sourceProvenance = sourceProvenance;
out.figure = h;
out.paths = paths;
end

function paths = phase18CL_paths(cfg)
outputDir = cfg.outputDir;
paths = struct();
paths.outputDir = outputDir;
paths.phase18BRHandoff = fullfile(outputDir, ...
    'phase18BR_handoff_status.csv');
paths.phase18BRCandidateAudit = fullfile(outputDir, ...
    'phase18BR_candidate_scan_audit.csv');
paths.phase18BRLegacyRateContext = fullfile(outputDir, ...
    'phase18BR_legacy_rate_context.csv');
paths.phase18BRGateSummary = fullfile(outputDir, ...
    'phase18BR_gate_summary.csv');
paths.scanComparabilityLedger = fullfile(outputDir, ...
    'phase18CL_scan_comparability_ledger.csv');
paths.rateContextMatrix = fullfile(outputDir, ...
    'phase18CL_rate_context_matrix.csv');
paths.confounderAudit = fullfile(outputDir, ...
    'phase18CL_confounder_audit.csv');
paths.normalizedCurveMetrics = fullfile(outputDir, ...
    'phase18CL_normalized_curve_metrics.csv');
paths.featureSummary = fullfile(outputDir, ...
    'phase18CL_feature_summary.csv');
paths.rateSensitivitySummary = fullfile(outputDir, ...
    'phase18CL_rate_sensitivity_summary.csv');
paths.deviceSummary = fullfile(outputDir, ...
    'phase18CL_device_summary.csv');
paths.claimBoundary = fullfile(outputDir, ...
    'phase18CL_claim_boundary.csv');
paths.gateSummary = fullfile(outputDir, ...
    'phase18CL_gate_summary.csv');
paths.handoffStatus = fullfile(outputDir, ...
    'phase18CL_handoff_status.csv');
paths.sourceProvenance = fullfile(outputDir, ...
    'phase18CL_source_provenance.csv');
paths.figureBase = fullfile(outputDir, ...
    'phase18CL_legacy_sweep_rate_summary');
paths.figurePng = [paths.figureBase '.png'];
paths.figurePdf = [paths.figureBase '.pdf'];
end

function inputs = load_inputs(paths)
inputs = struct();
inputs.handoffStatus = read_required_table(paths.phase18BRHandoff);
inputs.candidateAudit = read_required_table(paths.phase18BRCandidateAudit);
inputs.legacyRateContext = read_required_table(paths.phase18BRLegacyRateContext);
inputs.phase18BRGateSummary = read_required_table(paths.phase18BRGateSummary);
end

function T = read_required_table(pathValue)
if ~exist(pathValue, 'file')
    error('Required Phase 18C-L input is missing:\n%s', pathValue);
end
T = readtable(pathValue, 'FileType', 'text', 'Delimiter', ',', ...
    'ReadVariableNames', true, 'TextType', 'string', ...
    'VariableNamingRule', 'preserve');
T = repair_auto_header_table(T, pathValue);
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
    "phase18CL_legacy_sweep_rate_dependence_analysis"
    sourceStatus.commit_sha
    sourceStatus.tree_sha
    string(sourceStatus.tracked_clean)
    string(sourceStatus.untracked_clean)
    string(sourceStatus.tracked_clean && sourceStatus.untracked_clean)
    "legacy_programmed_rate_context_analysis"
    "Commit source first; rerun from clean source; commit generated artifacts separately."
    ];
note = [
    "Legacy-only readout of programmed/inferred sweep-rate context."
    "Git commit captured before this runner writes outputs."
    "Git tree captured before this runner writes outputs."
    "Tracked-source cleanliness before output generation."
    "Untracked-source/artifact cleanliness before output generation."
    "True only when tracked and untracked source state are clean before output generation."
    "This phase does not reconstruct branches, fit a model, or execute a solver."
    "Output artifacts may dirty the checkout after pre-run provenance is captured."
    ];
provenance = table(item, value, note);
end

function ledger = build_scan_comparability_ledger(candidateAudit)
device = string(table_column(candidateAudit, "device", 1));
raw_file_path = string(table_column(candidateAudit, "raw_file_path"));
sha256 = string(table_column(candidateAudit, "sha256"));
nominal_rate_A_per_s = as_double(table_column(candidateAudit, ...
    "inferred_abs_sweep_rate_A_per_s"));
current_min_A = as_double(table_column(candidateAudit, ...
    "inferred_current_min_A"));
current_max_A = as_double(table_column(candidateAudit, ...
    "inferred_current_max_A"));
current_step_A = as_double(table_column(candidateAudit, ...
    "inferred_dI_step_A"));
waittime_s = as_double(table_column(candidateAudit, "waittime_s"));
temperature_K = as_double(table_column(candidateAudit, "temperature_K"));
field_T = as_double(table_column(candidateAudit, "field_T"));
lockin_freq_Hz = as_double(table_column(candidateAudit, "lockin_freq_Hz"));
lockin_vpp_V = as_double(table_column(candidateAudit, "lockin_vpp_V"));
loadR_ohm = as_double(table_column(candidateAudit, "loadR_ohm"));
branch_metadata_status = string(table_column(candidateAudit, ...
    "branch_metadata_status"));
phase18B_status = string(table_column(candidateAudit, "phase18B_status"));

scan_id = strings(height(candidateAudit), 1);
if has_table_column(candidateAudit, "scan_id")
    scan_id = string(table_column(candidateAudit, "scan_id"));
end
scan_family = strings(height(candidateAudit), 1);
if has_table_column(candidateAudit, "scan_family")
    scan_family = string(table_column(candidateAudit, "scan_family"));
end

priority_tier = strings(size(device));
for k = 1:numel(device)
    priority_tier(k) = device_priority(device(k));
end

current_range_key = strings(size(device));
for k = 1:numel(device)
    current_range_key(k) = sprintf('%.9g_to_%.9g', ...
        current_min_A(k), current_max_A(k));
end

nominal_rate_source = repmat( ...
    "programmed_inferred_from_rng_npoints_waittime_LoadR", size(device));
nominal_rate_source(~isfinite(nominal_rate_A_per_s)) = ...
    "unavailable";
branch_scope = repmat("single_monotonic_legacy_ramp_only", size(device));
down_branch_inferred = false(size(device));
branch_reconstruction_used = false(size(device));
model_fitting_used = false(size(device));
solver_rerun_used = false(size(device));
metric_status = repmat("metadata_only_curve_metrics_not_computed", ...
    size(device));
comparability_note = repmat( ...
    "Rate comparability decided at device level before any dynamic claim.", ...
    size(device));

ledger = table(device, priority_tier, scan_family, scan_id, ...
    raw_file_path, sha256, nominal_rate_A_per_s, nominal_rate_source, ...
    current_min_A, current_max_A, current_step_A, current_range_key, ...
    waittime_s, temperature_K, field_T, lockin_freq_Hz, lockin_vpp_V, ...
    loadR_ohm, branch_metadata_status, phase18B_status, branch_scope, ...
    down_branch_inferred, branch_reconstruction_used, model_fitting_used, ...
    solver_rerun_used, metric_status, comparability_note);
end

function context = build_rate_context_matrix(ledger, legacyRateContext)
devices = string(table_column(legacyRateContext, "device", 1));
rateFactor = as_double(table_column(legacyRateContext, ...
    "rate_diversity_factor"));
currentRangeVaries = as_logical(table_column(legacyRateContext, ...
    "current_range_varies"));
uniqueRateCount = as_double(table_column(legacyRateContext, ...
    "unique_nominal_rate_count"));
minRate = as_double(table_column(legacyRateContext, ...
    "min_nominal_rate_A_per_s"));
maxRate = as_double(table_column(legacyRateContext, ...
    "max_nominal_rate_A_per_s"));

device = devices;
priority_tier = strings(size(device));
raw_scan_count = zeros(size(device));
unique_current_range_count = zeros(size(device));
unique_waittime_count = zeros(size(device));
rate_comparison_possible = false(size(device));
range_confounding_present = currentRangeVaries;
rate_context_class = strings(size(device));

ledgerDevice = ledger.device;
for k = 1:numel(device)
    rows = ledgerDevice == device(k);
    priority_tier(k) = device_priority(device(k));
    raw_scan_count(k) = sum(rows);
    unique_current_range_count(k) = numel(unique(ledger.current_range_key(rows)));
    unique_waittime_count(k) = numel(unique(ledger.waittime_s(rows)));
    rate_comparison_possible(k) = uniqueRateCount(k) > 1;
    if uniqueRateCount(k) <= 1
        rate_context_class(k) = "not_comparable_single_nominal_rate";
    elseif device(k) == "AS005"
        rate_context_class(k) = "supplemental_rate_context_only";
    elseif range_confounding_present(k) && ...
            unique_current_range_count(k) >= uniqueRateCount(k)
        rate_context_class(k) = "rate_strongly_confounded";
    elseif range_confounding_present(k)
        rate_context_class(k) = "rate_partially_confounded";
    else
        rate_context_class(k) = "rate_isolated_metadata_only";
    end
end

context = table(device, priority_tier, raw_scan_count, ...
    uniqueRateCount, minRate, maxRate, rateFactor, ...
    unique_current_range_count, unique_waittime_count, ...
    range_confounding_present, rate_comparison_possible, ...
    rate_context_class);
context.Properties.VariableNames = {'device', 'priority_tier', ...
    'raw_scan_count', 'unique_nominal_rate_count', ...
    'min_nominal_rate_A_per_s', 'max_nominal_rate_A_per_s', ...
    'rate_diversity_factor', 'unique_current_range_count', ...
    'unique_waittime_count', 'range_confounding_present', ...
    'rate_comparison_possible', 'rate_context_class'};
end

function audit = build_confounder_audit(rateContext)
device = rateContext.device;
priority_tier = rateContext.priority_tier;
rate_context_class = rateContext.rate_context_class;
rate_diversity_factor = rateContext.rate_diversity_factor;
range_confounding_present = rateContext.range_confounding_present;
range_confounding_assessed = true(size(device));
temperature_metadata_complete = false(size(device));
field_metadata_complete = false(size(device));
lockin_time_constant_available = false(size(device));
preamp_gain_available = false(size(device));
run_order_available = false(size(device));
confounder_status = strings(size(device));
for k = 1:numel(device)
    if contains(rate_context_class(k), "single")
        confounder_status(k) = "not_testable_single_rate";
    elseif contains(rate_context_class(k), "supplemental")
        confounder_status(k) = "supplemental_not_canonical";
    elseif contains(rate_context_class(k), "confounded")
        confounder_status(k) = rate_context_class(k);
    else
        confounder_status(k) = "metadata_only_rate_context_no_curve_claim";
    end
end
note = repmat( ...
    "Legacy metadata do not support hysteresis or retrapping inference.", ...
    size(device));
audit = table(device, priority_tier, rate_diversity_factor, ...
    range_confounding_present, range_confounding_assessed, ...
    temperature_metadata_complete, field_metadata_complete, ...
    lockin_time_constant_available, preamp_gain_available, ...
    run_order_available, confounder_status, note);
end

function metrics = build_normalized_curve_metrics(rateContext)
device = rateContext.device;
priority_tier = rateContext.priority_tier;
low_rate_A_per_s = rateContext.min_nominal_rate_A_per_s;
high_rate_A_per_s = rateContext.max_nominal_rate_A_per_s;
rate_diversity_factor = rateContext.rate_diversity_factor;
curve_metric_available = false(size(device));
normalized_curve_distance = nan(size(device));
feature_current_shift = nan(size(device));
transition_width_shift = nan(size(device));
low_current_dVdI_shift = nan(size(device));
peak_position_shift = nan(size(device));
metric_status = repmat("not_computed_metadata_only_legacy_audit", ...
    size(device));
reason = repmat( ...
    "Legacy recovery captured programmed-rate metadata, not branch-locked comparable curve pairs.", ...
    size(device));
metrics = table(device, priority_tier, low_rate_A_per_s, ...
    high_rate_A_per_s, rate_diversity_factor, curve_metric_available, ...
    normalized_curve_distance, feature_current_shift, ...
    transition_width_shift, low_current_dVdI_shift, peak_position_shift, ...
    metric_status, reason);
end

function summary = build_feature_summary()
feature_name = [
    "I_feature"
    "transition_width"
    "low_current_dVdI"
    "peak_position"
    "peak_amplitude"
    "normalized_curve_distance"
    ];
computed = false(size(feature_name));
blocked_reason = repmat( ...
    "Not computed in 18C-L because legacy scans lack bidirectional branch lock and comparable curve-pair protocol.", ...
    size(feature_name));
allowed_future_use = repmat( ...
    "Allowed only after canonical raw sweep-rate data lock or a declared legacy curve-loader extension.", ...
    size(feature_name));
summary = table(feature_name, computed, blocked_reason, allowed_future_use);
end

function summary = build_rate_sensitivity_summary(rateContext, confounderAudit)
device = rateContext.device;
priority_tier = rateContext.priority_tier;
rate_diversity_factor = rateContext.rate_diversity_factor;
comparability_class = rateContext.rate_context_class;
S_log_rate = nan(size(device));
rate_sensitivity_computed = false(size(device));
legacy_rate_dependence = strings(size(device));
for k = 1:numel(device)
    if device(k) == "AS005"
        legacy_rate_dependence(k) = "supplemental_not_canonical";
    elseif contains(comparability_class(k), "single")
        legacy_rate_dependence(k) = "not_testable_single_rate";
    elseif any(confounderAudit.device == device(k) & ...
            contains(confounderAudit.confounder_status, "confounded"))
        legacy_rate_dependence(k) = "confounded";
    else
        legacy_rate_dependence(k) = "not_detected_metadata_only";
    end
end
claim_strength = repmat("context_only", size(device));
claim_strength(legacy_rate_dependence == "confounded") = ...
    "rate_context_confounded";
claim_strength(device == "AS006") = "primary_confounded_context";
summary = table(device, priority_tier, rate_diversity_factor, ...
    comparability_class, rate_sensitivity_computed, S_log_rate, ...
    legacy_rate_dependence, claim_strength);
end

function summary = build_device_summary(rateContext, rateSensitivity)
device = rateContext.device;
priority_tier = rateContext.priority_tier;
rate_diversity_factor = rateContext.rate_diversity_factor;
comparability_class = rateContext.rate_context_class;
legacy_rate_dependence = rateSensitivity.legacy_rate_dependence;
use_in_phase18DL = strings(size(device));
for k = 1:numel(device)
    if device(k) == "AS006"
        use_in_phase18DL(k) = "primary_dynamic_identifiability_context";
    elseif device(k) == "AS004"
        use_in_phase18DL(k) = "secondary_dynamic_identifiability_context";
    elseif device(k) == "AS005"
        use_in_phase18DL(k) = "supplemental_context_only";
    else
        use_in_phase18DL(k) = "single_rate_context_only";
    end
end
device_claim = strings(size(device));
for k = 1:numel(device)
    switch legacy_rate_dependence(k)
        case "confounded"
            device_claim(k) = "legacy_rate_context_present_but_confounded";
        case "supplemental_not_canonical"
            device_claim(k) = "supplemental_legacy_rate_context_not_canonical";
        case "not_testable_single_rate"
            device_claim(k) = "legacy_rate_dependence_not_testable";
        otherwise
            device_claim(k) = "metadata_only_no_rate_dependence_claim";
    end
end
summary = table(device, priority_tier, rate_diversity_factor, ...
    comparability_class, legacy_rate_dependence, device_claim, ...
    use_in_phase18DL);
end

function claims = build_claim_boundary()
claim = [
    "bidirectional_claim"
    "hysteresis_claim"
    "retrapping_claim"
    "thermal_memory_claim"
    "RSJ_dynamics_claim"
    "dynamic_microscopic_origin_claim"
    "legacy_rate_context_claim"
    ];
allowed = [
    false
    false
    false
    false
    false
    false
    true
    ];
scope = [
    "blocked"
    "blocked"
    "blocked"
    "blocked"
    "blocked"
    "blocked"
    "allowed_context_only"
    ];
note = [
    "No down branch or branch-history lock exists in the legacy files."
    "No measured up/down branch pair exists."
    "No retrapping branch is preserved."
    "No thermal memory variable or sweep-history metadata is available."
    "No time-dependent Josephson/RSJ solver is run."
    "Programmed-rate context does not identify microscopic origin."
    "Only programmed/inferred nominal sweep-rate context may be reported."
    ];
claims = table(claim, allowed, scope, note);
end

function gates = build_gate_summary(handoff18BR, ledger, confounderAudit, ...
    deviceSummary, claimBoundary, sourceProvenance)
phase18BRClosure = lookup_handoff(handoff18BR, "phase18BR_closure");
legacyOnly18BR = lookup_handoff(handoff18BR, "legacy_only");
phase18BRConsumed = phase18BRClosure == "pass_legacy_recovery_audit" && ...
    legacyOnly18BR == "true";
legacyOnlyPreserved = all(ledger.branch_scope == ...
    "single_monotonic_legacy_ramp_only");
noBranchReconstruction = ~any(ledger.branch_reconstruction_used);
noDownBranchInference = ~any(ledger.down_branch_inferred);
noModelFitting = ~any(ledger.model_fitting_used);
noSolverRerun = ~any(ledger.solver_rerun_used);
nominalRateLabeled = all(ledger.nominal_rate_source == ...
    "programmed_inferred_from_rng_npoints_waittime_LoadR" | ...
    ledger.nominal_rate_source == "unavailable");
rangeConfoundingAssessed = height(confounderAudit) > 0 && ...
    all(confounderAudit.range_confounding_assessed);
as006Rows = deviceSummary.device == "AS006";
as006Prioritized = any(as006Rows & deviceSummary.priority_tier == "primary");
as005SupplementalOnly = all(deviceSummary.priority_tier( ...
    deviceSummary.device == "AS005") == "supplemental");
blockedClaims = ["bidirectional_claim"; "hysteresis_claim"; ...
    "retrapping_claim"; "thermal_memory_claim"; "RSJ_dynamics_claim"];
noForbiddenDynamicClaim = all(~claimBoundary.allowed( ...
    ismember(claimBoundary.claim, blockedClaims)));
sourceClean = lookup_provenance_logical(sourceProvenance, ...
    "source_pre_run_clean");

component = [
    "18B-R consumed unchanged"
    "Legacy-only scope preserved"
    "No branch reconstruction"
    "No down-branch inference"
    "No model fitting"
    "No solver rerun"
    "Nominal rate labeled inferred/programmed"
    "Range confounding explicitly assessed"
    "AS006 prioritized"
    "AS005 supplemental only"
    "No hysteresis/retrapping/thermal-memory claim"
    "Clean provenance"
    ];
pass = [
    phase18BRConsumed
    legacyOnlyPreserved
    noBranchReconstruction
    noDownBranchInference
    noModelFitting
    noSolverRerun
    nominalRateLabeled
    rangeConfoundingAssessed
    as006Prioritized
    as005SupplementalOnly
    noForbiddenDynamicClaim
    sourceClean
    ];
status = strings(size(pass));
status(pass) = "pass";
status(~pass) = "fail";
note = [
    "The Phase 18B-R handoff closes as a legacy recovery audit."
    "Phase 18C-L uses one-direction legacy context only."
    "No curve branch reconstruction is performed."
    "No down branch is inferred from monotonic ramps."
    "No transport or dynamic model parameters are fitted."
    "No solver or current-switching model is rerun."
    "Rates are explicitly labeled as programmed/inferred nominal sweep rates."
    "Each device receives a rate/range confounding classification."
    "AS006 is the primary device because it has the strongest nominal-rate span."
    "AS005 is retained as supplemental context only."
    "Hysteresis, retrapping, thermal memory, and RSJ-dynamic claims remain blocked."
    "Canonical artifact freeze requires a clean pre-run worktree."
    ];
gates = table(component, status, pass, note);
end

function handoff = build_handoff_status(deviceSummary, gateSummary)
scienceComponents = gateSummary.component ~= "Clean provenance";
sciencePass = all(gateSummary.pass(scienceComponents));
allPass = all(gateSummary.pass);
as006 = deviceSummary(deviceSummary.device == "AS006", :);
if isempty(as006)
    as006Claim = "missing";
else
    as006Claim = as006.device_claim(1);
end
item = [
    "phase18CL_scientific_closure"
    "phase18CL_canonical_artifact_freeze"
    "phase18CL_closure"
    "legacy_only"
    "branch_reconstruction_used"
    "down_branch_inferred"
    "model_fitting_used"
    "solver_rerun_used"
    "primary_device"
    "AS006_legacy_rate_claim"
    "AS005_role"
    "bidirectional_claim"
    "hysteresis_claim"
    "retrapping_claim"
    "thermal_memory_claim"
    "RSJ_dynamics_claim"
    "next_phase"
    ];
value = [
    ternary(sciencePass, "pass_legacy_sweep_rate_context_analysis", ...
        "fail_legacy_sweep_rate_context_analysis")
    ternary(allPass, "ready", "pending_clean_provenance")
    ternary(allPass, "pass_legacy_sweep_rate_context_analysis", ...
        "pass_science_pending_clean_artifact_freeze")
    "true"
    "false"
    "false"
    "false"
    "false"
    "AS006"
    as006Claim
    "supplemental_context_only"
    "false"
    "false"
    "false"
    "false"
    "false"
    "phase18DL_legacy_dynamic_identifiability_decision"
    ];
note = [
    "Scientific gates exclude clean provenance and should pass before canonical rerun."
    "Canonical artifact freeze is ready only after clean pre-run provenance."
    "Closure distinguishes scientific success from archival provenance."
    "This is a legacy-only metadata/context phase."
    "No branch reconstruction was performed."
    "No down branch was inferred."
    "No model parameters were fitted."
    "No solver was executed."
    "AS006 has the largest programmed nominal rate span."
    "AS006 context is interpreted with range confounding preserved."
    "AS005 is not promoted to the canonical priority set."
    "Bidirectional claims remain blocked."
    "Hysteresis claims remain blocked."
    "Retrapping claims remain blocked."
    "Thermal-memory claims remain blocked."
    "RSJ or phase-dynamic claims remain blocked."
    "Next decision phase evaluates whether legacy rate context justifies dynamic-model development."
    ];
handoff = table(item, value, note);
end

function h = plot_summary(paths, rateContext, confounderAudit, ...
    deviceSummary, claimBoundary, gateSummary)
h = figure('Name', 'v9 Phase 18C-L legacy sweep-rate context', ...
    'Color', 'w', 'Position', [100 100 1500 900]);
tiledlayout(2, 3, 'Padding', 'compact', 'TileSpacing', 'compact');

nexttile;
bar(categorical(rateContext.device), rateContext.rate_diversity_factor);
title('programmed-rate span');
ylabel('max / min nominal rate');
grid on;
style_light_axes(gca);

nexttile;
bar(categorical(rateContext.device), ...
    double(rateContext.range_confounding_present));
title('range confounding');
ylabel('range varies = 1');
ylim([0 1.2]);
grid on;
style_light_axes(gca);

nexttile;
classes = categorical(confounderAudit.confounder_status);
classCats = categories(classes);
counts = zeros(numel(classCats), 1);
for k = 1:numel(classCats)
    counts(k) = sum(classes == classCats{k});
end
bar(categorical(classCats), counts);
title('comparability classes');
ylabel('device count');
grid on;
style_light_axes(gca);

nexttile;
as006 = rateContext(rateContext.device == "AS006", :);
if ~isempty(as006)
    bar(categorical(["min rate", "max rate"]), ...
        [as006.min_nominal_rate_A_per_s(1), ...
        as006.max_nominal_rate_A_per_s(1)]);
    title('AS006 rate priority');
    ylabel('A/s');
else
    text(0.5, 0.5, 'AS006 missing', 'HorizontalAlignment', 'center');
    title('AS006 rate priority');
end
grid on;
style_light_axes(gca);

nexttile;
blocked = claimBoundary(~claimBoundary.allowed, :);
bar(categorical(blocked.claim), double(~blocked.allowed));
title('blocked dynamic claims');
ylabel('blocked = 1');
ylim([0 1.2]);
grid on;
style_light_axes(gca);

nexttile;
statuses = categorical(gateSummary.status, {'pass', 'fail', 'not_run'});
cats = categories(statuses);
gateCounts = zeros(numel(cats), 1);
for k = 1:numel(cats)
    gateCounts(k) = sum(statuses == cats{k});
end
bar(categorical(cats), gateCounts);
title('Phase 18C-L gates');
ylabel('gate count');
grid on;
style_light_axes(gca);

sgtitle('Phase 18C-L legacy programmed sweep-rate context analysis');
exportgraphics(h, paths.figurePng, 'Resolution', 200);
exportgraphics(h, paths.figurePdf, 'ContentType', 'vector');
end

function priority = device_priority(device)
switch string(device)
    case "AS006"
        priority = "primary";
    case "AS004"
        priority = "secondary";
    case "AS005"
        priority = "supplemental";
    otherwise
        priority = "context";
end
end

function value = lookup_handoff(T, itemName)
item = string(table_column(T, ["item"; "field"; "key"], 1));
valueColumn = string(table_column(T, ["value"; "status"], 2));
idx = normalize_column_name(item) == normalize_column_name(itemName);
if nnz(idx) ~= 1
    error('Expected exactly one %s row in handoff table, found %d.', ...
        itemName, nnz(idx));
end
value = strtrim(valueColumn(idx));
end

function value = lookup_provenance_logical(T, itemName)
item = string(table_column(T, ["item"; "field"; "key"], 1));
valueColumn = string(table_column(T, ["value"; "status"], 2));
idx = normalize_column_name(item) == normalize_column_name(itemName);
if nnz(idx) ~= 1
    value = false;
    return;
end
value = as_logical(valueColumn(idx));
end

function value = table_column(T, candidateNames, fallbackIndex)
if nargin < 3
    fallbackIndex = [];
end
if isempty(T)
    error('Cannot resolve column from an empty table.');
end
varNames = string(T.Properties.VariableNames);
candidateNames = string(candidateNames);
for k = 1:numel(candidateNames)
    exact = find(varNames == candidateNames(k), 1);
    if ~isempty(exact)
        value = T.(char(varNames(exact)));
        return;
    end
end
normVars = normalize_column_name(varNames);
normCandidates = normalize_column_name(candidateNames);
for k = 1:numel(normCandidates)
    matched = find(normVars == normCandidates(k), 1);
    if ~isempty(matched)
        value = T.(char(varNames(matched)));
        return;
    end
end
if ~isempty(fallbackIndex) && fallbackIndex >= 1 && fallbackIndex <= width(T)
    value = T.(char(varNames(fallbackIndex)));
    return;
end
error('Could not resolve required table column: %s. Present columns: %s', ...
    strjoin(candidateNames, "|"), strjoin(varNames, ", "));
end

function tf = has_table_column(T, candidateName)
varNames = string(T.Properties.VariableNames);
tf = any(normalize_column_name(varNames) == ...
    normalize_column_name(candidateName));
end

function normalized = normalize_column_name(names)
normalized = lower(regexprep(string(names), '[^A-Za-z0-9]', ''));
end

function T = repair_auto_header_table(T, pathValue)
varNames = string(T.Properties.VariableNames);
isAutoName = ~cellfun('isempty', regexp(cellstr(varNames), '^Var\d+$', 'once'));
if ~all(isAutoName)
    return;
end

headerNames = read_csv_header(pathValue);
if numel(headerNames) ~= width(T)
    error('CSV header repair failed for %s: found %d headers for %d table columns.', ...
        pathValue, numel(headerNames), width(T));
end

validNames = matlab.lang.makeValidName(cellstr(headerNames));
validNames = matlab.lang.makeUniqueStrings(validNames);

dropFirstRow = false;
if height(T) > 0
    firstRow = strings(1, width(T));
    for k = 1:width(T)
        firstRow(k) = first_table_value_as_string(T{1, k});
    end
    dropFirstRow = all(normalize_column_name(firstRow) == ...
        normalize_column_name(headerNames));
end

T.Properties.VariableNames = validNames;
if dropFirstRow
    T(1, :) = [];
end
end

function headerNames = read_csv_header(pathValue)
fid = fopen(pathValue, 'r');
if fid < 0
    error('Could not open CSV file for header repair: %s', pathValue);
end
cleanup = onCleanup(@() fclose(fid));
line = fgetl(fid);
if ~ischar(line)
    error('Could not read CSV header from: %s', pathValue);
end
headerNames = string(strsplit(line, ','));
headerNames = strip(headerNames);
if ~isempty(headerNames)
    headerNames(1) = erase(headerNames(1), char(65279));
end
end

function value = first_table_value_as_string(rawValue)
if iscell(rawValue)
    if isempty(rawValue)
        value = "";
    else
        value = string(rawValue{1});
    end
elseif isstring(rawValue)
    if isempty(rawValue)
        value = "";
    else
        value = rawValue(1);
    end
elseif ischar(rawValue)
    value = string(rawValue);
elseif isnumeric(rawValue) || islogical(rawValue)
    if isempty(rawValue)
        value = "";
    else
        value = string(rawValue(1));
    end
else
    value = string(rawValue);
end
end

function x = as_double(value)
if isnumeric(value)
    x = double(value);
elseif iscell(value)
    x = str2double(string(value));
else
    x = str2double(string(value));
end
end

function x = as_logical(value)
if islogical(value)
    x = value;
elseif isnumeric(value)
    x = value ~= 0;
else
    s = lower(strtrim(string(value)));
    x = s == "true" | s == "1" | s == "yes" | s == "pass";
end
end

function value = ternary(condition, trueValue, falseValue)
if condition
    value = string(trueValue);
else
    value = string(falseValue);
end
end

function style_light_axes(ax)
set(ax, 'Color', 'w', 'XColor', 'k', 'YColor', 'k', ...
    'GridColor', [0.75 0.75 0.75], ...
    'MinorGridColor', [0.85 0.85 0.85]);
ax.Title.Color = 'k';
ax.XLabel.Color = 'k';
ax.YLabel.Color = 'k';
cb = findall(ancestor(ax, 'figure'), 'Type', 'ColorBar');
for k = 1:numel(cb)
    cb(k).Color = 'k';
end
end
