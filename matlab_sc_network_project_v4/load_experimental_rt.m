function expData = load_experimental_rt(deviceName)
%LOAD_EXPERIMENTAL_RT Load exported experimental R(T) data for one AS device.
%
% Returns a struct with:
%   available: true/false
%   T: temperature vector
%   I: excitation/current vector if available
%   R: struct of resistance channels
%   sourceFile: file path

deviceName = upper(char(deviceName));
table = make_experiment_data_table();

if ~isfield(table, deviceName)
    error('Unknown device "%s".', deviceName);
end

info = table.(deviceName);

expData = struct();
expData.device = deviceName;
expData.available = false;
expData.rawLabel = info.rawLabel;
expData.sourceFile = info.filePath;
expData.note = info.note;
expData.modelPair = info.modelPair;
expData.pairFilePath = info.pairFilePath;
expData.T = [];
expData.I = [];
expData.R = struct();

if isempty(info.filePath) || ~exist(info.filePath, 'file')
    warning('No mapped experimental R(T) file for %s. %s', deviceName, info.note);
    return;
end

[T, I, R] = load_rt_dat_file(info.filePath);

expData.available = true;
expData.T = T;
expData.I = I;
expData.R = R;

% If a direct low-current R(T) file with explicit R1/R2 channels is available,
% keep those channels too. The curated publication CSV remains the selected
% main curve, while pairData enables 4-10 / 3-9 comparisons where possible.
expData.pairData = struct('available', false, 'T', [], 'I', [], 'R', struct());
if ~isempty(info.pairFilePath) && exist(info.pairFilePath, 'file')
    [Tp, Ip, Rp] = load_rt_dat_file(info.pairFilePath);
    expData.pairData.available = true;
    expData.pairData.T = Tp;
    expData.pairData.I = Ip;
    expData.pairData.R = Rp;
    expData.pairData.sourceFile = info.pairFilePath;
end

end
