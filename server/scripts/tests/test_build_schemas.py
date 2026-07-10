"""构建脚本 Schema 定义测试 — 验证 ASSETS_TABLES / LECTURE_TABLES 结构正确性"""

from scripts.build_schemas import ASSETS_TABLES, LECTURE_TABLES


class TestAssetsTables:
    """assets.db 表结构验证"""

    def test_has_required_tables(self):
        """必须包含题库核心表"""
        required = [
            'question', 'choice_ext', 'sub_question',
            'solution_method', 'solution_step',
            'concept_tag', 'knowledge_card',
            'question_concept_tag', 'question_knowledge_card',
        ]
        for t in required:
            assert t in ASSETS_TABLES, f'缺少表: {t}'

    def test_question_has_core_columns(self):
        """question 表含必需列"""
        cols = {c[0] for c in ASSETS_TABLES['question']['columns']}
        required = {'id', 'year', 'question_type', 'stem', 'difficulty'}
        assert required.issubset(cols), f'缺少列: {required - cols}'

    def test_each_table_has_primary_key(self):
        """每张表都有 PRIMARY KEY（可能是 id 或 level）"""
        for name, tdef in ASSETS_TABLES.items():
            cols = tdef['columns']
            has_pk = any('PRIMARY KEY' in col[1] for col in cols)
            assert has_pk, f'{name} 缺少 PRIMARY KEY'

    def test_all_tables_14(self):
        """assets.db 共 14 张表"""
        assert len(ASSETS_TABLES) == 14

    def test_each_table_has_valid_transform(self):
        """每张表必须有 transform 或 source"""
        for name, tdef in ASSETS_TABLES.items():
            has = bool(tdef.get('transform') or tdef.get('source'))
            assert has, f'{name} 缺少 transform/source'

    def test_m2m_table_source_format(self):
        """m2m 表 source 格式正确"""
        m2m = ASSETS_TABLES.get('question_concept_tag', {})
        src = m2m.get('source', '')
        assert src.startswith('m2m:'), f'source 格式错误: {src}'

    def test_relation_table_source(self):
        """relation 表 source 标记正确"""
        rel = ASSETS_TABLES.get('question_knowledge_card', {})
        assert rel.get('source') == 'relation'

    def test_level_config_pk_is_level(self):
        """level_config 的 PK 是 level 不是 id"""
        pk_col = ASSETS_TABLES['level_config']['columns'][0]
        assert pk_col[0] == 'level'
        assert 'PRIMARY KEY' in pk_col[1]


class TestLectureTables:
    """lectures.db 表结构验证"""

    def test_has_required_tables(self):
        """必须包含讲义核心表"""
        required = [
            'course', 'chapter', 'lecture_content',
            'assignment', 'assignment_question',
        ]
        for t in required:
            assert t in LECTURE_TABLES, f'缺少表: {t}'

    def test_all_tables_5(self):
        """lectures.db 共 5 张表"""
        assert len(LECTURE_TABLES) == 5

    def test_chapter_is_generated(self):
        """chapter 表由 generate 生成"""
        src = LECTURE_TABLES['chapter']['source']
        assert src == 'generate:from_document_chapter'

    def test_lecture_content_has_transform(self):
        """lecture_content 使用 lecture_transform"""
        assert LECTURE_TABLES['lecture_content']['transform'] == 'lecture_transform'

    def test_chapter_columns(self):
        """chapter 表含必需列"""
        cols = {c[0] for c in LECTURE_TABLES['chapter']['columns']}
        assert {'id', 'course_id', 'sort_order', 'title'}.issubset(cols)
