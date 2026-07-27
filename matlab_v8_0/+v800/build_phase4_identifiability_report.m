function out = build_phase4_identifiability_report(cfg)
%BUILD_PHASE4_IDENTIFIABILITY_REPORT Consume Phase 3 ledgers for pruning.

if ~exist(cfg.outputDir, 'dir')
    mkdir(cfg.outputDir);
end

rawScores = read_phase3_ledgers(cfg);
candidateScores = standardize_candidates(rawScores);
seedCount = numel(unique(candidateScores.seed(isfinite(candidateScores.seed))));
if seedCount < cfg.expectedFinalSeedCount && ~cfg.allowPartialLedgers
    error('v8:phase4IncompletePhase3', ...
        'Only %d/%d Phase 3 seeds are available.', ...
        seedCount, cfg.expectedFinalSeedCount);
end

evidenceMaturity = "provisional";
if seedCount >= cfg.expectedFinalSeedCount
    evidenceMaturity = "final_phase3";
end

seedModeWinners = build_seed_mode_winners(candidateScores, cfg);
mechanismSummary = build_mechanism_summary(seedModeWinners, candidateScores, cfg, ...
    evidenceMaturity);
parameterBasin = build_parameter_basin(candidateScores, cfg);
pruningDecisions = build_pruning_decisions(mechanismSummary, cfg, evidenceMaturity);

writetable(candidateScores, cfg.candidateScoreFile);
writetable(seedModeWinners, cfg.seedModeWinnerFile);
writetable(mechanismSummary, cfg.mechanismSummaryFile);
writetable(parameterBasin, cfg.parameterBasinFile);
writetable(pruningDecisions, cfg.pruningDecisionFile);

out = struct();
out.config = cfg;
out.seedCount = seedCount;
out.evidenceMaturity = evidenceMaturity;
out.candidateScores = candidateScores;
out.seedModeWinners = seedModeWinners;
out.mechanismSummary = mechanismSummary;
out.parameterBasin = parameterBasin;
out.pruningDecisions = pruningDecisions;
out.paths = struct();
out.paths.candidateScores = cfg.candidateScoreFile;
out.paths.seedModeWinners = cfg.seedModeWinnerFile;
out.paths.mechanismSummary = cfg.mechanismSummaryFile;
out.paths.parameterBasin = cfg.parameterBasinFile;
out.paths.pruningDecisions = cfg.pruningDecisionFile;

fprintf('Phase 4 read %d Phase 3 seed ledgers (%d/%d expected seeds).\n', ...
    numel(unique(candidateScores.sourceFile)), seedCount, cfg.expectedFinalSeedCount);

end

function rawScores = read_phase3_ledgers(cfg)
files = dir(fullfile(cfg.phase3LedgerDir, cfg.phase3LedgerPattern));
if isempty(files)
    error('v8:phase4NoSeedLedgers', ...
        'No Phase 3 seed ledgers found in %s.', cfg.phase3LedgerDir);
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
    if ~has_var(T, 'sourceFile')
        T.sourceFile = repmat(string(pathToFile), height(T), 1);
    end
    rawScores = append_tables(rawScores, T);
end
end

function candidateScores = standardize_candidates(rawScores)
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
activeWeakLinkFraction = get_numeric_col(rawScores, 'activeWeakLinkFraction', NaN);
shapeScore = get_numeric_col(rawScores, 'shapeScore', NaN);
conductanceScore = get_numeric_col(rawScores, 'conductanceScore', NaN);
shapeAsymmetry = get_numeric_col(rawScores, 'shapeAsymmetry', NaN);
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
    seed, calibrationMode, mechanism, topology, linkClass, caseName, ...
    parameterSignature, alphaGap, gammaW, pW, activeWeakLinkFraction, ...
    shapeScore, conductanceScore, evidenceScore, scoreBasis, ...
    shapeAsymmetry, conductanceAsymmetry, asymmetryScore);
candidateScores = sortrows(candidateScores, {'seed','calibrationMode','evidenceScore'});
end

