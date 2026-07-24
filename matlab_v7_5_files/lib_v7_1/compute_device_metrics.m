function metrics = compute_device_metrics(net, spec, params, result, model)
%COMPUTE_DEVICE_METRICS Qualitative metrics for chapter-level comparison.

pairNames = fieldnames(result.R4p);
mainPair = pairNames{1};
R = result.R4p.(mainPair);
T = result.T;

nLow = min(model.metrics.lowTempCount, numel(T));
nHigh = min(model.metrics.highTempCount, numel(T));

RN = local_nanmean(R(end-nHigh+1:end));
Rlow = local_nanmean(R(1:nLow));

threshold = RN * (1 - model.metrics.onsetDropFrac);
idx = find(R < threshold, 1, 'last');
if isempty(idx)
    Tonset = NaN;
else
    Tonset = T(idx);
end

metrics = struct();
metrics.RN_ohm = RN;
metrics.Rlow_ohm = Rlow;
metrics.Rlow_over_RN = Rlow / RN;
metrics.suppressionFrac = max(0, (RN - Rlow) / RN);
metrics.Tonset_K = Tonset;

if isfield(result.R4p, 'top_4_10') && isfield(result.R4p, 'bottom_3_9')
    top = result.R4p.top_4_10;
    bot = result.R4p.bottom_3_9;
    metrics.probeAsymLow_ohm = local_nanmean(top(1:nLow) - bot(1:nLow));
    metrics.probeAsymLowNorm = metrics.probeAsymLow_ohm / RN;
else
    metrics.probeAsymLow_ohm = NaN;
    metrics.probeAsymLowNorm = NaN;
end

metrics.currentParticipationLowT = current_participation(result.lastIx, result.lastIy, net);
metrics.percolatesLowT = percolates_low_resistance(net, params, spec, result.T(1), model);

end

function m = local_nanmean(x)
x = x(isfinite(x));
if isempty(x); m = NaN; else; m = mean(x); end
end

function P = current_participation(Ix, Iy, net)

vals = [abs(Ix(net.link.activeX)); abs(Iy(net.link.activeY))];
vals = vals(isfinite(vals));

if isempty(vals) || sum(vals.^2) == 0
    P = NaN;
else
    P = (sum(vals)^2) / (numel(vals) * sum(vals.^2));
end

end

function tf = percolates_low_resistance(net, params, spec, T, model)

[Rx, Ry] = link_resistance_T(params, spec, T);

lowX = net.link.activeX & (Rx < model.metrics.percResistanceFraction .* params.RnX);
lowY = net.link.activeY & (Ry < model.metrics.percResistanceFraction .* params.RnY);

active = net.active;
[Ny, Nx] = size(active);
visited = false(Ny, Nx);
queue = find(net.sourceMask & active);
visited(queue) = true;

head = 1;
while head <= numel(queue)
    idx = queue(head);
    head = head + 1;
    [row, col] = ind2sub([Ny, Nx], idx);

    if net.drainMask(row,col)
        tf = true;
        return;
    end

    neighbors = [];
    if col > 1 && lowX(row,col-1); neighbors(end+1) = sub2ind([Ny,Nx], row, col-1); end %#ok<AGROW>
    if col < Nx && lowX(row,col); neighbors(end+1) = sub2ind([Ny,Nx], row, col+1); end %#ok<AGROW>
    if row > 1 && lowY(row-1,col); neighbors(end+1) = sub2ind([Ny,Nx], row-1, col); end %#ok<AGROW>
    if row < Ny && lowY(row,col); neighbors(end+1) = sub2ind([Ny,Nx], row+1, col); end %#ok<AGROW>

    for kn = 1:numel(neighbors)
        nidx = neighbors(kn);
        if ~visited(nidx)
            visited(nidx) = true;
            queue(end+1) = nidx; %#ok<AGROW>
        end
    end
end

tf = false;

end
