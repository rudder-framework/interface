/*
QUESTION: What are the statistical and primitive characteristics of each signal?
INPUT: signal_statistics.parquet, signal_primitives.parquet
*/
SELECT
    s.cohort,
    s.signal_id,
    s.n_obs,
    s.mean,
    s.std,
    s.min_val,
    s.max_val,
    s.kurtosis,
    s.skewness,
    s.cv,
    s.is_constant,
    p.hurst_exponent,
    p.sample_entropy,
    p.perm_entropy,
    p.spectral_slope,
    p.spectral_flatness,
    CASE
        WHEN s.is_constant THEN 'CONSTANT'
        WHEN s.cv < 0.01 THEN 'NEAR_CONSTANT'
        WHEN p.hurst_exponent > 0.8 THEN 'PERSISTENT_TREND'
        WHEN p.hurst_exponent < 0.3 THEN 'ANTI_PERSISTENT'
        WHEN p.sample_entropy > 2.0 THEN 'HIGH_COMPLEXITY'
        WHEN p.sample_entropy < 0.5 THEN 'LOW_COMPLEXITY'
        ELSE 'TYPICAL'
    END AS signal_character
FROM read_parquet('{ml_dir}/ml_signal_statistics.parquet') s
JOIN read_parquet('{ml_dir}/ml_signal_primitives.parquet') p
    ON s.signal_id = p.signal_id AND s.cohort = p.cohort
ORDER BY s.signal_id, s.cohort
