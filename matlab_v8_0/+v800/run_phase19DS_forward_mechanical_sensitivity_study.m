function out = run_phase19DS_forward_mechanical_sensitivity_study(cfg)
%RUN_PHASE19DS_FORWARD_MECHANICAL_SENSITIVITY_STUDY
% Execute a normalized/unit-load forward mechanics atlas.
%
% This synthetic branch is separate from the locked quantitative branch:
% it produces dimensionless geometry-dependent mechanical descriptors, not
% device-specific strain reconstructions or absolute FEM strain tensors.

if ~exist(cfg.outputDir, 'dir')
    mkdir(cfg.outputDir);
end

paths = phase19DS_paths(cfg);
sourceProvenance = build_source_provenance(cfg);
inputs = load_inputs(paths);
pdeAvailable = pde_toolbox_available();

branchPolicy = build_branch_policy(pdeAvailable);
atlasManifest = build_atlas_manifest(cfg);
[metricSummary, linecutSummary] = build_metric_summary(atlasManifest);
sensitivitySummary = build_sensitivity_summary(atlasManifest);
transportCouplingCandidates = build_transport_coupling_candidates( ...
    atlasManifest);
gateSummary = build_gate_summary(inputs, branchPolicy, metricSummary, ...
    sensitivitySummary, sourceProvenance);
handoffStatus = build_handoff_status(gateSummary, branchPolicy);

writetable(branchPolicy, paths.branchPolicy);
writetable(atlasManifest, paths.atlasManifest);
writetable(metricSummary, paths.metricSummary);
writetable(linecutSummary, paths.linecutSummary);
writetable(sensitivitySummary, paths.sensitivitySummary);
writetable(transportCouplingCandidates, paths.transportCouplingCandidates);
writetable(gateSummary, paths.gateSummary);
writetable(handoffStatus, paths.handoffStatus);
writetable(sourceProvenance, paths.sourceProvenance);

try
    h = plot_summary(paths, atlasManifest, metricSummary, ...
        sensitivitySummary, transportCouplingCandidates, gateSummary);
catch ME
    warning('v8:phase19DSPlotFailed', ...
        'Phase 19D-S summary plot failed: %s', ME.message);
    h = [];
end

out = struct();
out.config = cfg;
out.inputs = inputs;
out.branchPolicy = branchPolicy;
out.atlasManifest = atlasManifest;
out.metricSummary = metricSummary;
out.linecutSummary = linecutSummary;
out.sensitivitySummary = sensitivitySummary;
out.transportCouplingCandidates = transportCouplingCandidates;
out.gateSummary = gateSummary;
out.handoffStatus = handoffStatus;
out.sourceProvenance = sourceProvenance;
out.figure = h;
out.paths = paths;
end

function paths = phase19DS_paths(cfg)
outputDir = cfg.outputDir;
paths = struct();
paths.phase19BHandoff = fullfile(outputDir, ...
    'phase19B_handoff_status.csv');
paths.phase19BUnlockCriteria = fullfile(outputDir, ...
    'phase19B_execution_unlock_criteria.csv');
paths.branchPolicy = fullfile(outputDir, ...
    'phase19DS_branch_policy.csv');
paths.atlasManifest = fullfile(outputDir, ...
    'phase19DS_normalized_atlas_manifest.csv');
paths.metricSummary = fullfile(outputDir, ...
    'phase19DS_unit_load_metric_summary.csv');
paths.linecutSummary = fullfile(outputDir, ...
    'phase19DS_linecut_summary.csv');
paths.sensitivitySummary = fullfile(outputDir, ...
    'phase19DS_parameter_sensitivity_summary.csv');
paths.transportCouplingCandidates = fullfile(outputDir, ...
    'phase19DS_transport_coupling_candidates.csv');
paths.gateSummary = fullfile(outputDir, ...
    'phase19DS_gate_summary.csv');
paths.handoffStatus = fullfile(outputDir, ...
    'phase19DS_handoff_status.csv');
paths.sourceProvenance = fullfile(outputDir, ...
    'phase19DS_source_provenance.csv');
