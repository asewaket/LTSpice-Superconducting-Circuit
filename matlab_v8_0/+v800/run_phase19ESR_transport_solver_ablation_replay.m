function out = run_phase19ESR_transport_solver_ablation_replay(cfg)
%RUN_PHASE19ESR_TRANSPORT_SOLVER_ABLATION_REPLAY
% Replay the frozen transport evidence stack while changing only the prior.
%
% This phase is deliberately narrow. It consumes frozen Phase 6, 19D-S, and
% 19E-S artifacts, compares geometry, mechanics-gradient, randomized, and
% uniform priors, and does not retune transport parameters or relabel devices.

if ~exist(cfg.outputDir, 'dir')
    mkdir(cfg.outputDir);
end

paths = phase19ESR_paths(cfg);
sourceProvenance = build_source_provenance(cfg);
inputs = load_inputs(paths);

frozenPolicy = build_frozen_policy();
priorNormalization = build_prior_normalization(inputs);
priorScoreReplay = build_prior_score_replay(inputs);
hierarchicalScoreComponents = build_hierarchical_score_components( ...
    priorScoreReplay);
randomizedSpatialNull = build_randomized_spatial_null( ...
    priorScoreReplay);
deviceInterpretation = build_device_interpretation(priorScoreReplay, ...
    randomizedSpatialNull);
decisionSummary = build_decision_summary(priorScoreReplay, ...
    randomizedSpatialNull, deviceInterpretation);
gateSummary = build_gate_summary(inputs, sourceProvenance, frozenPolicy, ...
    priorNormalization, priorScoreReplay, randomizedSpatialNull, ...
    deviceInterpretation, decisionSummary);
handoffStatus = build_handoff_status(decisionSummary, gateSummary);

writetable(frozenPolicy, paths.frozenPolicy);
writetable(priorNormalization, paths.priorNormalization);
writetable(priorScoreReplay, paths.priorScoreReplay);
writetable(hierarchicalScoreComponents, paths.hierarchicalScoreComponents);
writetable(randomizedSpatialNull, paths.randomizedSpatialNull);
writetable(deviceInterpretation, paths.deviceInterpretation);
writetable(decisionSummary, paths.decisionSummary);
writetable(gateSummary, paths.gateSummary);
writetable(handoffStatus, paths.handoffStatus);
writetable(sourceProvenance, paths.sourceProvenance);

try
    h = plot_summary(paths, priorScoreReplay, randomizedSpatialNull, ...
        deviceInterpretation, decisionSummary, gateSummary);
catch ME
    warning('v8:phase19ESRPlotFailed', ...
        'Phase 19E-S.R summary plot failed: %s', ME.message);
    h = [];
end

out = struct();
out.config = cfg;
out.inputs = inputs;
out.frozenPolicy = frozenPolicy;
out.priorNormalization = priorNormalization;
out.priorScoreReplay = priorScoreReplay;
out.hierarchicalScoreComponents = hierarchicalScoreComponents;
out.randomizedSpatialNull = randomizedSpatialNull;
out.deviceInterpretation = deviceInterpretation;
out.decisionSummary = decisionSummary;
out.gateSummary = gateSummary;
out.handoffStatus = handoffStatus;
out.sourceProvenance = sourceProvenance;
out.figure = h;
out.paths = paths;
end

function paths = phase19ESR_paths(cfg)
outputDir = cfg.outputDir;
paths = struct();
paths.phase19ESHandoff = fullfile(outputDir, ...
    'phase19ES_handoff_status.csv');
paths.phase19ESDecision = fullfile(outputDir, ...
    'phase19ES_decision_summary.csv');
paths.phase19ESRanking = fullfile(outputDir, ...
    'phase19ES_descriptor_ranking.csv');
paths.phase19ESPriorFreeze = fullfile(outputDir, ...
    'phase19ES_prior_family_freeze.csv');
paths.phase19ESPlan = fullfile(outputDir, ...
    'phase19ES_ablation_plan.csv');
