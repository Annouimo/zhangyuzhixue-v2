import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_app/domain/user_repository.dart';
import 'package:flutter_app/domain/achievement_repository.dart';
import 'package:flutter_app/domain/statistics_repository.dart';
import 'package:flutter_app/pages/profile/profile_page.dart';
import '../../test_setup.dart';

class _MockUserRepo implements UserRepository {
  _MockUserRepo();

  @override
  Future<UserInfo> getUserInfo() async =>
      const UserInfo(id: 1, name: 'test', realName: '张三', studentId: '2024001');

  @override
  Future<void> saveProfile(UserInfo data) async {}
  @override
  Future<String> uploadAvatar(String localPath) async => '';
  @override
  Future<List<HistoryItem>> getAnswerHistory() async => [];
  @override
  Future<int> getAnswerHistoryCount() async => 0;
  @override
  Future<List<PointsRecord>> getPointsHistory() async => [];
  @override
  Future<double> earnedPoints() async => 0;
  @override
  Future<double> bonusPoints() async => 0;
  @override
  Future<double> spentPoints() async => 0;
  @override
  Future<double> availablePoints() async => 0;
  @override
  Future<double> todayPoints() async => 0;
  @override
  Future<({double earned, double bonus, double spent, double available})>
  getPointsSummary() async =>
      (earned: 0.0, bonus: 0.0, spent: 0.0, available: 0.0);
  @override
  Future<List<LevelRow>> getLevels() async => [];
  @override
  Future<String> levelProgress() async => '0/0';
  @override
  Future<int> levelPercentile() async => 0;
  @override
  Future<int> currentLevel() async => 1;
  @override
  Future<int> streakDays() async => 0;
  @override
  Future<Map<String, dynamic>> checkin() async => {};
  @override
  Future<String> questionBankVersion() async => '1.0';
  @override
  Future<({int total, int correct})> getTodaySubmissionStats() async =>
      (total: 0, correct: 0);

  @override
  int getCachedLevelPercentile() => 0;

  @override
  Future<({int level, String progress})> getLevelAndProgress() async =>
      (level: 1, progress: '0/0');
}

class _MockStatsRepo implements StatisticsRepository {
  @override
  Future<StatsOverview> getOverview() async => const StatsOverview(
    totalQuestions: 0,
    accuracyPercent: 0,
    streakDays: 0,
    activeDays: 0,
  );
  @override
  Future<List<DailyRecord>> getDailyRecords(int rangeDays) async => [];
  @override
  Future<List<TrendPoint>> getPointsTrend(int rangeDays) async => [];
  @override
  Future<Distribution> getDistribution({int rangeDays = 0}) async =>
      const Distribution(
        total: 0,
        choiceCount: 0,
        choicePercent: 0,
        fillCount: 0,
        fillPercent: 0,
        solutionCount: 0,
        solutionPercent: 0,
      );
}

class _MockAchieveRepo implements AchievementRepository {
  @override
  Future<AchievementSummary> getSummary() async =>
      const AchievementSummary(unlockedCount: 0, totalCount: 0);
  @override
  Future<int> unlockedCount() async => 0;
  @override
  Future<List<AchievementCategory>> getCategories() async => [];

  @override
  List<AchievementItem>? get lastNewUnlocks => null;

  @override
  set lastNewUnlocks(List<AchievementItem>? v) {}
}

void main() {
  setUp(() => setupTestHooks());
  group('ProfilePage', () {
    testWidgets('shows user info and menu entries', (tester) async {
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: '/',
            routes: [
              GoRoute(
                path: '/',
                builder: (_, _) => ProfilePage(
                  userRepository: _MockUserRepo(),
                  statisticsRepository: _MockStatsRepo(),
                  achievementRepository: _MockAchieveRepo(),
                ),
              ),
              GoRoute(
                path: '/profile/edit',
                builder: (_, _) => const Scaffold(),
              ),
              GoRoute(
                path: '/profile/study-archive',
                builder: (_, _) => const Scaffold(),
              ),
              GoRoute(
                path: '/profile/growth',
                builder: (_, _) => const Scaffold(),
              ),
              GoRoute(
                path: '/profile/settings',
                builder: (_, _) => const Scaffold(),
              ),
            ],
          ),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.text('张三'), findsOneWidget);
      expect(find.text('学号 2024001'), findsOneWidget);
      expect(find.text('编辑资料'), findsOneWidget);
      expect(find.text('学习档案'), findsOneWidget);
      expect(find.text('成长中心'), findsOneWidget);
      expect(find.text('设置'), findsOneWidget);
    });
  });
}
