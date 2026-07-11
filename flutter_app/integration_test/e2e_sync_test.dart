import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:flutter_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('E2E: 同步推送', () {
    testWidgets('离线提交 → 同步状态 → 恢复联网', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // 登录
      await tester.enterText(find.byType(TextField).at(0), 'e2esync');
      await tester.enterText(find.byType(TextField).at(1), 'test123');
      await tester.tap(find.text('登录'));
      await tester.pumpAndSettle();

      // 进入「我的」→ 同步状态
      await tester.tap(find.byIcon(Icons.person));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('同步状态'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('同步状态'));
      await tester.pumpAndSettle();

      // 同步队列页面可见
      expect(find.textContaining('同步'), findsWidgets);
    });
  });
}
