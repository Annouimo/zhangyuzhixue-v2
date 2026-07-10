import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_app/data/database/app_database.dart' as udb;
import 'package:flutter_app/data/database/assets_database.dart' as adb;
import 'package:flutter_app/data/daos/achievement_dao.dart';
import 'package:flutter_app/data/daos/question_dao.dart';
import 'package:flutter_app/domain/achievement_repository.dart';

void main() {
  late udb.AppDatabase uDb;
  late adb.AssetsDatabase aDb;
  late AchievementDao dao;
  late QuestionDao qDao;
  late AchievementRepository repo;

  setUp(() {
    uDb = udb.AppDatabase(NativeDatabase.memory());
    aDb = adb.AssetsDatabase(NativeDatabase.memory());
    dao = AchievementDao(uDb);
    qDao = QuestionDao(aDb);
    repo = AchievementRepository(dao, qDao);
  });

  tearDown(() {
    uDb.close();
    aDb.close();
  });

  group('AchievementRepository', () {
    test('getSummary returns 0 unlocked', () async {
      final s = await repo.getSummary();
      expect(s.unlockedCount, 0);
      expect(s.totalCount, 0); // 无 achievement_def
    });

    test('unlockedCount returns 0 initially', () async {
      expect(await repo.unlockedCount(), 0);
    });

    test('getCategories returns categories with achievement defs', () async {
      // 插入成就定义
      await aDb.into(aDb.achievementDefs).insert(adb.AchievementDefsCompanion(
        code: const Value('LOGIN_7'),
        name: const Value('签到7天'),
        category: const Value('PRACTICE'),
        categoryLabel: const Value('学习实践'),
        triggerType: const Value('LOGIN_STREAK'),
        threshold: const Value(7),
      ));
      await aDb.into(aDb.achievementDefs).insert(adb.AchievementDefsCompanion(
        code: const Value('PRACTICE_100'),
        name: const Value('做题100'),
        category: const Value('PRACTICE'),
        categoryLabel: const Value('学习实践'),
        triggerType: const Value('PRACTICE_COUNT'),
        threshold: const Value(100),
      ));
      final cats = await repo.getCategories();
      expect(cats.length, 1); // 同一分类标签
      expect(cats.first.label, '学习实践');
      expect(cats.first.list.length, 2);
      expect(cats.first.list[0].name, '签到7天');
      expect(cats.first.list[1].name, '做题100');
    });
  });
}
