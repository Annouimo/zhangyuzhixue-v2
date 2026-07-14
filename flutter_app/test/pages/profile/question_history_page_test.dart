import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/domain/user_repository.dart';
import 'package:flutter_app/pages/profile/question_history_page.dart';
import '../../test_setup.dart';

class _MockRepo implements UserRepository {
  @override Future<List<HistoryItem>> getAnswerHistory() async => [];
  @override Future<UserInfo> getUserInfo() async => const UserInfo(id: 1, name: 'test');
  @override Future<void> saveProfile(UserInfo data) async {}
  @override Future<String> uploadAvatar(String localPath) async => '';
  @override Future<int> getAnswerHistoryCount() async => 0;
  @override Future<List<PointsRecord>> getPointsHistory() async => [];
  @override Future<double> earnedPoints() async => 0;
  @override Future<double> bonusPoints() async => 0;
  @override Future<double> spentPoints() async => 0;
  @override Future<double> availablePoints() async => 0;
  @override Future<({double earned, double bonus, double spent, double available})> getPointsSummary() async => (earned: 0.0, bonus: 0.0, spent: 0.0, available: 0.0);
  @override Future<double> todayPoints() async => 0;
  @override Future<List<LevelRow>> getLevels() async => [];
  @override Future<String> levelProgress() async => '0/0';
  @override Future<int> levelPercentile() async => 0;
  @override Future<int> currentLevel() async => 1;
  @override Future<int> streakDays() async => 0;
  @override Future<Map<String, dynamic>> checkin() async => {};
  @override Future<String> questionBankVersion() async => '1.0';
  @override Future<void> syncAccessibleCourseIds() async {}
  @override Future<({int total, int correct})> getTodaySubmissionStats() async => (total: 0, correct: 0);
}

void main() {
    setUp(() => setupTestHooks());
  testWidgets('QuestionHistoryPage shows empty state', (tester) async {
    await tester.pumpWidget(MaterialApp(home: QuestionHistoryPage(userRepository: _MockRepo())));
    await tester.pumpAndSettle();
    expect(find.text('暂无做题记录'), findsOneWidget);
  });
}
