function model = apply_sensitivity_sample_to_model(baseModel, sample)
%APPLY_SENSITIVITY_SAMPLE_TO_MODEL Modify shared model using one sample row.

model = baseModel;

model.proxy.coveredWeight = sample.coveredWeight;
model.proxy.boundaryWeight = sample.boundaryWeight;
model.proxy.crackWeight = sample.crackWeight;
model.proxy.edgeWeight = sample.edgeWeight;

model.Tc.TcSpan_K = sample.TcSpan_K;
model.Tc.eta0 = sample.eta0;
model.Tc.sigmoidWidth = sample.sigmoidWidth;

model.residual.fLow = sample.residualLow;
model.residual.fHigh = sample.residualHigh;

end
