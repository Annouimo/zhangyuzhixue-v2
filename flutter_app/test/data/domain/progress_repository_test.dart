import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:flutter_app/data/database/app_database.dart' as udb;
import 'package:flutter_app/data/database/assets_database.dart' as adb;
import 'package:flutter_app/data/daos/progress_dao.dart';
import 'package:flutter_app/data/daos/question_dao.dart';
import 'package:flutter_app/domain/progress_repository.dart';

void main() {
  late udb.AppDatabase uDb;
  late adb.AssetsDatabase aDb;
  late ProgressDao pDao;
  late QuestionDao qDao;
  late ProgressRepository repo;

  setUp(() {
    uDb = udb.AppDatabase(NativeDatabase.memory());
    aDb = adb.AssetsDatabase(NativeDatabase.memory());
    pDao = ProgressDao(uDb);
    qDao = QuestionDao(aDb);
    repo = ProgressRepository(pDao, qDao);
  });

  tearDown(() {
    uDb.close();
    aDb.close();
  });

  group('ProgressRepository', () {
    test('getAttempts returns empty initially', () async {
      final att = await repo.getAttempts(1);
      expect(att, isEmpty);
    });

    test('createAttempt returns id', () async {
      final id = await repo.createAttempt(1);
      expect(id, greaterThan(0));
    });

    test('getSolveState handles nonexistent question', () async {
      final state = await repo.getSolveState(1);
      expect(state.subQuestions, isEmpty);
    });

    test('createAttempt then getAttempts returns one', () async {
      await repo.createAttempt(1);
      final att = await repo.getAttempts(1);
      expect(att.length, 1);
      expect(att.first.attemptNumber, 1);
    });

    test('getAttemptState returns null for nonexistent', () async {
      final state = await repo.getAttemptState(1, 1);
      expect(state, isNull);
    });
  });
}
