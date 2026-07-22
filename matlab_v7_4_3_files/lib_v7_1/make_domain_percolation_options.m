function opts = make_domain_percolation_options()
%MAKE_DOMAIN_PERCOLATION_OPTIONS Defaults for v6.4 domain/percolation tests.
%
% v6.4 asks whether Raman-informed heterogeneity must nucleate connected
% enhanced superconducting domains, rather than only smoothly perturbing
% Tc/Ic/Rn/residual resistance link-by-link.

opts = make_out_of_plane_options();
opts.devices = {'AS002','AS005','AS006'};
opts.T_vec = linspace(0.05, 2.20, 120);
opts.Iprobe = 1e-8;

% Same combined score convention as v6.1--v6.3.
opts.combinedScore.metricWeight = 1.0;
opts.combinedScore.shapeWeight = 1.0;

% Percolation diagnostics: a link is counted as superconducting-like when
% its small-signal resistance is below this fraction of its normal Rn.
opts.percolation.scResistanceFraction = 0.20;
opts.percolation.snapshotT_K = [0.08 0.50 1.00 1.40];

% Compact domain-nucleation sweep. "smooth_only" reproduces the best v6.3
% Raman variant with no additional nucleated domains.
opts.domainVariants = make_domain_variant_list();

end

function variants = make_domain_variant_list()

base = struct();
base.enabled = false;
base.name = 'smooth_only';
base.description = 'v6.3 Raman variant; no thresholded superconducting domains';
base.etaThreshold = Inf;
base.etaWidth = 0.08;
base.maxProbability = 0;
base.supportFloor = 1.0;
base.correlation_um = 0.50;
base.TcBoost_K = 0;
base.IcMultiplier = 1;
base.residualMultiplier = 1;
base.RnMultiplier = 1;
base.crackEdgeWidth_um = 0.65;
base.crackProbabilityBoost = 0;
base.contactRelaxWidth_um = 0.65;
base.contactRelaxStrength = 0;

weak = base;
weak.enabled = true;
weak.name = 'weak_domains';
weak.description = 'sparse enhanced domains in high-proxy regions';
weak.etaThreshold = 0.62;
weak.etaWidth = 0.10;
weak.maxProbability = 0.45;
weak.supportFloor = 0.35;
weak.correlation_um = 0.65;
weak.TcBoost_K = 0.25;
weak.IcMultiplier = 2.0;
weak.residualMultiplier = 0.55;
weak.RnMultiplier = 0.90;
weak.crackProbabilityBoost = 0.10;
weak.contactRelaxStrength = 0.15;

medium = weak;
medium.name = 'medium_domains';
medium.description = 'moderately connected enhanced superconducting domains';
medium.etaThreshold = 0.54;
medium.maxProbability = 0.68;
medium.correlation_um = 0.85;
medium.TcBoost_K = 0.45;
medium.IcMultiplier = 3.5;
medium.residualMultiplier = 0.32;
medium.RnMultiplier = 0.80;
medium.crackProbabilityBoost = 0.18;
medium.contactRelaxStrength = 0.20;

strong = medium;
strong.name = 'strong_domains';
strong.description = 'aggressive percolating-domain hypothesis';
strong.etaThreshold = 0.47;
strong.maxProbability = 0.88;
strong.correlation_um = 1.05;
strong.TcBoost_K = 0.70;
strong.IcMultiplier = 6.0;
strong.residualMultiplier = 0.14;
strong.RnMultiplier = 0.70;
strong.crackProbabilityBoost = 0.25;
strong.contactRelaxStrength = 0.25;

crack = medium;
crack.name = 'crack_edge_domains';
crack.description = 'AS005-motivated crack-edge domain enhancement';
crack.etaThreshold = 0.56;
crack.maxProbability = 0.62;
crack.TcBoost_K = 0.50;
crack.IcMultiplier = 4.0;
crack.residualMultiplier = 0.25;
crack.crackEdgeWidth_um = 0.90;
crack.crackProbabilityBoost = 0.35;

variants = [base weak medium strong crack];

end
