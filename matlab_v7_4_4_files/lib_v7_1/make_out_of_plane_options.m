function opts = make_out_of_plane_options()
%MAKE_OUT_OF_PLANE_OPTIONS Defaults for v6.3 A4g/out-of-plane tests.

opts = make_raman_variant_options();

opts.devices = {'AS002','AS005','AS006'};

% Mode-ablation set. all_modes and all_with_A4g are equivalent after A4g is
% present for all three devices; both labels are kept so figures read clearly.
opts.modeSet = {'A4g_only','in_plane_only','all_with_A4g', ...
    'without_A4g','without_A5g','without_B2g', ...
    'A5g_only','B2g_only'};

opts.referenceSet = {'first_point','scan_mean'};
opts.representationSet = {'abs','signed_positive','signed_negative'};
opts.couplingSet = {'all','Tc_residual_only'};
opts.alphaVec = 1.0;

opts.T_vec = linspace(0.05, 2.20, 120);
opts.Iprobe = 1e-8;

end
