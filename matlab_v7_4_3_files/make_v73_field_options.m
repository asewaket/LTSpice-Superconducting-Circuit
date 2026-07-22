function opts = make_v73_field_options(expField)
%MAKE_V73_FIELD_OPTIONS Options for v7.3 magnetic-field scaffold.

if nargin < 1
    expField = struct('available', false);
end

opts = struct();
opts.version = 'v7.3';

if isfield(expField, 'available') && expField.available
    opts.B_vec_T = linspace(min(expField.B_T), max(expField.B_T), 121);
    opts.I_vec_A = linspace(min(expField.I_A), max(expField.I_A), 121);
    opts.T_K = expField.assumedTemperature_K;
else
    opts.B_vec_T = linspace(-0.05, 0.05, 121);
    opts.I_vec_A = linspace(-2.5e-6, 2.5e-6, 121);
    opts.T_K = 0.06;
end

opts.fieldDirection = 'out_of_plane';

% Phenomenological local field scale. This is deliberately modest because
% the first field scaffold is meant to test whether field-dependent local
% superconducting connectivity can reproduce the measured dV/dI(I,B)
% topology, not fit a microscopic Bc2.
opts.localBc2.base_T = 0.035;
opts.localBc2.span_T = 0.045;
opts.localBc2.etaWeight = 0.75;
opts.localBc2.floor_T = 0.008;

% Pair-breaking / critical-current suppression laws.
opts.suppression.alphaTc = 1.4;
opts.suppression.betaIc = 1.8;
opts.suppression.gammaIc = 1.0;
opts.suppression.minTcFactor = 0.05;
opts.suppression.minIcFactor = 0.03;

% Flux-flow-like residual resistance contribution. This increases the
% finite-resistance floor before a link is completely normal.
opts.fluxFlow.maxFraction = 0.35;
opts.fluxFlow.exponent = 1.2;

% Numerical derivative smoothing along current.
opts.smoothing.dVdI_currentWindow = 3;

opts.output.subdir = fullfile('outputs', 'v7_3_as006_field_maps');

end
