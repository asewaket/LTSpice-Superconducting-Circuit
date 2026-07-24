function [mechanismSummary, gateSummary] = aggregate_v77_mechanism_scores(candidateScores, opts)
%AGGREGATE_V77_MECHANISM_SCORES Mean/std, ablation-Z, and gate summaries.

if isempty(candidateScores)
    mechanismSummary = table();
    gateSummary = table();
    return;
end

mechanisms = unique(candidateScores.mechanism, 'stable');
n = numel(mechanisms);

mechanism = strings(n, 1);
bestCaseName = strings(n, 1);
bestSourceVersion = strings(n, 1);
candidateCount = zeros(n, 1);
seedCount = zeros(n, 1);
meanObjectiveScore = NaN(n, 1);
stdObjectiveScore = NaN(n, 1);
seedStdObjectiveScore = NaN(n, 1);
bestObjectiveScore = NaN(n, 1);
meanPrimaryRTScore = NaN(n, 1);
meanHeldoutScore = NaN(n, 1);
meanProbeAsymmetryScore = NaN(n, 1);
bestParameterCount = NaN(n, 1);
ablationZ = NaN(n, 1);
screeningPass = false(n, 1);
physicalClaimPass = false(n, 1);

for k = 1:n
    mechanism(k) = mechanisms(k);
    idx = candidateScores.mechanism == mechanisms(k);
    C = candidateScores(idx, :);
    C = sortrows(C, 'objectiveScore', 'ascend');

    candidateCount(k) = height(C);
    finiteSeed = C.seed(isfinite(C.seed));
    if isempty(finiteSeed)
        seedCount(k) = 1;
    else
        seedCount(k) = numel(unique(finiteSeed));
    end

    meanObjectiveScore(k) = finite_mean(C.objectiveScore);
    stdObjectiveScore(k) = finite_std(C.objectiveScore);
    seedStdObjectiveScore(k) = seed_std_objective(C);
    bestObjectiveScore(k) = C.objectiveScore(1);
    bestCaseName(k) = C.caseName(1);
    bestSourceVersion(k) = C.sourceVersion(1);
    meanPrimaryRTScore(k) = finite_mean(C.primaryRTScore);
    meanHeldoutScore(k) = finite_mean(C.heldoutScore);
    meanProbeAsymmetryScore(k) = finite_mean(C.probeAsymmetryScore);
    bestParameterCount(k) = C.parameterCount(1);
end

mechanismSummary = table(mechanism, bestCaseName, bestSourceVersion, ...
    candidateCount, seedCount, meanObjectiveScore, stdObjectiveScore, ...
    seedStdObjectiveScore, bestObjectiveScore, meanPrimaryRTScore, ...
    meanHeldoutScore, meanProbeAsymmetryScore, bestParameterCount);
mechanismSummary = sortrows(mechanismSummary, 'meanObjectiveScore', 'ascend');

fullIdx = find(contains(lower(mechanismSummary.mechanism), "weak links") & ...
    ~contains(lower(mechanismSummary.mechanism), "uniform") & ...
    ~contains(lower(mechanismSummary.mechanism), "shuffled") & ...
    ~contains(lower(mechanismSummary.mechanism), "no weak"), 1, 'first');
if isempty(fullIdx)
    fullIdx = 1;
end

sigmaSeed = mechanismSummary.seedStdObjectiveScore(fullIdx);
if isfinite(sigmaSeed) && sigmaSeed > 0
    sigmaSeed = max(sigmaSeed, opts.gates.seedSigmaFloor);
else
    sigmaSeed = NaN;
end
for k = 1:height(mechanismSummary)
    ablationZ(k) = (mechanismSummary.meanObjectiveScore(k) - ...
        mechanismSummary.meanObjectiveScore(fullIdx)) / sigmaSeed;
end

rankLimit = max(1, ceil(opts.gates.maxRankFractionForScreening * height(mechanismSummary)));
screeningPass(1:rankLimit) = true;

multiSeedGate = mechanismSummary.seedCount >= opts.gates.minSeeds & ...
    isfinite(mechanismSummary.seedStdObjectiveScore);
heldoutGate = isfinite(mechanismSummary.meanHeldoutScore);
probeGate = isfinite(mechanismSummary.meanProbeAsymmetryScore);
ablationGate = isfinite(ablationZ) & abs(ablationZ) >= opts.gates.minAblationZ;
physicalClaimPass = screeningPass & multiSeedGate & heldoutGate & probeGate & ablationGate;

mechanismSummary.ablationZ = ablationZ;
mechanismSummary.screeningPass = screeningPass;
mechanismSummary.physicalClaimPass = physicalClaimPass;

gate = ["screening rank"; "multi-seed robustness"; "held-out diagnostic"; ...
    "probe-pair/asymmetry"; "ablation Z significance"; "physical claim"];
required = [false; true; true; true; true; true];
explanation = [ ...
    "Mechanism is in the best rank fraction of current real candidate ledgers."; ...
    "Requires at least three true disorder seeds; single-seed ledgers are not enough."; ...
    "Uses conductance-preserving/field/linecut diagnostic available from v7.4.x outputs."; ...
    "AS006 has two probe pairs, so asymmetry must be represented, not ignored."; ...
    "Requires |Z_ablation| >= threshold relative to seed variability."; ...
    "All required gates pass." ...
    ];
passCount = [sum(screeningPass); sum(multiSeedGate); sum(heldoutGate); ...
    sum(probeGate); sum(ablationGate); sum(physicalClaimPass)];
totalMechanisms = repmat(height(mechanismSummary), numel(gate), 1);

gateSummary = table(gate, required, explanation, passCount, totalMechanisms);

end

function y = finite_mean(x)
x = x(isfinite(x));
if isempty(x)
    y = NaN;
else
    y = mean(x);
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

function y = seed_std_objective(C)
%SEED_STD_OBJECTIVE Estimate seed-to-seed scatter for the best case per seed.
%
% The ordinary within-mechanism std mixes two effects: different ablation
% parameters and different disorder realizations.  The ablation-Z requested
% for v7.7 should instead be normalized by disorder-seed variability.  When
% seed ledgers are available, use the best objective score within each seed
% for this mechanism, then take the standard deviation across seeds.

y = NaN;
if ~any(strcmp(C.Properties.VariableNames, 'seed'))
    return;
end

finite = isfinite(C.seed) & isfinite(C.objectiveScore);
seeds = unique(C.seed(finite));
if numel(seeds) < 2
    return;
end

perSeedBest = NaN(numel(seeds), 1);
for k = 1:numel(seeds)
    idx = finite & C.seed == seeds(k);
    perSeedBest(k) = min(C.objectiveScore(idx));
end

perSeedBest = perSeedBest(isfinite(perSeedBest));
if numel(perSeedBest) >= 2
    y = std(perSeedBest);
end
end
