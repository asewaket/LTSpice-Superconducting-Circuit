function apply_light_figure_style(ax)
%APPLY_LIGHT_FIGURE_STYLE Force thesis-friendly white plotting style.
%
% This avoids inheriting dark MATLAB theme colors and keeps exported figures
% readable on white thesis pages.

if nargin < 1 || isempty(ax)
    ax = gca;
end

if any(isgraphics(ax, 'figure'))
    figs = ax(isgraphics(ax, 'figure'));
    for k = 1:numel(figs)
        set(figs(k), 'Color', 'w');
        axesList = findall(figs(k), 'Type', 'axes');
        for j = 1:numel(axesList)
            apply_light_figure_style(axesList(j));
        end
    end
    return;
end

axesList = ax(isgraphics(ax, 'axes'));
for k = 1:numel(axesList)
    a = axesList(k);
    fig = ancestor(a, 'figure');
    if ~isempty(fig)
        set(fig, 'Color', 'w');
    else
        set(gcf, 'Color', 'w');
    end

    set(a, ...
        'Color', 'w', ...
        'XColor', 'k', ...
        'YColor', 'k', ...
        'GridColor', [0.72 0.72 0.72], ...
        'MinorGridColor', [0.86 0.86 0.86], ...
        'LineWidth', 0.9, ...
        'FontSize', 11, ...
        'Box', 'on');

    grid(a, 'on');

    a.Title.Color = 'k';
    a.XLabel.Color = 'k';
    a.YLabel.Color = 'k';

    try
        a.GridAlpha = 0.35;
        a.MinorGridAlpha = 0.20;
    catch
        % Older MATLAB versions may not expose these properties.
    end
end

end
