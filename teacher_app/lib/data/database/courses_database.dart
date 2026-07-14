import 'package:drift/drift.dart';

part 'courses_database.g.dart';

// ═══════════════════════════════════════════════
// 表定义 — SQL 表名与设计文档 docs/02-数据/数据库结构设计.md 一致（单数）
// ═══════════════════════════════════════════════

@DataClassName('CourseRow')
class Courses extends Table {
  @override
  String get tableName => 'course';
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn? get description => text().nullable()();
}

@DataClassName('ChapterRow')
class Chapters extends Table {
  @override
  String get tableName => 'chapter';
  IntColumn get id => integer().autoIncrement()();
  IntColumn get courseId => integer()();
  IntColumn get index => integer()();
  TextColumn get title => text()();
}

@DataClassName('LectureContentRow')
class LectureContents extends Table {
  @override
  String get tableName => 'lecture_content';
  IntColumn get id => integer().autoIncrement()();
  IntColumn get chapterId => integer().unique()();
  TextColumn get title => text()();
  TextColumn get mdContent => text()();
  TextColumn? get updatedAt => text().nullable()();
}

@DataClassName('AssignmentRow')
class Assignments extends Table {
  @override
  String get tableName => 'assignment';
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn? get description => text().nullable()();
  IntColumn? get courseId => integer().nullable()();
}

@DataClassName('AssignmentQuestionRow')
class AssignmentQuestions extends Table {
  @override
  String get tableName => 'assignment_question';
  IntColumn get id => integer().autoIncrement()();
  IntColumn get assignmentId => integer()();
  IntColumn get questionId => integer()();
  IntColumn get sortOrder => integer()();
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
  Courses,
  Chapters,
  LectureContents,
  Assignments,
  AssignmentQuestions,
  Meta,
])
class CoursesDatabase extends _$CoursesDatabase {
  CoursesDatabase(super.e);

  @override
  int get schemaVersion => 1;
}
