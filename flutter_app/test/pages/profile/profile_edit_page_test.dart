import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/domain/user_repository.dart';
import 'package:flutter_app/pages/profile/profile_edit_page.dart';

class _MockRepo implements UserRepository {
  @override Future<UserInfo> getUserInfo() async => const UserInfo(id: 1, name: 'test', realName: '张三',
    school: '北京一中', gaokaoYear: '2025', phone: '13800138000');
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
  @override Future<Map<String, dynamic>> checkin() async => {};
  @override Future<double> todayReward() async => 0;
  @override Future<double> nextReward() async => 0;
  @override Future<double> todayEarned() async => 0;
  @override Future<String> appVersion() async => '2.0.0';
  @override Future<String> questionBankVersion() async => '1.0';
}

void main() {
  testWidgets('ProfileEditPage renders form fields with loaded data', (tester) async {
    await tester.pumpWidget(MaterialApp(home: ProfileEditPage(userRepository: _MockRepo())));
    await tester.pumpAndSettle();
    expect(find.text('姓名'), findsOneWidget);
    expect(find.text('手机号'), findsOneWidget);
    expect(find.text('学校'), findsOneWidget);
    expect(find.text('高考年份'), findsOneWidget);
    expect(find.text('保存'), findsOneWidget);
    // Verify loaded data
    expect(find.text('张三'), findsOneWidget);
    expect(find.text('13800138000'), findsOneWidget);
  });
}
