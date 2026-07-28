import 'package:drift/drift.dart';

part 'assets_database.g.dart';

// ═══════════════════════════════════════════════
// 表定义 — 数据架构见 docs/current/data-architecture.md
// ═══════════════════════════════════════════════

@DataClassName('QuestionRow')
class Questions extends Table {
  @override
  String get tableName => 'question';
  IntColumn get id => integer().autoIncrement()();
  IntColumn get year => integer()();
  TextColumn get examType => text()();
  TextColumn get region => text()();
  TextColumn get number => text()();
  TextColumn get questionType => text()();
  RealColumn get difficulty => real().nullable()();
  RealColumn get calculation => real().nullable()();
  TextColumn get stem => text()();
  TextColumn get images => text().nullable()();
  RealColumn get defaultScore => real().nullable()();
}

@DataClassName('ChoiceExtRow')
class ChoiceExt extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get questionId => integer().unique()();
  TextColumn get options => text()();
}

@DataClassName('SubQuestionRow')
class SubQuestions extends Table {
  @override
  String get tableName => 'sub_question';
  IntColumn get id => integer().autoIncrement()();
  IntColumn get questionId => integer()();
  IntColumn? get parentId => integer().nullable()();
  TextColumn? get stem => text().nullable()();
  TextColumn? get answer => text().nullable()();
  TextColumn? get explanation => text().nullable()();
  IntColumn get sortOrder => integer()();
}

@DataClassName('SolutionMethodRow')
class SolutionMethods extends Table {
  @override
  String get tableName => 'solution_method';
  IntColumn get id => integer().autoIncrement()();
  IntColumn get subQuestionId => integer()();
  TextColumn? get methodName => text().nullable()();
  TextColumn? get source => text().nullable()();
  IntColumn get sortOrder => integer()();
}

@DataClassName('SolutionStepRow')
class SolutionSteps extends Table {
  @override
  String get tableName => 'solution_step';
  IntColumn get id => integer().autoIncrement()();
  IntColumn get methodId => integer()();
  IntColumn get stepNumber => integer()();
  TextColumn get title => text()();
  TextColumn get content => text()();
  TextColumn? get cardTitles => text().nullable()();
}

@DataClassName('ConceptTagRow')
class ConceptTags extends Table {
  @override
  String get tableName => 'concept_tag';
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().unique()();
  IntColumn? get parentId => integer().nullable()();
}

@DataClassName('KnowledgeCardRow')
class KnowledgeCards extends Table {
  @override
  String get tableName => 'knowledge_card';
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get category => text()();
  TextColumn get content => text()();
}

@DataClassName('QuestionConceptTagRow')
class QuestionConceptTags extends Table {
  @override
  String get tableName => 'question_concept_tag';
  IntColumn get id => integer().autoIncrement()();
  IntColumn get questionId => integer()();
  IntColumn get conceptTagId => integer()();
}

@DataClassName('QuestionKnowledgeCardRow')
class QuestionKnowledgeCards extends Table {
  @override
  String get tableName => 'question_knowledge_card';
  IntColumn get id => integer().autoIncrement()();
  IntColumn get questionId => integer()();
  IntColumn get knowledgeCardId => integer()();
}

@DataClassName('AchievementDefRow')
class AchievementDefs extends Table {
  @override
  String get tableName => 'achievement_def';
  IntColumn get id => integer().autoIncrement()();
  TextColumn get code => text().unique()();
  TextColumn get name => text()();
  TextColumn? get description => text().nullable()();
  TextColumn? get icon => text().nullable()();
  TextColumn? get iconEmoji => text().nullable()();
  TextColumn get category => text()();
  TextColumn? get categoryLabel => text().nullable()();
  IntColumn? get displayOrder => integer().nullable()();
  TextColumn? get triggerType => text().nullable()();
  IntColumn? get threshold => integer().nullable()();
}

@DataClassName('LevelConfigRow')
class LevelConfigs extends Table {
  @override
  String get tableName => 'level_config';
  IntColumn get level => integer()();
  IntColumn get minXp => integer()();
  TextColumn get title => text()();
  TextColumn? get iconEmoji => text().nullable()();

  @override
  Set<Column> get primaryKey => {level};
}

@DataClassName('SystemConfigRow')
class SystemConfigs extends Table {
  @override
  String get tableName => 'system_config';
  TextColumn get key => text()();
  TextColumn get value => text()();
  TextColumn? get description => text().nullable()();

  @override
  Set<Column> get primaryKey => {key};
}

/// 构建元数据（表名已是单数，与设计文档一致）
@DataClassName('MetaRow')
class Meta extends Table {
  IntColumn get schemaVersion => integer()();
  IntColumn get dataVersion => integer()();
  TextColumn get checksum => text()();
  TextColumn get builtAt => text()();
}

// ═══════════════════════════════════════════════
// Database
// ═══════════════════════════════════════════════

@DriftDatabase(tables: [
  Questions,
  ChoiceExt,
  SubQuestions,
  SolutionMethods,
  SolutionSteps,
  ConceptTags,
  KnowledgeCards,
  QuestionConceptTags,
  QuestionKnowledgeCards,
  AchievementDefs,
  LevelConfigs,
  SystemConfigs,
  Meta,
])
class AssetsDatabase extends _$AssetsDatabase {
  AssetsDatabase(super.e);

  @override
  int get schemaVersion => 1;
}
