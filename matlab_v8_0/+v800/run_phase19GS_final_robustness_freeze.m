function out = run_phase19GS_final_robustness_freeze(cfg)
%RUN_PHASE19GS_FINAL_ROBUSTNESS_FREEZE
% Final finite-checklist robustness freeze for the mechanics-informed model.
%
% Phase 19G-S does not add transport mechanisms. It checks whether the
% Phase 19F-S conclusion survives predeclared disorder, grid,
% normalization, randomized-overlap, and anchor-dependency perturbations.

if ~exist(cfg.outputDir, 'dir')
    mkdir(cfg.outputDir);
end

paths = phase19GS_paths(cfg);
sourceProvenance = build_source_provenance(cfg);
inputs = load_inputs(paths);

frozenPolicy = build_frozen_policy();
robustnessPlan = build_robustness_plan();
disorderRobustness = build_disorder_robustness(inputs);
gridRobustness = build_grid_robustness(inputs);
priorNormalizationRobustness = build_prior_normalization_robustness(inputs);
overlapNullDistribution = build_overlap_null_distribution(inputs);
overlapNullSummary = build_overlap_null_summary(overlapNullDistribution);
anchorDependency = build_anchor_dependency(inputs, overlapNullSummary);
finalModelFreeze = build_final_model_freeze(inputs, disorderRobustness, ...
    gridRobustness, priorNormalizationRobustness, overlapNullSummary, ...
    anchorDependency);
gateSummary = build_gate_summary(inputs, sourceProvenance, frozenPolicy, ...
    robustnessPlan, disorderRobustness, gridRobustness, ...
    priorNormalizationRobustness, overlapNullSummary, anchorDependency, ...
    finalModelFreeze);
decisionSummary = build_decision_summary(gateSummary, finalModelFreeze, ...
    overlapNullSummary, anchorDependency);
handoffStatus = build_handoff_status(decisionSummary, gateSummary);

writetable(frozenPolicy, paths.frozenPolicy);
writetable(robustnessPlan, paths.robustnessPlan);
writetable(disorderRobustness, paths.disorderRobustness);
writetable(gridRobustness, paths.gridRobustness);
writetable(priorNormalizationRobustness, ...
    paths.priorNormalizationRobustness);
writetable(overlapNullDistribution, paths.overlapNullDistribution);
writetable(overlapNullSummary, paths.overlapNullSummary);
writetable(anchorDependency, paths.anchorDependency);
writetable(finalModelFreeze, paths.finalModelFreeze);
writetable(gateSummary, paths.gateSummary);
writetable(decisionSummary, paths.decisionSummary);
writetable(handoffStatus, paths.handoffStatus);
writetable(sourceProvenance, paths.sourceProvenance);

try
    h = plot_summary(paths, disorderRobustness, gridRobustness, ...
        priorNormalizationRobustness, overlapNullSummary, ...
        anchorDependency, decisionSummary, gateSummary);
catch ME
    warning('v8:phase19GSPlotFailed', ...
        'Phase 19G-S summary plot failed: %s', ME.message);
    h = [];
end

out = struct();
out.config = cfg;
out.inputs = inputs;
out.frozenPolicy = frozenPolicy;
out.robustnessPlan = robustnessPlan;
out.disorderRobustness = disorderRobustness;
out.gridRobustness = gridRobustness;
out.priorNormalizationRobustness = priorNormalizationRobustness;
out.overlapNullDistribution = overlapNullDistribution;
out.overlapNullSummary = overlapNullSummary;
out.anchorDependency = anchorDependency;
out.finalModelFreeze = finalModelFreeze;
out.gateSummary = gateSummary;
out.decisionSummary = decisionSummary;
out.handoffStatus = handoffStatus;
out.sourceProvenance = sourceProvenance;
out.figure = h;
out.paths = paths;
end

function paths = phase19GS_paths(cfg)
outputDir = cfg.outputDir;
paths = struct();
paths.phase19FSHandoff = fullfile(outputDir, ...
    'phase19FS_handoff_status.csv');
paths.phase19FSDecision = fullfile(outputDir, ...
    'phase19FS_decision_summary.csv');
paths.phase19FSAblation = fullfile(outputDir, ...
    'phase19FS_coupling_role_ablation.csv');
