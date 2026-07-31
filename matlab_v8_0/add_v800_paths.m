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
clear run_v800_phase5B1_activation_law_validation
clear v800.run_phase5B1_activation_law_validation
clear v800.plot_phase5B1_activation_summary
clear run_v800_phase5B2_full_series_activation_consolidation
clear v800.run_phase5B2_full_series_activation_consolidation
clear v800.plot_phase5B2_full_series_summary
clear run_v800_phase5C_synthetic_recovery
clear v800.run_phase5C_synthetic_recovery
clear v800.plot_phase5C_synthetic_recovery_summary
clear run_v800_phase5D_calibration_plan
clear v800.build_phase5D_calibration_plan
clear run_v800_phase5D1_calibrate_m0star
clear v800.run_phase5D1_calibrate_m0star
clear v800.plot_phase5D_calibration_summary
clear run_v800_phase5D2_result_freeze
clear v800.run_phase5D2_result_freeze
clear v800.plot_phase5D2_result_freeze_summary
clear run_v800_phase6_hierarchical_evidence_freeze
clear v800.run_phase6_hierarchical_evidence_freeze
clear v800.plot_phase6_hierarchical_evidence_summary
clear v800.git_tree_status
clear v800.capture_source_provenance
clear run_v800_phase5C_phase5D_artifact_generation
clear run_v800_phase10_reproducible_release
clear v800.run_phase10_reproducible_release
clear v800.plot_phase10_reproducible_release
clear run_v800_phase11_multimodal_data_architecture
clear v800.run_phase11_multimodal_data_architecture
clear v800.plot_phase11_multimodal_architecture_summary
clear run_v800_phase12A_raman_registration_feasibility
clear v800.run_phase12A_raman_registration_feasibility
clear v800.plot_phase12A_raman_registration_feasibility
clear run_v800_phase12B_reduced_mechanical_forward_model
clear v800.run_phase12B_reduced_mechanical_forward_model
clear v800.plot_phase12B_reduced_mechanical_summary
clear run_v800_phase12C_raman_forward_feasibility
clear v800.run_phase12C_raman_forward_feasibility
clear v800.plot_phase12C_raman_forward_summary
clear run_v800_phase13A_constitutive_mapping_freeze
clear v800.run_phase13A_constitutive_mapping_freeze
clear v800.plot_phase13A_constitutive_mapping_summary
clear run_v800_phase13B_limiting_case_verification
clear v800.run_phase13B_limiting_case_verification
clear v800.plot_phase13B_limiting_case_summary

end
