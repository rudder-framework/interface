/*
QUESTION: What are the active risks per cohort?
*/
WITH active_flags AS (
    SELECT
        cohort,
        entity,
        level,
        state,
        trajectory,
        severity,
        signal_0
    FROM read_parquet('{derivatives_dir}/detection_flags.parquet')
    WHERE state IN ('ONSET', 'CHANGING')
),
risk_items AS (
    SELECT
        cohort,
        entity,
        level,
        MAX(severity) AS max_severity,
        COUNT(*) AS n_windows_active,
        MAX(signal_0) AS last_active_signal_0,
        MAX(trajectory) AS trajectory
    FROM active_flags
    GROUP BY cohort, entity, level
)
SELECT
    cohort,
    entity,
    level,
    max_severity,
    n_windows_active,
    trajectory,
    CASE
        WHEN max_severity >= 5.0 THEN 'HIGH'
        WHEN max_severity >= 3.0 THEN 'MODERATE'
        WHEN max_severity >= 1.0 THEN 'LOW'
        ELSE 'MINIMAL'
    END AS risk_level
FROM risk_items
ORDER BY max_severity DESC
