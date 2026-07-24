function out = run_v77_multiobservable_scoring()
%RUN_V77_MULTIOBSERVABLE_SCORING Score real v7.4.x candidate outputs.
%
% v7.7 consumes existing candidate score ledgers rather than creating new
% physics.  It ranks mechanisms using the v7.6 multi-observable logic and
% explicitly reports which physical-claim gates are not yet satisfied.

add_v77_paths();
opts = make_v77_scoring_options();

if ~exist(opts.outputDir, 'dir')
    mkdir(opts.outputDir);
end

[rawScores, sourceStatus] = load_v77_candidate_score_tables(opts);
candidateScores = compute_v77_candidate_scores(rawScores, opts);
[mechanismSummary, gateSummary] = aggregate_v77_mechanism_scores(candidateScores, opts);

writetable(sourceStatus, fullfile(opts.outputDir, ...
    'AS006_v7_7_source_status.csv'));
writetable(candidateScores, fullfile(opts.outputDir, ...
    'AS006_v7_7_candidate_scores.csv'));
writetable(mechanismSummary, fullfile(opts.outputDir, ...
    'AS006_v7_7_mechanism_summary.csv'));
writetable(gateSummary, fullfile(opts.outputDir, ...
    'AS006_v7_7_gate_summary.csv'));

h = plot_v77_mechanism_ranking(mechanismSummary, gateSummary, sourceStatus, opts);
saveas(h, fullfile(opts.outputDir, 'v7_7_mechanism_ranking.png'));
savefig(h, fullfile(opts.outputDir, 'v7_7_mechanism_ranking.fig'));

out = struct();
out.options = opts;
out.sourceStatus = sourceStatus;
out.candidateScores = candidateScores;
out.mechanismSummary = mechanismSummary;
out.gateSummary = gateSummary;
out.outputDir = opts.outputDir;

fprintf('v7.7 multi-observable scoring exported to:\n%s\n', opts.outputDir);
fprintf('Loaded %d real candidate rows from %d source tables.\n', ...
    height(candidateScores), sum(sourceStatus.loaded));
if any(~sourceStatus.loaded)
    fprintf('Missing source tables were recorded in AS006_v7_7_source_status.csv.\n');
end
if height(mechanismSummary) > 0
    fprintf('Best screening mechanism: %s, objectiveScore = %.4g\n', ...
        string(mechanismSummary.mechanism(1)), mechanismSummary.meanObjectiveScore(1));
end
fprintf(['Physical-claim status: require multi-seed robustness and ablation-Z ' ...
    'before interpreting small score differences mechanistically.\n']);

end

