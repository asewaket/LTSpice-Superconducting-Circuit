function out = run_v77_multiseed_screening()
%RUN_V77_MULTISEED_SCREENING Regenerate selected v7.4.x sweeps over seeds.
%
% This optional runner is intentionally separate from
% run_v77_multiobservable_scoring.  It creates seed-resolved candidate
% ledgers for the expensive v7.4.5/v7.4.6 AS006 screening sweeps, with full
% 121x121 field maps disabled by default.  After it finishes, rerun
% run_v77_multiobservable_scoring to fold the seed ledgers into the
% multi-observable mechanism ranking and ablation-Z estimates.

add_v77_paths();
v77opts = make_v77_scoring_options();
if ~exist(v77opts.outputDir, 'dir')
    mkdir(v77opts.outputDir);
end
if ~exist(v77opts.multiSeed.ledgerDir, 'dir')
    mkdir(v77opts.multiSeed.ledgerDir);
end

cleanupObj = onCleanup(@() clear_v77_override_globals()); %#ok<NASGU>

versions = v77opts.multiSeed.sources;
seeds = v77opts.multiSeed.seeds(:).';
nRuns = numel(versions) .* numel(seeds);
statusRows = repmat(empty_status_row(), nRuns, 1);
row = 0;

fprintf('\nRunning v7.7 optional multi-seed screening.\n');
fprintf('Seeds: %s\n', mat2str(seeds));
fprintf('Sources: %s\n', strjoin(cellstr(versions), ', '));
fprintf('Full field maps during seed screening: %d\n', v77opts.multiSeed.runFullFieldMaps);

for version = versions
    for seedValue = seeds
        row = row + 1;
        suffix = sprintf('v77_seed_%d', seedValue);
        try
            [scriptPath, scoreCsv, role, ledgerCsv] = source_paths(v77opts, version, suffix, seedValue);
        catch ME
            statusRows(row).sourceVersion = string(version);
            statusRows(row).seed = seedValue;
            statusRows(row).loaded = false;
            statusRows(row).note = "path resolution failed: " + string(ME.message);
            warning('v7.7:seedPathFailed', ...
                'Could not resolve seed run paths for %s seed %d: %s', ...
                char(version), seedValue, ME.message);
            continue;
        end

        statusRows(row).sourceVersion = string(version);
        statusRows(row).seed = seedValue;
        statusRows(row).scriptPath = string(scriptPath);
        statusRows(row).scoreFile = string(scoreCsv);
        statusRows(row).ledgerFile = string(ledgerCsv);

        try
            global V77_SEED_OVERRIDE V77_OUTPUT_SUFFIX V77_REUSE_EXISTING_SCREENING V77_RUN_FULL_FIELD_MAPS V77_KEEP_WORKSPACE
            V77_SEED_OVERRIDE = seedValue;
            V77_OUTPUT_SUFFIX = suffix;
            V77_REUSE_EXISTING_SCREENING = v77opts.multiSeed.reuseExistingScreeningTables;
            V77_RUN_FULL_FIELD_MAPS = v77opts.multiSeed.runFullFieldMaps;
            V77_KEEP_WORKSPACE = true;

            fprintf('\n[%d/%d] %s, seed %d\n', row, nRuns, char(version), seedValue);
            run(scriptPath);

            if exist(scoreCsv, 'file') ~= 2
                error('v7.7:missingSeedScoreCsv', ...
                    'Expected score CSV was not created: %s', scoreCsv);
            end

            T = read_v77_seed_table(scoreCsv);
            T.seed = repmat(seedValue, height(T), 1);
            T.sourceVersion = repmat(string(version), height(T), 1);
            T.sourceRole = repmat(string(role), height(T), 1);
            T.sourceFile = repmat(string(scoreCsv), height(T), 1);
            writetable(T, ledgerCsv);

            statusRows(row).loaded = true;
            statusRows(row).rowCount = height(T);
            statusRows(row).note = "seed ledger written";
            fprintf('Wrote seed ledger: %s\n', ledgerCsv);
        catch ME
            statusRows(row).loaded = false;
            statusRows(row).note = string(ME.message);
            warning('v7.7:seedRunFailed', ...
                'Seed run failed for %s seed %d: %s', ...
                char(version), seedValue, ME.message);
        end

        clear_v77_override_globals();
    end
end

statusTable = struct2table(statusRows);
statusCsv = fullfile(v77opts.multiSeed.ledgerDir, 'AS006_v7_7_multiseed_run_status.csv');
writetable(statusTable, statusCsv);

out = struct();
out.options = v77opts;
out.statusTable = statusTable;
out.statusCsv = statusCsv;
out.ledgerDir = v77opts.multiSeed.ledgerDir;

fprintf('\nv7.7 multi-seed screening status exported to:\n%s\n', statusCsv);
fprintf('Next step: run_v77_multiobservable_scoring to recompute mechanism gates.\n');

end

function [scriptPath, scoreCsv, role, ledgerCsv] = source_paths(v77opts, version, suffix, seedValue)
repoRoot = v77opts.repoRoot;
switch char(version)
    case 'v7.4.5'
        scriptPath = fullfile(repoRoot, 'matlab_v7_4_5_files', ...
            'run_v745_as006_physical_bottleneck_sweep.m');
        outputDir = fullfile(repoRoot, 'matlab_v7_4_5_files', 'outputs', ...
            ['v7_4_5_as006_physical_bottleneck_' suffix]);
        scoreCsv = fullfile(outputDir, 'AS006_v7_4_5_physical_bottleneck_scores.csv');
        role = "runtime_cleaned_physical_bottleneck_Wij_seed";
        ledgerName = sprintf('AS006_v7_4_5_seed_%d_scores.csv', seedValue);
    case 'v7.4.6'
        scriptPath = fullfile(repoRoot, 'matlab_v7_4_6_files', ...
            'run_v746_as006_gap_weaklink_sweep.m');
        outputDir = fullfile(repoRoot, 'matlab_v7_4_6_files', 'outputs', ...
            ['v7_4_6_as006_gap_weaklink_' suffix]);
        scoreCsv = fullfile(outputDir, 'AS006_v7_4_6_gap_weaklink_scores.csv');
        role = "gap_tied_weak_links_seed";
        ledgerName = sprintf('AS006_v7_4_6_seed_%d_scores.csv', seedValue);
    otherwise
        error('v7.7:unknownSeedSource', 'Unknown v7.7 seed source: %s', char(version));
end

ledgerCsv = fullfile(v77opts.multiSeed.ledgerDir, ledgerName);
end

function T = read_v77_seed_table(filePath)
try
    T = readtable(filePath, 'TextType', 'string');
catch
    T = readtable(filePath);
end
end

function row = empty_status_row()
row = struct();
row.sourceVersion = "";
row.seed = NaN;
row.scriptPath = "";
row.scoreFile = "";
row.ledgerFile = "";
row.loaded = false;
row.rowCount = 0;
row.note = "";
end

function clear_v77_override_globals()
global V77_SEED_OVERRIDE V77_OUTPUT_SUFFIX V77_REUSE_EXISTING_SCREENING V77_RUN_FULL_FIELD_MAPS V77_KEEP_WORKSPACE
V77_SEED_OVERRIDE = [];
V77_OUTPUT_SUFFIX = [];
V77_REUSE_EXISTING_SCREENING = [];
V77_RUN_FULL_FIELD_MAPS = [];
V77_KEEP_WORKSPACE = [];
end
