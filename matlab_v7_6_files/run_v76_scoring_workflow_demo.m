function outputs = run_v76_scoring_workflow_demo()
%RUN_V76_SCORING_WORKFLOW_DEMO Export v7.6 score schema and summary figure.
%
% This is intentionally lightweight.  It does not rerun the expensive
% network/PDE/field sweeps.  Instead it creates the score ledger that future
% candidate models should fill, plus a figure summarizing the objective.

rootDir = fileparts(mfilename('fullpath'));
addpath(rootDir);
addpath(fullfile(rootDir, 'lib_v7_1'));

opts = make_v76_multiobservable_score_options();
outDir = fullfile(rootDir, 'outputs', 'v7_6_scoring_workflow');
if ~exist(outDir, 'dir')
    mkdir(outDir);
end

scoreTemplate = make_score_component_template(opts);
gateTemplate = make_meaningfulness_gate_template();
ablationTemplate = make_ablation_template(opts);

writetable(scoreTemplate, fullfile(outDir, 'v7_6_score_component_template.csv'));
writetable(gateTemplate, fullfile(outDir, 'v7_6_meaningfulness_gates.csv'));
writetable(ablationTemplate, fullfile(outDir, 'v7_6_ablation_zscore_template.csv'));

h = plot_v76_score_workflow_summary(scoreTemplate, gateTemplate);
saveas(h, fullfile(outDir, 'v7_6_score_workflow_summary.png'));
savefig(h, fullfile(outDir, 'v7_6_score_workflow_summary.fig'));

outputs = struct();
outputs.options = opts;
outputs.scoreTemplate = scoreTemplate;
outputs.gateTemplate = gateTemplate;
outputs.ablationTemplate = ablationTemplate;
outputs.outputDir = outDir;

fprintf('v7.6 scoring workflow scaffold exported to:\n%s\n', outDir);
fprintf('Core rule: lower objectiveScore is better, but physical conclusions require gate checks.\n');

end

function T = make_score_component_template(opts)

component = {'primary_RT_chi2'; 'secondary_transition_metrics'; ...
    'probe_pair_asymmetry'; 'nonlinear_dVdI_linecuts'; ...
    'complexity_penalty'};
definition = { ...
    'weighted chi-square over available device/probe/temperature points'; ...
    'Tonset, low-T residual R/RN, and 90-10 transition breadth'; ...
    '|R_4-10 - R_3-9| / mean(R_4-10, R_3-9), when both pairs exist'; ...
    'selected measured dV/dI(I) linecuts only; no full B raster in core score'; ...
    'parameter-count penalty plus AICc/BIC bookkeeping'};
weight = [opts.weights.primaryRT; opts.weights.secondaryMetrics; ...
    opts.weights.probeAsymmetry; opts.weights.nonlinearLinecuts; ...
    opts.weights.complexityPenalty];
includeInCoreScore = [true; true; true; true; true];

T = table(component, definition, weight, includeInCoreScore);

end

function T = make_meaningfulness_gate_template()

gate = {'multi_seed_improvement'; 'both_probe_pairs_or_asymmetry_explained'; ...
    'reasonable_parameter_variation'; 'held_out_data'; ...
    'ablation_Z_larger_than_noise'; 'registration_uncertainty_test'};
criterion = { ...
    'candidate improves median score across disorder seeds'; ...
    'candidate helps both pairs or explicitly improves A_probe mismatch'; ...
    'candidate remains competitive under bounded prior/sensitivity sweeps'; ...
    'candidate improves data not used for tuning, e.g. selected dV/dI linecuts'; ...
    'Z_ablation = (S_ablation - S_full)/sigma_seed is meaningfully positive'; ...
    'improvement exceeds Raman registration/digitization uncertainty'};
requiredForPhysicalClaim = true(numel(gate), 1);

T = table(gate, criterion, requiredForPhysicalClaim);

end

function T = make_ablation_template(opts)

caseName = {'full'; 'no_weak_links'; 'uniform_weak_links'; ...
    'shuffled_weak_links'; 'boundary_or_crack_off'; 'central_lane'};
S_full = NaN(numel(caseName), 1);
S_ablation = NaN(numel(caseName), 1);
sigma_seed_eff = repmat(opts.complexity.seedSigmaFloor, numel(caseName), 1);
Z_ablation = NaN(numel(caseName), 1);
interpretation = { ...
    'reference model'; ...
    'tests whether weak links are needed at all'; ...
    'tests whether average weak-link strength is enough'; ...
    'tests whether weak-link spatial registration matters'; ...
    'tests device-specific boundary/crack contribution'; ...
    'tests 2D bypass/current redistribution'};

T = table(caseName, S_full, S_ablation, sigma_seed_eff, Z_ablation, interpretation);

end
