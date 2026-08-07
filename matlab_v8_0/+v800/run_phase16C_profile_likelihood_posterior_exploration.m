function out = run_phase16C_profile_likelihood_posterior_exploration(cfg)
%RUN_PHASE16C_PROFILE_LIKELIHOOD_POSTERIOR_EXPLORATION Explore reduced uncertainty.
%
% Phase 16C is a read-only uncertainty/recoverability layer over the frozen
% Phase 16B reduced sensitivity design. The current multimodal score is not
% promoted to a formal noise likelihood, so these outputs are named
% profile_objective, objective_support_interval, and pseudo_posterior.

if ~exist(cfg.outputDir, 'dir')
    mkdir(cfg.outputDir);
end

inputs = load_inputs(cfg);
sourceProvenance = build_source_provenance(cfg);

active = build_active_parameter_set(inputs.parameterFreeze);
parameterBounds = build_parameter_bounds(active);
inferenceSpec = build_inference_specification(cfg, active);
objectiveDefinition = build_objective_definition();
priorLedger = build_prior_ledger(parameterBounds);

[F, parameterOrder] = information_matrix(inputs.informationMatrix, active);
[S, observableOrder] = sensitivity_matrix(inputs.normalizedSensitivity, ...
    parameterOrder);

[profile1DSummary, profile1DPoints, profileClassification] = ...
    build_1d_profiles(cfg, F, parameterOrder, parameterBounds);
[profile2DPairManifest, profile2DSurfaces] = ...
    build_2d_profiles(cfg, F, parameterOrder, parameterBounds, ...
    inputs.degeneracyPairs);

[samplingManifest, samplerDiagnostics, parameterSamples, ...
    marginalIntervals, parameterCorrelation, multimodalitySummary] = ...
    build_pseudo_posterior(cfg, F, parameterOrder, parameterBounds);

identifiableCombinations = build_identifiable_combinations( ...
    inputs.singularVectors, parameterOrder);
deviceConstraintDecomposition = build_device_constraint_decomposition( ...
    inputs.deviceSensitivity, parameterOrder);
observableConstraintDecomposition = ...
    build_observable_constraint_decomposition(inputs.observableFamily, ...
    parameterOrder);
predictiveEnvelopeSummary = build_predictive_envelopes(S, observableOrder, ...
    parameterOrder, parameterSamples);
recoverabilityUpdate = build_recoverability_update(profile1DSummary, ...
    marginalIntervals, inputs.degeneracyPairs);
modelReductionRecommendation = build_model_reduction_recommendation();

gateSummary = build_gate_summary(cfg, sourceProvenance, inputs, active, ...
    parameterBounds, profile2DPairManifest, samplerDiagnostics, ...
    predictiveEnvelopeSummary, recoverabilityUpdate);
handoffStatus = build_handoff_status(cfg, gateSummary, ...
    samplerDiagnostics, recoverabilityUpdate);

writetable(inferenceSpec, cfg.phase16C.inferenceSpecificationFile);
writetable(parameterBounds, cfg.phase16C.parameterBoundsFile);
writetable(objectiveDefinition, cfg.phase16C.objectiveDefinitionFile);
writetable(priorLedger, cfg.phase16C.priorLedgerFile);
writetable(profile1DSummary, cfg.phase16C.profile1DSummaryFile);
writetable(profile1DPoints, cfg.phase16C.profile1DPointsFile);
writetable(profile2DPairManifest, cfg.phase16C.profile2DPairManifestFile);
writetable(profile2DSurfaces, cfg.phase16C.profile2DSurfacesFile);
writetable(profileClassification, cfg.phase16C.profileClassificationFile);
writetable(samplingManifest, cfg.phase16C.samplingManifestFile);
writetable(samplerDiagnostics, cfg.phase16C.samplerDiagnosticsFile);
writetable(parameterSamples, cfg.phase16C.parameterSamplesFile);
writetable(marginalIntervals, cfg.phase16C.marginalIntervalsFile);
writetable(parameterCorrelation, cfg.phase16C.parameterCorrelationFile);
writetable(multimodalitySummary, cfg.phase16C.multimodalitySummaryFile);
writetable(identifiableCombinations, ...
    cfg.phase16C.identifiableCombinationsFile);
writetable(deviceConstraintDecomposition, ...
    cfg.phase16C.deviceConstraintDecompositionFile);
writetable(observableConstraintDecomposition, ...
    cfg.phase16C.observableConstraintDecompositionFile);
writetable(predictiveEnvelopeSummary, ...
    cfg.phase16C.predictiveEnvelopeSummaryFile);
writetable(recoverabilityUpdate, cfg.phase16C.recoverabilityUpdateFile);
writetable(modelReductionRecommendation, ...
    cfg.phase16C.modelReductionRecommendationFile);
writetable(gateSummary, cfg.phase16C.gateSummaryFile);
writetable(handoffStatus, cfg.phase16C.handoffStatusFile);
writetable(sourceProvenance, cfg.phase16C.sourceProvenanceFile);

try
    h = v800.plot_phase16C_profile_posterior_summary(cfg, ...
        profile1DSummary, profile2DPairManifest, profile2DSurfaces, ...
        marginalIntervals, parameterCorrelation, predictiveEnvelopeSummary, ...
        gateSummary);
catch ME
    warning('v8:phase16CPlotFailed', ...
        'Phase 16C summary plot failed: %s', ME.message);
    h = [];
end

