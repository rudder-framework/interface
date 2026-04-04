/*
QUESTION: How do cohorts differ from each other? Ensemble outlier detection.
*/
WITH cohort_stats AS (
    SELECT
        cohort,
        AVG(effective_dim) AS mean_eff_dim,
        AVG(condition_number) AS mean_cond_num,
        AVG(total_variance) AS mean_total_var,
        STDDEV(effective_dim) AS std_eff_dim
    FROM read_parquet('{cohort_dir}/cohort_geometry.parquet')
    GROUP BY cohort
),
ensemble AS (
    SELECT
        AVG(mean_eff_dim) AS ensemble_eff_dim,
        STDDEV(mean_eff_dim) AS ensemble_eff_dim_std,
        AVG(mean_cond_num) AS ensemble_cond_num
    FROM cohort_stats
)
SELECT
    c.cohort,
    c.mean_eff_dim,
    c.mean_cond_num,
    c.std_eff_dim,
    (c.mean_eff_dim - f.ensemble_eff_dim) / NULLIF(f.ensemble_eff_dim_std, 0) AS eff_dim_z_score,
    CASE
        WHEN ABS((c.mean_eff_dim - f.ensemble_eff_dim) / NULLIF(f.ensemble_eff_dim_std, 0)) > 2 THEN 'OUTLIER'
        WHEN ABS((c.mean_eff_dim - f.ensemble_eff_dim) / NULLIF(f.ensemble_eff_dim_std, 0)) > 1 THEN 'ATYPICAL'
        ELSE 'TYPICAL'
    END AS ensemble_status
FROM cohort_stats c
CROSS JOIN ensemble f
ORDER BY ABS(eff_dim_z_score) DESC
