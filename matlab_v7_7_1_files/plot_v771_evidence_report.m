function h = plot_v771_evidence_report(evidence, gates, opts)
%PLOT_V771_EVIDENCE_REPORT Thesis-oriented v7.7.1 mechanism evidence plot.

h = figure('Name', 'v7.7.1 mechanism evidence report', ...
    'Color', 'w', 'Position', [80 80 1500 900]);
tiledlayout(h, 2, 2, 'Padding', 'compact', 'TileSpacing', 'compact');

mechanisms = evidence.mechanism;
y = 1:height(evidence);

ax1 = nexttile;
barh(ax1, y, evidence.multiObservableScore, 0.72, 'FaceColor', [0.20 0.52 0.84]);
set(ax1, 'YTick', y, 'YTickLabel', mechanisms, 'YDir', 'reverse', ...
    'TickLabelInterpreter', 'none');
xlabel(ax1, 'multi-observable objective score');
title(ax1, 'mechanism ranking; lower is better');
style_axes(ax1);

ax2 = nexttile;
deltaData = [evidence.deltaVsNoWeak, evidence.deltaVsCentralLane];
bar(ax2, y, deltaData, 'grouped');
yline(ax2, 0, ':', 'Color', [0.25 0.25 0.25]);
set(ax2, 'XTick', y, 'XTickLabel', mechanisms, ...
    'XTickLabelRotation', 30, 'TickLabelInterpreter', 'none');
ylabel(ax2, '\Delta objective score');
title(ax2, 'baseline wins: negative means improvement');
legend(ax2, {'vs no weak links', 'vs central lane'}, 'Location', 'best');
style_axes(ax2);

ax3 = nexttile;
gateNames = erase(string(gates.Properties.VariableNames(2:end)), "_");
gateMatrix = table2array(gates(:, 2:end));
imagesc(ax3, gateMatrix);
colormap(ax3, [0.82 0.82 0.82; 0.18 0.60 0.30]);
caxis(ax3, [0 1]);
set(ax3, 'XTick', 1:numel(gateNames), 'XTickLabel', gateNames, ...
    'YTick', y, 'YTickLabel', gates.mechanism, 'YDir', 'normal', ...
    'XTickLabelRotation', 30, 'TickLabelInterpreter', 'none');
title(ax3, 'claim gates');
style_axes(ax3);

ax4 = nexttile;
axis(ax4, 'off');
claimCount = sum(evidence.claimReady);
seedCounts = evidence.seedCount;
finiteZ = sum(isfinite(evidence.ablationZ_vsNoWeak));
bestMechanism = evidence.mechanism(1);
bestScore = evidence.multiObservableScore(1);

lines = [
    "v7.7.1 interpretation"
    ""
    "Best current mechanism: " + bestMechanism
    "Best multi-observable score: " + sprintf('%.4g', bestScore)
    "Mechanisms with claimReady = true: " + string(claimCount) + "/" + string(height(evidence))
    "Mechanisms with usable ablation Z: " + string(finiteZ) + "/" + string(height(evidence))
    "Seed counts present in ledger: " + join(unique(string(seedCounts(~isnan(seedCounts))))', ", ")
    ""
    "A physical claim requires:"
    "  - multi-seed variability, not one realization;"
    "  - significant Z relative to seed scatter;"
    "  - both-probe survival;"
    "  - held-out diagnostic support;"
    "  - improvement over no-weak-link and central-lane baselines."
    ""
    "If Z is NaN, that is intentional: the current ledger lacks enough seed-to-seed statistics."
    ];

text(ax4, 0.02, 0.95, strjoin(lines, newline), ...
    'Units', 'normalized', 'VerticalAlignment', 'top', ...
    'FontName', 'Helvetica', 'FontSize', 13, 'Interpreter', 'none', ...
    'Color', [0 0 0]);

sgtitle(h, sprintf('%s %s mechanism-evidence report', opts.version, opts.device), ...
    'FontWeight', 'bold', 'Interpreter', 'none');

end

function style_axes(ax)
set(ax, 'Color', 'w', 'XColor', 'k', 'YColor', 'k', ...
    'GridColor', [0.75 0.75 0.75], 'MinorGridColor', [0.85 0.85 0.85], ...
    'FontName', 'Helvetica', 'FontSize', 11, 'LineWidth', 1.0, ...
    'Box', 'on');
grid(ax, 'on');
title(ax, ax.Title.String, 'Color', 'k', 'Interpreter', 'none');
xlabel(ax, ax.XLabel.String, 'Color', 'k', 'Interpreter', 'tex');
ylabel(ax, ax.YLabel.String, 'Color', 'k', 'Interpreter', 'tex');
end
