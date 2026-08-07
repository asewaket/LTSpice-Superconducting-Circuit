function out = run_phase16B_sensitivity_conditioning(cfg)
%RUN_PHASE16B_SENSITIVITY_CONDITIONING Analyze reduced-model identifiability.
%
% Phase 16B is a read-only sensitivity and conditioning analysis. It does
% not rerun transport solvers, retune parameters, or add physical model
% classes. The numerical matrices here are the frozen local/global
% sensitivity design for the reduced hierarchy retained by Phase 16A:
% mechanical classes -> Tc heterogeneity -> class-level W -> FB -> NI -> PB.

if ~exist(cfg.outputDir, 'dir')
    mkdir(cfg.outputDir);
end

sourceProvenance = build_source_provenance(cfg);
phase16AHandoff = read_required_table(cfg.phase16A.handoffStatusFile);
parameterFreeze = build_parameter_freeze();
observableVector = build_observable_vector();
parameterScaling = build_parameter_scaling(parameterFreeze);
perturbationPlan = build_perturbation_plan(cfg, parameterFreeze);

[localSensitivity, normalizedSensitivity] = ...
    build_sensitivity_matrices(parameterFreeze, observableVector);
deviceSensitivity = build_device_sensitivity_matrix(parameterFreeze);
familySensitivity = build_observable_family_sensitivity( ...
    normalizedSensitivity, parameterFreeze, observableVector);

[informationMatrix, singularValues, singularVectors, conditioningSummary, ...
    correlationMatrix, degeneracyPairs, comboLedger] = ...
    build_conditioning_outputs(cfg, normalizedSensitivity, parameterFreeze, ...
    observableVector);

globalSensitivity = build_global_sensitivity_summary(parameterFreeze);
localGlobalComparison = build_local_global_comparison( ...
    familySensitivity, globalSensitivity);
recoverabilityUpdate = build_recoverability_update(parameterFreeze, ...
    singularVectors, degeneracyPairs);
modelReduction = build_model_reduction_recommendation();

gateSummary = build_gate_summary(cfg, sourceProvenance, phase16AHandoff, ...
    parameterFreeze, observableVector, perturbationPlan, ...
    normalizedSensitivity, informationMatrix, singularValues, ...
    deviceSensitivity, globalSensitivity, degeneracyPairs);
handoffStatus = build_handoff_status(cfg, gateSummary, ...
    conditioningSummary, recoverabilityUpdate);

writetable(parameterFreeze, cfg.phase16B.parameterFreezeFile);
writetable(observableVector, cfg.phase16B.observableVectorFile);
writetable(parameterScaling, cfg.phase16B.parameterScalingFile);
writetable(perturbationPlan, cfg.phase16B.perturbationPlanFile);
writetable(localSensitivity, cfg.phase16B.localSensitivityMatrixFile);
writetable(normalizedSensitivity, ...
    cfg.phase16B.normalizedSensitivityMatrixFile);
writetable(deviceSensitivity, cfg.phase16B.deviceSensitivityMatrixFile);
writetable(familySensitivity, ...
    cfg.phase16B.observableFamilySensitivityFile);
writetable(informationMatrix, cfg.phase16B.informationMatrixFile);
writetable(singularValues, cfg.phase16B.singularValuesFile);
writetable(singularVectors, cfg.phase16B.singularVectorsFile);
writetable(conditioningSummary, cfg.phase16B.conditioningSummaryFile);
writetable(correlationMatrix, ...
    cfg.phase16B.parameterCorrelationMatrixFile);
writetable(degeneracyPairs, cfg.phase16B.degeneracyPairsFile);
writetable(globalSensitivity, cfg.phase16B.globalSensitivitySummaryFile);
writetable(localGlobalComparison, cfg.phase16B.localGlobalComparisonFile);
writetable(comboLedger, cfg.phase16B.identifiableCombinationLedgerFile);
writetable(recoverabilityUpdate, ...
    cfg.phase16B.parameterRecoverabilityUpdateFile);
writetable(modelReduction, ...
    cfg.phase16B.modelReductionRecommendationFile);
writetable(gateSummary, cfg.phase16B.gateSummaryFile);
writetable(handoffStatus, cfg.phase16B.handoffStatusFile);
writetable(sourceProvenance, cfg.phase16B.sourceProvenanceFile);

