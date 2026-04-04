/*
QUESTION: How has effective dimension evolved over time per cohort?
*/
SELECT
    cohort,
    window_index,
    signal_0_center,
    effective_dim,
    LAG(effective_dim, 1) OVER w AS prev_eff_dim,
    effective_dim - LAG(effective_dim, 1) OVER w AS eff_dim_delta,
    AVG(effective_dim) OVER (PARTITION BY cohort ORDER BY window_index ROWS BETWEEN 4 PRECEDING AND CURRENT ROW) AS eff_dim_ma5,
    MIN(effective_dim) OVER (PARTITION BY cohort) AS eff_dim_min,
    MAX(effective_dim) OVER (PARTITION BY cohort) AS eff_dim_max,
    (effective_dim - MIN(effective_dim) OVER (PARTITION BY cohort))
        / NULLIF(MAX(effective_dim) OVER (PARTITION BY cohort) - MIN(effective_dim) OVER (PARTITION BY cohort), 0)
        AS eff_dim_normalized
FROM read_parquet('{cohort_dir}/cohort_geometry.parquet')
WINDOW w AS (PARTITION BY cohort ORDER BY window_index)
ORDER BY cohort, window_index
