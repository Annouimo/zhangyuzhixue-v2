import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_app/data/database/assets_database.dart' as adb;
import 'package:flutter_app/data/database/app_database.dart' as udb;
import 'package:flutter_app/data/daos/question_dao.dart';
import 'package:flutter_app/data/daos/progress_dao.dart';
import 'package:flutter_app/domain/recommend_repository.dart';

void main() {
  late adb.AssetsDatabase aDb;
  late udb.AppDatabase uDb;
  late QuestionDao qDao;
  late ProgressDao pDao;
  late RecommendRepository repo;

  setUp(() {
    aDb = adb.AssetsDatabase(NativeDatabase.memory());
    uDb = udb.AppDatabase(NativeDatabase.memory());
    qDao = QuestionDao(aDb);
    pDao = ProgressDao(uDb);
    repo = RecommendRepository(qDao, pDao);
  });

  tearDown(() {
    aDb.close();
    uDb.close();
  });

  group('RecommendRepository', () {
    test('getSmartList returns empty when no questions', () async {
      final list = await repo.getSmartList();
      expect(list, isEmpty);
    });

    test('getPresets returns empty', () async {
      expect(await repo.getPresets(), isEmpty);
    });

    test('getPresetQuestions returns empty', () async {
      expect(await repo.getPresetQuestions(1), isEmpty);
    });

    test('getSmartList cold start returns empty when <5 attempts', () async {
      await aDb.into(aDb.conceptTags).insert(adb.ConceptTagsCompanion(
        id: const Value(1), name: const Value('函数'),
      ));
      await aDb.into(aDb.questions).insert(adb.QuestionsCompanion(
        id: const Value(1), year: const Value(2024),
        examType: const Value('一模'), region: const Value('海淀'),
        number: const Value('1'), questionType: const Value('choice'),
        stem: const Value('测试题'),
      ));
      await aDb.into(aDb.questionConceptTags).insert(adb.QuestionConceptTagsCompanion(
        questionId: const Value(1), conceptTagId: const Value(1),
      ));
      final list = await repo.getSmartList();
      expect(list, isEmpty); // < 5 attempts → cold start
    });

    test('getSmartList with >5 attempted questions returns suggestions', () async {
      await aDb.into(aDb.conceptTags).insert(adb.ConceptTagsCompanion(
        id: const Value(1), name: const Value('函数'),
      ));
      // 插入 5 道题 + 各自有尝试记录
      for (var i = 1; i <= 5; i++) {
        await aDb.into(aDb.questions).insert(adb.QuestionsCompanion(
          id: Value(i), year: const Value(2024),
          examType: const Value('一模'), region: const Value('海淀'),
          number: Value(i.toString()), questionType: const Value('choice'),
          stem: Value('题 $i'),
        ));
        await aDb.into(aDb.questionConceptTags).insert(adb.QuestionConceptTagsCompanion(
          questionId: Value(i), conceptTagId: const Value(1),
        ));
        // 为每道题创建尝试记录（跨越冷启动阈值）
        await pDao.createAttempt(questionId: i);
      }
      // 再插入一道未做的题
      await aDb.into(aDb.questions).insert(adb.QuestionsCompanion(
        id: const Value(6), year: const Value(2024),
        examType: const Value('一模'), region: const Value('海淀'),
        number: const Value('6'), questionType: const Value('choice'),
        stem: const Value('未做题'),
      ));
      await aDb.into(aDb.questionConceptTags).insert(adb.QuestionConceptTagsCompanion(
        questionId: const Value(6), conceptTagId: const Value(1),
      ));
      final list = await repo.getSmartList();
      expect(list, isNotEmpty);
    });
  });
}
