function out = run_v800_phase17_final_release_or_targeted_future_work()
%RUN_V800_PHASE17_FINAL_RELEASE_OR_TARGETED_FUTURE_WORK Phase 17 entry point.

add_v800_paths;
cfg = v800.phase5_config();
out = v800.run_phase17_final_release_or_targeted_future_work(cfg);

fprintf('v8.0 Phase 17 final release/future-work handoff complete.\n');
end
