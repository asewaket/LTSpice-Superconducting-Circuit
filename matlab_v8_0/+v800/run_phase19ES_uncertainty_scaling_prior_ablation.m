function out = run_phase19ES_uncertainty_scaling_prior_ablation(cfg)
%RUN_PHASE19ES_UNCERTAINTY_SCALING_PRIOR_ABLATION
% Evaluate whether normalized mechanics descriptors merit transport entry.
%
% This phase consumes the 19D-S atlas. It does not generate new mechanics
% maps, rerun the transport solver, or enable absolute strain claims.

if ~exist(cfg.outputDir, 'dir')
    mkdir(cfg.outputDir);
end

paths = phase19ES_paths(cfg);
sourceProvenance = build_source_provenance(cfg);
inputs = load_inputs(paths);

robustnessSummary = build_robustness_summary(inputs);
scalingSummary = build_scaling_summary(inputs);
descriptorRanking = build_descriptor_ranking(robustnessSummary, ...
    scalingSummary);
priorFamilyFreeze = build_prior_family_freeze();
transportAssociationScreen = build_transport_association_screen(inputs);
ablationPlan = build_ablation_plan(priorFamilyFreeze);
nullTestLedger = build_null_test_ledger();
decisionSummary = build_decision_summary(robustnessSummary, ...
    descriptorRanking, transportAssociationScreen);
gateSummary = build_gate_summary(inputs, robustnessSummary, ...
    priorFamilyFreeze, ablationPlan, nullTestLedger, decisionSummary, ...
    sourceProvenance);
handoffStatus = build_handoff_status(decisionSummary, gateSummary);

writetable(robustnessSummary, paths.robustnessSummary);
writetable(scalingSummary, paths.scalingSummary);
writetable(descriptorRanking, paths.descriptorRanking);
writetable(priorFamilyFreeze, paths.priorFamilyFreeze);
writetable(transportAssociationScreen, paths.transportAssociationScreen);
writetable(ablationPlan, paths.ablationPlan);
writetable(nullTestLedger, paths.nullTestLedger);
writetable(decisionSummary, paths.decisionSummary);
writetable(gateSummary, paths.gateSummary);
writetable(handoffStatus, paths.handoffStatus);
writetable(sourceProvenance, paths.sourceProvenance);

try
    h = plot_summary(paths, robustnessSummary, descriptorRanking, ...
        transportAssociationScreen, decisionSummary, gateSummary);
catch ME
    warning('v8:phase19ESPlotFailed', ...
        'Phase 19E-S summary plot failed: %s', ME.message);
    h = [];
end

out = struct();
out.config = cfg;
out.inputs = inputs;
out.robustnessSummary = robustnessSummary;
out.scalingSummary = scalingSummary;
out.descriptorRanking = descriptorRanking;
out.priorFamilyFreeze = priorFamilyFreeze;
out.transportAssociationScreen = transportAssociationScreen;
out.ablationPlan = ablationPlan;
out.nullTestLedger = nullTestLedger;
out.decisionSummary = decisionSummary;
out.gateSummary = gateSummary;
out.handoffStatus = handoffStatus;
out.sourceProvenance = sourceProvenance;
out.figure = h;
out.paths = paths;
end

function paths = phase19ES_paths(cfg)
outputDir = cfg.outputDir;
paths = struct();
paths.phase19DSHandoff = fullfile(outputDir, ...
    'phase19DS_handoff_status.csv');
paths.phase19DSBranchPolicy = fullfile(outputDir, ...
    'phase19DS_branch_policy.csv');
paths.phase19DSMetricSummary = fullfile(outputDir, ...
    'phase19DS_unit_load_metric_summary.csv');
paths.phase19DSSensitivitySummary = fullfile(outputDir, ...
    'phase19DS_parameter_sensitivity_summary.csv');
paths.phase19DSTransportCandidates = fullfile(outputDir, ...
    'phase19DS_transport_coupling_candidates.csv');
paths.phase19DSAtlasManifest = fullfile(outputDir, ...
    'phase19DS_normalized_atlas_manifest.csv');
