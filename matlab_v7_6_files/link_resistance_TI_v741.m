function [Rx, Ry] = link_resistance_TI_v741(params, spec, T, IabsX, IabsY)
%LINK_RESISTANCE_TI_V741 Current-dependent resistance with weak-link widths.

S_Tx = 1 ./ (1 + exp(-(T - params.TcX) ./ spec.solver.dT));
S_Ty = 1 ./ (1 + exp(-(T - params.TcY) ./ spec.solver.dT));

IcEffX = params.IcX;
IcEffY = params.IcY;
if isfield(params, 'gapWeakLinkModel') && params.gapWeakLinkModel
    if isfield(params, 'gapAlpha')
        alphaGap = params.gapAlpha;
    else
        alphaGap = 3.7;
    end
    Fx = ab_gap_temperature_factor_local(T, params.TcX, alphaGap);
    Fy = ab_gap_temperature_factor_local(T, params.TcY, alphaGap);
    if isfield(params, 'gapClassExponentX')
        Fx = Fx .^ params.gapClassExponentX;
    end
    if isfield(params, 'gapClassExponentY')
        Fy = Fy .^ params.gapClassExponentY;
    end
    IcEffX = params.IcX .* Fx;
    IcEffY = params.IcY .* Fy;
end

if isfield(params, 'dI_fracX')
    dIfracX = params.dI_fracX;
else
    dIfracX = spec.solver.dI_frac .* ones(size(params.IcX));
end
if isfield(params, 'dI_fracY')
    dIfracY = params.dI_fracY;
else
    dIfracY = spec.solver.dI_frac .* ones(size(params.IcY));
end

if isfield(params, 'IcBroadeningX')
    broadX = params.IcBroadeningX;
else
    broadX = zeros(size(params.IcX));
end
if isfield(params, 'IcBroadeningY')
    broadY = params.IcBroadeningY;
else
    broadY = zeros(size(params.IcY));
end

dIx = max(dIfracX .* max(IcEffX, 1e-14), broadX);
dIy = max(dIfracY .* max(IcEffY, 1e-14), broadY);
dIx = max(dIx, 1e-14);
dIy = max(dIy, 1e-14);

S_Ix = 1 ./ (1 + exp(-(IabsX - IcEffX) ./ dIx));
S_Iy = 1 ./ (1 + exp(-(IabsY - IcEffY) ./ dIy));

Sx = 1 - (1 - S_Tx) .* (1 - S_Ix);
Sy = 1 - (1 - S_Ty) .* (1 - S_Iy);

Rx = params.Rfloor + params.RnX .* (params.fX + (1 - params.fX) .* Sx);
Ry = params.Rfloor + params.RnY .* (params.fY + (1 - params.fY) .* Sy);

Rx(params.RnX <= 0) = Inf;
Ry(params.RnY <= 0) = Inf;

end

function F = ab_gap_temperature_factor_local(T, Tc, alphaGap)
%AB_GAP_TEMPERATURE_FACTOR_LOCAL Normalized AB-like Ic(T)/Ic(0).
%
% Uses the standard BCS interpolation Delta(T)/Delta0 ~=
% tanh[1.74 sqrt(Tc/T - 1)] below Tc and an AB-like tanh[Delta(T)/2kBT]
% factor.  The result is dimensionless and intentionally normalized to 1 at
% low temperature for use as an Ic suppression factor.

Tsafe = max(T, 1e-6);
TcSafe = max(Tc, eps);
below = T < Tc & Tc > 0;

deltaNorm = zeros(size(Tc));
tau = Tsafe ./ TcSafe;
deltaNorm(below) = tanh(1.74 .* sqrt(max(1 ./ tau(below) - 1, 0)));

abArg = 0.25 .* alphaGap .* deltaNorm .* (TcSafe ./ Tsafe);
F = deltaNorm .* tanh(abArg);
F(~below) = 0;
F(~isfinite(F)) = 0;
F = min(1, max(0, F));

end
