function out = run_v800_phase18B_bidirectional_data_lock()
%RUN_V800_PHASE18B_BIDIRECTIONAL_DATA_LOCK Phase 18B raw data lock.
%
% Locks/import-audits bidirectional sweep-rate raw data declared by the
% frozen Phase 18A protocol. This phase does not fit, average branches,
% substitute proxy data, or execute any transport model.

cfg = v800.phase5_config();
out = v800.run_phase18B_bidirectional_data_lock(cfg);

fprintf('v8.0 Phase 18B bidirectional sweep-rate data lock complete.\n');
end
