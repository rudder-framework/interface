/*
QUESTION: How do phase margins compare across cohorts?
Ranked view with stability classification and margin breakdown.
Source: control_theory.parquet (one row per cohort).
*/
SELECT
    cohort,
    phase_margin_deg,
    stability_index,
    health_index AS stability_margin,
    control_margin,

    -- Decompose stability contributors
    ftle_mean AS ftle_contribution,
    lyapunov_mean AS lyapunov_contribution,
    entropy_production_mean AS entropy_contribution,
    conservation_violation_max AS violation_contribution,

    -- Rank within dataset
    RANK() OVER (ORDER BY phase_margin_deg ASC) AS instability_rank,
    RANK() OVER (ORDER BY health_index ASC) AS stability_rank

FROM read_parquet('{control_theory_path}')
ORDER BY phase_margin_deg ASC
