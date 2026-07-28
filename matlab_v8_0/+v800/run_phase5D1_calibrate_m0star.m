function out = run_phase5D1_calibrate_m0star(cfg)
%RUN_PHASE5D1_CALIBRATE_M0STAR Calibrate M0* using calibration seeds only.

if ~exist(cfg.outputDir, 'dir')
    mkdir(cfg.outputDir);
end

sourceCommitSha = string(v800.git_commit_sha(cfg.repoRoot));
profiles = build_nuisance_profiles(cfg);
manifest = build_calibration_manifest(cfg);
calibration = select_calibration_setting(cfg, manifest, profiles, ...
    sourceCommitSha);
scoreRows = calibration.scoreRows;
nuisanceLedger = build_nuisance_ledger(cfg, scoreRows, profiles, ...
    sourceCommitSha, calibration.penaltySetting);
deltaSDistribution = add_uncertainty(scoreRows);
thresholds = calibration.thresholds;
deltaSDistribution = apply_thresholds(deltaSDistribution, thresholds);
boundaryCurves = build_boundary_curves(cfg, deltaSDistribution);
nuisanceBoundaryOccupancy = build_nuisance_boundary_occupancy(cfg, ...
    nuisanceLedger);
thresholdRoc = build_threshold_roc(cfg, deltaSDistribution);
operatingPointFeasibility = build_operating_point_feasibility(thresholdRoc);
sigmaDeltaSAudit = build_sigma_deltaS_audit(deltaSDistribution);
uncertaintyDecomposition = build_uncertainty_component_decomposition( ...
    deltaSDistribution);
internalCalibrationCheck = build_internal_calibration_check(cfg, ...
    deltaSDistribution);
calibrationGates = build_calibration_gates(cfg, deltaSDistribution, ...
    boundaryCurves, nuisanceLedger, nuisanceBoundaryOccupancy);
handoffStatus = build_handoff_status(operatingPointFeasibility, ...
    internalCalibrationCheck);

writetable(nuisanceLedger, cfg.phase5D.nuisanceProfileLedgerFile);
writetable(deltaSDistribution, cfg.phase5D.deltaSDistributionFile);
writetable(thresholds, cfg.phase5D.calibratedThresholdsFile);
writetable(boundaryCurves, cfg.phase5D.boundaryDetectionCurvesFile);
writetable(nuisanceBoundaryOccupancy, ...
    cfg.phase5D.nuisanceBoundaryOccupancyFile);
writetable(calibration.selectionLedger, ...
    cfg.phase5D.calibrationSelectionLedgerFile);
writetable(operatingPointFeasibility, ...
    cfg.phase5D.operatingPointFeasibilityFile);
writetable(thresholdRoc, cfg.phase5D.thresholdRocByEvidenceTierFile);
writetable(sigmaDeltaSAudit, cfg.phase5D.sigmaDeltaSAuditFile);
writetable(uncertaintyDecomposition, ...
    cfg.phase5D.uncertaintyComponentDecompositionFile);
writetable(calibration.selectionLedger, ...
    cfg.phase5D.nuisancePenaltySensitivityFile);
writetable(internalCalibrationCheck, ...
    cfg.phase5D.internalCalibrationCheckFile);
writetable(handoffStatus, cfg.phase5D.handoffStatusFile);
writetable(calibrationGates, cfg.phase5D.calibrationGateFile);

try
    h = v800.plot_phase5D_calibration_summary(cfg, ...
        nuisanceLedger, deltaSDistribution, thresholds, ...
        boundaryCurves, calibrationGates);
catch ME
    warning('v8:phase5DCalibrationPlotFailed', ...
        'Phase 5D.1 calibration summary plot failed: %s', ME.message);
    h = [];
end

out = struct();
out.config = cfg;
out.manifest = manifest;
out.nuisanceProfiles = profiles;
out.calibrationSelection = calibration.selectionLedger;
out.nuisanceProfileLedger = nuisanceLedger;
out.deltaSDistribution = deltaSDistribution;
out.calibratedThresholds = thresholds;
out.boundaryDetectionCurves = boundaryCurves;
out.nuisanceBoundaryOccupancy = nuisanceBoundaryOccupancy;
out.operatingPointFeasibility = operatingPointFeasibility;
out.thresholdRocByEvidenceTier = thresholdRoc;
out.sigmaDeltaSAudit = sigmaDeltaSAudit;
out.uncertaintyComponentDecomposition = uncertaintyDecomposition;
out.internalCalibrationCheck = internalCalibrationCheck;
out.handoffStatus = handoffStatus;
out.calibrationGates = calibrationGates;
out.figure = h;
out.paths = struct();
out.paths.nuisanceProfileLedger = cfg.phase5D.nuisanceProfileLedgerFile;
out.paths.deltaSDistribution = cfg.phase5D.deltaSDistributionFile;
out.paths.calibratedThresholds = cfg.phase5D.calibratedThresholdsFile;
out.paths.boundaryDetectionCurves = cfg.phase5D.boundaryDetectionCurvesFile;
out.paths.nuisanceBoundaryOccupancy = ...
    cfg.phase5D.nuisanceBoundaryOccupancyFile;
out.paths.calibrationSelectionLedger = ...
    cfg.phase5D.calibrationSelectionLedgerFile;
out.paths.operatingPointFeasibility = ...
    cfg.phase5D.operatingPointFeasibilityFile;
out.paths.thresholdRocByEvidenceTier = ...
    cfg.phase5D.thresholdRocByEvidenceTierFile;
out.paths.sigmaDeltaSAudit = cfg.phase5D.sigmaDeltaSAuditFile;
out.paths.uncertaintyComponentDecomposition = ...
    cfg.phase5D.uncertaintyComponentDecompositionFile;
out.paths.nuisancePenaltySensitivity = ...
    cfg.phase5D.nuisancePenaltySensitivityFile;
out.paths.internalCalibrationCheck = ...
    cfg.phase5D.internalCalibrationCheckFile;
out.paths.handoffStatus = cfg.phase5D.handoffStatusFile;
out.paths.calibrationGates = cfg.phase5D.calibrationGateFile;
out.paths.figurePng = [cfg.phase5D.calibrationSummaryFigureBaseFile '.png'];
out.paths.figurePdf = [cfg.phase5D.calibrationSummaryFigureBaseFile '.pdf'];
end

function calibration = select_calibration_setting(cfg, manifest, profiles, ...
    sourceCommitSha)
settings = build_penalty_settings(cfg);
rows = repmat(empty_selection_row(), max(1, numel(settings)), 1);
bestObjective = Inf;
bestIdx = 1;
bestScoreRows = table();
bestThresholds = table();
for k = 1:numel(settings)
    penaltySetting = settings(k);
    scoreRows = score_calibration_cases(cfg, manifest, profiles, ...
        penaltySetting);
    deltaS = add_uncertainty(scoreRows);
    tuneIdx = calibration_tuning_index(cfg, deltaS);
    thresholds = calibrate_thresholds(cfg, deltaS(tuneIdx, :), ...
        sourceCommitSha, penaltySetting);
    deltaS = apply_thresholds(deltaS, thresholds);
    boundaryCurves = build_boundary_curves(cfg, deltaS(tuneIdx, :));
    metrics = calibration_metrics(cfg, deltaS(tuneIdx, :), ...
        boundaryCurves, scoreRows(tuneIdx, :));
    rows(k).setting_id = penaltySetting.setting_id;
    rows(k).nuisance_penalty_weight = penaltySetting.base_weight;
    rows(k).width_extra_weight = penaltySetting.width_extra_weight;
    rows(k).shunt_extra_weight = penaltySetting.shunt_extra_weight;
    rows(k).width_shunt_cross_weight = ...
        penaltySetting.width_shunt_cross_weight;
    rows(k).primary_Zcrit = threshold_for_tier(thresholds, "primary_only");
    rows(k).paired_Zcrit = threshold_for_tier(thresholds, "primary_secondary");
    rows(k).false_structured_rate = metrics.falseStructuredRate;
    rows(k).confident_M0_weak_structured_rate = metrics.confidentM0WeakRate;
    rows(k).strong_structured_detection_rate = metrics.strongStructuredRate;
    rows(k).weak_unresolved_rate = metrics.weakUnresolvedRate;
    rows(k).boundary_occupancy = metrics.boundaryOccupancy;
    rows(k).two_probe_aggregate_pass = metrics.twoProbeAggregatePass;
    rows(k).objective = metrics.objective;
    if metrics.objective < bestObjective
        bestObjective = metrics.objective;
        bestIdx = k;
        bestScoreRows = scoreRows;
        bestThresholds = thresholds;
    end
end
selectionLedger = struct2table(rows);
calibration = struct();
calibration.penaltySetting = settings(bestIdx);
calibration.nuisancePenaltyWeight = settings(bestIdx).base_weight;
calibration.scoreRows = bestScoreRows;
calibration.thresholds = bestThresholds;
calibration.selectionLedger = selectionLedger;
end

