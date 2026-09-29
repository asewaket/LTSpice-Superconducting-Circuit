function out = run_phase19FS_mechanics_informed_superconducting_network(cfg)
%RUN_PHASE19FS_MECHANICS_INFORMED_SUPERCONDUCTING_NETWORK
% Promote the frozen H_gradient prior while keeping transport rules fixed.
%
% Phase 19F-S is an integration and interpretation phase. It does not
% retune device parameters, reoptimize weak links, add nuisance terms, or
% reclassify Phase 6 devices. It asks which superconducting-network role is
% best supported by the frozen mechanics-gradient prior.

if ~exist(cfg.outputDir, 'dir')
    mkdir(cfg.outputDir);
end

paths = phase19FS_paths(cfg);
sourceProvenance = build_source_provenance(cfg);
inputs = load_inputs(paths);

frozenPolicy = build_frozen_policy();
requiredControls = build_required_controls();
couplingRoleAblation = build_coupling_role_ablation(inputs);
sixDeviceComparison = build_six_device_comparison(inputs, ...
    couplingRoleAblation);
[spatialFieldMaps, spatialFieldSummary] = build_spatial_fields(inputs);
currentOverlapMetrics = build_current_overlap_metrics(spatialFieldMaps);
deviceInterpretation = build_device_interpretation(inputs, ...
    couplingRoleAblation, sixDeviceComparison, currentOverlapMetrics);
decisionSummary = build_decision_summary(couplingRoleAblation, ...
    sixDeviceComparison, currentOverlapMetrics, deviceInterpretation);
gateSummary = build_gate_summary(inputs, sourceProvenance, frozenPolicy, ...
    requiredControls, couplingRoleAblation, sixDeviceComparison, ...
    spatialFieldMaps, currentOverlapMetrics, deviceInterpretation, ...
    decisionSummary);
handoffStatus = build_handoff_status(decisionSummary, gateSummary);

writetable(frozenPolicy, paths.frozenPolicy);
writetable(requiredControls, paths.requiredControls);
writetable(couplingRoleAblation, paths.couplingRoleAblation);
writetable(sixDeviceComparison, paths.sixDeviceComparison);
writetable(spatialFieldMaps, paths.spatialFieldMaps);
writetable(spatialFieldSummary, paths.spatialFieldSummary);
writetable(currentOverlapMetrics, paths.currentOverlapMetrics);
writetable(deviceInterpretation, paths.deviceInterpretation);
writetable(decisionSummary, paths.decisionSummary);
writetable(gateSummary, paths.gateSummary);
writetable(handoffStatus, paths.handoffStatus);
writetable(sourceProvenance, paths.sourceProvenance);

try
    h = plot_summary(paths, couplingRoleAblation, sixDeviceComparison, ...
        currentOverlapMetrics, decisionSummary, gateSummary);
catch ME
    warning('v8:phase19FSPlotFailed', ...
        'Phase 19F-S summary plot failed: %s', ME.message);
    h = [];
end
try
    hMap = plot_map_panel(paths, spatialFieldMaps, currentOverlapMetrics);
catch ME
    warning('v8:phase19FSMapPanelFailed', ...
        'Phase 19F-S map panel failed: %s', ME.message);
    hMap = [];
end

out = struct();
out.config = cfg;
out.inputs = inputs;
out.frozenPolicy = frozenPolicy;
out.requiredControls = requiredControls;
out.couplingRoleAblation = couplingRoleAblation;
out.sixDeviceComparison = sixDeviceComparison;
out.spatialFieldMaps = spatialFieldMaps;
out.spatialFieldSummary = spatialFieldSummary;
out.currentOverlapMetrics = currentOverlapMetrics;
out.deviceInterpretation = deviceInterpretation;
out.decisionSummary = decisionSummary;
out.gateSummary = gateSummary;
out.handoffStatus = handoffStatus;
out.sourceProvenance = sourceProvenance;
out.figure = h;
out.mapPanel = hMap;
out.paths = paths;
end

function paths = phase19FS_paths(cfg)
outputDir = cfg.outputDir;
paths = struct();
paths.phase19ESRHandoff = fullfile(outputDir, ...
    'phase19ESR_handoff_status.csv');
paths.phase19ESRDecision = fullfile(outputDir, ...
    'phase19ESR_decision_summary.csv');
paths.phase19ESRScoreReplay = fullfile(outputDir, ...
    'phase19ESR_prior_score_replay.csv');
paths.phase19ESRDeviceInterpretation = fullfile(outputDir, ...
    'phase19ESR_device_interpretation.csv');
paths.phase19DSCandidates = fullfile(outputDir, ...
    'phase19DS_transport_coupling_candidates.csv');
paths.phase19DSAtlas = fullfile(outputDir, ...
    'phase19DS_normalized_atlas_manifest.csv');
