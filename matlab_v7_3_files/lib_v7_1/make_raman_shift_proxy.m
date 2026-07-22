function ramanProxy = make_raman_shift_proxy(raman)
%MAKE_RAMAN_SHIFT_PROXY Add normalized Raman-shift proxy columns.
%
% The model should not treat digitized MoTe2 Raman shifts as a unique strain
% reconstruction. These normalized columns are dimensionless spatial proxies:
%
%   signed_shift_proxy = delta_peak_cm1 / max(abs(delta_peak_cm1))
%   abs_shift_proxy    = abs(signed_shift_proxy)
%
% The normalization is performed independently for each device/scan/mode
% series so that modes with different absolute Raman sensitivities can still
% be compared as spatial response patterns.

ramanProxy = raman;
ramanProxy.signed_shift_proxy = nan(height(ramanProxy), 1);
ramanProxy.abs_shift_proxy = nan(height(ramanProxy), 1);

[G, ~] = findgroups(ramanProxy.series_id);
for g = 1:max(G)
    idx = (G == g);
    d = ramanProxy.delta_peak_cm1(idx);
    scale = max(abs(d), [], 'omitnan');
    if isempty(scale) || ~isfinite(scale) || scale == 0
        signed = zeros(size(d));
    else
        signed = d ./ scale;
    end
    ramanProxy.signed_shift_proxy(idx) = signed;
    ramanProxy.abs_shift_proxy(idx) = abs(signed);
end

end
