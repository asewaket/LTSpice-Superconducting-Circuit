function params = assign_link_parameters_coupled(netGeometry, netHybrid, spec, model, seed, couplingMode)
%ASSIGN_LINK_PARAMETERS_COUPLED Mix geometry and Raman-hybrid parameter sets.
%
% Two parameter sets are generated with the same random seed so that the
% comparison primarily reflects eta/coupling changes, not different disorder.

if nargin < 6 || isempty(couplingMode)
    couplingMode = 'all';
end

pGeo = assign_link_parameters(netGeometry, spec, model, seed, 'full');
pHyb = assign_link_parameters(netHybrid, spec, model, seed, 'full');
params = pGeo;
params.couplingMode = couplingMode;

switch char(couplingMode)
    case 'all'
        params = pHyb;
        params.couplingMode = couplingMode;

    case 'Tc_residual_only'
        params.TcX = pHyb.TcX;
        params.TcY = pHyb.TcY;
        params.fX = pHyb.fX;
        params.fY = pHyb.fY;

    case 'Tc_only'
        params.TcX = pHyb.TcX;
        params.TcY = pHyb.TcY;

    case 'residual_only'
        params.fX = pHyb.fX;
        params.fY = pHyb.fY;

    case 'Ic_only'
        params.IcX = pHyb.IcX;
        params.IcY = pHyb.IcY;

    case 'Rn_only'
        params.RnX = pHyb.RnX;
        params.RnY = pHyb.RnY;

    case 'Tc_Ic'
        params.TcX = pHyb.TcX;
        params.TcY = pHyb.TcY;
        params.fX = pHyb.fX;
        params.fY = pHyb.fY;
        params.IcX = pHyb.IcX;
        params.IcY = pHyb.IcY;

    otherwise
        error('Unknown Raman coupling mode "%s".', couplingMode);
end

end