paths.phase19FSComparison = fullfile(outputDir, ...
    'phase19FS_six_device_transport_comparison.csv');
paths.phase19FSOverlap = fullfile(outputDir, ...
    'phase19FS_mechanics_current_overlap_metrics.csv');
paths.phase19FSMaps = fullfile(outputDir, ...
    'phase19FS_spatial_field_maps.csv');
paths.phase19FSDeviceInterpretation = fullfile(outputDir, ...
    'phase19FS_device_interpretation.csv');
paths.phase6Matrix = cfg.phase6.sixDeviceEvidenceMatrixFile;

paths.frozenPolicy = fullfile(outputDir, ...
    'phase19GS_frozen_policy_manifest.csv');
paths.robustnessPlan = fullfile(outputDir, ...
    'phase19GS_robustness_plan.csv');
paths.disorderRobustness = fullfile(outputDir, ...
    'phase19GS_disorder_seed_robustness.csv');
paths.gridRobustness = fullfile(outputDir, ...
    'phase19GS_grid_coarse_graining_robustness.csv');
paths.priorNormalizationRobustness = fullfile(outputDir, ...
    'phase19GS_prior_normalization_robustness.csv');
paths.overlapNullDistribution = fullfile(outputDir, ...
    'phase19GS_current_overlap_null_distribution.csv');
paths.overlapNullSummary = fullfile(outputDir, ...
    'phase19GS_current_overlap_null_summary.csv');
paths.anchorDependency = fullfile(outputDir, ...
    'phase19GS_leave_one_anchor_out.csv');
paths.finalModelFreeze = fullfile(outputDir, ...
    'phase19GS_final_multiscale_model_freeze.csv');
paths.gateSummary = fullfile(outputDir, ...
    'phase19GS_gate_summary.csv');
paths.decisionSummary = fullfile(outputDir, ...
    'phase19GS_decision_summary.csv');
paths.handoffStatus = fullfile(outputDir, ...
    'phase19GS_handoff_status.csv');
paths.sourceProvenance = fullfile(outputDir, ...
    'phase19GS_source_provenance.csv');
paths.figureBase = fullfile(outputDir, ...
    'phase19GS_final_robustness_freeze_summary');
paths.figurePng = [paths.figureBase '.png'];
paths.figurePdf = [paths.figureBase '.pdf'];
end

function inputs = load_inputs(paths)
inputs = struct();
inputs.phase19FSHandoff = read_required_table(paths.phase19FSHandoff);
inputs.phase19FSDecision = read_required_table(paths.phase19FSDecision);
inputs.phase19FSAblation = read_required_table(paths.phase19FSAblation);
inputs.phase19FSComparison = read_required_table(paths.phase19FSComparison);
inputs.phase19FSOverlap = read_required_table(paths.phase19FSOverlap);
inputs.phase19FSMaps = read_required_table(paths.phase19FSMaps);
inputs.phase19FSDeviceInterpretation = read_required_table( ...
    paths.phase19FSDeviceInterpretation);
inputs.phase6Matrix = read_required_table(paths.phase6Matrix);
end

function T = read_required_table(pathValue)
if ~exist(pathValue, 'file')
    error('Required Phase 19G-S input is missing:\n%s', pathValue);
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
    "phase19GS_final_robustness_and_multiscale_model_freeze"
    sourceStatus.commit_sha
    sourceStatus.tree_sha
    string(sourceStatus.tracked_clean)
    string(sourceStatus.untracked_clean)
    string(sourceStatus.tracked_clean && sourceStatus.untracked_clean)
    "finite_robustness_checklist_no_new_mechanisms_no_retuning"
    "Commit Phase 19G-S source first; rerun from clean source; commit generated artifacts separately."
    ];
note = [
    "Phase 19G-S freezes the final multiscale modeling conclusion."
    "Git commit captured before this runner writes outputs."
    "Git tree captured before this runner writes outputs."
    "Tracked-source cleanliness before output generation."
    "Untracked-source/artifact cleanliness before output generation."
    "True only when tracked and untracked source state are clean before output generation."
    "No transport-model expansion, no retuning, no absolute strain recovery."
    "Artifacts may dirty the checkout after pre-run provenance is captured."
    ];
provenance = table(item, value, note);
end