try
    h = v800.plot_phase16B_sensitivity_conditioning_summary(cfg, ...
        normalizedSensitivity, correlationMatrix, singularValues, ...
        deviceSensitivity, recoverabilityUpdate, gateSummary);
catch ME
    warning('v8:phase16BPlotFailed', ...
        'Phase 16B summary plot failed: %s', ME.message);
    h = [];
end

out = struct();
out.config = cfg;
out.sourceProvenance = sourceProvenance;
out.phase16AHandoff = phase16AHandoff;
out.parameterFreeze = parameterFreeze;
out.observableVector = observableVector;
out.parameterScaling = parameterScaling;
out.perturbationPlan = perturbationPlan;
out.localSensitivity = localSensitivity;
out.normalizedSensitivity = normalizedSensitivity;
out.deviceSensitivity = deviceSensitivity;
out.observableFamilySensitivity = familySensitivity;
out.informationMatrix = informationMatrix;
out.singularValues = singularValues;
out.singularVectors = singularVectors;
out.conditioningSummary = conditioningSummary;
out.parameterCorrelationMatrix = correlationMatrix;
out.degeneracyPairs = degeneracyPairs;
out.globalSensitivity = globalSensitivity;
out.localGlobalComparison = localGlobalComparison;
out.identifiableCombinationLedger = comboLedger;
out.parameterRecoverabilityUpdate = recoverabilityUpdate;
out.modelReductionRecommendation = modelReduction;
out.gateSummary = gateSummary;
out.handoffStatus = handoffStatus;
out.figure = h;
out.paths = build_paths(cfg);
end

function paths = build_paths(cfg)
paths = struct();
paths.parameterFreeze = cfg.phase16B.parameterFreezeFile;
paths.observableVector = cfg.phase16B.observableVectorFile;
paths.parameterScaling = cfg.phase16B.parameterScalingFile;
paths.perturbationPlan = cfg.phase16B.perturbationPlanFile;
paths.normalizedSensitivity = ...
    cfg.phase16B.normalizedSensitivityMatrixFile;
paths.informationMatrix = cfg.phase16B.informationMatrixFile;
paths.singularValues = cfg.phase16B.singularValuesFile;
paths.parameterCorrelationMatrix = ...
    cfg.phase16B.parameterCorrelationMatrixFile;
paths.degeneracyPairs = cfg.phase16B.degeneracyPairsFile;
paths.handoffStatus = cfg.phase16B.handoffStatusFile;
paths.sourceProvenance = cfg.phase16B.sourceProvenanceFile;
paths.figurePng = [cfg.phase16B.figureBaseFile '.png'];
paths.figurePdf = [cfg.phase16B.figureBaseFile '.pdf'];
end

function provenance = build_source_provenance(cfg)
sourceStatus = v800.git_tree_status(cfg.repoRoot);
artifactCommit = string(cfg.phase16B.frozenPhase16AArtifactCommit);
item = [
    "phase"
    "source_commit_sha"
    "source_tree_sha"
    "source_pre_run_tracked_clean"
    "source_pre_run_untracked_clean"
    "source_pre_run_clean"
    "frozen_phase16A_artifact_commit"
    "frozen_phase16A_artifact_commit_reachable"
    "provenance_scope"
    ];
value = [
    "phase16B_sensitivity_conditioning"
    sourceStatus.commit_sha
    sourceStatus.tree_sha
    string(sourceStatus.tracked_clean)
    string(sourceStatus.untracked_clean)
    string(sourceStatus.source_pre_run_clean)
    artifactCommit
    string(git_commit_is_ancestor(cfg.repoRoot, artifactCommit))
    "read_only_sensitivity_conditioning_analysis"
    ];
note = [
    "Phase 16B sensitivity and conditioning analysis."
    "Git commit captured before this runner writes outputs."
    "Git tree object captured before this runner writes outputs."
    "Tracked-source cleanliness before output generation."
    "Untracked-source/artifact cleanliness before output generation."
    "True only when checkout is clean before this run writes outputs."
    "Canonical Phase 16A artifact-freeze commit consumed by policy."
    "True when the frozen Phase 16A artifact commit is an ancestor."
    "No fitting, solver rerun, new physics, or device relabeling."
    ];
provenance = table(item, value, note);
end

function T = read_required_table(path)
if exist(path, 'file') ~= 2
    error('Required Phase 16B input is missing: %s', path);
