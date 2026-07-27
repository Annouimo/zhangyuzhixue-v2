@Tags(['integration'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_app/data/prefs/app_prefs.dart';
import 'package:flutter_app/main.dart';
import 'package:flutter_app/pages/router.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Windows host renders auth flow and real navigation', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await AppPrefs().init();
    appRouter.go(AppRoutes.login);

    await tester.pumpWidget(const ZhangyuzhixueApp());
    await tester.pumpAndSettle();

    final logicalSize = tester.view.physicalSize / tester.view.devicePixelRatio;
    expect(logicalSize.width, greaterThanOrEqualTo(900));
    expect(logicalSize.height, greaterThanOrEqualTo(600));
    expect(find.text('欢迎回来'), findsOneWidget);
    expect(find.text('登录'), findsOneWidget);

    await tester.tap(find.text('登录'));
    await tester.pumpAndSettle();
    expect(find.text('请输入用户名'), findsOneWidget);
    expect(find.text('请输入密码'), findsOneWidget);

    final registerLink = find.text('注册账号');
    await tester.ensureVisible(registerLink);
    await tester.tap(registerLink);
    await tester.pumpAndSettle();
    expect(find.text('创建学生账号'), findsOneWidget);
    expect(find.text('我已阅读并同意'), findsOneWidget);

    final registerButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, '完成注册'),
    );
    expect(registerButton.onPressed, isNull);

    final agreementCheckbox = find.byType(Checkbox);
    await tester.ensureVisible(agreementCheckbox);
    await tester.tap(agreementCheckbox);
    await tester.pumpAndSettle();
    final enabledRegisterButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, '完成注册'),
    );
    expect(enabledRegisterButton.onPressed, isNotNull);

    final backToLogin = find.text('返回登录');
    await tester.ensureVisible(backToLogin);
    await tester.tap(backToLogin);
    await tester.pumpAndSettle();
    expect(find.text('欢迎回来'), findsOneWidget);
  });
}
