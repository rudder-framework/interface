/*
QUESTION: How does geometry differ between two time periods?
PARAMS: early_start, early_end, late_start, late_end
*/
WITH early AS (
    SELECT
        cohort,
        AVG(effective_dim) AS eff_dim,
        STDDEV(effective_dim) AS eff_dim_std,
        AVG(condition_number) AS cond_num,
        AVG(eigenvalue_entropy) AS entropy,
        AVG(total_variance) AS total_var,
        COUNT(*) AS n_windows
    FROM read_parquet('{cohort_dir}/cohort_geometry.parquet')
    WHERE signal_0_start >= {early_start} AND signal_0_end <= {early_end}
    GROUP BY cohort
),
late AS (
    SELECT
        cohort,
        AVG(effective_dim) AS eff_dim,
        STDDEV(effective_dim) AS eff_dim_std,
        AVG(condition_number) AS cond_num,
        AVG(eigenvalue_entropy) AS entropy,
        AVG(total_variance) AS total_var,
        COUNT(*) AS n_windows
    FROM read_parquet('{cohort_dir}/cohort_geometry.parquet')
    WHERE signal_0_start >= {late_start} AND signal_0_end <= {late_end}
    GROUP BY cohort
)
SELECT
    e.cohort,
    e.eff_dim AS early_eff_dim,
    l.eff_dim AS late_eff_dim,
    (l.eff_dim - e.eff_dim) AS eff_dim_change,
    e.cond_num AS early_cond_num,
    l.cond_num AS late_cond_num,
    e.entropy AS early_entropy,
    l.entropy AS late_entropy
FROM early e
JOIN late l ON e.cohort = l.cohort
ORDER BY ABS(l.eff_dim - e.eff_dim) DESC
