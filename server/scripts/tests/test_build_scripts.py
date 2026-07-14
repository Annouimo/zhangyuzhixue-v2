"""构建脚本集成测试 — --test 模式冒烟测试"""

import os


from scripts.build_schemas import ASSETS_TABLES, COURSES_TABLES
from scripts.build_utils import build_database


class TestBuildAssets:
    """assets.db 构建冒烟测试"""

    def test_build_assets_test_mode(self, db):
        """--test 模式运行 assets 构建：不更新 DbVersion"""
        from system.models import DbVersion
        before_count = DbVersion.objects.filter(db_type='qbank').count()

        output = build_database(
            schema=ASSETS_TABLES,
            db_type='qbank',
            version_info={'schema_version': 1, 'data_version': 99},
            test_mode=True,
        )

        assert output is not None
        assert os.path.exists(output)

        after_count = DbVersion.objects.filter(db_type='qbank').count()
        assert after_count == before_count

        if os.path.exists(output):
            os.unlink(output)

    def test_build_assets_output_is_gzipped(self, db):
        """构建产物是有效的 .db.gz 文件"""
        output = build_database(
            schema=ASSETS_TABLES,
            db_type='qbank',
            version_info={'schema_version': 1, 'data_version': 98},
            test_mode=True,
        )
        try:
            import gzip
            import tempfile
            with gzip.open(output, 'rb') as f:
                data = f.read()
            assert len(data) > 0
            tmp = tempfile.NamedTemporaryFile(suffix='.db', delete=False)
            tmp.write(data)
            tmp.close()
            import sqlite3
            conn = sqlite3.connect(tmp.name)
            tables = conn.execute(
                "SELECT name FROM sqlite_master WHERE type='table'"
            ).fetchall()
            table_names = {t[0] for t in tables}
            assert 'question' in table_names
            assert 'meta' in table_names
            conn.close()
            os.unlink(tmp.name)
        finally:
            if os.path.exists(output):
                try:
                    os.unlink(output)
                except PermissionError:
                    pass


class TestBuildIdempotent:
    """构建幂等性测试"""

    def test_build_assets_idempotent(self, db):
        """两次连续构建 assets.db，产物 checksum 一致"""
        import hashlib

        output1 = build_database(
            schema=ASSETS_TABLES,
            db_type='qbank',
            version_info={'schema_version': 1, 'data_version': 99},
            test_mode=True,
        )
        hash1 = hashlib.sha256()
        with open(output1, 'rb') as f:
            hash1.update(f.read())

        output2 = build_database(
            schema=ASSETS_TABLES,
            db_type='qbank',
            version_info={'schema_version': 1, 'data_version': 99},
            test_mode=True,
        )
        hash2 = hashlib.sha256()
        with open(output2, 'rb') as f:
            hash2.update(f.read())

        assert hash1.hexdigest() == hash2.hexdigest()

        for path in [output1, output2]:
            if os.path.exists(path):
                try:
                    os.unlink(path)
                except PermissionError:
                    pass


class TestBuildLectures:
    """lectures.db 构建冒烟测试"""

    def test_build_courses_test_mode(self, db):
        """--test 模式运行 courses 构建"""
        from system.models import DbVersion
        before_count = DbVersion.objects.filter(db_type='courses').count()

        output = build_database(
            schema=COURSES_TABLES,
            db_type='courses',
            version_info={'schema_version': 1, 'data_version': 1},
            test_mode=True,
        )

        assert output is not None
        after_count = DbVersion.objects.filter(db_type='courses').count()
        assert after_count == before_count
        if os.path.exists(output):
            try:
                os.unlink(output)
            except PermissionError:
                pass

    def test_lectures_has_chapter_table(self, db):
        """lectures.db 包含 chapter 表"""
        output = build_database(
            schema=COURSES_TABLES,
            db_type='courses',
            version_info={'schema_version': 1, 'data_version': 1},
            test_mode=True,
        )
        try:
            import gzip
            import tempfile
            import sqlite3
            with gzip.open(output, 'rb') as f:
                data = f.read()
            tmp = tempfile.NamedTemporaryFile(suffix='.db', delete=False)
            tmp.write(data)
            tmp.close()
            conn = sqlite3.connect(tmp.name)
            tables = {t[0] for t in conn.execute(
                "SELECT name FROM sqlite_master WHERE type='table'"
            )}
            assert 'chapter' in tables
            assert 'course' in tables
            assert 'lecture_content' in tables
            conn.close()
            os.unlink(tmp.name)
        finally:
            if os.path.exists(output):
                try:
                    os.unlink(output)
                except PermissionError:
                    pass
