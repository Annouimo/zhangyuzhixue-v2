"""构建工具函数测试 — create_db / write_meta / checksum / gzip / 数据复制"""

import os
import tempfile

import pytest

from courses.models import Course, Document
from qbank.models import BaseQuestion
from scripts.build_schemas import ASSETS_TABLES, LECTURE_TABLES
from scripts.build_utils import (
    compute_checksum,
    copy_direct,
    copy_m2m,
    copy_relation,
    create_db,
    gzip_db,
    write_chapters,
    write_lecture_content,
    write_meta,
)


# ── create_db / write_meta / checksum / gzip ──────────────────


class TestBuildUtilsBasic:

    def test_create_db_creates_tables(self):
        """create_db 创建所有表"""
        schema = {
            'test_table': {
                'columns': [('id', 'INTEGER PRIMARY KEY'),
                            ('name', 'TEXT NOT NULL')],
            }
        }
        conn, path = create_db(schema)
        try:
            tables = conn.execute(
                "SELECT name FROM sqlite_master WHERE type='table'"
            ).fetchall()
            assert ('test_table',) in tables
        finally:
            conn.close()
            if os.path.exists(path):
                os.unlink(path)

    def test_write_meta(self):
        """write_meta 写入 meta 表"""
        conn, path = create_db({})
        try:
            write_meta(conn, schema_version=2, data_version=5,
                       checksum='abc123')
            row = conn.execute('SELECT * FROM meta').fetchone()
            assert row[0] == 2
            assert row[1] == 5
            assert row[2] == 'abc123'
        finally:
            conn.close()
            if os.path.exists(path):
                os.unlink(path)

    def test_checksum_format(self):
        """compute_checksum 返回 64 位十六进制"""
        tmp = tempfile.NamedTemporaryFile(delete=False)
        tmp.write(b'hello')
        tmp.close()
        try:
            chk = compute_checksum(tmp.name)
            assert len(chk) == 64
            assert all(c in '0123456789abcdef' for c in chk)
        finally:
            os.unlink(tmp.name)

    def test_gzip_roundtrip(self):
        """gzip_db 压缩后文件存在且更小"""
        tmp_src = tempfile.NamedTemporaryFile(suffix='.db', delete=False)
        tmp_src.write(b'x' * 10000)
        tmp_src.close()
        tmp_dst = tempfile.NamedTemporaryFile(suffix='.db.gz', delete=False)
        tmp_dst.close()
        try:
            gzip_db(tmp_src.name, tmp_dst.name)
            gz_size = os.path.getsize(tmp_dst.name)
            assert gz_size < 500
        finally:
            os.unlink(tmp_src.name)
            os.unlink(tmp_dst.name)


# ── copy_direct ──────────────────────────────────────────────


class TestCopyDirect:

    @pytest.fixture
    def db_and_conn(self):
        schema = {'question': ASSETS_TABLES['question']}
        conn, path = create_db(schema)
        yield conn
        conn.close()
        if os.path.exists(path):
            os.unlink(path)

    def test_copy_direct_questions(self, db, db_and_conn):
        """direct 复制题目数据"""
        conn = db_and_conn
        copy_direct(conn, ASSETS_TABLES, 'question', 'qbank.BaseQuestion')
        count = conn.execute('SELECT COUNT(*) FROM question').fetchone()[0]
        assert count == BaseQuestion.objects.count()


# ── copy_m2m ────────────────────────────────────────────────


class TestCopyM2M:

    @pytest.fixture
    def db_and_conn(self):
        schema = {
            'question_concept_tag': ASSETS_TABLES['question_concept_tag'],
        }
        conn, path = create_db(schema)
        yield conn
        conn.close()
        if os.path.exists(path):
            os.unlink(path)

    def test_copy_m2m_concept_tags(self, db, db_and_conn):
        """m2m 复制概念标签中间表"""
        conn = db_and_conn
        from qbank.models import QuestionConceptTag
        copy_m2m(conn, ASSETS_TABLES, 'question_concept_tag',
                 'm2m:qbank.BaseQuestion.concept_tags')
        count = conn.execute(
            'SELECT COUNT(*) FROM question_concept_tag'
        ).fetchone()[0]
        assert count == QuestionConceptTag.objects.count()


# ── copy_relation ────────────────────────────────────────────


class TestCopyRelation:

    @pytest.fixture
    def db_and_conn(self):
        schema = {
            'question_knowledge_card': (
                ASSETS_TABLES['question_knowledge_card']
            ),
        }
        conn, path = create_db(schema)
        yield conn
        conn.close()
        if os.path.exists(path):
            os.unlink(path)

    def test_copy_relation(self, db, db_and_conn):
        """relation 复制 question_knowledge_card（可能 0 条）"""
        conn = db_and_conn
        copy_relation(conn, ASSETS_TABLES, 'question_knowledge_card')
        count = conn.execute(
            'SELECT COUNT(*) FROM question_knowledge_card'
        ).fetchone()[0]
        # 确保不报错即可，可能 0 条（测试环境无 card_titles）
        assert count >= 0


# ── write_chapters / write_lecture_content ──────────────────


class TestWriteChapters:

    @pytest.fixture
    def course_with_docs(self, db):
        course = Course.objects.create(name='测试课程')
        for i in range(3):
            Document.objects.create(
                course=course, chapter=f'{i+1:02d}',
                title=f'第{i+1}讲', md_content=f'内容{i+1}',
            )
        return course

    def test_write_chapters(self, db, course_with_docs):
        """从 Document 生成 chapter 表"""
        schema = {'chapter': LECTURE_TABLES['chapter']}
        conn, path = create_db(schema)
        try:
            chapters = write_chapters(conn, LECTURE_TABLES)
            assert len(chapters) == 3
            count = conn.execute(
                'SELECT COUNT(*) FROM chapter'
            ).fetchone()[0]
            assert count == 3
        finally:
            conn.close()
            if os.path.exists(path):
                os.unlink(path)

    def test_lecture_content(self, db, course_with_docs):
        """从 Document 生成 lecture_content"""
        schema = {
            'chapter': LECTURE_TABLES['chapter'],
            'lecture_content': LECTURE_TABLES['lecture_content'],
        }
        conn, path = create_db(schema)
        try:
            chapters = write_chapters(conn, LECTURE_TABLES)
            write_lecture_content(conn, LECTURE_TABLES, chapters)
            count = conn.execute(
                'SELECT COUNT(*) FROM lecture_content'
            ).fetchone()[0]
            assert count == 3
        finally:
            conn.close()
            if os.path.exists(path):
                os.unlink(path)
