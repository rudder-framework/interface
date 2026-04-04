/*
QUESTION: Fleet-level statistics for comparison context.
*/
WITH geo AS (
    SELECT
        cohort,
        AVG(effective_dim) AS mean_eff_dim,
        STDDEV(effective_dim) AS std_eff_dim
    FROM read_parquet('{cohort_dir}/cohort_geometry.parquet')
    GROUP BY cohort
)
SELECT
    COUNT(DISTINCT cohort) AS n_cohorts,
    AVG(mean_eff_dim) AS ensemble_mean_eff_dim,
    STDDEV(mean_eff_dim) AS ensemble_std_eff_dim,
    MIN(mean_eff_dim) AS ensemble_min_eff_dim,
    MAX(mean_eff_dim) AS ensemble_max_eff_dim
FROM geo