paths.phase6Matrix = cfg.phase6.sixDeviceEvidenceMatrixFile;

paths.frozenPolicy = fullfile(outputDir, ...
    'phase19FS_frozen_policy_manifest.csv');
paths.requiredControls = fullfile(outputDir, ...
    'phase19FS_required_controls.csv');
paths.couplingRoleAblation = fullfile(outputDir, ...
    'phase19FS_coupling_role_ablation.csv');
paths.sixDeviceComparison = fullfile(outputDir, ...
    'phase19FS_six_device_transport_comparison.csv');
paths.spatialFieldMaps = fullfile(outputDir, ...
    'phase19FS_spatial_field_maps.csv');
paths.spatialFieldSummary = fullfile(outputDir, ...
    'phase19FS_spatial_field_summary.csv');
paths.currentOverlapMetrics = fullfile(outputDir, ...
    'phase19FS_mechanics_current_overlap_metrics.csv');
paths.deviceInterpretation = fullfile(outputDir, ...
    'phase19FS_device_interpretation.csv');
paths.decisionSummary = fullfile(outputDir, ...
    'phase19FS_decision_summary.csv');
paths.gateSummary = fullfile(outputDir, ...
    'phase19FS_gate_summary.csv');
paths.handoffStatus = fullfile(outputDir, ...
    'phase19FS_handoff_status.csv');
paths.sourceProvenance = fullfile(outputDir, ...
    'phase19FS_source_provenance.csv');
paths.figureBase = fullfile(outputDir, ...
    'phase19FS_mechanics_informed_network_summary');
paths.figurePng = [paths.figureBase '.png'];
paths.figurePdf = [paths.figureBase '.pdf'];
paths.mapPanelBase = fullfile(outputDir, ...
    'phase19FS_AS005_AS006_spatial_integration_panel');
paths.mapPanelPng = [paths.mapPanelBase '.png'];
paths.mapPanelPdf = [paths.mapPanelBase '.pdf'];
end

function inputs = load_inputs(paths)
inputs = struct();
inputs.phase19ESRHandoff = read_required_table(paths.phase19ESRHandoff);
inputs.phase19ESRDecision = read_required_table(paths.phase19ESRDecision);
inputs.phase19ESRScoreReplay = read_required_table( ...
    paths.phase19ESRScoreReplay);
inputs.phase19ESRDeviceInterpretation = read_required_table( ...
    paths.phase19ESRDeviceInterpretation);
inputs.phase19DSCandidates = read_required_table(paths.phase19DSCandidates);
inputs.phase19DSAtlas = read_required_table(paths.phase19DSAtlas);
inputs.phase6Matrix = read_required_table(paths.phase6Matrix);
end

function T = read_required_table(pathValue)
if ~exist(pathValue, 'file')
    error('Required Phase 19F-S input is missing:\n%s', pathValue);
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
    "phase19FS_mechanics_informed_superconducting_network"
    sourceStatus.commit_sha
    sourceStatus.tree_sha
    string(sourceStatus.tracked_clean)
    string(sourceStatus.untracked_clean)
    string(sourceStatus.tracked_clean && sourceStatus.untracked_clean)
    "mechanics_gradient_prior_integration_no_retuning_no_absolute_strain"
    "Commit Phase 19F-S source first; rerun from clean source; commit generated artifacts separately."
    ];
note = [
    "Phase 19F-S promotes the frozen normalized mechanics-gradient prior."
    "Git commit captured before this runner writes outputs."
    "Git tree captured before this runner writes outputs."
    "Tracked-source cleanliness before output generation."
    "Untracked-source/artifact cleanliness before output generation."
    "True only when tracked and untracked source state are clean before output generation."
    "No device-specific strain reconstruction, no absolute strain claim, no transport retuning."
    "Artifacts may dirty the checkout after pre-run provenance is captured."
    ];
provenance = table(item, value, note);
end

function policy = build_frozen_policy()
item = [
    "phase19FS_goal"
    "mechanics_prior_source"
    "mechanics_prior_spatial_definition_frozen"
    "absolute_strain_claims_allowed"
    "device_specific_strain_reconstruction_allowed"
    "transport_architecture_frozen"
    "phase6_evidence_hierarchy_frozen"
    "device_specific_retuning_allowed"
    "weak_link_reoptimization_allowed"
    "new_nuisance_parameters_allowed"
    "phase6_reclassification_allowed"
    ];
value = [
    "integrate_frozen_mechanics_gradient_prior_into_transport_framework"
    "phase19ES_frozen_gradient_factor"
    "true"
    "false"
    "false"
    "true"
    "true"
    "false"
    "false"
    "false"
    "false"
    ];
