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
    [Tp, Ip, Rp, pairReductionNote] = reduce_pair_file_to_rt_if_needed(Tp, Ip, Rp);
    expData.pairData.available = true;
    expData.pairData.T = Tp;
    expData.pairData.I = Ip;
    expData.pairData.R = Rp;
    expData.pairData.sourceFile = info.pairFilePath;
    expData.pairData.reductionNote = pairReductionNote;
    expData.pairData.availableChannels = fieldnames(Rp);
    expData.pairData.hasTopBottomPairs = ...
        isfield(Rp, 'top_4_10') && isfield(Rp, 'bottom_3_9');
    if ~expData.pairData.hasTopBottomPairs
        warning(['Experimental pair file for %s does not contain both ', ...
            'top_4_10 and bottom_3_9 channels. Available channels: %s'], ...
            deviceName, strjoin(expData.pairData.availableChannels, ', '));
    end
elseif ~isempty(info.pairFilePath)
    expData.pairData.sourceFile = info.pairFilePath;
    expData.pairData.availableChannels = {};
    expData.pairData.hasTopBottomPairs = false;
else
    expData.pairData.sourceFile = '';
    expData.pairData.availableChannels = {};
    expData.pairData.hasTopBottomPairs = false;
end

end

function [Tred, Ired, Rred, note] = reduce_pair_file_to_rt_if_needed(T, I, R)
%REDUCE_PAIR_FILE_TO_RT_IF_NEEDED Collapse dVdI-vs-I-vs-T grids to R(T).
%
% Some selected pair files are true R-vs-T files with one row per temperature.
% Others are dVdI(I,T) sweeps with many current values at each temperature.
% For the v7.1 top/bottom R(T) comparison, use the row closest to zero current
% at each temperature. This keeps the pair diagnostic consistent with a
% low-bias four-probe R(T) interpretation while preserving both R1/R2 channels.

T = T(:);
I = I(:);
fields = fieldnames(R);
Tred = T;
Ired = I;
Rred = R;
note = 'no reduction; file already treated as R(T)';

if isempty(T) || isempty(I) || all(~isfinite(I))
    return;
end

[Tu, ~, group] = unique(T);
if numel(Tu) == numel(T)
    return;
end

n = numel(Tu);
idxKeep = NaN(n, 1);
for k = 1:n
    idx = find(group == k);
    [~, local] = min(abs(I(idx)));
    idxKeep(k) = idx(local);
end

Tred = T(idxKeep);
Ired = I(idxKeep);
for k = 1:numel(fields)
    name = fields{k};
    vals = R.(name);
    vals = vals(:);
    if numel(vals) == numel(T)
        Rred.(name) = vals(idxKeep);
    end
end

[Tred, order] = sort(Tred);
Ired = Ired(order);
for k = 1:numel(fields)
    name = fields{k};
    vals = Rred.(name);
    if numel(vals) == numel(order)
        Rred.(name) = vals(order);
    end
end

note = sprintf(['reduced repeated-temperature I-sweep to near-zero-current ', ...
    'R(T); median |I| = %.3g A'], median(abs(Ired), 'omitnan'));

end
