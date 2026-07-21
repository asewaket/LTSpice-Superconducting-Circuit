function modeSummary = summarize_out_of_plane_modes(scoreTable)
%SUMMARIZE_OUT_OF_PLANE_MODES Best/mean scores by mode variant.

devices = unique(string(scoreTable.device), 'stable');
rows = {};

for d = 1:numel(devices)
    device = devices(d);
    Tdev = scoreTable(string(scoreTable.device) == device, :);
    modes = unique(string(Tdev.mode_variant), 'stable');
    for im = 1:numel(modes)
        modeName = modes(im);
        T = Tdev(string(Tdev.mode_variant) == modeName, :);
        scores = T.combinedScore(isfinite(T.combinedScore));
        if isempty(scores)
            bestScore = NaN;
            meanScore = NaN;
            medianScore = NaN;
            stdScore = NaN;
            bestRow = T(1,:);
        else
            [bestScore, idx] = min(T.combinedScore);
            bestRow = T(idx,:);
            meanScore = mean(scores);
            medianScore = median(scores);
            stdScore = std(scores);
        end
        rows(end+1,:) = {char(device), char(modeName), height(T), ...
            bestScore, meanScore, medianScore, stdScore, ...
            first_text(bestRow.reference), first_text(bestRow.representation), ...
            first_text(bestRow.couplingMode), bestRow.alpha}; %#ok<AGROW>
    end
end

function txt = first_text(x)
if iscell(x)
    txt = char(x{1});
else
    txt = char(string(x(1)));
end
end

modeSummary = cell2table(rows, 'VariableNames', { ...
    'device','mode_variant','N','bestScore','meanScore','medianScore','stdScore', ...
    'bestReference','bestRepresentation','bestCouplingMode','bestAlpha'});
modeSummary = sortrows(modeSummary, {'device','bestScore'});

end
