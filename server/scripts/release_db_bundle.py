#!/usr/bin/env python3
"""Validate, publish, and roll back versioned client database bundles."""

from __future__ import annotations

import argparse
import gzip
import hashlib
import json
import os
import shutil
import sqlite3
import sys
import tempfile
import urllib.request
from contextlib import contextmanager
from datetime import datetime, timezone
from pathlib import Path


ALLOWED_TYPES = ("qbank", "courses")
MANIFEST_FORMAT = 1


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def inspect_bundle(path: Path) -> dict[str, object]:
    if not path.is_file() or path.stat().st_size == 0:
        raise ValueError(f"missing or empty bundle: {path}")
    with tempfile.TemporaryDirectory(prefix="db-bundle-") as temp_dir:
        unpacked = Path(temp_dir) / "bundle.db"
        try:
            with gzip.open(path, "rb") as source, unpacked.open("wb") as output:
                shutil.copyfileobj(source, output)
        except (gzip.BadGzipFile, EOFError) as error:
            raise ValueError(f"invalid gzip bundle: {path}") from error
        connection = sqlite3.connect(f"file:{unpacked.as_posix()}?mode=ro", uri=True)
        try:
            integrity = connection.execute("PRAGMA integrity_check").fetchone()[0]
            foreign_keys = connection.execute("PRAGMA foreign_key_check").fetchall()
            row = connection.execute(
                "SELECT schema_version, data_version FROM meta"
            ).fetchone()
        finally:
            connection.close()
    if integrity != "ok":
        raise ValueError(f"SQLite integrity_check failed: {integrity}")
    if foreign_keys:
        raise ValueError(f"SQLite foreign_key_check failed: {len(foreign_keys)} rows")
    if not row:
        raise ValueError("bundle does not contain a meta version row")
    return {
        "schema_version": int(row[0]),
        "data_version": int(row[1]),
        "size_bytes": path.stat().st_size,
        "sha256": sha256(path),
    }


def load_manifest(path: Path) -> dict[str, object]:
    payload = json.loads(path.read_text(encoding="utf-8"))
    required = {
        "format_version", "db_type", "filename", "schema_version",
        "data_version", "size_bytes", "sha256", "git_commit", "created_at",
    }
    if set(payload) != required:
        raise ValueError(f"manifest fields differ: {sorted(set(payload) ^ required)}")
    if payload["format_version"] != MANIFEST_FORMAT:
        raise ValueError("unsupported manifest format")
    if payload["db_type"] not in ALLOWED_TYPES:
        raise ValueError("unsupported database type")
    expected = f'{payload["db_type"]}_v{int(payload["data_version"])}.db.gz'
    if payload["filename"] != expected:
        raise ValueError(f"bundle filename must be {expected}")
    return payload


def validate_against_manifest(bundle: Path, manifest: dict[str, object]) -> None:
    actual = inspect_bundle(bundle)
    for key in ("schema_version", "data_version", "size_bytes", "sha256"):
        if actual[key] != manifest[key]:
            raise ValueError(f"bundle {key} does not match manifest")


def prepare(args: argparse.Namespace) -> int:
    bundle = args.bundle.resolve()
    details = inspect_bundle(bundle)
    expected = f'{args.db_type}_v{details["data_version"]}.db.gz'
    if bundle.name != expected:
        raise ValueError(f"bundle filename must be {expected}")
    payload = {
        "format_version": MANIFEST_FORMAT,
        "db_type": args.db_type,
        "filename": bundle.name,
        **details,
        "git_commit": args.git_commit,
        "created_at": datetime.now(timezone.utc).isoformat(),
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(payload, indent=2))
    return 0


