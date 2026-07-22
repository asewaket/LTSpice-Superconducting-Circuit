function diag = compute_percolation_diagnostics(net, spec, params, T_vec, opts)
%COMPUTE_PERCOLATION_DIAGNOSTICS Source-drain SC connectivity vs T.

if nargin < 5 || isempty(opts)
    opts.scResistanceFraction = 0.20;
end
if ~isfield(opts, 'scResistanceFraction')
    opts.scResistanceFraction = 0.20;
end

nT = numel(T_vec);
diag = struct();
diag.T = T_vec(:);
diag.scLinkFraction = zeros(nT, 1);
diag.largestClusterFraction = zeros(nT, 1);
diag.sourceDrainConnected = false(nT, 1);
diag.topProbeConnected = false(nT, 1);
diag.bottomProbeConnected = false(nT, 1);
diag.percolationOnset_K = NaN;
diag.topProbeOnset_K = NaN;
diag.bottomProbeOnset_K = NaN;

for kT = 1:nT
    T = T_vec(kT);
    [Rx, Ry] = link_resistance_T(params, spec, T);
    scX = superconducting_links(Rx, params.RnX, net.link.activeX, opts.scResistanceFraction);
    scY = superconducting_links(Ry, params.RnY, net.link.activeY, opts.scResistanceFraction);

    labels = label_superconducting_clusters(net, scX, scY);
    activeLabels = labels(net.active);
    counts = accumarray(activeLabels(activeLabels > 0), 1);
    if isempty(counts)
        largest = 0;
    else
        largest = max(counts);
    end

    diag.scLinkFraction(kT) = (nnz(scX) + nnz(scY)) ./ ...
        max(1, nnz(net.link.activeX) + nnz(net.link.activeY));
    diag.largestClusterFraction(kT) = largest ./ max(1, nnz(net.active));
    diag.sourceDrainConnected(kT) = masks_connected(labels, net.sourceMask, net.drainMask);

    if isfield(spec.probePairs, 'top_4_10')
        diag.topProbeConnected(kT) = probe_pair_connected(labels, net, spec.probePairs.top_4_10);
    end
    if isfield(spec.probePairs, 'bottom_3_9')
        diag.bottomProbeConnected(kT) = probe_pair_connected(labels, net, spec.probePairs.bottom_3_9);
    end
end

diag.percolationOnset_K = highest_connected_temperature(T_vec, diag.sourceDrainConnected);
diag.topProbeOnset_K = highest_connected_temperature(T_vec, diag.topProbeConnected);
diag.bottomProbeOnset_K = highest_connected_temperature(T_vec, diag.bottomProbeConnected);

end

function sc = superconducting_links(R, Rn, active, thresholdFrac)

ratio = inf(size(R));
valid = active & isfinite(R) & isfinite(Rn) & Rn > 0;
ratio(valid) = R(valid) ./ Rn(valid);
sc = valid & ratio <= thresholdFrac;

end

function labels = label_superconducting_clusters(net, scX, scY)

active = net.active;
[Ny, Nx] = size(active);
labels = zeros(Ny, Nx);
label = 0;

for row0 = 1:Ny
    for col0 = 1:Nx
        if ~active(row0,col0) || labels(row0,col0) ~= 0
            continue;
        end

        label = label + 1;
        stackR = zeros(nnz(active), 1);
        stackC = zeros(nnz(active), 1);
        top = 1;
        stackR(top) = row0;
        stackC(top) = col0;
        labels(row0,col0) = label;

        while top > 0
            row = stackR(top);
            col = stackC(top);
            top = top - 1;

            if col > 1 && scX(row,col-1)
                [labels, stackR, stackC, top] = push_if_unlabeled(labels, stackR, stackC, top, row, col-1, label);
            end
            if col < Nx && scX(row,col)
                [labels, stackR, stackC, top] = push_if_unlabeled(labels, stackR, stackC, top, row, col+1, label);
            end
            if row > 1 && scY(row-1,col)
                [labels, stackR, stackC, top] = push_if_unlabeled(labels, stackR, stackC, top, row-1, col, label);
            end
            if row < Ny && scY(row,col)
                [labels, stackR, stackC, top] = push_if_unlabeled(labels, stackR, stackC, top, row+1, col, label);
            end
        end
    end
end

end

function [labels, stackR, stackC, top] = push_if_unlabeled(labels, stackR, stackC, top, row, col, label)

if labels(row,col) == 0
    labels(row,col) = label;
    top = top + 1;
    stackR(top) = row;
    stackC(top) = col;
end

end

function tf = masks_connected(labels, maskA, maskB)

la = unique(labels(maskA & labels > 0));
lb = unique(labels(maskB & labels > 0));
tf = ~isempty(intersect(la, lb));

end

function tf = probe_pair_connected(labels, net, pair)

maskA = net.probeMasks.(pair{1});
maskB = net.probeMasks.(pair{2});
tf = masks_connected(labels, maskA, maskB);

end

function Tconn = highest_connected_temperature(T_vec, connected)

if any(connected)
    Tconn = max(T_vec(connected));
else
    Tconn = NaN;
end

end
