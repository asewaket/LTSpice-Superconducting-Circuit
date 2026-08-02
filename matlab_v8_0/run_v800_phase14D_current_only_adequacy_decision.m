function out = run_v800_phase14D_current_only_adequacy_decision()
%RUN_V800_PHASE14D_CURRENT_ONLY_ADEQUACY_DECISION Run Phase 14D.

add_v800_paths;
cfg = v800.phase5_config();
out = v800.run_phase14D_current_only_adequacy_decision(cfg);
fprintf('v8.0 Phase 14D current-only raw nonlinear adequacy decision complete.\n');
end