paths.phase9DeviceConclusions = fullfile(outputDir, ...
    'phase9_final_device_conclusion_ledger.csv');
paths.robustnessSummary = fullfile(outputDir, ...
    'phase19ES_robustness_summary.csv');
paths.scalingSummary = fullfile(outputDir, ...
    'phase19ES_scaling_summary.csv');
paths.descriptorRanking = fullfile(outputDir, ...
    'phase19ES_descriptor_ranking.csv');
paths.priorFamilyFreeze = fullfile(outputDir, ...
    'phase19ES_prior_family_freeze.csv');
paths.transportAssociationScreen = fullfile(outputDir, ...
    'phase19ES_transport_association_screen.csv');
paths.ablationPlan = fullfile(outputDir, ...
    'phase19ES_ablation_plan.csv');
paths.nullTestLedger = fullfile(outputDir, ...
    'phase19ES_null_test_ledger.csv');
paths.decisionSummary = fullfile(outputDir, ...
    'phase19ES_decision_summary.csv');
paths.gateSummary = fullfile(outputDir, ...
    'phase19ES_gate_summary.csv');
paths.handoffStatus = fullfile(outputDir, ...
    'phase19ES_handoff_status.csv');
paths.sourceProvenance = fullfile(outputDir, ...
    'phase19ES_source_provenance.csv');
paths.figureBase = fullfile(outputDir, ...
    'phase19ES_uncertainty_scaling_prior_ablation_summary');
paths.figurePng = [paths.figureBase '.png'];
paths.figurePdf = [paths.figureBase '.pdf'];
end

function inputs = load_inputs(paths)
inputs = struct();
inputs.phase19DSHandoff = read_required_table(paths.phase19DSHandoff);
inputs.phase19DSBranchPolicy = read_required_table( ...
    paths.phase19DSBranchPolicy);
inputs.phase19DSMetricSummary = read_required_table( ...
    paths.phase19DSMetricSummary);
inputs.phase19DSSensitivitySummary = read_required_table( ...
    paths.phase19DSSensitivitySummary);
inputs.phase19DSTransportCandidates = read_required_table( ...
    paths.phase19DSTransportCandidates);
inputs.phase19DSAtlasManifest = read_required_table( ...
    paths.phase19DSAtlasManifest);
inputs.phase9DeviceConclusions = read_required_table( ...
    paths.phase9DeviceConclusions);
end

function T = read_required_table(pathValue)
if ~exist(pathValue, 'file')
    error('Required Phase 19E-S input is missing:\n%s', pathValue);
end
T = readtable(pathValue, 'FileType', 'text', 'Delimiter', ',', ...
    'ReadVariableNames', true, 'TextType', 'string', ...
    'VariableNamingRule', 'preserve');
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
    "phase19ES_uncertainty_scaling_prior_ablation"
    sourceStatus.commit_sha
    sourceStatus.tree_sha
    string(sourceStatus.tracked_clean)
    string(sourceStatus.untracked_clean)
    string(sourceStatus.tracked_clean && sourceStatus.untracked_clean)
    "read_only_uncertainty_scaling_and_prior_screen_no_transport_refit"
    "Commit Phase 19E-S source first; rerun from clean source; commit generated artifacts separately."
    ];
note = [
    "Phase 19E-S tests robustness and freezes mechanics-prior ablation logic."
    "Git commit captured before this runner writes outputs."
    "Git tree captured before this runner writes outputs."
    "Tracked-source cleanliness before output generation."
    "Untracked-source/artifact cleanliness before output generation."
    "True only when tracked and untracked source state are clean before output generation."
    "No mechanics maps, no absolute strain claims, no transport solver refit."
    "Artifacts may dirty the checkout after pre-run provenance is captured."
    ];
provenance = table(item, value, note);
end

