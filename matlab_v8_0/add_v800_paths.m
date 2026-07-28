function rootDir = add_v800_paths()
%ADD_V800_PATHS Add the canonical v8 orchestration path.

rootDir = fileparts(mfilename('fullpath'));
repoRoot = fileparts(rootDir);

addpath(rootDir, '-begin');

% v8 currently reuses the v7.4.6 physics engine rather than duplicating it.
v746Dir = fullfile(repoRoot, 'matlab_v7_4_6_files');
v746LibDir = fullfile(v746Dir, 'lib_v7_1');
if exist(v746Dir, 'dir')
    addpath(v746Dir, '-begin');
end
if exist(v746LibDir, 'dir')
    addpath(v746LibDir, '-begin');
end

% Scoring/evidence folders are read by later validation phases.
v76Dir = fullfile(repoRoot, 'matlab_v7_6_files');
v77Dir = fullfile(repoRoot, 'matlab_v7_7_files');
v771Dir = fullfile(repoRoot, 'matlab_v7_7_1_files');
if exist(v76Dir, 'dir')
    addpath(v76Dir, '-end');
end
if exist(v77Dir, 'dir')
    addpath(v77Dir, '-end');
end
if exist(v771Dir, 'dir')
    addpath(v771Dir, '-end');
end

clear run_v800_release
clear run_v800_phase3_as006_multiseed
clear run_v800_phase4_identifiability_pruning
clear run_v800_phase5_transfer_plan
clear v800.default_config
clear v800.run_as006_v746_reproduction
clear v800.phase3_config
clear v800.run_as006_multiseed_campaign
clear v800.build_as006_multiseed_report
clear v800.phase4_config
clear v800.build_phase4_identifiability_report
clear v800.plot_phase4_pruning_summary
clear v800.phase5_config
clear v800.build_phase5_transfer_plan
clear v800.run_phase5_transfer_campaign
clear v800.plot_phase5_transfer_summary
clear v800.build_phase5_data_manifest
clear v800.score_rt_transfer
clear v800.score_probe_transfer
clear v800.score_nonlinear_transfer
clear run_v800_phase5A_frozen_rt_transfer
clear v800.run_phase5A_frozen_rt_transfer
clear v800.build_phase5_rt_manifest
clear v800.select_phase5A_frozen_basin
clear v800.score_normalized_rt
clear v800.plot_phase5A_rt_transfer_summary
clear run_v800_phase5B_secondary_validation
clear v800.run_phase5B_secondary_validation
clear v800.score_probe_asymmetry
clear v800.plot_phase5B_secondary_summary

end
