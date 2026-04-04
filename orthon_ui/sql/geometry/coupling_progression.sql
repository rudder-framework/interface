/*
QUESTION: How has the overall coupling strength evolved over time?

TODO: window_id is not in the canonical schema. When Prime produces
coupling_progression.parquet, verify the column name is window_id and
not window_index. Update or remove accordingly.
*/
SELECT
    cohort,
    window_id,
    n_pairs,
    n_strong,
    n_very_strong,
    avg_abs_correlation,
    median_abs_correlation,
    CAST(n_strong AS DOUBLE) / NULLIF(n_pairs, 0) AS strong_fraction,
    CAST(n_very_strong AS DOUBLE) / NULLIF(n_pairs, 0) AS very_strong_fraction
FROM read_parquet('{output_dir}/coupling_progression.parquet')
ORDER BY cohort, window_id
