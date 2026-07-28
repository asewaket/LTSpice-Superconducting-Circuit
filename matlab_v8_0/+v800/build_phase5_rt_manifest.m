function manifest = build_phase5_rt_manifest(cfg)
%BUILD_PHASE5_RT_MANIFEST Frozen Level-A primary/holdout R(T) map.

rows = repmat(empty_row(), numel(cfg.devices), 1);
for k = 1:numel(cfg.devices)
    device = string(cfg.devices(k));
    mapping = primary_mapping(device);
    expRT = load_rt_safely(device);
    expCurve = select_experimental_curve(expRT, mapping.primaryProbe);

    rows(k).device = device;
    rows(k).primary_probe = mapping.primaryProbe;
    rows(k).experimental_channel = mapping.experimentalChannel;
    rows(k).secondary_probe = mapping.secondaryProbe;
    rows(k).secondary_level = "Level B holdout";
    rows(k).primary_curve_loaded = expCurve.available;
    rows(k).primary_curve_source = expCurve.source;
    rows(k).primary_curve_note = expCurve.note;
    rows(k).secondary_status = secondary_status(expRT, mapping.secondaryProbe);
    rows(k).levelA_status = ternary(expCurve.available, ...
        "ready_primary_rt", "missing_primary_rt");
end

manifest = struct2table(rows);
end

function mapping = primary_mapping(device)
device = upper(string(device));
mapping = struct();
mapping.primaryProbe = "top_4_10";
mapping.experimentalChannel = "R1";
mapping.secondaryProbe = "bottom_3_9";
if device == "AS003"
    mapping.primaryProbe = "bottom_3_9";
    mapping.experimentalChannel = "R2";
    mapping.secondaryProbe = "top_4_10";
end
end

function curve = select_experimental_curve(expRT, primaryProbe)
curve = struct('available', false, 'T', [], 'R', [], ...
    'source', "", 'note', "");
if isempty(expRT) || ~isfield(expRT, 'available') || ~expRT.available
    curve.note = "load_experimental_rt did not return an available R(T) curve";
    return;
end

primaryProbe = char(primaryProbe);
if isfield(expRT, 'pairData') && isfield(expRT.pairData, 'available') && ...
        expRT.pairData.available && isfield(expRT.pairData.R, primaryProbe)
    curve.available = true;
    curve.T = expRT.pairData.T;
    curve.R = expRT.pairData.R.(primaryProbe);
    curve.source = string(expRT.pairData.sourceFile);
    curve.note = "explicit primary probe channel";
elseif isfield(expRT, 'R') && isfield(expRT.R, 'main_4p')
    curve.available = true;
    curve.T = expRT.T;
    curve.R = expRT.R.main_4p;
    curve.source = string(expRT.sourceFile);
    curve.note = "publication main_4p curve mapped to declared primary probe";
else
    curve.note = "no usable main_4p or explicit primary probe channel";
end
end

function status = secondary_status(expRT, secondaryProbe)
status = "not_applicable";
if isempty(expRT) || ~isfield(expRT, 'pairData') || ...
        ~isfield(expRT.pairData, 'available') || ~expRT.pairData.available
    return;
end
if isfield(expRT.pairData.R, char(secondaryProbe))
    status = "available_held_out";
else
    status = "not_applicable";
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

function out = ternary(tf, a, b)
if tf
    out = a;
else
    out = b;
end
end

function row = empty_row()
row = struct();
row.device = "";
row.primary_probe = "";
row.experimental_channel = "";
row.secondary_probe = "";
row.secondary_level = "";
row.primary_curve_loaded = false;
row.primary_curve_source = "";
row.primary_curve_note = "";
row.secondary_status = "";
row.levelA_status = "";
end
