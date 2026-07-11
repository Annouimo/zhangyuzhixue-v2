import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/domain/user_repository.dart';
import 'package:flutter_app/pages/profile/points_page.dart';

class _MockRepo implements UserRepository {
  final List<PointsRecord> records;

  _MockRepo({this.records = const []});

  @override Future<UserInfo> getUserInfo() async => const UserInfo(id: 1, name: 'test');
  @override Future<void> saveProfile(UserInfo data) async {}
  @override Future<String> uploadAvatar(String localPath) async => '';
  @override Future<List<HistoryItem>> getAnswerHistory() async => [];
  @override Future<int> getAnswerHistoryCount() async => 0;
  @override Future<List<PointsRecord>> getPointsHistory() async => records;
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
  testWidgets('PointsPage shows loading indicator initially', (tester) async {
    final repo = _MockRepo();
    await tester.pumpWidget(MaterialApp(home: PointsPage(userRepository: repo)));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('PointsPage renders empty state gracefully', (tester) async {
    final repo = _MockRepo(records: []);
    await tester.pumpWidget(MaterialApp(home: PointsPage(userRepository: repo)));
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('PointsPage renders record with type and change', (tester) async {
    final repo = _MockRepo(records: [
      const PointsRecord(time: '2026-07-11T10:00:00', type: 'earned', change: 10,
        earned: 10, bonus: 0, spent: 0, available: 50),
    ]);
    await tester.pumpWidget(MaterialApp(home: PointsPage(userRepository: repo)));
    await tester.pumpAndSettle();
    expect(find.text('earned'), findsOneWidget);
    expect(find.text('+10'), findsOneWidget);
  });
}