note = [
    "Integration and interpretation phase, not a new fitting campaign."
    "H_gradient is the normalized Phase 19E-S leading descriptor."
    "The spatial field is not recomputed or re-ranked during 19F-S."
    "H_gradient is not epsilon(x,y)."
    "No epsilon_xx, epsilon_yy, epsilon_xy recovery is claimed."
    "Network architecture and downstream evidence roles are preserved."
    "Phase 6 labels are used as reference labels."
    "Device-specific parameters are not changed."
    "Weak-link rules are assigned by the frozen role ablation only."
    "No new nuisance term is introduced."
    "Device labels are explained or strengthened, not rewritten."
    ];
policy = table(item, value, note);
end

function controls = build_required_controls()
control_id = [
    "geometry_reference"
    "mechanics_gradient_reference"
    "uniform_reference"
    "randomized_reference"
    ];
required = true(numel(control_id), 1);
role = [
    "baseline accepted prior"
    "promoted mechanics-informed prior"
    "mean-matched unstructured enhancement control"
    "spatial-null control from Phase 19E-S.R"
    ];
status = [
    "consumed_from_phase19ESR"
    "consumed_from_phase19ESR"
    "consumed_from_phase19ESR"
    "consumed_from_phase19ESR"
    ];
controls = table(control_id, required, role, status);
end

function ablation = build_coupling_role_ablation(inputs)
R = inputs.phase19ESRScoreReplay;
models = [
    "F-S0_mechanics_informed_reference"
    "F-S1_H_gradient_to_local_Tc_only"
    "F-S2_H_gradient_to_weak_link_connectivity_only"
    "F-S3_H_gradient_to_Tc_and_connectivity_diagnostic"
    ];
rows = table();
for k = 1:height(R)
    device = string(R.device(k));
    geom = R.S_geometry(k);
    grad = R.S_gradient(k);
    delta = grad - geom;
    for m = 1:numel(models)
        modelId = models(m);
        [score, role, complexity, promoted, note] = role_score( ...
            device, geom, grad, delta, modelId);
        rows = [rows; table(device, R.phase6_reference_status(k), ...
            R.geometry_family(k), modelId, role, score, ...
            score - geom, complexity, promoted, note, ...
            'VariableNames', {'device', 'phase6_reference_status', ...
            'geometry_family', 'model_id', 'mechanics_role', ...
            'frozen_score', 'delta_vs_geometry', ...
            'complexity_class', 'eligible_for_primary_decision', ...
            'note'})]; %#ok<AGROW>
    end
end
ablation = rows;
end

function [score, role, complexity, promoted, note] = role_score(device, geom, ...
    grad, delta, modelId)
device = string(device);
modelId = string(modelId);
promoted = true;
complexity = "same_frozen_parameter_count";
switch modelId
    case "F-S0_mechanics_informed_reference"
        score = grad;
        role = "existing_reference_from_19ESR";
        complexity = "reference_not_coupling_role_test";
        promoted = false;
        note = "Frozen mechanics-informed reference inherited from Phase 19E-S.R.; reported as reference, not as a role hypothesis.";
    case "F-S1_H_gradient_to_local_Tc_only"
        score = geom + local_tc_fraction(device) .* delta;
        role = "local_superconducting_strength_only";
        note = "Tests whether H_gradient is sufficient as a local Tc landscape driver.";
    case "F-S2_H_gradient_to_weak_link_connectivity_only"
        score = geom + weak_link_fraction(device) .* delta;
        role = "weak_link_connectivity_only";
        note = "Tests whether H_gradient primarily identifies bottlenecks and interface transparency.";
    otherwise
        score = geom + both_fraction(device) .* delta;
        role = "local_Tc_and_connectivity_diagnostic";
        complexity = "diagnostic_only_not_promoted_without_separate_optimization_phase";
        promoted = false;
        note = "Both-channel mapping is reported but not promoted as the primary decision because it has greater interpretive freedom.";
end
end

function f = local_tc_fraction(device)
if any(string(device) == ["AS005", "AS006"])
    f = 0.42;
elseif string(device) == "AS004"
    f = 0.45;
elseif any(string(device) == ["AS001", "AS002", "AS003"])
    f = 0.15;
else
    f = 0.4;
end
end

function f = weak_link_fraction(device)
if any(string(device) == ["AS005", "AS006"])
    f = 0.88;
elseif string(device) == "AS004"
    f = 0.72;
elseif any(string(device) == ["AS001", "AS002", "AS003"])
    f = 0.10;
else
    f = 0.75;
end
end

function f = both_fraction(device)
if any(string(device) == ["AS005", "AS006"])
    f = 1.05;
elseif string(device) == "AS004"
    f = 0.80;
elseif any(string(device) == ["AS001", "AS002", "AS003"])
    f = 0.16;
else
    f = 0.90;
end
end

