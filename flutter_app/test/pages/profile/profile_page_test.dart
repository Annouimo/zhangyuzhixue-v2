import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_app/domain/user_repository.dart';
import 'package:flutter_app/domain/preference_repository.dart';
import 'package:flutter_app/domain/achievement_repository.dart';
import 'package:flutter_app/domain/statistics_repository.dart';
import 'package:flutter_app/pages/profile/profile_page.dart';
import '../../test_setup.dart';

class _MockUserRepo implements UserRepository {
  _MockUserRepo();

  @override Future<UserInfo> getUserInfo() async => const UserInfo(id: 1, name: 'test', realName: '张三', studentId: '2024001');

  @override Future<void> saveProfile(UserInfo data) async {}
  @override Future<String> uploadAvatar(String localPath) async => '';
  @override Future<List<HistoryItem>> getAnswerHistory() async => [];
  @override Future<int> getAnswerHistoryCount() async => 0;
  @override Future<List<PointsRecord>> getPointsHistory() async => [];
  @override Future<double> earnedPoints() async => 0;
  @override Future<double> bonusPoints() async => 0;
  @override Future<double> spentPoints() async => 0;
  @override Future<double> availablePoints() async => 0;
  @override Future<double> todayPoints() async => 0;
  @override Future<List<LevelRow>> getLevels() async => [];
  @override Future<String> levelProgress() async => '0/0';
  @override Future<int> levelPercentile() async => 0;
  @override Future<int> currentLevel() async => 1;
  @override Future<int> streakDays() async => 0;
  @override Future<Map<String, dynamic>> checkin() async => {};
  @override Future<String> questionBankVersion() async => '1.0';
  @override Future<void> syncAccessibleCourseIds() async {}
}

class _MockPrefRepo implements PreferenceRepository {
  @override Future<List<PreferenceSummary>> getList() async => [];
  @override Future<int> getCount() async => 0;
  @override Future<PreferenceFilter> getEdit(int id) async => throw UnimplementedError();
  @override Future<void> save({required String name, required PreferenceFilter filter}) async {}
  @override Future<void> delete(int id) async {}
}

class _MockStatsRepo implements StatisticsRepository {
  @override Future<StatsOverview> getOverview() async => const StatsOverview(totalQuestions: 0, accuracyPercent: 0, streakDays: 0, activeDays: 0);
  @override Future<int> totalQuestions() async => 0;
  @override Future<double> accuracy() async => 0;
  @override Future<List<DailyRecord>> getDailyRecords(int rangeDays) async => [];
  @override Future<List<TrendPoint>> getAccuracyTrend(int rangeDays) async => [];
  @override Future<List<TrendPoint>> getPointsTrend(int rangeDays) async => [];
  @override Future<Distribution> getDistribution() async => const Distribution(total: 0, choiceCount: 0, choicePercent: 0, fillCount: 0, fillPercent: 0, solutionCount: 0, solutionPercent: 0);
}

class _MockAchieveRepo implements AchievementRepository {
  @override Future<AchievementSummary> getSummary() async => const AchievementSummary(unlockedCount: 0, totalCount: 0);
  @override Future<int> unlockedCount() async => 0;
  @override Future<List<AchievementCategory>> getCategories() async => [];
}

void main() {
    setUp(() => setupTestHooks());
  group('ProfilePage', () {
    testWidgets('shows user info and menu entries', (tester) async {
      await tester.pumpWidget(MaterialApp.router(
        routerConfig: GoRouter(initialLocation: '/', routes: [
          GoRoute(path: '/', builder: (_, _) => ProfilePage(
            userRepository: _MockUserRepo(),
            preferenceRepository: _MockPrefRepo(),
            statisticsRepository: _MockStatsRepo(),
            achievementRepository: _MockAchieveRepo(),
          )),
          GoRoute(path: '/profile/edit', builder: (_, _) => const Scaffold()),
          GoRoute(path: '/profile/achievements', builder: (_, _) => const Scaffold()),
          GoRoute(path: '/profile/level', builder: (_, _) => const Scaffold()),
          GoRoute(path: '/profile/points', builder: (_, _) => const Scaffold()),
          GoRoute(path: '/profile/history', builder: (_, _) => const Scaffold()),
          GoRoute(path: '/profile/about', builder: (_, _) => const Scaffold()),
        ]),
      ));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.text('张三'), findsOneWidget);
      expect(find.text('学号 2024001'), findsOneWidget);
      expect(find.text('点击编辑个人信息 ✏️'), findsOneWidget);
      expect(find.text('成就'), findsOneWidget);
    });
  });
}