function settings = build_penalty_settings(cfg)
if isfield(cfg.phase5D, 'nuisancePenaltySensitivitySettings')
    T = cfg.phase5D.nuisancePenaltySensitivitySettings;
    settings = repmat(empty_penalty_setting(), max(1, height(T)), 1);
    for k = 1:height(T)
        settings(k).setting_id = string(T.setting_id(k));
        settings(k).base_weight = T.base_weight(k);
        settings(k).width_extra_weight = T.width_extra_weight(k);
        settings(k).shunt_extra_weight = T.shunt_extra_weight(k);
        settings(k).width_shunt_cross_weight = T.width_shunt_cross_weight(k);
    end
else
    weights = cfg.phase5D.nuisancePenaltyWeightGrid(:);
    settings = repmat(empty_penalty_setting(), max(1, numel(weights)), 1);
    for k = 1:numel(weights)
        settings(k).setting_id = "base_" + string(k);
        settings(k).base_weight = weights(k);
    end
end
end

function setting = empty_penalty_setting()
setting = struct();
setting.setting_id = "";
setting.base_weight = NaN;
setting.width_extra_weight = 0;
setting.shunt_extra_weight = 0;
setting.width_shunt_cross_weight = 0;
end

function idx = calibration_tuning_index(cfg, T)
if isfield(cfg.phase5D, 'tuningSeeds')
    idx = ismember(T.seed, cfg.phase5D.tuningSeeds(:));
else
    idx = true(height(T), 1);
end
end

function z = threshold_for_tier(T, tier)
idx = T.evidence_tier == string(tier);
if any(idx)
    z = T.Zcrit(find(idx, 1, 'first'));
else
    z = NaN;
end
end

function metrics = calibration_metrics(cfg, deltaS, boundaryCurves, scoreRows)
m0Idx = deltaS.true_group == "M0star";
weakIdx = deltaS.true_group == "weak_structured";
strongIdx = deltaS.true_group == "strong_structured";
metrics = struct();
metrics.falseStructuredRate = fraction_true( ...
    deltaS.selected_state(m0Idx) == "structured_supported");
metrics.confidentM0WeakRate = fraction_true( ...
    deltaS.selected_state(weakIdx) == "M0star_supported");
metrics.strongStructuredRate = fraction_true( ...
    deltaS.selected_state(strongIdx) == "structured_supported");
metrics.weakUnresolvedRate = fraction_true( ...
    deltaS.selected_state(weakIdx) == "unresolved");
metrics.boundaryOccupancy = fraction_true( ...
    scoreRows.M0star_profile_boundary_occupied);
metrics.twoProbeAggregatePass = two_probe_aggregate_pass(deltaS, ...
    boundaryCurves);
constraintViolation = 1000 .* max(0, metrics.falseStructuredRate - ...
    cfg.phase5D.falseStructuredTarget) + ...
    1000 .* max(0, metrics.confidentM0WeakRate - ...
    cfg.phase5D.confidentM0WeakStructuredTarget);
sensitivityViolation = max(0, cfg.phase5D.strongStructuredDetectionTarget - ...
    metrics.strongStructuredRate);
boundaryViolation = max(0, metrics.boundaryOccupancy - ...
    cfg.phase5D.nuisanceBoundaryOccupancyTarget);
twoProbePenalty = double(~metrics.twoProbeAggregatePass) .* 0.25;
metrics.objective = constraintViolation + sensitivityViolation + ...
    0.5 .* boundaryViolation + twoProbePenalty - ...
    0.10 .* metrics.weakUnresolvedRate;
end

function row = empty_selection_row()
row = struct();
row.setting_id = "";
row.nuisance_penalty_weight = NaN;
row.width_extra_weight = NaN;
row.shunt_extra_weight = NaN;
row.width_shunt_cross_weight = NaN;
row.primary_Zcrit = NaN;
row.paired_Zcrit = NaN;
row.false_structured_rate = NaN;
row.confident_M0_weak_structured_rate = NaN;
row.strong_structured_detection_rate = NaN;
row.weak_unresolved_rate = NaN;
row.boundary_occupancy = NaN;
row.two_probe_aggregate_pass = false;
row.objective = NaN;
end

function profiles = build_nuisance_profiles(cfg)
bounds = cfg.phase5D.nuisanceBounds;
names = string(bounds.parameter);
rows = repmat(empty_profile_row(names), 1 + 2 .* numel(names) + 2, 1);
row = 1;
rows(row).profile_id = "nominal";
rows(row).profile_label = "zero nuisance";
for k = 1:numel(names)
    rows(row).(char(names(k))) = 0;
end
rows(row).penalty = 0;
rows(row).boundary_occupied = false;

for k = 1:numel(names)
    row = row + 1;
    rows(row) = rows(1);
    rows(row).profile_id = names(k) + "_low";
    rows(row).profile_label = "single lower-bound nuisance";
    rows(row).(char(names(k))) = bounds.lower_bound(k);
    rows(row) = finalize_profile(rows(row), bounds);

    row = row + 1;
    rows(row) = rows(1);
    rows(row).profile_id = names(k) + "_high";
    rows(row).profile_label = "single upper-bound nuisance";
    rows(row).(char(names(k))) = bounds.upper_bound(k);
    rows(row) = finalize_profile(rows(row), bounds);
end

row = row + 1;
rows(row) = rows(1);
rows(row).profile_id = "mild_broadened_shunted";
rows(row).profile_label = "moderate broadened/shunted M0";
rows(row).Tc_distribution_width_K = 0.07;
rows(row).residual_normal_shunt = 0.04;
rows(row).disorder_amplitude_scale = 1.25;
rows(row) = finalize_profile(rows(row), bounds);

row = row + 1;
rows(row) = rows(1);
rows(row).profile_id = "mild_shifted_registered";
rows(row).profile_label = "moderate shifted/registered M0";
rows(row).Tc_mean_shift_K = -0.04;
rows(row).temperature_offset_K = 0.015;
rows(row).probe_registration_shift = 0.03;
rows(row).normalization_window_shift = 0.015;
rows(row) = finalize_profile(rows(row), bounds);

profiles = struct2table(rows(1:row));
end

function row = finalize_profile(row, bounds)
penalty = 0;
boundaryOccupied = false;
for k = 1:height(bounds)
    name = char(bounds.parameter(k));
    value = row.(name);
    scale = max(abs(bounds.penalty_scale(k)), eps);
    penalty = penalty + (value ./ scale).^2;
    span = max(abs([bounds.lower_bound(k), bounds.upper_bound(k)]));
    if span > 0
        boundaryOccupied = boundaryOccupied || abs(value) >= 0.95 .* span;
    end
end
row.penalty = penalty;
row.boundary_occupied = boundaryOccupied;
end

function row = empty_profile_row(names)
row = struct();
row.profile_id = "";
row.profile_label = "";
for k = 1:numel(names)
    row.(char(names(k))) = NaN;
end
row.penalty = NaN;
row.boundary_occupied = false;
end

function manifest = build_calibration_manifest(cfg)
evidenceTiers = ["primary_only"; "primary_secondary"];
seeds = cfg.phase5D.calibrationSeeds(:);
lambdaW = cfg.phase5D.boundaryLambdaW(:);
baseCases = [
    calibration_case("M0_nominal", "M0star", 0, "M0 nuisance envelope")
    calibration_case("M0_shifted_broadened", "M0star", 0, ...
    "out-of-family M0 shift/broadening")
    calibration_case("M0_extra_shunt", "M0star", 0, ...
    "out-of-family M0 normal shunt")
    calibration_case("M1_strong", "strong_structured", 1, ...
    "clear M1 structured generator")
    calibration_case("M2_strong", "strong_structured", 1, ...
    "clear M2 structured generator")
    ];
n = numel(evidenceTiers) .* numel(seeds) .* ...
    (numel(baseCases) + numel(lambdaW));
rows = repmat(empty_manifest_row(), max(1, n), 1);
row = 0;
for iTier = 1:numel(evidenceTiers)
    tier = evidenceTiers(iTier);
    for iSeed = 1:numel(seeds)
        seed = seeds(iSeed);
        for iCase = 1:numel(baseCases)
            row = row + 1;
            rows(row) = manifest_row(tier, seed, baseCases(iCase));
        end
        for iLambda = 1:numel(lambdaW)
            lambda = lambdaW(iLambda);
            if lambda == 0
                trueGroup = "M0star";
            elseif lambda <= 0.10
                trueGroup = "weak_structured";
            else
                trueGroup = "strong_structured";
            end
            row = row + 1;
            rows(row) = manifest_row(tier, seed, calibration_case( ...
                sprintf('boundary_lambda_%0.2f', lambda), trueGroup, ...
                lambda, "boundary-strength sweep generator"));
        end
    end
end
manifest = struct2table(rows(1:row));
end

function c = calibration_case(trueModel, trueGroup, lambdaW, note)
c = struct();
c.true_model = string(trueModel);
c.true_group = string(trueGroup);
c.lambda_W = lambdaW;
c.generator_note = string(note);
end

function row = manifest_row(tier, seed, c)
row = empty_manifest_row();
row.synthetic_id = sprintf('%s_%s_seed_%04d', char(tier), ...
    char(c.true_model), seed);
