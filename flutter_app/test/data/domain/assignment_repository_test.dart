import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_app/data/database/lectures_database.dart' as ldb;
import 'package:flutter_app/data/database/assets_database.dart' as adb;
import 'package:flutter_app/data/database/app_database.dart' as udb;
import 'package:flutter_app/data/daos/assignment_dao.dart';
import 'package:flutter_app/data/daos/progress_dao.dart';
import 'package:flutter_app/data/daos/question_dao.dart';
import 'package:flutter_app/domain/assignment_repository.dart';

/// 快速插入一条题目到 assets.db（返回 question_id）
Future<int> _insertQuestion(adb.AssetsDatabase db, {
  int id = 1, String number = '7', String questionType = 'choice',
}) async {
  await db.into(db.questions).insert(adb.QuestionsCompanion(
    id: Value(id),
    year: Value(2025),
    examType: Value('mock'),
    region: Value('海淀'),
    number: Value(number),
    questionType: Value(questionType),
    stem: Value('测试题'),
  ));
  return id;
}

/// 快速插入一条作业 + 题目关联
Future<int> _insertAssignment(ldb.LecturesDatabase db, {
  int id = 1, int courseId = 1, List<int> questionIds = const [1],
}) async {
  await db.into(db.courses).insert(ldb.CoursesCompanion(
    id: Value(courseId), name: Value('代数'),
  ));
  await db.into(db.assignments).insert(ldb.AssignmentsCompanion(
    id: Value(id), title: Value('函数作业'), courseId: Value(courseId),
  ));
  for (int i = 0; i < questionIds.length; i++) {
    await db.into(db.assignmentQuestions).insert(ldb.AssignmentQuestionsCompanion(
      assignmentId: Value(id),
      questionId: Value(questionIds[i]),
      sortOrder: Value(i),
    ));
  }
  return id;
}

void main() {
  group('AssignmentRepository', () {
    test('getPending returns 0 done when no attempts', () async {
      final lDb = ldb.LecturesDatabase(NativeDatabase.memory());
      final aDb = adb.AssetsDatabase(NativeDatabase.memory());
      final uDb = udb.AppDatabase(NativeDatabase.memory());

      await _insertQuestion(aDb);
      await _insertAssignment(lDb);

      final repo = AssignmentRepository(
        AssignmentDao(lDb), ProgressDao(uDb), QuestionDao(aDb),
      );
      final list = await repo.getPending();
      expect(list.length, 1);
      expect(list[0].doneCount, 0);
      expect(list[0].totalCount, 1);
      expect(list[0].status, 'pending');
      expect(list[0].courseName, '代数');

      await lDb.close(); await aDb.close(); await uDb.close();
    });

    test('getPending counts attempts as done', () async {
      final lDb = ldb.LecturesDatabase(NativeDatabase.memory());
      final aDb = adb.AssetsDatabase(NativeDatabase.memory());
      final uDb = udb.AppDatabase(NativeDatabase.memory());

      await _insertQuestion(aDb, id: 1, number: '7', questionType: 'choice');
      await _insertQuestion(aDb, id: 2, number: '8', questionType: 'fill');
      await _insertAssignment(lDb, questionIds: [1, 2]);

      // Create an attempt for question 1
      final pDao = ProgressDao(uDb);
      await pDao.createAttempt(questionId: 1);

      final repo = AssignmentRepository(
        AssignmentDao(lDb), pDao, QuestionDao(aDb),
      );
      final list = await repo.getPending();
      expect(list.length, 1);
      expect(list[0].doneCount, 1);
      expect(list[0].totalCount, 2);
      expect(list[0].status, 'in_progress');

      await lDb.close(); await aDb.close(); await uDb.close();
    });

    test('getQuestions returns number/type from assets and status from user', () async {
      final lDb = ldb.LecturesDatabase(NativeDatabase.memory());
      final aDb = adb.AssetsDatabase(NativeDatabase.memory());
      final uDb = udb.AppDatabase(NativeDatabase.memory());

      await _insertQuestion(aDb, id: 10, number: '7', questionType: 'choice');
      await _insertQuestion(aDb, id: 11, number: '8', questionType: 'fill');
      await _insertAssignment(lDb, questionIds: [10, 11]);

      final pDao = ProgressDao(uDb);
      // Complete question 10
      final aid = await pDao.createAttempt(questionId: 10);
      final q = uDb.update(uDb.submissionDetails)..where((t) => t.id.equals(aid));
      await q.write(udb.SubmissionDetailsCompanion(
        isCorrect: Value(1), status: Value('completed'),
      ));

      final repo = AssignmentRepository(
        AssignmentDao(lDb), pDao, QuestionDao(aDb),
      );
      final detail = await repo.getQuestions(1);
      expect(detail.totalCount, 2);
      expect(detail.doneCount, 1);
      expect(detail.courseName, '代数');
      expect(detail.questions[0].number, '7');
      expect(detail.questions[0].questionType, 'choice');
      expect(detail.questions[0].status, 'completed');
      expect(detail.questions[1].number, '8');
      expect(detail.questions[1].questionType, 'fill');
      expect(detail.questions[1].status, 'pending');

      await lDb.close(); await aDb.close(); await uDb.close();
    });

    test('getQuestions throws for nonexistent', () async {
      final lDb = ldb.LecturesDatabase(NativeDatabase.memory());
      final aDb = adb.AssetsDatabase(NativeDatabase.memory());
      final uDb = udb.AppDatabase(NativeDatabase.memory());

      final repo = AssignmentRepository(
        AssignmentDao(lDb), ProgressDao(uDb), QuestionDao(aDb),
      );
      expect(() => repo.getQuestions(999), throwsA(isA<Exception>()));

      await lDb.close(); await aDb.close(); await uDb.close();
    });

    test('pendingCount returns 0 initially', () async {
      final lDb = ldb.LecturesDatabase(NativeDatabase.memory());
      final aDb = adb.AssetsDatabase(NativeDatabase.memory());
      final uDb = udb.AppDatabase(NativeDatabase.memory());

      final repo = AssignmentRepository(
        AssignmentDao(lDb), ProgressDao(uDb), QuestionDao(aDb),
      );
      expect(await repo.pendingCount(), 0);

      await lDb.close(); await aDb.close(); await uDb.close();
    });
  });
}
