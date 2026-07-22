function asym = compute_v71_asymmetry_diagnostics(result, expData)
%COMPUTE_V71_ASYMMETRY_DIAGNOSTICS Top-bottom normalized R(T) asymmetry.
%
% The AS006 v7.1 diagnostic defines
%
%   Delta r(T) = r_bottom_3_9(T) - r_top_4_10(T),
%
% where each pair curve is independently normalized by its own high-temperature
% resistance. This isolates lateral top/bottom transition-shape asymmetry from
% the absolute normal-state scale.

model = normalized_model_pair_curves(result);
exp = normalized_experiment_pair_curves(expData);

asym = struct();
asym.definition = 'Delta r(T) = r_{3-9}(T) - r_{4-10}(T), pair-normalized';
asym.model = model;
asym.experiment = exp;

if exp.available
    tMin = max(min(model.T), min(exp.T));
    tMax = min(max(model.T), max(exp.T));
else
    tMin = min(model.T);
    tMax = max(model.T);
end

if ~(isfinite(tMin) && isfinite(tMax) && tMax > tMin)
    asym.curves = empty_asymmetry_curve_table();
    asym.summary = empty_asymmetry_summary(false);
    return;
end

Tcommon = linspace(tMin, tMax, 220)';

modelTop = interp1(model.T, model.top, Tcommon, 'linear');
modelBottom = interp1(model.T, model.bottom, Tcommon, 'linear');
modelDelta = modelBottom - modelTop;

if exp.available
    expTop = interp1(exp.T, exp.top, Tcommon, 'linear');
    expBottom = interp1(exp.T, exp.bottom, Tcommon, 'linear');
    expDelta = expBottom - expTop;
else
    expTop = NaN(size(Tcommon));
    expBottom = NaN(size(Tcommon));
    expDelta = NaN(size(Tcommon));
end

validModel = isfinite(modelDelta);
validExp = isfinite(expDelta);
validBoth = validModel & validExp;

curves = table();
curves.T_K = Tcommon;
curves.model_top_4_10_norm = modelTop;
curves.model_bottom_3_9_norm = modelBottom;
curves.model_delta_bottom_minus_top = modelDelta;
curves.exp_top_4_10_norm = expTop;
curves.exp_bottom_3_9_norm = expBottom;
curves.exp_delta_bottom_minus_top = expDelta;
curves.delta_model_minus_exp = modelDelta - expDelta;
asym.curves = curves;

summary = struct();
summary.definition = string(asym.definition);
summary.experimentAvailable = logical(exp.available);
summary.experimentAvailabilityNote = string(exp.availabilityNote);
summary.modelDeltaRms = rms_finite(modelDelta(validModel));
summary.modelDeltaMaxAbs = max_abs_finite(modelDelta(validModel));
summary.expDeltaRms = rms_finite(expDelta(validExp));
summary.expDeltaMaxAbs = max_abs_finite(expDelta(validExp));
summary.deltaMismatchRms = rms_finite(modelDelta(validBoth) - expDelta(validBoth));
summary.deltaMismatchMaxAbs = max_abs_finite(modelDelta(validBoth) - expDelta(validBoth));
summary.modelToExperimentDeltaRmsRatio = summary.modelDeltaRms ./ max(summary.expDeltaRms, eps);
summary.modelNearlySymmetric = logical(summary.modelDeltaRms < 0.02);
summary.experimentClearlyAsymmetric = logical(summary.expDeltaRms > 0.05);
summary.asymmetryFailureFlag = logical(summary.modelNearlySymmetric && summary.experimentClearlyAsymmetric);

asym.summary = summary;

end

function model = normalized_model_pair_curves(result)

required = {'top_4_10','bottom_3_9'};
for k = 1:numel(required)
    if ~isfield(result.R4p, required{k})
        error('Model result lacks required pair "%s".', required{k});
    end
end

[Ttop, top] = normalize_rt_curve(result.T, result.R4p.top_4_10);
[Tbottom, bottom] = normalize_rt_curve(result.T, result.R4p.bottom_3_9);

T = common_temperature_axis(Ttop, Tbottom);
model = struct();
model.T = T;
model.top = interp1(Ttop, top, T, 'linear');
model.bottom = interp1(Tbottom, bottom, T, 'linear');
model.delta = model.bottom - model.top;

end

function exp = normalized_experiment_pair_curves(expData)

exp = struct();
exp.available = false;
exp.availabilityNote = 'No experimental pair-data struct is available.';
exp.T = [];
exp.top = [];
exp.bottom = [];
exp.delta = [];

if ~(isfield(expData, 'pairData') && isfield(expData.pairData, 'available') && ...
        expData.pairData.available)
    if isfield(expData, 'pairFilePath') && ~isempty(expData.pairFilePath)
        exp.availabilityNote = sprintf('Mapped pair file was not loaded: %s', expData.pairFilePath);
    end
    return;
end
if ~(isfield(expData.pairData.R, 'top_4_10') && ...
        isfield(expData.pairData.R, 'bottom_3_9'))
    available = fieldnames(expData.pairData.R);
    exp.availabilityNote = sprintf(['Experimental pair file lacks both top_4_10 ', ...
        'and bottom_3_9. Available channels: %s'], strjoin(available, ', '));
    return;
end

[Ttop, top] = normalize_rt_curve(expData.pairData.T, expData.pairData.R.top_4_10);
[Tbottom, bottom] = normalize_rt_curve(expData.pairData.T, expData.pairData.R.bottom_3_9);

T = common_temperature_axis(Ttop, Tbottom);
exp.available = true;
exp.availabilityNote = 'Both experimental top_4_10 and bottom_3_9 channels are available.';
exp.T = T;
exp.top = interp1(Ttop, top, T, 'linear');
exp.bottom = interp1(Tbottom, bottom, T, 'linear');
exp.delta = exp.bottom - exp.top;

end

function T = common_temperature_axis(Ta, Tb)

tMin = max(min(Ta), min(Tb));
tMax = min(max(Ta), max(Tb));
if tMax <= tMin
    T = [];
else
    n = max(numel(Ta), numel(Tb));
    T = linspace(tMin, tMax, n)';
end

end

function y = rms_finite(x)

x = x(isfinite(x));
if isempty(x)
    y = NaN;
else
    y = sqrt(mean(x.^2));
end

end

function y = max_abs_finite(x)

x = x(isfinite(x));
if isempty(x)
    y = NaN;
else
    y = max(abs(x));
end

end

function T = empty_asymmetry_curve_table()

T = table();
T.T_K = [];
T.model_top_4_10_norm = [];
T.model_bottom_3_9_norm = [];
T.model_delta_bottom_minus_top = [];
T.exp_top_4_10_norm = [];
T.exp_bottom_3_9_norm = [];
T.exp_delta_bottom_minus_top = [];
T.delta_model_minus_exp = [];

end

function summary = empty_asymmetry_summary(expAvailable)

summary = struct();
summary.definition = "";
summary.experimentAvailable = logical(expAvailable);
summary.experimentAvailabilityNote = "";
summary.modelDeltaRms = NaN;
summary.modelDeltaMaxAbs = NaN;
summary.expDeltaRms = NaN;
summary.expDeltaMaxAbs = NaN;
summary.deltaMismatchRms = NaN;
summary.deltaMismatchMaxAbs = NaN;
summary.modelToExperimentDeltaRmsRatio = NaN;
summary.modelNearlySymmetric = false;
summary.experimentClearlyAsymmetric = false;
summary.asymmetryFailureFlag = false;

end
