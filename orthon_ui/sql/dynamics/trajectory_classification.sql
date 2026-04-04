/*
QUESTION: What trajectory patterns exist in the detection flags?
*/
SELECT
    cohort,
    entity,
    level,
    trajectory,
    COUNT(*) AS n_windows,
    MIN(signal_0) AS first_signal_0,
    MAX(signal_0) AS last_signal_0,
    AVG(severity) AS mean_severity,
    MAX(severity) AS max_severity
FROM read_parquet('{derivatives_dir}/detection_flags.parquet')
WHERE state != 'STABLE'
GROUP BY cohort, entity, level, trajectory
ORDER BY max_severity DESC