function winners = build_seed_mode_winners(candidateScores, cfg)
seeds = unique(candidateScores.seed(isfinite(candidateScores.seed)));
modes = unique(candidateScores.calibrationMode, 'stable');
mechanisms = unique(candidateScores.mechanism, 'stable');
rows = repmat(empty_winner_row(), ...
    max(1, numel(seeds) .* numel(modes) .* numel(mechanisms)), 1);
row = 0;

for iSeed = 1:numel(seeds)
    for iMode = 1:numel(modes)
        subset = candidateScores.seed == seeds(iSeed) & ...
            candidateScores.calibrationMode == modes(iMode);
        for iMech = 1:numel(mechanisms)
            idx = subset & candidateScores.mechanism == mechanisms(iMech) & ...
                isfinite(candidateScores.evidenceScore);
            if ~any(idx)
                continue;
            end
            C = candidateScores(idx, :);
            [bestScore, bestIdx] = min(C.evidenceScore);
            row = row + 1;
            rows(row).seed = seeds(iSeed);
            rows(row).calibrationMode = modes(iMode);
            rows(row).mechanism = mechanisms(iMech);
            rows(row).topology = C.topology(bestIdx);
            rows(row).linkClass = C.linkClass(bestIdx);
            rows(row).caseName = C.caseName(bestIdx);
            rows(row).parameterSignature = C.parameterSignature(bestIdx);
            rows(row).evidenceScore = bestScore;
            rows(row).asymmetryScore = C.asymmetryScore(bestIdx);
        end
    end
end

winners = struct2table(rows(1:row));
winners.rank = NaN(height(winners), 1);
winners.noWeakBaselineScore = NaN(height(winners), 1);
winners.centralLaneBaselineScore = NaN(height(winners), 1);
winners.beatsNoWeak = false(height(winners), 1);
winners.beatsCentralLane = false(height(winners), 1);

for iSeed = 1:numel(seeds)
    for iMode = 1:numel(modes)
        idx = winners.seed == seeds(iSeed) & winners.calibrationMode == modes(iMode);
        if ~any(idx)
            continue;
        end
        subsetRows = find(idx);
        [~, order] = sort(winners.evidenceScore(subsetRows), 'ascend');
        ranks = NaN(numel(subsetRows), 1);
        ranks(order) = (1:numel(subsetRows)).';
        winners.rank(subsetRows) = ranks;

        noIdx = idx & winners.mechanism == string(cfg.baselines.noWeak);
        centralIdx = idx & winners.mechanism == string(cfg.baselines.centralLane);
        noWeakScore = NaN;
        centralScore = NaN;
        if any(noIdx)
            noWeakScore = winners.evidenceScore(find(noIdx, 1, 'first'));
        end
        if any(centralIdx)
            centralScore = winners.evidenceScore(find(centralIdx, 1, 'first'));
        end
        winners.noWeakBaselineScore(subsetRows) = noWeakScore;
        winners.centralLaneBaselineScore(subsetRows) = centralScore;
        winners.beatsNoWeak(subsetRows) = winners.evidenceScore(subsetRows) < noWeakScore;
        winners.beatsCentralLane(subsetRows) = winners.evidenceScore(subsetRows) < centralScore;
    end
end
end

function summary = build_mechanism_summary(winners, candidateScores, cfg, evidenceMaturity)
mechanisms = unique(winners.mechanism, 'stable');
modes = unique(winners.calibrationMode, 'stable');
n = numel(mechanisms) .* numel(modes);
rows = repmat(empty_summary_row(), max(1, n), 1);
row = 0;

