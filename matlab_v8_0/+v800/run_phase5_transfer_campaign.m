function out = run_phase5_transfer_campaign(cfg, plan)
%RUN_PHASE5_TRANSFER_CAMPAIGN Build Phase 5 evidence/gate tables.

if nargin < 2 || isempty(plan)
    plan = v800.build_phase5_transfer_plan(cfg);
end

if ~exist(cfg.outputDir, 'dir')
    mkdir(cfg.outputDir);
end
if ~exist(cfg.ledgerDir, 'dir')
    mkdir(cfg.ledgerDir);
end

candidateSet = plan.candidateSet;
devicePlan = plan.devicePlan;
phase4Decisions = plan.phase4Decisions;
phase4Summary = read_table_if_exists(cfg.phase4MechanismSummaryFile);
dataManifest = v800.build_phase5_data_manifest(cfg);

statusTable = build_device_status(cfg, devicePlan, dataManifest);
transferScores = build_transfer_scores(cfg, candidateSet, statusTable, ...
    dataManifest, phase4Summary);
deviceSummary = build_device_summary(cfg, transferScores, candidateSet, statusTable);
leaveOneOut = build_leave_one_out(cfg, transferScores, candidateSet, devicePlan);
gateResults = build_gate_results(cfg, transferScores, deviceSummary, ...
    leaveOneOut, statusTable, phase4Decisions);

writetable(candidateSet, cfg.candidateSetFile);
writetable(devicePlan, cfg.devicePlanFile);
writetable(plan.validationGates, cfg.validationGateFile);
writetable(dataManifest, cfg.dataManifestFile);
writetable(statusTable, cfg.runStatusFile);
writetable(transferScores, cfg.transferScoreFile);
writetable(deviceSummary, cfg.deviceSummaryFile);
writetable(leaveOneOut, cfg.leaveOneOutFile);
writetable(gateResults, cfg.gateResultFile);

try
    h = v800.plot_phase5_transfer_summary(cfg, transferScores, ...
        deviceSummary, leaveOneOut, gateResults);
catch ME
    warning('v8:phase5PlotFailed', ...
        'Phase 5 summary plot failed: %s', ME.message);
    h = [];
end

out = struct();
out.config = cfg;
out.candidateSet = candidateSet;
out.devicePlan = devicePlan;
out.statusTable = statusTable;
out.dataManifest = dataManifest;
out.transferScores = transferScores;
out.deviceSummary = deviceSummary;
out.leaveOneOut = leaveOneOut;
out.gateResults = gateResults;
out.figure = h;
out.paths = struct();
out.paths.candidateSet = cfg.candidateSetFile;
out.paths.devicePlan = cfg.devicePlanFile;
out.paths.validationGates = cfg.validationGateFile;
out.paths.dataManifest = cfg.dataManifestFile;
out.paths.runStatus = cfg.runStatusFile;
out.paths.transferScores = cfg.transferScoreFile;
out.paths.deviceSummary = cfg.deviceSummaryFile;
out.paths.leaveOneOut = cfg.leaveOneOutFile;
out.paths.gateResults = cfg.gateResultFile;
out.paths.figurePng = [cfg.figureBaseFile '.png'];
out.paths.figurePdf = [cfg.figureBaseFile '.pdf'];

end

function statusTable = build_device_status(cfg, devicePlan, dataManifest)
rows = repmat(empty_status_row(), height(devicePlan), 1);
for k = 1:height(devicePlan)
    device = string(devicePlan.device(k));
    manifestIdx = string(dataManifest.device) == device;
    rows(k).device = device;
    rows(k).role = string(devicePlan.role(k));
    rows(k).runAttempted = false;
    rows(k).evidenceAvailable = false;
    rows(k).status = "not_run";
    rows(k).source = "";
    rows(k).note = "";

    if any(manifestIdx)
        j = find(manifestIdx, 1, 'first');
        rows(k).has_rt = logical(dataManifest.has_rt(j));
        rows(k).has_second_probe = logical(dataManifest.has_second_probe(j));
        rows(k).has_iv = logical(dataManifest.has_iv(j));
        rows(k).has_dvdi_it = logical(dataManifest.has_dvdi_it(j));
        rows(k).has_dvdi_ib = logical(dataManifest.has_dvdi_ib(j));
        rows(k).has_raman = logical(dataManifest.has_raman(j));
        rows(k).fieldDataAvailable = rows(k).has_dvdi_ib;
        rows(k).fieldDataMessage = string(dataManifest.dvdi_ib_note(j));
        rows(k).source = string(dataManifest.rt_source(j));
        rows(k).status = string(dataManifest.overall_status(j));
    end

    if rows(k).fieldDataAvailable && cfg.runDeviceSweeps
        rows(k) = run_device_sweep(cfg, device, rows(k));
    elseif rows(k).has_rt
        rows(k).evidenceAvailable = true;
        rows(k).note = "Level A R(T) transfer evidence available.";
    else
        rows(k).status = "insufficient_transport_data";
        rows(k).note = "No common R(T) transfer evidence available.";
    end
