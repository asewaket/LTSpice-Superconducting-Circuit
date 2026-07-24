function out = run_v771_mechanism_evidence_report()
%RUN_V771_MECHANISM_EVIDENCE_REPORT Build the v7.7.1 claim-readiness report.
%
% This script does not introduce a new physical model. It reads the real
% v7.7 multi-observable score tables and reports:
%   - multi-observable objective score,
%   - seed-to-seed variability,
%   - ablation Z-score relative to baselines,
%   - whether both probe pairs are represented,
%   - whether each mechanism beats no-weak-link and central-lane baselines.

rootDir = add_v771_paths();
opts = make_v771_options(rootDir);

if ~exist(opts.outputDir, 'dir')
    mkdir(opts.outputDir);
end

[evidence, gates, candidateScores, sourceInfo] = build_v771_evidence_report(opts);

evidencePath = fullfile(opts.outputDir, sprintf('%s_v7_7_1_mechanism_evidence.csv', opts.device));
gatesPath = fullfile(opts.outputDir, sprintf('%s_v7_7_1_gate_matrix.csv', opts.device));
candidatesPath = fullfile(opts.outputDir, sprintf('%s_v7_7_1_candidate_scores.csv', opts.device));

writetable(evidence, evidencePath);
writetable(gates, gatesPath);
writetable(candidateScores, candidatesPath);

h = plot_v771_evidence_report(evidence, gates, opts);
savefig(h, fullfile(opts.outputDir, 'v7_7_1_mechanism_evidence_report.fig'));
exportgraphics(h, fullfile(opts.outputDir, 'v7_7_1_mechanism_evidence_report.png'), ...
    'Resolution', 300);

fprintf('v7.7.1 mechanism evidence report exported to:\n%s\n', opts.outputDir);
fprintf('Core rule: lower objectiveScore is better, but physical conclusions require all gate checks.\n');

out = struct();
out.options = opts;
out.evidence = evidence;
out.gates = gates;
out.candidateScores = candidateScores;
out.sourceInfo = sourceInfo;
out.outputFiles = struct('evidence', evidencePath, ...
    'gates', gatesPath, 'candidateScores', candidatesPath);

end