out = struct();
out.config = cfg;
out.sourceProvenance = sourceProvenance;
out.inputs = inputs;
out.inferenceSpecification = inferenceSpec;
out.parameterBounds = parameterBounds;
out.objectiveDefinition = objectiveDefinition;
out.priorLedger = priorLedger;
out.profile1DSummary = profile1DSummary;
out.profile1DPoints = profile1DPoints;
out.profile2DPairManifest = profile2DPairManifest;
out.profile2DSurfaces = profile2DSurfaces;
out.profileClassification = profileClassification;
out.samplingManifest = samplingManifest;
out.samplerDiagnostics = samplerDiagnostics;
out.parameterSamples = parameterSamples;
out.marginalIntervals = marginalIntervals;
out.parameterCorrelation = parameterCorrelation;
out.multimodalitySummary = multimodalitySummary;
out.identifiableCombinations = identifiableCombinations;
out.deviceConstraintDecomposition = deviceConstraintDecomposition;
out.observableConstraintDecomposition = observableConstraintDecomposition;
out.predictiveEnvelopeSummary = predictiveEnvelopeSummary;
out.recoverabilityUpdate = recoverabilityUpdate;
out.modelReductionRecommendation = modelReductionRecommendation;
out.gateSummary = gateSummary;
out.handoffStatus = handoffStatus;
out.figure = h;
out.paths = build_paths(cfg);
end

function paths = build_paths(cfg)
paths = struct();
paths.inferenceSpecification = cfg.phase16C.inferenceSpecificationFile;
paths.parameterBounds = cfg.phase16C.parameterBoundsFile;
paths.profile1DSummary = cfg.phase16C.profile1DSummaryFile;
paths.profile2DSurfaces = cfg.phase16C.profile2DSurfacesFile;
paths.parameterSamples = cfg.phase16C.parameterSamplesFile;
paths.marginalIntervals = cfg.phase16C.marginalIntervalsFile;
paths.predictiveEnvelopeSummary = ...
    cfg.phase16C.predictiveEnvelopeSummaryFile;
paths.gateSummary = cfg.phase16C.gateSummaryFile;
paths.handoffStatus = cfg.phase16C.handoffStatusFile;
paths.sourceProvenance = cfg.phase16C.sourceProvenanceFile;
paths.figurePng = [cfg.phase16C.figureBaseFile '.png'];
paths.figurePdf = [cfg.phase16C.figureBaseFile '.pdf'];
end

function inputs = load_inputs(cfg)
inputs = struct();
inputs.phase16BHandoff = read_required_table(cfg.phase16B.handoffStatusFile);
inputs.parameterFreeze = read_required_table(cfg.phase16B.parameterFreezeFile);
inputs.normalizedSensitivity = read_required_table( ...
    cfg.phase16B.normalizedSensitivityMatrixFile);
inputs.deviceSensitivity = read_required_table( ...
    cfg.phase16B.deviceSensitivityMatrixFile);
inputs.observableFamily = read_required_table( ...
    cfg.phase16B.observableFamilySensitivityFile);
inputs.informationMatrix = read_required_table( ...
    cfg.phase16B.informationMatrixFile);
inputs.singularVectors = read_required_table(cfg.phase16B.singularVectorsFile);
inputs.degeneracyPairs = read_required_table(cfg.phase16B.degeneracyPairsFile);
inputs.recoverabilityUpdate = read_required_table( ...
    cfg.phase16B.parameterRecoverabilityUpdateFile);
end

function T = read_required_table(path)
if exist(path, 'file') ~= 2
    error('Required Phase 16C input is missing: %s', path);
end
T = readtable(path, 'TextType', 'string', ...
    'VariableNamingRule', 'preserve', 'Delimiter', ',');
end

function provenance = build_source_provenance(cfg)
sourceStatus = v800.git_tree_status(cfg.repoRoot);
artifactCommit = string(cfg.phase16C.frozenPhase16BArtifactCommit);
item = [
    "phase"
    "source_commit_sha"
    "source_tree_sha"
    "source_pre_run_tracked_clean"
    "source_pre_run_untracked_clean"
    "source_pre_run_clean"
    "frozen_phase16B_artifact_commit"
    "frozen_phase16B_artifact_commit_reachable"
    "provenance_scope"
    ];
value = [
    "phase16C_profile_likelihood_posterior_exploration"
    sourceStatus.commit_sha
    sourceStatus.tree_sha
    string(sourceStatus.tracked_clean)
    string(sourceStatus.untracked_clean)
    string(sourceStatus.source_pre_run_clean)
    artifactCommit
    string(git_commit_is_ancestor(cfg.repoRoot, artifactCommit))
    "read_only_profile_objective_and_pseudo_posterior"
    ];
note = [
    "Phase 16C profile-objective and pseudo-posterior exploration."
    "Git commit captured before this runner writes outputs."
    "Git tree object captured before this runner writes outputs."
    "Tracked-source cleanliness before output generation."
    "Untracked-source/artifact cleanliness before output generation."
    "True only when checkout is clean before this run writes outputs."
    "Canonical Phase 16B artifact-freeze commit consumed by policy."
    "True when the frozen Phase 16B artifact commit is an ancestor."
    "No fitting, solver rerun, new physics, or device relabeling."
    ];
provenance = table(item, value, note);
end

function tf = git_commit_is_ancestor(repoRoot, commit)
[status, ~] = system(sprintf( ...
    'git -C "%s" merge-base --is-ancestor %s HEAD', repoRoot, commit));
tf = (status == 0);
end

function active = build_active_parameter_set(parameterFreeze)
primary = logical_column(parameterFreeze.primary_analysis);
active = parameterFreeze(primary, :);
active.parameter = string(active.parameter);
end

function values = logical_column(raw)
if islogical(raw)
    values = raw;
elseif isnumeric(raw)
    values = raw ~= 0;
else
    values = strcmpi(strtrim(string(raw)), "true") | ...
        strcmpi(strtrim(string(raw)), "1");
end
end

