function out = run_v800_phase18A_bidirectional_sweep_protocol()
%RUN_V800_PHASE18A_BIDIRECTIONAL_SWEEP_PROTOCOL Phase 18A entry point.

cfg = v800.phase5_config();
out = v800.run_phase18A_bidirectional_sweep_protocol(cfg);

fprintf('v8.0 Phase 18A bidirectional sweep-rate protocol freeze complete.\n');
end
