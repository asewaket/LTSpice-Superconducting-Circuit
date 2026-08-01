function h = plot_phase14B4R_raw_nonlinear_source_recovery_summary(cfg, ...
    candidateLedger, recoveryValidation, deviceDecision, gates)
%PLOT_PHASE14B4R_RAW_NONLINEAR_SOURCE_RECOVERY_SUMMARY Plot 14B.4R.

if ~exist(cfg.outputDir, 'dir')
    mkdir(cfg.outputDir);
end

h = figure('Name', 'v9 Phase 14B.4R raw source recovery', ...
    'Color', 'w', 'Position', [100 100 1850 980]);
tiledlayout(2, 3, 'TileSpacing', 'compact', 'Padding', 'compact');

nexttile;
plot_candidate_counts(candidateLedger);
title('candidate files by device');

nexttile;
plot_validation_score(deviceDecision);
title('best validation score');

nexttile;
plot_relock_decision(deviceDecision);
title('relock readiness');

nexttile;
plot_validation_status(recoveryValidation);
title('candidate recovery status');

nexttile;
plot_policy_note();
title('Phase 14B.4R policy');

nexttile;
plot_gate_summary(gates);
title('Phase 14B.4R gates');

titleHandle = sgtitle( ...
    'Phase 14B.4R raw AS001/AS004 nonlinear source recovery');
set(titleHandle, 'Color', 'k', 'FontWeight', 'bold');
apply_light_style(h);

saveas(h, char([cfg.phase14B4R.figureBaseFile '.png']));
saveas(h, char([cfg.phase14B4R.figureBaseFile '.pdf']));
end

function plot_candidate_counts(T)
devices = unique(string(T.device), 'stable');
counts = zeros(numel(devices), 1);
numericCounts = zeros(numel(devices), 1);
for k = 1:numel(devices)
    mask = string(T.device) == devices(k);
    counts(k) = sum(mask & string(T.candidate_file) ~= "none");
    numericCounts(k) = sum(mask & string(T.candidate_file) ~= "none" & ...
        ~T.figure_only);
end
bar([counts numericCounts]);
set(gca, 'XTick', 1:numel(devices), 'XTickLabel', devices);
ylabel('candidate count');
legend(["all candidates", "numeric candidates"], 'Location', 'best');
grid on;
end

function plot_validation_score(T)
devices = string(T.device);
bar(T.best_validation_score, 'FaceColor', [0.25 0.55 0.85]);
hold on;
yline(10, '--', 'required lock score');
hold off;
set(gca, 'XTick', 1:numel(devices), 'XTickLabel', devices);
ylim([0 10.5]);
ylabel('criteria satisfied / 10');
grid on;
end

function plot_relock_decision(T)
ready = double(T.allowed_for_phase14B4_relock);
bar(ready, 'FaceColor', [0.25 0.55 0.85]);
set(gca, 'XTick', 1:height(T), 'XTickLabel', string(T.device));
ylim([0 1]);
ylabel('ready for relock = 1');
grid on;
for k = 1:height(T)
    if T.allowed_for_phase14B4_relock(k)
        label = "relock";
        color = [0.0 0.45 0.16];
    else
        label = "blocked";
        color = [0.55 0.08 0.08];
    end
    text(k, 0.55, label, 'HorizontalAlignment', 'center', ...
        'Color', color, 'FontWeight', 'bold');
end
end

function plot_validation_status(T)
statuses = unique(string(T.recovery_status), 'stable');
counts = zeros(numel(statuses), 1);
for k = 1:numel(statuses)
    counts(k) = sum(string(T.recovery_status) == statuses(k));
end
bar(counts, 'FaceColor', [0.25 0.55 0.85]);
set(gca, 'XTick', 1:numel(statuses), 'XTickLabel', statuses);
xtickangle(30);
ylabel('candidate count');
grid on;
end

function plot_policy_note()
axis off;
text(0.08, 0.78, 'No model changes', ...
    'FontWeight', 'bold', 'FontSize', 12, 'Color', 'k');
text(0.08, 0.58, 'No fitting or proxy substitution', ...
    'FontWeight', 'bold', 'FontSize', 12, 'Color', [0.55 0.08 0.08]);
text(0.08, 0.38, 'Recovery only enables 14B.4 relock review', ...
    'FontWeight', 'bold', 'FontSize', 12, 'Color', 'k');
text(0.08, 0.18, '14B.5 remains blocked until relock passes', ...
    'FontWeight', 'bold', 'FontSize', 12, 'Color', 'k');
end

function plot_gate_summary(T)
statuses = ["pass"; "fail"; "not_run"];
counts = zeros(numel(statuses), 1);
for k = 1:numel(statuses)
    counts(k) = sum(string(T.outcome) == statuses(k));
end
bar(counts, 'FaceColor', [0.25 0.55 0.85]);
set(gca, 'XTick', 1:numel(statuses), 'XTickLabel', statuses);
ylabel('gate count');
grid on;
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
end
