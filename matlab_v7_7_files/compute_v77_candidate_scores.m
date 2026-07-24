function candidateScores = compute_v77_candidate_scores(rawScores, opts)
%COMPUTE_V77_CANDIDATE_SCORES Convert v7.4.x ledgers into v7.6-style scores.

if isempty(rawScores)
    candidateScores = empty_candidate_table();
    return;
end

n = height(rawScores);
device = get_string_col(rawScores, 'device', opts.device);
sourceVersion = get_string_col(rawScores, 'sourceVersion', "");
sourceRole = get_string_col(rawScores, 'sourceRole', "");
caseName = get_string_col(rawScores, 'caseName', "");
topology = get_string_col(rawScores, 'topology', "");
calibrationMode = get_string_col(rawScores, 'calibrationMode', "");
linkClass = get_string_col(rawScores, 'linkClass', "");
seed = get_numeric_col(rawScores, 'seed', NaN);

primaryRTScore = first_numeric_col(rawScores, {'shapeScore', ...
    'shapeControlledScore', 'rtScore'}, NaN);
transitionScore = mean_ignoring_nan([ ...
    first_numeric_col(rawScores, {'shapeLowBias'}, NaN), ...
    first_numeric_col(rawScores, {'shapeZeroBias'}, NaN) ...
    ], 2);
probeAsymmetryScore = first_numeric_col(rawScores, ...
    {'shapeAsymmetry', 'asymmetryScore', 'probeAsymmetryScore'}, NaN);
heldoutScore = first_numeric_col(rawScores, ...
    {'conductanceScore', 'fieldScore', 'heldoutScore'}, NaN);

parameterCount = estimate_parameter_count(sourceVersion, topology, linkClass);
complexityPenalty = opts.weights.complexityPenalty .* parameterCount;

objectiveScore = ...
    opts.weights.primaryRT .* primaryRTScore + ...
    opts.weights.transitionMetrics .* replace_nan(transitionScore, primaryRTScore) + ...
    opts.weights.probeAsymmetry .* replace_nan(probeAsymmetryScore, 0) + ...
    opts.weights.heldoutDiagnostic .* heldout_term(heldoutScore) + ...
    complexityPenalty;

hasBothProbePairs = strcmp(device, "AS006") & isfinite(probeAsymmetryScore);
hasHeldoutDiagnostic = isfinite(heldoutScore);
candidateMechanism = classify_v77_mechanism(sourceVersion, sourceRole, topology, linkClass);

candidateScores = table(device, sourceVersion, sourceRole, caseName, ...
    topology, linkClass, calibrationMode, seed, candidateMechanism, ...
    primaryRTScore, transitionScore, probeAsymmetryScore, heldoutScore, ...
    parameterCount, complexityPenalty, objectiveScore, ...
    hasBothProbePairs, hasHeldoutDiagnostic);

candidateScores.Properties.VariableNames{'candidateMechanism'} = 'mechanism';

candidateScores = sortrows(candidateScores, 'objectiveScore', 'ascend');

end

function T = empty_candidate_table()
T = table(strings(0,1), strings(0,1), strings(0,1), strings(0,1), ...
    strings(0,1), strings(0,1), strings(0,1), NaN(0,1), strings(0,1), ...
    NaN(0,1), NaN(0,1), NaN(0,1), NaN(0,1), NaN(0,1), NaN(0,1), ...
    NaN(0,1), false(0,1), false(0,1), ...
    'VariableNames', {'device','sourceVersion','sourceRole','caseName', ...
    'topology','linkClass','calibrationMode','seed','mechanism', ...
    'primaryRTScore','transitionScore','probeAsymmetryScore','heldoutScore', ...
    'parameterCount','complexityPenalty','objectiveScore', ...
    'hasBothProbePairs','hasHeldoutDiagnostic'});
end

function col = get_string_col(T, name, defaultValue)
if any(strcmp(T.Properties.VariableNames, name))
    col = string(T.(name));
else
    col = repmat(string(defaultValue), height(T), 1);
end
col = col(:);
bad = ismissing(col);
col(bad) = "";
end

function col = get_numeric_col(T, name, defaultValue)
if any(strcmp(T.Properties.VariableNames, name)) && isnumeric(T.(name))
    col = T.(name);
else
    col = repmat(defaultValue, height(T), 1);
end
col = col(:);
end

function col = first_numeric_col(T, names, defaultValue)
col = repmat(defaultValue, height(T), 1);
for k = 1:numel(names)
    name = names{k};
    if any(strcmp(T.Properties.VariableNames, name)) && isnumeric(T.(name))
        x = T.(name);
        use = isfinite(x) & ~isfinite(col);
        col(use) = x(use);
    end
end
col = col(:);
end

function y = mean_ignoring_nan(X, dim)
valid = isfinite(X);
den = sum(valid, dim);
X(~valid) = 0;
y = sum(X, dim) ./ max(den, 1);
y(den == 0) = NaN;
end

function y = replace_nan(x, fallback)
y = x;
bad = ~isfinite(y);
if isscalar(fallback)
    y(bad) = fallback;
else
    y(bad) = fallback(bad);
end
end

function y = heldout_term(x)
% Existing conductance-preserving scores can explode when normal-state
% conductance is intentionally not recalibrated.  Compress them so they
% function as a diagnostic penalty without dominating the R(T) objective.
y = log10(1 + max(x, 0));
y(~isfinite(x)) = 0;
end

function count = estimate_parameter_count(sourceVersion, topology, linkClass)
n = numel(sourceVersion);
count = ones(n, 1);
for k = 1:n
    t = lower(string(topology(k)));
    v = lower(string(sourceVersion(k)));
    c = lower(string(linkClass(k)));

    if contains(t, "central")
        count(k) = 1;
    elseif t == "none" || t == "no_weak_links"
        count(k) = 0;
    elseif contains(t, "uniform") || contains(t, "shuffled")
        count(k) = 2;
    elseif contains(v, "7.4.6") || strlength(strtrim(c)) > 0
        count(k) = 4;
    else
        count(k) = 3;
    end
end
end

function mechanism = classify_v77_mechanism(sourceVersion, sourceRole, topology, linkClass)
n = numel(sourceVersion);
mechanism = strings(n, 1);
for k = 1:n
    t = lower(string(topology(k)));
    r = lower(string(sourceRole(k)));
    c = lower(string(linkClass(k)));

    if contains(t, "central")
        mechanism(k) = "central-lane / 1D-like";
    elseif t == "none" || contains(t, "no_weak")
        mechanism(k) = "no weak links";
    elseif contains(t, "uniform")
        mechanism(k) = "uniform weak links";
    elseif contains(t, "shuffled")
        mechanism(k) = "shuffled weak links";
    elseif contains(r, "gap") || strlength(strtrim(c)) > 0
        mechanism(k) = "gap-tied weak links";
    elseif contains(r, "bottleneck")
        mechanism(k) = "physical bottleneck W_{ij}";
    elseif contains(r, "wij")
        mechanism(k) = "controlled W_{ij} topology";
    else
        mechanism(k) = "unclassified candidate";
    end
end
end
