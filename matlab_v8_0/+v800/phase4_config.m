function cfg = phase4_config(rootDir)
%PHASE4_CONFIG Configuration for AS006 identifiability/pruning diagnostics.

if nargin < 1 || isempty(rootDir)
    rootDir = fileparts(fileparts(mfilename('fullpath')));
end

repoRoot = fileparts(rootDir);

cfg = struct();
cfg.modelVersion = 'v8.0-phase4';
cfg.device = 'AS006';
cfg.repoRoot = repoRoot;
cfg.rootDir = rootDir;

cfg.phase3LedgerDir = fullfile(rootDir, 'outputs', ...
    'v8_0_phase3_as006_multiseed', 'seed_ledgers');
cfg.phase3LedgerPattern = 'AS006_v8_0_phase3_seed_*_scores.csv';

cfg.outputDir = fullfile(rootDir, 'outputs', ...
    'v8_0_phase4_identifiability_pruning');
cfg.manifestFile = fullfile(cfg.outputDir, 'RUN_MANIFEST.json');
cfg.candidateScoreFile = fullfile(cfg.outputDir, ...
    'AS006_v8_0_phase4_candidate_scores.csv');
cfg.seedModeWinnerFile = fullfile(cfg.outputDir, ...
    'AS006_v8_0_phase4_seed_mode_winners.csv');
cfg.mechanismSummaryFile = fullfile(cfg.outputDir, ...
    'AS006_v8_0_phase4_mechanism_identifiability.csv');
cfg.parameterBasinFile = fullfile(cfg.outputDir, ...
    'AS006_v8_0_phase4_parameter_basin.csv');
cfg.pruningDecisionFile = fullfile(cfg.outputDir, ...
    'AS006_v8_0_phase4_pruning_decisions.csv');
cfg.figureBaseFile = fullfile(cfg.outputDir, ...
    'AS006_v8_0_phase4_identifiability_pruning');

cfg.expectedFinalSeedCount = 10;
cfg.allowPartialLedgers = true;

cfg.protectedMechanisms = [ ...
    "no weak links"; ...
    "uniform weak links"; ...
    "shuffled weak links"; ...
    "central-lane / 1D-like" ...
    ];
cfg.diagnosticMechanisms = [ ...
    "anisotropic control" ...
    ];

cfg.criteria.topRank = 1;
cfg.criteria.topTwoRank = 2;
cfg.criteria.provisionalTopTwoRate = 0.50;
cfg.criteria.finalTopTwoRate = 0.30;
cfg.criteria.finalWinRate = 0.20;
cfg.criteria.baselineBeatProbability = 0.80;
cfg.criteria.parameterBasinScoreTolerance = 0.02;
cfg.criteria.minNearBestParameterSignatures = 2;
cfg.criteria.minTopTwoRateForTransferPrimary = 0.30;

cfg.baselines.noWeak = 'no weak links';
cfg.baselines.centralLane = 'central-lane / 1D-like';

end