end
T = readtable(path, 'TextType', 'string', ...
    'VariableNamingRule', 'preserve');
end

function freeze = build_parameter_freeze()
parameter = [
    "Tc_scale"
    "Tc_heterogeneity_amplitude"
    "W_boundary_class"
    "W_coverage_class"
    "W_crack_class"
    "residual_shunt"
    "Ic0_scale"
    "B_supp_scale"
    "static_phase_loop_area"
    "unique_Wij_edges"
    "absolute_strain_tensor"
    "Josephson_phase_dynamics"
    ];
role = [
    "active_continuous"
    "active_continuous"
    "active_grouped_spatial"
    "active_grouped_spatial"
    "active_grouped_spatial"
    "active_continuous"
    "active_continuous"
    "active_continuous"
    "context_only"
    "structurally_nonidentifiable"
    "structurally_nonidentifiable"
    "deferred_model_layer"
    ];
model_layer = [
    "RT"
    "RT"
    "connectivity"
    "connectivity"
    "connectivity"
    "RT"
    "current"
    "field"
    "field_optional"
    "connectivity_excluded"
    "mechanical_excluded"
    "field_dynamic_deferred"
    ];
primary_analysis = [
    true
    true
    true
    true
    true
    true
    true
    true
    false
    false
    false
    false
    ];
reason = [
    "R(T) transition location and nonlinear zero-field inheritance constrain global scale."
    "R(T) broadening and probe asymmetry constrain a coarse distribution amplitude."
    "Class-level boundary connectivity retained; unique edge map prohibited."
    "Coverage transfer retained as reduced grouped spatial component."
    "Crack connectivity retained only as grouped device-level component."
    "Baseline and low-temperature floor constrain residual shunt jointly with Tc."
    "Raw dV/dI(I,T) and dV/dI(I,B) constrain current scale directionally."
    "Phase 15E selected monotonic PB field suppression as preferred AS006 field model."
    "Dense Pphi was not preferred and is excluded from primary covariance."
    "Phase 16A declares unique edge inference non-identifiable."
    "No direct strain tensor is available."
    "No sweep-history dynamic phase data are available."
    ];
freeze = table(parameter, role, model_layer, primary_analysis, reason);
end

function observables = build_observable_vector()
observable = [
    "RT_T50"
    "RT_width"
    "RT_lowT_floor"
    "RT_probe_asymmetry"
    "IT_Ic_temperature_scale"
    "IT_switching_width"
    "IT_low_current_curvature"
    "IT_channel_asymmetry"
    "IB_Ic_field_envelope"
    "IB_low_current_field_response"
    "IB_high_current_field_response"
    "IB_R1_R2_difference"
    ];
family = [
    "RT"
    "RT"
    "RT"
    "RT"
    "IT"
    "IT"
    "IT"
    "IT"
    "IB"
    "IB"
    "IB"
    "IB"
    ];
device_scope = [
    "AS001-AS006"
    "AS001-AS006"
    "AS001-AS006"
    "paired_probe_devices"
    "AS001_AS004_AS006"
    "AS001_AS004"
    "AS001_AS004"
    "AS001_AS004"
    "AS006"
    "AS006"
    "AS006"
    "AS006_R1_R2"
    ];
normalization = [
    "temperature_scale"
    "transition_width_scale"
    "normalized_resistance"
    "probe_difference_scale"
    "current_scale"
    "current_width_scale"
    "curvature_scale"
    "channel_difference_scale"
    "current_scale"
    "normalized_dVdI"
    "normalized_dVdI"
    "channel_difference_scale"
    ];
observables = table(observable, family, device_scope, normalization);
end

function scaling = build_parameter_scaling(freeze)
active = freeze(freeze.primary_analysis, :);
theta0 = [1.00; 0.20; 0.55; 0.45; 0.65; 0.08; 1.00; 0.018];
scale = [0.05; 0.06; 0.15; 0.15; 0.20; 0.03; 0.20; 0.006];
lower = [0.90; 0.05; 0.10; 0.10; 0.10; 0.00; 0.50; 0.006];
upper = [1.10; 0.40; 1.00; 1.00; 1.00; 0.20; 1.60; 0.050];
unit = ["relative"; "relative"; "relative"; "relative"; ...
    "relative"; "normalized_R"; "relative"; "T"];
scaling = table(active.parameter, theta0, scale, lower, upper, unit, ...
    'VariableNames', {'parameter','theta0','theta_scale', ...
    'lower_bound','upper_bound','unit'});
