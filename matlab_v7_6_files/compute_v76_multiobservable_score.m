function score = compute_v76_multiobservable_score(deviceName, modelRun, expData, opts, modelInfo, nonlinearData)
%COMPUTE_V76_MULTIOBSERVABLE_SCORE Multi-observable objective for v7.6.
%
% score = compute_v76_multiobservable_score(deviceName, modelRun, expData)
%
% Primary objective:
%   chi2_RT = sum_{p,k} ((R_model_p(T_k)-R_exp_p(T_k))/sigma_p(T_k))^2
%
% Secondary checks:
%   Tonset, rLow, transition breadth, probe-pair asymmetry, and optional
%   nonlinear dV/dI(I) linecuts.
%
% This function is intentionally tolerant of the different structs produced
% by earlier v7 scripts.  It accepts either a run struct with run.result, or
% a result struct directly.

if nargin < 4 || isempty(opts)
    opts = make_v76_multiobservable_score_options();
end
if nargin < 5 || isempty(modelInfo)
    modelInfo = struct();
end
if nargin < 6
    nonlinearData = [];
end

score = struct();
score.version = opts.version;
score.device = char(deviceName);
score.primary = compute_primary_rt_score(modelRun, expData, opts);
score.secondary = compute_secondary_metric_score(modelRun, expData, opts);
score.asymmetry = compute_probe_asymmetry_score(modelRun, expData, opts);
score.nonlinear = compute_nonlinear_linecut_score(nonlinearData, opts);
score.complexity = compute_complexity_terms(score, modelInfo, opts);

components = [];
weights = [];

[components, weights] = append_component(components, weights, ...
    score.primary.weightedRMS, opts.weights.primaryRT);
[components, weights] = append_component(components, weights, ...
    score.secondary.weightedRMS, opts.weights.secondaryMetrics);
[components, weights] = append_component(components, weights, ...
    score.asymmetry.weightedRMS, opts.weights.probeAsymmetry);
[components, weights] = append_component(components, weights, ...
    score.nonlinear.weightedRMS, opts.weights.nonlinearLinecuts);
[components, weights] = append_component(components, weights, ...
    score.complexity.normalizedPenalty, opts.weights.complexityPenalty);

if isempty(components)
    score.objectiveScore = NaN;
else
    score.objectiveScore = sum(weights .* components) / sum(weights);
end

score.summaryTable = make_score_summary_table(score);

end

function primary = compute_primary_rt_score(modelRun, expData, opts)

pairs = opts.probePairs;
primary = struct();
primary.pairs = struct();
primary.chi2 = 0;
primary.nPoints = 0;
primary.nPairs = 0;
primary.weightedRMS = NaN;
primary.note = '';

for k = 1:numel(pairs)
    pairName = pairs{k};
    P = empty_pair_primary(pairName);

    [Tm, Rm] = get_model_pair_curve(modelRun, pairName);
    [Te, Re] = get_exp_pair_curve(expData, pairName);

    if isempty(Tm) || isempty(Rm) || isempty(Te) || isempty(Re)
        primary.pairs.(pairName) = P;
        continue;
    end

    [Tm, Rm] = clean_curve(Tm, Rm);
    [Te, Re] = clean_curve(Te, Re);
    if numel(Tm) < 2 || numel(Te) < opts.primary.minPointsPerPair
        primary.pairs.(pairName) = P;
        continue;
    end

    if opts.primary.normalizeIndependent
        Rm = normalize_highT(Rm, opts.primary.highFrac, opts.primary.nHighDefault);
        Re = normalize_highT(Re, opts.primary.highFrac, opts.primary.nHighDefault);
    end

    overlap = Te >= min(Tm) & Te <= max(Tm);
    Te2 = Te(overlap);
    Re2 = Re(overlap);
    if numel(Te2) < opts.primary.minPointsPerPair
        primary.pairs.(pairName) = P;
        continue;
    end

    Rmi = interp1(Tm, Rm, Te2, 'linear');
    sigma = sqrt(opts.primary.sigmaFloor.^2 + ...
        (opts.primary.sigmaFraction .* max(abs(Re2), eps)).^2);
    resid = (Rmi - Re2) ./ sigma;
    valid = isfinite(resid);

    P.available = any(valid);
    P.nPoints = sum(valid);
    P.chi2 = sum(resid(valid).^2);
    P.weightedRMS = sqrt(mean(resid(valid).^2));
    P.temperature_K = Te2(valid);
    P.model = Rmi(valid);
    P.experiment = Re2(valid);
    P.sigma = sigma(valid);

    primary.chi2 = primary.chi2 + P.chi2;
    primary.nPoints = primary.nPoints + P.nPoints;
    primary.nPairs = primary.nPairs + double(P.available);
    primary.pairs.(pairName) = P;
