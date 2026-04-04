/*
QUESTION: In what order did onsets occur across entities?
*/
WITH onsets AS (
    SELECT
        cohort,
        entity,
        level,
        MIN(signal_0) AS onset_time,
        MIN(severity) AS onset_severity
    FROM read_parquet('{derivatives_dir}/detection_flags.parquet')
    WHERE state = 'ONSET'
    GROUP BY cohort, entity, level
)
SELECT
    cohort,
    entity,
    level,
    onset_time,
    onset_severity,
    ROW_NUMBER() OVER (PARTITION BY cohort ORDER BY onset_time) AS onset_rank
FROM onsets
ORDER BY cohort, onset_time
