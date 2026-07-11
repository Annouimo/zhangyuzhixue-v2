import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:flutter_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('E2E: 组卷流程', () {
    testWidgets('智能组卷 → 预览 → 确认', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // 登录
      await tester.enterText(find.byType(TextField).at(0), 'e2eexam');
      await tester.enterText(find.byType(TextField).at(1), 'test123');
      await tester.tap(find.text('登录'));
      await tester.pumpAndSettle();

      // 进入组卷
      await tester.tap(find.byIcon(Icons.explore));
      await tester.pumpAndSettle();
      await tester.tap(find.text('智能组卷'));
      await tester.pumpAndSettle();

      // 选择筛选条件
      await tester.tap(find.text('开始组卷'));
      await tester.pumpAndSettle();

      // 预览页有题目列表
      expect(find.byType(ListView), findsOneWidget);

      // 返回 → 进入自主选题
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      await tester.tap(find.text('自主选题'));
      await tester.pumpAndSettle();

      // 确认可渲染
      expect(find.text('自主选题'), findsOneWidget);
    });

    testWidgets('我的组卷列表', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'e2eexam');
      await tester.enterText(find.byType(TextField).at(1), 'test123');
      await tester.tap(find.text('登录'));
      await tester.pumpAndSettle();

      // 进入组卷 → 我的组卷
      await tester.tap(find.byIcon(Icons.explore));
      await tester.pumpAndSettle();
      await tester.tap(find.text('我的组卷'));
      await tester.pumpAndSettle();

      // 列表可见（可能为空）
      expect(find.byType(ListView), findsOneWidget);
    });
  });
}