end
statusTable = struct2table(rows);
end

function row = run_device_sweep(cfg, device, row)
suffix = sprintf('v800_phase5_%s', lower(char(device)));
scoreCsv = fullfile(cfg.sourceOutputBase, ...
    sprintf('v7_4_6_%s_gap_weaklink_%s', lower(char(device)), suffix), ...
    sprintf('%s_v7_4_6_gap_weaklink_scores.csv', upper(char(device))));

cleanupObj = onCleanup(@() clear_device_overrides()); %#ok<NASGU>
global V77_OUTPUT_SUFFIX V77_REUSE_EXISTING_SCREENING V77_RUN_FULL_FIELD_MAPS V77_KEEP_WORKSPACE
global V800_DEVICE_OVERRIDE V800_TOPOLOGY_FILTER
global V800_ALPHA_GAP_VALUES V800_GAMMAW_VALUES V800_PW_VALUES
V800_DEVICE_OVERRIDE = device;
V800_TOPOLOGY_FILTER = cfg.transferTopologyFilter;
V77_OUTPUT_SUFFIX = suffix;
V77_REUSE_EXISTING_SCREENING = cfg.reuseExistingScreeningTables;
V77_RUN_FULL_FIELD_MAPS = cfg.runFullFieldMaps;
V77_KEEP_WORKSPACE = true;
V800_ALPHA_GAP_VALUES = cfg.alphaGapValues;
V800_GAMMAW_VALUES = cfg.gammaWValues;
V800_PW_VALUES = cfg.pWValues;

try
    run(cfg.sourceScript);
    if exist(scoreCsv, 'file') == 2
        row.runAttempted = true;
        row.evidenceAvailable = true;
        row.status = "completed";
        row.source = string(scoreCsv);
        row.note = "Device sweep completed through v7.4.6 reduced topology set.";
    else
        row.runAttempted = true;
        row.evidenceAvailable = false;
        row.status = "missing_score_file";
        row.source = string(scoreCsv);
        row.note = "v7.4.6 completed without the expected score CSV.";
    end
catch ME
    row.runAttempted = true;
    row.evidenceAvailable = false;
    row.status = "run_failed";
    row.source = string(scoreCsv);
    row.note = string(ME.message);
end
end

function clear_device_overrides()
global V77_OUTPUT_SUFFIX V77_REUSE_EXISTING_SCREENING V77_RUN_FULL_FIELD_MAPS V77_KEEP_WORKSPACE
global V800_DEVICE_OVERRIDE V800_TOPOLOGY_FILTER
global V800_ALPHA_GAP_VALUES V800_GAMMAW_VALUES V800_PW_VALUES
V77_OUTPUT_SUFFIX = [];
V77_REUSE_EXISTING_SCREENING = [];
V77_RUN_FULL_FIELD_MAPS = [];
V77_KEEP_WORKSPACE = [];
V800_DEVICE_OVERRIDE = [];
V800_TOPOLOGY_FILTER = [];
V800_ALPHA_GAP_VALUES = [];
V800_GAMMAW_VALUES = [];
V800_PW_VALUES = [];
end

function scores = build_transfer_scores(cfg, candidateSet, statusTable, dataManifest, phase4Summary)
rows = repmat(empty_score_row(), max(1, height(statusTable) * height(candidateSet) * 2), 1);
row = 0;
modes = ["conductance"; "shape"];
hasPhase4Summary = ~isempty(phase4Summary) && ...
    all(ismember({'mechanism','calibrationMode','meanBestScore','meanRank'}, ...
    phase4Summary.Properties.VariableNames));

