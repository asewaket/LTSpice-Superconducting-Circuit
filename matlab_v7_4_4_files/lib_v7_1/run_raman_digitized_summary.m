%RUN_RAMAN_DIGITIZED_SUMMARY Import, summarize, and plot digitized Raman scans.
%
% This script is the first Raman-aware layer of the MATLAB network project.
% It does not yet alter the superconducting-network parameters. Instead, it
% prepares measured Raman shift patterns that can later constrain or replace
% the geometry-only mechanical-response proxy.

clear;
clc;

projectDir = fileparts(mfilename('fullpath'));
dataDir = fullfile(projectDir, 'data', 'raman_digitized');
outDir = fullfile(projectDir, 'outputs', 'raman');
if ~exist(outDir, 'dir')
    mkdir(outDir);
end

raman = load_raman_digitized_data(dataDir);
ramanProxy = make_raman_shift_proxy(raman);
summary = summarize_raman_digitized_data(ramanProxy);

writetable(ramanProxy, fullfile(outDir, 'raman_digitized_with_proxies.csv'));
writetable(summary, fullfile(outDir, 'raman_digitized_summary_metrics.csv'));

h = plot_raman_digitized_summary(ramanProxy, summary);
export_chapter_figure(h, outDir, 'raman_digitized_line_scan_summary');

fprintf('\nLoaded %d Raman points across %d scan/mode series.\n', ...
    height(ramanProxy), height(summary));
fprintf('Wrote:\n');
fprintf('  %s\n', fullfile(outDir, 'raman_digitized_with_proxies.csv'));
fprintf('  %s\n', fullfile(outDir, 'raman_digitized_summary_metrics.csv'));
fprintf('  %s\n', fullfile(outDir, 'raman_digitized_line_scan_summary.png'));
