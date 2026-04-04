/*
QUESTION: Overall dynamics characterization per cohort.
*/
WITH geo AS (
    SELECT
        cohort,
        AVG(ABS(effective_dim_velocity)) AS mean_abs_dim_velocity,
        MAX(ABS(effective_dim_velocity)) AS max_abs_dim_velocity,
        AVG(ABS(condition_number_velocity)) AS mean_abs_cond_velocity
    FROM read_parquet('{dynamics_dir}/geometry_dynamics.parquet')
    GROUP BY cohort
),
vel AS (
    SELECT
        cohort,
        AVG(speed) AS mean_speed,
        MAX(speed) AS max_speed,
        AVG(curvature) AS mean_curvature
    FROM read_parquet('{dynamics_dir}/velocity_field.parquet')
    GROUP BY cohort
),
flags AS (
    SELECT
        cohort,
        SUM(CASE WHEN state = 'ONSET' THEN 1 ELSE 0 END) AS n_onsets,
        SUM(CASE WHEN state = 'CHANGING' THEN 1 ELSE 0 END) AS n_changing,
        MAX(severity) AS max_severity
    FROM read_parquet('{derivatives_dir}/detection_flags.parquet')
    GROUP BY cohort
)
SELECT
    COALESCE(geo.cohort, vel.cohort, flags.cohort) AS cohort,
    geo.mean_abs_dim_velocity,
    geo.max_abs_dim_velocity,
    vel.mean_speed,
    vel.max_speed,
    vel.mean_curvature,
    flags.n_onsets,
    flags.n_changing,
    flags.max_severity
FROM geo
FULL OUTER JOIN vel USING (cohort)
FULL OUTER JOIN flags USING (cohort)
ORDER BY cohort
