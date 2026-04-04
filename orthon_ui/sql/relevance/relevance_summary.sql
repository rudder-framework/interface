/*
QUESTION: Feature relevance overview.
*/
SELECT
    COUNT(*) AS total_features,
    SUM(CASE WHEN is_near_constant THEN 1 ELSE 0 END) AS n_constant,
    SUM(CASE WHEN composite_score > 0.8 THEN 1 ELSE 0 END) AS n_critical,
    SUM(CASE WHEN composite_score > 0.5 THEN 1 ELSE 0 END) AS n_important,
    AVG(composite_score) AS mean_score,
    MEDIAN(composite_score) AS median_score,
    MAX(composite_score) AS max_score
FROM read_parquet('{relevance_dir}/feature_scores.parquet')
