"""
构建脚本共享工具

- create_db / write_meta / compute_checksum / gzip_db
- copy_direct / copy_m2m / copy_relation
- write_chapters / write_lecture_content: 讲义专用
- build_database: 完整构建流程
"""

import json
import os
import sqlite3
import tempfile
import time
import re
from hashlib import sha256


# ── SQL 模板辅助 ────────────────────────────────────────────


def _sql_insert(table_name, cols, or_ignore=False):
    ignore = ' OR IGNORE' if or_ignore else ''
    return (f'INSERT{ignore} INTO {table_name} '
            f'({chr(34)}' + ', '.join(cols) + '' + chr(34) + '}) '
            f'VALUES ({chr(34)}' + ', '.join('?' * len(cols)) + '' + chr(34) + '})')


def _sql_insert_id(table_name, cols, or_ignore=False):
    ignore = ' OR IGNORE' if or_ignore else ''
    c = ', '.join(cols)
    p = ', '.join('?' * len(cols))
    return f'INSERT{ignore} INTO {table_name} (id, {c}) VALUES (?, {p})'


def create_db(schema):
    """创建临时 SQLite 数据库并建表，返回 (conn, db_path)"""
    tmp = tempfile.NamedTemporaryFile(suffix='.db', delete=False)
    tmp.close()
    conn = sqlite3.connect(tmp.name)
    conn.execute('PRAGMA journal_mode=OFF;')
    conn.execute('PRAGMA synchronous=OFF;')

    for table_name, table_def in schema.items():
        cols = ', '.join(f'"{cname}" {ctype}' for cname, ctype in table_def['columns'])
        conn.execute(f'CREATE TABLE {table_name} ({cols});')
    conn.commit()
    return conn, tmp.name


def write_meta(conn, schema_version, data_version, checksum=''):
    """写入 _meta 表"""
    conn.execute(
        'CREATE TABLE meta ('
        'schema_version INTEGER NOT NULL,'
        'data_version INTEGER NOT NULL,'
        'checksum TEXT NOT NULL,'
        'built_at TEXT NOT NULL'
        ');'
    )
    now = time.strftime('%Y-%m-%dT%H:%M:%S', time.gmtime())
    conn.execute(
        'INSERT INTO meta (schema_version, data_version, checksum, built_at) '
        'VALUES (?, ?, ?, ?)',
        (schema_version, data_version, checksum, now),
    )
    conn.commit()


def compute_checksum(file_path):
    h = sha256()
    with open(file_path, 'rb') as f:
        while True:
            chunk = f.read(65536)
            if not chunk:
                break
            h.update(chunk)
    return h.hexdigest()


def gzip_db(src_path, dst_path):
    import gzip
    os.makedirs(os.path.dirname(dst_path), exist_ok=True)
    with open(src_path, 'rb') as f_in, gzip.open(dst_path, 'wb') as f_out:
        while True:
            chunk = f_in.read(65536)
            if not chunk:
                break
            f_out.write(chunk)


def _target_cols(schema, table_name):
    return {col[0] for col in schema[table_name]['columns']}


def _serialize(v):
    if isinstance(v, (dict, list)):
        return json.dumps(v, ensure_ascii=False)
    return v


_LEGACY_ANSWER_BLANK = re.compile(
    r'\$?(?:\\{1,2}_){3,}|\$?(?<!\\)_{3,}|'
    r'(?<!\$)\\underline\{\\hspace\{[0-9.]+(?:cm|em|pt)\}\}(?!\$)'
)


def _validate_question_stem(question):
    if getattr(question, 'question_type', None) != 'fill':
        return
    stem = getattr(question, 'stem', '')
    if _LEGACY_ANSWER_BLANK.search(stem):
        raise ValueError(
            f'fill question {question.pk} contains a legacy answer blank; '
            'use $\\underline{\\hspace{2cm}}$'
        )