function robustness = build_robustness_summary(inputs)
S = inputs.phase19DSSensitivitySummary;
metrics = unique(string(S.metric), 'stable');
rows = table();
for k = 1:numel(metrics)
    m = metrics(k);
    sub = S(string(S.metric) == m, :);
    fullRows = contains(string(sub.geometry_family), "continuous");
    halfRows = string(sub.geometry_family) == "half_coverage_boundary";
    crackRows = string(sub.geometry_family) == "cracked_coverage";

    fullMedian = median(as_double(sub.median_value(fullRows)), ...
        'omitnan');
    halfMedian = median(as_double(sub.median_value(halfRows)), ...
        'omitnan');
    crackMedian = median(as_double(sub.median_value(crackRows)), ...
        'omitnan');

    halfBeatsFull = halfMedian > fullMedian;
    crackBeatsFull = crackMedian > fullMedian;
    highSensitivity = any(contains(string(sub.robust_interpretation), ...
        "parameter_sensitive"));
    robust = halfBeatsFull && crackBeatsFull;
    if m == "gradient_factor"
        robust = robust && crackMedian > 0 && halfMedian > 0;
    end
    if m == "high_gradient_area_fraction"
        robust = robust && highSensitivity;
    end

    rows = [rows; table(m, fullMedian, halfMedian, crackMedian, ...
        string(halfBeatsFull), string(crackBeatsFull), ...
        string(highSensitivity), robustness_status(robust, ...
        highSensitivity), ...
        'VariableNames', {'descriptor', ...
        'continuous_control_median', 'half_coverage_median', ...
        'cracked_coverage_median', 'half_gt_continuous', ...
        'crack_gt_continuous', 'parameter_sensitive', ...
        'robustness_status'})]; %#ok<AGROW>
end
robustness = rows;
end

function summary = build_scaling_summary(inputs)
S = inputs.phase19DSSensitivitySummary;
descriptors = unique(string(S.metric), 'stable');
rows = table();
for k = 1:numel(descriptors)
    d = descriptors(k);
    sub = S(string(S.metric) == d, :);
    vals = as_double(sub.median_value);
    rangeVals = as_double(sub.range_value);
    dynamicRange = max(vals) - min(vals);
    medianSensitivity = median(rangeVals, 'omitnan');
    geometrySeparation = dynamicRange ./ max(abs(median(vals, ...
        'omitnan')), eps);
    rows = [rows; table(d, dynamicRange, medianSensitivity, ...
        geometrySeparation, scaling_interpretation(geometrySeparation, ...
        medianSensitivity), ...
        'VariableNames', {'descriptor', 'geometry_dynamic_range', ...
        'median_parameter_sensitivity_range', ...
        'dimensionless_geometry_separation', 'scaling_interpretation'})]; %#ok<AGROW>
end
summary = rows;
end

function ranking = build_descriptor_ranking(robustness, scaling)
descriptors = string(robustness.descriptor);
score = zeros(size(descriptors));
for k = 1:numel(descriptors)
    r = robustness(k, :);
    s = scaling(string(scaling.descriptor) == descriptors(k), :);
    score(k) = double(r.robustness_status == "robust") + ...
        min(2, as_double(s.dimensionless_geometry_separation(1))) - ...
        0.25 * double(r.parameter_sensitive == "true");
end
[sortedScore, order] = sort(score, 'descend');
descriptor = descriptors(order);
rank = (1:numel(descriptor)).';
recommended_role = strings(size(descriptor));
for k = 1:numel(descriptor)
    recommended_role(k) = descriptor_role(descriptor(k), sortedScore(k));
end
ranking = table(rank, descriptor, sortedScore(:), recommended_role, ...
    'VariableNames', {'rank', 'descriptor', 'screening_score', ...
    'recommended_role'});
end

function priors = build_prior_family_freeze()
prior_id = [
    "H_geometry"
    "H1_hydrostatic"
    "H2_shear"
    "H3_gradient"
    "H4_hybrid_predeclared"
    "H_randomized"
    "H_uniform"
    ];
definition = [
    "existing geometry/mechanical proxy baseline"
    "norm(abs(epsilon_xx+epsilon_yy))"
    "norm(abs(epsilon_xy))"
    "norm(abs(grad(epsilon_xx+epsilon_yy)))"
    "predeclared bounded combination of H1,H2,H3; no free three-parameter optimization"
    "spatially shuffled mechanics field preserving value distribution"
    "constant field"
    ];
