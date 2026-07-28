function h = plot_phase6_hierarchical_evidence_summary(cfg, evidenceMatrix, gates)
%PLOT_PHASE6_HIERARCHICAL_EVIDENCE_SUMMARY Plot frozen six-device hierarchy.

if ~exist(cfg.outputDir, 'dir')
    mkdir(cfg.outputDir);
end

h = figure('Name', 'v8.0 Phase 6 hierarchical evidence freeze', ...
    'Color', 'w', 'Position', [120 120 1600 860]);
tiledlayout(2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');

nexttile([1 2]);
plot_device_axis(evidenceMatrix);
title('six-device hierarchy: model status and evidence tier');

nexttile;
plot_deltaS_context(evidenceMatrix);
title('contextual \DeltaS and Z');

nexttile;
plot_gate_summary(gates);
title('Phase 6 gates');

sgtitle('v8.0 Phase 6 hierarchical six-device evidence/model freeze');
apply_light_style(h);

saveas(h, [cfg.phase6.figureBaseFile '.png']);
saveas(h, [cfg.phase6.figureBaseFile '.pdf']);
end

function plot_device_axis(T)
if isempty(T)
    empty_panel('missing evidence matrix');
    return;
end
devices = T.device;
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
plot([-1 1], [0 0], 'Color', [0.65 0.65 0.65], 'HandleVisibility', 'off');
seenTiers = strings(0, 1);
for k = 1:height(T)
    [marker, color] = tier_style(T.evidence_tier(k));
    if any(seenTiers == T.evidence_tier(k))
        scatter(x(k), y(k), 110, 'Marker', marker, ...
            'MarkerFaceColor', color, 'MarkerEdgeColor', 'k', ...
            'HandleVisibility', 'off');
    else
        scatter(x(k), y(k), 110, 'Marker', marker, ...
            'MarkerFaceColor', color, 'MarkerEdgeColor', 'k', ...
            'DisplayName', T.evidence_tier(k));
        seenTiers(end + 1, 1) = T.evidence_tier(k);
    end
    text(x(k) + 0.05, y(k), devices(k), ...
        'VerticalAlignment', 'middle', 'FontWeight', 'bold');
end
hold off;
xlim([-1.35 1.35]);
ylim([0.4 height(T) + 0.6]);
set(gca, 'XTick', [-1 0 1], ...
    'XTickLabel', ["M0* sufficient", "unresolved", "structured"]);
set(gca, 'YTick', []);
xlabel('frozen model status');
legend('Location', 'northwest');
grid on;
end

function plot_deltaS_context(T)
if isempty(T)
    empty_panel('missing evidence matrix');
    return;
end
bar(T.phase5D2_DeltaS, 'FaceColor', [0.25 0.55 0.85]);
yline(0, 'k-');
set(gca, 'XTick', 1:height(T), 'XTickLabel', T.device);
xtickangle(25);
ylabel('\DeltaS = S_{structured} - S_{M0*}');
yyaxis right;
plot(1:height(T), T.phase5D2_Z, 'ko-', 'LineWidth', 1.2);
ylabel('contextual Z');
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
bar(counts);
set(gca, 'XTick', 1:numel(statuses), 'XTickLabel', statuses);
ylabel('gate count');
grid on;
end

function [marker, color] = tier_style(tier)
switch string(tier)
    case "paired_probe_and_heldout"
        marker = "o";
        color = [0.10 0.55 0.25];
    case "auxiliary_supported"
        marker = "s";
        color = [0.95 0.55 0.15];
    case "control_limit"
        marker = "d";
        color = [0.35 0.45 0.85];
    case "mixed_probe"
        marker = "^";
        color = [0.75 0.35 0.75];
    otherwise
        marker = "v";
        color = [0.55 0.55 0.55];
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
        'LineWidth', 1.0, 'FontSize', 10, 'Box', 'on');
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
