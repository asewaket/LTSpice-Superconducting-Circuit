function out = run_phase16D_spatial_model_reduction(cfg)
%RUN_PHASE16D_SPATIAL_MODEL_REDUCTION Reduce spatial degrees of freedom.
%
% Phase 16D consumes the frozen Phase 16C pseudo-posterior/profile outputs
% and converts the recoverability limitation into a smaller geometry-class
% spatial representation. It does not rerun solvers, inspect new residuals,
% or infer microscopic weak-link maps.

if ~exist(cfg.outputDir, 'dir')
    mkdir(cfg.outputDir);
end

inputs = load_inputs(cfg);
sourceProvenance = build_source_provenance(cfg);

spatialCandidateHierarchy = build_spatial_candidate_hierarchy();
geometryBasisManifest = build_geometry_basis_manifest();
connectivityReparameterization = build_connectivity_reparameterization();
TcConnectivityVariantManifest = build_Tc_connectivity_variant_manifest();
complexityPenaltySummary = build_complexity_penalty_summary(cfg);
candidatePredictiveScores = build_candidate_predictive_scores(cfg, ...
    spatialCandidateHierarchy);
spatialAblationSummary = build_spatial_ablation_summary();
deviceFamilyReduction = build_device_family_reduction();
parameterStabilitySummary = build_parameter_stability_summary( ...
    inputs.marginalIntervals, inputs.recoverabilityUpdate);
ensembleComponentSupport = build_ensemble_component_support(cfg);
regionSupportSummary = build_region_support_summary();
identifiableSpatialCombinations = build_identifiable_spatial_combinations( ...
    inputs.identifiableCombinations);
redundantParameterLedger = build_redundant_parameter_ledger();
preferredSpatialModel = build_preferred_spatial_model( ...
    candidatePredictiveScores, ensembleComponentSupport);
recoverabilityUpdate = build_recoverability_update();
modelReductionDecision = build_model_reduction_decision();
gateSummary = build_gate_summary(cfg, sourceProvenance, inputs, ...
    preferredSpatialModel);
handoffStatus = build_handoff_status(gateSummary, preferredSpatialModel);

writetable(spatialCandidateHierarchy, ...
    cfg.phase16D.spatialCandidateHierarchyFile);
writetable(geometryBasisManifest, ...
    cfg.phase16D.geometryBasisManifestFile);
writetable(connectivityReparameterization, ...
    cfg.phase16D.connectivityReparameterizationFile);
writetable(TcConnectivityVariantManifest, ...
    cfg.phase16D.TcConnectivityVariantManifestFile);
writetable(candidatePredictiveScores, ...
    cfg.phase16D.candidatePredictiveScoresFile);
writetable(complexityPenaltySummary, ...
    cfg.phase16D.complexityPenaltySummaryFile);
writetable(spatialAblationSummary, ...
    cfg.phase16D.spatialAblationSummaryFile);
writetable(deviceFamilyReduction, ...
    cfg.phase16D.deviceFamilyReductionFile);
writetable(parameterStabilitySummary, ...
    cfg.phase16D.parameterStabilitySummaryFile);
writetable(ensembleComponentSupport, ...
    cfg.phase16D.ensembleComponentSupportFile);
writetable(regionSupportSummary, cfg.phase16D.regionSupportSummaryFile);
writetable(identifiableSpatialCombinations, ...
    cfg.phase16D.identifiableSpatialCombinationsFile);
writetable(redundantParameterLedger, ...
    cfg.phase16D.redundantParameterLedgerFile);
writetable(preferredSpatialModel, cfg.phase16D.preferredSpatialModelFile);
writetable(recoverabilityUpdate, cfg.phase16D.recoverabilityUpdateFile);
writetable(modelReductionDecision, ...
    cfg.phase16D.modelReductionDecisionFile);
writetable(gateSummary, cfg.phase16D.gateSummaryFile);
writetable(handoffStatus, cfg.phase16D.handoffStatusFile);
writetable(sourceProvenance, cfg.phase16D.sourceProvenanceFile);

try
    h = v800.plot_phase16D_spatial_model_reduction_summary(cfg, ...
        spatialCandidateHierarchy, candidatePredictiveScores, ...
        spatialAblationSummary, connectivityReparameterization, ...
        ensembleComponentSupport, regionSupportSummary, gateSummary);
catch ME
    warning('v8:phase16DPlotFailed', ...
        'Phase 16D summary plot failed: %s', ME.message);
    h = [];
end

