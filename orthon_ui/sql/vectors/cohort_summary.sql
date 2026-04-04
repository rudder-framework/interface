/*
QUESTION: What is the centroid profile of each cohort?
INPUT: modality_vector.parquet
*/
SELECT
    cohort,
    signal_0_start,
    signal_0_end,
    signal_0_center
FROM read_parquet('{modality_dir}/modality_vector.parquet')
ORDER BY cohort, signal_0_center
