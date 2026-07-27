function cfg = phase3_config(rootDir)
%PHASE3_CONFIG Configuration for the AS006 multi-seed campaign.

if nargin < 1 || isempty(rootDir)
    rootDir = fileparts(fileparts(mfilename('fullpath')));
end

repoRoot = fileparts(rootDir);

cfg = struct();
cfg.modelVersion = 'v8.0-phase3';
cfg.physicsSourceVersion = 'v7.4.6';
cfg.device = 'AS006';
cfg.repoRoot = repoRoot;
cfg.rootDir = rootDir;

cfg.outputDir = fullfile(rootDir, 'outputs', 'v8_0_phase3_as006_multiseed');
cfg.ledgerDir = fullfile(cfg.outputDir, 'seed_ledgers');
cfg.manifestFile = fullfile(cfg.outputDir, 'RUN_MANIFEST.json');
cfg.statusFile = fullfile(cfg.outputDir, 'AS006_v8_0_phase3_seed_run_status.csv');
cfg.candidateScoreFile = fullfile(cfg.outputDir, 'AS006_v8_0_phase3_candidate_scores.csv');
cfg.mechanismReportFile = fullfile(cfg.outputDir, 'AS006_v8_0_phase3_mechanism_report.csv');
cfg.gateReportFile = fullfile(cfg.outputDir, 'AS006_v8_0_phase3_gate_report.csv');

cfg.seeds = [101 202 303 404 505 606 707 808 909 1010];
cfg.alphaGapValues = [3.3 3.7 4.1];
cfg.gammaWValues = [0.05 0.10 0.20 0.40 0.70];
cfg.pWValues = [0.05 0.10 0.20 0.30];

cfg.runFullFieldMaps = false;
cfg.reuseExistingScreeningTables = false;
cfg.sourceVersion = 'v7.4.6';
cfg.sourceRole = 'gap_tied_weak_links_phase3_seed';
cfg.sourceScript = fullfile(repoRoot, 'matlab_v7_4_6_files', ...
    'run_v746_as006_gap_weaklink_sweep.m');
cfg.sourceOutputBase = fullfile(repoRoot, 'matlab_v7_4_6_files', 'outputs');

cfg.gates.minSeedCount = 10;
cfg.gates.minPassProbability = 0.80;
cfg.gates.minAbsZ = 2.0;
cfg.gates.probeAsymmetryTolerance = 0.02;
cfg.gates.requireBothCalibrationModes = true;
cfg.gates.seedSigmaFloor = 0.005;
cfg.gates.minBothProbeSurvivalRate = 0.80;
cfg.gates.basinScoreTolerance = 0.02;
cfg.gates.minBasinParameterPoints = 2;

cfg.baselines.noWeak = 'no weak links';
cfg.baselines.centralLane = 'central-lane / 1D-like';

end