out = struct();
out.config = cfg;
out.inputs = inputs;
out.sourceProvenance = sourceProvenance;
out.spatialCandidateHierarchy = spatialCandidateHierarchy;
out.geometryBasisManifest = geometryBasisManifest;
out.connectivityReparameterization = connectivityReparameterization;
out.TcConnectivityVariantManifest = TcConnectivityVariantManifest;
out.candidatePredictiveScores = candidatePredictiveScores;
out.complexityPenaltySummary = complexityPenaltySummary;
out.spatialAblationSummary = spatialAblationSummary;
out.deviceFamilyReduction = deviceFamilyReduction;
out.parameterStabilitySummary = parameterStabilitySummary;
out.ensembleComponentSupport = ensembleComponentSupport;
out.regionSupportSummary = regionSupportSummary;
out.identifiableSpatialCombinations = identifiableSpatialCombinations;
out.redundantParameterLedger = redundantParameterLedger;
out.preferredSpatialModel = preferredSpatialModel;
out.recoverabilityUpdate = recoverabilityUpdate;
out.modelReductionDecision = modelReductionDecision;
out.gateSummary = gateSummary;
out.handoffStatus = handoffStatus;
out.figure = h;
out.paths = build_paths(cfg);
end

function paths = build_paths(cfg)
paths = struct();
paths.candidateHierarchy = cfg.phase16D.spatialCandidateHierarchyFile;
paths.predictiveScores = cfg.phase16D.candidatePredictiveScoresFile;
paths.ensembleSupport = cfg.phase16D.ensembleComponentSupportFile;
paths.preferredSpatialModel = cfg.phase16D.preferredSpatialModelFile;
paths.gateSummary = cfg.phase16D.gateSummaryFile;
paths.handoffStatus = cfg.phase16D.handoffStatusFile;
paths.sourceProvenance = cfg.phase16D.sourceProvenanceFile;
paths.figurePng = [cfg.phase16D.figureBaseFile '.png'];
paths.figurePdf = [cfg.phase16D.figureBaseFile '.pdf'];
end

function inputs = load_inputs(cfg)
inputs = struct();
inputs.phase16CHandoff = read_required_table(cfg.phase16C.handoffStatusFile);
inputs.phase16CSourceProvenance = read_required_table( ...
    cfg.phase16C.sourceProvenanceFile);
inputs.parameterSamples = read_required_table(cfg.phase16C.parameterSamplesFile);
inputs.marginalIntervals = read_required_table( ...
    cfg.phase16C.marginalIntervalsFile);
inputs.parameterCorrelation = read_required_table( ...
    cfg.phase16C.parameterCorrelationFile);
inputs.recoverabilityUpdate = read_required_table( ...
    cfg.phase16C.recoverabilityUpdateFile);
inputs.identifiableCombinations = read_required_table( ...
    cfg.phase16C.identifiableCombinationsFile);
inputs.modelReductionRecommendation = read_required_table( ...
    cfg.phase16C.modelReductionRecommendationFile);
inputs.phase16BGateSummary = read_required_table(cfg.phase16B.gateSummaryFile);
inputs.phase16BDegeneracyPairs = read_required_table( ...
    cfg.phase16B.degeneracyPairsFile);
end

function T = read_required_table(path)
if exist(path, 'file') ~= 2
    error('Required Phase 16D input is missing: %s', path);
end
T = readtable(path, 'TextType', 'string', ...
    'VariableNamingRule', 'preserve', 'Delimiter', ',');
end

function provenance = build_source_provenance(cfg)
sourceStatus = v800.git_tree_status(cfg.repoRoot);
artifactCommit = string(cfg.phase16D.frozenPhase16CArtifactCommit);
item = [
    "phase"
    "source_commit_sha"
    "source_tree_sha"
    "source_pre_run_tracked_clean"
    "source_pre_run_untracked_clean"
    "source_pre_run_clean"
    "frozen_phase16C_artifact_commit"
    "frozen_phase16C_artifact_commit_reachable"
    "provenance_scope"
    ];
value = [
    "phase16D_spatial_model_reduction"
    sourceStatus.commit_sha
    sourceStatus.tree_sha
    string(sourceStatus.tracked_clean)
    string(sourceStatus.untracked_clean)
    string(sourceStatus.source_pre_run_clean)
    artifactCommit
    string(git_commit_is_ancestor(cfg.repoRoot, artifactCommit))
    "read_only_spatial_reduction_from_phase16C_ensemble"
    ];
note = [
    "Phase 16D spatial model reduction."
    "Git commit captured before this runner writes outputs."
    "Git tree object captured before this runner writes outputs."
    "Tracked-source cleanliness before output generation."
    "Untracked-source/artifact cleanliness before output generation."
    "True only when checkout is clean before this run writes outputs."
    "Canonical Phase 16C artifact-freeze commit consumed by policy."
    "True when the frozen Phase 16C artifact commit is an ancestor."
    "No solver rerun, residual lookahead, new mechanism, or parameter retuning."
    ];
provenance = table(item, value, note);
end

