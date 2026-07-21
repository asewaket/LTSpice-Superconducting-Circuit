function spec = make_device_spec(deviceName)
%MAKE_DEVICE_SPEC Device-specific geometry and parameter priors.
%
% Edit this file first when dimensions, contact assignments, or experimental
% constraints are refined.

deviceName = upper(char(deviceName));

spec = struct();
spec.name = deviceName;
spec.randomSeed = 100 + sum(double(deviceName));

% Common grid spacing. 0.25 um keeps the first scaffold quick while resolving
% the 0.5 um voltage probes.
spec.grid.dx_um = 0.25;
spec.grid.dy_um = 0.25;

% Default probe labels. The simplified model places P4/P10 on the upper side
% and P3/P9 on the lower side of the Hall bar.
spec.probePairs.top_4_10 = {'P4','P10'};
spec.probePairs.bottom_3_9 = {'P3','P9'};

% Shared solver settings.
spec.solver.Rfloor = 1e-6;
spec.solver.dT = 0.030;
spec.solver.dI_frac = 0.08;
spec.solver.maxIter = 250;
spec.solver.tolG = 1e-6;
spec.solver.alpha = 0.25;

% Region IDs used by build_hallbar_network and assign_link_parameters.
spec.region.background = 1;
spec.region.covered = 2;
spec.region.boundary = 3;
spec.region.crack = 4;
spec.region.edge = 5;
spec.regionNames = {'background','covered','boundary','crack','edge'};

% Conservative defaults. Individual devices override these below.
spec.targetRN_ohm = 100;
spec.geometryClass = 'control';
spec.coveredSide = 'none';
spec.thickness_nm = [NaN NaN];
spec.filmForce_Npm = NaN;
spec.filmForceLabel = '';

% The annotated screenshot is used as the first scaffold convention:
%   new: AS001/002/003/004/006, source-drain span 18 um
%   old: AS005, source-drain span 4 um
newGeom = struct( ...
    'name', 'new', ...
    'activeLength_um', 18.0, ...
    'channelWidth_um', 7.0, ...
    'probeSpacing_um', 5.0, ...
    'probeWidth_um', 0.50, ...
    'currentContactDepth_um', 0.75, ...
    'boundaryWidth_um', 0.75, ...
    'edgeWidth_um', 0.50);

oldGeom = struct( ...
    'name', 'old', ...
    'activeLength_um', 4.0, ...
    'channelWidth_um', 7.0, ...
    'probeSpacing_um', 1.25, ...
    'probeWidth_um', 0.50, ...
    'currentContactDepth_um', 0.35, ...
    'boundaryWidth_um', 0.55, ...
    'edgeWidth_um', 0.45);

% Parameter-prior defaults. Values are phenomenological and are intended to
% produce the correct device classes, not final fitted curves.
param = default_parameter_prior();

switch deviceName
    case 'AS001'
        spec.geom = newGeom;
        spec.geometryClass = 'control';
        spec.coveredSide = 'none';
        spec.thickness_nm = [7 10];
        spec.filmForce_Npm = 0;
        spec.filmForceLabel = 'control';
        spec.targetRN_ohm = 75;
        param.enhancedProb(:) = [0.01 0.01 0.01 0.01 0.01];
        param.enhancedTcMean(:) = 0.12;
        param.baseTcMean = 0.06;

    case 'AS002'
        spec.geom = newGeom;
        spec.geometryClass = 'half';
        spec.coveredSide = 'top';
        spec.thickness_nm = [7 8];
        spec.filmForce_Npm = -3;
        spec.filmForceLabel = 'F_f = -3 N/m';
        spec.targetRN_ohm = 61;
        param.enhancedProb = [0.03 0.10 0.16 0.02 0.04];
        param.enhancedTcMean = [0.14 0.22 0.30 0.20 0.18];
        param.residualFraction = [0.65 0.50 0.42 0.70 0.62];

    case 'AS003'
        spec.geom = newGeom;
        spec.geometryClass = 'full';
        spec.coveredSide = 'all';
        spec.thickness_nm = [7 10];
        spec.filmForce_Npm = -7;
        spec.filmForceLabel = 'F_f = -7 N/m';
        spec.targetRN_ohm = 368;
        param.enhancedProb = [0.02 0.06 0.02 0.02 0.03];
        param.enhancedTcMean = [0.10 0.18 0.12 0.12 0.14];
        param.residualFraction = [0.82 0.78 0.82 0.82 0.80];

    case 'AS004'
        spec.geom = newGeom;
        spec.geometryClass = 'half';
        spec.coveredSide = 'bottom';
        spec.thickness_nm = [6 9];
        spec.filmForce_Npm = -20;
        spec.filmForceLabel = 'F_f = -20 N/m';
        spec.targetRN_ohm = 38;
        param.enhancedProb = [0.04 0.26 0.42 0.03 0.08];
        param.enhancedTcMean = [0.15 0.32 0.46 0.20 0.25];
        param.residualFraction = [0.55 0.22 0.16 0.60 0.42];

    case 'AS005'
        spec.geom = oldGeom;
        spec.geometryClass = 'cracked_full';
        spec.coveredSide = 'all';
        spec.thickness_nm = [6 8];
        spec.filmForce_Npm = 25;
        spec.filmForceLabel = 'F_f = +25 N/m';
        spec.targetRN_ohm = 49;
        spec.crack.y0_um = 1.35;
        spec.crack.slope = 0.15;
        spec.crack.width_um = 0.45;
        spec.crack.weakLinkMultiplier = 8.0;
        param.enhancedProb = [0.06 0.20 0.10 0.72 0.16];
        param.enhancedTcMean = [0.25 0.70 0.40 1.35 0.55];
        param.enhancedTcSigma = [0.06 0.25 0.15 0.35 0.18];
        param.residualFraction = [0.45 0.20 0.35 0.08 0.25];
        param.IcMean = [0.20 0.55 0.35 1.50 0.45] * 1e-6;
        param.IcSigmaFrac = 0.55;

    case 'AS006'
        spec.geom = newGeom;
        spec.geometryClass = 'half';
        spec.coveredSide = 'bottom';
        spec.thickness_nm = [5 7];
        spec.filmForce_Npm = -40;
        spec.filmForceLabel = 'F_f = -40 N/m';
        spec.targetRN_ohm = 240;
        param.enhancedProb = [0.06 0.36 0.55 0.04 0.10];
        param.enhancedTcMean = [0.18 0.38 0.62 0.25 0.32];
        param.enhancedTcSigma = [0.06 0.15 0.22 0.08 0.12];
        param.residualFraction = [0.60 0.30 0.22 0.65 0.50];

    otherwise
        error('Unknown device name "%s".', deviceName);
end

spec.param = param;

end

function param = default_parameter_prior()

nr = 5;

param.RnMean = ones(1,nr);
param.RnSigmaFrac = 0.20;
param.transverseRnMultiplier = 1.15;

param.baseTcMean = 0.06;
param.baseTcSigma = 0.025;
param.enhancedProb = 0.02 * ones(1,nr);
param.enhancedTcMean = 0.20 * ones(1,nr);
param.enhancedTcSigma = 0.06 * ones(1,nr);
param.domainCorrelation_um = 0.75;

param.IcMean = 0.25e-6 * ones(1,nr);
param.IcSigmaFrac = 0.45;

% Link resistance at T << Tc approaches Rfloor + Rn*f. This is intentionally
% not zero, because the chapter interpretation emphasizes incomplete
% percolation and finite weak links.
param.residualFraction = 0.60 * ones(1,nr);

end
