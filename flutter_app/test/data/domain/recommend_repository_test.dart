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

    test('getSmartList with questions returns suggestions', () async {
      // 插入一个概念标签
      await aDb.into(aDb.conceptTags).insert(adb.ConceptTagsCompanion(
        id: const Value(1), name: const Value('函数'),
      ));
      // 插入一道题并关联标签
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
      expect(list.length, 1);
      expect(list.first.id, 1);
    });
  });
}
