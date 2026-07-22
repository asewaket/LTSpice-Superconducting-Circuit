function score = compute_rt_shape_score(Texp, Rexp, Tmodel, Rmodel)
%COMPUTE_RT_SHAPE_SCORE RMS difference between normalized R(T) curves.

[Texp, RexpNorm] = normalize_rt_curve(Texp, Rexp);
[Tmodel, RmodelNorm] = normalize_rt_curve(Tmodel, Rmodel);

validExp = isfinite(Texp) & isfinite(RexpNorm);
validModel = isfinite(Tmodel) & isfinite(RmodelNorm);
Texp = Texp(validExp);
RexpNorm = RexpNorm(validExp);
Tmodel = Tmodel(validModel);
RmodelNorm = RmodelNorm(validModel);

if numel(Texp) < 2 || numel(Tmodel) < 2
    score = NaN;
    return;
end

tMin = max(min(Texp), min(Tmodel));
tMax = min(max(Texp), max(Tmodel));
if tMax <= tMin
    score = NaN;
    return;
end

Tcommon = linspace(tMin, tMax, 180);
re = interp1(Texp, RexpNorm, Tcommon, 'linear');
rm = interp1(Tmodel, RmodelNorm, Tcommon, 'linear');
valid = isfinite(re) & isfinite(rm);
if ~any(valid)
    score = NaN;
else
    score = sqrt(mean((rm(valid) - re(valid)).^2));
end

end
