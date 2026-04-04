/*
QUESTION: Fleet-level health overview.
*/
WITH flags AS (
    SELECT
        cohort,
        SUM(CASE WHEN state = 'ONSET' THEN 1 ELSE 0 END) AS n_onsets,
        SUM(CASE WHEN state = 'CHANGING' THEN 1 ELSE 0 END) AS n_changing,
        MAX(severity) AS max_severity
    FROM read_parquet('{derivatives_dir}/detection_flags.parquet')
    GROUP BY cohort
)
SELECT
    COUNT(DISTINCT cohort) AS n_cohorts,
    SUM(n_onsets) AS total_onsets,
    SUM(n_changing) AS total_changing,
    AVG(max_severity) AS mean_max_severity,
    SUM(CASE WHEN max_severity >= 5 THEN 1 ELSE 0 END) AS n_high_risk_cohorts,
    SUM(CASE WHEN max_severity >= 3 AND max_severity < 5 THEN 1 ELSE 0 END) AS n_moderate_risk_cohorts,
    SUM(CASE WHEN max_severity < 3 THEN 1 ELSE 0 END) AS n_low_risk_cohorts
FROM flags
