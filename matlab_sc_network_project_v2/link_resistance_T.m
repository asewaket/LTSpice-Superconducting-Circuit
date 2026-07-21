function [Rx, Ry] = link_resistance_T(params, spec, T)
%LINK_RESISTANCE_T Temperature-only smooth local resistance.

Sx = 1 ./ (1 + exp(-(T - params.TcX) ./ spec.solver.dT));
Sy = 1 ./ (1 + exp(-(T - params.TcY) ./ spec.solver.dT));

Rx = params.Rfloor + params.RnX .* (params.fX + (1 - params.fX) .* Sx);
Ry = params.Rfloor + params.RnY .* (params.fY + (1 - params.fY) .* Sy);

Rx(params.RnX <= 0) = Inf;
Ry(params.RnY <= 0) = Inf;

end