def copy_direct(conn, schema, table_name, source_model, filter_kwargs=None):
    """direct 转换：字段名一致的直接复制"""
    from django.apps import apps
    model_cls = apps.get_model(source_model)
    cols = sorted(_target_cols(schema, table_name))

    qs = model_cls.objects.all()
    if filter_kwargs:
        qs = qs.filter(**filter_kwargs)

    rows = []
    for obj in qs.iterator():
        if source_model == 'qbank.BaseQuestion':
            _validate_question_stem(obj)
        row = {}
        for c in cols:
            if c == 'id':
                row[c] = obj.pk
            elif hasattr(obj, c):
                row[c] = _serialize(getattr(obj, c))
        rows.append(row)

    if not rows:
        return

    sql = f'INSERT OR IGNORE INTO {table_name} ({", ".join(cols)}) VALUES ({", ".join("?" * len(cols))})'  # noqa: E501
    conn.executemany(sql, [[r.get(c) for c in cols] for r in rows])
    conn.commit()


def copy_m2m(conn, schema, table_name, source_spec):
    """m2m 转换：通过 Django through 模型直接复制中间表"""
    from django.apps import apps
    # source_spec: 'm2m:ModelName.field_name'
    model_path = source_spec.split(':', 1)[1]
    model_name, field_name = model_path.rsplit('.', 1)
    model_cls = apps.get_model(model_name)
    through = getattr(model_cls, field_name).through

    cols = sorted(_target_cols(schema, table_name) - {'id'})
    fk_fields = [f.name for f in through._meta.fields if f.name != 'id']

    rows = []
    for obj in through.objects.all().iterator():
        row = {}
        for c in cols:
            # 尝试匹配字段名
            for fk in fk_fields:
                if c.endswith(fk) or fk.endswith(c):
                    row[c] = getattr(obj, fk + '_id', None)
                    break
            # 如果没匹配到，看下值
            if c not in row:
                if hasattr(obj, c):
                    row[c] = getattr(obj, c)
        rows.append(row)

    if not rows:
        return

    sql = f'INSERT INTO {table_name} ({", ".join(cols)}) VALUES ({", ".join("?" * len(cols))})'
    for i, row in enumerate(rows):
        vals = [row.get(c) for c in cols]
        conn.execute(sql, vals)
    conn.commit()


def copy_relation(conn, schema, table_name):
    """relation 转换：从 SolutionStep.card_titles → question_knowledge_card"""
    from qbank.models import KnowledgeCard, SolutionStep
    cols = sorted(_target_cols(schema, table_name) - {'id'})

    seen, rows = set(), []
    for step in SolutionStep.objects.filter(card_titles__isnull=False) \
                                    .exclude(card_titles='').iterator():
        titles = step.card_titles
        if isinstance(titles, str):
            try:
                titles = json.loads(titles)
            except (json.JSONDecodeError, TypeError):
                continue
        if not isinstance(titles, (list, tuple)):
            continue

        for title in titles:
            for card in KnowledgeCard.objects.filter(title=title).iterator():
                key = (step.method.sub_question.question_id, card.pk)
                if key not in seen:
                    seen.add(key)
                    rows.append({'question_id': key[0], 'knowledge_card_id': key[1]})

    if not rows:
        return

    quoted_cols = [f'"{c}"' for c in cols]
    sql = f'INSERT INTO {table_name} (id, {", ".join(quoted_cols)}) VALUES (?, {", ".join("?" * len(cols))})'  # noqa: E501
    for i, row in enumerate(rows):
        conn.execute(sql, [i + 1] + [row[c] for c in cols])
    conn.commit()


