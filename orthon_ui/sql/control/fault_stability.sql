/*
QUESTION: Which faults are most destabilizing?
Compare stability metrics across fault types.
Source: control_theory.parquet (one row per cohort).
*/
SELECT
    cohort,
    phase_margin_deg,
    stability_index,
    health_index AS stability_margin,
    control_margin,

    -- Raw stability metrics
    phase_margin_deg,
    ftle_mean,
    lyapunov_max,
    conservation_violation_max,
    angular_velocity_max,
    effective_dim_trend

FROM read_parquet('{control_theory_path}')
ORDER BY phase_margin_deg ASC
