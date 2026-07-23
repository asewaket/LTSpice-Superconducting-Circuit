function opts = make_v746_gap_weaklink_options()
%MAKE_V746_GAP_WEAKLINK_OPTIONS Literature-constrained weak-link scaffold.
%
% v7.4.6 is not another broad W_ij fit.  It keeps the v7.4.5 controlled
% topology comparison, but computes the critical-current scale from local
% Tc and Rn using a BCS/Ambegaokar-Baratoff-inspired relation:
%
%   Delta_0 = 0.5 * alpha_gap * k_B * Tc
%   Ic_AB(0) = pi * Delta_0 / (2 e Rn)
%
% Weak-link classes then enter through a small transparency factor tau_k.
% This is still phenomenological, but now Ic is tied to local superconducting
% energy scale instead of being an independent random field.

opts = struct();
opts.version = 'v7.4.6';
opts.device = 'AS006';

% Literature-motivated gap ratio prior.  The default span roughly encodes
% 2Delta/kBTc ~= 3.7 +/- 0.4 without claiming a precise MoTe2 value.
opts.alphaGap.values = [3.3, 3.7, 4.1];
opts.alphaGap.priorMean = 3.7;
opts.alphaGap.priorSigma = 0.4;

% Compact transparency/fraction sweep.  gammaW is now interpreted as a
% class transparency tau_k rather than a freely fitted Ic multiplier.
opts.gammaW_values = [0.003, 0.010, 0.030];
opts.pW_values = [0.03, 0.08];

% Link-class switching widths: tunnel/crack links are sharpest; SNS-like
% constrictions are smoother.  These are normalized dI/Ic widths used by
% the existing nonlinear solver.
opts.defaultSwitchWidthFrac = 0.08;
opts.classSwitchWidth.bulk_sns = 0.08;
opts.classSwitchWidth.boundary_constriction = 0.035;
opts.classSwitchWidth.contact_relaxed = 0.050;
opts.classSwitchWidth.crack_tunnel = 0.012;
opts.classSwitchWidth.anisotropic = 0.030;
opts.currentBroadening_A = 0.015e-6;

% Spatial score used to construct the weak-link class masks.
opts.boundaryLaneWidth_um = 0.55;
opts.boundaryWeight = 1.30;
opts.coveredEdgeWeight = 0.35;
opts.contactWeight = 0.75;
opts.currentCrowdingWeight = 1.10;
opts.hotspotWeight = 0.40;
opts.hotspotRadius_um = 0.35;
opts.numHotspots = 3;
opts.seedOffset = 7460;

opts.tearLaneWidth_um = 0.38;
opts.tearWeight = 1.60;
opts.tearX0_um = 0.0;
opts.tearHalfLength_um = 3.2;
opts.contactHaloRadius_um = 0.85;
opts.currentCrowdingRadius_um = 0.90;
opts.edgeCrowdingWidth_um = 0.45;
opts.anisotropyFactorX = 1.00;
opts.anisotropyFactorY = 0.30;

% Keep screening deliberately small. Best-case maps are off by default so
% v7.4.6 does not surprise-run for hours.
opts.screenBCount = 9;
opts.runFullFieldMaps = false;
opts.fullMapCalibrationModes = ["shape","conductance"];
opts.reuseExistingScreeningTable = true;

% Transport convention.  Rn still carries transparency. Ic is replaced by
% the gap-derived AB-like value after Rn is updated, so do not also multiply
% Ic by W a second time.
opts.applyWtoRn = true;
opts.applyGapDerivedIc = true;

opts.shapeScore = make_v742_feature_score_options_local();
opts.conductanceScore = opts.shapeScore;

end

function scoreOpts = make_v742_feature_score_options_local()

scoreOpts = struct();
scoreOpts.lowBiasWindow_A = 0.35e-6;
scoreOpts.weights.fullMap = 0.20;
scoreOpts.weights.lowBiasMap = 0.35;
scoreOpts.weights.zeroBiasField = 0.25;
scoreOpts.weights.topBottomAsymmetry = 0.20;

end