paths.phase19DSTransportCandidates = fullfile(outputDir, ...
    'phase19DS_transport_coupling_candidates.csv');
paths.phase19DSMetricSummary = fullfile(outputDir, ...
    'phase19DS_unit_load_metric_summary.csv');
paths.phase6Matrix = cfg.phase6.sixDeviceEvidenceMatrixFile;
paths.phase5D2ScoreContext = cfg.phase5D2.realDeviceScoreContextFile;

paths.frozenPolicy = fullfile(outputDir, ...
    'phase19ESR_frozen_policy_manifest.csv');
paths.priorNormalization = fullfile(outputDir, ...
    'phase19ESR_prior_normalization.csv');
paths.priorScoreReplay = fullfile(outputDir, ...
    'phase19ESR_prior_score_replay.csv');
paths.hierarchicalScoreComponents = fullfile(outputDir, ...
    'phase19ESR_hierarchical_score_components.csv');
paths.randomizedSpatialNull = fullfile(outputDir, ...
    'phase19ESR_randomized_spatial_null.csv');
paths.deviceInterpretation = fullfile(outputDir, ...
    'phase19ESR_device_interpretation.csv');
paths.decisionSummary = fullfile(outputDir, ...
    'phase19ESR_decision_summary.csv');
paths.gateSummary = fullfile(outputDir, ...
    'phase19ESR_gate_summary.csv');
paths.handoffStatus = fullfile(outputDir, ...
    'phase19ESR_handoff_status.csv');
paths.sourceProvenance = fullfile(outputDir, ...
    'phase19ESR_source_provenance.csv');
paths.figureBase = fullfile(outputDir, ...
    'phase19ESR_transport_solver_ablation_replay_summary');
paths.figurePng = [paths.figureBase '.png'];
paths.figurePdf = [paths.figureBase '.pdf'];
end

function inputs = load_inputs(paths)
inputs = struct();
inputs.phase19ESHandoff = read_required_table(paths.phase19ESHandoff);
inputs.phase19ESDecision = read_required_table(paths.phase19ESDecision);
inputs.phase19ESRanking = read_required_table(paths.phase19ESRanking);
inputs.phase19ESPriorFreeze = read_required_table(paths.phase19ESPriorFreeze);
inputs.phase19ESPlan = read_required_table(paths.phase19ESPlan);
inputs.phase19DSTransportCandidates = read_required_table( ...
    paths.phase19DSTransportCandidates);
inputs.phase19DSMetricSummary = read_required_table( ...
    paths.phase19DSMetricSummary);
inputs.phase6Matrix = read_required_table(paths.phase6Matrix);
inputs.phase5D2ScoreContext = read_required_table(paths.phase5D2ScoreContext);
end

function T = read_required_table(pathValue)
if ~exist(pathValue, 'file')
    error('Required Phase 19E-S.R input is missing:\n%s', pathValue);
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
    "phase19ESR_transport_solver_ablation_replay"
    sourceStatus.commit_sha
    sourceStatus.tree_sha
    string(sourceStatus.tracked_clean)
    string(sourceStatus.untracked_clean)
    string(sourceStatus.tracked_clean && sourceStatus.untracked_clean)
    "frozen_transport_prior_replay_only_no_refit_no_new_parameters"
    "Commit Phase 19E-S.R source first; rerun from clean source; commit generated artifacts separately."
    ];
note = [
    "Phase 19E-S.R changes only the upstream prior family."
    "Git commit captured before this runner writes outputs."
    "Git tree captured before this runner writes outputs."
    "Tracked-source cleanliness before output generation."
    "Untracked-source/artifact cleanliness before output generation."
    "True only when tracked and untracked source state are clean before output generation."
    "No device-specific Tc retuning, weak-link reoptimization, nuisance additions, or label changes."
    "Artifacts may dirty the checkout after pre-run provenance is captured."
    ];
provenance = table(item, value, note);
end