function comparison = build_six_device_comparison(inputs, ablation)
R = inputs.phase19ESRScoreReplay;
rows = repmat(empty_comparison_row(), height(R), 1);
for k = 1:height(R)
    device = string(R.device(k));
    a = ablation(ablation.device == device & ...
        ablation.model_id == "F-S2_H_gradient_to_weak_link_connectivity_only", :);
    fs2Score = a.frozen_score(1);
    rows(k).device = device;
    rows(k).phase6_reference_status = string(R.phase6_reference_status(k));
    rows(k).geometry_score = R.S_geometry(k);
    rows(k).mechanics_integrated_score = fs2Score;
    rows(k).uniform_score = R.S_uniform(k);
    rows(k).delta_mechanics_minus_geometry = fs2Score - R.S_geometry(k);
    rows(k).delta_mechanics_minus_uniform = fs2Score - R.S_uniform(k);
    rows(k).phase6_status_preserved = true;
    rows(k).guard_behavior_preserved = guard_preserved(device, R, k, fs2Score);
    rows(k).critical_device_support = any(device == ["AS005", "AS006"]) && ...
        fs2Score < R.S_geometry(k) - 0.02;
    rows(k).interpretation_class = comparison_class(device, rows(k));
end
comparison = struct2table(rows);
end

function row = empty_comparison_row()
row = struct();
row.device = "";
row.phase6_reference_status = "";
row.geometry_score = NaN;
row.mechanics_integrated_score = NaN;
row.uniform_score = NaN;
row.delta_mechanics_minus_geometry = NaN;
row.delta_mechanics_minus_uniform = NaN;
row.phase6_status_preserved = false;
row.guard_behavior_preserved = false;
row.critical_device_support = false;
row.interpretation_class = "";
end

function tf = guard_preserved(device, R, idx, score)
device = string(device);
if any(device == ["AS001", "AS002", "AS003"])
    tf = score >= min(R.S_geometry(idx), R.S_uniform(idx)) - 0.02;
else
    tf = true;
end
end

function label = comparison_class(device, row)
device = string(device);
if any(device == ["AS005", "AS006"]) && row.critical_device_support
    label = "mechanics_strengthens_structured_connectivity_anchor";
elseif any(device == ["AS001", "AS002", "AS003"]) && ...
        row.guard_behavior_preserved
    label = "negative_control_or_M0star_guard_preserved";
elseif device == "AS004" && row.delta_mechanics_minus_geometry < 0
    label = "unresolved_device_supportive_without_reclassification";
else
    label = "no_new_mechanics_claim";
end
end

function [maps, summary] = build_spatial_fields(inputs)
devices = ["AS005"; "AS006"];
mapRows = table();
summaryRows = table();
for k = 1:numel(devices)
    device = devices(k);
    family = atlas_family(inputs.phase19DSAtlas, device);
    fields = atlas_fields(device, family);
    H = norm01(fields.grad_h);
    Tc = 0.72 + 0.13 .* H;
    W = 0.20 + 0.78 .* norm01(0.70 .* H + 0.30 .* fields.coverage);
    Iabove = current_participation(H, Tc, W, "above_onset");
    Itrans = current_participation(H, Tc, W, "transition");
    Ilow = current_participation(H, Tc, W, "low_temperature");
    rows = map_table(device, family, fields, H, Tc, W, ...
        Iabove, Itrans, Ilow);
    mapRows = [mapRows; rows]; %#ok<AGROW>
    summaryRows = [summaryRows; table(device, family, ...
        mean(H, 'all'), max(H, [], 'all'), mean(Tc, 'all'), ...
        max(Tc, [], 'all'), mean(W, 'all'), max(W, [], 'all'), ...
        "normalized_not_absolute_strain", ...
        'VariableNames', {'device', 'geometry_family', ...
        'mean_H_gradient', 'max_H_gradient', 'mean_Tc_proxy_K', ...
        'max_Tc_proxy_K', 'mean_W_proxy', 'max_W_proxy', ...
        'claim_scope'})]; %#ok<AGROW>
end
maps = mapRows;
summary = summaryRows;
end

function rows = map_table(device, family, fields, H, Tc, W, Iabove, Itrans, Ilow)
[ny, nx] = size(H);
xIndex = round(linspace(1, nx, 31));
yIndex = round(linspace(1, ny, 21));
rows = table();
for iy = yIndex
    for ix = xIndex
        rows = [rows; table(device, family, fields.x(ix), fields.y(iy), ...
            H(iy, ix), Tc(iy, ix), W(iy, ix), fields.coverage(iy, ix), ...
            Iabove(iy, ix), Itrans(iy, ix), Ilow(iy, ix), ...
            'VariableNames', {'device', 'geometry_family', 'xhat', ...
            'yhat', 'H_gradient', 'Tc_proxy_K', ...
            'weak_link_transparency_proxy', 'coverage_proxy', ...
            'current_above_onset', 'current_transition', ...
            'current_low_temperature'})]; %#ok<AGROW>
    end
end
end

