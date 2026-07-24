function variantOpts = get_v64_best_variant_options(deviceName)
%GET_V64_BEST_VARIANT_OPTIONS Best compact Raman variants carried into v6.4.
%
% These choices are not treated as final physical truth; they are the best
% working hypotheses from v6.3 used to keep the v6.4 domain/percolation test
% compact and interpretable.

deviceName = upper(char(deviceName));
base = make_raman_variant_options();

variantOpts = struct();
variantOpts.alpha = 1.0;
variantOpts.sigma_um = base.sigma_um;
variantOpts.maxDistance_um = base.maxDistance_um;
variantOpts.minCoverageNorm = base.minCoverageNorm;
variantOpts.supportPower = base.supportPower;
variantOpts.useDisplayMap = base.useDisplayMap;
variantOpts.ramanScaleMode = base.ramanScaleMode;

switch deviceName
    case 'AS002'
        variantOpts.modeName = 'without_A4g';
        variantOpts.referenceName = 'scan_mean';
        variantOpts.representationName = 'abs';
        variantOpts.couplingMode = 'all';

    case 'AS005'
        variantOpts.modeName = 'without_A5g';
        variantOpts.referenceName = 'scan_mean';
        variantOpts.representationName = 'signed_positive';
        variantOpts.couplingMode = 'Tc_residual_only';

    case 'AS006'
        variantOpts.modeName = 'without_A4g';
        variantOpts.referenceName = 'first_point';
        variantOpts.representationName = 'signed_negative';
        variantOpts.couplingMode = 'all';

    otherwise
        error('No v6.4 Raman-variant hypothesis is defined for %s.', deviceName);
end

end
