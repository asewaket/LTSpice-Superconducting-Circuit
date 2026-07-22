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

switch deviceName
    case 'AS001'
        spec.geom = newGeom;
        spec.geometryClass = 'control';
        spec.coveredSide = 'none';
        spec.thickness_nm = [7 10];
        spec.filmForce_Npm = 0;
        spec.filmForceLabel = 'control';
        spec.targetRN_ohm = 75;

    case 'AS002'
        spec.geom = newGeom;
        spec.geometryClass = 'half';
        spec.coveredSide = 'top';
        spec.thickness_nm = [7 8];
        spec.filmForce_Npm = -3;
        spec.filmForceLabel = 'F_f = -3 N/m';
        spec.targetRN_ohm = 61;

    case 'AS003'
        spec.geom = newGeom;
        spec.geometryClass = 'full';
        spec.coveredSide = 'all';
        spec.thickness_nm = [7 10];
        spec.filmForce_Npm = -7;
        spec.filmForceLabel = 'F_f = -7 N/m';
        spec.targetRN_ohm = 368;

    case 'AS004'
        spec.geom = newGeom;
        spec.geometryClass = 'half';
        spec.coveredSide = 'bottom';
        spec.thickness_nm = [6 9];
        spec.filmForce_Npm = -20;
        spec.filmForceLabel = 'F_f = -20 N/m';
        spec.targetRN_ohm = 38;

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

    case 'AS006'
        spec.geom = newGeom;
        spec.geom.probeYTop_um = 2.20;
        spec.geom.probeYBottom_um = -0.80;
        spec.geometryClass = 'half';
        spec.coveredSide = 'bottom';
        spec.thickness_nm = [5 7];
        spec.filmForce_Npm = -40;
        spec.filmForceLabel = 'F_f = -40 N/m';
        spec.targetRN_ohm = 240;
        spec.flakeOutline.enabled = true;
        spec.flakeOutline.note = ['v7.1 simplified AS006 flake outline. ', ...
            'This is an approximate polygonal scaffold, not a traced optical/AFM boundary. ', ...
            'Bottom voltage probes are registered to the lower active-flake lobe.'];
        spec.flakeOutline.x_um = [-9.0 -8.5 -6.4 -4.0 -1.4  0.6  3.6  6.5  9.0  9.0  6.9  4.2  1.4 -1.6 -4.8 -7.4 -9.0];
        spec.flakeOutline.y_um = [-3.1 -1.1 -0.9 -1.1 -1.8 -1.2 -1.0 -1.3 -2.0  2.7  3.3  2.9  3.2  2.6  2.9  2.5  1.2];

    otherwise
        error('Unknown device name "%s".', deviceName);
end

end
