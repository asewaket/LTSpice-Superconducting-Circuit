function [Rx, Ry] = link_resistance_TI_v741(params, spec, T, IabsX, IabsY)
%LINK_RESISTANCE_TI_V741 Current-dependent resistance with weak-link widths.

S_Tx = 1 ./ (1 + exp(-(T - params.TcX) ./ spec.solver.dT));
S_Ty = 1 ./ (1 + exp(-(T - params.TcY) ./ spec.solver.dT));

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

dIx = max(dIfracX .* params.IcX, broadX);
dIy = max(dIfracY .* params.IcY, broadY);
dIx = max(dIx, 1e-14);
dIy = max(dIy, 1e-14);

S_Ix = 1 ./ (1 + exp(-(IabsX - params.IcX) ./ dIx));
S_Iy = 1 ./ (1 + exp(-(IabsY - params.IcY) ./ dIy));

Sx = 1 - (1 - S_Tx) .* (1 - S_Ix);
Sy = 1 - (1 - S_Ty) .* (1 - S_Iy);

Rx = params.Rfloor + params.RnX .* (params.fX + (1 - params.fX) .* Sx);
Ry = params.Rfloor + params.RnY .* (params.fY + (1 - params.fY) .* Sy);

Rx(params.RnX <= 0) = Inf;
Ry(params.RnY <= 0) = Inf;

end
