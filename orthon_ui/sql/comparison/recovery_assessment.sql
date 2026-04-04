/*
QUESTION: Has the coupling structure recovered to its baseline state?
PARAMS: early_start, early_end, late_start, late_end

INTERPRETATION:
  RECOVERED:  Late period eigenvalue structure statistically indistinguishable from early
  DEGRADED:   Late period has lower eff_dim or higher JS divergence than early
  SHIFTED:    Late period is different but not clearly worse (novel regime)
  UNCHANGED:  Both periods are similar (metric was stable throughout)
*/
WITH early_period AS (
    SELECT
        cohort,
        AVG(effective_dim) AS early_eff_dim,
        STDDEV(effective_dim) AS early_eff_dim_std,
        AVG(eigenvalue_entropy) AS early_entropy,
        AVG(condition_number) AS early_cond_num,
        COUNT(*) AS early_n_windows
    FROM read_parquet('{cohort_dir}/cohort_geometry.parquet')
    WHERE signal_0_start >= {early_start} AND signal_0_end <= {early_end}
    GROUP BY cohort
),
late_period AS (
    SELECT
        cohort,
        AVG(effective_dim) AS late_eff_dim,
        STDDEV(effective_dim) AS late_eff_dim_std,
        AVG(eigenvalue_entropy) AS late_entropy,
        AVG(condition_number) AS late_cond_num,
        COUNT(*) AS late_n_windows
    FROM read_parquet('{cohort_dir}/cohort_geometry.parquet')
    WHERE signal_0_start >= {late_start} AND signal_0_end <= {late_end}
    GROUP BY cohort
)
SELECT
    e.cohort,
    e.early_eff_dim,
    l.late_eff_dim,
    (l.late_eff_dim - e.early_eff_dim) AS eff_dim_change,
    e.early_cond_num,
    l.late_cond_num,
    e.early_entropy,
    l.late_entropy,
    CASE
        WHEN ABS(l.late_eff_dim - e.early_eff_dim) < 0.5
             AND ABS(l.late_entropy - e.early_entropy) < 0.1
        THEN 'RECOVERED'
        WHEN l.late_eff_dim < e.early_eff_dim - 0.5
        THEN 'DEGRADED'
        WHEN ABS(l.late_eff_dim - e.early_eff_dim) > 0.5
        THEN 'SHIFTED'
        ELSE 'UNCHANGED'
    END AS recovery_status
FROM early_period e
JOIN late_period l ON e.cohort = l.cohort
ORDER BY ABS(l.late_eff_dim - e.early_eff_dim) DESC
