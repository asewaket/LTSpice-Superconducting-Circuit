function topTable = select_top_raman_variants(sweepTable, opts)
%SELECT_TOP_RAMAN_VARIANTS Select top non-geometry variants plus baseline rows.

if nargin < 2 || isempty(opts)
    opts = make_raman_robustness_options();
end

devices = unique(string(sweepTable.device), 'stable');
topTable = table();

for d = 1:numel(devices)
    device = devices(d);
    Tdev = sweepTable(string(sweepTable.device) == device, :);
    Tnonzero = Tdev(Tdev.alpha > 0, :);
    Tnonzero = sortrows(Tnonzero, 'combinedScore');
    nKeep = min(opts.topNPerDevice, height(Tnonzero));
    if nKeep > 0
        topTable = [topTable; Tnonzero(1:nKeep,:)]; %#ok<AGROW>
    end

    Tgeo = Tdev(Tdev.alpha == 0, :);
    if ~isempty(Tgeo)
        Tgeo = sortrows(Tgeo, 'combinedScore');
        baselineRow = Tgeo(1,:);
        baselineRow.raman_mode = "geometry_only";
        baselineRow.reference = "none";
        baselineRow.representation = "none";
        baselineRow.couplingMode = "geometry_only";
        topTable = [topTable; baselineRow]; %#ok<AGROW>
    end
end

topTable = sortrows(topTable, {'device','combinedScore'});

end
