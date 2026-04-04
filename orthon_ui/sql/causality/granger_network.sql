/*
QUESTION: What is the Granger causality network?
*/
SELECT
    cohort,
    signal_a,
    signal_b,
    granger_f_a_to_b,
    granger_p_a_to_b,
    granger_f_b_to_a,
    granger_p_b_to_a,
    CASE WHEN granger_p_a_to_b < 0.05 THEN TRUE ELSE FALSE END AS a_granger_causes_b,
    CASE WHEN granger_p_b_to_a < 0.05 THEN TRUE ELSE FALSE END AS b_granger_causes_a
FROM read_parquet('{cohort_dir}/cohort_information_flow.parquet')
WHERE granger_p_a_to_b < 0.05 OR granger_p_b_to_a < 0.05
ORDER BY LEAST(granger_p_a_to_b, granger_p_b_to_a)
