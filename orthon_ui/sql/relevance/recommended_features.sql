/*
QUESTION: What is the recommended feature set?
*/
SELECT
    r.feature,
    f.composite_score,
    f.variance_ratio,
    f.unsupervised_score
FROM read_parquet('{relevance_dir}/recommended_features.parquet') r
LEFT JOIN read_parquet('{relevance_dir}/feature_scores.parquet') f
    ON r.feature = f.feature
ORDER BY f.composite_score DESC
