import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/pages/register_page.dart';

/// Helper: 填入所有字段（除第一项邀请码可指定外）
Future<void> _fillAllFields(
  WidgetTester tester, {
  String inviteCode = 'CODE123',
  String username = 'testuser',
  String realName = '张三',
  String phone = '13800138000',
  String gaokaoYear = '2026',
  String password = 'password123',
  String confirmPassword = 'password123',
}) async {
  final fields = find.byType(TextFormField);
  await tester.enterText(fields.at(0), inviteCode);
  await tester.enterText(fields.at(1), username);
  await tester.enterText(fields.at(2), realName);
  await tester.enterText(fields.at(3), phone);
  await tester.enterText(fields.at(4), gaokaoYear);
  await tester.enterText(fields.at(5), password);
  await tester.enterText(fields.at(6), confirmPassword);
}

/// Helper: 点击注册按钮（先确保可见）
Future<void> _tapRegister(WidgetTester tester) async {
  final btn = find.widgetWithText(ElevatedButton, '注册');
  await tester.ensureVisible(btn);
  await tester.pumpAndSettle();
  await tester.tap(btn);
  await tester.pumpAndSettle();
}

void main() {
  group('RegisterPage', () {
    testWidgets('renders register form with all elements', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: RegisterPage()),
      );

      expect(find.text('使用邀请码注册'), findsOneWidget);
      expect(find.text('邀请码'), findsOneWidget);
      expect(find.text('用户名'), findsOneWidget);
      expect(find.text('姓名'), findsOneWidget);
      expect(find.text('手机号'), findsOneWidget);
      expect(find.text('高考年份'), findsOneWidget);
      expect(find.text('密码'), findsOneWidget);
      expect(find.text('确认密码'), findsOneWidget);
      // AppBar 标题 + 按钮
      expect(find.text('注册'), findsAtLeast(1));
      expect(find.text('返回登录'), findsOneWidget);
    });

    testWidgets('shows validation errors on empty submit', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: RegisterPage()),
      );

      await _tapRegister(tester);

      expect(find.text('请输入邀请码'), findsOneWidget);
      expect(find.text('请输入用户名'), findsOneWidget);
      expect(find.text('请输入姓名'), findsOneWidget);
      expect(find.text('请输入手机号'), findsOneWidget);
      expect(find.text('请输入高考年份'), findsOneWidget);
      expect(find.text('请输入密码'), findsOneWidget);
    });

    testWidgets('validates phone number format', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: RegisterPage()),
      );

      await _fillAllFields(tester, phone: '12345');
      await _tapRegister(tester);

      expect(find.text('请输入正确的手机号'), findsOneWidget);
    });

    testWidgets('validates password confirmation match', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: RegisterPage()),
      );

      await _fillAllFields(tester, confirmPassword: 'different');
      await _tapRegister(tester);

      expect(find.text('两次密码不一致'), findsOneWidget);
    });

    testWidgets('validates gaokao year range', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: RegisterPage()),
      );

      await _fillAllFields(tester, gaokaoYear: '2020');
      await _tapRegister(tester);

      expect(find.text('请输入正确的年份（2024-2035）'), findsOneWidget);
    });

    testWidgets('back button returns to previous page', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: RegisterPage()),
      );

      expect(find.byIcon(Icons.arrow_back_ios), findsOneWidget);
      expect(find.text('返回登录'), findsOneWidget);
    });
  });
}