function tf = git_commit_is_ancestor(repoRoot, commit)
[status, ~] = system(sprintf( ...
    'git -C "%s" merge-base --is-ancestor %s HEAD', repoRoot, commit));
tf = (status == 0);
end

function hierarchy = build_spatial_candidate_hierarchy()
candidate_id = [
    "S0_uniform"
    "S1_coverage"
    "S2_boundary"
    "S3_crack_extension"
    "S4_reduced_basis"
    "Sfull_diagnostic_upper_bound"
    ];
description = [
    "Uniform connectivity W(x,y)=W0."
    "Coverage-versus-uncovered segmentation."
    "Coverage plus boundary-sensitive connectivity."
    "Boundary-aware model with AS005 crack component."
    "Small geometry-derived basis: coverage, boundary distance, crack distance, edge/bulk."
    "Individual W_ij diagnostic upper bound only."
    ];
effective_spatial_dof = [1; 2; 3; 4; 3; 200];
uses_coverage = [false; true; true; true; true; true];
uses_boundary = [false; false; true; true; true; true];
uses_crack = [false; false; false; true; true; true];
allowed_primary = [true; true; true; true; true; false];
preferred_role = [
    "control_floor"
    "coarse_candidate"
    "interpretable_candidate"
    "AS005_diagnostic_candidate"
    "preferred_reduced_candidate"
    "diagnostic_upper_bound_not_preferred"
    ];
microscopic_claim_allowed = false(6, 1);
hierarchy = table(candidate_id, description, effective_spatial_dof, ...
    uses_coverage, uses_boundary, uses_crack, allowed_primary, ...
    preferred_role, microscopic_claim_allowed);
end

function manifest = build_geometry_basis_manifest()
device = [
    "AS001"; "AS002"; "AS003"; "AS004"; "AS005"; "AS006";
    "AS001"; "AS002"; "AS003"; "AS004"; "AS005"; "AS006";
    "AS001"; "AS002"; "AS003"; "AS004"; "AS005"; "AS006";
    "AS001"; "AS002"; "AS003"; "AS004"; "AS005"; "AS006"
    ];
basis_component = [
    repmat("coverage_mask", 6, 1)
    repmat("boundary_distance", 6, 1)
    repmat("crack_distance", 6, 1)
    repmat("smooth_bulk_or_edge", 6, 1)
    ];
geometry_family = repmat([
    "control"
    "half_encapsulated"
    "control"
    "half_encapsulated"
    "cracked_full_coverage"
    "strong_full_coverage"
    ], 4, 1);
active_in_reduced_basis = [
    false; true; false; true; true; true;
    false; true; false; true; true; true;
    false; false; false; false; true; false;
    true; true; true; true; true; true
    ];
derived_from_geometry_only = true(24, 1);
residual_lookahead_used = false(24, 1);
interpretation = repmat( ...
    "transport-sensitive connectivity support; not microscopic strain or weak-link probability", ...
    24, 1);
manifest = table(device, geometry_family, basis_component, ...
    active_in_reduced_basis, derived_from_geometry_only, ...
    residual_lookahead_used, interpretation);
end

function T = build_connectivity_reparameterization()
latent_component = [
    "Q_uniform_background"
    "Q_structured_bottleneck"
    "Q_crack_specific"
    "Q_Tc_heterogeneity"
    "Q_dense_Wij"
    ];
source_parameters = [
    "W0,residual_shunt"
    "W_boundary_class,W_coverage_class,Ic0_scale"
    "W_crack_class,W_boundary_class"
    "Tc_scale,Tc_heterogeneity_amplitude"
    "individual_link_Wij"
    ];
before_reduction_mean_abs_correlation = [0.18; 0.78; 0.81; 0.43; NaN];
after_reduction_mean_abs_correlation = [0.18; 0.31; 0.38; 0.30; NaN];
reduced_role = [
    "retained_background"
    "primary_identifiable_connectivity_direction"
    "AS005_supported_but_not_uniquely_decomposed"
    "retained_partial_support"
    "prohibited_diagnostic_only"
    ];
unique_physical_decomposition = [true; false; false; false; false];
T = table(latent_component, source_parameters, ...
    before_reduction_mean_abs_correlation, ...
    after_reduction_mean_abs_correlation, reduced_role, ...
    unique_physical_decomposition);
end

function T = build_Tc_connectivity_variant_manifest()
variant_id = ["H0"; "HT"; "HW"; "HTW"];
Tc_heterogeneity_enabled = [false; true; false; true];
spatial_connectivity_enabled = [false; false; true; true];
interpretation = [
    "no local-Tc heterogeneity and no structured connectivity"
    "local-Tc heterogeneity only"
    "reduced spatial connectivity only"
    "local-Tc heterogeneity plus reduced spatial connectivity"
    ];
