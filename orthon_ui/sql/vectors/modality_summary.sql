/*
QUESTION: What modalities exist and how do they couple?
INPUT: analytics/modality_centroids/ (ensemble-level centroid distance per modality)
*/
SELECT *
FROM read_parquet('{analytics_dir}/modality_centroids/ensemble_*_centroid.parquet', union_by_name=true)
ORDER BY signal_0