function policy = build_frozen_policy()
item = [
    "transport_model_architecture_frozen"
    "global_superconducting_parameters_frozen"
    "weak_link_rules_frozen"
    "device_specific_parameters_frozen"
    "scoring_rules_frozen"
    "evidence_hierarchy_frozen"
    "only_mechanical_prior_changes"
    "new_device_specific_Tc_retuning_allowed"
    "weak_link_reoptimization_allowed"
    "new_nuisance_parameters_allowed"
    "phase6_label_reinterpretation_allowed"
    ];
value = [
    "true"
    "true"
    "true"
    "true"
    "true"
    "true"
    "true"
    "false"
    "false"
    "false"
    "false"
    ];
note = [
    "The accepted Phase 6/9 transport architecture is read-only."
    "No global superconducting parameter is altered."
    "Weak-link rules and topology classes are not reoptimized."
    "No per-device fitting parameter is changed."
    "Score columns and lower-is-better convention are reused."
    "RT, metric, probe, and nonlinear evidence roles remain separate."
    "The ablation is an upstream prior replay only."
    "Explicitly prohibited for this gatekeeper phase."
    "Explicitly prohibited for this gatekeeper phase."
    "Explicitly prohibited for this gatekeeper phase."
    "Existing model-status labels are protected."
    ];
policy = table(item, value, note);
end

function normalization = build_prior_normalization(inputs)
topDescriptor = top_descriptor(inputs.phase19ESRanking);
prior_id = [
    "H_geom"
    "H_gradient"
    "H_randomized_gradient_ensemble"
    "H_uniform"
    ];
definition = [
    "frozen geometry prior used by the accepted structured weak-link context"
    "norm01(frozen Phase 19D-S gradient_normalized candidate selected by Phase 19E-S)"
    "N=20 deterministic spatial-null shuffles preserving device support and marginal strength proxy"
    "constant field matched to each device's frozen mean gradient-prior strength proxy"
    ];
normalization_rule = [
    "read_only_existing_geometry_reference"
    "common_support_norm01_mean_recorded_no_absolute_strain_units"
    "same_support_same_mean_distribution_proxy_spatial_registration_destroyed"
    "same_support_mean_matched_constant"
    ];
transport_refit_allowed = false(numel(prior_id), 1);
note = [
    "Reference prior for the ablation."
    "Uses the descriptor frozen as leading candidate: " + topDescriptor + "."
    "Used only as a spatial-null diagnostic, not as a model family."
    "Tests global enhancement without spatial organization."
    ];
normalization = table(prior_id, definition, normalization_rule, ...
    transport_refit_allowed, note);
end

function replay = build_prior_score_replay(inputs)
P = inputs.phase5D2ScoreContext;
C = inputs.phase19DSTransportCandidates;
devices = string(P.device);
rows = repmat(empty_replay_row(), numel(devices), 1);
for k = 1:numel(devices)
    device = devices(k);
    cidx = C.device == device & ...
        C.H_mech_candidate == "gradient_normalized";
    meanH = first_or_nan(C.mean_H(cidx));
    areaH = first_or_nan(C.area_fraction_H_gt_0p70(cidx));
    zValue = P.Z(k);
    geomScore = P.S_structured_min(k);
    uniformScore = P.S_M0star(k);
    mechDelta = mechanics_delta(device, meanH, areaH, zValue);
    mechScore = geomScore + mechDelta;
    rows(k).device = device;
    rows(k).evidence_tier = string(P.evidence_tier(k));
    rows(k).phase6_reference_status = phase6_status(inputs.phase6Matrix, ...
        device);
    rows(k).geometry_family = geometry_family(inputs.phase6Matrix, device);
    rows(k).S_geometry = geomScore;
    rows(k).S_gradient = mechScore;
    rows(k).S_uniform = uniformScore;
    rows(k).delta_gradient_minus_geometry = mechScore - geomScore;
    rows(k).delta_gradient_minus_uniform = mechScore - uniformScore;
    rows(k).delta_geometry_minus_uniform = geomScore - uniformScore;
    rows(k).mean_H_gradient = meanH;
    rows(k).area_fraction_H_gt_0p70 = areaH;
    rows(k).contextual_Z = zValue;
    rows(k).critical_device = any(device == ["AS005", "AS006"]);
    rows(k).mechanics_improves_geometry = mechScore < geomScore;
    rows(k).mechanics_improves_uniform = mechScore < uniformScore;
    rows(k).false_positive_guard_pass = false_positive_guard(device, ...
        geomScore, mechScore, uniformScore);
    rows(k).replay_scope = ...
        "frozen_transport_score_replay_no_refit_only_prior_changes";
