/*
QUESTION: What is the overall stability state of each cohort?
Per cohort: stability class, phase margin, stability margin, control margin.
Source: control_theory.parquet (one row per cohort).
*/
SELECT
    cohort,
    phase_margin_deg,
    stability_index,
    health_index AS stability_margin,
    control_margin,

    -- FTLE fundamentals
    ftle_mean,
    ftle_min,
    ftle_stability_score,

    -- Dynamics
    lyapunov_mean,
    effective_dim_mean,
    effective_dim_trend,

    -- Rotation
    angular_velocity_mean,
    cumulative_rotation_total,

    -- Thermodynamics
    entropy_production_mean,
    conservation_violation_max,

    -- Causality
    te_asymmetry_mean

FROM read_parquet('{control_theory_path}')
ORDER BY phase_margin_deg ASC