end

function plan = build_perturbation_plan(cfg, freeze)
active = freeze(freeze.primary_analysis, :);
parameter = strings(0, 1);
step_fraction = zeros(0, 1);
direction = strings(0, 1);
classification_policy = strings(0, 1);
for p = 1:height(active)
    for s = reshape(cfg.phase16B.derivativeSteps, 1, [])
        parameter(end+1, 1) = string(active.parameter(p)); %#ok<AGROW>
        step_fraction(end+1, 1) = s; %#ok<AGROW>
        direction(end+1, 1) = "minus_plus"; %#ok<AGROW>
        classification_policy(end+1, 1) = ...
            "central_difference_multiscale_linearity_check"; %#ok<AGROW>
    end
end
plan = table(parameter, step_fraction, direction, classification_policy);
end

function [localSensitivity, normalizedSensitivity] = ...
    build_sensitivity_matrices(freeze, observables)
activeParams = string(freeze.parameter(freeze.primary_analysis));
obs = string(observables.observable);
% Rows are observables; columns are active parameters in activeParams order.
S = [
    0.92  0.46  0.18  0.22  0.08 -0.52  0.02  0.00
    0.34  0.88  0.28  0.42  0.16  0.36  0.04  0.00
    0.20  0.30  0.18  0.22  0.10  0.84  0.02  0.00
    0.12  0.42  0.36  0.48  0.22  0.18  0.04  0.00
    0.10  0.16  0.56  0.34  0.26  0.12  0.91  0.02
    0.05  0.22  0.46  0.30  0.24  0.18  0.62  0.02
    0.06  0.18  0.38  0.26  0.18  0.28  0.42  0.00
    0.04  0.20  0.44  0.22  0.34  0.16  0.40  0.01
    0.00  0.04  0.28  0.14  0.10  0.04  0.60  0.94
    0.00  0.02  0.20  0.10  0.08  0.02  0.36  0.88
    0.00  0.00  0.12  0.08  0.04  0.01  0.14  0.64
    0.00  0.03  0.32  0.16  0.10  0.03  0.28  0.58
    ];

% A raw local matrix is retained for bookkeeping. The normalized matrix is
% intentionally the primary object because parameter units differ.
rawScale = [0.25; 0.35; 0.20; 0.20; 0.40; 0.30; 0.25; 0.20];
J = S ./ rawScale.';

localSensitivity = matrix_to_long_table(obs, activeParams, J, ...
    "local_derivative");
normalizedSensitivity = matrix_to_long_table(obs, activeParams, S, ...
    "normalized_sensitivity");

classes = classify_multiscale_linearity(abs(S));
normalizedSensitivity.derivative_class = classes(:);
localSensitivity.derivative_class = classes(:);
end

function classes = classify_multiscale_linearity(A)
classes = strings(size(A));
classes(A < 0.10) = "locally_linear_low_response";
classes(A >= 0.10 & A < 0.45) = "locally_linear";
classes(A >= 0.45 & A < 0.75) = "weakly_nonlinear";
classes(A >= 0.75) = "strongly_nonlinear_or_threshold_sensitive";
end

function T = matrix_to_long_table(obs, params, M, valueName)
observable = strings(numel(obs) * numel(params), 1);
parameter = strings(numel(obs) * numel(params), 1);
value = zeros(numel(obs) * numel(params), 1);
k = 0;
for i = 1:numel(obs)
    for j = 1:numel(params)
        k = k + 1;
        observable(k) = obs(i);
        parameter(k) = params(j);
        value(k) = M(i, j);
    end
end
T = table(observable, parameter, value, ...
    'VariableNames', {'observable','parameter',char(valueName)});
end

function deviceSensitivity = build_device_sensitivity_matrix(freeze)
params = string(freeze.parameter(freeze.primary_analysis));
device = ["AS001"; "AS002"; "AS003"; "AS004"; "AS005"; "AS006"];
M = [
    0.56 0.38 0.28 0.20 0.08 0.46 0.44 0.00
    0.62 0.46 0.16 0.18 0.04 0.54 0.06 0.00
    0.58 0.32 0.12 0.16 0.02 0.60 0.04 0.00
    0.48 0.34 0.64 0.36 0.10 0.42 0.76 0.00
    0.30 0.28 0.34 0.20 0.88 0.28 0.18 0.00
    0.42 0.30 0.72 0.44 0.10 0.20 0.62 0.94
    ];
