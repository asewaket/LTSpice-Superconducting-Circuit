function apply_light_figure_style(ax)
%APPLY_LIGHT_FIGURE_STYLE Force thesis-friendly white plotting style.
%
% This avoids inheriting dark MATLAB theme colors and keeps exported figures
% readable on white thesis pages.

if nargin < 1 || isempty(ax)
    ax = gca;
end

set(gcf, 'Color', 'w');
set(ax, ...
    'Color', 'w', ...
    'XColor', 'k', ...
    'YColor', 'k', ...
    'GridColor', [0.72 0.72 0.72], ...
    'MinorGridColor', [0.86 0.86 0.86], ...
    'LineWidth', 0.9, ...
    'FontSize', 11, ...
    'Box', 'on');

grid(ax, 'on');

ax.Title.Color = 'k';
ax.XLabel.Color = 'k';
ax.YLabel.Color = 'k';

try
    ax.GridAlpha = 0.35;
    ax.MinorGridAlpha = 0.20;
catch
    % Older MATLAB versions may not expose these properties.
end

end

