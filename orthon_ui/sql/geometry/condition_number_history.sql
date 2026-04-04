/*
QUESTION: How has the condition number evolved? High = anisotropic coupling.
*/
SELECT
    cohort,
    window_index,
    signal_0_center,
    condition_number,
    LOG10(condition_number) AS log_cond_num,
    CASE
        WHEN condition_number < 10 THEN 'WELL_CONDITIONED'
        WHEN condition_number < 100 THEN 'MODERATE'
        WHEN condition_number < 1000 THEN 'ILL_CONDITIONED'
        ELSE 'SEVERELY_ILL_CONDITIONED'
    END AS conditioning_class,
    condition_number - LAG(condition_number, 1) OVER (PARTITION BY cohort ORDER BY window_index) AS cond_delta
FROM read_parquet('{cohort_dir}/cohort_geometry.parquet')
ORDER BY cohort, window_index
