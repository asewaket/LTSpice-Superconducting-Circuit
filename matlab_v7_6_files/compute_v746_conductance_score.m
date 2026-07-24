function score = compute_v746_conductance_score(field, expField, opts)
%COMPUTE_V746_CONDUCTANCE_SCORE Absolute-scale dV/dI score.
%
% Unlike compute_v742_weaklink_feature_score, this function does not
% independently normalize each model map by its own high-resistance scale.
% The model and experiment are divided only by the experimental normal-state
% reference for each pair, so removing/weakening links can carry an absolute
% conductance penalty.

if nargin < 3
    opts = make_v746_gap_weaklink_options();
    opts = opts.conductanceScore;
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
score.expRN = struct();
score.modelRN = struct();
score.definition = ['v7.4.6 conductance-preserving feature score. ', ...
    'The model is not renormalized case-by-case; differences are scaled ', ...
    'by the experimental high-resistance reference. Lower is better.'];

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
    if isfield(expField, 'R') && isfield(expField.R, pairName)
        expRaw = expField.R.(pairName);
    else
        expRaw = expField.Rnorm.(pairName);
    end

    expRN = percentile_local_v746(expRaw(isfinite(expRaw)), 95);
    modelRN = percentile_local_v746(field.dVdI.(pairName)(isfinite(field.dVdI.(pairName))), 95);
    score.expRN.(pairName) = expRN;
    score.modelRN.(pairName) = modelRN;

    modelScaled = field.dVdI.(pairName) ./ max(expRN, eps);
    expScaled = interp_exp_to_model_v746(expField, expRaw ./ max(expRN, eps), field);
    valid = isfinite(modelScaled) & isfinite(expScaled);
    fullRms = rms_valid_v746(modelScaled(valid) - expScaled(valid));

    lowMask = abs(field.I_A(:)) <= opts.lowBiasWindow_A;
    lowMask2 = repmat(lowMask, 1, numel(field.B_T));
    lowValid = valid & lowMask2;
    lowBiasRms = rms_valid_v746(modelScaled(lowValid) - expScaled(lowValid));

    zbModel = zero_bias_trace_v746(field.I_A, modelScaled);
    zbExp = zero_bias_trace_v746(field.I_A, expScaled);
    zeroBiasRms = rms_valid_v746(zbModel - zbExp);

    pairScore = opts.weights.fullMap .* fullRms + ...
        opts.weights.lowBiasMap .* lowBiasRms + ...
        opts.weights.zeroBiasField .* zeroBiasRms;

    score.fullMapRms.(pairName) = fullRms;
    score.lowBiasRms.(pairName) = lowBiasRms;
    score.zeroBiasRms.(pairName) = zeroBiasRms;
    pairScores(end+1) = pairScore; %#ok<AGROW>
end

if isfield(field.dVdI, 'top_4_10') && isfield(field.dVdI, 'bottom_3_9') && ...
        isfield(expField.Rnorm, 'top_4_10') && isfield(expField.Rnorm, 'bottom_3_9')
    expTop = get_exp_raw_v746(expField, 'top_4_10');
    expBot = get_exp_raw_v746(expField, 'bottom_3_9');
    rnTop = percentile_local_v746(expTop(isfinite(expTop)), 95);
    rnBot = percentile_local_v746(expBot(isfinite(expBot)), 95);
    mt = field.dVdI.top_4_10 ./ max(rnTop, eps);
    mb = field.dVdI.bottom_3_9 ./ max(rnBot, eps);
    et = interp_exp_to_model_v746(expField, expTop ./ max(rnTop, eps), field);
    eb = interp_exp_to_model_v746(expField, expBot ./ max(rnBot, eps), field);
    modelDelta = mb - mt;
    expDelta = eb - et;
    lowMask = abs(field.I_A(:)) <= opts.lowBiasWindow_A;
    lowMask2 = repmat(lowMask, 1, numel(field.B_T));
    valid = isfinite(modelDelta) & isfinite(expDelta) & lowMask2;
    score.asymmetryRms = rms_valid_v746(modelDelta(valid) - expDelta(valid));
end

if ~isempty(pairScores)
    score.available = true;
    asymTerm = opts.weights.topBottomAsymmetry .* score.asymmetryRms;
    if ~isfinite(asymTerm)
        asymTerm = 0;
    end
    score.combined = mean(pairScores, 'omitnan') + asymTerm;
    score.message = sprintf('v7.4.6 conductance score from %d pair(s).', numel(pairScores));
else
    score.message = 'No overlapping model/experiment maps were scored.';
end

end

function expRaw = get_exp_raw_v746(expField, pairName)
if isfield(expField, 'R') && isfield(expField.R, pairName)
    expRaw = expField.R.(pairName);
else
    expRaw = expField.Rnorm.(pairName);
end
end

function Zq = interp_exp_to_model_v746(expField, Zexp, field)
[Bexp, Iexp] = meshgrid(expField.B_T, expField.I_A);
[Bq, Iq] = meshgrid(field.B_T, field.I_A);
Zq = interp2(Bexp, Iexp, Zexp, Bq, Iq, 'linear', NaN);
end

function zb = zero_bias_trace_v746(I, Z)
[~, idx] = min(abs(I));
zb = Z(idx, :);
end

function r = rms_valid_v746(x)
x = x(isfinite(x));
if isempty(x)
    r = NaN;
else
    r = sqrt(mean(x(:).^2));
end
end

function p = percentile_local_v746(vals, pct)
vals = sort(vals(isfinite(vals)));
if isempty(vals)
    p = NaN;
    return;
end
idx = max(1, min(numel(vals), round(pct/100 * numel(vals))));
p = vals(idx);
end
