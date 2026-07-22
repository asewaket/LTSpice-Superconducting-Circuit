function h = plot_raman_digitized_summary(ramanProxy, summary)
%PLOT_RAMAN_DIGITIZED_SUMMARY Plot digitized Raman shifts for v5 model input.

devices = unique(ramanProxy.device, 'stable');
modes = unique(ramanProxy.mode, 'stable');
modeColors = lines(max(numel(modes), 3));

h = figure('Name', 'Raman digitized line-scan summary', 'Color', 'w', ...
    'Position', [80 80 1150 760]);
tiledlayout(numel(devices), 2, 'TileSpacing', 'compact', 'Padding', 'compact');

for d = 1:numel(devices)
    device = devices(d);
    Tdev = ramanProxy(ramanProxy.device == device, :);
    Sdev = summary(summary.device == device, :);

    nexttile;
    hold on;
    series = unique(Tdev.series_id, 'stable');
    for k = 1:numel(series)
        idx = (Tdev.series_id == series(k));
        T = sortrows(Tdev(idx, :), 'position_um');
        modeIdx = find(modes == T.mode(1), 1, 'first');
        plot(T.position_um, T.delta_peak_cm1, '-o', ...
            'Color', modeColors(modeIdx, :), ...
            'LineWidth', 1.3, ...
            'MarkerSize', 4, ...
            'DisplayName', char(T.scan_direction(1) + " " + T.mode(1)));
    end
    yline(0, ':', 'Color', [0.35 0.35 0.35], 'HandleVisibility', 'off');
    grid on;
    box on;
    xlabel('position along scan [\mum]');
    ylabel('\Delta peak [cm^{-1}]');
    title(sprintf('%s digitized Raman shifts', device));
    lgd = legend('Location', 'bestoutside', 'Interpreter', 'none');
    apply_light_legend_style(lgd);

    nexttile;
    hold on;
    if ~isempty(Sdev)
        labels = Sdev.scan_direction + newline + Sdev.mode;
        bar(categorical(labels), Sdev.delta_span_cm1, 0.72, ...
            'FaceColor', [0.25 0.50 0.85]);
    end
    grid on;
    box on;
    ylabel('peak-to-peak \Delta\omega span [cm^{-1}]');
    title(sprintf('%s spatial variation by scan/mode', device));
    set(gca, 'TickLabelInterpreter', 'none');
end

sgtitle('Digitized Raman line-scan inputs for MoTe_2 network model v5');
set(h, 'Color', 'w');
allAxes = findall(h, 'Type', 'axes');
for k = 1:numel(allAxes)
    apply_light_figure_style(allAxes(k));
end

end
