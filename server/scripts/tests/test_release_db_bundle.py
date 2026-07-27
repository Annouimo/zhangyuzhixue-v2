import gzip
import json
import sqlite3

import pytest

from scripts.release_db_bundle import inspect_bundle, load_manifest, validate_against_manifest


def make_bundle(path, schema=1, data=8):
    database = path.with_suffix("")
    connection = sqlite3.connect(database)
    connection.execute("CREATE TABLE meta (schema_version INTEGER, data_version INTEGER)")
    connection.execute("INSERT INTO meta VALUES (?, ?)", (schema, data))
    connection.commit()
    connection.close()
    with database.open("rb") as source, gzip.open(path, "wb") as output:
        output.write(source.read())


def test_inspect_bundle_validates_sqlite_metadata(tmp_path):
    bundle = tmp_path / "qbank_v8.db.gz"
    make_bundle(bundle)
    details = inspect_bundle(bundle)
    assert details["schema_version"] == 1
    assert details["data_version"] == 8
    assert len(details["sha256"]) == 64


def test_manifest_rejects_unexpected_fields(tmp_path):
    manifest = tmp_path / "manifest.json"
    manifest.write_text(json.dumps({"format_version": 1, "extra": True}))
    with pytest.raises(ValueError, match="manifest fields differ"):
        load_manifest(manifest)


def test_validation_rejects_tampered_bundle(tmp_path):
    bundle = tmp_path / "courses_v8.db.gz"
    make_bundle(bundle)
    details = inspect_bundle(bundle)
    manifest = {
        "format_version": 1, "db_type": "courses", "filename": bundle.name,
        **details, "git_commit": "a" * 40, "created_at": "2026-07-27T00:00:00Z",
    }
    bundle.write_bytes(bundle.read_bytes() + b"tampered")
    with pytest.raises(ValueError, match="invalid gzip|size_bytes|sha256"):
        validate_against_manifest(bundle, manifest)