for iMech = 1:numel(mechanisms)
    for iMode = 1:numel(modes)
        idx = winners.mechanism == mechanisms(iMech) & ...
            winners.calibrationMode == modes(iMode);
        if ~any(idx)
            continue;
        end
        W = winners(idx, :);
        C = candidateScores(candidateScores.mechanism == mechanisms(iMech) & ...
            candidateScores.calibrationMode == modes(iMode), :);
        row = row + 1;
        rows(row).evidenceMaturity = evidenceMaturity;
        rows(row).mechanism = mechanisms(iMech);
        rows(row).calibrationMode = modes(iMode);
        rows(row).diagnosticControl = is_diagnostic(mechanisms(iMech), cfg);
        rows(row).seedCount = numel(unique(W.seed(isfinite(W.seed))));
        rows(row).seedModeCount = height(W);
        rows(row).meanBestScore = finite_mean(W.evidenceScore);
        rows(row).medianBestScore = finite_median(W.evidenceScore);
        rows(row).stdBestScore = finite_std(W.evidenceScore);
        rows(row).meanRank = finite_mean(W.rank);
        rows(row).medianRank = finite_median(W.rank);
        rows(row).winRate = finite_fraction(W.rank <= cfg.criteria.topRank);
        rows(row).topTwoRate = finite_fraction(W.rank <= cfg.criteria.topTwoRank);
        rows(row).probabilityBeatsNoWeak = finite_fraction(W.beatsNoWeak);
        rows(row).probabilityBeatsCentralLane = finite_fraction(W.beatsCentralLane);
        rows(row).meanDeltaVsNoWeak = finite_mean(W.evidenceScore - W.noWeakBaselineScore);
        rows(row).meanDeltaVsCentralLane = finite_mean(W.evidenceScore - W.centralLaneBaselineScore);
        rows(row).parameterBasinCount = count_near_best_signatures(C, ...
            cfg.criteria.parameterBasinScoreTolerance);
        rows(row).bestCaseName = best_case_name(W);
        rows(row).rankDistribution = rank_distribution(W.rank);
        rows(row).protectedControl = is_protected(mechanisms(iMech), cfg);
        rows(row).recommendation = decide_mode_recommendation(rows(row), cfg, evidenceMaturity);
    end
end

summary = struct2table(rows(1:row));
summary = sortrows(summary, {'calibrationMode','meanRank','meanBestScore'});
end

function basin = build_parameter_basin(candidateScores, cfg)
mechanisms = unique(candidateScores.mechanism, 'stable');
modes = unique(candidateScores.calibrationMode, 'stable');
rows = repmat(empty_basin_row(), max(1, height(candidateScores)), 1);
row = 0;

for iMech = 1:numel(mechanisms)
    for iMode = 1:numel(modes)
        C = candidateScores(candidateScores.mechanism == mechanisms(iMech) & ...
            candidateScores.calibrationMode == modes(iMode) & ...
            isfinite(candidateScores.evidenceScore), :);
        if isempty(C)
            continue;
        end
        bestScore = min(C.evidenceScore);
        near = C.evidenceScore <= bestScore + cfg.criteria.parameterBasinScoreTolerance;
        C = C(near, :);
        signatures = unique(C.parameterSignature, 'stable');
        for iSig = 1:numel(signatures)
            S = C(C.parameterSignature == signatures(iSig), :);
            row = row + 1;
            rows(row).mechanism = mechanisms(iMech);
            rows(row).calibrationMode = modes(iMode);
            rows(row).parameterSignature = signatures(iSig);
            rows(row).nearBestSeedCount = numel(unique(S.seed(isfinite(S.seed))));
            rows(row).candidateCount = height(S);
            rows(row).minScore = min(S.evidenceScore);
            rows(row).meanScore = finite_mean(S.evidenceScore);
            rows(row).alphaGap = first_finite(S.alphaGap);
            rows(row).gammaW = first_finite(S.gammaW);
            rows(row).pW = first_finite(S.pW);
            rows(row).exampleCaseName = S.caseName(1);
        end
    end
end

basin = struct2table(rows(1:row));
if ~isempty(basin)
    basin = sortrows(basin, {'calibrationMode','mechanism','minScore'});
end
end

function decisions = build_pruning_decisions(summary, cfg, evidenceMaturity)
mechanisms = unique(summary.mechanism, 'stable');
rows = repmat(empty_decision_row(), max(1, numel(mechanisms)), 1);