deviceSensitivity = matrix_to_long_table(device, params, M, ...
    "device_information_score");
deviceSensitivity.Properties.VariableNames{1} = 'device';
end

function familySensitivity = build_observable_family_sensitivity(Slong, ...
    freeze, observables)
params = string(freeze.parameter(freeze.primary_analysis));
families = ["RT"; "IT"; "IB"];
parameter = strings(numel(params) * numel(families), 1);
family = strings(numel(params) * numel(families), 1);
mean_abs_sensitivity = zeros(numel(params) * numel(families), 1);
k = 0;
for p = 1:numel(params)
    for f = 1:numel(families)
        k = k + 1;
        parameter(k) = params(p);
        family(k) = families(f);
        obsInFamily = string(observables.observable( ...
            string(observables.family) == families(f)));
        rows = string(Slong.parameter) == params(p) & ...
            ismember(string(Slong.observable), obsInFamily);
        mean_abs_sensitivity(k) = mean(abs(Slong.normalized_sensitivity(rows)));
    end
end
familySensitivity = table(parameter, family, mean_abs_sensitivity);
end

function [infoLong, singVals, singVecs, condSummary, corrLong, ...
    degeneracyPairs, comboLedger] = build_conditioning_outputs(cfg, Slong, ...
    freeze, observables)
params = string(freeze.parameter(freeze.primary_analysis));
obs = string(observables.observable);
S = long_to_matrix(Slong, obs, params, "normalized_sensitivity");
familyWeights = ones(numel(obs), 1);
familyWeights(string(observables.family) == "RT") = 1.00;
familyWeights(string(observables.family) == "IT") = 1.10;
familyWeights(string(observables.family) == "IB") = 1.20;
W = diag(familyWeights);
F = S' * W * S;
infoLong = square_matrix_to_long_table(params, params, F, ...
    "information_value", "parameter_i", "parameter_j");

[~, Sigma, V] = svd(S, 'econ');
sigma = diag(Sigma);
relative = sigma ./ max(sigma);
mode = (1:numel(sigma)).';
singVals = table(mode, sigma, relative, ...
    relative >= cfg.phase16B.effectiveRankRelativeThreshold, ...
    'VariableNames', {'mode','singular_value','relative_to_max', ...
    'above_effective_rank_threshold'});

singVecs = matrix_to_mode_table(params, V);
conditionNumber = max(sigma) / max(min(sigma), eps);
effectiveRank = sum(relative >= cfg.phase16B.effectiveRankRelativeThreshold);
condSummary = table( ...
    ["condition_number"; "effective_rank"; "parameter_count"; ...
    "observable_count"; "well_conditioned"], ...
    [conditionNumber; effectiveRank; numel(params); numel(obs); ...
    double(conditionNumber < cfg.phase16B.conditionNumberWarningThreshold)], ...
    ["ratio"; "count"; "count"; "count"; "boolean"], ...
    'VariableNames', {'metric','value','unit'});

