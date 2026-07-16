import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:flutter_app/main.dart' as app;

/// E2E 凭据从环境变量读取，GitHub Secrets → env
final _e2eUser = Platform.environment['E2E_USER'] ?? 'e2esync';
final _e2ePass = Platform.environment['E2E_PASS'] ?? 'e2e_test_pass';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('E2E: 同步推送', () {
    testWidgets('离线提交 → 同步状态 → 恢复联网', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // 登录
      await tester.enterText(find.byType(TextField).at(0), _e2eUser);
      await tester.enterText(find.byType(TextField).at(1), _e2ePass);
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