for iDevice = 1:height(statusTable)
    device = string(statusTable.device(iDevice));
    available = logical(statusTable.evidenceAvailable(iDevice));
    expRT = load_rt_safely(device);
    for iCand = 1:height(candidateSet)
        mechanism = string(candidateSet.mechanism(iCand));
        role = string(candidateSet.role(iCand));
        includeSweep = logical(candidateSet.includeInTransferSweep(iCand));
        for iMode = 1:numel(modes)
            row = row + 1;
            rows(row) = empty_score_row();
            rows(row).device = device;
            rows(row).mechanism = mechanism;
            rows(row).role = role;
            rows(row).includeInTransferSweep = includeSweep;
            rows(row).calibrationMode = modes(iMode);
            rows(row).evidenceAvailable = false;
            rows(row).score = NaN;
            rows(row).rank = NaN;
            rows(row).source = string(statusTable.source(iDevice));
            rows(row).note = string(statusTable.status(iDevice));

            if ~available
                continue;
            end

            rt = v800.score_rt_transfer(device, mechanism, expRT, cfg);
            if rt.available
                rows(row).evidenceAvailable = true;
                rows(row).score = rt.score;
                rows(row).rank = NaN;
                rows(row).source = string(statusTable.source(iDevice));
                rows(row).observableLevel = "A";
                rows(row).observableFamily = "RT+metrics";
                rows(row).curveScore = rt.curveScore;
                rows(row).metricScore = rt.metricScore;
                rows(row).expClass = rt.expClass;
                rows(row).predictedClass = rt.predictedClass;
                rows(row).exp_rLow = rt.exp_rLow;
                rows(row).model_rLow = rt.model_rLow;
                rows(row).exp_Tonset_K = rt.exp_Tonset_K;
                rows(row).model_Tonset_K = rt.model_Tonset_K;
                rows(row).exp_width90_10_K = rt.exp_width90_10_K;
                rows(row).model_width90_10_K = rt.model_width90_10_K;
                rows(row).note = rt.note;
            elseif device == string(cfg.trainingAnchorDevice) && hasPhase4Summary && ...
                    string(statusTable.status(iDevice)) == "eligible_full_transfer"
                rows(row).note = "Level A R(T) unavailable; nonlinear anchor fallback not used for Level A.";
            else
                rows(row).note = rt.note;
            end
        end
    end
end

scores = struct2table(rows(1:row));
scores = add_baseline_margins(scores);
scores = sortrows(scores, {'device','calibrationMode','score'});
end

function scores = add_baseline_margins(scores)
n = height(scores);
scores.bestRequiredControlScore = NaN(n, 1);
scores.marginVsBestRequiredControl = NaN(n, 1);
scores.beatsRequiredControls = false(n, 1);
scores.beatsNoWeak = false(n, 1);
scores.beatsUniform = false(n, 1);
scores.beatsShuffled = false(n, 1);
scores.beatsCentralLane = false(n, 1);

devices = unique(scores.device, 'stable');
modes = unique(scores.calibrationMode, 'stable');
for iDevice = 1:numel(devices)
    for iMode = 1:numel(modes)
        idx = scores.device == devices(iDevice) & ...
            scores.calibrationMode == modes(iMode) & scores.evidenceAvailable;
        if ~any(idx)
            continue;
        end
        controlIdx = idx & scores.role == "required_control";
        bestControl = NaN;
        if any(controlIdx)
            bestControl = min(scores.score(controlIdx));
        end
        noWeak = score_for(scores, idx, "no weak links");
        uniform = score_for(scores, idx, "uniform weak links");
        shuffled = score_for(scores, idx, "shuffled weak links");
        central = score_for(scores, idx, "central-lane / 1D-like");

        rows = find(idx);
        scores.bestRequiredControlScore(rows) = bestControl;
        scores.marginVsBestRequiredControl(rows) = bestControl - scores.score(rows);
        scores.beatsRequiredControls(rows) = scores.score(rows) < bestControl;
        scores.beatsNoWeak(rows) = scores.score(rows) < noWeak;
        scores.beatsUniform(rows) = scores.score(rows) < uniform;
        scores.beatsShuffled(rows) = scores.score(rows) < shuffled;
        scores.beatsCentralLane(rows) = scores.score(rows) < central;
    end