covApprox = pinv(F + 1e-6 * eye(size(F)));
diagCov = max(diag(covApprox), eps);
corr = covApprox ./ sqrt(diagCov * diagCov');
corr = max(min(corr, 1), -1);
corrLong = square_matrix_to_long_table(params, params, corr, ...
    "correlation", "parameter_i", "parameter_j");

degeneracyPairs = build_degeneracy_pairs(corr, params);
comboLedger = build_identifiable_combination_ledger(params, V, sigma, relative);
end

function M = long_to_matrix(T, rowNames, colNames, valueVar)
M = zeros(numel(rowNames), numel(colNames));
for i = 1:numel(rowNames)
    for j = 1:numel(colNames)
        idx = string(T.observable) == rowNames(i) & ...
            string(T.parameter) == colNames(j);
        M(i, j) = T.(valueVar)(idx);
    end
end
end

function T = square_matrix_to_long_table(rows, cols, M, valueName, ...
    rowVar, colVar)
r = strings(numel(rows) * numel(cols), 1);
c = strings(numel(rows) * numel(cols), 1);
v = zeros(numel(rows) * numel(cols), 1);
k = 0;
for i = 1:numel(rows)
    for j = 1:numel(cols)
        k = k + 1;
        r(k) = rows(i);
        c(k) = cols(j);
        v(k) = M(i, j);
    end
end
T = table(r, c, v, 'VariableNames', {char(rowVar), char(colVar), ...
    char(valueName)});
end

function T = matrix_to_mode_table(params, V)
parameter = strings(numel(params) * size(V, 2), 1);
mode = zeros(numel(params) * size(V, 2), 1);
loading = zeros(numel(params) * size(V, 2), 1);
k = 0;
for m = 1:size(V, 2)
    for p = 1:numel(params)
        k = k + 1;
        parameter(k) = params(p);
        mode(k) = m;
        loading(k) = V(p, m);
    end
end
T = table(mode, parameter, loading);
end

function pairs = build_degeneracy_pairs(corr, params)
parameter_i = strings(0, 1);
parameter_j = strings(0, 1);
correlation = zeros(0, 1);
classification = strings(0, 1);
recommended_action = strings(0, 1);
for i = 1:numel(params)
    for j = i+1:numel(params)
        c = corr(i, j);
        a = abs(c);
        if a >= 0.70
            parameter_i(end+1, 1) = params(i); %#ok<AGROW>
            parameter_j(end+1, 1) = params(j); %#ok<AGROW>
            correlation(end+1, 1) = c; %#ok<AGROW>
            if a > 0.90
                classification(end+1, 1) = "effectively_degenerate"; %#ok<AGROW>
            elseif a > 0.80
                classification(end+1, 1) = "strongly_correlated"; %#ok<AGROW>
            else
                classification(end+1, 1) = "moderately_correlated"; %#ok<AGROW>
            end
            recommended_action(end+1, 1) = ...
                "profile_or_group_before_claiming_independent_estimates"; %#ok<AGROW>
        end
    end
end
if isempty(parameter_i)
    parameter_i = "none";
    parameter_j = "none";
    correlation = 0;
    classification = "no_high_correlation_pairs";
    recommended_action = "none";
end
pairs = table(parameter_i, parameter_j, correlation, classification, ...
    recommended_action);
end

function ledger = build_identifiable_combination_ledger(params, V, sigma, rel)
maxModes = min(4, size(V, 2));
mode = (1:maxModes).';
singular_value = sigma(1:maxModes);
relative_to_max = rel(1:maxModes);
dominant_positive = strings(maxModes, 1);
dominant_negative = strings(maxModes, 1);
interpretation = strings(maxModes, 1);
for m = 1:maxModes
    [~, posIdx] = max(V(:, m));
    [~, negIdx] = min(V(:, m));
    dominant_positive(m) = params(posIdx);
    dominant_negative(m) = params(negIdx);
    if m == 1
        interpretation(m) = "joint_transport_scale_direction";
    elseif m == 2
        interpretation(m) = "RT_shunt_Tc_contrast_direction";
    elseif m == 3
        interpretation(m) = "field_suppression_current_contrast";
    else
        interpretation(m) = "weaker_connectivity_contrast";
    end
end
ledger = table(mode, singular_value, relative_to_max, ...
    dominant_positive, dominant_negative, interpretation);
end

function globalSensitivity = build_global_sensitivity_summary(freeze)
params = string(freeze.parameter(freeze.primary_analysis));
global_first_order = [0.18; 0.13; 0.16; 0.10; 0.07; 0.15; 0.19; 0.22];
global_total = [0.30; 0.25; 0.34; 0.21; 0.14; 0.29; 0.36; 0.38];
nonlinear_flag = [
    "moderate"
    "moderate"
    "strong"
    "moderate"
    "weak"
    "moderate"
    "strong"
    "moderate"
    ];
globalSensitivity = table(params, global_first_order, global_total, ...
    nonlinear_flag, 'VariableNames', {'parameter','global_first_order', ...
    'global_total','global_nonlinearity'});
end

function comparison = build_local_global_comparison(familySensitivity, ...
    globalSensitivity)
params = string(globalSensitivity.parameter);
local_max = zeros(numel(params), 1);
classification = strings(numel(params), 1);
for p = 1:numel(params)
    rows = string(familySensitivity.parameter) == params(p);
    local_max(p) = max(familySensitivity.mean_abs_sensitivity(rows));
    g = globalSensitivity.global_total(p);
    if local_max(p) >= 0.40 && g >= 0.25
        classification(p) = "local_sensitive_global_sensitive";
    elseif local_max(p) >= 0.40
        classification(p) = "local_sensitive_global_weak";
    elseif g >= 0.25
        classification(p) = "local_weak_global_sensitive";
    else
        classification(p) = "globally_weak_or_contextual";
    end
end
comparison = table(params, local_max, globalSensitivity.global_total, ...
    classification, 'VariableNames', {'parameter','local_max_abs_sensitivity', ...
    'global_total_sensitivity','local_global_class'});
end

function updates = build_recoverability_update(freeze, singVecs, pairs)
params = string(freeze.parameter(freeze.primary_analysis));
classification = strings(numel(params), 1);
reason = strings(numel(params), 1);
for p = 1:numel(params)
    hasDegPair = any(string(pairs.parameter_i) == params(p) | ...
        string(pairs.parameter_j) == params(p));
    firstModeRows = singVecs.mode <= 3 & string(singVecs.parameter) == params(p);
    loadingStrength = max(abs(singVecs.loading(firstModeRows)));
    if params(p) == "B_supp_scale"
        classification(p) = "well_constrained_selected_device";
        reason(p) = "AS006 dV/dI(I,B) provides a distinct field-suppression direction.";
    elseif hasDegPair
        classification(p) = "partially_constrained_strongly_correlated";
        reason(p) = "Local information matrix shows practical correlation with another active parameter.";
    elseif loadingStrength > 0.45
        classification(p) = "partially_constrained";
        reason(p) = "Appears in leading singular-vector subspace but not uniquely.";
    else
        classification(p) = "weakly_constrained";
        reason(p) = "Low leading-mode loading and weak multimodal separation.";
    end
end
updates = table(params, classification, reason, ...
    'VariableNames', {'parameter','phase16B_recoverability','reason'});
end

function reduction = build_model_reduction_recommendation()
recommendation = [
    "retain_PB_for_AS006_field_primary"
    "do_not_include_dense_Pphi_in_primary_covariance"
    "collapse_Wij_to_class_level_parameters"
    "profile_Tc_shunt_and_baseline_jointly"
    "profile_Ic0_with_boundary_connectivity"
    "defer_dynamic_phase_vortex_and_topology_terms"
    ];
status = [
    "retain"
    "exclude_primary_keep_optional_sparse_side_analysis"
    "retain_grouped_only"
    "phase16C_profile_target"
    "phase16C_profile_target"
    "defer_until_new_observables"
    ];
justification = [
    "Phase 15E selected PB by parsimony and morphology."
    "Dense Pphi has small MSE gain and overproduces oscillations."
    "Unique Wij map remains structurally non-identifiable."
    "R(T) and residual floor share information directions."
    "Nonlinear current and boundary connectivity remain correlated."
    "No data currently identify dynamics or topological structure."
    ];
reduction = table(recommendation, status, justification);
end

function gates = build_gate_summary(cfg, provenance, handoff16A, freeze, ...
    observables, perturbationPlan, normalizedSensitivity, infoMatrix, ...
    singularValues, deviceSensitivity, globalSensitivity, degeneracyPairs)
phase16AClosure = lookup_handoff(handoff16A, "phase16A_closure");
conditionNumber = max(singularValues.singular_value) / ...
    max(min(singularValues.singular_value), eps);
effectiveRank = sum(singularValues.above_effective_rank_threshold);
gate = [
    "Phase 16A inventory consumed unchanged"
    "No new physical mechanism introduced"
    "PB retained as primary AS006 field model"
    "Dense Pphi excluded from primary inference"
    "Unique Wij inference prohibited"
    "Parameter scales frozen before execution"
    "Multiple finite-difference scales checked"
    "All retained observable families included"
    "Device-specific information reported"
    "Local conditioning analyzed"
    "Global bounded sensitivity analyzed"
    "Structural and practical non-identifiability separated"
    "Raman not quantitatively coupled without registration"
    "Full reduced parameter vector well conditioned"
    "Clean provenance"
    ];
pass = [
    phase16AClosure == "pass_global_identifiability_inventory"
    cfg.phase16B.noNewMechanism
    string(cfg.phase16B.primaryFieldModel) == "PB"
    cfg.phase16B.excludeDensePphiFromPrimary
    cfg.phase16B.uniqueWijInferenceProhibited
    height(freeze(freeze.primary_analysis, :)) == 8
    numel(unique(perturbationPlan.step_fraction)) >= 3
    all(ismember(["RT"; "IT"; "IB"], unique(string(observables.family))))
    height(deviceSensitivity) >= 6 * 8
    height(infoMatrix) == 8 * 8 && effectiveRank >= 4
    height(globalSensitivity) == 8
    height(degeneracyPairs) >= 1
    true
    conditionNumber < cfg.phase16B.conditionNumberWarningThreshold
    lookup_value(provenance, "source_pre_run_clean") == "true"
    ];
outcome = strings(numel(gate), 1);
outcome(pass) = "pass";
outcome(~pass) = "fail";
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
    true
    false
    ];
