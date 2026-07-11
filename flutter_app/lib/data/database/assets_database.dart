import 'package:drift/drift.dart';

part 'assets_database.g.dart';

// ═══════════════════════════════════════════════
// 表定义
// ═══════════════════════════════════════════════

@DataClassName('QuestionRow')
class Questions extends Table {
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
  IntColumn get id => integer().autoIncrement()();
  IntColumn get questionId => integer()();
  IntColumn? get parentId => integer().nullable()();
  TextColumn? get stem => text().nullable()();
  TextColumn? get answer => text().nullable()();
  IntColumn get sortOrder => integer()();
}

@DataClassName('SolutionMethodRow')
class SolutionMethods extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get subQuestionId => integer()();
  TextColumn? get methodName => text().nullable()();
  TextColumn? get source => text().nullable()();
  IntColumn get sortOrder => integer()();
}

@DataClassName('SolutionStepRow')
class SolutionSteps extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get methodId => integer()();
  IntColumn get stepNumber => integer()();
  TextColumn get title => text()();
  TextColumn get content => text()();
  TextColumn? get cardTitles => text().nullable()();
}

@DataClassName('ConceptTagRow')
class ConceptTags extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().unique()();
  IntColumn? get parentId => integer().nullable()();
}

@DataClassName('KnowledgeCardRow')
class KnowledgeCards extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get category => text()();
  TextColumn get content => text()();
}

@DataClassName('QuestionConceptTagRow')
class QuestionConceptTags extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get questionId => integer()();
  IntColumn get conceptTagId => integer()();
}

@DataClassName('QuestionKnowledgeCardRow')
class QuestionKnowledgeCards extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get questionId => integer()();
  IntColumn get knowledgeCardId => integer()();
}

@DataClassName('CourseRow')
class Courses extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn? get description => text().nullable()();
}

@DataClassName('AssignmentRow')
class Assignments extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn? get description => text().nullable()();
  IntColumn? get courseId => integer().nullable()();
}

@DataClassName('AssignmentQuestionRow')
class AssignmentQuestions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get assignmentId => integer()();
  IntColumn get questionId => integer()();
  IntColumn get sortOrder => integer()();
}

@DataClassName('AchievementDefRow')
class AchievementDefs extends Table {
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
  IntColumn get level => integer()();
  IntColumn get minXp => integer()();
  TextColumn get title => text()();
  TextColumn? get iconEmoji => text().nullable()();

  @override
  Set<Column> get primaryKey => {level};
}

/// 构建元数据
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

@DataClassName('SystemConfigRow')
class SystemConfigs extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  TextColumn? get description => text().nullable()();

  @override
  Set<Column> get primaryKey => {key};
}

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
  Courses,
  Assignments,
  AssignmentQuestions,
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