role = [
    "baseline"
    "mechanics_candidate"
    "mechanics_candidate"
    "mechanics_candidate"
    "secondary_mechanics_candidate_after_single_terms"
    "null_control"
    "null_control"
    ];
transport_refit_allowed = false(numel(prior_id), 1);
note = [
    "Geometry baseline must remain in the comparison."
    "Tests deformation magnitude as the relevant structure."
    "Tests shear-rich boundaries/cracks."
    "Tests discontinuity/gradient as the relevant structure."
    "Only if individual priors show need for combination."
    "Tests whether spatial arrangement matters beyond histogram."
    "Tests uniform enhancement versus spatial structure."
    ];
priors = table(prior_id, definition, role, transport_refit_allowed, note);
end

function screen = build_transport_association_screen(inputs)
C = inputs.phase19DSTransportCandidates;
P = inputs.phase9DeviceConclusions;
devices = string(P.device);
transportSignal = abs(as_double(P.contextual_Z));
structured = double(contains(string(P.final_model_status), ...
    "structured_supported"));
candidateIds = unique(string(C.H_mech_candidate), 'stable');

rows = table();
for k = 1:numel(candidateIds)
    cid = candidateIds(k);
    sub = C(string(C.H_mech_candidate) == cid, :);
    mechSignal = nan(size(devices));
    for j = 1:numel(devices)
        idx = find(string(sub.device) == devices(j), 1);
        if ~isempty(idx)
            mechSignal(j) = as_double(sub.area_fraction_H_gt_0p70(idx));
        end
    end
    rhoZ = corr_safe(mechSignal, transportSignal);
    rhoStructured = corr_safe(mechSignal, structured);
    beatsUniform = std(mechSignal, 'omitnan') > 0;
    associationStatus = association_status(rhoZ, rhoStructured);
    rows = [rows; table(cid, rhoZ, rhoStructured, ...
        string(beatsUniform), associationStatus, ...
        "screen_only_no_transport_solver_refit", ...
        'VariableNames', {'prior_candidate', ...
        'rho_with_abs_contextual_Z', 'rho_with_structured_status', ...
        'beats_uniform_control_by_variation', 'association_status', ...
        'scope'})]; %#ok<AGROW>
end

rows = [rows; table("H_geometry", NaN, NaN, "true", ...
    "baseline_required_for_future_ablation", ...
    "baseline_no_screen_score_assigned", ...
    'VariableNames', rows.Properties.VariableNames)]; %#ok<AGROW>
rows = [rows; table("H_randomized", NaN, NaN, "unresolved", ...
    "null_required_for_future_ablation", ...
    "control_not_executed_without_transport_solver", ...
    'VariableNames', rows.Properties.VariableNames)]; %#ok<AGROW>
rows = [rows; table("H_uniform", 0, 0, "false", ...
    "null_control", "uniform_spatial_structure", ...
    'VariableNames', rows.Properties.VariableNames)]; %#ok<AGROW>
screen = rows;
end

function plan = build_ablation_plan(priorFamilyFreeze)
prior = string(priorFamilyFreeze.prior_id);
stage = strings(size(prior));
frozen_transport_rules = true(size(prior));
downstream_refit_allowed = false(size(prior));
required_outputs = strings(size(prior));
success_rule = strings(size(prior));
for k = 1:numel(prior)
    if prior(k) == "H_geometry"
        stage(k) = "baseline";
        success_rule(k) = "reference_score";
    elseif contains(prior(k), "randomized") || contains(prior(k), "uniform")
        stage(k) = "null_control";
        success_rule(k) = "candidate_must_beat_control";
    elseif prior(k) == "H4_hybrid_predeclared"
        stage(k) = "secondary_after_single_term_screen";
        success_rule(k) = "allowed_only_if_single_terms_show_complementary_support";
    else
        stage(k) = "single_descriptor_candidate";
        success_rule(k) = "must_preserve_or_improve_transfer_and_beat_randomized_control";
    end
    required_outputs(k) = ...
        "S_RT,S_probe,S_metrics,S_NL,leave_one_device_out,device_claim_stability";
