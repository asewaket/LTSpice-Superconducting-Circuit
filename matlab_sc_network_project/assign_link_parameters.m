function params = assign_link_parameters(net, spec, seed)
%ASSIGN_LINK_PARAMETERS Draw local Rn/Tc/Ic triples for each valid link.

rng(seed);

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

params = fill_link_family(params, 'X', net.link.regionX, spec, 1.0);
params = fill_link_family(params, 'Y', net.link.regionY, spec, spec.param.transverseRnMultiplier);

% Cracked full-coverage devices get extra weak/bottleneck links in the crack
% region. This changes connectivity without deleting the MoTe2 channel.
if strcmp(spec.geometryClass, 'cracked_full')
    crackX = net.link.regionX == spec.region.crack;
    crackY = net.link.regionY == spec.region.crack;
    params.RnX(crackX) = params.RnX(crackX) * spec.crack.weakLinkMultiplier;
    params.RnY(crackY) = params.RnY(crackY) * spec.crack.weakLinkMultiplier;
end

end

function params = fill_link_family(params, family, region, spec, rnMultiplier)

valid = region > 0;

Rn = zeros(size(region));
Tc = zeros(size(region));
Ic = zeros(size(region));
f = zeros(size(region));

corrCells = max(1, round(spec.param.domainCorrelation_um / spec.grid.dx_um));
domainField = smooth_random_field(randn(size(region)), corrCells);
domainScore = 1 ./ (1 + exp(-domainField));

for r = 1:numel(spec.regionNames)
    mask = valid & region == r;
    if ~any(mask(:))
        continue;
    end

    rnMean = spec.param.RnMean(r) * rnMultiplier;
    Rn(mask) = rnMean .* exp(spec.param.RnSigmaFrac .* randn(nnz(mask),1));

    pEnh = spec.param.enhancedProb(r);
    enhanced = mask & domainScore > (1 - pEnh);

    Tc(mask) = spec.param.baseTcMean + spec.param.baseTcSigma .* randn(nnz(mask),1);
    Tc(enhanced) = spec.param.enhancedTcMean(r) + spec.param.enhancedTcSigma(r) .* randn(nnz(enhanced),1);
    Tc(mask) = max(Tc(mask), 0.005);

    Ic(mask) = spec.param.IcMean(r) .* exp(spec.param.IcSigmaFrac .* randn(nnz(mask),1));
    Ic(mask) = max(Ic(mask), 1e-12);

    f(mask) = spec.param.residualFraction(r);
end

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

