function score = compute_v742_weaklink_feature_score(field, expField, opts)
%COMPUTE_V742_WEAKLINK_FEATURE_SCORE Score low-bias weak-link signatures.
%
% Lower scores are better. Compared with the v7.3 full-map score, this score
% intentionally emphasizes the low-current dV/dI feature and zero-bias
% field trace that motivated the v7.4 weak-link ablation.

if nargin < 3
    opts = struct();
end
if ~isfield(opts, 'lowBiasWindow_A')
    opts.lowBiasWindow_A = 0.35e-6;
end
if ~isfield(opts, 'weights')
    opts.weights.fullMap = 0.20;
    opts.weights.lowBiasMap = 0.35;
    opts.weights.zeroBiasField = 0.25;
    opts.weights.topBottomAsymmetry = 0.20;
end

pairs = {'top_4_10','bottom_3_9'};

score = struct();
score.available = false;
score.combined = NaN;
score.fullMapRms = struct();
score.lowBiasRms = struct();
score.zeroBiasRms = struct();
score.asymmetryRms = NaN;
score.pairScores = struct();
score.definition = ['v7.4.2 feature score. Lower is better. The score ', ...
    'emphasizes low-bias current cuts, zero-bias field dependence, and ', ...
    'top/bottom asymmetry rather than only full-map RMS.'];

if nargin < 2 || ~isfield(expField, 'available') || ~expField.available
    score.message = 'No experimental field map available.';
    return;
end

pairScores = [];
for kp = 1:numel(pairs)
    pairName = pairs{kp};
    if ~isfield(field.dVdI, pairName) || ~isfield(expField.Rnorm, pairName)
        continue;
    end

    modelNorm = normalize_map(field.dVdI.(pairName));
    expOnModel = interp_exp_to_model(expField, expField.Rnorm.(pairName), field);
    valid = isfinite(modelNorm) & isfinite(expOnModel);

    fullRms = rms_valid(modelNorm(valid) - expOnModel(valid));

    lowMask = abs(field.I_A(:)) <= opts.lowBiasWindow_A;
    lowMask2 = repmat(lowMask, 1, numel(field.B_T));
    lowValid = valid & lowMask2;
    lowBiasRms = rms_valid(modelNorm(lowValid) - expOnModel(lowValid));

    zbModel = zero_bias_trace(field.I_A, modelNorm);
    zbExp = zero_bias_trace(field.I_A, expOnModel);
    zeroBiasRms = rms_valid(zbModel - zbExp);

    pairScore = opts.weights.fullMap .* fullRms + ...
        opts.weights.lowBiasMap .* lowBiasRms + ...
        opts.weights.zeroBiasField .* zeroBiasRms;

    score.fullMapRms.(pairName) = fullRms;
    score.lowBiasRms.(pairName) = lowBiasRms;
    score.zeroBiasRms.(pairName) = zeroBiasRms;
    score.pairScores.(pairName) = pairScore;
    pairScores(end+1) = pairScore; %#ok<AGROW>
end

if isfield(field.dVdI, 'top_4_10') && isfield(field.dVdI, 'bottom_3_9') && ...
        isfield(expField.Rnorm, 'top_4_10') && isfield(expField.Rnorm, 'bottom_3_9')
    mt = normalize_map(field.dVdI.top_4_10);
    mb = normalize_map(field.dVdI.bottom_3_9);
    et = interp_exp_to_model(expField, expField.Rnorm.top_4_10, field);
    eb = interp_exp_to_model(expField, expField.Rnorm.bottom_3_9, field);
    modelDelta = mb - mt;
    expDelta = eb - et;
    lowMask = abs(field.I_A(:)) <= opts.lowBiasWindow_A;
    lowMask2 = repmat(lowMask, 1, numel(field.B_T));
    valid = isfinite(modelDelta) & isfinite(expDelta) & lowMask2;
    score.asymmetryRms = rms_valid(modelDelta(valid) - expDelta(valid));
else
    score.asymmetryRms = NaN;
end

if ~isempty(pairScores)
    score.available = true;
    asymTerm = opts.weights.topBottomAsymmetry .* score.asymmetryRms;
    if ~isfinite(asymTerm)
        asymTerm = 0;
    end
    score.combined = mean(pairScores, 'omitnan') + asymTerm;
    score.message = sprintf('v7.4.2 weak-link feature score from %d pair(s).', ...
        numel(pairScores));
else
    score.message = 'No overlapping model/experiment maps were scored.';
end

end

function Z = normalize_map(Z)

vals = Z(isfinite(Z));
if isempty(vals)
    return;
end
rn = percentile_local(vals, 95);
Z = Z ./ max(rn, eps);

end

function Zq = interp_exp_to_model(expField, Zexp, field)

[Bexp, Iexp] = meshgrid(expField.B_T, expField.I_A);
[Bq, Iq] = meshgrid(field.B_T, field.I_A);
Zq = interp2(Bexp, Iexp, Zexp, Bq, Iq, 'linear', NaN);

end

function zb = zero_bias_trace(I, Z)

[~, idx] = min(abs(I));
zb = Z(idx, :);

end

function r = rms_valid(x)

x = x(isfinite(x));
if isempty(x)
    r = NaN;
else
    r = sqrt(mean(x(:).^2, 'omitnan'));
end

end

function p = percentile_local(x, pct)

x = sort(x(:));
if isempty(x)
    p = NaN;
    return;
end
q = 1 + (numel(x)-1) * pct / 100;
lo = floor(q);
hi = ceil(q);
if lo == hi
    p = x(lo);
else
    p = x(lo) + (q-lo) * (x(hi)-x(lo));
end

end
