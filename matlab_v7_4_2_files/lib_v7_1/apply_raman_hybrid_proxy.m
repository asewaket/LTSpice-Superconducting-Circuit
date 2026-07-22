function [net, proxyInfo] = apply_raman_hybrid_proxy(net, spec, model, registered, alpha, opts)
%APPLY_RAMAN_HYBRID_PROXY Blend geometry eta with registered Raman proxy.
%
% v6 asks whether Raman-informed spatial heterogeneity helps transport.
% The Raman map is treated as a support-weighted phenomenological constraint:
%
%   eta_hybrid = eta_geometry + alpha*w*(eta_raman - eta_geometry)
%
% where w(x,y) is the Raman interpolation-support map. Far from registered
% Raman scans, w -> 0 and the model falls back to the geometry-only proxy.
%
% This function does not claim that Raman shifts are calibrated absolute
% strain. It only lets measured Raman spatial variation perturb the existing
% mechanical-response proxy where Raman support exists.

if nargin < 5 || isempty(alpha)
    alpha = 0.5;
end
if nargin < 6 || isempty(opts)
    opts = make_raman_hybrid_options();
end

alpha = max(0, min(1, alpha));

if ~isfield(net, 'etaNode') || ~isfield(net.link, 'etaX') || ~isfield(net.link, 'etaY')
    net = apply_mechanical_proxy(net, spec, model, 'full');
end

etaGeometry = net.etaNode;

mapOpts = struct('valueColumn', opts.valueColumn, ...
    'sigma_um', opts.sigma_um, ...
    'maxDistance_um', opts.maxDistance_um, ...
    'minCoverageNorm', opts.minCoverageNorm);
ramanMap = build_raman_proxy_map(net, registered, spec.name, mapOpts);

etaRaman = ramanMap.nodeMapNorm;
if strcmp(opts.useDisplayMap, 'supported_only')
    etaRaman = ramanMap.nodeMapDisplay;
end

support = ramanMap.coverageNorm;
support(~isfinite(support)) = 0;
support = min(1, max(0, support));

if opts.supportPower ~= 1
    support = support .^ opts.supportPower;
end

etaRamanFilled = etaRaman;
etaRamanFilled(~isfinite(etaRamanFilled)) = etaGeometry(~isfinite(etaRamanFilled));

switch opts.ramanScaleMode
    case 'match_geometry_max'
        geoScale = max(etaGeometry(net.active), [], 'omitnan');
        if ~isfinite(geoScale) || geoScale <= 0
            geoScale = 1;
        end
        etaRamanFilled = etaRamanFilled .* geoScale;
    case 'unit'
        % Leave the normalized Raman proxy on its native 0--1 scale.
    otherwise
        error('Unknown Raman scale mode "%s".', opts.ramanScaleMode);
end

etaHybrid = etaGeometry + alpha .* support .* (etaRamanFilled - etaGeometry);
etaHybrid(~net.active) = 0;
etaHybrid = min(model.proxy.clipMax, max(model.proxy.clipMin, etaHybrid));

etaX = 0.5 * (etaHybrid(:,1:end-1) + etaHybrid(:,2:end));
etaY = 0.5 * (etaHybrid(1:end-1,:) + etaHybrid(2:end,:));
etaX(~net.link.activeX) = 0;
etaY(~net.link.activeY) = 0;

net.etaNodeGeometry = etaGeometry;
net.etaNodeRaman = etaRaman;
net.etaNodeRamanSupport = support;
net.etaNode = etaHybrid;
net.link.etaX = etaX;
net.link.etaY = etaY;
net.proxyMode = 'raman_hybrid';

proxyInfo = struct();
proxyInfo.alpha = alpha;
proxyInfo.options = opts;
proxyInfo.ramanMap = ramanMap;
proxyInfo.meanEtaGeometry = mean(etaGeometry(net.active), 'omitnan');
proxyInfo.meanEtaHybrid = mean(etaHybrid(net.active), 'omitnan');
proxyInfo.meanSupport = mean(support(net.active), 'omitnan');
proxyInfo.supportedNodeFraction = nnz(ramanMap.supportedMask & net.active) / nnz(net.active);

end