def verify(args: argparse.Namespace) -> int:
    manifest = load_manifest(args.manifest.resolve())
    endpoint = f'{args.base_url.rstrip("/")}/api/v1/sync/{manifest["db_type"]}/version/'
    request = urllib.request.Request(
        endpoint, headers={"User-Agent": "zhangyuzhixue-data-release/1.0"}
    )
    with urllib.request.urlopen(request, timeout=args.timeout) as response:
        payload = json.load(response)
    data = payload.get("data", {})
    expected_url = f'/media/db/{manifest["filename"]}'
    for key in ("schema_version", "data_version", "size_bytes", "checksum"):
        manifest_key = "sha256" if key == "checksum" else key
        if data.get(key) != manifest[manifest_key]:
            raise ValueError(f"public API {key} does not match manifest")
    if not str(data.get("download_url", "")).endswith(expected_url):
        raise ValueError("public API download URL does not match manifest")
    with tempfile.TemporaryDirectory(prefix="db-release-verify-") as temp_dir:
        downloaded = Path(temp_dir) / str(manifest["filename"])
        bundle_request = urllib.request.Request(
            str(data["download_url"]),
            headers={"User-Agent": "zhangyuzhixue-data-release/1.0"},
        )
        with urllib.request.urlopen(bundle_request, timeout=args.timeout) as response:
            downloaded.write_bytes(response.read())
        validate_against_manifest(downloaded, manifest)
    print(f'VERIFIED={manifest["db_type"]}:v{manifest["data_version"]}')
    return 0


def setup_django(project_root: Path) -> None:
    sys.path.insert(0, str(project_root))
    os.environ.setdefault("DJANGO_SETTINGS_MODULE", "math_platform.settings")
    import django
    django.setup()