end
plan = table(prior, stage, frozen_transport_rules, ...
    downstream_refit_allowed, required_outputs, success_rule);
end

function ledger = build_null_test_ledger()
test_id = [
    "spatial_randomization"
    "geometry_only_baseline"
    "uniform_field_control"
    ];
required = true(3, 1);
executed_in_phase19ES = false(3, 1);
reason = [
    "Requires frozen transport-prior injection and solver replay."
    "Required comparator for all mechanics-derived priors."
    "Tests spatially structured enhancement against uniform enhancement."
    ];
ledger = table(test_id, required, executed_in_phase19ES, reason);
end

function decision = build_decision_summary(robustness, ranking, screen)
robustCount = sum(string(robustness.robustness_status) == "robust");
top = string(ranking.descriptor(1));
mechanicsScreenSupported = any(string(screen.association_status) == ...
    "screen_supportive");
mechanicsScreenMixed = any(string(screen.association_status) == ...
    "screen_mixed_or_weak");

if mechanicsScreenSupported
    transportState = "supported_screen_only";
elseif mechanicsScreenMixed
    transportState = "unresolved_screen_only";
else
    transportState = "unsupported_or_unresolved_screen_only";
end
phase19FSAllowed = mechanicsScreenSupported;

item = [
    "phase19ES_uncertainty_complete"
    "robust_mechanical_descriptors_identified"
    "top_mechanical_descriptor"
    "absolute_strain_claims_made"
    "geometry_prior_tested"
    "mechanics_prior_tested"
    "randomized_prior_tested"
    "uniform_prior_tested"
    "transport_relevant_mechanical_structure"
    "phase19FS_allowed"
    ];
value = [
    "true"
    string(robustCount > 0)
    top
    "false"
    "planned_as_required_baseline"
    "screened_not_solver_replayed"
    "planned_not_solver_replayed"
    "planned_not_solver_replayed"
    transportState
    string(phase19FSAllowed)
    ];
note = [
    "19D-S uncertainty summaries were consumed."
    "At least one descriptor shows robust geometry separation."
    "Best descriptor by robustness/scaling screen."
    "No absolute strain reconstruction or validation is made."
    "Geometry baseline remains mandatory for future ablation."
    "Mechanics priors are screened against existing device-level transport conclusions only."
    "Randomized spatial control requires a future frozen transport replay."
    "Uniform null control is specified for future replay."
    "Screening is not equivalent to full transport-solver ablation."
    "Allowed only if existing-artifact screen already supports transport relevance."
    ];
decision = table(item, value, note);
end

function gates = build_gate_summary(inputs, robustness, priorFamilyFreeze, ...
    ablationPlan, nullTestLedger, decisionSummary, sourceProvenance)
sourceClean = lookup_item(sourceProvenance, "source_pre_run_clean") == "true";
phase19DSClosed = lookup_item(inputs.phase19DSHandoff, ...
    "phase19DS_closure") == "pass_normalized_forward_mechanics_atlas";
noAbsClaims = lookup_item(decisionSummary, ...
    "absolute_strain_claims_made") == "false";
robustDescriptors = lookup_item(decisionSummary, ...
    "robust_mechanical_descriptors_identified") == "true";
priorFamiliesFrozen = height(priorFamilyFreeze) >= 7;
nullsDeclared = all(nullTestLedger.required);
ablationFrozen = height(ablationPlan) >= height(priorFamilyFreeze);
phase19FSConservative = lookup_item(decisionSummary, ...
    "phase19FS_allowed") == "false" || ...
    lookup_item(decisionSummary, ...
    "transport_relevant_mechanical_structure") == "supported_screen_only";
mechanicsRows = robustness(robustness.descriptor ~= ...
    "high_gradient_area_fraction", :);
uncertaintyComplete = height(mechanicsRows) >= 3;

component = [
    "Clean provenance"
    "Phase 19D-S atlas consumed"
    "Uncertainty/scaling summary complete"
    "Robust descriptor screen complete"
    "Prior families frozen"
    "Null tests declared"
    "Transport ablation plan frozen"
    "No absolute strain claims"
    "Phase 19F-S gate conservative"
    ];