end
end

function y = score_for(scores, idx, mechanism)
j = idx & scores.mechanism == mechanism & scores.evidenceAvailable;
if any(j)
    y = scores.score(find(j, 1, 'first'));
else
    y = NaN;
end
end

function summary = build_device_summary(cfg, scores, candidateSet, statusTable)
rows = repmat(empty_summary_row(), max(1, numel(cfg.devices) * 2), 1);
row = 0;
modes = ["conductance"; "shape"];

for iDevice = 1:numel(cfg.devices)
    device = string(cfg.devices(iDevice));
    statusIdx = statusTable.device == device;
    for iMode = 1:numel(modes)
        row = row + 1;
        rows(row) = empty_summary_row();
        rows(row).device = device;
        rows(row).calibrationMode = modes(iMode);
        if any(statusIdx)
            rows(row).status = string(statusTable.status(find(statusIdx, 1, 'first')));
        end
        idx = scores.device == device & scores.calibrationMode == modes(iMode) & ...
            scores.evidenceAvailable;
        rows(row).evidenceAvailable = any(idx);
        if ~any(idx)
            rows(row).note = "No scored Phase 5 device evidence available.";
            continue;
        end
        primaryIdx = idx & scores.role == "transfer_primary";
        controlIdx = idx & scores.role == "required_control";
        if any(primaryIdx)
            [rows(row).bestPrimaryScore, local] = min(scores.score(primaryIdx));
            primaryRows = find(primaryIdx);
            rows(row).bestPrimaryMechanism = string(scores.mechanism(primaryRows(local)));
        end
        if any(controlIdx)
            [rows(row).bestControlScore, local] = min(scores.score(controlIdx));
            controlRows = find(controlIdx);
            rows(row).bestControlMechanism = string(scores.mechanism(controlRows(local)));
        end
        rows(row).primaryMarginVsBestControl = ...
            rows(row).bestControlScore - rows(row).bestPrimaryScore;
        rows(row).primaryBeatsRequiredControls = ...
            rows(row).primaryMarginVsBestControl > 0;
        [rows(row).bestAnyScore, local] = min(scores.score(idx));
        allRows = find(idx);
        rows(row).bestAnyMechanism = string(scores.mechanism(allRows(local)));
        rows(row).bestAnyRole = string(scores.role(allRows(local)));
        rows(row).note = "Scored against reduced Phase 5 candidate/control set.";
    end
end

summary = struct2table(rows(1:row));
summary = sortrows(summary, {'device','calibrationMode'});
end

function loo = build_leave_one_out(cfg, scores, candidateSet, devicePlan)
modes = ["conductance"; "shape"];
rows = repmat(empty_loo_row(), max(1, height(devicePlan) * numel(modes)), 1);
row = 0;

for iDevice = 1:height(devicePlan)
    withheld = string(devicePlan.device(iDevice));
    for iMode = 1:numel(modes)
        row = row + 1;
        rows(row) = empty_loo_row();
        rows(row).withheldDevice = withheld;
        rows(row).calibrationMode = modes(iMode);

        trainIdx = scores.device ~= withheld & ...
            scores.calibrationMode == modes(iMode) & ...
            scores.role == "transfer_primary" & ...
            scores.evidenceAvailable;
        rows(row).availableTrainingDeviceCount = numel(unique(scores.device(trainIdx)));
        rows(row).trainingDeviceCount = numel(cfg.devices) - 1;
        if ~any(trainIdx)
            rows(row).status = "incomplete";
            rows(row).note = "No scored training devices after withholding.";
            continue;
        end

        primaries = string(candidateSet.mechanism(string(candidateSet.role) == "transfer_primary"));
        meanScores = NaN(numel(primaries), 1);
        for k = 1:numel(primaries)
            idx = trainIdx & scores.mechanism == primaries(k);
            meanScores(k) = finite_mean(scores.score(idx));
        end
        [bestScore, bestIdx] = min(meanScores);
        rows(row).selectedMechanism = primaries(bestIdx);
        rows(row).trainingMeanScore = bestScore;

        valIdx = scores.device == withheld & ...
            scores.calibrationMode == modes(iMode) & ...
            scores.mechanism == rows(row).selectedMechanism & ...
            scores.evidenceAvailable;
        rows(row).validationEvidenceAvailable = any(valIdx);
        if any(valIdx)
            j = find(valIdx, 1, 'first');
            rows(row).validationMarginVsBestControl = ...
                scores.marginVsBestRequiredControl(j);
            rows(row).validationPass = scores.beatsRequiredControls(j);
            if rows(row).validationPass
                rows(row).status = "pass";
            else
                rows(row).status = "fail";
            end
            rows(row).note = "Withheld device scored.";
        else
            rows(row).status = "incomplete";
            rows(row).note = "Withheld device has no scored Phase 5 evidence.";
        end
    end