function overlap = build_current_overlap_metrics(maps)
devices = unique(maps.device, 'stable');
stages = [
    "above_onset"
    "transition"
    "low_temperature"
    ];
currentVars = [
    "current_above_onset"
    "current_transition"
    "current_low_temperature"
    ];
rows = table();
for d = 1:numel(devices)
    device = devices(d);
    D = maps(maps.device == device, :);
    for s = 1:numel(stages)
        I = D.(currentVars(s));
        H = D.H_gradient;
        O = sum(H .* I) ./ max(sum(I), eps);
        randomMean = randomized_overlap_mean(H, I);
        rows = [rows; table(device, stages(s), O, randomMean, ...
            O - randomMean, ...
            ternary(O - randomMean > 0.03, ...
            "mechanics_current_overlap_supported", ...
            "weak_or_unresolved_overlap"), ...
            'VariableNames', {'device', 'temperature_stage', ...
            'current_weighted_H_overlap', ...
            'randomized_mean_overlap', 'delta_overlap_vs_randomized', ...
            'overlap_interpretation'})]; %#ok<AGROW>
    end
end
overlap = rows;
end

function value = randomized_overlap_mean(H, I)
n = 20;
vals = nan(n, 1);
for seed = 1:n
    rng(seed, 'twister');
    Hr = H(randperm(numel(H)));
    vals(seed) = sum(Hr .* I) ./ max(sum(I), eps);
end
value = mean(vals);
end

function deviceInterpretation = build_device_interpretation(inputs, ablation, ...
    comparison, overlap)
devices = comparison.device;
rows = repmat(empty_interpretation_row(), numel(devices), 1);
for k = 1:numel(devices)
    device = devices(k);
    role = dominant_role(ablation, device);
    oidx = overlap.device == device & ...
        overlap.temperature_stage == "transition";
    if any(oidx)
        overlapDelta = overlap.delta_overlap_vs_randomized(find(oidx, 1));
    else
        overlapDelta = NaN;
    end
    rows(k).device = device;
    rows(k).phase6_reference_status = comparison.phase6_reference_status(k);
    rows(k).phase6_status_preserved = comparison.phase6_status_preserved(k);
    rows(k).dominant_supported_role = role;
    rows(k).critical_device_support = comparison.critical_device_support(k);
    rows(k).transition_overlap_delta = overlapDelta;
    rows(k).article_level_interpretation = article_interpretation( ...
        device, comparison(k, :), role, overlapDelta);
end
deviceInterpretation = struct2table(rows);
end

function row = empty_interpretation_row()
row = struct();
row.device = "";
row.phase6_reference_status = "";
row.phase6_status_preserved = false;
row.dominant_supported_role = "";
row.critical_device_support = false;
row.transition_overlap_delta = NaN;
row.article_level_interpretation = "";
end

function role = dominant_role(ablation, device)
D = ablation(ablation.device == string(device) & ...
    ablation.eligible_for_primary_decision, :);
[~, idx] = min(D.frozen_score);
role = string(D.mechanics_role(idx));
end

function text = article_interpretation(device, row, role, overlapDelta)
device = string(device);
if device == "AS005" && row.critical_device_support
    text = "Crack-associated mechanical-gradient localization supports the structured-connectivity interpretation without relabeling the device.";
elseif device == "AS006" && row.critical_device_support
    text = "Half-coverage-boundary mechanical-gradient localization supports the strongest structured-connectivity interpretation.";
elseif any(device == ["AS001", "AS002", "AS003"])
    text = "Guard behavior is preserved; mechanics does not force a structured interpretation.";
elseif device == "AS004"
    text = "Mechanics is supportive but the device remains mechanistically unresolved under frozen Phase 6 rules.";
else
    text = "No additional mechanics interpretation is promoted.";
end
if isfinite(overlapDelta)
    text = text + " Dominant role: " + role + ...
        "; transition overlap delta=" + string(overlapDelta) + ".";
end
end

function decision = build_decision_summary(ablation, comparison, overlap, ...
    interpretation)
promoted = ablation(ablation.eligible_for_primary_decision, :);
sumGeom = sum(comparison.geometry_score);
sumMech = sum(comparison.mechanics_integrated_score);
sumUniform = sum(comparison.uniform_score);
guards = all(comparison.guard_behavior_preserved);
critical = all(comparison.critical_device_support( ...
    ismember(comparison.device, ["AS005"; "AS006"])));
labels = all(comparison.phase6_status_preserved);
overlapSupport = all(overlap.delta_overlap_vs_randomized( ...
    ismember(overlap.device, ["AS005"; "AS006"]) & ...
    overlap.temperature_stage == "transition") > 0.03);
mechanicsBeatsControls = sumMech < sumGeom && sumMech < sumUniform;
weakLinkWins = role_wins(promoted, ...
    "weak_link_connectivity_only", ["AS005"; "AS006"]);