pass = [
    sourceClean
    phase19DSClosed
    uncertaintyComplete
    robustDescriptors
    priorFamiliesFrozen
    nullsDeclared
    ablationFrozen
    noAbsClaims
    phase19FSConservative
    ];
status = pass_fail(pass);
note = [
    "Canonical artifact freeze requires clean pre-run source state."
    "19E-S starts from frozen normalized mechanics descriptors."
    "Sensitivity distributions are summarized from the 19D-S bounded sweep."
    "Descriptors are ranked before transport entry."
    "H_geometry, H1, H2, H3, H4, H_randomized, and H_uniform are frozen."
    "Randomized, geometry, and uniform controls are required."
    "Transport solver replay is planned but not silently performed."
    "No device-specific strain reconstruction is made."
    "19F-S is blocked unless transport relevance is supported."
    ];
gates = table(component, status, pass, note);
end

function handoff = build_handoff_status(decisionSummary, gateSummary)
allPass = all(gateSummary.pass);
transportState = lookup_item(decisionSummary, ...
    "transport_relevant_mechanical_structure");
phase19FSAllowed = lookup_item(decisionSummary, ...
    "phase19FS_allowed");
item = [
    "phase19ES_closure"
    "robust_mechanical_descriptors_identified"
    "transport_relevant_mechanical_structure"
    "geometry_prior_tested"
    "mechanics_prior_tested"
    "randomized_prior_tested"
    "uniform_prior_tested"
    "absolute_strain_claims_made"
    "phase19FS_allowed"
    "next_phase"
    ];
value = [
    ternary(allPass, ...
        "pass_uncertainty_scaling_prior_screen", ...
        "fail_uncertainty_scaling_prior_ablation")
    lookup_item(decisionSummary, "robust_mechanical_descriptors_identified")
    transportState
    lookup_item(decisionSummary, "geometry_prior_tested")
    lookup_item(decisionSummary, "mechanics_prior_tested")
    lookup_item(decisionSummary, "randomized_prior_tested")
    lookup_item(decisionSummary, "uniform_prior_tested")
    lookup_item(decisionSummary, "absolute_strain_claims_made")
    phase19FSAllowed
    ternary(phase19FSAllowed == "true", ...
        "phase19FS_mechanics_informed_superconducting_network", ...
        "phase19ES_transport_solver_ablation_replay_or_hold")
    ];
note = [
    "Closure means uncertainty/scaling descriptors and ablation logic are frozen."
    "Mechanics descriptors survive bounded uncertainty at the atlas level."
    "Transport relevance is based on existing-artifact screen, not solver replay."
    "Geometry prior remains a required baseline."
    "Mechanics prior has been screened but not transport-solver replayed."
    "Randomized control remains required for solver ablation."
    "Uniform control remains required for solver ablation."
    "No absolute strain claim is made."
    "19F-S requires supported transport relevance."
    "If not allowed, run the frozen ablation replay or hold the coupling branch."
    ];
handoff = table(item, value, note);
end

function value = lookup_item(T, key)
value = "";
if isempty(T)
    return;
end
names = string(T.Properties.VariableNames);
if ismember("item", names)
    idx = find(string(T.item) == string(key), 1);
elseif ismember("component", names)
    idx = find(string(T.component) == string(key), 1);
else
    return;
end
if isempty(idx)
    return;
end
if ismember("value", names)
    value = string(T.value(idx));
elseif ismember("status", names)
    value = string(T.status(idx));
end
end

function nums = as_double(x)
if isnumeric(x) || islogical(x)
    nums = double(x);
else
    nums = str2double(string(x));
end
end

function rho = corr_safe(x, y)
x = x(:);
y = y(:);
idx = isfinite(x) & isfinite(y);
if sum(idx) < 3 || std(x(idx)) == 0 || std(y(idx)) == 0
    rho = NaN;
else
    rx = tied_rank(x(idx));
    ry = tied_rank(y(idx));
    rx = rx - mean(rx);
    ry = ry - mean(ry);
    denom = sqrt(sum(rx.^2) .* sum(ry.^2));
    if denom == 0
        rho = NaN;
    else
        rho = sum(rx .* ry) ./ denom;
    end