end

loo = struct2table(rows(1:row));
end

function gates = build_gate_results(cfg, scores, deviceSummary, loo, statusTable, phase4Decisions)
rows = repmat(empty_gate_row(), 6, 1);
row = 0;
availableDevices = unique(scores.device(scores.evidenceAvailable), 'stable');
requiredDeviceCount = ceil(cfg.requiredEvidenceDeviceFraction * numel(cfg.devices));

row = row + 1;
rows(row).gate = "beats_required_controls";
rows(row).required = true;
modePass = deviceSummary.evidenceAvailable & deviceSummary.primaryBeatsRequiredControls;
modeFail = deviceSummary.evidenceAvailable & ~deviceSummary.primaryBeatsRequiredControls;
if numel(availableDevices) < requiredDeviceCount
    rows(row).status = "incomplete";
elseif any(modeFail)
    rows(row).status = "fail";
else
    rows(row).status = "pass";
end
rows(row).evidence = sprintf('%d/%d devices scored; %d mode rows pass, %d fail.', ...
    numel(availableDevices), numel(cfg.devices), sum(modePass), sum(modeFail));
rows(row).note = "Requires transfer-primary mechanisms to beat protected controls on most devices.";

row = row + 1;
rows(row).gate = "shared_global_rule_set";
rows(row).required = true;
rows(row).status = "pass";
rows(row).evidence = "Phase 5 candidate set and topology filter are shared across devices.";
rows(row).note = "No device-specific weak-link class retuning is introduced.";

row = row + 1;
rows(row).gate = "leave_one_device_out_survival";
rows(row).required = true;
if any(loo.status == "fail")
    rows(row).status = "fail";
elseif all(loo.status == "pass")
    rows(row).status = "pass";
else
    rows(row).status = "incomplete";
end
rows(row).evidence = sprintf('%d pass, %d fail, %d incomplete LOO rows.', ...
    sum(loo.status == "pass"), sum(loo.status == "fail"), ...
    sum(loo.status == "incomplete"));
rows(row).note = "Cannot be complete until withheld devices have scored evidence.";

row = row + 1;
rows(row).gate = "probe_asymmetry_survival";
rows(row).required = true;
rows(row).status = "incomplete";
rows(row).evidence = "Phase 5 does not yet have scored probe/asymmetry diagnostics for all devices.";
rows(row).note = "AS006 asymmetry exists upstream; six-device transfer needs mapped pair diagnostics.";

row = row + 1;
rows(row).gate = "parameter_basin_not_single_point";
rows(row).required = true;
hasPhase4Decisions = ~isempty(phase4Decisions) && ...
    all(ismember({'transferRole','maxParameterBasinCount'}, ...
    phase4Decisions.Properties.VariableNames));
if hasPhase4Decisions
    primaryRows = string(phase4Decisions.transferRole) == "transfer_primary";
else
    primaryRows = false(0, 1);
end
if ~hasPhase4Decisions || ~any(primaryRows)
    rows(row).status = "incomplete";
    rows(row).evidence = "Phase 4 pruning decision table unavailable.";
elseif all(phase4Decisions.maxParameterBasinCount(primaryRows) >= 2)
    rows(row).status = "pass";
    rows(row).evidence = sprintf('Minimum primary Phase 4 basin count = %.4g.', ...
        min(phase4Decisions.maxParameterBasinCount(primaryRows)));
