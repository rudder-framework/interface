/*
QUESTION: Which features are most important?
*/
SELECT
    feature,
    variance_ratio,
    unsupervised_score,
    composite_score,
    is_near_constant,
    CASE
        WHEN composite_score > 0.8 THEN 'CRITICAL'
        WHEN composite_score > 0.5 THEN 'IMPORTANT'
        WHEN composite_score > 0.2 THEN 'MODERATE'
        ELSE 'LOW'
    END AS importance_class
FROM read_parquet('{relevance_dir}/feature_scores.parquet')
ORDER BY composite_score DESC
