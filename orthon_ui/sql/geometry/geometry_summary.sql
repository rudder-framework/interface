/*
QUESTION: Summary statistics of geometry per cohort.
*/
SELECT
    cohort,
    COUNT(*) AS n_windows,
    AVG(effective_dim) AS mean_eff_dim,
    STDDEV(effective_dim) AS std_eff_dim,
    MIN(effective_dim) AS min_eff_dim,
    MAX(effective_dim) AS max_eff_dim,
    AVG(condition_number) AS mean_cond_num,
    AVG(eigenvalue_entropy) AS mean_entropy,
    AVG(total_variance) AS mean_total_variance,
    AVG(CASE WHEN window_index <= (SELECT MAX(window_index) * 0.2 FROM read_parquet('{cohort_dir}/cohort_geometry.parquet') g2 WHERE g2.cohort = g.cohort) THEN effective_dim END) AS early_eff_dim,
    AVG(CASE WHEN window_index >= (SELECT MAX(window_index) * 0.8 FROM read_parquet('{cohort_dir}/cohort_geometry.parquet') g2 WHERE g2.cohort = g.cohort) THEN effective_dim END) AS late_eff_dim
FROM read_parquet('{cohort_dir}/cohort_geometry.parquet') g
GROUP BY cohort
ORDER BY cohort