def write_chapters(conn, schema):
    """从 Document 生成 chapter 表"""
    from courses.models import Document
    table_name = 'chapter'
    cols = sorted(_target_cols(schema, table_name) - {'id'})

    seen = set()
    rows = []
    for doc in Document.objects.values('course_id', 'chapter', 'title') \
                               .distinct().order_by('course_id', 'chapter'):
        key = (doc['course_id'], doc['chapter'])
        if key in seen:
            continue
        seen.add(key)
        try:
            idx = int(doc['chapter'])
        except (ValueError, TypeError):
            idx = len(seen)
        rows.append({'course_id': doc['course_id'], 'index': idx, 'title': doc['title']})

    if not rows:
        return

    quoted_cols = [f'"{c}"' for c in cols]
    sql = f'INSERT INTO {table_name} (id, {", ".join(quoted_cols)}) VALUES (?, {", ".join("?" * len(cols))})'  # noqa: E501
    for i, row in enumerate(rows):
        conn.execute(sql, [i + 1] + [row[c] for c in cols])
    conn.commit()
    return rows  # 供 lecture_content 使用


def _validate_lecture_markdown(title, content):
    """Reject lecture content that cannot render as intended in the app."""
    import re

    if not content.strip():
        raise ValueError(f'Lecture "{title}" has empty markdown content')

    inline_code_math = re.search(
        r'`[^`\n]*(?:\\[A-Za-z{]|[_^])[^`\n]*`',
        content,
    )
    if inline_code_math:
        raise ValueError(
            f'Lecture "{title}" contains math wrapped as inline code: '
            f'{inline_code_math.group(0)}'
        )


def write_lecture_content(conn, schema, chapters):
    """lecture_transform: Document → lecture_content"""
    from courses.models import Document
    table_name = 'lecture_content'
    cols = sorted(_target_cols(schema, table_name) - {'id'})

    # 构建 chapter_id 查找表: (course_id, chapter) → pk
    ch_map = {}
    for i, ch in enumerate(chapters):
        ch_map[(ch['course_id'], ch['index'])] = i + 1

    rows = []
    for doc in Document.objects.all().order_by('course_id', 'chapter').iterator():
        try:
            ch_idx = int(doc.chapter)
        except (ValueError, TypeError):
            ch_idx = 0
        ch_id = ch_map.get((doc.course_id, ch_idx))
        if ch_id is None:
            continue
        _validate_lecture_markdown(doc.title, doc.md_content)
        rows.append({
            'chapter_id': ch_id,
            'title': doc.title,
            'md_content': doc.md_content,
            'updated_at': doc.updated_at.isoformat() if doc.updated_at else '',
        })

    if not rows:
        return

    quoted_cols = [f'"{c}"' for c in cols]
    sql = f'INSERT INTO {table_name} (id, {", ".join(quoted_cols)}) VALUES (?, {", ".join("?" * len(cols))})'  # noqa: E501

    sql = f'INSERT OR IGNORE INTO {table_name} ({", ".join(cols)}) VALUES ({", ".join("?" * len(cols))})'  # noqa: E501
    for row in rows:
        conn.execute(sql, [row[c] for c in cols])
    conn.commit()


def write_video_document_links(conn, schema, chapters):
    """把服务端 Document 外键映射为数据包内重新编号的 chapter_id。"""
    from courses.models import VideoDocumentLink

    chapter_map = {
        (chapter['course_id'], chapter['index']): index + 1
        for index, chapter in enumerate(chapters)
    }
    rows = []
    links = VideoDocumentLink.objects.filter(
        video__is_published=True,
    ).select_related('document').order_by('video_id', 'sort_order', 'id')
    for link in links.iterator():
        try:
            chapter_index = int(link.document.chapter)
        except (TypeError, ValueError):
            continue
        chapter_id = chapter_map.get((link.document.course_id, chapter_index))
        if chapter_id is None:
            continue
        rows.append((
            link.video_id,
            chapter_id,
            link.relation_label,
            link.sort_order,
        ))

    conn.executemany(
        'INSERT INTO video_document_link '
        '(video_id, chapter_id, relation_label, sort_order) '
        'VALUES (?, ?, ?, ?)',
        rows,
    )
    conn.commit()


