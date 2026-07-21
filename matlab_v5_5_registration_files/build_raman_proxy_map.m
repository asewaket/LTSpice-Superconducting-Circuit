function ramanMap = build_raman_proxy_map(net, registered, deviceName, opts)
%BUILD_RAMAN_PROXY_MAP Interpolate registered Raman shift proxies onto nodes.
%
% This is a visualization/constraint map, not a calibrated strain field. It
% uses Gaussian distance weighting from registered Raman scan points to create
% sparse node-level maps on the Hall-bar grid.

if nargin < 4 || isempty(opts)
    opts = struct();
end
if ~isfield(opts, 'sigma_um')
    opts.sigma_um = 0.85;
end
if ~isfield(opts, 'maxDistance_um')
    opts.maxDistance_um = 3 * opts.sigma_um;
end
if ~isfield(opts, 'valueColumn')
    opts.valueColumn = 'abs_shift_proxy';
end
if ~isfield(opts, 'modeAggregation')
    opts.modeAggregation = 'all_modes';
end

deviceName = string(upper(char(deviceName)));
T = registered(registered.device == deviceName & ...
    registered.registration_status == "registered", :);

if isempty(T)
    error('No registered Raman rows found for %s.', deviceName);
end

values = T.(opts.valueColumn);
valid = isfinite(T.x_um) & isfinite(T.y_um) & isfinite(values);
T = T(valid, :);
values = values(valid);

nodeMap = nan(size(net.active));
coverage = zeros(size(net.active));

for n = 1:numel(net.X_um)
    if ~net.active(n)
        continue;
    end
    dx = T.x_um - net.X_um(n);
    dy = T.y_um - net.Y_um(n);
    dist = hypot(dx, dy);
    close = dist <= opts.maxDistance_um;
    if ~any(close)
        continue;
    end
    w = exp(-(dist(close).^2) ./ (2 * opts.sigma_um^2));
    nodeMap(n) = sum(w .* values(close)) ./ sum(w);
    coverage(n) = sum(w);
end

if any(isfinite(nodeMap(:)))
    finiteVals = nodeMap(isfinite(nodeMap));
    minVal = min(finiteVals);
    maxVal = max(finiteVals);
    if maxVal > minVal
        nodeMapNorm = (nodeMap - minVal) ./ (maxVal - minVal);
    else
        nodeMapNorm = zeros(size(nodeMap));
        nodeMapNorm(~isfinite(nodeMap)) = NaN;
    end
else
    nodeMapNorm = nodeMap;
end

ramanMap = struct();
ramanMap.device = deviceName;
ramanMap.opts = opts;
ramanMap.nodeMap = nodeMap;
ramanMap.nodeMapNorm = nodeMapNorm;
ramanMap.coverage = coverage;
ramanMap.sourceRows = T;

end
