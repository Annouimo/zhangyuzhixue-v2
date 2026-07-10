import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_app/data/database/app_database.dart' as db;
import 'package:flutter_app/data/daos/achievement_dao.dart';

void main() {
  late db.AppDatabase database;
  late AchievementDao dao;

  setUp(() {
    database = db.AppDatabase(NativeDatabase.memory());
    dao = AchievementDao(database);
  });

  tearDown(() => database.close());

  group('AchievementDao', () {
    test('getUnlockedCount returns 0 initially', () async {
      expect(await dao.getUnlockedCount(), 0);
    });

    test('upsertProgress creates new progress record', () async {
      await dao.upsertProgress(achievementCode: 'LOGIN_7', progress: 3, isUnlocked: 0);
      final all = await dao.getAllProgress();
      expect(all.length, 1);
      expect(all.first.achievementCode, 'LOGIN_7');
    });

    test('upsertProgress updates existing record', () async {
      await dao.upsertProgress(achievementCode: 'LOGIN_7', progress: 3, isUnlocked: 0);
      await dao.upsertProgress(achievementCode: 'LOGIN_7', progress: 7, isUnlocked: 1, unlockedAt: '2026-07-10');
      final all = await dao.getAllProgress();
      expect(all.length, 1);
      expect(all.first.progress, 7);
      expect(all.first.isUnlocked, 1);
    });

    test('getUnlockedCount counts unlocked only', () async {
      await dao.upsertProgress(achievementCode: 'A', progress: 5, isUnlocked: 1);
      await dao.upsertProgress(achievementCode: 'B', progress: 3, isUnlocked: 0);
      expect(await dao.getUnlockedCount(), 1);
    });

    test('getSubmissionCount returns 0 initially', () async {
      expect(await dao.getSubmissionCount(), 0);
    });

    test('getRatingCount returns correct count', () async {
      final now = DateTime.now().toIso8601String();
      await database.into(database.questionRatings).insert(db.QuestionRatingsCompanion(
        questionId: Value(1), difficultyScore: Value(5), calculationScore: Value(5), eleganceScore: Value(5), createdAt: Value(now),
      ));
      expect(await dao.getRatingCount(), 1);
    });
  });
}
