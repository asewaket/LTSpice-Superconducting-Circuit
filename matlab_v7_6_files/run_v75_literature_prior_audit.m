function run_v75_literature_prior_audit()
%RUN_V75_LITERATURE_PRIOR_AUDIT Export v7.5 literature-prior framework.
%
% This runner does not refit the network.  It creates the thesis-facing
% reference/prior tables and diagnostic figures that state how literature is
% allowed to constrain later v7.5 transport sweeps.

rootDir = fileparts(mfilename('fullpath'));
addpath(rootDir);

outDir = fullfile(rootDir, 'outputs', 'v7_5_literature_prior_framework');
if ~exist(outDir, 'dir')
    mkdir(outDir);
end

priors = make_v75_literature_priors();
cases = make_v75_hypothesis_cases();

writetable(priors, fullfile(outDir, 'v7_5_literature_priors.csv'));
writetable(cases, fullfile(outDir, 'v7_5_hypothesis_cases.csv'));

hPrior = plot_v75_literature_prior_map(priors);
saveas(hPrior, fullfile(outDir, 'v7_5_literature_prior_map.png'));
saveas(hPrior, fullfile(outDir, 'v7_5_literature_prior_map.fig'));

hCase = plot_v75_hypothesis_case_map(cases);
saveas(hCase, fullfile(outDir, 'v7_5_hypothesis_case_map.png'));
saveas(hCase, fullfile(outDir, 'v7_5_hypothesis_case_map.fig'));

fprintf('v7.5 literature-prior audit complete.\n');
fprintf('Output directory:\n  %s\n', outDir);
fprintf('Priors exported: %d\n', height(priors));
fprintf('Hypothesis cases exported: %d\n', height(cases));
fprintf('Core-model boundary: magnetic oscillation periods remain outside the scalar network fit.\n');
end
