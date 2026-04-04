/*
QUESTION: Which cohorts are ensemble outliers based on dynamics?
*/
WITH cohort_dynamics AS (
    SELECT
        cohort,
        AVG(speed) AS mean_speed,
        MAX(speed) AS max_speed,
        AVG(curvature) AS mean_curvature
    FROM read_parquet('{dynamics_dir}/velocity_field.parquet')
    GROUP BY cohort
),
ensemble AS (
    SELECT
        AVG(mean_speed) AS ensemble_speed,
        STDDEV(mean_speed) AS ensemble_speed_std,
        AVG(max_speed) AS ensemble_max_speed,
        STDDEV(max_speed) AS ensemble_max_speed_std
    FROM cohort_dynamics
)
SELECT
    c.cohort,
    c.mean_speed,
    c.max_speed,
    (c.mean_speed - f.ensemble_speed) / NULLIF(f.ensemble_speed_std, 0) AS speed_z_score,
    (c.max_speed - f.ensemble_max_speed) / NULLIF(f.ensemble_max_speed_std, 0) AS max_speed_z_score,
    CASE
        WHEN (c.max_speed - f.ensemble_max_speed) / NULLIF(f.ensemble_max_speed_std, 0) > 2 THEN 'FAST_OUTLIER'
        WHEN (c.mean_speed - f.ensemble_speed) / NULLIF(f.ensemble_speed_std, 0) > 2 THEN 'CONSISTENTLY_FAST'
        WHEN (c.mean_speed - f.ensemble_speed) / NULLIF(f.ensemble_speed_std, 0) < -2 THEN 'CONSISTENTLY_SLOW'
        ELSE 'TYPICAL'
    END AS ensemble_status
FROM cohort_dynamics c
CROSS JOIN ensemble f
ORDER BY ABS(speed_z_score) DESC
