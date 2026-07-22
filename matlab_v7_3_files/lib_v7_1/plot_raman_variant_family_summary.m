function h = plot_raman_variant_family_summary(familyTable, baselineTable, opts)
%PLOT_RAMAN_VARIANT_FAMILY_SUMMARY Plot family-level v6.2 sensitivity.

if nargin < 3 || isempty(opts)
    opts = make_raman_robustness_options();
end

families = {'representation','couplingMode','raman_mode','reference'};
h = figure('Name', 'Raman variant family summary', 'Color', 'w', ...
    'Position', [80 80 1250 780]);
tiledlayout(2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');

for f = 1:numel(families)
    family = families{f};
    nexttile;
    T = familyTable(string(familyTable.family) == family, :);
    devices = unique(string(T.device), 'stable');
    values = unique(string(T.value), 'stable');
    hold on;
    colors = lines(numel(devices));
    for d = 1:numel(devices)
        Td = T(string(T.device) == devices(d), :);
        y = nan(numel(values), 1);
        for iv = 1:numel(values)
            idx = string(Td.value) == values(iv);
            if any(idx)
                y(iv) = Td.scoreBest(find(idx, 1, 'first'));
            end
        end
        x = 1:numel(values);
        plot(x, y, '-o', 'LineWidth', 1.7, ...
            'MarkerSize', 5, 'Color', colors(d,:), ...
            'DisplayName', char(devices(d)));
    end
    set(gca, 'XTick', 1:numel(values), 'XTickLabel', cellstr(values));
    title(sprintf('Best score by %s', strrep(family, '_', '\_')));
    ylabel('best combined score');
    grid on;
    box on;
    xtickangle(25);
    set(gca, 'TickLabelInterpreter', 'none');
    apply_light_figure_style(gca);
    lgd = legend('Location', 'best');
    apply_light_legend_style(lgd);
end

sgtitle(sprintf('v6.2 family-level Raman sensitivity; top-%d fraction also exported', ...
    opts.topFractionN));

% baselineTable is exported even if not shown in this compact plot; keeping it
% as an input makes the function signature explicit for future annotation.
if isempty(baselineTable)
end

end
