function scores = evaluate_scores(field, expField, opts)
%EVALUATE_SCORES Canonical score-evaluation wrapper.

scores = struct();
scores.shape = compute_v742_weaklink_feature_score(field, expField, opts.shapeScore);
scores.conductance = compute_v746_conductance_score(field, expField, opts.conductanceScore);

end

