function score = compute_v73_field_score(field, expField)
%COMPUTE_V73_FIELD_SCORE Compare modeled and measured dV/dI(I,B) maps.
%
% Scores are RMS mismatches between independently normalized maps. Lower is
% better. This intentionally evaluates shape/topology rather than claiming an
% independent absolute dV/dI calibration.

pairs = {'top_4_10','bottom_3_9'};

score = struct();
score.available = false;
score.mapRms = struct();
score.zeroBiasRms = struct();
score.pairScores = struct();
score.combined = NaN;
score.definition = ['RMS mismatch between model and experiment after each ', ...
    'pair map is normalized by its own high-resistance percentile.'];

if nargin < 2 || ~isfield(expField, 'available') || ~expField.available
    score.message = 'No experimental dV/dI(I,B) field map available.';
    return;
end

pairVals = [];

for kp = 1:numel(pairs)
    pairName = pairs{kp};
    if ~isfield(field.dVdI, pairName) || ~isfield(expField.Rnorm, pairName)
        continue;
    end

    modelNorm = normalize_map(field.dVdI.(pairName));
    expNorm = expField.Rnorm.(pairName);
    expOnModel = interp_exp_to_model(expField, expNorm, field);

    valid = isfinite(modelNorm) & isfinite(expOnModel);
    if nnz(valid) < 10
        continue;
    end

    diffMap = modelNorm - expOnModel;
    mapRms = sqrt(mean(diffMap(valid).^2, 'omitnan'));

    zbModel = zero_bias_trace(field.I_A, modelNorm);
    zbExp = zero_bias_trace(field.I_A, expOnModel);
    validZb = isfinite(zbModel) & isfinite(zbExp);
    zbRms = sqrt(mean((zbModel(validZb) - zbExp(validZb)).^2, 'omitnan'));

    pairScore = 0.75 .* mapRms + 0.25 .* zbRms;

    score.mapRms.(pairName) = mapRms;
    score.zeroBiasRms.(pairName) = zbRms;
    score.pairScores.(pairName) = pairScore;
    pairVals(end+1) = pairScore; %#ok<AGROW>
end

if ~isempty(pairVals)
    score.available = true;
    score.combined = mean(pairVals, 'omitnan');
    score.message = sprintf('v7.3 field score from %d pair(s).', numel(pairVals));
else
    score.message = 'No overlapping model/experimental pair maps were scored.';
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

function p = percentile_local(x, pct)

x = sort(x(:));
q = 1 + (numel(x)-1) * pct / 100;
lo = floor(q);
hi = ceil(q);
if lo == hi
    p = x(lo);
else
    p = x(lo) + (q-lo) * (x(hi)-x(lo));
end

end
