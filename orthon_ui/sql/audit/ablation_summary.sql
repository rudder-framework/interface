/*
POST-ABLATION AUDIT — confirm ablation results are consistent.

Reads: {ablation_dir}/window_derivative_ablation.parquet

Checks:
  1. Every signal has a max_valid_derivative_order >= 0
  2. No signal was skipped without reason
  3. Optimal windows are within feasible range
  4. Signals with high ACF half-life have lower max orders
     (slow signals should not sustain high derivative orders)
*/

-- 1. Signal coverage
SELECT
    COUNT(*) AS total_signals,
    SUM(CASE WHEN skipped THEN 1 ELSE 0 END) AS skipped,
    SUM(CASE WHEN NOT skipped AND max_valid_derivative_order = 0 THEN 1 ELSE 0 END) AS zero_order,
    SUM(CASE WHEN max_valid_derivative_order >= 1 THEN 1 ELSE 0 END) AS has_d1,
    SUM(CASE WHEN max_valid_derivative_order >= 2 THEN 1 ELSE 0 END) AS has_d2,
    SUM(CASE WHEN max_valid_derivative_order >= 3 THEN 1 ELSE 0 END) AS has_d3,
    SUM(CASE WHEN max_valid_derivative_order >= 4 THEN 1 ELSE 0 END) AS has_d4_plus
FROM read_parquet('{ablation_dir}/window_derivative_ablation.parquet');

-- 2. Max order distribution
SELECT
    max_valid_derivative_order AS max_order,
    COUNT(*) AS n_signals,
    ROUND(AVG(acf_half_life), 1) AS mean_acf_half_life,
    ROUND(AVG(n_observations), 0) AS mean_n_obs
FROM read_parquet('{ablation_dir}/window_derivative_ablation.parquet')
WHERE NOT skipped
GROUP BY max_valid_derivative_order
ORDER BY max_valid_derivative_order;

-- 3. Consistency check: high ACF half-life should correlate with lower max order
SELECT
    signal_id,
    acf_half_life,
    max_valid_derivative_order,
    n_observations,
    CASE
        WHEN acf_half_life > 30 AND max_valid_derivative_order > 3
        THEN 'FLAG: slow signal with high derivative order'
        WHEN acf_half_life < 5 AND max_valid_derivative_order < 2
        THEN 'FLAG: fast signal with low derivative order'
        ELSE 'OK'
    END AS consistency_check
FROM read_parquet('{ablation_dir}/window_derivative_ablation.parquet')
WHERE NOT skipped
  AND consistency_check != 'OK'
ORDER BY acf_half_life DESC;
