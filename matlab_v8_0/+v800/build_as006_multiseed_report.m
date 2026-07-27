function [mechanismReport, gateReport, candidateScores] = build_as006_multiseed_report(cfg)
%BUILD_AS006_MULTISEED_REPORT Aggregate AS006 Phase 3 seed ledgers.
%
% The seed campaign generates ordinary v7.4.6 score tables.  This report is
% the v8 stop/go layer: it converts those tables into mechanism-level
% evidence across seeds, calibration conventions, ablations, probe-pair
% asymmetry, and parameter-basin occupancy.

if ~exist(cfg.outputDir, 'dir')
    mkdir(cfg.outputDir);
end

rawScores = read_seed_ledgers(cfg);
candidateScores = standardize_candidate_scores(rawScores);
candidateScores = sortrows(candidateScores, 'evidenceScore', 'ascend');
writetable(candidateScores, cfg.candidateScoreFile);

perBest = best_case_per_seed_mode_mechanism(candidateScores, cfg);
mechanismReport = aggregate_mechanisms(candidateScores, perBest, cfg);
gateReport = build_gate_report(mechanismReport);

writetable(mechanismReport, cfg.mechanismReportFile);
writetable(gateReport, cfg.gateReportFile);

fprintf('Wrote Phase 3 candidate scores: %s\n', cfg.candidateScoreFile);

end

function rawScores = read_seed_ledgers(cfg)
files = dir(fullfile(cfg.ledgerDir, 'AS006_v8_0_phase3_seed_*_scores.csv'));
if isempty(files)
    error('v8:phase3NoSeedLedgers', ...
        'No Phase 3 seed ledgers found in %s. Run the seed campaign first.', ...
        cfg.ledgerDir);
end

rawScores = table();
for k = 1:numel(files)
    pathToFile = fullfile(files(k).folder, files(k).name);
    try
        T = readtable(pathToFile, 'TextType', 'string');
    catch
        T = readtable(pathToFile);
    end
    if ~has_var(T, 'seed')
        T.seed = repmat(infer_seed_from_name(files(k).name), height(T), 1);
    end
    rawScores = append_tables(rawScores, T);
end
end

function candidateScores = standardize_candidate_scores(rawScores)
n = height(rawScores);

device = get_string_col(rawScores, 'device', "AS006");
sourceVersion = get_string_col(rawScores, 'sourceVersion', "");
sourceRole = get_string_col(rawScores, 'sourceRole', "");
sourceFile = get_string_col(rawScores, 'sourceFile', "");
caseName = get_string_col(rawScores, 'caseName', "");
topology = get_string_col(rawScores, 'topology', "");
linkClass = get_string_col(rawScores, 'linkClass', "");
calibrationMode = get_string_col(rawScores, 'calibrationMode', "shape");
seed = get_numeric_col(rawScores, 'seed', NaN);

alphaGap = get_numeric_col(rawScores, 'alphaGap', NaN);
gammaW = get_numeric_col(rawScores, 'gammaW', NaN);
pW = get_numeric_col(rawScores, 'pW', NaN);
meanW = get_numeric_col(rawScores, 'meanW', NaN);
minW = get_numeric_col(rawScores, 'minW', NaN);
activeWeakLinkFraction = get_numeric_col(rawScores, 'activeWeakLinkFraction', NaN);

shapeScore = get_numeric_col(rawScores, 'shapeScore', NaN);
shapeAsymmetry = get_numeric_col(rawScores, 'shapeAsymmetry', NaN);
conductanceScore = get_numeric_col(rawScores, 'conductanceScore', NaN);
conductanceAsymmetry = get_numeric_col(rawScores, 'conductanceAsymmetry', NaN);

evidenceScore = shapeScore;
scoreBasis = repmat("shapeScore", n, 1);
isConductance = lower(calibrationMode) == "conductance";
evidenceScore(isConductance) = conductanceScore(isConductance);
scoreBasis(isConductance) = "conductanceScore";