else
    rows(row).status = "fail";
    rows(row).evidence = sprintf('Minimum primary Phase 4 basin count = %.4g.', ...
        min(phase4Decisions.maxParameterBasinCount(primaryRows)));
end
rows(row).note = "Inherited from Phase 4 pruning decisions for transfer-primary candidates.";

row = row + 1;
rows(row).gate = "explicit_failure_accounting";
rows(row).required = true;
if height(statusTable) == numel(cfg.devices) && all(strlength(statusTable.status) > 0)
    rows(row).status = "pass";
else
    rows(row).status = "fail";
end
rows(row).evidence = sprintf('%d device status rows written.', height(statusTable));
rows(row).note = "Unavailable devices are reported rather than hidden by retuning.";

gates = struct2table(rows(1:row));
end

function expField = load_field_safely(device)
try
    [~, expField] = evalc('load_v73_experimental_field_dvdi(device);');
catch ME
    expField = struct();
    expField.available = false;
    expField.message = ME.message;
end
if ~isfield(expField, 'message')
    expField.message = "";
end
end

function expRT = load_rt_safely(device)
try
    [~, expRT] = evalc('load_experimental_rt(device);');
catch ME
    expRT = struct();
    expRT.available = false;
    expRT.sourceFile = "";
    expRT.note = ME.message;
end
end

function T = read_table_if_exists(filePath)
if exist(filePath, 'file') ~= 2
    T = table();
    return;
end
try
    T = readtable(filePath, 'TextType', 'string');
catch
    T = readtable(filePath);
end
end

function y = finite_mean(x)
x = x(isfinite(x));
if isempty(x)
    y = NaN;
else
    y = mean(x);
end
end

function row = empty_status_row()
row = struct();
row.device = "";
row.role = "";
row.has_rt = false;
row.has_second_probe = false;
row.has_iv = false;
row.has_dvdi_it = false;
row.has_dvdi_ib = false;
row.has_raman = false;
row.fieldDataAvailable = false;
row.fieldDataMessage = "";
row.runAttempted = false;
row.evidenceAvailable = false;
row.status = "";
row.source = "";
row.note = "";
end

function row = empty_score_row()
row = struct();
row.device = "";
row.mechanism = "";
row.role = "";
row.includeInTransferSweep = false;
row.calibrationMode = "";
row.observableLevel = "";
row.observableFamily = "";
row.evidenceAvailable = false;
row.score = NaN;
row.rank = NaN;
row.curveScore = NaN;
row.metricScore = NaN;
row.expClass = "";
row.predictedClass = "";
row.exp_rLow = NaN;
row.model_rLow = NaN;
row.exp_Tonset_K = NaN;
row.model_Tonset_K = NaN;
row.exp_width90_10_K = NaN;
row.model_width90_10_K = NaN;
row.bestRequiredControlScore = NaN;
row.marginVsBestRequiredControl = NaN;
row.beatsRequiredControls = false;
row.beatsNoWeak = false;
row.beatsUniform = false;
row.beatsShuffled = false;
row.beatsCentralLane = false;
row.source = "";
row.note = "";
end

function row = empty_summary_row()
row = struct();
row.device = "";
row.calibrationMode = "";
row.status = "";
row.evidenceAvailable = false;
row.bestPrimaryMechanism = "";
row.bestPrimaryScore = NaN;
row.bestControlMechanism = "";
row.bestControlScore = NaN;
row.primaryMarginVsBestControl = NaN;
row.primaryBeatsRequiredControls = false;
row.bestAnyMechanism = "";
row.bestAnyRole = "";
row.bestAnyScore = NaN;
row.note = "";
end

function row = empty_loo_row()
row = struct();
row.withheldDevice = "";
row.calibrationMode = "";
row.trainingDeviceCount = 0;
row.availableTrainingDeviceCount = 0;
row.selectedMechanism = "";
row.trainingMeanScore = NaN;
row.validationEvidenceAvailable = false;
row.validationMarginVsBestControl = NaN;
row.validationPass = false;
row.status = "";
row.note = "";
end

function row = empty_gate_row()
row = struct();
row.gate = "";
row.required = true;
row.status = "";
row.evidence = "";
row.note = "";
end