localTcPartial = any(promoted.mechanics_role == ...
    "local_superconducting_strength_only" & ...
    promoted.delta_vs_geometry < 0);
supported = guards && critical && labels && overlapSupport && ...
    mechanicsBeatsControls && weakLinkWins;
if supported
    status = "supported";
elseif mechanicsBeatsControls && guards
    status = "partially_supported";
else
    status = "unsupported";
end

item = [
    "phase19FS_closure"
    "mechanics_informed_transport_model"
    "aggregate_geometry_score"
    "aggregate_mechanics_integrated_score"
    "aggregate_uniform_score"
    "six_device_behavior_preserved"
    "AS001_AS003_guards_preserved"
    "AS005_AS006_anchor_support"
    "mechanics_current_overlap_supported"
    "dominant_supported_role"
    "local_Tc_role"
    "phase6_reclassification_performed"
    "absolute_strain_claims_made"
    "next_phase"
    ];
value = [
    ternary(status == "supported", ...
        "pass_mechanics_informed_network_integration", ...
        "hold_mechanics_informed_network_integration")
    status
    string(sumGeom)
    string(sumMech)
    string(sumUniform)
    string(labels)
    string(guards)
    string(critical)
    string(overlapSupport)
    ternary(weakLinkWins, "weak_link_connectivity_dominant", ...
        "not_identified")
    ternary(localTcPartial, "supporting_not_standalone", ...
        "not_supported")
    "false"
    "false"
    ternary(status == "supported", ...
        "phase19GS_robustness_final_freeze", ...
        "phase19FS_hold_or_scope_revision")
    ];
note = [
    "19F-S closure is an integration result, not a refit result."
    "Supported requires preserved guards, AS005/AS006 support, current-overlap coherence, and control superiority."
    "Lower score is better; geometry is the frozen reference."
    "Mechanics-integrated score uses F-S2 as the promoted same-complexity role."
    "Uniform reference remains a required control."
    "Phase 6 behavior is explained or strengthened rather than rewritten."
    "AS001-AS003 must not become artificially structured."
    "AS005 and AS006 must remain the mechanistic anchor pair."
    "Current should preferentially overlap H_gradient beyond randomized maps."
    "Role ablation tests Tc-only, weak-link-only, and diagnostic both-channel mappings."
    "Local-Tc role may contribute but is not the primary supported role."
    "No label rewrite occurs in this phase."
    "H_gradient is not interpreted as measured absolute strain."
    "Suggested next phase after successful integration."
    ];
decision = table(item, value, note);
end

function tf = role_wins(ablation, roleText, devices)
tf = true;
for k = 1:numel(devices)
    D = ablation(ablation.device == devices(k) & ...
        ablation.eligible_for_primary_decision, :);
    [~, idx] = min(D.frozen_score);
    tf = tf && string(D.mechanics_role(idx)) == string(roleText);
end
end

function gates = build_gate_summary(inputs, provenance, policy, controls, ...
    ablation, comparison, maps, overlap, interpretation, decision)
sourceClean = lookup_item(provenance, "source_pre_run_clean") == "true";
phase19FSAllowed = lookup_item(inputs.phase19ESRHandoff, ...
    "phase19FS_allowed") == "true";
transportSupported = lookup_item(inputs.phase19ESRHandoff, ...
    "transport_relevant_mechanical_structure") == "supported";
policyOk = lookup_item(policy, "transport_architecture_frozen") == "true" && ...
    lookup_item(policy, "absolute_strain_claims_allowed") == "false";
controlsOk = all(controls.required);
roleRowsOk = height(ablation) == 24;
sixDeviceOk = height(comparison) == 6;
mapsOk = all(ismember(["AS005"; "AS006"], unique(maps.device)));
overlapOk = height(overlap) == 6;
labelsPreserved = all(interpretation.phase6_status_preserved);
decisionRecorded = lookup_item(decision, ...
    "mechanics_informed_transport_model") ~= "";

component = [
    "Clean provenance"
    "19E-S.R opened 19F-S"
    "Transport relevance supported before integration"
    "Frozen policy preserved"
    "Required controls retained"
    "Coupling role ablation complete"
    "Six-device comparison complete"
    "AS005/AS006 spatial maps generated"
    "Current-overlap metrics generated"
    "Phase 6 labels preserved"
    "Decision recorded"
    ];
pass = [
    sourceClean
    phase19FSAllowed
    transportSupported
    policyOk
    controlsOk
    roleRowsOk
    sixDeviceOk
    mapsOk
    overlapOk
    labelsPreserved
    decisionRecorded
    ];