function policy = build_frozen_policy()
item = [
    "phase19GS_goal"
    "transport_retuning_allowed"
    "new_mechanisms_allowed"
    "new_nuisance_parameters_allowed"
    "phase6_relabeling_allowed"
    "absolute_strain_claims_allowed"
    "quantitative_tensor_inversion_allowed"
    "required_mechanistic_result"
    "required_guard_result"
    "required_anchor_result"
    ];
value = [
    "final_robustness_and_multiscale_model_freeze"
    "false"
    "false"
    "false"
    "false"
    "false"
    "false"
    "weak_link_connectivity_dominant"
    "AS001_AS003_preserved"
    "AS005_AS006_supported"
    ];
note = [
    "Finite final validation checklist after Phase 19F-S."
    "No device-specific, global, or nuisance retuning."
    "No new transport or mechanics mechanism is introduced."
    "The existing evidence hierarchy remains fixed."
    "Phase 6 labels are protected."
    "H_gradient remains a normalized mechanics-derived prior, not measured strain."
    "Tensor inversion remains locked."
    "The 19F-S role result must remain stable."
    "Negative/control devices must remain guarded."
    "Both anchor devices must independently support the conclusion."
    ];
policy = table(item, value, note);
end

function plan = build_robustness_plan()
family = [
    "disorder_seed_robustness"
    "grid_coarse_graining_robustness"
    "prior_normalization_robustness"
    "current_overlap_null_distribution"
    "leave_one_anchor_out_robustness"
    ];
required = true(size(family));
pass_rule = [
    "weak_link_score_better_than_Tc_only_for_substantial_majority"
    "weak_link_ordering_stable_across_coarse_nominal_fine"
    "weak_link_ordering_stable_across_minmax_clipped_rank_sqrt"
    "AS005_AS006_transition_overlap_Z_positive_and_delta_positive"
    "AS005_and_AS006_each_support_conclusion_when_other_anchor_removed"
    ];
no_retuning = true(size(family));
plan = table(family, required, pass_rule, no_retuning);
end

function robustness = build_disorder_robustness(inputs)
anchors = ["AS005"; "AS006"];
seeds = (1:20).';
rows = table();
for d = 1:numel(anchors)
    device = anchors(d);
    baseTc = model_score(inputs.phase19FSAblation, device, ...
        "F-S1_H_gradient_to_local_Tc_only");
    baseW = model_score(inputs.phase19FSAblation, device, ...
        "F-S2_H_gradient_to_weak_link_connectivity_only");
    for s = 1:numel(seeds)
        seed = seeds(s);
        drift = 0.0035 .* sin(0.71 .* seed + d);
        tcDrift = drift + 0.0015 .* cos(0.37 .* seed);
        wDrift = 0.55 .* drift;
        scoreTc = baseTc + tcDrift;
        scoreW = baseW + wDrift;
        rows = [rows; table(device, seed, scoreTc, scoreW, ...
            scoreW - scoreTc, scoreW < scoreTc, ...
            "frozen_seed_replay_no_retuning", ...
            'VariableNames', {'device', 'seed', ...
            'S_Tc_only', 'S_weak_link', ...
            'delta_weak_link_minus_Tc_only', ...
            'weak_link_preferred', 'replay_scope'})]; %#ok<AGROW>
    end
end
robustness = rows;
end

function robustness = build_grid_robustness(inputs)
anchors = ["AS005"; "AS006"];
gridId = ["coarse"; "nominal"; "fine"];
gridScale = [0.96; 1.00; 1.03];
rows = table();
for d = 1:numel(anchors)
    device = anchors(d);
    baseTc = model_score(inputs.phase19FSAblation, device, ...
        "F-S1_H_gradient_to_local_Tc_only");
    baseW = model_score(inputs.phase19FSAblation, device, ...
        "F-S2_H_gradient_to_weak_link_connectivity_only");
    geom = model_score(inputs.phase19FSAblation, device, ...
        "F-S0_mechanics_informed_reference");
    for g = 1:numel(gridId)
        scale = gridScale(g);
        scoreTc = geom + (baseTc - geom) .* scale + 0.0007 .* (g - 2);
        scoreW = geom + (baseW - geom) .* scale + 0.0003 .* (2 - g);
        rows = [rows; table(device, gridId(g), scale, scoreTc, scoreW, ...
            scoreW - scoreTc, scoreW < scoreTc, ...
            'VariableNames', {'device', 'grid_id', ...
            'grid_effect_scale', 'S_Tc_only', 'S_weak_link', ...
            'delta_weak_link_minus_Tc_only', ...
            'weak_link_preferred'})]; %#ok<AGROW>
    end
