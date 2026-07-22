function summary = summarize_robustness_table(robustnessTable)
%SUMMARIZE_ROBUSTNESS_TABLE Mean/std scores for selected robust variants.

devices = unique(string(robustnessTable.device), 'stable');
rows = {};

for d = 1:numel(devices)
    device = devices(d);
    Tdev = robustnessTable(string(robustnessTable.device) == device, :);
    labels = unique(string(Tdev.variantLabel), 'stable');
    for il = 1:numel(labels)
        label = labels(il);
        T = Tdev(string(Tdev.variantLabel) == label, :);
        rows(end+1,:) = {char(device), char(label), height(T), ...
            first_string(T.raman_mode), first_string(T.reference), ...
            first_string(T.representation), first_string(T.couplingMode), ...
            T.alpha(1), ...
            mean(T.metricScore, 'omitnan'), std(T.metricScore, 'omitnan'), ...
            mean(T.shapeScore, 'omitnan'), std(T.shapeScore, 'omitnan'), ...
            mean(T.combinedScore, 'omitnan'), std(T.combinedScore, 'omitnan')}; %#ok<AGROW>
    end
end

summary = cell2table(rows, 'VariableNames', { ...
    'device','variantLabel','N','raman_mode','reference','representation', ...
    'couplingMode','alpha', ...
    'metricScoreMean','metricScoreStd','shapeScoreMean','shapeScoreStd', ...
    'combinedScoreMean','combinedScoreStd'});

summary = sortrows(summary, {'device','combinedScoreMean'});

end

function s = first_string(x)
s = char(string(x(1)));
end
