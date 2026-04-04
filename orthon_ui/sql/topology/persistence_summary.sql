/*
QUESTION: How persistent are topological features? High persistence = real structure.
*/
SELECT
    cohort,
    AVG(betti_0) AS mean_betti_0,
    AVG(betti_1) AS mean_betti_1,
    MAX(betti_1) AS max_betti_1,
    AVG(total_persistence_0) AS mean_total_pers_0,
    AVG(total_persistence_1) AS mean_total_pers_1,
    AVG(max_persistence_0) AS mean_max_pers_0,
    AVG(max_persistence_1) AS mean_max_pers_1,
    SUM(CASE WHEN betti_1 > 0 THEN 1 ELSE 0 END) AS n_windows_with_loops,
    COUNT(*) AS total_windows
FROM read_parquet('{cohort_dir}/persistent_homology.parquet')
GROUP BY cohort
ORDER BY cohort