for k = 1:numel(mechanisms)
    S = summary(summary.mechanism == mechanisms(k), :);
    rows(k).evidenceMaturity = evidenceMaturity;
    rows(k).mechanism = mechanisms(k);
    rows(k).protectedControl = is_protected(mechanisms(k), cfg);
    rows(k).diagnosticControl = is_diagnostic(mechanisms(k), cfg);
    rows(k).bestMode = best_mode(S);
    rows(k).seedCount = max(S.seedCount);
    rows(k).bestMeanRank = min(S.meanRank);
    rows(k).maxWinRate = max(S.winRate);
    rows(k).maxTopTwoRate = max(S.topTwoRate);
    rows(k).maxProbabilityBeatsNoWeak = max(S.probabilityBeatsNoWeak);
    rows(k).maxProbabilityBeatsCentralLane = max(S.probabilityBeatsCentralLane);
    rows(k).maxParameterBasinCount = max(S.parameterBasinCount);
    rows(k).decision = decide_pruning(rows(k), cfg, evidenceMaturity);
    rows(k).transferRole = transfer_role(rows(k).decision);
end

decisions = struct2table(rows);
decisions = sortrows(decisions, 'bestMeanRank', 'ascend');
decisions = sortrows(decisions, 'protectedControl', 'descend');
end

function decision = decide_mode_recommendation(row, cfg, evidenceMaturity)
if row.protectedControl
    decision = "required_control";
elseif isfield(row, 'diagnosticControl') && row.diagnosticControl
    decision = "diagnostic_control";
elseif evidenceMaturity ~= "final_phase3"
    if row.winRate > 0 || row.topTwoRate >= cfg.criteria.provisionalTopTwoRate
        decision = "provisional_keep_candidate";
    else
        decision = "provisional_hold";
    end
else
    strongRank = row.winRate >= cfg.criteria.finalWinRate || ...
        row.topTwoRate >= cfg.criteria.finalTopTwoRate;
    beatsBaselines = row.probabilityBeatsNoWeak >= cfg.criteria.baselineBeatProbability && ...
        row.probabilityBeatsCentralLane >= cfg.criteria.baselineBeatProbability;
    hasBasin = row.parameterBasinCount >= cfg.criteria.minNearBestParameterSignatures;
    if strongRank && beatsBaselines && hasBasin
        decision = "retain_for_pruning";
    elseif row.topTwoRate == 0 && beatsBaselines
        decision = "not_transfer_primary";
    elseif ~strongRank && ~beatsBaselines
        decision = "prune_after_phase3";
    else
        decision = "hold_for_robustness";
    end
end
end

function decision = decide_pruning(row, cfg, evidenceMaturity)
if row.protectedControl
    decision = "required_control";
elseif row.diagnosticControl
    decision = "diagnostic_control";
elseif evidenceMaturity ~= "final_phase3"
    if row.maxWinRate > 0 || row.maxTopTwoRate >= cfg.criteria.provisionalTopTwoRate
        decision = "provisional_keep_candidate";
    else
        decision = "provisional_hold";
    end
else
    strongRank = row.maxWinRate >= cfg.criteria.finalWinRate || ...
        row.maxTopTwoRate >= cfg.criteria.finalTopTwoRate;
    beatsBaselines = row.maxProbabilityBeatsNoWeak >= cfg.criteria.baselineBeatProbability && ...
        row.maxProbabilityBeatsCentralLane >= cfg.criteria.baselineBeatProbability;
    hasBasin = row.maxParameterBasinCount >= cfg.criteria.minNearBestParameterSignatures;
    if row.maxTopTwoRate == 0 && beatsBaselines
        decision = "not_transfer_primary";
    elseif strongRank && beatsBaselines && hasBasin
        decision = "retain_for_transfer";
    elseif ~strongRank && ~beatsBaselines && ~hasBasin
        decision = "prune_after_phase3";
    else
        decision = "hold_for_robustness";
    end
end

end

