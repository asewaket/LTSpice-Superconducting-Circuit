function params = assign_link_parameters(net, spec, model, seed, mode)
%ASSIGN_LINK_PARAMETERS Generate local Rn/Tc/Ic from shared eta rules.
%
% v2 intentionally avoids independent device-by-device parameter priors.
% Each link is generated from the mechanical proxy eta and the same shared
% constitutive parameters in make_shared_model_params.m.

rng(seed);

if nargin < 5
    mode = 'full';
end

szX = size(net.link.regionX);
szY = size(net.link.regionY);

params = struct();
params.RnX = zeros(szX);
params.TcX = zeros(szX);
params.IcX = zeros(szX);
params.fX = zeros(szX);
params.RnY = zeros(szY);
params.TcY = zeros(szY);
params.IcY = zeros(szY);
params.fY = zeros(szY);

params.Rfloor = spec.solver.Rfloor;
params.modelMode = mode;

params = fill_link_family(params, 'X', net.link.regionX, net.link.etaX, spec, model, 1.0);
params = fill_link_family(params, 'Y', net.link.regionY, net.link.etaY, spec, model, model.Rn.transverseMultiplier);

% Cracked full-coverage devices get extra weak/bottleneck links in the crack
% region. This changes connectivity without deleting the MoTe2 channel.
if strcmp(spec.geometryClass, 'cracked_full') && ~strcmp(mode, 'crack_off')
    crackX = net.link.regionX == spec.region.crack;
    crackY = net.link.regionY == spec.region.crack;
    params.RnX(crackX) = params.RnX(crackX) * model.crack.weakLinkMultiplier;
    params.RnY(crackY) = params.RnY(crackY) * model.crack.weakLinkMultiplier;
end

if strcmp(mode, 'weak_transverse')
    params.RnY(net.link.activeY) = params.RnY(net.link.activeY) * 1e6;
end

end

function params = fill_link_family(params, family, region, eta, spec, model, rnMultiplier)

valid = region > 0;

Rn = zeros(size(region));
Tc = zeros(size(region));
Ic = zeros(size(region));
f = zeros(size(region));

H = eta_mapping(eta, model);

corrCells = max(1, round(model.Tc.disorderCorrelation_um / spec.grid.dx_um));
tcDisorder = model.Tc.disorderSigma_K * smooth_random_field(randn(size(region)), corrCells);

Rn(valid) = model.Rn.baseMean_ohm * rnMultiplier .* ...
    (1 + model.Rn.etaCoeff .* eta(valid)) .* ...
    exp(model.Rn.sigmaFrac .* randn(nnz(valid),1));

Tc(valid) = model.Tc.TcMin_K + model.Tc.TcSpan_K .* H(valid) + tcDisorder(valid);
Tc(valid) = max(Tc(valid), 0.005);

Ic(valid) = model.Ic.IcMin_A + model.Ic.IcSpan_A .* H(valid);
Ic(valid) = Ic(valid) .* exp(model.Ic.disorderSigmaFrac .* randn(nnz(valid),1));
Ic(valid) = max(Ic(valid), 1e-12);

f(valid) = model.residual.fHigh - (model.residual.fHigh - model.residual.fLow) .* H(valid);
f(valid) = min(model.residual.maxValue, max(model.residual.minValue, f(valid)));

switch family
    case 'X'
        params.RnX = Rn;
        params.TcX = Tc;
        params.IcX = Ic;
        params.fX = f;
    case 'Y'
        params.RnY = Rn;
        params.TcY = Tc;
        params.IcY = Ic;
        params.fY = f;
end

end

function H = eta_mapping(eta, model)

switch model.Tc.mapping
    case 'linear'
        H = eta;
    case 'sigmoid'
        H = 1 ./ (1 + exp(-(eta - model.Tc.eta0) ./ model.Tc.sigmoidWidth));
    case 'threshold'
        H = max(0, eta - model.Tc.threshold) ./ max(1e-12, 1 - model.Tc.threshold);
    otherwise
        error('Unknown Tc mapping "%s".', model.Tc.mapping);
end

H = min(1, max(0, H));

end
