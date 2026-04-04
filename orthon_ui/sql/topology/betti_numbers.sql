/*
QUESTION: What is the topological structure at each window?
  betti_0 = connected components (clusters)
  betti_1 = loops/cycles
*/
SELECT
    cohort,
    window_index,
    signal_0_end,
    betti_0,
    betti_1,
    total_persistence_0,
    max_persistence_0,
    total_persistence_1,
    max_persistence_1,
    CASE
        WHEN betti_1 > 0 THEN 'HAS_LOOPS'
        ELSE 'NO_LOOPS'
    END AS topology_class
FROM read_parquet('{cohort_dir}/persistent_homology.parquet')
ORDER BY cohort, window_index