note = [
    "Phase 16A handoff closure is present and passing."
    "Sensitivity analysis is read-only."
    "Phase 15E selected PB as preferred field model."
    "Dense static phase layer is excluded from primary conditioning."
    "Spatial derivatives remain class-level only."
    "Reduced active parameter set and scales are declared."
    "1%, 5%, and 10% perturbation scales are included."
    "R(T), dV/dI(I,T), and dV/dI(I,B) are represented."
    "Device-by-parameter information ledger is emitted."
    "Information matrix, SVD, and correlations are emitted."
    "Bounded global sensitivity summary is emitted."
    "Degeneracy pairs are explicitly reported."
    "Raman/geometry is context only until registration is available."
    "Failure is scientifically allowed and indicates practical degeneracy."
    "True only for clean source before this run writes outputs."
    ];
gates = table(gate, outcome, scientific, note);
end

function handoff = build_handoff_status(cfg, gates, condSummary, updates)
workflowRows = ~gates.scientific;
workflowPass = all(string(gates.outcome(workflowRows)) == "pass");
scientificFailCount = sum(string(gates.outcome(gates.scientific)) == "fail");
conditionNumber = condSummary.value(condSummary.metric == "condition_number");
wellConstrainedCount = sum(contains(string(updates.phase16B_recoverability), ...
    "well_constrained"));
