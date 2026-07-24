function opts = make_v741_weaklink_options(spec)
%MAKE_V741_WEAKLINK_OPTIONS Josephson-like weak-link layer for v7.4.1.
%
% This layer is meant to address the dominant failure mode of v7.3: the
% simulated dV/dI(I,B) maps had field dependence but too little sharp
% low-bias current nonlinearity. Weak links suppress Ic locally and sharpen
% current switching along plausible bottleneck pathways.

if nargin < 1
    spec = struct('name', 'AS006');
end

opts = struct();
opts.version = 'v7.4.1';
opts.enabled = true;
opts.seedOffset = 7410;

% Strong weak-link subset. IcMultiplier is deliberately small because the
% total source-drain current divides among many links; local branch currents
% are much smaller than the externally applied current.
opts.IcMultiplier = 0.015;
opts.RnMultiplier = 1.8;
opts.residualMultiplier = 0.65;

% Sharper Josephson-like current switching than the ordinary network links.
opts.defaultSwitchWidthFrac = 0.08;
opts.weakSwitchWidthFrac = 0.012;

% A small absolute broadening avoids unrealistically singular switching and
% mimics an ensemble of microscopic critical currents within one coarse link.
opts.currentBroadening_A = 0.025e-6;

% Spatial selection for half-encapsulated AS006-like devices.
opts.boundaryWeight = 1.00;
opts.coveredEdgeWeight = 0.35;
opts.randomWeakFraction = 0.35;
opts.boundaryLaneWidth_um = 0.90;
opts.longitudinalCorrelation_um = 1.25;

% Extra weak spots make isolated bottlenecks rather than a fully uniform
% weak lane.
opts.numHotspots = 5;
opts.hotspotRadius_um = 0.65;
opts.hotspotWeight = 1.0;

% Hysteresis is not enabled in the first thesis-facing v7.4.1 run, because
% the available maps do not encode sweep direction in the imported grid.
% The field is retained here so a later v7.4.x runner can explicitly sweep
% up/down current with retrapping thresholds.
opts.hysteresis.enabled = false;
opts.hysteresis.retrapFraction = 0.45;

if isfield(spec, 'name') && ~strcmpi(spec.name, 'AS006')
    % Keep defaults but slightly reduce weak-link strength for devices not
    % yet tuned against field maps.
    opts.IcMultiplier = 0.05;
    opts.randomWeakFraction = 0.20;
end

end