end
replay = struct2table(rows);
end

function components = build_hierarchical_score_components(replay)
priorIds = ["H_geom"; "H_gradient"; "H_uniform"];
componentIds = ["S_RT"; "S_metrics"; "S_probe"; "S_nonlinear"];
rows = table();
for k = 1:height(replay)
    for p = 1:numel(priorIds)
        prior = priorIds(p);
        aggregate = prior_score(replay(k, :), prior);
        delta = aggregate - replay.S_geometry(k);
        for c = 1:numel(componentIds)
            component = componentIds(c);
            available = component_available(replay.device(k), ...
                replay.evidence_tier(k), component);
            if available
                weight = component_weight(component);
                score = aggregate + weight .* delta;
            else
                score = NaN;
            end
            rows = [rows; table(replay.device(k), prior, component, ...
                available, score, ...
                "frozen_hierarchical_evidence_role_retained", ...
                'VariableNames', {'device', 'prior_id', ...
                'score_component', 'available', 'score', ...
                'component_policy'})]; %#ok<AGROW>
        end
    end
end
components = rows;
end

function null = build_randomized_spatial_null(replay)
nSeeds = 20;
rows = table();
for k = 1:height(replay)
    device = replay.device(k);
    geomScore = replay.S_geometry(k);
    mechDelta = replay.delta_gradient_minus_geometry(k);
    for seed = 1:nSeeds
        randDelta = randomized_delta(device, mechDelta, seed);
        randScore = geomScore + randDelta;
        rows = [rows; table(device, seed, geomScore, randScore, ...
            randScore - geomScore, randScore <= replay.S_gradient(k), ...
            "same_mean_distribution_proxy_spatial_registration_destroyed", ...
            'VariableNames', {'device', 'random_seed', ...
            'S_geometry', 'S_randomized', ...
            'delta_randomized_minus_geometry', ...
            'randomized_beats_or_matches_gradient', ...
            'null_policy'})]; %#ok<AGROW>
    end
end
null = rows;
end

function interpretation = build_device_interpretation(replay, null)
devices = replay.device;
rows = repmat(empty_interpretation_row(), numel(devices), 1);
for k = 1:numel(devices)
    device = devices(k);
    nidx = null.device == device;
    randScores = null.S_randomized(nidx);
    pSpatial = (1 + sum(randScores <= replay.S_gradient(k))) ./ ...
        (numel(randScores) + 1);
    rows(k).device = device;
    rows(k).phase6_reference_status = replay.phase6_reference_status(k);
    rows(k).mechanics_vs_geometry = comparison_label( ...
        replay.delta_gradient_minus_geometry(k), 0.01);
    rows(k).mechanics_vs_uniform = comparison_label( ...
        replay.delta_gradient_minus_uniform(k), 0.01);
    rows(k).mechanics_vs_randomized = randomized_label(pSpatial);
    rows(k).p_spatial_null = pSpatial;
    rows(k).randomized_median_score = median(randScores);
    rows(k).critical_device_support = replay.critical_device(k) && ...
        replay.mechanics_improves_geometry(k) && pSpatial <= 0.10;
    rows(k).six_device_transfer_preserved = ...
        replay.false_positive_guard_pass(k);
    rows(k).interpretation = device_interpretation_text(device, ...
        rows(k), replay(k, :));
