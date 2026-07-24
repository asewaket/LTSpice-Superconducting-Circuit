function paramsB = apply_v73_field_to_params(params0, net, opts, B_T)
%APPLY_V73_FIELD_TO_PARAMS Return B-dependent local link parameters.
%
% Phenomenological model:
%   Bc2(x,y) = B0 + dB * eta(x,y)
%   Tc(B)   = Tc0 * max(floor, 1 - (|B|/Bc2)^alpha)
%   Ic(B)   = Ic0 * max(floor, [1 - (|B|/Bc2)^beta]^gamma)
%   f(B)    = f0 + fluxFlowFraction * (1-f0)
%
% The field is out of plane for the present AS006 scaffold.

paramsB = params0;

etaX = link_eta_x(net);
etaY = link_eta_y(net);

Bc2X = local_b_scale(etaX, opts);
Bc2Y = local_b_scale(etaY, opts);

absB = abs(B_T);
[tcFactorX, icFactorX, fluxX] = field_factors(absB, Bc2X, opts);
[tcFactorY, icFactorY, fluxY] = field_factors(absB, Bc2Y, opts);

paramsB.TcX = params0.TcX .* tcFactorX;
paramsB.TcY = params0.TcY .* tcFactorY;
paramsB.IcX = params0.IcX .* icFactorX;
paramsB.IcY = params0.IcY .* icFactorY;

paramsB.fX = min(1, params0.fX + (1 - params0.fX) .* fluxX);
paramsB.fY = min(1, params0.fY + (1 - params0.fY) .* fluxY);

paramsB.B_T = B_T;
paramsB.Bc2X_T = Bc2X;
paramsB.Bc2Y_T = Bc2Y;

end

function etaX = link_eta_x(net)

eta = net.etaNode;
etaX = 0.5 .* (eta(:,1:end-1) + eta(:,2:end));
etaX(~net.link.activeX) = NaN;

end

function etaY = link_eta_y(net)

eta = net.etaNode;
etaY = 0.5 .* (eta(1:end-1,:) + eta(2:end,:));
etaY(~net.link.activeY) = NaN;

end

function Bc2 = local_b_scale(eta, opts)

etaSafe = eta;
etaSafe(~isfinite(etaSafe)) = 0;
etaSafe = max(0, min(1, etaSafe));
weightedEta = opts.localBc2.etaWeight .* etaSafe + ...
    (1 - opts.localBc2.etaWeight) .* mean(etaSafe(:), 'omitnan');
Bc2 = opts.localBc2.base_T + opts.localBc2.span_T .* weightedEta;
Bc2 = max(opts.localBc2.floor_T, Bc2);

end

function [tcFactor, icFactor, fluxFraction] = field_factors(absB, Bc2, opts)

b = absB ./ max(Bc2, eps);

tcFactor = 1 - b .^ opts.suppression.alphaTc;
tcFactor = max(opts.suppression.minTcFactor, tcFactor);

icCore = max(0, 1 - b .^ opts.suppression.betaIc);
icFactor = icCore .^ opts.suppression.gammaIc;
icFactor = max(opts.suppression.minIcFactor, icFactor);

fluxFraction = opts.fluxFlow.maxFraction .* min(1, b .^ opts.fluxFlow.exponent);

end