asymmetryScore = shapeAsymmetry;
asymmetryScore(isConductance) = conductanceAsymmetry(isConductance);
fallback = ~isfinite(asymmetryScore);
asymmetryScore(fallback) = shapeAsymmetry(fallback);

mechanism = classify_mechanism(topology, linkClass);
parameterSignature = make_parameter_signature(caseName, topology, linkClass, ...
    alphaGap, gammaW, pW);

candidateScores = table(device, sourceVersion, sourceRole, sourceFile, ...
    caseName, topology, linkClass, calibrationMode, seed, mechanism, ...
    parameterSignature, alphaGap, gammaW, pW, meanW, minW, ...
    activeWeakLinkFraction, shapeScore, conductanceScore, evidenceScore, ...
    scoreBasis, shapeAsymmetry, conductanceAsymmetry, asymmetryScore);
end

function perBest = best_case_per_seed_mode_mechanism(candidateScores, cfg)
seeds = unique(candidateScores.seed(isfinite(candidateScores.seed)));
modes = unique(candidateScores.calibrationMode, 'stable');
mechanisms = unique(candidateScores.mechanism, 'stable');

rows = repmat(empty_best_row(), max(1, numel(seeds) * numel(modes) * numel(mechanisms)), 1);
row = 0;

for iSeed = 1:numel(seeds)
    for iMode = 1:numel(modes)
        for iMech = 1:numel(mechanisms)
            idx = candidateScores.seed == seeds(iSeed) & ...
                candidateScores.calibrationMode == modes(iMode) & ...
                candidateScores.mechanism == mechanisms(iMech) & ...
                isfinite(candidateScores.evidenceScore);
            if ~any(idx)
                continue;
            end
            C = candidateScores(idx, :);
            [bestScore, localIdx] = min(C.evidenceScore);
            row = row + 1;
            rows(row).device = C.device(localIdx);
            rows(row).seed = seeds(iSeed);
            rows(row).calibrationMode = modes(iMode);
            rows(row).mechanism = mechanisms(iMech);
            rows(row).caseName = C.caseName(localIdx);
            rows(row).sourceVersion = C.sourceVersion(localIdx);
            rows(row).parameterSignature = C.parameterSignature(localIdx);
            rows(row).evidenceScore = bestScore;
            rows(row).asymmetryScore = C.asymmetryScore(localIdx);
        end
    end
end

if row == 0
    perBest = struct2table(rows([]));
    return;
end

perBest = struct2table(rows(1:row));
perBest.noWeakBaselineScore = NaN(height(perBest), 1);
perBest.centralLaneBaselineScore = NaN(height(perBest), 1);
perBest.noWeakBaselineAsymmetry = NaN(height(perBest), 1);
perBest.beatsNoWeak = false(height(perBest), 1);
perBest.beatsCentralLane = false(height(perBest), 1);
perBest.probeSurvives = false(height(perBest), 1);
perBest.rank = NaN(height(perBest), 1);

