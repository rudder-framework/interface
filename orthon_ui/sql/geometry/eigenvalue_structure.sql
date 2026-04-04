/*
QUESTION: What is the eigenvalue structure at each window?
INTERPRETATION:
  eff_dim near 1    → one dominant mode (all signals co-moving)
  eff_dim near n    → independent signals (no coupling)
  eff_dim DROPPING  → losing degrees of freedom (concerning)
  cond_num HIGH     → anisotropic coupling
  eigenvalue_entropy LOW → concentrated variance
*/
SELECT
    cohort,
    window_index,
    signal_0_start,
    signal_0_end,
    effective_dim,
    eigenvalue_entropy,
    eigenvalue_entropy_normalized,
    condition_number,
    total_variance,
    ratio_2_1,
    energy_concentration,
    n_signals,
    CASE
        WHEN effective_dim < 1.5 THEN 'COLLAPSED'
        WHEN effective_dim < n_signals * 0.3 THEN 'LOW'
        WHEN effective_dim < n_signals * 0.7 THEN 'MODERATE'
        ELSE 'HIGH'
    END AS dim_class,
    (effective_dim - LAG(effective_dim, 1) OVER (PARTITION BY cohort ORDER BY window_index)) AS eff_dim_delta
FROM read_parquet('{cohort_dir}/cohort_geometry.parquet')
ORDER BY cohort, window_index
