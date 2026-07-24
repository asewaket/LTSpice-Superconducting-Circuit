function opts = make_v771_options(rootDir)
%MAKE_V771_OPTIONS Shared options for the v7.7.1 evidence report.

if nargin < 1 || isempty(rootDir)
    rootDir = fileparts(fileparts(mfilename('fullpath')));
end

opts = struct();
opts.version = 'v7.7.1';
opts.device = 'AS006';
opts.repoRoot = rootDir;

opts.v77OutputDir = fullfile(rootDir, ...
    'matlab_v7_7_files', 'outputs', 'v7_7_multiobservable_scoring');
opts.outputDir = fullfile(rootDir, ...
    'matlab_v7_7_1_files', 'outputs', 'v7_7_1_mechanism_evidence_report');

opts.minSeedCountForClaim = 3;
opts.minAbsZForClaim = 2.0;
opts.scoreTolerance = 1e-6;
opts.probeAsymmetryTolerance = 0.02;
opts.largeDiagnosticCutoff = 1e3;

opts.baselineNoWeak = "no weak links";
opts.baselineCentralLane = "central-lane / 1D-like";

end
