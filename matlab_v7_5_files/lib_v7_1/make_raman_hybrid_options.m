function opts = make_raman_hybrid_options()
%MAKE_RAMAN_HYBRID_OPTIONS Defaults for v6 Raman-informed transport tests.

opts = struct();

% The conservative first pass uses magnitude, not sign, because the Raman
% modes have not yet been converted into calibrated strain components.
opts.valueColumn = 'abs_shift_proxy';

% Gaussian interpolation around registered line scans.
opts.sigma_um = 0.85;
opts.maxDistance_um = 2.55;
opts.minCoverageNorm = 0.08;
opts.supportPower = 1.0;

% 'all' uses the continuous interpolated map; 'supported_only' falls back to
% geometry-only outside the support-masked display region.
opts.useDisplayMap = 'all';

% Keep the Raman proxy as spatial heterogeneity rather than a new arbitrary
% device-level amplitude. The default scales the 0--1 Raman map to the maximum
% geometry-only eta in the same device. Use 'unit' only for stress-testing.
opts.ramanScaleMode = 'match_geometry_max'; % 'match_geometry_max', 'unit'

% Alpha values for geometry/Raman mixing.
opts.alphaVec = [0 0.25 0.50 0.75 1.00];

% Devices with registered Raman data in the current project.
opts.devices = {'AS002','AS005','AS006'};

% Keep the first v6 transport sweep moderate; increase if final ensemble
% robustness is needed.
opts.Nens = 4;
opts.T_vec = linspace(0.05, 2.20, 160);
opts.Iprobe = 1e-8;

% Weighted dimensionless score for model-vs-experiment metric comparison.
opts.scoreWeights.rLow = 1.0;
opts.scoreWeights.Tonset = 0.8;
opts.scoreWeights.Tmid = 0.8;
opts.scoreWeights.width = 1.0;
opts.scale.T_K = 1.0;

end