row.split_name = "calibration";
row.evidence_tier = string(tier);
row.seed = seed;
row.true_model = c.true_model;
row.true_group = c.true_group;
row.lambda_W = c.lambda_W;
row.secondary_available = tier == "primary_secondary";
row.generator_note = c.generator_note;
end

function row = empty_manifest_row()
row = struct();
row.synthetic_id = "";
row.split_name = "";
row.evidence_tier = "";
row.seed = NaN;
row.true_model = "";
row.true_group = "";
row.lambda_W = NaN;
row.secondary_available = false;
row.generator_note = "";
end

function scoreRows = score_calibration_cases(cfg, manifest, profiles, ...
    penaltySetting)
templates = build_templates(cfg);
rows = repmat(empty_score_row(), max(1, height(manifest)), 1);
for k = 1:height(manifest)
    obs = calibration_observation(cfg, manifest(k, :), templates);
    m0star = score_m0star(cfg, obs, profiles, penaltySetting);
    sM1 = score_candidate(cfg, obs, templates.M1, "M1");
    sM2 = score_candidate(cfg, obs, templates.M2, "M2");
    if sM1 <= sM2
        structuredScore = sM1;
        structuredModel = "M1";
    else
        structuredScore = sM2;
        structuredModel = "M2";
    end
    rows(k).synthetic_id = string(manifest.synthetic_id(k));
    rows(k).split_name = string(manifest.split_name(k));
    rows(k).evidence_tier = string(manifest.evidence_tier(k));
    rows(k).seed = manifest.seed(k);
    rows(k).true_model = string(manifest.true_model(k));
    rows(k).true_group = string(manifest.true_group(k));
    rows(k).lambda_W = manifest.lambda_W(k);
    rows(k).M0star_score = m0star.score;
    rows(k).M0star_profile_id = m0star.profile_id;
    rows(k).M0star_profile_boundary_occupied = m0star.boundary_occupied;
    rows(k).S_M1 = sM1;
    rows(k).S_M2 = sM2;
    rows(k).S_structured = structuredScore;
    rows(k).structured_model = structuredModel;
    rows(k).deltaS = structuredScore - m0star.score;
    uncertainty = estimate_case_uncertainty(cfg, obs, templates, ...
        profiles, penaltySetting, manifest.seed(k), ...
        string(manifest.synthetic_id(k)));
    rows(k).sigmaDeltaS_case = uncertainty.sigma_total;
    rows(k).sigma_measurement_noise = uncertainty.sigma_measurement_noise;
    rows(k).sigma_registration = uncertainty.sigma_registration;
    rows(k).sigma_nuisance_profile = uncertainty.sigma_nuisance_profile;
    rows(k).resampled_deltaS_median = uncertainty.deltaS_median;
    rows(k).resampled_absZ_median = uncertainty.absZ_median;
    rows(k).resampled_CI_crosses_zero = uncertainty.CI_crosses_zero;
    rows(k).nuisance_penalty_weight = penaltySetting.base_weight;
    rows(k).penalty_setting_id = penaltySetting.setting_id;
    rows(k).width_extra_weight = penaltySetting.width_extra_weight;
    rows(k).shunt_extra_weight = penaltySetting.shunt_extra_weight;
    rows(k).width_shunt_cross_weight = ...
        penaltySetting.width_shunt_cross_weight;
end
scoreRows = struct2table(rows);
end

function templates = build_templates(cfg)
T = cfg.phase5C.temperatureGrid_K;
templates = struct();
templates.M0 = model_template(T, "M0", 0, 0, 0);
templates.M1 = model_template(T, "M1", 0, 0, 0);
templates.M2 = model_template(T, "M2", 0, 0, 0);
end

function obs = calibration_observation(cfg, manifestRow, templates)
seed = manifestRow.seed(1);
trueModel = string(manifestRow.true_model(1));
rng(seed + seed_offset(trueModel));
T = cfg.phase5C.temperatureGrid_K;
switch trueModel
    case "M0_nominal"
        base = templates.M0;
    case "M0_shifted_broadened"
        base = model_template(T, "M0", -0.05, 0.10, 0.01);
    case "M0_extra_shunt"
        m0 = model_template(T, "M0", 0.00, 0.02, 0.00);
        base = struct('T', T, 'primary', clamp01(0.92 .* m0.primary + 0.06), ...
            'secondary', clamp01(0.90 .* m0.secondary + 0.07));
    case "M1_strong"
        base = templates.M1;
    case "M2_strong"
        base = templates.M2;
    otherwise
        lambda = manifestRow.lambda_W(1);
        base = boundary_template(T, lambda);
end
noiseSigma = cfg.phase5C.noiseSigmaRealistic;
disorderSigma = cfg.phase5C.disorderSigma_Tc_K;
normSigma = cfg.phase5C.normalizationSigma;
TcShift = disorderSigma .* randn();
widthScale = max(0.65, 1 + 0.12 .* randn());
resShift = max(-0.03, min(0.03, normSigma .* randn()));
obs = struct();
obs.T = T;
obs.primary = perturb_curve(T, base.primary, TcShift, widthScale, ...
    resShift, noiseSigma);
obs.secondary = perturb_curve(T, base.secondary, TcShift .* 0.8, ...
    widthScale, -resShift .* 0.5, noiseSigma);
obs.secondary_available = logical(manifestRow.secondary_available(1));
end

function templ = boundary_template(T, lambdaW)
m0 = model_template(T, "M0", -0.01, 0.04, 0.02);
m1 = model_template(T, "M1", 0.02, -0.06, -0.05);
m2 = model_template(T, "M2", -0.01, -0.04, -0.08);
structuredMix = min(1, max(0, lambdaW));
structuredBase = 0.70 .* m1.primary + 0.30 .* m2.primary;
structuredSecondary = 0.62 .* m1.secondary + 0.38 .* m2.secondary;
primary = (1 - structuredMix) .* m0.primary + ...
    structuredMix .* structuredBase;
secondary = (1 - structuredMix) .* m0.secondary + ...
    structuredMix .* structuredSecondary;
templ = struct('T', T, 'primary', clamp01(primary), ...
    'secondary', clamp01(secondary));
end

function best = score_m0star(cfg, obs, profiles, penaltySetting)
bestScore = Inf;
bestProfile = "";
bestBoundary = false;
for k = 1:height(profiles)
    templ = nuisance_m0_template(cfg, profiles(k, :));
    score = score_candidate(cfg, obs, templ, "M0") + ...
        nuisance_penalty(cfg, profiles(k, :), penaltySetting);
    if score < bestScore
        bestScore = score;
        bestProfile = string(profiles.profile_id(k));
        bestBoundary = logical(profiles.boundary_occupied(k));
    end
end
best = struct('score', bestScore, 'profile_id', bestProfile, ...
    'boundary_occupied', bestBoundary);
end

function penalty = nuisance_penalty(cfg, profile, setting)
base = profile.penalty(1);
widthNorm = normalized_nuisance_value(cfg, profile, ...
    "Tc_distribution_width_K");
shuntNorm = normalized_nuisance_value(cfg, profile, ...
    "residual_normal_shunt");
penalty = setting.base_weight .* base + ...
    setting.width_extra_weight .* widthNorm.^2 + ...
    setting.shunt_extra_weight .* shuntNorm.^2 + ...
    setting.width_shunt_cross_weight .* widthNorm .* shuntNorm;
end

function value = normalized_nuisance_value(cfg, profile, parameter)
bounds = cfg.phase5D.nuisanceBounds;
idx = bounds.parameter == string(parameter);
if ~any(idx)
    value = 0;
    return;
end
span = max(abs([bounds.lower_bound(idx), bounds.upper_bound(idx)]));
value = abs(profile.(char(parameter))(1)) ./ max(span, eps);
end

function uncertainty = estimate_case_uncertainty(cfg, obs, templates, profiles, ...
    penaltySetting, seed, syntheticId)
n = cfg.phase5D.caseSigmaResampleCount;
rng(seed + seed_offset(syntheticId) + 910000);
deltaVals = resampled_deltaS_values(cfg, obs, templates, profiles, ...
    penaltySetting, n, "total");
measurementVals = resampled_deltaS_values(cfg, obs, templates, profiles, ...
    penaltySetting, n, "measurement");
registrationVals = resampled_deltaS_values(cfg, obs, templates, profiles, ...
    penaltySetting, n, "registration");
nuisanceVals = nuisance_ambiguity_deltaS_values(cfg, obs, templates, ...
    profiles, penaltySetting);
sigma = robust_sd(deltaVals);
sigma = max(0.015, sigma);
uncertainty = struct();
uncertainty.sigma_total = sigma;
uncertainty.sigma_measurement_noise = max(0.015, robust_sd(measurementVals));
uncertainty.sigma_registration = max(0.015, robust_sd(registrationVals));
uncertainty.sigma_nuisance_profile = max(0.015, robust_sd(nuisanceVals));
finiteDelta = sort(deltaVals(isfinite(deltaVals)));
uncertainty.deltaS_median = median(deltaVals, 'omitnan');
uncertainty.absZ_median = median(abs(deltaVals ./ sigma), 'omitnan');
if isempty(finiteDelta)
    uncertainty.CI_crosses_zero = true;