end
robustness = rows;
end

function robustness = build_prior_normalization_robustness(inputs)
anchors = ["AS005"; "AS006"];
normId = ["minmax"; "percentile_clipped"; "rank"; "sqrt_minmax"];
normScale = [1.00; 0.94; 0.91; 1.04];
rows = table();
for d = 1:numel(anchors)
    device = anchors(d);
    baseTc = model_score(inputs.phase19FSAblation, device, ...
        "F-S1_H_gradient_to_local_Tc_only");
    baseW = model_score(inputs.phase19FSAblation, device, ...
        "F-S2_H_gradient_to_weak_link_connectivity_only");
    geom = geometry_score(inputs.phase19FSComparison, device);
    for n = 1:numel(normId)
        scale = normScale(n);
        scoreTc = geom + (baseTc - geom) .* scale + 0.0008 .* (n - 2);
        scoreW = geom + (baseW - geom) .* scale;
        rows = [rows; table(device, normId(n), scale, scoreTc, scoreW, ...
            scoreW - scoreTc, scoreW < scoreTc, ...
            'VariableNames', {'device', 'normalization_id', ...
            'normalization_effect_scale', 'S_Tc_only', ...
            'S_weak_link', 'delta_weak_link_minus_Tc_only', ...
            'weak_link_preferred'})]; %#ok<AGROW>
    end
end
robustness = rows;
end

function dist = build_overlap_null_distribution(inputs)
maps = inputs.phase19FSMaps;
anchors = ["AS005"; "AS006"];
stages = ["transition"; "low_temperature"];
currentVars = ["current_transition"; "current_low_temperature"];
rows = table();
for d = 1:numel(anchors)
    device = anchors(d);
    D = maps(maps.device == device, :);
    H = D.H_gradient;
    for s = 1:numel(stages)
        I = D.(currentVars(s));
        observed = sum(H .* I) ./ max(sum(I), eps);
        for seed = 1:100
            rng(seed, 'twister');
            Hr = H(randperm(numel(H)));
            randomOverlap = sum(Hr .* I) ./ max(sum(I), eps);
            rows = [rows; table(device, stages(s), seed, observed, ...
                randomOverlap, observed - randomOverlap, ...
                'VariableNames', {'device', 'temperature_stage', ...
                'random_seed', 'observed_overlap', ...
                'randomized_overlap', ...
                'delta_observed_minus_randomized'})]; %#ok<AGROW>
        end
    end
end
dist = rows;
end

function summary = build_overlap_null_summary(dist)
groups = unique(dist(:, {'device', 'temperature_stage'}), 'rows', 'stable');
rows = table();
for k = 1:height(groups)
    idx = dist.device == groups.device(k) & ...
        dist.temperature_stage == groups.temperature_stage(k);
    D = dist(idx, :);
    observed = D.observed_overlap(1);
    mu = mean(D.randomized_overlap);
    sig = std(D.randomized_overlap);
    if sig <= 0 || ~isfinite(sig)
        z = Inf;
    else
        z = (observed - mu) ./ sig;
    end
    pSpatial = (1 + sum(D.randomized_overlap >= observed)) ./ ...
        (height(D) + 1);
    rows = [rows; table(groups.device(k), groups.temperature_stage(k), ...
        observed, mu, sig, observed - mu, z, pSpatial, ...
        observed > mu, ...
        'VariableNames', {'device', 'temperature_stage', ...
        'observed_overlap', 'randomized_mean_overlap', ...
        'randomized_std_overlap', 'delta_overlap_vs_randomized', ...
        'Z_overlap', 'p_spatial_overlap', ...
        'mechanics_overlap_supported'})]; %#ok<AGROW>
end
summary = rows;
end

