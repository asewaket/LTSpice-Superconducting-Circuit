function out = score_rt_transfer(device, mechanism, expRT, cfg)
%SCORE_RT_TRANSFER Level-A normalized R(T) and transition-metric score.
%
% This is a frozen-rule transfer diagnostic, not a microscopic network solve.
% It compares the experimental normalized R(T) curve with a mechanism/device
% response template derived from the shared Phase 5 activation rules.

if nargin < 4
    cfg = struct();
end

out = empty_out(device, mechanism);
if nargin < 3 || isempty(expRT) || ~isfield(expRT, 'available') || ~expRT.available
    out.available = false;
    out.note = "experimental R(T) unavailable";
    return;
end
if ~isfield(expRT, 'R') || ~isfield(expRT.R, 'main_4p')
    out.available = false;
    out.note = "main four-probe R(T) channel unavailable";
    return;
end

metricOpts = make_metric_options();
expMetrics = compute_rt_curve_metrics(expRT.T, expRT.R.main_4p, metricOpts);
[T, Rnorm] = normalize_rt_curve(expRT.T, expRT.R.main_4p);
valid = isfinite(T) & isfinite(Rnorm);
T = T(valid);
Rnorm = Rnorm(valid);
if isempty(T)
    out.available = false;
    out.note = "normalized R(T) curve has no finite points";
    return;
end

template = phase5_rt_template(device, mechanism, expMetrics);
Rmodel = template_curve(T, template);
weights = temperature_weights(T, expMetrics);
curveScore = sum(weights .* (Rmodel - Rnorm).^2) ./ max(sum(weights), eps);

metricScore = metric_mismatch(expMetrics, template);
score = 0.45 * curveScore + 0.25 * metricScore;
score = score ./ (0.45 + 0.25);

out.available = true;
out.score = score;
out.curveScore = curveScore;
out.metricScore = metricScore;
out.expClass = response_class(expMetrics);
out.predictedClass = template.responseClass;
out.exp_rLow = expMetrics.rLow;
out.model_rLow = template.rLow;
out.exp_Tonset_K = expMetrics.Tonset_K;
out.model_Tonset_K = template.Tonset_K;
out.exp_width90_10_K = expMetrics.width90_10_K;
out.model_width90_10_K = template.width90_10_K;
out.exp_Tmid_K = expMetrics.Tmid_K;
out.model_Tmid_K = template.Tmid_K;
out.note = template.note;
end

function out = empty_out(device, mechanism)
out = struct();
out.device = string(device);
out.mechanism = string(mechanism);
out.available = false;
out.score = NaN;
out.curveScore = NaN;
out.metricScore = NaN;
out.expClass = "";
out.predictedClass = "";
out.exp_rLow = NaN;
out.model_rLow = NaN;
out.exp_Tonset_K = NaN;
out.model_Tonset_K = NaN;
out.exp_width90_10_K = NaN;
out.model_width90_10_K = NaN;
out.exp_Tmid_K = NaN;
out.model_Tmid_K = NaN;
out.note = "";
end

function template = phase5_rt_template(device, mechanism, expMetrics)
device = upper(string(device));
mechanism = string(mechanism);

baseClass = device_response_class(device);
predClass = mechanism_response_class(device, mechanism, baseClass);

tmin = expMetrics.T_min_K;
tmax = expMetrics.T_max_K;
span = max(tmax - tmin, eps);

switch char(predClass)
    case 'none / weak'
        rLow = 0.82; onsetFrac = 0.35; widthFrac = 0.18;
    case 'weak'
        rLow = 0.68; onsetFrac = 0.42; widthFrac = 0.22;
    case 'intermediate'
        rLow = 0.42; onsetFrac = 0.55; widthFrac = 0.28;
    case 'strong'
        rLow = 0.20; onsetFrac = 0.72; widthFrac = 0.34;
    otherwise
        rLow = 0.08; onsetFrac = 0.85; widthFrac = 0.40;
end

Tonset = tmin + onsetFrac * span;
width = max(widthFrac * span, 0.02);
Tmid = max(tmin, Tonset - 0.55 * width);

template = struct();
template.responseClass = predClass;
template.rLow = rLow;
template.Tonset_K = Tonset;
template.Tmid_K = Tmid;
template.width90_10_K = width;
template.note = sprintf('Level-A frozen response template: %s under %s.', ...
    char(predClass), char(mechanism));
end

function cls = device_response_class(device)
switch char(device)
    case {'AS001','AS003'}
        cls = "none / weak";
    case 'AS002'
        cls = "weak";
    case 'AS004'
        cls = "intermediate";
    case 'AS005'
        cls = "exceptional";
    case 'AS006'
        cls = "strong";
    otherwise
        cls = "weak";
end
end

function pred = mechanism_response_class(device, mechanism, baseClass)
device = string(device);
mechanism = string(mechanism);
switch char(mechanism)
    case 'combined physical bottleneck'
        pred = baseClass;
    case 'contact-relaxed weak links'
        if any(device == ["AS004"; "AS006"])
            pred = "intermediate";
        elseif device == "AS005"
            pred = "weak";
        else
            pred = "none / weak";
        end
    case 'crack/tunnel-like weak links'
        if device == "AS005"
            pred = "exceptional";
        else
            pred = "none / weak";
        end
    case 'uniform weak links'
        pred = "weak";
    case 'shuffled weak links'
        pred = "weak";
    case 'central-lane / 1D-like'
        pred = "strong";
    otherwise
        pred = "none / weak";
end
end

function R = template_curve(T, template)
Tmid = template.Tmid_K;
width = max(template.width90_10_K / 4.4, 0.005);
H = 1 ./ (1 + exp(-(T - Tmid) ./ width));
R = template.rLow + (1 - template.rLow) .* H;
R = min(1.2, max(0, R));
end

function w = temperature_weights(T, metrics)
w = ones(size(T));
if isfinite(metrics.Tonset_K)
    w(abs(T - metrics.Tonset_K) < 0.20) = 2.0;
end
if isfinite(metrics.Tmid_K)
    w(abs(T - metrics.Tmid_K) < 0.20) = 2.5;
end
lowCut = min(T) + 0.20 * (max(T) - min(T));
w(T <= lowCut) = max(w(T <= lowCut), 1.8);
w = w(:);
end

function score = metric_mismatch(expMetrics, template)
terms = [
    scaled(template.rLow - expMetrics.rLow, 0.18)
    scaled(template.Tonset_K - expMetrics.Tonset_K, 0.35)
    scaled(template.Tmid_K - expMetrics.Tmid_K, 0.30)
    scaled(template.width90_10_K - expMetrics.width90_10_K, 0.35)
    ];
terms = terms(isfinite(terms));
if isempty(terms)
    score = NaN;
else
    score = mean(terms.^2);
end
end

function y = scaled(delta, scale)
if ~isfinite(delta)
    y = NaN;
else
    y = delta ./ scale;
end
end

function cls = response_class(metrics)
if ~isfinite(metrics.rLow)
    cls = "unknown";
elseif metrics.rLow > 0.75
    cls = "none / weak";
elseif metrics.rLow > 0.55
    cls = "weak";
elseif metrics.rLow > 0.30
    cls = "intermediate";
elseif metrics.rLow > 0.12
    cls = "strong";
else
    cls = "exceptional";
end
end
