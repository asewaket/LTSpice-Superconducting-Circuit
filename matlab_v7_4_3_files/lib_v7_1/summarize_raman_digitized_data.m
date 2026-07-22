function summary = summarize_raman_digitized_data(raman)
%SUMMARIZE_RAMAN_DIGITIZED_DATA Compute compact line-scan metrics.
%
% The summary metrics are intended to compare spatial Raman response across
% devices, scan directions, and Raman modes before mapping them onto the
% superconducting-network grid.

series = unique(raman.series_id, 'stable');
rows = cell(numel(series), 1);

for k = 1:numel(series)
    idx = (raman.series_id == series(k));
    T = sortrows(raman(idx, :), 'position_um');

    x = T.position_um;
    y = T.peak_cm1;
    dy = T.delta_peak_cm1;

    finiteTrend = isfinite(x) & isfinite(y);
    if nnz(finiteTrend) >= 2
        p = polyfit(x(finiteTrend), y(finiteTrend), 1);
        slope_cm1_per_um = p(1);
    else
        slope_cm1_per_um = NaN;
    end

    [~, iMaxAbs] = max(abs(dy));
    if isempty(iMaxAbs) || ~isfinite(dy(iMaxAbs))
        max_abs_delta_cm1 = NaN;
        position_max_abs_delta_um = NaN;
    else
        max_abs_delta_cm1 = dy(iMaxAbs);
        position_max_abs_delta_um = x(iMaxAbs);
    end

    rows{k} = table( ...
        T.device(1), T.scan_direction(1), T.mode(1), T.series_id(1), ...
        height(T), min(x), max(x), max(x) - min(x), ...
        min(y), max(y), mean(y, 'omitnan'), std(y, 'omitnan'), ...
        min(dy), max(dy), max(dy) - min(dy), ...
        sqrt(mean(dy.^2, 'omitnan')), max_abs_delta_cm1, ...
        position_max_abs_delta_um, slope_cm1_per_um, ...
        'VariableNames', {'device', 'scan_direction', 'mode', 'series_id', ...
        'n_points', 'position_min_um', 'position_max_um', 'scan_length_um', ...
        'peak_min_cm1', 'peak_max_cm1', 'peak_mean_cm1', 'peak_std_cm1', ...
        'delta_min_cm1', 'delta_max_cm1', 'delta_span_cm1', ...
        'delta_rms_cm1', 'max_abs_delta_cm1', ...
        'position_max_abs_delta_um', 'linear_slope_cm1_per_um'});
end

summary = vertcat(rows{:});
summary = sortrows(summary, {'device', 'scan_direction', 'mode'});

end
