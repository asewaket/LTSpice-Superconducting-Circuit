function familyTable = summarize_raman_variant_families(sweepTable, opts)
%SUMMARIZE_RAMAN_VARIANT_FAMILIES Score Raman variant families, not just winners.

if nargin < 2 || isempty(opts)
    opts = make_raman_robustness_options();
end

familyVars = {'raman_mode','reference','representation','couplingMode','alpha'};
devices = unique(string(sweepTable.device), 'stable');
rows = {};

for d = 1:numel(devices)
    device = devices(d);
    Tdev = sweepTable(string(sweepTable.device) == device, :);
    Tdev = sortrows(Tdev, 'combinedScore');
    topN = min(opts.topFractionN, height(Tdev));
    topRows = Tdev(1:topN, :);

    for fv = 1:numel(familyVars)
        fName = familyVars{fv};
        values = unique(string(Tdev.(fName)), 'stable');
        for iv = 1:numel(values)
            val = values(iv);
            idxAll = string(Tdev.(fName)) == val;
            idxTop = string(topRows.(fName)) == val;
            scores = Tdev.combinedScore(idxAll);
            scores = scores(isfinite(scores));
            if isempty(scores)
                scoreMean = NaN;
                scoreMedian = NaN;
                scoreBest = NaN;
                scoreStd = NaN;
            else
                scoreMean = mean(scores);
                scoreMedian = median(scores);
                scoreBest = min(scores);
                scoreStd = std(scores);
            end
            rows(end+1,:) = {char(device), fName, char(val), ...
                nnz(idxAll), nnz(idxTop), nnz(idxTop)/max(1, topN), ...
                scoreMean, scoreMedian, scoreBest, scoreStd}; %#ok<AGROW>
        end
    end
end

familyTable = cell2table(rows, 'VariableNames', { ...
    'device','family','value','N_total','N_top','topFraction', ...
    'scoreMean','scoreMedian','scoreBest','scoreStd'});

end
