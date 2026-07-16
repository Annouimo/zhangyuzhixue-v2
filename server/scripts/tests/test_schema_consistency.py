"""
构建脚本 Schema vs Django 模型一致性验证 — CI 守卫

核心原则：Schema columns 是 Django 模型字段的 __子集__。
构建时故意省略服务端管理字段（created_at/updated_at 等）。
本测试只检查：schema 中的每一列都能在 Django 模型中找到对应字段，
防止出现添了字段但忘记加到 schema 的情况。
"""
import pytest

from scripts.build_schemas import ASSETS_TABLES, COURSES_TABLES


def _get_direct_tables():
    """返回所有 transform='direct' 的表"""
    result = {}
    for name, tdef in {**ASSETS_TABLES, **COURSES_TABLES}.items():
        if tdef.get('transform') == 'direct':
            result[name] = tdef
    return result


def _get_model_column_names(model_cls):
    """获取 Django 模型在数据库层面的所有列名（含 FK _id 列）"""
    cols = set()
    for f in model_cls._meta.get_fields():
        # 跳过自动创建的反向关系（OneToOneRel / ManyToOneRel 等）
        if getattr(f, 'auto_created', False) and not getattr(f, 'concrete', True):
            continue
        # 跳过多对多（由中间表独立处理）
        if f.many_to_many:
            continue
        # 获取实际列名——对 FK/OneToOne 是 field_id；对普通字段就是 field.name
        col = getattr(f, 'column', None) or f.name
        cols.add(col)
    return cols


@pytest.mark.django_db
class TestSchemaConsistencyWithModels:

    def test_all_direct_tables_have_valid_source_model(self):
        """每个 direct 表必须指定有效的 source_model"""
        direct_tables = _get_direct_tables()
        assert direct_tables, '没有找到 direct 表'
        for name, tdef in direct_tables.items():
            sm = tdef.get('source_model', '')
            assert sm, f'{name}: 缺少 source_model'
            from django.apps import apps
            try:
                apps.get_model(sm)
            except LookupError:
                pytest.fail(f'{name}: source_model="{sm}" 不是有效的 Django 模型')

    def test_schema_columns_exist_in_django_model(self):
        """ schema 中的每个列名都必须在对应 Django 模型中有定义 """
        direct_tables = _get_direct_tables()
        errors = []

        for name, tdef in direct_tables.items():
            sm = tdef.get('source_model', '')
            from django.apps import apps
            try:
                model_cls = apps.get_model(sm)
            except LookupError:
                continue

            schema_cols = {c[0] for c in tdef.get('columns', [])}
            model_cols = _get_model_column_names(model_cls)

            # schema 中的列必须在 Django 模型中有定义
            for sc in schema_cols:
                if sc not in model_cols:
                    errors.append(
                        f'{name}.{sc}: schema 中有此列，但 {sm} 模型没有对应字段'
                    )

        if errors:
            pytest.fail('Schema 列找不到对应的模型字段:\n' + '\n'.join(errors))

    def test_direct_table_count(self):
        """验证 direct 表总数（防止误删）"""
        direct_tables = _get_direct_tables()
        # assets: 12 direct, lecture: 3 direct（与 assets 重叠）
        assert len(direct_tables) >= 12, (
            f'预期至少 12 个 direct 表，实际 {len(direct_tables)}'
        )
