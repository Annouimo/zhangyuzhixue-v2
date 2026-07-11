"""
客户端数据库表结构定义（独立 Schema）

与 Django models 独立维护。客户端只包含运行所需字段，不包含服务端管理字段。
"""

ASSETS_TABLES = {
    'question': {
        'columns': [
            ('id', 'INTEGER PRIMARY KEY'),
            ('year', 'INTEGER NOT NULL'),
            ('exam_type', 'TEXT NOT NULL'),
            ('region', 'TEXT NOT NULL'),
            ('number', 'TEXT NOT NULL'),
            ('question_type', 'TEXT NOT NULL'),
            ('difficulty', 'REAL'),
            ('calculation', 'REAL'),
            ('stem', 'TEXT NOT NULL'),
            ('images', 'TEXT'),          # JSON list
            ('default_score', 'REAL'),
        ],
        'source_model': 'qbank.BaseQuestion',
        'transform': 'direct',
    },

    'choice_ext': {
        'columns': [
            ('id', 'INTEGER PRIMARY KEY'),
            ('question_id', 'INTEGER NOT NULL UNIQUE'),
            ('options', 'TEXT NOT NULL'),  # JSON
        ],
        'source_model': 'qbank.ChoiceExt',
        'transform': 'direct',
    },

    'sub_question': {
        'columns': [
            ('id', 'INTEGER PRIMARY KEY'),
            ('question_id', 'INTEGER NOT NULL'),
            ('parent_id', 'INTEGER'),
            ('stem', 'TEXT'),
            ('answer', 'TEXT'),
            ('sort_order', 'INTEGER NOT NULL'),
        ],
        'source_model': 'qbank.SubQuestion',
        'transform': 'direct',
    },

    'solution_method': {
        'columns': [
            ('id', 'INTEGER PRIMARY KEY'),
            ('sub_question_id', 'INTEGER NOT NULL'),
            ('method_name', 'TEXT'),
            ('source', 'TEXT'),
            ('sort_order', 'INTEGER NOT NULL'),
        ],
        'source_model': 'qbank.SolutionMethod',
        'transform': 'direct',
    },

    'solution_step': {
        'columns': [
            ('id', 'INTEGER PRIMARY KEY'),
            ('method_id', 'INTEGER NOT NULL'),
            ('step_number', 'INTEGER NOT NULL'),
            ('title', 'TEXT NOT NULL'),
            ('content', 'TEXT NOT NULL'),
            ('card_titles', 'TEXT'),      # JSON list
        ],
        'source_model': 'qbank.SolutionStep',
        'transform': 'direct',
    },

    'concept_tag': {
        'columns': [
            ('id', 'INTEGER PRIMARY KEY'),
            ('name', 'TEXT NOT NULL UNIQUE'),
            ('parent_id', 'INTEGER'),
        ],
        'source_model': 'qbank.ConceptTag',
        'transform': 'direct',
    },

    'knowledge_card': {
        'columns': [
            ('id', 'INTEGER PRIMARY KEY'),
            ('title', 'TEXT NOT NULL'),
            ('category', 'TEXT NOT NULL'),
            ('content', 'TEXT NOT NULL'),
        ],
        'source_model': 'qbank.KnowledgeCard',
        'transform': 'direct',
    },

    # M2M 中间表
    'question_concept_tag': {
        'columns': [
            ('id', 'INTEGER PRIMARY KEY'),
            ('question_id', 'INTEGER NOT NULL'),
            ('concept_tag_id', 'INTEGER NOT NULL'),
        ],
        'source': 'm2m:qbank.BaseQuestion.concept_tags',
    },

    'question_knowledge_card': {
        'columns': [
            ('id', 'INTEGER PRIMARY KEY'),
            ('question_id', 'INTEGER NOT NULL'),
            ('knowledge_card_id', 'INTEGER NOT NULL'),
        ],
        'source': 'relation',
    },

    'course': {
        'columns': [
            ('id', 'INTEGER PRIMARY KEY'),
            ('name', 'TEXT NOT NULL'),
            ('description', 'TEXT'),
        ],
        'source_model': 'courses.Course',
        'transform': 'direct',
    },

    'assignment': {
        'columns': [
            ('id', 'INTEGER PRIMARY KEY'),
            ('title', 'TEXT NOT NULL'),
            ('description', 'TEXT'),
            ('course_id', 'INTEGER'),
        ],
        'source_model': 'courses.Assignment',
        'transform': 'direct',
    },

    'assignment_question': {
        'columns': [
            ('id', 'INTEGER PRIMARY KEY'),
            ('assignment_id', 'INTEGER NOT NULL'),
            ('question_id', 'INTEGER NOT NULL'),
            ('sort_order', 'INTEGER NOT NULL'),
        ],
        'source_model': 'courses.AssignmentQuestion',
        'transform': 'direct',
    },

    'achievement_def': {
        'columns': [
            ('id', 'INTEGER PRIMARY KEY'),
            ('code', 'TEXT NOT NULL UNIQUE'),
            ('name', 'TEXT NOT NULL'),
            ('description', 'TEXT'),
            ('icon', 'TEXT'),
            ('icon_emoji', 'TEXT'),
            ('category', 'TEXT NOT NULL'),
            ('category_label', 'TEXT'),
            ('display_order', 'INTEGER'),
            ('trigger_type', 'TEXT'),
            ('threshold', 'INTEGER'),
        ],
        'source_model': 'system.AchievementDef',
        'transform': 'direct',
    },

    'level_config': {
        'columns': [
            ('level', 'INTEGER PRIMARY KEY'),
            ('min_xp', 'INTEGER NOT NULL'),
            ('title', 'TEXT NOT NULL'),
            ('icon_emoji', 'TEXT'),
        ],
        'source_model': 'system.LevelConfig',
        'transform': 'direct',
    },

    'system_config': {
        'columns': [
            ('key', 'TEXT PRIMARY KEY'),
            ('value', 'TEXT NOT NULL'),
            ('description', 'TEXT'),
        ],
        'source': 'static',
        'defaults': [
            ('exit_rating_probability', '0.2', '退出页面评价触发概率'),
            ('exit_rating_min_stay_seconds', '30', '退出页面评价停留阈值(秒)'),
            ('exit_rating_reward_points', '5', '退出页面评价奖励积分'),
            ('solve_cooldown_choice', '10', '选择题冷却时长(秒)'),
            ('solve_cooldown_fill', '10', '填空题冷却时长(秒)'),
            ('solve_cooldown_step', '5', '解答题每步冷却时长(秒)'),
        ],
    },
}

