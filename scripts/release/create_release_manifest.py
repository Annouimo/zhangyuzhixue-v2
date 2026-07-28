#!/usr/bin/env python3
"""Create a machine-readable manifest for already-built Windows installers."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import sqlite3
import subprocess
from datetime import datetime, timezone
from pathlib import Path


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def release_info(pubspec: Path) -> dict[str, object]:
    text = pubspec.read_text(encoding="utf-8")
    values: dict[str, str] = {}
    for name in ("version", "release_channel", "release_iteration"):
        match = re.search(rf"^{name}:\s*(\S+)", text, re.MULTILINE)
        if not match:
            raise ValueError(f"missing {name} in {pubspec}")
        values[name] = match.group(1)
    return values


def database_info(path: Path) -> dict[str, object]:
    connection = sqlite3.connect(f"file:{path.resolve().as_posix()}?mode=ro", uri=True)
    try:
        row = connection.execute("SELECT schema_version, data_version FROM meta").fetchone()
        integrity = connection.execute("PRAGMA integrity_check").fetchone()[0]
        foreign_keys = len(connection.execute("PRAGMA foreign_key_check").fetchall())
    finally:
        connection.close()
    if not row or integrity != "ok" or foreign_keys:
        raise ValueError(f"database validation failed: {path}")
    return {
        "path": path.as_posix(),
        "schema_version": row[0],
        "data_version": row[1],
        "size_bytes": path.stat().st_size,
        "sha256": sha256(path),
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[2])
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    root = args.root.resolve()
    commit = subprocess.check_output(
        ["git", "-c", "safe.directory=D:/Hermes/zhangyuzhixue_app_v2", "rev-parse", "HEAD"],
        cwd=root,
        text=True,
    ).strip()
    artifacts = []
    for path in sorted((root / "dist/windows").glob("**/*.exe")):
        artifacts.append({
            "path": path.relative_to(root).as_posix(),
            "size_bytes": path.stat().st_size,
            "sha256": sha256(path),
        })
    if not artifacts:
        raise SystemExit("No Windows installer artifacts found under dist/windows")
    payload = {
        "format_version": 1,
        "created_at": datetime.now(timezone.utc).isoformat(),
        "git_commit": commit,
        "student_release": release_info(root / "flutter_app/pubspec.yaml"),
        "bundled_databases": {
            "qbank": database_info(root / "flutter_app/assets/db/assets.db"),
            "courses": database_info(root / "flutter_app/assets/db/courses.db"),
        },
        "artifacts": artifacts,
    }
    output = args.output.resolve()
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Manifest: {output}")
    print(f"Artifacts: {len(artifacts)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