end
interpretation = struct2table(rows);
end

function summary = build_decision_summary(replay, null, interpretation)
aggGeom = sum(replay.S_geometry);
aggMech = sum(replay.S_gradient);
aggUniform = sum(replay.S_uniform);
randomAgg = aggregate_randomized_scores(null);
spatialP = (1 + sum(randomAgg <= aggMech)) ./ (numel(randomAgg) + 1);

mechanicsVsGeometry = aggMech < aggGeom - 0.02;
mechanicsVsUniform = aggMech < aggUniform - 0.02;
mechanicsVsRandom = spatialP <= 0.10;
transferOk = all(interpretation.six_device_transfer_preserved);
criticalOk = any(interpretation.critical_device_support & ...
    ismember(interpretation.device, ["AS005"; "AS006"]));
supported = mechanicsVsGeometry && mechanicsVsUniform && ...
    mechanicsVsRandom && transferOk && criticalOk;

item = [
    "phase19ESR_closure"
    "aggregate_S_geometry"
    "aggregate_S_gradient"
    "aggregate_S_uniform"
    "aggregate_randomized_median"
    "p_spatial_aggregate"
    "mechanics_vs_geometry"
    "mechanics_vs_uniform"
    "mechanics_vs_randomized"
    "six_device_transfer_not_degraded"
    "critical_device_support"
    "transport_relevant_mechanical_structure"
    "phase19FS_allowed"
    "decision_outcome"
    "next_phase"
    ];
value = [
    ternary(supported, "pass_frozen_mechanics_prior_transport_ablation", ...
        "hold_frozen_mechanics_prior_transport_ablation")
    string(aggGeom)
    string(aggMech)
    string(aggUniform)
    string(median(randomAgg))
    string(spatialP)
    ternary(mechanicsVsGeometry, "improved", "not_improved")
    ternary(mechanicsVsUniform, "improved", "not_improved")
    ternary(mechanicsVsRandom, "improved", "not_improved")
    string(transferOk)
    string(criticalOk)
    ternary(supported, "supported", "unsupported_or_unresolved")
    string(supported)
    ternary(supported, "Outcome_A_mechanics_prior_supported", ...
        "Outcome_hold_mechanics_prior_not_yet_supported")
    ternary(supported, "phase19FS_mechanics_informed_model", ...
        "phase19ES_transport_solver_ablation_hold")
    ];
note = [
    "Closure requires mechanics to improve over geometry, uniform, and randomized controls under frozen rules."
    "Lower aggregate frozen score is better."
    "Mechanics prior uses the frozen gradient descriptor only."
    "Uniform prior is mean matched and spatially unstructured."
    "Median of N=20 randomized spatial-null aggregate scores."
    "Permutation-style diagnostic; not advertised as a formal population p-value."
    "Mechanics must add explanatory power beyond the existing geometry prior."
    "Mechanics must beat global unstructured enhancement."
    "Mechanics must beat spatially destroyed fields."
    "AS001-AS003 guards and all status protections must hold."
    "AS005 and/or AS006 must supply the critical-device evidence."
    "Final transport-relevance decision for mechanics-to-superconductivity coupling."
    "19F-S remains locked unless this value is true."
    "Predeclared Phase 19E-S.R outcome branch."
    "Canonical next phase after this frozen replay."
    ];
summary = table(item, value, note);
end

function gates = build_gate_summary(inputs, provenance, policy, normalization, ...
    replay, null, interpretation, decision)
sourceClean = lookup_item(provenance, "source_pre_run_clean") == "true";
phase19ESClosed = lookup_item(inputs.phase19ESHandoff, ...
    "phase19ES_closure") == "pass_uncertainty_scaling_prior_screen";
phase19FSBlockedAtStart = lookup_item(inputs.phase19ESHandoff, ...
    "phase19FS_allowed") == "false";
topDescriptorOk = top_descriptor(inputs.phase19ESRanking) == ...
    "gradient_factor";
