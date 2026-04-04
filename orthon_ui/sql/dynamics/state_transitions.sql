/*
QUESTION: What state transitions have occurred and when?
*/
WITH ordered AS (
    SELECT
        cohort,
        entity,
        signal_0,
        state,
        trajectory,
        severity,
        level,
        LAG(state) OVER (PARTITION BY cohort, entity ORDER BY signal_0) AS prev_state
    FROM read_parquet('{derivatives_dir}/detection_flags.parquet')
)
SELECT
    cohort,
    entity,
    signal_0,
    prev_state,
    state AS current_state,
    trajectory,
    severity,
    level
FROM ordered
WHERE state != prev_state OR prev_state IS NULL
ORDER BY signal_0
