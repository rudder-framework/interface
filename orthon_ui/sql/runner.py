"""
SQL execution engine for interface.
Reads prime's parquet output via DuckDB. Read-only.
"""
import re
import sys
import duckdb
from pathlib import Path


class InterfaceRunner:
    def __init__(self, domain_dir: str):
        self.domain_dir = Path(domain_dir)
        self.output_dir = self.domain_dir / "output_time"
        self.con = duckdb.connect()

    def _build_params(self, extra: dict | None = None) -> dict:
        """Build template parameters from output directory structure."""
        params = {
            "output_dir": str(self.output_dir),
            "signal_dir": str(self.output_dir / "signal"),
            "cohort_dir": str(self.output_dir / "cohort"),
            "ensemble_dir": str(self.output_dir / "system"),
            "domain_dir": str(self.output_dir / "domain"),
            "dynamics_dir": str(self.output_dir / "cohort" / "cohort_dynamics"),
            "derivatives_dir": str(self.output_dir / "derivatives"),
            "relevance_dir": str(self.output_dir / "relevance"),
            "modality_dir": str(self.output_dir / "modality"),
            "analytics_dir": str(self.output_dir / "analytics"),
            "ml_dir": str(self.output_dir / "ml"),
            "ablation_dir": str(self.output_dir / "ablation"),
            "control_theory_path": str(self.output_dir / "control_theory.parquet"),
        }
        if extra:
            params.update(extra)
        return params

    @staticmethod
    def _extract_parquet_paths(sql_text: str) -> list[str]:
        """Extract parquet file paths from read_parquet() calls in SQL."""
        return re.findall(r"read_parquet\('([^']+)'\)", sql_text)

    def run_script(self, script_path: str, params: dict | None = None):
        """Execute a SQL script. script_path is relative to sql/ or absolute."""
        sql_dir = Path(__file__).parent
        path = Path(script_path)
        if not path.is_absolute():
            path = sql_dir / path
        sql_text = path.read_text()
        merged = self._build_params(params)
        for key, value in merged.items():
            sql_text = sql_text.replace(f"{{{key}}}", str(value))

        # Guard: check that all referenced parquets exist before executing
        missing = []
        for pq_path in self._extract_parquet_paths(sql_text):
            if not Path(pq_path).exists():
                missing.append(pq_path)
        if missing:
            names = ", ".join(Path(p).name for p in missing)
            msg = f"Skipping {path.name} — parquet not yet produced by Prime: {names}"
            print(f"WARNING: {msg}", file=sys.stderr)
            raise FileNotFoundError(msg)

        return self.con.execute(sql_text)

    def run_category(self, category: str, params: dict | None = None) -> dict:
        """Run all SQL scripts in a category. Returns {name: DataFrame}."""
        sql_dir = Path(__file__).parent / category
        results = {}
        if not sql_dir.exists():
            return results
        for sql_file in sorted(sql_dir.glob("*.sql")):
            try:
                result = self.run_script(str(sql_file), params)
                results[sql_file.stem] = result.fetchdf()
            except FileNotFoundError:
                pass  # warning already printed by run_script
            except Exception as e:
                results[sql_file.stem] = f"ERROR: {e}"
        return results
