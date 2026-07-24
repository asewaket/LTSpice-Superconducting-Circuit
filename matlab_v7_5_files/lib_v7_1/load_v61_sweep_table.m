function sweepTable = load_v61_sweep_table(projectDir, opts)
%LOAD_V61_SWEEP_TABLE Load v6.1 Raman variant score table.

if nargin < 2 || isempty(opts)
    opts = make_raman_robustness_options();
end

scoreFile = fullfile(projectDir, opts.variantOutputSubdir, ...
    'raman_variant_sensitivity_scores.csv');

if ~exist(scoreFile, 'file')
    error(['v6.1 score table not found:\n%s\n\n', ...
        'Run run_raman_variant_sensitivity_sweep first, then rerun this script.'], ...
        scoreFile);
end

sweepTable = readtable(scoreFile);

stringVars = {'device','raman_mode','reference','representation','couplingMode','modelPair'};
for k = 1:numel(stringVars)
    v = stringVars{k};
    if ismember(v, sweepTable.Properties.VariableNames)
        sweepTable.(v) = string(sweepTable.(v));
    end
end

end
