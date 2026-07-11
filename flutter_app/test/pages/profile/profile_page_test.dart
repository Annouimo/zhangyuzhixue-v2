import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_app/domain/user_repository.dart';
import 'package:flutter_app/pages/profile/profile_page.dart';

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
  @override Future<int> streakDays() async => 0;
  @override Future<double> todayReward() async => 0;
  @override Future<double> nextReward() async => 0;
  @override Future<double> todayEarned() async => 0;
  @override Future<String> appVersion() async => '2.0.0';
  @override Future<String> questionBankVersion() async => '1.0';
}

void main() {
  group('ProfilePage', () {
    testWidgets('shows user info and menu entries', (tester) async {
      await tester.pumpWidget(MaterialApp.router(
        routerConfig: GoRouter(initialLocation: '/', routes: [
          GoRoute(path: '/', builder: (_, _) => ProfilePage(userRepository: _MockUserRepo())),
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
      expect(find.text('编辑资料'), findsOneWidget);
      expect(find.text('成就'), findsOneWidget);
    });
  });
}
