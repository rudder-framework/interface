/*
QUESTION: How stable is each signal's amplitude envelope?
*/
SELECT
    signal_id,
    cohort,
    mean_amplitude,
    amplitude_std,
    amplitude_cv,
    mean_frequency,
    stability_ratio,
    signal_energy
FROM read_parquet('{signal_dir}/signal_stability.parquet')
ORDER BY stability_ratio
