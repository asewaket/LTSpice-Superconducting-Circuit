function opts = make_v743_wij_ablation_options()
%MAKE_V743_WIJ_ABLATION_OPTIONS Controlled weak-link transparency sweep.
%
% v7.4.3 intentionally varies only W_ij, interpreted as a local weak-link
% transparency / conductance ratio G_weak/G_bulk.  The same base geometry,
% PDE/Raman proxy, Tc field, disorder realization, field grid, and probe
% mapping are reused for every case.

opts = struct();
opts.version = 'v7.4.3';
opts.device = 'AS006';

% Compact two-variable sweep: gammaW and pW.
opts.gammaW_values = [0.003, 0.010, 0.030, 0.100];
opts.pW_values = [0.04, 0.10];

% Weak-link spatial score used to construct the full W_ij field.
opts.boundaryLaneWidth_um = 0.75;
opts.boundaryWeight = 1.00;
opts.coveredEdgeWeight = 0.25;
opts.contactWeight = 0.40;
opts.hotspotWeight = 0.65;
opts.hotspotRadius_um = 0.45;
opts.numHotspots = 4;
opts.seedOffset = 7430;

% Screening grid: smaller than the final map, but not a separate physics
% shortcut.  The best case is re-run on the full experimental grid.
opts.screenBCount = 9;

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
