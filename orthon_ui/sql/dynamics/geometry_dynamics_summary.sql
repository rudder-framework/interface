/*
QUESTION: How fast is the eigenstructure changing?
*/
SELECT
    cohort,
    signal_0_center,
    effective_dim_velocity,
    effective_dim_acceleration,
    condition_number_velocity,
    variance_velocity,
    CASE
        WHEN effective_dim_velocity < -0.05 THEN 'COLLAPSING'
        WHEN effective_dim_velocity > 0.05 THEN 'EXPANDING'
        ELSE 'STABLE'
    END AS dim_trend
FROM read_parquet('{dynamics_dir}/geometry_dynamics.parquet')
ORDER BY cohort, signal_0_center