for iSeed = 1:numel(seeds)
    for iMode = 1:numel(modes)
        idx = perBest.seed == seeds(iSeed) & perBest.calibrationMode == modes(iMode);
        if ~any(idx)
            continue;
        end

        noIdx = idx & perBest.mechanism == string(cfg.baselines.noWeak);
        centralIdx = idx & perBest.mechanism == string(cfg.baselines.centralLane);
        if any(noIdx)
            noWeakScore = perBest.evidenceScore(find(noIdx, 1, 'first'));
            noWeakAsymmetry = perBest.asymmetryScore(find(noIdx, 1, 'first'));
        else
            noWeakScore = NaN;
            noWeakAsymmetry = NaN;
        end
        if any(centralIdx)
            centralScore = perBest.evidenceScore(find(centralIdx, 1, 'first'));
        else
            centralScore = NaN;
        end

        subset = find(idx);
        [~, order] = sort(perBest.evidenceScore(subset), 'ascend');
        ranks = NaN(numel(subset), 1);
        ranks(order) = (1:numel(subset)).';

        perBest.noWeakBaselineScore(subset) = noWeakScore;
        perBest.centralLaneBaselineScore(subset) = centralScore;
        perBest.noWeakBaselineAsymmetry(subset) = noWeakAsymmetry;
        perBest.beatsNoWeak(subset) = perBest.evidenceScore(subset) < noWeakScore;
        perBest.beatsCentralLane(subset) = perBest.evidenceScore(subset) < centralScore;
        perBest.probeSurvives(subset) = isfinite(perBest.asymmetryScore(subset)) & ...
            isfinite(noWeakAsymmetry) & ...
            perBest.asymmetryScore(subset) <= noWeakAsymmetry + cfg.gates.probeAsymmetryTolerance;
        perBest.rank(subset) = ranks;
    end
end
end

function mechanismReport = aggregate_mechanisms(candidateScores, perBest, cfg)
mechanisms = unique(candidateScores.mechanism, 'stable');
n = numel(mechanisms);

mechanism = strings(n, 1);
bestCaseName = strings(n, 1);
bestSourceVersion = strings(n, 1);
candidateCount = zeros(n, 1);
seedCount = zeros(n, 1);
seedModeCount = zeros(n, 1);
calibrationModesSeen = strings(n, 1);
meanEvidenceScore = NaN(n, 1);
medianEvidenceScore = NaN(n, 1);
stdEvidenceScore = NaN(n, 1);
iqrEvidenceScore = NaN(n, 1);
seedToSeedStd = NaN(n, 1);
sigmaSeedEff = NaN(n, 1);
rankDistribution = strings(n, 1);
meanRank = NaN(n, 1);
probabilityBeatsNoWeak = NaN(n, 1);
probabilityBeatsCentralLane = NaN(n, 1);
shapeProbabilityBeatsNoWeak = NaN(n, 1);
shapeProbabilityBeatsCentralLane = NaN(n, 1);
conductanceProbabilityBeatsNoWeak = NaN(n, 1);
conductanceProbabilityBeatsCentralLane = NaN(n, 1);
deltaVsNoWeakMean = NaN(n, 1);
deltaVsCentralLaneMean = NaN(n, 1);
ablationZ_vsNoWeak = NaN(n, 1);
ablationZ_vsCentralLane = NaN(n, 1);
bothProbeSurvivalRate = NaN(n, 1);
parameterBasinCount = zeros(n, 1);
seedCountGate = false(n, 1);
beatsNoWeakGate = false(n, 1);
beatsCentralLaneGate = false(n, 1);
ablationZGate = false(n, 1);
probeAsymmetryGate = false(n, 1);
bothCalibrationModeGate = false(n, 1);
parameterBasinGate = false(n, 1);
advanceGate = false(n, 1);

