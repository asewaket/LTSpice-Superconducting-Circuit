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
        keepX = false(size(net.link.activeX));
        keepX(row0,:) = net.link.activeX(row0,:);
        net.link.activeX = keepX;
        net.link.activeY(:) = false;

    otherwise
        error('Unknown ablation mode "%s".', mode);
end

end