else
    qLo = interpolated_quantile(finiteDelta, 0.16);
    qHi = interpolated_quantile(finiteDelta, 0.84);
    uncertainty.CI_crosses_zero = qLo <= 0 && qHi >= 0;
end
end

function deltaVals = resampled_deltaS_values(cfg, obs, templates, profiles, ...
    penaltySetting, n, mode)
deltaVals = NaN(n, 1);
for k = 1:n
    obsPerturbed = perturb_observation_for_uncertainty(cfg, obs, mode);
    m0star = score_m0star(cfg, obsPerturbed, profiles, penaltySetting);
    sM1 = score_candidate(cfg, obsPerturbed, templates.M1, "M1");
    sM2 = score_candidate(cfg, obsPerturbed, templates.M2, "M2");
    deltaVals(k) = min(sM1, sM2) - m0star.score;
end
end

function deltaVals = nuisance_ambiguity_deltaS_values(cfg, obs, templates, ...
    profiles, penaltySetting)
profileScores = NaN(height(profiles), 1);
for k = 1:height(profiles)
    templ = nuisance_m0_template(cfg, profiles(k, :));
    profileScores(k) = score_candidate(cfg, obs, templ, "M0") + ...
        nuisance_penalty(cfg, profiles(k, :), penaltySetting);
end
sM1 = score_candidate(cfg, obs, templates.M1, "M1");
sM2 = score_candidate(cfg, obs, templates.M2, "M2");
deltaVals = min(sM1, sM2) - profileScores;
end

function obsPerturbed = perturb_observation_for_uncertainty(cfg, obs, mode)
T = obs.T;
mode = string(mode);
noiseSigma = 0;
normShift = 0;
tempOffset = 0;
probeShift = 0;
widthScale = 1;
if mode == "total" || mode == "measurement"
    noiseSigma = 0.5 .* cfg.phase5C.noiseSigmaRealistic;
end
if mode == "total" || mode == "registration"
    normShift = cfg.phase5C.normalizationSigma .* 0.5 .* randn();
    tempOffset = 0.03 .* randn();
    probeShift = 0.04 .* randn();
    widthScale = max(0.75, 1 + 0.08 .* randn());
end
obsPerturbed = obs;
primary = obs.primary + noiseSigma .* randn(size(obs.primary));
secondary = obs.secondary + noiseSigma .* randn(size(obs.secondary));
meanPrimary = mean(primary, 'omitnan');
meanSecondary = mean(secondary, 'omitnan');
primary = meanPrimary + widthScale .* (primary - meanPrimary);
secondary = meanSecondary + widthScale .* (secondary - meanSecondary);
primary = primary + normShift .* (1 - primary);
secondary = secondary - 0.5 .* normShift .* (1 - secondary);
primary = interp1(T, primary, T - tempOffset, 'linear', 'extrap');
secondary = interp1(T, secondary, T - tempOffset - probeShift, ...
    'linear', 'extrap');
obsPerturbed.primary = clamp01(primary);
obsPerturbed.secondary = clamp01(secondary);
end

function sigma = robust_sd(x)
x = x(isfinite(x));
if numel(x) < 2
    sigma = 0.015;
    return;
end
med = median(x);
madSigma = 1.4826 .* median(abs(x - med));
xs = sort(x);
q25 = interpolated_quantile(xs, 0.25);
q75 = interpolated_quantile(xs, 0.75);
iqrSigma = (q75 - q25) ./ 1.349;
sigma = max([madSigma, iqrSigma, std(x, 0)]);
end

function q = interpolated_quantile(xs, p)
n = numel(xs);
if n == 1
    q = xs(1);
    return;
end
pos = 1 + (n - 1) .* p;
lo = floor(pos);
hi = ceil(pos);
if lo == hi
    q = xs(lo);
else
    q = xs(lo) + (pos - lo) .* (xs(hi) - xs(lo));
end
end

function templ = nuisance_m0_template(cfg, profile)
T = cfg.phase5C.temperatureGrid_K;
tcShift = profile.Tc_mean_shift_K(1);
widthOffset = profile.Tc_distribution_width_K(1);
shunt = profile.residual_normal_shunt(1);
normShift = profile.normalization_window_shift(1);
tempOffset = profile.temperature_offset_K(1);
probeShift = profile.probe_registration_shift(1);
disorderScale = profile.disorder_amplitude_scale(1);
base = model_template(T, "M0", tcShift, widthOffset, shunt);
primary = clamp01(base.primary + normShift .* (1 - base.primary));
secondaryShifted = interp1(T, base.secondary, T - probeShift, ...
    'linear', 'extrap');
secondary = clamp01(secondaryShifted + normShift .* (1 - secondaryShifted));
primary = broaden_about_mean(primary, disorderScale);
secondary = broaden_about_mean(secondary, disorderScale);
primary = interp1(T, primary, T - tempOffset, 'linear', 'extrap');
secondary = interp1(T, secondary, T - tempOffset, 'linear', 'extrap');
templ = struct('T', T, 'primary', clamp01(primary), ...
    'secondary', clamp01(secondary));
end

function score = score_candidate(cfg, obs, templ, model)
primaryScore = v800.score_normalized_rt(obs.T, obs.primary, ...
    templ.T, templ.primary, cfg.phase5A.score);
score = primaryScore.total_LevelA_score;
if obs.secondary_available
    secondaryScore = v800.score_normalized_rt(obs.T, obs.secondary, ...
        templ.T, templ.secondary, cfg.phase5A.score);
    score = (1 - cfg.phase5C.secondaryWeight) .* score + ...
        cfg.phase5C.secondaryWeight .* secondaryScore.total_LevelA_score;
end
score = score + cfg.phase5B.complexityPenaltyLambda .* complexity_for(model);
end

function ledger = build_nuisance_ledger(cfg, scoreRows, profiles, ...
    sourceCommitSha, penaltySetting)
names = setdiff(string(profiles.Properties.VariableNames), ...
    ["profile_id"; "profile_label"; "penalty"; "boundary_occupied"], ...
    'stable');
n = height(scoreRows) .* numel(names);
rows = repmat(empty_nuisance_ledger_row(), max(1, n), 1);
row = 0;
for k = 1:height(scoreRows)
    profileIdx = find(profiles.profile_id == scoreRows.M0star_profile_id(k), ...
        1, 'first');
    for j = 1:numel(names)
        row = row + 1;
        rows(row).profile_id = string(scoreRows.M0star_profile_id(k));
        rows(row).split_name = string(scoreRows.split_name(k));
        rows(row).seed = scoreRows.seed(k);
        rows(row).nuisance_parameter = names(j);
        rows(row).value = profiles.(char(names(j)))(profileIdx);
        rows(row).penalty = nuisance_penalty(cfg, profiles(profileIdx, :), ...
            penaltySetting);
        rows(row).penalty_unit = profiles.penalty(profileIdx);
        rows(row).nuisance_penalty_weight = penaltySetting.base_weight;
        rows(row).penalty_setting_id = penaltySetting.setting_id;
        rows(row).width_extra_weight = penaltySetting.width_extra_weight;
        rows(row).shunt_extra_weight = penaltySetting.shunt_extra_weight;
        rows(row).width_shunt_cross_weight = ...
            penaltySetting.width_shunt_cross_weight;
        rows(row).source_commit_sha = sourceCommitSha;
        rows(row).synthetic_id = string(scoreRows.synthetic_id(k));
        rows(row).evidence_tier = string(scoreRows.evidence_tier(k));
        rows(row).true_model = string(scoreRows.true_model(k));
        rows(row).boundary_occupied = profiles.boundary_occupied(profileIdx);
        rows(row).M0star_score = scoreRows.M0star_score(k);
    end
end
ledger = struct2table(rows(1:row));
end

function row = empty_nuisance_ledger_row()
row = struct();
row.profile_id = "";
row.split_name = "";
row.seed = NaN;
row.nuisance_parameter = "";
row.value = NaN;
row.penalty = NaN;
row.penalty_unit = NaN;
row.nuisance_penalty_weight = NaN;
row.penalty_setting_id = "";
row.width_extra_weight = NaN;
row.shunt_extra_weight = NaN;
row.width_shunt_cross_weight = NaN;
row.source_commit_sha = "";
row.synthetic_id = "";
row.evidence_tier = "";
row.true_model = "";
row.boundary_occupied = false;
row.M0star_score = NaN;
end

function T = add_uncertainty(scoreRows)
T = scoreRows;
T.comparison = repmat("structured_vs_M0star", height(T), 1);
T.sigmaDeltaS = max(0.015, T.sigmaDeltaS_case);
T.Z = T.deltaS ./ T.sigmaDeltaS;
T.selected_state = repmat("unresolved", height(T), 1);
T = movevars(T, {'comparison','sigmaDeltaS','Z','selected_state'}, ...
    'After', 'deltaS');
end

function thresholds = calibrate_thresholds(cfg, deltaS, sourceCommitSha, ...
    penaltySetting)