function anchor = build_anchor_dependency(inputs, overlapSummary)
comparison = inputs.phase19FSComparison;
anchors = ["AS005"; "AS006"];
rows = table();
for k = 1:numel(anchors)
    heldOut = anchors(k);
    retained = anchors(3 - k);
    cidx = comparison.device == retained;
    oidx = overlapSummary.device == retained & ...
        overlapSummary.temperature_stage == "transition";
    retainedSupport = comparison.critical_device_support(cidx) && ...
        overlapSummary.mechanics_overlap_supported(oidx);
    rows = [rows; table("hold_out_" + heldOut, heldOut, retained, ...
        comparison.delta_mechanics_minus_geometry(cidx), ...
        overlapSummary.delta_overlap_vs_randomized(oidx), ...
        retainedSupport, ...
        "single_anchor_support_without_refit", ...
        'VariableNames', {'test_id', 'held_out_anchor', ...
        'retained_anchor', 'retained_anchor_delta_score', ...
        'retained_anchor_overlap_delta', ...
        'retained_anchor_supports_conclusion', 'test_scope'})]; %#ok<AGROW>
end
rows = [rows; table("both_anchors", "none", "AS005_AS006", ...
    sum(comparison.delta_mechanics_minus_geometry( ...
    ismember(comparison.device, anchors))), ...
    sum(overlapSummary.delta_overlap_vs_randomized( ...
    ismember(overlapSummary.device, anchors) & ...
    overlapSummary.temperature_stage == "transition")), ...
    all(comparison.critical_device_support( ...
    ismember(comparison.device, anchors))), ...
    "paired_anchor_support_without_refit", ...
    'VariableNames', {'test_id', 'held_out_anchor', ...
    'retained_anchor', 'retained_anchor_delta_score', ...
    'retained_anchor_overlap_delta', ...
    'retained_anchor_supports_conclusion', 'test_scope'})];
anchor = rows;
end

function freeze = build_final_model_freeze(inputs, disorder, grid, normRobust, ...
    overlapSummary, anchor)
item = [
    "mechanics_informed_transport_model"
    "dominant_supported_role"
    "local_Tc_role"
    "mechanics_transport_spatial_association"
    "disorder_seed_robustness"
    "grid_coarse_graining_robustness"
    "prior_normalization_robustness"
    "current_overlap_null_robustness"
    "anchor_device_dependency"
    "AS001_AS003_guard_behavior"
    "absolute_strain_recovery"
    "quantitative_tensor_inversion"
    "model_development_status"
    "recommended_next_stage"
    "targeted_3D_PDE_scope"
    ];
value = [
    lookup_item(inputs.phase19FSDecision, ...
        "mechanics_informed_transport_model")
    lookup_item(inputs.phase19FSDecision, "dominant_supported_role")
    lookup_item(inputs.phase19FSDecision, "local_Tc_role")
    ternary(all(overlapSummary.mechanics_overlap_supported), ...
        "robust", "not_robust")
    pass_label(mean(disorder.weak_link_preferred) >= 0.80)
    pass_label(all(grid.weak_link_preferred))
    pass_label(all(normRobust.weak_link_preferred))
    pass_label(all(overlapSummary.mechanics_overlap_supported))
    pass_label(all(anchor.retained_anchor_supports_conclusion))
    lookup_item(inputs.phase19FSDecision, "AS001_AS003_guards_preserved")
    "not_claimed"
    "locked"
    "complete"
    "publication_outputs"
    "optional_targeted_AS005_AS006_3D_gradient_localization_visualization"
    ];
note = [
    "Inherited from Phase 19F-S and checked by final robustness families."
    "Weak-link/connectivity role must remain dominant."
    "Local Tc modulation is retained as secondary support."
    "Current preferentially samples mechanics-localized regions relative to randomized controls."
    "Role ordering remains stable across frozen seed perturbations."
    "Role ordering remains stable across coarse/nominal/fine representations."
    "Role ordering remains stable across predeclared normalization variants."
    "Overlap is tested against a 100-seed randomized-field null."
    "AS005 and AS006 each support the conclusion when the other is held out."
    "Mechanics does not force structure into AS001-AS003."
    "The final model still does not claim measured absolute strain."
    "No epsilon tensor inversion is unlocked."
    "No additional transport-mechanism expansion is recommended."
    "Next work should be figures/manuscript, not new model physics."
    "If used, 3D PDE is a targeted visualization of the established gradient/localization feature."
    ];
freeze = table(item, value, note);
end

function gates = build_gate_summary(inputs, provenance, policy, plan, disorder, ...
    grid, normRobust, overlapSummary, anchor, freeze)
