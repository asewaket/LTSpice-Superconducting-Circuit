function h = plot_phase9_final_model_package(cfg, deviceLedger, ...
    evidenceHierarchy, gates)
%PLOT_PHASE9_FINAL_MODEL_PACKAGE Plot final v8 packaging summary.

if ~exist(cfg.outputDir, 'dir')
    mkdir(cfg.outputDir);
end

h = figure('Name', 'v8.0 Phase 9 final model package', ...
    'Color', 'w', 'Position', [100 100 1600 900]);
tiledlayout(2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');

nexttile;
plot_final_hierarchy(deviceLedger);
title('frozen six-device hierarchy');

nexttile;
plot_contextual_scores(deviceLedger);
title('contextual score evidence');

nexttile;
plot_evidence_hierarchy(evidenceHierarchy);
title('final evidence hierarchy');

nexttile;
plot_gate_summary(gates);
title('Phase 9 gates');

titleHandle = sgtitle('v8.0 Phase 9 final model packaging and claim freeze');
set(titleHandle, 'Color', 'k', 'FontWeight', 'bold');
apply_light_style(h);

saveas(h, [cfg.phase9.figureBaseFile '.png']);
saveas(h, [cfg.phase9.figureBaseFile '.pdf']);
end

function plot_final_hierarchy(T)
if isempty(T)
    empty_panel('missing final device ledger');
    return;
end
x = zeros(height(T), 1);
for k = 1:height(T)
    switch string(T.final_model_status(k))
        case "M0star_sufficient"
            x(k) = -1;
        case "structured_supported"
            x(k) = 1;
        otherwise
            x(k) = 0;
    end
end
y = (1:height(T)).';
hold on;
plot([-1 1], [0 0], 'Color', [0.70 0.70 0.70], ...
    'HandleVisibility', 'off');
for k = 1:height(T)
    [marker, color] = status_style(T.final_model_status(k));
    scatter(x(k), y(k), 120, 'Marker', marker, ...
        'MarkerFaceColor', color, 'MarkerEdgeColor', 'k');
    text(x(k) + 0.05, y(k), T.device(k), ...
        'VerticalAlignment', 'middle', 'FontWeight', 'bold');
end
hold off;
xlim([-1.35 1.35]);
ylim([0.4 height(T) + 0.6]);
set(gca, 'XTick', [-1 0 1], ...
    'XTickLabel', ["M0* sufficient", "unresolved", "structured supported"]);
set(gca, 'YTick', []);
xlabel('final frozen model status');
grid on;
end

function plot_contextual_scores(T)
if isempty(T)
    empty_panel('missing contextual scores');
    return;
end
bar(T.contextual_DeltaS, 'FaceColor', [0.25 0.55 0.85]);
yline(0, 'k-');
set(gca, 'XTick', 1:height(T), 'XTickLabel', T.device);
xtickangle(25);
ylabel('\DeltaS = S_{structured} - S_{M0*}');
yyaxis right;
plot(1:height(T), T.contextual_Z, 'ko-', 'LineWidth', 1.2, ...
    'MarkerFaceColor', 'w');
ylabel('contextual Z');
text(0.05, 0.92, 'contextual only; not a validated universal classifier', ...
    'Units', 'normalized', 'Color', [0.35 0.35 0.35], ...
    'FontWeight', 'bold');
grid on;
end

function plot_evidence_hierarchy(T)
if isempty(T)
    empty_panel('missing evidence hierarchy');
    return;
end
barh(T.rank, ones(height(T), 1), 'FaceColor', [0.25 0.55 0.85]);
set(gca, 'YTick', T.rank, 'YTickLabel', T.evidence_class);
set(gca, 'XTick', []);
ylim([0.4 max(T.rank) + 0.6]);
xlim([0 1.20]);
ylabel('evidence rank');
for k = 1:height(T)
    text(0.04, T.rank(k), string(T.rank(k)) + ". " + T.evidence_class(k), ...
        'VerticalAlignment', 'middle', 'Color', 'w', ...
        'FontWeight', 'bold', 'Interpreter', 'none');
end
grid on;
end

function plot_gate_summary(T)
if isempty(T)
    empty_panel('missing gate summary');
    return;
end
statuses = ["pass"; "fail"; "not_run"];
counts = zeros(numel(statuses), 1);
for k = 1:numel(statuses)
    counts(k) = sum(T.outcome == statuses(k));
end
bar(counts, 'FaceColor', [0.25 0.55 0.85]);
set(gca, 'XTick', 1:numel(statuses), 'XTickLabel', statuses);
ylabel('gate count');
grid on;
end

function [marker, color] = status_style(status)
switch string(status)
    case "M0star_sufficient"
        marker = "d";
        color = [0.35 0.45 0.85];
    case "structured_supported"
        marker = "o";
        color = [0.10 0.55 0.25];
    otherwise
        marker = "^";
        color = [0.75 0.35 0.75];
end
end

function empty_panel(msg)
text(0.5, 0.5, msg, 'HorizontalAlignment', 'center', 'Color', 'k');
axis off;
end

function apply_light_style(h)
set(h, 'Color', 'w');
axList = findall(h, 'Type', 'axes');
for k = 1:numel(axList)
    ax = axList(k);
    set(ax, 'Color', 'w', 'XColor', 'k', 'YColor', 'k', ...
        'GridColor', [0.72 0.72 0.72], ...
        'MinorGridColor', [0.86 0.86 0.86], ...
        'LineWidth', 1.0, 'FontSize', 10, 'Box', 'on', ...
        'TickLabelInterpreter', 'none');
    ax.Title.Color = 'k';
    ax.XLabel.Color = 'k';
    ax.YLabel.Color = 'k';
end
legendList = findall(h, 'Type', 'Legend');
for k = 1:numel(legendList)
    set(legendList(k), 'TextColor', 'k', 'Color', 'w', ...
        'EdgeColor', [0.4 0.4 0.4]);
end
end
