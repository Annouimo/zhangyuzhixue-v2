import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:flutter_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('E2E: 解题流程', () {
    testWidgets('选择题 → 提交 → 评分', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // 用预设账号登录（假设 staging 环境有此用户）
      await tester.enterText(find.byType(TextField).at(0), 'e2esolver');
      await tester.enterText(find.byType(TextField).at(1), 'test123');
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
