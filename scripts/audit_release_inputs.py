#!/usr/bin/env python3
"""Audit bundled databases, client versions, and Windows installer isolation."""

from __future__ import annotations

import argparse
import gzip
import hashlib
import json
import re
import sqlite3
import sys
import tempfile
import urllib.request
from dataclasses import dataclass
from pathlib import Path


PRODUCTION_API = "https://zhangyuzhixue.zhtec123.com/api/v1/sync"


@dataclass(frozen=True)
class DatabaseInfo:
    path: Path
    schema_version: int
    data_version: int
    checksum: str
    sha256: str
    size: int


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def inspect_database(path: Path) -> DatabaseInfo:
    if not path.is_file() or path.stat().st_size == 0:
        raise ValueError(f"missing or empty database: {path}")
    connection = sqlite3.connect(f"file:{path.resolve().as_posix()}?mode=ro", uri=True)
    try:
        integrity = connection.execute("PRAGMA integrity_check").fetchone()[0]
        if integrity != "ok":
            raise ValueError(f"integrity_check failed for {path}: {integrity}")
        foreign_keys = connection.execute("PRAGMA foreign_key_check").fetchall()
        if foreign_keys:
            raise ValueError(f"foreign_key_check failed for {path}: {len(foreign_keys)} rows")
        row = connection.execute(
            "SELECT schema_version, data_version, checksum FROM meta"
        ).fetchone()
        if row is None:
            raise ValueError(f"missing meta row: {path}")
    finally:
        connection.close()
    return DatabaseInfo(path, int(row[0]), int(row[1]), str(row[2]), sha256(path), path.stat().st_size)


def field(text: str, pattern: str, label: str) -> str:
    match = re.search(pattern, text, re.MULTILINE)
    if not match:
        raise ValueError(f"missing {label}")
    return match.group(1)


def production_info(db_type: str) -> dict[str, object]:
    url = f"{PRODUCTION_API}/{db_type}/version/"
    request = urllib.request.Request(url, headers={"User-Agent": "zhangyuzhixue-release-audit/1.0"})
    with urllib.request.urlopen(request, timeout=20) as response:
        payload = json.load(response)
    return payload["data"]


def verify_production_bundle(db_type: str, info: dict[str, object]) -> None:
    url = str(info["download_url"])
    with tempfile.TemporaryDirectory(prefix="zhangyuzhixue-release-audit-") as temp:
        gz_path = Path(temp) / f"{db_type}.db.gz"
        db_path = Path(temp) / f"{db_type}.db"
        request = urllib.request.Request(url, headers={"User-Agent": "zhangyuzhixue-release-audit/1.0"})
        with urllib.request.urlopen(request, timeout=30) as response, gz_path.open("wb") as output:
            output.write(response.read())
        if gz_path.stat().st_size != int(info["size_bytes"]):
            raise ValueError(f"{db_type}: production size does not match API metadata")
        if sha256(gz_path) != info["checksum"]:
            raise ValueError(f"{db_type}: production SHA-256 does not match API metadata")
        with gzip.open(gz_path, "rb") as source, db_path.open("wb") as output:
            for chunk in iter(lambda: source.read(1024 * 1024), b""):
                output.write(chunk)
        database = inspect_database(db_path)
        if database.schema_version != int(info["schema_version"]):
            raise ValueError(f"{db_type}: production schema version mismatch")
        if database.data_version != int(info["data_version"]):
            raise ValueError(f"{db_type}: production data version mismatch")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--production", action="store_true", help="download and validate current public bundles")
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parent.parent)
    args = parser.parse_args()
    root = args.root.resolve()
    errors: list[str] = []
    warnings: list[str] = []

    databases = {
        "qbank": root / "flutter_app/assets/db/assets.db",
        "courses": root / "flutter_app/assets/db/courses.db",
    }
    local: dict[str, DatabaseInfo] = {}
    for db_type, path in databases.items():
        try:
            database = inspect_database(path)
            local[db_type] = database
            print(f"LOCAL {db_type} schema={database.schema_version} data={database.data_version} sha256={database.sha256}")
        except (OSError, sqlite3.Error, ValueError) as error:
            errors.append(str(error))

    try:
        student_pubspec = (root / "flutter_app/pubspec.yaml").read_text(encoding="utf-8")
        student_version = field(student_pubspec, r"^version:\s*(\S+)", "student version")

        version_name, build_number = student_version.split("+", 1)
        major, minor, _patch = version_name.split(".")
        expected_msix_version = f"{major}.{minor}.{build_number}.0"
        msix_version = field(
            student_pubspec,
            r"^\s*msix_version:\s*(\S+)",
            "student MSIX version",
        )
        if msix_version != expected_msix_version:
            errors.append(
                f"student MSIX version mismatch: expected={expected_msix_version}, actual={msix_version}"
            )

        installer = (root / "docs/07-工作流/build_script_student.iss").read_text(encoding="utf-8")
        output_directory = field(
            installer, r"^OutputDir=(.+)$", "student output directory",
        )
        if "\\build\\windows\\" in output_directory.casefold():
            errors.append("student: installer output is mixed into the Flutter build tree")
    except (OSError, ValueError) as error:
        errors.append(str(error))

    if args.production:
        for db_type in ("qbank", "courses"):
            try:
                info = production_info(db_type)
                verify_production_bundle(db_type, info)
                print(f"PROD  {db_type} schema={info['schema_version']} data={info['data_version']} sha256={info['checksum']}")
                bundled = local.get(db_type)
                if bundled and int(info["data_version"]) < bundled.data_version:
                    warnings.append(
                        f"{db_type}: production data v{info['data_version']} is older than bundled v{bundled.data_version}"
                    )
            except (OSError, ValueError, KeyError, json.JSONDecodeError) as error:
                errors.append(f"{db_type}: production validation failed: {error}")

    print(f"Warnings: {len(warnings)}")
    for warning in warnings:
        print(f"- WARN: {warning}")
    print(f"Errors: {len(errors)}")
    for error in errors:
        print(f"- ERROR: {error}")
    return 1 if errors else 0


if __name__ == "__main__":
    raise SystemExit(main())