end

if primary.nPoints > 0
    primary.reducedChi2 = primary.chi2 / primary.nPoints;
    primary.weightedRMS = sqrt(primary.reducedChi2);
else
    primary.reducedChi2 = NaN;
    primary.note = 'No overlapping model/experiment R(T) pair data found.';
end

end

function secondary = compute_secondary_metric_score(modelRun, expData, opts)

secondary = struct();
secondary.enabled = opts.secondary.enabled;
secondary.components = struct();
secondary.nContributions = 0;
secondary.weightedRMS = NaN;

if ~opts.secondary.enabled
    return;
end

pairs = opts.probePairs;
fields = fieldnames(opts.secondary.weights);
accum = 0;
wtSum = 0;

for k = 1:numel(pairs)
    pairName = pairs{k};
    [Tm, Rm] = get_model_pair_curve(modelRun, pairName);
    [Te, Re] = get_exp_pair_curve(expData, pairName);
    if isempty(Tm) || isempty(Rm) || isempty(Te) || isempty(Re)
        continue;
    end
    [Tm, Rm] = clean_curve(Tm, Rm);
    [Te, Re] = clean_curve(Te, Re);
    if numel(Tm) < 3 || numel(Te) < 3
        continue;
    end

    modelMetrics = compute_rt_curve_metrics(Tm, Rm, opts.metricOptions);
    expMetrics = compute_rt_curve_metrics(Te, Re, opts.metricOptions);

    for f = 1:numel(fields)
        name = fields{f};
        if ~isfield(modelMetrics, name) || ~isfield(expMetrics, name)
            continue;
        end
        scale = opts.secondary.scales.(name);
        weight = opts.secondary.weights.(name);
        z = (modelMetrics.(name) - expMetrics.(name)) ./ scale;
        if ~isfinite(z)
            continue;
        end
        key = matlab.lang.makeValidName([pairName '_' name]);
        secondary.components.(key) = z;
        accum = accum + weight * z.^2;
        wtSum = wtSum + weight;
        secondary.nContributions = secondary.nContributions + 1;
    end
end

if wtSum > 0
    secondary.weightedRMS = sqrt(accum / wtSum);
end

end

function asym = compute_probe_asymmetry_score(modelRun, expData, opts)

asym = struct();
asym.enabled = opts.asymmetry.enabled;
asym.available = false;
asym.weightedRMS = NaN;
asym.nPoints = 0;
asym.temperature_K = [];
asym.modelA = [];
asym.expA = [];

if ~opts.asymmetry.enabled || numel(opts.probePairs) < 2
    return;
end

p1 = opts.probePairs{1};
p2 = opts.probePairs{2};
[Tm1, Rm1] = get_model_pair_curve(modelRun, p1);
[Tm2, Rm2] = get_model_pair_curve(modelRun, p2);
[Te1, Re1] = get_exp_pair_curve(expData, p1);
[Te2, Re2] = get_exp_pair_curve(expData, p2);

if isempty(Tm1) || isempty(Tm2) || isempty(Te1) || isempty(Te2)
    return;
end

[Tm1, Rm1] = clean_curve(Tm1, Rm1);
[Tm2, Rm2] = clean_curve(Tm2, Rm2);
[Te1, Re1] = clean_curve(Te1, Re1);
[Te2, Re2] = clean_curve(Te2, Re2);

if opts.asymmetry.usePairNormalized
    Rm1 = normalize_highT(Rm1, opts.primary.highFrac, opts.primary.nHighDefault);
    Rm2 = normalize_highT(Rm2, opts.primary.highFrac, opts.primary.nHighDefault);
    Re1 = normalize_highT(Re1, opts.primary.highFrac, opts.primary.nHighDefault);
    Re2 = normalize_highT(Re2, opts.primary.highFrac, opts.primary.nHighDefault);
end