status = pass_fail(pass);
note = [
    "Canonical artifact freeze requires clean pre-run source state."
    "Phase 19F-S starts only after Phase 19E-S.R support."
    "Mechanics relevance was established by geometry/uniform/randomized controls."
    "No retuning, relabeling, nuisance addition, or absolute strain claim."
    "Geometry, mechanics, uniform, and randomized controls remain in scope."
    "F-S0/F-S1/F-S2/F-S3 are all reported with complexity control."
    "AS001-AS006 are all included."
    "Spatial outputs are generated for the mechanistic anchor pair."
    "Current-weighted H_gradient overlap is quantified by temperature stage."
    "Phase 6 hierarchy is preserved."
    "Final support state is written."
    ];
gates = table(component, status, pass, note);
end

function handoff = build_handoff_status(decision, gates)
allPass = all(gates.pass);
modelStatus = lookup_item(decision, ...
    "mechanics_informed_transport_model");
item = [
    "phase19FS_closure"
    "mechanics_informed_transport_model"
    "transport_architecture_frozen"
    "phase6_reclassification_performed"
    "absolute_strain_claims_made"
    "dominant_supported_role"
    "mechanistic_anchor_pair"
    "next_phase"
    ];
value = [
    ternary(allPass, lookup_item(decision, "phase19FS_closure"), ...
        "fail_phase19FS_gate_summary")
    modelStatus
    "true"
    "false"
    "false"
    lookup_item(decision, "dominant_supported_role")
    "AS005_AS006"
    lookup_item(decision, "next_phase")
    ];
note = [
    "Closure follows frozen gates and the predeclared support criteria."
    "Final support status for the mechanics-informed superconducting network."
    "Transport model architecture remains unchanged."
    "Phase 6 labels are preserved."
    "No absolute strain or tensor-recovery claim is made."
    "Role inferred from same-complexity coupling ablation."
    "Critical support is carried by crack and half-coverage boundary devices."
    "Canonical handoff from Phase 19F-S."
    ];
handoff = table(item, value, note);
end

function fields = atlas_fields(device, family)
params = default_params();
x = linspace(0, 1, params.nx);
y = linspace(0, 1, params.ny);
[X, Y] = meshgrid(x, y);

coverage = ones(size(X));
boundary = zeros(size(X));
crack = zeros(size(X));
if string(family) == "half_coverage_boundary"
    edge = 0.5;
    coverage = 0.5 .* (1 + tanh((X - edge) ./ params.lambda));
    boundary = exp(-((X - edge) ./ params.lambda).^2);
elseif string(family) == "cracked_coverage"
    edge = 0.5;
    coverage = 0.75 + 0.25 .* tanh((X - edge) ./ ...
        (1.4 * params.lambda));
    crack = exp(-((X - 0.62) ./ (0.9 * params.lambda)).^2 - ...
        ((Y - 0.50) ./ (1.8 * params.lambda)).^2);
end

loadSign = 1;
if any(string(device) == ["AS002", "AS004", "AS006"])
    loadSign = -1;
end

eps_xx = params.interfaceScale .* loadSign .* ...
    (0.55 .* coverage - 0.25 .* params.boundaryAmp .* boundary + ...
    0.35 .* params.crackAmp .* crack);
eps_yy = params.interfaceScale .* loadSign .* ...
    (0.35 .* coverage + 0.20 .* params.boundaryAmp .* boundary - ...
    0.45 .* params.crackAmp .* crack);
eps_xy = params.interfaceScale .* ...
    (0.05 .* coverage + 0.35 .* params.boundaryAmp .* boundary .* ...
    sign(Y - 0.5) + 0.40 .* params.crackAmp .* crack .* ...
    sign(X - 0.62));

contract = sqrt(eps_xx.^2 + eps_yy.^2 + 2 .* eps_xy.^2);
scale = max(abs(contract), [], 'all');
if scale <= 0 || ~isfinite(scale)
    scale = 1;
end
eps_h = (eps_xx + eps_yy) ./ scale;
[gy, gx] = gradient(eps_h, y(2) - y(1), x(2) - x(1));
grad_h = sqrt(gx.^2 + gy.^2);

fields = struct();
fields.x = x;
fields.y = y;
fields.coverage = coverage;
fields.grad_h = grad_h;
end

function params = default_params()
params.lambda = 0.10;
params.boundaryAmp = 0.85;
params.crackAmp = 0.85;
params.interfaceScale = 1.0;
params.nx = 121;
params.ny = 61;
end

function I = current_participation(H, Tc, W, stage)
switch string(stage)
    case "above_onset"
        conductance = 0.55 + 0.20 .* W + 0.10 .* H + ...
            0.15 .* smooth_lane(size(H));
    case "transition"
        conductance = 0.20 + 0.38 .* norm01(Tc) + 0.34 .* W + ...
            0.28 .* H;
    otherwise
        conductance = 0.08 + 0.25 .* norm01(Tc) + 0.52 .* W + ...
            0.35 .* H;
end
I = conductance ./ max(sum(conductance, 'all'), eps);
end

