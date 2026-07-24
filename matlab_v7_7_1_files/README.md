# MoTe2 superconducting-network model v7.7.1

v7.7.1 is an evidence-reporting layer for the real v7.7 score ledgers. It does not add a new transport mechanism. Instead, it turns the current AS006 candidate-model table into a thesis-facing “can we claim this?” report.

Run from MATLAB with:

```matlab
cd('/Users/asewaket/Documents/LTSpice Superconducting Circuit/matlab_v7_7_1_files')
out = run_v771_mechanism_evidence_report;
```

The report includes:

- multi-observable objective score;
- seed count and seed-to-seed score variability;
- ablation Z-score relative to the no-weak-link and central-lane baselines;
- whether the mechanism survives both probe pairs;
- whether it beats no-weak-link and central-lane baselines;
- a final `claimReady` gate.

Important interpretation:

- Lower score is better for screening.
- A lower score is not automatically a physical conclusion.
- With a single seed, ablation Z is intentionally reported as `NaN`; the model has not yet earned a claim-ready mechanism label.
- The next substantive step is to generate true multi-seed ledgers for the leading mechanisms, then repeat the same v7.7.1 gate report.

