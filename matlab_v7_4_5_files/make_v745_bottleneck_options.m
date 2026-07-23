function opts = make_v745_bottleneck_options()
%MAKE_V745_BOTTLENECK_OPTIONS Physically constrained bottleneck sweep.
%
% v7.4.5 keeps the v7.4.3 discipline of varying only W_ij, interpreted as
% local weak-link transparency / conductance ratio G_weak/G_bulk, but it
% makes the W_ij topology more physical: boundary/crack lanes, contact
% relaxation halos, probe current-crowding zones, tear-like bottlenecks, and
% anisotropic transparency are tested as explicit named mechanisms.

opts = struct();
opts.version = 'v7.4.5';
opts.device = 'AS006';

% Compact two-variable sweep: gammaW and pW.  These are intentionally not a
% broad fit; they test whether stronger, spatially constrained bottlenecks
% can reproduce the AS006 magnetic-field dV/dI features.
opts.gammaW_values = [0.003, 0.010, 0.030];
opts.pW_values = [0.03, 0.08];

% Weak-link spatial score used to construct the full W_ij field.
opts.boundaryLaneWidth_um = 0.55;
opts.boundaryWeight = 1.30;
opts.coveredEdgeWeight = 0.35;
opts.contactWeight = 0.75;
opts.currentCrowdingWeight = 1.10;
opts.hotspotWeight = 0.40;
opts.hotspotRadius_um = 0.35;
opts.numHotspots = 3;
opts.seedOffset = 7440;

% Physical bottleneck-specific geometry controls.
opts.tearLaneWidth_um = 0.38;
opts.tearWeight = 1.60;
opts.tearX0_um = 0.0;
opts.tearHalfLength_um = 3.2;
opts.contactHaloRadius_um = 0.85;
opts.currentCrowdingRadius_um = 0.90;
opts.edgeCrowdingWidth_um = 0.45;
opts.anisotropyFactorX = 1.00;
opts.anisotropyFactorY = 0.30;

% Screening grid: smaller than the final map, but not a separate physics
% shortcut.  The best case is re-run on the full experimental grid.
opts.screenBCount = 9;
opts.runFullFieldMaps = false;
opts.fullMapCalibrationModes = ["shape","conductance"];
opts.bestMapBCount = 41;
opts.bestMapICount = 81;

% If the screening score CSV already exists with the expected number of
% rows, reuse it.  This is useful when a run completed the expensive
% screening loop but failed later during figure export.
opts.reuseExistingScreeningTable = true;

% W-only transport convention.  The weak-link transparency changes normal
% conductance and critical current together; Tc and residual fields are not
% changed by this ablation.
opts.applyWtoRn = true;
opts.applyWtoIc = true;

% Scoring conventions.
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
