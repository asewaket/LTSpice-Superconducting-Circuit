function outputs = run_v71_three_device_pde_scaffold(devices)
%RUN_V71_THREE_DEVICE_PDE_SCAFFOLD Run the v7.1 PDE workflow for 002/005/006.
%
% Usage:
%   run_v71_three_device_pde_scaffold
%   outputs = run_v71_three_device_pde_scaffold({'AS002','AS005','AS006'});

if nargin < 1 || isempty(devices)
    devices = {'AS002','AS005','AS006'};
end

outputs = struct();
for k = 1:numel(devices)
    device = upper(char(devices{k}));
    fprintf('\n============================================================\n');
    fprintf('v7.1 PDE scaffold batch item %d/%d: %s\n', k, numel(devices), device);
    fprintf('============================================================\n');
    outputs.(device) = run_v71_device_pde_scaffold(device);
end

projectDir = fileparts(mfilename('fullpath'));
outDir = fullfile(projectDir, 'outputs', 'v7_1_device_pde_scaffold');
T = summarize_v71_batch_outputs(outputs);
writetable(T, fullfile(outDir, 'v7_1_three_device_PDE_scaffold_summary.csv'));

fprintf('\nFinished v7.1 three-device PDE scaffold batch.\n');
fprintf('Batch summary written to:\n%s\n', ...
    fullfile(outDir, 'v7_1_three_device_PDE_scaffold_summary.csv'));

end

function T = summarize_v71_batch_outputs(outputs)

names = fieldnames(outputs);
rows = cell(numel(names), 1);
for k = 1:numel(names)
    O = outputs.(names{k});
    S = O.summary;
    A = S.asymmetry;
    row = struct();
    row.device = string(S.device);
    row.filmForce_Npm = S.filmForce_Npm;
    row.filmForceLabel = string(S.filmForceLabel);
    row.combinedScore = S.scoreInfo.combinedScore;
    row.metricScore = S.scoreInfo.metricScore;
    row.shapeScore = S.scoreInfo.shapeScore;
    row.modelPair = string(S.scoreInfo.modelPair);
    row.meanEta = S.meanEta;
    row.maxEta = S.maxEta;
    row.meanContactRelaxation = S.meanContactRelaxation;
    row.asym_experimentAvailable = logical(A.experimentAvailable);
    row.asym_modelDeltaRms = A.modelDeltaRms;
    row.asym_expDeltaRms = A.expDeltaRms;
    row.asym_deltaMismatchRms = A.deltaMismatchRms;
    row.asymmetryFailureFlag = logical(A.asymmetryFailureFlag);
    rows{k} = row;
end

T = struct2table([rows{:}]);

end
