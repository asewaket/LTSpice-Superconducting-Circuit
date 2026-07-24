function opts = make_sensitivity_options()
%MAKE_SENSITIVITY_OPTIONS Defaults for v4 proxy/parameter sensitivity sweep.

opts = struct();

opts.Nsweep = 25;
opts.seed = 7401;
opts.T_vec = linspace(0.05, 2.20, 120);
opts.Iprobe = 1e-8;

% Run a representative realization for speed. Increase or adapt later if
% ensemble-level sensitivity is needed.
opts.useEnsemble = false;

% Uniform random ranges for shared proxy/constitutive parameters.
opts.ranges.coveredWeight = [0.10 0.55];
opts.ranges.boundaryWeight = [0.35 1.05];
opts.ranges.crackWeight = [0.50 1.60];
opts.ranges.edgeWeight = [0.00 0.30];
opts.ranges.TcSpan_K = [0.50 1.80];
opts.ranges.eta0 = [0.35 0.75];
opts.ranges.sigmoidWidth = [0.07 0.22];
opts.ranges.residualLow = [0.03 0.25];
opts.ranges.residualHigh = [0.55 0.90];

% Metric score scales. These put temperature errors and normalized-resistance
% errors on roughly comparable scales for ranking, not formal statistics.
opts.scoreScale.rLow = 0.20;
opts.scoreScale.suppressionFrac = 0.20;
opts.scoreScale.Tonset_K = 0.50;
opts.scoreScale.Tmid_K = 0.35;
opts.scoreScale.width90_10_K = 0.50;

opts.deviceNames = {'AS001','AS002','AS003','AS004','AS005','AS006'};

end
