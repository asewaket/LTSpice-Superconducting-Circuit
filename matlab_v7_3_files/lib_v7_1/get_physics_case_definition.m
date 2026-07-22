function caseDef = get_physics_case_definition(deviceName, caseID)
%GET_PHYSICS_CASE_DEFINITION Literature-motivated v6.7 case definitions.

deviceName = upper(char(deviceName));
caseID = char(caseID);

caseDef = default_case_definition(caseID);
caseDef.device = deviceName;

switch caseID
    case 'baseline_smooth'
        caseDef.label = 'baseline smooth Raman';
        caseDef.description = 'Best v6.3/v6.4 smooth Raman variant without additional physics-informed changes.';
        caseDef.useDeviceBestVariant = true;

    case 'case_A_inplane_Tc'
        caseDef.label = 'Case A: in-plane Raman controls Tc';
        caseDef.description = 'In-plane-like Raman heterogeneity modifies local Tc but not weak-link transparency directly.';
        caseDef.variant.modeName = 'in_plane_only';
        caseDef.variant.referenceName = 'scan_mean';
        caseDef.variant.representationName = 'abs';
        caseDef.variant.couplingMode = 'Tc_only';
        caseDef.TcGain_K = 0.35;

    case 'case_B_outofplane_weaklinks'
        caseDef.label = 'Case B: out-of-plane Raman controls weak links';
        caseDef.description = 'Out-of-plane-sensitive Raman heterogeneity mainly modifies residual resistance and Ic.';
        caseDef.variant.modeName = 'A4g_only';
        caseDef.variant.referenceName = 'scan_mean';
        caseDef.variant.representationName = 'abs';
        caseDef.variant.couplingMode = 'Tc_residual_only';
        caseDef.TcGain_K = 0.10;
        caseDef.IcMultiplier = 3.0;
        caseDef.residualSuppression = 0.70;
        caseDef.RnSuppression = 0.10;

    case 'case_C_crack_edge_domains'
        caseDef.label = 'Case C: crack-edge domain nucleation';
        caseDef.description = 'Crack-edge strain/relaxation nucleates enhanced domains along the crack-adjacent lane.';
        caseDef.useDeviceBestVariant = true;
        caseDef.domainMode = 'crack_edge_lane';
        caseDef.TcGain_K = 0.55;
        caseDef.IcMultiplier = 5.0;
        caseDef.residualSuppression = 0.88;
        caseDef.RnSuppression = 0.20;
        caseDef.laneHalfWidth_um = 0.85;
        caseDef.gapProbability = 0.04;
        caseDef.backgroundGainFactor = 0.15;

    case 'case_D_boundary_lane'
        caseDef.label = 'Case D: boundary-lane percolation';
        caseDef.description = 'The covered/uncovered boundary is treated as a correlated strain-transfer lane.';
        caseDef.useDeviceBestVariant = true;
        caseDef.domainMode = 'boundary_lane';
        caseDef.TcGain_K = 0.55;
        caseDef.IcMultiplier = 5.0;
        caseDef.residualSuppression = 0.86;
        caseDef.RnSuppression = 0.20;
        caseDef.laneHalfWidth_um = 0.55;
        caseDef.gapProbability = 0.03;
        caseDef.backgroundGainFactor = 0.15;

    case 'case_E_contact_relaxation'
        caseDef.label = 'Case E: contact/probe relaxation';
        caseDef.description = 'Metal contacts locally suppress strain-enhanced superconducting parameters.';
        caseDef.useDeviceBestVariant = true;
        caseDef.contactRelaxationOnly = true;
        caseDef.contactWidth_um = 0.80;
        caseDef.contactTcSuppression_K = 0.25;
        caseDef.contactIcMultiplier = 0.45;
        caseDef.contactResidualIncrease = 0.22;
        caseDef.contactRnIncrease = 0.20;

    case 'case_F_interrupted_boundary_lane'
        caseDef.label = 'Case F: interrupted boundary-lane superconductivity';
        caseDef.description = 'A strong but spatially interrupted superconducting lane forms along the covered/uncovered boundary.';
        caseDef.useDeviceBestVariant = true;
        caseDef.domainMode = 'interrupted_boundary_lane';
        caseDef.TcGain_K = 0.72;
        caseDef.IcMultiplier = 6.0;
        caseDef.residualSuppression = 0.90;
        caseDef.RnSuppression = 0.24;
        caseDef.laneHalfWidth_um = 0.65;
        caseDef.gapProbability = 0.08;
        caseDef.backgroundGainFactor = 0.10;
        caseDef.interruptionWidth_um = 0.45;
        caseDef.contactGapWidth_um = 0.70;

    case 'case_G_weak_boundary_channel'
        caseDef.label = 'Case G: weakly connected boundary channel';
        caseDef.description = 'A continuous covered/uncovered boundary channel forms, but its finite weak-link transparency creates broad/residual transport.';
        caseDef.useDeviceBestVariant = true;
        caseDef.domainMode = 'weak_boundary_channel';
        caseDef.TcGain_K = 0.55;
        caseDef.IcMultiplier = 4.0;
        caseDef.residualSuppression = 0.65;
        caseDef.RnSuppression = 0.12;
        caseDef.laneHalfWidth_um = 0.70;
        caseDef.gapProbability = 0.00;
        caseDef.backgroundGainFactor = 0.08;
        caseDef.weakChannelResidualFloor = 0.18;
        caseDef.weakChannelRnMultiplier = 0.92;

    otherwise
        error('Unknown v6.7 physics case "%s".', caseID);