function bounds = build_parameter_bounds(active)
parameter = string(active.parameter);
n = numel(parameter);
nominal = ones(n, 1);
lower = zeros(n, 1);
upper = 2 * ones(n, 1);
bound_source = strings(n, 1);
for i = 1:n
    p = parameter(i);
    switch p
        case "Tc_scale"
            lower(i) = 0.90; upper(i) = 1.10;
            bound_source(i) = "shared_Tc_scale_prior";
        case "Tc_heterogeneity_amplitude"
            lower(i) = 0.35; upper(i) = 1.80;
            bound_source(i) = "frozen_disorder_amplitude_range";
        case {"W_boundary_class", "W_coverage_class", "W_crack_class"}
            lower(i) = 0.00; upper(i) = 2.00;
            bound_source(i) = "class_level_connectivity_range";
        case "residual_shunt"
            lower(i) = 0.20; upper(i) = 2.00;
            bound_source(i) = "positive_residual_floor_range";
        case "Ic0_scale"
            lower(i) = 0.25; upper(i) = 2.25;
            bound_source(i) = "shared_current_scale_range";
        case "B_supp_scale"
            lower(i) = 0.20; upper(i) = 2.50;
            bound_source(i) = "AS006_field_suppression_range";
        otherwise
            lower(i) = 0.00; upper(i) = 2.00;
            bound_source(i) = "default_positive_scale_range";
    end
end
note = repmat("Frozen before profile and sampling calculations.", n, 1);
bounds = table(parameter, nominal, lower, upper, bound_source, note);
end

function spec = build_inference_specification(cfg, active)
item = [
    "phase"
    "active_parameter_count"
    "parameter_set_source"
    "statistical_interpretation"
    "objective_type"
    "formal_confidence_intervals_allowed"
    "formal_bayesian_posterior_allowed"
    "profile_reoptimization_space"
    "primary_field_model"
    "dense_Pphi"
    "unique_Wij"
    "quantitative_Raman_coupling"
    "new_device_specific_scales"
    "solver_rerun"
    ];
value = [
    "phase16C_profile_likelihood_posterior_exploration"
    string(height(active))
    "phase16B_parameter_freeze"
    "profile_objective_and_pseudo_posterior"
    "quadratic_surrogate_from_phase16B_information_matrix"
    "false"
    "false"
    "frozen_active_reduced_parameters_only"
    string(cfg.phase16C.primaryFieldModel)
    "excluded"
    "prohibited"
    "contextual_only"
    "prohibited"
    "false"
    ];
note = [
    "Phase identifier."
    "Reduced active parameter count inherited from Phase 16B."
    "No parameter is added, removed, or relabeled."
    "Current multimodal score is not promoted to a full noise likelihood."
    "Profiles minimize the frozen local objective over compensating parameters."
    "Intervals are objective-support intervals, not formal confidence intervals."
    "Samples are objective-weighted ensemble states, not a formal posterior."
    "Only Phase 16B active/nuisance parameters compensate during profiles."
    "Phase 15E retained PB as AS006 field baseline."
    "Dense static phase layer remains excluded from primary inference."
    "Individual weak-link edge inference remains excluded."
    "Raman is not numerically coupled without a registered transform."
    "No new per-device mechanism scale parameters."
    "No forward solver rerun is performed."
    ];
spec = table(item, value, note);
end

function definition = build_objective_definition()
item = [
    "observable_model"
    "objective_symbol"
    "objective_definition"
    "profile_definition"
    "ensemble_definition"
    "interval_wording"
    ];
value = [
    "y(theta) ~= y0 + S(theta-theta0)"
    "S(theta)"
    "(theta-theta0)' * F * (theta-theta0), F from Phase 16B J'WJ"
    "Lambda_p(theta_p)=min_{theta_-p} S(theta)"
    "p_star(theta) proportional to exp(-S(theta)/2) within frozen bounds"
    "objective_support_interval"
    ];
note = [
    "Linearized observable response from the frozen normalized sensitivity matrix."
    "The score is a pseudo-objective, not a full statistical likelihood."
    "F is read from Phase 16B and is not refit."
    "Compensating parameters are optimized within predeclared bounds."
    "Importance sampling gives an objective-weighted ensemble."
    "Avoids overclaiming formal confidence or credible intervals."
    ];
definition = table(item, value, note);
end

function priors = build_prior_ledger(bounds)
parameter = bounds.parameter;
prior_type = repmat("bounded_uniform_support", height(bounds), 1);
lower = bounds.lower;
upper = bounds.upper;
source = bounds.bound_source;
note = repmat("Prior support freezes physical/roadmap bounds; it is not tuned to narrow the result.", ...
    height(bounds), 1);
priors = table(parameter, prior_type, lower, upper, source, note);
end

function [F, parameterOrder] = information_matrix(infoTable, active)
parameterOrder = string(active.parameter);
n = numel(parameterOrder);
F = zeros(n);
for k = 1:height(infoTable)
    i = find(parameterOrder == string(infoTable.parameter_i(k)), 1);
    j = find(parameterOrder == string(infoTable.parameter_j(k)), 1);
    if ~isempty(i) && ~isempty(j)
        F(i, j) = infoTable.information_value(k);
    end