LECTURE_TABLES = {
    'course': {
        'columns': [
            ('id', 'INTEGER PRIMARY KEY'),
            ('name', 'TEXT NOT NULL'),
            ('description', 'TEXT'),
        ],
        'source_model': 'courses.Course',
        'transform': 'direct',
    },

    'chapter': {
        'columns': [
            ('id', 'INTEGER PRIMARY KEY AUTOINCREMENT'),
            ('course_id', 'INTEGER NOT NULL'),
            ('sort_order', 'INTEGER NOT NULL'),
            ('title', 'TEXT NOT NULL'),
        ],
        'source': 'generate:from_document_chapter',
    },

    'lecture_content': {
        'columns': [
            ('id', 'INTEGER PRIMARY KEY AUTOINCREMENT'),
            ('chapter_id', 'INTEGER NOT NULL UNIQUE'),
            ('title', 'TEXT NOT NULL'),
            ('md_content', 'TEXT NOT NULL'),
            ('updated_at', 'TEXT'),
        ],
        'source_model': 'courses.Document',
        'transform': 'lecture_transform',
    },

    'assignment': {
        'columns': [
            ('id', 'INTEGER PRIMARY KEY'),
            ('title', 'TEXT NOT NULL'),
            ('description', 'TEXT'),
            ('course_id', 'INTEGER'),
        ],
        'source_model': 'courses.Assignment',
        'transform': 'direct',
    },

    'assignment_question': {
        'columns': [
            ('id', 'INTEGER PRIMARY KEY'),
            ('assignment_id', 'INTEGER NOT NULL'),
            ('question_id', 'INTEGER NOT NULL'),
            ('sort_order', 'INTEGER NOT NULL'),
        ],
        'source_model': 'courses.AssignmentQuestion',
        'transform': 'direct',
    },
}

# 所有 schema 定义的列名集合，供 copy_data_direct 过滤 Django 字段用
ASSETS_COLUMNS = {
    tname: {col[0] for col in tdef['columns']}
    for tname, tdef in ASSETS_TABLES.items()
}

LECTURE_COLUMNS = {
    tname: {col[0] for col in tdef['columns']}
    for tname, tdef in LECTURE_TABLES.items()
}