for k = 1:n
    mechanism(k) = mechanisms(k);
    C = candidateScores(candidateScores.mechanism == mechanisms(k), :);
    B = perBest(perBest.mechanism == mechanisms(k), :);
    candidateCount(k) = height(C);
    seedCount(k) = numel(unique(B.seed(isfinite(B.seed))));
    seedModeCount(k) = height(B);

    modes = unique(B.calibrationMode, 'stable');
    if ~isempty(modes)
        calibrationModesSeen(k) = string(strjoin(cellstr(modes), ';'));
    end

    if ~isempty(B)
        B = sortrows(B, 'evidenceScore', 'ascend');
        bestCaseName(k) = B.caseName(1);
        bestSourceVersion(k) = B.sourceVersion(1);
        scores = B.evidenceScore;
        meanEvidenceScore(k) = finite_mean(scores);
        medianEvidenceScore(k) = finite_median(scores);
        stdEvidenceScore(k) = finite_std(scores);
        iqrEvidenceScore(k) = finite_iqr(scores);
        seedToSeedStd(k) = per_seed_std(B);
        sigmaSeedEff(k) = finite_floor(seedToSeedStd(k), cfg.gates.seedSigmaFloor);
        rankDistribution(k) = format_rank_distribution(B.rank);
        meanRank(k) = finite_mean(B.rank);

        probabilityBeatsNoWeak(k) = finite_fraction(B.beatsNoWeak);
        probabilityBeatsCentralLane(k) = finite_fraction(B.beatsCentralLane);
        shapeProbabilityBeatsNoWeak(k) = mode_fraction(B, "shape", 'beatsNoWeak');
        shapeProbabilityBeatsCentralLane(k) = mode_fraction(B, "shape", 'beatsCentralLane');
        conductanceProbabilityBeatsNoWeak(k) = mode_fraction(B, "conductance", 'beatsNoWeak');
        conductanceProbabilityBeatsCentralLane(k) = mode_fraction(B, "conductance", 'beatsCentralLane');

        deltaVsNoWeakMean(k) = finite_mean(B.evidenceScore - B.noWeakBaselineScore);
        deltaVsCentralLaneMean(k) = finite_mean(B.evidenceScore - B.centralLaneBaselineScore);
        ablationZ_vsNoWeak(k) = deltaVsNoWeakMean(k) ./ sigmaSeedEff(k);
        ablationZ_vsCentralLane(k) = deltaVsCentralLaneMean(k) ./ sigmaSeedEff(k);
        bothProbeSurvivalRate(k) = finite_fraction(B.probeSurvives);
    end

    parameterBasinCount(k) = count_parameter_basin(C, cfg.gates.basinScoreTolerance);

    seedCountGate(k) = seedCount(k) >= cfg.gates.minSeedCount;
    beatsNoWeakGate(k) = probabilityBeatsNoWeak(k) >= cfg.gates.minPassProbability;
    beatsCentralLaneGate(k) = probabilityBeatsCentralLane(k) >= cfg.gates.minPassProbability;
    ablationZGate(k) = isfinite(ablationZ_vsNoWeak(k)) & ...
        abs(ablationZ_vsNoWeak(k)) >= cfg.gates.minAbsZ;
    probeAsymmetryGate(k) = bothProbeSurvivalRate(k) >= cfg.gates.minBothProbeSurvivalRate;
    bothCalibrationModeGate(k) = calibration_mode_gate(B, cfg);
    parameterBasinGate(k) = parameterBasinCount(k) >= cfg.gates.minBasinParameterPoints;

    advanceGate(k) = seedCountGate(k) & beatsNoWeakGate(k) & ...
        beatsCentralLaneGate(k) & ablationZGate(k) & probeAsymmetryGate(k) & ...
        bothCalibrationModeGate(k) & parameterBasinGate(k);
end

mechanismReport = table(mechanism, bestCaseName, bestSourceVersion, ...
    candidateCount, seedCount, seedModeCount, calibrationModesSeen, ...
    meanEvidenceScore, medianEvidenceScore, stdEvidenceScore, ...
    iqrEvidenceScore, seedToSeedStd, sigmaSeedEff, rankDistribution, ...
    meanRank, probabilityBeatsNoWeak, probabilityBeatsCentralLane, ...
    shapeProbabilityBeatsNoWeak, shapeProbabilityBeatsCentralLane, ...
    conductanceProbabilityBeatsNoWeak, conductanceProbabilityBeatsCentralLane, ...
    deltaVsNoWeakMean, deltaVsCentralLaneMean, ablationZ_vsNoWeak, ...
    ablationZ_vsCentralLane, bothProbeSurvivalRate, parameterBasinCount, ...
    seedCountGate, beatsNoWeakGate, beatsCentralLaneGate, ablationZGate, ...
    probeAsymmetryGate, bothCalibrationModeGate, parameterBasinGate, advanceGate);

