function model = make_shared_model_params()
%MAKE_SHARED_MODEL_PARAMS Shared constitutive rules for v3.
%
% Device-specific inputs should mostly enter through geometry, film force,
% crack/stressor masks, and normal-state resistance scaling. This file holds
% the low-dimensional shared rules that map a mechanical proxy eta to local
% superconducting-network parameters.

model = struct();

% Mechanical-proxy construction.
model.proxy.forceScale_Npm = 40;          % maps |Ff| to a 0--1 amplitude
model.proxy.fullCoverageWeight = 0.22;    % full uniform coverage alone is modest
model.proxy.coveredWeight = 0.34;         % broad covered-region contribution
model.proxy.boundaryWeight = 0.78;        % half-coverage boundary enhancement
model.proxy.crackWeight = 1.15;           % crack-adjacent enhancement
model.proxy.edgeWeight = 0.12;            % physical edge/interface contribution
model.proxy.smooth_um = 0.50;
model.proxy.clipMin = 0;
model.proxy.clipMax = 1;

% Shared Tc mapping: Tc = TcMin + TcSpan * H(eta) + correlated disorder.
model.Tc.TcMin_K = 0.055;
model.Tc.TcSpan_K = 1.55;
model.Tc.mapping = 'sigmoid';             % 'linear', 'sigmoid', 'threshold'
model.Tc.eta0 = 0.52;
model.Tc.sigmoidWidth = 0.12;
model.Tc.threshold = 0.25;
model.Tc.disorderSigma_K = 0.035;
model.Tc.disorderCorrelation_um = 0.70;

% Shared Ic mapping.
model.Ic.IcMin_A = 0.05e-6;
model.Ic.IcSpan_A = 1.45e-6;
model.Ic.disorderSigmaFrac = 0.45;

% Shared normal and residual-resistance mapping.
model.Rn.baseMean_ohm = 1.0;
model.Rn.sigmaFrac = 0.18;
model.Rn.transverseMultiplier = 1.15;
model.Rn.etaCoeff = 0.10;

% Low-temperature residual fraction. This keeps incomplete percolation and
% finite weak links in the phenomenology.
model.residual.fHigh = 0.72;
model.residual.fLow = 0.08;
model.residual.minValue = 0.04;
model.residual.maxValue = 0.90;

% Crack weak links modify Rn after the shared eta mapping.
model.crack.weakLinkMultiplier = 7.0;

% Ensemble defaults.
model.ensemble.N = 6;
model.ensemble.seed0 = 4100;

% Metrics defaults.
model.metrics.onsetDropFrac = 0.02;
model.metrics.lowTempCount = 5;
model.metrics.highTempCount = 10;
model.metrics.percResistanceFraction = 0.25;

end
