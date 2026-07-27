# PHASE4_SCOPE

## Purpose

Phase 4 is an identifiability and pruning phase. It does not introduce new
physics and it does not change the Phase 3 AS006 seed campaign. Its job is to
consume the Phase 3 ledgers and decide which weak-link mechanisms are
identifiable, which are required controls, and which can be pruned before
six-device transfer.

Phase 4 may run while Phase 3 is still computing, but any result with fewer
than the frozen Phase 3 seed count is provisional.

## Inputs

Primary input:

- `matlab_v8_0/outputs/v8_0_phase3_as006_multiseed/seed_ledgers/AS006_v8_0_phase3_seed_*_scores.csv`

Optional input after Phase 3 completion:

- `AS006_v8_0_phase3_mechanism_report.csv`
- `AS006_v8_0_phase3_gate_report.csv`

The report builder reads the seed ledgers directly so it can run on partial
evidence without disturbing an active Phase 3 MATLAB process.

## Questions

1. Which mechanism is identifiable in shape-controlled scoring?
2. Which mechanism is identifiable in conductance-preserving scoring?
3. Which mechanisms occupy a parameter basin rather than a single isolated
   optimum?
4. Which controls must remain for interpretation?
5. Which mechanisms are weak enough to prune after, but not before, the full
   Phase 3 seed count is available?

## Non-Goals

Phase 4 must not:

- rerun or alter the Phase 3 campaign;
- change v7.4.6 physics, grids, seed list, or score definitions;
- introduce new weak-link classes;
- make final pruning decisions from fewer than 10 AS006 seeds;
- claim microscopic junction identity from ranking alone.

## Required Controls

These mechanisms are protected from pruning even if they score poorly:

- no weak links;
- uniform weak links;
- shuffled weak links;
- central-lane / 1D-like.

They are not retained because they are good models; they are retained because
they are required baselines for the frozen scientific question.

## Diagnostic Controls

`anisotropic control` is retained as a diagnostic control. It can help separate
generic anisotropy from named physical weak-link classes, but it is not a
transfer-primary physical mechanism unless a later validation phase explicitly
promotes it.

## Pruning Criteria

A non-control mechanism is a strong retain candidate only when, after the full
10-seed Phase 3 campaign:

- it appears in the top two mechanisms in at least one calibration mode with
  probability at or above the configured threshold;
- it beats both no-weak-link and central-lane baselines with probability at or
  above the configured threshold;
- it has at least the configured number of near-best parameter signatures;
- it does not depend on one isolated seed or one isolated parameter point.

A non-control mechanism becomes a prune candidate only after full Phase 3
completion and only if it has low win/top-two support, weak baseline-beating
probability, and insufficient basin occupancy.

After full Phase 3 completion, a non-control mechanism with zero top-two support
in both calibration modes is marked `not_transfer_primary` even if it beats the
null baselines. This prevents broad but non-identifiable basins from being
mistaken for leading physical mechanisms.

Before all 10 seeds are available, Phase 4 may label a mechanism as
`provisional_keep_candidate`, `provisional_hold`, `diagnostic_control`, or
`required_control`, but not as finally pruned.

## Deliverables

Phase 4 writes:

- candidate score table;
- seed/mode mechanism winner table;
- mechanism identifiability summary;
- parameter-basin table;
- pruning decision table;
- compact identifiability/pruning figure.

The final Phase 4 pruning decision should be rerun after Phase 3 has completed.
