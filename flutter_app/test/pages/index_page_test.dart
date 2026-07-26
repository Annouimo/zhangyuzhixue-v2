import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app/domain/user_repository.dart';
import 'package:flutter_app/data/prefs/app_prefs.dart';
import 'package:flutter_app/pages/index_page.dart';
import 'package:shared/shared.dart';
import '../support/ui_test_harness.dart';
import '../test_setup.dart';

class _MockUserRepo implements UserRepository {
  final bool shouldFail;
  _MockUserRepo({this.shouldFail = false});

  @override Future<int> currentLevel() async => shouldFail ? throw Exception('fail') : 5;
  @override Future<String> levelProgress() async => shouldFail ? throw Exception('fail') : '7/10';
  @override Future<double> todayPoints() async => shouldFail ? throw Exception('fail') : 3.5;
  @override Future<double> earnedPoints() async => 50;
  @override Future<double> bonusPoints() async => 10;
  @override Future<double> spentPoints() async => 5;
  @override Future<double> availablePoints() async => 55;
  @override Future<List<PointsRecord>> getPointsHistory() async => [];
  @override Future<List<LevelRow>> getLevels() async => [];
  @override Future<int> levelPercentile() async => 75;
  @override Future<int> streakDays() async => 0;
  @override Future<Map<String, dynamic>> checkin() async => {};
  @override Future<String> questionBankVersion() async => '1.0';
  @override Future<UserInfo> getUserInfo() async => const UserInfo(id: 1, name: 'test');
  @override Future<void> saveProfile(UserInfo data) async {}
  @override Future<String> uploadAvatar(String localPath) async => '';
  @override Future<List<HistoryItem>> getAnswerHistory() async => [];
  @override Future<int> getAnswerHistoryCount() async => 0;
  @override
  Future<({int total, int correct})> getTodaySubmissionStats() async => (total: 0, correct: 0);

  @override
  int getCachedLevelPercentile() => 0;

  @override
  Future<({int level, String progress})> getLevelAndProgress() async => (level: 1, progress: '0/0');

  @override
  Future<({double earned, double bonus, double spent, double available})> getPointsSummary() async =>
      (earned: 0.0, bonus: 0.0, spent: 0.0, available: 0.0);
}

void main() {
  setUp(() => setupTestHooks());
  group('IndexPage', () {
    testWidgets('renders app bar with title 首页', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(MaterialApp(home: IndexPage(userRepository: _MockUserRepo())));
      expect(find.text('首页'), findsOneWidget);
    });

    testWidgets('shows loading indicator on first frame', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(MaterialApp(home: IndexPage(userRepository: _MockUserRepo())));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders error placeholder when load fails', (tester) async {
      SharedPreferences.setMockInitialValues({});
      // 使用会抛出异常的 mock，模拟加载失败
      final failingRepo = _MockUserRepo(shouldFail: true);
      await tester.pumpWidget(MaterialApp(home: IndexPage(userRepository: failingRepo)));
      // 让异步 _load 执行完成并捕获异常
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('加载失败'), findsOneWidget);
    });

    for (final viewport in [UiTestViewport.mobile, UiTestViewport.desktop]) {
      testWidgets('${viewport.name} keeps actions ahead of progress data', (
        tester,
      ) async {
        SharedPreferences.setMockInitialValues({});
        await AppPrefs().init();
        await pumpUiScenario(
          tester,
          IndexPage(
            userRepository: _MockUserRepo(),
            streakLoader: () async => 0,
          ),
          viewport: viewport,
          theme: viewport == UiTestViewport.mobile
              ? UiTestTheme.light
              : UiTestTheme.dark,
        );
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.text('开始快速练习'), findsOneWidget);
        expect(
          tester.getTopLeft(find.text('学习入口')).dy,
          lessThan(tester.getTopLeft(find.text('今日进度')).dy),
        );

        final checkinButton = tester.widget<AppButton>(
          find.widgetWithText(AppButton, '签到'),
        );
        expect(checkinButton.variant, AppButtonVariant.outlined);

        final learningCard = find.byKey(
          const Key('home-learning-resources'),
        );
        final streakCard = find.byKey(const Key('home-learning-streak'));
        if (viewport == UiTestViewport.desktop) {
          expect(
            tester.getSize(learningCard).height,
            tester.getSize(streakCard).height,
          );
        }
      });
    }
  });
}
