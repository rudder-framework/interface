"""
Docker-based Prime client.
Runs orthonui/orthonui:latest container with input/output volume mounts.
"""

import docker
from pathlib import Path


IMAGE = "orthonui/orthonui:latest"


def run_prime(input_path: str, output_path: str) -> bool:
    """Run Prime via Docker container.

    Args:
        input_path: Absolute path to directory containing input data.
        output_path: Absolute path to directory where Prime writes output.

    Returns:
        True if container completed successfully.
    """
    client = docker.from_env()

    # Check image exists locally, pull if not present
    try:
        client.images.get(IMAGE)
    except docker.errors.ImageNotFound:
        client.images.pull(IMAGE)

    # Prime CLI: orthon <domain_path> --output-dir <output_dir> --baseline-auto
    # Mount input as /domain (rw for Prime to write observations.parquet back),
    # output as /output
    client.containers.run(
        IMAGE,
        command="/domain --output-dir /output --baseline-auto",
        volumes={
            input_path: {"bind": "/domain", "mode": "rw"},
            output_path: {"bind": "/output", "mode": "rw"},
        },
        remove=True,
        detach=False,
    )

    return True
