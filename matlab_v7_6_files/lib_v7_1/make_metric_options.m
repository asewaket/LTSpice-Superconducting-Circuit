function opts = make_metric_options()
%MAKE_METRIC_OPTIONS Definitions for normalized R(T) comparison metrics.

opts = struct();

% R_N and R_low averaging windows. The effective number of points is the
% larger of the absolute count and the fractional count, capped by data length.
opts.nHighDefault = 10;
opts.nLowDefault = 5;
opts.highFrac = 0.20;
opts.lowFrac = 0.10;

% Onset: highest temperature where normalized resistance drops below this
% fraction of R_N. Requiring consecutive points reduces noise sensitivity.
opts.onsetThreshold = 0.98;
opts.minConsecutiveBelow = 2;

% Transition-width thresholds are defined relative to the observed suppression:
% r_p = r_low + p*(1-r_low). T90 is near onset; T10 is near low T.
opts.widthHighFraction = 0.90;
opts.widthLowFraction = 0.10;

% Smoothing is off by default; it can be enabled later for noisy traces.
opts.smoothingWindow = 1;

end
