function opts = make_raman_robustness_options()
%MAKE_RAMAN_ROBUSTNESS_OPTIONS Defaults for v6.2 robustness analysis.
%
% v6.2 asks whether the v6.1 Raman proxy conclusions are stable across
% disorder realizations and across families of related variants.

opts = struct();

opts.variantOutputSubdir = fullfile('outputs', 'raman_variant_sensitivity');
opts.robustnessOutputSubdir = fullfile('outputs', 'raman_variant_robustness');

opts.devices = {'AS002','AS005','AS006'};
opts.topNPerDevice = 4;
opts.topFractionN = 20;
opts.Nens = 12;

opts.T_vec = linspace(0.05, 2.20, 120);
opts.Iprobe = 1e-8;

% Geometry-only rows in the v6.1 table are repeated because alpha = 0 is
% sampled for each Raman variant. Use median as the default robust baseline.
opts.geometryBaselineStatistic = 'median'; % 'median', 'mean', 'best'

end
