/*
QUESTION: Combined topological characterization per cohort.
*/
WITH topo AS (
    SELECT
        cohort,
        AVG(betti_0) AS mean_betti_0,
        AVG(betti_1) AS mean_betti_1,
        SUM(CASE WHEN betti_1 > 0 THEN 1 ELSE 0 END)::DOUBLE / COUNT(*) AS loop_fraction
    FROM read_parquet('{cohort_dir}/persistent_homology.parquet')
    GROUP BY cohort
),
ftle AS (
    SELECT
        cohort,
        AVG(ftle) AS mean_ftle,
        MAX(ftle) AS max_ftle
    FROM read_parquet('{dynamics_dir}/ftle.parquet')
    GROUP BY cohort
),
thermo AS (
    SELECT
        cohort,
        AVG(entropy) AS mean_entropy,
        AVG(temperature) AS mean_temperature,
        AVG(free_energy) AS mean_free_energy
    FROM read_parquet('{dynamics_dir}/thermodynamics.parquet')
    GROUP BY cohort
)
SELECT
    COALESCE(topo.cohort, ftle.cohort, thermo.cohort) AS cohort,
    topo.mean_betti_0,
    topo.mean_betti_1,
    topo.loop_fraction,
    ftle.mean_ftle,
    ftle.max_ftle,
    thermo.mean_entropy,
    thermo.mean_temperature,
    thermo.mean_free_energy
FROM topo
FULL OUTER JOIN ftle USING (cohort)
FULL OUTER JOIN thermo USING (cohort)
ORDER BY cohort
