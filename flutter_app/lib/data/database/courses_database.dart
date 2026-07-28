import 'package:drift/drift.dart';

part 'courses_database.g.dart';

// ═══════════════════════════════════════════════
// 表定义 — 数据架构见 docs/current/data-architecture.md
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
  Meta,
])
class CoursesDatabase extends _$CoursesDatabase {
  CoursesDatabase(super.e);

  @override
  int get schemaVersion => 1;
}