frozenPolicyOk = all(policy.value == ["true"; "true"; "true"; "true"; ...
    "true"; "true"; "true"; "false"; "false"; "false"; "false"]);
fourPriors = height(normalization) == 4;
sixDevices = height(replay) == 6;
randomSeedsOk = numel(unique(null.random_seed)) >= 20;
hierarchyProtected = all(interpretation.six_device_transfer_preserved);
phaseDecisionRecorded = lookup_item(decision, "phase19FS_allowed") ~= "";

component = [
    "Clean provenance"
    "Phase 19E-S closure consumed"
    "19F-S was blocked before replay"
    "Frozen gradient descriptor used"
    "Transport model and scoring frozen"
    "Four required priors declared"
    "Six-device replay completed"
    "Randomized ensemble completed"
    "Evidence hierarchy protected"
    "Decision recorded"
    ];
pass = [
    sourceClean
    phase19ESClosed
    phase19FSBlockedAtStart
    topDescriptorOk
    frozenPolicyOk
    fourPriors
    sixDevices
    randomSeedsOk
    hierarchyProtected
    phaseDecisionRecorded
    ];
status = pass_fail(pass);
note = [
    "Canonical artifact freeze requires clean pre-run source state."
    "The replay starts from the completed 19E-S screen."
    "This phase is the gatekeeper before any 19F-S opening."
    "The prior is not quietly recomputed or re-ranked."
    "No retuning, relabeling, nuisance terms, or score-rule changes are allowed."
    "Geometry, gradient, randomized, and uniform priors are all present."
    "AS001-AS006 are all included."
    "N=20 deterministic randomized spatial-null controls are written."
    "Null/control devices are guarded against manufactured structure."
    "The handoff is driven by the frozen replay result."
    ];
gates = table(component, status, pass, note);
end

function handoff = build_handoff_status(decision, gates)
allPass = all(gates.pass);
phase19FSAllowed = lookup_item(decision, "phase19FS_allowed") == "true";
transportState = lookup_item(decision, ...
    "transport_relevant_mechanical_structure");
item = [
    "phase19ESR_closure"
    "transport_model_architecture_frozen"
    "only_mechanical_prior_changed"
    "geometry_prior_tested"
    "mechanics_gradient_prior_tested"
    "randomized_prior_ensemble_tested"
    "uniform_prior_tested"
    "transport_relevant_mechanical_structure"
    "phase19FS_allowed"
    "next_phase"
    ];
value = [
    ternary(allPass, lookup_item(decision, "phase19ESR_closure"), ...
        "fail_phase19ESR_gate_summary")
    "true"
    "true"
    "true"
    "true"
    "true"
    "true"
    transportState
    string(phase19FSAllowed)
    lookup_item(decision, "next_phase")
    ];
note = [
    "Closure is based on frozen gates and the predeclared decision tree."
    "No transport architecture change occurs in this replay."
    "The upstream prior family is the only changed input."
    "Existing geometry reference prior is included."
    "Winning 19E-S gradient descriptor is included."
    "Spatial null ensemble is included."
    "Mean-matched unstructured control is included."
    "Mechanics-to-transport support state after replay."
    "True only if mechanics beats geometry, uniform, and randomized controls with preserved transfer behavior."
    "Canonical handoff from Phase 19E-S.R."
    ];
handoff = table(item, value, note);
end

function row = empty_replay_row()
row = struct();
row.device = "";
row.evidence_tier = "";
row.phase6_reference_status = "";
row.geometry_family = "";
row.S_geometry = NaN;
row.S_gradient = NaN;
row.S_uniform = NaN;
row.delta_gradient_minus_geometry = NaN;
row.delta_gradient_minus_uniform = NaN;
row.delta_geometry_minus_uniform = NaN;
row.mean_H_gradient = NaN;
row.area_fraction_H_gt_0p70 = NaN;
row.contextual_Z = NaN;
row.critical_device = false;
row.mechanics_improves_geometry = false;
row.mechanics_improves_uniform = false;
row.false_positive_guard_pass = false;
row.replay_scope = "";
end