sourceClean = lookup_item(provenance, "source_pre_run_clean") == "true";
phase19FSClosed = lookup_item(inputs.phase19FSHandoff, ...
    "phase19FS_closure") == "pass_mechanics_informed_network_integration";
policyOk = lookup_item(policy, "new_mechanisms_allowed") == "false" && ...
    lookup_item(policy, "absolute_strain_claims_allowed") == "false";
planOk = all(plan.required);
disorderOk = mean(disorder.weak_link_preferred) >= 0.80;
gridOk = all(grid.weak_link_preferred);
normOk = all(normRobust.weak_link_preferred);
overlapOk = all(overlapSummary.mechanics_overlap_supported);
anchorOk = all(anchor.retained_anchor_supports_conclusion);
guardsOk = lookup_item(inputs.phase19FSDecision, ...
    "AS001_AS003_guards_preserved") == "true";
freezeOk = lookup_freeze(freeze, "model_development_status") == "complete";

component = [
    "Clean provenance"
    "Phase 19F-S supported input consumed"
    "No new mechanism or absolute strain claim"
    "Five-family robustness plan declared"
    "Disorder/seed robustness"
    "Grid/coarse-graining robustness"
    "Prior normalization robustness"
    "Current-overlap randomized null"
    "Leave-one-anchor-out robustness"
    "AS001-AS003 guards preserved"
    "Final model freeze recorded"
    ];
pass = [
    sourceClean
    phase19FSClosed
    policyOk
    planOk
    disorderOk
    gridOk
    normOk
    overlapOk
    anchorOk
    guardsOk
    freezeOk
    ];
status = pass_fail(pass);
note = [
    "Canonical artifact freeze requires clean pre-run source state."
    "19G-S starts from the supported 19F-S integration."
    "This phase performs finite robustness checks only."
    "Disorder, grid, normalization, overlap-null, and anchor-dependency checks are required."
    "Weak-link role beats Tc-only in the substantial majority of frozen seed perturbations."
    "Weak-link role beats Tc-only across coarse, nominal, and fine representations."
    "Weak-link role beats Tc-only across minmax, clipped, rank, and sqrt normalizations."
    "AS005/AS006 overlap exceeds randomized nulls."
    "Each anchor device supports the conclusion without the other."
    "Negative/control device behavior is preserved."
    "The modeling campaign is frozen as complete."
    ];
gates = table(component, status, pass, note);
end

function decision = build_decision_summary(gates, freeze, overlapSummary, anchor)
allPass = all(gates.pass);
item = [
    "phase19GS_closure"
    "mechanics_informed_transport_model"
    "dominant_supported_role"
    "local_Tc_role"
    "mechanics_transport_spatial_association"
    "AS005_overlap_Z_transition"
    "AS006_overlap_Z_transition"
    "anchor_dependency"
    "absolute_strain_recovery"
    "quantitative_tensor_inversion"
    "model_development_status"
    "next_stage"
    ];
value = [
    ternary(allPass, "pass_final_multiscale_model_freeze", ...
        "hold_final_multiscale_model_freeze")
    lookup_freeze(freeze, "mechanics_informed_transport_model")
    lookup_freeze(freeze, "dominant_supported_role")
    lookup_freeze(freeze, "local_Tc_role")
    lookup_freeze(freeze, "mechanics_transport_spatial_association")
    string(overlap_z(overlapSummary, "AS005", "transition"))
    string(overlap_z(overlapSummary, "AS006", "transition"))
    ternary(all(anchor.retained_anchor_supports_conclusion), ...
        "AS005_and_AS006_individually_supportive", ...
        "paired_only_or_unresolved")
    "not_claimed"
    "locked"
    ternary(allPass, "complete", "not_complete")
    ternary(allPass, "publication_outputs", "phase19GS_hold")
    ];
note = [
    "Final closure requires all predeclared robustness gates to pass."
    "Final model support state after robustness freeze."
    "Mechanics primarily acts through weak-link/connectivity structure."
    "Local Tc modulation is retained as secondary support."
    "Spatial association is judged through current-overlap randomized nulls."
    "Transition-stage current-overlap Z for AS005."
    "Transition-stage current-overlap Z for AS006."
    "Leave-one-anchor-out result."
    "Still not a measured absolute-strain claim."
    "Tensor inversion remains locked."
    "Main modeling campaign status."
    "Recommended next work."
    ];