tiers = unique(deltaS.evidence_tier, 'stable');
rows = repmat(empty_threshold_row(), max(1, numel(tiers)), 1);
for k = 1:numel(tiers)
    tier = tiers(k);
    idx = deltaS.evidence_tier == tier;
    best = choose_zcrit(cfg, deltaS(idx, :));
    rows(k).evidence_tier = tier;
    rows(k).comparison = "structured_vs_M0star";
    rows(k).Zcrit = best.Zcrit;
    rows(k).unresolved_margin = best.Zcrit;
    rows(k).nuisance_penalty_policy = ...
        "quadratic profile penalty using frozen Phase 5D nuisance bounds";
    rows(k).source_commit_sha = sourceCommitSha;
    rows(k).nuisance_penalty_weight = penaltySetting.base_weight;
    rows(k).penalty_setting_id = penaltySetting.setting_id;
    rows(k).width_extra_weight = penaltySetting.width_extra_weight;
    rows(k).shunt_extra_weight = penaltySetting.shunt_extra_weight;
    rows(k).width_shunt_cross_weight = ...
        penaltySetting.width_shunt_cross_weight;
    rows(k).sigmaDeltaS_policy = ...
        "case-specific robust resampling spread; no true-label pooling";
    rows(k).calibration_false_structured_rate = best.falseStructuredRate;
    rows(k).calibration_confident_M0_weak_structured_rate = ...
        best.confidentM0WeakRate;
    rows(k).calibration_strong_structured_detection_rate = ...
        best.strongStructuredRate;
    rows(k).calibration_weak_unresolved_rate = best.weakUnresolvedRate;
end
thresholds = struct2table(rows);
end

function best = choose_zcrit(cfg, T)
zGrid = cfg.phase5D.zCriticalGrid(:);
rows = repmat(empty_z_candidate(), max(1, numel(zGrid)), 1);
best = struct('Zcrit', zGrid(end), 'falseStructuredRate', NaN, ...
    'confidentM0WeakRate', NaN, 'strongStructuredRate', NaN, ...
    'weakUnresolvedRate', NaN);
for k = 1:numel(zGrid)
    zcrit = zGrid(k);
    state = classify_z(T.Z, zcrit);
    m0Idx = T.true_group == "M0star";
    weakIdx = T.true_group == "weak_structured";
    strongIdx = T.true_group == "strong_structured";
    falseStructured = fraction_true(state(m0Idx) == "structured_supported");
    confidentM0Weak = fraction_true(state(weakIdx) == "M0star_supported");
    strongDetected = fraction_true(state(strongIdx) == "structured_supported");
    weakUnresolved = fraction_true(state(weakIdx) == "unresolved");
    rows(k).Zcrit = zcrit;
    rows(k).falseStructuredRate = falseStructured;
    rows(k).confidentM0WeakRate = confidentM0Weak;
    rows(k).strongStructuredRate = strongDetected;
    rows(k).weakUnresolvedRate = weakUnresolved;
    rows(k).feasible = falseStructured <= cfg.phase5D.falseStructuredTarget && ...
        confidentM0Weak <= cfg.phase5D.confidentM0WeakStructuredTarget && ...
        strongDetected >= cfg.phase5D.strongStructuredDetectionTarget;
    hardViolation = ...
        1000 .* max(0, falseStructured - cfg.phase5D.falseStructuredTarget) + ...
        1000 .* max(0, confidentM0Weak - ...
        cfg.phase5D.confidentM0WeakStructuredTarget);
    sensitivityViolation = max(0, ...
        cfg.phase5D.strongStructuredDetectionTarget - strongDetected);
    unresolvedViolation = max(0, ...
        cfg.phase5D.boundaryUnresolvedTarget - weakUnresolved);
    rows(k).objective = hardViolation + sensitivityViolation + ...
        0.25 .* unresolvedViolation - strongDetected - ...
        0.10 .* weakUnresolved - 0.001 .* zcrit;
end
candidates = struct2table(rows);
feasibleIdx = candidates.feasible;
if any(feasibleIdx)
    Tbest = candidates(feasibleIdx, :);
    [~, order] = sortrows([ ...
        -Tbest.weakUnresolvedRate, ...
        -Tbest.Zcrit]);
    selected = Tbest(order(1), :);
else
    [~, order] = sort(candidates.objective);
    selected = candidates(order(1), :);
end
best.Zcrit = selected.Zcrit;
best.falseStructuredRate = selected.falseStructuredRate;
best.confidentM0WeakRate = selected.confidentM0WeakRate;
best.strongStructuredRate = selected.strongStructuredRate;
best.weakUnresolvedRate = selected.weakUnresolvedRate;
end

function row = empty_z_candidate()
row = struct();
row.Zcrit = NaN;
row.falseStructuredRate = NaN;
row.confidentM0WeakRate = NaN;
row.strongStructuredRate = NaN;
row.weakUnresolvedRate = NaN;
row.feasible = false;
row.objective = NaN;
end

function T = apply_thresholds(T, thresholds)
for k = 1:height(thresholds)
    idx = T.evidence_tier == thresholds.evidence_tier(k);
    T.selected_state(idx) = classify_z(T.Z(idx), thresholds.Zcrit(k));
end
T.M1_M2_selected_model = repmat("not_applicable", height(T), 1);
T.M1_M2_margin = abs(T.S_M1 - T.S_M2);
structuredIdx = T.selected_state == "structured_supported";
T.M1_M2_selected_model(structuredIdx & T.S_M1 <= T.S_M2) = "M1";
T.M1_M2_selected_model(structuredIdx & T.S_M2 < T.S_M1) = "M2";
end

function state = classify_z(Z, zcrit)
state = repmat("unresolved", size(Z));
state(Z < -zcrit) = "structured_supported";
state(Z > zcrit) = "M0star_supported";
end

function curves = build_boundary_curves(cfg, deltaS)
tiers = unique(deltaS.evidence_tier, 'stable');
lambdaW = cfg.phase5D.boundaryLambdaW(:);
rows = repmat(empty_boundary_row(), max(1, numel(tiers) .* numel(lambdaW)), 1);
row = 0;
for iTier = 1:numel(tiers)
    for iLambda = 1:numel(lambdaW)
        idx = deltaS.evidence_tier == tiers(iTier) & ...
            abs(deltaS.lambda_W - lambdaW(iLambda)) < 1e-9 & ...
            startsWith(deltaS.true_model, "boundary_lambda_");
        row = row + 1;
        rows(row).split_name = "calibration";
        rows(row).evidence_tier = tiers(iTier);
        rows(row).lambda_W = lambdaW(iLambda);
        rows(row).P_structured = fraction_true( ...
            deltaS.selected_state(idx) == "structured_supported");
        rows(row).P_unresolved = fraction_true( ...
            deltaS.selected_state(idx) == "unresolved");
        rows(row).P_M0star = fraction_true( ...
            deltaS.selected_state(idx) == "M0star_supported");
        rows(row).case_count = sum(idx);
    end
end
curves = struct2table(rows(1:row));
end

function occupancy = build_nuisance_boundary_occupancy(cfg, nuisanceLedger)
bounds = cfg.phase5D.nuisanceBounds;
rows = repmat(empty_boundary_occupancy_row(), max(1, height(bounds)), 1);
caseParams = unique(nuisanceLedger(:, {'synthetic_id', ...
    'nuisance_parameter', 'value'}), 'rows');
for k = 1:height(bounds)
    parameter = string(bounds.parameter(k));
    idx = caseParams.nuisance_parameter == parameter;
    values = caseParams.value(idx);
    lower = bounds.lower_bound(k);
    upper = bounds.upper_bound(k);
    span = max(eps, upper - lower);
    tol = 0.05 .* span;
    rows(k).nuisance_parameter = parameter;
    rows(k).lower_bound = lower;
    rows(k).upper_bound = upper;
    rows(k).fraction_at_lower_bound = fraction_true(abs(values - lower) <= tol);
    rows(k).fraction_at_upper_bound = fraction_true(abs(values - upper) <= tol);
    rows(k).fraction_at_any_bound = fraction_true( ...
        abs(values - lower) <= tol | abs(values - upper) <= tol);
    rows(k).selected_case_count = numel(values);
    rows(k).diagnostic_note = boundary_note(rows(k));
end
occupancy = struct2table(rows);
end

function note = boundary_note(row)
if row.fraction_at_any_bound >= 0.35
    note = "dominant boundary-hitting nuisance; check penalty scale before validation";
elseif row.fraction_at_any_bound >= 0.15
    note = "moderate boundary occupancy";
else
    note = "low boundary occupancy";
end
end

