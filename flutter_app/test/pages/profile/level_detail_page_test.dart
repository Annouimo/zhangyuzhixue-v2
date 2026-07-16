import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/domain/user_repository.dart';
import 'package:flutter_app/pages/profile/level_detail_page.dart';
import '../../test_setup.dart';

class _MockRepo implements UserRepository {
  @override Future<String> levelProgress() async => '50/100';
  @override Future<double> earnedPoints() async => 50;
  @override Future<UserInfo> getUserInfo() async => const UserInfo(id: 1, name: 'test');
  @override Future<void> saveProfile(UserInfo data) async {}
  @override Future<String> uploadAvatar(String localPath) async => '';
  @override Future<List<HistoryItem>> getAnswerHistory() async => [];
  @override Future<int> getAnswerHistoryCount() async => 0;
  @override Future<List<PointsRecord>> getPointsHistory() async => [];
  @override Future<double> bonusPoints() async => 0;
  @override Future<double> spentPoints() async => 0;
  @override Future<double> availablePoints() async => 0;
  @override Future<double> todayPoints() async => 0;
  @override Future<List<LevelRow>> getLevels() async => [];
  @override Future<int> levelPercentile() async => 0;
  @override Future<int> currentLevel() async => 1;
  @override Future<int> streakDays() async => 0;
  @override Future<Map<String, dynamic>> checkin() async => {};
  @override Future<String> questionBankVersion() async => '1.0';
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
  testWidgets('LevelDetailPage renders progress', (tester) async {
    await tester.pumpWidget(MaterialApp(home: LevelDetailPage(userRepository: _MockRepo())));
    await tester.pumpAndSettle();
    expect(find.text('等级进度'), findsOneWidget);
    expect(find.textContaining('50'), findsAtLeast(1));
  });
}