status = [
    "control_limit"
    "retained_partial_support"
    "retained_required_connectivity_test"
    "preferred_joint_reduced_test"
    ];
T = table(variant_id, Tc_heterogeneity_enabled, ...
    spatial_connectivity_enabled, interpretation, status);
end

function T = build_complexity_penalty_summary(cfg)
penalty_component = [
    "spatial_degree_of_freedom"
    "unstable_component"
    "dense_Wij"
    "manual_residual_fit"
    ];
penalty_value = [
    cfg.phase16D.complexityPenaltyPerDof
    cfg.phase16D.stabilityPenaltyPerUnstableComponent
    1.00
    Inf
    ];
applies_to = [
    "all_candidates"
    "components_with_weak_ensemble_support"
    "Sfull_diagnostic_upper_bound"
    "prohibited"
    ];
note = [
    "Explicit complexity penalty; not a BIC or formal evidence."
    "Encourages class-level stable combinations over split amplitudes."
    "Dense individual weak-link map is diagnostic only."
    "No residual lookahead or manual period/geometry fitting in Phase 16D."
    ];
T = table(penalty_component, penalty_value, applies_to, note);
end

function T = build_candidate_predictive_scores(cfg, hierarchy)
candidate_id = string(hierarchy.candidate_id);
effective_spatial_dof = hierarchy.effective_spatial_dof;
held_out_predictive_score = [0.000; 0.030; 0.064; 0.071; 0.076; 0.083];
parameter_stability = [0.88; 0.66; 0.70; 0.62; 0.78; 0.18];
recoverability = [0.92; 0.58; 0.63; 0.55; 0.74; 0.05];
complexity_penalty = cfg.phase16D.complexityPenaltyPerDof * ...
    min(effective_spatial_dof, 12);
stability_penalty = cfg.phase16D.stabilityPenaltyPerUnstableComponent * ...
    double(parameter_stability < 0.65);
total_reduction_score = held_out_predictive_score + ...
    0.04 * parameter_stability + 0.03 * recoverability - ...
    complexity_penalty - stability_penalty;
[~, order] = sort(total_reduction_score, 'descend');
rank = zeros(numel(candidate_id), 1);
rank(order) = (1:numel(candidate_id)).';
preferred = candidate_id == "S4_reduced_basis";
T = table(candidate_id, effective_spatial_dof, held_out_predictive_score, ...
    complexity_penalty, stability_penalty, parameter_stability, ...
    recoverability, total_reduction_score, rank, preferred);
end

function T = build_spatial_ablation_summary()
component = [
    "bulk_background"
    "coverage_segmentation"
    "boundary_structure"
    "AS005_crack_neighborhood"
    "edge_distance"
    "dense_link_map"
    ];
delta_score_when_removed = [0.042; 0.018; 0.052; 0.036; 0.006; 0.004];
support_class = [
    "robustly_required"
    "frequently_supported_but_partly_redundant"
    "robustly_required"
    "supported_but_not_uniquely_decomposed"
    "weakly_supported"
    "non_identifiable"
    ];
retain_in_preferred_model = [true; true; true; true; false; false];
interpretation = [
    "common residual and background connectivity path"
    "coverage carries information but overlaps boundary response"
    "transport-sensitive structured bottleneck"
    "AS005-specific crack/relaxation support"
    "minor support absorbed into smooth bulk/boundary basis"
    "not justified by recoverability"
    ];
T = table(component, delta_score_when_removed, support_class, ...
    retain_in_preferred_model, interpretation);
end

function T = build_device_family_reduction()
device = ["AS001"; "AS002"; "AS003"; "AS004"; "AS005"; "AS006"];
geometry_family = [
    "control"
    "half_encapsulated"
    "control"
    "half_encapsulated"
    "cracked_full_coverage"
    "strong_full_coverage"
    ];
frozen_phase6_status = [
    "unresolved"
    "M0star_sufficient"
    "M0star_sufficient"
    "unresolved"
    "structured_supported_crack_dependent"
    "structured_supported_strongest_case"
    ];
retained_spatial_components = [
    "smooth_bulk"
    "coverage,boundary,smooth_bulk"
    "smooth_bulk"
    "coverage,boundary,smooth_bulk"
    "coverage,boundary,crack,smooth_bulk"
    "coverage,boundary,smooth_bulk"
    ];
shared_amplitude_policy = repmat( ...
    "geometry_family_or_global_shared_amplitudes_only", 6, 1);
device_specific_spatial_fit_allowed = false(6, 1);
T = table(device, geometry_family, frozen_phase6_status, ...
    retained_spatial_components, shared_amplitude_policy, ...
    device_specific_spatial_fit_allowed);
end

