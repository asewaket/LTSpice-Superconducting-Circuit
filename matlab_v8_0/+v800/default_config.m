function cfg = default_config(rootDir)
%DEFAULT_CONFIG Canonical v8 configuration as a MATLAB struct.

if nargin < 1 || isempty(rootDir)
    rootDir = fileparts(fileparts(mfilename('fullpath')));
end

repoRoot = fileparts(rootDir);

cfg = struct();
cfg.modelVersion = 'v8.0-phase2';
cfg.physicsSourceVersion = 'v7.4.6';
cfg.device = 'AS006';
cfg.repoRoot = repoRoot;
cfg.rootDir = rootDir;
cfg.outputDir = fullfile(rootDir, 'outputs', 'v8_0_phase2_as006_reproduction');
cfg.outputSuffix = 'v800_reproduction';
cfg.runFullFieldMaps = false;
cfg.reuseExistingScreeningTables = false;
cfg.seedOverride = NaN;
cfg.scoreTolerance = 1e-9;
cfg.referenceScoreFile = fullfile(repoRoot, 'matlab_v7_4_6_files', 'outputs', ...
    'v7_4_6_as006_gap_weaklink', 'AS006_v7_4_6_gap_weaklink_scores.csv');
cfg.generatedScoreFile = fullfile(repoRoot, 'matlab_v7_4_6_files', 'outputs', ...
    ['v7_4_6_as006_gap_weaklink_' cfg.outputSuffix], ...
    'AS006_v7_4_6_gap_weaklink_scores.csv');
cfg.v8ScoreFile = fullfile(cfg.outputDir, 'AS006_v8_0_phase2_reproduction_scores.csv');
cfg.manifestFile = fullfile(cfg.outputDir, 'RUN_MANIFEST.json');

end

