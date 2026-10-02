# Mechanics-Informed Superconducting Network: Manuscript Scaffold

## Final Paper-Level Claim

The frozen model supports this manuscript-level statement:

> A normalized mechanics-derived gradient field contains transport-relevant spatial information in the device series. Its dominant supported role is to organize weak-link connectivity in the two-dimensional superconducting network, while local Tc modulation provides a secondary contribution.

Required caveat:

> The mechanics calculation identifies transport-relevant normalized spatial structure. It does not reconstruct the absolute device-specific strain tensor.

## Final Modeling Narrative

The main text should present the model as a compact scientific workflow, not as a phase history:

1. The six-device hierarchy shows that nominal film force alone is insufficient.
2. A geometry-aware two-dimensional superconducting network separates local superconducting strength from connectivity.
3. Normalized forward mechanics identifies mechanical-gradient localization at boundaries and discontinuities.
4. A frozen prior ablation shows that this mechanics-derived spatial prior outperforms geometry-only, uniform, and randomized controls.
5. A coupling-role ablation identifies weak-link connectivity as the dominant supported role, with local Tc modulation secondary.
6. Robustness checks show that the conclusion survives disorder, coarse-graining, prior normalization, randomized overlap nulls, and anchor-device selection.

The main text should avoid internal phase numbers, exploratory failures, version history, and optimization chronology. Those details belong in Methods, Supplementary Information, or an archival reproducibility appendix.

## Main Modeling Figures

### Figure A: Model Architecture

Purpose: show the final architecture in one visual chain.

Core panels:

- Experimental device/stressor geometry and the six-device hierarchy.
- Schematic workflow: device geometry -> normalized mechanics prior -> Tc and W_ij fields -> four-probe network.
- Network cartoon distinguishing local superconducting strength from weak-link connectivity.
- Scope box: frozen transport architecture, no retuning, no Phase 6 relabeling, no absolute strain reconstruction.

Paper message:

> The model tests whether normalized mechanical localization supplies transport-relevant spatial information to a frozen two-dimensional superconducting network.

Recommended source artifacts:

- `phase6_six_device_evidence_matrix.csv`
- `phase19FS_frozen_policy_manifest.csv`
- `phase19GS_final_multiscale_model_freeze.csv`
- `phase19FS_device_interpretation.csv`

### Figure B: Mechanics Prior Transport Test

Purpose: show that the mechanics prior adds transport-relevant information.

Core panels:

- Six-device comparison with AS005 and AS006 highlighted.
- Geometry-only, mechanics-gradient, uniform, and randomized-prior comparison.
- Critical-device contribution for AS005 and AS006.
- Compact spatial-null or randomized-control panel showing that the mechanics field is not merely a value distribution.

Paper message:

> The mechanics-derived spatial prior improves the frozen transport description relative to geometry-only, uniform, and randomized controls, with strongest support from AS005 and AS006.

Recommended source artifacts:

- `phase19ESR_prior_score_replay.csv`
- `phase19ESR_randomized_spatial_null.csv`
- `phase19ESR_decision_summary.csv`
- `phase19FS_six_device_transport_comparison.csv`

### Figure C: Mechanistic Role and Robustness

Purpose: show what role the mechanics prior plays and why the conclusion is stable.

Core panels:

- AS005 and AS006 spatial integration panel: H_gradient, Tc proxy, W proxy, transition current.
- Coupling-role ablation: Tc-only, weak-link-only, diagnostic both-channel.
- Current-weighted mechanics overlap for AS005 and AS006.
- Compact robustness panel: disorder, grid, normalization, overlap null, leave-one-anchor-out.

Paper message:

> The dominant supported role of mechanical localization is weak-link connectivity, not Tc-only modulation, and this conclusion survives the main robustness checks without retuning.

Recommended source artifacts:

- `phase19FS_AS005_AS006_spatial_integration_panel.png`
- `phase19FS_coupling_role_ablation.csv`
- `phase19FS_mechanics_current_overlap_metrics.csv`
- `phase19GS_final_robustness_freeze_summary.png`
- `phase19GS_decision_summary.csv`

## Supplementary Figure Architecture

### Figure S1: Full Six-Device Score Matrix

Purpose: show all devices under geometry, mechanics, uniform, and randomized/reference controls.

Source artifacts:

- `phase19FS_six_device_transport_comparison.csv`
- `phase19ESR_prior_score_replay.csv`

### Figure S2: Mechanics Descriptor Selection

Purpose: justify H_gradient as the promoted normalized mechanics prior.

Source artifacts:

- `phase19ES_descriptor_ranking.csv`
- `phase19ES_scaling_summary.csv`
- `phase19ES_prior_family_freeze.csv`

### Figure S3: Current-Overlap Null Distributions

Purpose: show randomized overlap distributions for AS005 and AS006.

Source artifacts:

- `phase19GS_current_overlap_null_distribution.csv`
- `phase19GS_current_overlap_null_summary.csv`

### Figure S4: Full Coupling-Role Ledger

Purpose: show F-S0 reference, Tc-only, weak-link-only, and diagnostic both-channel rows for all devices.

Source artifact:

- `phase19FS_coupling_role_ablation.csv`