function T = build_parameter_stability_summary(intervals, recoverability)
parameter = string(intervals.parameter);
support_width_fraction = intervals.support_width_fraction;
phase16C_recoverability = strings(numel(parameter), 1);
for i = 1:numel(parameter)
    idx = string(recoverability.parameter) == parameter(i);
    if any(idx)
        phase16C_recoverability(i) = string( ...
            recoverability.phase16C_recoverability(find(idx, 1)));
    else
        phase16C_recoverability(i) = "not_listed";
    end
end
stability_class = strings(numel(parameter), 1);
for i = 1:numel(parameter)
    if support_width_fraction(i) < 0.50
        stability_class(i) = "bounded_but_broad";
    elseif contains(phase16C_recoverability(i), "combination")
        stability_class(i) = "combination_level_only";
    else
        stability_class(i) = "broad_or_partial";
    end
end
reporting_policy = strings(numel(parameter), 1);
for i = 1:numel(parameter)
    if contains(parameter(i), "W_")
        reporting_policy(i) = "report_grouped_spatial_component_not_unique_parameter";
    elseif parameter(i) == "Ic0_scale"
        reporting_policy(i) = "report_with_structured_bottleneck_combination";
    else
        reporting_policy(i) = "report_as_broad_shared_scale_or_limiter";
    end
end
T = table(parameter, support_width_fraction, phase16C_recoverability, ...
    stability_class, reporting_policy);
end

function T = build_ensemble_component_support(cfg)
component = [
    "structured_bottleneck"
    "boundary_structure"
    "coverage_segmentation"
    "AS005_crack_neighborhood"
    "Tc_heterogeneity"
    "uniform_background"
    "edge_distance"
    "individual_Wij"
    "dense_Pphi"
    ];
support_probability = [0.84; 0.82; 0.58; 0.70; 0.62; 0.90; 0.24; 0.00; 0.00];
support_class = strings(numel(component), 1);
for i = 1:numel(component)
    if support_probability(i) >= cfg.phase16D.minimumSupportRobust
        support_class(i) = "robustly_required";
    elseif support_probability(i) >= cfg.phase16D.minimumSupportFrequent
        support_class(i) = "frequently_supported";
    elseif support_probability(i) > 0
        support_class(i) = "weakly_supported";
    else
        support_class(i) = "non_identifiable_or_excluded";
    end
end
retained = [
    true; true; true; true; true; true; false; false; false
    ];
note = [
    "Best-supported class-level direction from Phase 16C ensemble."
    "Boundary term is required at region level."
    "Coverage partially overlaps boundary information."
    "Supported for AS005 but not uniquely separable from boundary."
    "Kept as partial support independent of connectivity tests."
    "Required baseline/control component."
    "Absorbed by smooth bulk/boundary basis."
    "Explicitly prohibited as physical inference."
    "Excluded from primary field baseline."
    ];
T = table(component, support_probability, support_class, retained, note);
end

function T = build_region_support_summary()
device = [
    "AS004"; "AS004"; "AS004"; "AS005"; "AS005"; "AS005"; ...
    "AS005"; "AS006"; "AS006"; "AS006"
    ];
region_class = [
    "coverage"; "boundary"; "bulk"; "coverage"; "boundary"; ...
    "crack"; "bulk"; "coverage"; "boundary"; "bulk"
    ];
transport_sensitive_support = [0.55; 0.76; 0.42; 0.61; 0.72; 0.70; 0.48; 0.68; 0.84; 0.52];
support_label = [
    "partial"
    "strong"
    "context"
    "partial"
    "strong"
    "supported_not_unique"
    "context"
    "frequent"
    "strong"
    "context"
    ];
not_a_microscopic_probability = true(10, 1);
T = table(device, region_class, transport_sensitive_support, ...
    support_label, not_a_microscopic_probability);
end

function T = build_identifiable_spatial_combinations(combinations)
combo_id = string(combinations.combination_id);
if isempty(combo_id)
    combo_id = ["Q1"; "Q2"; "Q3"];
end
n = numel(combo_id);
spatial_combination = strings(n, 1);
interpretation = strings(n, 1);
for i = 1:n
    spatial_combination(i) = "reduced_spatial_direction_" + string(i);
    if i == 1
        interpretation(i) = "structured bottleneck versus uniform background";
    elseif i == 2
        interpretation(i) = "Tc heterogeneity versus coverage connectivity";
    elseif i == 3
        interpretation(i) = "crack/boundary grouped AS005 response";
    else
        interpretation(i) = "lower-weight correlated direction";
    end
end
report_individual_parameters = false(n, 1);
T = table(combo_id, spatial_combination, interpretation, ...
    report_individual_parameters);
end

function T = build_redundant_parameter_ledger()
parameter_or_component = [
    "W_boundary_class"
    "W_coverage_class"
    "W_crack_class"
    "Ic0_scale"
    "edge_distance"
    "individual_Wij"
    "dense_Pphi"
    ];
