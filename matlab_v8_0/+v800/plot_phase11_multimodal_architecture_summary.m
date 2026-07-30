function h = plot_phase11_multimodal_architecture_summary(cfg, ...
    deviceManifest, registrationAvailability, transportSchema, ...
    nonlinearSchema, ramanSchema, geometrySchema, gates)
%PLOT_PHASE11_MULTIMODAL_ARCHITECTURE_SUMMARY Plot Phase 11 architecture audit.

if ~exist(cfg.outputDir, 'dir')
    mkdir(cfg.outputDir);
end

h = figure('Name', 'v9 Phase 11 multimodal architecture', ...
    'Color', 'w', 'Position', [100 100 1700 950]);
tiledlayout(2, 3, 'TileSpacing', 'compact', 'Padding', 'compact');

nexttile;
plot_observable_counts(deviceManifest);
title('observable availability');

nexttile;
plot_device_matrix(deviceManifest);
title('device observable matrix');

nexttile;
plot_schema_counts(transportSchema, nonlinearSchema, ramanSchema, ...
    geometrySchema);
title('schema rows');

nexttile;
plot_registration_status(registrationAvailability);
title('Raman registration status');

nexttile;
plot_device_roles(deviceManifest);
title('Phase 11 device roles');

nexttile;
plot_gate_summary(gates);
title('Phase 11 gates');

titleHandle = sgtitle('Phase 11 unified multimodal data architecture');
set(titleHandle, 'Color', 'k', 'FontWeight', 'bold');
apply_light_style(h);

saveas(h, [cfg.phase11.figureBaseFile '.png']);
saveas(h, [cfg.phase11.figureBaseFile '.pdf']);
end

function plot_observable_counts(T)
labels = ["R(T)", "secondary R(T)", "I-V", "dV/dI(I,T)", ...
    "dV/dI(I,B)", "Raman hint"];
counts = [
    sum(T.has_RT)
    sum(T.has_secondary_RT)
    sum(T.has_IV)
    sum(T.has_dVdI_IT)
    sum(T.has_dVdI_IB)
    sum(T.has_Raman_hint)
    ];
bar(counts, 'FaceColor', [0.25 0.55 0.85]);
set(gca, 'XTick', 1:numel(labels), 'XTickLabel', labels);
xtickangle(25);
ylabel('device count');
grid on;
end

function plot_device_matrix(T)
M = [
    T.has_RT, T.has_secondary_RT, T.has_IV, T.has_dVdI_IT, ...
    T.has_dVdI_IB, T.has_Raman_hint, T.registered_Raman_available
    ];
imagesc(double(M));
colormap(gca, [0.92 0.92 0.92; 0.20 0.55 0.85]);
set(gca, 'XTick', 1:7, 'XTickLabel', ...
    ["RT", "2nd RT", "IV", "dVdI-T", "dVdI-B", "Raman", "reg Raman"]);
set(gca, 'YTick', 1:height(T), 'YTickLabel', T.device);
xtickangle(30);
axis tight;
end

function plot_schema_counts(transportSchema, nonlinearSchema, ramanSchema, ...
    geometrySchema)
labels = ["transport", "nonlinear", "Raman", "geometry"];
counts = [height(transportSchema), height(nonlinearSchema), ...
    height(ramanSchema), height(geometrySchema)];
bar(counts, 'FaceColor', [0.25 0.55 0.85]);
set(gca, 'XTick', 1:numel(labels), 'XTickLabel', labels);
ylabel('schema row count');
grid on;
end

function plot_registration_status(T)
statuses = unique(string(T.registration_status), 'stable');
counts = zeros(numel(statuses), 1);
for k = 1:numel(statuses)
    counts(k) = sum(string(T.registration_status) == statuses(k));
end
bar(counts, 'FaceColor', [0.25 0.55 0.85]);
set(gca, 'XTick', 1:numel(statuses), 'XTickLabel', statuses);
xtickangle(25);
ylabel('device count');
grid on;
end

function plot_device_roles(T)
roles = unique(string(T.phase11_role), 'stable');
counts = zeros(numel(roles), 1);
for k = 1:numel(roles)
    counts(k) = sum(string(T.phase11_role) == roles(k));
end
bar(counts, 'FaceColor', [0.25 0.55 0.85]);
set(gca, 'XTick', 1:numel(roles), 'XTickLabel', roles);
xtickangle(25);
ylabel('device count');
grid on;
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