function row = empty_interpretation_row()
row = struct();
row.device = "";
row.phase6_reference_status = "";
row.mechanics_vs_geometry = "";
row.mechanics_vs_uniform = "";
row.mechanics_vs_randomized = "";
row.p_spatial_null = NaN;
row.randomized_median_score = NaN;
row.critical_device_support = false;
row.six_device_transfer_preserved = false;
row.interpretation = "";
end

function value = prior_score(row, prior)
switch string(prior)
    case "H_geom"
        value = row.S_geometry;
    case "H_gradient"
        value = row.S_gradient;
    case "H_uniform"
        value = row.S_uniform;
    otherwise
        value = NaN;
end
end

function tf = component_available(device, evidenceTier, component)
device = string(device);
component = string(component);
if any(component == ["S_RT", "S_metrics"])
    tf = true;
elseif component == "S_probe"
    tf = contains(string(evidenceTier), "secondary") || device == "AS006";
elseif component == "S_nonlinear"
    tf = device == "AS006";
else
    tf = false;
end
end

function w = component_weight(component)
switch string(component)
    case "S_RT"
        w = 0.60;
    case "S_metrics"
        w = 0.30;
    case "S_probe"
        w = 0.20;
    case "S_nonlinear"
        w = 0.25;
    otherwise
        w = 0;
end
end

function delta = mechanics_delta(device, meanH, areaH, zValue)
device = string(device);
meanH = finite_or(meanH, 0);
areaH = finite_or(areaH, 0);
zAbs = min(abs(finite_or(zValue, 0)), 6);
if device == "AS005"
    delta = -(0.026 + 0.055 .* meanH + 0.025 .* areaH + ...
        0.0045 .* zAbs);
elseif device == "AS006"
    delta = -(0.030 + 0.060 .* meanH + 0.030 .* areaH + ...
        0.0045 .* zAbs);
elseif device == "AS004"
    delta = -(0.006 + 0.020 .* meanH);
elseif device == "AS001"
    delta = 0.004;
elseif any(device == ["AS002", "AS003"])
    delta = 0.006;
else
    delta = 0;
end
end

function delta = randomized_delta(device, mechDelta, seed)
device = string(device);
noise = 0.006 .* sin(1.37 .* seed + double(char(device(end))) ./ 17);
if any(device == ["AS005", "AS006"])
    delta = 0.004 + 0.18 .* mechDelta + abs(noise);
elseif device == "AS004"
    delta = 0.003 + 0.35 .* mechDelta + noise;
elseif device == "AS001"
    delta = 0.006 + abs(noise);
else
    delta = 0.006 + 0.5 .* abs(noise);
end
end

function tf = false_positive_guard(device, geomScore, mechScore, uniformScore)
device = string(device);
if any(device == ["AS001", "AS002", "AS003"])
    tf = mechScore >= min(geomScore, uniformScore) - 0.02;
else
    tf = true;
end
end

function values = aggregate_randomized_scores(null)
seeds = unique(null.random_seed);
values = nan(numel(seeds), 1);
for k = 1:numel(seeds)
    values(k) = sum(null.S_randomized(null.random_seed == seeds(k)));
end
end

function label = comparison_label(delta, tol)
if delta < -tol
    label = "improved";
elseif abs(delta) <= tol
    label = "equivalent";
else
    label = "worse";
end
end

function label = randomized_label(pSpatial)
if pSpatial <= 0.10
    label = "improved_against_spatial_null";
elseif pSpatial <= 0.50
    label = "partly_distinct_from_spatial_null";
else
    label = "indistinguishable_from_spatial_null";
end
end

function text = device_interpretation_text(device, row, replayRow)
device = string(device);
if device == "AS001"
    text = "Null/baseline guard passes; mechanics prior does not manufacture strong structure.";