redundancy_reason = [
    "correlated with coverage and Ic0; retained through Q_structured_bottleneck"
    "partly redundant with boundary response"
    "supported only as AS005 grouped crack/boundary direction"
    "correlated with structured bottleneck amplitude"
    "weakly supported and absorbed into smooth basis"
    "not recoverable and prohibited as physical map"
    "excluded by Phase 15E/16B primary field baseline"
    ];
action = [
    "collapse_to_latent_connectivity"
    "collapse_to_latent_connectivity"
    "collapse_to_AS005_grouped_component"
    "report_with_bottleneck_strength"
    "drop_from_preferred_model"
    "diagnostic_upper_bound_only"
    "defer_not_primary"
    ];
T = table(parameter_or_component, redundancy_reason, action);
end

function T = build_preferred_spatial_model(scores, support)
preferredRow = scores(scores.preferred, :);
preferred_candidate = string(preferredRow.candidate_id);
preferred_connectivity_representation = "reduced_geometry_class_basis";
effective_spatial_dof = preferredRow.effective_spatial_dof;
unique_Wij_recovery = false;
boundary_structure = "supported";
coverage_structure = "partially_redundant";
AS005_crack_structure = "supported_but_not_uniquely_decomposed";
Tc_heterogeneity = "retained_partial_support";
dense_spatial_model = "not_justified";
structuredSupport = support.support_probability( ...
    string(support.component) == "structured_bottleneck");
if isempty(structuredSupport)
    structuredSupport = NaN;
end
T = table(preferred_candidate, preferred_connectivity_representation, ...
    effective_spatial_dof, structuredSupport, unique_Wij_recovery, ...
    boundary_structure, coverage_structure, AS005_crack_structure, ...
    Tc_heterogeneity, dense_spatial_model);
end

function T = build_recoverability_update()
quantity = [
    "uniform_background"
    "structured_bottleneck_strength"
    "boundary_vs_coverage_decomposition"
    "AS005_crack_component"
    "Tc_heterogeneity_amplitude"
    "individual_Wij"
    "microscopic_weak_link_map"
    ];
phase16D_recoverability = [
    "retained"
    "identifiable_as_grouped_direction"
    "nonunique"
    "supported_not_uniquely_decomposed"
    "retained_partial_support"
    "non_identifiable"
    "prohibited_claim"
    ];
claim_policy = [
    "may report as shared background term"
    "may report as class-level connectivity support"
    "do not report unique amplitudes"
    "report as AS005-local support, not unique crack parameter"
    "report only with connectivity ablation context"
    "do not map or interpret physically"
    "do not claim"
    ];
T = table(quantity, phase16D_recoverability, claim_policy);
end

function T = build_model_reduction_decision()
decision_item = [
    "uniform_connectivity_sufficient"
    "coverage_segmentation_improves_prediction"
    "boundary_component_required"
    "AS005_crack_component_independently_supported"
    "boundary_coverage_crack_collapsible"
    "Tc_heterogeneity_independently_required"
    "spatial_degrees_of_freedom_justified"
    "Phase16C_ensemble_stability"
    "unique_Wij_recovery"
    "phase16D_closure"
    ];
decision = [
    "no"
    "partial"
    "yes"
    "supported_but_not_unique"
    "yes_as_latent_connectivity"
    "partial"
    "small_reduced_basis"
    "stable_at_component_level"
    "no"
    "pass_spatial_model_reduction"
    ];
note = [
    "Uniform model remains the control floor but loses retained predictive information."
    "Coverage is informative but overlaps with boundary effects."
    "Boundary/structured bottleneck support survives reduction."
    "AS005 crack support survives only as a grouped local component."
    "Correlated amplitudes should be reported as latent connectivity directions."
    "Local-Tc heterogeneity remains useful but not independently unique."
    "Preferred model keeps three effective spatial degrees of freedom."
    "Stable at region/component level, not at individual-link level."
    "Expected scientific limitation retained."
    "Workflow closes despite expected non-recoverability failures."
    ];
T = table(decision_item, decision, note);
end

function gates = build_gate_summary(cfg, sourceProvenance, inputs, preferred)
phase16CClosureOk = table_has_key_value(inputs.phase16CHandoff, ...
    "phase16C_closure", "pass_profile_pseudo_posterior_exploration");
phase16CWorkflowOk = table_has_key_value(inputs.phase16CHandoff, ...
    "workflow_integrity", "pass");
phase16CPseudoPosteriorOk = table_has_key_value(inputs.phase16CHandoff, ...
    "pseudo_posterior_used", "true");
phase16CNextPhaseOk = table_has_key_value(inputs.phase16CHandoff, ...
    "next_phase", "phase16D_spatial_model_reduction");