paths.figureBase = fullfile(outputDir, ...
    'phase19DS_forward_mechanical_sensitivity_summary');
paths.figurePng = [paths.figureBase '.png'];
paths.figurePdf = [paths.figureBase '.pdf'];
end

function inputs = load_inputs(paths)
inputs = struct();
inputs.phase19BHandoff = read_required_table(paths.phase19BHandoff);
inputs.phase19BUnlockCriteria = read_required_table( ...
    paths.phase19BUnlockCriteria);
end

function T = read_required_table(pathValue)
if ~exist(pathValue, 'file')
    error('Required Phase 19D-S input is missing:\n%s', pathValue);
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
    "phase19DS_forward_mechanical_sensitivity_study"
    sourceStatus.commit_sha
    sourceStatus.tree_sha
    string(sourceStatus.tracked_clean)
    string(sourceStatus.untracked_clean)
    string(sourceStatus.tracked_clean && sourceStatus.untracked_clean)
    "normalized_forward_mechanics_no_absolute_device_strain_claims"
    "Commit Phase 19D-S source first; rerun from clean source; commit generated artifacts separately."
    ];
note = [
    "Phase 19D-S executes a normalized/unit-load mechanics atlas."
    "Git commit captured before this runner writes outputs."
    "Git tree captured before this runner writes outputs."
    "Tracked-source cleanliness before output generation."
    "Untracked-source/artifact cleanliness before output generation."
    "True only when tracked and untracked source state are clean before output generation."
    "No device-specific strain reconstruction, no Raman inversion, no absolute strain validation."
    "Artifacts may dirty the checkout after pre-run provenance is captured."
    ];
provenance = table(item, value, note);
end

function tf = pde_toolbox_available()
v = ver;
tf = any(strcmp({v.Name}, 'Partial Differential Equation Toolbox'));
end

function policy = build_branch_policy(pdeAvailable)
item = [
    "device_specific_strain_claims_allowed"
    "quantitative_absolute_strain_validation_allowed"
    "normalized_forward_mechanics_execution_allowed"
    "reduced_2D_unit_load_atlas_executed"
    "PDE_toolbox_available"
    "validated_geometry_to_PDE_solver_available"
    "full_PDE_FEM_execution_allowed"
    "parameter_sensitivity_allowed"
    "transport_coupling_prior_generation_allowed"
    ];
value = [
    "false"
    "false"
    "true"
    "true"
    string(pdeAvailable)
    "false"
    "false"
    "true"
    "true"
    ];
note = [
    "Phase 19A/19B quantitative branch remains locked."
    "No absolute strain is validated against device-specific Raman registration."
    "Dimensionless geometry consequences can be studied now."
    "This phase executes an analytic reduced 2D atlas under unit load."
    "MATLAB PDE Toolbox availability is recorded, but availability is not validation."
    "The canonical branch lacks a verified geometry-to-PDE meshing/solver pipeline."
    "Full FEM is deferred to a solver-validation subphase."
    "Uncertain normalized parameters are swept as dimensions of the study."
    "Mechanics-derived normalized H_mech candidates may be compared to geometry priors later."
    ];
policy = table(item, value, note);
end

function manifest = build_atlas_manifest(cfg)
devices = string(cfg.devices(:));
geometryFamily = strings(size(devices));
mechanicalMotif = strings(size(devices));
boundaryCoordinate = nan(size(devices));
crackCoordinate = nan(size(devices));
for k = 1:numel(devices)
    switch devices(k)
        case {"AS002", "AS004", "AS006"}
            geometryFamily(k) = "half_coverage_boundary";
            mechanicalMotif(k) = "boundary_shear_and_decay";
            boundaryCoordinate(k) = 0.5;
        case "AS005"
            geometryFamily(k) = "cracked_coverage";
            mechanicalMotif(k) = "crack_localization_and_relaxation";
            crackCoordinate(k) = 0.62;
        otherwise
            geometryFamily(k) = "continuous_or_control_coverage";
            mechanicalMotif(k) = "low_lateral_gradient_control";
    end
