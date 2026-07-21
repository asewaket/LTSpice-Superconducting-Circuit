function variant = prepare_raman_variant_data(registered, deviceName, variantOpts)
%PREPARE_RAMAN_VARIANT_DATA Filter/re-reference Raman points for one variant.
%
% Adds variant_proxy, a 0--1 value suitable for build_raman_proxy_map.

deviceName = string(deviceName);
variant = registered(registered.device == deviceName & ...
    registered.registration_status == "registered", :);

switch variantOpts.modeName
    case 'all_modes'
        % keep all rows
    case 'A5g_only'
        variant = variant(variant.mode == "A5g", :);
    case 'B2g_only'
        variant = variant(variant.mode == "B2g", :);
    case 'A4g_only'
        variant = variant(variant.mode == "A4g", :);
    otherwise
        error('Unknown Raman mode variant "%s".', variantOpts.modeName);
end

if isempty(variant)
    error('No Raman rows remain for %s / %s.', deviceName, variantOpts.modeName);
end

variant.variant_delta_cm1 = nan(height(variant), 1);
variant.variant_proxy = nan(height(variant), 1);

series = unique(variant.registered_series_id, 'stable');
for ks = 1:numel(series)
    idx = variant.registered_series_id == series(ks);
    T = sortrows(variant(idx,:), 'position_um');

    switch variantOpts.referenceName
        case 'first_point'
            ref = T.peak_cm1(1);
        case 'scan_mean'
            ref = mean(T.peak_cm1, 'omitnan');
        otherwise
            error('Unknown Raman reference "%s".', variantOpts.referenceName);
    end

    delta = T.peak_cm1 - ref;
    scale = max(abs(delta), [], 'omitnan');
    if ~isfinite(scale) || scale == 0
        proxy = zeros(size(delta));
    else
        switch variantOpts.representationName
            case 'abs'
                proxy = abs(delta) ./ scale;
            case 'signed_positive'
                proxy = max(delta, 0) ./ scale;
            case 'signed_negative'
                proxy = max(-delta, 0) ./ scale;
            otherwise
                error('Unknown Raman representation "%s".', variantOpts.representationName);
        end
    end

    originalIdx = find(idx);
    [~, sortOrder] = sort(variant.position_um(idx));
    targetIdx = originalIdx(sortOrder);
    variant.variant_delta_cm1(targetIdx) = delta;
    variant.variant_proxy(targetIdx) = proxy;
end

variant.variant_mode = repmat(string(variantOpts.modeName), height(variant), 1);
variant.variant_reference = repmat(string(variantOpts.referenceName), height(variant), 1);
variant.variant_representation = repmat(string(variantOpts.representationName), height(variant), 1);

end