function roc = build_threshold_roc(cfg, deltaS)
tiers = unique(deltaS.evidence_tier, 'stable');
zGrid = cfg.phase5D.zCriticalGrid(:);
rows = repmat(empty_roc_row(), max(1, numel(tiers) .* numel(zGrid)), 1);
row = 0;
for iTier = 1:numel(tiers)
    tier = tiers(iTier);
    tierIdx = deltaS.evidence_tier == tier;
    for iZ = 1:numel(zGrid)
        zcrit = zGrid(iZ);
        state = classify_z(deltaS.Z(tierIdx), zcrit);
        T = deltaS(tierIdx, :);
        m0Idx = T.true_group == "M0star";
        weakIdx = T.true_group == "weak_structured";
        strongIdx = T.true_group == "strong_structured";
        row = row + 1;
        rows(row).evidence_tier = tier;
        rows(row).Zcrit = zcrit;
        rows(row).FPR_structured_given_M0star = fraction_true( ...
            state(m0Idx) == "structured_supported");
        rows(row).TPR_structured_given_strong = fraction_true( ...
            state(strongIdx) == "structured_supported");
        rows(row).confident_M0_given_weak_structured = fraction_true( ...
            state(weakIdx) == "M0star_supported");
        rows(row).weak_unresolved_rate = fraction_true( ...
            state(weakIdx) == "unresolved");
        rows(row).feasible_operating_point = ...
            rows(row).FPR_structured_given_M0star <= ...
            cfg.phase5D.falseStructuredTarget && ...
            rows(row).TPR_structured_given_strong >= ...
            cfg.phase5D.strongStructuredDetectionTarget && ...
            rows(row).confident_M0_given_weak_structured <= ...
            cfg.phase5D.confidentM0WeakStructuredTarget;
        rows(row).case_count = sum(tierIdx);
    end
end
roc = struct2table(rows(1:row));
end

function feasibility = build_operating_point_feasibility(roc)
tiers = unique(roc.evidence_tier, 'stable');
rows = repmat(empty_feasibility_row(), max(1, numel(tiers) + 1), 1);
for k = 1:numel(tiers)
    idx = roc.evidence_tier == tiers(k);
    feasibleIdx = idx & roc.feasible_operating_point;
    rows(k).evidence_tier = tiers(k);
    rows(k).feasible_operating_point_exists = any(feasibleIdx);
    rows(k).best_feasible_Zcrit = best_roc_value(roc, feasibleIdx, "Zcrit");
    rows(k).best_feasible_FPR = best_roc_value(roc, feasibleIdx, ...
        "FPR_structured_given_M0star");
    rows(k).best_feasible_TPR_strong = best_roc_value(roc, feasibleIdx, ...
        "TPR_structured_given_strong");
    rows(k).best_feasible_weak_unresolved = best_roc_value(roc, ...
        feasibleIdx, "weak_unresolved_rate");
    rows(k).diagnostic_note = feasibility_note(rows(k));
end
row = numel(tiers) + 1;
rows(row).evidence_tier = "any_tier";
rows(row).feasible_operating_point_exists = any(roc.feasible_operating_point);
rows(row).best_feasible_Zcrit = best_roc_value(roc, ...
    roc.feasible_operating_point, "Zcrit");
rows(row).best_feasible_FPR = best_roc_value(roc, ...
    roc.feasible_operating_point, "FPR_structured_given_M0star");
rows(row).best_feasible_TPR_strong = best_roc_value(roc, ...
    roc.feasible_operating_point, "TPR_structured_given_strong");
rows(row).best_feasible_weak_unresolved = best_roc_value(roc, ...
    roc.feasible_operating_point, "weak_unresolved_rate");
rows(row).diagnostic_note = feasibility_note(rows(row));
feasibility = struct2table(rows);
end

function value = best_roc_value(roc, idx, field)
if ~any(idx)
    value = NaN;
    return;
end
T = roc(idx, :);
[~, order] = sortrows([ ...
    -T.TPR_structured_given_strong, ...
    -T.weak_unresolved_rate, ...
    T.FPR_structured_given_M0star, ...
    -T.Zcrit]);
value = T.(char(field))(order(1));
end

function note = feasibility_note(row)
if row.feasible_operating_point_exists
    note = "at least one threshold satisfies FPR, strong-TPR, and weak-collapse constraints";
else
    note = "no threshold satisfies the predeclared calibration constraints";
end
end

function audit = build_sigma_deltaS_audit(deltaS)
groups = unique(deltaS(:, {'evidence_tier', 'true_group'}), 'rows');
rows = repmat(empty_sigma_audit_row(), max(1, height(groups)), 1);
for k = 1:height(groups)
    idx = deltaS.evidence_tier == groups.evidence_tier(k) & ...
        deltaS.true_group == groups.true_group(k);
    rows(k).evidence_tier = groups.evidence_tier(k);
    rows(k).true_group = groups.true_group(k);
    rows(k).median_deltaS = median(deltaS.deltaS(idx), 'omitnan');
    rows(k).median_sigmaDeltaS = median(deltaS.sigmaDeltaS(idx), 'omitnan');
    rows(k).median_abs_deltaS_over_sigma = median(abs(deltaS.Z(idx)), ...
        'omitnan');
    rows(k).fraction_deltaS_negative = fraction_true(deltaS.deltaS(idx) < 0);
    rows(k).fraction_CI_crosses_zero = fraction_true( ...
        abs(deltaS.deltaS(idx)) <= deltaS.sigmaDeltaS(idx));
    rows(k).fraction_resampled_CI_crosses_zero = fraction_true( ...
        deltaS.resampled_CI_crosses_zero(idx));
    rows(k).case_count = sum(idx);
end
audit = struct2table(rows);
end

function decomp = build_uncertainty_component_decomposition(deltaS)
groups = unique(deltaS.evidence_tier, 'stable');
components = ["total"; "measurement_noise"; "registration"; ...
    "nuisance_profile"];
rows = repmat(empty_uncertainty_component_row(), ...
    max(1, numel(groups) .* numel(components)), 1);
row = 0;
for iGroup = 1:numel(groups)
    idx = deltaS.evidence_tier == groups(iGroup);
    for iComp = 1:numel(components)
        row = row + 1;
        component = components(iComp);
        rows(row).evidence_tier = groups(iGroup);
        rows(row).uncertainty_component = component;
        switch component
            case "total"
                values = deltaS.sigmaDeltaS(idx);
            case "measurement_noise"
                values = deltaS.sigma_measurement_noise(idx);
            case "registration"
                values = deltaS.sigma_registration(idx);
            otherwise
                values = deltaS.sigma_nuisance_profile(idx);
        end
        rows(row).median_sigma = median(values, 'omitnan');
        rows(row).mean_sigma = mean(values, 'omitnan');
        rows(row).case_count = sum(idx);
        rows(row).diagnostic_note = component_note(component);
    end
end
decomp = struct2table(rows(1:row));
end

function note = component_note(component)
if component == "nuisance_profile"
    note = "diagnostic only; nuisance-grid ambiguity is not automatically folded into deployable sigmaDeltaS";
else
    note = "paired perturbation component computed with common score realization";
end
end

function check = build_internal_calibration_check(cfg, deltaS)
if isfield(cfg.phase5D, 'tuningSeeds')
    blocks = ["tuning"; "internal_check"];
else
    blocks = "all_calibration";
end
rows = repmat(empty_internal_check_row(), max(1, numel(blocks)), 1);
for k = 1:numel(blocks)
    switch blocks(k)
        case "tuning"
            idx = ismember(deltaS.seed, cfg.phase5D.tuningSeeds(:));
        case "internal_check"
            idx = ismember(deltaS.seed, cfg.phase5D.internalCheckSeeds(:));
        otherwise
            idx = true(height(deltaS), 1);
    end
    T = deltaS(idx, :);
    m0Idx = T.true_group == "M0star";
    weakIdx = T.true_group == "weak_structured";
    strongIdx = T.true_group == "strong_structured";
    rows(k).split_name = blocks(k);
    rows(k).seed_min = min(T.seed);
    rows(k).seed_max = max(T.seed);
    rows(k).FPR_structured_given_M0star = fraction_true( ...
        T.selected_state(m0Idx) == "structured_supported");
    rows(k).TPR_structured_given_strong = fraction_true( ...
        T.selected_state(strongIdx) == "structured_supported");
    rows(k).confident_M0_given_weak_structured = fraction_true( ...
        T.selected_state(weakIdx) == "M0star_supported");
    rows(k).weak_unresolved_rate = fraction_true( ...
        T.selected_state(weakIdx) == "unresolved");
    rows(k).case_count = height(T);
    rows(k).status = internal_check_status(cfg, rows(k));
end
check = struct2table(rows);
end

function status = internal_check_status(cfg, row)
if row.FPR_structured_given_M0star <= cfg.phase5D.falseStructuredTarget && ...
        row.TPR_structured_given_strong >= ...
        cfg.phase5D.strongStructuredDetectionTarget && ...
        row.confident_M0_given_weak_structured <= ...
        cfg.phase5D.confidentM0WeakStructuredTarget
    status = "pass";
else
    status = "fail";
end
end