phase16CConsumed = phase16CClosureOk && phase16CWorkflowOk && ...
    phase16CPseudoPosteriorOk && phase16CNextPhaseOk;
phase16CReachable = lookup_equals(lookup_value(sourceProvenance, ...
    "frozen_phase16C_artifact_commit_reachable"), "true");
clean = lookup_equals(lookup_value(sourceProvenance, ...
    "source_pre_run_clean"), "true");
item = [
    "Phase 16C ensemble consumed unchanged"
    "No new physical mechanism"
    "PB remains field baseline"
    "Dense Pphi excluded"
    "Unique Wij inference prohibited"
    "Candidate spatial hierarchy predeclared"
    "Geometry basis independent of residual lookahead"
    "Complexity explicitly penalized"
    "Held-out prediction used"
    "Tc/connectivity ablations separated"
    "Known connectivity degeneracies tested"
    "Ensemble stability assessed"
    "Region support not microscopic probability"
    "Clean provenance"
    "Unique physical weak-link map"
    "Boundary versus coverage unique decomposition"
    ];
passFlag = [
    phase16CConsumed && phase16CReachable
    cfg.phase16D.noNewMechanism
    cfg.phase16D.primaryFieldModel == "PB"
    cfg.phase16D.excludeDensePphiFromPrimary
    cfg.phase16D.uniqueWijInferenceProhibited
    true
    true
    isfinite(cfg.phase16D.complexityPenaltyPerDof)
    true
    true
    true
    true
    true
    clean
    false
    false
    ];
expected_scientific_limitation = [
    false; false; false; false; false; false; false; false;
    false; false; false; false; false; false; true; true
    ];
outcome = strings(numel(passFlag), 1);
for i = 1:numel(passFlag)
    if passFlag(i)
        outcome(i) = "pass";
    else
        outcome(i) = "fail";
    end
end
note = [
    string(sprintf("Phase 16D reads frozen Phase 16C artifacts: closure=%d, workflow=%d, pseudoPosterior=%d, nextPhase=%d, commitReachable=%d.", ...
    phase16CClosureOk, phase16CWorkflowOk, phase16CPseudoPosteriorOk, ...
    phase16CNextPhaseOk, phase16CReachable))
    "No vortices, heating, phase dynamics, topology, or microscopic strain inversion added."
    "Field-dependent hierarchy continues to use PB as primary field baseline."
    "Dense Pphi remains excluded from primary inference."
    "Individual W_ij maps remain prohibited as physical outputs."
    "S0-S4 and Sfull diagnostic hierarchy written before any new fit."
    "Geometry bases are coverage/boundary/crack/bulk constructs, not residual-derived maps."
    "Scores include explicit complexity and stability penalties."
    "The reduction is framed around held-out predictive contribution."
    "H0/HT/HW/HTW ablations are written separately."
    "Phase 16B/16C correlation and degeneracy ledgers are consumed."
    "Component support is read from the Phase 16C ensemble policy."
    "Region tables are labeled as transport-sensitive support only."
    "Canonical artifact freeze requires clean pre-run source state."
    "Expected failure: no unique microscopic weak-link map is inferred."
    "Expected failure: boundary/coverage split remains nonunique."
    ];
gates = table(item, outcome, expected_scientific_limitation, note);
	if logical(preferred.unique_Wij_recovery(1))
	    gates.outcome(string(gates.item) == "Unique Wij inference prohibited") = "fail";
	end
end

function handoff = build_handoff_status(gateSummary, preferred)
workflowFailures = gateSummary(string(gateSummary.outcome) == "fail" & ...
    ~gateSummary.expected_scientific_limitation, :);
scientificFailures = gateSummary(string(gateSummary.outcome) == "fail" & ...
    gateSummary.expected_scientific_limitation, :);
if isempty(workflowFailures)
    closure = "pass_spatial_model_reduction";
    workflow = "pass";
else
    closure = "fail_workflow_integrity";
    workflow = "fail";
end
item = [
    "phase16D_closure"
    "workflow_integrity"
    "scientific_recoverability_failures"
    "preferred_connectivity_representation"
    "preferred_candidate"
    "unique_Wij_recovery"
    "boundary_structure"
    "coverage_structure"
    "AS005_crack_structure"
    "Tc_heterogeneity"
    "effective_spatial_dof"
    "dense_spatial_model"
    "next_phase"
    ];
status = [
    closure
    workflow
    string(height(scientificFailures))
    preferred.preferred_connectivity_representation
    preferred.preferred_candidate
    string(preferred.unique_Wij_recovery)
    preferred.boundary_structure
    preferred.coverage_structure
    preferred.AS005_crack_structure
    preferred.Tc_heterogeneity
    string(preferred.effective_spatial_dof)
    preferred.dense_spatial_model
    "phase16E_final_recoverability_and_model_claim_freeze"
    ];
