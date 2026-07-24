function apply_v77_light_style(h)
%APPLY_V77_LIGHT_STYLE Force exported v7.7 figures onto a white theme.

if nargin < 1 || isempty(h)
    h = gcf;
end

set(h, 'Color', 'w', 'InvertHardcopy', 'off');
ax = findall(h, 'Type', 'axes');
for k = 1:numel(ax)
    set(ax(k), 'Color', 'w', 'XColor', 'k', 'YColor', 'k', ...
        'GridColor', [0.75 0.75 0.75], 'MinorGridColor', [0.86 0.86 0.86], ...
        'LineWidth', 0.9, 'Box', 'on', 'FontSize', 10);
    try
        ax(k).Title.Color = 'k';
        ax(k).XLabel.Color = 'k';
        ax(k).YLabel.Color = 'k';
    catch
    end
    grid(ax(k), 'on');
end

txt = findall(h, 'Type', 'text');
for k = 1:numel(txt)
    try
        txt(k).Color = 'k';
        txt(k).Interpreter = 'none';
    catch
    end
end

lg = findall(h, 'Type', 'legend');
for k = 1:numel(lg)
    set(lg(k), 'Color', 'w', 'TextColor', 'k', ...
        'EdgeColor', [0.4 0.4 0.4]);
end

cb = findall(h, 'Type', 'colorbar');
for k = 1:numel(cb)
    try
        cb(k).Color = 'k';
    catch
    end
end

end

