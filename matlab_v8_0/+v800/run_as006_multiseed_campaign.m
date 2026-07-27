function out = run_as006_multiseed_campaign(cfg)
%RUN_AS006_MULTISEED_CAMPAIGN Generate v8 AS006 seed ledgers.

if ~exist(cfg.outputDir, 'dir')
    mkdir(cfg.outputDir);
end
if ~exist(cfg.ledgerDir, 'dir')
    mkdir(cfg.ledgerDir);
end

statusRows = repmat(empty_status_row(), numel(cfg.seeds), 1);
cleanupObj = onCleanup(@() clear_overrides()); %#ok<NASGU>

fprintf('\nRunning v8.0 Phase 3 AS006 multi-seed campaign.\n');
fprintf('Seeds: %s\n', mat2str(cfg.seeds));
fprintf('alphaGap values: %s\n', mat2str(cfg.alphaGapValues));
fprintf('gammaW values: %s\n', mat2str(cfg.gammaWValues));
fprintf('pW values: %s\n', mat2str(cfg.pWValues));
fprintf('Full field maps during seed campaign: %d\n', cfg.runFullFieldMaps);

for seedIndex = 1:numel(cfg.seeds)
    seedValue = cfg.seeds(seedIndex);
    try
        statusRows(seedIndex) = run_one_seed(cfg, seedValue, ...
            seedIndex, numel(cfg.seeds));
    catch ME
        statusRows(seedIndex) = failed_status_row(cfg, seedValue, ME);
        warning('v8:phase3SeedRunFailed', ...
            'Phase 3 seed run failed for seed %d: %s', seedValue, ME.message);
    end

    clear_overrides();
end

statusTable = struct2table(statusRows);
writetable(statusTable, cfg.statusFile);

out = struct();
out.config = cfg;
out.statusTable = statusTable;
out.statusFile = cfg.statusFile;
out.ledgerDir = cfg.ledgerDir;

end

function row = run_one_seed(cfg, seedValue, seedIndex, seedCount)
%RUN_ONE_SEED Keep legacy script side effects away from the parent loop.

suffix = sprintf('v800_phase3_seed_%d', seedValue);
outputDir = fullfile(cfg.sourceOutputBase, ...
    ['v7_4_6_as006_gap_weaklink_' suffix]);
scoreCsv = fullfile(outputDir, 'AS006_v7_4_6_gap_weaklink_scores.csv');
ledgerCsv = fullfile(cfg.ledgerDir, ...
    sprintf('AS006_v8_0_phase3_seed_%d_scores.csv', seedValue));

row = empty_status_row();
row.sourceVersion = string(cfg.sourceVersion);
row.seed = seedValue;
row.scriptPath = string(cfg.sourceScript);
row.scoreFile = string(scoreCsv);
row.ledgerFile = string(ledgerCsv);

% These names must exist in the same workspace used by run(...), because the
% legacy v7.4.6 script checks V77_KEEP_WORKSPACE before it decides to clear.
global V77_SEED_OVERRIDE V77_OUTPUT_SUFFIX V77_REUSE_EXISTING_SCREENING V77_RUN_FULL_FIELD_MAPS V77_KEEP_WORKSPACE
global V800_ALPHA_GAP_VALUES V800_GAMMAW_VALUES V800_PW_VALUES
V77_SEED_OVERRIDE = seedValue;
V77_OUTPUT_SUFFIX = suffix;
V77_REUSE_EXISTING_SCREENING = cfg.reuseExistingScreeningTables;
V77_RUN_FULL_FIELD_MAPS = cfg.runFullFieldMaps;
V77_KEEP_WORKSPACE = true;
V800_ALPHA_GAP_VALUES = cfg.alphaGapValues;
V800_GAMMAW_VALUES = cfg.gammaWValues;
V800_PW_VALUES = cfg.pWValues;

fprintf('\n[%d/%d] AS006 v7.4.6 seed %d\n', ...
    seedIndex, seedCount, seedValue);
run(cfg.sourceScript);

if exist(scoreCsv, 'file') ~= 2
    error('v8:missingPhase3ScoreCsv', ...
        'Expected score CSV was not created: %s', scoreCsv);
end

T = read_seed_table(scoreCsv);
T.seed = repmat(seedValue, height(T), 1);
T.sourceVersion = repmat(string(cfg.sourceVersion), height(T), 1);
T.sourceRole = repmat(string(cfg.sourceRole), height(T), 1);
T.sourceFile = repmat(string(scoreCsv), height(T), 1);
writetable(T, ledgerCsv);

row.loaded = true;
row.rowCount = height(T);
row.note = "seed ledger written";
end

function row = failed_status_row(cfg, seedValue, ME)
suffix = sprintf('v800_phase3_seed_%d', seedValue);
outputDir = fullfile(cfg.sourceOutputBase, ...
    ['v7_4_6_as006_gap_weaklink_' suffix]);
scoreCsv = fullfile(outputDir, 'AS006_v7_4_6_gap_weaklink_scores.csv');
ledgerCsv = fullfile(cfg.ledgerDir, ...
    sprintf('AS006_v8_0_phase3_seed_%d_scores.csv', seedValue));

row = empty_status_row();
row.sourceVersion = string(cfg.sourceVersion);
row.seed = seedValue;
row.scriptPath = string(cfg.sourceScript);
row.scoreFile = string(scoreCsv);
row.ledgerFile = string(ledgerCsv);
row.loaded = false;
row.note = string(ME.message);
end

function clear_overrides()
global V77_SEED_OVERRIDE V77_OUTPUT_SUFFIX V77_REUSE_EXISTING_SCREENING V77_RUN_FULL_FIELD_MAPS V77_KEEP_WORKSPACE
global V800_ALPHA_GAP_VALUES V800_GAMMAW_VALUES V800_PW_VALUES
V77_SEED_OVERRIDE = [];
V77_OUTPUT_SUFFIX = [];
V77_REUSE_EXISTING_SCREENING = [];
V77_RUN_FULL_FIELD_MAPS = [];
V77_KEEP_WORKSPACE = [];
V800_ALPHA_GAP_VALUES = [];
V800_GAMMAW_VALUES = [];
V800_PW_VALUES = [];
end

function T = read_seed_table(filePath)
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
