/*
QUESTION: What is the overall system stability margin?
Combines geometry stability, onset count, severity, and velocity.
Stability margin = 10 (fully stable) → 0 (critical).
*/
WITH geo AS (
    SELECT
        cohort,
        LAST(effective_dim ORDER BY window_index) AS current_eff_dim,
        MAX(effective_dim) AS max_eff_dim,
        STDDEV(effective_dim) AS eff_dim_volatility
    FROM read_parquet('{cohort_dir}/cohort_geometry.parquet')
    GROUP BY cohort
),
flags AS (
    SELECT
        cohort,
        SUM(CASE WHEN state IN ('ONSET', 'CHANGING') THEN 1 ELSE 0 END) AS n_active_events,
        MAX(severity) AS max_severity,
        AVG(CASE WHEN state != 'STABLE' THEN severity ELSE NULL END) AS mean_event_severity
    FROM read_parquet('{derivatives_dir}/detection_flags.parquet')
    GROUP BY cohort
),
vel AS (
    SELECT
        cohort,
        AVG(speed) AS mean_speed,
        MAX(speed) AS max_speed
    FROM read_parquet('{dynamics_dir}/velocity_field.parquet')
    GROUP BY cohort
)
SELECT
    COALESCE(geo.cohort, flags.cohort, vel.cohort) AS cohort,
    geo.current_eff_dim,
    geo.max_eff_dim,
    geo.eff_dim_volatility,
    flags.n_active_events,
    flags.max_severity,
    vel.mean_speed,
    GREATEST(0, LEAST(10,
        10.0
        - COALESCE(flags.max_severity, 0)
        - CASE WHEN geo.current_eff_dim / NULLIF(geo.max_eff_dim, 0) < 0.5 THEN 2 ELSE 0 END
        - LEAST(2, COALESCE(flags.n_active_events, 0) * 0.2)
        - CASE WHEN COALESCE(vel.max_speed, 0) > 5 THEN 1 ELSE 0 END
    )) AS stability_margin,
    CASE
        WHEN GREATEST(0, LEAST(10, 10.0 - COALESCE(flags.max_severity, 0))) < 3 THEN 'CRITICAL'
        WHEN GREATEST(0, LEAST(10, 10.0 - COALESCE(flags.max_severity, 0))) < 5 THEN 'WARNING'
        WHEN GREATEST(0, LEAST(10, 10.0 - COALESCE(flags.max_severity, 0))) < 7 THEN 'CAUTION'
        ELSE 'STABLE'
    END AS stability_status
FROM geo
FULL OUTER JOIN flags ON geo.cohort = flags.cohort
FULL OUTER JOIN vel ON COALESCE(geo.cohort, flags.cohort) = vel.cohort
ORDER BY stability_margin