end

% Device-specific gentleness: AS002 is experimentally close to normal, so do
% not let physics cases force strong superconductivity by default.
if strcmp(deviceName, 'AS002') && ismember(caseID, {'case_C_crack_edge_domains','case_D_boundary_lane','case_F_interrupted_boundary_lane','case_G_weak_boundary_channel'})
    caseDef.TcGain_K = 0.20;
    caseDef.IcMultiplier = 2.0;
    caseDef.residualSuppression = 0.35;
    caseDef.gapProbability = 0.25;
end

if strcmp(deviceName, 'AS006') && strcmp(caseID, 'case_G_weak_boundary_channel')
    caseDef.TcGain_K = 0.78;
    caseDef.IcMultiplier = 5.5;
    caseDef.residualSuppression = 0.78;
    caseDef.RnSuppression = 0.15;
    caseDef.laneHalfWidth_um = 0.85;
    caseDef.weakChannelResidualFloor = 0.10;
end

% AS006 is the motivating device for Case F; make its lane stronger but keep
% the contact/interruption breaks explicit.
if strcmp(deviceName, 'AS006') && strcmp(caseID, 'case_F_interrupted_boundary_lane')
    caseDef.TcGain_K = 0.85;
    caseDef.IcMultiplier = 7.5;
    caseDef.residualSuppression = 0.94;
    caseDef.gapProbability = 0.04;
end

end

function caseDef = default_case_definition(caseID)

base = make_raman_variant_options();

caseDef = struct();
caseDef.caseID = char(caseID);
caseDef.label = char(caseID);
caseDef.description = '';
caseDef.useDeviceBestVariant = false;
caseDef.variant = struct();
caseDef.variant.alpha = 1.0;
caseDef.variant.sigma_um = base.sigma_um;
caseDef.variant.maxDistance_um = base.maxDistance_um;
caseDef.variant.minCoverageNorm = base.minCoverageNorm;
caseDef.variant.supportPower = base.supportPower;
caseDef.variant.useDisplayMap = base.useDisplayMap;
caseDef.variant.ramanScaleMode = base.ramanScaleMode;
caseDef.variant.modeName = 'all_modes';
caseDef.variant.referenceName = 'scan_mean';
caseDef.variant.representationName = 'abs';
caseDef.variant.couplingMode = 'all';

caseDef.domainMode = 'none';
caseDef.contactRelaxationOnly = false;
caseDef.TcGain_K = 0;
caseDef.IcMultiplier = 1;
caseDef.residualSuppression = 0;
caseDef.RnSuppression = 0;
caseDef.laneHalfWidth_um = 0.55;
caseDef.gapProbability = 0;
caseDef.contactWidth_um = 0.75;
caseDef.contactTcSuppression_K = 0;
caseDef.contactIcMultiplier = 1;
caseDef.contactResidualIncrease = 0;
caseDef.contactRnIncrease = 0;
caseDef.backgroundGainFactor = 1;
caseDef.interruptionWidth_um = 0.45;
caseDef.contactGapWidth_um = 0.70;
caseDef.weakChannelResidualFloor = 0.18;
caseDef.weakChannelRnMultiplier = 0.92;

end
