import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/pages/profile/growth_center_page.dart';
import 'package:flutter_app/pages/profile/settings_page.dart';
import 'package:flutter_app/pages/profile/study_archive_page.dart';
import 'package:shared/theme/app_theme.dart';

import '../../test_setup.dart';

void main() {
  setUp(setupTestHooks);

  testWidgets('study archive groups review, statistics and history', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const StudyArchivePage()),
    );

    expect(find.text('学习复盘'), findsOneWidget);
    expect(find.text('学习统计'), findsOneWidget);
    expect(find.text('做题记录'), findsOneWidget);
  });

  testWidgets('growth center groups level, points and achievements', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const GrowthCenterPage()),
    );

    expect(find.text('等级'), findsOneWidget);
    expect(find.text('积分'), findsOneWidget);
    expect(find.text('成就'), findsOneWidget);
  });

  testWidgets('settings groups preferences, sync and account actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const SettingsPage()),
    );
    await tester.pump();

    expect(find.text('常用范围'), findsOneWidget);
    expect(find.text('同步状态'), findsOneWidget);
    expect(find.text('关于章鱼智学'), findsOneWidget);
    expect(find.text('修改密码'), findsOneWidget);
    expect(find.text('注销账号'), findsOneWidget);
    expect(find.text('退出登录'), findsOneWidget);
  });
}