def _write_static(conn, table_name, table_def):
    """static 转换：插入预定义的行数据"""
    defaults = table_def.get('defaults', [])
    if not defaults:
        return
    cols = [col[0] for col in table_def['columns']]
    sql = f'INSERT INTO {table_name} ({", ".join(cols)}) VALUES ({", ".join("?" * len(cols))})'
    for row in defaults:
        conn.execute(sql, row)
    conn.commit()


def build_database(schema, db_type, version_info, test_mode=False):
    """
    完整构建流程
    version_info: {'schema_version': int, 'data_version': int}
    """
    import os
    from django.conf import settings

    conn, db_path = create_db(schema)
    table_count = len(schema)

    try:
        chapters = None

        for table_name, table_def in schema.items():
            tf = table_def.get('transform')
            source = table_def.get('source')

            if tf == 'direct':
                copy_direct(
                    conn, schema, table_name, table_def['source_model'],
                    table_def.get('filter'),
                )
            elif source and source.startswith('m2m:'):
                copy_m2m(conn, schema, table_name, source)
            elif source == 'relation':
                copy_relation(conn, schema, table_name)
            elif source == 'generate:from_document_chapter':
                chapters = write_chapters(conn, schema)
            elif source == 'static':
                _write_static(conn, table_name, table_def)
            elif tf == 'lecture_transform':
                write_lecture_content(conn, schema, chapters or [])
            elif source == 'video_document_relation':
                write_video_document_links(conn, schema, chapters or [])

        # 计算 checksum + 写入 _meta
        conn.commit()
        conn.close()

        checksum = compute_checksum(db_path)
        conn2 = sqlite3.connect(db_path)
        write_meta(conn2, version_info['schema_version'],
                   version_info['data_version'], checksum)
        conn2.close()

        # gzip
        output_dir = os.path.join(settings.MEDIA_ROOT, 'db')
        output_name = f'{db_type}_v{version_info["data_version"]}.db.gz'
        output_path = os.path.join(output_dir, output_name)
        gzip_db(db_path, output_path)
        gz_size = os.path.getsize(output_path)

        # 对 .gz 计算 checksum（客户端下载后 hash 的是 gz bytes）
        final_checksum = compute_checksum(output_path)

        print(f'  ✅ {table_count} 表处理完成')
        print(f'  🔑 SHA-256: {final_checksum}')
        print(f'  📦 gz: {gz_size:,} bytes')

        if not test_mode:
            from system.models import DbVersion
            ver, _ = DbVersion.objects.get_or_create(db_type=db_type)
            ver.schema_version = version_info['schema_version']
            ver.data_version = version_info['data_version']
            ver.checksum = final_checksum
            ver.size_bytes = gz_size
            ver.download_url = f'/media/db/{output_name}'
            ver.built_at = time.strftime('%Y-%m-%dT%H:%M:%S', time.gmtime())
            ver.save()
            print(f'  💾 DbVersion 已更新 (v{version_info["data_version"]})')

        print(f'  📄 输出: {output_path}')

        # 清理旧版产物：保留当前版 + 上一版
        if not test_mode:
            import glob
            pattern = os.path.join(output_dir, f'{db_type}_v*.db.gz')
            files = []
            for f in glob.glob(pattern):
                try:
                    v = int(f.split('_v')[1].split('.db')[0])
                    files.append((v, f))
                except (IndexError, ValueError):
                    continue
            files.sort(key=lambda x: x[0])
            keep_versions = {version_info['data_version']}
            if len(files) >= 2:
                prev_v = files[-2][0] if len(files) >= 2 else None
                if prev_v:
                    keep_versions.add(prev_v)
            for v, f in files:
                if v not in keep_versions:
                    os.unlink(f)
                    print(f'  🗑️ 清理旧版: {os.path.basename(f)}')
            print(f'  💾 保留 {len(keep_versions)} 版: {sorted(keep_versions)}')

        return output_path

    except Exception:
        conn.close()
        if os.path.exists(db_path):
            os.unlink(db_path)
        raise
    finally:
        conn.close()
        if os.path.exists(db_path):
            try:
                os.unlink(db_path)
            except PermissionError:
                pass
