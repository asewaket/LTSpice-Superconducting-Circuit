function [Rx, Ry] = link_resistance_TI(params, spec, T, IabsX, IabsY)
%LINK_RESISTANCE_TI Temperature- and current-dependent link resistance.

S_Tx = 1 ./ (1 + exp(-(T - params.TcX) ./ spec.solver.dT));
S_Ty = 1 ./ (1 + exp(-(T - params.TcY) ./ spec.solver.dT));

dIx = spec.solver.dI_frac .* params.IcX;
dIy = spec.solver.dI_frac .* params.IcY;

S_Ix = 1 ./ (1 + exp(-(IabsX - params.IcX) ./ dIx));
S_Iy = 1 ./ (1 + exp(-(IabsY - params.IcY) ./ dIy));

Sx = 1 - (1 - S_Tx) .* (1 - S_Ix);
Sy = 1 - (1 - S_Ty) .* (1 - S_Iy);

Rx = params.Rfloor + params.RnX .* (params.fX + (1 - params.fX) .* Sx);
Ry = params.Rfloor + params.RnY .* (params.fY + (1 - params.fY) .* Sy);

Rx(params.RnX <= 0) = Inf;
Ry(params.RnY <= 0) = Inf;

end

