import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/domain/user_repository.dart';
import 'package:flutter_app/pages/profile/profile_edit_page.dart';
import '../../test_setup.dart';

class _MockRepo implements UserRepository {
  @override Future<UserInfo> getUserInfo() async => const UserInfo(id: 1, name: 'test', realName: '张三',
    studentId: '2026001', gaokaoYear: '2025', phone: '13800138000');
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

void main() {
  setUp(() => setupTestHooks());
  testWidgets('ProfileEditPage renders form fields with loaded data', (tester) async {
    await tester.pumpWidget(MaterialApp(home: ProfileEditPage(userRepository: _MockRepo())));
    await tester.pumpAndSettle();
    // 头像区域
    expect(find.text('点击相机图标更换头像（建议 200×200 以内）'), findsOneWidget);
    // 基本信息分组标题
    expect(find.text('基本信息'), findsOneWidget);
    // 可编辑字段
    expect(find.text('昵称'), findsOneWidget);
    expect(find.text('高考年份'), findsOneWidget);
    // 只读字段
    expect(find.text('真实姓名'), findsOneWidget);
    expect(find.text('学号'), findsOneWidget);
    expect(find.text('手机号'), findsOneWidget);
    // 提示文案
    expect(find.textContaining('不可修改'), findsNWidgets(2));
    // 加载的数据 — 出现在昵称TextField + 真实姓名只读区
    expect(find.text('张三'), findsNWidgets(2));
    expect(find.text('2026001'), findsOneWidget);
    expect(find.text('13800138000'), findsOneWidget);
    // 保存按钮（可能在屏幕外，需 skipOffstage）
    expect(find.text('保存修改', skipOffstage: false), findsOneWidget);
  });
}
