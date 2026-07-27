function out = build_phase5_transfer_plan(cfg)
%BUILD_PHASE5_TRANSFER_PLAN Write reduced candidate/device/gate tables.

if ~exist(cfg.outputDir, 'dir')
    mkdir(cfg.outputDir);
end

phase4Decisions = read_phase4_decisions(cfg.phase4DecisionFile);
candidateSet = make_candidate_set(cfg, phase4Decisions);
devicePlan = make_device_plan(cfg);
validationGates = make_validation_gates();

writetable(candidateSet, cfg.candidateSetFile);
writetable(devicePlan, cfg.devicePlanFile);
writetable(validationGates, cfg.validationGateFile);

out = struct();
out.config = cfg;
out.phase4Decisions = phase4Decisions;
out.candidateSet = candidateSet;
out.devicePlan = devicePlan;
out.validationGates = validationGates;
out.paths = struct();
out.paths.candidateSet = cfg.candidateSetFile;
out.paths.devicePlan = cfg.devicePlanFile;
out.paths.validationGates = cfg.validationGateFile;

end

function T = read_phase4_decisions(pathToFile)
if exist(pathToFile, 'file') == 2
    try
        T = readtable(pathToFile, 'TextType', 'string');
    catch
        T = readtable(pathToFile);
    end
else
    T = table();
end
end

function T = make_candidate_set(cfg, phase4Decisions)
mechanism = [cfg.transferPrimary; cfg.requiredControls; ...
    cfg.diagnosticControls; cfg.diagnosticHold];
role = [repmat("transfer_primary", numel(cfg.transferPrimary), 1); ...
    repmat("required_control", numel(cfg.requiredControls), 1); ...
    repmat("diagnostic_control", numel(cfg.diagnosticControls), 1); ...
    repmat("diagnostic_hold", numel(cfg.diagnosticHold), 1)];
includeInTransferSweep = role == "transfer_primary" | role == "required_control";
includeAsDiagnostic = role == "diagnostic_control" | role == "diagnostic_hold";
phase4Decision = repmat("", numel(mechanism), 1);

if ~isempty(phase4Decisions) && any(strcmp(phase4Decisions.Properties.VariableNames, 'mechanism'))
    for k = 1:numel(mechanism)
        idx = string(phase4Decisions.mechanism) == mechanism(k);
        if any(idx) && any(strcmp(phase4Decisions.Properties.VariableNames, 'decision'))
            phase4Decision(k) = string(phase4Decisions.decision(find(idx, 1, 'first')));
        end
    end
end

notes = strings(numel(mechanism), 1);
for k = 1:numel(mechanism)
    switch char(role(k))
        case 'transfer_primary'
            notes(k) = "Retained from AS006 Phase 4 for six-device transfer.";
        case 'required_control'
            notes(k) = "Protected baseline required by MODEL_SCOPE.";
        case 'diagnostic_control'
            notes(k) = "Diagnostic control; not a primary physical transfer class.";
        otherwise
            notes(k) = "Diagnostic hold; not transfer-primary unless later evidence promotes it.";
    end
end

T = table(mechanism, role, includeInTransferSweep, includeAsDiagnostic, ...
    phase4Decision, notes);
end

function T = make_device_plan(cfg)
device = cfg.devices;
role = repmat("validation_device", numel(device), 1);
role(device == cfg.trainingAnchorDevice) = "AS006_anchor_and_validation";
useSharedGlobalRules = true(numel(device), 1);
allowDeviceSpecificWeakLinkRetuning = false(numel(device), 1);
includeLeaveOneDeviceOut = true(numel(device), 1);
notes = repmat("Use same reduced candidate set and report failures explicitly.", ...
    numel(device), 1);
T = table(device, role, useSharedGlobalRules, ...
    allowDeviceSpecificWeakLinkRetuning, includeLeaveOneDeviceOut, notes);
end

function T = make_validation_gates()
gate = [ ...
    "beats_required_controls"; ...
    "shared_global_rule_set"; ...
    "leave_one_device_out_survival"; ...
    "probe_asymmetry_survival"; ...
    "parameter_basin_not_single_point"; ...
    "explicit_failure_accounting" ...
    ];
required = true(numel(gate), 1);
description = [ ...
    "Transfer-primary mechanism beats no/uniform/shuffled/central controls on most devices."; ...
    "No device-specific weak-link class retuning."; ...
    "Conclusions survive leave-one-device-out checks."; ...
    "Probe-pair/asymmetry diagnostics remain acceptable where data exist."; ...
    "Preferred mechanism is supported by a basin, not one isolated parameter point."; ...
    "Device failures are reported rather than hidden by retuning." ...
    ];
T = table(gate, required, description);
end
