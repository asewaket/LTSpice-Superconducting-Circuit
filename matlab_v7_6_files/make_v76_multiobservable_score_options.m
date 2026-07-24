function opts = make_v76_multiobservable_score_options()
%MAKE_V76_MULTIOBSERVABLE_SCORE_OPTIONS Defaults for v7.6 scoring.
%
% v7.6 deliberately changes the judging workflow, not the physical model.
% The aim is to prevent a candidate model from "winning" by matching only a
% single global R(T) curve while missing probe asymmetry, onset, residual
% resistance, or nonlinear validation data.

opts = struct();

opts.version = 'v7.6';
opts.description = 'multi-observable scoring and ablation-significance scaffold';

% Probe-pair labels used throughout the MATLAB network model.
opts.probePairs = {'top_4_10','bottom_3_9'};

% Primary R(T) objective.  The default uses independently normalized curves
% because most previous figures compare normalized transition shape rather
% than claiming absolute RN prediction.
opts.primary = struct();
opts.primary.normalizeIndependent = true;
opts.primary.highFrac = 0.12;
opts.primary.nHighDefault = 5;
opts.primary.sigmaFloor = 0.015;       % normalized R/RN floor
opts.primary.sigmaFraction = 0.010;    % fractional digitization/readout term
opts.primary.minPointsPerPair = 6;

% Secondary metric penalties.  These are compact, interpretable checks of
% transition features rather than a second full curve fit.
opts.secondary = struct();
opts.secondary.enabled = true;
opts.secondary.weights = struct( ...
    'Tonset_K', 1.0, ...
    'rLow', 1.0, ...
    'width90_10_K', 0.8);
opts.secondary.scales = struct( ...
    'Tonset_K', 0.10, ...       % K
    'rLow', 0.10, ...           % normalized resistance
    'width90_10_K', 0.15);      % K

% Probe-asymmetry metric:
% A_probe = |R_4-10 - R_3-9| / ((R_4-10 + R_3-9)/2).
% Pair-normalized A_probe is the safe default until absolute pair RN
% calibrations are equally trusted for every device.
opts.asymmetry = struct();
opts.asymmetry.enabled = true;
opts.asymmetry.usePairNormalized = true;
opts.asymmetry.sigmaFloor = 0.030;
opts.asymmetry.weight = 1.0;

% Nonlinear validation is optional and intentionally linecut-based.  Full
% magnetic-field rasters are not part of the core objective until a
% phase-aware field model exists.
opts.nonlinear = struct();
opts.nonlinear.enabled = true;
opts.nonlinear.includeFullFieldRaster = false;
opts.nonlinear.sigmaFloor = 0.050;     % normalized dV/dI/RN
opts.nonlinear.weight = 0.7;

% Overall score weights.  These combine already dimensionless RMS penalties.
opts.weights = struct();
opts.weights.primaryRT = 1.0;
opts.weights.secondaryMetrics = 0.6;
opts.weights.probeAsymmetry = 0.6;
opts.weights.nonlinearLinecuts = 0.4;
opts.weights.complexityPenalty = 1.0;

% Complexity / model-comparison bookkeeping.  This does not force a final
% conclusion; it exports AICc/BIC-ready quantities and a small optional
% normalized parameter-count penalty.
opts.complexity = struct();
opts.complexity.enabled = true;
opts.complexity.parameterPenaltyPerFreeParameter = 0.003;
opts.complexity.seedSigmaFloor = 0.020;
opts.complexity.computeInformationCriteria = true;

% Metric extraction options reused from the v7.1 library where available.
if exist('make_metric_options', 'file') == 2
    opts.metricOptions = make_metric_options();
else
    opts.metricOptions = struct( ...
        'smoothingWindow', 1, ...
        'highFrac', 0.12, ...
        'lowFrac', 0.12, ...
        'nHighDefault', 5, ...
        'nLowDefault', 5, ...
        'onsetThreshold', 0.98, ...
        'minConsecutiveBelow', 2, ...
        'widthHighFraction', 0.90, ...
        'widthLowFraction', 0.10);
end

end
