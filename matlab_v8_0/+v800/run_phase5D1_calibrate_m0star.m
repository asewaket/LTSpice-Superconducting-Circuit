function out = run_phase5D1_calibrate_m0star(cfg)
%RUN_PHASE5D1_CALIBRATE_M0STAR Calibrate M0* using calibration seeds only.

if ~exist(cfg.outputDir, 'dir')
    mkdir(cfg.outputDir);
end

sourceCommitSha = string(v800.git_commit_sha(cfg.repoRoot));
profiles = build_nuisance_profiles(cfg);
manifest = build_calibration_manifest(cfg);
scoreRows = score_calibration_cases(cfg, manifest, profiles);
nuisanceLedger = build_nuisance_ledger(scoreRows, profiles, ...
    sourceCommitSha);
deltaSDistribution = add_uncertainty(scoreRows);
thresholds = calibrate_thresholds(cfg, deltaSDistribution, ...
    sourceCommitSha);
deltaSDistribution = apply_thresholds(deltaSDistribution, thresholds);
boundaryCurves = build_boundary_curves(cfg, deltaSDistribution);
calibrationGates = build_calibration_gates(cfg, deltaSDistribution, ...
    boundaryCurves, nuisanceLedger);

writetable(nuisanceLedger, cfg.phase5D.nuisanceProfileLedgerFile);
writetable(deltaSDistribution, cfg.phase5D.deltaSDistributionFile);
writetable(thresholds, cfg.phase5D.calibratedThresholdsFile);
writetable(boundaryCurves, cfg.phase5D.boundaryDetectionCurvesFile);
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
out.nuisanceProfileLedger = nuisanceLedger;
out.deltaSDistribution = deltaSDistribution;
out.calibratedThresholds = thresholds;
out.boundaryDetectionCurves = boundaryCurves;
out.calibrationGates = calibrationGates;
out.figure = h;
out.paths = struct();
out.paths.nuisanceProfileLedger = cfg.phase5D.nuisanceProfileLedgerFile;
out.paths.deltaSDistribution = cfg.phase5D.deltaSDistributionFile;
out.paths.calibratedThresholds = cfg.phase5D.calibratedThresholdsFile;
out.paths.boundaryDetectionCurves = cfg.phase5D.boundaryDetectionCurvesFile;
out.paths.calibrationGates = cfg.phase5D.calibrationGateFile;
out.paths.figurePng = [cfg.phase5D.calibrationSummaryFigureBaseFile '.png'];
out.paths.figurePdf = [cfg.phase5D.calibrationSummaryFigureBaseFile '.pdf'];
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
    penalty = penalty + 0.004 .* (value ./ scale).^2;
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

function scoreRows = score_calibration_cases(cfg, manifest, profiles)
templates = build_templates(cfg);
rows = repmat(empty_score_row(), max(1, height(manifest)), 1);
for k = 1:height(manifest)
    obs = calibration_observation(cfg, manifest(k, :), templates);
    m0star = score_m0star(cfg, obs, profiles);
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

function best = score_m0star(cfg, obs, profiles)
bestScore = Inf;
bestProfile = "";
bestBoundary = false;
for k = 1:height(profiles)
    templ = nuisance_m0_template(cfg, profiles(k, :));
    score = score_candidate(cfg, obs, templ, "M0") + profiles.penalty(k);
    if score < bestScore
        bestScore = score;
        bestProfile = string(profiles.profile_id(k));
        bestBoundary = logical(profiles.boundary_occupied(k));
    end
end
best = struct('score', bestScore, 'profile_id', bestProfile, ...
    'boundary_occupied', bestBoundary);
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

function ledger = build_nuisance_ledger(scoreRows, profiles, sourceCommitSha)
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
        rows(row).penalty = profiles.penalty(profileIdx);
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
T.sigmaDeltaS = NaN(height(T), 1);
groups = unique(T(:, {'evidence_tier','true_group'}), 'rows');
for k = 1:height(groups)
    idx = T.evidence_tier == groups.evidence_tier(k) & ...
        T.true_group == groups.true_group(k);
    sigma = std(T.deltaS(idx), 0, 'omitnan');
    T.sigmaDeltaS(idx) = max(0.015, sigma);
end
T.Z = T.deltaS ./ T.sigmaDeltaS;
T.selected_state = repmat("unresolved", height(T), 1);
T = movevars(T, {'comparison','sigmaDeltaS','Z','selected_state'}, ...
    'After', 'deltaS');
end

function thresholds = calibrate_thresholds(cfg, deltaS, sourceCommitSha)
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
bestObjective = Inf;
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
    violation = max(0, falseStructured - cfg.phase5D.falseStructuredTarget) + ...
        max(0, confidentM0Weak - cfg.phase5D.confidentM0WeakStructuredTarget) + ...
        max(0, cfg.phase5D.strongStructuredDetectionTarget - strongDetected) + ...
        0.25 .* max(0, cfg.phase5D.boundaryUnresolvedTarget - weakUnresolved);
    objective = violation + 0.02 .* zcrit;
    if objective < bestObjective
        bestObjective = objective;
        best.Zcrit = zcrit;
        best.falseStructuredRate = falseStructured;
        best.confidentM0WeakRate = confidentM0Weak;
        best.strongStructuredRate = strongDetected;
        best.weakUnresolvedRate = weakUnresolved;
    end
end
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

function gates = build_calibration_gates(cfg, deltaS, curves, nuisanceLedger)
rows = repmat(empty_gate_row(), 8, 1);
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
paired = curves.evidence_tier == "primary_secondary";
primary = curves.evidence_tier == "primary_only";
lambdaVals = unique(curves.lambda_W, 'stable');
pairedBetterOrTie = true;
for k = 1:numel(lambdaVals)
    pPair = curves.P_structured(paired & curves.lambda_W == lambdaVals(k));
    pPrim = curves.P_structured(primary & curves.lambda_W == lambdaVals(k));
    if ~isempty(pPair) && ~isempty(pPrim)
        pairedBetterOrTie = pairedBetterOrTie && pPair >= pPrim - 0.05;
    end
end
rows(row) = gate_row("two_probe_improvement", true, pairedBetterOrTie, ...
    "paired-probe structured support ties or exceeds primary-only within tolerance", ...
    "Paired probes should not perform worse across the boundary sweep.");

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
rows(row) = gate_row("calibration_seed_block_only", true, ...
    all(deltaS.seed >= cfg.phase5D.calibrationSeeds(1) & ...
    deltaS.seed <= cfg.phase5D.calibrationSeeds(end)), ...
    sprintf('seed range %d-%d used', min(deltaS.seed), max(deltaS.seed)), ...
    "Validation seeds 1001-1080 must remain untouched during calibration.");

gates = struct2table(rows(1:row));
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

function row = empty_threshold_row()
row = struct();
row.evidence_tier = "";
row.comparison = "";
row.Zcrit = NaN;
row.unresolved_margin = NaN;
row.nuisance_penalty_policy = "";
row.source_commit_sha = "";
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