### Figure S5: Guard-Device Preservation

Purpose: show that AS001-AS003 are not forced into structured-connectivity interpretations.

Source artifacts:

- `phase19FS_device_interpretation.csv`
- `phase19GS_final_multiscale_model_freeze.csv`

### Figure S6: Numerical Robustness Details

Purpose: keep disorder, grid, normalization, and leave-one-anchor-out ledgers out of the main figure while preserving auditability.

Source artifacts:

- `phase19GS_disorder_seed_robustness.csv`
- `phase19GS_grid_coarse_graining_robustness.csv`
- `phase19GS_prior_normalization_robustness.csv`
- `phase19GS_leave_one_anchor_out.csv`

## Modeling Section Outline

### 3.x Multiscale Modeling of Mechanically Structured Superconductivity

Opening task:

Introduce the modeling section as a test of whether geometry-derived mechanical heterogeneity helps explain the six-device transport hierarchy. State that the model is not intended to reconstruct absolute strain.

### 3.x.1 Geometry-Aware Superconducting Network

Purpose:

Describe the frozen two-dimensional superconducting-network architecture.

Must include:

- local superconducting strength and weak-link connectivity are distinct fields;
- the four-probe response is computed from the network;
- the device hierarchy and evidence rules are fixed before mechanics integration;
- downstream retuning is not used to make the mechanics prior work.

Figure callout:

Use Figure A.

### 3.x.2 Normalized Forward-Mechanics Prior

Purpose:

Introduce the normalized mechanics-derived gradient field as an upstream spatial prior.

Must include:

- H_gradient is a normalized mechanics-derived localization descriptor;
- AS005 and AS006 are complementary anchor cases: crack/discontinuity and half-coverage boundary;
- H_gradient is not epsilon(x,y), and not a measured strain tensor.

Figure callout:

Use Figure A or the first panel of Figure B, depending on layout.

### 3.x.3 Mechanics-Prior Transport Test

Purpose:

Show that the mechanics prior contains transport-relevant spatial information under frozen downstream rules.

Must include:

- geometry-only reference;
- mechanics-gradient prior;
- uniform control;
- spatially randomized control;
- AS005/AS006 critical-device contribution.

Figure callout:

Use Figure B.

### 3.x.4 Weak-Link Connectivity as the Dominant Supported Role

Purpose:

Interpret how the mechanics prior enters the network.

Must include:

- Tc-only coupling is supporting but not sufficient;
- weak-link/connectivity coupling retains the dominant explanatory benefit;
- diagnostic both-channel coupling is not promoted as the primary claim because it has greater interpretive freedom;
- current-overlap metrics show that current preferentially samples mechanics-localized regions during transition and low-temperature stages.

Figure callout:

Use Figure C.

### 3.x.5 Robustness and Model Scope

Purpose:

Close model development and define the claim boundary.

Must include:

- conclusion survives disorder, coarse-graining, prior normalization, randomized overlap nulls, and leave-one-anchor-out checks;
- AS001-AS003 guard behavior is preserved;
- no absolute strain reconstruction is claimed;
- no new transport mechanism is proposed after the freeze;
- optional AS005/AS006 3D PDE visualization is a publication enhancement, not unfinished core science.

Figure callout:

Use the robustness panel of Figure C.

## Claims Ledger

### Supported

- Nominal film force alone is insufficient to organize the six-device transport hierarchy.
- Normalized mechanical-gradient localization is transport relevant under frozen downstream rules.
- The mechanics-derived prior outperforms geometry-only, uniform, and randomized controls.
- Weak-link connectivity is the dominant supported role of the mechanics prior.
- Local Tc modulation is secondary/supporting.
- AS005 and AS006 independently support the final interpretation.
- AS001-AS003 preserve guard behavior.
- The final conclusion is robust to disorder, grid/coarse-graining, prior normalization, current-overlap nulls, and anchor-device selection.

### Not Claimed

- Absolute device-specific strain reconstruction.
- Quantitative epsilon_xx, epsilon_yy, epsilon_xy tensor inversion.
- Microscopic proof that strain gradients cause weak links.
- Direct proof of a pairing mechanism controlled by |grad epsilon|.
- A new transport mechanism beyond the frozen superconducting-network architecture.
- Retuned device-specific superconducting parameters.

## Targeted 3D PDE Decision

The central paper is supportable without 3D PDE. A targeted 3D calculation should be included only if it gives a visually and scientifically clearer answer to this focused question:

> Does the boundary/crack-associated normalized mechanical-gradient localization identified by the reduced mechanics model persist through the layered geometry of AS005 and AS006?

Recommended scope:

- AS005 and AS006 only.
- Plot quantities tied to the frozen mechanism: normalized epsilon_xx, normalized epsilon_yy, |epsilon_xy|, |grad epsilon|, and optionally u_z.
- Do not add transport parameters, new coupling roles, or absolute strain claims.

Recommended placement:

- Main text only if compact and decisive.
- Otherwise Supplementary Information.

## Final Stop Condition

The modeling campaign should remain frozen:

```ini
model_development_status = complete
next_stage = publication_outputs
new_transport_mechanisms_recommended = false
absolute_strain_claims_allowed = false
```
