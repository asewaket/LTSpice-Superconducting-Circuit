function out = run_v800_phase18_experimental_design_optimization()
%RUN_V800_PHASE18_EXPERIMENTAL_DESIGN_OPTIMIZATION Phase 18 entry point.

add_v800_paths;
cfg = v800.phase5_config();
out = v800.run_phase18_experimental_design_optimization(cfg);

fprintf('v8.0 Phase 18 experimental design optimization complete.\n');
end
