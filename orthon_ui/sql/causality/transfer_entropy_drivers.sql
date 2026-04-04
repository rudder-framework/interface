/*
QUESTION: Which signals drive which? Transfer entropy reveals directional information flow.
*/
SELECT
    cohort,
    signal_a,
    signal_b,
    transfer_entropy_a_to_b,
    transfer_entropy_b_to_a,
    (transfer_entropy_a_to_b - transfer_entropy_b_to_a) AS net_flow_a_to_b,
    granger_f_a_to_b,
    granger_p_a_to_b,
    js_divergence,
    CASE
        WHEN transfer_entropy_a_to_b > transfer_entropy_b_to_a * 1.5 THEN signal_a || ' drives ' || signal_b
        WHEN transfer_entropy_b_to_a > transfer_entropy_a_to_b * 1.5 THEN signal_b || ' drives ' || signal_a
        ELSE 'BIDIRECTIONAL'
    END AS flow_direction
FROM read_parquet('{cohort_dir}/cohort_information_flow.parquet')
ORDER BY ABS(transfer_entropy_a_to_b - transfer_entropy_b_to_a) DESC