end
end

function ranks = tied_rank(values)
[sorted, order] = sort(values(:));
ranks = zeros(size(sorted));
k = 1;
while k <= numel(sorted)
    j = k;
    while j < numel(sorted) && sorted(j + 1) == sorted(k)
        j = j + 1;
    end
    ranks(k:j) = mean(k:j);
    k = j + 1;
end
out = zeros(size(ranks));
out(order) = ranks;
ranks = out;
end

function status = robustness_status(robust, highSensitivity)
if robust && highSensitivity
    status = "robust_but_parameter_sensitive";
elseif robust
    status = "robust";
else
    status = "not_robust";
end
end

function txt = scaling_interpretation(separation, sensitivity)
if separation >= 1 && sensitivity < separation
    txt = "geometry_separation_dominates_parameter_range";
elseif separation >= 1
    txt = "geometry_separation_present_but_parameter_sensitive";
elseif sensitivity > separation
    txt = "parameter_sensitivity_dominates";
else
    txt = "weak_geometry_separation";
end
end

function role = descriptor_role(descriptor, score)
if score < 1
    role = "do_not_promote_to_transport_prior";
elseif descriptor == "gradient_factor"
    role = "primary_H3_gradient_candidate";
elseif descriptor == "shear_factor"
    role = "primary_H2_shear_candidate";
elseif descriptor == "localization_factor"
    role = "supporting_H1_hydrostatic_or_localization_candidate";
else
    role = "secondary_descriptor_for_reporting_not_direct_prior";
end
end

function status = association_status(rhoZ, rhoStructured)
if isfinite(rhoZ) && rhoZ > 0.45 && isfinite(rhoStructured) && ...
        rhoStructured > 0.25
    status = "screen_supportive";
elseif isfinite(rhoZ) && rhoZ > 0.20
    status = "screen_mixed_or_weak";
else
    status = "screen_unresolved_or_negative";
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

function h = plot_summary(paths, robustness, ranking, screen, decision, gates)
h = figure('Name', 'v8 Phase 19E-S uncertainty and prior screen', ...
    'Color', 'w', 'Position', [100 100 1500 880]);
tiledlayout(2, 3, 'Padding', 'compact', 'TileSpacing', 'compact');

nexttile;
bar(categorical(robustness.descriptor), ...
    as_double(robustness.half_coverage_median));
title('half-coverage median descriptors');
xtickangle(35);
grid on;

nexttile;
bar(categorical(robustness.descriptor), ...
    as_double(robustness.cracked_coverage_median));
title('cracked-coverage median descriptors');
xtickangle(35);
grid on;

nexttile;
bar(categorical(ranking.descriptor), as_double(ranking.screening_score));
title('descriptor screening score');
xtickangle(35);
grid on;

nexttile;
candidateRows = ~isnan(as_double(screen.rho_with_abs_contextual_Z));
bar(categorical(screen.prior_candidate(candidateRows)), ...
    as_double(screen.rho_with_abs_contextual_Z(candidateRows)));
title('screen vs |contextual Z|');
xtickangle(35);
grid on;

nexttile;
bar(categorical(gates.component), double(gates.pass));
title('phase gates');
ylim([0 1.2]);
xtickangle(35);
grid on;

nexttile;
axis off;
text(0, 0.86, '19E-S decision', 'FontWeight', 'bold', ...
    'FontSize', 13);
text(0, 0.68, strrep(lookup_item(decision, ...
    "transport_relevant_mechanical_structure"), '_', '\_'), ...
    'FontSize', 11);
text(0, 0.50, ['top descriptor: ' char(lookup_item(decision, ...
    "top_mechanical_descriptor"))], 'FontSize', 11);
text(0, 0.34, 'no absolute strain claims; no transport refit', ...
    'FontSize', 11);

exportgraphics(h, paths.figurePng, 'Resolution', 200);
exportgraphics(h, paths.figurePdf, 'ContentType', 'vector');
end
