/*
QUESTION: When the system changed, which entity drove the change?
The entity whose ONSET flag appears earliest IS the driver.
*/
WITH onset_events AS (
    SELECT
        cohort,
        entity,
        level,
        MIN(signal_0) AS onset_time,
        MIN(severity) AS onset_severity
    FROM read_parquet('{derivatives_dir}/detection_flags.parquet')
    WHERE state = 'ONSET'
    GROUP BY cohort, entity, level
),
ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY cohort ORDER BY onset_time) AS onset_rank
    FROM onset_events
)
SELECT
    r1.cohort,
    r1.entity AS driver_entity,
    r1.level AS driver_level,
    r1.onset_time AS driver_onset_time,
    r1.onset_severity AS driver_severity,
    r2.entity AS follower_entity,
    r2.onset_time AS follower_onset_time,
    (r2.onset_time - r1.onset_time) AS propagation_delay
FROM ranked r1
LEFT JOIN ranked r2 ON r1.cohort = r2.cohort AND r2.onset_rank = 2
WHERE r1.onset_rank = 1
ORDER BY r1.cohort
