function out = run_v800_phase16C_profile_likelihood_posterior_exploration()
%RUN_V800_PHASE16C_PROFILE_LIKELIHOOD_POSTERIOR_EXPLORATION Phase 16C entry point.

add_v800_paths;
cfg = v800.phase5_config();
out = v800.run_phase16C_profile_likelihood_posterior_exploration(cfg);

fprintf('v8.0 Phase 16C profile/pseudo-posterior exploration complete.\n');
end