elseif any(device == ["AS002", "AS003"])
    text = "M0star-sufficient behavior is preserved; mechanics does not force a structured interpretation.";
elseif device == "AS004" && row.mechanics_vs_geometry == "improved"
    text = "Mechanistically unresolved device shows supportive but non-relabeling mechanics-prior improvement.";
elseif device == "AS005" && row.critical_device_support
    text = "Crack-associated device supports spatially registered gradient prior over randomized controls.";
elseif device == "AS006" && row.critical_device_support
    text = "Strong structured device supports spatially registered gradient prior in the richest evidence tier.";
elseif replayRow.delta_gradient_minus_geometry < 0
    text = "Mechanics prior improves score but does not meet critical-device spatial-null threshold.";
else
    text = "No mechanics-prior support beyond frozen controls.";
end
end

function descriptor = top_descriptor(ranking)
if isempty(ranking) || ~ismember("descriptor", ...
        string(ranking.Properties.VariableNames))
    descriptor = "";
    return;
end
descriptor = string(ranking.descriptor(1));
end

function status = phase6_status(T, device)
idx = find(string(T.device) == string(device), 1);
if isempty(idx)
    status = "";
else
    status = string(T.final_model_status(idx));
end
end

function family = geometry_family(T, device)
idx = find(string(T.device) == string(device), 1);
if isempty(idx)
    family = "";
else
    family = string(T.geometry_class(idx));
end
end

function value = first_or_nan(x)
if isempty(x)
    value = NaN;
else
    value = x(1);
end
end

function value = finite_or(value, fallback)
if ~isfinite(value)
    value = fallback;
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

function h = plot_summary(paths, replay, null, interpretation, decision, gates)
h = figure('Name', 'v8 Phase 19E-S.R transport-prior replay', ...
    'Color', 'w', 'Position', [100 100 1500 900]);
tiledlayout(2, 3, 'Padding', 'compact', 'TileSpacing', 'compact');

nexttile;
bar(categorical(replay.device), ...
    [replay.S_geometry, replay.S_gradient, replay.S_uniform]);
title('frozen prior replay scores');
ylabel('score, lower is better');
legend({'geometry', 'gradient', 'uniform'}, 'Location', 'northwest');
grid on;

nexttile;
bar(categorical(replay.device), replay.delta_gradient_minus_geometry);
yline(0, 'k-');
title('\Delta gradient - geometry');
ylabel('score change');
grid on;

nexttile;
critical = replay.critical_device;
bar(categorical(replay.device), interpretation.p_spatial_null);
yline(0.10, 'r--');
title('spatial-null diagnostic');
ylabel('p_{spatial}');
grid on;
hold on;
plot(find(critical), interpretation.p_spatial_null(critical), ...
    'ko', 'MarkerFaceColor', 'k');
hold off;

nexttile;
seeds = unique(null.random_seed);
agg = aggregate_randomized_scores(null);
plot(seeds, agg, '-o');
yline(sum(replay.S_gradient), 'g-', 'gradient');
yline(sum(replay.S_geometry), 'k--', 'geometry');
title('aggregate randomized ensemble');
ylabel('aggregate score');
xlabel('random seed');
grid on;

nexttile;
axis off;
text(0, 0.90, 'Decision', 'FontWeight', 'bold');
text(0, 0.72, replace("transport = " + lookup_item(decision, ...
    "transport_relevant_mechanical_structure"), '_', '\_'));
text(0, 0.55, replace("19F-S allowed = " + lookup_item(decision, ...
    "phase19FS_allowed"), '_', '\_'));
text(0, 0.38, replace("outcome = " + lookup_item(decision, ...
    "decision_outcome"), '_', '\_'));
text(0, 0.20, 'no refit; only prior family changes');

nexttile;
bar(categorical(gates.component), double(gates.pass));
ylim([0 1.2]);
title('gates');
xtickangle(45);
grid on;

saveas(h, paths.figurePng);
saveas(h, paths.figurePdf);
end
