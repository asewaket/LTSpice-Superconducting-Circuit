function opts = make_raman_variant_options()
%MAKE_RAMAN_VARIANT_OPTIONS Defaults for v6.1 Raman representation tests.
%
% v6.1 is intentionally a controlled sensitivity test, not an unconstrained
% fit. It asks which Raman representation and which local-parameter coupling
% most improves normalized R(T).

opts = make_raman_hybrid_options();

opts.devices = {'AS002','AS005','AS006'};

% Keep the default run reasonably fast. Increase Nens after identifying
% promising variants.
opts.Nens = 1;
opts.T_vec = linspace(0.05, 2.20, 120);
opts.alphaVec = [0 0.50 1.00];

% Raman representation variants.
opts.modeSet = {'all_modes','A5g_only','B2g_only'};
opts.referenceSet = {'first_point','scan_mean'};
opts.representationSet = {'abs','signed_positive','signed_negative'};

% Coupling variants. For low-current R(T), Ic_only is expected to have little
% effect; keeping it is a useful null/control test.
opts.couplingSet = {'all','Tc_residual_only','Rn_only','Ic_only'};

% Combined score weighting.
opts.combinedScore.metricWeight = 1.0;
opts.combinedScore.shapeWeight = 1.0;

end
