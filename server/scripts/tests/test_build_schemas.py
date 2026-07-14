"""构建脚本 Schema 定义验证测试"""
from scripts.build_schemas import ASSETS_TABLES, COURSES_TABLES


class TestAssetsTables:
    """assets.db 表结构验证"""

    def test_has_required_tables(self):
        """必须包含所有核心表"""
        required = [
            'question', 'choice_ext', 'sub_question',
            'solution_method', 'solution_step',
            'concept_tag', 'knowledge_card',
            'question_concept_tag', 'question_knowledge_card',
            'course', 'assignment', 'assignment_question',
            'achievement_def', 'level_config',
        ]
        for name in required:
            assert name in ASSETS_TABLES, f'缺少表: {name}'

    def test_question_has_core_columns(self):
        """question 表必须包含核心字段"""
        cols = dict(ASSETS_TABLES['question']['columns'])
        for col in [
            'id', 'year', 'exam_type', 'region', 'number',
            'question_type', 'difficulty', 'calculation', 'stem',
        ]:
            assert col in cols, f'缺少字段: {col}'

    def test_each_table_has_primary_key(self):
        """每个表必须有 PRIMARY KEY"""
        for name, tdef in ASSETS_TABLES.items():
            cols = tdef['columns']
            pks = [c for c in cols if 'PRIMARY KEY' in c[1].upper()]
            assert pks, f'{name} 缺少 PRIMARY KEY'

    def test_all_tables_14(self):
        """assets.db 应有 15 个表"""
        assert len(ASSETS_TABLES) == 15

    def test_each_table_has_valid_transform(self):
        """每个表必须有 transform 或 source"""
        for name, tdef in ASSETS_TABLES.items():
            has = bool(tdef.get('transform') or tdef.get('source'))
            assert has, f'{name} 缺少 transform/source'

    def test_knowledge_card_has_category_column(self):
        """knowledge_card 必须有 category 列"""
        cols = ASSETS_TABLES['knowledge_card']['columns']
        col_names = [c[0] for c in cols]
        assert 'category' in col_names, f'缺少 category 列: {col_names}'

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
        for name in required:
            assert name in COURSES_TABLES, f'缺少表: {name}'

    def test_all_tables_5(self):
        """lectures.db 应有 5 个表"""
        assert len(COURSES_TABLES) == 5

    def test_chapter_is_generated(self):
        """chapter 表 source 应为 generate"""
        src = COURSES_TABLES['chapter'].get('source', '')
        assert src.startswith('generate:'), f'chapter source 错误: {src}'

    def test_lecture_content_has_transform(self):
        """lecture_content 应有 transform 字段"""
        trans = COURSES_TABLES['lecture_content'].get('transform', '')
        assert trans == 'lecture_transform', 'transform 应为 lecture_transform'

    def test_chapter_columns(self):
        """chapter 表应有 course_id/index/title"""
        cols = dict(COURSES_TABLES['chapter']['columns'])
        for col in ['course_id', 'index', 'title']:
            assert col in cols, f'缺少字段: {col}'
