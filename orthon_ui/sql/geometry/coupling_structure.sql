/*
QUESTION: What is the pairwise coupling structure between signals?

TODO: window_id is not in the canonical schema. When Prime produces
pairwise_windowed.parquet, verify the column name is window_id and
not window_index. Update or remove this filter accordingly.
*/
SELECT
    cohort,
    signal_a,
    signal_b,
    correlation AS full_correlation,
    abs_correlation,
    CASE
        WHEN abs_correlation > 0.8 THEN 'STRONG'
        WHEN abs_correlation > 0.5 THEN 'MODERATE'
        WHEN abs_correlation > 0.3 THEN 'WEAK'
        ELSE 'NEGLIGIBLE'
    END AS coupling_class
FROM read_parquet('{output_dir}/pairwise_windowed.parquet')
WHERE window_id = (SELECT MAX(window_id) FROM read_parquet('{output_dir}/pairwise_windowed.parquet'))
ORDER BY abs_correlation DESC
