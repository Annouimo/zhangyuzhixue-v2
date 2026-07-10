import 'package:drift/drift.dart';

part 'lectures_database.g.dart';

// ═══════════════════════════════════════════════
// 表定义
// ═══════════════════════════════════════════════

@DataClassName('CourseRow')
class Courses extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn? get description => text().nullable()();
}

@DataClassName('ChapterRow')
class Chapters extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get courseId => integer()();
  IntColumn get index => integer()();
  TextColumn get title => text()();
}

@DataClassName('LectureContentRow')
class LectureContents extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get chapterId => integer().unique()();
  TextColumn get title => text()();
  TextColumn get mdContent => text()();
  TextColumn? get updatedAt => text().nullable()();
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

@DriftDatabase(tables: [
  Courses,
  Chapters,
  LectureContents,
  Assignments,
  AssignmentQuestions,
  Meta,
])
class LecturesDatabase extends _$LecturesDatabase {
  LecturesDatabase(super.e);

  @override
  int get schemaVersion => 1;
}
