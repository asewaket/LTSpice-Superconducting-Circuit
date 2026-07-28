function manifest = build_phase5_data_manifest(cfg)
%BUILD_PHASE5_DATA_MANIFEST Observable availability authority for Phase 5.

rows = repmat(empty_row(), numel(cfg.devices), 1);
for k = 1:numel(cfg.devices)
    device = string(cfg.devices(k));
    rows(k).device = device;

    expRT = load_rt_safely(device);
    rows(k).has_rt = isfield(expRT, 'available') && expRT.available;
    rows(k).rt_source = "";
    if isfield(expRT, 'sourceFile')
        rows(k).rt_source = string(expRT.sourceFile);
    end

    rows(k).has_second_probe = false;
    rows(k).has_dvdi_it = false;
    rows(k).has_iv = false;
    rows(k).has_raman = has_raman_hint(device);
    rows(k).has_dvdi_ib = false;
    rows(k).has_probe1 = rows(k).has_rt;
    if isfield(expRT, 'pairData') && isfield(expRT.pairData, 'available')
        rows(k).has_second_probe = expRT.pairData.available && ...
            isfield(expRT.pairData, 'hasTopBottomPairs') && ...
            expRT.pairData.hasTopBottomPairs;
        if isfield(expRT.pairData, 'sourceFile') && ...
                strlength(string(expRT.pairData.sourceFile)) > 0
            pairFile = lower(string(expRT.pairData.sourceFile));
            rows(k).has_dvdi_it = contains(pairFile, "dvdi") && contains(pairFile, "ivt");
            rows(k).has_iv = contains(pairFile, "dvdi") || contains(pairFile, "iv");
        end
    end

    expField = load_field_safely(device);
    rows(k).has_dvdi_ib = isfield(expField, 'available') && expField.available;
    rows(k).dvdi_ib_note = "";
    if isfield(expField, 'message')
        rows(k).dvdi_ib_note = string(expField.message);
    end

    tests = strings(0, 1);
    if rows(k).has_rt
        tests(end+1, 1) = "RT"; %#ok<AGROW>
        tests(end+1, 1) = "metrics"; %#ok<AGROW>
    end
    if rows(k).has_second_probe
        tests(end+1, 1) = "probe"; %#ok<AGROW>
    end
    if rows(k).has_iv || rows(k).has_dvdi_it
        tests(end+1, 1) = "selected nonlinear"; %#ok<AGROW>
    end
    if rows(k).has_dvdi_ib
        tests(end+1, 1) = "field-map nonlinear"; %#ok<AGROW>
    end
    if isempty(tests)
        rows(k).eligible_tests = "none";
        rows(k).overall_status = "insufficient_transport_data";
    else
        rows(k).eligible_tests = string(strjoin(cellstr(tests), ', '));
        if rows(k).has_dvdi_ib && rows(k).has_second_probe
            rows(k).overall_status = "eligible_full_transfer";
        elseif rows(k).has_iv || rows(k).has_dvdi_it || rows(k).has_dvdi_ib
            rows(k).overall_status = "eligible_nonlinear_transfer";
        elseif rows(k).has_second_probe
            rows(k).overall_status = "eligible_probe_transfer";
        else
            rows(k).overall_status = "eligible_rt_transfer";
        end
    end
end

manifest = struct2table(rows);
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

function expField = load_field_safely(device)
try
    [~, expField] = evalc('load_v73_experimental_field_dvdi(device);');
catch ME
    expField = struct();
    expField.available = false;
    expField.message = ME.message;
end
end

function tf = has_raman_hint(device)
tf = any(string(device) == ["AS002"; "AS005"; "AS006"]);
end

function row = empty_row()
row = struct();
row.device = "";
row.has_rt = false;
row.has_probe1 = false;
row.has_second_probe = false;
row.has_iv = false;
row.has_dvdi_it = false;
row.has_dvdi_ib = false;
row.has_raman = false;
row.eligible_tests = "";
row.overall_status = "";
row.rt_source = "";
row.dvdi_ib_note = "";
end
