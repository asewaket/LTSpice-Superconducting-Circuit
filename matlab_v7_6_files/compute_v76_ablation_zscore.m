function out = compute_v76_ablation_zscore(fullScores, ablationScores, seedSigma, opts)
%COMPUTE_V76_ABLATION_ZSCORE Score ablation effects relative to seed noise.
%
% Z_ablation = (S_ablation - S_full) / sigma_seed
%
% Positive Z means the ablation is worse than the full model.  A useful
% physical contribution should be positive, robust across seeds, and larger
% than the seed/registration uncertainty floor.

if nargin < 4 || isempty(opts)
    opts = make_v76_multiobservable_score_options();
end

fullScores = fullScores(:);
ablationScores = ablationScores(:);
n = min(numel(fullScores), numel(ablationScores));
fullScores = fullScores(1:n);
ablationScores = ablationScores(1:n);

if nargin < 3 || isempty(seedSigma)
    seedSigma = std(fullScores, 'omitnan');
end

if ~isscalar(seedSigma)
    seedSigma = seedSigma(:);
    seedSigma = seedSigma(1:n);
else
    seedSigma = repmat(seedSigma, n, 1);
end

sigmaEff = max(seedSigma, opts.complexity.seedSigmaFloor);
Z = (ablationScores - fullScores) ./ sigmaEff;

out = table(fullScores, ablationScores, sigmaEff, Z, ...
    'VariableNames', {'S_full','S_ablation','sigma_seed_eff','Z_ablation'});

end