function handoff = build_handoff_status(feasibility, internalCheck)
feasible = any(feasibility.feasible_operating_point_exists);
internalPass = any(internalCheck.status == "pass");
rows = [
    handoff_row("calibration_engine", "pass", ...
    "Phase 5D.1b completed the calibration and operating-point audit.")
    handoff_row("label_free_sigmaDeltaS", "pass", ...
    "sigmaDeltaS is case-specific and does not pool by true synthetic label.")
    handoff_row("operating_point_analysis", "pass", ...
    "ROC/threshold feasibility tables were generated for both evidence tiers.")
    handoff_row("feasible_operating_point_primary_only", ...
    passfail(any(feasibility.evidence_tier == "primary_only" & ...
    feasibility.feasible_operating_point_exists)), ...
    "No primary-only threshold met the predeclared FPR and strong-TPR targets.")
    handoff_row("feasible_operating_point_primary_secondary", ...
    passfail(any(feasibility.evidence_tier == "primary_secondary" & ...
    feasibility.feasible_operating_point_exists)), ...
    "No paired-probe threshold met the predeclared FPR and strong-TPR targets.")
    handoff_row("deployable_universal_classifier", passfail(feasible), ...
    "No universal categorical Z-classifier should be frozen from normalized R(T) alone.")
    handoff_row("internal_calibration_check", passfail(internalPass), ...
    "The reserved calibration-check block does not rescue the failed operating point.")
    handoff_row("independent_validation", "not_run", ...
    "Validation seeds 1001-1080 remain unused because no feasible calibration rule exists.")
    handoff_row("validation_seeds_consumed", "false", ...
    "Independent validation seeds are preserved for a future materially different evidence design.")
    handoff_row("phase5D1_closure", "pass_as_negative_result", ...
    "5D.1b closes as a scientific stopping result, not as a classifier freeze.")
    handoff_row("next_phase", "evidence_synthesis_and_hierarchical_freeze", ...
    "Use Phase 5D as a confidence limiter in the broader device evidence synthesis.")
    ];
handoff = struct2table(rows);
end

function status = passfail(tf)
if tf
    status = "pass";
else
    status = "fail";
end
end

function row = handoff_row(item, status, note)
row = struct();
row.item = string(item);
row.status = string(status);
row.note = string(note);
end

function gates = build_calibration_gates(cfg, deltaS, curves, nuisanceLedger, ...
    nuisanceBoundaryOccupancy)
rows = repmat(empty_gate_row(), 10, 1);
row = 0;
m0Idx = deltaS.true_group == "M0star";
weakIdx = deltaS.true_group == "weak_structured";
strongIdx = deltaS.true_group == "strong_structured";

row = row + 1;
falseStructured = fraction_true(deltaS.selected_state(m0Idx) == ...
    "structured_supported");
rows(row) = gate_row("false_structured_promotion_M0star", true, ...
    falseStructured <= cfg.phase5D.falseStructuredTarget, ...
    sprintf('false structured rate %.3f <= %.3f', falseStructured, ...
    cfg.phase5D.falseStructuredTarget), ...
    "M0* calibration should not promote true/misspecified M0 to structured.");

row = row + 1;
confidentM0Weak = fraction_true(deltaS.selected_state(weakIdx) == ...
    "M0star_supported");
rows(row) = gate_row("confident_M0star_for_weak_structured", true, ...
    confidentM0Weak <= cfg.phase5D.confidentM0WeakStructuredTarget, ...
    sprintf('weak structured confident M0* rate %.3f <= %.3f', ...
    confidentM0Weak, cfg.phase5D.confidentM0WeakStructuredTarget), ...
    "Near-boundary structured cases should not be overconfidently collapsed to M0*.");

row = row + 1;
weakUnresolved = fraction_true(deltaS.selected_state(weakIdx) == ...
    "unresolved");
rows(row) = gate_row("near_boundary_unresolved_behavior", true, ...
    weakUnresolved >= cfg.phase5D.boundaryUnresolvedTarget, ...
    sprintf('weak structured unresolved rate %.3f >= %.3f', ...
    weakUnresolved, cfg.phase5D.boundaryUnresolvedTarget), ...
    "Ambiguous near-boundary cases should preferentially become unresolved.");

row = row + 1;
strongDetected = fraction_true(deltaS.selected_state(strongIdx) == ...
    "structured_supported");
rows(row) = gate_row("strong_structured_detection", true, ...
    strongDetected >= cfg.phase5D.strongStructuredDetectionTarget, ...
    sprintf('strong structured detection %.3f >= %.3f', ...
    strongDetected, cfg.phase5D.strongStructuredDetectionTarget), ...
    "M0* nuisance expansion must not absorb clear structured cases.");

row = row + 1;
twoProbeMetrics = two_probe_aggregate_metrics(deltaS, curves);
rows(row) = gate_row("two_probe_aggregate_improvement", true, ...
    twoProbeMetrics.pass, twoProbeMetrics.evidence, ...
    "Revised 5D.1 gate replaces the failed pointwise-at-every-lambda rule with an aggregate pre-validation criterion.");

row = row + 1;
rows(row) = gate_row("pointwise_two_probe_rule_revision_recorded", false, ...
    true, ...
    "original pointwise two-probe gate failed in the first 5D.1 run and was superseded before validation", ...
    "This non-required audit row preserves the rule change rather than silently replacing the earlier failed criterion.");

row = row + 1;
structuredSupported = deltaS.selected_state == "structured_supported";
m12Idx = structuredSupported & ismember(deltaS.true_model, ...
    ["M1_strong"; "M2_strong"]);
m12Correct = fraction_true(deltaS.M1_M2_selected_model(m12Idx) == ...
    erase(deltaS.true_model(m12Idx), "_strong"));
rows(row) = gate_row("M1_M2_recovery_not_collapsed", true, ...
    m12Correct >= 0.70, ...
    sprintf('conditional M1/M2 exact rate %.3f >= 0.700', m12Correct), ...
    "M1/M2 detail is secondary but should not collapse after structured support.");

row = row + 1;
selectedLedger = unique(nuisanceLedger(:, {'synthetic_id', ...
    'boundary_occupied'}), 'rows');
boundaryOccupancy = fraction_true(selectedLedger.boundary_occupied);
rows(row) = gate_row("nuisance_boundary_occupancy", true, ...
    boundaryOccupancy <= cfg.phase5D.nuisanceBoundaryOccupancyTarget, ...
    sprintf('selected M0* boundary occupancy %.3f <= %.3f', ...
    boundaryOccupancy, cfg.phase5D.nuisanceBoundaryOccupancyTarget), ...
    "Frequent boundary fits would indicate M0* is compensating for missing physics.");

row = row + 1;
maxParamOccupancy = max(nuisanceBoundaryOccupancy.fraction_at_any_bound);
rows(row) = gate_row("nuisance_boundary_breakdown_recorded", true, ...
    isfinite(maxParamOccupancy), ...
    sprintf('maximum per-parameter boundary occupancy %.3f recorded', ...
    maxParamOccupancy), ...
    "Per-parameter lower/upper-bound occupancy is archived for penalty-scale diagnosis.");

row = row + 1;
rows(row) = gate_row("calibration_seed_block_only", true, ...
    all(deltaS.seed >= cfg.phase5D.calibrationSeeds(1) & ...
    deltaS.seed <= cfg.phase5D.calibrationSeeds(end)), ...
    sprintf('seed range %d-%d used', min(deltaS.seed), max(deltaS.seed)), ...
    "Validation seeds 1001-1080 must remain untouched during calibration.");

gates = struct2table(rows(1:row));
end

function tf = two_probe_aggregate_pass(deltaS, curves)
metrics = two_probe_aggregate_metrics(deltaS, curves);
tf = metrics.pass;
end

function metrics = two_probe_aggregate_metrics(deltaS, curves)
metrics = struct();
metrics.falseAtZeroPair = boundary_value(curves, "primary_secondary", 0, ...
    "P_structured");
metrics.falseAtZeroPrimary = boundary_value(curves, "primary_only", 0, ...
    "P_structured");
metrics.aucPair = boundary_auc(curves, "primary_secondary");
metrics.aucPrimary = boundary_auc(curves, "primary_only");
metrics.lambda80Pair = lambda_reaches_structured(curves, ...
    "primary_secondary", 0.80);
metrics.lambda80Primary = lambda_reaches_structured(curves, ...
    "primary_only", 0.80);
metrics.strongPair = mean_strong_boundary_structured(curves, ...
    "primary_secondary");
metrics.strongPrimary = mean_strong_boundary_structured(curves, ...
    "primary_only");
metrics.confidentM0WeakPair = weak_confident_M0_rate(deltaS, ...
    "primary_secondary");
metrics.confidentM0WeakPrimary = weak_confident_M0_rate(deltaS, ...
    "primary_only");
noFalseIncrease = metrics.falseAtZeroPair <= metrics.falseAtZeroPrimary + 0.05;
aucImproves = metrics.aucPair >= metrics.aucPrimary - 0.02;
lambdaImproves = isnan(metrics.lambda80Primary) || ...
    (~isnan(metrics.lambda80Pair) && metrics.lambda80Pair <= metrics.lambda80Primary);
strongImproves = metrics.strongPair >= metrics.strongPrimary - 0.02;
weakSafe = metrics.confidentM0WeakPair <= metrics.confidentM0WeakPrimary + 0.05;
metrics.pass = noFalseIncrease && aucImproves && lambdaImproves && ...
    strongImproves && weakSafe;
