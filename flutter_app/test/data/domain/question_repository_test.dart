import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_app/data/database/assets_database.dart' as adb;
import 'package:flutter_app/data/database/app_database.dart' as udb;
import 'package:flutter_app/data/daos/question_dao.dart';
import 'package:flutter_app/data/daos/progress_dao.dart';
import 'package:flutter_app/domain/question_repository.dart';

adb.QuestionsCompanion qCompanion({
  int id = 1, int year = 2024, String examType = '一模', String region = '海淀',
  String number = '1', String questionType = 'choice', double difficulty = 5.0,
  String stem = '题干',
}) => adb.QuestionsCompanion(
  id: Value(id), year: Value(year), examType: Value(examType),
  region: Value(region), number: Value(number), questionType: Value(questionType),
  difficulty: Value(difficulty), stem: Value(stem),
);

void main() {
  late adb.AssetsDatabase aDb;
  late udb.AppDatabase uDb;
  late QuestionDao qDao;
  late ProgressDao pDao;
  late QuestionRepository repo;

  setUp(() {
    aDb = adb.AssetsDatabase(NativeDatabase.memory());
    uDb = udb.AppDatabase(NativeDatabase.memory());
    qDao = QuestionDao(aDb);
    pDao = ProgressDao(uDb);
    repo = QuestionRepository(qDao, pDao);
  });

  tearDown(() {
    aDb.close();
    uDb.close();
  });

  group('QuestionRepository', () {
    test('getDetail throws for nonexistent', () async {
      expect(() => repo.getDetail(999), throwsA(isA<Exception>()));
    });

    test('getDetail returns basic question', () async {
      await aDb.into(aDb.questions).insert(qCompanion(stem: '测试题干'));
      final d = await repo.getDetail(1);
      expect(d.id, 1);
      expect(d.stem, '测试题干');
      expect(d.questionType, 'choice');
    });

    test('startSolve creates attempt', () async {
      await aDb.into(aDb.questions).insert(qCompanion());
      final attempt = await repo.startSolve(1);
      expect(attempt.questionId, 1);
      expect(attempt.attemptNumber, 1);
    });

    test('nextQuestion returns next id', () async {
      await aDb.into(aDb.questions).insert(qCompanion(id: 1, number: '1'));
      await aDb.into(aDb.questions).insert(qCompanion(id: 2, number: '2'));
      expect(await repo.nextQuestion(1), 2);
      expect(await repo.nextQuestion(2), isNull);
    });
  });
}
