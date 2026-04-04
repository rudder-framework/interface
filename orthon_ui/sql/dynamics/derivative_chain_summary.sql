/*
QUESTION: Summary of the derivative chain — how many signals are changing?
*/
WITH flags AS (
    SELECT * FROM read_parquet('{derivatives_dir}/detection_flags.parquet')
)
SELECT
    level,
    state,
    COUNT(*) AS n_events,
    COUNT(DISTINCT entity) AS n_entities,
    AVG(severity) AS mean_severity,
    MAX(severity) AS max_severity
FROM flags
GROUP BY level, state
ORDER BY level, state
