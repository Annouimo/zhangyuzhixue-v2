import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_app/data/database/courses_database.dart' as db;
import 'package:flutter_app/data/daos/assignment_dao.dart';

void main() {
  late db.CoursesDatabase database;
  late AssignmentDao dao;

  setUp(() {
    database = db.CoursesDatabase(NativeDatabase.memory());
    dao = AssignmentDao(database);
  });

  tearDown(() => database.close());

  group('AssignmentDao', () {
    test('listAll returns empty initially', () async {
      final result = await dao.listAll();
      expect(result, isEmpty);
    });

    test('listAll returns all assignments', () async {
      await database.into(database.assignments).insert(db.AssignmentsCompanion(
        title: Value('作业1'),
      ));
      await database.into(database.assignments).insert(db.AssignmentsCompanion(
        title: Value('作业2'),
        courseId: Value(1),
      ));
      final result = await dao.listAll();
      expect(result.length, 2);
    });

    test('getById returns correct assignment', () async {
      final id = await database.into(database.assignments).insert(db.AssignmentsCompanion(
        title: Value('测试作业'),
      ));
      final result = await dao.getById(id);
      expect(result, isNotNull);
      expect(result!.title, '测试作业');
    });

    test('getById returns null for nonexistent', () async {
      final result = await dao.getById(999);
      expect(result, isNull);
    });

    test('getByCourse returns filtered assignments', () async {
      await database.into(database.assignments).insert(db.AssignmentsCompanion(
        title: Value('A1'), courseId: Value(1),
      ));
      await database.into(database.assignments).insert(db.AssignmentsCompanion(
        title: Value('A2'), courseId: Value(1),
      ));
      await database.into(database.assignments).insert(db.AssignmentsCompanion(
        title: Value('A3'), courseId: Value(2),
      ));
      final result = await dao.getByCourse(1);
      expect(result.length, 2);
    });

    test('getQuestions returns ordered questions', () async {
      final aId = await database.into(database.assignments).insert(db.AssignmentsCompanion(
        title: Value('作业'),
      ));
      await database.into(database.assignmentQuestions).insert(db.AssignmentQuestionsCompanion(
        assignmentId: Value(aId), questionId: Value(2), sortOrder: Value(2),
      ));
      await database.into(database.assignmentQuestions).insert(db.AssignmentQuestionsCompanion(
        assignmentId: Value(aId), questionId: Value(1), sortOrder: Value(1),
      ));
      final result = await dao.getQuestions(aId);
      expect(result.length, 2);
      expect(result[0].questionId, 1);
      expect(result[1].questionId, 2);
    });

    test('getQuestionIds returns id list', () async {
      final aId = await database.into(database.assignments).insert(db.AssignmentsCompanion(
        title: Value('作业'),
      ));
      await database.into(database.assignmentQuestions).insert(db.AssignmentQuestionsCompanion(
        assignmentId: Value(aId), questionId: Value(42), sortOrder: Value(0),
      ));
      final result = await dao.getQuestionIds(aId);
      expect(result, [42]);
    });

    test('count returns correct number', () async {
      expect(await dao.count(), 0);
      await database.into(database.assignments).insert(db.AssignmentsCompanion(title: Value('A')));
      await database.into(database.assignments).insert(db.AssignmentsCompanion(title: Value('B')));
      expect(await dao.count(), 2);
    });
  });
}
