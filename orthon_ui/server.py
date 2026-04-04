import shutil
import tempfile
import threading
import uuid
from pathlib import Path

import polars as pl
from fastapi import FastAPI, File, UploadFile
from fastapi.responses import HTMLResponse

app = FastAPI(title="Orthon UI")

TEMPLATES = Path(__file__).parent / "templates"
JOBS_DIR = Path(tempfile.gettempdir()) / "orthon_jobs"

# In-memory job store
jobs: dict[str, dict] = {}


@app.get("/", response_class=HTMLResponse)
async def index():
    return (TEMPLATES / "upload.html").read_text()


@app.post("/upload")
async def upload(file: UploadFile = File(...)):
    job_id = uuid.uuid4().hex[:12]
    job_dir = JOBS_DIR / job_id / "data"
    job_dir.mkdir(parents=True, exist_ok=True)

    dest = job_dir / file.filename
    with open(dest, "wb") as f:
        shutil.copyfileobj(file.file, f)

    jobs[job_id] = {
        "status": "uploaded",
        "file": str(dest),
        "filename": file.filename,
        "stage_status": {},
        "log": "",
    }
    return {"job_id": job_id, "filename": file.filename}


@app.get("/results/{job_id}", response_class=HTMLResponse)
async def results(job_id: str):
    job = jobs.get(job_id)
    if not job:
        return HTMLResponse("<h1>Job not found</h1>", status_code=404)
    html = (TEMPLATES / "results.html").read_text().replace("{job_id}", job_id)
    return HTMLResponse(html)


@app.get("/status/{job_id}")
async def status(job_id: str):
    job = jobs.get(job_id)
    if not job:
        return {"error": "not found"}
    return {
        "status": job["status"],
        "filename": job["filename"],
        "stage_status": job["stage_status"],
        "log": job["log"],
    }


@app.post("/compute/{job_id}")
async def compute(job_id: str, body: dict):
    job = jobs.get(job_id)
    if not job:
        return {"error": "not found"}

    stages = body.get("stages", [])
    job["status"] = "running"
    job["log"] = f"Starting {len(stages)} stage(s)...\n"

    # Run in background thread
    threading.Thread(
        target=_run_stages, args=(job_id, stages), daemon=True
    ).start()

    return {"status": "started", "stages": stages}


@app.get("/results_data/{job_id}")
async def results_data(job_id: str):
    """Return summary stats and list of output parquet files."""
    job = jobs.get(job_id)
    if not job:
        return {"error": "not found"}

    output_dir = JOBS_DIR / job_id / "output_time"
    files = []
    if output_dir.exists():
        for pq in sorted(output_dir.rglob("*.parquet")):
            try:
                schema = pl.read_parquet_schema(pq)
                n_rows = pl.scan_parquet(pq).select(pl.len()).collect().item()
                size = pq.stat().st_size
                size_str = f"{size / 1024:.0f} KB" if size < 1_048_576 else f"{size / 1_048_576:.1f} MB"
                files.append({
                    "name": str(pq.relative_to(output_dir)),
                    "rows": n_rows,
                    "cols": len(schema),
                    "size": size_str,
                })
            except Exception:
                continue

    summary = {}
    if files:
        summary["Files"] = len(files)
        total_rows = sum(f["rows"] for f in files)
        total_cols = max((f["cols"] for f in files), default=0)
        summary["Total Rows"] = f"{total_rows:,}"
        summary["Max Columns"] = total_cols

    return {"summary": summary, "files": files}


@app.get("/preview/{job_id}/{file_path:path}")
async def preview(job_id: str, file_path: str):
    """Return first 50 rows of a parquet file as JSON."""
    job = jobs.get(job_id)
    if not job:
        return {"error": "not found"}

    pq_path = JOBS_DIR / job_id / "output_time" / file_path
    if not pq_path.exists() or not str(pq_path).endswith(".parquet"):
        return {"error": "file not found"}

    df = pl.read_parquet(pq_path).head(50)
    columns = df.columns
    rows = df.to_dicts()
    # Convert any non-JSON-serializable types
    for row in rows:
        for k, v in row.items():
            if v is not None and not isinstance(v, (int, float, str, bool)):
                row[k] = str(v)
    return {"columns": columns, "rows": rows}