mechanismReport = sortrows(mechanismReport, 'meanEvidenceScore', 'ascend');
end

function gateReport = build_gate_report(mechanismReport)
gateReport = table(mechanismReport.mechanism, ...
    mechanismReport.seedCountGate, mechanismReport.beatsNoWeakGate, ...
    mechanismReport.beatsCentralLaneGate, mechanismReport.ablationZGate, ...
    mechanismReport.probeAsymmetryGate, mechanismReport.bothCalibrationModeGate, ...
    mechanismReport.parameterBasinGate, mechanismReport.advanceGate, ...
    'VariableNames', {'mechanism','seedCountGate','beatsNoWeakGate', ...
    'beatsCentralLaneGate','ablationZGate','probeAsymmetryGate', ...
    'bothCalibrationModeGate','parameterBasinGate','advanceGate'});
end

function mechanism = classify_mechanism(topology, linkClass)
n = numel(topology);
mechanism = strings(n, 1);
for k = 1:n
    t = lower(string(topology(k)));
    c = lower(string(linkClass(k)));

    if contains(t, "central")
        mechanism(k) = "central-lane / 1D-like";
    elseif t == "none" || contains(t, "no_weak")
        mechanism(k) = "no weak links";
    elseif contains(t, "uniform")
        mechanism(k) = "uniform weak links";
    elseif contains(t, "shuffled")
        mechanism(k) = "shuffled weak links";
    elseif contains(t, "combined")
        mechanism(k) = "combined physical bottleneck";
    elseif contains(t, "anisotropic")
        mechanism(k) = "anisotropic control";
    elseif contains(t, "tear")
        mechanism(k) = "crack/tunnel-like weak links";
    elseif contains(t, "contact")
        mechanism(k) = "contact-relaxed weak links";
    elseif contains(t, "boundary")
        mechanism(k) = "boundary/SNS-inspired constriction";
    elseif contains(c, "boundary")
        mechanism(k) = "boundary/SNS-inspired constriction";
    elseif contains(c, "contact")
        mechanism(k) = "contact-relaxed weak links";
    elseif contains(c, "crack") || contains(c, "tunnel")
        mechanism(k) = "crack/tunnel-like weak links";
    elseif contains(c, "anisotropic")
        mechanism(k) = "anisotropic control";
    else
        mechanism(k) = "unclassified candidate";
    end
end
end

function ok = calibration_mode_gate(B, cfg)
if isempty(B)
    ok = false;
    return;
end
if ~cfg.gates.requireBothCalibrationModes
    ok = true;
    return;
end
hasShape = any(B.calibrationMode == "shape");
hasConductance = any(B.calibrationMode == "conductance");
shapeOK = mode_fraction(B, "shape", 'beatsNoWeak') >= cfg.gates.minPassProbability & ...
    mode_fraction(B, "shape", 'beatsCentralLane') >= cfg.gates.minPassProbability;
conductanceOK = mode_fraction(B, "conductance", 'beatsNoWeak') >= cfg.gates.minPassProbability & ...
    mode_fraction(B, "conductance", 'beatsCentralLane') >= cfg.gates.minPassProbability;
ok = hasShape & hasConductance & shapeOK & conductanceOK;
end

function n = count_parameter_basin(C, tolerance)
if isempty(C) || ~any(isfinite(C.evidenceScore))
    n = 0;
    return;
end
bestScore = min(C.evidenceScore);
idx = isfinite(C.evidenceScore) & C.evidenceScore <= bestScore + tolerance;
n = numel(unique(C.parameterSignature(idx)));
end

