import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:flutter_app/main.dart' as app;

/// E2E 凭据从环境变量读取，GitHub Secrets → env
final _e2eUser = Platform.environment['E2E_USER'] ?? 'e2esolver';
final _e2ePass = Platform.environment['E2E_PASS'] ?? 'e2e_test_pass';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('E2E: 解题流程', () {
    testWidgets('选择题 → 提交 → 评分', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // 用预设账号登录
      await tester.enterText(find.byType(TextField).at(0), _e2eUser);
      await tester.enterText(find.byType(TextField).at(1), _e2ePass);
      await tester.tap(find.text('登录'));
      await tester.pumpAndSettle();

      // 导航到组卷页（或其他可进入解题的路径）
      await tester.tap(find.byIcon(Icons.explore));
      await tester.pumpAndSettle();

      // 进入智能组卷
      await tester.tap(find.text('智能组卷'));
      await tester.pumpAndSettle();

      // 确认组卷（使用默认筛选）
      await tester.tap(find.text('开始组卷'));
      await tester.pumpAndSettle();

      // 预览页 → 点击第一题
      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();

      // 等待冷却（如果存在）
      await tester.pump(const Duration(seconds: 3));

      // 选择选项（选择题）
      final choice = find.text('A');
      if (choice.evaluate().isNotEmpty) {
        await tester.tap(choice);
        await tester.pumpAndSettle();
      }

      // 提交
      await tester.tap(find.text('提交'));
      await tester.pumpAndSettle();

      // 验证结果区出现
      expect(find.textContaining('正确'), findsWidgets);
    });
  });
}