end
loadPolicy = repmat("unit_load_dimensionless", numel(devices), 1);
normalization = repmat("max_sqrt_eps_contract_eps", numel(devices), 1);
claimScope = repmat( ...
    "geometry_consequence_only_not_device_specific_strain", ...
    numel(devices), 1);
manifest = table(devices, geometryFamily, mechanicalMotif, ...
    boundaryCoordinate, crackCoordinate, loadPolicy, normalization, ...
    claimScope, 'VariableNames', {'device', 'geometry_family', ...
    'mechanical_motif', 'boundary_coordinate_xhat', ...
    'crack_coordinate_xhat', 'load_policy', 'normalization', ...
    'claim_scope'});
end

function [metrics, linecuts] = build_metric_summary(manifest)
rows = table();
lineRows = table();
for k = 1:height(manifest)
    fields = atlas_fields(string(manifest.device(k)), ...
        string(manifest.geometry_family(k)), default_params());
    row = metrics_from_fields(string(manifest.device(k)), ...
        string(manifest.geometry_family(k)), fields);
    rows = [rows; struct2table(row)]; %#ok<AGROW>

    lineRows = [lineRows; linecut_from_fields(string(manifest.device(k)), ...
        string(manifest.geometry_family(k)), fields)]; %#ok<AGROW>
end
metrics = rows;
linecuts = lineRows;
end

function sensitivity = build_sensitivity_summary(manifest)
lambdaVals = [0.05 0.10 0.18];
boundaryVals = [0.55 0.85 1.15];
crackVals = [0.50 0.85 1.20];
interfaceVals = [0.70 1.00 1.30];
metricNames = ["localization_factor"; "shear_factor"; ...
    "gradient_factor"; "high_gradient_area_fraction"];
rows = table();
for k = 1:height(manifest)
    device = string(manifest.device(k));
    family = string(manifest.geometry_family(k));
    values = nan(numel(lambdaVals) * numel(boundaryVals) * ...
        numel(crackVals) * numel(interfaceVals), numel(metricNames));
    n = 0;
    for a = 1:numel(lambdaVals)
        for b = 1:numel(boundaryVals)
            for c = 1:numel(crackVals)
                for d = 1:numel(interfaceVals)
                    n = n + 1;
                    params = default_params();
                    params.lambda = lambdaVals(a);
                    params.boundaryAmp = boundaryVals(b);
                    params.crackAmp = crackVals(c);
                    params.interfaceScale = interfaceVals(d);
                    fields = atlas_fields(device, family, params);
                    m = metrics_from_fields(device, family, fields);
                    values(n, :) = [m.localization_factor, ...
                        m.shear_factor, m.gradient_factor, ...
                        m.high_gradient_area_fraction];
                end
            end
        end
    end
    for q = 1:numel(metricNames)
        vals = values(:, q);
        rows = [rows; table(device, family, metricNames(q), ...
            min(vals), median(vals), max(vals), max(vals) - min(vals), ...
            robust_status(metricNames(q), min(vals), median(vals), max(vals)), ...
            'VariableNames', {'device', 'geometry_family', 'metric', ...
            'min_value', 'median_value', 'max_value', 'range_value', ...
            'robust_interpretation'})]; %#ok<AGROW>
    end
end
sensitivity = rows;
end

function candidates = build_transport_coupling_candidates(manifest)
rows = table();
weights = [
    1.0 0.0 0.0
    0.0 1.0 0.0
    0.0 0.0 1.0
    0.45 0.35 0.20
    0.30 0.30 0.40
    ];
candidate = [
    "hydrostatic_normalized"
    "shear_normalized"
    "gradient_normalized"
    "balanced_hydrostatic_shear_gradient"
    "gradient_weighted_localization"
    ];
