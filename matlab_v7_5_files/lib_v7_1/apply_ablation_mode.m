function net = apply_ablation_mode(net, spec, mode)
%APPLY_ABLATION_MODE Modify network topology for null/ablation tests.

if nargin < 3
    mode = 'full';
end

switch mode
    case {'full','uniform','random_eta','crack_off','no_local_ic','weak_transverse'}
        % No topology change.

    case 'central_lane'
        % A crude 1D-like null model: keep only horizontal links closest to
        % the channel centerline. This is not the main Hall-bar model; it is
        % a topology ablation showing what disappears when lateral pathways
        % are removed.
        [~, row0] = min(abs(net.y_um));

        active = false(size(net.active));
        active(row0,:) = true;
        net.active = active;

        keepX = false(size(net.link.activeX));
        keepX(row0,:) = net.link.activeX(row0,:);
        net.link.activeX = keepX;
        net.link.activeY(:) = false;

        net.sourceMask = false(size(net.sourceMask));
        net.drainMask = false(size(net.drainMask));
        net.sourceMask(row0,:) = net.x_um <= min(net.x_um) + spec.geom.currentContactDepth_um;
        net.drainMask(row0,:) = net.x_um >= max(net.x_um) - spec.geom.currentContactDepth_um;

        [~, leftProbeCol] = min(abs(net.x_um + spec.geom.probeSpacing_um/2));
        [~, rightProbeCol] = min(abs(net.x_um - spec.geom.probeSpacing_um/2));

        probeNames = fieldnames(net.probeMasks);
        for kp = 1:numel(probeNames)
            net.probeMasks.(probeNames{kp}) = false(size(net.active));
        end
        net.probeMasks.P4(row0,leftProbeCol) = true;
        net.probeMasks.P3(row0,leftProbeCol) = true;
        net.probeMasks.P10(row0,rightProbeCol) = true;
        net.probeMasks.P9(row0,rightProbeCol) = true;

    otherwise
        error('Unknown ablation mode "%s".', mode);
end

end
