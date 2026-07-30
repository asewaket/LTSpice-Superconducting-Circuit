function h = plot_phase12A_raman_registration_feasibility(cfg, ...
    registrationLedger, transformManifest, mechanicalInputs, gates)
%PLOT_PHASE12A_RAMAN_REGISTRATION_FEASIBILITY Plot registration feasibility.

if ~exist(cfg.outputDir, 'dir')
    mkdir(cfg.outputDir);
end

h = figure('Name', 'v9 Phase 12A Raman registration feasibility', ...
    'Color', 'w', 'Position', [120 120 1650 920]);
tiledlayout(2, 3, 'TileSpacing', 'compact', 'Padding', 'compact');

nexttile;
plot_registration_status(registrationLedger);
title('Raman registration status');

nexttile;
plot_registration_prerequisites(registrationLedger);
title('registration prerequisites');

nexttile;
plot_allowed_use(registrationLedger);
title('allowed Raman model use');

nexttile;
plot_transform_status(transformManifest);
title('coordinate transforms');

nexttile;
plot_mechanical_inputs(mechanicalInputs);
title('mechanical proxy classes');

nexttile;
plot_gate_summary(gates);
title('Phase 12A gates');

titleHandle = sgtitle( ...
    'Phase 12A Raman registration feasibility and mechanical-input definition');
set(titleHandle, 'Color', 'k', 'FontWeight', 'bold');
apply_light_style(h);

saveas(h, [cfg.phase12A.figureBaseFile '.png']);
saveas(h, [cfg.phase12A.figureBaseFile '.pdf']);
end

function plot_registration_status(T)
if isempty(T)
    empty_panel('missing registration ledger');
    return;
end
plot_category_counts(string(T.registration_status), 'device count');
end

function plot_registration_prerequisites(T)
if isempty(T)
    empty_panel('missing registration ledger');
    return;
end
M = [
    T.device_coordinate_available, T.scan_origin_known, ...
    T.scan_endpoint_known, T.scan_direction_known, ...
    T.device_orientation_known, T.rotation_known, ...
    T.boundary_location_known, T.spatial_scale_known
    ];
imagesc(double(M));
colormap(gca, [0.92 0.92 0.92; 0.20 0.55 0.85]);
set(gca, 'XTick', 1:8, 'XTickLabel', ...
    ["dev coord", "origin", "endpoint", "direction", ...
    "orientation", "rotation", "boundary", "scale"]);
set(gca, 'YTick', 1:height(T), 'YTickLabel', T.device);
xtickangle(35);
axis tight;
end

function plot_allowed_use(T)
if isempty(T)
    empty_panel('missing registration ledger');
    return;
end
plot_category_counts(string(T.allowed_model_use), 'device count');
end

function plot_transform_status(T)
if isempty(T)
    empty_panel('missing transform manifest');
    return;
end
labels = ["transform available"; "2D field allowed"; ...
    "transport coupling allowed"];
counts = [
    sum(string(T.transform_type) ~= "not_available")
    sum(T.two_dimensional_field_allowed)
    sum(T.transport_coupling_allowed)
    ];
bar(counts, 'FaceColor', [0.25 0.55 0.85]);
set(gca, 'XTick', 1:numel(labels), 'XTickLabel', labels);
xtickangle(25);
ylabel('device count');
ylim([0, max(1, max(counts) + 1)]);
grid on;
end

function plot_mechanical_inputs(T)
if isempty(T)
    empty_panel('missing mechanical input definition');
    return;
end
plot_category_counts(string(T.reduced_mechanical_proxy_class), ...
    'device count');
end

function plot_gate_summary(T)
if isempty(T)
    empty_panel('missing gate summary');
    return;
end
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

function plot_category_counts(values, yLabel)
values = string(values);
if isempty(values)
    empty_panel('no rows');
    return;
end
labels = unique(values, 'stable');
counts = zeros(numel(labels), 1);
for k = 1:numel(labels)
    counts(k) = sum(values == labels(k));
end
bar(counts, 'FaceColor', [0.25 0.55 0.85]);
set(gca, 'XTick', 1:numel(labels), 'XTickLabel', labels);
xtickangle(25);
ylabel(yLabel);
grid on;
end

function empty_panel(msg)
text(0.5, 0.5, msg, 'HorizontalAlignment', 'center', ...
    'Color', 'k');
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
end
