function opts = make_v77_scoring_options()
%MAKE_V77_SCORING_OPTIONS Configuration for v7.7 multi-observable scoring.

rootDir = fileparts(fileparts(mfilename('fullpath')));

opts = struct();
opts.version = 'v7.7';
opts.device = 'AS006';
opts.repoRoot = rootDir;
opts.outputDir = fullfile(rootDir, 'matlab_v7_7_files', 'outputs', ...
    'v7_7_multiobservable_scoring');

% Component weights are intentionally close to v7.6.  Field-map-derived
% terms are treated as held-out diagnostics, not as a substitute for R(T).
opts.weights = struct();
opts.weights.primaryRT = 1.00;
opts.weights.transitionMetrics = 0.60;
opts.weights.probeAsymmetry = 0.60;
opts.weights.heldoutDiagnostic = 0.40;
opts.weights.complexityPenalty = 0.025;

opts.gates = struct();
opts.gates.minSeeds = 3;
opts.gates.maxRankFractionForScreening = 0.20;
opts.gates.minAblationZ = 2.0;
opts.gates.seedSigmaFloor = 0.005;

% Optional multi-seed screening.  The default v7.7 entry point only reads
% available ledgers.  Run run_v77_multiseed_screening explicitly when you
% want to regenerate v7.4.5/v7.4.6 candidate tables over several disorder
% seeds and then re-run the v7.7 ranking.
opts.multiSeed = struct();
opts.multiSeed.enabledByDefault = false;
opts.multiSeed.seeds = [1101 2202 3303];
opts.multiSeed.sources = ["v7.4.5","v7.4.6"];
opts.multiSeed.ledgerDir = fullfile(opts.outputDir, 'seed_ledgers');
opts.multiSeed.runFullFieldMaps = false;
opts.multiSeed.reuseExistingScreeningTables = false;

opts.sources = [ ...
    source_def('v7.4.3', 'controlled_Wij_ablation', ...
    fullfile(rootDir, 'matlab_v7_4_3_files', 'outputs', ...
    'v7_4_3_as006_wij_ablation', 'AS006_v7_4_3_wij_ablation_scores.csv')); ...
    source_def('v7.4.4', 'physical_bottleneck_Wij', ...
    fullfile(rootDir, 'matlab_v7_4_4_files', 'outputs', ...
    'v7_4_4_as006_physical_bottleneck', 'AS006_v7_4_4_physical_bottleneck_scores.csv')); ...
    source_def('v7.4.5', 'runtime_cleaned_physical_bottleneck_Wij', ...
    fullfile(rootDir, 'matlab_v7_4_5_files', 'outputs', ...
    'v7_4_5_as006_physical_bottleneck', 'AS006_v7_4_5_physical_bottleneck_scores.csv')); ...
    source_def('v7.4.6', 'gap_tied_weak_links', ...
    fullfile(rootDir, 'matlab_v7_4_6_files', 'outputs', ...
    'v7_4_6_as006_gap_weaklink', 'AS006_v7_4_6_gap_weaklink_scores.csv')) ...
    ];

end

function s = source_def(version, role, scoreFile)
s = struct('version', version, 'role', role, 'scoreFile', scoreFile);
end