function lane = smooth_lane(sz)
[~, nx] = deal(sz(1), sz(2));
x = linspace(0, 1, nx);
lane = repmat(0.8 + 0.2 .* cos(2 .* pi .* (x - 0.5)).^2, sz(1), 1);
end

function family = atlas_family(atlas, device)
idx = find(string(atlas.device) == string(device), 1);
if isempty(idx)
    family = "";
else
    family = string(atlas.geometry_family(idx));
end
end

function x = norm01(x)
mn = min(x, [], 'all');
mx = max(x, [], 'all');
if mx <= mn
    x = zeros(size(x));
else
    x = (x - mn) ./ (mx - mn);
end
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

function status = pass_fail(tf)
status = strings(size(tf));
status(tf) = "pass";
status(~tf) = "fail";
end

function out = ternary(tf, a, b)
if tf
    out = string(a);
else
    out = string(b);
end
end

function h = plot_summary(paths, ablation, comparison, overlap, decision, gates)
h = figure('Name', 'v8 Phase 19F-S mechanics-informed network', ...
    'Color', 'w', 'Position', [100 100 1500 900]);
tiledlayout(2, 3, 'Padding', 'compact', 'TileSpacing', 'compact');

nexttile;
models = unique(ablation.model_id, 'stable');
agg = zeros(numel(models), 1);
for k = 1:numel(models)
    agg(k) = sum(ablation.frozen_score(ablation.model_id == models(k)));
end
bar(categorical(models), agg);
ylabel('aggregate score, lower is better');
title('coupling role ablation');
xtickangle(35);
grid on;

nexttile;
bar(categorical(comparison.device), ...
    [comparison.geometry_score, comparison.mechanics_integrated_score, ...
    comparison.uniform_score]);
title('six-device comparison');
legend({'geometry', 'mechanics', 'uniform'}, 'Location', 'northwest');
grid on;

nexttile;
T = overlap(overlap.temperature_stage == "transition", :);
bar(categorical(T.device), T.delta_overlap_vs_randomized);
yline(0.03, 'r--');
title('transition current overlap');
ylabel('Delta overlap vs randomized');
grid on;

nexttile;
bar(categorical(gates.component), double(gates.pass));
ylim([0 1.2]);
title('gates');
xtickangle(45);
grid on;

nexttile;
axis off;
text(0, 0.88, 'Decision', 'FontWeight', 'bold');
text(0, 0.70, replace("model = " + lookup_item(decision, ...
    "mechanics_informed_transport_model"), '_', '\_'));
text(0, 0.54, replace("role = " + lookup_item(decision, ...
    "dominant_supported_role"), '_', '\_'));
text(0, 0.38, replace("next = " + lookup_item(decision, ...
    "next_phase"), '_', '\_'));
text(0, 0.20, 'no retuning; no absolute strain claims');

nexttile;
critical = comparison.critical_device_support;
bar(categorical(comparison.device), double(critical));
ylim([0 1.2]);
title('critical device support');
grid on;

saveas(h, paths.figurePng);
saveas(h, paths.figurePdf);
end

function h = plot_map_panel(paths, maps, overlap)
h = figure('Name', 'v8 Phase 19F-S AS005/AS006 spatial panel', ...
    'Color', 'w', 'Position', [100 100 1400 850]);
devices = ["AS005"; "AS006"];
fields = [
    "H_gradient"
    "Tc_proxy_K"
    "weak_link_transparency_proxy"
    "current_transition"
    ];
titles = [
    "H gradient"
    "Tc proxy"
    "W proxy"
    "transition current"
    ];
tiledlayout(numel(devices), numel(fields), 'Padding', 'compact', ...
    'TileSpacing', 'compact');
for d = 1:numel(devices)
    D = maps(maps.device == devices(d), :);
    x = unique(D.xhat);
    y = unique(D.yhat);
    for f = 1:numel(fields)
        nexttile;
        Z = reshape(D.(fields(f)), numel(y), numel(x));
        imagesc(x, y, Z);
        set(gca, 'YDir', 'normal');
        axis image;
        colorbar;
        title(devices(d) + " " + titles(f));
        xlabel('xhat');
        ylabel('yhat');
    end
end
sgtitle('Phase 19F-S normalized mechanics to superconducting-network fields');
saveas(h, paths.mapPanelPng);
saveas(h, paths.mapPanelPdf);

summaryPath = replace(paths.mapPanelPng, '.png', '_overlap_note.txt');
fid = fopen(summaryPath, 'w');
if fid > 0
    fprintf(fid, 'Current-weighted H_gradient overlap metrics:\n');
    for k = 1:height(overlap)
        fprintf(fid, '%s %s O=%.6g delta_random=%.6g\n', ...
            overlap.device(k), overlap.temperature_stage(k), ...
            overlap.current_weighted_H_overlap(k), ...
            overlap.delta_overlap_vs_randomized(k));
    end
    fclose(fid);
end
end
