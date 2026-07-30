import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:flutter_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('E2E: 注册 → 登录 → 登出', () {
    testWidgets('完整注册登录登出流程', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // 1. 看到登录页
      expect(find.text('章鱼智学'), findsWidgets);

      // 2. 点击「去注册」
      await tester.tap(find.text('去注册'));
      await tester.pumpAndSettle();

      // 3. 填写注册表单
      final now = DateTime.now().millisecondsSinceEpoch;
      final username = 'e2e_user_$now';
      await tester.enterText(find.byType(TextField).at(0), username);
      await tester.enterText(find.byType(TextField).at(1), '张三');
      await tester.enterText(find.byType(TextField).at(2), '13800138000');
      await tester.enterText(find.byType(TextField).at(3), 'pass_$now');
      await tester.enterText(find.byType(TextField).at(4), 'pass_$now');

      // 提交注册
      await tester.tap(find.text('注册'));
      await tester.pumpAndSettle();

      // 4. 注册成功提示
      expect(find.text('注册成功，请登录'), findsOneWidget);

      // 5. 登录
      await tester.enterText(find.byType(TextField).at(0), username);
      await tester.enterText(find.byType(TextField).at(1), 'pass_$now');
      await tester.tap(find.text('登录'));
      await tester.pumpAndSettle();

      // 6. 验证跳转到 MainShell（底部 Tab 可见）
      expect(find.byIcon(Icons.home), findsOneWidget);
      expect(find.byIcon(Icons.book), findsOneWidget);
      expect(find.byIcon(Icons.explore), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);

      // 7. 进入「我的」→ 登出
      await tester.tap(find.byIcon(Icons.person));
      await tester.pumpAndSettle();
      await tester.tap(find.text('登出'));
      await tester.pumpAndSettle();
      expect(find.text('登录'), findsOneWidget);
    });
  });
}
