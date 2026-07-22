function registered = register_raman_scans_to_hallbar(ramanProxy, registration)
%REGISTER_RAMAN_SCANS_TO_HALLBAR Map Raman line-scan positions to x/y.
%
% Each digitized Raman point has a one-dimensional position along a scan.
% This function maps those positions onto manually supplied Hall-bar scan
% endpoints. Position normalization is performed independently for each
% device/scan/mode series so that the full digitized trace spans the endpoint
% segment.
%
% AS005 compatibility: older digitized AS005 labels are "zigzag" and
% "armchair"; endpoint labels may be "zigzag_1" and "armchair_1". If exact
% matching fails, a unique endpoint whose scan_id base name matches the Raman
% scan_direction is used.

registered = ramanProxy;
registered.scan_id = strings(height(registered), 1);
registered.x_um = nan(height(registered), 1);
registered.y_um = nan(height(registered), 1);
registered.scan_fraction = nan(height(registered), 1);
registered.registration_status = strings(height(registered), 1);

series = unique(registered.series_id, 'stable');

for k = 1:numel(series)
    idx = (registered.series_id == series(k));
    T = registered(idx, :);
    endpoint = find_endpoint_row(registration, T.device(1), T.scan_direction(1));

    if isempty(endpoint)
        registered.registration_status(idx) = "missing_endpoint";
        continue;
    end

    pos = T.position_um;
    posMin = min(pos, [], 'omitnan');
    posMax = max(pos, [], 'omitnan');
    if ~isfinite(posMin) || ~isfinite(posMax) || posMax == posMin
        frac = zeros(size(pos));
    else
        frac = (pos - posMin) ./ (posMax - posMin);
    end

    x = endpoint.x0_um + frac .* (endpoint.x1_um - endpoint.x0_um);
    y = endpoint.y0_um + frac .* (endpoint.y1_um - endpoint.y0_um);

    registered.scan_id(idx) = endpoint.scan_id;
    registered.x_um(idx) = x;
    registered.y_um(idx) = y;
    registered.scan_fraction(idx) = frac;
    registered.registration_status(idx) = "registered";
end

registered.registered_series_id = registered.device + "_" + ...
    registered.scan_id + "_" + registered.mode;

end

function endpoint = find_endpoint_row(registration, device, scanDirection)

endpoint = table();
devRows = registration(registration.device == device, :);
if isempty(devRows)
    return;
end

exact = devRows(devRows.scan_id == scanDirection, :);
if height(exact) == 1
    endpoint = exact;
    return;
elseif height(exact) > 1
    error('Multiple exact endpoint matches for %s %s.', device, scanDirection);
end

baseScan = erase(scanDirection, "_1");
baseScan = erase(baseScan, "_2");
baseScan = erase(baseScan, "_3");

endpointBase = devRows.scan_id;
endpointBase = erase(endpointBase, "_1");
endpointBase = erase(endpointBase, "_2");
endpointBase = erase(endpointBase, "_3");

baseMatches = devRows(endpointBase == baseScan, :);
if height(baseMatches) == 1
    endpoint = baseMatches;
elseif height(baseMatches) > 1
    error('Ambiguous endpoint base-name matches for %s %s.', device, scanDirection);
end

end