function role = transfer_role(decision)
switch char(decision)
    case 'retain_for_transfer'
        role = "transfer_primary";
    case 'required_control'
        role = "required_control";
    case 'diagnostic_control'
        role = "diagnostic_control";
    case 'not_transfer_primary'
        role = "diagnostic_hold";
    case 'hold_for_robustness'
        role = "robustness_hold";
    otherwise
        role = "not_selected";
end
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
    elseif contains(t, "boundary") || contains(c, "boundary")
        mechanism(k) = "boundary/SNS-inspired constriction";
    elseif contains(t, "contact") || contains(c, "contact")
        mechanism(k) = "contact-relaxed weak links";
    elseif contains(t, "tear") || contains(c, "crack") || contains(c, "tunnel")
        mechanism(k) = "crack/tunnel-like weak links";
    elseif contains(c, "anisotropic")
        mechanism(k) = "anisotropic control";
    else
        mechanism(k) = "unclassified candidate";
    end
end
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

function n = count_near_best_signatures(C, tolerance)
if isempty(C) || ~any(isfinite(C.evidenceScore))
    n = 0;
    return;
end
bestScore = min(C.evidenceScore);
idx = isfinite(C.evidenceScore) & C.evidenceScore <= bestScore + tolerance;
n = numel(unique(C.parameterSignature(idx)));
end

function tf = is_protected(mechanism, cfg)
tf = any(string(mechanism) == cfg.protectedMechanisms);
end

function tf = is_diagnostic(mechanism, cfg)
if isfield(cfg, 'diagnosticMechanisms')
    tf = any(string(mechanism) == cfg.diagnosticMechanisms);
else
    tf = false;
end
end

function name = best_case_name(W)
[~, idx] = min(W.evidenceScore);
name = W.caseName(idx);
end

function modeName = best_mode(S)
[~, idx] = min(S.meanRank);
modeName = S.calibrationMode(idx);
end

function txt = rank_distribution(rankValues)
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

function row = empty_winner_row()
row = struct();
row.seed = NaN;
row.calibrationMode = "";
row.mechanism = "";
row.topology = "";
row.linkClass = "";
row.caseName = "";
row.parameterSignature = "";
row.evidenceScore = NaN;
row.asymmetryScore = NaN;
end

function row = empty_summary_row()
row = struct();
row.evidenceMaturity = "";
row.mechanism = "";
row.calibrationMode = "";
row.diagnosticControl = false;
row.seedCount = 0;
row.seedModeCount = 0;
row.meanBestScore = NaN;
row.medianBestScore = NaN;
row.stdBestScore = NaN;
row.meanRank = NaN;
row.medianRank = NaN;
row.winRate = NaN;
row.topTwoRate = NaN;
row.probabilityBeatsNoWeak = NaN;
row.probabilityBeatsCentralLane = NaN;
row.meanDeltaVsNoWeak = NaN;
row.meanDeltaVsCentralLane = NaN;
row.parameterBasinCount = 0;
row.bestCaseName = "";
row.rankDistribution = "";
row.protectedControl = false;
row.recommendation = "";
end

function row = empty_basin_row()
row = struct();
row.mechanism = "";
row.calibrationMode = "";
row.parameterSignature = "";
row.nearBestSeedCount = 0;
row.candidateCount = 0;
row.minScore = NaN;
row.meanScore = NaN;
row.alphaGap = NaN;
row.gammaW = NaN;
row.pW = NaN;
row.exampleCaseName = "";
end

function row = empty_decision_row()
row = struct();
row.evidenceMaturity = "";
row.mechanism = "";
row.protectedControl = false;
row.diagnosticControl = false;
row.bestMode = "";
row.seedCount = 0;
row.bestMeanRank = NaN;
row.maxWinRate = NaN;
row.maxTopTwoRate = NaN;
row.maxProbabilityBeatsNoWeak = NaN;
row.maxProbabilityBeatsCentralLane = NaN;
row.maxParameterBasinCount = 0;
row.decision = "";
row.transferRole = "";
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
x = x(isfinite(x));
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

function value = first_finite(x)
idx = find(isfinite(x), 1, 'first');
if isempty(idx)
    value = NaN;
else
    value = x(idx);
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
