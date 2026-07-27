function out = run_as006_v746_reproduction(cfg)
%RUN_AS006_V746_REPRODUCTION Reproduce v7.4.6 through the v8 entry point.

if ~exist(cfg.outputDir, 'dir')
    mkdir(cfg.outputDir);
end

global V77_SEED_OVERRIDE V77_OUTPUT_SUFFIX V77_REUSE_EXISTING_SCREENING V77_RUN_FULL_FIELD_MAPS
oldSeed = V77_SEED_OVERRIDE;
oldSuffix = V77_OUTPUT_SUFFIX;
oldReuse = V77_REUSE_EXISTING_SCREENING;
oldFullMaps = V77_RUN_FULL_FIELD_MAPS;

cleanupObj = onCleanup(@() restore_globals(oldSeed, oldSuffix, oldReuse, oldFullMaps));

V77_SEED_OVERRIDE = cfg.seedOverride;
V77_OUTPUT_SUFFIX = cfg.outputSuffix;
V77_REUSE_EXISTING_SCREENING = cfg.reuseExistingScreeningTables;
V77_RUN_FULL_FIELD_MAPS = cfg.runFullFieldMaps;

V77_KEEP_WORKSPACE = true; %#ok<NASGU>
run_v746_as006_gap_weaklink_sweep;

if exist(cfg.generatedScoreFile, 'file') ~= 2
    error('Expected generated v7.4.6 score ledger was not found: %s', ...
        cfg.generatedScoreFile);
end

copyfile(cfg.generatedScoreFile, cfg.v8ScoreFile);

gate = compare_score_ledgers(cfg.referenceScoreFile, cfg.generatedScoreFile, ...
    cfg.scoreTolerance);
manifest = make_manifest(cfg, gate);
v800.write_run_manifest(manifest, cfg.manifestFile);

out = struct();
out.config = cfg;
out.gate = gate;
out.manifest = manifest;
out.manifestPath = cfg.manifestFile;
out.generatedScoreFile = cfg.generatedScoreFile;
out.v8ScoreFile = cfg.v8ScoreFile;

end

function restore_globals(seedValue, suffixValue, reuseValue, fullMapsValue)
global V77_SEED_OVERRIDE V77_OUTPUT_SUFFIX V77_REUSE_EXISTING_SCREENING V77_RUN_FULL_FIELD_MAPS
V77_SEED_OVERRIDE = seedValue;
V77_OUTPUT_SUFFIX = suffixValue;
V77_REUSE_EXISTING_SCREENING = reuseValue;
V77_RUN_FULL_FIELD_MAPS = fullMapsValue;
end

function gate = compare_score_ledgers(referencePath, generatedPath, tolerance)

gate = struct();
gate.name = 'v7.4.6 AS006 score-ledger reproduction';
gate.referencePath = referencePath;
gate.generatedPath = generatedPath;
gate.tolerance = tolerance;
gate.referenceAvailable = exist(referencePath, 'file') == 2;
gate.generatedAvailable = exist(generatedPath, 'file') == 2;
gate.maxAbsScoreDifference = NaN;
gate.rowCountMatch = false;
gate.status = 'NOT_RUN';
gate.message = '';

if ~gate.generatedAvailable
    gate.status = 'FAIL';
    gate.message = 'Generated score ledger is missing.';
    return;
end
if ~gate.referenceAvailable
    gate.status = 'REFERENCE_MISSING';
    gate.message = 'Reference v7.4.6 ledger is missing; run completed but numerical reproduction was not checked.';
    return;
end

ref = read_table(referencePath);
gen = read_table(generatedPath);
gate.rowCountMatch = height(ref) == height(gen);

scoreVars = intersect(["shapeScore","conductanceScore","shapeFullMap", ...
    "shapeLowBias","shapeZeroBias","shapeAsymmetry","conductanceFullMap", ...
    "conductanceLowBias","conductanceZeroBias","conductanceAsymmetry"], ...
    string(ref.Properties.VariableNames), 'stable');
scoreVars = intersect(scoreVars, string(gen.Properties.VariableNames), 'stable');

maxDiff = 0;
for k = 1:numel(scoreVars)
    name = char(scoreVars(k));
    a = ref.(name);
    b = gen.(name);
    if numel(a) ~= numel(b)
        maxDiff = Inf;
        break;
    end
    d = abs(a - b);
    d = d(isfinite(d));
    if ~isempty(d)
        maxDiff = max(maxDiff, max(d));
    end
end
gate.maxAbsScoreDifference = maxDiff;

if gate.rowCountMatch && isfinite(maxDiff) && maxDiff <= tolerance
    gate.status = 'PASS';
    gate.message = 'Generated v8 reproduction ledger matches the v7.4.6 reference within tolerance.';
else
    gate.status = 'FAIL';
    gate.message = 'Generated v8 reproduction ledger differs from the v7.4.6 reference.';
end

end

function manifest = make_manifest(cfg, gate)

manifest = struct();
manifest.model_version = cfg.modelVersion;
manifest.physics_source_version = cfg.physicsSourceVersion;
manifest.device = cfg.device;
manifest.commit_sha = v800.git_commit_sha(cfg.repoRoot);
manifest.generated_at = datestr(now, 30);
manifest.output_dir = cfg.outputDir;
manifest.generated_score_file = cfg.generatedScoreFile;
manifest.v8_score_file = cfg.v8ScoreFile;
manifest.reference_score_file = cfg.referenceScoreFile;
manifest.seed_override = cfg.seedOverride;
manifest.output_suffix = cfg.outputSuffix;
manifest.run_full_field_maps = cfg.runFullFieldMaps;
manifest.reuse_existing_screening_tables = cfg.reuseExistingScreeningTables;
manifest.reproduction_gate = gate;

end

function T = read_table(pathToFile)
try
    T = readtable(pathToFile, 'TextType', 'string');
catch
    T = readtable(pathToFile);
end
end
