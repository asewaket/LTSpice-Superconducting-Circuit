# MODEL_SCOPE

## Frozen scientific question

This document defines the fitting scope for the final v8 optimization campaign. It is a scientific contract: the questions, excluded claims, comparison baselines, and gate rules below must not change during fitting. Model development after this point should be a validation, reduction, and reproducibility campaign, not another search for new mechanisms.

## Primary question

Can one shared two-dimensional superconducting-network framework identify, for each device, whether local-Tc heterogeneity is sufficient, structured connectivity is required, or the available measurements cannot distinguish the two?

The core test is therefore hierarchical and comparative. A structured weak-link model is useful for a given device only if it beats the relevant null models under the same geometry, local superconducting-scale construction, disorder policy, calibration convention, and scoring rules. The final objective is not to force one AS006-derived weak-link law to beat controls on every device; it is to select the minimum supported level:

- `M0`: local-Tc heterogeneity with `W_ij = 1`;
- `M1`: local-Tc heterogeneity plus geometry-activated structured connectivity;
- `M2`: local-Tc heterogeneity plus the full combined bottleneck structure.

## Secondary questions

1. Which spatial weak-link class is supported most consistently across observables and seeds?
2. Is the result robust to disorder realization, Raman registration uncertainty, and mesh resolution?
3. Does one global rule set provide descriptive value without device-specific weak-link retuning, and where does strict held-out transfer fail?
4. Which conclusions concern local superconductivity, which concern connectivity, and which are unresolved under the available observables?
5. Can synthetic datasets generated from known `M0`, `M1`, and `M2` mechanisms be recovered by the same scoring workflow?

## In-scope model ingredients

The core model may use measured or fixed device information: Hall-bar geometry, source/drain contacts, voltage probes, stressor coverage, crack masks, nominal film-force metadata, registered Raman priors where available, and measured normal-state resistance.

The shared model rules may include:

- a geometry/Raman mechanical-prior field that generates local Tc variation;
- correlated local Tc disorder with fixed or globally fitted scale and correlation length;
- a literature-bounded gap ratio prior, `alpha_gap`;
- effective link resistance through weak-link transparency, `Rn_eff = Rn / W_ij`;
- gap-derived critical-current scale, `Ic ~ pi Delta / (2 e Rn_eff)`;
- a small set of named weak-link classes, such as bulk, boundary/SNS-inspired constriction, contact-relaxed, crack/tunnel-like, and anisotropic control;
- scalar smooth switching around the gap-derived critical-current scale;
- shape-controlled and conductance-preserving calibration modes;
- multi-observable scoring with probe-pair, transition-metric, held-out, complexity, seed-variability, and ablation-gate bookkeeping.

The model is allowed to identify whether local superconducting scale and spatial connectivity are sufficient to explain the observed transport classes. It is not allowed to infer a unique microscopic mechanism from a good score alone.

## Required baselines

Every mechanism claim must be compared against:

- local-Tc heterogeneity with no weak-link transparency structure;
- no weak links;
- uniform weak-link transparency;
- shuffled weak-link transparency with the same transparency histogram;
- central-lane or one-dimensional current-path control;
- the simplest structured weak-link class that can explain the same observables.

The preferred model is the simplest model that passes the validation gates, not necessarily the model with the lowest single score. Primary-only classifications carry lower evidence confidence than classifications supported by independent probe-pair evidence.

## Phase 5C Freeze And 5D Handoff

Phase 5C is frozen as a synthetic identifiability result, not as a calibrated experimental classifier. Its label policy is fixed:

- `M0` is unstructured;
- `M1` and `M2` are structured;
- `mixed` has exact-recovery target `M1` and binary class `structured`.

The Phase 5C misspecification failures must be preserved as diagnostic failures. They show that broadened or shifted local-Tc-only responses can be falsely promoted to structured connectivity, and that weak structured cases can be classified too confidently as local-like. These failures are not a reason to add a new mechanism class or retune Phase 5C.

Phase 5D is therefore restricted to uncertainty and significance calibration: define a nuisance-aware `M0*` family, estimate score-difference uncertainty, set unresolved decision thresholds, and validate the frozen calibrated rule on independent synthetic perturbations. The Phase 5C misspecification set may be used to design Phase 5D, but it must not be reused as the final post-calibration validation set.

The Phase 5D decision hierarchy is fixed: first decide `M0* supported`, `structured supported`, or `unresolved`; only after structured support is significant may the workflow distinguish `M1` from `M2`.

## Explicitly excluded questions

The core v8 model must not attempt to establish:

- topological superconductivity;
- Josephson phase dynamics;
- vortex trajectories;
- flux quantization;
- microscopic pairing symmetry;
- heating and hysteretic dynamics;
- a unique local strain map.

The v7.4.6 documentation already states the relevant boundary: current switching remains sigmoid-like, while phase dynamics, vortices, heating, and sweep history remain outside the present model. Magnetic-field raster data may be used as diagnostic context, but a scalar resistor network without phase and flux dynamics cannot claim a quantitative fluxoid or vortex mechanism.

## Claim language

Allowed claim form:

> The measured transport is consistent with a geometry-constrained two-dimensional superconducting network in which literature-bounded local gap scales determine link critical currents and spatially structured weak-link transparency controls global connectivity.

Disallowed claim form:

> The model proves a microscopic junction type, topological edge mode, phase-interference mechanism, vortex trajectory, or unique strain map.

## Phase gate

No new physics class may be introduced after this phase unless every current candidate fails the validation campaign.

A current candidate fails only if it fails the agreed multi-seed, ablation-Z, both-probe, held-out, mesh, Raman-registration, and six-device transfer gates under the frozen scoring rules. If that happens, any proposed new physics class must be documented as a new scope revision before fitting begins again.
