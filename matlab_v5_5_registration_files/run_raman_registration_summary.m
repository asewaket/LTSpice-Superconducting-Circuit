%RUN_RAMAN_REGISTRATION_SUMMARY Register Raman scans onto Hall-bar coordinates.
%
% This is the v5.5 bridge from digitized 1D Raman traces to network-ready
% spatial coordinates. It does not yet alter Tc/Ic/Rn. Instead, it exports
% registered point tables and Raman proxy maps that can be inspected before
% being coupled to the transport solver.

clear;
clc;

projectDir = fileparts(mfilename('fullpath'));
outDir = fullfile(projectDir, 'outputs', 'raman_registration');
if ~exist(outDir, 'dir')
    mkdir(outDir);
end

raman = load_raman_digitized_data(fullfile(projectDir, 'data', 'raman_digitized'));
ramanProxy = make_raman_shift_proxy(raman);
registration = load_raman_scan_registration(fullfile(projectDir, ...
    'data', 'raman_registration', 'raman_scan_endpoints_hallbar_coordinates.txt'));

registered = register_raman_scans_to_hallbar(ramanProxy, registration);

registeredFile = fullfile(outDir, 'raman_registered_points.csv');
registrationFile = fullfile(outDir, 'raman_scan_registration_table.csv');
writetable(registered, registeredFile);
writetable(registration, registrationFile);

devices = unique(registered.device(registered.registration_status == "registered"), 'stable');

mapRows = cell(numel(devices), 1);
for d = 1:numel(devices)
    device = devices(d);
    spec = make_device_spec(device);
    net = build_hallbar_network(spec);

    opts = struct('valueColumn', 'abs_shift_proxy', 'sigma_um', 0.85);
    ramanMap = build_raman_proxy_map(net, registered, device, opts);

    mapStructFile = fullfile(outDir, sprintf('%s_raman_proxy_map.mat', device));
    save(mapStructFile, 'ramanMap', 'net', 'spec', 'opts');

    vals = ramanMap.nodeMapNorm(isfinite(ramanMap.nodeMapNorm));
    if isempty(vals)
        meanProxy = NaN;
        maxProxy = NaN;
        coverageFrac = 0;
    else
        meanProxy = mean(vals, 'omitnan');
        maxProxy = max(vals, [], 'omitnan');
        coverageFrac = nnz(isfinite(ramanMap.nodeMapNorm) & net.active) / nnz(net.active);
    end

    mapRows{d} = table(device, meanProxy, maxProxy, coverageFrac, ...
        string(mapStructFile), ...
        'VariableNames', {'device', 'mean_registered_proxy', ...
        'max_registered_proxy', 'node_coverage_fraction', 'map_file'});
end

mapSummary = vertcat(mapRows{:});
writetable(mapSummary, fullfile(outDir, 'raman_proxy_map_summary.csv'));

h = plot_raman_registration_overlays(devices, registered, registration);
export_chapter_figure(h, outDir, 'raman_registration_overlays');

fprintf('\nRegistered Raman scans for %d devices.\n', numel(devices));
fprintf('Wrote:\n');
fprintf('  %s\n', registeredFile);
fprintf('  %s\n', registrationFile);
fprintf('  %s\n', fullfile(outDir, 'raman_proxy_map_summary.csv'));
fprintf('  %s\n', fullfile(outDir, 'raman_registration_overlays.png'));

missing = unique(registered.series_id(registered.registration_status ~= "registered"));
if ~isempty(missing)
    fprintf('\nUnregistered series:\n');
    for k = 1:numel(missing)
        fprintf('  %s\n', missing(k));
    end
end