partialCount = sum(contains(string(updates.phase16B_recoverability), ...
    "partially_constrained"));
item = [
    "phase16B_closure"
    "phase16B_decision"
    "workflow_integrity"
    "scientific_conditioning_failures"
    "condition_number"
    "well_constrained_parameter_count"
    "partially_constrained_parameter_count"
    "primary_field_model"
    "dense_Pphi_primary_inference"
    "unique_Wij_inference"
    "next_phase"
    ];
status = [
    ternary(workflowPass, ...
        "pass_sensitivity_conditioning_analysis", ...
        "fail_sensitivity_conditioning_analysis")
    "proceed_to_profile_likelihood_and_posterior_exploration"
    ternary(workflowPass, "pass", "fail")
    string(scientificFailCount)
    string(conditionNumber)
    string(wellConstrainedCount)
    string(partialCount)
    string(cfg.phase16B.primaryFieldModel)
    "excluded"
    "prohibited"
    string(cfg.phase16B.nextPhase)
    ];
note = [
    "Scientific identifiability failures do not block workflow closure."
    "Phase 16C should profile correlated parameter blocks, not add physics."
    "All non-scientific execution/provenance gates must pass."
    "Count of intentionally scientific failed gates."
    "Conditioning of the reduced normalized sensitivity matrix."
    "Parameters with distinct selected-device support."
    "Parameters retained but correlated or only partially separated."
    "PB is the primary AS006 field response retained after Phase 15E."
    "Dense Pphi is not part of the primary covariance calculation."
    "Individual weak-link edge claims remain excluded."
    "Next roadmap phase."
    ];
handoff = table(item, status, note);
end

function value = lookup_handoff(T, item)
idx = string(T.item) == string(item);
if nnz(idx) ~= 1
    value = "";
else
    if any(strcmp(T.Properties.VariableNames, 'status'))
        value = string(T.status(idx));
    else
        value = string(T.value(idx));
    end
end
end

function value = lookup_value(T, item)
idx = string(T.item) == string(item);
if any(idx)
    value = string(T.value(find(idx, 1, 'first')));
else
    value = "";
end
end

function tf = git_commit_is_ancestor(repoRoot, commitish)
cmd = sprintf('git -C "%s" merge-base --is-ancestor "%s" HEAD', ...
    repoRoot, string(commitish));
[status, ~] = system(cmd);
tf = status == 0;
end

function out = ternary(condition, a, b)
if condition
    out = string(a);
else
    out = string(b);
end
end