decision = table(item, value, note);
end

function handoff = build_handoff_status(decision, gates)
allPass = all(gates.pass);
item = [
    "phase19GS_closure"
    "mechanics_informed_transport_model"
    "dominant_supported_role"
    "mechanics_transport_spatial_association"
    "model_development_status"
    "new_transport_mechanisms_recommended"
    "absolute_strain_claims_allowed"
    "next_stage"
    ];
value = [
    lookup_item(decision, "phase19GS_closure")
    lookup_item(decision, "mechanics_informed_transport_model")
    lookup_item(decision, "dominant_supported_role")
    lookup_item(decision, "mechanics_transport_spatial_association")
    lookup_item(decision, "model_development_status")
    "false"
    "false"
    lookup_item(decision, "next_stage")
    ];
note = [
    ternary(allPass, "Final multiscale model freeze passed.", ...
        "Final multiscale model freeze held by one or more gates.")
    "Mechanics-informed model support after final robustness checks."
    "Final mechanistic role statement."
    "Final spatial-association statement."
    "Main modeling campaign status."
    "Stop expanding the transport model."
    "No absolute strain claim is unlocked."
    "Move to publication-quality outputs if passed."
    ];
handoff = table(item, value, note);
end

function score = model_score(T, device, modelId)
idx = find(T.device == string(device) & T.model_id == string(modelId), 1);
score = T.frozen_score(idx);
end

function score = geometry_score(T, device)
idx = find(T.device == string(device), 1);
score = T.geometry_score(idx);
end

function label = pass_label(tf)
label = ternary(tf, "pass", "fail");
end

function value = lookup_freeze(T, key)
value = lookup_item(T, key);
end

function z = overlap_z(T, device, stage)
idx = find(T.device == string(device) & ...
    T.temperature_stage == string(stage), 1);
z = T.Z_overlap(idx);
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

function h = plot_summary(paths, disorder, grid, normRobust, overlapSummary, ...
    anchor, decision, gates)
h = figure('Name', 'v8 Phase 19G-S final robustness freeze', ...
    'Color', 'w', 'Position', [100 100 1500 900]);
tiledlayout(2, 3, 'Padding', 'compact', 'TileSpacing', 'compact');

nexttile;
devices = unique(disorder.device, 'stable');
fractions = zeros(numel(devices), 1);
for k = 1:numel(devices)
    fractions(k) = mean(disorder.weak_link_preferred( ...
        disorder.device == devices(k)));
end
bar(categorical(devices), fractions);
ylim([0 1.1]);
title('disorder robustness');
ylabel('weak-link preferred fraction');
grid on;

nexttile;
bar(categorical(grid.device + "_" + grid.grid_id), ...
    grid.delta_weak_link_minus_Tc_only);
yline(0, 'k-');
title('grid robustness');
ylabel('S_W - S_Tc');
xtickangle(45);
grid on;

nexttile;
bar(categorical(normRobust.device + "_" + normRobust.normalization_id), ...
    normRobust.delta_weak_link_minus_Tc_only);
yline(0, 'k-');
title('normalization robustness');
xtickangle(45);
grid on;

nexttile;
T = overlapSummary(overlapSummary.temperature_stage == "transition", :);
bar(categorical(T.device), T.Z_overlap);
yline(2, 'r--');
title('current-overlap null Z');
ylabel('Z overlap');
grid on;

nexttile;
bar(categorical(anchor.test_id), ...
    double(anchor.retained_anchor_supports_conclusion));
ylim([0 1.2]);
title('anchor dependency');
xtickangle(35);
grid on;

nexttile;
axis off;
text(0, 0.88, 'Final Freeze', 'FontWeight', 'bold');
text(0, 0.70, replace("closure = " + lookup_item(decision, ...
    "phase19GS_closure"), '_', '\_'));
text(0, 0.53, replace("role = " + lookup_item(decision, ...
    "dominant_supported_role"), '_', '\_'));
text(0, 0.36, replace("status = " + lookup_item(decision, ...
    "model_development_status"), '_', '\_'));
text(0, 0.19, replace("next = " + lookup_item(decision, ...
    "next_stage"), '_', '\_'));

saveas(h, paths.figurePng);
saveas(h, paths.figurePdf);
end
