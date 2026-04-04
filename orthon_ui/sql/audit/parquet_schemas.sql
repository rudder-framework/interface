-- 01: Verify every canonical parquet has expected schema
-- Run via DuckDB against output_time/

-- Signal vector
SELECT
    'signal_vector' AS parquet,
    COUNT(*) AS rows,
    COUNT(DISTINCT signal_id) AS n_signals,
    COUNT(DISTINCT cohort) AS n_cohorts,
    COUNT(DISTINCT window_index) AS n_windows
FROM read_parquet('{signal_dir}/signal_vector.parquet')

UNION ALL

-- Modality vector (replaces cohort_vector)
SELECT
    'modality_vector',
    COUNT(*),
    COUNT(DISTINCT modality),
    COUNT(DISTINCT cohort),
    COUNT(DISTINCT window_index)
FROM read_parquet('{modality_dir}/modality_vector.parquet')

UNION ALL

-- Geodesic departure
SELECT
    'geodesic_departure',
    COUNT(*),
    COUNT(DISTINCT modality),
    COUNT(DISTINCT cohort),
    COUNT(DISTINCT window_index)
FROM read_parquet('{output_dir}/geodesic_departure.parquet')

UNION ALL

-- Cohort geometry
SELECT
    'cohort_geometry',
    COUNT(*),
    0,
    COUNT(DISTINCT cohort),
    COUNT(DISTINCT window_index)
FROM read_parquet('{cohort_dir}/cohort_geometry.parquet')

UNION ALL

-- Domain geodesic
SELECT
    'domain_geodesic',
    COUNT(*),
    0,
    0,
    COUNT(DISTINCT window_index)
FROM read_parquet('{domain_dir}/domain_geodesic.parquet');