for k = 1:height(manifest)
    device = string(manifest.device(k));
    family = string(manifest.geometry_family(k));
    fields = atlas_fields(device, family, default_params());
    absHydro = abs(fields.eps_h);
    absShear = abs(fields.eps_xy);
    grad = fields.grad_h;
    components = cat(3, norm01(absHydro), norm01(absShear), ...
        norm01(grad));
    for c = 1:numel(candidate)
        H = weights(c, 1) .* components(:, :, 1) + ...
            weights(c, 2) .* components(:, :, 2) + ...
            weights(c, 3) .* components(:, :, 3);
        rows = [rows; table(device, family, candidate(c), ...
            weights(c, 1), weights(c, 2), weights(c, 3), ...
            max(H, [], 'all'), mean(H, 'all'), ...
            sum(H > 0.70, 'all') / numel(H), ...
            "candidate_only_no_transport_refit", ...
            'VariableNames', {'device', 'geometry_family', ...
            'H_mech_candidate', 'weight_hydrostatic', 'weight_shear', ...
            'weight_gradient', 'max_H', 'mean_H', ...
            'area_fraction_H_gt_0p70', 'allowed_use'})]; %#ok<AGROW>
    end
end
candidates = rows;
end

function params = default_params()
params.lambda = 0.10;
params.boundaryAmp = 0.85;
params.crackAmp = 0.85;
params.interfaceScale = 1.0;
params.nx = 121;
params.ny = 61;
end

function fields = atlas_fields(device, family, params)
x = linspace(0, 1, params.nx);
y = linspace(0, 1, params.ny);
[X, Y] = meshgrid(x, y);

coverage = ones(size(X));
boundary = zeros(size(X));
crack = zeros(size(X));
if family == "half_coverage_boundary"
    edge = 0.5;
    coverage = 0.5 .* (1 + tanh((X - edge) ./ params.lambda));
    boundary = exp(-((X - edge) ./ params.lambda).^2);
elseif family == "cracked_coverage"
    edge = 0.5;
    coverage = 0.75 + 0.25 .* tanh((X - edge) ./ (1.4 * params.lambda));
    crack = exp(-((X - 0.62) ./ (0.9 * params.lambda)).^2 - ...
        ((Y - 0.50) ./ (1.8 * params.lambda)).^2);
end

loadSign = 1;
if any(device == ["AS002", "AS004", "AS006"])
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
eps_xx = eps_xx ./ scale;
eps_yy = eps_yy ./ scale;
eps_xy = eps_xy ./ scale;
eps_h = eps_xx + eps_yy;
[gy, gx] = gradient(eps_h, y(2) - y(1), x(2) - x(1));
grad_h = sqrt(gx.^2 + gy.^2);

fields = struct();
fields.x = x;
fields.y = y;
fields.X = X;
fields.Y = Y;
fields.coverage = coverage;
fields.eps_xx = eps_xx;
fields.eps_yy = eps_yy;
fields.eps_xy = eps_xy;
fields.eps_h = eps_h;
fields.grad_h = grad_h;
fields.contract = contract ./ scale;
end

function row = metrics_from_fields(device, family, fields)
absParallel = abs(fields.eps_xx + fields.eps_yy);
meanParallel = mean(absParallel, 'all');
if meanParallel == 0
    meanParallel = eps;
end
localization = max(absParallel, [], 'all') ./ meanParallel;
shearFactor = max(abs(fields.eps_xy), [], 'all') ./ ...
    mean(abs(fields.eps_xx) + abs(fields.eps_yy), 'all');
gradientFactor = max(fields.grad_h, [], 'all') ./ ...
    max(mean(fields.grad_h, 'all'), eps);
threshold = 0.70 .* max(fields.grad_h, [], 'all');
highGradientFraction = sum(fields.grad_h > threshold, 'all') ./ ...
    numel(fields.grad_h);

covered = fields.coverage > 0.70;
uncovered = fields.coverage < 0.30;
if any(covered, 'all') && any(uncovered, 'all')
    contrast = mean(absParallel(covered), 'all') ./ ...
        max(mean(absParallel(uncovered), 'all'), eps);
else
    contrast = NaN;
end

