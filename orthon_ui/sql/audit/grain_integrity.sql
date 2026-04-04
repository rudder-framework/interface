-- 02: Verify per-cycle vs per-window grain is clean

-- 2A: Per-cycle parquets have signal_0, not signal_0_center
SELECT
    'observations' AS parquet,
    MAX(CASE WHEN column_name = 'signal_0'
             THEN 'HAS signal_0' END) AS signal_0_present,
    MAX(CASE WHEN column_name = 'signal_0_center'
             THEN 'BUG: has signal_0_center' END) AS center_present
FROM (DESCRIBE SELECT * FROM read_parquet('{output_dir}/observations.parquet'));

-- 2B: Per-window parquets have signal_0_center
SELECT
    'signal_vector' AS parquet,
    MAX(CASE WHEN column_name = 'signal_0_center'
             THEN 'HAS signal_0_center' END) AS center_present,
    MAX(CASE WHEN column_name = 'signal_0'
             AND column_name != 'signal_0_center'
             AND column_name != 'signal_0_start'
             AND column_name != 'signal_0_end'
             THEN 'CHECK: has raw signal_0' END) AS raw_present
FROM (DESCRIBE SELECT * FROM read_parquet('{signal_dir}/signal_vector.parquet'))

UNION ALL

SELECT
    'modality_vector',
    MAX(CASE WHEN column_name = 'signal_0_center'
             THEN 'HAS signal_0_center' END),
    MAX(CASE WHEN column_name = 'signal_0'
             AND column_name != 'signal_0_center'
             AND column_name != 'signal_0_start'
             AND column_name != 'signal_0_end'
             THEN 'CHECK: has raw signal_0' END)
FROM (DESCRIBE SELECT * FROM read_parquet('{modality_dir}/modality_vector.parquet'));
