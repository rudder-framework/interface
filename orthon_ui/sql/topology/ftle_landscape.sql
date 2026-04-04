/*
QUESTION: What does the FTLE landscape look like? High FTLE = trajectory divergence.
*/
SELECT
    signal_id,
    cohort,
    ftle,
    confidence,
    embedding_dim,
    direction,
    CASE
        WHEN ftle > 0.5 THEN 'STRONGLY_CHAOTIC'
        WHEN ftle > 0.1 THEN 'MILDLY_CHAOTIC'
        WHEN ftle > 0 THEN 'NEAR_BOUNDARY'
        ELSE 'STABLE'
    END AS ftle_class
FROM read_parquet('{dynamics_dir}/ftle.parquet')
ORDER BY ftle DESC
