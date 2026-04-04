/*
QUESTION: How close are signals to the FTLE ridge (regime boundary)?
*/
SELECT
    cohort,
    signal_id,
    signal_0_center,
    ftle_current,
    ftle_gradient,
    urgency,
    time_to_ridge,
    speed,
    CASE
        WHEN urgency > 0.8 THEN 'IMMINENT'
        WHEN urgency > 0.5 THEN 'APPROACHING'
        WHEN urgency > 0.2 THEN 'DISTANT'
        ELSE 'FAR'
    END AS ridge_proximity_class
FROM read_parquet('{dynamics_dir}/ridge_proximity.parquet')
ORDER BY urgency DESC