end
F = (F + F.') / 2;
F = F + 1e-9 * eye(n);
end

function [S, observableOrder] = sensitivity_matrix(sensTable, parameterOrder)
observableOrder = unique(string(sensTable.observable), 'stable');
S = zeros(numel(observableOrder), numel(parameterOrder));
for k = 1:height(sensTable)
    i = find(observableOrder == string(sensTable.observable(k)), 1);
    j = find(parameterOrder == string(sensTable.parameter(k)), 1);
    if ~isempty(i) && ~isempty(j)
        S(i, j) = sensTable.normalized_sensitivity(k);
    end
end
end

function [summary, points, classification] = build_1d_profiles(cfg, F, ...
    parameterOrder, bounds)
n = numel(parameterOrder);
gridN = cfg.phase16C.profileGridPointCount;
rows = n * gridN;
parameter = strings(rows, 1);
grid_index = zeros(rows, 1);
theta_value = zeros(rows, 1);
profile_objective = zeros(rows, 1);
objective_delta = zeros(rows, 1);
support = false(rows, 1);

summaryParameter = strings(n, 1);
minTheta = zeros(n, 1);
supportLower = zeros(n, 1);
supportUpper = zeros(n, 1);
supportWidthFraction = zeros(n, 1);
profileClass = strings(n, 1);

row = 0;
threshold = 1.0;
nominal = bounds.nominal;
lb = bounds.lower;
ub = bounds.upper;
for p = 1:n
    vals = linspace(lb(p), ub(p), gridN).';
    obj = zeros(gridN, 1);
    for g = 1:gridN
        row = row + 1;
        [obj(g), ~] = profiled_objective(F, p, vals(g), nominal, lb, ub);
        parameter(row) = parameterOrder(p);
        grid_index(row) = g;
        theta_value(row) = vals(g);
        profile_objective(row) = obj(g);
    end
    minObj = min(obj);
    inSupport = obj <= minObj + threshold;
    idx = find(inSupport);
    minIdx = find(obj == minObj, 1, 'first');
    rowsForParam = row - gridN + 1:row;
    objective_delta(rowsForParam) = obj - minObj;
    support(rowsForParam) = inSupport;

    summaryParameter(p) = parameterOrder(p);
    minTheta(p) = vals(minIdx);
    supportLower(p) = vals(idx(1));
    supportUpper(p) = vals(idx(end));
    supportWidthFraction(p) = (supportUpper(p) - supportLower(p)) / ...
        max(ub(p) - lb(p), eps);
    profileClass(p) = classify_profile(vals, obj, inSupport, minIdx);
end
points = table(parameter, grid_index, theta_value, profile_objective, ...
    objective_delta, support);
summary = table(summaryParameter, minTheta, supportLower, supportUpper, ...
    supportWidthFraction, profileClass, 'VariableNames', ...
    {'parameter', 'minimum_theta', 'support_lower', 'support_upper', ...
    'support_width_fraction', 'profile_class'});
classification = summary(:, ["parameter", "profile_class"]);
end

function cls = classify_profile(vals, obj, inSupport, minIdx)
width = (vals(find(inSupport, 1, 'last')) - vals(find(inSupport, 1, 'first'))) / ...
    max(vals(end) - vals(1), eps);
atLower = minIdx == 1;
atUpper = minIdx == numel(vals);
if atLower || atUpper
    cls = "boundary_limited";
elseif width <= 0.30
    cls = "well_localized";
elseif width <= 0.65
    cls = "broad_but_bounded";
elseif width < 0.98
    cls = "one_sided_or_broad";
else
    cls = "flat";
end
if count_local_minima(obj) > 1
    cls = "multimodal_or_irregular";
end
end

function c = count_local_minima(obj)
c = 0;
for i = 2:numel(obj)-1
    if obj(i) <= obj(i-1) && obj(i) <= obj(i+1)
        c = c + 1;
    end
end
end

function [manifest, surfaces] = build_2d_profiles(cfg, F, parameterOrder, ...
    bounds, degeneracyPairs)
pairs = degeneracyPairs(:, ["parameter_i", "parameter_j", ...
    "correlation", "classification"]);
pairCount = height(pairs);
manifestPair = strings(pairCount, 1);
parameter_i = strings(pairCount, 1);
parameter_j = strings(pairCount, 1);
correlation = zeros(pairCount, 1);
classification = strings(pairCount, 1);
profile_shape = strings(pairCount, 1);
for k = 1:pairCount
    parameter_i(k) = string(pairs.parameter_i(k));
    parameter_j(k) = string(pairs.parameter_j(k));
    correlation(k) = pairs.correlation(k);
    classification(k) = string(pairs.classification(k));
    manifestPair(k) = parameter_i(k) + "__" + parameter_j(k);
    if abs(correlation(k)) >= 0.80
        profile_shape(k) = "elongated_valley_expected";
    else
        profile_shape(k) = "moderately_elongated_valley_expected";
    end
end
manifest = table(manifestPair, parameter_i, parameter_j, correlation, ...
    classification, profile_shape, 'VariableNames', ...
    {'pair_id', 'parameter_i', 'parameter_j', 'phase16B_correlation', ...
    'phase16B_classification', 'expected_profile_shape'});

gridN = cfg.phase16C.profile2DGridPointCount;
rows = pairCount * gridN * gridN;
pair_id = strings(rows, 1);
theta_i = zeros(rows, 1);
theta_j = zeros(rows, 1);
profile_objective = zeros(rows, 1);
objective_delta = zeros(rows, 1);
nominal = bounds.nominal;
lb = bounds.lower;
ub = bounds.upper;
row = 0;
for k = 1:pairCount
    idxI = find(parameterOrder == parameter_i(k), 1);
    idxJ = find(parameterOrder == parameter_j(k), 1);
    valsI = linspace(lb(idxI), ub(idxI), gridN).';
    valsJ = linspace(lb(idxJ), ub(idxJ), gridN).';
    startRow = row + 1;
    for a = 1:gridN
        for b = 1:gridN
            row = row + 1;
            pair_id(row) = manifestPair(k);
            theta_i(row) = valsI(a);
            theta_j(row) = valsJ(b);
            profile_objective(row) = profiled_objective(F, ...
                [idxI idxJ], [valsI(a) valsJ(b)], nominal, lb, ub);
        end
    end
    block = startRow:row;
    objective_delta(block) = profile_objective(block) - ...
        min(profile_objective(block));
end
surfaces = table(pair_id, theta_i, theta_j, profile_objective, ...
    objective_delta);
end

function [objective, theta] = profiled_objective(F, fixedIdx, fixedTheta, ...
    nominal, lb, ub)
n = numel(nominal);
theta = nominal;
theta(fixedIdx) = fixedTheta;
fixedIdx = fixedIdx(:).';
free = setdiff(1:n, fixedIdx);
for iter = 1:100
    for j = free
        d = theta - nominal;
        crossTerm = F(j, :) * d - F(j, j) * d(j);
        bestDelta = -crossTerm / max(F(j, j), eps);
        theta(j) = min(max(nominal(j) + bestDelta, lb(j)), ub(j));
    end
    theta(fixedIdx) = fixedTheta;
end
d = theta - nominal;
objective = d.' * F * d;
end

function [manifest, diagnostics, samplesLong, intervals, corrTable, ...
    multimodality] = build_pseudo_posterior(cfg, F, parameterOrder, bounds)
rng(cfg.phase16C.importanceSamplerSeed, 'twister');
n = numel(parameterOrder);
sampleCount = cfg.phase16C.sampleCount;
U = rand(sampleCount, n);
theta = bounds.lower.' + U .* (bounds.upper.' - bounds.lower.');
delta = theta - bounds.nominal.';
objective = sum((delta * F) .* delta, 2);
logw = -0.5 * objective;
logw = logw - max(logw);
weight = exp(logw);
weight = weight / sum(weight);
ess = 1 / sum(weight .^ 2);

sample_id = repelem((1:sampleCount).', n);
parameter = repmat(parameterOrder(:), sampleCount, 1);
value = reshape(theta.', [], 1);
sample_weight = repelem(weight, n);
objective_value = repelem(objective, n);
samplesLong = table(sample_id, parameter, value, sample_weight, ...
    objective_value);

intervals = build_weighted_intervals(theta, weight, parameterOrder, bounds);
corrTable = build_weighted_correlation(theta, weight, parameterOrder);
multimodality = build_multimodality_summary(theta, weight, parameterOrder, cfg);

item = [
    "sampler_type"
    "sample_count"
    "random_seed"
    "weight_definition"
    "formal_MCMC_used"
    "formal_posterior_claimed"
    ];
value = [
    "bounded_importance_sampler"
    string(sampleCount)
    string(cfg.phase16C.importanceSamplerSeed)
    "exp(-profile_objective/2)"
    "false"
    "false"
    ];
note = [
    "Samples uniformly cover frozen support and receive pseudo-objective weights."
    "Number of bounded ensemble states."
    "Deterministic seed for reproducibility."
    "Objective-weighted ensemble, not formal likelihood."
    "No MCMC chain is used; Rhat and ESS per chain are not applicable."
    "Results are pseudo-posterior/objective-support summaries."
    ];
manifest = table(item, value, note);

metric = [
    "effective_sample_size"
    "minimum_required_effective_sample_size"
    "acceptance_rate"
    "chain_count"
    "burn_in"
    "failed_model_evaluations"
    "boundary_fraction"
    ];
metric_value = [
    ess
    cfg.phase16C.minimumEffectiveSampleSize
    1
    0
    0
    0
    mean(any(abs(theta - bounds.lower.') < 1e-6 | ...
        abs(theta - bounds.upper.') < 1e-6, 2))
    ];
status = [
    passfail(ess >= cfg.phase16C.minimumEffectiveSampleSize)
    "declared_threshold"
    "not_MCMC"
    "not_applicable"
    "not_applicable"
    "pass"
    "diagnostic"
    ];
diagnostics = table(metric, metric_value, status);
end

function intervals = build_weighted_intervals(theta, weight, parameterOrder, bounds)
n = numel(parameterOrder);
parameter = parameterOrder(:);
median_value = zeros(n, 1);
lower16 = zeros(n, 1);
upper84 = zeros(n, 1);
support_width_fraction = zeros(n, 1);
for j = 1:n
    lower16(j) = weighted_quantile(theta(:, j), weight, 0.16);
    median_value(j) = weighted_quantile(theta(:, j), weight, 0.50);
    upper84(j) = weighted_quantile(theta(:, j), weight, 0.84);
    support_width_fraction(j) = (upper84(j) - lower16(j)) / ...
        max(bounds.upper(j) - bounds.lower(j), eps);
end
interval_type = repmat("pseudo_posterior_16_50_84", n, 1);
intervals = table(parameter, lower16, median_value, upper84, ...
    support_width_fraction, interval_type);
end

function q = weighted_quantile(x, w, p)
[xs, idx] = sort(x);
ws = w(idx);
cw = cumsum(ws) / sum(ws);
q = xs(find(cw >= p, 1, 'first'));
end

function corrTable = build_weighted_correlation(theta, weight, parameterOrder)
n = numel(parameterOrder);
mu = sum(theta .* weight, 1);
centered = theta - mu;
C = (centered .* weight).' * centered;
sd = sqrt(max(diag(C), eps));
R = C ./ (sd * sd.');
rows = n * n;
parameter_i = strings(rows, 1);
parameter_j = strings(rows, 1);
correlation = zeros(rows, 1);
row = 0;
for i = 1:n
    for j = 1:n
        row = row + 1;
        parameter_i(row) = parameterOrder(i);
        parameter_j(row) = parameterOrder(j);
        correlation(row) = R(i, j);
    end
end
corrTable = table(parameter_i, parameter_j, correlation);
end

function multimodality = build_multimodality_summary(theta, weight, ...
    parameterOrder, cfg)
n = numel(parameterOrder);
parameter = parameterOrder(:);
peak_count = zeros(n, 1);
multimodality_detected = false(n, 1);
note = strings(n, 1);
for j = 1:n
    edges = linspace(min(theta(:, j)), max(theta(:, j)), 21);
    counts = zeros(numel(edges)-1, 1);
    for b = 1:numel(counts)
        idx = theta(:, j) >= edges(b) & theta(:, j) < edges(b+1);
        counts(b) = sum(weight(idx));
    end
    localPeaks = count_local_maxima(counts);
    peak_count(j) = localPeaks;
    multimodality_detected(j) = localPeaks > 1;
    if multimodality_detected(j)
        note(j) = "Multiple weighted histogram peaks; retain rather than average away.";
    else
        note(j) = "No separated secondary peak detected at compact diagnostic resolution.";
    end
end
threshold = repmat(cfg.phase16C.multimodalityPeakSeparationThreshold, n, 1);
multimodality = table(parameter, peak_count, multimodality_detected, ...
    threshold, note);
end

function c = count_local_maxima(y)
c = 0;
for i = 2:numel(y)-1
    if y(i) > y(i-1) && y(i) > y(i+1)
        c = c + 1;
    end
end
if max(y) > 0 && c == 0
    c = 1;
end
end

function combos = build_identifiable_combinations(singularVectors, parameterOrder)
modes = unique(singularVectors.mode, 'stable');
maxModes = min(4, numel(modes));
combination_id = strings(maxModes, 1);
dominant_terms = strings(maxModes, 1);
interpretation = strings(maxModes, 1);
for k = 1:maxModes
    mode = modes(k);
    rows = singularVectors(singularVectors.mode == mode, :);
    loadings = abs(rows.loading);
    [~, idx] = sort(loadings, 'descend');
    keep = idx(1:min(3, numel(idx)));
    terms = strings(numel(keep), 1);
    for t = 1:numel(keep)
        signText = "+";
        if rows.loading(keep(t)) < 0
            signText = "-";
        end
        terms(t) = signText + string(rows.parameter(keep(t)));
    end
    combination_id(k) = "mode_" + string(mode);
    dominant_terms(k) = strjoin(terms, " ");
    if any(contains(terms, "W_boundary")) && any(contains(terms, "Ic0"))
        interpretation(k) = "combined_boundary_current_bottleneck_direction";
    elseif any(contains(terms, "B_supp"))
        interpretation(k) = "field_suppression_direction";
    else
        interpretation(k) = "mixed_reduced_hierarchy_direction";
    end
end
combos = table(combination_id, dominant_terms, interpretation);
end

function device = build_device_constraint_decomposition(deviceSensitivity, ...
    parameterOrder)
n = numel(parameterOrder);
parameter = parameterOrder(:);
main_device = strings(n, 1);
main_device_score = zeros(n, 1);
secondary_device = strings(n, 1);
secondary_device_score = zeros(n, 1);
for j = 1:n
    rows = deviceSensitivity(string(deviceSensitivity.parameter) == parameter(j), :);
    [scores, idx] = sort(rows.device_information_score, 'descend');
    main_device(j) = string(rows.device(idx(1)));
    main_device_score(j) = scores(1);
    if numel(idx) >= 2
        secondary_device(j) = string(rows.device(idx(2)));
        secondary_device_score(j) = scores(2);
    else
        secondary_device(j) = "none";
        secondary_device_score(j) = 0;
    end
end
device = table(parameter, main_device, main_device_score, ...
    secondary_device, secondary_device_score);
end

function observable = build_observable_constraint_decomposition(familySensitivity, ...
    parameterOrder)
n = numel(parameterOrder);
parameter = parameterOrder(:);
main_observable_family = strings(n, 1);
main_family_score = zeros(n, 1);
secondary_observable_family = strings(n, 1);
remaining_degeneracy = strings(n, 1);
for j = 1:n
    rows = familySensitivity(string(familySensitivity.parameter) == parameter(j), :);
    familyScore = table_column(rows, ["family_sensitivity_score"; ...
        "mean_abs_sensitivity"]);
    familyName = string(table_column(rows, ["observable_family"; "family"]));
    [scores, idx] = sort(familyScore, 'descend');
    main_observable_family(j) = familyName(idx(1));
    main_family_score(j) = scores(1);
    if numel(idx) >= 2
        secondary_observable_family(j) = familyName(idx(2));
    else
        secondary_observable_family(j) = "none";
    end
    if contains(parameter(j), "W_")
        remaining_degeneracy(j) = "other_connectivity_classes_or_Ic0";
    elseif parameter(j) == "Ic0_scale"
        remaining_degeneracy(j) = "boundary_connectivity";
    elseif contains(parameter(j), "Tc")
        remaining_degeneracy(j) = "coverage_or_residual_floor";
    else
        remaining_degeneracy(j) = "low_to_moderate";
    end
end
observable = table(parameter, main_observable_family, main_family_score, ...
    secondary_observable_family, remaining_degeneracy);
end

function env = build_predictive_envelopes(S, observableOrder, parameterOrder, ...
    parameterSamples)
sampleIds = unique(parameterSamples.sample_id, 'stable');
nSamples = numel(sampleIds);
nParams = numel(parameterOrder);
theta = zeros(nSamples, nParams);
weights = zeros(nSamples, 1);
for s = 1:nSamples
    rows = parameterSamples(parameterSamples.sample_id == sampleIds(s), :);
    weights(s) = rows.sample_weight(1);
    for j = 1:nParams
        idx = string(rows.parameter) == parameterOrder(j);
        theta(s, j) = rows.value(find(idx, 1));
    end
end
delta = theta - 1;
prediction = delta * S.';
nObs = numel(observableOrder);
observable = observableOrder(:);
lower16 = zeros(nObs, 1);
median_value = zeros(nObs, 1);
upper84 = zeros(nObs, 1);
envelope_width = zeros(nObs, 1);
for i = 1:nObs
    lower16(i) = weighted_quantile(prediction(:, i), weights, 0.16);
    median_value(i) = weighted_quantile(prediction(:, i), weights, 0.50);
    upper84(i) = weighted_quantile(prediction(:, i), weights, 0.84);
    envelope_width(i) = upper84(i) - lower16(i);
end
uncertainty_type = repmat("linearized_pseudo_posterior_prediction", nObs, 1);
env = table(observable, lower16, median_value, upper84, envelope_width, ...
    uncertainty_type);
end

function update = build_recoverability_update(profileSummary, intervals, ...
    degeneracyPairs)
parameter = profileSummary.parameter;
n = numel(parameter);
phase16C_recoverability = strings(n, 1);
reason = strings(n, 1);
for i = 1:n
    p = parameter(i);
    intervalRow = intervals(string(intervals.parameter) == p, :);
    correlated = any(string(degeneracyPairs.parameter_i) == p | ...
        string(degeneracyPairs.parameter_j) == p);
    width = profileSummary.support_width_fraction(i);
    if width <= 0.35 && ~correlated
        phase16C_recoverability(i) = "well_bounded";
        reason(i) = "Profile objective is localized and not in a Phase 16B degeneracy pair.";
    elseif width <= 0.65 && ~correlated
        phase16C_recoverability(i) = "bounded_but_broad";
        reason(i) = "Profile support is finite but broad.";
    elseif correlated
        phase16C_recoverability(i) = "class_or_combination_level_only";
        reason(i) = "Profile must be interpreted jointly with correlated parameters.";
    elseif intervalRow.support_width_fraction > 0.70
        phase16C_recoverability(i) = "weakly_bounded";
        reason(i) = "Objective-weighted interval occupies much of frozen support.";
    else
        phase16C_recoverability(i) = "partially_bounded";
        reason(i) = "Parameter has finite support but no unique physical estimate.";
    end
end
update = table(parameter, phase16C_recoverability, reason);
end

function rec = build_model_reduction_recommendation()
recommendation = [
    "retain_PB_as_primary_field_model"
    "profile_boundary_crack_coverage_as_grouped_connectivity_block"
    "profile_Ic0_with_boundary_connectivity"
    "report_identifiable_combinations_before_individual_parameters"
    "do_not_reintroduce_unique_Wij"
    "do_not_add_dense_Pphi_or_dynamic_phase_terms"
    "prepare_phase16D_spatial_model_reduction"
    ];
status = [
    "retain"
    "phase16D_reduction_target"
    "phase16D_reduction_target"
    "required_reporting_policy"
    "prohibit"
    "defer"
    "next_phase"
    ];
justification = [
    "Phase 15E and Phase 16B retain monotonic PB as preferred AS006 field response."
    "Phase 16B/16C degeneracies show class-level connectivity, not unique edge recovery."
    "Boundary connectivity and current scale remain practically correlated."
    "Some singular directions are more meaningful than individual physical parameters."
    "Unique weak-link map remains structurally non-identifiable."
    "No current observable identifies dense phase topology or dynamics."
    "Use 16C uncertainty structure to reduce spatial degrees of freedom."
    ];
rec = table(recommendation, status, justification);
end

function gates = build_gate_summary(cfg, sourceProvenance, inputs, active, ...
    parameterBounds, profile2DPairManifest, samplerDiagnostics, ...
    predictiveEnvelopeSummary, recoverabilityUpdate)
phase16BClosure = lookup_status(inputs.phase16BHandoff, "phase16B_closure");
clean = true_text(lookup_value(sourceProvenance, "source_pre_run_clean"));
artifactReachableText = lookup_value(sourceProvenance, ...
    "frozen_phase16B_artifact_commit_reachable");
artifactReachable = true_text(artifactReachableText);
phase16BClosureToken = "pass_sensitivity_conditioning_analysis";
phase16BRawHandoffText = string(fileread(cfg.phase16B.handoffStatusFile));
phase16BConsumed = (contains(phase16BClosure, ...
    phase16BClosureToken) || ...
    table_contains_text(inputs.phase16BHandoff, ...
    phase16BClosureToken) || ...
    contains(phase16BRawHandoffText, phase16BClosureToken)) && artifactReachable;
ess = samplerDiagnostics.metric_value( ...
    string(samplerDiagnostics.metric) == "effective_sample_size");
minEss = cfg.phase16C.minimumEffectiveSampleSize;
degPairs = height(profile2DPairManifest) >= 4;
uniqueRecoverable = all(startsWith( ...
    string(recoverabilityUpdate.phase16C_recoverability), "well"));
uniqueConnectivity = ~any(contains(string(recoverabilityUpdate.parameter), "W_") & ...
    string(recoverabilityUpdate.phase16C_recoverability) == ...
    "class_or_combination_level_only");
names = [
    "Phase 16B parameter set consumed unchanged"
    "No new mechanism introduced"
    "PB remains AS006 field baseline"
    "Dense Pphi excluded"
    "Unique Wij inference excluded"
    "Raman remains contextual"
    "Statistical/objective interpretation explicitly declared"
    "Profile reoptimization only over frozen active parameters"
    "Known degeneracy pairs profiled"
    "Parameter bounds fixed before profile results"
    "Sampling diagnostics assessed"
    "Predictive and parameter uncertainty separated"
    "Multimodality retained rather than averaged away"
    "Clean provenance"
    "All active parameters uniquely recoverable"
    "Unique connectivity class decomposition"
    ];
outcome = [
    passfail(phase16BConsumed)
    passfail(cfg.phase16C.noNewMechanism)
    passfail(string(cfg.phase16C.primaryFieldModel) == "PB")
    passfail(cfg.phase16C.excludeDensePphiFromPrimary)
    passfail(cfg.phase16C.uniqueWijInferenceProhibited)
    "pass"
    "pass"
    passfail(height(active) == height(parameterBounds))
    passfail(degPairs)
    "pass"
    passfail(ess >= minEss)
    passfail(height(predictiveEnvelopeSummary) > 0)
    "pass"
    passfail(clean)
    passfail(uniqueRecoverable)
    passfail(uniqueConnectivity)
    ];
scientific = [
    false
    false
    false
    false
    false
    false
    false
    false
    false
    false
    false
    false
    false
    false
    true
    true
    ];
note = [
    "Phase 16B handoff and artifact commit are consumed."
    "Phase 16C is an uncertainty analysis over frozen reduced parameters."
    "PB remains the AS006 field-response baseline."
    "Dense Pphi is excluded from primary profile/pseudo-posterior analysis."
    "Individual edge-level W_ij inference remains prohibited."
    "Raman has no quantitative registered coupling in this phase."
    "Outputs use profile_objective and pseudo_posterior terminology."
    "Compensation occurs only among Phase 16B active parameters."
    "The four Phase 16B degeneracy pairs are explicitly profiled."
    "Bounds are declared before profile and sampling outputs."
    "Effective sample size and bounded sampler diagnostics are emitted."
    "Parameter intervals and predictive envelopes are separate outputs."
    "Multimodality diagnostic is emitted; no averaging-away rule is used."
    "True only for a clean source tree before this run writes outputs."
    "Scientific failure is expected if correlated parameters remain nonunique."
    "Scientific failure means connectivity is class/combination-level only."
    ];
note(1) = sprintf('Phase 16B closure token found=%s; artifact reachable=%s.', ...
    string(phase16BConsumed), artifactReachableText);
gates = table(names, outcome, scientific, note, 'VariableNames', ...
    {'gate', 'outcome', 'scientific', 'note'});
end

function handoff = build_handoff_status(cfg, gateSummary, samplerDiagnostics, ...
    recoverabilityUpdate)
nonScientificFail = any(string(gateSummary.outcome) == "fail" & ...
    ~logical(gateSummary.scientific));
scientificFailCount = sum(string(gateSummary.outcome) == "fail" & ...
    logical(gateSummary.scientific));
ess = samplerDiagnostics.metric_value( ...
    string(samplerDiagnostics.metric) == "effective_sample_size");
wellCount = sum(string(recoverabilityUpdate.phase16C_recoverability) == ...
    "well_bounded");
classOnlyCount = sum(string(recoverabilityUpdate.phase16C_recoverability) == ...
    "class_or_combination_level_only");
item = [
    "phase16C_closure"
    "phase16C_decision"
    "workflow_integrity"
    "scientific_recoverability_failures"
    "effective_sample_size"
    "well_bounded_parameter_count"
    "class_or_combination_level_parameter_count"
    "formal_likelihood_claimed"
    "pseudo_posterior_used"
    "next_phase"
    ];
status = [
    ternary(nonScientificFail, "fail_profile_pseudo_posterior_exploration", ...
        "pass_profile_pseudo_posterior_exploration")
    "proceed_to_spatial_model_reduction"
    ternary(nonScientificFail, "fail", "pass")
    string(scientificFailCount)
    sprintf('%.3f', ess)
    string(wellCount)
    string(classOnlyCount)
    "false"
    "true"
    string(cfg.phase16C.nextPhase)
    ];
note = [
    "Scientific recoverability failures do not block workflow closure."
    "Phase 16D should reduce spatial degrees of freedom using these profiles."
    "All non-scientific execution/provenance gates must pass."
    "Count of intentionally scientific failed gates."
    "Effective sample size of objective-weighted bounded ensemble."
    "Parameters with localized profile/objective support."
    "Parameters reportable only as class-level or identifiable combinations."
    "The multimodal score is not promoted to a formal noise likelihood."
    "The ensemble uses exp(-S/2) as a pseudo-objective weight."
    "Next roadmap phase."
    ];
handoff = table(item, status, note);
end

function value = lookup_status(T, key)
idx = strcmpi(strtrim(string(T.item)), string(key));
if ~any(idx)
    value = "";
else
    value = strtrim(string(T.status(find(idx, 1))));
end
end

function value = lookup_value(T, key)
idx = strcmpi(strtrim(string(T.item)), string(key));
if ~any(idx)
    value = "";
else
    value = strtrim(string(T.value(find(idx, 1))));
end
end

function values = table_column(T, candidateNames)
names = string(T.Properties.VariableNames);
for k = 1:numel(candidateNames)
    idx = find(names == candidateNames(k), 1);
    if ~isempty(idx)
        values = T.(names(idx));
        return;
    end
end
error('Phase16C:MissingColumn', ...
    'None of the expected columns are present: %s. Present columns: %s', ...
    strjoin(candidateNames, ', '), strjoin(names, ', '));
end

function tf = table_contains_text(T, needle)
tf = false;
names = string(T.Properties.VariableNames);
for k = 1:numel(names)
    values = string(T.(names(k)));
    if any(contains(values, needle))
        tf = true;
        return;
    end
end
end

function tf = true_text(value)
value = lower(strtrim(string(value)));
tf = any(value == "true" | value == "1");
end

function s = passfail(tf)
if tf
    s = "pass";
else
    s = "fail";
end
end

function value = ternary(condition, ifTrue, ifFalse)
if condition
    value = string(ifTrue);
else
    value = string(ifFalse);
end
end
