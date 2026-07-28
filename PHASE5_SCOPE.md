# PHASE5_SCOPE

## Purpose

Phase 5 is the hierarchical six-device transfer phase. It tests whether the
reduced v8 rule set selected from AS006 can transfer across AS001-AS006 without
device-specific weak-link retuning.

Phase 5 does not introduce new physics. It starts from the Phase 4 retained
mechanisms and required controls.

## Reduced Candidate Set

Transfer-primary mechanisms:

- combined physical bottleneck;
- contact-relaxed weak links;
- crack/tunnel-like weak links.

Required controls:

- no weak links;
- uniform weak links;
- shuffled weak links;
- central-lane / 1D-like.

Diagnostic controls:

- anisotropic control.

Diagnostic hold, not transfer-primary:

- boundary/SNS-inspired constriction.

## Scientific Questions

1. Does the same global rule set transfer across AS001-AS006?
2. Which retained weak-link class is most stable across devices?
3. Are conclusions about local superconductivity separable from conclusions
   about connectivity?
4. Does transfer survive leave-one-device-out and held-out-probe checks?

## Non-Goals

Phase 5 must not:

- add new weak-link classes;
- tune mechanism-specific rules independently per device;
- use AS006-only rank as proof of microscopic mechanism;
- fit phase dynamics, vortices, flux quantization, heating, or unique strain.

## Required Gates

Phase 5 should advance only if:

- at least one transfer-primary mechanism beats required controls on most
  devices;
- retained classes do not collapse under leave-one-device-out testing;
- probe/asymmetry diagnostics remain acceptable where both probe pairs exist;
- the global parameter rules remain shared across devices;
- failures are reported as device-specific limitations, not hidden by retuning.

## Evidence Levels

Level A is the common six-device R(T) transfer layer. Every device with a mapped
four-probe R(T) curve contributes normalized curve and transition-metric
evidence.

Level B is the probe-pair/asymmetry and selected nonlinear layer. It is active
only where second-probe or I-dependent traces are mapped.

Level C is the full dV/dI(I,B) nonlinear validation layer. AS006 is currently
the nonlinear anchor because it has the mapped field-sweep data used by the
v7.4.6 scorer.

## Deliverables

Phase 5 begins with a transfer plan:

- reduced candidate set;
- device validation plan;
- validation gate table;
- manifest linking back to Phase 4 decisions.

The executable Phase 5 campaign then writes:

- `phase5_data_manifest.csv`, the observable-availability authority;
- device run-status table, including explicit unavailable-data rows;
- per-device transfer score ledger;
- per-device primary-vs-control summary;
- leave-one-device-out survival table;
- gate-result table;
- transfer summary figure.

The Level A R(T) transfer layer is expected to score all six devices. Missing
field maps are carried as Level C availability notes, not as exclusions from
Phase 5.
