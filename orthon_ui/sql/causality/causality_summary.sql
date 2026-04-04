/*
QUESTION: Overall causal structure per cohort.
*/
SELECT
    cohort,
    COUNT(*) AS n_pairs,
    SUM(CASE WHEN granger_p_a_to_b < 0.05 OR granger_p_b_to_a < 0.05 THEN 1 ELSE 0 END) AS n_granger_significant,
    AVG(transfer_entropy_a_to_b + transfer_entropy_b_to_a) AS mean_total_te,
    MAX(ABS(transfer_entropy_a_to_b - transfer_entropy_b_to_a)) AS max_asymmetry,
    AVG(js_divergence) AS mean_js_divergence
FROM read_parquet('{cohort_dir}/cohort_information_flow.parquet')
GROUP BY cohort
ORDER BY cohort
