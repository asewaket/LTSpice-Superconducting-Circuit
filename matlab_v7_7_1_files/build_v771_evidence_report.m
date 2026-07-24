function [evidence, gates, candidateScores, sourceInfo] = build_v771_evidence_report(opts)
%BUILD_V771_EVIDENCE_REPORT Convert v7.7 ledgers into claim-readiness tables.

summaryPath = fullfile(opts.v77OutputDir, sprintf('%s_v7_7_mechanism_summary.csv', opts.device));
candidatePath = fullfile(opts.v77OutputDir, sprintf('%s_v7_7_candidate_scores.csv', opts.device));
sourcePath = fullfile(opts.v77OutputDir, sprintf('%s_v7_7_source_status.csv', opts.device));

if ~exist(summaryPath, 'file')
    error('v7.7 mechanism summary not found: %s', summaryPath);
end

summary = readtable(summaryPath, 'TextType', 'string');
candidateScores = read_optional_table(candidatePath);
sourceInfo = read_optional_table(sourcePath);

mechanism = as_string_col(summary, 'mechanism', strings(height(summary), 1));
bestCaseName = as_string_col(summary, 'bestCaseName', strings(height(summary), 1));
bestSourceVersion = as_string_col(summary, 'bestSourceVersion', strings(height(summary), 1));

candidateCount = as_numeric_col(summary, 'candidateCount', nan(height(summary), 1));
seedCount = as_numeric_col(summary, 'seedCount', nan(height(summary), 1));
multiObservableScore = as_numeric_col(summary, 'meanObjectiveScore', nan(height(summary), 1));
bestScreeningScore = as_numeric_col(summary, 'bestObjectiveScore', nan(height(summary), 1));
candidateSpread = as_numeric_col(summary, 'stdObjectiveScore', nan(height(summary), 1));
seedToSeedStd = as_numeric_col(summary, 'seedStdObjectiveScore', nan(height(summary), 1));
primaryRTScore = as_numeric_col(summary, 'meanPrimaryRTScore', nan(height(summary), 1));
heldoutDiagnosticScore = as_numeric_col(summary, 'meanHeldoutScore', nan(height(summary), 1));
probeAsymmetryScore = as_numeric_col(summary, 'meanProbeAsymmetryScore', nan(height(summary), 1));
parameterCount = as_numeric_col(summary, 'bestParameterCount', nan(height(summary), 1));

noWeakScore = baseline_value(mechanism, multiObservableScore, opts.baselineNoWeak);
centralLaneScore = baseline_value(mechanism, multiObservableScore, opts.baselineCentralLane);
noWeakAsymmetry = baseline_value(mechanism, probeAsymmetryScore, opts.baselineNoWeak);

deltaVsNoWeak = multiObservableScore - noWeakScore;
deltaVsCentralLane = multiObservableScore - centralLaneScore;

ablationZ_vsNoWeak = nan(size(deltaVsNoWeak));
ablationZ_vsCentralLane = nan(size(deltaVsCentralLane));
okSeedStd = isfinite(seedToSeedStd) & seedToSeedStd > 0;
ablationZ_vsNoWeak(okSeedStd) = deltaVsNoWeak(okSeedStd) ./ seedToSeedStd(okSeedStd);
ablationZ_vsCentralLane(okSeedStd) = deltaVsCentralLane(okSeedStd) ./ seedToSeedStd(okSeedStd);

heldoutDiagnosticAvailable = isfinite(heldoutDiagnosticScore) & ...
    abs(heldoutDiagnosticScore) < opts.largeDiagnosticCutoff;
bothProbeEvidenceAvailable = isfinite(probeAsymmetryScore);

survivesBothProbePairs = bothProbeEvidenceAvailable & ...
    probeAsymmetryScore <= noWeakAsymmetry + opts.probeAsymmetryTolerance;
beatsNoWeak = deltaVsNoWeak < -opts.scoreTolerance;
beatsCentralLane = deltaVsCentralLane < -opts.scoreTolerance;
passesSeedGate = seedCount >= opts.minSeedCountForClaim & okSeedStd;
passesZGate = isfinite(ablationZ_vsNoWeak) & ...
    ablationZ_vsNoWeak <= -opts.minAbsZForClaim;

claimReady = beatsNoWeak & beatsCentralLane & passesSeedGate & ...
    passesZGate & survivesBothProbePairs & heldoutDiagnosticAvailable;

evidence = table(mechanism, bestCaseName, bestSourceVersion, candidateCount, ...
    seedCount, multiObservableScore, bestScreeningScore, candidateSpread, ...
    seedToSeedStd, deltaVsNoWeak, deltaVsCentralLane, ablationZ_vsNoWeak, ...
    ablationZ_vsCentralLane, primaryRTScore, heldoutDiagnosticScore, ...
    probeAsymmetryScore, parameterCount, heldoutDiagnosticAvailable, ...
    bothProbeEvidenceAvailable, survivesBothProbePairs, beatsNoWeak, ...
    beatsCentralLane, passesSeedGate, passesZGate, claimReady);

evidence = sortrows(evidence, 'multiObservableScore', 'ascend');

gateNames = ["seed variability"; "ablation Z"; "both probes"; ...
    "held-out diagnostic"; "beats no weak"; "beats central lane"; "claim-ready"];
gateMatrix = [evidence.passesSeedGate, evidence.passesZGate, ...
    evidence.survivesBothProbePairs, evidence.heldoutDiagnosticAvailable, ...
    evidence.beatsNoWeak, evidence.beatsCentralLane, evidence.claimReady];

gateVarNames = matlab.lang.makeValidName(cellstr(gateNames));
gates = table(evidence.mechanism, gateMatrix(:, 1), gateMatrix(:, 2), ...
    gateMatrix(:, 3), gateMatrix(:, 4), gateMatrix(:, 5), ...
    gateMatrix(:, 6), gateMatrix(:, 7), ...
    'VariableNames', [{'mechanism'}, gateVarNames(:)']);

end

function T = read_optional_table(pathToFile)
if exist(pathToFile, 'file')
    T = readtable(pathToFile, 'TextType', 'string');
else
    T = table();
end
end

function values = as_string_col(T, name, defaultValue)
if any(strcmp(T.Properties.VariableNames, name))
    values = string(T.(name));
else
    values = defaultValue;
end
end

function values = as_numeric_col(T, name, defaultValue)
if any(strcmp(T.Properties.VariableNames, name))
    values = T.(name);
    if iscell(values) || isstring(values) || ischar(values)
        values = str2double(string(values));
    end
else
    values = defaultValue;
end
values = double(values);
end

function val = baseline_value(mechanism, score, baselineName)
idx = mechanism == baselineName;
if any(idx)
    val = score(find(idx, 1, 'first'));
else
    val = nan;
end
end
