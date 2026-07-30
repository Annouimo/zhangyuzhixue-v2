import gzip
import hashlib
import shutil
import sqlite3
import tempfile
from pathlib import Path

from django.conf import settings
from django.test.utils import override_settings

from scripts.build_schemas import ASSETS_TABLES, COURSES_TABLES
from scripts.build_utils import build_database
from system.models import DbVersion


SCHEMAS = {'qbank': ASSETS_TABLES, 'courses': COURSES_TABLES}


def _version(db_type, bump=False):
    current = DbVersion.objects.filter(db_type=db_type).first()
    data_version = current.data_version if current else 1
    return {
        'schema_version': current.schema_version if current else 1,
        'data_version': data_version + (1 if bump else 0),
    }


def _inspect(path):
    digest = hashlib.sha256(path.read_bytes()).hexdigest()
    with tempfile.TemporaryDirectory(prefix='workbench-inspect-') as directory:
        database = Path(directory) / 'candidate.db'
        with gzip.open(path, 'rb') as source, database.open('wb') as target:
            shutil.copyfileobj(source, target)
        connection = sqlite3.connect(database)
        try:
            integrity = connection.execute('PRAGMA integrity_check').fetchone()[0]
            foreign_keys = connection.execute('PRAGMA foreign_key_check').fetchall()
        finally:
            connection.close()
    if integrity != 'ok' or foreign_keys:
        raise ValueError('候选数据库完整性检查失败。')
    return {'checksum': digest, 'size_bytes': path.stat().st_size}


def build_candidate(db_type):
    if db_type not in SCHEMAS:
        raise ValueError('未知内容包类型。')
    with tempfile.TemporaryDirectory(prefix='workbench-build-') as directory:
        with override_settings(MEDIA_ROOT=directory):
            output = Path(build_database(
                schema=SCHEMAS[db_type], db_type=db_type,
                version_info=_version(db_type, bump=True), test_mode=True,
            ))
        details = _inspect(output)
        candidate_dir = Path(settings.BASE_DIR) / '.hermes' / 'content-candidates'
        candidate_dir.mkdir(parents=True, exist_ok=True)
        destination = candidate_dir / f'{db_type}_candidate.db.gz'
        shutil.copy2(output, destination)
    return {'path': destination, **details, **_version(db_type, bump=True)}


def publish(db_type):
    if db_type not in SCHEMAS:
        raise ValueError('未知内容包类型。')
    version = _version(db_type, bump=True)
    output = build_database(
        schema=SCHEMAS[db_type], db_type=db_type,
        version_info=version, test_mode=False,
    )
    published = 0
    if db_type == 'qbank':
        from .publication_services import confirm_qbank_publication
        published = confirm_qbank_publication(output, version['data_version'])
    return {'path': Path(output), 'published': published, **_inspect(Path(output)), **version}