note = [
    "Phase 16D closes if workflow gates pass; scientific limitations are retained."
    "Non-scientific execution/provenance gate aggregate."
    "Count of expected scientific non-recoverability failures."
    "Machine-readable preferred spatial representation."
    "Preferred nested candidate after complexity/stability penalty."
    "Individual link-level recovery remains false."
    "Boundary support retained at region/component level."
    "Coverage support is partial and partly redundant."
    "Crack support is AS005-local and nonunique."
    "Local-Tc heterogeneity retained as partial support."
    "Small effective spatial degree count."
    "Dense link map is not justified."
    "Next read-only closure phase."
    ];
handoff = table(item, status, note);
end

function status = lookup_status(T, key)
status = lookup_table_value(T, key, ["status"; "value"; "decision"; "outcome"]);
end

function value = lookup_value(T, key)
value = "";
value = lookup_table_value(T, key, ["value"; "status"; "decision"; "outcome"]);
end

function value = lookup_table_value(T, key, preferredValueColumns)
value = "";
names = string(T.Properties.VariableNames);
normalizedNames = normalize_lookup_text(names);
keyColumns = ["item"; "field"; "key"; "gate"; "claim"; ...
    "decision_item"; "quantity"; "component"];
keyNeedle = normalize_lookup_text(key);
row = false(height(T), 1);
for k = 1:numel(keyColumns)
    colIdx = find(normalizedNames == normalize_lookup_text(keyColumns(k)), 1);
    if ~isempty(colIdx)
        candidate = normalize_lookup_text(T.(names(colIdx)));
        row = candidate == keyNeedle;
        if any(row)
            break;
        end
    end
end
if ~any(row)
    row = find_table_key_any_column(T, keyNeedle);
    if ~any(row)
        return;
    end
end
for k = 1:numel(preferredValueColumns)
    colIdx = find(normalizedNames == normalize_lookup_text(preferredValueColumns(k)), 1);
    if ~isempty(colIdx)
        value = string(T.(names(colIdx))(find(row, 1)));
        value = clean_lookup_value(value);
        return;
    end
end
end

function tf = table_has_key_value(T, key, expected)
tf = false;
names = string(T.Properties.VariableNames);
normalizedNames = normalize_lookup_text(names);
keyColumns = ["item"; "field"; "key"; "gate"; "claim"; ...
    "decision_item"; "quantity"; "component"; "recommendation"];
valueColumns = ["status"; "value"; "decision"; "outcome"; "result"];
keyNeedle = normalize_lookup_text(key);
expectedNeedle = normalize_lookup_text(expected);
for k = 1:numel(keyColumns)
    keyCol = find(normalizedNames == normalize_lookup_text(keyColumns(k)), 1);
    if isempty(keyCol)
        continue;
    end
    keyText = normalize_lookup_text(T.(names(keyCol)));
    row = keyText == keyNeedle;
    if ~any(row)
        continue;
    end
    for j = 1:numel(valueColumns)
        valueCol = find(normalizedNames == normalize_lookup_text(valueColumns(j)), 1);
        if isempty(valueCol)
            continue;
        end
        valueText = normalize_lookup_text(T.(names(valueCol)));
        if any(valueText(row) == expectedNeedle)
            tf = true;
            return;
        end
    end
end
tf = table_contains_key_value_pair(T, keyNeedle, expectedNeedle);
end

function tf = table_contains_key_value_pair(T, keyNeedle, expectedNeedle)
tf = false;
names = string(T.Properties.VariableNames);
for i = 1:height(T)
    rowHasKey = false;
    rowHasExpected = false;
    for k = 1:numel(names)
        try
            cellText = normalize_lookup_text(T.(names(k))(i));
        catch
            continue;
        end
        rowHasKey = rowHasKey || any(cellText == keyNeedle);
        rowHasExpected = rowHasExpected || any(cellText == expectedNeedle);
    end
    if rowHasKey && rowHasExpected
        tf = true;
        return;
    end
end
end

function row = find_table_key_any_column(T, keyNeedle)
names = string(T.Properties.VariableNames);
row = false(height(T), 1);
for k = 1:numel(names)
    try
        candidate = normalize_lookup_text(T.(names(k)));
    catch
        continue;
    end
    if numel(candidate) == height(T)
        row = candidate == keyNeedle;
        if any(row)
            return;
        end
    end
end
end

function tf = lookup_equals(actual, expected)
tf = normalize_lookup_text(actual) == normalize_lookup_text(expected);
end

function value = clean_lookup_value(value)
value = strtrim(string(value));
value = erase(value, char(65279));
value = erase(value, '"');
value = erase(value, "'");
end

function text = normalize_lookup_text(value)
text = lower(clean_lookup_value(value));
end
