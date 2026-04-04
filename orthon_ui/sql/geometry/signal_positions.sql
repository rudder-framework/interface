/*
QUESTION: Where does each signal sit relative to the eigenstructure?
*/
SELECT
    signal_id,
    cohort,
    signal_0_end,
    distance,
    coherence,
    contribution,
    residual,
    magnitude,
    CASE
        WHEN distance < 0.5 THEN 'NEAR_CENTROID'
        WHEN distance < 1.5 THEN 'MODERATE'
        ELSE 'PERIPHERAL'
    END AS position_class,
    CASE
        WHEN coherence > 0.8 THEN 'HIGHLY_COHERENT'
        WHEN coherence > 0.5 THEN 'MODERATE'
        ELSE 'INCOHERENT'
    END AS coherence_class
FROM read_parquet('{signal_dir}/signal_geometry.parquet')
ORDER BY cohort, signal_0_end, distance DESC