Tmin = max([min(Tm1), min(Tm2), min(Te1), min(Te2)]);
Tmax = min([max(Tm1), max(Tm2), max(Te1), max(Te2)]);
Tgrid = Te1(Te1 >= Tmin & Te1 <= Tmax);
if numel(Tgrid) < opts.primary.minPointsPerPair
    return;
end

Rm1i = interp1(Tm1, Rm1, Tgrid, 'linear');
Rm2i = interp1(Tm2, Rm2, Tgrid, 'linear');
Re1i = interp1(Te1, Re1, Tgrid, 'linear');
Re2i = interp1(Te2, Re2, Tgrid, 'linear');

Am = asymmetry_value(Rm1i, Rm2i);
Ae = asymmetry_value(Re1i, Re2i);
resid = (Am - Ae) ./ opts.asymmetry.sigmaFloor;
valid = isfinite(resid);

if any(valid)
    asym.available = true;
    asym.temperature_K = Tgrid(valid);
    asym.modelA = Am(valid);
    asym.expA = Ae(valid);
    asym.nPoints = sum(valid);
    asym.weightedRMS = sqrt(mean(resid(valid).^2));
end

end

function nonlinear = compute_nonlinear_linecut_score(nonlinearData, opts)

nonlinear = struct();
nonlinear.enabled = opts.nonlinear.enabled;
nonlinear.available = false;
nonlinear.weightedRMS = NaN;
nonlinear.nPoints = 0;
nonlinear.note = '';

if ~opts.nonlinear.enabled
    return;
end
if isempty(nonlinearData)
    nonlinear.note = 'No nonlinear linecut data supplied.';
    return;
end
if opts.nonlinear.includeFullFieldRaster
    nonlinear.note = 'Full field raster scoring is intentionally disabled for core v7.6.';
    return;
end

% Expected lightweight format:
% nonlinearData.cuts(k).I, .model, .experiment
if ~isfield(nonlinearData, 'cuts')
    nonlinear.note = 'Expected nonlinearData.cuts with I/model/experiment linecuts.';
    return;
end

allResid = [];
for k = 1:numel(nonlinearData.cuts)
    C = nonlinearData.cuts(k);
    if ~isfield(C, 'I') || ~isfield(C, 'model') || ~isfield(C, 'experiment')
        continue;
    end
    I = C.I(:);
    model = C.model(:);
    experiment = C.experiment(:);
    n = min([numel(I), numel(model), numel(experiment)]);
    if n < 3
        continue;
    end
    resid = (model(1:n) - experiment(1:n)) ./ opts.nonlinear.sigmaFloor;
    allResid = [allResid; resid(isfinite(resid))]; %#ok<AGROW>
end

if ~isempty(allResid)
    nonlinear.available = true;
    nonlinear.nPoints = numel(allResid);
    nonlinear.weightedRMS = sqrt(mean(allResid.^2));
end

end

function complexity = compute_complexity_terms(score, modelInfo, opts)

complexity = struct();
complexity.enabled = opts.complexity.enabled;
complexity.parameterCount = get_struct_value(modelInfo, 'parameterCount', 0);
complexity.normalizedPenalty = NaN;
complexity.AIC = NaN;
complexity.AICc = NaN;
complexity.BIC = NaN;

if ~opts.complexity.enabled
    return;
end

complexity.normalizedPenalty = ...
    opts.complexity.parameterPenaltyPerFreeParameter * complexity.parameterCount;

n = score.primary.nPoints;
k = complexity.parameterCount;
chi2 = score.primary.chi2;

if opts.complexity.computeInformationCriteria && n > 0 && isfinite(chi2)
    % Gaussian residual IC up to an additive constant.  This is useful for
    % comparing nested model variants scored against the same data.
    mse = max(chi2 / n, eps);
    complexity.AIC = n * log(mse) + 2 * k;
    complexity.BIC = n * log(mse) + k * log(max(n, 1));
    if n > k + 1
        complexity.AICc = complexity.AIC + (2 * k * (k + 1)) / (n - k - 1);
    end
end

end

function T = make_score_summary_table(score)

component = {'primary_RT'; 'secondary_metrics'; 'probe_asymmetry'; ...
    'nonlinear_linecuts'; 'complexity_penalty'; 'objective'};
value = [score.primary.weightedRMS; score.secondary.weightedRMS; ...
    score.asymmetry.weightedRMS; score.nonlinear.weightedRMS; ...
    score.complexity.normalizedPenalty; score.objectiveScore];