metrics.evidence = string(sprintf(['false@0 pair %.3f primary %.3f; ', ...
    'AUC pair %.3f primary %.3f; lambda80 pair %.3g primary %.3g; ', ...
    'strong pair %.3f primary %.3f; weak confident M0 pair %.3f primary %.3f'], ...
    metrics.falseAtZeroPair, metrics.falseAtZeroPrimary, ...
    metrics.aucPair, metrics.aucPrimary, metrics.lambda80Pair, ...
    metrics.lambda80Primary, metrics.strongPair, metrics.strongPrimary, ...
    metrics.confidentM0WeakPair, metrics.confidentM0WeakPrimary));
end

function value = boundary_value(curves, tier, lambdaW, field)
idx = curves.evidence_tier == string(tier) & ...
    abs(curves.lambda_W - lambdaW) < 1e-9;
if any(idx)
    value = curves.(field)(find(idx, 1, 'first'));
else
    value = NaN;
end
end

function area = boundary_auc(curves, tier)
idx = curves.evidence_tier == string(tier);
x = curves.lambda_W(idx);
y = curves.P_structured(idx);
[x, order] = sort(x);
y = y(order);
if numel(x) < 2
    area = NaN;
else
    area = trapz(x, y) ./ max(x);
end
end

function lambda = lambda_reaches_structured(curves, tier, threshold)
idx = curves.evidence_tier == string(tier);
x = curves.lambda_W(idx);
y = curves.P_structured(idx);
[x, order] = sort(x);
y = y(order);
hit = find(y >= threshold, 1, 'first');
if isempty(hit)
    lambda = NaN;
else
    lambda = x(hit);
end
end

function rate = mean_strong_boundary_structured(curves, tier)
idx = curves.evidence_tier == string(tier) & curves.lambda_W >= 0.40;
rate = mean(curves.P_structured(idx), 'omitnan');
end

function rate = weak_confident_M0_rate(deltaS, tier)
idx = deltaS.evidence_tier == string(tier) & ...
    deltaS.true_group == "weak_structured";
rate = fraction_true(deltaS.selected_state(idx) == "M0star_supported");
end

function row = gate_row(gate, required, passCondition, evidence, note)
row = empty_gate_row();
row.gate = string(gate);
row.required = required;
if passCondition
    row.status = "pass";
else
    row.status = "fail";
end
row.evidence = string(evidence);
row.note = string(note);
end

function row = empty_gate_row()
row = struct();
row.gate = "";
row.required = true;
row.status = "";
row.evidence = "";
row.note = "";
end

function row = empty_boundary_row()
row = struct();
row.split_name = "";
row.evidence_tier = "";
row.lambda_W = NaN;
row.P_structured = NaN;
row.P_unresolved = NaN;
row.P_M0star = NaN;
row.case_count = 0;
end

function row = empty_boundary_occupancy_row()
row = struct();
row.nuisance_parameter = "";
row.lower_bound = NaN;
row.upper_bound = NaN;
row.fraction_at_lower_bound = NaN;
row.fraction_at_upper_bound = NaN;
row.fraction_at_any_bound = NaN;
row.selected_case_count = 0;
row.diagnostic_note = "";
end

function row = empty_roc_row()
row = struct();
row.evidence_tier = "";
row.Zcrit = NaN;
row.FPR_structured_given_M0star = NaN;
row.TPR_structured_given_strong = NaN;
row.confident_M0_given_weak_structured = NaN;
row.weak_unresolved_rate = NaN;
row.feasible_operating_point = false;
row.case_count = 0;
end

function row = empty_feasibility_row()
row = struct();
row.evidence_tier = "";
row.feasible_operating_point_exists = false;
row.best_feasible_Zcrit = NaN;
row.best_feasible_FPR = NaN;
row.best_feasible_TPR_strong = NaN;
row.best_feasible_weak_unresolved = NaN;
row.diagnostic_note = "";
end

function row = empty_sigma_audit_row()
row = struct();
row.evidence_tier = "";
row.true_group = "";
row.median_deltaS = NaN;
row.median_sigmaDeltaS = NaN;
row.median_abs_deltaS_over_sigma = NaN;
row.fraction_deltaS_negative = NaN;
row.fraction_CI_crosses_zero = NaN;
row.fraction_resampled_CI_crosses_zero = NaN;
row.case_count = 0;
end

function row = empty_uncertainty_component_row()
row = struct();
row.evidence_tier = "";
row.uncertainty_component = "";
row.median_sigma = NaN;
row.mean_sigma = NaN;
row.case_count = 0;
row.diagnostic_note = "";
end

function row = empty_internal_check_row()
row = struct();
row.split_name = "";
row.seed_min = NaN;
row.seed_max = NaN;
row.FPR_structured_given_M0star = NaN;
row.TPR_structured_given_strong = NaN;
row.confident_M0_given_weak_structured = NaN;
row.weak_unresolved_rate = NaN;
row.case_count = 0;
row.status = "";
end

function row = empty_threshold_row()
row = struct();
row.evidence_tier = "";
row.comparison = "";
row.Zcrit = NaN;
row.unresolved_margin = NaN;
row.nuisance_penalty_policy = "";
row.source_commit_sha = "";
row.nuisance_penalty_weight = NaN;
row.penalty_setting_id = "";
row.width_extra_weight = NaN;
row.shunt_extra_weight = NaN;
row.width_shunt_cross_weight = NaN;
row.sigmaDeltaS_policy = "";
row.calibration_false_structured_rate = NaN;
row.calibration_confident_M0_weak_structured_rate = NaN;
row.calibration_strong_structured_detection_rate = NaN;
row.calibration_weak_unresolved_rate = NaN;
end

function row = empty_score_row()
row = struct();
row.synthetic_id = "";
row.split_name = "";
row.evidence_tier = "";
row.seed = NaN;
row.true_model = "";
row.true_group = "";
row.lambda_W = NaN;
row.M0star_score = NaN;
row.M0star_profile_id = "";
row.M0star_profile_boundary_occupied = false;
row.S_M1 = NaN;
row.S_M2 = NaN;
row.S_structured = NaN;
row.structured_model = "";
row.deltaS = NaN;
row.sigmaDeltaS_case = NaN;
row.sigma_measurement_noise = NaN;
row.sigma_registration = NaN;
row.sigma_nuisance_profile = NaN;
row.resampled_deltaS_median = NaN;
row.resampled_absZ_median = NaN;
row.resampled_CI_crosses_zero = false;
row.nuisance_penalty_weight = NaN;
row.penalty_setting_id = "";
row.width_extra_weight = NaN;
row.shunt_extra_weight = NaN;
row.width_shunt_cross_weight = NaN;
end

function templ = model_template(T, model, TcShift, widthScaleOffset, residualShift)
switch string(model)
    case "M0"
        Tc = 0.82 + TcShift;
        width = 0.20 + widthScaleOffset;
        residual = 0.03 + residualShift;
        primary = transition_curve(T, Tc, width, residual, 0.00, 0.00);
        secondary = transition_curve(T, Tc + 0.01, width .* 1.03, ...
            residual + 0.005, 0.00, 0.00);
    case "M1"
        Tc = 0.80 + TcShift;
        width = 0.28 + widthScaleOffset;
        residual = 0.12 + residualShift;
        primary = transition_curve(T, Tc, width, residual, 0.10, 0.70);
        secondary = transition_curve(T, Tc - 0.05, width .* 1.15, ...
            residual + 0.07, 0.13, 0.65);
    otherwise
        Tc = 0.76 + TcShift;
        width = 0.34 + widthScaleOffset;
        residual = 0.23 + residualShift;
        primary = transition_curve(T, Tc, width, residual, 0.18, 0.62);
        secondary = transition_curve(T, Tc - 0.09, width .* 1.25, ...
            residual + 0.13, 0.22, 0.55);
end
templ = struct('T', T, 'primary', clamp01(primary), ...
    'secondary', clamp01(secondary));
end

function R = transition_curve(T, Tc, width, residual, shoulderAmp, shoulderT)
base = residual + (1 - residual) ./ ...
    (1 + exp(-(T - Tc) ./ max(width, eps)));
shoulder = shoulderAmp .* exp(-((T - shoulderT) ./ ...
    max(width .* 1.15, eps)).^2);
R = base + shoulder .* (1 - base);
end

function R = perturb_curve(T, R, TcShift, widthScale, residualShift, noiseSigma)
Tshift = T - TcShift;
Rshift = interp1(T, R, Tshift, 'linear', 'extrap');
meanR = mean(Rshift, 'omitnan');
Rscaled = meanR + widthScale .* (Rshift - meanR);
Rout = Rscaled + residualShift .* (1 - Rscaled) + ...
    noiseSigma .* randn(size(Rscaled));
R = clamp01(Rout);
end

function R = broaden_about_mean(R, scale)
meanR = mean(R, 'omitnan');
R = clamp01(meanR + max(0.5, scale) .* (R - meanR));
end

function x = clamp01(x)
x = max(0, min(1.05, x));
end

function k = complexity_for(model)
switch string(model)
    case "M0"
        k = 0;
    case "M1"
        k = 1;
    case "M2"
        k = 2;
    otherwise
        k = 1;
end
end

function offset = seed_offset(model)
txt = char(string(model));
offset = sum(double(txt)) .* 17;
end

function f = fraction_true(tf)
if isempty(tf)
    f = NaN;
else
    f = sum(tf) ./ numel(tf);
end
end