[~, idx] = max(fields.grad_h, [], 'all');
[iy, ix] = ind2sub(size(fields.grad_h), idx);
distanceToBoundary = abs(fields.x(ix) - 0.5);
decayLength = estimate_decay_length(fields);

row = struct();
row.device = device;
row.geometry_family = family;
row.localization_factor = localization;
row.shear_factor = shearFactor;
row.gradient_factor = gradientFactor;
row.high_gradient_area_fraction = highGradientFraction;
row.covered_to_uncovered_parallel_contrast = contrast;
row.max_gradient_xhat = fields.x(ix);
row.max_gradient_yhat = fields.y(iy);
row.distance_of_max_gradient_from_boundary = distanceToBoundary;
row.characteristic_decay_length_xhat = decayLength;
row.claim_scope = "dimensionless_forward_geometry_metric";
end

function linecuts = linecut_from_fields(device, family, fields)
[~, iy] = min(abs(fields.y - 0.5));
xq = linspace(0, 1, 21).';
epsH = interp1(fields.x(:), fields.eps_h(iy, :).', xq, 'linear');
epsXY = interp1(fields.x(:), fields.eps_xy(iy, :).', xq, 'linear');
gradH = interp1(fields.x(:), fields.grad_h(iy, :).', xq, 'linear');
linecuts = table(repmat(device, numel(xq), 1), ...
    repmat(family, numel(xq), 1), xq, epsH, epsXY, gradH, ...
    'VariableNames', {'device', 'geometry_family', 'xhat', ...
    'eps_h_linecut', 'eps_xy_linecut', 'grad_h_linecut'});
end

function lambda = estimate_decay_length(fields)
[~, iy] = min(abs(fields.y - 0.5));
x = fields.x(:);
v = abs(fields.grad_h(iy, :).');
idx = x >= 0.5 & x <= 0.9 & v > 0;
if sum(idx) < 5 || max(v(idx)) <= 0
    lambda = NaN;
    return;
end
xx = x(idx) - 0.5;
yy = log(v(idx) ./ max(v(idx)));
p = polyfit(xx, yy, 1);
if p(1) >= 0
    lambda = NaN;
else
    lambda = -1 ./ p(1);
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

function status = robust_status(metric, mn, med, mx)
if metric == "localization_factor" && med > 1.5
    status = "robust_localization_present";
elseif metric == "shear_factor" && med > 0.25
    status = "robust_shear_component_present";
elseif metric == "gradient_factor" && med > 3
    status = "robust_gradient_localization_present";
elseif mx - mn < 0.10 * max(abs(med), eps)
    status = "low_parameter_sensitivity";
else
    status = "parameter_sensitive_but_quantified";
end
end

function gates = build_gate_summary(inputs, policy, metrics, sensitivity, ...
    sourceProvenance)
sourceClean = lookup_item(sourceProvenance, "source_pre_run_clean") == "true";
phase19BClosed = lookup_item(inputs.phase19BHandoff, ...
    "phase19B_closure") == "pass_specification_only_no_FEM_execution";
noDeviceClaims = lookup_policy(policy, ...
    "device_specific_strain_claims_allowed") == "false";
normalizedAllowed = lookup_policy(policy, ...
    "normalized_forward_mechanics_execution_allowed") == "true";
atlasCompleted = height(metrics) == 6;
sensitivityCompleted = height(sensitivity) >= 6;
transportCandidatesAllowed = lookup_policy(policy, ...
    "transport_coupling_prior_generation_allowed") == "true";

component = [
    "Clean provenance"
    "Phase 19B specification consumed"
    "Quantitative device-strain claims remain blocked"
    "Normalized forward mechanics allowed"
    "Six-device normalized atlas completed"
    "Parameter sensitivity completed"
    "Transport-prior candidates allowed"
    "Full PDE/FEM remains separate from reduced atlas"
    ];
pass = [
    sourceClean
    phase19BClosed
    noDeviceClaims
    normalizedAllowed
    atlasCompleted
    sensitivityCompleted
    transportCandidatesAllowed
    true
    ];
status = pass_fail(pass);
note = [
    "Canonical artifact freeze requires clean pre-run source state."
    "Phase 19D-S starts after the Phase 19B specification freeze."
    "No AS005/AS006 absolute strain map is claimed."
    "Unit-load dimensionless geometry consequences can be computed now."
    "AS001-AS006 all receive reduced normalized mechanics descriptors."
    "Uncertain reduced parameters are swept instead of hidden."
    "H_mech candidates may be used in later ablation against geometry/randomized priors."
    "PDE Toolbox availability is not treated as a validated solver pipeline."
    ];
gates = table(component, status, pass, note);
end

function handoff = build_handoff_status(gateSummary, policy)
allPass = all(gateSummary.pass);
item = [
    "phase19DS_closure"
    "device_specific_strain_claims_allowed"
    "normalized_mechanical_comparison_allowed"
    "absolute_strain_validation_allowed"
    "PDE_toolbox_available"
    "full_PDE_FEM_execution_allowed"
    "transport_coupling_candidates_generated"
    "next_phase"
    ];
value = [
    ternary(allPass, "pass_normalized_forward_mechanics_atlas", ...
        "fail_forward_mechanics_sensitivity_study")
    lookup_policy(policy, "device_specific_strain_claims_allowed")
    lookup_policy(policy, "normalized_forward_mechanics_execution_allowed")
    lookup_policy(policy, ...
        "quantitative_absolute_strain_validation_allowed")
    lookup_policy(policy, "PDE_toolbox_available")
    lookup_policy(policy, "full_PDE_FEM_execution_allowed")
    lookup_policy(policy, "transport_coupling_prior_generation_allowed")
    "phase19ES_uncertainty_scaling_and_mechanics_prior_ablation"
    ];
note = [
    "Closure means dimensionless forward geometry metrics are frozen."
    "The quantitative device-specific branch remains locked."
    "Normalized unit-load comparisons are allowed and generated."
    "Absolute strain validation remains blocked."
    "Toolbox availability is recorded for future solver-backed FEM."
    "Full PDE/FEM waits for geometry-to-solver validation."
    "H_mech candidates are generated for future weak-link coupling tests."
    "Next phase should quantify scaling/UQ and compare mechanics priors to geometry/random controls."
    ];
handoff = table(item, value, note);
end

function value = lookup_policy(policy, key)
value = lookup_item(policy, key);
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

function h = plot_summary(paths, manifest, metrics, sensitivity, ...
    candidates, gateSummary)
h = figure('Name', 'v8 Phase 19D-S forward mechanics atlas', ...
    'Color', 'w', 'Position', [100 100 1500 900]);
tiledlayout(2, 3, 'Padding', 'compact', 'TileSpacing', 'compact');

nexttile;
bar(categorical(metrics.device), metrics.localization_factor);
title('localization factor');
ylabel('max / mean');
grid on;

nexttile;
bar(categorical(metrics.device), metrics.shear_factor);
title('normalized shear factor');
grid on;

nexttile;
bar(categorical(metrics.device), metrics.gradient_factor);
title('gradient localization');
grid on;

nexttile;
classes = categorical(manifest.geometry_family);
bar(categorical(categories(classes)), countcats(classes));
title('geometry families');
xtickangle(25);
grid on;

nexttile;
gradRows = sensitivity.metric == "gradient_factor";
bar(categorical(sensitivity.device(gradRows)), ...
    sensitivity.median_value(gradRows));
title('median gradient factor in sweep');
grid on;

nexttile;
balanced = candidates.H_mech_candidate == ...
    "balanced_hydrostatic_shear_gradient";
bar(categorical(candidates.device(balanced)), ...
    candidates.area_fraction_H_gt_0p70(balanced));
title('H_{mech} high-field area');
ylabel('area fraction > 0.70');
grid on;

sgtitle('Phase 19D-S normalized forward mechanics: no absolute strain claims');
exportgraphics(h, paths.figurePng, 'Resolution', 200);
exportgraphics(h, paths.figurePdf, 'ContentType', 'vector');
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