nPoints = [score.primary.nPoints; score.secondary.nContributions; ...
    score.asymmetry.nPoints; score.nonlinear.nPoints; NaN; NaN];

T = table(component, value, nPoints);

end

function P = empty_pair_primary(pairName)
P = struct();
P.pairName = pairName;
P.available = false;
P.nPoints = 0;
P.chi2 = NaN;
P.weightedRMS = NaN;
P.temperature_K = [];
P.model = [];
P.experiment = [];
P.sigma = [];
end

function [T, R] = get_model_pair_curve(modelRun, pairName)

T = [];
R = [];

if isfield(modelRun, 'result')
    modelRun = modelRun.result;
end

if isfield(modelRun, 'T')
    T = modelRun.T;
end

if isfield(modelRun, 'R4p') && isfield(modelRun.R4p, pairName)
    R = modelRun.R4p.(pairName);
elseif isfield(modelRun, 'R') && isfield(modelRun.R, pairName)
    R = modelRun.R.(pairName);
elseif isfield(modelRun, 'curves') && isfield(modelRun.curves, pairName)
    C = modelRun.curves.(pairName);
    if isfield(C, 'T')
        T = C.T;
    end
    if isfield(C, 'R')
        R = C.R;
    end
end

end

function [T, R] = get_exp_pair_curve(expData, pairName)

T = [];
R = [];

if isempty(expData)
    return;
end

if isfield(expData, 'pairData') && isfield(expData.pairData, 'available') && ...
        expData.pairData.available && isfield(expData.pairData, 'R') && ...
        isfield(expData.pairData.R, pairName)
    T = expData.pairData.T;
    R = expData.pairData.R.(pairName);
    return;
end

if isfield(expData, 'curves') && isfield(expData.curves, pairName)
    C = expData.curves.(pairName);
    if isfield(C, 'T')
        T = C.T;
    elseif isfield(expData, 'T')
        T = expData.T;
    end
    if isfield(C, 'R')
        R = C.R;
    end
    return;
end

% Fallback: a curated publication curve can represent its mapped pair.
if isfield(expData, 'modelPair') && strcmp(pairName, expData.modelPair) && ...
        isfield(expData, 'R') && isfield(expData.R, 'main_4p')
    T = expData.T;
    R = expData.R.main_4p;
elseif isfield(expData, 'R') && isfield(expData.R, pairName)
    T = expData.T;
    R = expData.R.(pairName);
end

end

function [T, R] = clean_curve(T, R)

T = numeric_vector(T);
R = numeric_vector(R);
n = min(numel(T), numel(R));
T = T(1:n);
R = R(1:n);
valid = isfinite(T) & isfinite(R);
T = T(valid);
R = R(valid);
[T, order] = sort(T);
R = R(order);

end

function y = normalize_highT(y, highFrac, nHighDefault)

y = numeric_vector(y);
n = numel(y);
if n == 0
    return;
end
nHigh = min(n, max(nHighDefault, ceil(highFrac * n)));
rn = mean(y(end-nHigh+1:end), 'omitnan');
if isfinite(rn) && abs(rn) > eps
    y = y ./ rn;
end

end

function A = asymmetry_value(R1, R2)
denom = (abs(R1) + abs(R2)) ./ 2;
A = abs(R1 - R2) ./ max(denom, eps);
end

function x = numeric_vector(x)
if istable(x)
    x = table2array(x);
end
if isnumeric(x) || islogical(x)
    x = double(x);
elseif iscell(x)
    if all(cellfun(@(c) isnumeric(c) && isscalar(c), x(:)))
        x = cellfun(@double, x);
    else
        x = str2double(x);
    end
elseif isstring(x) || ischar(x) || iscategorical(x)
    x = str2double(cellstr(x));
else
    try
        x = double(x);
    catch
        x = str2double(cellstr(x));
    end
end
x = x(:);
end

function value = get_struct_value(S, name, defaultValue)
if isstruct(S) && isfield(S, name)
    value = S.(name);
else
    value = defaultValue;
end
end

function [components, weights] = append_component(components, weights, value, weight)
if isfinite(value) && isfinite(weight) && weight > 0
    components(end+1,1) = value; %#ok<AGROW>
    weights(end+1,1) = weight; %#ok<AGROW>
end
end