@contextmanager
def release_lock(path: Path):
    import fcntl

    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w") as stream:
        try:
            fcntl.flock(stream, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError as error:
            raise RuntimeError("another database bundle release is running") from error
        yield


def version_snapshot(version) -> dict[str, object]:
    return {
        field: getattr(version, field)
        for field in (
            "schema_version", "data_version", "checksum", "size_bytes",
            "download_url", "force_update", "message", "built_at",
        )
    }


def install(args: argparse.Namespace) -> int:
    project_root = args.project_root.resolve()
    media_dir = project_root / "media" / "db"
    backup_root = args.backup_root.resolve()
    manifest = load_manifest(args.manifest.resolve())
    bundle = args.bundle.resolve()
    validate_against_manifest(bundle, manifest)
    setup_django(project_root)
    from django.db import transaction
    from django.utils import timezone as django_timezone
    from interactions.publication_services import confirm_qbank_publication
    from system.models import DbVersion

    release_id = args.release_id
    backup_dir = backup_root / release_id
    if backup_dir.exists():
        raise ValueError(f"release ID already exists: {release_id}")
    destination = media_dir / str(manifest["filename"])
    stage = media_dir / f'.{manifest["filename"]}.{release_id}.tmp'

    with release_lock(args.lock_file):
        current = DbVersion.objects.get(db_type=manifest["db_type"])
        if int(manifest["data_version"]) <= current.data_version and not args.allow_same_version:
            raise ValueError(
                f'new data version {manifest["data_version"]} must exceed current {current.data_version}'
            )
        if int(manifest["data_version"]) < current.data_version:
            raise ValueError("same-version override cannot be used for a downgrade")

        backup_dir.mkdir(parents=True)
        metadata = {
            "release_id": release_id,
            "db_type": manifest["db_type"],
            "destination": str(destination),
            "destination_existed": destination.exists(),
            "previous": version_snapshot(current),
            "manifest": manifest,
        }
        (backup_dir / "rollback.json").write_text(
            json.dumps(metadata, default=str, indent=2) + "\n", encoding="utf-8"
        )
        shutil.copy2(args.manifest, backup_dir / "manifest.json")
        if destination.exists():
            shutil.copy2(destination, backup_dir / destination.name)

        try:
            shutil.copy2(bundle, stage)
            with stage.open("rb") as stream:
                os.fsync(stream.fileno())
            os.replace(stage, destination)
            destination.chmod(0o644)
            with transaction.atomic():
                current = DbVersion.objects.select_for_update().get(
                    db_type=manifest["db_type"]
                )
                current.schema_version = manifest["schema_version"]
                current.data_version = manifest["data_version"]
                current.checksum = manifest["sha256"]
                current.size_bytes = manifest["size_bytes"]
                current.download_url = f'/media/db/{manifest["filename"]}'
                current.force_update = args.force_update
                current.message = args.message
                current.built_at = django_timezone.now()
                current.save()
                if manifest["db_type"] == "qbank":
                    confirm_qbank_publication(bundle, manifest["data_version"])
            with (backup_root / "releases.log").open("a", encoding="utf-8") as log:
                log.write(
                    f'{datetime.now(timezone.utc).isoformat()} release={release_id} '
                    f'type={manifest["db_type"]} data={manifest["data_version"]} '
                    f'sha256={manifest["sha256"]} commit={manifest["git_commit"]}\n'
                )
        except Exception:
            stage.unlink(missing_ok=True)
            backup = backup_dir / destination.name
            if backup.exists():
                shutil.copy2(backup, destination)
            elif destination.exists():
                destination.unlink()
            with transaction.atomic():
                current = DbVersion.objects.select_for_update().get(
                    db_type=manifest["db_type"]
                )
                for field, value in metadata["previous"].items():
                    setattr(current, field, value)
                current.save()
            raise
    print(f"RELEASE_ID={release_id}")
    print(f"BACKUP={backup_dir}")
    return 0


def rollback(args: argparse.Namespace) -> int:
    project_root = args.project_root.resolve()
    backup_dir = args.backup_root.resolve() / args.release_id
    metadata = json.loads((backup_dir / "rollback.json").read_text(encoding="utf-8"))
    destination = Path(metadata["destination"])
    expected_parent = (project_root / "media" / "db").resolve()
    if destination.resolve().parent != expected_parent:
        raise ValueError("rollback destination is outside the media database directory")
    setup_django(project_root)
    from django.db import transaction
    from django.utils.dateparse import parse_datetime
    from interactions.publication_services import rollback_qbank_publication
    from system.models import DbVersion

    with release_lock(args.lock_file):
        with transaction.atomic():
            version = DbVersion.objects.select_for_update().get(
                db_type=metadata["db_type"]
            )
            previous = metadata["previous"]
            for field, value in previous.items():
                if field == "built_at" and value:
                    value = parse_datetime(value)
                setattr(version, field, value)
            version.save()
            if metadata["db_type"] == "qbank":
                rollback_qbank_publication(metadata["manifest"]["data_version"])
            saved_bundle = backup_dir / destination.name
            if metadata["destination_existed"]:
                if not saved_bundle.is_file():
                    raise ValueError("rollback bundle is missing")
                stage = destination.parent / f".{destination.name}.{args.release_id}.rollback"
                shutil.copy2(saved_bundle, stage)
                os.replace(stage, destination)
            else:
                destination.unlink(missing_ok=True)
        with (args.backup_root.resolve() / "releases.log").open(
            "a", encoding="utf-8"
        ) as log:
            log.write(
                f'{datetime.now(timezone.utc).isoformat()} rollback={args.release_id} '
                f'type={metadata["db_type"]} data={previous["data_version"]}\n'
            )
    print(f"ROLLED_BACK={args.release_id}")
    return 0


def parser() -> argparse.ArgumentParser:
    result = argparse.ArgumentParser()
    commands = result.add_subparsers(dest="command", required=True)
    prepare_cmd = commands.add_parser("prepare")
    prepare_cmd.add_argument("--db-type", choices=ALLOWED_TYPES, required=True)
    prepare_cmd.add_argument("--bundle", type=Path, required=True)
    prepare_cmd.add_argument("--output", type=Path, required=True)
    prepare_cmd.add_argument("--git-commit", required=True)
    prepare_cmd.set_defaults(handler=prepare)
    verify_cmd = commands.add_parser("verify")
    verify_cmd.add_argument("--manifest", type=Path, required=True)
    verify_cmd.add_argument("--base-url", default="https://zhangyuzhixue.zhtec123.com")
    verify_cmd.add_argument("--timeout", type=float, default=30.0)
    verify_cmd.set_defaults(handler=verify)
    for name, handler in (("install", install), ("rollback", rollback)):
        command = commands.add_parser(name)
        command.add_argument("--project-root", type=Path, required=True)
        command.add_argument("--backup-root", type=Path, required=True)
        command.add_argument("--lock-file", type=Path, required=True)
        command.add_argument("--release-id", required=True)
        command.set_defaults(handler=handler)
    install_cmd = commands.choices["install"]
    install_cmd.add_argument("--bundle", type=Path, required=True)
    install_cmd.add_argument("--manifest", type=Path, required=True)
    install_cmd.add_argument("--allow-same-version", action="store_true")
    install_cmd.add_argument("--force-update", action="store_true")
    install_cmd.add_argument("--message", default="")
    return result


def main() -> int:
    args = parser().parse_args()
    try:
        return args.handler(args)
    except (
        OSError, ValueError, RuntimeError, sqlite3.Error, json.JSONDecodeError,
    ) as error:
        print(f"ERROR: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
