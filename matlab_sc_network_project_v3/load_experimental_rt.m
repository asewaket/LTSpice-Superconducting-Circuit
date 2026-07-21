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

end
