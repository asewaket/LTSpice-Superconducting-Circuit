# MODEL_SCOPE

## Frozen scientific question

This document defines the fitting scope for the final v8 optimization campaign. It is a scientific contract: the questions, excluded claims, comparison baselines, and gate rules below must not change during fitting. Model development after this point should be a validation, reduction, and reproducibility campaign, not another search for new mechanisms.

## Primary question

Does a spatially structured weak-link transparency field improve the explanation of measured transport beyond local-Tc heterogeneity alone, a uniform weak-link distribution, and a one-dimensional current path?

The core test is therefore comparative. A structured weak-link model is useful only if it beats the relevant null models under the same geometry, local superconducting-scale construction, disorder policy, calibration convention, and scoring rules.

## Secondary questions

1. Which spatial weak-link class is supported most consistently across observables and seeds?
2. Is the result robust to disorder realization, Raman registration uncertainty, and mesh resolution?
3. Does one global rule set transfer across AS001-AS006 without device-specific weak-link retuning?
4. Which conclusions concern local superconductivity, and which conclusions concern connectivity?

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

The preferred model is the simplest model that passes the validation gates, not necessarily the model with the lowest single score.

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
