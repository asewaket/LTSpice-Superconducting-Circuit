function samples = generate_sensitivity_samples(opts)
%GENERATE_SENSITIVITY_SAMPLES Random parameter/proxy samples.

rng(opts.seed);
fields = fieldnames(opts.ranges);

samples = repmat(struct(), opts.Nsweep, 1);

for k = 1:opts.Nsweep
    for jf = 1:numel(fields)
        f = fields{jf};
        range = opts.ranges.(f);
        samples(k).(f) = range(1) + rand() * (range(2) - range(1));
    end
    samples(k).sampleIndex = k;
end

end

