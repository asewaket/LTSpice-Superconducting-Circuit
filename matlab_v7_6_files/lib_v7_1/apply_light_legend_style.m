function apply_light_legend_style(lgd)
%APPLY_LIGHT_LEGEND_STYLE Force thesis-friendly legend appearance.

if nargin < 1 || isempty(lgd)
    lgd = legend;
end

set(lgd, ...
    'Color', 'w', ...
    'TextColor', 'k', ...
    'EdgeColor', [0.25 0.25 0.25], ...
    'Box', 'on');

try
    lgd.FontSize = 10;
catch
end

end
