/*
QUESTION: What is the system velocity — how fast is state changing?
*/
SELECT
    cohort,
    signal_0_center,
    speed,
    acceleration_magnitude,
    acceleration_parallel,
    acceleration_perpendicular,
    curvature,
    dominant_motion_signal,
    dominant_motion_fraction,
    motion_dimensionality,
    CASE
        WHEN speed < 0.1 THEN 'QUASI_STATIC'
        WHEN speed < 1.0 THEN 'SLOW'
        WHEN speed < 5.0 THEN 'MODERATE'
        ELSE 'FAST'
    END AS speed_class
FROM read_parquet('{dynamics_dir}/velocity_field.parquet')
ORDER BY cohort, signal_0_center