@app.get("/query_all/{job_id}")
async def query_all(job_id: str):
    """Run all SQL categories against the job's output and return tables."""
    job = jobs.get(job_id)
    if not job:
        return {"error": "not found"}

    output_dir = JOBS_DIR / job_id / "output_time"
    if not output_dir.exists():
        return {"tables": []}

    from orthon_ui.sql.runner import InterfaceRunner

    runner = InterfaceRunner(str(JOBS_DIR / job_id))
    sql_dir = Path(__file__).parent / "sql"
    categories = sorted(
        d.name for d in sql_dir.iterdir()
        if d.is_dir() and not d.name.startswith(("_", "."))
    )

    tables = []
    for cat in categories:
        results = runner.run_category(cat)
        for name, df in results.items():
            if isinstance(df, str):
                # error string
                tables.append({"category": cat, "name": name, "error": df, "columns": [], "rows": []})
                continue
            columns = list(df.columns)
            rows = df.head(100).to_dict(orient="records")
            for row in rows:
                for k, v in row.items():
                    if v is not None and not isinstance(v, (int, float, str, bool)):
                        row[k] = str(v)
            tables.append({
                "category": cat,
                "name": name,
                "columns": columns,
                "rows": rows,
                "total_rows": len(df),
            })

    return {"tables": tables}


def _run_stages(job_id: str, stages: list[str]):
    """Execute requested Prime stages via Docker container."""
    from orthon_ui.prime_client import run_prime

    job = jobs[job_id]
    job_dir = JOBS_DIR / job_id
    input_path = str(job_dir / "data")
    output_path = str(job_dir / "output_time")
    Path(output_path).mkdir(parents=True, exist_ok=True)

    for stage in stages:
        job["stage_status"][stage] = "running"
        job["log"] += f"\n[{stage}] running...\n"

        try:
            run_prime(input_path=input_path, output_path=output_path)
            job["stage_status"][stage] = "done"
            job["log"] += f"[{stage}] done\n"
        except Exception as e:
            job["stage_status"][stage] = "failed"
            job["log"] += f"[{stage}] FAILED: {e}\n"
            job["status"] = "failed"
            return

    job["status"] = "done"
    job["log"] += "\nAll stages complete."


def _generate_placeholder_output(job_id: str, stage: str):
    """Write placeholder parquets so the results panel has data to show."""
    import numpy as np

    output_dir = JOBS_DIR / job_id / "output_time"
    rng = np.random.default_rng(42)

    stage_outputs = {
        "ingest": ("observations.parquet", {
            "signal_0": list(range(100)),
            "signal_id": [f"sensor_{i % 10}" for i in range(100)],
            "value": rng.normal(0, 1, 100).tolist(),
            "cohort": [f"unit_{i % 5}" for i in range(100)],
        }),
        "typology": ("typology.parquet", {
            "signal_id": [f"sensor_{i}" for i in range(10)],
            "typology_class": rng.choice(["monotonic", "oscillatory", "step", "noisy"], 10).tolist(),
            "stationarity": rng.choice(["stationary", "non-stationary"], 10).tolist(),
        }),
        "compute": ("signal/signal_vector.parquet", {
            "cohort": [f"unit_{i % 5}" for i in range(50)],
            "signal_id": [f"sensor_{i % 10}" for i in range(50)],
            "signal_0": list(range(50)),
            "mean": rng.normal(0, 1, 50).tolist(),
            "std": rng.exponential(0.5, 50).tolist(),
            "skew": rng.normal(0, 0.5, 50).tolist(),
            "kurtosis": rng.exponential(1, 50).tolist(),
            "trend": rng.normal(0, 0.1, 50).tolist(),
        }),
        "ftle": ("cohort/cohort_dynamics/ftle.parquet", {
            "cohort": [f"unit_{i}" for i in range(5)],
            "ftle": rng.normal(0.3, 0.1, 5).tolist(),
            "confidence": rng.uniform(0.8, 1.0, 5).tolist(),
        }),
        "sigma": ("layer_sigma.parquet", {
            "cohort": [f"unit_{i % 5}" for i in range(20)],
            "window_index": list(range(20)),
            "sigma_mean": rng.normal(1.5, 0.5, 20).tolist(),
            "sigma_max": rng.normal(3.0, 1.0, 20).tolist(),
            "phase": rng.choice(["nominal", "degrading", "critical"], 20).tolist(),
        }),
        "assembly": ("per_cycle.parquet", {
            "cohort": [f"unit_{i % 5}" for i in range(100)],
            "signal_0": list(range(100)),
            "mean": rng.normal(0, 1, 100).tolist(),
            "sigma": rng.exponential(1, 100).tolist(),
            "ftle": rng.normal(0.3, 0.1, 100).tolist(),
            "phase": rng.choice(["nominal", "degrading", "critical"], 100).tolist(),
        }),
    }

    if stage in stage_outputs:
        filename, data = stage_outputs[stage]
        path = output_dir / filename
        path.parent.mkdir(parents=True, exist_ok=True)
        pl.DataFrame(data).write_parquet(path)
