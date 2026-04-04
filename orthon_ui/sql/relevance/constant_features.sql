/*
QUESTION: Which features are near-constant and should be excluded?
*/
SELECT
    feature,
    variance_ratio,
    composite_score
FROM read_parquet('{relevance_dir}/feature_scores.parquet')
WHERE is_near_constant = true
ORDER BY feature
