function basin = select_phase5A_frozen_basin(cfg)
%SELECT_PHASE5A_FROZEN_BASIN Pick frozen Phase-4 basin rows for Level A.

candidateScores = readtable(cfg.phase4CandidateScoreFile, 'TextType', 'string');
if ~ismember('evidenceScore', candidateScores.Properties.VariableNames)
    candidateScores.evidenceScore = candidateScores.conductanceScore;
end

tol = cfg.phase5A.parameterBasinScoreTolerance;
maxRows = cfg.phase5A.maxBasinRowsPerTrack;
seeds = unique(candidateScores.seed(isfinite(candidateScores.seed)), 'stable');
if isempty(seeds)
    seeds = cfg.phase5A.commonSeeds(:);
end
cfgSeeds = cfg.phase5A.commonSeeds(:);
if ~isempty(cfgSeeds) && all(isfinite(cfgSeeds))
    seeds = cfgSeeds;
end

rows = repmat(empty_row(), 0, 1);
rows = append_track(rows, candidateScores, "combined physical bottleneck", ...
    "conductance", "transfer_primary", "combined_physical_bottleneck_basin", ...
    tol, maxRows, seeds);
rows = append_track(rows, candidateScores, "contact-relaxed weak links", ...
    "conductance", "required_challenger", "contact_relaxed_conductance_basin", ...
    tol, maxRows, seeds);
rows = append_track(rows, candidateScores, "crack/tunnel-like weak links", ...
    "shape", "required_challenger", "crack_tunnel_shape_basin", ...
    tol, maxRows, seeds);

controlSpecs = [
    control_spec("no weak links", "required_control", ...
        "no_weak_links_control", "bulk_AB_reference", "none", "bulk_sns", NaN, 0, 3.7, "shape")
    control_spec("uniform weak links", "required_control", ...
        "uniform_transparency_control", "uniform_tau_control", "uniform", "boundary_constriction", 0.010, 0.08, 3.7, "shape")
    control_spec("shuffled weak links", "required_control", ...
        "shuffled_transparency_control", "shuffled_tau_control", "shuffled", "boundary_constriction", 0.010, 0.08, 3.7, "shape")
    control_spec("central-lane / 1D-like", "required_control", ...
        "central_lane_control", "central_lane_gap_control", "central_lane", "boundary_constriction", 0.010, 0.08, 3.7, "shape")
    control_spec("geometry-only Tc", "required_control", ...
        "geometry_only_tc_control", "bulk_AB_reference", "none", "bulk_sns", NaN, 0, 3.7, "shape")
    control_spec("bulk gap reference", "required_control", ...
        "bulk_gap_reference_control", "bulk_AB_reference", "none", "bulk_sns", NaN, 0, 3.7, "shape")
    ];

for k = 1:numel(controlSpecs)
    for s = 1:numel(seeds)
        row = empty_row();
        row.track = controlSpecs(k).track;
        row.role = controlSpecs(k).role;
        row.mechanism = controlSpecs(k).mechanism;
        row.parameter_basin_id = sprintf('%s_seed_%g', ...
            char(controlSpecs(k).track), seeds(s));
        row.caseName = controlSpecs(k).caseName;
        row.topology = controlSpecs(k).topology;
        row.linkClass = controlSpecs(k).linkClass;
        row.calibrationMode = controlSpecs(k).calibrationMode;
        row.alpha_gap = controlSpecs(k).alpha_gap;
        row.gammaW = controlSpecs(k).gammaW;
        row.pW = controlSpecs(k).pW;
        row.seed = seeds(s);
        row.phase4_evidence_score = NaN;
        row.selection_note = "required Level A control expanded over common seeds";
        rows(end+1, 1) = row; %#ok<AGROW>
    end
end

basin = struct2table(rows);
basin = sortrows(basin, {'seed','role','track','phase4_evidence_score'});
assert_matched_seed_coverage(basin, seeds);
end

function rows = append_track(rows, scores, mechanism, mode, role, track, tol, maxRows, seeds)
idx = scores.mechanism == mechanism & scores.calibrationMode == mode & ...
    isfinite(scores.evidenceScore);
S = scores(idx, :);
if isempty(S)
    return;
end
best = min(S.evidenceScore);
keep = S.evidenceScore <= best + tol;
Skeep = S(keep, :);
if isempty(Skeep)
    Skeep = S(1, :);
end

selected = table();
for k = 1:numel(seeds)
    seedRows = Skeep(Skeep.seed == seeds(k), :);
    note = "inside global Phase 4 basin tolerance";
    if isempty(seedRows)
        seedRows = S(S.seed == seeds(k), :);
        note = "seed-local representative outside global basin tolerance";
    end
    if isempty(seedRows)
        continue;
    end
    seedRows = sortrows(seedRows, 'evidenceScore');
    seedRows.selection_note = repmat(note, height(seedRows), 1);
    selected = [selected; seedRows(1, :)]; %#ok<AGROW>
end

if isempty(selected)
    selected = sortrows(Skeep, 'evidenceScore');
else
    selected = sortrows(selected, 'evidenceScore');
end
if isfinite(maxRows) && height(selected) > maxRows
    selected = selected(1:maxRows, :);
end

for k = 1:height(selected)
    row = empty_row();
    row.track = track;
    row.role = role;
    row.mechanism = mechanism;
    row.parameter_basin_id = sprintf('%s_%s_seed_%g', ...
        char(track), char(selected.caseName(k)), selected.seed(k));
    row.caseName = selected.caseName(k);
    row.topology = selected.topology(k);
    row.linkClass = selected.linkClass(k);
    row.calibrationMode = selected.calibrationMode(k);
    row.alpha_gap = selected.alphaGap(k);
    row.gammaW = selected.gammaW(k);
    row.pW = selected.pW(k);
    row.seed = selected.seed(k);
    row.phase4_evidence_score = selected.evidenceScore(k);
    row.selection_note = selected.selection_note(k);
    rows(end+1, 1) = row; %#ok<AGROW>
end
end

function s = control_spec(mechanism, role, track, caseName, topology, ...
    linkClass, gammaW, pW, alpha_gap, calibrationMode)
s = struct();
s.mechanism = string(mechanism);
s.role = string(role);
s.track = string(track);
s.caseName = string(caseName);
s.topology = string(topology);
s.linkClass = string(linkClass);
s.gammaW = gammaW;
s.pW = pW;
s.alpha_gap = alpha_gap;
s.calibrationMode = string(calibrationMode);
end

function row = empty_row()
row = struct();
row.track = "";
row.role = "";
row.mechanism = "";
row.parameter_basin_id = "";
row.caseName = "";
row.topology = "";
row.linkClass = "";
row.calibrationMode = "";
row.alpha_gap = NaN;
row.gammaW = NaN;
row.pW = NaN;
row.seed = NaN;
row.phase4_evidence_score = NaN;
row.selection_note = "";
end

function assert_matched_seed_coverage(basin, requestedSeeds)
requestedSeeds = sort(requestedSeeds(:));
tracks = unique(basin.track, 'stable');
for k = 1:numel(tracks)
    idx = basin.track == tracks(k);
    trackSeeds = sort(unique(basin.seed(idx)));
    if ~isequal(trackSeeds(:), requestedSeeds(:))
        error('v8:phase5ASeedMismatch', ...
            ['Phase 5A seed coverage mismatch for track "%s". ', ...
            'Expected [%s], found [%s].'], ...
            char(tracks(k)), num2str(requestedSeeds(:).'), ...
            num2str(trackSeeds(:).'));
    end
end
end