function signature = make_parameter_signature(caseName, topology, linkClass, alphaGap, gammaW, pW)
n = numel(caseName);
signature = strings(n, 1);
for k = 1:n
    signature(k) = sprintf('%s|%s|%s|alpha=%.6g|gamma=%.6g|p=%.6g', ...
        char(caseName(k)), char(topology(k)), char(linkClass(k)), ...
        alphaGap(k), gammaW(k), pW(k));
end
end

function row = empty_best_row()
row = struct();
row.device = "";
row.seed = NaN;
row.calibrationMode = "";
row.mechanism = "";
row.caseName = "";
row.sourceVersion = "";
row.parameterSignature = "";
row.evidenceScore = NaN;
row.asymmetryScore = NaN;
end

function y = per_seed_std(B)
seeds = unique(B.seed(isfinite(B.seed)));
if numel(seeds) < 2
    y = NaN;
    return;
end

perSeed = NaN(numel(seeds), 1);
for k = 1:numel(seeds)
    idx = B.seed == seeds(k);
    perSeed(k) = finite_mean(B.evidenceScore(idx));
end
y = finite_std(perSeed);
end

function out = mode_fraction(B, modeName, varName)
idx = B.calibrationMode == modeName;
if ~any(idx)
    out = NaN;
else
    out = finite_fraction(B.(varName)(idx));
end
end

function out = finite_fraction(x)
if isempty(x)
    out = NaN;
    return;
end
x = double(x);
x = x(isfinite(x));
if isempty(x)
    out = NaN;
else
    out = mean(x ~= 0);
end
end

function txt = format_rank_distribution(rankValues)
rankValues = rankValues(isfinite(rankValues));
if isempty(rankValues)
    txt = "";
    return;
end
ranks = unique(rankValues(:).');
parts = strings(numel(ranks), 1);
for k = 1:numel(ranks)
    parts(k) = sprintf('%d:%d', ranks(k), sum(rankValues == ranks(k)));
end
txt = string(strjoin(cellstr(parts), ';'));
end

function y = finite_mean(x)
x = x(isfinite(x));
if isempty(x)
    y = NaN;
else
    y = mean(x);
end
end

function y = finite_median(x)
x = sort(x(isfinite(x)));
if isempty(x)
    y = NaN;
else
    y = median(x);
end
end

function y = finite_std(x)
x = x(isfinite(x));
if numel(x) < 2
    y = NaN;
else
    y = std(x);
end
end

function y = finite_iqr(x)
x = sort(x(isfinite(x)));
if numel(x) < 2
    y = NaN;
else
    y = percentile_sorted(x, 75) - percentile_sorted(x, 25);
end
end

function y = percentile_sorted(x, p)
if isempty(x)
    y = NaN;
    return;
end
pos = 1 + (numel(x) - 1) * p / 100;
lo = floor(pos);
hi = ceil(pos);
if lo == hi
    y = x(lo);
else
    y = x(lo) + (x(hi) - x(lo)) * (pos - lo);
end
end

function y = finite_floor(x, floorValue)
if isfinite(x)
    y = max(abs(x), floorValue);
else
    y = NaN;
end
end

function col = get_string_col(T, name, defaultValue)
if has_var(T, name)
    col = string(T.(name));
else
    col = repmat(string(defaultValue), height(T), 1);
end
col = col(:);
col(ismissing(col)) = "";
end

function col = get_numeric_col(T, name, defaultValue)
if has_var(T, name)
    col = T.(name);
    if ~isnumeric(col)
        col = str2double(string(col));
    end
else
    col = repmat(defaultValue, height(T), 1);
end
col = double(col(:));
end

function tf = has_var(T, name)
tf = any(strcmp(T.Properties.VariableNames, name));
end

function T = append_tables(A, B)
if isempty(A)
    T = B;
else
    T = [A; B];
end
end

function seed = infer_seed_from_name(fileName)
tokens = regexp(char(fileName), 'seed[_-](\d+)', 'tokens', 'once');
if isempty(tokens)
    seed = NaN;
else
    seed = str2double(tokens{1});
end
end
