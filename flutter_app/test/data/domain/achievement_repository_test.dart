import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_app/data/database/app_database.dart' as udb;
import 'package:flutter_app/data/database/assets_database.dart' as adb;
import 'package:flutter_app/data/daos/achievement_dao.dart';
import 'package:flutter_app/data/daos/question_dao.dart';
import 'package:flutter_app/data/daos/exam_dao.dart';
import 'package:flutter_app/domain/achievement_repository.dart';

void main() {
  late udb.AppDatabase uDb;
  late adb.AssetsDatabase aDb;
  late AchievementDao dao;
  late QuestionDao qDao;
  late ExamDao eDao;
  late AchievementRepository repo;

  setUp(() {
    uDb = udb.AppDatabase(NativeDatabase.memory());
    aDb = adb.AssetsDatabase(NativeDatabase.memory());
    dao = AchievementDao(uDb);
    qDao = QuestionDao(aDb);
    eDao = ExamDao(uDb);
    repo = AchievementRepository(dao, qDao, eDao);
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

    test('PAPER_COUNT achievement shows progress from ExamDao', () async {
      await aDb.into(aDb.achievementDefs).insert(adb.AchievementDefsCompanion(
        code: const Value('PAPER_5'),
        name: const Value('组卷达人'),
        category: const Value('PRACTICE'),
        categoryLabel: const Value('学习实践'),
        triggerType: const Value('PAPER_COUNT'),
        threshold: const Value(5),
      ));
      // 还没有组卷
      var cats = await repo.getCategories();
      expect(cats.first.list.first.progress, 0);
      expect(cats.first.list.first.status, 'locked');
      // 新建 3 份组卷
      await eDao.savePaper(title: '卷1');
      await eDao.savePaper(title: '卷2');
      await eDao.savePaper(title: '卷3');
      cats = await repo.getCategories();
      expect(cats.first.list.first.progress, 3);
      expect(cats.first.list.first.status, 'in_progress');
      // 再建 2 份达到门槛
      await eDao.savePaper(title: '卷4');
      await eDao.savePaper(title: '卷5');
      cats = await repo.getCategories();
      expect(cats.first.list.first.progress, 5);
      expect(cats.first.list.first.status, 'unlocked');
    });
  });
}
