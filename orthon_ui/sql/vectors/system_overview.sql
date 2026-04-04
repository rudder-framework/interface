/*
QUESTION: What is the ensemble-level trajectory structure?
INPUT: system/ensemble_vector.parquet, system/trajectory_match.parquet
*/
WITH sys AS (
    SELECT * FROM read_parquet('{ensemble_dir}/ensemble_vector.parquet')
),
traj AS (
    SELECT * FROM read_parquet('{ensemble_dir}/trajectory_match.parquet')
)
SELECT
    t.cohort,
    t.trajectory_id,
    t.match_confidence,
    t.trajectory_position,
    s.mean_distance,
    s.max_distance,
    s.n_cohorts
FROM traj t
LEFT JOIN sys s ON t.cohort = s.cohort
ORDER BY t.cohort
