function oopIndex = compute_out_of_plane_contribution_index(modeSummary)
%COMPUTE_OUT_OF_PLANE_CONTRIBUTION_INDEX Simple A4g contribution diagnostics.
%
% Positive delta_without_A4g means removing A4g worsens the best score relative
% to all modes, suggesting the A4g channel carries useful information.
% Positive delta_inplane_minus_all similarly means all modes beat in-plane only.

devices = unique(string(modeSummary.device), 'stable');
rows = {};

for d = 1:numel(devices)
    device = devices(d);
    T = modeSummary(string(modeSummary.device) == device, :);
    sAll = score_for(T, 'all_with_A4g');
    if ~isfinite(sAll)
        sAll = score_for(T, 'all_modes');
    end
    sA4g = score_for(T, 'A4g_only');
    sInPlane = score_for(T, 'in_plane_only');
    sWithoutA4g = score_for(T, 'without_A4g');
    sA5g = score_for(T, 'A5g_only');
    sB2g = score_for(T, 'B2g_only');

    deltaWithoutA4g = sWithoutA4g - sAll;
    deltaInPlaneMinusAll = sInPlane - sAll;
    deltaA4gMinusInPlane = sA4g - sInPlane;

    if isfinite(deltaWithoutA4g) && deltaWithoutA4g > 0.01
        interpretation = "A4g improves all-mode proxy";
    elseif isfinite(deltaA4gMinusInPlane) && deltaA4gMinusInPlane < -0.01
        interpretation = "A4g-only beats in-plane-only";
    else
        interpretation = "A4g contribution not isolated";
    end

    rows(end+1,:) = {char(device), sAll, sA4g, sInPlane, sWithoutA4g, ...
        sA5g, sB2g, deltaWithoutA4g, deltaInPlaneMinusAll, ...
        deltaA4gMinusInPlane, char(interpretation)}; %#ok<AGROW>
end

oopIndex = cell2table(rows, 'VariableNames', { ...
    'device','score_all_with_A4g','score_A4g_only','score_in_plane_only', ...
    'score_without_A4g','score_A5g_only','score_B2g_only', ...
    'delta_without_A4g_minus_all','delta_inplane_minus_all', ...
    'delta_A4g_minus_inplane','interpretation'});

end

function s = score_for(T, modeName)
idx = string(T.mode_variant) == string(modeName);
if any(idx)
    vals = T.bestScore(idx);
    s = vals(1);
else
    s = NaN;
end
end
